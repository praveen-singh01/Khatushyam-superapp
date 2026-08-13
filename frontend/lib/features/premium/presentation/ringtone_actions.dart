import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/device_media_service.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../subscription/presentation/premium_gate.dart';

Future<void> openRingtoneActions(
  BuildContext context, {
  required MediaAsset asset,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RingtoneSheet(asset: asset),
  );
}

class _RingtoneSheet extends ConsumerStatefulWidget {
  const _RingtoneSheet({required this.asset});

  final MediaAsset asset;

  @override
  ConsumerState<_RingtoneSheet> createState() => _RingtoneSheetState();
}

class _RingtoneSheetState extends ConsumerState<_RingtoneSheet> {
  final _media = DeviceMediaService();
  bool _busy = false;
  bool _playing = false;

  @override
  void dispose() {
    _media.stopPreview();
    super.dispose();
  }

  Future<void> _togglePreview() async {
    final url = widget.asset.url;
    if (url == null || url.isEmpty) {
      _toast('Audio link uplabdh nahi');
      return;
    }
    if (!_media.isAndroid) {
      _toast('Preview Android par uplabdh hai');
      return;
    }
    try {
      if (_playing) {
        await _media.stopPreview();
        setState(() => _playing = false);
        return;
      }
      setState(() => _busy = true);
      final ok = await _media.previewSound(url: url);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _playing = ok;
      });
      if (!ok) _toast('Play nahi ho saka');
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _busy = false;
          _playing = false;
        });
        _toast('App poori tarah restart karein aur phir koshish karein');
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _playing = false;
        });
        _toast(e.message ?? 'Play nahi ho saka');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _playing = false;
        });
        _toast('Play nahi ho saka');
      }
    }
  }

  Future<void> _set(RingtoneTargetChoice target) async {
    if (!requirePremiumOrOpenPaywall(context, ref)) return;

    final url = widget.asset.url;
    if (url == null || url.isEmpty) {
      _toast('Audio link uplabdh nahi');
      return;
    }
    if (!_media.isAndroid) {
      _toast('Ringtone set karna Android par uplabdh hai');
      return;
    }
    setState(() => _busy = true);
    try {
      await _media.stopPreview();
      setState(() => _playing = false);
      final canWrite = await _media.canWriteSettings();
      if (!canWrite) {
        if (!mounted) return;
        final go = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Anumati chahiye'),
                content: const Text(
                  'Ringtone set karne ke liye system settings badalne ki anumati on karein.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Baad mein'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Settings kholen'),
                  ),
                ],
              ),
        );
        if (go == true) await _media.openWriteSettings();
        return;
      }
      final ok = await _media.setSound(
        url: url,
        target: target,
        title: widget.asset.title,
      );
      if (!mounted) return;
      _toast(ok ? 'Set ho gaya 🙏' : 'Set nahi ho saka');
    } on MissingPluginException {
      if (!mounted) return;
      _toast('App poori tarah restart karein aur phir koshish karein');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('no_permission')) {
        await _media.openWriteSettings();
        _toast('Kripya anumati on karke phir set karein');
      } else {
        _toast('Truti: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.asset.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.asset.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _togglePreview,
              icon: Icon(_playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
              label: Text(_playing ? 'Rokein' : 'Sunein'),
            ),
            const SizedBox(height: 8),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.ring_volume_rounded, color: AppColors.orange),
                title: const Text('Phone ringtone'),
                onTap: () => _set(RingtoneTargetChoice.ringtone),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded, color: AppColors.orange),
                title: const Text('Notification tone'),
                onTap: () => _set(RingtoneTargetChoice.notification),
              ),
              ListTile(
                leading: const Icon(Icons.alarm_rounded, color: AppColors.orange),
                title: const Text('Alarm tone'),
                onTap: () => _set(RingtoneTargetChoice.alarm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
