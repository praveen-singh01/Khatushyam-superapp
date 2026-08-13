import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_state.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.firebaseConfigured || config.useBackendApi) {
    return ApiSubscriptionRepository(ref.watch(apiClientProvider));
  }
  return FakeSubscriptionRepository();
});

final subscriptionControllerProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );

class SubscriptionController extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() {
    return ref.read(subscriptionRepositoryProvider).fetchEntitlement();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionRepositoryProvider).fetchEntitlement(),
    );
  }

  /// Creates a Razorpay subscription on the backend and returns checkout ids.
  Future<SubscriptionState?> prepareCheckout(SubscriptionPlanId plan) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionRepositoryProvider).startCheckout(plan),
    );
    return state.asData?.value;
  }

  Future<SubscriptionState?> verifyCheckout({
    required String razorpaySubscriptionId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(subscriptionRepositoryProvider)
          .verifyPayment(
            razorpaySubscriptionId: razorpaySubscriptionId,
            razorpayPaymentId: razorpayPaymentId,
            razorpaySignature: razorpaySignature,
          ),
    );
    return state.asData?.value;
  }

  Future<void> startCheckout(SubscriptionPlanId plan) =>
      prepareCheckout(plan).then((_) {});

  Future<void> subscribeMonthly() =>
      startCheckout(SubscriptionPlanId.monthly);
}
