import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Meta (Facebook) App Events — mirrors Yaaro `mitro-mobile/src/utils/fbevents.ts`.
///
/// Native config: Android `strings.xml` + iOS `Info.plist` (App ID + Client Token).
/// App Secret is server-only and must never ship in the mobile binary.
class FBTracker {
  FBTracker._();

  static final FacebookAppEvents _sdk = FacebookAppEvents();
  static const String appId = '1219859294552977';

  static Future<void> initialize() async {
    try {
      await _sdk.setAutoLogAppEventsEnabled(true);
      await _sdk.setAdvertiserTracking(enabled: true, collectId: true);
      if (kDebugMode) {
        await _sdk.setDebugLoggingEnabled(true);
      }
      await _sdk.activateApp(applicationId: appId);
      if (kDebugMode) {
        final resolved = await _sdk.getApplicationId();
        final anon = await _sdk.getAnonymousId();
        debugPrint('FBTracker ready appId=$resolved anonId=$anon');
      }

      // One-shot smoke test: flutter run --dart-define=FB_EVENT_SMOKE_TEST=true
      const smoke =
          bool.fromEnvironment('FB_EVENT_SMOKE_TEST', defaultValue: false);
      if (smoke) {
        await smokeTestAllEvents();
      }
    } catch (e, st) {
      debugPrint('FBTracker initialize Error: $e\n$st');
    }
  }

  /// Fires every Meta event we care about (for Events Manager → Test Events).
  static Future<void> smokeTestAllEvents() async {
    debugPrint('FBTracker smokeTest START');
    try {
      await setUser(
        userId: 'smoke_test_user',
        email: 'smoke@khatushyam.test',
        firstName: 'Smoke',
      );
      await logRegistration(method: 'Google');
      await logOnboardingCompleted();
      await logInitiateCheckout(
        amount: 1,
        contentId: 'trial_monthly',
        params: {'plan': 'trial_monthly', 'source': 'smoke_test'},
      );
      await logPurchase(
        amount: 1,
        params: {
          'plan': 'trial_monthly',
          'payment_id': 'pay_smoke_test',
          'source': 'smoke_test',
        },
        orderId: 'sub_smoke_test_${DateTime.now().millisecondsSinceEpoch}',
        isTrial: true,
      );
      await logCustomEvent(
        'khatushyam_smoke_test',
        params: {'ok': 'true'},
      );
      await _sdk.flush();
      debugPrint('FBTracker smokeTest DONE (check Meta Test Events)');
    } catch (e, st) {
      debugPrint('FBTracker smokeTest Error: $e\n$st');
    }
  }

  /// Yaaro: `AppEventsLogger.logPurchase` + `flush`.
  static Future<void> logPurchase({
    required double amount,
    String currency = 'INR',
    Map<String, dynamic>? params,
    String? orderId,
    bool isTrial = false,
  }) async {
    try {
      await _sdk.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {
          if (params != null) ...params,
          if (orderId != null) FacebookAppEvents.paramNameOrderId: orderId,
        },
      );

      // Extra Meta subscription standard events (helps Ads Manager optimization).
      final oid = orderId ?? 'khatushyam_${DateTime.now().millisecondsSinceEpoch}';
      if (isTrial) {
        await _sdk.logStartTrial(
          price: amount,
          currency: currency,
          orderId: oid,
          parameters: params,
        );
      } else {
        await _sdk.logSubscribe(
          price: amount,
          currency: currency,
          orderId: oid,
          parameters: params,
        );
      }

      await _sdk.flush();
    } catch (e, st) {
      debugPrint('FBTracker logPurchase Error: $e\n$st');
    }
  }

  /// Yaaro: `fb_mobile_tutorial_completion`.
  static Future<void> logOnboardingCompleted() async {
    try {
      await _sdk.logCompletedTutorial(contentId: 'khatushyam_home');
    } catch (e, st) {
      debugPrint('FBTracker logOnboardingCompleted Error: $e\n$st');
    }
  }

  /// Yaaro: `fb_mobile_complete_registration`.
  static Future<void> logRegistration({String method = 'Unknown'}) async {
    try {
      await _sdk.logCompletedRegistration(registrationMethod: method);
    } catch (e, st) {
      debugPrint('FBTracker logRegistration Error: $e\n$st');
    }
  }

  /// Fired when user taps subscribe / trial CTA (before Razorpay opens).
  static Future<void> logInitiateCheckout({
    required double amount,
    String currency = 'INR',
    String? contentId,
    Map<String, dynamic>? params,
  }) async {
    try {
      await _sdk.logInitiatedCheckout(
        totalPrice: amount,
        currency: currency,
        contentType: 'subscription',
        contentId: contentId,
        numItems: 1,
        paymentInfoAvailable: true,
        parameters: params,
      );
    } catch (e, st) {
      debugPrint('FBTracker logInitiateCheckout Error: $e\n$st');
    }
  }

  static Future<void> logCustomEvent(
    String eventName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      await _sdk.logEvent(name: eventName, parameters: params);
    } catch (e, st) {
      debugPrint('FBTracker logCustomEvent Error: $e\n$st');
    }
  }

  static Future<void> setUser({
    String? userId,
    String? email,
    String? firstName,
  }) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        await _sdk.setUserID(userId);
      }
      if (email != null || firstName != null) {
        await _sdk.setUserData(email: email, firstName: firstName);
      }
    } catch (e, st) {
      debugPrint('FBTracker setUser Error: $e\n$st');
    }
  }
}
