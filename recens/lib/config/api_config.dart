import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8080' : 'http://192.168.1.8:8080';

  static String get alerts       => '$baseUrl/get_alerts';
  static String get missingItems => '$baseUrl/get_missing_items';
  static String get setResponse  => '$baseUrl/set_response';
  static String get incompatible => '$baseUrl/get_incompatible';
  static String get getItems     => '$baseUrl/get_items';
  static String get getRecipes   => '$baseUrl/get_recipes';
  static String get getAvgTemp   => '$baseUrl/get_avg_temp';
  static String get getWaste     => '$baseUrl/get_waste';
  static String get insights     => '$baseUrl/get_insights';
  static String get tempSpikes   => '$baseUrl/get_temp_spikes'; // ✅ new
}

// Alias used by report_screen.dart via import '../config.dart'
typedef AppConfig = ApiConfig;