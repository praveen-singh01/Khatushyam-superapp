import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_features.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../../live/presentation/live_youtube_player.dart';
import '../domain/subscription_state.dart';
import 'razorpay_checkout.dart';
import 'subscription_providers.dart';

/// Promo video shown on paywall for trial-eligible users.
const _kTrialPaywallVideoId = 'QfoBOzqSCLw';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  String _label(AppLocalizations l10n, AppFeature feature) {
    return switch (feature) {
      AppFeature.liveDarshan => l10n.featureLiveDarshan,
      AppFeature.calendar => l10n.featureCalendar,
      AppFeature.aartiAlarms => l10n.featureAartiAlarms,
      AppFeature.events => l10n.featureEvents,
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

  String _periodLabel(AppLocalizations l10n, SubscriptionOfferPeriod period) {
    return period == SubscriptionOfferPeriod.week
        ? l10n.paywallPerWeek
        : l10n.paywallPerMonth;
  }

  String _planDescription(AppLocalizations l10n, SubscriptionPlanId plan) {
    return switch (plan) {
      SubscriptionPlanId.trialMonthly => l10n.paywallTrialCta,
      SubscriptionPlanId.weekly => l10n.paywallWeeklyTitle,
      SubscriptionPlanId.monthly => l10n.paywallMonthlyTitle,
    };
  }

  Future<void> _startPlan(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlanId plan,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final prepared = await ref
        .read(subscriptionControllerProvider.notifier)
        .prepareCheckout(plan);
    if (!context.mounted) return;

    final asyncState = ref.read(subscriptionControllerProvider);
    if (asyncState.hasError || prepared == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      await ref.read(subscriptionControllerProvider.notifier).refresh();
      return;
    }

    final subId = prepared.checkoutSubscriptionId;
    final keyId = prepared.checkoutKeyId;
    if (subId == null || subId.isEmpty || keyId == null || keyId.isEmpty) {
      if (prepared.isPremium) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      return;
    }

    final paid = await openRazorpaySubscriptionCheckout(
      keyId: keyId,
      subscriptionId: subId,
      name: l10n.paywallTitle,
      description: _planDescription(l10n, plan),
    );
    if (!context.mounted) return;

    await ref.read(subscriptionControllerProvider.notifier).refresh();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(paid ? l10n.premiumActive : l10n.errorGeneric)),
    );
  }

  Widget _offerCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required SubscriptionOffer offer,
    required bool loading,
    required WidgetRef ref,
    required bool highlighted,
  }) {
    final isTrial = offer.isTrial;
    final title =
        isTrial
            ? l10n.paywallTrialTitle
            : offer.period == SubscriptionOfferPeriod.week
            ? l10n.paywallWeeklyTitle
            : l10n.paywallMonthlyTitle;
    final priceText =
        isTrial ? '₹${offer.trialPriceInr ?? 3}' : '₹${offer.priceInr}';
    final detail =
        isTrial
            ? l10n.paywallTrialDetail(offer.priceInr)
            : [
              _periodLabel(l10n, offer.period),
              l10n.paywallCancelAnytime,
            ].join(' · ');
    final cta = isTrial ? l10n.paywallTrialCta : l10n.paywallSubscribeCta;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: SoftCard(
          padding: EdgeInsets.zero,
          color: highlighted ? Colors.transparent : AppColors.orangeSoft,
          onTap: loading ? null : () => _startPlan(context, ref, offer.id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient:
                  highlighted
                      ? const LinearGradient(
                        colors: [Color(0xFFFFB347), AppColors.orange],
                      )
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: highlighted ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  priceText,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: highlighted ? Colors.white : AppColors.orangeDeep,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        highlighted
                            ? Colors.white.withValues(alpha: 0.92)
                            : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          highlighted ? Colors.white : AppColors.orange,
                      foregroundColor:
                          highlighted ? AppColors.orangeDeep : Colors.white,
                    ),
                    onPressed:
                        loading
                            ? null
                            : () => _startPlan(context, ref, offer.id),
                    child:
                        loading
                            ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(cta),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subscription = ref.watch(subscriptionControllerProvider);
    final state = subscription.asData?.value;
    final isPremium = state?.isPremium ?? false;
    final loading = subscription.isLoading;
    final offers =
        state?.displayOffers ?? const SubscriptionState.free().displayOffers;
    final trialEligible = state?.trialEligible ?? true;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.paywallTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh:
              () => ref.read(subscriptionControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              if (!isPremium && trialEligible) ...[
                const LiveYoutubePlayer(
                  videoId: _kTrialPaywallVideoId,
                  autoPlay: true,
                  showLiveBadge: false,
                  loop: true,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                isPremium
                    ? l10n.premiumActiveHint
                    : trialEligible
                    ? l10n.paywallSubtitleTrial
                    : l10n.paywallSubtitleReturn,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              if (isPremium)
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: double.infinity,
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
                          l10n.premiumActive,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.premiumActiveHint,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ...offers.map(
                  (offer) => _offerCard(
                    context: context,
                    l10n: l10n,
                    offer: offer,
                    loading: loading,
                    ref: ref,
                    highlighted:
                        offer.isTrial ||
                        offer.id == SubscriptionPlanId.monthly,
                  ),
                ),
                Text(
                  l10n.paywallNote,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                ),
              ],
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
            ],
          ),
        ),
      ),
    );
  }
}
