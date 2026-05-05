import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:health_tracker/data/models/recipe_model.dart';
import 'package:health_tracker/data/repositories/api_keys.dart';
import 'package:http/http.dart' as http;

class SpoonacularService {
  SpoonacularService._instantiate();

  static final SpoonacularService instance = SpoonacularService._instantiate();

  final String _baseUrl = 'api.spoonacular.com';
  static const String _apiKey = APIKeys.spoonacular;

  bool get _hasKey => _apiKey.isNotEmpty;

  Future<List<Recipe>> getRandomRecipes({int number = 5}) async {
    if (!_hasKey) {
      throw Exception('Cần thêm API Key! Vào spoonacular.com đăng ký miễn phí');
    }

    Map<String, String> parameters = {
      'number': number.toString(),
      'apiKey': _apiKey,
    };
    Uri uri = Uri.https(_baseUrl, '/recipes/random', parameters);

    try {
      var response = await http.get(uri);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        var data = jsonDecode(response.body)['recipes'];
        if (data != null) {
          return (data as List).map((json) => Recipe.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Spoonacular error: $e');
      rethrow;
    }
    
    return [];
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    if (!_hasKey) {
      throw Exception('Cần thêm API Key! Vào spoonacular.com đăng ký miễn phí');
    }

    Map<String, String> parameters = {
      'query': query,
      'number': '10',
      'apiKey': _apiKey,
    };
    Uri uri = Uri.https(_baseUrl, '/recipes/complexSearch', parameters);

    try {
      var response = await http.get(uri);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        var data = jsonDecode(response.body)['results'];
        if (data != null) {
          return (data as List).map((json) => Recipe.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      rethrow;
    }

    return [];
  }

  Future<Recipe> fetchRecipe(String id) async {
    if (!_hasKey) {
      throw Exception('Cần thêm API Key!');
    }

    Map<String, String> parameters = {
      'includeNutrition': 'false',
      'apiKey': _apiKey,
    };
    Uri uri = Uri.https(_baseUrl, 'recipes/$id/information', parameters);

    try {
      var response = await http.get(uri);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return Recipe.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Fetch recipe error: $e');
      rethrow;
    }

    throw Exception('Recipe not found');
  }

  Future<Map<String, dynamic>> getNutrition(String id) async {
    if (!_hasKey) {
      throw Exception('Cần thêm API Key!');
    }

    Map<String, String> parameters = {'apiKey': _apiKey};
    Uri uri = Uri.https(_baseUrl, 'recipes/$id/nutritionWidget.json', parameters);

    try {
      var response = await http.get(uri);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Nutrition error: $e');
    }

    return {};
  }
}