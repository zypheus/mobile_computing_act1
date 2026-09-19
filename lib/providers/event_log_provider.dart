import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_event.dart';
import '../models/network_connection.dart';

/// Rolling log of connectivity transitions and request recovery steps.
///
/// Newest entries are stored first so the UI can render them without sorting.
class EventLogController extends Notifier<List<ConnectionEvent>> {
  /// Upper bound so the log cannot grow forever during a long demo.
  static const int maxEntries = 80;

  int _sequence = 0;

  @override
  List<ConnectionEvent> build() => const <ConnectionEvent>[];

  /// Prepends a new entry to the log.
  void log({
    required ConnectionEventType type,
    required String title,
    required String detail,
    NetworkConnection? connection,
  }) {
    final ConnectionEvent event = ConnectionEvent(
      id: 'evt-${++_sequence}',
      type: type,
      title: title,
      detail: detail,
      timestamp: DateTime.now(),
      connection: connection,
    );
    final List<ConnectionEvent> next = <ConnectionEvent>[event, ...state];
    state = next.length > maxEntries ? next.sublist(0, maxEntries) : next;
  }

  void clear() {
    state = const <ConnectionEvent>[];
  }
}

final eventLogProvider =
    NotifierProvider<EventLogController, List<ConnectionEvent>>(EventLogController.new);