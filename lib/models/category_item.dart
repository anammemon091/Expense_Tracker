import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category_item.g.dart';

@HiveType(typeId: 1) // Assign typeId 1 to differentiate from Transaction (typeId 0)
class CategoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue; // Stores hex integer (e.g., Colors.blue.value)

  @HiveField(3)
  final int iconCodePoint; // Stores material icon code point for serializing

  @HiveField(4)
  final double monthlyLimit;

  CategoryItem({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.monthlyLimit,
  });

  // Helper getters to convert primitives back to Flutter UI types safely
  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}