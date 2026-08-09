import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/theme/app_colors.dart';

class PosterEditorScreen extends StatefulWidget {
  const PosterEditorScreen({super.key, required this.poster});

  final PosterItem poster;

  @override
  State<PosterEditorScreen> createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();
  File? _userPhoto;
  bool _busy = false;

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() => _userPhoto = File(picked.path));
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    if (_userPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.posterAddPhotoFirst)),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
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
          text: widget.poster.title,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final posterUrl = widget.poster.url;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(widget.poster.title)),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _aspectRatio(),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (posterUrl.isNotEmpty)
                            CachedNetworkImage(
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
                          else
                            const ColoredBox(
                              color: Color(0xFFFFB347),
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: _UserPhotoBadge(
                              photo: _userPhoto,
                              onTap: _pickPhoto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.posterHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _pickPhoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(l10n.posterAddPhoto),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _share,
                          icon:
                              _busy
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.share_rounded),
                          label: Text(l10n.posterShare),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _aspectRatio() {
    final w = widget.poster.width;
    final h = widget.poster.height;
    if (w != null && h != null && w > 0 && h > 0) {
      return w / h;
    }
    return 3 / 4;
  }
}

class _UserPhotoBadge extends StatelessWidget {
  const _UserPhotoBadge({required this.photo, required this.onTap});

  final File? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 84.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child:
              photo == null
                  ? const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.orange,
                  )
                  : ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(photo!, fit: BoxFit.cover),
                  ),
        ),
      ),
    );
  }
}
