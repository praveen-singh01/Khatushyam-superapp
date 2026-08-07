import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_state.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.firebaseConfigured) {
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

  Future<void> subscribeMonthly() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionRepositoryProvider).startMonthlyCheckout(),
    );
  }
}
