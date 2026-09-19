import 'package:flutter/material.dart';

import '../models/network_connection.dart';
import '../models/network_request.dart';
import 'network_monitor_styles.dart';
import 'request_tile.dart';
import 'section_header.dart';

/// Panel that lists every tracked request together with its live state.
class RequestQueuePanel extends StatelessWidget {
  const RequestQueuePanel({
    super.key,
    required this.requests,
    required this.connection,
  });

  final List<NetworkRequest> requests;
  final NetworkConnection connection;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<NetworkRequest> ordered = requests.reversed.toList();

    final int active =
        requests.where((NetworkRequest r) => r.status.isInFlight).length;
    final int queued = requests.where((NetworkRequest r) => r.isWaitingForNetwork).length;
    final int retrying =
        requests.where((NetworkRequest r) => r.status == RequestStatus.retrying).length;
    final int completed =
        requests.where((NetworkRequest r) => r.status == RequestStatus.completed).length;
    final int failed =
        requests.where((NetworkRequest r) => r.status == RequestStatus.failed).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: monitorCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'Request Queue',
            subtitle: 'Interrupted transfers are parked here, never crash',
            trailing: _CountBadge(label: '${requests.length} tracked'),
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            const _EmptyQueueState()
          else ...<Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _QueueStat(
                  label: 'Active',
                  value: active,
                  color: scheme.primary,
                ),
                _QueueStat(
                  label: 'Queued',
                  value: queued,
                  color: scheme.secondary,
                ),
                _QueueStat(
                  label: 'Retrying',
                  value: retrying,
                  color: scheme.tertiary,
                ),
                _QueueStat(
                  label: 'Completed',
                  value: completed,
                  color: successColor(context),
                ),
                if (failed > 0)
                  _QueueStat(
                    label: 'Failed',
                    value: failed,
                    color: scheme.error,
                  ),
              ],
            ),
            if (queued > 0 && !connection.isOnline) ...<Widget>[
              const SizedBox(height: 14),
              _OfflineNotice(queued: queued),
            ],
            const SizedBox(height: 14),
            for (int i = 0; i < ordered.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              RequestTile(request: ordered[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.queued});

  final int queued;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.wifi_off_rounded, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline – $queued request${queued == 1 ? '' : 's'} waiting. '
              'They are retried automatically as soon as Wi-Fi or cellular '
              'connectivity returns.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueueState extends StatelessWidget {
  const _EmptyQueueState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.inbox_rounded, size: 30, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'No requests yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Simulate Large Request", then run the handover to watch the '
            'transfer get queued and recovered.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueStat extends StatelessWidget {
  const _QueueStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tintOf(color),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$value',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}