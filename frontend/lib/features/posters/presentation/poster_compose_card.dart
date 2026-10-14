import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../subscription/presentation/premium_gate.dart';
import 'poster_profile_store.dart';

/// Wins the gesture arena immediately so ListView scroll doesn't steal drags.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// One poster row on the main Posters tab — same look as the share preview.
class PosterComposeCard extends ConsumerStatefulWidget {
  const PosterComposeCard({
    super.key,
    required this.poster,
    required this.displayName,
    required this.subtitle,
    required this.userPhoto,
    required this.onPickPhoto,
    required this.onEditNamePlate,
    this.photoScale = 1.0,
    this.photoOffsetX = 0.0,
    this.photoOffsetY = 0.0,
    this.onPhotoTransform,
  });

  final PosterItem poster;
  final String displayName;
  final String subtitle;
  final File? userPhoto;
  final Future<void> Function() onPickPhoto;
  final VoidCallback onEditNamePlate;
  final double photoScale;
  final double photoOffsetX;
  final double photoOffsetY;
  final void Function(double scale, double offsetX, double offsetY)?
      onPhotoTransform;

  static const photoWidth = 148.0;
  static const photoHeight = 168.0;
  static const plateHeight = 56.0;

  @override
  ConsumerState<PosterComposeCard> createState() => _PosterComposeCardState();
}

class _PosterComposeCardState extends ConsumerState<PosterComposeCard> {
  final _boundaryKey = GlobalKey();
  bool _includePhoto = true;
  bool _busy = false;

  late double _scale;
  late double _offsetX;
  late double _offsetY;

  @override
  void initState() {
    super.initState();
    _scale = widget.photoScale;
    _offsetX = widget.photoOffsetX;
    _offsetY = widget.photoOffsetY;
  }

  @override
  void didUpdateWidget(covariant PosterComposeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't clobber in-progress local drags unless props actually changed
    // from outside (e.g. new photo reset).
    if (oldWidget.photoScale != widget.photoScale) {
      _scale = widget.photoScale;
    }
    if (oldWidget.photoOffsetX != widget.photoOffsetX) {
      _offsetX = widget.photoOffsetX;
    }
    if (oldWidget.photoOffsetY != widget.photoOffsetY) {
      _offsetY = widget.photoOffsetY;
    }
    if (oldWidget.userPhoto?.path != widget.userPhoto?.path) {
      _scale = widget.photoScale;
      _offsetX = widget.photoOffsetX;
      _offsetY = widget.photoOffsetY;
    }
  }

  void _persistTransform() {
    widget.onPhotoTransform?.call(_scale, _offsetX, _offsetY);
  }

  void _applyMove(Offset delta) {
    setState(() {
      _offsetX = (_offsetX + delta.dx).clamp(-48, 120);
      _offsetY = (_offsetY + delta.dy).clamp(-48, 160);
    });
  }

  void _applyResize(Offset delta) {
    final step = (delta.dx - delta.dy) / 160;
    setState(() {
      _scale = (_scale + step).clamp(
        PosterProfileController.minPhotoScale,
        PosterProfileController.maxPhotoScale,
      );
    });
  }

