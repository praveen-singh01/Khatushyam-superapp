import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/soft_card.dart';
import 'poster_editor_screen.dart';
import 'posters_providers.dart';

class PostersScreen extends ConsumerStatefulWidget {
  const PostersScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  ConsumerState<PostersScreen> createState() => _PostersScreenState();
}

class _PostersScreenState extends ConsumerState<PostersScreen> {
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
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 280) {
      ref.read(posterListProvider.notifier).loadMore();
    }
  }

  void _openEditor(PosterItem poster) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PosterEditorScreen(poster: poster),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(posterListProvider);

    final body = AsyncBody(
      value: feed,
      onRetry: () => ref.read(posterListProvider.notifier).refresh(),
      builder: (state) {
        if (state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.posterEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(posterListProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: state.items.length + (state.loadingMore ? 1 : 0) + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    l10n.posterHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              final itemIndex = index - 1;
              if (itemIndex >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final item = state.items[itemIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  onTap: () => _openEditor(item),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 72,
                          height: 96,
                          child:
                              item.url.isEmpty
                                  ? const ColoredBox(
                                    color: Color(0xFFFFB347),
                                    child: Icon(
                                      Icons.photo_camera_rounded,
                                      color: Colors.white,
                                    ),
                                  )
                                  : CachedNetworkImage(
                                    imageUrl: item.url,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (_, __) => const ColoredBox(
                                          color: Color(0xFFEDE4D5),
                                        ),
                                    errorWidget:
                                        (_, __, ___) => const ColoredBox(
                                          color: Color(0xFFEDE4D5),
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                  ),
                        ),
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
                            if (item.category.isNotEmpty)
                              Text(
                                item.category,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.inkMuted),
                              ),
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
              );
            },
          ),
        );
      },
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l10n.featurePosters)),
      body: body,
    );
  }
}
