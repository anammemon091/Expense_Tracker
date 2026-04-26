import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../widgets/allocation_card.dart';
import '../widgets/spending_chart.dart';
import 'category_detail_screen.dart';
import 'settings_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _myBox = Hive.box('transactions_box');
  List<Transaction> _transactions = [];
  
  final List<String> _categories = ["Housing", "Transport", "Food", "Entertainment", "Other"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Map<String, double> get _categoryMap {
    Map<String, double> data = {};
    for (var cat in _categories) {
      data[cat] = _getCategoryTotal(cat);
    }
    return data;
  }

  void _loadData() {
    final dynamic data = _myBox.get("TRANSACTION_LIST");
    setState(() {
      if (data != null) {
        _transactions = List<Transaction>.from(
          data.map((item) => Transaction(
                title: item['title'],
                amount: item['amount'],
                date: DateTime.parse(item['date']),
                category: item['category'],
                isExpense: item['isExpense'] ?? true,
              )),
        );
      } else {
        _transactions = [];
      }
    });
  }

  void _saveToHive() {
    final dataToSave = _transactions.map((tx) => {
      'title': tx.title,
      'amount': tx.amount,
      'date': tx.date.toIso8601String(),
      'category': tx.category,
      'isExpense': tx.isExpense,
    }).toList();
    _myBox.put("TRANSACTION_LIST", dataToSave);
  }

  double _getCategoryTotal(String categoryName) {
    return _transactions
        .where((tx) => tx.category == categoryName && tx.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _totalBalance {
    double total = 0.0;
    for (var tx in _transactions) {
      tx.isExpense ? total -= tx.amount : total += tx.amount;
    }
    return total;
  }

  void _addNewTransaction(String title, double amount, bool isExpense, String category) {
    setState(() {
      _transactions.add(Transaction(
        title: title,
        amount: amount,
        date: DateTime.now(),
        category: category,
        isExpense: isExpense,
      ));
    });
    _saveToHive();
  }

  void _deleteTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
    _saveToHive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              // Wait for the result from SettingsScreen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              
              // Refresh data if something was changed or cleared
              if (result == true || result == null) {
                _loadData(); 
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildBalanceCard()),
          
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 20, top: 10),
              child: Text('Spending Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          
          SliverToBoxAdapter(
            child: _transactions.isEmpty 
              ? const SizedBox(height: 100, child: Center(child: Text("Add expenses to see analysis"))) 
              : SpendingChart(categoryData: _categoryMap),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
              child: Text('Allocation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Fetching limits from Hive dynamically
                _buildAllocationWithNavigation(
                  "Housing", 
                  _myBox.get('limit_Housing', defaultValue: 1500.0), 
                  Icons.home_rounded, 
                  Colors.blue
                ),
                _buildAllocationWithNavigation(
                  "Transport", 
                  _myBox.get('limit_Transport', defaultValue: 500.0), 
                  Icons.directions_bus, 
                  Colors.green
                ),
                _buildAllocationWithNavigation(
                  "Food", 
                  _myBox.get('limit_Food', defaultValue: 800.0), 
                  Icons.restaurant, 
                  Colors.orange
                ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
              child: Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final actualIndex = _transactions.length - 1 - index;
                final tx = _transactions[actualIndex];
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) => _deleteTransaction(actualIndex),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: _buildTransactionItem(tx),
                );
              },
              childCount: _transactions.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(context),
        backgroundColor: const Color(0xFF1e3c72),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAllocationWithNavigation(String category, double limit, IconData icon, Color color) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              category: category,
              allTransactions: _transactions,
            ),
          ),
        );
        _loadData(); // Refresh in case transactions were modified
      },
      child: AllocationCard(
        category: category,
        spentAmount: _getCategoryTotal(category),
        totalLimit: limit,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1e3c72), Color(0xFF2a5298)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text(
            '\$${_totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tx.isExpense ? Colors.red[50] : Colors.green[50],
          child: Icon(
            tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: tx.isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tx.category),
        trailing: Text(
          '${tx.isExpense ? "-" : "+"}\$${tx.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: tx.isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    String selectedCategory = _categories[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Add Transaction", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setModalState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              SwitchListTile(
                title: Text(isExpense ? "Expense" : "Income"),
                value: isExpense,
                activeColor: Colors.red,
                onChanged: (val) => setModalState(() => isExpense = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final enteredTitle = titleController.text;
                    final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
                    if (enteredTitle.isEmpty || enteredAmount <= 0) return;

                    _addNewTransaction(enteredTitle, enteredAmount, isExpense, selectedCategory);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1e3c72)),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}