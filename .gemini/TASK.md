# Tasks

- [x] Initialize Flutter project `mobile_computing_act1` (2026-09-16)
- [x] Implement Provider global theme state, master portfolio dashboard, Activity 1 state management demo, Activity 2 placeholder, and Settings screen (2026-09-16)
- [x] Activity 3 – Network Monitor module: `connectivity_plus` live state (Wi-Fi / Cellular / Offline), Riverpod request queue that parks interrupted `http` requests and retries them after a handover, scripted Wi-Fi → Offline → Cellular demo controls and a connection event log (2026-09-19)
- [x] Remove Activity 2 placeholder and promote Network Monitor module to Activity 2 (2026-09-19)
- [x] Activity 3 – Network Diagnostic Dashboard: background diagnostic service, 3-phase test sequence, global Riverpod state, real-time metrics dashboard, adaptive multimedia UI demo (2026-09-22)

## Activity 3 – Network Monitor structure

| Layer | Files |
| --- | --- |
| Models | `lib/models/network_connection.dart`, `network_status.dart`, `network_request.dart`, `connection_event.dart` |
| Services | `lib/services/connectivity_service.dart`, `request_service.dart`, `simulated_http_client.dart` |
| Providers | `lib/providers/network_status_provider.dart`, `request_queue_provider.dart`, `event_log_provider.dart` |
| Widgets | `lib/widgets/network_status_card.dart`, `network_action_panel.dart`, `request_queue_panel.dart`, `request_tile.dart`, `connection_event_log.dart`, `network_monitor_styles.dart` |
| Screen | `lib/screens/network_monitor_screen.dart` (route `/network-monitor`) |
| Tests | `test/network_monitor_test.dart` |

Notes:
- Riverpod (`ProviderScope`) is mounted at the root in `lib/main.dart`; the existing Provider based theme state is untouched.
- `HttpRequestService` runs through `package:http`; `SimulatedHttpClient` is a real `http.BaseClient` that streams a synthetic payload so the demo is deterministic and works offline.
- Tests: `flutter test`, static analysis: `flutter analyze`.
