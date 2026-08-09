import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_features.dart';
import '../../../core/routing/app_routes.dart';
import 'subscription_providers.dart';

/// Returns `true` if the user can continue a premium action.
/// Otherwise opens the subscription screen and returns `false`.
bool requirePremiumOrOpenPaywall(BuildContext context, WidgetRef ref) {
  if (kAppFreeMode) return true;
  final isPremium =
      ref.read(subscriptionControllerProvider).asData?.value.isPremium ?? false;
  if (isPremium) return true;
  context.push(AppRoutes.paywall);
  return false;
}
