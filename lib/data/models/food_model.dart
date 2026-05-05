class Food {
  final String name, id;
  final String? imageUrl, description, servingSizeUnit;
  final double? servingSize, numberOfServings, calories, carbs, protein, fat;
  final List<dynamic> nutrients;

  Food(
      {required this.id,
      required this.name,
      required this.nutrients,
      this.calories,
      this.carbs,
      this.fat,
      this.protein,
      this.description,
      this.imageUrl,
      this.servingSize,
      this.servingSizeUnit,
      this.numberOfServings = 1});

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
        id: json['fdcId'].toString(),
        name: (json['description'] as String).toLowerCase(),
        nutrients: json['foodNutrients'] as List<dynamic>,
        servingSize: json['servingSize'],
        servingSizeUnit: json['servingSizeUnit']);
  }

  // Parse từ Spoonacular API
  factory Food.fromSpoonacularJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] as Map<String, dynamic>?;
    final nutrients = <Map<String, dynamic>>[];
    double? calories, protein, fat, carbs;

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

    double? calories = (nutriments['energy-kcal_100g'] as num?)?.toDouble();
    double? protein = (nutriments['proteins_100g'] as num?)?.toDouble();
    double? fat = (nutriments['fat_100g'] as num?)?.toDouble();
    double? carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble();

    // Chuyển đổi sang format nutrients
    nutriments.forEach((key, value) {
      if (value is num) {
        nutrients.add({
          'nutrientName': key.replaceAll('_100g', ''),
          'value': value.toDouble(),
          'unitName': 'g',
        });
      }
    });

    return Food(
      id: 'off_${json['code'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch}',
      name: (json['product_name'] as String? ?? json['product_name_en'] ?? 'unknown').toLowerCase(),
      nutrients: nutrients,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      imageUrl: json['image_url'] as String? ?? json['image_small_url'] as String?,
      description: json['product_name'] as String?,
      servingSize: 100,
      servingSizeUnit: 'g',
      numberOfServings: 1,
    );
  }

  Map<String, dynamic> nutrientFromMap(int nutrientId) {
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
