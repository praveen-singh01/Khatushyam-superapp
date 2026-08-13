import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_alarm.dart';

class AlarmStore {
  static const _key = 'khatushyam_app_alarms_v1';

  Future<List<AppAlarm>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .whereType<Map>()
        .map((e) => AppAlarm.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) {
        final at = a.hour * 60 + a.minute;
        final bt = b.hour * 60 + b.minute;
        return at.compareTo(bt);
      });
  }

  Future<void> save(List<AppAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(alarms.map((a) => a.toJson()).toList()),
    );
  }
}
