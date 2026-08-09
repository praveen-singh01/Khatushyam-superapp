import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Opens Razorpay Checkout for a subscription created by the backend.
/// Returns `true` on payment success, `false` on failure/cancel.
Future<bool> openRazorpaySubscriptionCheckout({
  required String keyId,
  required String subscriptionId,
  String name = 'Khatu Shyam Premium',
  String description = 'Membership',
}) async {
  final completer = Completer<bool>();
  final razorpay = Razorpay();

  void finish(bool ok) {
    if (!completer.isCompleted) completer.complete(ok);
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse _) {
    finish(true);
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    debugPrint('Razorpay error: ${response.code} ${response.message}');
    finish(false);
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {
    // Still waiting for payment success/error.
  });

  try {
    razorpay.open({
      'key': keyId,
      'subscription_id': subscriptionId,
      'name': name,
      'description': description,
      'theme': {'color': '#E67E22'},
    });
  } catch (e, st) {
    debugPrint('Razorpay open failed: $e\n$st');
    finish(false);
  }

  return completer.future.timeout(
    const Duration(minutes: 10),
    onTimeout: () {
      razorpay.clear();
      return false;
    },
  );
}
