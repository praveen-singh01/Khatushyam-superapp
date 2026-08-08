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

    return StoryContent(
      titleHi: (title['hi'] as String?) ?? 'खाटू श्याम कथा',
      titleEn: (title['en'] as String?) ?? 'Khatu Shyam Story',
      summaryHi:
          (summary['hi'] as String?) ??
          'श्याम बाबा की भक्ति कथा — जल्द ही पूर्ण वीडियो के साथ।',
      summaryEn:
          (summary['en'] as String?) ??
          'The devotion story of Shyam Baba — full video coming soon.',
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

  Future<List<ChamatkarPost>> fetchChamatkars() async {
    final response = await _api.get<Map<String, dynamic>>('/v1/chamatkars');
    final items = response.data?['items'] as List<dynamic>? ?? const [];
    return items.map((raw) {
      final map = raw as Map<String, dynamic>;
      return ChamatkarPost(
        id: (map['_id'] as String?) ?? (map['id'] as String?) ?? '',
        authorName: (map['authorName'] as String?) ?? 'भक्त',
        title: (map['title'] as String?) ?? '',
        story: (map['story'] as String?) ?? '',
        language: (map['language'] as String?) ?? 'hi',
        createdAt:
            DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );
    }).toList();
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
}
