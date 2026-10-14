import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoryProgress {
  const StoryProgress({
    this.lastChapterIndex = 0,
    this.completedIndices = const {},
    this.bookmarked = false,
  });

  final int lastChapterIndex;
  final Set<int> completedIndices;
  final bool bookmarked;

  int completedCount(int total) =>
      completedIndices.where((i) => i >= 0 && i < total).length;

  double progressFraction(int total) {
    if (total <= 0) return 0;
    return completedCount(total) / total;
  }

  StoryProgress copyWith({
    int? lastChapterIndex,
    Set<int>? completedIndices,
    bool? bookmarked,
  }) {
    return StoryProgress(
      lastChapterIndex: lastChapterIndex ?? this.lastChapterIndex,
      completedIndices: completedIndices ?? this.completedIndices,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  Map<String, dynamic> toJson() => {
    'lastChapterIndex': lastChapterIndex,
    'completedIndices': completedIndices.toList()..sort(),
    'bookmarked': bookmarked,
  };

  factory StoryProgress.fromJson(Map<String, dynamic> json) {
    final raw = json['completedIndices'];
    final indices = <int>{};
    if (raw is List) {
      for (final item in raw) {
        if (item is int) {
          indices.add(item);
        } else if (item is num) {
          indices.add(item.toInt());
        }
      }
    }
    return StoryProgress(
      lastChapterIndex: (json['lastChapterIndex'] as num?)?.toInt() ?? 0,
      completedIndices: indices,
      bookmarked: json['bookmarked'] == true,
    );
  }
}

class StoryProgressStore {
  static const _key = 'khatushyam_story_progress_v1';

  Future<StoryProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const StoryProgress();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoryProgress.fromJson(map);
    } catch (_) {
      return const StoryProgress();
    }
  }

  Future<void> save(StoryProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }
}

final storyProgressStoreProvider = Provider<StoryProgressStore>(
  (_) => StoryProgressStore(),
);

final storyProgressProvider =
    AsyncNotifierProvider<StoryProgressController, StoryProgress>(
      StoryProgressController.new,
    );

class StoryProgressController extends AsyncNotifier<StoryProgress> {
  @override
  Future<StoryProgress> build() {
    return ref.read(storyProgressStoreProvider).load();
  }

  Future<void> markChapterOpened(int index) async {
    final current = state.asData?.value ?? const StoryProgress();
    final next = current.copyWith(
      lastChapterIndex: index,
      completedIndices: {...current.completedIndices, index},
    );
    state = AsyncData(next);
    await ref.read(storyProgressStoreProvider).save(next);
  }

  Future<void> toggleBookmark() async {
    final current = state.asData?.value ?? const StoryProgress();
    final next = current.copyWith(bookmarked: !current.bookmarked);
    state = AsyncData(next);
    await ref.read(storyProgressStoreProvider).save(next);
  }
}

int estimateReadMinutes(String body) {
  final chars = body.trim().length;
  if (chars == 0) return 1;
  final minutes = (chars / 450).ceil();
  return minutes.clamp(1, 45);
}
