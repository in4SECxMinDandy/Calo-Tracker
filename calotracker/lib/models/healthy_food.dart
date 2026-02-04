// Healthy Food Model
// Data model for healthy food items with nutrition info
import 'package:flutter/material.dart';

/// Category của đồ ăn healthy
enum FoodCategory {
  protein,
  carbs,
  vegetables,
  fruits,
  dairy,
  nuts,
  beverages;

  String get label {
    switch (this) {
      case FoodCategory.protein:
        return 'Protein';
      case FoodCategory.carbs:
        return 'Tinh bột';
      case FoodCategory.vegetables:
        return 'Rau củ';
      case FoodCategory.fruits:
        return 'Trái cây';
      case FoodCategory.dairy:
        return 'Sữa';
      case FoodCategory.nuts:
        return 'Hạt';
      case FoodCategory.beverages:
        return 'Đồ uống';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodCategory.protein:
        return Icons.egg_alt;
      case FoodCategory.carbs:
        return Icons.breakfast_dining;
      case FoodCategory.vegetables:
        return Icons.eco;
      case FoodCategory.fruits:
        return Icons.apple;
      case FoodCategory.dairy:
        return Icons.local_drink;
      case FoodCategory.nuts:
        return Icons.scatter_plot;
      case FoodCategory.beverages:
        return Icons.water_drop;
    }
  }

  Color get color {
    switch (this) {
      case FoodCategory.protein:
        return const Color(0xFFE53935);
      case FoodCategory.carbs:
        return const Color(0xFFFF9800);
      case FoodCategory.vegetables:
        return const Color(0xFF4CAF50);
      case FoodCategory.fruits:
        return const Color(0xFF9C27B0);
      case FoodCategory.dairy:
        return const Color(0xFF2196F3);
      case FoodCategory.nuts:
        return const Color(0xFF795548);
      case FoodCategory.beverages:
        return const Color(0xFF00BCD4);
    }
  }
}

/// Model cho một thực phẩm healthy
class HealthyFood {
  final String id;
  final String name;
  final String description;
  final FoodCategory category;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final String benefits; // Lợi ích chính
  final String imageUrl;
  final List<String> tips; // Mẹo sử dụng

  const HealthyFood({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0,
    required this.benefits,
    this.imageUrl = '',
    this.tips = const [],
  });

  String get macrosFormatted =>
      'P: ${proteinPer100g}g | C: ${carbsPer100g}g | F: ${fatPer100g}g';
}
