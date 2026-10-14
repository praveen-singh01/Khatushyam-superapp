import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../data/story_progress_store.dart';

const _chapterThumbs = <String>[
  'assets/images/hero_darshan.jpg',
  'assets/images/hero_night.jpg',
  'assets/images/hero_blessing.jpg',
  'assets/images/poster_sample.jpg',
  'assets/images/hero_darshan.jpg',
];

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  void _openChapter(
    BuildContext context,
    WidgetRef ref, {
    required StoryContent story,
    required int index,
  }) {
    ref.read(storyProgressProvider.notifier).markChapterOpened(index);
    final chapter = story.chapters[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => _ChapterReaderPage(
              storyTitle:
                  story.titleHi.isNotEmpty ? story.titleHi : story.titleEn,
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
    final progressAsync = ref.watch(storyProgressProvider);
    final progress = progressAsync.asData?.value ?? const StoryProgress();
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.storyTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Barbarik se Shyam Baba tak ki divya katha',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        () =>
                            ref
                                .read(storyProgressProvider.notifier)
                                .toggleBookmark(),
                    icon: Icon(
                      progress.bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color:
                          progress.bookmarked
                              ? AppColors.orange
                              : AppColors.ink,
                    ),
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
                    final total = data.chapters.length;
                    if (total == 0) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: const [
                          _StoryHeroBanner(),
                          SizedBox(height: 24),
                          Text(
                            'कथा अध्याय जल्द उपलब्ध होंगे।',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                    final completed = progress.completedCount(total);
                    final fraction = progress.progressFraction(total);
                    final resumeIndex =
                        progress.lastChapterIndex.clamp(0, total - 1);
                    final resumeChapter = data.chapters[resumeIndex];
                    final resumeMinutes = estimateReadMinutes(
                      resumeChapter.body,
                    );

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        const _StoryHeroBanner(),
                        const SizedBox(height: 16),
                        _ProgressCard(
                          completed: completed,
                          total: total,
                          fraction: fraction,
                        ),
                        const SizedBox(height: 14),
                        _ContinueCard(
                          chapterIndex: resumeIndex,
                          chapterTitle: resumeChapter.title,
                          minutes: resumeMinutes,
                          onContinue:
                              () => _openChapter(
                                context,
                                ref,
                                story: data,
                                index: resumeIndex,
                              ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'कथा के अध्याय',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.menu_book_outlined,
                              size: 16,
                              color: AppColors.inkMuted.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$total अध्याय',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...data.chapters.asMap().entries.map((entry) {
                          final index = entry.key;
                          final chapter = entry.value;
                          final preview =
                              chapter.body.length > 70
                                  ? '${chapter.body.substring(0, 70).trim()}…'
                                  : chapter.body;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChapterRow(
                              number: index + 1,
                              title: chapter.title,
                              preview: preview,
                              thumbAsset:
                                  _chapterThumbs[index % _chapterThumbs.length],
                              onTap:
                                  () => _openChapter(
                                    context,
                                    ref,
                                    story: data,
                                    index: index,
                                  ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              size: 14,
                              color: AppColors.inkMuted.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'कथाएं सर्वर से प्राप्त हो रही हैं',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryHeroBanner extends StatelessWidget {
  const _StoryHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFE0B8),
            Color(0xFFFFC078),
            Color(0xFFF08A2E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -18,
            child: Icon(
              Icons.temple_hindu_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            left: 18,
            top: 0,
            bottom: 0,
            right: 118,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'श्री श्याम कथा',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF5A2A10),
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'पढ़ें बाबा श्याम की अद्भुत\nऔर दिव्य कथा',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B3A1A),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 8,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/hero_blessing.jpg',
                width: 118,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) {
                  return Image.asset(
                    'assets/applogo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.fraction,
  });

  final int completed;
  final int total;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final pct = (fraction * 100).round().clamp(0, 100);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'आपकी कथा यात्रा',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed / $total अध्याय पूरे',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.line,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.minutes,
    required this.onContinue,
  });

  final int chapterIndex;
  final String chapterTitle;
  final int minutes;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              _chapterThumbs[chapterIndex % _chapterThumbs.length],
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'जहाँ छोड़ा था वहीं से पढ़ें',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'अध्याय ${chapterIndex + 1} – $chapterTitle',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.inkMuted.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$minutes मिनट पढ़ा गया',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onContinue,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'जारी रखें ›',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.number,
    required this.title,
    required this.preview,
    required this.thumbAsset,
    required this.onTap,
  });

  final int number;
  final String title;
  final String preview;
  final String thumbAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$number',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.orange.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  thumbAsset,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.orange.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text('अध्याय $chapterNumber / $totalChapters'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Text(
            storyTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            chapter.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '~ ${estimateReadMinutes(chapter.body)} मिनट पढ़ने में',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            chapter.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.75,
              fontSize: 18,
              color: AppColors.ink,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'जय श्री श्याम',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
