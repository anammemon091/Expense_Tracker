import 'package:uuid/uuid.dart'; // Run 'flutter pub add uuid' in terminal

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isExpense;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.isExpense = true,
  }) : id = const Uuid().v4(); // Generates a unique ID automatically
}