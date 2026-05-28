import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/ui/widgets/cactus_visual_state.dart';

enum TreeStage {
  seed(
    minLevel: 1,
    maxLevel: 4,
    name: 'Seed',
  ),
  sprout(
    minLevel: 5,
    maxLevel: 14,
    name: 'Sprout',
  ),
  youngTree(
    minLevel: 15,
    maxLevel: 34,
    name: 'Young Tree',
  ),
  growingTree(
    minLevel: 35,
    maxLevel: 69,
    name: 'Growing Tree',
  ),
  bigTree(
    minLevel: 70,
    maxLevel: 100,
    name: 'Legend Tree',
  );

  final int minLevel;
  final int maxLevel;
  final String name;

  const TreeStage({
    required this.minLevel,
    required this.maxLevel,
    required this.name,
  });

  int get stageLevel => index + 1;

  static TreeStage fromLevel(int level) {
    if (level >= 70) return TreeStage.bigTree;
    if (level >= 35) return TreeStage.growingTree;
    if (level >= 15) return TreeStage.youngTree;
    if (level >= 5) return TreeStage.sprout;
    return TreeStage.seed;
  }
}

class HealthActivity {
  final String type;
  final int xp;
  final DateTime timestamp;
  final bool completed;

  HealthActivity({
    required this.type,
    required this.xp,
    required this.timestamp,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'xp': xp,
      'timestamp': timestamp.toIso8601String(),
      'completed': completed,
    };
  }

