import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Reference our opened Hive box
  final _myBox = Hive.box('transactions_box');
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load data from Hive on startup
  void _loadData() {
    final dynamic data = _myBox.get("TRANSACTION_LIST");
    if (data != null) {
      setState(() {
        // We cast the dynamic list from Hive back to our Transaction model
        _transactions = List<Transaction>.from(
          data.map((item) => Transaction(
                title: item['title'],
                amount: item['amount'],
                date: DateTime.parse(item['date']),
                category: item['category'],
                isExpense: item['isExpense'] ?? true,
              )),
        );
      });
    }
  }

  // Save the current state of the list to Hive
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

  double get _totalBalance {
    double total = 0.0;
    for (var tx in _transactions) {
      tx.isExpense ? total -= tx.amount : total += tx.amount;
    }
    return total;
  }

  void _addNewTransaction(String title, double amount, bool isExpense) {
    setState(() {
      _transactions.add(Transaction(
        title: title,
        amount: amount,
        date: DateTime.now(),
        category: isExpense ? 'Expense' : 'Income',
        isExpense: isExpense,
      ));
    });
    _saveToHive(); // Persist data
  }

  void _deleteTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
    _saveToHive(); // Update persistence
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}), // Manual UI refresh if needed
          )
        ],
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text("No transactions yet!"))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      // Logic to show newest items at the top
                      final actualIndex = _transactions.length - 1 - index;
                      final tx = _transactions[actualIndex];

                      // STEP 2: SWIPE TO DELETE
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

  // ... [Keep _buildBalanceCard and _buildTransactionItem the same as your previous version] ...

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
              const SizedBox(height: 10),
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

                    _addNewTransaction(enteredTitle, enteredAmount, isExpense);
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