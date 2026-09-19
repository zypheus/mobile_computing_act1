import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_event.dart';
import '../models/network_request.dart';
import '../models/network_status.dart';
import '../providers/event_log_provider.dart';
import '../providers/network_status_provider.dart';
import '../providers/request_queue_provider.dart';
import '../widgets/connection_event_log.dart';
import '../widgets/network_action_panel.dart';
import '../widgets/network_status_card.dart';
import '../widgets/request_queue_panel.dart';

/// Activity 2 – real time connectivity monitoring with an offline request
/// queue that survives network handovers.
class NetworkMonitorScreen extends ConsumerWidget {
  const NetworkMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final NetworkStatus status = ref.watch(networkStatusProvider);
    final List<NetworkRequest> requests = ref.watch(requestQueueProvider);
    final List<ConnectionEvent> events = ref.watch(eventLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Network Monitor',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Connectivity & Request Queue',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: <Widget>[
          NetworkStatusPill(connection: status.connection),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= 900;

            final Widget statusColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NetworkStatusCard(status: status),
                const SizedBox(height: 16),
                NetworkActionPanel(status: status, requests: requests),
              ],
            );

            final Widget queueColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RequestQueuePanel(
                  requests: requests,
                  connection: status.connection,
                ),
                const SizedBox(height: 16),
                ConnectionEventLog(events: events),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 28 : 20),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: statusColumn),
                        const SizedBox(width: 20),
                        Expanded(child: queueColumn),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        statusColumn,
                        const SizedBox(height: 20),
                        queueColumn,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}