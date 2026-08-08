package com.khatushyam.khatushyam_app

import android.app.WallpaperManager
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val channelName = "khatushyam/device_media"
    private var previewPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canWriteSettings" -> {
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                Settings.System.canWrite(this)
                            } else {
                                true
                            },
                        )
                    }
                    "openWriteSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    }
                    "setWallpaper" -> {
                        try {
                            val path = call.argument<String>("path")
                            val target = call.argument<String>("target") ?: "both"
                            if (path.isNullOrBlank()) {
                                result.error("bad_args", "Missing path", null)
                                return@setMethodCallHandler
                            }
                            val ok = setWallpaperFromFile(File(path), target)
                            result.success(ok)
                        } catch (e: Exception) {
                            result.error("set_failed", e.message, null)
                        }
                    }
                    "setSound" -> {
                        try {
                            val path = call.argument<String>("path")
                            val type = call.argument<String>("type") ?: "ringtone"
                            val title = call.argument<String>("title") ?: "Khatu Shyam"
                            if (path.isNullOrBlank()) {
                                result.error("bad_args", "Missing path", null)
                                return@setMethodCallHandler
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                                !Settings.System.canWrite(this)
                            ) {
                                result.error("no_permission", "WRITE_SETTINGS required", null)
                                return@setMethodCallHandler
                            }
                            val ok = setSystemSound(File(path), type, title)
                            result.success(ok)
                        } catch (e: Exception) {
                            result.error("set_failed", e.message, null)
                        }
                    }
                    "previewSound" -> {
                        try {
                            val path = call.argument<String>("path")
                            val url = call.argument<String>("url")
                            stopPreviewInternal()
                            val player = MediaPlayer()
                            var replied = false
                            fun replyOk() {
                                if (!replied) {
                                    replied = true
                                    result.success(true)
                                }
                            }
                            fun replyErr(message: String?) {
                                if (!replied) {
                                    replied = true
                                    result.error("preview_failed", message, null)
                                }
                            }
                            player.setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_MEDIA)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                    .build(),
                            )
                            when {
                                !path.isNullOrBlank() -> player.setDataSource(path)
                                !url.isNullOrBlank() -> player.setDataSource(url)
                                else -> {
                                    result.error("bad_args", "Missing path/url", null)
                                    return@setMethodCallHandler
                                }
                            }
                            player.setOnCompletionListener {
                                stopPreviewInternal()
                            }
                            player.setOnPreparedListener {
                                it.start()
                                previewPlayer = it
                                replyOk()
                            }
                            player.setOnErrorListener { _, _, _ ->
                                stopPreviewInternal()
                                replyErr("Unable to play")
                                true
                            }
                            player.prepareAsync()
                        } catch (e: Exception) {
                            stopPreviewInternal()
                            result.error("preview_failed", e.message, null)
                        }
                    }
                    "stopPreview" -> {
                        stopPreviewInternal()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        stopPreviewInternal()
        super.onDestroy()
    }

    private fun stopPreviewInternal() {
        try {
            previewPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            previewPlayer?.release()
        } catch (_: Exception) {
        }
        previewPlayer = null
    }

    private fun setWallpaperFromFile(file: File, target: String): Boolean {
        if (!file.exists()) return false
        val bitmap = decodeSampledBitmap(file) ?: return false
        return try {
            val manager = WallpaperManager.getInstance(this)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val flags = when (target) {
                    "home" -> WallpaperManager.FLAG_SYSTEM
                    "lock" -> WallpaperManager.FLAG_LOCK
                    else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                }
                manager.setBitmap(bitmap, null, true, flags)
            } else {
                manager.setBitmap(bitmap)
            }
            true
        } finally {
            if (!bitmap.isRecycled) bitmap.recycle()
        }
    }

    private fun decodeSampledBitmap(file: File): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getRealMetrics(metrics)
        val maxW = (metrics.widthPixels * 1.5).toInt().coerceAtLeast(1080)
        val maxH = (metrics.heightPixels * 1.5).toInt().coerceAtLeast(1920)

        var sample = 1
        while (bounds.outWidth / sample > maxW * 2 || bounds.outHeight / sample > maxH * 2) {
            sample *= 2
        }

        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeFile(file.absolutePath, opts)
    }

    private fun setSystemSound(file: File, type: String, title: String): Boolean {
        if (!file.exists()) return false

        val ringtoneType = when (type) {
            "notification" -> RingtoneManager.TYPE_NOTIFICATION
            "alarm" -> RingtoneManager.TYPE_ALARM
            else -> RingtoneManager.TYPE_RINGTONE
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeFor(file.name))
            put(MediaStore.Audio.Media.IS_RINGTONE, type == "ringtone")
            put(MediaStore.Audio.Media.IS_NOTIFICATION, type == "notification")
            put(MediaStore.Audio.Media.IS_ALARM, type == "alarm")
            put(MediaStore.Audio.Media.IS_MUSIC, false)
            put(MediaStore.Audio.Media.TITLE, title)
        }

        val collection =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_RINGTONES)
            values.put(MediaStore.Audio.Media.IS_PENDING, 1)
        }

        val resolver = contentResolver
        val uri = resolver.insert(collection, values) ?: return false
        resolver.openOutputStream(uri)?.use { out ->
            FileInputStream(file).use { input -> input.copyTo(out) }
        } ?: return false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }

        RingtoneManager.setActualDefaultRingtoneUri(this, ringtoneType, uri)
        return true
    }

    private fun mimeFor(name: String): String {
        val lower = name.lowercase()
        return when {
            lower.endsWith(".m4a") -> "audio/mp4"
            lower.endsWith(".mp3") -> "audio/mpeg"
            lower.endsWith(".ogg") -> "audio/ogg"
            lower.endsWith(".wav") -> "audio/wav"
            else -> "audio/mpeg"
        }
    }
}
