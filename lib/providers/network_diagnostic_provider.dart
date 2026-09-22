import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/network_connection.dart';
import '../models/network_diagnostic_models.dart';
import '../services/network_diagnostic_service.dart';
import 'network_status_provider.dart';

final networkDiagnosticServiceProvider = Provider<NetworkDiagnosticService>((ref) {
  return NetworkDiagnosticService();
});

class NetworkDiagnosticNotifier extends Notifier<NetworkDiagnosticState> {
  Timer? _autoTestTimer;
  bool _isTesting = false;

  @override
  NetworkDiagnosticState build() {
    ref.onDispose(() {
      _autoTestTimer?.cancel();
    });

    // Listen to live connectivity updates from Activity 2 connection provider
    ref.listen(networkConnectionProvider, (previous, next) {
      final connectionLabel = next.label;
      if (state.connectionType != connectionLabel) {
        state = state.copyWith(connectionType: connectionLabel);
        if (!next.isOnline) {
          state = state.copyWith(
            healthLevel: NetworkHealthLevel.degraded,
            statusMessage: 'Connection lost. Device is currently offline.',
          );
        }
      }
    });

    final initialConnection = ref.read(networkConnectionProvider).label;

    return NetworkDiagnosticState(
      connectionType: initialConnection,
    );
  }

  /// Manually triggers the 3-phase diagnostic test sequence
  Future<void> runManualDiagnostic() async {
    if (_isTesting) return;
    _isTesting = true;

    final service = ref.read(networkDiagnosticServiceProvider);
    final currentConnection = ref.read(networkConnectionProvider).label;

    state = state.copyWith(
      phase: DiagnosticPhase.measuringIdlePing,
      progress: 0.05,
      statusMessage: 'Starting diagnostic sequence...',
      connectionType: currentConnection,
    );

    final finalState = await service.runDiagnostics(
      connectionType: currentConnection,
      onProgress: (phase, progress, metrics, status) {
        state = state.copyWith(
          phase: phase,
          progress: progress,
          metrics: metrics,
          statusMessage: status,
        );
      },
    );

    state = finalState.copyWith(
      isPeriodicAutoTestEnabled: state.isPeriodicAutoTestEnabled,
      manualOverrideHealth: state.manualOverrideHealth,
    );

    _isTesting = false;
  }

  /// Toggles periodic background diagnostic testing (runs test every 30s)
  void togglePeriodicTesting() {
    final nextAutoState = !state.isPeriodicAutoTestEnabled;
    _autoTestTimer?.cancel();
    _autoTestTimer = null;

    if (nextAutoState) {
      _autoTestTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!_isTesting && state.connectionType != 'Offline') {
          runManualDiagnostic();
        }
      });
      // Optionally run initial test immediately on toggle
      runManualDiagnostic();
    }

    state = state.copyWith(isPeriodicAutoTestEnabled: nextAutoState);
  }

  /// Allows override of health level for instant UI demo testing of adaptive multimedia viewer
  void setManualOverrideHealth(NetworkHealthLevel? override) {
    if (override == null) {
      state = state.copyWith(clearManualOverride: true);
    } else {
      state = state.copyWith(manualOverrideHealth: override);
    }
  }
}

final networkDiagnosticNotifierProvider =
    NotifierProvider<NetworkDiagnosticNotifier, NetworkDiagnosticState>(
  NetworkDiagnosticNotifier.new,
);

/// Convenience Provider exposing the active NetworkHealthLevel globally
final globalNetworkHealthProvider = Provider<NetworkHealthLevel>((ref) {
  return ref.watch(networkDiagnosticNotifierProvider).effectiveHealthLevel;
});
