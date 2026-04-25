import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Add this import
import 'screens/security_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Hive for Flutter
    await Hive.initFlutter();

    // 3. Open the "transactions_box" so it's ready when the Dashboard loads
    // This name must match exactly what you use in Dashboard.dart
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
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1e3c72), // Matches your Security Screen theme
        ),
        useMaterial3: true,
      ),
      // Starts with Face ID for security
      home: const SecurityScreen(),
    );
  }
}