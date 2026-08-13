import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/media/device_media_service.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../subscription/presentation/premium_gate.dart';

Future<void> openWallpaperViewer(
  BuildContext context, {
  required MediaAsset asset,
  List<MediaAsset>? assets,
  int initialIndex = 0,
}) async {
  final list = assets ?? [asset];
  final index = assets == null
      ? 0
      : initialIndex.clamp(0, list.isEmpty ? 0 : list.length - 1);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => WallpaperCarouselPage(
        assets: list,
        initialIndex: index,
      ),
    ),
  );
}

/// 3D cover-flow wallpaper browser — swipe to flip through cards.
class WallpaperCarouselPage extends ConsumerStatefulWidget {
  const WallpaperCarouselPage({
    super.key,
    required this.assets,
    this.initialIndex = 0,
    this.showCloseButton = true,
  });

  final List<MediaAsset> assets;
  final int initialIndex;
  final bool showCloseButton;

  @override
  ConsumerState<WallpaperCarouselPage> createState() =>
      _WallpaperCarouselPageState();
}

class _WallpaperCarouselPageState extends ConsumerState<WallpaperCarouselPage> {
  final _media = DeviceMediaService();
  late final PageController _pageController;
  late double _page;
  late int _index;
  bool _busy = false;

  MediaAsset? get _current =>
      widget.assets.isEmpty ? null : widget.assets[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(
      0,
      widget.assets.isEmpty ? 0 : widget.assets.length - 1,
    );
    _page = _index.toDouble();
    _pageController = PageController(
      initialPage: _index,
      viewportFraction: 0.72,
    );
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _pageController.page;
    if (page == null) return;
    setState(() {
      _page = page;
      _index = page.round().clamp(0, widget.assets.length - 1);
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _set(WallpaperTargetChoice target) async {
    if (!requirePremiumOrOpenPaywall(context, ref)) return;

    final url = _current?.url;
    if (url == null || url.isEmpty) {
      _toast('Wallpaper link uplabdh nahi');
      return;
    }
    if (!_media.isAndroid) {
      _toast('Wallpaper set karna Android par uplabdh hai');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await _media.setWallpaper(url: url, target: target);
      if (!mounted) return;
      _toast(ok ? 'Wallpaper set ho gaya 🙏' : 'Set nahi ho saka');
    } on PlatformException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? 'Wallpaper set nahi ho saka');
    } on MissingPluginException {
      if (!mounted) return;
      _toast('App restart karein (full restart) aur phir set karein');
    } catch (e) {
      if (!mounted) return;
      _toast('Truti: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickTarget() async {
    if (!requirePremiumOrOpenPaywall(context, ref)) return;

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
                  'Wallpaper kahan set karein?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.home_rounded,
                    color: AppColors.orange,
                  ),
                  title: const Text('Home screen'),
                  onTap:
                      () => Navigator.pop(context, WallpaperTargetChoice.home),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.orange,
                  ),
                  title: const Text('Lock screen'),
                  onTap:
                      () => Navigator.pop(context, WallpaperTargetChoice.lock),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.orange,
                  ),
                  title: const Text('Dono'),
                  onTap:
                      () => Navigator.pop(context, WallpaperTargetChoice.both),
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
    final l10n = AppLocalizations.of(context)!;
    final assets = widget.assets;
    final title = _current?.title ?? l10n.featureWallpapers;
    final count = assets.length;
    final bgUrl = _current?.url;

    return Scaffold(
      backgroundColor: const Color(0xFF1A120C),
      body: assets.isEmpty
          ? Center(
              child: Text(
                l10n.errorGeneric,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // Soft blurred backdrop from current wallpaper
                if (bgUrl != null && bgUrl.isNotEmpty)
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: Image.network(
                        bgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1A120C).withValues(alpha: 0.55),
                          const Color(0xFF2A1810).withValues(alpha: 0.72),
                          const Color(0xFF1A120C).withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Row(
                          children: [
                            if (widget.showCloseButton)
                              IconButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutes.home);
                                  }
                                },
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const SizedBox(width: 48),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    l10n.featureWallpapers,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 56,
                              child: Text(
                                count > 0 ? '${_index + 1}/$count' : '',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: count,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _CoverFlowCard(
                              asset: assets[index],
                              page: _page,
                              index: index,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Column(
                          children: [
                            if (count > 1) ...[
                              _PageDots(count: count, index: _index),
                              const SizedBox(height: 8),
                              Text(
                                'Swipe karke agla wallpaper dekhein',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_busy)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: CircularProgressIndicator(
                                  color: AppColors.orange,
                                ),
                              )
                            else
                              FilledButton.icon(
                                onPressed: _pickTarget,
                                icon: const Icon(Icons.wallpaper_rounded),
                                label: Text(l10n.setWallpaper),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CoverFlowCard extends StatelessWidget {
  const _CoverFlowCard({
    required this.asset,
    required this.page,
    required this.index,
  });

  final MediaAsset asset;
  final double page;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delta = (page - index).clamp(-1.5, 1.5);
    final abs = delta.abs();
    // Y-axis tilt + slight scale for cover-flow depth.
    final rotateY = delta * 0.55;
    final scale = 1 - (abs * 0.14);
    final translateY = abs * 18;
    final opacity = (1 - abs * 0.35).clamp(0.45, 1.0);

    final url = asset.url;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..translate(0.0, translateY)
          ..rotateY(rotateY)
          ..scale(scale),
        child: Opacity(
          opacity: opacity,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: Offset(delta * 12, 18),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.18 * (1 - abs)),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (url != null && url.isNotEmpty)
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const ColoredBox(
                              color: Color(0xFF3A2418),
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                              ),
                            ),
                      )
                    else
                      const ColoredBox(
                        color: Color(0xFF3A2418),
                        child: Center(
                          child: Icon(
                            Icons.wallpaper,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                    // Phone bezel hint
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Fake status notch bar for “phone preview”
                    Positioned(
                      top: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 72,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible single-asset viewer.
class WallpaperViewerPage extends StatelessWidget {
  const WallpaperViewerPage({super.key, required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context) {
    return WallpaperCarouselPage(assets: [asset], initialIndex: 0);
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final visible = math.min(count, 12);
    final start = count <= 12 ? 0 : (index - 5).clamp(0, count - visible);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = start; i < start + visible; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color:
                  i == index
                      ? AppColors.orange
                      : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
