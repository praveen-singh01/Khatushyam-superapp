import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import 'poster_background_removal.dart';

/// Pick → crop → remove background (with loading) → confirm OK.
/// Returns the approved cutout/original file path, or null if cancelled.
Future<String?> runPosterPhotoFlow(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final picker = ImagePicker();

  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 2048,
    imageQuality: 95,
  );
  if (picked == null) return null;
  if (!context.mounted) return null;

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 92,
    maxWidth: 1600,
    maxHeight: 1600,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: l10n.posterCropTitle,
        toolbarColor: AppColors.orange,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: AppColors.orange,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
        aspectRatioPresets: const [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio3x2,
        ],
      ),
      IOSUiSettings(
        title: l10n.posterCropTitle,
        aspectRatioLockEnabled: false,
        aspectRatioPresets: const [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio3x2,
        ],
      ),
    ],
  );
  if (cropped == null) return null;
  if (!context.mounted) return null;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(width: 16),
                Expanded(child: Text(l10n.posterRemovingBackground)),
              ],
            ),
          ),
        ),
  );

  File? cutoutFile;
  File prepared;
  try {
    cutoutFile = await removePhotoBackground(cropped.path);
    if (cutoutFile != null && await cutoutFile.exists()) {
      prepared = cutoutFile;
    } else {
      prepared = File(cropped.path);
    }
  } catch (_) {
    prepared = File(cropped.path);
  }

  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop();

  final approved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.posterPreviewTitle),
        content: SizedBox(
          width: 280,
          height: 320,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEDE4D5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                prepared,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.posterCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.posterUsePhoto),
          ),
        ],
      );
    },
  );

  if (approved == true) return prepared.path;

  // Discard cutout if user cancels after preview.
  if (cutoutFile != null) {
    try {
      if (await cutoutFile.exists()) await cutoutFile.delete();
    } catch (_) {}
  }
  return null;
}
