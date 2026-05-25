import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/app_state_manager.dart'; // Import your new global state manager

class CategoryDetailScreen extends StatelessWidget {
  final String category;
  final List<Transaction> allTransactions;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.allTransactions,
  });

  @override
  Widget build(BuildContext context) {
    // Filter transactions for this specific category
    final categoryTransactions = allTransactions
        .where((tx) => tx.category == category)
        .toList()
        .reversed // Show newest first
        .toList();

    double totalSpent = categoryTransactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);

    // Grab the current theme state to handle subtle background containers manually
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('$category Ledger', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary Header (Theme-aware container matching Figma layout styles)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            // Uses true surface colors in dark mode or a subtle tint in light mode
            color: isDark ? const Color(0xFF121212) : Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total $category Spending', 
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600], 
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Dynamic Global Currency for Total Spent
                ValueListenableBuilder<String>(
                  valueListenable: AppStateManager.currencyNotifier,
                  builder: (context, currencySymbol, child) {
                    return Text(
                      '$currencySymbol${totalSpent.toStringAsFixed(2)}', 
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : const Color(0xFF1e3c72),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Transaction List
          Expanded(
            child: categoryTransactions.isEmpty
                ? const Center(child: Text("No transactions in this category"))
                : ListView.builder(
                    itemCount: categoryTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = categoryTransactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.isExpense ? Colors.red[50] : Colors.green[50],
                          child: Icon(
                            tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.isExpense ? Colors.red : Colors.green,
                            size: 18,
                          ),
                        ),
                        subtitle: Text(tx.date.toString().split(' ')[0]),
                        // Dynamic Global Currency for Single Transaction Items
                        trailing: ValueListenableBuilder<String>(
                          valueListenable: AppStateManager.currencyNotifier,
                          builder: (context, currencySymbol, child) {
                            return Text(
                              '${tx.isExpense ? "-" : "+"}$currencySymbol${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: tx.isExpense ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}