import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/presentation/auth_providers.dart';

class ChamatkarScreen extends ConsumerWidget {
  const ChamatkarScreen({super.key});

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final storyController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chamatkarShareCta,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: l10n.chamatkarTitleHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storyController,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(hintText: l10n.chamatkarStoryHint),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.chamatkarPublish),
              ),
            ],
          ),
        );
      },
    );

    if (submitted != true) return;
    final title = titleController.text.trim();
    final story = storyController.text.trim();
    if (title.length < 3 || story.length < 20) return;

    final user = ref.read(authStateProvider).asData?.value;
    await ref
        .read(chamatkarListProvider.notifier)
        .addPost(
          authorName: user?.displayName ?? 'भक्त',
          title: title,
          story: story,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(chamatkarListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _compose(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.chamatkarShareCta),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chamatkarTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.chamatkarSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncBody(
                value: feed,
                onRetry:
                    () => ref.read(chamatkarListProvider.notifier).refresh(),
                builder: (posts) {
                  if (posts.isEmpty) {
                    return Center(child: Text(l10n.chamatkarEmpty));
                  }
                  return RefreshIndicator(
                    color: AppColors.orange,
                    onRefresh:
                        () =>
                            ref.read(chamatkarListProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final initial =
                            post.authorName.isNotEmpty
                                ? post.authorName.characters.first
                                : 'भ';
                        return SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.orangeSoft,
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.authorName,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                        ),
                                        Text(
                                          _timeAgo(post.createdAt),
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                post.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                post.story,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 14),
                              const Row(
                                children: [
                                  _ActionChip(
                                    icon: Icons.favorite_border_rounded,
                                    label: 'Like',
                                  ),
                                  SizedBox(width: 16),
                                  _ActionChip(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    label: 'Comment',
                                  ),
                                  SizedBox(width: 16),
                                  _ActionChip(
                                    icon: Icons.share_outlined,
                                    label: 'Share',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} मिनेट पहले';
    if (diff.inHours < 24) return '${diff.inHours} घंटे पहले';
    return '${diff.inDays} दिन पहले';
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
