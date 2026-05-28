import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_item.dart';
import '../services/app_state_manager.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  // Pre-defined premium colors for selection canvas
  static const List<Color> selectionColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF9E9E9E), // Grey
  ];

  // Pre-defined finance-focused icons
  static const List<IconData> selectionIcons = [
    Icons.home_rounded,
    Icons.directions_bus,
    Icons.restaurant,
    Icons.movie_creation_outlined,
    Icons.shopping_bag_outlined,
    Icons.medical_services_outlined,
    Icons.flight_takeoff,
    Icons.school_outlined,
    Icons.fitness_center,
    Icons.build_outlined,
  ];

  void _showAddCategorySheet(BuildContext context) {
    final nameController = TextEditingController();
    final limitController = TextEditingController();
    Color selectedColor = selectionColors[0];
    IconData selectedIcon = selectionIcons[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor ?? Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Custom Category",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 20),
                    
                    // Name Field
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Category Name",
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: "e.g., Subscriptions, Gym",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Monthly Limit Field
                    TextField(
                      controller: limitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Monthly Budget Limit",
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: "0.00",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixText: "${AppStateManager.currencyNotifier.value} ",
                        prefixStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Color Picker Horizontal Track
                    Text("Select Color", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectionColors.length,
                        itemBuilder: (context, index) {
                          final color = selectionColors[index];
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = color),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 42,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon Picker Grid
                    Text("Select Icon", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: selectionIcons.length,
                        itemBuilder: (context, index) {
                          final icon = selectionIcons[index];
                          final isSelected = selectedIcon == icon;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIcon = icon),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? selectedColor.withValues(alpha: 0.2) 
                                    : (isDark ? Colors.grey[900] : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? Border.all(color: selectedColor, width: 2) : null,
                              ),
                              child: Icon(icon, color: isSelected ? selectedColor : Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          
                          final double parsedLimit = double.tryParse(limitController.text) ?? 0.0;
                          final newCat = CategoryItem(
                            id: const Uuid().v4(),
                            name: nameController.text.trim(),
                            colorValue: selectedColor.value,
                            iconCodePoint: selectedIcon.codePoint,
                            monthlyLimit: parsedLimit,
                          );

                          AppStateManager.addCustomCategory(newCat);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Save Category",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
        title: const Text("Manage Categories", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<CategoryItem>>(
        valueListenable: AppStateManager.categoriesNotifier,
        builder: (context, categories, child) {
          if (categories.isEmpty) {
            return const Center(child: Text("No categories found. Add some!"));
          }
          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                      )
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color),
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                  subtitle: Text(
                    "Limit: ${AppStateManager.currencyNotifier.value}${category.monthlyLimit.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () {
                      // Prevent deleting default fallback items to secure transactions log integrity
                      if (categories.length <= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("You must keep at least one category!")),
                        );
                        return;
                      }
                      AppStateManager.deleteCategory(category.name);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1e3c72),
        onPressed: () => _showAddCategorySheet(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Tag", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}