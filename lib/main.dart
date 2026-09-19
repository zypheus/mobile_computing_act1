import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/activity1_screen.dart';
import 'screens/activity2_screen.dart';
import 'screens/network_monitor_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // Riverpod powers the Network Monitor module (Activity 3) while the
    // existing Provider based theme state keeps working unchanged.
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MobileComputingApp(),
      ),
    ),
  );
}

class MobileComputingApp extends StatelessWidget {
  const MobileComputingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Base Primary Seed Color
        const seedColor = Colors.indigo;

        return MaterialApp(
          title: 'Flutter Portfolio - Activity 1',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
            ),
            cardTheme: const CardThemeData(
              margin: EdgeInsets.zero,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 1,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            cardTheme: const CardThemeData(
              margin: EdgeInsets.zero,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 1,
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/activity1': (context) => const Activity1Screen(),
            '/activity2': (context) => const Activity2Screen(),
            '/network-monitor': (context) => const NetworkMonitorScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