  Future<void> _share({required bool withPhoto}) async {
    if (!requirePremiumOrOpenPaywall(context, ref)) return;

    final l10n = AppLocalizations.of(context)!;
    if (withPhoto && widget.userPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.posterAddPhotoFirst)),
      );
      return;
    }
    if (_busy) return;

    final previousInclude = _includePhoto;
    setState(() {
      _busy = true;
      _includePhoto = withPhoto && widget.userPhoto != null;
    });

    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('compose boundary missing');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('encode failed');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/khatu-poster-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path, mimeType: 'image/png', name: 'khatu-poster.png'),
          ],
          text: widget.displayName,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _includePhoto = previousInclude;
        });
      }
    }
  }

  Widget _buildPosterImage(String posterUrl) {
    if (posterUrl.isEmpty) {
      return const ColoredBox(color: Color(0xFFFFE8D6));
    }
    return CachedNetworkImage(
      imageUrl: posterUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      placeholder:
          (_, __) => const ColoredBox(
            color: Color(0xFFEDE4D5),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      errorWidget:
          (_, __, ___) => const ColoredBox(
            color: Color(0xFFEDE4D5),
            child: Icon(Icons.broken_image_outlined),
          ),
    );
  }

  Widget _buildOrangePlate({required double textRightPad}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      child: ColoredBox(
        color: AppColors.orange,
        child: SizedBox(
          height: PosterComposeCard.plateHeight,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 8, textRightPad, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserPhoto({required bool interactive}) {
    final w = PosterComposeCard.photoWidth * _scale;
    final h = PosterComposeCard.photoHeight * _scale;
    final photo = widget.userPhoto;

    if (photo == null) {
      return Material(
        color: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => widget.onPickPhoto(),
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1EA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: SizedBox(
              width: w,
              height: h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.orange,
                    size: math.max(18, 26 * _scale),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.posterAddPhoto,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: math.max(8, 10 * _scale),
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final image = Image.file(
      photo,
      fit: BoxFit.contain,
      width: w,
      height: h,
      filterQuality: FilterQuality.high,
    );

    if (!interactive) return image;

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _EagerPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
              () => _EagerPanGestureRecognizer(),
              (_EagerPanGestureRecognizer instance) {
                instance.onUpdate = (DragUpdateDetails details) {
                  _applyMove(details.delta);
                };
                instance.onEnd = (DragEndDetails details) {
                  _persistTransform();
                };
              },
            ),
      },
      child: image,
    );
  }

  Widget _buildResizeHandle() {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _EagerPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
              () => _EagerPanGestureRecognizer(),
              (_EagerPanGestureRecognizer instance) {
                instance.onUpdate = (DragUpdateDetails details) {
                  _applyResize(details.delta);
                };
                instance.onEnd = (DragEndDetails details) {
                  _persistTransform();
                };
              },
            ),
      },
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.open_in_full_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final posterUrl = widget.poster.url;
    final showPhoto = _includePhoto;
    final photoW = PosterComposeCard.photoWidth * _scale;
    final photoH = PosterComposeCard.photoHeight * _scale;
    final textRightPad = showPhoto ? photoW + 12 : 12.0;
    final photoRight = 8 - _offsetX;
    final photoBottom = 8 - _offsetY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _buildPosterImage(posterUrl),
                          ),
                        ),
                        _buildOrangePlate(textRightPad: textRightPad),
                      ],
                    ),
                    if (showPhoto)
                      Positioned(
                        right: photoRight,
                        bottom: photoBottom,
                        child: _buildUserPhoto(interactive: false),
                      ),
                  ],
                ),
              ),
              // Interactive overlays (excluded from share via sibling of boundary).
              if (showPhoto && !_busy) ...[
                Positioned(
                  right: photoRight,
                  bottom: photoBottom,
                  child: SizedBox(
                    width: photoW,
                    height: photoH,
                    child: _buildUserPhoto(interactive: true),
                  ),
                ),
                Positioned(
                  right: photoRight - 6,
                  bottom: photoBottom - 6,
                  child: _buildResizeHandle(),
                ),
              ],
            ],
          ),
        ),
        if (widget.userPhoto != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.photo_size_select_large_rounded,
                  size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Size',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _scale,
                  min: PosterProfileController.minPhotoScale,
                  max: PosterProfileController.maxPhotoScale,
                  activeColor: AppColors.orange,
                  onChanged: (v) => setState(() => _scale = v),
                  onChangeEnd: (_) => _persistTransform(),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _share(withPhoto: true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            icon:
                _busy
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.share_rounded),
            label: Text(l10n.posterShareWithPhoto),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _share(withPhoto: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l10n.posterShareWithoutPhoto),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : widget.onEditNamePlate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l10n.posterEditNamePlate),
              ),
            ),
          ],
        ),
        if (widget.userPhoto != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => widget.onPickPhoto(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.posterChangePhoto),
          ),
        ],
      ],
    );
  }
}
