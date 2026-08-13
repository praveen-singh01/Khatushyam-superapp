import 'mock_models.dart';

/// In-memory mock API used while backend endpoints are built.
class MockApi {
  MockApi._();
  static final MockApi instance = MockApi._();

  static const _delay = Duration(milliseconds: 280);

  final List<ChamatkarPost> _chamatkars = [
    ChamatkarPost(
      id: 'c1',
      authorName: 'Ramesh',
      title: 'Shyam Baba ki kripa',
      story:
          'Jab main Khatu pahuncha to mandir band tha, par ek bhakt ne raat ka intezaar karwaya. Subah darshan milte hi man shant ho gaya.',
      language: 'hi',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likeCount: 12,
    ),
    ChamatkarPost(
      id: 'c2',
      authorName: 'Sunita',
      title: 'Hope after hard days',
      story:
          'After months of worry for my child, a neighbor shared a Shyam bhajan. Listening every morning gave our family peace.',
      language: 'en',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likeCount: 5,
    ),
  ];

  List<AartiSlot> _aartiSlots = const [
    AartiSlot(
      id: 'a1',
      name: 'Mangala Aarti',
      timeLabel: '5:00 AM',
      enabled: true,
    ),
    AartiSlot(
      id: 'a2',
      name: 'Shringar Aarti',
      timeLabel: '7:30 AM',
      enabled: false,
    ),
    AartiSlot(id: 'a3', name: 'Bhog Aarti', timeLabel: '12:00 PM', enabled: true),
    AartiSlot(
      id: 'a4',
      name: 'Sandhya Aarti',
      timeLabel: '6:30 PM',
      enabled: true,
    ),
    AartiSlot(id: 'a5', name: 'Shayan Aarti', timeLabel: '9:00 PM', enabled: false),
    AartiSlot(
      id: 'a6',
      name: 'Ratri Aarti',
      timeLabel: '10:30 PM',
      enabled: false,
    ),
  ];

  Future<T> _wait<T>(T value) async {
    await Future<void>.delayed(_delay);
    return value;
  }

  Future<StoryContent> fetchStory() => _wait(
    const StoryContent(
      titleHi: 'Khatu Shyam Baba ki katha',
      titleEn: 'The story of Khatu Shyam Baba',
      summaryHi:
          'Barbarik ki bhakti aur balidan ki kahani — simple words mein, nayi peedi ke liye.',
      summaryEn:
          'The devotion and sacrifice of Barbarik — told simply for every devotee.',
      chapters: [
        StoryChapter(
          title: 'Barbarik kaun the?',
          body:
              'Barbarik Ghatotkach ke putra the. Unhone Mahabharat yudh mein adbhut shakti prapt ki thi.',
        ),
        StoryChapter(
          title: 'Shir daan',
          body:
              'Krishna ki ichha par unhone apna sheesh arpit kiya. Usi bhakti se ve Khatu Shyam Baba kehlaaye.',
        ),
        StoryChapter(
          title: 'Aaj ki bhakti',
          body:
              'Shraddhalu aaj bhi Khatu mein darshan karte hain aur Shyam naam se manokamnaayein poori hone ki aastha rakhte hain.',
        ),
      ],
    ),
  );

  Future<List<ChamatkarPost>> fetchChamatkars() =>
      _wait(List.unmodifiable(_chamatkars));

  Future<ChamatkarPost> createChamatkar({
    required String authorName,
    required String title,
    required String story,
    String language = 'hi',
  }) async {
    await Future<void>.delayed(_delay);
    final post = ChamatkarPost(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      authorName: authorName,
      title: title,
      story: story,
      language: language,
      createdAt: DateTime.now(),
    );
    _chamatkars.insert(0, post);
    return post;
  }

