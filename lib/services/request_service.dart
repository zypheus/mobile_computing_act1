import 'dart:async';

import 'package:http/http.dart' as http;

import 'simulated_http_client.dart';

/// Thrown when a transfer is aborted because the link went away.
class NetworkInterruptedException implements Exception {
  NetworkInterruptedException(this.message);

  final String message;

  @override
  String toString() => 'NetworkInterruptedException: $message';
}

/// Progress snapshot reported while a body is streaming in.
class RequestProgress {
  const RequestProgress({required this.receivedBytes, required this.totalBytes});

  final int receivedBytes;
  final int totalBytes;

  double get fraction {
    if (totalBytes <= 0) {
      return 0;
    }
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }
}

/// Successful outcome of a simulated request.
class RequestResult {
  const RequestResult({
    required this.statusCode,
    required this.receivedBytes,
    required this.totalBytes,
    required this.elapsed,
  });

  final int statusCode;
  final int receivedBytes;
  final int totalBytes;
  final Duration elapsed;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Cancellation handle shared between the queue and the running request.
class RequestCancellationToken {
  bool _cancelled = false;
  String _reason = 'Request cancelled';

  bool get isCancelled => _cancelled;

  String get reason => _reason;

  void cancel([String reason = 'Request cancelled by the client']) {
    if (_cancelled) {
      return;
    }
    _reason = reason;
    _cancelled = true;
  }
}

/// Executes the (simulated) HTTP transfers used by the request queue.
abstract class RequestService {
  Future<RequestResult> execute({
    required Uri endpoint,
    required RequestCancellationToken token,
    required void Function(RequestProgress progress) onProgress,
  });

  void dispose();
}

/// Executes requests through `package:http`.
///
/// The client is injectable, so the same pipeline can either stream a
/// simulated payload ([SimulatedHttpClient]) or talk to a real host.
class HttpRequestService implements RequestService {
  HttpRequestService({http.Client? client}) : _client = client ?? SimulatedHttpClient();

  final http.Client _client;

  static const Duration _cancelPollInterval = Duration(milliseconds: 40);

  @override
  Future<RequestResult> execute({
    required Uri endpoint,
    required RequestCancellationToken token,
    required void Function(RequestProgress progress) onProgress,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    final http.Request request = http.Request('GET', endpoint)
      ..headers['accept'] = 'application/octet-stream'
      ..headers['user-agent'] = 'network-monitor-demo/1.0';

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } on http.ClientException catch (error) {
      throw NetworkInterruptedException(error.message);
    }

    if (token.isCancelled) {
      throw NetworkInterruptedException(token.reason);
    }

    final int totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    onProgress(RequestProgress(receivedBytes: 0, totalBytes: totalBytes));

    final Completer<void> completer = Completer<void>();
    StreamSubscription<List<int>>? subscription;

    // Polls the token so a dropped link aborts within ~40ms instead of
    // waiting for the next chunk to arrive.
    final Timer watchdog = Timer.periodic(_cancelPollInterval, (_) {
      if (token.isCancelled && !completer.isCompleted) {
        completer.completeError(NetworkInterruptedException(token.reason));
      }
    });

    subscription = response.stream.listen(
      (List<int> chunk) {
        if (completer.isCompleted) {
          return;
        }
        receivedBytes += chunk.length;
        onProgress(
          RequestProgress(receivedBytes: receivedBytes, totalBytes: totalBytes),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        if (completer.isCompleted) {
          return;
        }
        if (error is http.ClientException) {
          completer.completeError(NetworkInterruptedException(error.message));
        } else {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      cancelOnError: true,
    );

    try {
      await completer.future;
    } finally {
      watchdog.cancel();
      await subscription.cancel();
    }

    stopwatch.stop();
    if (token.isCancelled) {
      throw NetworkInterruptedException(token.reason);
    }

    return RequestResult(
      statusCode: response.statusCode,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
      elapsed: stopwatch.elapsed,
    );
  }

  @override
  void dispose() {
    _client.close();
  }
}