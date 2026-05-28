import 'package:flutter/material.dart';
import 'package:health_tracker/providers/tree_provider.dart';

class TreeService {
  static TreeService? _instance;
  static TreeProvider? _sharedProvider;

  factory TreeService() {
    _instance ??= TreeService._internal();
    return _instance!;
  }

  TreeService._internal();

  static void setSharedProvider(TreeProvider provider) {
    _sharedProvider = provider;
  }

  Future<TreeProvider> getProvider() async {
    if (_sharedProvider != null) return _sharedProvider!;
    _sharedProvider = TreeProvider();
    await _sharedProvider!.initialize();
    return _sharedProvider!;
  }

  Future<int> addXpFromTask(String taskType) async {
    try {
      final provider = await getProvider();

      switch (taskType.toLowerCase().trim()) {
        case 'water':
          return await provider.addWaterXp();

        case 'steps':
          return await provider.addStepsXp();

        case 'sleep':
          return await provider.addSleepXp();

        case 'meditation':
        case 'breathing':
          return await provider.addMeditationXp();

        case 'calories':
        case 'food':
          return await provider.addCaloriesXp();

        case 'heart':
        case 'bpm':
          return await provider.addHeartXp();

        case 'weight':
          return await provider.addWeightXp();

        case 'blood_pressure':
        case 'bp':
          return await provider.addBloodPressureXp();

        case 'blood_sugar':
        case 'sugar':
          return await provider.addBloodSugarXp();

        default:
          return await provider.addXpFromActivity(
            type: taskType,
            baseXp: 10,
          );
      }
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return 0;
    }
  }

  Future<int> addWaterXp() {
    return addXpFromTask('water');
  }

  Future<int> addStepsXp() {
    return addXpFromTask('steps');
  }

  Future<int> addSleepXp() {
    return addXpFromTask('sleep');
  }

  Future<int> addMeditationXp() {
    return addXpFromTask('meditation');
  }

  Future<int> addCaloriesXp() {
    return addXpFromTask('calories');
  }

  Future<int> addHeartXp() {
    return addXpFromTask('heart');
  }

  Future<int> addWeightXp() {
    return addXpFromTask('weight');
  }

  Future<int> addBloodPressureXp() {
    return addXpFromTask('blood_pressure');
  }

  Future<int> addBloodSugarXp() {
    return addXpFromTask('blood_sugar');
  }

  Future<bool> isActivityCompleted(String type) async {
    try {
      final provider = await getProvider();
      return provider.isActivityCompleted(type);
    } catch (e) {
      debugPrint('Error checking activity: $e');
      return false;
    }
  }

  Future<String> getStreakMultiplier() async {
    try {
      final provider = await getProvider();
      return provider.streakMultiplierText;
    } catch (e) {
      debugPrint('Error getting streak multiplier: $e');
      return 'x1.0';
    }
  }
}