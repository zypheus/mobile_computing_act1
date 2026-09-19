import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_event.dart';
import '../models/network_connection.dart';
import '../models/network_status.dart';
import '../services/connectivity_service.dart';
import 'event_log_provider.dart';

/// The connectivity sensor used by the Network Monitor.
///
/// Overridden in tests (and could be overridden in demos) with a deterministic
/// implementation.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final ConnectivityService service = ConnectivityPlusService();
  ref.onDispose(service.dispose);
  return service;
});

/// Controls the live connectivity state of the monitor.
///
/// The controller subscribes to the `connectivity_plus` stream, keeps the
/// latest state in memory and can additionally play a scripted handover
/// (Wi-Fi -> Offline -> Cellular) so the queue/recovery behaviour can be
/// demonstrated on any device.
class NetworkStatusController extends Notifier<NetworkStatus> {
  NetworkStatusController({this.stepDuration = defaultStepDuration});

  /// How long each scripted handover step is held.
  static const Duration defaultStepDuration = Duration(seconds: 4);

  final Duration stepDuration;

  static const Duration _tick = Duration(milliseconds: 100);

  StreamSubscription<NetworkConnection>? _subscription;
  bool _disposed = false;

  /// Invalidates a running script when a newer simulation or restore happens.
  int _generation = 0;

  @override
  NetworkStatus build() {
    final ConnectivityService service = ref.watch(connectivityServiceProvider);

    ref.onDispose(() {
      _disposed = true;
      _subscription?.cancel();
      _subscription = null;
    });

    _subscription = service.onConnectivityChanged.listen(
      _handleDeviceUpdate,
      onError: (Object _) {
        // Some targets (web/desktop tests) cannot provide a sensor; the
        // monitor simply keeps the last known state.
      },
    );

    unawaited(_syncWithDevice(service));

    return NetworkStatus.initial();
  }

  /// Reads the transport once so the UI is accurate before the first event.
  Future<void> _syncWithDevice(ConnectivityService service) async {
    try {
      final NetworkConnection connection = await service.checkConnectivity();
      if (_disposed || state.isSimulating) {
        return;
      }
      _apply(
        connection,
        source: NetworkStatus.deviceSource,
        isSimulating: false,
      );
    } catch (_) {
      // Keep the safe "offline" default when the sensor is unavailable.
    }
  }

  void _handleDeviceUpdate(NetworkConnection connection) {
    if (_disposed || state.isSimulating) {
      return;
    }
    _apply(
      connection,
      source: NetworkStatus.deviceSource,
      isSimulating: false,
    );
  }

  /// Applies a state transition and records it in the event log.
  void _apply(
    NetworkConnection connection, {
    required String source,
    required bool isSimulating,
  }) {
    final bool changed = state.connection != connection;
    state = NetworkStatus(
      connection: connection,
      source: source,
      changedAt: changed ? DateTime.now() : state.changedAt,
      transitionCount: changed ? state.transitionCount + 1 : state.transitionCount,
      isSimulating: isSimulating,
    );

    if (!changed) {
      return;
    }

    _log(
      title: 'Network state: ${connection.label}',
      detail: isSimulating
          ? 'Applied by the ${NetworkStatus.simulatedSource.toLowerCase()}.'
          : 'Reported by connectivity_plus.',
      connection: connection,
    );
  }

  void _log({
    required String title,
    required String detail,
    NetworkConnection? connection,
  }) {
    ref.read(eventLogProvider.notifier).log(
          type: ConnectionEventType.connectivity,
          title: title,
          detail: detail,
          connection: connection,
        );
  }

  /// Plays the portfolio demo sequence: **Wi-Fi -> Offline -> Cellular**.
  ///
  /// Each step is held for [stepDuration] so a running transfer can be
  /// interrupted while the state is scripted. Returns `true` when the whole
  /// sequence completed; it is aborted when the user restores the connection
  /// or leaves the screen.
  Future<bool> simulateHandover({Duration? stepDuration}) async {
    final Duration hold = stepDuration ?? this.stepDuration;
    final int generation = ++_generation;

    _log(
      title: 'Handover simulation started',
      detail: 'Scripted sequence Wi-Fi → Offline → Cellular. '
          'In-flight requests are interrupted on purpose.',
    );

    if (!await _runStep(NetworkConnection.wifi, generation, hold)) {
      return false;
    }
    if (!await _runStep(NetworkConnection.offline, generation, hold)) {
      return false;
    }
    if (!await _runStep(NetworkConnection.cellular, generation, hold)) {
      return false;
    }

    await restoreConnection();
    return !_disposed;
  }

  Future<bool> _runStep(
    NetworkConnection connection,
    int generation,
    Duration hold,
  ) async {
    if (_disposed || generation != _generation) {
      return false;
    }
    _apply(
      connection,
      source: NetworkStatus.simulatedSource,
      isSimulating: true,
    );
    return _hold(hold, generation);
  }

  /// Waits while staying responsive to disposal or a newer script run.
  Future<bool> _hold(Duration duration, int generation) async {
    var remaining = duration;
    while (remaining > Duration.zero) {
      if (_disposed || generation != _generation) {
        return false;
      }
      await Future<void>.delayed(_tick);
      remaining -= _tick;
    }
    return !_disposed && generation == _generation;
  }

  /// Forces the monitor offline until [restoreConnection] is called.
  void holdOffline() {
    _generation++;
    _apply(
      NetworkConnection.offline,
      source: NetworkStatus.simulatedSource,
      isSimulating: true,
    );
  }

  /// Drops the simulated override and hands monitoring back to the device.
  Future<void> restoreConnection() async {
    _generation++;
    final bool wasSimulating = state.isSimulating;

    try {
      final NetworkConnection connection =
          await ref.read(connectivityServiceProvider).checkConnectivity();
      if (_disposed) {
        return;
      }
      _apply(
        connection,
        source: NetworkStatus.deviceSource,
        isSimulating: false,
      );
    } catch (_) {
      if (_disposed) {
        return;
      }
      _apply(
        NetworkConnection.offline,
        source: NetworkStatus.deviceSource,
        isSimulating: false,
      );
    }

    if (wasSimulating) {
      _log(
        title: 'Simulation released',
        detail: 'Monitoring handed back to the device sensor.',
        connection: state.connection,
      );
    }
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatusController, NetworkStatus>(
  NetworkStatusController.new,
);

/// Convenience provider exposing only the current transport state.
final networkConnectionProvider = Provider<NetworkConnection>((ref) {
  return ref.watch(networkStatusProvider).connection;
});
