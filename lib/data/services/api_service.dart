// lib/data/services/api_services.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to interact with the Spoonacular API for food recognition
class SpoonacularApiService {
  final String apiKey = '064aabda20ad4f778cd8d72041a3f79c';
  final String baseUrl = 'api.spoonacular.com';

  // Daily quota limit - easy to change as needed
  final int dailyQuotaLimit = 50;

  // Keys for storing quota usage in SharedPreferences
  static const String _quotaUsedKey = 'spoonacular_quota_used';
  static const String _quotaDateKey = 'spoonacular_quota_date';

  /// Analyze a food image and return recognition results
  /// Takes a [File] containing the food image
  /// Returns a Map containing the API response
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    // Construct the API endpoint
    var uri = Uri.https(baseUrl, '/food/images/analyze', {
      'apiKey': apiKey,
    });

    // Create multipart request for file upload
    var request = http.MultipartRequest('POST', uri);

    // Add the image file to the request
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ));

    // Send the request
    try {
      final streamedResponse = await request.send();

      // Increment our quota usage counter
      await incrementQuotaUsage();

      // Process response
      if (streamedResponse.statusCode == 200) {
        final responseData = await streamedResponse.stream.bytesToString();
        return json.decode(responseData);
      } else {
        final errorData = await streamedResponse.stream.bytesToString();
        print('Spoonacular API error: $errorData');
        throw Exception(
            'Failed to analyze image: ${streamedResponse.statusCode}, $errorData');
      }
    } catch (e) {
      print('Error sending image to Spoonacular: $e');
      rethrow;
    }
  }

  /// Get detailed information about a specific food ingredient by ID
  /// [id] - The Spoonacular ingredient ID
  /// Returns detailed nutritional information about the ingredient
  Future<Map<String, dynamic>> getFoodInformation(int id) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    var uri = Uri.https(baseUrl, '/food/ingredients/$id/information', {
      'apiKey': apiKey,
      'amount': '1',
      'unit': 'serving',
      'nutrimentInfo': 'true',
    });

    try {
      var response = await http.get(uri);

      // Increment our quota usage counter
      await incrementQuotaUsage();

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Spoonacular API error: ${response.body}');
        throw Exception(
            'Failed to get food information: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error getting food information: $e');
      rethrow;
    }
  }

  /// Search for foods by name (useful for manual corrections)
  /// [query] - The search term
  /// Returns a list of matching food items
  Future<List<dynamic>> searchFoods(String query) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    var uri = Uri.https(baseUrl, '/food/ingredients/search', {
      'apiKey': apiKey,
      'query': query,
      'number': '5', // Limit to 5 results
      'metaInformation': 'true', // Include nutrition info
    });

    try {
      var response = await http.get(uri);

      // Increment our quota usage counter
      await incrementQuotaUsage();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] ?? [];
      } else {
        print('Spoonacular API error: ${response.body}');
        throw Exception(
            'Failed to search foods: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error searching foods: $e');
      rethrow;
    }
  }

  /// Get recipe information by ID
  /// [id] - The Spoonacular recipe ID
  /// Returns detailed information about the recipe
  Future<Map<String, dynamic>> getRecipeInformation(int id) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    var uri = Uri.https(baseUrl, '/recipes/$id/information', {
      'apiKey': apiKey,
      'includeNutrition': 'true',
    });

    try {
      var response = await http.get(uri);

      // Increment our quota usage counter
      await incrementQuotaUsage();

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Spoonacular API error: ${response.body}');
        throw Exception(
            'Failed to get recipe information: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error getting recipe information: $e');
      rethrow;
    }
  }

  /// Get meal planning suggestions based on calorie target
  /// [targetCalories] - Target calories per day
  /// [diet] - Optional diet preference (e.g., "vegetarian")
  /// Returns meal suggestions for a day
  Future<Map<String, dynamic>> getMealPlan(int targetCalories,
      {String? diet}) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    final queryParams = {
      'apiKey': apiKey,
      'timeFrame': 'day',
      'targetCalories': targetCalories.toString(),
    };

    if (diet != null && diet.isNotEmpty) {
      queryParams['diet'] = diet;
    }

    var uri = Uri.https(baseUrl, '/mealplanner/generate', queryParams);

    try {
      var response = await http.get(uri);

      // Increment our quota usage counter
      await incrementQuotaUsage();

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Spoonacular API error: ${response.body}');
        throw Exception(
            'Failed to get meal plan: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error getting meal plan: $e');
      rethrow;
    }
  }

  /// Check if API quota is exceeded based on Spoonacular headers
  /// Many Spoonacular responses include headers with quota information
  /// Returns true if the request was throttled or quota exceeded
  bool isQuotaExceeded(http.Response response) {
    // Check the headers for quota information
    if (response.headers.containsKey('x-api-quota-used') &&
        response.headers.containsKey('x-api-quota-left')) {
      final used =
          int.tryParse(response.headers['x-api-quota-used'] ?? '0') ?? 0;
      final left =
          int.tryParse(response.headers['x-api-quota-left'] ?? '0') ?? 0;

      return left <= 0 || response.statusCode == 402; // Payment required status
    }

    return false;
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
