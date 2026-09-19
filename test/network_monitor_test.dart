import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_computing_act1/models/connection_event.dart';
import 'package:mobile_computing_act1/models/network_connection.dart';
import 'package:mobile_computing_act1/models/network_request.dart';
import 'package:mobile_computing_act1/providers/event_log_provider.dart';
import 'package:mobile_computing_act1/providers/network_status_provider.dart';
import 'package:mobile_computing_act1/providers/request_queue_provider.dart';
import 'package:mobile_computing_act1/screens/network_monitor_screen.dart';
import 'package:mobile_computing_act1/services/connectivity_service.dart';
import 'package:mobile_computing_act1/widgets/network_status_card.dart';

/// Small profile so queue tests finish quickly.
const RequestProfile testProfile = RequestProfile(
  id: 'test',
  label: 'Test payload',
  path: '/v1/test/payload',
  totalBytes: 4096,
  chunkCount: 10,
  chunkDelay: Duration(milliseconds: 100),
);

ProviderContainer containerWith(FakeConnectivityService fake) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      connectivityServiceProvider.overrideWithValue(fake),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
  String description = 'condition',
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out after $timeout waiting for $description');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('submissions made while offline stay queued and recover on Wi-Fi',
      () async {
    final FakeConnectivityService fake = FakeConnectivityService(
      initial: NetworkConnection.offline,
    );
    final ProviderContainer container = containerWith(fake);

    expect(
      container.read(networkConnectionProvider),
      NetworkConnection.offline,
    );

    unawaited(
      container
          .read(requestQueueProvider.notifier)
          .submit(testProfile, label: 'Parked payload'),
    );

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(
      container.read(requestQueueProvider).single.status,
      RequestStatus.queued,
    );

    fake.emit(NetworkConnection.wifi);

    await waitUntil(
      () =>
          container.read(requestQueueProvider).single.status ==
          RequestStatus.completed,
      description: 'the queued request to complete after recovery',
    );

    final NetworkRequest request = container.read(requestQueueProvider).single;
    expect(request.status, RequestStatus.completed);
    expect(request.attempt, 1);
    expect(request.progress, 1);
    expect(request.receivedBytes, testProfile.totalBytes);
    expect(request.elapsed, isNotNull);

    final List<ConnectionEvent> events = container.read(eventLogProvider);
    expect(
      events.any((ConnectionEvent e) => e.type == ConnectionEventType.requestQueued),
      isTrue,
    );
    expect(
      events.any(
        (ConnectionEvent e) => e.type == ConnectionEventType.requestCompleted,
      ),
      isTrue,
    );
  });

  test('a transfer interrupted by a network handover is queued, then retried',
      () async {
    final FakeConnectivityService fake = FakeConnectivityService(
      initial: NetworkConnection.wifi,
    );
    final ProviderContainer container = containerWith(fake);

    unawaited(
      container
          .read(requestQueueProvider.notifier)
          .submit(testProfile, label: 'Handover payload'),
    );

    await waitUntil(
      () => container.read(requestQueueProvider).single.progress > 0,
      description: 'the transfer to start',
    );
    expect(
      container.read(requestQueueProvider).single.status,
      RequestStatus.active,
    );

    // Wi-Fi -> Offline interrupts the running transfer.
    fake.emit(NetworkConnection.offline);

    await waitUntil(
      () =>
          container.read(requestQueueProvider).single.status ==
          RequestStatus.queued,
      description: 'the interrupted request to be parked in the queue',
    );
    final NetworkRequest parked = container.read(requestQueueProvider).single;
    expect(parked.status, RequestStatus.queued);
    expect(parked.message, contains('queued for retry'));

    // Offline -> Cellular triggers the automatic retry.
    fake.emit(NetworkConnection.cellular);

    await waitUntil(
      () =>
          container.read(requestQueueProvider).single.status ==
          RequestStatus.retrying,
      description: 'the automatic retry to start',
    );

    await waitUntil(
      () =>
          container.read(requestQueueProvider).single.status ==
          RequestStatus.completed,
      description: 'the retried request to complete',
    );

    final NetworkRequest recovered = container.read(requestQueueProvider).single;
    expect(recovered.status, RequestStatus.completed);
    expect(recovered.attempt, 2);
    expect(recovered.progress, 1);

    final List<ConnectionEvent> events = container.read(eventLogProvider);
    expect(
      events.any(
        (ConnectionEvent e) => e.type == ConnectionEventType.requestRetried,
      ),
      isTrue,
    );
  });

  Future<void> pumpMonitor(
    WidgetTester tester,
    FakeConnectivityService fake,
  ) async {
    tester.view.physicalSize = const Size(1500, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(home: NetworkMonitorScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders the live network state and follows connectivity changes',
      (WidgetTester tester) async {
    final FakeConnectivityService fake = FakeConnectivityService(
      initial: NetworkConnection.wifi,
    );
    await pumpMonitor(tester, fake);

    expect(find.text('CURRENT NETWORK STATE'), findsOneWidget);
    expect(find.text('Request Queue'), findsOneWidget);
    expect(find.text('Connection Event Log'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(networkStateLabelKey)).data,
      'Wi-Fi',
    );

    fake.emit(NetworkConnection.cellular);
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(networkStateLabelKey)).data,
      'Cellular',
    );

    fake.emit(NetworkConnection.offline);
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(networkStateLabelKey)).data,
      'Offline',
    );
  });

  testWidgets('offline submissions are shown as queued instead of failing',
      (WidgetTester tester) async {
    final FakeConnectivityService fake = FakeConnectivityService(
      initial: NetworkConnection.offline,
    );
    await pumpMonitor(tester, fake);

    await tester.ensureVisible(find.text('Simulate Large Request'));
    await tester.tap(find.text('Simulate Large Request'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Queued'), findsWidgets);
    expect(
      find.textContaining('Offline – 1 request waiting'),
      findsOneWidget,
    );
  });

  testWidgets('renders without overflow on a phone sized viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final FakeConnectivityService fake = FakeConnectivityService(
      initial: NetworkConnection.wifi,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(home: NetworkMonitorScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // A RenderFlex overflow would be reported as a test exception.
    expect(find.text('CURRENT NETWORK STATE'), findsOneWidget);
    expect(find.text('Simulate Handover'), findsOneWidget);

    await tester.ensureVisible(find.text('Standard Request'));
    await tester.tap(find.text('Standard Request'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Active'), findsWidgets);

    // Let the short transfer finish so no timers are left pending.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('handover demo queues the running transfer and recovers it',
      (WidgetTester tester) async {
    final FakeConnectivityService fake = FakeConnectivityService(
      initial: NetworkConnection.wifi,
    );
    await pumpMonitor(tester, fake);

    // Start a long running transfer on Wi-Fi.
    await tester.ensureVisible(find.text('Simulate Large Request'));
    await tester.tap(find.text('Simulate Large Request'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Active'), findsWidgets);

    // Wi-Fi -> Offline -> Cellular while the request is running.
    await tester.ensureVisible(find.text('Simulate Handover'));
    await tester.tap(find.text('Simulate Handover'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<Text>(find.byKey(networkStateLabelKey)).data,
      'Offline',
    );
    expect(find.text('Queued'), findsWidgets);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<Text>(find.byKey(networkStateLabelKey)).data,
      'Cellular',
    );
    expect(find.text('Retrying'), findsWidgets);

    // The recovery attempt finishes on the restored link.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Completed'), findsWidgets);
  });
}