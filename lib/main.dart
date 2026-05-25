import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/security_screen.dart';
import 'services/app_state_manager.dart'; // Import your new global state manager

void main() async {
  // 1. Ensure Flutter bindings are initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Hive for Flutter
    await Hive.initFlutter();

    // 3. Open the "transactions_box" so it's ready when the app loads
    await Hive.openBox('transactions_box');
    
    debugPrint("Hive Initialized Successfully");
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
              surface: Colors.black, // Fixes the background deprecation error
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
            ),
          ),

          // Link the MaterialApp mode to the notifier value
          themeMode: currentThemeMode,
          
          // Starts with the Face ID security gate
          home: const SecurityScreen(),
        ); // <-- Fixed: Properly closing the MaterialApp initialization block
      }, // <-- Fixed: Closing the builder argument block
    ); // <-- Fixed: Closing the ValueListenableBuilder statement
  }
}