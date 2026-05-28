import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:health_tracker/shared/services/notification_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartReminderService {
  static final SmartReminderService _instance =
      SmartReminderService._internal();
  factory SmartReminderService() => _instance;
  SmartReminderService._internal();

  Timer? _timer;
  int _notificationId = 100;

  void init() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _checkAll());
  }

  void _checkAll() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    await _checkHeart(now, prefs);
    await _checkMeditation(now, prefs);
    await _checkSleep(now, prefs);
  }

  Future<void> _checkHeart(DateTime now, SharedPreferences prefs) async {
    const lastKey = 'last_heart_reminder';
    final last = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(lastKey) ?? 0);
    if (now.difference(last).inHours < 3) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final todayKey =
        '${now.year}_${now.month}_${now.day}';
    final bpmKey = 'heart_rate_$todayKey';
    final lastBpm = prefs.getInt(bpmKey) ?? 0;

    if (lastBpm > 0) return;

    _sendNotification(
      title: NotificationStrings.heartReminderTitle,
      body: NotificationStrings.heartReminderBody,
    );
    await prefs.setInt(lastKey, now.millisecondsSinceEpoch);
  }

  Future<void> _checkMeditation(DateTime now, SharedPreferences prefs) async {
    const lastKey = 'last_meditation_reminder';
    final last = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(lastKey) ?? 0);
    if (now.difference(last).inHours < 24) return;
    if (now.hour < 18 || now.hour > 23) return;

    _sendNotification(
      title: NotificationStrings.meditationReminderTitle,
      body: NotificationStrings.meditationReminderBody,
    );
    await prefs.setInt(lastKey, now.millisecondsSinceEpoch);
  }

  Future<void> _checkSleep(DateTime now, SharedPreferences prefs) async {
    const lastKey = 'last_sleep_reminder';
    final last = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(lastKey) ?? 0);
    if (now.difference(last).inHours < 24) return;
    if (now.hour < 22 || now.hour > 3) return;

    _sendNotification(
      title: NotificationStrings.sleepReminderTitle,
      body: NotificationStrings.sleepReminderBody,
    );
    await prefs.setInt(lastKey, now.millisecondsSinceEpoch);
  }

  void _sendNotification({
    required String title,
    required String body,
  }) {
    _notificationId++;
    NotificationService().showNotification(
      id: _notificationId,
      title: title,
      body: body,
    );
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
