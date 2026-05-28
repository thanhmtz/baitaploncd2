class Food {
  final String name, id;
  final String? imageUrl, description, servingSizeUnit;
  final double? servingSize, numberOfServings, calories, carbs, protein, fat, fiber, sugar, sodium;
  final List<dynamic> nutrients;

  Food(
      {required this.id,
      required this.name,
      required this.nutrients,
      this.calories,
      this.carbs,
      this.fat,
      this.protein,
      this.fiber,
      this.sugar,
      this.sodium,
      this.description,
      this.imageUrl,
      this.servingSize,
      this.servingSizeUnit,
      this.numberOfServings = 1});

  factory Food.fromJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'] as List<dynamic>? ?? [];
    double? calories, protein, fat, carbs, fiber, sugar, sodium;

    for (final n in nutrients) {
      if (n is! Map) continue;
      final nutrientId = n['nutrientId'] as int?;
      final value = (n['value'] as num?)?.toDouble();
      final unit = n['unitName'] as String? ?? '';

      if (nutrientId == 1008) calories = value;
      if (nutrientId == 1003) protein = value;
      if (nutrientId == 1004) fat = value;
      if (nutrientId == 1005) carbs = value;
      if (nutrientId == 1079) fiber = value;
      if (nutrientId == 2000) sugar = value;
      if (nutrientId == 1093) sodium = value;
    }

    return Food(
        id: json['fdcId'].toString(),
        name: (json['description'] as String).toLowerCase(),
        nutrients: nutrients,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
        servingSize: json['servingSize'],
        servingSizeUnit: json['servingSizeUnit']);
  }

  // Parse từ Spoonacular API
  factory Food.fromSpoonacularJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] as Map<String, dynamic>?;
    final nutrients = <Map<String, dynamic>>[];
    double? calories, protein, fat, carbs, fiber, sugar, sodium;

    if (nutrition != null) {
      final nutrientList = nutrition['nutrients'] as List<dynamic>? ?? [];
      for (final n in nutrientList) {
        final nutrient = n as Map<String, dynamic>;
        final name = nutrient['name'] as String? ?? '';
        final amount = (nutrient['amount'] as num?)?.toDouble();
        final unit = nutrient['unit'] as String? ?? '';

        if (name == 'Calories') calories = amount;
        if (name == 'Protein') protein = amount;
        if (name == 'Fat') fat = amount;
        if (name == 'Carbohydrates') carbs = amount;
        if (name == 'Fiber') fiber = amount;
        if (name == 'Sugar') sugar = amount;
        if (name == 'Sodium') sodium = amount;

        nutrients.add({
          'nutrientName': name,
          'value': amount,
          'unitName': unit,
        });
      }
    }

    return Food(
      id: 'spoon_${json['id']}',
      name: (json['title'] as String? ?? '').toLowerCase(),
      nutrients: nutrients,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      imageUrl: json['image'] as String?,
      description: json['title'] as String?,
      servingSize: 1,
      servingSizeUnit: 'serving',
      numberOfServings: 1,
    );
  }

  // Parse từ Open Food Facts API
  factory Food.fromOpenFoodFactsJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};
    final nutrients = <Map<String, dynamic>>[];

    // Lấy giá trị từ nutriments - thử nhiều key format
    double? calories = _getNutrientValue(nutriments, ['energy-kcal_100g', 'energy-kcal', 'energy-kcal_serving']);
    double? protein = _getNutrientValue(nutriments, ['proteins_100g', 'proteins', 'protein_100g']);
    double? fat = _getNutrientValue(nutriments, ['fat_100g', 'fats', 'fat']);
    double? carbs = _getNutrientValue(nutriments, ['carbohydrates_100g', 'carbohydrates', 'carbs_100g']);
    double? fiber = _getNutrientValue(nutriments, ['fiber_100g', 'fiber', 'fibers_100g']);
    double? sugar = _getNutrientValue(nutriments, ['sugars_100g', 'sugars', 'sugar_100g']);
    double? sodium = _getNutrientValue(nutriments, ['sodium_100g', 'sodium', 'salt_100g']);

    // Chuyển đổi sang format nutrients
    nutriments.forEach((key, value) {
      if (value is num) {
        nutrients.add({
          'nutrientName': key.replaceAll('_100g', '').replaceAll('_serving', ''),
          'value': value.toDouble(),
          'unitName': key.contains('_100g') ? 'g' : 'mg',
        });
      }
    });

    // Lấy ảnh từ nhiều nguồn
    String? imageUrl = json['image_url'] as String? ?? 
        json['image_small_url'] as String? ??
        json['image_front_url'] as String? ??
        json['image_front_small_url'] as String?;

    return Food(
      id: 'off_${json['code'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch}',
      name: (json['product_name'] as String? ?? json['product_name_en'] ?? 'unknown').toLowerCase(),
      nutrients: nutrients,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      imageUrl: imageUrl,
      description: json['product_name'] as String?,
      servingSize: 100,
      servingSizeUnit: 'g',
      numberOfServings: 1,
    );
  }

  static double? _getNutrientValue(Map<String, dynamic> nutriments, List<String> keys) {
    for (final key in keys) {
      if (nutriments[key] is num) {
        return (nutriments[key] as num).toDouble();
      }
    }
    return null;
  }

  Map<String, dynamic> nutrientFromMap(int nutrientId) {
    final nutrientNames = {
      1003: ['protein', 'proteins'],
      1004: ['fat', 'fats'],
      1005: ['carbohydrates', 'carbs', 'carbohydrates_100g'],
      1008: ['energy-kcal', 'calories', 'energy'],
      1079: ['fiber', 'fibers', 'dietary fiber', 'fibre'],
      2000: ['sugar', 'sugars', 'sucrose'],
      1093: ['sodium', 'salt'],
    };
    
    final searchNames = nutrientNames[nutrientId] ?? [];
    
    for (var nutrient in nutrients) {
      final name = nutrient['nutrientName']?.toString().toLowerCase() ?? '';
      for (final searchName in searchNames) {
        if (name.contains(searchName.toLowerCase())) {
          return nutrient;
        }
      }
    }
    
    for (var nutrient in nutrients) {
      if (nutrient['nutrientId'] == nutrientId) {
        return nutrient;
      }
    }
    return {
      'value': 0,
      'unitName': '?',
    };
  }
}
