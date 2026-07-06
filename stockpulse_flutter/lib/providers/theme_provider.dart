import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  late Box _settingsBox;
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode

  ThemeProvider() {
    _settingsBox = Hive.box('settings');
    final isDark = _settingsBox.get('isDark', defaultValue: true);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppTheme.isDark = isDark;
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      AppTheme.isDark = false;
      _settingsBox.put('isDark', false);
    } else {
      _themeMode = ThemeMode.dark;
      AppTheme.isDark = true;
      _settingsBox.put('isDark', true);
    }
    notifyListeners();
  }
}
