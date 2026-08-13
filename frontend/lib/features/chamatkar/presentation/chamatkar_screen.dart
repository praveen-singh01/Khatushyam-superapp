import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/presentation/auth_providers.dart';

class ChamatkarScreen extends ConsumerStatefulWidget {
  const ChamatkarScreen({super.key});

  @override
  ConsumerState<ChamatkarScreen> createState() => _ChamatkarScreenState();
}

class _ChamatkarScreenState extends ConsumerState<ChamatkarScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      ref.read(chamatkarListProvider.notifier).loadMore();
    }
  }

  Future<void> _compose() async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      _toast('Share karne ke liye sign in karein');
      return;
    }

    final titleController = TextEditingController();
    final storyController = TextEditingController();
    String? formError;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    decoration: InputDecoration(
                      hintText: l10n.chamatkarTitleHint,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storyController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: l10n.chamatkarStoryHint,
                    ),
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      formError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final story = storyController.text.trim();
                      if (title.length < 3) {
                        setModalState(
                          () => formError = 'Shirshak kam se kam 3 akshar ka ho',
                        );
                        return;
                      }
                      if (story.length < 20) {
                        setModalState(
                          () =>
                              formError =
                                  'Anubhav kam se kam 20 akshar ka likhein',
                        );
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: Text(l10n.chamatkarPublish),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final title = titleController.text.trim();
    final story = storyController.text.trim();
    titleController.dispose();
    storyController.dispose();
    if (submitted != true || !mounted) return;
    try {
      await ref
          .read(chamatkarListProvider.notifier)
          .addPost(
            authorName: user.displayName ?? 'Bhakt',
            title: title,
            story: story,
          );
      if (mounted) _toast('Aapka anubhav share ho gaya 🙏');
    } catch (_) {
      if (mounted) _toast('Share nahi ho saka. Phir koshish karein.');
    }
  }

  Future<void> _toggleLike(ChamatkarPost post) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      _toast('Like ke liye sign in karein');
      return;
    }
    try {
      await ref.read(chamatkarListProvider.notifier).toggleLike(post.id);
    } catch (_) {
      if (mounted) _toast('Like nahi ho saka');
    }
  }

  Future<void> _share(ChamatkarPost post) async {
    final text = '${post.title}\n\n${post.story}\n\n— ${post.authorName}\nJai Shree Shyam';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _toast('Anubhav copy ho gaya — ab share karein');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(chamatkarListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
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
                builder: (state) {
                  final posts = state.items;
                  return RefreshIndicator(
                    color: AppColors.orange,
                    onRefresh:
                        () =>
                            ref.read(chamatkarListProvider.notifier).refresh(),
                    child:
                        posts.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.35,
                                ),
                                Center(child: Text(l10n.chamatkarEmpty)),
                              ],
                            )
                            : ListView.separated(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                100,
                              ),
                              itemCount:
                                  posts.length + (state.loadingMore ? 1 : 0),
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index >= posts.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.orange,
                                      ),
                                    ),
                                  );
                                }
                                final post = posts[index];
                                final initial =
                                    post.authorName.isNotEmpty
                                        ? post.authorName.characters.first
                                        : 'B';
                                return SoftCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                AppColors.orangeSoft,
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
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        post.story,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          _ActionChip(
                                            icon:
                                                post.likedByMe
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                        .favorite_border_rounded,
                                            label:
                                                post.likeCount > 0
                                                    ? '${post.likeCount}'
                                                    : 'Like',
                                            color:
                                                post.likedByMe
                                                    ? AppColors.orange
                                                    : AppColors.inkMuted,
                                            onTap: () => _toggleLike(post),
                                          ),
                                          const SizedBox(width: 16),
                                          _ActionChip(
                                            icon: Icons.ios_share_rounded,
                                            label: 'Share',
                                            onTap: () => _share(post),
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
    if (diff.inMinutes < 1) return 'Abhi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
    if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
    return '${diff.inDays} din pehle';
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = AppColors.inkMuted,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
