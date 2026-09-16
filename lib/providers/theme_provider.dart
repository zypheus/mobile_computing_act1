import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _appThemeMode = AppThemeMode.system;

  AppThemeMode get appThemeMode => _appThemeMode;

  bool get isDarkMode {
    if (_appThemeMode == AppThemeMode.system) {
      final window = WidgetsBinding.instance.platformDispatcher;
      return window.platformBrightness == Brightness.dark;
    }
    return _appThemeMode == AppThemeMode.dark;
  }

  ThemeMode get themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  void toggleTheme(bool isDark) {
    _appThemeMode = isDark ? AppThemeMode.dark : AppThemeMode.light;
    notifyListeners();
  }

  void setAppThemeMode(AppThemeMode mode) {
    _appThemeMode = mode;
    notifyListeners();
  }
}
