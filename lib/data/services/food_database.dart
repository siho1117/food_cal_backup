// lib/data/services/food_database.dart

/// A database containing common food items with nutritional information
/// This serves as a fallback data source when API services are unavailable
class FoodDatabase {
  // Singleton pattern
  static final FoodDatabase _instance = FoodDatabase._internal();
  factory FoodDatabase() => _instance;
  FoodDatabase._internal();

  /// Get the full database of food items with nutritional information
  Map<String, Map<String, dynamic>> get database => _foodDatabase;

  /// Find a food item by name (exact or partial match)
  Map<String, dynamic>? findFood(String name) {
    final lowerName = name.toLowerCase();

    // Try exact match first
    if (_foodDatabase.containsKey(lowerName)) {
      return {
        'name':
            lowerName.substring(0, 1).toUpperCase() + lowerName.substring(1),
        ..._foodDatabase[lowerName]!
      };
    }

    // Then try to find food names that contain the query
    for (final entry in _foodDatabase.entries) {
      if (entry.key.contains(lowerName) || lowerName.contains(entry.key)) {
        return {
          'name':
              entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1),
          ...entry.value
        };
      }
    }

    // Check keywords for partial matches
    for (final entry in _foodDatabase.entries) {
      final keywords = entry.value['keywords'] as List<String>;
      for (final keyword in keywords) {
        if (keyword.contains(lowerName) || lowerName.contains(keyword)) {
          return {
            'name': entry.key.substring(0, 1).toUpperCase() +
                entry.key.substring(1),
            ...entry.value
          };
        }
      }
    }

    // No match found
    return null;
  }

  /// Search the database for foods matching the query
  List<Map<String, dynamic>> searchFoods(String query) {
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();

    // First look for direct matches in food names
    for (final entry in _foodDatabase.entries) {
      if (entry.key.contains(lowerQuery)) {
        results.add({
          'id': entry.key,
          'name':
              entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1),
          ...entry.value
        });
      }
    }

    // Then check keywords if we don't have enough results
    if (results.length < 5) {
      for (final entry in _foodDatabase.entries) {
        // Skip if already added
        if (results.any((result) => result['id'] == entry.key)) {
          continue;
        }

        // Check keywords
        final keywords = entry.value['keywords'] as List<String>;
        if (keywords.any((keyword) =>
            keyword.contains(lowerQuery) || lowerQuery.contains(keyword))) {
          results.add({
            'id': entry.key,
            'name': entry.key.substring(0, 1).toUpperCase() +
                entry.key.substring(1),
            ...entry.value
          });
        }
      }
    }

    return results;
  }

  /// Get default popular foods as suggestions when no matches found
  List<Map<String, dynamic>> getDefaultSuggestions() {
    final popularFoods = ['apple', 'banana', 'chicken'];
    final results = <Map<String, dynamic>>[];

    for (final food in popularFoods) {
      if (_foodDatabase.containsKey(food)) {
        results.add({
          'id': food,
          'name':
              '${food.substring(0, 1).toUpperCase() + food.substring(1)} (suggested)',
          ..._foodDatabase[food]!
        });
      }
    }

    return results;
  }

  /// Get a default unknown food item
  Map<String, dynamic> getDefaultFood() {
    return {
      'name': 'Unknown Food',
      'calories': 250.0,
      'protein': 10.0,
      'carbs': 30.0,
      'fat': 12.0,
      'keywords': ['unknown']
    };
  }

  /// The in-memory food database
  final Map<String, Map<String, dynamic>> _foodDatabase = {
    "apple": {
      "keywords": ["apple", "fruit", "red fruit", "green fruit"],
      "calories": 95.0,
      "protein": 0.5,
      "carbs": 25.0,
      "fat": 0.3
    },
    "banana": {
      "keywords": ["banana", "fruit", "yellow fruit"],
      "calories": 105.0,
      "protein": 1.3,
      "carbs": 27.0,
      "fat": 0.4
    },
    "orange": {
      "keywords": ["orange", "fruit", "citrus"],
      "calories": 65.0,
      "protein": 1.3,
      "carbs": 16.0,
      "fat": 0.2
    },
    "pizza": {
      "keywords": [
        "pizza",
        "italian",
        "cheese",
        "tomato",
        "dough",
        "fast food"
      ],
      "calories": 285.0,
      "protein": 12.0,
      "carbs": 39.0,
      "fat": 10.0
    },
    "burger": {
      "keywords": [
        "burger",
        "hamburger",
        "beef",
        "sandwich",
        "fast food",
        "patty"
      ],
      "calories": 350.0,
      "protein": 20.0,
      "carbs": 33.0,
      "fat": 15.0
    },
    "sandwich": {
      "keywords": ["sandwich", "bread", "lunch", "sliced bread"],
      "calories": 300.0,
      "protein": 15.0,
      "carbs": 35.0,
      "fat": 10.0
    },
    "salad": {
      "keywords": ["salad", "vegetables", "lettuce", "greens", "healthy"],
      "calories": 150.0,
      "protein": 3.0,
      "carbs": 10.0,
      "fat": 10.0
    },
    "pasta": {
      "keywords": ["pasta", "noodle", "spaghetti", "italian", "carb"],
      "calories": 200.0,
      "protein": 7.0,
      "carbs": 40.0,
      "fat": 1.0
    },
    "rice": {
      "keywords": ["rice", "grain", "white rice", "brown rice", "carb"],
      "calories": 130.0,
      "protein": 2.7,
      "carbs": 28.0,
      "fat": 0.3
    },
    "chicken": {
      "keywords": ["chicken", "meat", "poultry", "protein", "grilled"],
      "calories": 165.0,
      "protein": 31.0,
      "carbs": 0.0,
      "fat": 3.6
    },
    "fish": {
      "keywords": ["fish", "seafood", "protein", "salmon", "tuna"],
      "calories": 180.0,
      "protein": 25.0,
      "carbs": 0.0,
      "fat": 8.0
    },
    "steak": {
      "keywords": ["steak", "beef", "meat", "protein", "red meat"],
      "calories": 270.0,
      "protein": 29.0,
      "carbs": 0.0,
      "fat": 17.0
    },
    "broccoli": {
      "keywords": ["broccoli", "vegetable", "green", "healthy"],
      "calories": 55.0,
      "protein": 3.7,
      "carbs": 11.2,
      "fat": 0.6
    },
    "cake": {
      "keywords": ["cake", "dessert", "sweet", "bakery", "birthday"],
      "calories": 350.0,
      "protein": 5.0,
      "carbs": 50.0,
      "fat": 15.0
    },
    "ice cream": {
      "keywords": ["ice cream", "dessert", "frozen", "sweet", "dairy"],
      "calories": 270.0,
      "protein": 4.0,
      "carbs": 30.0,
      "fat": 15.0
    },
    "chocolate": {
      "keywords": ["chocolate", "dessert", "sweet", "candy", "cocoa"],
      "calories": 550.0,
      "protein": 8.0,
      "carbs": 55.0,
      "fat": 32.0
    }
  };
}
