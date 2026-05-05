import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:health_tracker/data/models/food_model.dart';
import 'package:health_tracker/data/repositories/api_keys.dart';
import 'package:http/http.dart' as http;

class CombinedFoodService {
  CombinedFoodService._instantiate();

  static final CombinedFoodService instance =
      CombinedFoodService._instantiate();

  final String _usdaBaseUrl = 'api.nal.usda.gov';
  final String _spoonacularBaseUrl = 'api.spoonacular.com';
  final String _openFoodFactsBaseUrl = 'world.openfoodfacts.org';

  // 1. Tìm kiếm từ USDA (dinh dưỡng chuẩn)
  Future<List<Food>> searchUSDA(String query) async {
    if (query.isEmpty) return [];
    try {
      final uri = Uri.https(_usdaBaseUrl, '/fdc/v1/foods/search', {
        'api_key': APIKeys.usda,
        'query': query,
        'pageSize': '10',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body)['foods'] as List<dynamic>? ?? [];
      return data.map((json) => Food.fromJson(json)).toList();
    } catch (e) {
      log('USDA error: $e');
      return [];
    }
  }

  // 2. Tìm kiếm từ Spoonacular (có hình ảnh + công thức)
  Future<List<Food>> searchSpoonacular(String query) async {
    if (query.isEmpty) return [];
    try {
      final uri = Uri.https(_spoonacularBaseUrl, '/recipes/complexSearch', {
        'apiKey': APIKeys.spoonacular,
        'query': query,
        'number': '10',
        'addRecipeNutrition': 'true',
        'fillIngredients': 'true',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body)['results'] as List<dynamic>? ?? [];
      return data.map((json) => Food.fromSpoonacularJson(json)).toList();
    } catch (e) {
      log('Spoonacular error: $e');
      return [];
    }
  }

  // 3. Tìm kiếm từ Open Food Facts (thực phẩm đóng gói)
  Future<List<Food>> searchOpenFoodFacts(String query) async {
    if (query.isEmpty) return [];
    try {
      final uri = Uri.https(_openFoodFactsBaseUrl, '/cgi/search.pl', {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '10',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body)['products'] as List<dynamic>? ?? [];
      return data.map((json) => Food.fromOpenFoodFactsJson(json)).toList();
    } catch (e) {
      log('OpenFoodFacts error: $e');
      return [];
    }
  }

  // Kết hợp tất cả API
  Future<List<Food>> searchFood(String query) async {
    if (query.isEmpty) return [];

    final results = <Food>[];
    final addedNames = <String>{};

    // Chạy song song cả 3 API
    final usdaResults = await searchUSDA(query);
    final spoonacularResults = await searchSpoonacular(query);
    final offResults = await searchOpenFoodFacts(query);

    // Ưu tiên USDA trước (dữ liệu dinh dưỡng chuẩn)
    for (final food in usdaResults) {
      final name = food.name.toLowerCase();
      if (!addedNames.contains(name)) {
        addedNames.add(name);
        results.add(food);
      }
    }

    // Thêm Spoonacular (có hình ảnh)
    for (final food in spoonacularResults) {
      final name = food.name.toLowerCase();
      if (!addedNames.contains(name)) {
        addedNames.add(name);
        results.add(food);
      } else {
        // Nếu đã có từ USDA, cập nhật ảnh
        final index = results.indexWhere((f) => f.name.toLowerCase() == name);
        if (index != -1 && results[index].imageUrl == null) {
          results[index] = Food(
            id: results[index].id,
            name: results[index].name,
            nutrients: results[index].nutrients,
            calories: results[index].calories,
            carbs: results[index].carbs,
            protein: results[index].protein,
            fat: results[index].fat,
            description: results[index].description,
            imageUrl: food.imageUrl,
            servingSize: results[index].servingSize,
            servingSizeUnit: results[index].servingSizeUnit,
            numberOfServings: results[index].numberOfServings,
          );
        }
      }
    }

    // Thêm Open Food Facts
    for (final food in offResults) {
      final name = food.name.toLowerCase();
      if (!addedNames.contains(name)) {
        addedNames.add(name);
        results.add(food);
      }
    }

    return results;
  }
}
