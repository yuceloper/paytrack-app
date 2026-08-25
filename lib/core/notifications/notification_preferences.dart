import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  final bool dayBeforeEnabled;
  final bool dueDayEnabled;
  final bool overdueEnabled;
  final bool incomeDayEnabled;
  final TimeOfDay dayBeforeTime;
  final TimeOfDay dueDayTime;
  final TimeOfDay overdueTime;
  final TimeOfDay incomeDayTime;

  const NotificationPreferences({
    this.dayBeforeEnabled = true,
    this.dueDayEnabled = true,
    this.overdueEnabled = true,
    this.incomeDayEnabled = true,
    this.dayBeforeTime = const TimeOfDay(hour: 18, minute: 0),
    this.dueDayTime = const TimeOfDay(hour: 9, minute: 0),
    this.overdueTime = const TimeOfDay(hour: 9, minute: 0),
    this.incomeDayTime = const TimeOfDay(hour: 9, minute: 0),
  });

  NotificationPreferences copyWith({
    bool? dayBeforeEnabled,
    bool? dueDayEnabled,
    bool? overdueEnabled,
    bool? incomeDayEnabled,
    TimeOfDay? dayBeforeTime,
    TimeOfDay? dueDayTime,
    TimeOfDay? overdueTime,
    TimeOfDay? incomeDayTime,
  }) {
    return NotificationPreferences(
      dayBeforeEnabled: dayBeforeEnabled ?? this.dayBeforeEnabled,
      dueDayEnabled: dueDayEnabled ?? this.dueDayEnabled,
      overdueEnabled: overdueEnabled ?? this.overdueEnabled,
      incomeDayEnabled: incomeDayEnabled ?? this.incomeDayEnabled,
      dayBeforeTime: dayBeforeTime ?? this.dayBeforeTime,
      dueDayTime: dueDayTime ?? this.dueDayTime,
      overdueTime: overdueTime ?? this.overdueTime,
      incomeDayTime: incomeDayTime ?? this.incomeDayTime,
    );
  }
}

class NotificationPreferencesStore {
  static const _dayBeforeEnabledKey = 'notification.dayBefore.enabled';
  static const _dueDayEnabledKey = 'notification.dueDay.enabled';
  static const _overdueEnabledKey = 'notification.overdue.enabled';
  static const _incomeDayEnabledKey = 'notification.incomeDay.enabled';
  static const _dayBeforeTimeKey = 'notification.dayBefore.time';
  static const _dueDayTimeKey = 'notification.dueDay.time';
  static const _overdueTimeKey = 'notification.overdue.time';
  static const _incomeDayTimeKey = 'notification.incomeDay.time';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = NotificationPreferences();

    return NotificationPreferences(
      dayBeforeEnabled: prefs.getBool(_dayBeforeEnabledKey) ?? defaults.dayBeforeEnabled,
      dueDayEnabled: prefs.getBool(_dueDayEnabledKey) ?? defaults.dueDayEnabled,
      overdueEnabled: prefs.getBool(_overdueEnabledKey) ?? defaults.overdueEnabled,
      incomeDayEnabled: prefs.getBool(_incomeDayEnabledKey) ?? defaults.incomeDayEnabled,
      dayBeforeTime: _decodeTime(prefs.getString(_dayBeforeTimeKey)) ?? defaults.dayBeforeTime,
      dueDayTime: _decodeTime(prefs.getString(_dueDayTimeKey)) ?? defaults.dueDayTime,
      overdueTime: _decodeTime(prefs.getString(_overdueTimeKey)) ?? defaults.overdueTime,
      incomeDayTime: _decodeTime(prefs.getString(_incomeDayTimeKey)) ?? defaults.incomeDayTime,
    );
  }

  Future<void> save(NotificationPreferences value) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_dayBeforeEnabledKey, value.dayBeforeEnabled),
      prefs.setBool(_dueDayEnabledKey, value.dueDayEnabled),
      prefs.setBool(_overdueEnabledKey, value.overdueEnabled),
      prefs.setBool(_incomeDayEnabledKey, value.incomeDayEnabled),
      prefs.setString(_dayBeforeTimeKey, _encodeTime(value.dayBeforeTime)),
      prefs.setString(_dueDayTimeKey, _encodeTime(value.dueDayTime)),
      prefs.setString(_overdueTimeKey, _encodeTime(value.overdueTime)),
      prefs.setString(_incomeDayTimeKey, _encodeTime(value.incomeDayTime)),
    ]);
  }

  static String _encodeTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _decodeTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }
}
