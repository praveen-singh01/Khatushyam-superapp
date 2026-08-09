import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Removes the photo background on-device (ML Kit Selfie Segmentation)
/// and writes a transparent PNG. Returns null if cutout fails.
Future<File?> removePhotoBackground(String sourcePath) async {
  final segmenter = SelfieSegmenter(
    mode: SegmenterMode.single,
    enableRawSizeMask: false,
  );

  try {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;

    final bytes = await sourceFile.readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Keep work bounded — large gallery photos OOMed / crashed cutout before.
    if (decoded.width > 1024 || decoded.height > 1024) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? 1024 : null,
        height: decoded.height > decoded.width ? 1024 : null,
      );
    }

    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final workingJpg = File('${docs.path}/poster_cutout_src_$stamp.jpg');
    await workingJpg.writeAsBytes(img.encodeJpg(decoded, quality: 90), flush: true);

    final mask = await segmenter.processImage(
      InputImage.fromFilePath(workingJpg.path),
    );
    if (mask == null || mask.confidences.isEmpty) {
      await _safeDelete(workingJpg);
      return null;
    }

    final image = decoded.convert(numChannels: 4);
    final maskW = mask.width;
    final maskH = mask.height;
    if (maskW <= 0 || maskH <= 0) {
      await _safeDelete(workingJpg);
      return null;
    }

    for (var y = 0; y < image.height; y++) {
      final my = ((y * maskH) / image.height).floor().clamp(0, maskH - 1);
      for (var x = 0; x < image.width; x++) {
        final mx = ((x * maskW) / image.width).floor().clamp(0, maskW - 1);
        final conf = mask.confidences[my * maskW + mx];
        final soft = ((conf - 0.28) / 0.55).clamp(0.0, 1.0);
        final pixel = image.getPixel(x, y);
        image.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          (soft * 255).round(),
        );
      }
    }

    final out = File('${docs.path}/poster_user_photo_$stamp.png');
    await out.writeAsBytes(img.encodePng(image), flush: true);
    await _safeDelete(workingJpg);
    return out;
  } catch (e, st) {
    debugPrint('removePhotoBackground failed: $e\n$st');
    return null;
  } finally {
    await segmenter.close();
  }
}

Future<void> _safeDelete(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
