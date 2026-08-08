import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/media/device_media_service.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/theme/app_colors.dart';

Future<void> openWallpaperViewer(
  BuildContext context, {
  required MediaAsset asset,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => WallpaperViewerPage(asset: asset),
    ),
  );
}

class WallpaperViewerPage extends StatefulWidget {
  const WallpaperViewerPage({super.key, required this.asset});

  final MediaAsset asset;

  @override
  State<WallpaperViewerPage> createState() => _WallpaperViewerPageState();
}

class _WallpaperViewerPageState extends State<WallpaperViewerPage> {
  final _media = DeviceMediaService();
  bool _busy = false;

  Future<void> _set(WallpaperTargetChoice target) async {
    final url = widget.asset.url;
    if (url == null || url.isEmpty) {
      _toast('वॉलपेपर लिंक उपलब्ध नहीं');
      return;
    }
    if (!_media.isAndroid) {
      _toast('वॉलपेपर सेट करना Android पर उपलब्ध है');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await _media.setWallpaper(url: url, target: target);
      if (!mounted) return;
      _toast(ok ? 'वॉलपेपर सेट हो गया 🙏' : 'सेट नहीं हो सका');
    } on PlatformException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? 'वॉलपेपर सेट नहीं हो सका');
    } on MissingPluginException {
      if (!mounted) return;
      _toast('ऐप रीस्टार्ट करें (full restart) और फिर सेट करें');
    } catch (e) {
      if (!mounted) return;
      _toast('त्रुटि: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickTarget() async {
    final choice = await showModalBottomSheet<WallpaperTargetChoice>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'वॉलपेपर कहाँ सेट करें?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.home_rounded, color: AppColors.orange),
                  title: const Text('होम स्क्रीन'),
                  onTap: () => Navigator.pop(context, WallpaperTargetChoice.home),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_rounded, color: AppColors.orange),
                  title: const Text('लॉक स्क्रीन'),
                  onTap: () => Navigator.pop(context, WallpaperTargetChoice.lock),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_android_rounded, color: AppColors.orange),
                  title: const Text('दोनों'),
                  onTap: () => Navigator.pop(context, WallpaperTargetChoice.both),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice != null) await _set(choice);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.asset.url;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder:
                      (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                ),
              ),
            )
          else
            const Center(
              child: Icon(Icons.wallpaper, color: Colors.white54, size: 64),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.asset.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator(color: AppColors.orange),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _pickTarget,
                      icon: const Icon(Icons.wallpaper_rounded),
                      label: const Text('सेट करें'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
