import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_item.dart';
import '../models/recurring_blueprint.dart'; // Import your new RecurringBlueprint model

// Explicit declaration of the timeline sorting parameters
enum TimelineFilter { week, month, allTime }

class AppStateManager {
  static final _myBox = Hive.box('transactions_box');
  // Handle to the dynamic categories storage box
  static final _categoriesBox = Hive.box<CategoryItem>('categories_box');
  // Handle to the structural subscriptions and billing schedule engine box
  static final _recurringBox = Hive.box<RecurringBlueprint>('recurring_box');

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

  // Global category listener initialized with current persisted box values
  static final ValueNotifier<List<CategoryItem>> categoriesNotifier = 
      ValueNotifier<List<CategoryItem>>(_categoriesBox.values.toList());

  // New: Global recurring scheduler tracker listener initialized with database lists
  static final ValueNotifier<List<RecurringBlueprint>> recurringNotifier = 
      ValueNotifier<List<RecurringBlueprint>>(_recurringBox.values.toList());

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

  // Action method to save a dynamic category and update UI pipelines
  static void addCustomCategory(CategoryItem item) {
    _categoriesBox.put(item.name, item);
    categoriesNotifier.value = _categoriesBox.values.toList(); // Forces listeners to rebuild
  }

  // Action method to drop a category from storage and push update
  static void deleteCategory(String categoryName) {
    _categoriesBox.delete(categoryName);
    categoriesNotifier.value = _categoriesBox.values.toList(); // Forces listeners to rebuild
  }

  // --- 🔄 New: Smart Auto-Leap Engine & Subscription Management Logic ---

  /// Core execution pipeline evaluating outstanding logs on application start
  static Future<void> initializeRecurringEngine() async {
    final List<RecurringBlueprint> savedBlueprints = _recurringBox.values.toList();
    recurringNotifier.value = savedBlueprints;

    bool recordsUpdated = false;
    final DateTime diagnosticNow = DateTime.now();
    
    // Load current dynamic transactions reference array from transaction box
    final dynamic transactionData = _myBox.get("TRANSACTION_LIST");
    List<Map<String, dynamic>> transactionRawList = [];
    
    if (transactionData != null) {
      transactionRawList = List<Map<String, dynamic>>.from(
        transactionData.map((e) => Map<String, dynamic>.from(e))
      );
    }

    for (var blueprint in savedBlueprints) {
      DateTime checkTimeline = blueprint.nextBillingDate;
      
      // Catch-up loops injecting missing operational intervals dynamically
      while (checkTimeline.isBefore(diagnosticNow) || checkTimeline.isAtSameMomentAs(diagnosticNow)) {
        final automatedTx = {
          'title': "[Auto] ${blueprint.title}",
          'amount': blueprint.amount,
          'date': checkTimeline.toIso8601String(),
          'category': blueprint.category,
          'isExpense': blueprint.isExpense,
        };
        
        transactionRawList.add(automatedTx);
        blueprint.lastTriggeredDate = checkTimeline;
        recordsUpdated = true;
        
        // Advance tracking parameters parameters loop
        checkTimeline = blueprint.nextBillingDate;
      }
      
      if (recordsUpdated) {
        await blueprint.save(); // Sync internal updated dates back to Hive box keys
      }
    }

    if (recordsUpdated) {
      // Commit dynamic modifications safely straight back down onto local binary disks
      await _myBox.put("TRANSACTION_LIST", transactionRawList);
      recurringNotifier.value = _recurringBox.values.toList(); // Refresh pipelines
    }
  }

  /// Action method to create and track a new recurring blueprint rule
  static Future<void> addRecurringSubscription(RecurringBlueprint item) async {
    await _recurringBox.put(item.id, item);
    recurringNotifier.value = _recurringBox.values.toList(); // Notify listeners
  }

  /// Action method to delete a recurring tracking profile straight from local storage
  static Future<void> deleteRecurringSubscription(String id) async {
    await _recurringBox.delete(id);
    recurringNotifier.value = _recurringBox.values.toList(); // Notify listeners
  }
}