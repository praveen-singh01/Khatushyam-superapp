import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum WallpaperTargetChoice { home, lock, both }

enum RingtoneTargetChoice { ringtone, notification, alarm }

/// Applies wallpapers / system sounds on Android. iOS is unsupported by OS APIs.
class DeviceMediaService {
  DeviceMediaService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _channel = MethodChannel('khatushyam/device_media');

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  Future<File> downloadToCache(String url, {String? preferredName}) async {
    final dir = await getTemporaryDirectory();
    final uri = Uri.parse(url);
    final name = preferredName ??
        (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'media.bin');
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${dir.path}/$safeName');
    await _dio.download(url, file.path);
    return file;
  }

  Future<bool> setWallpaper({
    required String url,
    required WallpaperTargetChoice target,
  }) async {
    if (!isAndroid) {
      throw UnsupportedError('Wallpaper setting is only supported on Android.');
    }
    final file = await downloadToCache(url);
    final targetName = switch (target) {
      WallpaperTargetChoice.home => 'home',
      WallpaperTargetChoice.lock => 'lock',
      WallpaperTargetChoice.both => 'both',
    };
    final ok = await _channel.invokeMethod<bool>('setWallpaper', {
      'path': file.path,
      'target': targetName,
    });
    return ok ?? false;
  }

  Future<bool> previewSound({required String url}) async {
    if (!isAndroid) {
      throw UnsupportedError('Preview is only supported on Android.');
    }
    // Prefer local file so cleartext/local server URLs work reliably.
    final file = await downloadToCache(url);
    final ok = await _channel.invokeMethod<bool>('previewSound', {
      'path': file.path,
    });
    return ok ?? false;
  }

  Future<void> stopPreview() async {
    if (!isAndroid) return;
    await _channel.invokeMethod<bool>('stopPreview');
  }

  Future<bool> setSound({
    required String url,
    required RingtoneTargetChoice target,
    String? title,
  }) async {
    if (!isAndroid) {
      throw UnsupportedError('Ringtone setting is only supported on Android.');
    }
    final file = await downloadToCache(url);
    final type = switch (target) {
      RingtoneTargetChoice.ringtone => 'ringtone',
      RingtoneTargetChoice.notification => 'notification',
      RingtoneTargetChoice.alarm => 'alarm',
    };
    final ok = await _channel.invokeMethod<bool>('setSound', {
      'path': file.path,
      'type': type,
      'title': title ?? 'Khatu Shyam',
    });
    return ok ?? false;
  }

  Future<bool> openWriteSettings() async {
    if (!isAndroid) return false;
    final ok = await _channel.invokeMethod<bool>('openWriteSettings');
    return ok ?? false;
  }

  Future<bool> canWriteSettings() async {
    if (!isAndroid) return false;
    final ok = await _channel.invokeMethod<bool>('canWriteSettings');
    return ok ?? false;
  }
}
