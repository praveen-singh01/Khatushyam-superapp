import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_models.dart';
import '../data/alarm_scheduler.dart';
import '../data/alarm_store.dart';
import '../domain/app_alarm.dart';

final alarmStoreProvider = Provider<AlarmStore>((ref) => AlarmStore());

final alarmSchedulerProvider = Provider<AlarmScheduler>(
  (ref) => AlarmScheduler(),
);

final alarmsControllerProvider =
    AsyncNotifierProvider<AlarmsController, List<AppAlarm>>(
      AlarmsController.new,
    );

class AlarmsController extends AsyncNotifier<List<AppAlarm>> {
  StreamSubscription<AlarmSet>? _ringSub;

  AlarmStore get _store => ref.read(alarmStoreProvider);
  AlarmScheduler get _scheduler => ref.read(alarmSchedulerProvider);

  @override
  Future<List<AppAlarm>> build() async {
    ref.onDispose(() {
      _ringSub?.cancel();
    });
    _ringSub ??= Alarm.ringing.listen(_onRinging);
    final alarms = await _store.load();
    await _scheduler.rescheduleAll(alarms);
    return alarms;
  }

  Future<void> _persist(List<AppAlarm> alarms) async {
    await _store.save(alarms);
    state = AsyncData(alarms);
  }

  Future<void> _onRinging(AlarmSet set) async {
    if (set.alarms.isEmpty) return;
    final current = state.asData?.value ?? await _store.load();
    var changed = false;
    final next = <AppAlarm>[];
    for (final alarm in current) {
      final ringing = set.alarms.any((a) => a.id == alarm.id);
      if (!ringing) {
        next.add(alarm);
        continue;
      }
      if (alarm.repeatDaily) {
        // Re-arm for tomorrow after user stops / after fire.
        next.add(alarm);
        changed = true;
        // Delay slightly so native stop can settle, then schedule next day.
        unawaited(
          Future<void>.delayed(const Duration(seconds: 1), () async {
            if (alarm.enabled) await _scheduler.schedule(alarm);
          }),
        );
      } else {
        next.add(alarm.copyWith(enabled: false));
        changed = true;
      }
    }
    if (changed) await _persist(next);
  }

  Future<AppAlarm> create({
    required int hour,
    required int minute,
    required bool repeatDaily,
    required MediaAsset ringtone,
    String label = '',
  }) async {
    final existing = state.asData?.value ?? await _store.load();
    // alarm package forbids ids 0 and -1
    var id = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    if (id <= 0) id = 1;
    final localPath = await _scheduler.cacheRingtone(
      id: ringtone.id,
      url: ringtone.url,
    );
    final alarm = AppAlarm(
      id: id,
      hour: hour,
      minute: minute,
      enabled: true,
      repeatDaily: repeatDaily,
      ringtoneId: ringtone.id,
      ringtoneTitle: ringtone.title,
      ringtoneUrl: ringtone.url,
      localAudioPath: localPath,
      label: label,
    );
    final updated = [...existing, alarm]..sort((a, b) {
      return (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
    });
    await _persist(updated);
    await _scheduler.schedule(alarm);
    return alarm;
  }

  Future<void> toggle(int id, bool enabled) async {
    final current = state.asData?.value ?? await _store.load();
    final updated =
        current.map((a) {
          if (a.id != id) return a;
          return a.copyWith(enabled: enabled);
        }).toList();
    await _persist(updated);
    final alarm = updated.firstWhere((a) => a.id == id);
    if (enabled) {
      await _scheduler.schedule(alarm);
    } else {
      await _scheduler.cancel(id);
    }
  }

  Future<void> setRepeatDaily(int id, bool repeatDaily) async {
    final current = state.asData?.value ?? await _store.load();
    final updated =
        current.map((a) {
          if (a.id != id) return a;
          return a.copyWith(repeatDaily: repeatDaily);
        }).toList();
    await _persist(updated);
    final alarm = updated.firstWhere((a) => a.id == id);
    if (alarm.enabled) await _scheduler.schedule(alarm);
  }

  Future<void> delete(int id) async {
    final current = state.asData?.value ?? await _store.load();
    final updated = current.where((a) => a.id != id).toList();
    await _scheduler.cancel(id);
    await _persist(updated);
  }

  Future<void> updateTime(int id, int hour, int minute) async {
    final current = state.asData?.value ?? await _store.load();
    final updated =
        current.map((a) {
          if (a.id != id) return a;
          return a.copyWith(hour: hour, minute: minute);
        }).toList()
          ..sort(
            (a, b) =>
                (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
          );
    await _persist(updated);
    final alarm = updated.firstWhere((a) => a.id == id);
    if (alarm.enabled) await _scheduler.schedule(alarm);
  }
}
