import 'package:hive/hive.dart';

part 'recurring_blueprint.g.dart';

@HiveType(typeId: 2) // Unique typeId for Hive adapter tracking
class RecurringBlueprint extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String interval; // 'Daily', 'Weekly', 'Monthly', 'Yearly'

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  DateTime lastTriggeredDate;

  @HiveField(7)
  final bool isExpense;

  RecurringBlueprint({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.interval,
    required this.startDate,
    required this.lastTriggeredDate,
    this.isExpense = true,
  });

  // Business logic parameter configuration evaluating next billing milestone
  DateTime get nextBillingDate {
    switch (interval) {
      case 'Daily':
        return lastTriggeredDate.add(const Duration(days: 1));
      case 'Weekly':
        return lastTriggeredDate.add(const Duration(days: 7));
      case 'Monthly':
        // Safe standard approach for monthly offsets
        return DateTime(lastTriggeredDate.year, lastTriggeredDate.month + 1, lastTriggeredDate.day);
      case 'Yearly':
        return DateTime(lastTriggeredDate.year + 1, lastTriggeredDate.month, lastTriggeredDate.day);
      default:
        return lastTriggeredDate;
    }
  }
}