  factory HealthActivity.fromJson(Map<String, dynamic> json) {
    return HealthActivity(
      type: json['type'] ?? '',
      xp: _readInt(json['xp']),
      timestamp: _readDate(json['timestamp']),
      completed: json['completed'] ?? false,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class TreeProvider with ChangeNotifier {
  static const String _collection = 'users';
  static const String _treeSubcollection = 'tree_data';
  static const String _docId = 'main';

  static const int maxLevel = 100;

  static const int xpWater = 10;
  static const int xpSteps = 15;
  static const int xpSleep = 15;
  static const int xpMeditation = 10;
  static const int xpCalories = 20;
  static const int xpHeart = 10;
  static const int xpWeight = 5;
  static const int xpBloodPressure = 10;
  static const int xpBloodSugar = 10;

  int _totalXp = 0;
  int _currentXp = 0;
  int _treeLevel = 1;
  int _streakDays = 0;
  int _todayXp = 0;

  int _todayWaterMl = 720;
  int _waterGoalMl = 2300;

  bool _isLoading = false;

  String _dataDate = '';
  DateTime? _lastActiveDate;

  List<HealthActivity> _todayActivities = [];

  Timer? _autoXpTimer;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  int get totalXp => _totalXp;
  int get currentXp => _currentXp;
  int get todayXp => _todayXp;
  int get treeLevel => _treeLevel;
  int get streakDays => _streakDays;
  int get todayWaterMl => _todayWaterMl;
  int get waterGoalMl => _waterGoalMl;
  bool get isLoading => _isLoading;
  List<HealthActivity> get todayActivities => _todayActivities;

  TreeStage get currentStage => TreeStage.fromLevel(_treeLevel);

  int get xpForNextLevel {
    if (_treeLevel >= maxLevel) return 0;
    return 100 + ((_treeLevel - 1) * 25);
  }

  int get xpToNextLevel {
    if (_treeLevel >= maxLevel) return 0;
    return xpForNextLevel - _currentXp;
  }

  double get levelProgress {
    if (_treeLevel >= maxLevel) return 1.0;
    if (xpForNextLevel <= 0) return 1.0;
    return (_currentXp / xpForNextLevel).clamp(0.0, 1.0);
  }

  double get waterProgress {
    if (_waterGoalMl <= 0) return 0.0;
    return (_todayWaterMl / _waterGoalMl).clamp(0.0, 1.0);
  }

  int get waterPercent => (waterProgress * 100).round();

  bool get hasBloomTree => _streakDays >= 14;

  bool get canLevelUp {
    return _treeLevel < maxLevel && _currentXp >= xpForNextLevel;
  }

  double get streakMultiplier {
    if (_streakDays >= 14) return 1.5;
    if (_streakDays >= 7) return 1.3;
    if (_streakDays >= 3) return 1.2;
    return 1.0;
  }

  String get streakMultiplierText {
    return 'x${streakMultiplier.toStringAsFixed(1)}';
  }

  bool get allActivitiesCompleted {
    return isActivityCompleted('water') &&
        isActivityCompleted('steps') &&
        isActivityCompleted('meditation') &&
        isActivityCompleted('calories');
  }

  bool get allHealthActivitiesCompleted {
    return isActivityCompleted('water') &&
        isActivityCompleted('steps') &&
        isActivityCompleted('meditation') &&
        isActivityCompleted('calories') &&
        isActivityCompleted('heart') &&
        isActivityCompleted('weight') &&
        isActivityCompleted('blood_pressure') &&
        isActivityCompleted('blood_sugar');
  }
CactusVisualState get cactusVisualState {
  final hydration = switch (waterProgress) {
    < 0.35 => CactusHydrationState.dry,
    < 0.75 => CactusHydrationState.low,
    < 1.15 => CactusHydrationState.good,
    _ => CactusHydrationState.over,
  };

  final completedTypes = _todayActivities
      .where((activity) => activity.completed)
      .map((activity) => activity.type.toLowerCase().trim())
      .toSet();

  final hasWater = completedTypes.contains('water') || waterProgress >= 0.75;
  final hasSteps = completedTypes.contains('steps');
  final hasSleep = completedTypes.contains('sleep');
  final hasCalories = completedTypes.contains('calories');
  final hasMeditation = completedTypes.contains('meditation');
  final hasHeart = completedTypes.contains('heart');

  final energyScore = [
    if (hasSleep) 1,
    if (hasSteps) 1,
    if (hasCalories) 1,
    if (hasWater) 1,
  ].fold<int>(0, (sum, value) => sum + value);

  final energy = switch (energyScore) {
    <= 1 => CactusEnergyState.exhausted,
    2 => CactusEnergyState.sleepy,
    3 => CactusEnergyState.normal,
    _ => CactusEnergyState.energetic,
  };

  final stress = switch ((hasMeditation, hasHeart, _streakDays == 0)) {
    (true, _, _) => CactusStressState.calm,
    (false, true, _) => CactusStressState.normal,
    (false, false, true) => CactusStressState.stressed,
    _ => CactusStressState.tense,
  };

  final consistency = switch (_streakDays) {
    >= 21 => CactusConsistencyState.legendary,
    >= 14 => CactusConsistencyState.strong,
    >= 7 => CactusConsistencyState.building,
    >= 1 => CactusConsistencyState.weak,
    _ => CactusConsistencyState.broken,
  };

  return CactusVisualState(
    hydration: hydration,
    energy: energy,
    stress: stress,
    consistency: consistency,
    completedToday: allActivitiesCompleted,
    lostStreakRecently: _streakDays == 0,
    missedDays: _streakDays == 0 ? 1 : 0,
  );
}
  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    stopAutoXp();
    _resetState();
    final uid = _uid;
    if (uid != null) {
      _isLoading = true;
      notifyListeners();
      await _loadFromFirestore();
      _resetDailyDataIfNeeded();
      _checkAndUpdateStreak();
      startAutoXp();
      _isLoading = false;
      notifyListeners();
    }
  }

  void startAutoXp() {
    _autoXpTimer?.cancel();

    _autoXpTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) async {
        await addAutoXp(100);
      },
    );
  }

  void stopAutoXp() {
    _autoXpTimer?.cancel();
    _autoXpTimer = null;
  }

  Future<int> addAutoXp(int xp) async {
    if (xp <= 0 || _treeLevel >= maxLevel) return 0;

    _resetDailyDataIfNeeded();
    _markActiveToday();
    _addXpToTree(xp);
    await _saveToFirestore();
    notifyListeners();
    return xp;
  }

