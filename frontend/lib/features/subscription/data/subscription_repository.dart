import '../domain/subscription_state.dart';

/// Loads entitlement state from the Node API (or a fake for tests).
abstract class SubscriptionRepository {
  Future<SubscriptionState> fetchEntitlement();

  /// Starts Razorpay checkout flow via backend; returns updated entitlement.
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
  Future<SubscriptionState> startMonthlyCheckout() async {
    _state = SubscriptionState(
      isPremium: true,
      planId: 'monthly_fake',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      source: SubscriptionSource.fake,
    );
    return _state;
  }

  void setState(SubscriptionState state) => _state = state;
}
