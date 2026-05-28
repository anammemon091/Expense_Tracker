import 'package:flutter/material.dart';
import '../models/category_item.dart';
import '../services/app_state_manager.dart';

class AllocationCard extends StatelessWidget {
  final CategoryItem category;
  final double currentSpend;

  const AllocationCard({
    super.key,
    required this.category,
    required this.currentSpend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double percentage = category.monthlyLimit > 0 
        ? (currentSpend / category.monthlyLimit).clamp(0.0, 1.0)
        : 0.0;
        
    final bool isOverBudget = currentSpend > category.monthlyLimit && category.monthlyLimit > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverBudget ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              ValueListenableBuilder<String>(
                valueListenable: AppStateManager.currencyNotifier,
                builder: (context, currency, child) {
                  return Text(
                    "$currency${currentSpend.toStringAsFixed(0)} / $currency${category.monthlyLimit.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isOverBudget ? Colors.redAccent : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar track
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.redAccent : category.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}