import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';
import 'live_providers.dart';
import 'live_youtube_player.dart';

class LiveDarshanScreen extends ConsumerWidget {
  const LiveDarshanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final live = ref.watch(liveStreamProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureLiveDarshan)),
      body: AsyncBody(
        value: live,
        onRetry: () => ref.invalidate(liveStreamProvider),
        builder: (state) {
          final title =
              state.titleEn.isNotEmpty ? state.titleEn : state.titleHi;
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: () async {
              ref.invalidate(liveStreamProvider);
              await ref.read(liveStreamProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  l10n.liveDarshanSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (state.canPlay)
                  LiveYoutubePlayer(videoId: state.youtubeVideoId!)
                else
                  SoftCard(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.orangeSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.live_tv_rounded,
                            size: 36,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.liveDarshanOfflineTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.liveDarshanOfflineMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Row(
                    children: [
                      Icon(
                        state.canPlay
                            ? Icons.sensors_rounded
                            : Icons.sensors_off_rounded,
                        color:
                            state.canPlay
                                ? AppColors.success
                                : AppColors.inkMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.canPlay
                              ? l10n.liveDarshanLiveBadge
                              : l10n.liveDarshanOfflineBadge,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(liveStreamProvider),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
