import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models/transaction.dart'; // Ensure Transaction model is imported
import 'models/category_item.dart'; // Import your new CategoryItem model
import 'screens/security_screen.dart';
import 'services/app_state_manager.dart'; 

void main() async {
  // 1. Ensure Flutter bindings are initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Hive for Flutter
    await Hive.initFlutter();

    // 3. Register your TypeAdapters
    Hive.registerAdapter(TransactionAdapter()); // Adapts your Transaction class (typeId: 0)
    Hive.registerAdapter(CategoryItemAdapter()); // Adapts your CategoryItem class (typeId: 1)

    // 4. Open the data persistence storage boxes
    await Hive.openBox('transactions_box');
    final categoriesBox = await Hive.openBox<CategoryItem>('categories_box');
    
    // 5. Auto-hydrate default categories on the absolute first launch
    if (categoriesBox.isEmpty) {
      const uuid = Uuid();
      final List<CategoryItem> defaultCategories = [
        CategoryItem(
          id: uuid.v4(),
          name: "Housing",
          colorValue: const Color(0xFF2196F3).value, // Colors.blue
          iconCodePoint: Icons.home_rounded.codePoint,
          monthlyLimit: 1500.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Transport",
          colorValue: const Color(0xFF4CAF50).value, // Colors.green
          iconCodePoint: Icons.directions_bus.codePoint,
          monthlyLimit: 500.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Food",
          colorValue: const Color(0xFFFF9800).value, // Colors.orange
          iconCodePoint: Icons.restaurant.codePoint,
          monthlyLimit: 800.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Entertainment",
          colorValue: const Color(0xFF9C27B0).value, // Colors.purple
          iconCodePoint: Icons.movie_creation_outlined.codePoint,
          monthlyLimit: 300.0,
        ),
        CategoryItem(
          id: uuid.v4(),
          name: "Other",
          colorValue: const Color(0xFF9E9E9E).value, // Colors.grey
          iconCodePoint: Icons.category_outlined.codePoint,
          monthlyLimit: 200.0,
        ),
      ];

      for (var cat in defaultCategories) {
        await categoriesBox.put(cat.name, cat); // Use name as key for direct filters
      }
    }

    debugPrint("Hive & Custom Categories Box Initialized Successfully");
  } catch (e) {
    debugPrint("Hive Initialization Error: $e");
  }

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to global theme changes dynamically across the entire application
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
            scaffoldBackgroundColor: Colors.black, // True pitch black for AMOLED panels
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1e3c72),
              brightness: Brightness.dark,
              surface: Colors.black, // Handles background canvas tints
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
              surfaceTintColor: Colors.transparent, // Prevents Material 3 purple overlay on dark dialogs
            ),
          ),
        
          // Link the MaterialApp mode to the notifier value
          themeMode: currentThemeMode,
          
          // Starts with the Face ID security gate
          home: const SecurityScreen(),
        ); 
      }, 
    ); 
  }
}