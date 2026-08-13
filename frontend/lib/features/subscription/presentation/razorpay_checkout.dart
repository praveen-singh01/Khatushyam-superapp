import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.success,
    this.paymentId,
    this.subscriptionId,
    this.signature,
  });

  final bool success;
  final String? paymentId;
  final String? subscriptionId;
  final String? signature;
}

/// Opens Razorpay Checkout for a subscription created by the backend.
Future<RazorpayCheckoutResult> openRazorpaySubscriptionCheckout({
  required String keyId,
  required String subscriptionId,
  String name = 'Khatu Shyam Premium',
  String description = 'Membership',
}) async {
  final completer = Completer<RazorpayCheckoutResult>();
  final razorpay = Razorpay();

  void finish(RazorpayCheckoutResult result) {
    if (!completer.isCompleted) completer.complete(result);
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    finish(
      RazorpayCheckoutResult(
        success: true,
        paymentId: response.paymentId,
        // SDK may put subscription id in orderId for subscription checkouts.
        subscriptionId: response.orderId?.isNotEmpty == true
            ? response.orderId
            : subscriptionId,
        signature: response.signature,
      ),
    );
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    debugPrint('Razorpay error: ${response.code} ${response.message}');
    finish(const RazorpayCheckoutResult(success: false));
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
    finish(const RazorpayCheckoutResult(success: false));
  }

  return completer.future.timeout(
    const Duration(minutes: 10),
    onTimeout: () {
      razorpay.clear();
      return const RazorpayCheckoutResult(success: false);
    },
  );
}
