import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_item.dart'; // Import your new CategoryItem model

// Explicit declaration of the timeline sorting parameters
enum TimelineFilter { week, month, allTime }

class AppStateManager {
  static final _myBox = Hive.box('transactions_box');
  // Handle to the dynamic categories storage box
  static final _categoriesBox = Hive.box<CategoryItem>('categories_box');

  // --- ValueNotifiers that UI components can listen to globally ---
  
  static final ValueNotifier<ThemeMode> themeModeNotifier = 
      ValueNotifier(_loadThemeMode());

  static final ValueNotifier<String> currencyNotifier = 
      ValueNotifier(_myBox.get('global_currency', defaultValue: '\$'));

  // Biometric Notifier initialized directly from saved disk values
  static final ValueNotifier<bool> biometricNotifier = 
      ValueNotifier(_myBox.get('is_biometric_enabled', defaultValue: true));

  // Global timeline notifier targeting dashboard list sorting filters
  static final ValueNotifier<TimelineFilter> activeFilterNotifier = 
      ValueNotifier<TimelineFilter>(TimelineFilter.allTime);

  // New: Global category listener initialized with current persisted box values
  static final ValueNotifier<List<CategoryItem>> categoriesNotifier = 
      ValueNotifier<List<CategoryItem>>(_categoriesBox.values.toList());

  // --- Helper to map string/bool to ThemeMode on launch ---
  static ThemeMode _loadThemeMode() {
    final isDark = _myBox.get('is_dark_mode', defaultValue: false);
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // --- State Action Methods ---

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

  // Toggle Biometrics Method
  static void toggleBiometrics(bool enabled) {
    biometricNotifier.value = enabled;
    _myBox.put('is_biometric_enabled', enabled);
  }

  // Core implementation for updating current calendar timelines
  static void updateTimelineFilter(TimelineFilter newFilter) {
    activeFilterNotifier.value = newFilter;
  }

  // New: Action method to save a dynamic category and update UI pipelines
  static void addCustomCategory(CategoryItem item) {
    _categoriesBox.put(item.name, item);
    categoriesNotifier.value = _categoriesBox.values.toList(); // Forces listeners to rebuild
  }

  // New: Action method to drop a category from storage and push update
  static void deleteCategory(String categoryName) {
    _categoriesBox.delete(categoryName);
    categoriesNotifier.value = _categoriesBox.values.toList(); // Forces listeners to rebuild
  }
}