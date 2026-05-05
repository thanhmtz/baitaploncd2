import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ⚠️ USDA API Key - Đăng ký miễn phí tại https://fdc.nal.usda.gov/api-guide.html
class NutritionAPI {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String _apiKey = 'efNApVsozijlschEgqKdQ96y78HakhqTYpANUApx'; // Thay bằng API key thật

  static bool get _hasKey => _apiKey != 'efNApVsozijlschEgqKdQ96y78HakhqTYpANUApx';

  // Search food
  static Future<List<dynamic>> searchFood(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
        'query': query,
        'pageSize': '10',
        'api_key': _apiKey,
      });
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['foods'] ?? [];
      }
    } catch (e) {
      debugPrint('USDA search error: $e');
    }
    return [];
  }

  // Get food by FDC ID
  static Future<Map<String, dynamic>?> getFoodById(String fdcId) async {
    try {
      final uri = Uri.parse('$_baseUrl/food/$fdcId').replace(queryParameters: {
        'api_key': _apiKey,
      });
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('USDA getFood error: $e');
    }
    return null;
  }
}

// Food Search Service - Sử dụng USDA API
class FoodSearchService {
  static Future<List<Map<String, dynamic>>> search(String query) async {
    final results = await NutritionAPI.searchFood(query);
    
    return results.map((food) => {
      'name': food['description'] ?? '',
      'calories': _getNutrient(food, 208), // Energy
      'protein': _getNutrient(food, 203), // Protein
      'carbs': _getNutrient(food, 205), // Carbs
      'fat': _getNutrient(food, 204), // Fat
      'fdcId': food['fdcId'],
    }).toList();
  }

  static double _getNutrient(dynamic food, int nutrientId) {
    if (food['foodNutrients'] == null) return 0;
    
    for (var nutrient in food['foodNutrients']) {
      if (nutrient['nutrientId'] == nutrientId || nutrient['number'] == nutrientId) {
        return (nutrient['value'] ?? 0).toDouble();
      }
    }
    return 0;
  }
}