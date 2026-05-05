import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'health_status_channel',
            'Health Status',
            description: 'Shows steps and heart rate',
            importance: Importance.high,
          ),
        );
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> showHealthStatusNotification({
    required int steps,
    required int stepGoal,
    int? bpm,
    String? heartStatus,
  }) async {
    final hasPermission = await Permission.notification.isGranted;
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('Notification permission not granted');
        return;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'health_status_channel',
      'Health Status',
      channelDescription: 'Shows steps and heart rate',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      icon: 'splash',
    );

    final details = NotificationDetails(android: androidDetails);

    final stepProgress = ((steps / stepGoal) * 100).round();
    
    String bpmText = '';
    if (bpm != null && bpm > 0) {
      String bpmIcon;
      if (bpm < 60) {
        bpmIcon = '🫀';
      } else if (bpm > 100) {
        bpmIcon = '❤️';
      } else {
        bpmIcon = '💚';
      }
      bpmText = '\n$bpmIcon $bpm BPM';
    }

    final body = '🚶 $steps/$stepGoal bước ($stepProgress%)$bpmText';

    await _notifications.show(
      0,
      'Health Tracker',
      body,
      details,
      payload: 'health_status',
    );
    
    debugPrint('Notification shown: $body');
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
      '🎉 Chúc mừng!',
      'Đã đạt mục tiêu $goal bước/ngày!',
      details,
      payload: 'goal',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}