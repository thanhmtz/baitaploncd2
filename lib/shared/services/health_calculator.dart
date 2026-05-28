enum ActivityLevel {
  sedentary,
  light,
  moderate,
  heavy,
  veryHeavy,
}

enum GoalType {
  loseWeight,
  maintain,
  gainWeight,
}

class HealthCalculator {
  static double bmi(double weightKg, double heightCm) {
    final hM = heightCm / 100;
    if (hM <= 0) return 0;
    return weightKg / (hM * hM);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    if (bmi < 35) return 'Obese Class 1';
    if (bmi < 40) return 'Obese Class 2';
    return 'Obese Class 3';
  }

  static double bmrMifflin(bool isMale, double weightKg, double heightCm, int age) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return isMale ? base + 5 : base - 161;
  }

  static double tdee(double bmr, ActivityLevel level) {
    final multipliers = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.light: 1.375,
      ActivityLevel.moderate: 1.55,
      ActivityLevel.heavy: 1.725,
      ActivityLevel.veryHeavy: 1.9,
    };
    return bmr * (multipliers[level] ?? 1.2);
  }

  static double tdeeForGoal(double tdee, GoalType goal) {
    switch (goal) {
      case GoalType.loseWeight:
        return tdee - 500;
      case GoalType.maintain:
        return tdee;
      case GoalType.gainWeight:
        return tdee + 300;
    }
  }

  static double bodyFatPercentage(bool isMale, double bmi, int age) {
    return isMale
        ? (1.20 * bmi) + (0.23 * age) - 16.2
        : (1.20 * bmi) + (0.23 * age) - 5.4;
  }

  static double idealWeightDevine(bool isMale, double heightCm) {
    final base = isMale ? 50.0 : 45.5;
    return base + 0.91 * (heightCm - 152.4);
  }

  static double macroProtein(double calories) => (calories * 0.25) / 4;
  static double macroCarbs(double calories) => (calories * 0.50) / 4;
  static double macroFat(double calories) => (calories * 0.25) / 9;

  static String activityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary (desk job)';
      case ActivityLevel.light:
        return 'Light (1-3 days/week)';
      case ActivityLevel.moderate:
        return 'Moderate (3-5 days/week)';
      case ActivityLevel.heavy:
        return 'Heavy (6-7 days/week)';
      case ActivityLevel.veryHeavy:
        return 'Very Heavy (2x/day)';
    }
  }

  static String goalLabel(GoalType goal) {
    switch (goal) {
      case GoalType.loseWeight:
        return 'Lose weight (-500 kcal)';
      case GoalType.maintain:
        return 'Maintain weight';
      case GoalType.gainWeight:
        return 'Gain weight (+300 kcal)';
    }
  }
}
