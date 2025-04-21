// lib/data/services/api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fallback_provider.dart';

/// Service to interact with OpenAI API for food recognition with Google Vision API fallback
class FoodApiService {
  // Singleton instance
  static final FoodApiService _instance = FoodApiService._internal();
  factory FoodApiService() => _instance;
  FoodApiService._internal() {
    _fallbackProvider = FallbackProvider();
  }

  // OpenAI configuration
  final String _openAIBaseUrl = 'api.openai.com';
  final String _openAIImagesEndpoint = '/v1/chat/completions';
  late FallbackProvider _fallbackProvider;

  // OpenAI model names
  final String _visionModel = 'gpt-4.1-mini';
  final String _textModel = 'gpt-4.1-nano';

  // Keys for storage
  static const String _errorLogKey = 'api_error_log';
  static const String _quotaUsedKey = 'food_api_quota_used';
  static const String _quotaDateKey = 'food_api_quota_date';

  // Daily quota limit
  final int dailyQuotaLimit = 150;

  // Get OpenAI API key from environment variables
  String get _openAIApiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      print('WARNING: OPENAI_API_KEY not found in .env file');
      return '';
    }
    return key;
  }

  // Get Google Vision API key from environment variables
  String get _googleApiKey {
    final key = dotenv.env['GOOGLE_API_KEY'] ?? dotenv.env['API_KEY'];
    if (key == null || key.isEmpty) {
      print('WARNING: Google API key not found in .env file');
      return '';
    }
    return key;
  }

  /// Analyze a food image and return recognition results
  /// Takes a [File] containing the food image
  /// Returns a Map containing the API response
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    try {
      // Try OpenAI first
      return await _analyzeWithOpenAI(imageFile);
    } catch (e) {
      // Log the error for analytics
      await _logError('OpenAI', e.toString());
      print('OpenAI error, falling back to Google Vision: $e');

      // Fall back to Google Vision
      return await _fallbackProvider.analyzeImage(
          imageFile, _googleApiKey, _visionModel);
    } finally {
      // Increment quota usage regardless of which service was used
      await incrementQuotaUsage();
    }
  }

  /// Analyze food image using OpenAI's API directly
  Future<Map<String, dynamic>> _analyzeWithOpenAI(File imageFile) async {
    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Create OpenAI API request body
    final requestBody = {
      "model": _visionModel,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a food recognition system. Identify the food item in the image and provide nutritional information."
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "What food is in this image? Please provide the name and nutritional information including calories, protein, carbs, and fat."
            },
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
            }
          ]
        }
      ],
      "max_tokens": 300
    };

    // Send request to OpenAI
    final uri = Uri.https(_openAIBaseUrl, _openAIImagesEndpoint);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAIApiKey',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI API error: ${response.statusCode}, ${response.body}');
    }

    // Parse OpenAI response
    final responseData = jsonDecode(response.body);
    print('OpenAI Response: $responseData');

    // Extract food information from OpenAI response
    return _extractFoodInfoFromOpenAI(responseData);
  }

  /// Extract food information from OpenAI response
  Map<String, dynamic> _extractFoodInfoFromOpenAI(
      Map<String, dynamic> response) {
    try {
      // Get the content from the response
      final content = response['choices'][0]['message']['content'] as String;

      // Use a basic parsing approach to extract information
      // In a real implementation, you might want to use more robust parsing
      String name = 'Unknown Food';
      double calories = 0.0;
      double protein = 0.0;
      double carbs = 0.0;
      double fat = 0.0;

      // Extract food name (usually the first line or after "Food:" or similar)
      final nameMatches =
          RegExp(r'(?:Food|Name)[:\s]+([^\n\.]+)', caseSensitive: false)
              .firstMatch(content);
      if (nameMatches != null && nameMatches.groupCount >= 1) {
        name = nameMatches.group(1)!.trim();
      }

      // Extract calories
      final caloriesMatches =
          RegExp(r'(?:Calories|Cal)[:\s]+(\d+\.?\d*)', caseSensitive: false)
              .firstMatch(content);
      if (caloriesMatches != null && caloriesMatches.groupCount >= 1) {
        calories = double.tryParse(caloriesMatches.group(1)!) ?? 0.0;
      }

      // Extract protein
      final proteinMatches =
          RegExp(r'(?:Protein)[:\s]+(\d+\.?\d*)', caseSensitive: false)
              .firstMatch(content);
      if (proteinMatches != null && proteinMatches.groupCount >= 1) {
        protein = double.tryParse(proteinMatches.group(1)!) ?? 0.0;
      }

      // Extract carbs
      final carbsMatches = RegExp(r'(?:Carbs|Carbohydrates)[:\s]+(\d+\.?\d*)',
              caseSensitive: false)
          .firstMatch(content);
      if (carbsMatches != null && carbsMatches.groupCount >= 1) {
        carbs = double.tryParse(carbsMatches.group(1)!) ?? 0.0;
      }

      // Extract fat
      final fatMatches =
          RegExp(r'(?:Fat)[:\s]+(\d+\.?\d*)', caseSensitive: false)
              .firstMatch(content);
      if (fatMatches != null && fatMatches.groupCount >= 1) {
        fat = double.tryParse(fatMatches.group(1)!) ?? 0.0;
      }

      // Format the response for our app
      return {
        'category': {'name': name},
        'nutrition': {
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'nutrients': [
            {'name': 'Protein', 'amount': protein, 'unit': 'g'},
            {'name': 'Carbohydrates', 'amount': carbs, 'unit': 'g'},
            {'name': 'Fat', 'amount': fat, 'unit': 'g'},
          ]
        }
      };
    } catch (e) {
      print('Error extracting food info from OpenAI response: $e');
      // Return a default structure if parsing fails
      return {
        'category': {'name': 'Unknown Food'},
        'nutrition': {
          'calories': 250.0,
          'protein': 10.0,
          'carbs': 30.0,
          'fat': 12.0,
          'nutrients': [
            {'name': 'Protein', 'amount': 10.0, 'unit': 'g'},
            {'name': 'Carbohydrates', 'amount': 30.0, 'unit': 'g'},
            {'name': 'Fat', 'amount': 12.0, 'unit': 'g'},
          ]
        }
      };
    }
  }

  /// Get detailed information about a specific food ingredient by name
  Future<Map<String, dynamic>> getFoodInformation(String name) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    try {
      // Try OpenAI first
      return await _getFoodInfoFromOpenAI(name);
    } catch (e) {
      // Log the error for analytics
      await _logError('OpenAI', e.toString());
      print('OpenAI error, falling back to Google Vision for text: $e');

      // Fall back to Google Vision
      return await _fallbackProvider.getFoodInformation(
          name, _googleApiKey, _textModel);
    } finally {
      // Increment quota usage regardless of which service was used
      await incrementQuotaUsage();
    }
  }

  /// Get food information from OpenAI
  Future<Map<String, dynamic>> _getFoodInfoFromOpenAI(String name) async {
    // Create OpenAI API request body
    final requestBody = {
      "model": _textModel,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a nutritional information system. Provide detailed nutritional facts for food items."
        },
        {
          "role": "user",
          "content":
              "Provide nutritional information for $name including calories, protein, carbs, and fat content in grams."
        }
      ],
      "max_tokens": 300
    };

    // Send request to OpenAI
    final uri = Uri.https(_openAIBaseUrl, _openAIImagesEndpoint);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAIApiKey',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI API error: ${response.statusCode}, ${response.body}');
    }

    // Parse OpenAI response
    final responseData = jsonDecode(response.body);
    print('OpenAI Response: $responseData');

    // Extract food information from OpenAI response
    return _extractFoodInfoFromOpenAI(responseData);
  }

  /// Search for foods by name
  Future<List<dynamic>> searchFoods(String query) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    try {
      // Try OpenAI first
      return await _searchFoodsWithOpenAI(query);
    } catch (e) {
      // Log the error for analytics
      await _logError('OpenAI', e.toString());
      print('OpenAI error, falling back to Google Vision for search: $e');

      // Fall back to Google Vision
      return await _fallbackProvider.searchFoods(
          query, _googleApiKey, _textModel);
    } finally {
      // Increment quota usage regardless of which service was used
      await incrementQuotaUsage();
    }
  }

  /// Search for foods with OpenAI
  Future<List<dynamic>> _searchFoodsWithOpenAI(String query) async {
    // Create OpenAI API request body
    final requestBody = {
      "model": _textModel,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a food database system. Provide food items matching the search query with nutritional information."
        },
        {
          "role": "user",
          "content":
              "Find food items matching '$query'. For each item, provide name, calories, protein, carbs, and fat content in JSON format."
        }
      ],
      "max_tokens": 500
    };

    // Send request to OpenAI
    final uri = Uri.https(_openAIBaseUrl, _openAIImagesEndpoint);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAIApiKey',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI API error: ${response.statusCode}, ${response.body}');
    }

    // Parse OpenAI response
    final responseData = jsonDecode(response.body);
    print('OpenAI Response: $responseData');

    // Extract food items from OpenAI response
    return _extractFoodItemsFromOpenAI(responseData, query);
  }

  /// Extract food items from OpenAI response
  List<dynamic> _extractFoodItemsFromOpenAI(
      Map<String, dynamic> response, String query) {
    try {
      // Get the content from the response
      final content = response['choices'][0]['message']['content'] as String;

      // Try to find JSON in the response
      final jsonMatches =
          RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(content);

      if (jsonMatches != null) {
        // Try to parse the JSON array
        final jsonString = jsonMatches.group(0)!;
        final items = jsonDecode(jsonString) as List;

        // Format each item
        return items.map((item) {
          // Ensure we have all required fields
          final name = item['name'] ?? 'Unknown Food';
          final calories = _parseDoubleValue(item['calories']) ?? 0.0;
          final protein = _parseDoubleValue(item['protein']) ?? 0.0;
          final carbs = _parseDoubleValue(item['carbs']) ?? 0.0;
          final fat = _parseDoubleValue(item['fat']) ?? 0.0;

          return {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': name,
            'nutrition': {
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat,
              'nutrients': [
                {'name': 'Protein', 'amount': protein, 'unit': 'g'},
                {'name': 'Carbohydrates', 'amount': carbs, 'unit': 'g'},
                {'name': 'Fat', 'amount': fat, 'unit': 'g'},
              ]
            }
          };
        }).toList();
      }

      // If JSON parsing fails, use fallback database
      print('No valid JSON found in OpenAI response, using fallback database');
      return _searchFallbackDatabase(query);
    } catch (e) {
      print('Error extracting food items from OpenAI response: $e');
      // Return results from fallback database
      return _searchFallbackDatabase(query);
    }
  }

  /// Parse a numeric value from various formats
  double? _parseDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove any non-numeric characters except decimal points
      final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanValue);
    }
    return null;
  }

  /// Search fallback food database (simple in-memory database)
  List<dynamic> _searchFallbackDatabase(String query) {
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Simple food database for fallback
    final foodDatabase = {
      "apple": {"calories": 95.0, "protein": 0.5, "carbs": 25.0, "fat": 0.3},
      "banana": {"calories": 105.0, "protein": 1.3, "carbs": 27.0, "fat": 0.4},
      "orange": {"calories": 65.0, "protein": 1.3, "carbs": 16.0, "fat": 0.2},
      "pizza": {"calories": 285.0, "protein": 12.0, "carbs": 39.0, "fat": 10.0},
      "burger": {
        "calories": 350.0,
        "protein": 20.0,
        "carbs": 33.0,
        "fat": 15.0
      },
      "salad": {"calories": 150.0, "protein": 3.0, "carbs": 10.0, "fat": 10.0},
      "chicken": {"calories": 165.0, "protein": 31.0, "carbs": 0.0, "fat": 3.6},
      "rice": {"calories": 130.0, "protein": 2.7, "carbs": 28.0, "fat": 0.3}
    };

    // Find matching foods
    for (final entry in foodDatabase.entries) {
      if (entry.key.contains(lowerQuery) || lowerQuery.contains(entry.key)) {
        results.add({
          'id': entry.key,
          'name':
              entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1),
          'nutrition': {
            'calories': entry.value['calories'],
            'protein': entry.value['protein'],
            'carbs': entry.value['carbs'],
            'fat': entry.value['fat'],
            'nutrients': [
              {
                'name': 'Protein',
                'amount': entry.value['protein'],
                'unit': 'g'
              },
              {
                'name': 'Carbohydrates',
                'amount': entry.value['carbs'],
                'unit': 'g'
              },
              {'name': 'Fat', 'amount': entry.value['fat'], 'unit': 'g'},
            ]
          }
        });
      }
    }

    // Return at least 3 items (add default items if needed)
    if (results.isEmpty) {
      // Default items
      final defaultItems = ['apple', 'banana', 'chicken'];
      for (final item in defaultItems) {
        final food = foodDatabase[item]!;
        results.add({
          'id': item,
          'name':
              '${item.substring(0, 1).toUpperCase() + item.substring(1)} (suggested)',
          'nutrition': {
            'calories': food['calories'],
            'protein': food['protein'],
            'carbs': food['carbs'],
            'fat': food['fat'],
            'nutrients': [
              {'name': 'Protein', 'amount': food['protein'], 'unit': 'g'},
              {'name': 'Carbohydrates', 'amount': food['carbs'], 'unit': 'g'},
              {'name': 'Fat', 'amount': food['fat'], 'unit': 'g'},
            ]
          }
        });
      }
    }

    return results;
  }

  /// Log error for analytics (minimal data usage)
  Future<void> _logError(String service, String errorMessage) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing error log
      final errorLog = prefs.getStringList(_errorLogKey) ?? [];

      // Add new error with timestamp
      final timestamp = DateTime.now().toIso8601String();
      final errorEntry =
          '$timestamp|$service|${errorMessage.substring(0, Math.min(100, errorMessage.length))}';

      // Keep only the most recent 20 errors
      errorLog.add(errorEntry);
      if (errorLog.length > 20) {
        errorLog.removeAt(0);
      }

      // Save updated log
      await prefs.setStringList(_errorLogKey, errorLog);
    } catch (e) {
      print('Error logging API error: $e');
      // Continue execution even if logging fails
    }
  }

  /// Check if we've exceeded our self-imposed daily quota limit
  Future<bool> isDailyQuotaExceeded() async {
    try {
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
    } catch (e) {
      print('Error checking quota: $e');
      // In case of error, assume we haven't exceeded quota for better UX
      return false;
    }
  }

  /// Increment the quota usage counter
  Future<void> incrementQuotaUsage() async {
    try {
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
    } catch (e) {
      print('Error incrementing quota: $e');
      // Continue execution even if quota tracking fails
    }
  }

  /// Get the remaining quota for today
  Future<int> getRemainingQuota() async {
    try {
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
    } catch (e) {
      print('Error getting remaining quota: $e');
      // In case of error, return a safe default
      return dailyQuotaLimit;
    }
  }
}

// For min function
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
