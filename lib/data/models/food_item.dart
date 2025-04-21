// lib/data/models/food_item.dart

/// Model class representing a food item recognized from an image or added manually
class FoodItem {
  final String id;
  final String name;
  final double calories;
  final double proteins;
  final double carbs;
  final double fats;
  final String? imagePath;
  final String mealType; // breakfast, lunch, dinner, snack
  final DateTime timestamp;
  final double servingSize;
  final String servingUnit;
  final int? spoonacularId; // Kept for backward compatibility

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    this.imagePath,
    required this.mealType,
    required this.timestamp,
    required this.servingSize,
    required this.servingUnit,
    this.spoonacularId,
  });

  /// Create a FoodItem from API image analysis response (generic format)
  factory FoodItem.fromApiAnalysis(Map<String, dynamic> data, String mealType) {
    try {
      // Default values if something is missing
      double calories = 0.0;
      double proteins = 0.0;
      double carbs = 0.0;
      double fats = 0.0;
      String name = 'Unknown Food';
      int? spoonacularId;

      // Extract the food name
      if (data.containsKey('category')) {
        name = data['category']['name'] ?? 'Unknown Food';
      }

      // Extract nutritional information
      if (data.containsKey('nutrition')) {
        final nutrition = data['nutrition'];

        // Extract calories
        if (nutrition.containsKey('calories')) {
          if (nutrition['calories'] is num) {
            calories = (nutrition['calories'] as num).toDouble();
          } else if (nutrition['calories'] is Map &&
              nutrition['calories'].containsKey('value')) {
            calories =
                (nutrition['calories']['value'] as num?)?.toDouble() ?? 0.0;
          }
        }

        // Extract macronutrients from the nutrients array
        if (nutrition.containsKey('nutrients') &&
            nutrition['nutrients'] is List) {
          for (var nutrient in nutrition['nutrients']) {
            if (nutrient['name'] == 'Protein' ||
                nutrient['name'] == 'protein') {
              proteins = (nutrient['amount'] as num?)?.toDouble() ?? 0.0;
            } else if (nutrient['name'] == 'Carbohydrates' ||
                nutrient['name'] == 'carbohydrates') {
              carbs = (nutrient['amount'] as num?)?.toDouble() ?? 0.0;
            } else if (nutrient['name'] == 'Fat' || nutrient['name'] == 'fat') {
              fats = (nutrient['amount'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }

        // Fallback: try direct properties if nutrients array didn't work
        if (proteins == 0.0 && nutrition.containsKey('protein')) {
          proteins = _extractNumericValue(nutrition['protein']) ?? 0.0;
        }
        if (carbs == 0.0 && nutrition.containsKey('carbs')) {
          carbs = _extractNumericValue(nutrition['carbs']) ?? 0.0;
        }
        if (fats == 0.0 && nutrition.containsKey('fat')) {
          fats = _extractNumericValue(nutrition['fat']) ?? 0.0;
        }
      }

      // Extra validation - ensure we have at least some nutritional data
      // If all macros are zero but we have calories, estimate macros using standard ratios
      if (proteins == 0.0 && carbs == 0.0 && fats == 0.0 && calories > 0) {
        // Standard ratio - 20% protein, 50% carbs, 30% fat
        proteins = (calories * 0.2) / 4; // 4 calories per gram of protein
        carbs = (calories * 0.5) / 4; // 4 calories per gram of carbs
        fats = (calories * 0.3) / 9; // 9 calories per gram of fat
      }

      // Try to extract API-specific ID if provided
      if (data.containsKey('id')) {
        if (data['id'] is int) {
          spoonacularId = data['id'];
        } else if (data['id'] is String) {
          spoonacularId = int.tryParse(data['id']);
        }
      }

      // Print debug information
      print(
          'Creating FoodItem: name=$name, calories=$calories, proteins=$proteins, carbs=$carbs, fats=$fats');

      return FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        mealType: mealType,
        timestamp: DateTime.now(),
        servingSize: 1.0,
        servingUnit: 'serving',
        spoonacularId: spoonacularId,
      );
    } catch (e) {
      print('Error creating FoodItem from analysis: $e');
      // Return a default food item if parsing fails
      return FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Unknown Food',
        calories: 0.0,
        proteins: 0.0,
        carbs: 0.0,
        fats: 0.0,
        mealType: mealType,
        timestamp: DateTime.now(),
        servingSize: 1.0,
        servingUnit: 'serving',
      );
    }
  }

  /// Helper method to extract numeric values from different formats
  static double? _extractNumericValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('value')) {
      return (value['value'] as num?)?.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'imagePath': imagePath,
      'mealType': mealType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'spoonacularId': spoonacularId,
    };
  }

  /// Create from Map for retrieval from storage
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    // Print debug info for troubleshooting
    print('Loading FoodItem from map: $map');

    return FoodItem(
      id: map['id'],
      name: map['name'],
      calories: map['calories']?.toDouble() ?? 0.0,
      proteins: map['proteins']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fats: map['fats']?.toDouble() ?? 0.0,
      imagePath: map['imagePath'],
      mealType: map['mealType'] ?? 'snack',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      servingSize: map['servingSize']?.toDouble() ?? 1.0,
      servingUnit: map['servingUnit'] ?? 'serving',
      spoonacularId: map['spoonacularId'],
    );
  }

  /// Create a copy of this FoodItem with modified properties
  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? proteins,
    double? carbs,
    double? fats,
    String? imagePath,
    String? mealType,
    DateTime? timestamp,
    double? servingSize,
    String? servingUnit,
    int? spoonacularId,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      imagePath: imagePath ?? this.imagePath,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      spoonacularId: spoonacularId ?? this.spoonacularId,
    );
  }

  /// Calculate adjusted nutritional values based on serving size
  Map<String, double> getNutritionForServing() {
    // Print debug information to check values
    print(
        'Nutrition values before adjustment: calories=$calories, proteins=$proteins, carbs=$carbs, fats=$fats');
    print('Serving size: $servingSize');

    final adjustedCalories = calories * servingSize;
    final adjustedProteins = proteins * servingSize;
    final adjustedCarbs = carbs * servingSize;
    final adjustedFats = fats * servingSize;

    // Print adjusted values
    print(
        'Adjusted values: calories=$adjustedCalories, proteins=$adjustedProteins, carbs=$adjustedCarbs, fats=$adjustedFats');

    return {
      'calories': adjustedCalories,
      'proteins': adjustedProteins,
      'carbs': adjustedCarbs,
      'fats': adjustedFats,
    };
  }

  /// Get formatted string representation of calories (with serving size applied)
  String getFormattedCalories() {
    // Updated to remove decimal places
    return '${(calories * servingSize).round()} cal';
  }

  /// Generate a descriptive string for the food item
  @override
  String toString() {
    return 'FoodItem: $name (${getFormattedCalories()})';
  }
}
