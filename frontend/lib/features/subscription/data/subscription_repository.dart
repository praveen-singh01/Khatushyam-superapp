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
    if (plan == SubscriptionPlanId.trialMonthly && _state.trialUsed) {
      throw StateError('TRIAL_ALREADY_USED');
    }

    final trialUsed =
        plan == SubscriptionPlanId.trialMonthly ? true : _state.trialUsed;

    _state = SubscriptionState(
      isPremium: true,
      planId: switch (plan) {
        SubscriptionPlanId.trialMonthly => 'trial_monthly',
        SubscriptionPlanId.weekly => 'weekly',
        SubscriptionPlanId.monthly => 'monthly',
      },
      expiresAt: DateTime.now().add(
        plan == SubscriptionPlanId.weekly
            ? const Duration(days: 7)
            : const Duration(days: 30),
      ),
      source: SubscriptionSource.fake,
      trialUsed: trialUsed,
      trialEligible: !trialUsed,
      subscriptionStatus: 'active',
      offers:
          trialUsed
              ? const [
                SubscriptionOffer(
                  id: SubscriptionPlanId.weekly,
                  priceInr: 49,
                  period: SubscriptionOfferPeriod.week,
                ),
                SubscriptionOffer(
                  id: SubscriptionPlanId.monthly,
                  priceInr: 199,
                  period: SubscriptionOfferPeriod.month,
                ),
              ]
              : const [
                SubscriptionOffer(
                  id: SubscriptionPlanId.trialMonthly,
                  priceInr: 199,
                  period: SubscriptionOfferPeriod.month,
                  trialPriceInr: 3,
                ),
              ],
    );
    return _state;
  }

  /// Simulates cancel after trial — next paywall shows weekly + monthly.
  void cancelSubscription() {
    _state = _state.copyWith(
      isPremium: false,
      planId: null,
      source: SubscriptionSource.none,
      trialUsed: true,
      trialEligible: false,
      subscriptionStatus: 'cancelled',
      offers: const [
        SubscriptionOffer(
          id: SubscriptionPlanId.weekly,
          priceInr: 49,
          period: SubscriptionOfferPeriod.week,
        ),
        SubscriptionOffer(
          id: SubscriptionPlanId.monthly,
          priceInr: 199,
          period: SubscriptionOfferPeriod.month,
        ),
      ],
    );
  }

  void setState(SubscriptionState state) => _state = state;
}
