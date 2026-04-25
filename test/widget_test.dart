import 'package:flutter_test/flutter_test.dart';
import 'package:hng_expense_tracker/main.dart'; // Make sure this matches your project name

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExpenseTrackerApp());

    // Verify that our app starts (looking for the Dashboard title)
    expect(find.text('Expense Tracker'), findsOneWidget);
  });
}