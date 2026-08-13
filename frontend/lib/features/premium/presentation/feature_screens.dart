import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_features.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';
import '../../live/presentation/live_darshan_screen.dart';
import '../../live/presentation/live_youtube_player.dart';
import '../../posters/presentation/posters_screen.dart';
import 'calendar_screen.dart';
import '../../alarms/presentation/alarms_screen.dart';
import 'ringtone_actions.dart';
import 'wallpaper_viewer.dart';

class FeatureHostScreen extends ConsumerStatefulWidget {
  const FeatureHostScreen({super.key, required this.feature});

  final AppFeature? feature;

  @override
  ConsumerState<FeatureHostScreen> createState() => _FeatureHostScreenState();
}

class _FeatureHostScreenState extends ConsumerState<FeatureHostScreen> {
  @override
  void initState() {
    super.initState();
    // Root-stack features cover the shell; pause any tab YouTube players.
    LiveYoutubePlayer.pauseAll();
  }

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;
    final l10n = AppLocalizations.of(context)!;

    if (feature == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.lockedTitle)),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }

    // Browse is free — paywall opens only on premium actions
    // (share poster / set wallpaper / set ringtone).
    return switch (feature) {
      AppFeature.liveDarshan => const LiveDarshanScreen(),
      AppFeature.calendar => const CalendarFeatureScreen(),
      AppFeature.aartiAlarms => const AlarmsFeatureScreen(),
      AppFeature.events => const EventsFeatureScreen(),
      AppFeature.travelGuides => const TravelGuidesFeatureScreen(),
      AppFeature.bhajans => const BhajansFeatureScreen(),
      AppFeature.posters => const PostersScreen(),
      AppFeature.wallpapers => const WallpapersFeatureScreen(),
      AppFeature.ringtones => const RingtonesFeatureScreen(),
      AppFeature.callerTunes => const CallerTunesFeatureScreen(),
      AppFeature.story || AppFeature.chamatkar => Scaffold(
        appBar: AppBar(title: Text(_title(l10n, feature))),
        body: const SizedBox.shrink(),
      ),
    };
  }

  static String _title(AppLocalizations l10n, AppFeature feature) {
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
}

class _FeatureScaffold extends StatelessWidget {
  const _FeatureScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed:
              () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: child,
    );
  }
}

class EventsFeatureScreen extends ConsumerWidget {
  const EventsFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(eventsProvider);
    return _FeatureScaffold(
      title: l10n.featureEvents,
      child: AsyncBody(
        value: events,
        onRetry: () => ref.invalidate(eventsProvider),
        builder:
            (items) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = items[index];
                return SoftCard(
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: AppColors.orange,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('${event.city} · ${event.venue}'),
                            Text(event.dateLabel),
                            const SizedBox(height: 8),
                            Text(
                              'Vivaran dekhein',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppColors.orange),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

class TravelGuidesFeatureScreen extends ConsumerWidget {
  const TravelGuidesFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final guides = ref.watch(travelGuidesProvider);
    return _FeatureScaffold(
      title: l10n.featureTravelGuides,
      child: AsyncBody(
        value: guides,
        onRetry: () => ref.invalidate(travelGuidesProvider),
        builder:
            (items) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                SoftCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _TransportChip(icon: Icons.train_rounded, label: 'Train'),
                      _TransportChip(
                        icon: Icons.directions_bus_rounded,
                        label: 'Bus',
                      ),
                      _TransportChip(
                        icon: Icons.flight_rounded,
                        label: 'Flight',
                      ),
                      _TransportChip(
                        icon: Icons.directions_car_rounded,
                        label: 'Car',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...items.map(
                  (guide) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(guide.fromCity),
                          const SizedBox(height: 12),
                          ...guide.steps.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.orangeSoft,
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.ink),
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }
}

class _TransportChip extends StatelessWidget {
  const _TransportChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.orangeSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.orange),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class BhajansFeatureScreen extends ConsumerWidget {
  const BhajansFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Same catalog as ringtones for now.
    return _MediaListScreen(
      title: l10n.featureBhajans,
      value: ref.watch(bhajansProvider),
      onRetry: () => ref.invalidate(bhajansProvider),
      actionLabel: l10n.setRingtone,
      icon: Icons.music_note_rounded,
      onItemTap: (asset) => openRingtoneActions(context, asset: asset),
    );
  }
}

class WallpapersFeatureScreen extends ConsumerWidget {
  const WallpapersFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final value = ref.watch(wallpapersProvider);

    return value.when(
      data: (items) {
        if (items.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(l10n.featureWallpapers),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed:
                    () =>
                        context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.home),
              ),
            ),
            body: Center(
              child: Text(
                l10n.errorGeneric,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return WallpaperCarouselPage(assets: items);
      },
      loading:
          () => const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          ),
      error:
          (_, __) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(l10n.featureWallpapers),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed:
                    () =>
                        context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.home),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.errorGeneric,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(wallpapersProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class RingtonesFeatureScreen extends ConsumerWidget {
  const RingtonesFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _MediaListScreen(
      title: l10n.featureRingtones,
      value: ref.watch(ringtonesProvider),
      onRetry: () => ref.invalidate(ringtonesProvider),
      actionLabel: l10n.setRingtone,
      icon: Icons.ring_volume_rounded,
      onItemTap: (asset) => openRingtoneActions(context, asset: asset),
    );
  }
}

class CallerTunesFeatureScreen extends ConsumerWidget {
  const CallerTunesFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _MediaListScreen(
      title: l10n.featureCallerTunes,
      value: ref.watch(callerTunesProvider),
      onRetry: () => ref.invalidate(callerTunesProvider),
      actionLabel: l10n.activateTune,
      icon: Icons.call_rounded,
      onItemTap: (asset) => openRingtoneActions(context, asset: asset),
    );
  }
}

class _MediaListScreen extends StatelessWidget {
  const _MediaListScreen({
    required this.title,
    required this.value,
    required this.onRetry,
    required this.actionLabel,
    required this.icon,
    this.onItemTap,
  });

  final String title;
  final AsyncValue<List<MediaAsset>> value;
  final VoidCallback onRetry;
  final String actionLabel;
  final IconData icon;
  final void Function(MediaAsset asset)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: title,
      child: AsyncBody(
        value: value,
        onRetry: onRetry,
        builder:
            (items) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return SoftCard(
                  onTap: onItemTap == null ? null : () => onItemTap!(item),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: AppColors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(item.subtitle),
                          ],
                        ),
                      ),
                      Text(
                        actionLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
