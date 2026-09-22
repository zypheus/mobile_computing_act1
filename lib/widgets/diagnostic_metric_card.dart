import 'package:flutter/material.dart';
import '../models/network_diagnostic_models.dart';

class DiagnosticMetricCard extends StatelessWidget {
  final DiagnosticMetrics metrics;
  final NetworkHealthLevel healthLevel;

  const DiagnosticMetricCard({
    super.key,
    required this.metrics,
    required this.healthLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final healthColor = healthLevel.color(colorScheme);

    return Column(
      children: [
        // Primary Bandwidth Cards Row
        Row(
          children: [
            Expanded(
              child: _BandwidthTile(
                title: 'Download Speed',
                value: metrics.formattedDownload,
                rawMbps: metrics.downloadMbps,
                icon: Icons.download_rounded,
                accentColor: healthColor,
                maxMbps: 50.0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BandwidthTile(
                title: 'Upload Speed',
                value: metrics.formattedUpload,
                rawMbps: metrics.uploadMbps,
                icon: Icons.upload_rounded,
                accentColor: colorScheme.secondary,
                maxMbps: 25.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Latency & Ping Matrix Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Latency & Stability Matrix',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: metrics.packetLossPercent > 10
                          ? colorScheme.errorContainer
                          : colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Loss: ${metrics.formattedPacketLoss}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: metrics.packetLossPercent > 10
                            ? colorScheme.onErrorContainer
                            : colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PingMetricItem(
                      label: 'Idle Ping',
                      value: metrics.formattedIdlePing,
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: _PingMetricItem(
                      label: 'Download Ping',
                      value: metrics.formattedDownloadPing,
                      icon: Icons.download_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: _PingMetricItem(
                      label: 'Upload Ping',
                      value: metrics.formattedUploadPing,
                      icon: Icons.upload_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BandwidthTile extends StatelessWidget {
  final String title;
  final String value;
  final double rawMbps;
  final IconData icon;
  final Color accentColor;
  final double maxMbps;

  const _BandwidthTile({
    required this.title,
    required this.value,
    required this.rawMbps,
    required this.icon,
    required this.accentColor,
    required this.maxMbps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (rawMbps / maxMbps).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: accentColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PingMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PingMetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
