import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/data/models/blood_sugar_model.dart';

void main() {
  group('BloodSugar model', () {
    test('toJson returns correct map', () {
      final bs = BloodSugar(
        value: 5.6,
        mealContext: BloodSugarMealContext.fasting,
        timestamp: DateTime(2026, 5, 26, 7, 0),
        notes: 'Morning fasting',
      );

      final json = bs.toJson();

      expect(json['value'], 5.6);
      expect(json['mealContext'], 'fasting');
      expect(json['hour'], 7);
      expect(json['minute'], 0);
      expect(json['notes'], 'Morning fasting');
    });

    test('fromJson restores object correctly', () {
      final json = {
        'value': 7.2,
        'mealContext': 'afterMeal',
        'hour': 13,
        'minute': 30,
        'notes': 'After lunch',
      };

      final bs = BloodSugar.fromJson(json, date: DateTime(2026, 5, 26));

      expect(bs.value, 7.2);
      expect(bs.mealContext, BloodSugarMealContext.afterMeal);
      expect(bs.timestamp.hour, 13);
      expect(bs.timestamp.minute, 30);
      expect(bs.notes, 'After lunch');
    });

    test('fromJson defaults to fasting context', () {
      final json = {
        'value': 5.0,
        'hour': 8,
        'minute': 0,
      };

      final bs = BloodSugar.fromJson(json);
      expect(bs.mealContext, BloodSugarMealContext.fasting);
    });

    test('category Normal for fasting < 5.6', () {
      final bs = BloodSugar(
        value: 5.0,
        mealContext: BloodSugarMealContext.fasting,
        timestamp: DateTime.now(),
      );
      expect(bs.category, 'Normal');
    });

    test('category Prediabetes for fasting 6.0', () {
      final bs = BloodSugar(
        value: 6.0,
        mealContext: BloodSugarMealContext.fasting,
        timestamp: DateTime.now(),
      );
      expect(bs.category, 'Prediabetes');
    });

    test('category Diabetes for fasting 7.5', () {
      final bs = BloodSugar(
        value: 7.5,
        mealContext: BloodSugarMealContext.fasting,
        timestamp: DateTime.now(),
      );
      expect(bs.category, 'Diabetes');
    });

    test('category Normal after meal < 7.8', () {
      final bs = BloodSugar(
        value: 7.0,
        mealContext: BloodSugarMealContext.afterMeal,
        timestamp: DateTime.now(),
      );
      expect(bs.category, 'Normal');
    });

    test('category Elevated after meal 9.0', () {
      final bs = BloodSugar(
        value: 9.0,
        mealContext: BloodSugarMealContext.afterMeal,
        timestamp: DateTime.now(),
      );
      expect(bs.category, 'Elevated');
    });

    test('category High after meal 12.0', () {
      final bs = BloodSugar(
        value: 12.0,
        mealContext: BloodSugarMealContext.afterMeal,
        timestamp: DateTime.now(),
      );
      expect(bs.category, 'High');
    });

    test('all meal contexts can be created', () {
      for (final ctx in BloodSugarMealContext.values) {
        final bs = BloodSugar(
          value: 5.5,
          mealContext: ctx,
          timestamp: DateTime.now(),
        );
        expect(bs.mealContext, ctx);
      }
    });
  });
}
