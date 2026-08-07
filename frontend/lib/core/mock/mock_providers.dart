import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_api.dart';
import 'mock_models.dart';

final mockApiProvider = Provider<MockApi>((ref) => MockApi.instance);

final storyProvider = FutureProvider<StoryContent>((ref) {
  return ref.watch(mockApiProvider).fetchStory();
});

final chamatkarListProvider =
    AsyncNotifierProvider<ChamatkarListController, List<ChamatkarPost>>(
      ChamatkarListController.new,
    );

class ChamatkarListController extends AsyncNotifier<List<ChamatkarPost>> {
  @override
  Future<List<ChamatkarPost>> build() {
    return ref.read(mockApiProvider).fetchChamatkars();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mockApiProvider).fetchChamatkars(),
    );
  }

  Future<void> addPost({
    required String authorName,
    required String title,
    required String story,
  }) async {
    await ref
        .read(mockApiProvider)
        .createChamatkar(authorName: authorName, title: title, story: story);
    await refresh();
  }
}

final calendarProvider = FutureProvider<List<CalendarDay>>((ref) {
  return ref.watch(mockApiProvider).fetchCalendar();
});

final aartiSlotsProvider =
    AsyncNotifierProvider<AartiSlotsController, List<AartiSlot>>(
      AartiSlotsController.new,
    );

class AartiSlotsController extends AsyncNotifier<List<AartiSlot>> {
  @override
  Future<List<AartiSlot>> build() {
    return ref.read(mockApiProvider).fetchAartiSlots();
  }

  Future<void> toggle(String id, bool enabled) async {
    state = await AsyncValue.guard(
      () => ref.read(mockApiProvider).setAartiEnabled(id, enabled),
    );
  }
}

final eventsProvider = FutureProvider<List<EventPoster>>((ref) {
  return ref.watch(mockApiProvider).fetchEvents();
});

final singersProvider = FutureProvider<List<SingerContact>>((ref) {
  return ref.watch(mockApiProvider).fetchSingers();
});

final templeStatusProvider = FutureProvider<TempleStatus>((ref) {
  return ref.watch(mockApiProvider).fetchTempleStatus();
});

final travelGuidesProvider = FutureProvider<List<TravelGuide>>((ref) {
  return ref.watch(mockApiProvider).fetchTravelGuides();
});

final bhajansProvider = FutureProvider<List<BhajanTrack>>((ref) {
  return ref.watch(mockApiProvider).fetchBhajans();
});

final postersProvider = FutureProvider<List<PosterTemplate>>((ref) {
  return ref.watch(mockApiProvider).fetchPosterTemplates();
});

final wallpapersProvider = FutureProvider<List<MediaAsset>>((ref) {
  return ref.watch(mockApiProvider).fetchWallpapers();
});

final ringtonesProvider = FutureProvider<List<MediaAsset>>((ref) {
  return ref.watch(mockApiProvider).fetchRingtones();
});

final callerTunesProvider = FutureProvider<List<MediaAsset>>((ref) {
  return ref.watch(mockApiProvider).fetchCallerTunes();
});
