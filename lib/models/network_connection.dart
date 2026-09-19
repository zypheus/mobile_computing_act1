/// Connectivity states surfaced by the Network Monitor module.
///
/// The `connectivity_plus` plugin exposes a wide range of transports
/// (wifi, ethernet, vpn, mobile, bluetooth, satellite, ...). A mobile app
/// usually only needs to distinguish between "connected over Wi-Fi",
/// "connected over cellular data" and "offline", therefore every reported
/// transport is collapsed into one of the three [NetworkConnection] values.
enum NetworkConnection { wifi, cellular, offline }

extension NetworkConnectionX on NetworkConnection {
  /// Label rendered across the Network Monitor UI.
  String get label {
    switch (this) {
      case NetworkConnection.wifi:
        return 'Wi-Fi';
      case NetworkConnection.cellular:
        return 'Cellular';
      case NetworkConnection.offline:
        return 'Offline';
    }
  }

  /// Short explanation rendered underneath the label.
  String get description {
    switch (this) {
      case NetworkConnection.wifi:
        return 'Unmetered link available. Transfers run immediately.';
      case NetworkConnection.cellular:
        return 'Metered mobile data available. Queued work resumes.';
      case NetworkConnection.offline:
        return 'No transport available. Requests wait in the queue.';
    }
  }

  /// Whether network requests can be executed right now.
  bool get isOnline => this != NetworkConnection.offline;

  /// Cellular links are treated as metered for the purpose of this demo.
  bool get isMetered => this == NetworkConnection.cellular;
}