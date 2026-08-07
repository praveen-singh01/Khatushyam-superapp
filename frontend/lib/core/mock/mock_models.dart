class StoryContent {
  const StoryContent({
    required this.titleHi,
    required this.titleEn,
    required this.summaryHi,
    required this.summaryEn,
    required this.chapters,
  });

  final String titleHi;
  final String titleEn;
  final String summaryHi;
  final String summaryEn;
  final List<StoryChapter> chapters;
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
  });

  final String id;
  final String authorName;
  final String title;
  final String story;
  final String language;
  final DateTime createdAt;
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.title,
    required this.note,
    required this.isSpecial,
  });

  final DateTime date;
  final String title;
  final String note;
  final bool isSpecial;
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

class SingerContact {
  const SingerContact({
    required this.id,
    required this.name,
    required this.city,
    required this.phone,
    required this.specialty,
  });

  final String id;
  final String name;
  final String city;
  final String phone;
  final String specialty;
}

class TempleStatus {
  const TempleStatus({
    required this.isOpen,
    required this.statusLabel,
    required this.nextChangeLabel,
    required this.note,
  });

  final bool isOpen;
  final String statusLabel;
  final String nextChangeLabel;
  final String note;
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

class BhajanTrack {
  const BhajanTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationLabel,
  });

  final String id;
  final String title;
  final String artist;
  final String durationLabel;
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
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
