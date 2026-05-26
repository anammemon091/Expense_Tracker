import 'package:uuid/uuid.dart';
import '../services/app_state_manager.dart';
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
// Helper function to sort incoming transactions based on selection parameters
List<Transaction> filterTransactionsByTimeline(List<Transaction> transactions, TimelineFilter filter) {
  final now = DateTime.now();
  
  switch (filter) {
    case TimelineFilter.week:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      // Truncate time parameters to ensure accurate calendar days matching
      final cleanStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return transactions.where((tx) => tx.date.isAfter(cleanStart) || tx.date.isAtSameMomentAs(cleanStart)).toList();
      
    case TimelineFilter.month:
      final cleanStart = DateTime(now.year, now.month, 1);
      return transactions.where((tx) => tx.date.isAfter(cleanStart) || tx.date.isAtSameMomentAs(cleanStart)).toList();
      
    case TimelineFilter.allTime:
    default:
      return transactions;
  }
}