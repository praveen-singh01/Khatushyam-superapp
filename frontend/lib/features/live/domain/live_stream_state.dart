import 'package:equatable/equatable.dart';

/// Backend-controlled Live Darshan config from `GET /v1/content/live`.
class LiveStreamState extends Equatable {
  const LiveStreamState({
    required this.isLive,
    required this.youtubeVideoId,
    required this.titleHi,
    required this.titleEn,
    this.embedUrl,
    this.access = 'free',
  });

  final bool isLive;
  final String? youtubeVideoId;
  final String titleHi;
  final String titleEn;
  final String? embedUrl;
  final String access;

  bool get canPlay => isLive && youtubeVideoId != null && youtubeVideoId!.isNotEmpty;

  factory LiveStreamState.offline() => const LiveStreamState(
    isLive: false,
    youtubeVideoId: null,
    titleHi: 'Khatu Shyam Live Darshan',
    titleEn: 'Khatu Shyam Live Darshan',
  );

  factory LiveStreamState.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final titleMap =
        title is Map ? Map<String, dynamic>.from(title) : const <String, dynamic>{};
    return LiveStreamState(
      isLive: json['isLive'] == true,
      youtubeVideoId: json['youtubeVideoId'] as String?,
      titleHi: (titleMap['hi'] as String?) ?? 'Khatu Shyam Live Darshan',
      titleEn: (titleMap['en'] as String?) ?? 'Khatu Shyam Live Darshan',
      embedUrl: json['embedUrl'] as String?,
      access: (json['access'] as String?) ?? 'free',
    );
  }

  @override
  List<Object?> get props => [
    isLive,
    youtubeVideoId,
    titleHi,
    titleEn,
    embedUrl,
    access,
  ];
}
