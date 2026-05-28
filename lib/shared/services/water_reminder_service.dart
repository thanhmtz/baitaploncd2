import 'dart:convert';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:health_tracker/shared/services/notification_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

class WaterReminder {
  final String id;
  int hour;
  int minute;
  bool enabled;

  WaterReminder({
    String? id,
    required this.hour,
    required this.minute,
    this.enabled = true,
  }) : id = id ?? const Uuid().v4();

  String get timeLabel {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory WaterReminder.fromJson(Map<String, dynamic> json) => WaterReminder(
        id: json['id'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        enabled: json['enabled'] as bool,
      );
}

class WaterReminderService {
  static final WaterReminderService _instance =
      WaterReminderService._internal();
  factory WaterReminderService() => _instance;
  WaterReminderService._internal();

  static const String _storageKey = 'water_reminders';
  bool _tzReady = false;

  final FlutterLocalNotificationsPlugin _plugin =
      NotificationService().plugin;

  List<WaterReminder> _reminders = [];
  bool _loaded = false;

  Future<void> _ensureTz() async {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
  }

  Future<List<WaterReminder>> getReminders() async {
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
            .map((e) => WaterReminder.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _reminders = [
          WaterReminder(hour: 7, minute: 0),
          WaterReminder(hour: 10, minute: 0),
          WaterReminder(hour: 14, minute: 0, enabled: false),
        ];
      }
      await _rescheduleAll();
      _loaded = true;
    } catch (e) {
      log('WaterReminderService._load error: $e');
      _reminders = [
        WaterReminder(hour: 7, minute: 0),
        WaterReminder(hour: 10, minute: 0),
        WaterReminder(hour: 14, minute: 0, enabled: false),
      ];
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  Future<void> addReminder(WaterReminder r) async {
    _reminders.add(r);
    await _persist();
    if (r.enabled) await _schedule(r);
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    final i = _reminders.indexWhere((r) => r.id == id);
    if (i == -1) return;
    _reminders[i].enabled = enabled;
    await _persist();
    if (enabled) {
      await _schedule(_reminders[i]);
    } else {
      await _cancel(id);
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _persist();
    await _cancel(id);
  }

  Future<void> updateReminder(WaterReminder updated) async {
    final i = _reminders.indexWhere((r) => r.id == updated.id);
    if (i == -1) return;
    _reminders[i] = updated;
    await _persist();
    await _cancel(updated.id);
    if (updated.enabled) await _schedule(updated);
  }

  Future<void> _schedule(WaterReminder r) async {
    try {
      await _ensureTz();
      final now = DateTime.now();
      final loc = tz.local;
      var date = tz.TZDateTime(loc, now.year, now.month, now.day, r.hour, r.minute);
      if (date.isBefore(now)) date = date.add(const Duration(days: 1));

      await _plugin.zonedSchedule(
        r.id.hashCode,
        NotificationStrings.waterReminderTitle,
        NotificationStrings.waterReminderBody,
        date,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Health Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      log('WaterReminderService._schedule error: $e');
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await _plugin.cancel(id.hashCode);
    } catch (e) {
      log('WaterReminderService._cancel error: $e');
    }
  }

  Future<void> _rescheduleAll() async {
    for (final r in _reminders) {
      if (r.enabled) await _schedule(r);
    }
  }
}
