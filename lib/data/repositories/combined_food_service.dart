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
      log('Spoonacular API: $uri');
      final response = await http.get(uri);
      log('Spoonacular status: ${response.statusCode}');
      if (response.statusCode == 402) {
        log('Spoonacular quota exceeded');
        return [];
      }
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body)['results'] as List<dynamic>? ?? [];
      log('Spoonacular results: ${data.length}');
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
      log('OpenFoodFacts API: $uri');
      final response = await http.get(uri);
      log('OpenFoodFacts status: ${response.statusCode}');
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body)['products'] as List<dynamic>? ?? [];
      log('OpenFoodFacts results: ${data.length}');
      if (data.isNotEmpty) {
        log('First product nutriments keys: ${(data.first as Map)['nutriments']?.keys}');
      }
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

    // 1. Ưu tiên Spoonacular (CÓ HÌNH ẢNH + dinh dưỡng)
    for (final food in spoonacularResults) {
      final name = food.name.toLowerCase();
      if (!addedNames.contains(name)) {
        addedNames.add(name);
        results.add(food);
      } else if (food.imageUrl != null) {
        // Update ảnh nếu đã có
        final index = results.indexWhere((f) => f.name.toLowerCase() == name);
        if (index != -1) {
          results[index] = Food(
            id: results[index].id,
            name: results[index].name,
            nutrients: food.nutrients.isNotEmpty ? food.nutrients : results[index].nutrients,
            calories: food.calories ?? results[index].calories,
            carbs: food.carbs ?? results[index].carbs,
            protein: food.protein ?? results[index].protein,
            fat: food.fat ?? results[index].fat,
            description: results[index].description,
            imageUrl: food.imageUrl ?? results[index].imageUrl,
            servingSize: results[index].servingSize,
            servingSizeUnit: results[index].servingSizeUnit,
            numberOfServings: results[index].numberOfServings,
          );
        }
      }
    }

    // 2. Thêm Open Food Facts (CÓ HÌNH ẢNH)
    for (final food in offResults) {
      final name = food.name.toLowerCase();
      if (!addedNames.contains(name)) {
        if (food.imageUrl != null) {
          addedNames.add(name);
          results.add(food);
        }
      } else {
        // Update ảnh nếu chưa có
        final index = results.indexWhere((f) => f.name.toLowerCase() == name);
        if (index != -1 && results[index].imageUrl == null && food.imageUrl != null) {
          results[index] = Food(
            id: results[index].id,
            name: results[index].name,
            nutrients: food.nutrients.isNotEmpty ? food.nutrients : results[index].nutrients,
            calories: food.calories ?? results[index].calories,
            carbs: food.carbs ?? results[index].carbs,
            protein: food.protein ?? results[index].protein,
            fat: food.fat ?? results[index].fat,
            description: results[index].description,
            imageUrl: food.imageUrl,
            servingSize: results[index].servingSize,
            servingSizeUnit: results[index].servingSizeUnit,
            numberOfServings: results[index].numberOfServings,
          );
        }
      }
    }

    // 3. Thêm USDA (bổ sung dinh dưỡng nếu thiếu)
    for (final food in usdaResults) {
      final name = food.name.toLowerCase();
      if (!addedNames.contains(name)) {
        addedNames.add(name);
        results.add(food);
      } else {
        // Bổ sung dinh dưỡng nếu thiếu
        final index = results.indexWhere((f) => f.name.toLowerCase() == name);
        if (index != -1) {
          final existing = results[index];
          if (existing.calories == null || existing.protein == null) {
            results[index] = Food(
              id: existing.id,
              name: existing.name,
              nutrients: existing.nutrients.isNotEmpty ? existing.nutrients : food.nutrients,
              calories: food.calories ?? existing.calories,
              carbs: food.carbs ?? existing.carbs,
              protein: food.protein ?? existing.protein,
              fat: food.fat ?? existing.fat,
              description: existing.description,
              imageUrl: existing.imageUrl,
              servingSize: food.servingSize ?? existing.servingSize,
              servingSizeUnit: food.servingSizeUnit ?? existing.servingSizeUnit,
              numberOfServings: food.numberOfServings ?? existing.numberOfServings,
            );
          }
        }
      }
    }

    return results;
  }
}
