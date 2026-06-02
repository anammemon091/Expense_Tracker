import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_item.dart';
import '../models/recurring_blueprint.dart';
import '../services/app_state_manager.dart';

class ManageSubscriptionsScreen extends StatefulWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  State<ManageSubscriptionsScreen> createState() => _ManageSubscriptionsScreenState();
}

class _ManageSubscriptionsScreenState extends State<ManageSubscriptionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedInterval = 'Monthly';
  String? _selectedCategory;
  final List<String> _intervals = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAddSubscriptionModal(BuildContext context, List<CategoryItem> categories) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please create at least one category first.")),
      );
      return;
    }
    
    // Default select first available category if null
    _selectedCategory ??= categories.first.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "New Subscription Rule",
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Subscription / Bill Title",
                        hintText: "e.g., Netflix Premium, Gym Membership",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? "Title is required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        prefixText: "${AppStateManager.currencyNotifier.value} ",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || double.tryParse(value) == null ? "Enter a valid amount" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedInterval,
                            decoration: InputDecoration(
                              labelText: "Billing Cycle",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _intervals.map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => _selectedInterval = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: "Category",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: categories.map((CategoryItem cat) {
                              return DropdownMenuItem<String>(value: cat.name, child: Text(cat.name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final newBlueprint = RecurringBlueprint(
                              id: const Uuid().v4(),
                              title: _titleController.text.trim(),
                              amount: double.parse(_amountController.text.trim()),
                              category: _selectedCategory!,
                              interval: _selectedInterval,
                              startDate: DateTime.now(),
                              lastTriggeredDate: DateTime.now(),
                            );
                            
                            await AppStateManager.addRecurringSubscription(newBlueprint);
                            
                            _titleController.clear();
                            _amountController.clear();
                            
                            // 🛡️ Fix Line 156: Guarded context invocation safely across async gap
                            if (!modalContext.mounted) return;
                            Navigator.pop(modalContext);
                          }
                        },
                        child: const Text("Activate Scheduler", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscription Scheduler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ValueListenableBuilder<List<CategoryItem>>(
        valueListenable: AppStateManager.categoriesNotifier,
        builder: (context, categories, child) {
          return ValueListenableBuilder<List<RecurringBlueprint>>(
            valueListenable: AppStateManager.recurringNotifier,
            builder: (context, subscriptions, child) {
              if (subscriptions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.autorenew_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        "No active dynamic schedules yet",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final item = subscriptions[index];
                  
                  // Match color matching configurations
                  final matchedCat = categories.firstWhere(
                    (c) => c.name.toLowerCase() == item.category.toLowerCase(),
                    orElse: () => CategoryItem(
                      id: '', 
                      name: item.category, 
                      // 🔄 Fix Line 211: Standard dynamic compliance for modern color integer format
                      colorValue: Colors.grey.toARGB32(), 
                      iconCodePoint: Icons.category.codePoint, 
                      monthlyLimit: 0,
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[900]! : Colors.grey[200]!, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: matchedCat.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(matchedCat.icon, color: matchedCat.color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.interval,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Next: ${item.nextBillingDate.day}/${item.nextBillingDate.month}",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ValueListenableBuilder<String>(
                              valueListenable: AppStateManager.currencyNotifier,
                              builder: (context, symbol, child) {
                                return Text(
                                  "$symbol${item.amount.toStringAsFixed(0)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                              onPressed: () => AppStateManager.deleteRecurringSubscription(item.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<List<CategoryItem>>(
        valueListenable: AppStateManager.categoriesNotifier,
        builder: (context, categories, child) {
          return FloatingActionButton.extended(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            onPressed: () => _showAddSubscriptionModal(context, categories),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add Tracker", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}