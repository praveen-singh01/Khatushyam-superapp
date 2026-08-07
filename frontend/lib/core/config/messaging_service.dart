import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Thin FCM wrapper — no-op when Firebase is not configured.
class MessagingService {
  MessagingService({FirebaseMessaging? messaging}) : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  Future<void> initialize() async {
    final messaging = _messaging;
    if (messaging == null) {
      debugPrint('FCM skipped: Firebase not configured.');
      return;
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    debugPrint('FCM token obtained: ${token != null}');
  }
}
