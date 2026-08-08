import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_features.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import 'subscription_providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  String _label(AppLocalizations l10n, AppFeature feature) {
    return switch (feature) {
      AppFeature.liveDarshan => l10n.featureLiveDarshan,
      AppFeature.calendar => l10n.featureCalendar,
      AppFeature.aartiAlarms => l10n.featureAartiAlarms,
      AppFeature.events => l10n.featureEvents,
      AppFeature.singers => l10n.featureSingers,
      AppFeature.templeStatus => l10n.featureTempleStatus,
      AppFeature.travelGuides => l10n.featureTravelGuides,
      AppFeature.bhajans => l10n.featureBhajans,
      AppFeature.posters => l10n.featurePosters,
      AppFeature.wallpapers => l10n.featureWallpapers,
      AppFeature.ringtones => l10n.featureRingtones,
      AppFeature.callerTunes => l10n.featureCallerTunes,
      AppFeature.story => l10n.storyTitle,
      AppFeature.chamatkar => l10n.chamatkarTitle,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subscription = ref.watch(subscriptionControllerProvider);
    final isPremium = subscription.asData?.value.isPremium ?? false;
    final loading = subscription.isLoading;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            l10n.paywallTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.paywallSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB347), AppColors.orange],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? l10n.premiumActive : '₹49 / महीना',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.paywallNote,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...kPremiumFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _label(l10n, feature),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                isPremium || loading
                    ? null
                    : () =>
                        ref
                            .read(subscriptionControllerProvider.notifier)
                            .subscribeMonthly(),
            child:
                loading
                    ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(isPremium ? l10n.premiumActive : l10n.paywallCta),
          ),
        ],
      ),
    );
  }
}
