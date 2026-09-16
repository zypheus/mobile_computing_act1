import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_computing_act1/main.dart';
import 'package:mobile_computing_act1/providers/theme_provider.dart';

void main() {
  testWidgets('App renders Home Dashboard title and profile card',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MobileComputingApp(),
      ),
    );

    expect(find.text('Flutter Portfolio'), findsOneWidget);
    expect(find.text('Welcome to My Portfolio 👋'), findsOneWidget);
    expect(find.text('Student Developers'), findsOneWidget);
    expect(find.text('Flutter & State Management'), findsOneWidget);
  });

  testWidgets('Navigation to Settings screen works',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MobileComputingApp(),
      ),
    );

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
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MobileComputingApp(),
      ),
    );

    // Ensure Activity 1 card is scrolled into view and tapped
    final activity1Card = find.text('Flutter & State Management');
    expect(activity1Card, findsOneWidget);
    await tester.ensureVisible(activity1Card);
    await tester.tap(activity1Card);
    await tester.pumpAndSettle();

    expect(find.text('1. Local State Demo (StatefulWidget)'), findsOneWidget);
    expect(find.text('Increase'), findsOneWidget);
  });
}
