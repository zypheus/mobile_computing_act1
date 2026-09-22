import 'package:flutter/material.dart';

/// Network health classification levels
enum NetworkHealthLevel {
  excellent,
  fair,
  poor,
  degraded,
}

extension NetworkHealthLevelX on NetworkHealthLevel {
  String get label {
    switch (this) {
      case NetworkHealthLevel.excellent:
        return 'Excellent';
      case NetworkHealthLevel.fair:
        return 'Fair';
      case NetworkHealthLevel.poor:
        return 'Poor';
      case NetworkHealthLevel.degraded:
        return 'Degraded';
    }
  }

  String get description {
    switch (this) {
      case NetworkHealthLevel.excellent:
        return '> 10 Mbps • Low Latency • Ideal for High-Res Video & Real-time Apps';
      case NetworkHealthLevel.fair:
        return '2–10 Mbps • Moderate Ping • Suitable for HD Video & Standard Web';
      case NetworkHealthLevel.poor:
        return '< 2 Mbps • High Ping • Low Resolution & Basic Data Recommended';
      case NetworkHealthLevel.degraded:
        return 'Heavy Packet Loss / High Latency • Data Saver Mode Engaged';
    }
  }

  IconData get icon {
    switch (this) {
      case NetworkHealthLevel.excellent:
        return Icons.verified_rounded;
      case NetworkHealthLevel.fair:
        return Icons.signal_cellular_alt_rounded;
      case NetworkHealthLevel.poor:
        return Icons.signal_cellular_alt_2_bar_rounded;
      case NetworkHealthLevel.degraded:
        return Icons.warning_amber_rounded;
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case NetworkHealthLevel.excellent:
        return const Color(0xFF10B981); // Emerald Green
      case NetworkHealthLevel.fair:
        return const Color(0xFF0284C7); // Sky Blue
      case NetworkHealthLevel.poor:
        return const Color(0xFFF59E0B); // Amber / Orange
      case NetworkHealthLevel.degraded:
        return const Color(0xFFEF4444); // Crimson Red
    }
  }
}

/// Phases in the diagnostic test sequence
enum DiagnosticPhase {
  idle,
  measuringIdlePing,
  measuringDownload,
  measuringUpload,
  complete,
  failed,
}

extension DiagnosticPhaseX on DiagnosticPhase {
  String get stepName {
    switch (this) {
      case DiagnosticPhase.idle:
        return 'Ready';
      case DiagnosticPhase.measuringIdlePing:
        return 'Phase 1: Measuring Idle Ping';
      case DiagnosticPhase.measuringDownload:
        return 'Phase 2: Measuring Download Speed & Latency';
      case DiagnosticPhase.measuringUpload:
        return 'Phase 3: Measuring Upload Speed & Latency';
      case DiagnosticPhase.complete:
        return 'Diagnostic Complete';
      case DiagnosticPhase.failed:
        return 'Diagnostic Failed';
    }
  }
}

/// Real-time metrics calculated during network diagnostic runs
class DiagnosticMetrics {
  final double downloadMbps;
  final double uploadMbps;
  final double idlePingMs;
  final double downloadPingMs;
  final double uploadPingMs;
  final double packetLossPercent;

  const DiagnosticMetrics({
    this.downloadMbps = 0.0,
    this.uploadMbps = 0.0,
    this.idlePingMs = 0.0,
    this.downloadPingMs = 0.0,
    this.uploadPingMs = 0.0,
    this.packetLossPercent = 0.0,
  });

  DiagnosticMetrics copyWith({
    double? downloadMbps,
    double? uploadMbps,
    double? idlePingMs,
    double? downloadPingMs,
    double? uploadPingMs,
    double? packetLossPercent,
  }) {
    return DiagnosticMetrics(
      downloadMbps: downloadMbps ?? this.downloadMbps,
      uploadMbps: uploadMbps ?? this.uploadMbps,
      idlePingMs: idlePingMs ?? this.idlePingMs,
      downloadPingMs: downloadPingMs ?? this.downloadPingMs,
      uploadPingMs: uploadPingMs ?? this.uploadPingMs,
      packetLossPercent: packetLossPercent ?? this.packetLossPercent,
    );
  }

  String get formattedDownload => '${downloadMbps.toStringAsFixed(2)} Mbps';
  String get formattedUpload => '${uploadMbps.toStringAsFixed(2)} Mbps';
  String get formattedIdlePing => '${idlePingMs.toStringAsFixed(0)} ms';
  String get formattedDownloadPing => '${downloadPingMs.toStringAsFixed(0)} ms';
  String get formattedUploadPing => '${uploadPingMs.toStringAsFixed(0)} ms';
  String get formattedPacketLoss => '${packetLossPercent.toStringAsFixed(1)}%';
}

/// Overall immutable state for the Network Diagnostic Dashboard
class NetworkDiagnosticState {
  final DiagnosticPhase phase;
  final double progress; // 0.0 to 1.0
  final NetworkHealthLevel healthLevel;
  final DiagnosticMetrics metrics;
  final DateTime? lastDiagnosticTime;
  final bool isPeriodicAutoTestEnabled;
  final String connectionType; // Wi-Fi, Cellular, Ethernet, Offline
  final String statusMessage;
  final NetworkHealthLevel? manualOverrideHealth;

  const NetworkDiagnosticState({
    this.phase = DiagnosticPhase.idle,
    this.progress = 0.0,
    this.healthLevel = NetworkHealthLevel.fair,
    this.metrics = const DiagnosticMetrics(),
    this.lastDiagnosticTime,
    this.isPeriodicAutoTestEnabled = false,
    this.connectionType = 'Unknown',
    this.statusMessage = 'Tap "Run Diagnostic" or enable auto-test.',
    this.manualOverrideHealth,
  });

  /// The effective health level considering optional manual override for UI demo
  NetworkHealthLevel get effectiveHealthLevel =>
      manualOverrideHealth ?? healthLevel;

  NetworkDiagnosticState copyWith({
    DiagnosticPhase? phase,
    double? progress,
    NetworkHealthLevel? healthLevel,
    DiagnosticMetrics? metrics,
    DateTime? lastDiagnosticTime,
    bool? isPeriodicAutoTestEnabled,
    String? connectionType,
    String? statusMessage,
    NetworkHealthLevel? manualOverrideHealth,
    bool clearManualOverride = false,
  }) {
    return NetworkDiagnosticState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      healthLevel: healthLevel ?? this.healthLevel,
      metrics: metrics ?? this.metrics,
      lastDiagnosticTime: lastDiagnosticTime ?? this.lastDiagnosticTime,
      isPeriodicAutoTestEnabled:
          isPeriodicAutoTestEnabled ?? this.isPeriodicAutoTestEnabled,
      connectionType: connectionType ?? this.connectionType,
      statusMessage: statusMessage ?? this.statusMessage,
      manualOverrideHealth: clearManualOverride
          ? null
          : (manualOverrideHealth ?? this.manualOverrideHealth),
    );
  }
}
