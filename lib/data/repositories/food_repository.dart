// lib/data/repositories/food_repository.dart
import 'dart:io';
import '../models/food_item.dart';
import '../services/api_service.dart';
import '../storage/local_storage.dart';

/// Repository for managing food data from API and local storage
class FoodRepository {
  final SpoonacularApiService _apiService = SpoonacularApiService();
  final LocalStorage _storage = LocalStorage();

  static const String _foodEntriesKey = 'food_entries';
  static const String _tempImageFolderKey = 'food_images';

  /// Recognize food from an image and return results
  /// Takes an image file and meal type (breakfast, lunch, dinner, snack)
  /// Returns a list of recognized food items
  Future<List<FoodItem>> recognizeFood(File imageFile, String mealType) async {
    try {
      // Call the API to analyze the image
      final analysisResult = await _apiService.analyzeImage(imageFile);

      // Print response for debugging
      print('API Response: $analysisResult');

      // Save the image file for reference
      final savedImagePath = await _saveImageFile(imageFile);

      // Process the results
      final List<FoodItem> recognizedItems = [];

      // Process response format - Spoonacular may return different structures
      if (analysisResult.containsKey('category')) {
        // Single food item recognized (typical case)
        final item = FoodItem.fromSpoonacularAnalysis(analysisResult, mealType)
            .copyWith(imagePath: savedImagePath);
        recognizedItems.add(item);
      } else if (analysisResult.containsKey('annotations') &&
          analysisResult['annotations'] is List &&
          (analysisResult['annotations'] as List).isNotEmpty) {
        // Multiple food items recognized
        for (var annotation in analysisResult['annotations']) {
          try {
            if (annotation.containsKey('id') && annotation['id'] != null) {
              // Get detailed food information using the ID
              print('Getting details for food ID: ${annotation['id']}');
              final foodInfo =
                  await _apiService.getFoodInformation(annotation['id']);
              print('Food info: $foodInfo');

              // Create food item with nutrition details
              final item = FoodItem(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    '_${annotation['id']}',
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
                spoonacularId: annotation['id'],
              );

              // Print for debugging
              print(
                  'Created food item: ${item.name}, calories: ${item.calories}, proteins: ${item.proteins}, carbs: ${item.carbs}, fats: ${item.fats}');

              recognizedItems.add(item);
            } else {
              // Add with limited information if ID is missing
              print(
                  'Creating food item with limited info for: ${annotation['name']}');
              final item = FoodItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: annotation['name'] ?? 'Unknown Food',
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
            print('Error getting food details: $e');
            // Add with limited information if detailed call fails
            final item = FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: annotation['name'] ?? 'Unknown Food',
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
        print('Creating food item from direct nutrition data');
        final calories =
            _extractNutrientValue(analysisResult, 'calories') ?? 0.0;
        final proteins =
            _extractNutrientValue(analysisResult, 'protein') ?? 0.0;
        final carbs = _extractNutrientValue(analysisResult, 'carbs') ?? 0.0;
        final fats = _extractNutrientValue(analysisResult, 'fat') ?? 0.0;

        print(
            'Extracted values: calories=$calories, proteins=$proteins, carbs=$carbs, fats=$fats');

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
        print(
            'Unrecognized response format. Available keys: ${analysisResult.keys.join(", ")}');
        throw Exception(
            'No food recognized in the image or unsupported response format');
      }

      // For testing - if we got no items, add a dummy food item
      if (recognizedItems.isEmpty && false) {
        // Set to true for testing
        recognizedItems.add(FoodItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Test Food Item',
          calories: 250.0,
          proteins: 15.0,
          carbs: 30.0,
          fats: 8.0,
          imagePath: savedImagePath,
          mealType: mealType,
          timestamp: DateTime.now(),
          servingSize: 1.0,
          servingUnit: 'serving',
        ));
      }

      print('Recognized ${recognizedItems.length} food items');
      return recognizedItems;
    } catch (e) {
      print('Food recognition error: $e');
      throw Exception('Failed to recognize food: $e');
    }
  }

  /// Helper method to extract nutrient values from API response
  double? _extractNutrientValue(
      Map<String, dynamic> data, String nutrientName) {
    try {
      print('Extracting $nutrientName from: $data');

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
      print('Error extracting nutrient $nutrientName: $e');
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
      print('Error saving food image: $e');
      return null;
    }
  }

  /// Save a food entry to local storage
  Future<bool> saveFoodEntry(FoodItem item) async {
    try {
      print(
          'Saving food entry: ${item.name}, proteins=${item.proteins}, carbs=${item.carbs}, fats=${item.fats}');
      final entries = await getFoodEntries(item.timestamp);
      entries.add(item);
      return _saveFoodEntries(entries);
    } catch (e) {
      print('Error saving food entry: $e');
      return false;
    }
  }

  /// Save multiple food entries at once
  Future<bool> saveFoodEntries(List<FoodItem> items) async {
    try {
      if (items.isEmpty) return true;

      print('Saving ${items.length} food entries');
      // Print first item for debugging
      if (items.isNotEmpty) {
        final item = items.first;
        print(
            'First item: ${item.name}, proteins=${item.proteins}, carbs=${item.carbs}, fats=${item.fats}');
      }

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
      print('Error saving multiple food entries: $e');
      return false;
    }
  }

  /// Get all food entries for a specific date
  Future<List<FoodItem>> getFoodEntries(DateTime date) async {
    try {
      final entries = await _getFoodEntriesForDate(date);
      print(
          'Retrieved ${entries.length} food entries for ${_getDateKey(date)}');

      // Debug: Print first entry if available
      if (entries.isNotEmpty) {
        final item = entries.first;
        print(
            'First item: ${item.name}, proteins=${item.proteins}, carbs=${item.carbs}, fats=${item.fats}');
      }

      return entries;
    } catch (e) {
      print('Error retrieving food entries: $e');
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

      // Print for debugging
      print('Saving ${entries.length} entries for date $dateKey');

      return await _storage.setObjectList(key, entriesMaps);
    } catch (e) {
      print('Error saving food entries for date $dateKey: $e');
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
      print('Error updating food entry: $e');
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
      print('Error deleting food entry: $e');
      return false;
    }
  }

  /// Get food entries for all meals on a specific date
  Future<Map<String, List<FoodItem>>> getFoodEntriesByMeal(
      DateTime date) async {
    try {
      final allEntries = await getFoodEntries(date);
      print(
          'Retrieved ${allEntries.length} total entries for ${_getDateKey(date)}');

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

      // Print summary of entries by meal type for debugging
      entriesByMeal.forEach((mealType, entries) {
        print('$mealType: ${entries.length} entries');

        // Print nutritional data for the first entry in each meal type
        if (entries.isNotEmpty) {
          final item = entries.first;
          print(
              '  First item: ${item.name}, calories=${item.calories}, proteins=${item.proteins}, carbs=${item.carbs}, fats=${item.fats}');
        }
      });

      return entriesByMeal;
    } catch (e) {
      print('Error getting food entries by meal: $e');
      return {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
        'snack': [],
      };
    }
  }

  /// Search for foods by name using the API
  Future<List<FoodItem>> searchFoods(String query, String mealType) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final searchResults = await _apiService.searchFoods(query);
      print('Found ${searchResults.length} search results for "$query"');

      // Convert search results to FoodItem objects
      final List<FoodItem> foodItems = [];

      for (var result in searchResults) {
        try {
          // Check if result has a valid ID
          if (result.containsKey('id') && result['id'] != null) {
            // Get detailed information for this food item
            final foodInfo = await _apiService.getFoodInformation(result['id']);
            print('Got detailed info for ${result['name']}');

            final calories = _extractNutrientValue(foodInfo, 'calories') ?? 0.0;
            final proteins = _extractNutrientValue(foodInfo, 'protein') ?? 0.0;
            final carbs = _extractNutrientValue(foodInfo, 'carbs') ?? 0.0;
            final fats = _extractNutrientValue(foodInfo, 'fat') ?? 0.0;

            print(
                'Extracted values: calories=$calories, proteins=$proteins, carbs=$carbs, fats=$fats');

            final item = FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() +
                  '_${result['id']}',
              name: result['name'] ?? 'Unknown Food',
              calories: calories,
              proteins: proteins,
              carbs: carbs,
              fats: fats,
              mealType: mealType,
              timestamp: DateTime.now(),
              servingSize: 1.0,
              servingUnit: 'serving',
              spoonacularId: result['id'],
            );

            foodItems.add(item);
          } else {
            // Add with limited information if ID is missing
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
          print('Error getting detailed food info: $e');
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
      print('Error searching foods: $e');
      throw Exception('Failed to search for foods: $e');
    }
  }

  /// Get remaining API quota for today
  Future<int> getRemainingApiQuota() async {
    return _apiService.getRemainingQuota();
  }
}
