import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import 'poster_compose_card.dart';
import 'poster_photo_flow.dart';
import 'poster_profile_store.dart';
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
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      ref.read(posterListProvider.notifier).loadMore();
    }
  }

  Future<void> _pickSharedPhoto() async {
    final profile = ref.read(posterProfileProvider).asData?.value;
    if (profile?.isProcessingPhoto == true) return;

    final preparedPath = await runPosterPhotoFlow(context);
    if (preparedPath == null || !mounted) return;

    try {
      await ref
          .read(posterProfileProvider.notifier)
          .commitPreparedPhoto(preparedPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
    }
  }

  Future<void> _editNamePlate(String currentName, String currentSubtitle) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: currentName);
    final subtitleController = TextEditingController(text: currentSubtitle);

    final saved = await showModalBottomSheet<bool>(
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
                l10n.posterEditNamePlate,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: l10n.posterNameHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.posterSubtitleHint),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.posterSaveNamePlate),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && mounted) {
      await ref.read(posterProfileProvider.notifier).setNamePlate(
        displayName: nameController.text,
        subtitle: subtitleController.text,
      );
    }
    nameController.dispose();
    subtitleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(posterListProvider);
    final profileAsync = ref.watch(posterProfileProvider);

    final body = profileAsync.when(
      loading:
          () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error:
          (_, __) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(posterProfileProvider),
              child: Text(l10n.retry),
            ),
          ),
      data: (profile) {
        final list = AsyncBody(
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
              color: AppColors.orange,
              onRefresh: () => ref.read(posterListProvider.notifier).refresh(),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: state.items.length + 1 + (state.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        l10n.posterHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
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
                    padding: const EdgeInsets.only(bottom: 28),
                    child: PosterComposeCard(
                      key: ValueKey('${item.id}-${profile.photoPath ?? ''}'),
                      poster: item,
                      displayName: profile.displayName,
                      subtitle: profile.subtitle,
                      userPhoto: profile.photoFile,
                      onPickPhoto: _pickSharedPhoto,
                      onEditNamePlate:
                          () => _editNamePlate(
                            profile.displayName,
                            profile.subtitle,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );

        if (!profile.isProcessingPhoto) return list;

        return Stack(
          children: [
            list,
            const ModalBarrier(dismissible: false, color: Color(0x66000000)),
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 12),
                      Text('Removing background…'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(l10n.featurePosters),
      ),
      body: body,
    );
  }
}
