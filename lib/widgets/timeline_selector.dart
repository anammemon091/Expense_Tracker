import 'package:flutter/material.dart';
import '../services/app_state_manager.dart';

class TimelineSelector extends StatelessWidget {
  const TimelineSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<TimelineFilter>(
      valueListenable: AppStateManager.activeFilterNotifier,
      builder: (context, currentFilter, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: TimelineFilter.values.map((filter) {
              final isSelected = currentFilter == filter;
              String label = 'All Time';
              if (filter == TimelineFilter.week) label = 'This Week';
              if (filter == TimelineFilter.month) label = 'This Month';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => AppStateManager.updateTimelineFilter(filter),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF1e3c72))
                            : (isDark ? const Color(0xFF121212) : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}