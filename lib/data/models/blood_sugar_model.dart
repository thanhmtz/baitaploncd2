enum BloodSugarMealContext {
  fasting,
  beforeMeal,
  afterMeal,
  bedtime,
}

class BloodSugar {
  final double value;
  final BloodSugarMealContext mealContext;
  final DateTime timestamp;
  final String? notes;

  BloodSugar({
    required this.value,
    required this.mealContext,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'mealContext': mealContext.name,
      'hour': timestamp.hour,
      'minute': timestamp.minute,
      'notes': notes ?? '',
    };
  }

  factory BloodSugar.fromJson(Map<String, dynamic> json, {DateTime? date}) {
    final contextStr = json['mealContext'] as String? ?? 'fasting';
    return BloodSugar(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      mealContext: BloodSugarMealContext.values.firstWhere(
        (e) => e.name == contextStr,
        orElse: () => BloodSugarMealContext.fasting,
      ),
      timestamp: date != null
          ? DateTime(
              date.year,
              date.month,
              date.day,
              (json['hour'] as num?)?.toInt() ?? 0,
              (json['minute'] as num?)?.toInt() ?? 0,
            )
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  String get category {
    switch (mealContext) {
      case BloodSugarMealContext.fasting:
        if (value < 5.6) return 'Normal';
        if (value < 7.0) return 'Prediabetes';
        return 'Diabetes';
      case BloodSugarMealContext.beforeMeal:
        if (value < 5.6) return 'Normal';
        if (value < 7.0) return 'Elevated';
        return 'High';
      case BloodSugarMealContext.afterMeal:
        if (value < 7.8) return 'Normal';
        if (value < 11.0) return 'Elevated';
        return 'High';
      case BloodSugarMealContext.bedtime:
        if (value < 6.7) return 'Normal';
        if (value < 8.5) return 'Elevated';
        return 'High';
    }
  }
}
