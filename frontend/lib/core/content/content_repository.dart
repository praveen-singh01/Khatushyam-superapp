import '../mock/mock_models.dart';
import '../network/api_client.dart';

/// Backend-backed content (library, story, chamatkar).
class ContentRepository {
  ContentRepository(this._api);

  final ApiClient _api;

  Future<StoryContent> fetchStory() async {
    final response = await _api.get<Map<String, dynamic>>('/v1/content/story');
    final data = response.data ?? const <String, dynamic>{};
    final title = data['title'] as Map<String, dynamic>? ?? const {};
    final summary = data['summary'] as Map<String, dynamic>? ?? const {};
    final chaptersJson = data['chapters'] as List<dynamic>? ?? const [];

    final chapters =
        chaptersJson.map((raw) {
          final map = raw as Map<String, dynamic>;
          final t = map['title'] as Map<String, dynamic>? ?? const {};
          final b = map['body'] as Map<String, dynamic>? ?? const {};
          return StoryChapter(
            title: (t['hi'] as String?) ?? (t['en'] as String?) ?? '',
            body: (b['hi'] as String?) ?? (b['en'] as String?) ?? '',
          );
        }).toList();

    final youtube = data['youtubeVideoId'];
    return StoryContent(
      titleHi: (title['hi'] as String?) ?? 'खाटू श्याम कथा',
      titleEn: (title['en'] as String?) ?? 'Khatu Shyam Story',
      summaryHi:
          (summary['hi'] as String?) ??
          'श्याम बाबा की भक्ति कथा — अध्यायों में पढ़ें।',
      summaryEn:
          (summary['en'] as String?) ??
          'The devotion story of Shyam Baba — read in chapters.',
      youtubeVideoId: youtube is String && youtube.isNotEmpty ? youtube : null,
      chapters:
          chapters.isEmpty
              ? [
                const StoryChapter(
                  title: 'श्याम कथा',
                  body: 'पूरा अध्याय शीघ्र उपलब्ध होगा।',
                ),
              ]
              : chapters,
    );
  }

  Future<PosterPage> fetchPosters({String? cursor, int limit = 20}) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/v1/content/posters',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    final items = response.data?['items'] as List<dynamic>? ?? const [];
    return PosterPage(
      items:
          items.map((raw) {
            final map = raw as Map<String, dynamic>;
            final title = map['title'] as Map<String, dynamic>? ?? const {};
            return PosterItem(
              id: (map['id'] as String?) ?? '',
              title:
                  (title['hi'] as String?) ??
                  (title['en'] as String?) ??
                  (map['id'] as String?) ??
                  '',
              category: (map['category'] as String?) ?? '',
              url: (map['url'] as String?) ?? '',
              width: (map['width'] as num?)?.toInt(),
              height: (map['height'] as num?)?.toInt(),
            );
          }).toList(),
      nextCursor: response.data?['nextCursor'] as String?,
      hasMore: response.data?['hasMore'] == true,
    );
  }

  Future<List<MediaAsset>> fetchLibrary({required String type}) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/v1/content/library',
      queryParameters: {'type': type},
    );
    final items = response.data?['items'] as List<dynamic>? ?? const [];
    return items.map((raw) {
      final map = raw as Map<String, dynamic>;
      final title = map['title'] as Map<String, dynamic>? ?? const {};
      final category = (map['category'] as String?) ?? '';
      final format = (map['format'] as String?) ?? '';
      final duration = map['durationSeconds'];
      final subtitle = switch (type) {
        'ringtone' when duration is num => '${duration.round()} सेकंड · $category',
        _ => category.isEmpty ? format : '$category · $format',
      };
      return MediaAsset(
        id: (map['id'] as String?) ?? '',
        title:
            (title['hi'] as String?) ??
            (title['en'] as String?) ??
            (map['id'] as String?) ??
            '',
        subtitle: subtitle,
        url: map['url'] as String?,
        category: category,
      );
    }).toList();
  }

  ChamatkarPost _mapChamatkar(Map<String, dynamic> map) {
    return ChamatkarPost(
      id: (map['_id'] as String?) ?? (map['id'] as String?) ?? '',
      authorName: (map['authorName'] as String?) ?? 'भक्त',
      title: (map['title'] as String?) ?? '',
      story: (map['story'] as String?) ?? '',
      language: (map['language'] as String?) ?? 'hi',
      createdAt:
          DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: map['likedByMe'] == true,
    );
  }

  Future<ChamatkarPage> fetchChamatkars({String? cursor}) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/v1/chamatkars',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    final items = response.data?['items'] as List<dynamic>? ?? const [];
    return ChamatkarPage(
      items:
          items
              .map((raw) => _mapChamatkar(raw as Map<String, dynamic>))
              .toList(),
      nextCursor: response.data?['nextCursor'] as String?,
    );
  }

  Future<void> createChamatkar({
    required String title,
    required String story,
    String language = 'hi',
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/v1/chamatkars',
      data: {'title': title, 'story': story, 'language': language},
    );
  }

  Future<ChamatkarPost> toggleChamatkarLike(String id) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/v1/chamatkars/$id/like',
    );
    final item = response.data?['item'] as Map<String, dynamic>? ?? const {};
    return _mapChamatkar(item);
  }
}
