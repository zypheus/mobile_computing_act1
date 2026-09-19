import 'network_connection.dart';

/// Immutable snapshot of the currently monitored connectivity state.
class NetworkStatus {
  const NetworkStatus({
    required this.connection,
    required this.source,
    required this.changedAt,
    required this.transitionCount,
    this.isSimulating = false,
  });

  /// State used until the first real device reading arrives.
  NetworkStatus.initial()
      : connection = NetworkConnection.offline,
        source = deviceSource,
        changedAt = DateTime.now(),
        transitionCount = 0,
        isSimulating = false;

  /// Human readable source labels.
  static const String deviceSource = 'connectivity_plus (live device state)';
  static const String simulatedSource = 'Simulated handover script';

  /// Current transport state.
  final NetworkConnection connection;

  /// Where the state came from (device sensor or simulation script).
  final String source;

  /// Timestamp of the most recent state transition.
  final DateTime changedAt;

  /// Amount of state transitions observed since the app started.
  final int transitionCount;

  /// True while a scripted or forced state overrides the device sensor.
  final bool isSimulating;

  bool get isOnline => connection.isOnline;

  /// Short source label for compact UI chips.
  String get sourceLabel => isSimulating ? 'Simulated' : 'Device';

  NetworkStatus copyWith({
    NetworkConnection? connection,
    String? source,
    DateTime? changedAt,
    int? transitionCount,
    bool? isSimulating,
  }) {
    return NetworkStatus(
      connection: connection ?? this.connection,
      source: source ?? this.source,
      changedAt: changedAt ?? this.changedAt,
      transitionCount: transitionCount ?? this.transitionCount,
      isSimulating: isSimulating ?? this.isSimulating,
    );
  }

  @override
  String toString() =>
      'NetworkStatus(${connection.label}, source: $source, '
      'simulating: $isSimulating, transitions: $transitionCount)';
}