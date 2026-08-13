import '../domain/subscription_state.dart';

/// Loads entitlement state from the Node API (or a fake for tests).
abstract class SubscriptionRepository {
  Future<SubscriptionState> fetchEntitlement();

  /// Starts checkout for a specific offer plan.
  Future<SubscriptionState> startCheckout(SubscriptionPlanId plan);

  /// Backward-compatible monthly path.
  Future<SubscriptionState> startMonthlyCheckout();

  /// Verify Razorpay checkout signature (Mitro-style immediate unlock).
  Future<SubscriptionState> verifyPayment({
    required String razorpaySubscriptionId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? mongoSubscriptionId,
  });

  Future<SubscriptionState> cancelSubscription({String? reason});
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    SubscriptionState initial = const SubscriptionState.free(),
  }) : _state = initial;

  SubscriptionState _state;

  @override
  Future<SubscriptionState> fetchEntitlement() async => _state;

  @override
  Future<SubscriptionState> startMonthlyCheckout() =>
      startCheckout(SubscriptionPlanId.monthly);

  @override
  Future<SubscriptionState> startCheckout(SubscriptionPlanId plan) async {
    _state = SubscriptionState(
      isPremium: false,
      planId: switch (plan) {
        SubscriptionPlanId.weekly => 'weekly',
        SubscriptionPlanId.trialMonthly || SubscriptionPlanId.monthly =>
          'monthly',
      },
      source: SubscriptionSource.fake,
      trialUsed: false,
      trialEligible: true,
      subscriptionStatus: 'pending',
      offers: kDefaultTrialOffers,
      checkoutSubscriptionId: 'sub_fake',
      checkoutKeyId: 'rzp_test_fake',
    );
    return _state;
  }

  @override
  Future<SubscriptionState> verifyPayment({
    required String razorpaySubscriptionId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? mongoSubscriptionId,
  }) async {
    _state = SubscriptionState(
      isPremium: true,
      planId: 'monthly',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      source: SubscriptionSource.fake,
      trialUsed: true,
      trialEligible: false,
      subscriptionStatus: 'authenticated',
      offers: kDefaultOffersReturning,
    );
    return _state;
  }

  @override
  Future<SubscriptionState> cancelSubscription({String? reason}) async {
    _state = _state.copyWith(
      isPremium: false,
      planId: null,
      source: SubscriptionSource.none,
      trialUsed: true,
      trialEligible: false,
      subscriptionStatus: 'cancelled',
      offers: kDefaultOffersReturning,
    );
    return _state;
  }

  void setState(SubscriptionState state) => _state = state;
}
