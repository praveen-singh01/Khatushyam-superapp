import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';
import '../../live/presentation/live_youtube_player.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  void _openChapter(
    BuildContext context, {
    required StoryContent story,
    required int index,
  }) {
    final chapter = story.chapters[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => _ChapterReaderPage(
              storyTitle: story.titleHi,
              chapterNumber: index + 1,
              chapter: chapter,
              totalChapters: story.chapters.length,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final story = ref.watch(storyProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.storyTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.storySubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.orange,
              onRefresh: () async {
                ref.invalidate(storyProvider);
                await ref.read(storyProvider.future);
              },
              child: AsyncBody(
                value: story,
                onRetry: () => ref.invalidate(storyProvider),
                builder: (data) {
                  final videoId = data.youtubeVideoId;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                    SoftCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child:
                            videoId != null && videoId.isNotEmpty
                                ? AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: LiveYoutubePlayer(
                                    videoId: videoId,
                                    autoPlay: false,
                                  ),
                                )
                                : Container(
                                  height: 180,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFFFC47A),
                                        AppColors.orange,
                                        AppColors.orangeDeep,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/applogo.png',
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data.titleHi,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.summaryHi,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data.chapters.length} अध्याय · पढ़ने के लिए टैप करें',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...data.chapters.asMap().entries.map((entry) {
                      final index = entry.key;
                      final chapter = entry.value;
                      final preview =
                          chapter.body.length > 90
                              ? '${chapter.body.substring(0, 90)}…'
                              : chapter.body;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          onTap:
                              () => _openChapter(
                                context,
                                story: data,
                                index: index,
                              ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.orangeSoft,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chapter.title,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      preview,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.ink),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'पूरा अध्याय पढ़ें →',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterReaderPage extends StatelessWidget {
  const _ChapterReaderPage({
    required this.storyTitle,
    required this.chapterNumber,
    required this.chapter,
    required this.totalChapters,
  });

  final String storyTitle;
  final int chapterNumber;
  final StoryChapter chapter;
  final int totalChapters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('अध्याय $chapterNumber / $totalChapters'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            storyTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            chapter.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            chapter.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.55,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'जय श्री श्याम 🙏',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
