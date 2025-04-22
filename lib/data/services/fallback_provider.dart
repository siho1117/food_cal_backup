// lib/data/services/fallback_provider.dart
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for TimeoutException
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Provider to handle Taiwan VM proxy as fallback when OpenAI direct access fails
class FallbackProvider {
  // Taiwan VM proxy configuration
  final String _vmProxyUrl =
      '35.229.164.1'; // Update with your actual VM domain
  final String _vmProxyEndpoint =
      '/api/openai-proxy'; // Update with your actual endpoint

  // Get Taiwan VM API key from environment variables
  String get _vmApiKey {
    final key = dotenv.env['VM_API_KEY'];
    if (key == null || key.isEmpty) {
      print('WARNING: VM_API_KEY not found in .env file');
      return '';
    }
    return key;
  }

  // Generate a unique request ID
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        (1000 + Random().nextInt(9000)).toString();
  }

  /// Analyze a food image using Taiwan VM proxy
  Future<Map<String, dynamic>> analyzeImage(
      File imageFile, String apiKey, String modelName) async {
    try {
      // Convert image to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Generate request ID
      final requestId = _generateRequestId();
      print('Sending image to Taiwan VM proxy');

      // Create request body with requestId
      final requestBody = json.encode({
        "imageData": base64Image,
        "apiKey": apiKey, // Pass the original OpenAI API key to the VM
        "model": modelName,
        "requestId": requestId,
        "systemPrompt":
            "You are a food recognition system. Identify the food item in the image with a concise name (1-7 words maximum) and provide nutritional information. Use common food names that would appear in a food database.",
        "userPrompt":
            "What single food item is in this image? Reply in this exact format:\nFood Name: [concise name, 1-7 words]\nCalories: [number] cal\nProtein: [number] g\nCarbs: [number] g\nFat: [number] g\n\nIf you can't identify the food or the image doesn't contain food, respond with \"Food Name: Unidentified Food Item\" and provide estimated nutritional values."
      });

      // Send the request to Taiwan VM proxy
      final uri = Uri.https(_vmProxyUrl, _vmProxyEndpoint);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Client-API-Key': _vmApiKey,
              'Request-Type': 'image-analysis',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      // Process response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Verify the requestId matches
        if (responseData.containsKey('requestId') &&
            responseData['requestId'] != requestId) {
          throw Exception('Response ID mismatch. Possible data corruption.');
        }

        print('Taiwan VM Proxy Response: ${response.body}');
        return _formatResponseForApp(responseData);
      } else {
        print(
            'Taiwan VM Proxy error: ${response.statusCode}, ${response.body}');
        String errorMessage = 'HTTP Error: ${response.statusCode}';

        try {
          // Try to extract error message from response body
          final errorData = json.decode(response.body);
          if (errorData.containsKey('error') &&
              errorData['error'].containsKey('message')) {
            errorMessage = errorData['error']['message'];
          }
        } catch (e) {
          // If JSON parsing fails, use the original error message
        }

        throw Exception('Taiwan VM Proxy failed: $errorMessage');
      }
    } catch (e) {
      // Handle all exceptions in a single catch
      if (e is SocketException) {
        print('Network error: $e');
        throw Exception('Network error: Please check your internet connection');
      } else if (e is FormatException) {
        print('Format error: $e');
        throw Exception('Error parsing Taiwan VM Proxy response');
      } else if (e is TimeoutException) {
        print('Timeout error: $e');
        throw Exception('Taiwan VM Proxy request timed out. Please try again');
      } else {
        print('Error in fallback provider: $e');
        throw Exception('Taiwan VM Proxy error: $e');
      }
    }
  }

  /// Extract food information from text content
  Map<String, dynamic> _extractFoodInfoFromContent(String content) {
    try {
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
      print('Error extracting food info from content: $e');
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

  /// Format the VM proxy response to match our app's expected format
  Map<String, dynamic> _formatResponseForApp(Map<String, dynamic> response) {
    try {
      // Check if the response already has the expected structure
      if (response.containsKey('category') &&
          response['category'].containsKey('name') &&
          response.containsKey('nutrition')) {
        return response;
      }

      // Extract the content from OpenAI response if present
      if (response.containsKey('choices') &&
          response['choices'] is List &&
          response['choices'].isNotEmpty &&
          response['choices'][0].containsKey('message') &&
          response['choices'][0]['message'].containsKey('content')) {
        final content = response['choices'][0]['message']['content'] as String;

        // Extract food information from content
        return _extractFoodInfoFromContent(content);
      }

      // If direct response from VM (not passing through OpenAI format)
      if (response.containsKey('name') && response.containsKey('nutrition')) {
        return {
          'category': {'name': response['name']},
          'nutrition': response['nutrition']
        };
      }

      // If response contains direct food data
      if (response.containsKey('foodName') ||
          response.containsKey('foodData')) {
        final foodData = response['foodData'] ?? response;
        final name = foodData['foodName'] ??
            foodData['name'] ??
            'Unidentified Food Item';
        final calories = _parseDoubleValue(foodData['calories']) ?? 0.0;
        final protein = _parseDoubleValue(foodData['protein']) ?? 0.0;
        final carbs = _parseDoubleValue(foodData['carbs']) ?? 0.0;
        final fat = _parseDoubleValue(foodData['fat']) ?? 0.0;

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
      }

      // Fallback to default undefined food response
      return _getUndefinedFoodResponse();
    } catch (e) {
      print('Error formatting VM proxy response: $e');
      return _getUndefinedFoodResponse();
    }
  }

  /// Get detailed information about a specific food ingredient by name
  Future<Map<String, dynamic>> getFoodInformation(
      String name, String apiKey, String modelName) async {
    try {
      print('Getting food information via Taiwan VM proxy: $name');

      // Generate request ID
      final requestId = _generateRequestId();

      // Create request body for the VM proxy
      final requestBody = json.encode({
        "foodName": name,
        "apiKey": apiKey,
        "model": modelName,
        "requestId": requestId,
        "requestType": "food_nutrition",
        "systemPrompt":
            "You are a nutritional information system. Provide detailed nutritional facts for food items in a structured format.",
        "userPrompt":
            "Provide nutritional information for $name. Reply in this exact format:\nFood Name: $name\nCalories: [number] cal\nProtein: [number] g\nCarbs: [number] g\nFat: [number] g"
      });

      // Send request to Taiwan VM proxy
      final uri = Uri.https(_vmProxyUrl, _vmProxyEndpoint);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Client-API-Key': _vmApiKey,
              'Request-Type': 'food-info',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
            'VM Proxy error: ${response.statusCode}, ${response.body}');
      }

      // Parse VM proxy response
      final responseData = json.decode(response.body);

      // Verify the requestId matches
      if (responseData is Map &&
          responseData.containsKey('requestId') &&
          responseData['requestId'] != requestId) {
        throw Exception('Response ID mismatch. Possible data corruption.');
      }

      print('VM Proxy Food Info Response: $responseData');

      // Format the response for our app
      return _formatResponseForApp(responseData);
    } catch (e) {
      print('Error getting food information from VM proxy: $e');
      throw Exception('Error getting food information: $e');
    }
  }

  /// Search for foods by name
  Future<List<dynamic>> searchFoods(
      String query, String apiKey, String modelName) async {
    try {
      print('Searching foods via Taiwan VM proxy: $query');

      // Generate request ID
      final requestId = _generateRequestId();

      // Create request body for Taiwan VM proxy
      final requestBody = json.encode({
        "searchQuery": query,
        "apiKey": apiKey,
        "model": modelName,
        "requestId": requestId,
        "requestType": "food_search",
        "systemPrompt":
            "You are a food database system. Provide food items matching the search query with concise names and nutritional information in a structured JSON format.",
        "userPrompt":
            "Find up to 5 food items matching '$query'. For each item, provide a concise name (1-7 words) and nutritional information. Format your response as a valid JSON array with each object having the format: {\"name\": \"Food Name\", \"calories\": number, \"protein\": number, \"carbs\": number, \"fat\": number}. Ensure the numbers are just numeric values without units."
      });

      // Send request to Taiwan VM proxy
      final uri = Uri.https(_vmProxyUrl, _vmProxyEndpoint);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Client-API-Key': _vmApiKey,
              'Request-Type': 'food-search',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
            'VM Proxy error: ${response.statusCode}, ${response.body}');
      }

      // Parse VM proxy response
      final responseData = json.decode(response.body);

      // Verify the requestId matches if it's a map
      if (responseData is Map &&
          responseData.containsKey('requestId') &&
          responseData['requestId'] != requestId) {
        throw Exception('Response ID mismatch. Possible data corruption.');
      }

      print('VM Proxy Food Search Response: $responseData');

      // Extract and format food items
      return _extractFoodItemsFromResponse(responseData);
    } catch (e) {
      print('Error searching foods from VM proxy: $e');
      throw Exception('Error searching foods: $e');
    }
  }

  /// Extract food items from VM proxy response
  List<dynamic> _extractFoodItemsFromResponse(dynamic response) {
    try {
      // If response is already a list of food items
      if (response is List) {
        return response.map((item) {
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

      // If response is a map (OpenAI format with choices)
      if (response is Map && response.containsKey('choices')) {
        // Extract content from OpenAI response
        final content = response['choices'][0]['message']['content'] as String;

        // Try to find JSON in the response - looking for an array [...]
        final jsonMatches =
            RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(content);

        if (jsonMatches != null) {
          // Try to parse the JSON array
          final jsonString = jsonMatches.group(0)!;
          print('Found JSON array: $jsonString');

          final items = json.decode(jsonString) as List;
          print('Successfully parsed ${items.length} items');

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
      }

      // If response contains results array directly
      if (response is Map &&
          response.containsKey('results') &&
          response['results'] is List) {
        final results = response['results'] as List;
        return results.map((item) {
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

      // If no items found, return empty list
      return [];
    } catch (e) {
      print('Error extracting food items from VM proxy response: $e');
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
}
