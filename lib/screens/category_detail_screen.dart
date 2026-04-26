import 'package:flutter/material.dart';
import '../models/transaction.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$category Ledger', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Summary Header (Matching Figma style)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total $category Spending', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 8),
                Text('\$${totalSpent.toStringAsFixed(2)}', 
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1e3c72))),
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
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(tx.date.toString().split(' ')[0]),
                        trailing: Text(
                          '${tx.isExpense ? "-" : "+"}\$${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: tx.isExpense ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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