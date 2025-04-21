// lib/services/local_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/region_detector.dart';

/// Service for handling AI API requests with region-based proxy routing
class LocalService {
  // Singleton instance
  static final LocalService _instance = LocalService._internal();
  factory LocalService() => _instance;
  LocalService._internal();

  // API endpoints and configuration
  final String _openaiBaseUrl = 'https://api.openai.com/v1';
  late final String _proxyBaseUrl;
  late final String _apiKey;

  // Initialize service with environment variables
  Future<void> initialize() async {
    // Get configuration from environment
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    _proxyBaseUrl = dotenv.env['PROXY_BASE_URL'] ?? 'http://35.229.164.1:8080';

    if (_apiKey.isEmpty) {
      print('Warning: OPENAI_API_KEY not set in environment variables');
    }
  }

  /// Makes an API request to the appropriate endpoint based on region access
  Future<Map<String, dynamic>> makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    // Check if OpenAI is directly accessible
    final bool canAccessOpenAI = await RegionDetector.canAccessOpenAI();

    // Determine base URL based on access
    final String baseUrl = canAccessOpenAI ? _openaiBaseUrl : _proxyBaseUrl;

    // Create the full URL - if using proxy, the proxy handles adding /v1
    final Uri uri = canAccessOpenAI
        ? Uri.parse('$baseUrl$endpoint')
        : Uri.parse('$baseUrl$endpoint');

    // Set up headers
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      ...?headers,
    };

    // Make the request based on the HTTP method
    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: json.encode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: json.encode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        // Log error details
        print('API Error: ${response.statusCode}, ${response.body}');
        throw HttpException(
          'API request failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('Error making API request: $e');
      rethrow;
    }
  }

  /// Example: Send a chat completion request to OpenAI
  Future<Map<String, dynamic>> getChatCompletion({
    required List<Map<String, String>> messages,
    String model = 'gpt-3.5-turbo',
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    return await makeRequest(
      endpoint: '/chat/completions',
      method: 'POST',
      body: {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    );
  }

  /// Example: Generate an image using DALL-E
  Future<Map<String, dynamic>> generateImage({
    required String prompt,
    String model = 'dall-e-3',
    String size = '1024x1024',
    String quality = 'standard',
    int n = 1,
  }) async {
    return await makeRequest(
      endpoint: '/images/generations',
      method: 'POST',
      body: {
        'model': model,
        'prompt': prompt,
        'size': size,
        'quality': quality,
        'n': n,
      },
    );
  }

  /// Example: Get embeddings for a text
  Future<Map<String, dynamic>> getEmbeddings({
    required String input,
    String model = 'text-embedding-ada-002',
  }) async {
    return await makeRequest(
      endpoint: '/embeddings',
      method: 'POST',
      body: {
        'model': model,
        'input': input,
      },
    );
  }
}
