import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';

bool _useApi(Ref ref) => ref.watch(appConfigProvider).useBackendApi;

class PosterFeedState {
  const PosterFeedState({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<PosterItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool loadingMore;

  PosterFeedState copyWith({
    List<PosterItem>? items,
    String? nextCursor,
    bool? hasMore,
    bool? loadingMore,
    bool clearCursor = false,
  }) =>
      PosterFeedState(
        items: items ?? this.items,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

final posterListProvider =
    AsyncNotifierProvider<PosterListController, PosterFeedState>(
      PosterListController.new,
    );

class PosterListController extends AsyncNotifier<PosterFeedState> {
  @override
  Future<PosterFeedState> build() => _loadInitial();

  Future<PosterFeedState> _loadInitial() async {
    if (_useApi(ref)) {
      final page = await ref.read(contentRepositoryProvider).fetchPosters();
      return PosterFeedState(
        items: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore && (page.nextCursor?.isNotEmpty ?? false),
      );
    }

    final templates = await ref.read(mockApiProvider).fetchPosterTemplates();
    return PosterFeedState(
      items:
          templates
              .map(
                (t) => PosterItem(
                  id: t.id,
                  title: t.title,
                  category: t.theme,
                  url: '',
                ),
              )
              .toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadInitial);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    if (!_useApi(ref)) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(contentRepositoryProvider)
          .fetchPosters(cursor: current.nextCursor);
      state = AsyncData(
        PosterFeedState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          hasMore: page.hasMore && (page.nextCursor?.isNotEmpty ?? false),
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}
