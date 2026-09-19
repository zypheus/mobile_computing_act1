import 'package:flutter/material.dart';

import '../models/connection_event.dart';
import '../models/network_connection.dart';
import '../models/network_request.dart';

/// Shared iconography/colour mapping for the Network Monitor feature so every
/// widget renders the same state the same way.

/// Success tone that stays readable on light and dark Material 3 surfaces.
Color successColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6ED79F)
      : const Color(0xFF1B7A4B);
}

/// Soft tint used behind signal icons.
Color tintOf(Color color) => color.withValues(alpha: 0.14);

IconData connectionIcon(NetworkConnection connection) {
  switch (connection) {
    case NetworkConnection.wifi:
      return Icons.wifi_rounded;
    case NetworkConnection.cellular:
      return Icons.signal_cellular_alt_rounded;
    case NetworkConnection.offline:
      return Icons.wifi_off_rounded;
  }
}

Color connectionColor(BuildContext context, NetworkConnection connection) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  switch (connection) {
    case NetworkConnection.wifi:
      return scheme.primary;
    case NetworkConnection.cellular:
      return scheme.tertiary;
    case NetworkConnection.offline:
      return scheme.error;
  }
}

Color connectionContainerColor(
  BuildContext context,
  NetworkConnection connection,
) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  switch (connection) {
    case NetworkConnection.wifi:
      return scheme.primaryContainer;
    case NetworkConnection.cellular:
      return scheme.tertiaryContainer;
    case NetworkConnection.offline:
      return scheme.errorContainer;
  }
}

IconData requestStatusIcon(RequestStatus status) {
  switch (status) {
    case RequestStatus.queued:
      return Icons.hourglass_bottom_rounded;
    case RequestStatus.active:
      return Icons.downloading_rounded;
    case RequestStatus.retrying:
      return Icons.autorenew_rounded;
    case RequestStatus.completed:
      return Icons.check_circle_rounded;
    case RequestStatus.failed:
      return Icons.error_rounded;
  }
}

Color requestStatusColor(BuildContext context, RequestStatus status) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  switch (status) {
    case RequestStatus.queued:
      return scheme.secondary;
    case RequestStatus.active:
      return scheme.primary;
    case RequestStatus.retrying:
      return scheme.tertiary;
    case RequestStatus.completed:
      return successColor(context);
    case RequestStatus.failed:
      return scheme.error;
  }
}

Color requestStatusContainerColor(BuildContext context, RequestStatus status) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  switch (status) {
    case RequestStatus.queued:
      return scheme.surfaceContainerHighest;
    case RequestStatus.active:
      return scheme.primaryContainer;
    case RequestStatus.retrying:
      return scheme.tertiaryContainer;
    case RequestStatus.completed:
      return tintOf(successColor(context));
    case RequestStatus.failed:
      return scheme.errorContainer;
  }
}

IconData connectionEventIcon(ConnectionEventType type) {
  switch (type) {
    case ConnectionEventType.connectivity:
      return Icons.wifi_tethering_rounded;
    case ConnectionEventType.requestStarted:
      return Icons.downloading_rounded;
    case ConnectionEventType.requestQueued:
      return Icons.hourglass_bottom_rounded;
    case ConnectionEventType.requestRetried:
      return Icons.autorenew_rounded;
    case ConnectionEventType.requestCompleted:
      return Icons.check_circle_rounded;
    case ConnectionEventType.requestFailed:
      return Icons.error_rounded;
    case ConnectionEventType.queueCleared:
      return Icons.cleaning_services_rounded;
  }
}

Color connectionEventColor(BuildContext context, ConnectionEventType type) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  switch (type) {
    case ConnectionEventType.connectivity:
      return scheme.primary;
    case ConnectionEventType.requestStarted:
      return scheme.primary;
    case ConnectionEventType.requestQueued:
      return scheme.secondary;
    case ConnectionEventType.requestRetried:
      return scheme.tertiary;
    case ConnectionEventType.requestCompleted:
      return successColor(context);
    case ConnectionEventType.requestFailed:
      return scheme.error;
    case ConnectionEventType.queueCleared:
      return scheme.onSurfaceVariant;
  }
}

/// Rounded surface shared by the monitor panels.
BoxDecoration monitorCardDecoration(BuildContext context) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
  );
}