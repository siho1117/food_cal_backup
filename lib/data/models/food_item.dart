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
  final int? spoonacularId; // Optional ID from Spoonacular for reference

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

  /// Create a FoodItem from Spoonacular image analysis response
  factory FoodItem.fromSpoonacularAnalysis(
      Map<String, dynamic> data, String mealType) {
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
          calories = nutrition['calories']['value']?.toDouble() ?? 0.0;
        }

        // Extract macronutrients from the nutrients array
        if (nutrition.containsKey('nutrients') &&
            nutrition['nutrients'] is List) {
          for (var nutrient in nutrition['nutrients']) {
            if (nutrient['name'] == 'Protein') {
              proteins = nutrient['amount']?.toDouble() ?? 0.0;
            } else if (nutrient['name'] == 'Carbohydrates') {
              carbs = nutrient['amount']?.toDouble() ?? 0.0;
            } else if (nutrient['name'] == 'Fat') {
              fats = nutrient['amount']?.toDouble() ?? 0.0;
            }
          }
        }
      }

      // Try to extract Spoonacular ID
      if (data.containsKey('id')) {
        spoonacularId = data['id'];
      }

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

  /// Create a FoodItem from Spoonacular ingredient information
  factory FoodItem.fromSpoonacularIngredient(
      Map<String, dynamic> data, String mealType) {
    try {
      double calories = 0.0;
      double proteins = 0.0;
      double carbs = 0.0;
      double fats = 0.0;
      String name = data['name'] ?? 'Unknown Ingredient';
      int? spoonacularId = data['id'];

      // Extract nutrition information if available
      if (data.containsKey('nutrition')) {
        final nutrition = data['nutrition'];

        if (nutrition.containsKey('nutrients') &&
            nutrition['nutrients'] is List) {
          for (var nutrient in nutrition['nutrients']) {
            final nutrientName =
                nutrient['name']?.toString().toLowerCase() ?? '';
            final amount = nutrient['amount']?.toDouble() ?? 0.0;

            if (nutrientName == 'calories') {
              calories = amount;
            } else if (nutrientName == 'protein') {
              proteins = amount;
            } else if (nutrientName == 'carbohydrates') {
              carbs = amount;
            } else if (nutrientName == 'fat') {
              fats = amount;
            }
          }
        }
      }

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
      print('Error creating FoodItem from ingredient: $e');
      return FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Unknown Ingredient',
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
    return {
      'calories': calories * servingSize,
      'proteins': proteins * servingSize,
      'carbs': carbs * servingSize,
      'fats': fats * servingSize,
    };
  }

  /// Get formatted string representation of calories (with serving size applied)
  String getFormattedCalories() {
    return '${(calories * servingSize).round()} cal';
  }

  /// Generate a descriptive string for the food item
  @override
  String toString() {
    return 'FoodItem: $name (${getFormattedCalories()})';
  }
}
