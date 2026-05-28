import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:health_tracker/shared/services/notification_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

class Reminder {
  final String id;
  String title;
  String subtitle;
  int hour;
  int minute;
  bool enabled;

  Reminder({
    String? id,
    required this.title,
    required this.subtitle,
    required this.hour,
    required this.minute,
    this.enabled = true,
  }) : id = id ?? const Uuid().v4();

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        enabled: json['enabled'] as bool,
      );

  Reminder copyWith({
    String? title,
    String? subtitle,
    int? hour,
    int? minute,
    bool? enabled,
  }) =>
      Reminder(
        id: id,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
      );
}

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  static const String _storageKey = 'health_reminders';
  bool _tzInitialized = false;

  final FlutterLocalNotificationsPlugin _plugin =
      NotificationService().plugin;

  List<Reminder> _reminders = [];
  bool _loaded = false;

  Future<void> _ensureTz() async {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  Future<List<Reminder>> getReminders() async {
    if (!_loaded) await _load();
    return List.unmodifiable(_reminders);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _reminders = list
            .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _reminders = _defaultReminders();
      }
      await _rescheduleAll();
      _loaded = true;
    } catch (e) {
      log('ReminderService._load error: $e');
      _reminders = _defaultReminders();
      _loaded = true;
    }
  }

  List<Reminder> _defaultReminders() {
    final t = NotificationStrings();
    return [
      Reminder(
        title: t.defaultDrinkWater,
        subtitle: t.defaultDrinkWaterSub,
        hour: 9,
        minute: 0,
      ),
      Reminder(
        title: t.defaultWalk,
        subtitle: t.defaultWalkSub,
        hour: 6,
        minute: 30,
      ),
      Reminder(
        title: t.defaultHeartRate,
        subtitle: t.defaultHeartRateSub,
        hour: 8,
        minute: 0,
      ),
      Reminder(
        title: t.defaultMeditation,
        subtitle: t.defaultMeditationSub,
        hour: 20,
        minute: 0,
      ),
      Reminder(
        title: t.defaultSleep,
        subtitle: t.defaultSleepSub,
        hour: 22,
        minute: 0,
      ),
    ];
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    await _persist();
    if (reminder.enabled) await _schedule(reminder);
  }

  Future<void> updateReminder(Reminder updated) async {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index == -1) return;
    _reminders[index] = updated;
    await _persist();
    await _cancel(updated.id);
    if (updated.enabled) await _schedule(updated);
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _reminders[index].enabled = enabled;
    await _persist();
    if (enabled) {
      await _schedule(_reminders[index]);
    } else {
      await _cancel(id);
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _persist();
    await _cancel(id);
  }

  Future<void> _schedule(Reminder reminder) async {
    try {
      await _ensureTz();
      final now = DateTime.now();
      final location = tz.local;
      var scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Health Reminders',
        channelDescription: 'Scheduled health reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      await _plugin.zonedSchedule(
        reminder.id.hashCode,
        reminder.title,
        reminder.subtitle,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      log('Scheduled reminder: ${reminder.title} at ${reminder.hour}:${reminder.minute}');
    } catch (e) {
      log('ReminderService._schedule error: $e');
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await _plugin.cancel(id.hashCode);
    } catch (e) {
      log('ReminderService._cancel error: $e');
    }
  }

  Future<void> _rescheduleAll() async {
    for (final r in _reminders) {
      if (r.enabled) await _schedule(r);
    }
  }
}
