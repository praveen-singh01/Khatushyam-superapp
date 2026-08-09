import 'package:flutter_test/flutter_test.dart';

import 'package:khatushyam_app/core/config/app_features.dart';
import 'package:khatushyam_app/features/auth/data/fake_auth_service.dart';
import 'package:khatushyam_app/features/subscription/data/subscription_repository.dart';
import 'package:khatushyam_app/features/subscription/domain/subscription_state.dart';

void main() {
  group('SubscriptionState', () {
    test('free features are always accessible', () {
      const free = SubscriptionState.free();
      expect(free.canAccess(AppFeature.story), isTrue);
      expect(free.canAccess(AppFeature.chamatkar), isTrue);
      expect(free.canAccess(AppFeature.liveDarshan), isTrue);
      if (!kAppFreeMode) {
        expect(free.canAccess(AppFeature.bhajans), isFalse);
        expect(free.canAccess(AppFeature.calendar), isFalse);
      }
    });

    test('premium unlocks all paid features', () {
      const premium = SubscriptionState(
        isPremium: true,
        planId: 'monthly',
        source: SubscriptionSource.razorpay,
      );
      for (final feature in AppFeature.values) {
        expect(premium.canAccess(feature), isTrue, reason: feature.name);
      }
    });

    test('round-trips JSON', () {
      final original = SubscriptionState(
        isPremium: true,
        planId: 'monthly',
        expiresAt: DateTime.utc(2026, 8, 1),
        source: SubscriptionSource.razorpay,
      );
      final restored = SubscriptionState.fromJson(original.toJson());
      expect(restored, original);
    });
  });

  group('FakeSubscriptionRepository', () {
    test('first checkout grants premium and consumes mandate addon', () async {
      final repo = FakeSubscriptionRepository();
      final before = await repo.fetchEntitlement();
      expect(before.trialEligible, isTrue);
      expect(
        before.displayOffers.map((o) => o.id),
        [SubscriptionPlanId.weekly, SubscriptionPlanId.monthly],
      );
      final next = await repo.startCheckout(SubscriptionPlanId.monthly);
      expect(next.isPremium, isTrue);
      expect(next.trialUsed, isTrue);
      expect(next.trialEligible, isFalse);
      expect(next.source, SubscriptionSource.fake);
    });

    test('after cancel, still offers weekly and monthly', () async {
      final repo = FakeSubscriptionRepository();
      await repo.startCheckout(SubscriptionPlanId.weekly);
      repo.cancelSubscription();
      final state = await repo.fetchEntitlement();
      expect(state.isPremium, isFalse);
      expect(state.trialEligible, isFalse);
      expect(
        state.displayOffers.map((o) => o.id),
        [SubscriptionPlanId.weekly, SubscriptionPlanId.monthly],
      );
      expect(state.displayOffers.every((o) => !o.hasMandateAddon), isTrue);
    });
  });

  group('FakeAuthService', () {
    test('sign-in and token without Firebase', () async {
      final auth = FakeAuthService();
      expect(auth.currentUser, isNull);

      final user = await auth.signInWithGoogle();
      expect(user.uid, 'local-premium');
      expect(await auth.getIdToken(), 'premium');

      await auth.signOut();
      expect(auth.currentUser, isNull);
      expect(await auth.getIdToken(), isNull);
      auth.dispose();
    });
  });

  group('AppFeature', () {
    test('premium list excludes free features', () {
      expect(kPremiumFeatures, isNot(contains(AppFeature.story)));
      expect(kPremiumFeatures, isNot(contains(AppFeature.chamatkar)));
      expect(kPremiumFeatures, isNot(contains(AppFeature.liveDarshan)));
      expect(AppFeature.story.isFree, isTrue);
      expect(AppFeature.chamatkar.isFree, isTrue);
      expect(AppFeature.liveDarshan.isFree, isTrue);
    });
  });
}
