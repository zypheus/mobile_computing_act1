import 'network_connection.dart';

/// Kinds of entries shown in the connection event log.
enum ConnectionEventType {
  connectivity,
  requestStarted,
  requestQueued,
  requestRetried,
  requestCompleted,
  requestFailed,
  queueCleared,
}

/// A single line of the connection event log.
class ConnectionEvent {
  const ConnectionEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.timestamp,
    this.connection,
  });

  final String id;
  final ConnectionEventType type;

  /// Short headline, e.g. "Network state: Offline".
  final String title;

  /// Longer explanation of what happened.
  final String detail;

  final DateTime timestamp;

  /// Connectivity state associated with the event, when relevant.
  final NetworkConnection? connection;

  /// `HH:mm:ss` label rendered next to the event.
  String get timeLabel {
    final String hours = timestamp.hour.toString().padLeft(2, '0');
    final String minutes = timestamp.minute.toString().padLeft(2, '0');
    final String seconds = timestamp.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  String toString() => 'ConnectionEvent(${type.name}, $title @ $timeLabel)';
}