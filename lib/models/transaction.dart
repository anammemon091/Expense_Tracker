import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/app_state_manager.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0) // Assign typeId 0 for transaction entities
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final bool isExpense;

  Transaction({
    String? id, // Allows Hive to pass back the original saved ID on deserialization
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.isExpense = true,
  }) : id = id ?? const Uuid().v4(); // Generates a unique ID *only* if it's a brand new entry
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
      return transactions; // Clean exit without an unreachable default statement blocking compilation
  }
}