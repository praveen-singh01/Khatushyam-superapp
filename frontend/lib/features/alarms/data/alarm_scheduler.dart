import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/app_alarm.dart';

const kDefaultAlarmAsset = 'assets/sounds/default_alarm.m4a';

class AlarmScheduler {
  AlarmScheduler({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _channel = MethodChannel('khatushyam/device_media');

  static DateTime nextOccurrence(int hour, int minute, {DateTime? from}) {
    final now = from ?? DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now.add(const Duration(seconds: 2)))) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  Future<void> ensurePermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('requestAlarmPermissions');
    } catch (_) {
      // Best-effort; Alarm.set still proceeds with manifest permissions.
    }
  }

  Future<String> cacheRingtone({
    required String id,
    required String? url,
  }) async {
    if (url == null || url.isEmpty) return kDefaultAlarmAsset;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final alarmsDir = Directory('${dir.path}/alarm_sounds');
      if (!await alarmsDir.exists()) {
        await alarmsDir.create(recursive: true);
      }
      final uri = Uri.parse(url);
      final ext =
          uri.pathSegments.isNotEmpty && uri.pathSegments.last.contains('.')
              ? uri.pathSegments.last.split('.').last
              : 'm4a';
      final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${alarmsDir.path}/$safeId.$ext');
      if (!await file.exists() || await file.length() < 100) {
        await _dio.download(url, file.path);
      }
      return file.path;
    } catch (_) {
      return kDefaultAlarmAsset;
    }
  }

  Future<void> schedule(AppAlarm alarm) async {
    if (!alarm.enabled) {
      await cancel(alarm.id);
      return;
    }
    await ensurePermissions();
    final audioPath =
        alarm.localAudioPath ??
        await cacheRingtone(id: alarm.ringtoneId, url: alarm.ringtoneUrl);
    final when = nextOccurrence(alarm.hour, alarm.minute);
    final title =
        alarm.label.trim().isEmpty ? 'Khatu Shyam Alarm' : alarm.label.trim();
    final body = '${alarm.ringtoneTitle} · ${alarm.timeLabel}';

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: alarm.id,
        dateTime: when,
        assetAudioPath: audioPath,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.9,
          fadeDuration: const Duration(seconds: 3),
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: title,
          body: body,
          stopButton: 'Rokein',
        ),
        payload: alarm.id.toString(),
      ),
    );
  }

  Future<void> cancel(int id) async {
    try {
      await Alarm.stop(id);
    } catch (_) {}
  }

  Future<void> rescheduleAll(List<AppAlarm> alarms) async {
    for (final alarm in alarms) {
      if (alarm.enabled) {
        await schedule(alarm);
      } else {
        await cancel(alarm.id);
      }
    }
  }
}
