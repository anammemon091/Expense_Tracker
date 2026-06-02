import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/category_item.dart';
import '../services/app_state_manager.dart';

class SpendingChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const SpendingChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<List<CategoryItem>>(
        valueListenable: AppStateManager.categoriesNotifier,
        builder: (context, availableCategories, child) {
          return ValueListenableBuilder<String>(
            valueListenable: AppStateManager.currencyNotifier,
            builder: (context, currencySymbol, child) {
              
              final sections = _buildSections(currencySymbol, availableCategories);
              
              if (sections.isEmpty) {
                return const Center(
                  child: Text(
                    "No expense breakdown available",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                  sections: sections,
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    String currencySymbol, 
    List<CategoryItem> availableCategories
  ) {
    final List<Color> fallbackColors = [
      Colors.blue, 
      Colors.green, 
      Colors.orange, 
      Colors.purple, 
      Colors.red
    ];
    int fallbackIndex = 0;

    return categoryData.entries.where((entry) => entry.value > 0).map((entry) {
      
      final matchedCategory = availableCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == entry.key.toLowerCase(),
        orElse: () => CategoryItem(
          id: '',
          name: entry.key,
          colorValue: fallbackColors[fallbackIndex % fallbackColors.length].toARGB32(),
          iconCodePoint: 0,
          monthlyLimit: 0.0, // Fixed the missing required argument
        ),
      );
      
      if (matchedCategory.id.isEmpty) {
        fallbackIndex++;
      }

      return PieChartSectionData(
        color: matchedCategory.color, 
        value: entry.value,
        title: '${entry.key}\n$currencySymbol${entry.value.toStringAsFixed(0)}',
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600, 
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      );
    }).toList();
  }
}