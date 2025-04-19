// lib/data/services/api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Add image compression library

/// Service to interact with the Food API for food recognition
class FoodApiService {
  // Use the OpenAI API key
  final String apiKey =
      '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';

  // Model names
  final String visionModel = 'gpt-4.1-mini'; // Using gpt-4.1-nano for vision
  final String textModel = 'gpt-4.1-nano'; // Using gpt-4.1-nano for text

  // Base URL for OpenAI API calls
  final String baseUrl = 'api.openai.com';

  // Endpoint for OpenAI Vision API
  final String visionEndpoint = '/v1/chat/completions';

  // Endpoint for OpenAI Chat API
  final String chatEndpoint = '/v1/chat/completions';

  // Daily quota limit - easy to change as needed
  final int dailyQuotaLimit = 150;

  // Keys for storing quota usage in SharedPreferences
  static const String _quotaUsedKey = 'food_api_quota_used';
  static const String _quotaDateKey = 'food_api_quota_date';

  /// Analyze a food image and return recognition results
  /// Takes a [File] containing the food image
  /// Returns a Map containing the API response
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    try {
      // Resize and compress the image to reduce upload size
      // Targeting 512x512 pixels which is sufficient for food recognition
      List<int> compressedImageBytes = await _compressImage(imageFile);

      // Convert compressed image to base64
      String base64Image = base64Encode(compressedImageBytes);
      String dataUri = 'data:image/jpeg;base64,$base64Image';

      // Print size comparison for debugging
      print('Original image size: ${imageFile.lengthSync()} bytes');
      print('Compressed image size: ${compressedImageBytes.length} bytes');
      print(
          'Compression ratio: ${compressedImageBytes.length / imageFile.lengthSync() * 100}%');

      // Construct the API endpoint
      var uri = Uri.https(baseUrl, visionEndpoint);

      // Create request body for OpenAI Vision API
      final requestBody = json.encode({
        "model": visionModel,
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                    "Identify this food and provide detailed nutritional information. Return the response in JSON format with the following structure: {\"name\": \"Food Name\", \"nutrition\": {\"calories\": 123, \"protein\": 12, \"carbs\": 34, \"fat\": 5}}. Be as accurate as possible with the nutritional values. Include only the JSON in your response."
              },
              {
                "type": "image_url",
                "image_url": {"url": dataUri}
              }
            ]
          }
        ],
        "max_tokens": 1000
      });

      // Send the request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      // Increment our quota usage counter
      await incrementQuotaUsage();

      // Process response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Print the response for debugging
        print('API Response: ${response.body}');

        // Extract the content from the OpenAI response
        String content = responseData['choices'][0]['message']['content'];

        // Try to extract JSON from the content (in case there's text around it)
        RegExp jsonRegex = RegExp(r'{[\s\S]*}');
        Match? match = jsonRegex.firstMatch(content);

        String jsonContent = match != null ? match.group(0)! : content;

        try {
          // Parse the JSON content
          Map<String, dynamic> foodData = json.decode(jsonContent);

          // Format the response for our app
          return _formatResponseForApp(foodData);
        } catch (e) {
          print('Error parsing JSON from OpenAI: $e');
          // Try to extract food information from text response
          return _extractFoodInfoFromText(content);
        }
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

  /// Compress and resize an image to reduce API upload costs
  /// Provides a good balance between image quality and file size
  Future<List<int>> _compressImage(File imageFile) async {
    try {
      // Target dimensions for food recognition (512x512 is usually sufficient)
      const targetWidth = 512;
      const targetHeight = 512;

      // Target quality (0-100, where 100 is highest quality)
      // 85 is a good balance between quality and file size
      const quality = 85;

      // Compress the image
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: quality,
      );

      // Return the compressed image bytes or original if compression failed
      return result ?? await imageFile.readAsBytes();
    } catch (e) {
      print('Error compressing image: $e');
      // Fallback to original image if compression fails
      return await imageFile.readAsBytes();
    }
  }

  /// Extract food information from text response when JSON parsing fails
  Map<String, dynamic> _extractFoodInfoFromText(String text) {
    // Default values
    String name = 'Unknown Food';
    double calories = 250.0;
    double proteins = 10.0;
    double carbs = 30.0;
    double fats = 12.0;

    // Try to find food name
    final nameMatch = RegExp(r'name["\s:]+([^",\n}]+)', caseSensitive: false)
        .firstMatch(text);
    if (nameMatch != null && nameMatch.group(1) != null) {
      name = nameMatch.group(1)!.trim();
    }

    // Try to find calories
    final caloriesMatch =
        RegExp(r'calories["\s:]+(\d+\.?\d*)', caseSensitive: false)
            .firstMatch(text);
    if (caloriesMatch != null && caloriesMatch.group(1) != null) {
      calories = double.tryParse(caloriesMatch.group(1)!) ?? calories;
    }

    // Try to find protein
    final proteinMatch =
        RegExp(r'protein["\s:]+(\d+\.?\d*)', caseSensitive: false)
            .firstMatch(text);
    if (proteinMatch != null && proteinMatch.group(1) != null) {
      proteins = double.tryParse(proteinMatch.group(1)!) ?? proteins;
    }

    // Try to find carbs
    final carbsMatch = RegExp(r'carbs["\s:]+(\d+\.?\d*)', caseSensitive: false)
        .firstMatch(text);
    if (carbsMatch != null && carbsMatch.group(1) != null) {
      carbs = double.tryParse(carbsMatch.group(1)!) ?? carbs;
    }

    // Try to find fat
    final fatMatch =
        RegExp(r'fat["\s:]+(\d+\.?\d*)', caseSensitive: false).firstMatch(text);
    if (fatMatch != null && fatMatch.group(1) != null) {
      fats = double.tryParse(fatMatch.group(1)!) ?? fats;
    }

    // Format the response for our app
    return {
      'category': {'name': name},
      'nutrition': {
        'calories': calories,
        'protein': proteins,
        'carbs': carbs,
        'fat': fats,
        'nutrients': [
          {'name': 'Protein', 'amount': proteins, 'unit': 'g'},
          {'name': 'Carbohydrates', 'amount': carbs, 'unit': 'g'},
          {'name': 'Fat', 'amount': fats, 'unit': 'g'},
        ]
      }
    };
  }

  /// Format the API response into the structure our app expects
  Map<String, dynamic> _formatResponseForApp(Map<String, dynamic> foodData) {
    try {
      String name = foodData['name'] ?? 'Unknown Food';

      // Extract nutrition information
      Map<String, dynamic> nutrition = foodData['nutrition'] ?? {};
      double calories = (nutrition['calories'] is num)
          ? (nutrition['calories'] as num).toDouble()
          : 250.0;
      double proteins = (nutrition['protein'] is num)
          ? (nutrition['protein'] as num).toDouble()
          : 10.0;
      double carbs = (nutrition['carbs'] is num)
          ? (nutrition['carbs'] as num).toDouble()
          : 30.0;
      double fats = (nutrition['fat'] is num)
          ? (nutrition['fat'] as num).toDouble()
          : 12.0;

      // Return formatted response
      return {
        'category': {'name': name},
        'nutrition': {
          'calories': calories,
          'protein': proteins,
          'carbs': carbs,
          'fat': fats,
          'nutrients': [
            {'name': 'Protein', 'amount': proteins, 'unit': 'g'},
            {'name': 'Carbohydrates', 'amount': carbs, 'unit': 'g'},
            {'name': 'Fat', 'amount': fats, 'unit': 'g'},
          ]
        }
      };
    } catch (e) {
      print('Error formatting API response: $e');
      // Return default values if parsing fails
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
  /// [name] - The food name to search for
  /// Returns detailed nutritional information about the ingredient
  Future<Map<String, dynamic>> getFoodInformation(String name) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    try {
      // Construct the API endpoint
      var uri = Uri.https(baseUrl, chatEndpoint);

      // Create request body for OpenAI chat API
      final requestBody = json.encode({
        "model": textModel,
        "messages": [
          {
            "role": "system",
            "content":
                "You are a nutrition information system. When given a food name, provide accurate nutritional information. Return ONLY JSON with no additional text."
          },
          {
            "role": "user",
            "content":
                "Provide detailed nutritional information for $name. Return the response in JSON format with the following structure: {\"name\": \"$name\", \"nutrition\": {\"calories\": 123, \"protein\": 12, \"carbs\": 34, \"fat\": 5}}. Be as accurate as possible with the nutritional values."
          }
        ],
        "max_tokens": 500
      });

      // Send the request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      // Increment quota usage
      await incrementQuotaUsage();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Extract the content from the OpenAI response
        String content = responseData['choices'][0]['message']['content'];

        // Try to extract JSON from the content (in case there's text around it)
        RegExp jsonRegex = RegExp(r'{[\s\S]*}');
        Match? match = jsonRegex.firstMatch(content);

        String jsonContent = match != null ? match.group(0)! : content;

        try {
          // Parse the JSON content
          Map<String, dynamic> foodData = json.decode(jsonContent);

          // Format the response for our app
          return _formatResponseForApp(foodData);
        } catch (e) {
          print('Error parsing JSON from OpenAI: $e');
          // Try to extract food information from text response
          return _extractFoodInfoFromText(content);
        }
      } else {
        print('API error: ${response.body}');
        throw Exception(
            'Failed to get food information: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error getting food information: $e');

      // Return default values with the food name
      return {
        'name': name,
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

  /// Search for foods by name
  /// [query] - The search term
  /// Returns a list of matching food items
  Future<List<dynamic>> searchFoods(String query) async {
    // Check if we've exceeded our daily quota
    if (await isDailyQuotaExceeded()) {
      throw Exception('Daily API quota exceeded. Please try again tomorrow.');
    }

    try {
      // Construct the API endpoint
      var uri = Uri.https(baseUrl, chatEndpoint);

      // Create request body for OpenAI chat API
      final requestBody = json.encode({
        "model": textModel,
        "messages": [
          {
            "role": "system",
            "content":
                "You are a food database API. Return JSON only, with no explanatory text."
          },
          {
            "role": "user",
            "content":
                "Provide a list of 5 food items that match the search term: '$query'. Return the response as a JSON array of objects with the following structure: [{\"id\": 1, \"name\": \"Food Name\", \"nutrition\": {\"calories\": 123, \"protein\": 12, \"carbs\": 34, \"fat\": 5}}]"
          }
        ],
        "max_tokens": 1000
      });

      // Send the request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      // Increment quota usage
      await incrementQuotaUsage();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Extract the content from the OpenAI response
        String content = responseData['choices'][0]['message']['content'];

        // Try to extract JSON from the content (in case there's text around it)
        RegExp jsonRegex = RegExp(r'\[[\s\S]*\]');
        Match? match = jsonRegex.firstMatch(content);

        String jsonContent = match != null ? match.group(0)! : content;

        try {
          // Parse the JSON content
          List<dynamic> foodItems = json.decode(jsonContent);
          return foodItems;
        } catch (e) {
          print('Error parsing JSON from OpenAI search results: $e');
          // Create a fallback result with the query term
          return [
            {
              'id': 1,
              'name': query,
              'nutrition': {
                'calories': 250.0,
                'protein': 10.0,
                'carbs': 30.0,
                'fat': 12.0
              }
            }
          ];
        }
      } else {
        print('API error: ${response.body}');
        throw Exception(
            'Failed to search foods: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error searching foods: $e');
      // Create a fallback result with the query term
      return [
        {
          'id': 1,
          'name': query,
          'nutrition': {
            'calories': 250.0,
            'protein': 10.0,
            'carbs': 30.0,
            'fat': 12.0
          }
        }
      ];
    }
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
