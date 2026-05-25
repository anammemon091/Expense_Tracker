import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/app_state_manager.dart'; // Import your global state manager

class SpendingChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const SpendingChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      // Listen to currency changes to redraw chart segment titles reactively
      child: ValueListenableBuilder<String>(
        valueListenable: AppStateManager.currencyNotifier,
        builder: (context, currencySymbol, child) {
          return PieChart(
            PieChartData(
              sectionsSpace: 5,
              centerSpaceRadius: 40,
              sections: _buildSections(currencySymbol),
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildSections(String currencySymbol) {
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    int index = 0;

    return categoryData.entries.map((entry) {
      final isNotEmpty = entry.value > 0;
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        // Replaced hardcoded '$' with dynamic currencySymbol
        title: isNotEmpty ? '${entry.key}\n$currencySymbol${entry.value.toStringAsFixed(0)}' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}