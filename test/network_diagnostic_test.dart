import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_computing_act1/models/network_diagnostic_models.dart';
import 'package:mobile_computing_act1/providers/network_diagnostic_provider.dart';
import 'package:mobile_computing_act1/services/network_diagnostic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkHealthLevel Classification Tests', () {
    test('Classifies as Excellent when download > 10 Mbps and normal ping/loss', () {
      const metrics = DiagnosticMetrics(
        downloadMbps: 25.5,
        uploadMbps: 12.0,
        idlePingMs: 22.0,
        downloadPingMs: 35.0,
        uploadPingMs: 40.0,
        packetLossPercent: 0.0,
      );

      final health = NetworkDiagnosticService.classifyHealth(
        metrics,
        connectionType: 'Wi-Fi',
      );

      expect(health, equals(NetworkHealthLevel.excellent));
    });

    test('Classifies as Fair when download is between 2 and 10 Mbps', () {
      const metrics = DiagnosticMetrics(
        downloadMbps: 6.5,
        uploadMbps: 3.0,
        idlePingMs: 45.0,
        downloadPingMs: 60.0,
        uploadPingMs: 70.0,
        packetLossPercent: 2.0,
      );

      final health = NetworkDiagnosticService.classifyHealth(
        metrics,
        connectionType: 'Wi-Fi',
      );

      expect(health, equals(NetworkHealthLevel.fair));
    });

    test('Classifies as Poor when download is < 2 Mbps', () {
      const metrics = DiagnosticMetrics(
        downloadMbps: 1.2,
        uploadMbps: 0.5,
        idlePingMs: 120.0,
        downloadPingMs: 150.0,
        uploadPingMs: 180.0,
        packetLossPercent: 5.0,
      );

      final health = NetworkDiagnosticService.classifyHealth(
        metrics,
        connectionType: 'Cellular',
      );

      expect(health, equals(NetworkHealthLevel.poor));
    });

    test('Classifies as Degraded when packet loss > 15%', () {
      const metrics = DiagnosticMetrics(
        downloadMbps: 15.0,
        uploadMbps: 8.0,
        idlePingMs: 50.0,
        downloadPingMs: 80.0,
        uploadPingMs: 90.0,
        packetLossPercent: 25.0,
      );

      final health = NetworkDiagnosticService.classifyHealth(
        metrics,
        connectionType: 'Wi-Fi',
      );

      expect(health, equals(NetworkHealthLevel.degraded));
    });

    test('Classifies as Degraded when idle ping > 300ms', () {
      const metrics = DiagnosticMetrics(
        downloadMbps: 20.0,
        uploadMbps: 10.0,
        idlePingMs: 350.0,
        downloadPingMs: 400.0,
        uploadPingMs: 420.0,
        packetLossPercent: 0.0,
      );

      final health = NetworkDiagnosticService.classifyHealth(
        metrics,
        connectionType: 'Cellular',
      );

      expect(health, equals(NetworkHealthLevel.degraded));
    });

    test('Classifies as Degraded when connection is Offline', () {
      const metrics = DiagnosticMetrics();

      final health = NetworkDiagnosticService.classifyHealth(
        metrics,
        connectionType: 'Offline',
      );

      expect(health, equals(NetworkHealthLevel.degraded));
    });
  });

  group('NetworkDiagnosticService Mocked Execution Tests', () {
    test('Runs 3-phase diagnostic sequence and reports progress', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' || request.method == 'HEAD') {
          return http.Response('OK', 200);
        } else if (request.method == 'POST') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = NetworkDiagnosticService(client: mockClient);
      final List<DiagnosticPhase> phasesVisited = [];

      final result = await service.runDiagnostics(
        connectionType: 'Wi-Fi',
        onProgress: (phase, progress, metrics, status) {
          if (!phasesVisited.contains(phase)) {
            phasesVisited.add(phase);
          }
        },
      );

      expect(result.phase, equals(DiagnosticPhase.complete));
      expect(result.metrics.downloadMbps, greaterThanOrEqualTo(0.0));
      expect(phasesVisited, contains(DiagnosticPhase.measuringIdlePing));
      expect(phasesVisited, contains(DiagnosticPhase.measuringDownload));
      expect(phasesVisited, contains(DiagnosticPhase.measuringUpload));
      expect(phasesVisited, contains(DiagnosticPhase.complete));
    });
  });

  group('Riverpod State Notifier Tests', () {
    test('Toggles periodic testing and sets manual health override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(networkDiagnosticNotifierProvider.notifier);
      var state = container.read(networkDiagnosticNotifierProvider);

      expect(state.isPeriodicAutoTestEnabled, isFalse);
      expect(state.manualOverrideHealth, isNull);

      // Toggle periodic testing
      notifier.togglePeriodicTesting();
      state = container.read(networkDiagnosticNotifierProvider);
      expect(state.isPeriodicAutoTestEnabled, isTrue);

      // Set manual override
      notifier.setManualOverrideHealth(NetworkHealthLevel.excellent);
      state = container.read(networkDiagnosticNotifierProvider);
      expect(state.effectiveHealthLevel, equals(NetworkHealthLevel.excellent));

      // Reset manual override
      notifier.setManualOverrideHealth(null);
      state = container.read(networkDiagnosticNotifierProvider);
      expect(state.manualOverrideHealth, isNull);
    });
  });
}
