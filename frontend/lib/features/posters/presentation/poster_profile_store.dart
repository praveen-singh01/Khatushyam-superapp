import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/auth_providers.dart';

const _kPhotoPath = 'poster_user_photo_path';
const _kDisplayName = 'poster_display_name';
const _kSubtitle = 'poster_subtitle';


class PosterProfileState {
  const PosterProfileState({
    required this.displayName,
    required this.subtitle,
    this.photoPath,
    this.isProcessingPhoto = false,
  });

  final String displayName;
  final String subtitle;
  final String? photoPath;
  final bool isProcessingPhoto;

  File? get photoFile {
    final path = photoPath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  PosterProfileState copyWith({
    String? displayName,
    String? subtitle,
    String? photoPath,
    bool? isProcessingPhoto,
    bool clearPhoto = false,
  }) =>
      PosterProfileState(
        displayName: displayName ?? this.displayName,
        subtitle: subtitle ?? this.subtitle,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
        isProcessingPhoto: isProcessingPhoto ?? this.isProcessingPhoto,
      );
}

final posterProfileProvider =
    AsyncNotifierProvider<PosterProfileController, PosterProfileState>(
      PosterProfileController.new,
    );

class PosterProfileController extends AsyncNotifier<PosterProfileState> {
  @override
  Future<PosterProfileState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final user = ref.read(authStateProvider).asData?.value;
    final authName = user?.displayName?.trim();

    final savedName = prefs.getString(_kDisplayName)?.trim();
    final savedSubtitle = prefs.getString(_kSubtitle)?.trim();
    final savedPhoto = prefs.getString(_kPhotoPath);

    var photoPath = savedPhoto;
    if (photoPath != null && !File(photoPath).existsSync()) {
      photoPath = null;
      await prefs.remove(_kPhotoPath);
    }

    return PosterProfileState(
      displayName:
          (savedName != null && savedName.isNotEmpty)
              ? savedName
              : ((authName != null && authName.isNotEmpty) ? authName : 'भक्त'),
      subtitle:
          (savedSubtitle != null && savedSubtitle.isNotEmpty)
              ? savedSubtitle
              : 'जय श्री श्याम',
      photoPath: photoPath,
    );
  }

  Future<void> setNamePlate({
    required String displayName,
    required String subtitle,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;

    final next = current.copyWith(
      displayName:
          displayName.trim().isEmpty ? current.displayName : displayName.trim(),
      subtitle: subtitle.trim().isEmpty ? current.subtitle : subtitle.trim(),
    );
    state = AsyncData(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, next.displayName);
    await prefs.setString(_kSubtitle, next.subtitle);
  }

  /// Persists an already-cropped/cutout photo after the user taps OK.
  Future<void> commitPreparedPhoto(String preparedPath) async {
    final current = state.asData?.value;
    if (current == null) return;

    final previousPath = current.photoPath;

    try {
      final prepared = File(preparedPath);
      if (!await prepared.exists()) {
        throw StateError('Prepared photo file missing');
      }

      final docs = await getApplicationDocumentsDirectory();
      File saved = prepared;

      // Cropper / gallery paths are temporary — copy into app documents.
      final alreadyDurable = preparedPath.contains('/poster_user_photo_');
      if (!alreadyDurable) {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final ext =
            preparedPath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        saved = File('${docs.path}/poster_user_photo_$stamp.$ext');
        await prepared.copy(saved.path);
      }

      final next = current.copyWith(
        photoPath: saved.path,
        isProcessingPhoto: false,
      );
      state = AsyncData(next);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPhotoPath, saved.path);

      if (previousPath != null &&
          previousPath.isNotEmpty &&
          previousPath != saved.path) {
        try {
          final old = File(previousPath);
          if (await old.exists()) await old.delete();
        } catch (_) {}
      }
    } catch (e, st) {
      debugPrint('commitPreparedPhoto failed: $e\n$st');
      rethrow;
    }
  }
}

