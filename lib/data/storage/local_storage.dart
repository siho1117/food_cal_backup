// lib/data/storage/local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// A class to handle local storage operations using SharedPreferences
///
/// This class provides a clean interface for storing and retrieving data
/// from the device's local storage. It's designed to be easily replaceable
/// with other storage solutions in the future (like SQLite or cloud storage).
class LocalStorage {
  // Singleton instance
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  // Get temporary directory for file storage
  Future<Directory> getTemporaryDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Get string value by key
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Save string value by key
  Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  // Get string list by key
  Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  // Save string list by key
  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(key, value);
  }

  // Get boolean value by key
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  // Save boolean value by key
  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  // Get object by key (stored as JSON string)
  Future<Map<String, dynamic>?> getObject(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding object for key $key: $e');
      return null;
    }
  }

  // Save object by key (stored as JSON string)
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      print('Error encoding object for key $key: $e');
      return false;
    }
  }

  // Get list of objects by key (stored as list of JSON strings)
  Future<List<Map<String, dynamic>>?> getObjectList(String key) async {
    final jsonStringList = await getStringList(key);
    if (jsonStringList == null) return null;

    try {
      List<Map<String, dynamic>> result = [];
      for (var jsonString in jsonStringList) {
        final decodedObject = jsonDecode(jsonString);
        if (decodedObject is Map<String, dynamic>) {
          result.add(decodedObject);
        }
      }
      return result;
    } catch (e) {
      print('Error decoding object list for key $key: $e');
      return null;
    }
  }

  // Save list of objects by key (stored as list of JSON strings)
  Future<bool> setObjectList(
      String key, List<Map<String, dynamic>> value) async {
    try {
      final jsonStringList = value.map((obj) => jsonEncode(obj)).toList();
      return await setStringList(key, jsonStringList);
    } catch (e) {
      print('Error encoding object list for key $key: $e');
      return false;
    }
  }

  // Remove a key
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  // Clear all data
  Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}
