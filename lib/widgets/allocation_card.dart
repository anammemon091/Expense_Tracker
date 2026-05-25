import 'package:flutter/material.dart';
import '../services/app_state_manager.dart'; // Import your new global state manager

class AllocationCard extends StatelessWidget {
  final String category;
  final double spentAmount;
  final double totalLimit;
  final IconData icon;
  final Color color;

  const AllocationCard({
    super.key,
    required this.category,
    required this.spentAmount,
    required this.totalLimit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = (spentAmount / totalLimit).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Switches background dynamically to premium pitch dark or crisp white
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              // Dynamic Currency System Injection
              ValueListenableBuilder<String>(
                valueListenable: AppStateManager.currencyNotifier,
                builder: (context, currencySymbol, child) {
                  return Text(
                    "$currencySymbol${spentAmount.toStringAsFixed(0)} / $currencySymbol${totalLimit.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600], 
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          // CUSTOM PROGRESS BAR
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  // Dark tracking track bar backgrounds 
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  height: 8,
                  width: constraints.maxWidth * percentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}