import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../subscription/presentation/premium_gate.dart';

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
  });

  final PosterItem poster;
  final String displayName;
  final String subtitle;
  final File? userPhoto;
  final Future<void> Function() onPickPhoto;
  final VoidCallback onEditNamePlate;

  @override
  ConsumerState<PosterComposeCard> createState() => _PosterComposeCardState();
}

class _PosterComposeCardState extends ConsumerState<PosterComposeCard> {
  final _boundaryKey = GlobalKey();
  bool _includePhoto = true;
  bool _busy = false;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final posterUrl = widget.poster.url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: RepaintBoundary(
            key: _boundaryKey,
            child: Material(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.none,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          posterUrl.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: posterUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (_, __) => const ColoredBox(
                                      color: Color(0xFFEDE4D5),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (_, __, ___) => const ColoredBox(
                                      color: Color(0xFFEDE4D5),
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                              )
                              : const ColoredBox(color: Color(0xFFFFE8D6)),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                      clipBehavior: Clip.none,
                      child: _NamePlate(
                        name: widget.displayName,
                        subtitle: widget.subtitle,
                        showPhoto: _includePhoto,
                        photo: widget.userPhoto,
                        onPhotoTap: () => widget.onPickPhoto(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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

class _NamePlate extends StatelessWidget {
  const _NamePlate({
    required this.name,
    required this.subtitle,
    required this.showPhoto,
    required this.photo,
    required this.onPhotoTap,
  });

  final String name;
  final String subtitle;
  final bool showPhoto;
  final File? photo;
  final VoidCallback onPhotoTap;

  static const double photoWidth = 148;
  static const double photoHeight = 168;
  // Keep the orange name-plate compact; extra photo height overlaps the poster.
  static const double plateHeightWithPhoto = 70;
  static const double plateHeightNoPhoto = 56;

  @override
  Widget build(BuildContext context) {
    final plateHeight =
        showPhoto ? plateHeightWithPhoto : plateHeightNoPhoto;

    return SizedBox(
      height: plateHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.orange,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  12,
                  showPhoto ? photoWidth + 18 : 14,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showPhoto)
            Positioned(
              right: 0,
              // Flush to the bottom-right corner; top overlaps the poster.
              bottom: 0,
              child: Material(
                // Transparent so cutout PNGs sit on the poster (no white box).
                color: Colors.transparent,
                elevation: photo == null ? 2 : 0,
                shadowColor: Colors.black45,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onPhotoTap,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: photoWidth,
                    height: photoHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child:
                              photo == null
                                  ? DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F1EA),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_a_photo_outlined,
                                          color: AppColors.orange,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .posterAddPhoto,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppColors.inkMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : Image.file(
                                    photo!,
                                    fit: BoxFit.contain,
                                    width: photoWidth,
                                    height: photoHeight,
                                    filterQuality: FilterQuality.high,
                                  ),
                        ),
                        // Edit badge hidden for now — tapping the photo
                        // already opens change-photo via InkWell above.
                        // if (photo != null)
                        //   Positioned(
                        //     right: 2,
                        //     top: 2,
                        //     child: Container(
                        //       width: 22,
                        //       height: 22,
                        //       alignment: Alignment.center,
                        //       decoration: BoxDecoration(
                        //         color: AppColors.orange,
                        //         shape: BoxShape.circle,
                        //         border: Border.all(
                        //           color: Colors.white,
                        //           width: 1.5,
                        //         ),
                        //       ),
                        //       child: const Icon(
                        //         Icons.edit_rounded,
                        //         color: Colors.white,
                        //         size: 11,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
