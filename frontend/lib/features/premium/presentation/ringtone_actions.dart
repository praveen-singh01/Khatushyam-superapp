import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/media/device_media_service.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/theme/app_colors.dart';

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

class _RingtoneSheet extends StatefulWidget {
  const _RingtoneSheet({required this.asset});

  final MediaAsset asset;

  @override
  State<_RingtoneSheet> createState() => _RingtoneSheetState();
}

class _RingtoneSheetState extends State<_RingtoneSheet> {
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
      _toast('ऑडियो लिंक उपलब्ध नहीं');
      return;
    }
    if (!_media.isAndroid) {
      _toast('प्रीव्यू Android पर उपलब्ध है');
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
      if (!ok) _toast('प्ले नहीं हो सका');
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _busy = false;
          _playing = false;
        });
        _toast('ऐप पूरी तरह रीस्टार्ट करें और फिर कोशिश करें');
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _playing = false;
        });
        _toast(e.message ?? 'प्ले नहीं हो सका');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _playing = false;
        });
        _toast('प्ले नहीं हो सका');
      }
    }
  }

  Future<void> _set(RingtoneTargetChoice target) async {
    final url = widget.asset.url;
    if (url == null || url.isEmpty) {
      _toast('ऑडियो लिंक उपलब्ध नहीं');
      return;
    }
    if (!_media.isAndroid) {
      _toast('रिंगटोन सेट करना Android पर उपलब्ध है');
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
                title: const Text('अनुमति चाहिए'),
                content: const Text(
                  'रिंगटोन सेट करने के लिए सिस्टम सेटिंग्स बदलने की अनुमति चालू करें।',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('बाद में'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('सेटिंग्स खोलें'),
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
      _toast(ok ? 'सेट हो गया 🙏' : 'सेट नहीं हो सका');
    } on MissingPluginException {
      if (!mounted) return;
      _toast('ऐप पूरी तरह रीस्टार्ट करें और फिर कोशिश करें');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('no_permission')) {
        await _media.openWriteSettings();
        _toast('कृपया अनुमति चालू करके फिर सेट करें');
      } else {
        _toast('त्रुटि: $e');
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
              label: Text(_playing ? 'रोकें' : 'सुनें'),
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
                title: const Text('फोन रिंगटोन'),
                onTap: () => _set(RingtoneTargetChoice.ringtone),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded, color: AppColors.orange),
                title: const Text('नोटिफिकेशन टोन'),
                onTap: () => _set(RingtoneTargetChoice.notification),
              ),
              ListTile(
                leading: const Icon(Icons.alarm_rounded, color: AppColors.orange),
                title: const Text('अलार्म टोन'),
                onTap: () => _set(RingtoneTargetChoice.alarm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