  Future<List<CalendarDay>> fetchCalendar() {
    final now = DateTime.now();
    return _wait([
      CalendarDay(
        date: now,
        title: 'Aaj',
        note: 'Regular aarti aur bhajan',
        isSpecial: false,
      ),
      CalendarDay(
        date: now.add(const Duration(days: 2)),
        title: 'Ekadashi',
        note: 'Upvaas aur vishesh bhakti ka din',
        isSpecial: true,
      ),
      CalendarDay(
        date: now.add(const Duration(days: 8)),
        title: 'Amavasya',
        note: 'Deep daan aur shanti prarthana',
        isSpecial: true,
      ),
      CalendarDay(
        date: now.add(const Duration(days: 15)),
        title: 'Shyam Jayanti saptah',
        note: 'Community kirtan aur yatra guidance',
        isSpecial: true,
      ),
    ]);
  }

  Future<List<AartiSlot>> fetchAartiSlots() =>
      _wait(List.unmodifiable(_aartiSlots));

  Future<List<AartiSlot>> setAartiEnabled(String id, bool enabled) async {
    await Future<void>.delayed(_delay);
    _aartiSlots =
        _aartiSlots
            .map(
              (slot) => slot.id == id ? slot.copyWith(enabled: enabled) : slot,
            )
            .toList();
    return List.unmodifiable(_aartiSlots);
  }

  Future<List<EventPoster>> fetchEvents() => _wait(const [
    EventPoster(
      id: 'e1',
      title: 'Raat bhar kirtan',
      city: 'Sikar',
      dateLabel: 'Saturday, 8:00 PM',
      venue: 'Shyam Mandir Chowk',
    ),
    EventPoster(
      id: 'e2',
      title: 'Bhajan Sandhya',
      city: 'Jaipur',
      dateLabel: 'Sunday, 6:30 PM',
      venue: 'Community hall',
    ),
    EventPoster(
      id: 'e3',
      title: 'Ghar kirtan',
      city: 'Delhi',
      dateLabel: 'Friday, 7:00 PM',
      venue: 'Sector 12',
    ),
  ]);

  Future<List<TravelGuide>> fetchTravelGuides() => _wait(const [
    TravelGuide(
      id: 't1',
      fromCity: 'Delhi',
      title: 'Delhi se Khatu',
      steps: [
        'Delhi Cantt / New Delhi se Sikar/Rewari route ki train lein',
        'Sikar se bus ya taxi se Khatu pahunchein',
        'Mandir campus mein jootey/bag ki vyavastha dekhein',
      ],
    ),
    TravelGuide(
      id: 't2',
      fromCity: 'Jaipur',
      title: 'Jaipur se Khatu',
      steps: [
        'Jaipur Sindhi Camp se Sikar bus lein',
        'Sikar se Khatu Shyam Ji ke liye seedhi bus',
        'Subah jaldi niklein — garmi/bheed kam rehti hai',
      ],
    ),
  ]);

  Future<List<PosterTemplate>> fetchPosterTemplates() => _wait(const [
    PosterTemplate(id: 'p1', title: 'Jai Shyam', theme: 'Kesariya'),
    PosterTemplate(id: 'p2', title: 'Parivar darshan', theme: 'Sona'),
    PosterTemplate(id: 'p3', title: 'Kirtan invitation', theme: 'Simple'),
  ]);

  Future<List<MediaAsset>> fetchWallpapers() => _wait(const [
    MediaAsset(id: 'w1', title: 'Mandir pratah', subtitle: '1080×1920'),
    MediaAsset(id: 'w2', title: 'Shyam mukut', subtitle: '1080×1920'),
    MediaAsset(id: 'w3', title: 'Dhwaja', subtitle: '1440×2560'),
  ]);

  Future<List<MediaAsset>> fetchRingtones() => _wait(const [
    MediaAsset(id: 'r1', title: 'Shyam ghanta', subtitle: '12 sec'),
    MediaAsset(id: 'r2', title: 'Aarti tone', subtitle: '18 sec'),
    MediaAsset(id: 'r3', title: 'Shyam naam', subtitle: '22 sec'),
  ]);

  Future<List<MediaAsset>> fetchCallerTunes() => _wait(const [
    MediaAsset(id: 'ct1', title: 'Jai Shyam tune', subtitle: 'Caller tune'),
    MediaAsset(id: 'ct2', title: 'Bhakti beep', subtitle: 'Caller tune'),
  ]);
}
