// lib/data/services/api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to interact with the Food API for food recognition
class FoodApiService {
  // Get API key from environment variables
  final String apiKey = dotenv.env['API_KEY'] ?? '';

  // Base URL for API calls - can be changed as needed
  final String baseUrl = 'vision.googleapis.com';

  // Endpoint for image analysis
  final String imageAnalysisEndpoint = '/v1/images:annotate';

  // Daily quota limit - easy to change as needed
  final int dailyQuotaLimit = 150;

  // Keys for storing quota usage in SharedPreferences
  static const String _quotaUsedKey = 'food_api_quota_used';
  static const String _quotaDateKey = 'food_api_quota_date';

  // Food database with nutritional information and keywords for matching
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

  /// Analyze a food image and return recognition results
  /// Takes a [File] containing the food image
  /// Returns a Map containing the API response
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    try {
      // Convert image file to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Construct the API endpoint
      var uri = Uri.https(baseUrl, imageAnalysisEndpoint);

      // Create request body for Google Vision API
      final requestBody = json.encode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 15},
              {"type": "OBJECT_LOCALIZATION", "maxResults": 5}
            ]
          }
        ]
      });

      // Send the request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Goog-Api-Key': apiKey,
        },
        body: requestBody,
      );

      // Increment our quota usage counter
      await incrementQuotaUsage();

      // Process response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Print the response for debugging
        print('Vision API Response: ${response.body}');

        // Identify the food from the response
        final identifiedFood = _identifyFoodFromResponse(responseData);
        print('Identified food: ${identifiedFood['name']}');

        // Format the response for our app
        final result = _formatResponseForApp(identifiedFood);

        return result;
      } else {
        print('API error: ${response.body}');
        throw Exception(
            'Failed to analyze image: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error sending image to API: $e');
      rethrow;
    }
  }

  /// Identify food from the API response using all available labels
  Map<String, dynamic> _identifyFoodFromResponse(
      Map<String, dynamic> apiResponse) {
    try {
      // Extract all label descriptions from the API response
      final List<String> labels = [];

      if (apiResponse.containsKey('responses') &&
          apiResponse['responses'] is List &&
          (apiResponse['responses'] as List).isNotEmpty) {
        final responseList = apiResponse['responses'] as List;
        if (responseList.isEmpty) {
          return _getDefaultFood();
        }

        final response = responseList[0];
        if (response == null || response is! Map<String, dynamic>) {
          return _getDefaultFood();
        }

        // Extract from label annotations
        if (response.containsKey('labelAnnotations') &&
            response['labelAnnotations'] is List) {
          final labelAnnotations = response['labelAnnotations'] as List;

          for (var item in labelAnnotations) {
            if (item is Map<String, dynamic> &&
                item.containsKey('description') &&
                item['description'] != null) {
              labels.add(item['description'].toString().toLowerCase());
            }
          }
        }

        // Extract from localized object annotations
        if (response.containsKey('localizedObjectAnnotations') &&
            response['localizedObjectAnnotations'] is List) {
          final objectAnnotations =
              response['localizedObjectAnnotations'] as List;

          for (var item in objectAnnotations) {
            if (item is Map<String, dynamic> &&
                item.containsKey('name') &&
                item['name'] != null) {
              labels.add(item['name'].toString().toLowerCase());
            }
          }
        }
      }

      print('Extracted labels: $labels');

      // Match against food database using keywords
      String bestMatchName = "Unknown Food";
      int highestMatches = 0;
      double highestScore = 0.0;

      for (final entry in _foodDatabase.entries) {
        final foodName = entry.key;
        final foodInfo = entry.value;
        final keywords = foodInfo['keywords'] as List<String>;

        int matches = 0;
        double matchScore = 0.0;

        // Check each keyword against the labels
        for (final keyword in keywords) {
          for (final label in labels) {
            // Exact match gets highest score
            if (label == keyword) {
              matches += 3;
              matchScore += 3.0;
            }
            // Contains match gets medium score
            else if (label.contains(keyword) || keyword.contains(label)) {
              matches += 1;
              matchScore += 1.0;
            }
          }
        }

        // Check if food name itself is in the labels with higher weight
        for (final label in labels) {
          if (label == foodName) {
            matches += 4; // Exact match with food name is highest priority
            matchScore += 4.0;
          } else if (label.contains(foodName) || foodName.contains(label)) {
            matches += 2; // Partial match with food name is medium priority
            matchScore += 2.0;
          }
        }

        // Consider label confidence scores if available (not implemented here but could be added)

        // Debug: print match info
        if (matches > 0) {
          print('Food: $foodName, Matches: $matches, Score: $matchScore');
        }

        // Update best match if this one has higher score
        if (matches > highestMatches ||
            (matches == highestMatches && matchScore > highestScore)) {
          highestMatches = matches;
          highestScore = matchScore;
          bestMatchName = foodName;
        }
      }

      // Only return a match if we have at least some confidence
      if (highestMatches == 0) {
        return _getDefaultFood();
      }

      print(
          'Best match: $bestMatchName with $highestMatches matches and score $highestScore');

      // Return the matched food with its nutritional info
      final matchedFood = _foodDatabase[bestMatchName]!;

      return {
        "name": bestMatchName.substring(0, 1).toUpperCase() +
            bestMatchName.substring(1), // Capitalize first letter
        "calories": matchedFood['calories'] as double,
        "protein": matchedFood['protein'] as double,
        "carbs": matchedFood['carbs'] as double,
        "fat": matchedFood['fat'] as double
      };
    } catch (e) {
      print('Error identifying food: $e');
      return _getDefaultFood();
    }
  }

  /// Get default food values for unknown foods
  Map<String, dynamic> _getDefaultFood() {
    return {
      "name": "Unknown Food",
      "calories": 250.0,
      "protein": 10.0,
      "carbs": 30.0,
      "fat": 12.0
    };
  }

  /// Format the food data for our app
  Map<String, dynamic> _formatResponseForApp(Map<String, dynamic> foodData) {
    return {
      'category': {'name': foodData['name']},
      'nutrition': {
        'calories': foodData['calories'],
        'protein': foodData['protein'],
        'carbs': foodData['carbs'],
        'fat': foodData['fat'],
        'nutrients': [
          {'name': 'Protein', 'amount': foodData['protein'], 'unit': 'g'},
          {'name': 'Carbohydrates', 'amount': foodData['carbs'], 'unit': 'g'},
          {'name': 'Fat', 'amount': foodData['fat'], 'unit': 'g'},
        ]
      }
    };
  }

  /// Get detailed information about a specific food ingredient by name
  /// [name] - The food name to search for
  /// Returns detailed nutritional information about the ingredient
  Future<Map<String, dynamic>> getFoodInformation(String name) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    await incrementQuotaUsage();

    // Find the food in our database (case-insensitive)
    final lowerName = name.toLowerCase();
    String matchedFood = "Unknown Food";

    // Try exact match first
    for (final foodName in _foodDatabase.keys) {
      if (foodName.toLowerCase() == lowerName) {
        matchedFood = foodName;
        break;
      }
    }

    // If no exact match, try partial match
    if (matchedFood == "Unknown Food") {
      for (final foodName in _foodDatabase.keys) {
        if (foodName.toLowerCase().contains(lowerName) ||
            lowerName.contains(foodName.toLowerCase())) {
          matchedFood = foodName;
          break;
        }
      }
    }

    // Get nutrition data
    final Map<String, dynamic> nutritionData;
    if (matchedFood != "Unknown Food") {
      nutritionData = {
        'calories': _foodDatabase[matchedFood]!['calories'],
        'protein': _foodDatabase[matchedFood]!['protein'],
        'carbs': _foodDatabase[matchedFood]!['carbs'],
        'fat': _foodDatabase[matchedFood]!['fat'],
        'nutrients': [
          {
            'name': 'Protein',
            'amount': _foodDatabase[matchedFood]!['protein'],
            'unit': 'g'
          },
          {
            'name': 'Carbohydrates',
            'amount': _foodDatabase[matchedFood]!['carbs'],
            'unit': 'g'
          },
          {
            'name': 'Fat',
            'amount': _foodDatabase[matchedFood]!['fat'],
            'unit': 'g'
          },
        ]
      };
    } else {
      // Default values for unknown foods
      nutritionData = {
        'calories': 250.0,
        'protein': 10.0,
        'carbs': 30.0,
        'fat': 12.0,
        'nutrients': [
          {'name': 'Protein', 'amount': 10.0, 'unit': 'g'},
          {'name': 'Carbohydrates', 'amount': 30.0, 'unit': 'g'},
          {'name': 'Fat', 'amount': 12.0, 'unit': 'g'},
        ]
      };
    }

    // Format the response for our app
    return {'name': name, 'nutrition': nutritionData};
  }

  /// Search for foods by name
  /// [query] - The search term
  /// Returns a list of matching food items
  Future<List<dynamic>> searchFoods(String query) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    await incrementQuotaUsage();

    // Search our food database
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Find foods that match the query
    for (final foodName in _foodDatabase.keys) {
      if (foodName.toLowerCase().contains(lowerQuery)) {
        final foodInfo = _foodDatabase[foodName]!;

        results.add({
          'id': _foodDatabase.keys.toList().indexOf(foodName) + 1,
          'name': foodName.substring(0, 1).toUpperCase() +
              foodName.substring(1), // Capitalize
          'nutrition': {
            'calories': foodInfo['calories'],
            'protein': foodInfo['protein'],
            'carbs': foodInfo['carbs'],
            'fat': foodInfo['fat'],
            'nutrients': [
              {'name': 'Protein', 'amount': foodInfo['protein'], 'unit': 'g'},
              {
                'name': 'Carbohydrates',
                'amount': foodInfo['carbs'],
                'unit': 'g'
              },
              {'name': 'Fat', 'amount': foodInfo['fat'], 'unit': 'g'},
            ]
          }
        });
      }
    }

    // Also check keywords for better matches
    if (results.length < 5) {
      for (final entry in _foodDatabase.entries) {
        // Skip if already added
        if (results.any(
            (result) => result['name'].toString().toLowerCase() == entry.key)) {
          continue;
        }

        // Check keywords
        final keywords = entry.value['keywords'] as List<String>;
        if (keywords.any((keyword) =>
            keyword.contains(lowerQuery) || lowerQuery.contains(keyword))) {
          final foodInfo = entry.value;

          results.add({
            'id': _foodDatabase.keys.toList().indexOf(entry.key) + 1,
            'name': entry.key.substring(0, 1).toUpperCase() +
                entry.key.substring(1), // Capitalize
            'nutrition': {
              'calories': foodInfo['calories'],
              'protein': foodInfo['protein'],
              'carbs': foodInfo['carbs'],
              'fat': foodInfo['fat'],
              'nutrients': [
                {'name': 'Protein', 'amount': foodInfo['protein'], 'unit': 'g'},
                {
                  'name': 'Carbohydrates',
                  'amount': foodInfo['carbs'],
                  'unit': 'g'
                },
                {'name': 'Fat', 'amount': foodInfo['fat'], 'unit': 'g'},
              ]
            }
          });
        }
      }
    }

    // If no matches, return top 3 popular foods as suggestions
    if (results.isEmpty) {
      final popularFoods = ['apple', 'banana', 'chicken', 'pizza', 'rice'];

      for (var i = 0; i < 3; i++) {
        final food = popularFoods[i];
        final foodInfo = _foodDatabase[food]!;

        results.add({
          'id': i + 1,
          'name':
              '${food.substring(0, 1).toUpperCase() + food.substring(1)} (suggested)',
          'nutrition': {
            'calories': foodInfo['calories'],
            'protein': foodInfo['protein'],
            'carbs': foodInfo['carbs'],
            'fat': foodInfo['fat'],
            'nutrients': [
              {'name': 'Protein', 'amount': foodInfo['protein'], 'unit': 'g'},
              {
                'name': 'Carbohydrates',
                'amount': foodInfo['carbs'],
                'unit': 'g'
              },
              {'name': 'Fat', 'amount': foodInfo['fat'], 'unit': 'g'},
            ]
          }
        });
      }
    }

    return results;
  }

  /// Check if we've exceeded our self-imposed daily quota limit
  /// Returns true if the quota is exceeded, false otherwise
  Future<bool> isDailyQuotaExceeded() async {
    final prefs = await SharedPreferences.getInstance();

    // Get today's date as a string (YYYY-MM-DD format)
    final today = DateTime.now().toString().split(' ')[0];

    // Get the last date we recorded quota usage
    final lastQuotaDate = prefs.getString(_quotaDateKey) ?? '';

    // If it's a new day, reset the quota
    if (lastQuotaDate != today) {
      await prefs.setString(_quotaDateKey, today);
      await prefs.setInt(_quotaUsedKey, 0);
      return false;
    }

    // Get current quota usage
    final quotaUsed = prefs.getInt(_quotaUsedKey) ?? 0;

    // Check if we've exceeded our limit
    return quotaUsed >= dailyQuotaLimit;
  }

  /// Increment the quota usage counter
  Future<void> incrementQuotaUsage() async {
    final prefs = await SharedPreferences.getInstance();

    // Get today's date as a string (YYYY-MM-DD format)
    final today = DateTime.now().toString().split(' ')[0];

    // Get the last date we recorded quota usage
    final lastQuotaDate = prefs.getString(_quotaDateKey) ?? '';

    // If it's a new day, reset the quota
    if (lastQuotaDate != today) {
      await prefs.setString(_quotaDateKey, today);
      await prefs.setInt(_quotaUsedKey, 1); // Set to 1 for this first request
      return;
    }

    // Get current quota usage and increment it
    final quotaUsed = prefs.getInt(_quotaUsedKey) ?? 0;
    await prefs.setInt(_quotaUsedKey, quotaUsed + 1);
  }

  /// Get the remaining quota for today
  Future<int> getRemainingQuota() async {
    final prefs = await SharedPreferences.getInstance();

    // Get today's date as a string (YYYY-MM-DD format)
    final today = DateTime.now().toString().split(' ')[0];

    // Get the last date we recorded quota usage
    final lastQuotaDate = prefs.getString(_quotaDateKey) ?? '';

    // If it's a new day, the full quota is available
    if (lastQuotaDate != today) {
      return dailyQuotaLimit;
    }

    // Get current quota usage
    final quotaUsed = prefs.getInt(_quotaUsedKey) ?? 0;

    // Calculate remaining quota
    return (dailyQuotaLimit - quotaUsed).clamp(0, dailyQuotaLimit);
  }
}
