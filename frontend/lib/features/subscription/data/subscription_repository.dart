import '../domain/subscription_state.dart';

/// Loads entitlement state from the Node API (or a fake for tests).
abstract class SubscriptionRepository {
  Future<SubscriptionState> fetchEntitlement();

  /// Starts checkout for a specific offer plan.
  Future<SubscriptionState> startCheckout(SubscriptionPlanId plan);

  /// Backward-compatible monthly path.
  Future<SubscriptionState> startMonthlyCheckout();
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
      isPremium: true,
      planId: plan == SubscriptionPlanId.weekly ? 'weekly' : 'monthly',
      expiresAt: DateTime.now().add(
        plan == SubscriptionPlanId.weekly
            ? const Duration(days: 7)
            : const Duration(days: 30),
      ),
      source: SubscriptionSource.fake,
      trialUsed: true,
      trialEligible: false,
      subscriptionStatus: 'active',
      offers: kDefaultOffersReturning,
    );
    return _state;
  }

  /// Simulates cancel — next paywall still shows weekly + monthly (no ₹3).
  void cancelSubscription() {
    _state = _state.copyWith(
      isPremium: false,
      planId: null,
      source: SubscriptionSource.none,
      trialUsed: true,
      trialEligible: false,
      subscriptionStatus: 'cancelled',
      offers: kDefaultOffersReturning,
    );
  }

  void setState(SubscriptionState state) => _state = state;
}
