import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../calendar/hindu_calendar.dart';
import '../content/content_repository.dart';
import 'mock_api.dart';
import 'mock_models.dart';

final mockApiProvider = Provider<MockApi>((ref) => MockApi.instance);

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(apiClientProvider));
});

bool _useApi(Ref ref) => ref.watch(appConfigProvider).useBackendApi;

final storyProvider = FutureProvider<StoryContent>((ref) async {
  if (_useApi(ref)) {
    return ref.watch(contentRepositoryProvider).fetchStory();
  }
  return ref.watch(mockApiProvider).fetchStory();
});

class ChamatkarFeedState {
  const ChamatkarFeedState({
    required this.items,
    this.nextCursor,
    this.loadingMore = false,
  });

  final List<ChamatkarPost> items;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  ChamatkarFeedState copyWith({
    List<ChamatkarPost>? items,
    String? nextCursor,
    bool? loadingMore,
    bool clearCursor = false,
  }) =>
      ChamatkarFeedState(
        items: items ?? this.items,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

final chamatkarListProvider =
    AsyncNotifierProvider<ChamatkarListController, ChamatkarFeedState>(
      ChamatkarListController.new,
    );

class ChamatkarListController extends AsyncNotifier<ChamatkarFeedState> {
  @override
  Future<ChamatkarFeedState> build() => _loadInitial();

  Future<ChamatkarFeedState> _loadInitial() async {
    if (_useApi(ref)) {
      final page = await ref.read(contentRepositoryProvider).fetchChamatkars();
      return ChamatkarFeedState(
        items: page.items,
        nextCursor: page.nextCursor,
      );
    }
    final items = await ref.read(mockApiProvider).fetchChamatkars();
    return ChamatkarFeedState(items: items);
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
          .fetchChamatkars(cursor: current.nextCursor);
      state = AsyncData(
        ChamatkarFeedState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  Future<void> toggleLike(String id) async {
    final current = state.asData?.value;
    if (current == null) return;

    if (_useApi(ref)) {
      final updated =
          await ref.read(contentRepositoryProvider).toggleChamatkarLike(id);
      state = AsyncData(
        current.copyWith(
          items: [
            for (final post in current.items)
              if (post.id == id) updated else post,
          ],
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(
        items: [
          for (final post in current.items)
            if (post.id == id)
              post.copyWith(
                likedByMe: !post.likedByMe,
                likeCount:
                    post.likedByMe
                        ? (post.likeCount - 1).clamp(0, 1 << 30)
                        : post.likeCount + 1,
              )
            else
              post,
        ],
      ),
    );
  }

  Future<void> addPost({
    required String authorName,
    required String title,
    required String story,
  }) async {
    if (_useApi(ref)) {
      await ref
          .read(contentRepositoryProvider)
          .createChamatkar(title: title, story: story);
    } else {
      await ref
          .read(mockApiProvider)
          .createChamatkar(
            authorName: authorName,
            title: title,
            story: story,
          );
    }
    await refresh();
  }
}

class CalendarMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) => state = DateTime(month.year, month.month);
}

final calendarMonthProvider =
    NotifierProvider<CalendarMonthNotifier, DateTime>(CalendarMonthNotifier.new);

final calendarProvider = FutureProvider<List<CalendarDay>>((ref) async {
  // Always use local Hindu calendar engine (backend CMS can replace later).
  final month = ref.watch(calendarMonthProvider);
  return HinduCalendar.monthDays(month);
});

final aartiSlotsProvider =
    AsyncNotifierProvider<AartiSlotsController, List<AartiSlot>>(
      AartiSlotsController.new,
    );

class AartiSlotsController extends AsyncNotifier<List<AartiSlot>> {
  @override
  Future<List<AartiSlot>> build() {
    if (_useApi(ref)) return Future.value(const []);
    return ref.read(mockApiProvider).fetchAartiSlots();
  }

  Future<void> toggle(String id, bool enabled) async {
    if (_useApi(ref)) {
      state = const AsyncData([]);
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(mockApiProvider).setAartiEnabled(id, enabled),
    );
  }
}

final eventsProvider = FutureProvider<List<EventPoster>>((ref) async {
  if (_useApi(ref)) return const [];
  return ref.watch(mockApiProvider).fetchEvents();
});

final singersProvider = FutureProvider<List<SingerContact>>((ref) async {
  if (_useApi(ref)) return const [];
  return ref.watch(mockApiProvider).fetchSingers();
});

final templeStatusProvider = FutureProvider<TempleStatus>((ref) async {
  if (_useApi(ref)) {
    return const TempleStatus(
      isOpen: true,
      statusLabel: 'अपडेट जल्द',
      nextChangeLabel: '—',
      note: 'मंदिर स्थिति शीघ्र CMS से जुड़ेगी।',
    );
  }
  return ref.watch(mockApiProvider).fetchTempleStatus();
});

final travelGuidesProvider = FutureProvider<List<TravelGuide>>((ref) async {
  if (_useApi(ref)) return const [];
  return ref.watch(mockApiProvider).fetchTravelGuides();
});

final bhajansProvider = FutureProvider<List<BhajanTrack>>((ref) async {
  if (_useApi(ref)) return const [];
  return ref.watch(mockApiProvider).fetchBhajans();
});

final postersProvider = FutureProvider<List<PosterTemplate>>((ref) async {
  if (_useApi(ref)) return const [];
  return ref.watch(mockApiProvider).fetchPosterTemplates();
});

final wallpapersProvider = FutureProvider<List<MediaAsset>>((ref) async {
  if (_useApi(ref)) {
    return ref
        .watch(contentRepositoryProvider)
        .fetchLibrary(type: 'wallpaper');
  }
  return ref.watch(mockApiProvider).fetchWallpapers();
});

final ringtonesProvider = FutureProvider<List<MediaAsset>>((ref) async {
  if (_useApi(ref)) {
    return ref.watch(contentRepositoryProvider).fetchLibrary(type: 'ringtone');
  }
  return ref.watch(mockApiProvider).fetchRingtones();
});

final callerTunesProvider = FutureProvider<List<MediaAsset>>((ref) async {
  // No separate caller-tune catalog yet — reuse ringtone library.
  if (_useApi(ref)) {
    return ref.watch(contentRepositoryProvider).fetchLibrary(type: 'ringtone');
  }
  return ref.watch(mockApiProvider).fetchCallerTunes();
});
