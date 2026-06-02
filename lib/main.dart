import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models/transaction.dart'; 
import 'models/category_item.dart'; 
import 'models/recurring_blueprint.dart'; 
import 'screens/security_screen.dart';
import 'screens/dashboard.dart'; 
import 'services/app_state_manager.dart'; 

void main() async {
  // 1. Ensure Flutter bindings are initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // Root screen variable to determine home route dynamically
  Widget initialScreen = const Dashboard();

  try {
    // 2. Initialize Hive for Flutter
    await Hive.initFlutter();

    // 3. Register your TypeAdapters
    Hive.registerAdapter(TransactionAdapter());        // typeId: 0
    Hive.registerAdapter(CategoryItemAdapter());       // typeId: 1
    Hive.registerAdapter(RecurringBlueprintAdapter()); // typeId: 2

    // 4. Open the data persistence storage boxes
    final transactionsBox = await Hive.openBox('transactions_box');
    await Hive.openBox<RecurringBlueprint>('recurring_box'); 
    final categoriesBox = await Hive.openBox<CategoryItem>('categories_box');
    
    // 🔏 Dynamic Security Checkpoint routing evaluation
    final dynamic masterPin = transactionsBox.get("APP_MASTER_PIN");
    if (masterPin != null && masterPin.toString().trim().isNotEmpty) {
      initialScreen = const SecurityScreen();
    } else {
      initialScreen = const Dashboard();
    }

    // 5. Auto-hydrate default categories on the absolute first launch
    if (categoriesBox.isEmpty) {
      const uuid = Uuid();
      final List<CategoryItem> defaultCategories = [
        CategoryItem(
          id: uuid.v4(),
          name: "Housing",
          colorValue: const Color(0xFF2196F3).toARGB32(), // Updated: Removed deprecated .value
          iconCodePoint: Icons.home_rounded.codePoint,
          monthlyLimit: 1500.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Transport",
          colorValue: const Color(0xFF4CAF50).toARGB32(), // Updated: Removed deprecated .value
          iconCodePoint: Icons.directions_bus.codePoint,
          monthlyLimit: 500.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Food",
          colorValue: const Color(0xFFFF9800).toARGB32(), // Updated: Removed deprecated .value
          iconCodePoint: Icons.restaurant.codePoint,
          monthlyLimit: 800.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Entertainment",
          colorValue: const Color(0xFF9C27B0).toARGB32(), // Updated: Removed deprecated .value
          iconCodePoint: Icons.movie_creation_outlined.codePoint,
          monthlyLimit: 300.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Other",
          colorValue: const Color(0xFF9E9E9E).toARGB32(), // Updated: Removed deprecated .value
          iconCodePoint: Icons.category_outlined.codePoint,
          monthlyLimit: 200.0,
        ),
      ];

      for (var cat in defaultCategories) {
        await categoriesBox.put(cat.name, cat); 
      }
    }

    // 6. 🔄 Run the Auto-Leap Recurring Calculation Engine on startup
    await AppStateManager.initializeRecurringEngine();

    debugPrint("Hive & Subscription Core Engines Initialized Successfully");
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }

  runApp(ExpenseTrackerApp(homeScreen: initialScreen));
}

class ExpenseTrackerApp extends StatelessWidget {
  final Widget homeScreen;
  
  const ExpenseTrackerApp({super.key, required this.homeScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppStateManager.themeModeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          
          // --- Minimalist SaaS Light Theme ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[50],
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1e3c72),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),

          // --- Premium AMOLED Dark Theme ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black, 
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1e3c72),
              brightness: Brightness.dark,
              surface: Colors.black, 
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: const CardThemeData( 
              color: Color(0xFF121212), 
              elevation: 0,
            ),
            dialogTheme: const DialogThemeData( 
              backgroundColor: Color(0xFF121212),
              surfaceTintColor: Colors.transparent, 
            ),
          ),
        
          themeMode: currentThemeMode,
          home: homeScreen, 
        ); 
      }, 
    ); 
  }
}