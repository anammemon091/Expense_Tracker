import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hng_expense_tracker/main.dart'; 
// Agar aapke paas dashboard screen import ho sake toh:
// import 'package:hng_expense_tracker/screens/dashboard.dart';

void main() {
  testWidgets('Counter value increment test placeholder', (WidgetTester tester) async {
    // Pass a default placeholder widget to satisfy the required homeScreen parameter
    await tester.pumpWidget(const ExpenseTrackerApp(homeScreen: Scaffold(body: Center(child: Text('Test Layout')))));

    // Ya fir agar Dashboard screen imported hai toh:
    // await tester.pumpWidget(const ExpenseTrackerApp(homeScreen: Dashboard()));

    // Aapke baaki test cases yahan chalenge...
  });
}