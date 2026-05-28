import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background FCM message: ${message.messageId}');

  try {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('splash');
    const settings = InitializationSettings(android: androidSettings);
    await plugin.initialize(settings);

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'fcm_channel',
            'Push Notifications',
            description: 'Push notifications from server',
            importance: Importance.high,
          ),
        );

    final title = message.notification?.title ?? 'Health Tracker';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    await plugin.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_channel',
          'Push Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['route'],
    );
  } catch (e) {
    log('Error in FCM background handler: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _saveToken(messaging);

      messaging.onTokenRefresh.listen((newToken) {
        log('FCM Token refreshed: $newToken');
        _persistToken(newToken);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        log('App opened from terminated state via notification: ${initialMessage.messageId}');
      }
    } catch (e) {
      log('FcmService.initialize error: $e');
    }
  }

  Future<void> _saveToken(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    log('FCM Token: $token');
    if (token != null) {
      await _persistToken(token);
    }
  }

  Future<void> _persistToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      log('Failed to persist FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    log('Foreground FCM message: ${message.messageId}');

    final title = message.notification?.title ?? 'Health Tracker';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    NotificationService().showNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: message.data['route'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    log('Notification tapped: ${message.messageId}');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}
