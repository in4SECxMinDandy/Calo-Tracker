// Barcode Service
// Handles product lookup via Open Food Facts API (free, open-source)
// API Documentation: https://openfoodfacts.github.io/openfoodfacts-server/api/
// No API key required - uses free public API
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

class BarcodeService {
  // Open Food Facts API - Free, no API key required
  // Supports over 2.6 million products worldwide
  static const String _openFoodFactsUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  // User agent for API calls (required by Open Food Facts)
  static const String _userAgent = 'CaloTracker/1.0 (Flutter; Android/iOS)';

  /// Lookup product by barcode using Open Food Facts API
  /// This API is free and open-source, no API key needed
  static Future<BarcodeProductResult> lookupProduct(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_openFoodFactsUrl/$barcode.json'),
        headers: {
          'User-Agent': _userAgent,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          return BarcodeProductResult.success(_parseProduct(product, barcode));
        } else {
          return BarcodeProductResult.notFound(
            'Không tìm thấy sản phẩm với mã: $barcode',
          );
        }
      } else {
        return BarcodeProductResult.error(
          'Lỗi kết nối: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return BarcodeProductResult.error('Hết thời gian chờ. Thử lại.');
      }
      return BarcodeProductResult.error('Lỗi: $e');
    }
  }

  /// Parse product data from Open Food Facts API response
  static BarcodeProduct _parseProduct(
    Map<String, dynamic> product,
    String barcode,
  ) {
    // Get product name
    String name = product['product_name'] ?? '';
    if (name.isEmpty) {
      name = product['product_name_en'] ?? '';
    }
    if (name.isEmpty) {
      name = product['product_name_vi'] ?? 'Sản phẩm không tên';
    }

    // Get brand
    final brand = product['brands'] ?? '';

    // Get nutrition per 100g
    final nutriments = product['nutriments'] ?? {};

    final calories = _parseNutrient(nutriments, 'energy-kcal_100g') ??
        _parseNutrient(nutriments, 'energy_100g')?.let((e) => e / 4.184) ??
        0;

    final protein = _parseNutrient(nutriments, 'proteins_100g') ?? 0;
    final carbs = _parseNutrient(nutriments, 'carbohydrates_100g') ?? 0;
    final fat = _parseNutrient(nutriments, 'fat_100g') ?? 0;
    final fiber = _parseNutrient(nutriments, 'fiber_100g');
    final sugar = _parseNutrient(nutriments, 'sugars_100g');
    final sodium = _parseNutrient(nutriments, 'sodium_100g');

    // Get serving size
    final servingSize = product['serving_size'] ?? '';
    final servingQuantity =
        _parseNutrient(product, 'serving_quantity') ?? 100.0;

    // Get image
    final imageUrl = product['image_front_url'] ??
        product['image_url'] ??
        product['image_small_url'];

    // Get nutri-score
    final nutriScore = product['nutriscore_grade']?.toString().toUpperCase();

    // Get categories
    final categories = product['categories'] ?? '';

    return BarcodeProduct(
      barcode: barcode,
      name: name,
      brand: brand,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
      fiberPer100g: fiber,
      sugarPer100g: sugar,
      sodiumPer100g: sodium,
      servingSize: servingSize,
      servingQuantity: servingQuantity,
      imageUrl: imageUrl,
      nutriScore: nutriScore,
      categories: categories,
    );
  }

  /// Helper to parse nutrient values
  static double? _parseNutrient(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Convert BarcodeProduct to Meal
  static Meal productToMeal(BarcodeProduct product, double weightGrams) {
    final scale = weightGrams / 100;

    return Meal(
      dateTime: DateTime.now(),
      foodName: product.displayName,
      weight: weightGrams,
      calories: product.caloriesPer100g * scale,
      protein: product.proteinPer100g * scale,
      carbs: product.carbsPer100g * scale,
      fat: product.fatPer100g * scale,
      source: 'barcode',
    );
  }
}

/// Extension for nullable let
extension NullableExtension<T> on T? {
  R? let<R>(R Function(T) fn) {
    if (this == null) return null;
    return fn(this as T);
  }
}

/// Result of barcode product lookup
class BarcodeProductResult {
  final bool isSuccess;
  final bool isNotFound;
  final BarcodeProduct? product;
  final String? error;

  BarcodeProductResult._({
    required this.isSuccess,
    this.isNotFound = false,
    this.product,
    this.error,
  });

  factory BarcodeProductResult.success(BarcodeProduct product) {
    return BarcodeProductResult._(isSuccess: true, product: product);
  }

  factory BarcodeProductResult.notFound(String message) {
    return BarcodeProductResult._(
      isSuccess: false,
      isNotFound: true,
      error: message,
    );
  }

  factory BarcodeProductResult.error(String message) {
    return BarcodeProductResult._(isSuccess: false, error: message);
  }
}

/// Product data from barcode scan
class BarcodeProduct {
  final String barcode;
  final String name;
  final String brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;
  final String servingSize;
  final double servingQuantity;
  final String? imageUrl;
  final String? nutriScore;
  final String categories;

  BarcodeProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
    required this.servingSize,
    required this.servingQuantity,
    this.imageUrl,
    this.nutriScore,
    required this.categories,
  });

  /// Get display name with brand
  String get displayName {
    if (brand.isNotEmpty) {
      return '$name ($brand)';
    }
    return name;
  }

  /// Check if product has nutrition data
  bool get hasNutritionData {
    return caloriesPer100g > 0 ||
        proteinPer100g > 0 ||
        carbsPer100g > 0 ||
        fatPer100g > 0;
  }

  /// Get nutri-score color
  String get nutriScoreColor {
    switch (nutriScore?.toUpperCase()) {
      case 'A':
        return 'green';
      case 'B':
        return 'lightGreen';
      case 'C':
        return 'yellow';
      case 'D':
        return 'orange';
      case 'E':
        return 'red';
      default:
        return 'grey';
    }
  }
}
