import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/data/models/blood_pressure_model.dart';

void main() {
  group('BloodPressure model', () {
    test('toJson returns correct map', () {
      final bp = BloodPressure(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        timestamp: DateTime(2026, 5, 26, 10, 30),
        notes: 'Test reading',
      );

      final json = bp.toJson();

      expect(json['systolic'], 120);
      expect(json['diastolic'], 80);
      expect(json['pulse'], 72);
      expect(json['hour'], 10);
      expect(json['minute'], 30);
      expect(json['notes'], 'Test reading');
    });

    test('fromJson restores object correctly', () {
      final json = {
        'systolic': 130,
        'diastolic': 85,
        'pulse': 75,
        'hour': 14,
        'minute': 15,
        'notes': 'Afternoon reading',
      };

      final bp = BloodPressure.fromJson(json, date: DateTime(2026, 5, 26));

      expect(bp.systolic, 130);
      expect(bp.diastolic, 85);
      expect(bp.pulse, 75);
      expect(bp.timestamp.hour, 14);
      expect(bp.timestamp.minute, 15);
      expect(bp.notes, 'Afternoon reading');
    });

    test('category returns Normal for 110/70', () {
      final bp = BloodPressure(
        systolic: 110,
        diastolic: 70,
        pulse: 72,
        timestamp: DateTime.now(),
      );
      expect(bp.category, 'Normal');
    });

    test('category returns Elevated for 125/75', () {
      final bp = BloodPressure(
        systolic: 125,
        diastolic: 75,
        pulse: 72,
        timestamp: DateTime.now(),
      );
      expect(bp.category, 'Elevated');
    });

    test('category returns High Stage 1 for 135/85', () {
      final bp = BloodPressure(
        systolic: 135,
        diastolic: 85,
        pulse: 72,
        timestamp: DateTime.now(),
      );
      expect(bp.category, 'High Stage 1');
    });

    test('category returns High Stage 2 for 145/95', () {
      final bp = BloodPressure(
        systolic: 145,
        diastolic: 95,
        pulse: 72,
        timestamp: DateTime.now(),
      );
      expect(bp.category, 'High Stage 2');
    });

    test('category returns High Stage 2 for 145/95', () {
      final bp = BloodPressure(
        systolic: 145,
        diastolic: 95,
        pulse: 72,
        timestamp: DateTime.now(),
      );
      expect(bp.category, 'High Stage 2');
    });

    test('category returns Crisis for 185/125', () {
      final bp = BloodPressure(
        systolic: 185,
        diastolic: 125,
        pulse: 72,
        timestamp: DateTime.now(),
      );
      expect(bp.category, 'Crisis');
    });

    test('fromJson handles missing notes', () {
      final json = {
        'systolic': 110,
        'diastolic': 70,
        'pulse': 65,
        'hour': 8,
        'minute': 0,
      };

      final bp = BloodPressure.fromJson(json, date: DateTime.now());
      expect(bp.notes, isNull);
    });

    test('fromJson handles null date', () {
      final json = {
        'systolic': 120,
        'diastolic': 80,
        'pulse': 70,
        'hour': 12,
        'minute': 0,
      };

      final bp = BloodPressure.fromJson(json);
      expect(bp.timestamp, isNotNull);
    });
  });
}
