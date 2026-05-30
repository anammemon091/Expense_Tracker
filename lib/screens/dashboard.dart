import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/category_item.dart';
import '../models/recurring_blueprint.dart'; // Import the new RecurringBlueprint model
import '../widgets/allocation_card.dart';
import '../widgets/spending_chart.dart';
import '../widgets/timeline_selector.dart';
import '../services/app_state_manager.dart';
import 'category_detail_screen.dart';
import 'manage_subscriptions_screen.dart'; // Import your new subscription screen
import 'settings_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _myBox = Hive.box('transactions_box');
  List<Transaction> _allTransactions = []; // Raw array reflecting disk state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Generate category chart allocations mapped strictly against the active sorting window dynamically
  Map<String, double> _getCategoryMapForFiltered(
    List<Transaction> filteredList, 
    List<CategoryItem> availableCategories
  ) {
    Map<String, double> data = {};
    for (var cat in availableCategories) {
      data[cat.name] = filteredList
          .where((tx) => tx.category.toLowerCase() == cat.name.toLowerCase() && tx.isExpense)
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
        centerTitle: true,
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
      body: ValueListenableBuilder<List<CategoryItem>>(
        valueListenable: AppStateManager.categoriesNotifier,
        builder: (context, availableCategories, child) {
          return ValueListenableBuilder<TimelineFilter>(
            valueListenable: AppStateManager.activeFilterNotifier,
            builder: (context, currentFilter, child) {
              
              // Pipeline calculations using the unified helper
              final filteredTransactions = filterTransactionsByTimeline(_allTransactions, currentFilter);
              final scopedCategoryMap = _getCategoryMapForFiltered(filteredTransactions, availableCategories);
              final scopedBalance = _calculateFilteredBalance(filteredTransactions);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildBalanceCard(scopedBalance)),
                  
                  // 🔄 New: Smart Subscription & Future Impact Forecast Matrix Card Added Here
                  SliverToBoxAdapter(child: _buildSubscriptionForecastCard()),
                  
                  // Interactive Dashboard Timeline Selector track
                  const SliverToBoxAdapter(child: TimelineSelector()),
                  
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, top: 15),
                      child: Text('Spending Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: filteredTransactions.isEmpty 
                        ? const SizedBox(height: 140, child: Center(child: Text("No data inside this interval frame"))) 
                        : SpendingChart(categoryData: scopedCategoryMap),
                  ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, top: 15, bottom: 10),
                      child: Text('Allocation Limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  // Dynamic Allocation Progress Track mapping directly from Hive states
                  SliverToBoxAdapter(
                    child: availableCategories.isEmpty
                        ? const Center(child: Text("No categories found. Configure in Settings."))
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: availableCategories.map((category) {
                                final double categoryTotalSpend = scopedCategoryMap[category.name] ?? 0.0;

                                return GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CategoryDetailScreen(
                                          category: category.name,
                                          allTransactions: _allTransactions,
                                        ),
                                      ),
                                    );
                                    _loadData(); 
                                  },
                                  child: AllocationCard(
                                    category: category,
                                    currentSpend: categoryTotalSpend,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                      child: Text('Ledger Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                key: Key(tx.date.toIso8601String() + tx.title + tx.amount.toString()),
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

  Widget _buildBalanceCard(double balanceAmount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1e3c72), Color(0xFF2a5298)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          ValueListenableBuilder<String>(
            valueListenable: AppStateManager.currencyNotifier,
            builder: (context, currencySymbol, child) {
              return Text(
                '$currencySymbol${balanceAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔄 New Helper Widget: Smart 30-Day Subscription Impact Indicator Card
  Widget _buildSubscriptionForecastCard() {
    return ValueListenableBuilder<List<RecurringBlueprint>>(
      valueListenable: AppStateManager.recurringNotifier,
      builder: (context, subscriptions, child) {
        double upcoming30DaysTotal = 0;
        final DateTime horizonDate = DateTime.now().add(const Duration(days: 30));

        for (var sub in subscriptions) {
          if (sub.nextBillingDate.isBefore(horizonDate)) {
            upcoming30DaysTotal += sub.amount;
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageSubscriptionsScreen()),
            );
            // Refresh data arrays to catch any processed items on popping back
            _loadData();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[900]! : Colors.amber.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      subscriptions.isEmpty ? Icons.autorenew_rounded : Icons.speed_rounded, 
                      color: subscriptions.isEmpty ? Colors.grey : Colors.amber, 
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscriptions.isEmpty ? "Subscription Scheduler" : "30-Day Subscription Forecast",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          subscriptions.isEmpty 
                              ? "Tap to configure recurring expense items" 
                              : "Automated tracks scheduled to deploy soon",
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
                if (subscriptions.isNotEmpty && upcoming30DaysTotal > 0)
                  ValueListenableBuilder<String>(
                    valueListenable: AppStateManager.currencyNotifier,
                    builder: (context, symbol, child) {
                      return Text(
                        "-$symbol${upcoming30DaysTotal.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                      );
                    },
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ],
            ),
          ),
        );
      },
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
    
    final currentCategories = AppStateManager.categoriesNotifier.value;
    String? selectedCategory = currentCategories.isNotEmpty ? currentCategories[0].name : null;

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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  );
                },
              ),
              const SizedBox(height: 15),
              
              if (currentCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: currentCategories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.name,
                      child: Row(
                        children: [
                          Icon(cat.icon, color: cat.color, size: 18),
                          const SizedBox(width: 8),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedCategory = val),
                  decoration: const InputDecoration(labelText: 'Category'),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("Please define categories in settings first.", style: TextStyle(color: Colors.red)),
                ),
                
              SwitchListTile(
                title: Text(isExpense ? "Expense" : "Income"),
                value: isExpense,
                activeThumbColor: Colors.red, 
                onChanged: (val) => setModalState(() => isExpense = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final enteredTitle = titleController.text.trim();
                    final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
                    if (enteredTitle.isEmpty || enteredAmount <= 0 || selectedCategory == null) return;

                    _addNewTransaction(enteredTitle, enteredAmount, isExpense, selectedCategory!);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1e3c72),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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