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
  String name = 'Khatu Shyam Premi',
  String description = 'Membership',
  String? customerName,
  String? email,
  String? contact,
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

  final prefill = <String, String>{};
  final trimmedName = customerName?.trim();
  if (trimmedName != null && trimmedName.isNotEmpty) {
    prefill['name'] = trimmedName;
  }
  final trimmedEmail = email?.trim();
  if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
    prefill['email'] = trimmedEmail;
  }
  final normalizedContact = _normalizeContact(contact);
  if (normalizedContact != null) {
    prefill['contact'] = normalizedContact;
  }

  try {
    razorpay.open({
      'key': keyId,
      'subscription_id': subscriptionId,
      'name': name,
      'description': description,
      'theme': {'color': '#E67E22'},
      if (prefill.isNotEmpty) 'prefill': prefill,
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

/// Razorpay expects a 10-digit Indian mobile (or E.164). Normalize common forms.
String? _normalizeContact(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.length == 12 && digits.startsWith('91')) {
    digits = digits.substring(2);
  }
  if (digits.length == 11 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.length == 10) return digits;
  if (digits.length >= 8 && digits.length <= 15) return digits;
  return null;
}
