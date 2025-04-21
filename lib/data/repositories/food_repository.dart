// lib/data/repositories/food_repository.dart
import 'dart:io';
import 'dart:async';
import '../models/food_item.dart';
import '../services/api_service.dart';
import '../storage/local_storage.dart';

/// Repository for managing food data from API and local storage
/// Acts as a single access point for all food-related operations
class FoodRepository {
  final FoodApiService _apiService = FoodApiService();
  final LocalStorage _storage = LocalStorage();

  // Storage keys
  static const String _foodEntriesKey = 'food_entries';
  static const String _tempImageFolderKey = 'food_images';
  static const String _recentSearchesKey = 'recent_food_searches';
  static const String _favoriteFoodsKey = 'favorite_foods';

  // Maximum number of recent searches to store
  static const int _maxRecentSearches = 10;

  /// Recognize food from an image and return results
  /// Takes an image file and meal type (breakfast, lunch, dinner, snack)
  /// Returns a list of recognized food items
  Future<List<FoodItem>> recognizeFood(File imageFile, String mealType) async {
    try {
      // Call the API to analyze the image
      final analysisResult = await _apiService.analyzeImage(imageFile);

      // Save the image file for reference
      final savedImagePath = await _saveImageFile(imageFile);

      // Process the results
      final List<FoodItem> recognizedItems = [];

      // Process response based on structure
      if (analysisResult.containsKey('category')) {
        // Single food item recognized (typical case)
        final item = FoodItem.fromApiAnalysis(analysisResult, mealType)
            .copyWith(imagePath: savedImagePath);
        recognizedItems.add(item);
      } else if (analysisResult.containsKey('annotations') &&
          analysisResult['annotations'] is List &&
          (analysisResult['annotations'] as List).isNotEmpty) {
        // Multiple food items recognized
        for (var annotation in analysisResult['annotations']) {
          try {
            if (annotation.containsKey('name') && annotation['name'] != null) {
              // Get detailed food information using the name
              final foodInfo =
                  await _apiService.getFoodInformation(annotation['name']);

              // Create food item with nutrition details
              final item = FoodItem(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    '_${annotation['name']}',
                name: annotation['name'] ?? 'Unknown Food',
                calories: _extractNutrientValue(foodInfo, 'calories') ?? 0.0,
                proteins: _extractNutrientValue(foodInfo, 'protein') ?? 0.0,
                carbs: _extractNutrientValue(foodInfo, 'carbs') ?? 0.0,
                fats: _extractNutrientValue(foodInfo, 'fat') ?? 0.0,
                imagePath: savedImagePath,
                mealType: mealType,
                timestamp: DateTime.now(),
                servingSize: 1.0,
                servingUnit: 'serving',
                spoonacularId: null,
              );

              recognizedItems.add(item);
            } else {
              // Add with limited information if name is missing
              final item = FoodItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: annotation['description'] ?? 'Unknown Food',
                // Try to get nutrition info directly from annotation if available
                calories:
                    annotation['nutrition']?['calories']?.toDouble() ?? 0.0,
                proteins:
                    annotation['nutrition']?['protein']?.toDouble() ?? 0.0,
                carbs: annotation['nutrition']?['carbs']?.toDouble() ?? 0.0,
                fats: annotation['nutrition']?['fat']?.toDouble() ?? 0.0,
                imagePath: savedImagePath,
                mealType: mealType,
                timestamp: DateTime.now(),
                servingSize: 1.0,
                servingUnit: 'serving',
              );

              recognizedItems.add(item);
            }
          } catch (e) {
            // Add with limited information if detailed call fails
            final item = FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: annotation['description'] ?? 'Unknown Food',
              calories: 0.0,
              proteins: 0.0,
              carbs: 0.0,
              fats: 0.0,
              imagePath: savedImagePath,
              mealType: mealType,
              timestamp: DateTime.now(),
              servingSize: 1.0,
              servingUnit: 'serving',
            );

            recognizedItems.add(item);
          }
        }
      } else if (analysisResult.containsKey('nutrition') &&
          analysisResult.containsKey('name')) {
        // Direct nutritional information with name
        final calories =
            _extractNutrientValue(analysisResult, 'calories') ?? 0.0;
        final proteins =
            _extractNutrientValue(analysisResult, 'protein') ?? 0.0;
        final carbs = _extractNutrientValue(analysisResult, 'carbs') ?? 0.0;
        final fats = _extractNutrientValue(analysisResult, 'fat') ?? 0.0;

        final item = FoodItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: analysisResult['name'] ?? 'Unknown Food',
          calories: calories,
          proteins: proteins,
          carbs: carbs,
          fats: fats,
          imagePath: savedImagePath,
          mealType: mealType,
          timestamp: DateTime.now(),
          servingSize: 1.0,
          servingUnit: 'serving',
        );

