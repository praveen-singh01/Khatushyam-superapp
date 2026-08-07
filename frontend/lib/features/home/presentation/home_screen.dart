import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_features.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/circle_action.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../subscription/presentation/subscription_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _label(AppLocalizations l10n, AppFeature feature) {
    return switch (feature) {
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
    final user = ref.watch(authStateProvider).asData?.value;
    final isPremium =
        ref.watch(subscriptionControllerProvider).asData?.value.isPremium ??
        false;
    final temple = ref.watch(templeStatusProvider);
    final name = user?.displayName?.split(' ').first ?? 'भक्त';

    final quickActions = <(AppFeature?, String, IconData, String)>[
      (null, AppRoutes.story, Icons.auto_stories_rounded, l10n.storyTitle),
      (
        AppFeature.bhajans,
        AppRoutes.featurePath('bhajans'),
        Icons.music_note_rounded,
        l10n.featureBhajans,
      ),
      (
        AppFeature.calendar,
        AppRoutes.featurePath('calendar'),
        Icons.calendar_month_rounded,
        l10n.featureCalendar,
      ),
      (
        AppFeature.templeStatus,
        AppRoutes.featurePath('temple-status'),
        Icons.temple_hindu_rounded,
        l10n.featureTempleStatus,
      ),
      (
        AppFeature.aartiAlarms,
        AppRoutes.featurePath('aarti-alarms'),
        Icons.alarm_rounded,
        l10n.featureAartiAlarms,
      ),
      (
        AppFeature.events,
        AppRoutes.featurePath('events'),
        Icons.event_rounded,
        l10n.featureEvents,
      ),
      (
        AppFeature.travelGuides,
        AppRoutes.featurePath('travel-guides'),
        Icons.map_rounded,
        l10n.featureTravelGuides,
      ),
      (
        AppFeature.wallpapers,
        AppRoutes.featurePath('wallpapers'),
        Icons.wallpaper_rounded,
        l10n.featureWallpapers,
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.homeGreeting}, $name',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.appTagline,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.orangeSoft,
                child: Text(
                  name.isNotEmpty ? name.characters.first : 'भ',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.signOut,
                onPressed: () => ref.read(authServiceProvider).signOut(),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFB347),
                    AppColors.orange,
                    AppColors.orangeDeep,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: temple.when(
                data:
                    (status) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "आज की आरती",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          status.nextChangeLabel,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white, fontSize: 24),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed:
                                  () => context.push(
                                    AppRoutes.featurePath('temple-status'),
                                  ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('विवरण'),
                            ),
                          ],
                        ),
                      ],
                    ),
                loading:
                    () => Text(
                      "आज की आरती",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: Colors.white, fontSize: 24),
                    ),
                error:
                    (_, __) => Text(
                      l10n.featureTempleStatus,
                      style: const TextStyle(color: Colors.white),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            onTap: () => context.go(AppRoutes.paywall),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isPremium
                        ? Icons.verified_rounded
                        : Icons.workspace_premium_rounded,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? l10n.premiumActive : l10n.premiumInactive,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        isPremium
                            ? l10n.premiumActiveHint
                            : l10n.premiumInactiveHint,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('त्वरित पहुँच', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quickActions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 6,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final item = quickActions[index];
              final feature = item.$1;
              final locked = feature != null && !feature.isFree && !isPremium;
              return CircleAction(
                icon: item.$3,
                label: item.$4,
                locked: locked,
                onTap: () {
                  if (item.$2 == AppRoutes.story) {
                    context.go(AppRoutes.story);
                  } else {
                    context.push(item.$2);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            l10n.homeFreeFeatures,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SoftCard(
                  onTap: () => context.go(AppRoutes.story),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.orange,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.storyTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SoftCard(
                  onTap: () => context.go(AppRoutes.chamatkar),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.orange,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.chamatkarTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            l10n.homePremiumFeatures,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...kPremiumFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                onTap:
                    () => context.push(
                      AppRoutes.featurePath(feature.routeSegment),
                    ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_iconFor(feature), color: AppColors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _label(l10n, feature),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!isPremium)
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.inkMuted,
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.inkMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AppFeature feature) {
    return switch (feature) {
      AppFeature.calendar => Icons.calendar_month_rounded,
      AppFeature.aartiAlarms => Icons.alarm_rounded,
      AppFeature.events => Icons.event_rounded,
      AppFeature.singers => Icons.mic_rounded,
      AppFeature.templeStatus => Icons.temple_hindu_rounded,
      AppFeature.travelGuides => Icons.map_rounded,
      AppFeature.bhajans => Icons.music_note_rounded,
      AppFeature.posters => Icons.photo_camera_rounded,
      AppFeature.wallpapers => Icons.wallpaper_rounded,
      AppFeature.ringtones => Icons.ring_volume_rounded,
      AppFeature.callerTunes => Icons.call_rounded,
      _ => Icons.star_rounded,
    };
  }
}