  Future<int> addXpFromActivity({
    required String type,
    required int baseXp,
    bool completed = true,
  }) async {
    if (_treeLevel >= maxLevel) {
      debugPrint('Max level reached. No more XP earned.');
      return 0;
    }

    final normalizedType = type.toLowerCase().trim();

    _resetDailyDataIfNeeded();

    final alreadyDone = _todayActivities.any(
      (activity) =>
          activity.type == normalizedType && activity.completed == true,
    );

    if (alreadyDone && completed) {
      debugPrint('Activity $normalizedType already completed today.');
      return 0;
    }

    _markActiveToday();

    final earnedXp = (baseXp * streakMultiplier).round();

    _addXpToTree(earnedXp);

    _todayActivities.add(
      HealthActivity(
        type: normalizedType,
        xp: earnedXp,
        timestamp: DateTime.now(),
        completed: completed,
      ),
    );

    await _saveToFirestore();
    notifyListeners();

    debugPrint(
      'Added $earnedXp XP for $normalizedType. '
      'Level: $_treeLevel, Stage: ${currentStage.name}',
    );

    return earnedXp;
  }

  void _addXpToTree(int xp) {
    if (xp <= 0) return;

    _todayXp += xp;
    _totalXp += xp;

    if (_treeLevel >= maxLevel) {
      _treeLevel = maxLevel;
      _currentXp = 0;
      return;
    }

    _currentXp += xp;

    while (_treeLevel < maxLevel && _currentXp >= xpForNextLevel) {
      _currentXp -= xpForNextLevel;
      _treeLevel++;

      debugPrint(
        'Tree leveled up to LV.$_treeLevel - ${currentStage.name}',
      );
    }

    if (_treeLevel >= maxLevel) {
      _treeLevel = maxLevel;
      _currentXp = 0;
    }
  }

  Future<int> addWaterXp() {
    return addXpFromActivity(type: 'water', baseXp: xpWater);
  }

  Future<int> addStepsXp() {
    return addXpFromActivity(type: 'steps', baseXp: xpSteps);
  }

  Future<int> addSleepXp() {
    return addXpFromActivity(type: 'sleep', baseXp: xpSleep);
  }

  Future<int> addMeditationXp() {
    return addXpFromActivity(type: 'meditation', baseXp: xpMeditation);
  }

  Future<int> addCaloriesXp() {
    return addXpFromActivity(type: 'calories', baseXp: xpCalories);
  }

  Future<int> addHeartXp() {
    return addXpFromActivity(type: 'heart', baseXp: xpHeart);
  }

  Future<int> addWeightXp() {
    return addXpFromActivity(type: 'weight', baseXp: xpWeight);
  }

  Future<int> addBloodPressureXp() {
    return addXpFromActivity(type: 'blood_pressure', baseXp: xpBloodPressure);
  }

  Future<int> addBloodSugarXp() {
    return addXpFromActivity(type: 'blood_sugar', baseXp: xpBloodSugar);
  }

  Future<int> addWater(int ml) async {
    if (ml <= 0) return 0;

    _resetDailyDataIfNeeded();

    _todayWaterMl += ml;

    final earnedXp = await addWaterXp();

    await _saveToFirestore();
    notifyListeners();

    return earnedXp;
  }

  Future<void> setTodayWaterMl(int value) async {
    _resetDailyDataIfNeeded();

    _todayWaterMl = value.clamp(0, _waterGoalMl);

    await _saveToFirestore();
    notifyListeners();
  }

  bool isActivityCompleted(String type) {
    _resetDailyDataIfNeeded();

    final normalizedType = type.toLowerCase().trim();

    return _todayActivities.any(
      (activity) =>
          activity.type == normalizedType && activity.completed == true,
    );
  }

