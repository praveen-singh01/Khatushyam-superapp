import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/media/device_media_service.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';
import '../domain/app_alarm.dart';
import 'alarms_providers.dart';

class AlarmsFeatureScreen extends ConsumerStatefulWidget {
  const AlarmsFeatureScreen({super.key});

  @override
  ConsumerState<AlarmsFeatureScreen> createState() =>
      _AlarmsFeatureScreenState();
}

class _AlarmsFeatureScreenState extends ConsumerState<AlarmsFeatureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alarmSchedulerProvider).ensurePermissions();
    });
  }

  Future<void> _openCreate() async {
    // Alarm feature is free for now (testing).
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateAlarmSheet(),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm set ho gaya 🙏')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alarms = ref.watch(alarmsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.featureAartiAlarms),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed:
              () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Alarm jodein'),
      ),
      body: AsyncBody(
        value: alarms,
        onRetry: () => ref.invalidate(alarmsControllerProvider),
        builder: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 100),
              children: [
                Icon(
                  Icons.alarm_rounded,
                  size: 64,
                  color: AppColors.orange.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Abhi koi alarm nahi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ringtone choose karke alarm set karein. Trigger hone par wahi tone bajegi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _AlarmCard(alarm: items[index]);
            },
          );
        },
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard({required this.alarm});

  final AppAlarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(alarmsControllerProvider.notifier);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: alarm.hour,
                        minute: alarm.minute,
                      ),
                    );
                    if (time == null) return;
                    await controller.updateTime(
                      alarm.id,
                      time.hour,
                      time.minute,
                    );
                  },
                  child: Text(
                    alarm.timeLabel,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: alarm.enabled ? AppColors.ink : AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
              Switch.adaptive(
                value: alarm.enabled,
                activeColor: AppColors.orange,
                onChanged: (v) => controller.toggle(alarm.id, v),
              ),
            ],
          ),
          if (alarm.label.trim().isNotEmpty) ...[
            Text(
              alarm.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            alarm.ringtoneTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                selected: alarm.repeatDaily,
                label: const Text('Har din'),
                selectedColor: AppColors.orangeSoft,
                checkmarkColor: AppColors.orangeDeep,
                onSelected: (v) => controller.setRepeatDaily(alarm.id, v),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => controller.delete(alarm.id),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateAlarmSheet extends ConsumerStatefulWidget {
  const _CreateAlarmSheet();

  @override
  ConsumerState<_CreateAlarmSheet> createState() => _CreateAlarmSheetState();
}

class _CreateAlarmSheetState extends ConsumerState<_CreateAlarmSheet> {
  late TimeOfDay _time;
  bool _repeatDaily = true;
  MediaAsset? _ringtone;
  final _labelCtrl = TextEditingController();
  final _media = DeviceMediaService();
  bool _saving = false;
  bool _previewBusy = false;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _time = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
  }

  @override
  void dispose() {
    _media.stopPreview();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(MediaAsset item) async {
    final url = item.url;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio link uplabdh nahi')),
      );
      return;
    }
    try {
      if (_playingId == item.id) {
        await _media.stopPreview();
        if (!mounted) return;
        setState(() {
          _playingId = null;
          _previewBusy = false;
        });
        return;
      }
      setState(() {
        _previewBusy = true;
        _playingId = item.id;
        _ringtone = item;
      });
      final ok = await _media.previewSound(url: url);
      if (!mounted) return;
      setState(() {
        _previewBusy = false;
        if (!ok) _playingId = null;
      });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Play nahi ho saka')),
        );
      }
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _previewBusy = false;
        _playingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App poori tarah restart karein aur phir try karein'),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _previewBusy = false;
        _playingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Play nahi ho saka')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewBusy = false;
        _playingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Play nahi ho saka')),
      );
    }
  }

  Future<void> _save() async {
    final tone = _ringtone;
    if (tone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle ringtone choose karein')),
      );
      return;
    }
    await _media.stopPreview();
    setState(() {
      _saving = true;
      _playingId = null;
    });
    try {
      await ref.read(alarmsControllerProvider.notifier).create(
        hour: _time.hour,
        minute: _time.minute,
        repeatDaily: _repeatDaily,
        ringtone: tone,
        label: _labelCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alarm set nahi ho saka: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringtones = ref.watch(ringtonesProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Naya alarm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SoftCard(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _time.format(context),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Text('Time badlein'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'Jaise: Mangala aarti',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _repeatDaily,
              activeColor: AppColors.orange,
              title: const Text('Har din repeat'),
              subtitle: const Text('Alarm har din isi time par bajega'),
              onChanged: (v) => setState(() => _repeatDaily = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Ringtone choose karein',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncBody(
                value: ringtones,
                onRetry: () => ref.invalidate(ringtonesProvider),
                builder: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Abhi koi ringtone nahi mili'),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = _ringtone?.id == item.id;
                      final playing = _playingId == item.id;
                      return SoftCard(
                        color:
                            selected ? AppColors.orangeSoft : AppColors.surface,
                        onTap: () => setState(() => _ringtone = item),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (item.subtitle.isNotEmpty)
                                    Text(
                                      item.subtitle,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: playing ? 'Rokein' : 'Sunein',
                              onPressed:
                                  _previewBusy && !playing
                                      ? null
                                      : () => _togglePreview(item),
                              icon:
                                  playing && _previewBusy
                                      ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.orange,
                                        ),
                                      )
                                      : Icon(
                                        playing
                                            ? Icons.stop_circle_rounded
                                            : Icons.play_circle_filled_rounded,
                                        color: AppColors.orange,
                                        size: 32,
                                      ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                minimumSize: const Size(double.infinity, 52),
              ),
              child:
                  _saving
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Alarm set karein'),
            ),
          ],
        ),
      ),
    );
  }
}
