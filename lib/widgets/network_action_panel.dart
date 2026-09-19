import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/network_request.dart';
import '../models/network_status.dart';
import '../providers/network_status_provider.dart';
import '../providers/request_queue_provider.dart';
import 'network_monitor_styles.dart';
import 'section_header.dart';

/// Buttons that drive the Network Monitor demo.
class NetworkActionPanel extends ConsumerWidget {
  const NetworkActionPanel({
    super.key,
    required this.status,
    required this.requests,
  });

  final NetworkStatus status;
  final List<NetworkRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isSimulating = status.isSimulating;
    final bool hasFinished =
        requests.any((NetworkRequest r) => r.status.isTerminal);

    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final ButtonStyle filledStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: shape,
    );
    final ButtonStyle outlinedStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: shape,
    );
    final ButtonStyle textStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: shape,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: monitorCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(
            title: 'Simulation Controls',
            subtitle: 'Drive the demo without changing device settings',
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                style: filledStyle,
                onPressed: isSimulating
                    ? null
                    : () {
                        unawaited(
                          ref
                              .read(networkStatusProvider.notifier)
                              .simulateHandover(),
                        );
                      },
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Simulate Handover'),
              ),
              FilledButton.tonalIcon(
                style: filledStyle,
                onPressed: () {
                  unawaited(
                    ref
                        .read(requestQueueProvider.notifier)
                        .submit(RequestProfile.large),
                  );
                },
                icon: const Icon(Icons.cloud_download_rounded, size: 18),
                label: const Text('Simulate Large Request'),
              ),
              OutlinedButton.icon(
                style: outlinedStyle,
                onPressed: () {
                  unawaited(
                    ref
                        .read(requestQueueProvider.notifier)
                        .submit(RequestProfile.standard),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Standard Request'),
              ),
              if (isSimulating)
                OutlinedButton.icon(
                  style: outlinedStyle,
                  onPressed: () {
                    unawaited(
                      ref
                          .read(networkStatusProvider.notifier)
                          .restoreConnection(),
                    );
                  },
                  icon: const Icon(Icons.sensors_rounded, size: 18),
                  label: const Text('Restore Connection'),
                )
              else
                OutlinedButton.icon(
                  style: outlinedStyle,
                  onPressed: () {
                    ref.read(networkStatusProvider.notifier).holdOffline();
                  },
                  icon: const Icon(Icons.wifi_off_rounded, size: 18),
                  label: const Text('Force Offline'),
                ),
              TextButton.icon(
                style: textStyle,
                onPressed: hasFinished
                    ? () {
                        ref.read(requestQueueProvider.notifier).clearFinished();
                      }
                    : null,
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: const Text('Clear Finished'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HintRow(
            icon:
                isSimulating ? Icons.science_rounded : Icons.play_circle_outline,
            color: isSimulating ? scheme.tertiary : scheme.primary,
            text: isSimulating
                ? 'Demo override active – the device sensor is ignored until the '
                    'simulation is released.'
                : 'Recommended demo: tap "Simulate Large Request", then '
                    '"Simulate Handover". The transfer is interrupted on '
                    'Wi-Fi → Offline and retried automatically once cellular '
                    'data returns.',
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tintOf(color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}