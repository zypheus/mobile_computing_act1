import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_event.dart';
import '../models/network_connection.dart';
import '../models/network_request.dart';
import '../services/request_service.dart';
import 'event_log_provider.dart';
import 'network_status_provider.dart';

/// Executes the simulated HTTP transfers.
final requestServiceProvider = Provider<RequestService>((ref) {
  final RequestService service = HttpRequestService();
  ref.onDispose(service.dispose);
  return service;
});

/// Owns the request queue and the recovery behaviour of the monitor.
///
/// Requests are only executed while Wi-Fi or cellular is available. When the
/// link disappears mid-transfer the running request is interrupted, parked in
/// the queue (instead of throwing) and retried automatically as soon as
/// connectivity comes back.
class RequestQueueController extends Notifier<List<NetworkRequest>> {
  final Map<String, RequestCancellationToken> _tokens =
      <String, RequestCancellationToken>{};
  final Map<String, int> _attempts = <String, int>{};
  final Set<String> _running = <String>{};

  int _sequence = 0;
  bool _draining = false;
  bool _drainAgain = false;
  bool _disposed = false;

  @override
  List<NetworkRequest> build() {
    ref.onDispose(() {
      _disposed = true;
      for (final RequestCancellationToken token in _tokens.values) {
        token.cancel('Network Monitor was closed');
      }
      _tokens.clear();
      _running.clear();
    });

    ref.listen<NetworkConnection>(networkConnectionProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      _handleConnectionChange(next);
    });

