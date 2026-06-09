import 'package:flutter/foundation.dart';

class ApiConfig {
  // Centralized base URL logic
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8080' : 'http://192.168.1.8:8080';

  // Centralized endpoint mappings
  static String get alerts => '$baseUrl/get_alerts';
  static String get missingItems => '$baseUrl/get_missing_items';
  static String get setResponse => '$baseUrl/set_response';
  static String get incompatible => '$baseUrl/get_incompatible';
  static String get getItems => '$baseUrl/get_items';
  static String get getRecipes => '$baseUrl/get_recipes';
}