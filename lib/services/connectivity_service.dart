import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/network_connection.dart';

/// Abstraction around the platform connectivity sensor.
///
/// Keeping the plugin behind this interface allows the UI/providers to be
/// exercised with a deterministic stream (see [FakeConnectivityService]).
abstract class ConnectivityService {
  /// Emits every time the device transport changes.
  Stream<NetworkConnection> get onConnectivityChanged;

  /// One-shot read used to prime the UI before the first stream event.
  Future<NetworkConnection> checkConnectivity();

  void dispose();
}

/// Production implementation backed by `connectivity_plus`.
class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Maps the plugin transport list onto the three states the UI supports.
  ///
  /// Wired, VPN or Bluetooth links are surfaced as Wi-Fi because they are
  /// unmetered local links, mobile/satellite links become "Cellular" and
  /// everything else is reported as offline.
  static NetworkConnection mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return NetworkConnection.offline;
    }
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn) ||
        results.contains(ConnectivityResult.bluetooth)) {
      return NetworkConnection.wifi;
    }
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.satellite)) {
      return NetworkConnection.cellular;
    }
    return NetworkConnection.offline;
  }

  @override
  Stream<NetworkConnection> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(mapResults).distinct();

  @override
  Future<NetworkConnection> checkConnectivity() async {
    return mapResults(await _connectivity.checkConnectivity());
  }

  @override
  void dispose() {
    // The plugin exposes a singleton broadcast stream, nothing to release.
  }
}

/// Deterministic connectivity source used by tests and offline demos.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({NetworkConnection initial = NetworkConnection.offline})
      : _current = initial;

  final StreamController<NetworkConnection> _controller =
      StreamController<NetworkConnection>.broadcast();

  NetworkConnection _current;

  @override
  Stream<NetworkConnection> get onConnectivityChanged => _controller.stream;

  @override
  Future<NetworkConnection> checkConnectivity() async => _current;

  /// Publishes a new state to every listener.
  void emit(NetworkConnection connection) {
    _current = connection;
    if (!_controller.isClosed) {
      _controller.add(connection);
    }
  }

  @override
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}