    return const <NetworkRequest>[];
  }

  bool get _isOnline => !_disposed && ref.read(networkConnectionProvider).isOnline;

  /// Requests still waiting for a usable link.
  int get queuedCount =>
      state.where((NetworkRequest r) => r.isWaitingForNetwork).length;

  /// Adds a request to the queue and starts it when the link is available.
  Future<NetworkRequest> submit(RequestProfile profile, {String? label}) async {
    final NetworkRequest request = NetworkRequest(
      id: 'req-${++_sequence}',
      label: label ?? '${profile.label} #$_sequence',
      status: RequestStatus.queued,
      createdAt: DateTime.now(),
      profile: profile,
      message: _isOnline
          ? 'Waiting for a free slot in the queue'
          : 'Waiting for connectivity',
    );

    state = <NetworkRequest>[...state, request];

    _log(
      type: ConnectionEventType.requestQueued,
      title: '${request.label} queued',
      detail: _isOnline
          ? '${formatBytes(request.totalBytes)} added to the request queue.'
          : 'Submitted while offline – parked until Wi-Fi or cellular returns.',
      connection: ref.read(networkConnectionProvider),
    );

    await _drain(reason: 'request submitted');
    return _find(request.id) ?? request;
  }

  /// Removes completed and failed requests from the panel.
  void clearFinished() {
    final List<NetworkRequest> remaining =
        state.where((NetworkRequest r) => !r.status.isTerminal).toList();
    if (remaining.length == state.length) {
      return;
    }

    for (final NetworkRequest removed in state) {
      if (removed.status.isTerminal) {
        _attempts.remove(removed.id);
      }
    }

    state = remaining;
    _log(
      type: ConnectionEventType.queueCleared,
      title: 'Queue cleaned up',
      detail: 'Finished requests were removed from the queue view.',
    );
  }

  void _handleConnectionChange(NetworkConnection next) {
    if (_disposed) {
      return;
    }

    if (next.isOnline) {
      final int waiting = queuedCount;
      if (waiting > 0) {
        _log(
          type: ConnectionEventType.connectivity,
          title: 'Recovering $waiting queued request${waiting == 1 ? '' : 's'} '
              'on ${next.label}',
          detail: 'Automatic retry started – no user action required.',
          connection: next,
        );
      }
      unawaited(_drain(reason: '${next.label} restored'));
      return;
    }

    _interruptActiveTransfers();
  }

  /// Cancels in-flight transfers so they can be parked instead of crashing.
  void _interruptActiveTransfers() {
    if (_disposed || _tokens.isEmpty) {
      return;
    }

    for (final MapEntry<String, RequestCancellationToken> entry
        in _tokens.entries.toList()) {
      entry.value.cancel('Network connection lost');

      final NetworkRequest? request = _find(entry.key);
      if (request == null) {
        continue;
      }

      _update(
        entry.key,
        status: RequestStatus.queued,
        message: 'Interrupted at ${formatBytes(request.receivedBytes)} – '
            'queued for retry',
      );

      _log(
        type: ConnectionEventType.requestQueued,
        title: '${request.label} queued',
        detail: 'Connection lost after ${formatBytes(request.receivedBytes)} of '
            '${formatBytes(request.totalBytes)}. Parked safely for recovery.',
      );
    }
  }

  /// Runs queued requests in FIFO order while the link is available.
  Future<void> _drain({required String reason}) async {
    if (_disposed) {
      return;
    }

    if (_draining) {
      // A drain is already running: flag it so the loop re-checks the queue
      // before finishing. Without this a transfer that is parked while the
      // link is coming back could be left waiting forever.
      _drainAgain = true;
      return;
    }

    _draining = true;
    try {
      do {
        _drainAgain = false;

        while (!_disposed && _isOnline) {
          final NetworkRequest? next = _nextQueued();
          if (next == null) {
            break;
          }

          await _run(next.id, reason: reason);

          final NetworkRequest? updated = _find(next.id);
          if (updated == null || updated.status == RequestStatus.queued) {
            // The link dropped again (or the request was re-queued): stop this
            // pass, the outer loop resumes when new work arrived.
            break;
          }
        }
      } while (_drainAgain && !_disposed && _isOnline && _nextQueued() != null);
    } finally {
      _draining = false;
      _drainAgain = false;
    }
  }

  NetworkRequest? _nextQueued() {
    if (_disposed) {
      return null;
    }
    for (final NetworkRequest request in state) {
      if (request.status == RequestStatus.queued) {
        return request;
      }
    }
    return null;
  }

  Future<void> _run(String id, {required String reason}) async {
    final NetworkRequest? request = _find(id);
    if (request == null ||
        request.status != RequestStatus.queued ||
        _running.contains(id) ||
        !_isOnline) {
      return;
    }

    final int attempt = (_attempts[id] ?? 0) + 1;
    _attempts[id] = attempt;
    final bool isRetry = attempt > 1;

    final String connectionLabel = ref.read(networkConnectionProvider).label;
    final RequestCancellationToken token = RequestCancellationToken();
    _tokens[id] = token;
    _running.add(id);

    _update(
      id,
      status: isRetry ? RequestStatus.retrying : RequestStatus.active,
      attempt: attempt,
      progress: 0,
      receivedBytes: 0,
      message: isRetry
          ? 'Retrying on $connectionLabel ($reason)'
          : 'Streaming ${formatBytes(request.totalBytes)} over $connectionLabel',
    );

    _log(
      type: isRetry
          ? ConnectionEventType.requestRetried
          : ConnectionEventType.requestStarted,
      title: isRetry ? '${request.label} retrying' : '${request.label} started',
      detail: isRetry
          ? 'Automatic recovery attempt $attempt on $connectionLabel.'
          : 'Transfer started on $connectionLabel '
              '(${formatBytes(request.totalBytes)}).',
    );

    try {
      final RequestResult result =
          await ref.read(requestServiceProvider).execute(
                endpoint: request.endpoint,
                token: token,
                onProgress: (RequestProgress progress) {
                  if (_disposed) {
                    return;
                  }
                  _update(
                    id,
                    progress: progress.fraction,
                    receivedBytes: progress.receivedBytes,
                  );
                },
              );

      if (_disposed) {
        return;
      }

      if (!result.isSuccess) {
        throw StateError('Server responded with HTTP ${result.statusCode}');
      }

      _update(
        id,
        status: RequestStatus.completed,
        progress: 1,
        receivedBytes: result.receivedBytes,
        elapsed: result.elapsed,
        completedAt: DateTime.now(),
        message: 'Completed in ${formatDurationShort(result.elapsed)} on '
            '${connectionLabel.toLowerCase()}',
      );

      _log(
        type: ConnectionEventType.requestCompleted,
        title: '${request.label} completed',
        detail: 'Recovered ${formatBytes(result.receivedBytes)} in '
            '${formatDurationShort(result.elapsed)} (attempt $attempt).',
      );
    } on NetworkInterruptedException catch (error) {
      // Expected path when the link changes mid-transfer: park the request.
      if (_disposed) {
        return;
      }
      _update(
        id,
        status: RequestStatus.queued,
        message: '${error.message} – queued for retry',
      );
    } catch (error) {
      if (_disposed) {
        return;
      }
      final String description = _describeError(error);
      _update(id, status: RequestStatus.failed, message: description);
      _log(
        type: ConnectionEventType.requestFailed,
        title: '${request.label} failed',
        detail: description,
      );
    } finally {
      _tokens.remove(id);
      _running.remove(id);
    }
  }

  String _describeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }

  NetworkRequest? _find(String id) {
    if (_disposed) {
      return null;
    }
    for (final NetworkRequest request in state) {
      if (request.id == id) {
        return request;
      }
    }
    return null;
  }

  void _update(
    String id, {
    RequestStatus? status,
    int? attempt,
    double? progress,
    int? receivedBytes,
    Duration? elapsed,
    DateTime? completedAt,
    String? message,
  }) {
    final NetworkRequest? current = _find(id);
    if (current == null) {
      return;
    }

    final NetworkRequest updated = current.copyWith(
      status: status,
      attempt: attempt,
      progress: progress,
      receivedBytes: receivedBytes,
      elapsed: elapsed ?? current.elapsed,
      completedAt: completedAt ?? current.completedAt,
      message: message ?? current.message,
    );

    state = <NetworkRequest>[
      for (final NetworkRequest item in state)
        if (item.id == updated.id) updated else item,
    ];
  }

  void _log({
    required ConnectionEventType type,
    required String title,
    required String detail,
    NetworkConnection? connection,
  }) {
    ref.read(eventLogProvider.notifier).log(
          type: type,
          title: title,
          detail: detail,
          connection: connection,
        );
  }
}

final requestQueueProvider =
    NotifierProvider<RequestQueueController, List<NetworkRequest>>(
  RequestQueueController.new,
);