        recognizedItems.add(item);
      } else {
        // If we have no structured information but some text, create a generic food item
        if (analysisResult.containsKey('text') &&
            analysisResult['text'] is String) {
          // Try to extract food name from text
          final foodName = analysisResult['text'];

          if (foodName.isNotEmpty) {
            final item = FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: foodName,
              calories: 0.0, // No nutrition info available
              proteins: 0.0,
              carbs: 0.0,
              fats: 0.0,
              imagePath: savedImagePath,
              mealType: mealType,
              timestamp: DateTime.now(),
              servingSize: 1.0,
              servingUnit: 'serving',
            );

            recognizedItems.add(item);
            return recognizedItems;
          }
        }

        // Fallback if no food is recognized or format is unexpected
        throw Exception(
            'No food recognized in the image or unsupported response format');
      }

      return recognizedItems;
    } catch (e) {
      throw Exception('Failed to recognize food: $e');
    }
  }

  /// Helper method to extract nutrient values from API response
  double? _extractNutrientValue(
      Map<String, dynamic> data, String nutrientName) {
    try {
      // Direct access if the property exists at top level
      if (data.containsKey(nutrientName)) {
        final value = data[nutrientName];
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          return double.tryParse(value);
        } else if (value is Map && value.containsKey('value')) {
          final numValue = value['value'];
          return numValue is num ? numValue.toDouble() : null;
        }
      }

      if (data.containsKey('nutrition')) {
        final nutrition = data['nutrition'];

        // Direct property access format
        if (nutrition.containsKey(nutrientName)) {
          final value = nutrition[nutrientName];
          if (value is num) {
            return value.toDouble();
          } else if (value is String) {
            return double.tryParse(value);
          } else if (value is Map && value.containsKey('value')) {
            final numValue = value['value'];
            return numValue is num ? numValue.toDouble() : null;
          }
        }

        // Nutrients array format
        if (nutrition.containsKey('nutrients') &&
            nutrition['nutrients'] is List) {
          for (var nutrient in nutrition['nutrients']) {
            // Case-insensitive comparison
            final name = nutrient['name']?.toString().toLowerCase() ?? '';
            if (name == nutrientName.toLowerCase()) {
              final amount = nutrient['amount'];
              return amount is num ? amount.toDouble() : null;
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save the food image file to local storage
  Future<String?> _saveImageFile(File imageFile) async {
    try {
      // Get the app's temporary directory
      final tempDir = await _storage.getTemporaryDirectory();

      // Create a folder for food images if it doesn't exist
      final foodImagesDir = Directory('${tempDir.path}/$_tempImageFolderKey');
      if (!await foodImagesDir.exists()) {
        await foodImagesDir.create(recursive: true);
      }

      // Generate a unique filename based on timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${foodImagesDir.path}/food_${timestamp}.jpg';

      // Copy the file to our app's storage
      final savedImage = await imageFile.copy(newPath);

      return savedImage.path;
    } catch (e) {
      return null;
    }
  }

  /// Save a food entry to local storage
  Future<bool> saveFoodEntry(FoodItem item) async {
    try {
      final entries = await getFoodEntries(item.timestamp);
      entries.add(item);
      return _saveFoodEntries(entries);
    } catch (e) {
      return false;
    }
  }

  /// Save multiple food entries at once
  Future<bool> saveFoodEntries(List<FoodItem> items) async {
    try {
      if (items.isEmpty) return true;

      // Group entries by date to ensure we don't overwrite entries from other dates
      final Map<String, List<FoodItem>> entriesByDate = {};

      for (final item in items) {
        final dateKey = _getDateKey(item.timestamp);
        if (!entriesByDate.containsKey(dateKey)) {
          entriesByDate[dateKey] = await _getFoodEntriesForDate(item.timestamp);
        }
        entriesByDate[dateKey]!.add(item);
      }

      // Save entries for each date
      bool allSaved = true;
      for (final date in entriesByDate.keys) {
        final success =
            await _saveFoodEntriesForDate(entriesByDate[date]!, date);
        if (!success) allSaved = false;
      }

      return allSaved;
    } catch (e) {
      return false;
    }
  }

  /// Get all food entries for a specific date
  Future<List<FoodItem>> getFoodEntries(DateTime date) async {
    try {
      final entries = await _getFoodEntriesForDate(date);
      return entries;
    } catch (e) {
      return [];
    }
  }

  /// Get food entries for a specific date (helper method)
  Future<List<FoodItem>> _getFoodEntriesForDate(DateTime date) async {
    final dateKey = _getDateKey(date);
    final key = '${_foodEntriesKey}_$dateKey';

    final entriesList = await _storage.getObjectList(key);

    if (entriesList == null || entriesList.isEmpty) return [];

    return entriesList.map((map) => FoodItem.fromMap(map)).toList();
  }

  /// Save food entries for a specific date (helper method)
  Future<bool> _saveFoodEntriesForDate(
      List<FoodItem> entries, String dateKey) async {
    try {
      final key = '${_foodEntriesKey}_$dateKey';
      final entriesMaps = entries.map((entry) => entry.toMap()).toList();

      return await _storage.setObjectList(key, entriesMaps);
    } catch (e) {
      return false;
    }
  }

  /// Get date key string from DateTime (YYYY-MM-DD format)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Helper method for saving food entries (legacy method)
  Future<bool> _saveFoodEntries(List<FoodItem> entries) async {
    if (entries.isEmpty) return true;

    final dateKey = _getDateKey(entries.first.timestamp);
    return _saveFoodEntriesForDate(entries, dateKey);
  }

  /// Update an existing food entry
  Future<bool> updateFoodEntry(FoodItem item) async {
    try {
      final dateKey = _getDateKey(item.timestamp);
      final entries = await _getFoodEntriesForDate(item.timestamp);

      final index = entries.indexWhere((entry) => entry.id == item.id);

      if (index != -1) {
        entries[index] = item;
        return _saveFoodEntriesForDate(entries, dateKey);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete a food entry by ID and date
  Future<bool> deleteFoodEntry(String id, DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final entries = await _getFoodEntriesForDate(date);

      final filtered = entries.where((entry) => entry.id != id).toList();

      if (filtered.length == entries.length) {
        // No entry was removed
        return false;
      }

      return _saveFoodEntriesForDate(filtered, dateKey);
    } catch (e) {
      return false;
    }
  }

  /// Delete multiple food entries by IDs for a specific date
  Future<bool> deleteFoodEntries(List<String> ids, DateTime date) async {
    try {
      if (ids.isEmpty) return true;

      final dateKey = _getDateKey(date);
      final entries = await _getFoodEntriesForDate(date);

      final filtered =
          entries.where((entry) => !ids.contains(entry.id)).toList();

      if (filtered.length == entries.length) {
        // No entries were removed
        return false;
      }

      return _saveFoodEntriesForDate(filtered, dateKey);
    } catch (e) {
      return false;
    }
  }

  /// Get food entries for all meals on a specific date
  Future<Map<String, List<FoodItem>>> getFoodEntriesByMeal(
      DateTime date) async {
    try {
      final allEntries = await getFoodEntries(date);

      // Group entries by meal type
      final Map<String, List<FoodItem>> entriesByMeal = {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
        'snack': [],
      };

      for (final entry in allEntries) {
        final mealType = entry.mealType.toLowerCase();
        if (entriesByMeal.containsKey(mealType)) {
          entriesByMeal[mealType]!.add(entry);
        } else {
          // Default to snack if meal type is unknown
          entriesByMeal['snack']!.add(entry);
        }
      }

      return entriesByMeal;
    } catch (e) {
      return {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
        'snack': [],
      };
    }
  }

  /// Get food entries for a date range grouped by date
  Future<Map<String, List<FoodItem>>> getFoodEntriesForDateRange(
      DateTime startDate, DateTime endDate) async {
    final Map<String, List<FoodItem>> entriesByDate = {};

    try {
      // Ensure end date is not before start date
      if (endDate.isBefore(startDate)) {
        final temp = startDate;
        startDate = endDate;
        endDate = temp;
      }

      // Create a list of all dates in the range
      final List<DateTime> dates = [];
      for (var date = startDate;
          !date.isAfter(endDate);
          date = date.add(const Duration(days: 1))) {
        dates.add(date);
      }

      // Get entries for each date
      for (final date in dates) {
        final dateKey = _getDateKey(date);
        final entries = await getFoodEntries(date);
        entriesByDate[dateKey] = entries;
      }

      return entriesByDate;
    } catch (e) {
      return entriesByDate;
    }
  }

  /// Get nutrition summary for a specific date
  Future<Map<String, dynamic>> getNutritionSummary(DateTime date) async {
    try {
      final entries = await getFoodEntries(date);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final entry in entries) {
        final nutritionValues = entry.getNutritionForServing();
        totalCalories += nutritionValues['calories'] ?? 0;
        totalProtein += nutritionValues['proteins'] ?? 0;
        totalCarbs += nutritionValues['carbs'] ?? 0;
        totalFat += nutritionValues['fats'] ?? 0;
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'entryCount': entries.length,
      };
    } catch (e) {
      return {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'entryCount': 0,
      };
    }
  }

  /// Search for foods by name using the API
  Future<List<FoodItem>> searchFoods(String query, String mealType) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // Save query to recent searches
      await _addToRecentSearches(query);

      final searchResults = await _apiService.searchFoods(query);

      // Convert search results to FoodItem objects
      final List<FoodItem> foodItems = [];

      for (var result in searchResults) {
        try {
          // Check if result has a valid ID or name
          if (result.containsKey('name') && result['name'] != null) {
            // Get detailed information for this food item if needed
            Map<String, dynamic> foodInfo = result;

            // If the result doesn't have nutrition info, fetch it
            if (!result.containsKey('nutrition') ||
                result['nutrition'] == null) {
              foodInfo = await _apiService.getFoodInformation(result['name']);
            }

            final calories = _extractNutrientValue(foodInfo, 'calories') ?? 0.0;
            final proteins = _extractNutrientValue(foodInfo, 'protein') ?? 0.0;
            final carbs = _extractNutrientValue(foodInfo, 'carbs') ?? 0.0;
            final fats = _extractNutrientValue(foodInfo, 'fat') ?? 0.0;

            final item = FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() +
                  '_${result['name']}',
              name: result['name'] ?? 'Unknown Food',
              calories: calories,
              proteins: proteins,
              carbs: carbs,
              fats: fats,
              mealType: mealType,
              timestamp: DateTime.now(),
              servingSize: 1.0,
              servingUnit: 'serving',
              spoonacularId: result['id'], // Keep for backward compatibility
            );

            foodItems.add(item);
          } else {
            // Add with limited information if name is missing
            foodItems.add(FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: result['name'] ?? 'Unknown Food',
              calories: 0.0,
              proteins: 0.0,
              carbs: 0.0,
              fats: 0.0,
              mealType: mealType,
              timestamp: DateTime.now(),
              servingSize: 1.0,
              servingUnit: 'serving',
            ));
          }
        } catch (e) {
          // Add with limited information
          foodItems.add(FoodItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: result['name'] ?? 'Unknown Food',
            calories: 0.0,
            proteins: 0.0,
            carbs: 0.0,
            fats: 0.0,
            mealType: mealType,
            timestamp: DateTime.now(),
            servingSize: 1.0,
            servingUnit: 'serving',
          ));
        }
      }

      return foodItems;
    } catch (e) {
      throw Exception('Failed to search for foods: $e');
    }
  }

  /// Add a search query to recent searches
  Future<bool> _addToRecentSearches(String query) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) return false;

      // Get existing recent searches
      List<String> recentSearches =
          await _storage.getStringList(_recentSearchesKey) ?? [];

      // Remove if it already exists (to move it to the front)
      recentSearches.remove(trimmedQuery);

      // Add to the beginning of the list
      recentSearches.insert(0, trimmedQuery);

      // Limit the number of recent searches
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches = recentSearches.sublist(0, _maxRecentSearches);
      }

      // Save updated list
      return await _storage.setStringList(_recentSearchesKey, recentSearches);
    } catch (e) {
      return false;
    }
  }

  /// Get recent food searches
  Future<List<String>> getRecentSearches() async {
    try {
      return await _storage.getStringList(_recentSearchesKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Clear recent searches
  Future<bool> clearRecentSearches() async {
    try {
      return await _storage.remove(_recentSearchesKey);
    } catch (e) {
      return false;
    }
  }

  /// Add a food item to favorites
  Future<bool> addToFavorites(FoodItem item) async {
    try {
      // Get existing favorites
      final favoritesList =
          await _storage.getObjectList(_favoriteFoodsKey) ?? [];

      // Check if it already exists
      final exists = favoritesList.any((favorite) =>
          favorite['id'] == item.id ||
          (favorite['name'] == item.name &&
              favorite['calories'] == item.calories));

      if (exists) return true; // Already a favorite

      // Add to favorites
      favoritesList.add(item.toMap());

      // Save updated list
      return await _storage.setObjectList(_favoriteFoodsKey, favoritesList);
    } catch (e) {
      return false;
    }
  }

  /// Remove a food item from favorites
  Future<bool> removeFromFavorites(String id) async {
    try {
      // Get existing favorites
      final favoritesList =
          await _storage.getObjectList(_favoriteFoodsKey) ?? [];

      // Remove item with matching ID
      final filteredList =
          favoritesList.where((favorite) => favorite['id'] != id).toList();

      if (filteredList.length == favoritesList.length) {
        return false; // No item was removed
      }

      // Save updated list
      return await _storage.setObjectList(_favoriteFoodsKey, filteredList);
    } catch (e) {
      return false;
    }
  }

  /// Get favorite food items
  Future<List<FoodItem>> getFavorites() async {
    try {
      final favoritesList =
          await _storage.getObjectList(_favoriteFoodsKey) ?? [];

      return favoritesList.map((map) => FoodItem.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a food item is in favorites
  Future<bool> isFavorite(String id) async {
    try {
      final favoritesList =
          await _storage.getObjectList(_favoriteFoodsKey) ?? [];

      return favoritesList.any((favorite) => favorite['id'] == id);
    } catch (e) {
      return false;
    }
  }

  /// Get frequently logged foods (based on occurrence in the last 30 days)
  Future<List<FoodItem>> getFrequentlyLoggedFoods(int limit) async {
    try {
      // Get entries for the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final Map<String, FoodItem> foodMap = {};
      final Map<String, int> countMap = {};

      // Go through each day
      for (var date = thirtyDaysAgo;
          !date.isAfter(now);
          date = date.add(const Duration(days: 1))) {
        final entries = await getFoodEntries(date);

        for (final entry in entries) {
          final key = '${entry.name}_${entry.calories}';

          // Update count
          countMap[key] = (countMap[key] ?? 0) + 1;

          // Store the food item
          foodMap[key] = entry;
        }
      }

      // Sort by frequency
      final sortedKeys = countMap.keys.toList()
        ..sort((a, b) => countMap[b]!.compareTo(countMap[a]!));

      // Create result list
      final result = <FoodItem>[];
      for (int i = 0; i < limit && i < sortedKeys.length; i++) {
        result.add(foodMap[sortedKeys[i]]!.copyWith(
          timestamp: DateTime.now(),
        ));
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  /// Get remaining API quota for today
  Future<int> getRemainingApiQuota() async {
    return _apiService.getRemainingQuota();
  }

  /// Clear all food data for a specific date
  Future<bool> clearFoodEntriesForDate(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final key = '${_foodEntriesKey}_$dateKey';

      return await _storage.remove(key);
    } catch (e) {
      return false;
    }
  }

  /// Delete all stored food images
  Future<bool> clearAllFoodImages() async {
    try {
      final tempDir = await _storage.getTemporaryDirectory();
      final foodImagesDir = Directory('${tempDir.path}/$_tempImageFolderKey');

      if (await foodImagesDir.exists()) {
        await foodImagesDir.delete(recursive: true);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
