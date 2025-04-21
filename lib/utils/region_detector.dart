// lib/utils/region_detector.dart
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Utility class to detect whether OpenAI API is accessible from the current region
class RegionDetector {
  // Cache the result of the accessibility test to avoid repeated checks
  static bool? _canAccessOpenAICache;

  // Timestamp when the cache was last updated
  static DateTime? _lastCheckedTime;

  // Cache validity duration (6 hours by default)
  static const Duration _cacheDuration = Duration(hours: 6);

  /// Check if the OpenAI API is directly accessible from the current region
  static Future<bool> canAccessOpenAI() async {
    // Check if we have a valid cached result
    if (_canAccessOpenAICache != null && _lastCheckedTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckedTime!);
      if (timeSinceLastCheck < _cacheDuration) {
        return _canAccessOpenAICache!;
      }
    }

    // Get the list of regions to always use proxy from environment variables
    final String alwaysProxyRegions =
        dotenv.env['ALWAYS_PROXY_REGIONS'] ?? 'CN,HK,MO,RU,IR,CU,SY,KP';

    // Get the current region (in a real app, you'd use a proper geolocation service)
    final String currentRegion = await _detectCurrentRegion();

    // Check if the current region is in the list of regions that should always use proxy
    final List<String> proxyRegions = alwaysProxyRegions.split(',');
    if (proxyRegions.contains(currentRegion)) {
      _canAccessOpenAICache = false;
      _lastCheckedTime = DateTime.now();
      return false;
    }

    // Try to make a test connection to the OpenAI API
    try {
      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      // If we get a 401 Unauthorized, it means the API is reachable but we need an API key
      // Any other successful status code also indicates reachability
      final bool isAccessible = response.statusCode == 401 ||
          (response.statusCode >= 200 && response.statusCode < 300);

      // Cache the result
      _canAccessOpenAICache = isAccessible;
      _lastCheckedTime = DateTime.now();

      return isAccessible;
    } catch (e) {
      // If there's a timeout or any other error, assume the API is not accessible
      print('Error checking OpenAI accessibility: $e');

      // Cache the result
      _canAccessOpenAICache = false;
      _lastCheckedTime = DateTime.now();

      return false;
    }
  }

  /// Detect the current region/country
  /// In a production app, you would use a proper geolocation service
  static Future<String> _detectCurrentRegion() async {
    try {
      // Using a geolocation service API
      // This is a simplified example - in production use a reliable service
      final response = await http
          .get(
            Uri.parse('https://ipinfo.io/json'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(await response.body as Map);
        return data['country'] as String? ?? 'UNKNOWN';
      }
    } catch (e) {
      print('Error detecting region: $e');
    }

    // Default value from environment variable if region detection fails
    return dotenv.env['DEFAULT_REGION'] ?? 'UNKNOWN';
  }

  /// Force the system to always use proxy (for testing purposes)
  static void forceUseProxy(bool useProxy) {
    _canAccessOpenAICache = !useProxy;
    _lastCheckedTime = DateTime.now();
  }

  /// Clear the cached result to force a fresh check
  static void clearCache() {
    _canAccessOpenAICache = null;
    _lastCheckedTime = null;
  }
}
