import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_features.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../live/domain/live_stream_state.dart';
import '../../live/presentation/live_providers.dart';
import '../../subscription/presentation/subscription_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  LiveStreamState? _cachedLive;
  final _heroPage = ValueNotifier<int>(0);

  static const _heroImages = [
    'assets/images/hero_darshan.jpg',
    'assets/images/hero_night.jpg',
    'assets/images/hero_blessing.jpg',
    'assets/images/poster_sample.jpg',
  ];

  @override
  void dispose() {
    _heroPage.dispose();
    super.dispose();
  }

  void _open(String path) {
    if (path == AppRoutes.story ||
        path == AppRoutes.posters ||
        path == AppRoutes.chamatkar ||
        path == AppRoutes.profile) {
      context.go(path);
    } else {
      context.push(path);
    }
  }

  Future<void> _openAllSeva(List<_BhaktiTile> items) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Aur Bhakti Sevaein',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final tile = items[index];
                    return _RoundSevaChip(
                      tile: tile,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _open(tile.path);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final isPremium =
        ref.watch(subscriptionControllerProvider).asData?.value.isPremium ??
        false;
    final liveAsync = ref.watch(liveStreamProvider);
    final liveData = liveAsync.asData?.value;
    if (liveData != null) {
      _cachedLive = liveData;
    }
    final live = liveData ?? _cachedLive;
    final isLiveNow = live?.canPlay ?? false;
    final name = user?.displayName?.split(' ').first ?? 'Bhakt';
    final livePath = AppRoutes.featurePath(
      AppFeature.liveDarshan.routeSegment,
    );

    final aajKiBhakti = <_BhaktiTile>[
      _BhaktiTile(
        title: 'Live Darshan',
        subtitle: 'Darshan karein',
        image: 'assets/home_tabs/tab-live.png',
        path: livePath,
      ),
      _BhaktiTile(
        title: 'Shyam Katha',
        subtitle: 'Katha sunein',
        image: 'assets/home_tabs/tab-story.png',
        path: AppRoutes.story,
      ),
      _BhaktiTile(
        title: 'Photo Poster',
        subtitle: 'Poster banayein',
        image: 'assets/home_tabs/tab-posters.png',
        path: AppRoutes.posters,
      ),
      _BhaktiTile(
        title: 'Bhajan',
        subtitle: 'Bhajan sunein',
        image: 'assets/home_tabs/tab-bhajans.png',
        path: AppRoutes.featurePath('bhajans'),
      ),
    ];

    final moreSeva = <_BhaktiTile>[
      _BhaktiTile(
        title: 'Wallpaper',
        subtitle: 'Set karein',
        image: 'assets/home_tabs/tab-wallpapers.png',
        path: AppRoutes.featurePath('wallpapers'),
      ),
      _BhaktiTile(
        title: 'Ringtone',
        subtitle: 'Lagayein',
        image: 'assets/home_tabs/tab-ringtones.png',
        path: AppRoutes.featurePath('ringtones'),
      ),
      _BhaktiTile(
        title: 'Calendar',
        subtitle: 'Tithi',
        image: 'assets/home_tabs/tab-calendar.png',
        path: AppRoutes.featurePath('calendar'),
      ),
      _BhaktiTile(
        title: 'Alarm',
        subtitle: 'Aarti',
        image: 'assets/home_tabs/tab-alarms.png',
        path: AppRoutes.featurePath('aarti-alarms'),
      ),
      _BhaktiTile(
        title: 'Yatra',
        subtitle: 'Rasta',
        image: 'assets/home_tabs/tab-travel.png',
        path: AppRoutes.featurePath('travel-guides'),
      ),
      _BhaktiTile(
        title: 'Chamatkar',
        subtitle: 'Share',
        image: 'assets/applogo.png',
        path: AppRoutes.chamatkar,
      ),
      _BhaktiTile(
        title: 'Events',
        subtitle: 'Utsav',
        image: 'assets/home_tabs/tab-events.png',
        path: AppRoutes.featurePath('events'),
      ),
    ];

    Future<void> refreshHome() async {
      ref.invalidate(liveStreamProvider);
      await Future.wait<void>([
        ref.read(liveStreamProvider.future).then((_) {}, onError: (_) {}),
        ref.read(subscriptionControllerProvider.notifier).refresh(),
      ]);
    }

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: refreshHome,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _HomeHeader(name: name, onBellTap: () => _open(AppRoutes.profile)),
            const SizedBox(height: 14),
            _HeroCarousel(
              images: _heroImages,
              isLive: isLiveNow,
              page: _heroPage,
              onDarshan: () => _open(livePath),
            ),
            const SizedBox(height: 20),
            Text(
              'Aaj ki Bhakti',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: aajKiBhakti.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final tile = aajKiBhakti[index];
                return _BhaktiGridCard(
                  tile: tile,
                  onTap: () => _open(tile.path),
                );
              },
            ),
            const SizedBox(height: 16),
            _SandeshBanner(onReadMore: () => _open(AppRoutes.story)),
            const SizedBox(height: 16),
            _PosterPromoBanner(onCreate: () => _open(AppRoutes.posters)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Aur Bhakti Sevaein',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontSize: 18,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openAllSeva(moreSeva),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Sabhi ›',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: moreSeva.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final tile = moreSeva[index];
                  return _RoundSevaChip(
                    tile: tile,
                    onTap: () => _open(tile.path),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _PremiumStrip(
              isPremium: isPremium,
              onTap:
                  () => _open(
                    isPremium ? AppRoutes.profile : AppRoutes.paywall,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BhaktiTile {
  const _BhaktiTile({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.path,
  });

  final String title;
  final String subtitle;
  final String image;
  final String path;
}


class _OrangePill extends StatelessWidget {
  const _OrangePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.onBellTap});

  final String name;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jai Shyam, $name 🙏',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Shyam ki kripa bani rahe',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            onTap: onBellTap,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.orange,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.images,
    required this.isLive,
    required this.page,
    required this.onDarshan,
  });

  final List<String> images;
  final bool isLive;
  final ValueNotifier<int> page;
  final VoidCallback onDarshan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          elevation: 0,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onDarshan,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              width: double.infinity,
              height: 168,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Row(
                  children: [
                    // Text lives only on this light panel — never on the image.
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isLive
                                        ? AppColors.error
                                        : const Color(0xFF6B5A4A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isLive ? '● LIVE' : 'DARSHAN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Aaj ke Darshan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Khatu Shyam ji ke live darshan ka anand lein',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 11,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _OrangePill(
                              label: 'Abhi Darshan Karein ›',
                              onTap: onDarshan,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => page.value = i,
                        itemBuilder:
                            (context, index) => Image.asset(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      Container(color: AppColors.orangeSoft),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: page,
          builder: (context, current, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? AppColors.orange : AppColors.line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _BhaktiGridCard extends StatelessWidget {
  const _BhaktiGridCard({required this.tile, required this.onTap});

  final _BhaktiTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
            color: AppColors.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    tile.image,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tile.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.ink,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tile.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SandeshBanner extends StatelessWidget {
  const _SandeshBanner({required this.onReadMore});

  final VoidCallback onReadMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onReadMore,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF6E0), Color(0xFFFFECC4)],
            ),
            border: Border.all(color: const Color(0xFFF0D48A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/peacock_feather.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => const Text('🪶', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aaj ka Shyam Sandesh',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '“हारे का सहारा, बाबा श्याम हमारा”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'जय श्री श्याम 🙏',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _OrangePill(
                label: 'Aur Padhein ›',
                onTap: onReadMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterPromoBanner extends StatelessWidget {
  const _PosterPromoBanner({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apni Photo se Shyam Ji ka Poster Banayein',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onCreate,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: double.infinity,
              height: 176,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  children: [
                    Expanded(
                      flex: 42,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Text(
                                'Apna sundar Shyam Ji poster banayein aur sabke saath share karein',
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _OrangePill(
                              label: 'Poster Banayein ›',
                              onTap: onCreate,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 58,
                      child: Container(
                        color: const Color(0xFFF7EFD9),
                        padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFD4A84B),
                              width: 2,
                            ),
                            color: Colors.white,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox.expand(
                              child: Image.asset(
                                'assets/images/poster_sample.jpg',
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      color: AppColors.orangeSoft,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_rounded,
                                        color: AppColors.orange,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundSevaChip extends StatelessWidget {
  const _RoundSevaChip({required this.tile, required this.onTap});

  final _BhaktiTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(5),
              child: ClipOval(
                child: Image.asset(tile.image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tile.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: AppColors.ink,
              ),
            ),
            Text(
              tile.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumStrip extends StatelessWidget {
  const _PremiumStrip({required this.isPremium, required this.onTap});

  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3D6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8C96A)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shyam Premi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isPremium
                          ? 'Sadasyata sakriya hai'
                          : 'Calendar, wallpaper aur zyada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isPremium ? 'Dekhein ›' : 'Join ›',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
