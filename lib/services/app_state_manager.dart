import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppStateManager {
  static final _myBox = Hive.box('transactions_box');

  // ValueNotifiers that UI components can listen to globally
  static final ValueNotifier<ThemeMode> themeModeNotifier = 
      ValueNotifier(_loadThemeMode());

  static final ValueNotifier<String> currencyNotifier = 
      ValueNotifier(_myBox.get('global_currency', defaultValue: '\$'));

  // Helper to map string/bool to ThemeMode on launch
  static ThemeMode _loadThemeMode() {
    final isDark = _myBox.get('is_dark_mode', defaultValue: false);
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // Toggle Theme Method
  static void toggleTheme(bool isDark) {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    _myBox.put('is_dark_mode', isDark);
  }

  // Update Currency Method
  static void updateCurrency(String newCurrency) {
    currencyNotifier.value = newCurrency;
    _myBox.put('global_currency', newCurrency);
  }
}