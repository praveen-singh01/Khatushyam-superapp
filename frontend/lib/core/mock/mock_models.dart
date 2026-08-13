class StoryContent {
  const StoryContent({
    required this.titleHi,
    required this.titleEn,
    required this.summaryHi,
    required this.summaryEn,
    required this.chapters,
    this.youtubeVideoId,
  });

  final String titleHi;
  final String titleEn;
  final String summaryHi;
  final String summaryEn;
  final List<StoryChapter> chapters;
  final String? youtubeVideoId;
}

class StoryChapter {
  const StoryChapter({required this.title, required this.body});

  final String title;
  final String body;
}

class ChamatkarPost {
  const ChamatkarPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.story,
    required this.language,
    required this.createdAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String authorName;
  final String title;
  final String story;
  final String language;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  ChamatkarPost copyWith({
    int? likeCount,
    bool? likedByMe,
  }) =>
      ChamatkarPost(
        id: id,
        authorName: authorName,
        title: title,
        story: story,
        language: language,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}

class ChamatkarPage {
  const ChamatkarPage({required this.items, this.nextCursor});

  final List<ChamatkarPost> items;
  final String? nextCursor;
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.title,
    required this.note,
    required this.isSpecial,
    this.weekdayHi = '',
    this.weekdayEn = '',
    this.tithiHi = '',
    this.tithiEn = '',
    this.isToday = false,
  });

  final DateTime date;
  final String title;
  final String note;
  final bool isSpecial;
  final String weekdayHi;
  final String weekdayEn;
  final String tithiHi;
  final String tithiEn;
  final bool isToday;
}

class AartiSlot {
  const AartiSlot({
    required this.id,
    required this.name,
    required this.timeLabel,
    required this.enabled,
  });

  final String id;
  final String name;
  final String timeLabel;
  final bool enabled;

  AartiSlot copyWith({bool? enabled}) => AartiSlot(
    id: id,
    name: name,
    timeLabel: timeLabel,
    enabled: enabled ?? this.enabled,
  );
}

class EventPoster {
  const EventPoster({
    required this.id,
    required this.title,
    required this.city,
    required this.dateLabel,
    required this.venue,
  });

  final String id;
  final String title;
  final String city;
  final String dateLabel;
  final String venue;
}

class TravelGuide {
  const TravelGuide({
    required this.id,
    required this.fromCity,
    required this.title,
    required this.steps,
  });

  final String id;
  final String fromCity;
  final String title;
  final List<String> steps;
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.title,
    required this.subtitle,
    this.url,
    this.category,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? url;
  final String? category;
}

class PosterTemplate {
  const PosterTemplate({
    required this.id,
    required this.title,
    required this.theme,
  });

  final String id;
  final String title;
  final String theme;
}

class PosterItem {
  const PosterItem({
    required this.id,
    required this.title,
    required this.category,
    required this.url,
    this.width,
    this.height,
  });

  final String id;
  final String title;
  final String category;
  final String url;
  final int? width;
  final int? height;
}

class PosterPage {
  const PosterPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<PosterItem> items;
  final String? nextCursor;
  final bool hasMore;
}