  void _markActiveToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActiveDate != null) {
      final lastDate = DateTime(
        _lastActiveDate!.year,
        _lastActiveDate!.month,
        _lastActiveDate!.day,
      );

      final diff = today.difference(lastDate).inDays;

      if (diff == 0) {
        _lastActiveDate = now;
        return;
      }

      if (diff == 1) {
        _streakDays++;
      } else {
        _streakDays = 1;
      }
    } else {
      _streakDays = 1;
    }

    _lastActiveDate = now;
  }

  void _checkAndUpdateStreak() {
    if (_lastActiveDate == null) {
      _streakDays = 0;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDate = DateTime(
      _lastActiveDate!.year,
      _lastActiveDate!.month,
      _lastActiveDate!.day,
    );

    final diff = today.difference(lastDate).inDays;

    if (diff > 1) {
      _streakDays = 0;
    }
  }

  void _resetDailyDataIfNeeded() {
    final todayKey = _dateKey(DateTime.now());

    if (_dataDate.isEmpty) {
      _dataDate = todayKey;
      return;
    }

    if (_dataDate != todayKey) {
      _todayXp = 0;
      _todayActivities = [];
      _todayWaterMl = 0;
      _dataDate = todayKey;
    }
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _loadFromFirestore() async {
    if (_uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_uid)
          .collection(_treeSubcollection)
          .doc(_docId)
          .get();

      if (!doc.exists) {
        _dataDate = _dateKey(DateTime.now());
        await _createInitialTreeData();
        return;
      }

      final data = doc.data()!;

      _totalXp = _readInt(data, 'totalXp');
      _currentXp = _readInt(data, 'currentXp');
      _treeLevel = _readInt(data, 'treeLevel', defaultValue: 1);
      _streakDays = _readInt(data, 'streakDays');
      _todayXp = _readInt(data, 'todayXp');

      _todayWaterMl = _readInt(data, 'todayWaterMl', defaultValue: 720);
      _waterGoalMl = _readInt(data, 'waterGoalMl', defaultValue: 2300);

      _dataDate = data['dataDate'] as String? ?? _dateKey(DateTime.now());
      _lastActiveDate = _readDate(data['lastActiveDate']);

      final activitiesData = data['todayActivities'];

      if (activitiesData is List) {
        _todayActivities = activitiesData
            .map(
              (item) => HealthActivity.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      if (_todayActivities.isNotEmpty && _todayXp == 0) {
        _todayXp = _todayActivities.fold(
          0,
          (sum, activity) => sum + activity.xp,
        );
      }

      _treeLevel = _treeLevel.clamp(1, maxLevel);

      if (_treeLevel >= maxLevel) {
        _currentXp = 0;
      }

      if (_treeLevel == 1) {
        _totalXp = 0;
        _currentXp = 0;
        _todayXp = 0;
      }
    } catch (e) {
      debugPrint('Error loading tree data: $e');
    }
  }

  void _resetState() {
    _totalXp = 0;
    _currentXp = 0;
    _treeLevel = 1;
    _streakDays = 0;
    _todayXp = 0;
    _todayWaterMl = 720;
    _waterGoalMl = 2300;
    _dataDate = '';
    _lastActiveDate = null;
    _todayActivities = [];
  }

  Future<void> _createInitialTreeData() async {
    if (_uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_uid)
          .collection(_treeSubcollection)
          .doc(_docId)
          .set(
        {
          'treeLevel': 1,
          'totalXp': 0,
          'currentXp': 0,
          'treeStage': 'Seed',
          'streakDays': 0,
          'todayXp': 0,
          'dataDate': _dateKey(DateTime.now()),
          'lastActiveDate': '',
          'todayActivities': [],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('Created initial tree data for user $_uid');
    } catch (e) {
      debugPrint('Error creating initial tree data: $e');
    }
  }

  Future<void> _saveToFirestore() async {
    if (_uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_uid)
          .collection(_treeSubcollection)
          .doc(_docId)
          .set(
        {
          'totalXp': _totalXp,
          'currentXp': _currentXp,
          'treeLevel': _treeLevel,
          'treeStage': currentStage.name,
          'streakDays': _streakDays,
          'todayXp': _todayXp,
          'todayWaterMl': _todayWaterMl,
          'waterGoalMl': _waterGoalMl,
          'dataDate': _dataDate,
          'lastActiveDate': _lastActiveDate?.toIso8601String() ?? '',
          'todayActivities': _todayActivities.map((e) => e.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving tree data: $e');
    }
  }

  int _readInt(
    Map<String, dynamic> data,
    String key, {
    int defaultValue = 0,
  }) {
    final value = data[key];

    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  @override
  void dispose() {
    stopAutoXp();
    super.dispose();
  }
}