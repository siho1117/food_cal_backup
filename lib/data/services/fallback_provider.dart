// lib/data/services/fallback_provider.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for TimeoutException
import 'food_database.dart'; // Import the food database

/// Provider to handle Google Vision API fallback when OpenAI direct access fails
class FallbackProvider {
  // Google Vision API configuration
  final String _baseUrl = 'vision.googleapis.com';
  final String _imageAnalysisEndpoint = '/v1/images:annotate';

  // Database instance
  final FoodDatabase _foodDatabase = FoodDatabase();

  /// Analyze a food image using Google Vision API
  Future<Map<String, dynamic>> analyzeImage(
      File imageFile, String apiKey, String modelName) async {
    try {
      // Convert image file to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Construct the API endpoint
      var uri = Uri.https(_baseUrl, _imageAnalysisEndpoint);

      // Create request body for Google Vision API
      final requestBody = json.encode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 15},
              {"type": "OBJECT_LOCALIZATION", "maxResults": 5}
            ],
            "imageContext": {
              "productSearchParams": {
                "productCategories": ["food"]
              }
            }
          }
        ]
      });

      // Send the request
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Goog-Api-Key': apiKey,
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      // Process response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        print('Vision API Response: ${response.body}');

        // Identify the food from the response
        final identifiedFood = _identifyFoodFromResponse(responseData);
        print('Identified food: ${identifiedFood['name']}');

        // Format the response for our app
        return _formatResponseForApp(identifiedFood);
      } else {
        print(
            'Google Vision API error: ${response.statusCode}, ${response.body}');
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

        throw Exception('Failed to analyze image: $errorMessage');
      }
    } catch (e) {
      // Handle all exceptions in a single catch to avoid ordering issues
      if (e is SocketException) {
        print('Network error: $e');
        throw Exception('Network error: Please check your internet connection');
      } else if (e is FormatException) {
        print('Format error: $e');
        throw Exception('Error parsing API response');
      } else if (e is TimeoutException) {
        print('Timeout error: $e');
        throw Exception('Request timed out. Please try again');
      } else {
        print('Error in fallback provider: $e');
        // Fall back to the in-memory database
        return _getDefaultFood();
      }
    }
  }

  /// Identify food from the Google Vision API response
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
      Map<String, dynamic>? bestMatch;

      // Get the database
      final foodDatabase = _foodDatabase.database;

      for (final entry in foodDatabase.entries) {
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
          bestMatch = {'name': bestMatchName, ...foodInfo};
        }
      }

      // Only return a match if we have at least some confidence
      if (highestMatches == 0 || bestMatch == null) {
        return _getDefaultFood();
      }

      print(
          'Best match: $bestMatchName with $highestMatches matches and score $highestScore');

      // Return the matched food with its nutritional info
      return {
        "name": bestMatchName.substring(0, 1).toUpperCase() +
            bestMatchName.substring(1), // Capitalize first letter
        "calories": bestMatch['calories'] as double,
        "protein": bestMatch['protein'] as double,
        "carbs": bestMatch['carbs'] as double,
        "fat": bestMatch['fat'] as double
      };
    } catch (e) {
      print('Error identifying food: $e');
      return _getDefaultFood();
    }
  }

  /// Format the food data for the app
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

  /// Get default food values for unknown foods
  Map<String, dynamic> _getDefaultFood() {
    final defaultFood = _foodDatabase.getDefaultFood();

    return {
      'category': {'name': defaultFood['name']},
      'nutrition': {
        'calories': defaultFood['calories'],
        'protein': defaultFood['protein'],
        'carbs': defaultFood['carbs'],
        'fat': defaultFood['fat'],
        'nutrients': [
          {'name': 'Protein', 'amount': defaultFood['protein'], 'unit': 'g'},
          {
            'name': 'Carbohydrates',
            'amount': defaultFood['carbs'],
            'unit': 'g'
          },
          {'name': 'Fat', 'amount': defaultFood['fat'], 'unit': 'g'},
        ]
      }
    };
  }

  /// Get detailed information about a specific food
  Future<Map<String, dynamic>> getFoodInformation(
      String name, String apiKey, String modelName) async {
    try {
      // Find the food in our database
      final foodInfo = _foodDatabase.findFood(name);

      if (foodInfo != null) {
        return {
          'category': {'name': foodInfo['name']},
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
        };
      }

      // If not in database, try to use Google Cloud to get basic recognition
      // This is a simplified approach - in a real app, you might use the Cloud Vision API's
      // web detection or another endpoint to search for the food
      final uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
        'key': apiKey,
        'cx': '017576662512468239146:omuauf_lfve',
        'q': '$name nutrition facts'
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // This would parse the search results to find nutrition information
        // For the demo, we'll return default values
        return _getDefaultFood();
      } else {
        // Fall back to default values
        return _getDefaultFood();
      }
    } catch (e) {
      print('Error getting food information: $e');
      return _getDefaultFood();
    }
  }

  /// Search for foods by name
  Future<List<dynamic>> searchFoods(
      String query, String apiKey, String modelName) async {
    try {
      // Search our food database
      final results = _foodDatabase.searchFoods(query);

      // Format the results for the API
      final formattedResults = results.map((food) {
        return {
          'id': food['id'],
          'name': food['name'],
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
        };
      }).toList();

      // If no matches, return suggestions
      if (formattedResults.isEmpty) {
        final suggestions = _foodDatabase.getDefaultSuggestions();

        return suggestions.map((food) {
          return {
            'id': food['id'],
            'name': food['name'],
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
          };
        }).toList();
      }

      return formattedResults;
    } catch (e) {
      print('Error searching foods: $e');

      // Return default items on error
      final suggestions = _foodDatabase.getDefaultSuggestions();

      return suggestions.map((food) {
        return {
          'id': food['id'],
          'name': food['name'] + ' (default)',
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
        };
      }).toList();
    }
  }
}
