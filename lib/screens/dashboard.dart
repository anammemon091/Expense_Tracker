import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../widgets/allocation_card.dart';
import '../widgets/spending_chart.dart';
import '../widgets/timeline_selector.dart';
import '../services/app_state_manager.dart';
import 'category_detail_screen.dart';
import 'settings_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _myBox = Hive.box('transactions_box');
  List<Transaction> _allTransactions = []; // Raw array reflecting disk state
  
  final List<String> _categories = ["Housing", "Transport", "Food", "Entertainment", "Other"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Generate category chart allocations mapped strictly against the active sorting window
  Map<String, double> _getCategoryMapForFiltered(List<Transaction> filteredList) {
    Map<String, double> data = {};
    for (var cat in _categories) {
      data[cat] = filteredList
          .where((tx) => tx.category == cat && tx.isExpense)
          .fold(0.0, (sum, item) => sum + item.amount);
    }
    return data;
  }

  void _loadData() {
    final dynamic data = _myBox.get("TRANSACTION_LIST");
    setState(() {
      if (data != null) {
        _allTransactions = List<Transaction>.from(
          data.map((item) => Transaction(
                title: item['title'],
                amount: item['amount'],
                date: DateTime.parse(item['date']),
                category: item['category'],
                isExpense: item['isExpense'] ?? true,
              )),
        );
      } else {
        _allTransactions = [];
      }
    });
  }

  void _saveToHive() {
    final dataToSave = _allTransactions.map((tx) => {
      'title': tx.title,
      'amount': tx.amount,
      'date': tx.date.toIso8601String(),
      'category': tx.category,
      'isExpense': tx.isExpense,
    }).toList();
    _myBox.put("TRANSACTION_LIST", dataToSave);
  }

  // Calculate dynamic balance aggregates for the scoped timeline view frame
  double _calculateFilteredBalance(List<Transaction> filteredList) {
    double total = 0.0;
    for (var tx in filteredList) {
      tx.isExpense ? total -= tx.amount : total += tx.amount;
    }
    return total;
  }

  void _addNewTransaction(String title, double amount, bool isExpense, String category) {
    setState(() {
      _allTransactions.add(Transaction(
        title: title,
        amount: amount,
        date: DateTime.now(),
        category: category,
        isExpense: isExpense,
      ));
    });
    _saveToHive();
  }

  void _deleteTransaction(Transaction targetTx) {
    setState(() {
      _allTransactions.remove(targetTx);
    });
    _saveToHive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              
              if (result == true || result == null) {
                _loadData(); 
              }
            },
          ),
        ],
      ),
      // Reactive binding layer feeding sorted timelines out down through the layout builder
      body: ValueListenableBuilder<TimelineFilter>(
        valueListenable: AppStateManager.activeFilterNotifier,
        builder: (context, currentFilter, child) {
          // Process calculations using the model helper from Step 2
          final filteredTransactions = filterTransactionsByTimeline(_allTransactions, currentFilter);
          final scopedCategoryMap = _getCategoryMapForFiltered(filteredTransactions);
          final scopedBalance = _calculateFilteredBalance(filteredTransactions);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildBalanceCard(scopedBalance)),
              
              // Segment Track Added: Interactive Dashboard Filter track
              const SliverToBoxAdapter(child: TimelineSelector()),
              
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 20, top: 15),
                  child: Text('Spending Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              
              SliverToBoxAdapter(
                child: filteredTransactions.isEmpty 
                  ? const SizedBox(height: 140, child: Center(child: Text("No data inside this interval frame"))) 
                  : SpendingChart(categoryData: scopedCategoryMap),
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
                    _buildAllocationWithNavigation(
                      "Housing", 
                      _myBox.get('limit_Housing', defaultValue: 1500.0), 
                      Icons.home_rounded, 
                      Colors.blue,
                      scopedCategoryMap["Housing"] ?? 0.0
                    ),
                    _buildAllocationWithNavigation(
                      "Transport", 
                      _myBox.get('limit_Transport', defaultValue: 500.0), 
                      Icons.directions_bus, 
                      Colors.green,
                      scopedCategoryMap["Transport"] ?? 0.0
                    ),
                    _buildAllocationWithNavigation(
                      "Food", 
                      _myBox.get('limit_Food', defaultValue: 800.0), 
                      Icons.restaurant, 
                      Colors.orange,
                      scopedCategoryMap["Food"] ?? 0.0
                    ),
                  ],
                ),
              ),
              
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                  child: Text('Interval Ledger Records', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              
              filteredTransactions.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: Text("Empty stream timeline frame")),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Render items in clean reversed chronological order (newest on top)
                          final actualIndex = filteredTransactions.length - 1 - index;
                          final tx = filteredTransactions[actualIndex];
                          
                          return Dismissible(
                            key: Key(tx.date.toIso8601String() + tx.title),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) => _deleteTransaction(tx),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: _buildTransactionItem(tx),
                          );
                        },
                        childCount: filteredTransactions.length,
                      ),
                    ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(context),
        backgroundColor: const Color(0xFF1e3c72),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAllocationWithNavigation(String category, double limit, IconData icon, Color color, double categorySpent) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              category: category,
              allTransactions: _allTransactions,
            ),
          ),
        );
        _loadData(); 
      },
      child: AllocationCard(
        category: category,
        spentAmount: categorySpent, // Dynamic contextual parameter value updates
        totalLimit: limit,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _buildBalanceCard(double balanceAmount) {
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
          const Text('Interval Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          ValueListenableBuilder<String>(
            valueListenable: AppStateManager.currencyNotifier,
            builder: (context, currencySymbol, child) {
              return Text(
                '$currencySymbol${balanceAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              );
            },
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
        trailing: ValueListenableBuilder<String>(
          valueListenable: AppStateManager.currencyNotifier,
          builder: (context, currencySymbol, child) {
            return Text(
              '${tx.isExpense ? "-" : "+"}$currencySymbol${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: tx.isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            );
          },
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
              ValueListenableBuilder<String>(
                valueListenable: AppStateManager.currencyNotifier,
                builder: (context, currencySymbol, child) {
                  return TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '$currencySymbol ',
                    ),
                    keyboardType: TextInputType.number,
                  );
                },
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