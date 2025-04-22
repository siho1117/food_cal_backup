// lib/data/services/api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fallback_provider.dart'; // Import for fallback mechanism

/// Service to interact with OpenAI API for food recognition with fallback to Taiwan VM proxy
class FoodApiService {
  // Singleton instance
  static final FoodApiService _instance = FoodApiService._internal();
  factory FoodApiService() => _instance;
  FoodApiService._internal();

  // OpenAI configuration
  final String _openAIBaseUrl = 'api.openai.com';
  final String _openAIImagesEndpoint = '/v1/chat/completions';

  // OpenAI model names - updated per your requirement
  final String _visionModel = 'gpt-4.1-mini';
  final String _textModel = 'gpt-4.1-nano';

  // Keys for storage
  static const String _errorLogKey = 'api_error_log';
  static const String _quotaUsedKey = 'food_api_quota_used';
  static const String _quotaDateKey = 'food_api_quota_date';

  // Fallback provider
  final FallbackProvider _fallbackProvider = FallbackProvider();

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
      print('OpenAI direct access error, trying fallback provider: $e');

      // Increment quota usage
      await incrementQuotaUsage();

      // Use fallback provider (Taiwan VM proxy)
      return await _fallbackProvider.analyzeImage(
          imageFile, _openAIApiKey, _visionModel);
    }
  }

  /// Analyze food image using OpenAI's API directly
  Future<Map<String, dynamic>> _analyzeWithOpenAI(File imageFile) async {
    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Create OpenAI API request body with improved prompt for concise food names
    final requestBody = {
      "model": _visionModel,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a food recognition system. Identify the food item in the image with a concise name (1-7 words maximum) and provide nutritional information. Use common food names that would appear in a food database."
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "What single food item is in this image? Reply in this exact format:\nFood Name: [concise name, 1-7 words]\nCalories: [number] cal\nProtein: [number] g\nCarbs: [number] g\nFat: [number] g\n\nIf you can't identify the food or the image doesn't contain food, respond with \"Food Name: Unidentified Food Item\" and provide estimated nutritional values."
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
      print('Extracted content: $content'); // Debug print

      // Initialize default values
      String name = 'Unidentified Food Item';
      double calories = 0.0;
      double protein = 0.0;
      double carbs = 0.0;
      double fat = 0.0;

      // Extract food name - looking for "Food Name:" or similar at the beginning of a line
      final nameMatches =
          RegExp(r'(?:Food\s*Name|Name)[:\s]+([^\n\.]+)', caseSensitive: false)
              .firstMatch(content);
      if (nameMatches != null && nameMatches.groupCount >= 1) {
        name = nameMatches.group(1)!.trim();
      }

      // Extract calories - looking for "Calories:" followed by numbers
      final caloriesMatches =
          RegExp(r'(?:Calories|Cal)[:\s]+(\d+\.?\d*)', caseSensitive: false)
              .firstMatch(content);
      if (caloriesMatches != null && caloriesMatches.groupCount >= 1) {
        calories = double.tryParse(caloriesMatches.group(1)!) ?? 0.0;
      }

      // Extract protein - looking for "Protein:" followed by numbers
      final proteinMatches =
          RegExp(r'(?:Protein)[:\s]+(\d+\.?\d*)', caseSensitive: false)
              .firstMatch(content);
      if (proteinMatches != null && proteinMatches.groupCount >= 1) {
        protein = double.tryParse(proteinMatches.group(1)!) ?? 0.0;
      }

      // Extract carbs - looking for "Carbs:" or "Carbohydrates:" followed by numbers
      final carbsMatches = RegExp(r'(?:Carbs|Carbohydrates)[:\s]+(\d+\.?\d*)',
              caseSensitive: false)
          .firstMatch(content);
      if (carbsMatches != null && carbsMatches.groupCount >= 1) {
        carbs = double.tryParse(carbsMatches.group(1)!) ?? 0.0;
      }

      // Extract fat - looking for "Fat:" followed by numbers
      final fatMatches =
          RegExp(r'(?:Fat)[:\s]+(\d+\.?\d*)', caseSensitive: false)
              .firstMatch(content);
      if (fatMatches != null && fatMatches.groupCount >= 1) {
        fat = double.tryParse(fatMatches.group(1)!) ?? 0.0;
      }

      // Check if the food was unidentified or unknown
      if (name.toLowerCase().contains('unidentified') ||
          name.toLowerCase().contains('unknown') ||
          name.toLowerCase().contains('not food')) {
        name = 'Unidentified Food Item';
      }

      // Debug print for extracted values
      print(
          'Extracted values: name=$name, calories=$calories, protein=$protein, carbs=$carbs, fat=$fat');

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
      // Return an undefined food item response if parsing fails
      return _getUndefinedFoodResponse();
    }
  }

  /// Get an undefined food item response
  Map<String, dynamic> _getUndefinedFoodResponse() {
    return {
      'category': {'name': 'Unidentified Food Item'},
      'nutrition': {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'nutrients': [
          {'name': 'Protein', 'amount': 0.0, 'unit': 'g'},
          {'name': 'Carbohydrates', 'amount': 0.0, 'unit': 'g'},
          {'name': 'Fat', 'amount': 0.0, 'unit': 'g'},
        ]
      }
    };
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
      print('OpenAI error, using fallback provider: $e');

      // Increment quota usage
      await incrementQuotaUsage();

      // Use fallback provider
      return await _fallbackProvider.getFoodInformation(
          name, _openAIApiKey, _textModel);
    }
  }

  /// Get food information from OpenAI
  Future<Map<String, dynamic>> _getFoodInfoFromOpenAI(String name) async {
    // Create OpenAI API request body with improved structured format
    final requestBody = {
      "model": _textModel,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a nutritional information system. Provide detailed nutritional facts for food items in a structured format."
        },
        {
          "role": "user",
          "content":
              "Provide nutritional information for $name. Reply in this exact format:\nFood Name: $name\nCalories: [number] cal\nProtein: [number] g\nCarbs: [number] g\nFat: [number] g"
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
      print('OpenAI error, using fallback provider: $e');

      // Increment quota usage
      await incrementQuotaUsage();

      // Use fallback provider
      return await _fallbackProvider.searchFoods(
          query, _openAIApiKey, _textModel);
    }
  }

  /// Search for foods with OpenAI
  Future<List<dynamic>> _searchFoodsWithOpenAI(String query) async {
    // Create OpenAI API request body with improved output format
    final requestBody = {
      "model": _textModel,
      "messages": [
        {
          "role": "system",
          "content":
              "You are a food database system. Provide food items matching the search query with concise names and nutritional information in a structured JSON format."
        },
        {
          "role": "user",
          "content":
              "Find up to 5 food items matching '$query'. For each item, provide a concise name (1-7 words) and nutritional information. Format your response as a valid JSON array with each object having the format: {\"name\": \"Food Name\", \"calories\": number, \"protein\": number, \"carbs\": number, \"fat\": number}. Ensure the numbers are just numeric values without units."
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
    return _extractFoodItemsFromOpenAI(responseData);
  }

  /// Extract food items from OpenAI response
  List<dynamic> _extractFoodItemsFromOpenAI(Map<String, dynamic> response) {
    try {
      // Get the content from the response
      final content = response['choices'][0]['message']['content'] as String;
      print('Extracting food items from: $content'); // Debug print

      // Try to find JSON in the response - looking for an array [...]
      final jsonMatches =
          RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(content);

      if (jsonMatches != null) {
        // Try to parse the JSON array
        final jsonString = jsonMatches.group(0)!;
        print('Found JSON array: $jsonString'); // Debug print

        final items = jsonDecode(jsonString) as List;
        print('Successfully parsed ${items.length} items'); // Debug print

        // Format each item
        return items.map((item) {
          // Ensure we have all required fields
          final name = item['name'] ?? 'Unknown Food';
          final calories = _parseDoubleValue(item['calories']) ?? 0.0;
          final protein = _parseDoubleValue(item['protein']) ?? 0.0;
          final carbs = _parseDoubleValue(item['carbs']) ?? 0.0;
          final fat = _parseDoubleValue(item['fat']) ?? 0.0;

          print(
              'Formatted item: $name, cal=$calories, p=$protein, c=$carbs, f=$fat'); // Debug print

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
      } else {
        // If JSON parsing fails, search for possible structured content
        print('No valid JSON found, attempting to extract structured data');

        final items = <Map<String, dynamic>>[];

        // Match individual food entry blocks
        final foodBlocks = RegExp(
                r'(?:Food|Name)[:\s]+([^\n]+)(?:\s*Calories?[:\s]+(\d+\.?\d*)(?:\s*cal)?)?(?:\s*Protein[:\s]+(\d+\.?\d*)(?:\s*g)?)?(?:\s*Carb(?:s|ohydrates)?[:\s]+(\d+\.?\d*)(?:\s*g)?)?(?:\s*Fat[:\s]+(\d+\.?\d*)(?:\s*g)?)?',
                caseSensitive: false)
            .allMatches(content);

        for (final match in foodBlocks) {
          if (match.groupCount >= 1) {
            final name = match.group(1)?.trim() ?? 'Unknown Food';
            final calories = _parseDoubleValue(match.group(2)) ?? 0.0;
            final protein = _parseDoubleValue(match.group(3)) ?? 0.0;
            final carbs = _parseDoubleValue(match.group(4)) ?? 0.0;
            final fat = _parseDoubleValue(match.group(5)) ?? 0.0;

            items.add({
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
            });
          }
        }

        if (items.isNotEmpty) {
          print('Extracted ${items.length} items using regex');
          return items;
        }

        // If no items found, return empty list
        return [];
      }
    } catch (e) {
      print('Error extracting food items from response: $e');
      // Return empty list on error
      return [];
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
