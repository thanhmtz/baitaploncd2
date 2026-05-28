import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _notifications;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('notification payload: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'health_ongoing_channel',
          'Health Tracker',
          description: 'Persistent health status notification',
          importance: Importance.min,
        ),
      );

      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'water_channel',
          'Water Reminder',
          description: 'Reminds you to drink water',
          importance: Importance.high,
        ),
      );

      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'goal_channel',
          'Goal Achieved',
          description: 'Celebrates achieving your daily goal',
          importance: Importance.max,
        ),
      );

      await plugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'fcm_channel',
            'Push Notifications',
            description: 'Push notifications from server',
            importance: Importance.high,
          ),
        );

      await plugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'reminder_channel',
            'Health Reminders',
            description: 'Scheduled health reminders',
            importance: Importance.high,
          ),
        );

      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isDenied && Platform.isAndroid) {
          await Permission.notification.request();
        }
      }
    }
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> showHealthStatusNotification({
    int? bpm,
    int? systolic,
    int? diastolic,
    double? bloodSugar,
  }) async {
    if (Platform.isAndroid) {
      final hasPermission = await Permission.notification.isGranted;
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          return;
        }
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'health_ongoing_channel',
      'Health Tracker',
      channelDescription: 'Persistent health status notification',
      importance: Importance.min,
      priority: Priority.min,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    String bpmText;
    if (bpm != null && bpm > 0) {
      String icon;
      if (bpm < 60) {
        icon = '\u{1FAC0}';
      } else if (bpm > 100) {
        icon = '\u{2764}\u{FE0F}';
      } else {
        icon = '\u{1F49A}';
      }
      bpmText = '$icon $bpm BPM';
    } else {
      bpmText = '\u{1F49A} _/_ BPM';
    }

    String bpText;
    if (systolic != null && diastolic != null && systolic > 0) {
      bpText = '\u{1FA7A} $systolic/$diastolic';
    } else {
      bpText = '\u{1FA7A} _/_';
    }

    String sugarText;
    if (bloodSugar != null && bloodSugar > 0) {
      sugarText = '\u{1F489} $bloodSugar mmol/L';
    } else {
      sugarText = '\u{1F489} _/_ mmol/L';
    }

    final body = '$bpmText | $bpText | $sugarText';

    await _notifications.show(
      0,
      'Health Tracker',
      body,
      details,
      payload: 'health_status',
    );
  }

  Future<void> showGoalAchievedNotification(int steps, int goal) async {
    final androidDetails = AndroidNotificationDetails(
      'goal_channel',
      'Goal Achieved',
      channelDescription: 'Celebrates achieving your daily goal',
      importance: Importance.max,
      priority: Priority.max,
      autoCancel: true,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      3,
      '\u{1F389} Chúc mừng!',
      'Đã đạt mục tiêu $goal bước/ngày!',
      details,
      payload: 'goal',
    );
  }

  Future<void> showDrinkWaterNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'water_channel',
      'Water Reminder',
      channelDescription: 'Reminds you to drink water',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      1,
      'Drink Water!',
      'Don\'t forget to drink water',
      details,
      payload: 'water',
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'Push Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details, payload: payload);
  }

  Timer? _healthTimer;

  void startOngoingHealthNotification() {
    _healthTimer?.cancel();
    _fetchAndShowHealthSummary();
  }

  Future<void> _fetchAndShowHealthSummary() async {
    int? bpm;
    int? systolic;
    int? diastolic;
    double? bloodSugar;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final firestore = FirebaseFirestore.instance;

        final heartSnapshot = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('health_data')
            .doc('heart_rate')
            .collection('records')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (heartSnapshot.docs.isNotEmpty) {
          final data = heartSnapshot.docs.first.data();
          bpm = (data['bpm'] as num?)?.toInt();
        }

        final today = DateFormat('d-M-y').format(DateTime.now());
        final yesterday = DateFormat('d-M-y')
            .format(DateTime.now().subtract(const Duration(days: 1)));

        for (final dateStr in [today, yesterday]) {
          final diaryDoc = await firestore
              .collection('users')
              .doc(user.uid)
              .collection('diary')
              .doc(dateStr)
              .get();

          if (!diaryDoc.exists) continue;

          final diaryData = diaryDoc.data();
          if (diaryData == null) continue;

          if (diaryData.containsKey('bloodPressure') && systolic == null) {
            final bpList = diaryData['bloodPressure'] as List?;
            if (bpList != null && bpList.isNotEmpty) {
              final last = bpList.last as Map;
              systolic = (last['systolic'] as num?)?.toInt();
              diastolic = (last['diastolic'] as num?)?.toInt();
            }
          }

          if (diaryData.containsKey('bloodSugar') && bloodSugar == null) {
            final bsList = diaryData['bloodSugar'] as List?;
            if (bsList != null && bsList.isNotEmpty) {
              final last = bsList.last as Map;
              bloodSugar = (last['value'] as num?)?.toDouble();
            }
          }

          if ((systolic != null || bloodSugar != null)) break;
        }
      } catch (e) {
        debugPrint('Health summary fetch error: $e');
      }
    }

    await showHealthStatusNotification(
      bpm: bpm,
      systolic: systolic,
      diastolic: diastolic,
      bloodSugar: bloodSugar,
    );
  }

  void stopOngoingHealthNotification() {
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  Future<void> cancelHealthStatusNotification() async {
    await _notifications.cancel(0);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
