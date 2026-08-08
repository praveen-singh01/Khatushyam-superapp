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
import '../../subscription/presentation/subscription_providers.dart';
import 'calendar_screen.dart';
import 'ringtone_actions.dart';
import 'wallpaper_viewer.dart';

class FeatureHostScreen extends ConsumerWidget {
  const FeatureHostScreen({super.key, required this.feature});

  final AppFeature? feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium =
        ref.watch(subscriptionControllerProvider).asData?.value.isPremium ??
        false;

    if (feature == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.lockedTitle)),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }

    if (!feature!.isFree && !isPremium) {
      return _PremiumGateScaffold(title: _title(l10n, feature!));
    }

    return switch (feature!) {
      AppFeature.liveDarshan => const LiveDarshanScreen(),
      AppFeature.calendar => const CalendarFeatureScreen(),
      AppFeature.aartiAlarms => const AartiAlarmsFeatureScreen(),
      AppFeature.events => const EventsFeatureScreen(),
      AppFeature.singers => const SingersFeatureScreen(),
      AppFeature.templeStatus => const TempleStatusFeatureScreen(),
      AppFeature.travelGuides => const TravelGuidesFeatureScreen(),
      AppFeature.bhajans => const BhajansFeatureScreen(),
      AppFeature.posters => const PostersFeatureScreen(),
      AppFeature.wallpapers => const WallpapersFeatureScreen(),
      AppFeature.ringtones => const RingtonesFeatureScreen(),
      AppFeature.callerTunes => const CallerTunesFeatureScreen(),
      AppFeature.story || AppFeature.chamatkar => Scaffold(
        appBar: AppBar(title: Text(_title(l10n, feature!))),
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
}

class _PremiumGateScaffold extends StatelessWidget {
  const _PremiumGateScaffold({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.orangeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 36,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.lockedTitle,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.lockedMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go(AppRoutes.paywall),
              child: Text(l10n.unlockCta),
            ),
          ],
        ),
      ),
    );
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

class AartiAlarmsFeatureScreen extends ConsumerWidget {
  const AartiAlarmsFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final slots = ref.watch(aartiSlotsProvider);
    return _FeatureScaffold(
      title: l10n.featureAartiAlarms,
      child: AsyncBody(
        value: slots,
        onRetry: () => ref.invalidate(aartiSlotsProvider),
        builder:
            (items) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final slot = items[index];
                return SoftCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: SwitchListTile(
                    value: slot.enabled,
                    activeColor: AppColors.orange,
                    title: Text(slot.name),
                    subtitle: Text(slot.timeLabel),
                    onChanged:
                        (value) => ref
                            .read(aartiSlotsProvider.notifier)
                            .toggle(slot.id, value),
                  ),
                );
              },
            ),
      ),
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
                              'विवरण देखें',
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

class SingersFeatureScreen extends ConsumerWidget {
  const SingersFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final singers = ref.watch(singersProvider);
    return _FeatureScaffold(
      title: l10n.featureSingers,
      child: AsyncBody(
        value: singers,
        onRetry: () => ref.invalidate(singersProvider),
        builder:
            (items) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final singer = items[index];
                return SoftCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.orangeSoft,
                        child: Icon(Icons.mic_rounded, color: AppColors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              singer.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${singer.specialty} · ${singer.city}'),
                            Text(
                              singer.phone,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppColors.orange),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.call_rounded,
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

class TempleStatusFeatureScreen extends ConsumerWidget {
  const TempleStatusFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(templeStatusProvider);
    return _FeatureScaffold(
      title: l10n.featureTempleStatus,
      child: AsyncBody(
        value: status,
        onRetry: () => ref.invalidate(templeStatusProvider),
        builder: (data) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftCard(
                color:
                    data.isOpen
                        ? AppColors.successSoft
                        : const Color(0xFFFDECEA),
                child: Column(
                  children: [
                    Icon(
                      data.isOpen
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 48,
                      color: data.isOpen ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.statusLabel,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(data.nextChangeLabel),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Text(
                  data.note,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => ref.invalidate(templeStatusProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('रिफ्रेश'),
              ),
            ],
          );
        },
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
    final tracks = ref.watch(bhajansProvider);
    return _FeatureScaffold(
      title: l10n.featureBhajans,
      child: AsyncBody(
        value: tracks,
        onRetry: () => ref.invalidate(bhajansProvider),
        builder:
            (items) => Column(
              children: [
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      _CategoryChip(label: 'सभी', selected: true),
                      _CategoryChip(label: 'प्रातः'),
                      _CategoryChip(label: 'संध्या'),
                      _CategoryChip(label: 'आरती'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final track = items[index];
                      return SoftCard(
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.orangeSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: AppColors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${track.artist} · ${track.durationLabel}',
                                  ),
                                ],
                              ),
                            ),
                            const CircleAvatar(
                              backgroundColor: AppColors.orange,
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class PostersFeatureScreen extends ConsumerWidget {
  const PostersFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templates = ref.watch(postersProvider);
    return _FeatureScaffold(
      title: l10n.featurePosters,
      child: AsyncBody(
        value: templates,
        onRetry: () => ref.invalidate(postersProvider),
        builder:
            (items) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  l10n.posterHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                ...items.map(
                  (template) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFB347), AppColors.orange],
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(template.theme),
                              ],
                            ),
                          ),
                          Text(
                            l10n.useTemplate,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.orange),
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

class WallpapersFeatureScreen extends ConsumerWidget {
  const WallpapersFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _MediaGridScreen(
      title: l10n.featureWallpapers,
      value: ref.watch(wallpapersProvider),
      onRetry: () => ref.invalidate(wallpapersProvider),
      actionLabel: l10n.setWallpaper,
      icon: Icons.wallpaper_rounded,
      onItemTap: (asset) => openWallpaperViewer(context, asset: asset),
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

class _MediaGridScreen extends StatelessWidget {
  const _MediaGridScreen({
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
            (items) => GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final imageUrl = item.url;
                return SoftCard(
                  onTap: onItemTap == null ? null : () => onItemTap!(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child:
                              imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _MediaPlaceholder(
                                          icon: icon,
                                        ),
                                  )
                                  : _MediaPlaceholder(icon: icon),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB347), AppColors.orange],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 34),
    );
  }
}
