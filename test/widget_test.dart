import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_computing_act1/main.dart';
import 'package:mobile_computing_act1/providers/theme_provider.dart';
import 'package:mobile_computing_act1/widgets/network_status_card.dart';

/// Mirrors `main()`: Riverpod scope plus the existing Provider theme state.
Widget buildApp() {
  return ProviderScope(
    child: ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MobileComputingApp(),
    ),
  );
}

void main() {
  testWidgets('App renders Home Dashboard title and profile card',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Flutter Portfolio'), findsOneWidget);
    expect(find.text('Welcome to Our Portfolio'), findsOneWidget);
    // Appears in both the section header and the profile card badge.
    expect(find.text('Student Developers'), findsWidgets);
    expect(find.text('John Lloyd Legario'), findsOneWidget);
    expect(find.text('Flutter & State Management'), findsOneWidget);
  });

  testWidgets('Navigation to Settings screen works',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    // Tap Settings button in AppBar
    final settingsButton = find.byIcon(Icons.settings_outlined);
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
  });

  testWidgets('Navigation to Activity 1 screen works',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    // Ensure Activity 1 card is scrolled into view and tapped
    final activity1Card = find.text('Flutter & State Management');
    expect(activity1Card, findsOneWidget);
    await tester.ensureVisible(activity1Card);
    await tester.tap(activity1Card);
    await tester.pumpAndSettle();

    expect(find.text('1. Local State Demo (StatefulWidget)'), findsOneWidget);
    expect(find.text('Increase'), findsOneWidget);
  });

  testWidgets('Navigation to the Network Monitor activity works',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    final networkCard = find.text('Network Monitor & Request Queue');
    expect(networkCard, findsOneWidget);
    await tester.ensureVisible(networkCard);
    await tester.tap(networkCard);
    await tester.pumpAndSettle();

    expect(find.text('CURRENT NETWORK STATE'), findsOneWidget);
    expect(find.text('Request Queue'), findsOneWidget);
    expect(find.text('Connection Event Log'), findsOneWidget);
    expect(find.byKey(networkStateLabelKey), findsOneWidget);
  });
}
