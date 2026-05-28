import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCounterService {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _todaySteps = 0;
  int _initialSteps = 0;
  String _pedestrianStatus = 'unknown';
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _dailyStepRewardGiven = false;

  int _walkingSteps = 0;
  int _runningSteps = 0;
  int _lastStepCount = 0;
  DateTime _lastStepTime = DateTime.now();
  double _stepsPerMinute = 0;
  String _lastDateKey = '';

  static const int _walkingThreshold = 80;
  static const int _runningThreshold = 160;
  static const int _minTimeBetweenUpdates = 2;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  int get todaySteps => _todaySteps;
  String get pedestrianStatus => _pedestrianStatus;
  bool get isInitialized => _isInitialized;
  int get walkingSteps => _walkingSteps;
  int get runningSteps => _runningSteps;
  double get stepsPerMinute => _stepsPerMinute;

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    
    await _loadInitialSteps();
    _initializePedometer();
    
    _isInitialized = true;
    _isInitializing = false;
  }

  Future<void> _loadInitialSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    final savedDate = prefs.getString('steps_date');
    
    if (savedDate != todayKey) {
      await prefs.setInt('initial_steps', 0);
      await prefs.setString('steps_date', todayKey);
      await prefs.setInt('walking_steps', 0);
      await prefs.setInt('running_steps', 0);
      _initialSteps = 0;
      _walkingSteps = 0;
      _runningSteps = 0;
    } else {
      _initialSteps = prefs.getInt('initial_steps') ?? 0;
      _walkingSteps = prefs.getInt('walking_steps') ?? 0;
      _runningSteps = prefs.getInt('running_steps') ?? 0;
    }
  }

  void _initializePedometer() {
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );

    _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatusChanged,
      onError: _onPedestrianStatusError,
    );
  }

  void _onStepCount(StepCount event) async {
    log('Raw step count: ${event.steps}');
    
    final now = DateTime.now();
    final todayKey = _getDateKey(now);

    if (_lastDateKey.isNotEmpty && _lastDateKey != todayKey) {
      _walkingSteps = 0;
      _runningSteps = 0;
      _dailyStepRewardGiven = false;
    }
    _lastDateKey = todayKey;

    // Detect device reboot: counter reset to smaller value
    if (_initialSteps > 0 && event.steps < _initialSteps) {
      log('Device reboot detected, resetting initial steps');
      _initialSteps = event.steps;
      _todaySteps = 0;
      _walkingSteps = 0;
      _runningSteps = 0;
      _lastStepCount = event.steps;
      _lastStepTime = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('initial_steps', event.steps);
      await prefs.setInt('walking_steps', 0);
      await prefs.setInt('running_steps', 0);
      return;
    }

    // First event: set baseline
    if (_initialSteps == 0 && event.steps > 0) {
      _initialSteps = event.steps;
      _lastStepCount = event.steps;
      _lastStepTime = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('initial_steps', event.steps);
      await prefs.setString('steps_date', todayKey);
      log('Saved initial steps: $event.steps');
      // _todaySteps stays 0 until next event
      return;
    }

    int calculatedSteps = event.steps - _initialSteps;
    if (calculatedSteps < 0) calculatedSteps = 0;

    final timeDiff = now.difference(_lastStepTime).inSeconds;
    final stepDiff = event.steps - _lastStepCount;
    
    if (stepDiff > 0 && timeDiff >= _minTimeBetweenUpdates) {
      _stepsPerMinute = (stepDiff / timeDiff) * 60;

      if (_stepsPerMinute >= _runningThreshold) {
        _runningSteps += stepDiff;
      } else if (_stepsPerMinute >= _walkingThreshold) {
        _walkingSteps += stepDiff;
      }
    }

    if (stepDiff > 0) {
      _lastStepCount = event.steps;
      _lastStepTime = now;
    }
    
    _todaySteps = calculatedSteps;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('walking_steps', _walkingSteps);
    await prefs.setInt('running_steps', _runningSteps);
    
    await _saveStepsToFirestore(calculatedSteps);
  }

  Future<void> _saveStepsToFirestore(int steps) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final today = DateTime.now();
    final dateKey = _getDateKey(today);

    // Reset reward flag if new day
    if (_lastDateKey != dateKey) {
      _dailyStepRewardGiven = false;
      _lastDateKey = dateKey;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .set({
        'totalSteps': steps,
        'lastUpdated': Timestamp.fromDate(today),
      }, SetOptions(merge: true));

      // Give XP for reaching 10000 steps (once per day)
      if (steps >= 10000 && !_dailyStepRewardGiven) {
        _dailyStepRewardGiven = true;
        TreeService().addStepsXp();
        NotificationService().showGoalAchievedNotification(steps, 10000);
        log('XP reward given for 10000 steps!');
      }
    } catch (e) {
      log('Error saving steps to Firestore: $e');
    }
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _pedestrianStatus = event.status;
    log('Pedestrian status: ${event.status}');
  }

  void _onPedestrianStatusError(error) {
    log('Pedometer error: $error');
    _pedestrianStatus = 'unavailable';
  }

  void _onStepCountError(error) {
    log('Step count error: $error');
  }

  String _getDateKey(DateTime date) {
    return '${date.year}_${date.month}_${date.day}';
  }

  Future<int> getStepsForDate(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final dateKey = _getDateKey(date);

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .get();

      if (docSnapshot.exists && docSnapshot.data()!= null) {
        return docSnapshot.data()!['totalSteps'] ?? 0;
      }
    } catch (e) {
      log('Error getting steps for date: $e');
    }
    return 0;
  }

  Stream<int> watchStepsForDate(DateTime date) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    final dateKey = _getDateKey(date);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('diary')
        .doc(dateKey)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data()!= null) {
        return snapshot.data()!['totalSteps'] ?? 0;
      }
      return 0;
    });
  }

  Future<int> getTodayStepsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final today = DateTime.now();
    final dateKey = _getDateKey(today);

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .get();

      if (docSnapshot.exists && docSnapshot.data()!= null) {
        return docSnapshot.data()!['totalSteps'] ?? 0;
      }
    } catch (e) {
      log('Error getting steps from Firestore: $e');
    }
    return 0;
  }

  Stream<int> watchTodaySteps() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    final today = DateTime.now();
    final dateKey = _getDateKey(today);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('diary')
        .doc(dateKey)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data()!= null) {
        return snapshot.data()!['totalSteps'] ?? 0;
      }
      return 0;
    });
  }

  Future<Map<String, int>> getWeeklySteps() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final now = DateTime.now();
    final Map<String, int> weeklySteps = {};
    final List<int> weekDays = [6, 5, 4, 3, 2, 1, 0];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: weekDays[i]));
      final dateKey = _getDateKey(date);
      try {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('diary')
            .doc(dateKey)
            .get();

        if (docSnapshot.exists && docSnapshot.data()!= null) {
          weeklySteps[dateKey] = docSnapshot.data()!['totalSteps'] ?? 0;
        } else {
          weeklySteps[dateKey] = 0;
        }
      } catch (e) {
        weeklySteps[dateKey] = 0;
      }
    }

    return weeklySteps;
  }

  Future<Map<String, int>> getMonthlySteps() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final now = DateTime.now();
    final Map<String, int> monthlySteps = {};

    for (int i = 0; i < now.day; i++) {
      final date = now.subtract(Duration(days: (now.day - 1 - i)));
      final dateKey = _getDateKey(date);
      try {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('diary')
            .doc(dateKey)
            .get();

        if (docSnapshot.exists && docSnapshot.data()!= null) {
          monthlySteps[dateKey] = docSnapshot.data()!['totalSteps'] ?? 0;
        } else {
          monthlySteps[dateKey] = 0;
        }
      } catch (e) {
        monthlySteps[dateKey] = 0;
      }
    }

    return monthlySteps;
  }

  Future<int> getAverageSteps(String period) async {
    final stepsData = period == 'week' ? await getWeeklySteps() : await getMonthlySteps();
    if (stepsData.isEmpty) return 0;
    
    final total = stepsData.values.fold<int>(0, (sum, steps) => sum + steps);
    return total ~/ stepsData.length;
  }

  Future<int> getTotalStepsForPeriod(String period) async {
    final stepsData = period == 'week' ? await getWeeklySteps() : await getMonthlySteps();
    return stepsData.values.fold<int>(0, (sum, steps) => sum + steps);
  }

  Future<void> addManualSteps(int steps) async {
    if (steps <= 0) return;
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final today = DateTime.now();
    final dateKey = _getDateKey(today);

    _todaySteps += steps;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .collection('steps')
          .add({
        'steps': steps,
        'timestamp': Timestamp.fromDate(today),
        'source': 'manual',
      });

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .set({
        'totalSteps': FieldValue.increment(steps),
        'lastUpdated': Timestamp.fromDate(today),
      }, SetOptions(merge: true));
    } catch (e) {
      log('Error adding manual steps: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStepsHistory(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final dateKey = _getDateKey(date);

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .collection('steps')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'steps': data['steps'],
          'timestamp': data['timestamp'],
          'source': data['source'],
        };
      }).toList();
    } catch (e) {
      log('Error getting steps history: $e');
      return [];
    }
  }

  Future<int> getTotalStepsForDate(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final dateKey = _getDateKey(date);

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('diary')
          .doc(dateKey)
          .get();

      if (docSnapshot.exists && docSnapshot.data()!= null) {
        return docSnapshot.data()!['totalSteps'] ?? 0;
      }
    } catch (e) {
      log('Error getting total steps for date: $e');
    }
    return 0;
  }

  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _isInitialized = false;
  }
}