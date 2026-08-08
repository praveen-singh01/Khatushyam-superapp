import 'mock_models.dart';

/// In-memory mock API used while backend endpoints are built.
class MockApi {
  MockApi._();
  static final MockApi instance = MockApi._();

  static const _delay = Duration(milliseconds: 280);

  final List<ChamatkarPost> _chamatkars = [
    ChamatkarPost(
      id: 'c1',
      authorName: 'रमेश',
      title: 'श्याम बाबा की कृपा',
      story:
          'जब मैं खटु पहुँचा तो मंदिर बंद था, पर एक भक्त ने रात का इंतज़ार करवाया। सुबह दर्शन मिलते ही मन शांत हो गया।',
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
      name: 'मंगला आरती',
      timeLabel: '5:00 AM',
      enabled: true,
    ),
    AartiSlot(
      id: 'a2',
      name: 'श्रंगार आरती',
      timeLabel: '7:30 AM',
      enabled: false,
    ),
    AartiSlot(id: 'a3', name: 'भोग आरती', timeLabel: '12:00 PM', enabled: true),
    AartiSlot(
      id: 'a4',
      name: 'संध्या आरती',
      timeLabel: '6:30 PM',
      enabled: true,
    ),
    AartiSlot(id: 'a5', name: 'शयन आरती', timeLabel: '9:00 PM', enabled: false),
    AartiSlot(
      id: 'a6',
      name: 'रात्रि आरती',
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
      titleHi: 'खाटू श्याम बाबा की कथा',
      titleEn: 'The story of Khatu Shyam Baba',
      summaryHi:
          'बारबरीक की भक्ति और बलिदान की कहानी — सरल शब्दों में, नई पीढ़ी के लिए।',
      summaryEn:
          'The devotion and sacrifice of Barbarik — told simply for every devotee.',
      chapters: [
        StoryChapter(
          title: 'बारबरीक कौन थे?',
          body:
              'बारबरीक घटोत्कच के पुत्र थे। उन्होंने महाभारत युद्ध में अद्भुत शक्ति प्राप्त की थी।',
        ),
        StoryChapter(
          title: 'शिर दान',
          body:
              'कृष्ण की इच्छा पर उन्होंने अपना शीश अर्पित किया। उसी भक्ति से वे खाटू श्याम बाबा कहलाए।',
        ),
        StoryChapter(
          title: 'आज की भक्ति',
          body:
              'श्रद्धालु आज भी खाटू में दर्शन करते हैं और श्याम नाम से मनोकामनाएँ पूरी होने की आस्था रखते हैं।',
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
        title: 'आज',
        note: 'नियमित आरती और भजन',
        isSpecial: false,
      ),
      CalendarDay(
        date: now.add(const Duration(days: 2)),
        title: 'एकादशी',
        note: 'उपवास और विशेष भक्ति का दिन',
        isSpecial: true,
      ),
      CalendarDay(
        date: now.add(const Duration(days: 8)),
        title: 'अमावस्या',
        note: 'दीप दान और शांति प्रार्थना',
        isSpecial: true,
      ),
      CalendarDay(
        date: now.add(const Duration(days: 15)),
        title: 'श्याम जयंती सप्ताह',
        note: 'समुदाय कीर्तन और यात्रा मार्गदर्शन',
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
      title: 'रात भर कीर्तन',
      city: 'सीकर',
      dateLabel: 'शनिवार, 8:00 PM',
      venue: 'श्याम मंदिर चौक',
    ),
    EventPoster(
      id: 'e2',
      title: 'भजन संध्या',
      city: 'जयपुर',
      dateLabel: 'रविवार, 6:30 PM',
      venue: 'सामुदायिक भवन',
    ),
    EventPoster(
      id: 'e3',
      title: 'घर कीर्तन',
      city: 'दिल्ली',
      dateLabel: 'शुक्रवार, 7:00 PM',
      venue: 'सेक्टर 12',
    ),
  ]);

  Future<List<SingerContact>> fetchSingers() => _wait(const [
    SingerContact(
      id: 's1',
      name: 'पंडित हरिओम',
      city: 'खाटू',
      phone: '+91 98XXX XXX01',
      specialty: 'श्याम भजन',
    ),
    SingerContact(
      id: 's2',
      name: 'मीरा देवी',
      city: 'सीकर',
      phone: '+91 98XXX XXX22',
      specialty: 'कीर्तन मंडली',
    ),
    SingerContact(
      id: 's3',
      name: 'रामकिशन जी',
      city: 'जयपुर',
      phone: '+91 98XXX XXX45',
      specialty: 'आरती व भजन',
    ),
  ]);

  Future<TempleStatus> fetchTempleStatus() => _wait(
    const TempleStatus(
      isOpen: true,
      statusLabel: 'मंदिर खुला है',
      nextChangeLabel: 'शयन आरती 9:00 PM',
      note: 'भीड़ सामान्य है। पानी की बोतल साथ रखें।',
    ),
  );

  Future<List<TravelGuide>> fetchTravelGuides() => _wait(const [
    TravelGuide(
      id: 't1',
      fromCity: 'दिल्ली',
      title: 'दिल्ली से खाटू',
      steps: [
        'दिल्ली कैंट / न्यू दिल्ली से सीकर/रेवाड़ी मार्ग की ट्रेन लें',
        'सीकर से बस या टैक्सी से खाटू पहुँचें',
        'मंदिर परिसर में जूते/बैग की व्यवस्था देखें',
      ],
    ),
    TravelGuide(
      id: 't2',
      fromCity: 'जयपुर',
      title: 'जयपुर से खाटू',
      steps: [
        'जयपुर सिंधी कैंप से सीकर बस लें',
        'सीकर से खाटू श्याम जी के लिए सीधी बस',
        'सुबह जल्दी निकलें — गर्मी/भीड़ कम रहती है',
      ],
    ),
  ]);

  Future<List<BhajanTrack>> fetchBhajans() => _wait(const [
    BhajanTrack(
      id: 'b1',
      title: 'श्याम तेरा नाम',
      artist: 'भक्ति संग्रह',
      durationLabel: '4:12',
    ),
    BhajanTrack(
      id: 'b2',
      title: 'खाटू वाले श्याम',
      artist: 'लोक भजन',
      durationLabel: '5:01',
    ),
    BhajanTrack(
      id: 'b3',
      title: 'मेरे श्याम बाबा',
      artist: 'आरती माला',
      durationLabel: '3:40',
    ),
  ]);

  Future<List<PosterTemplate>> fetchPosterTemplates() => _wait(const [
    PosterTemplate(id: 'p1', title: 'जय श्याम', theme: 'केसरिया'),
    PosterTemplate(id: 'p2', title: 'परिवार दर्शन', theme: 'सोना'),
    PosterTemplate(id: 'p3', title: 'कीर्तन आमंत्रण', theme: 'सरल'),
  ]);

  Future<List<MediaAsset>> fetchWallpapers() => _wait(const [
    MediaAsset(id: 'w1', title: 'मंदिर प्रातः', subtitle: '1080×1920'),
    MediaAsset(id: 'w2', title: 'श्याम मुकुट', subtitle: '1080×1920'),
    MediaAsset(id: 'w3', title: 'ध्वजा', subtitle: '1440×2560'),
  ]);

  Future<List<MediaAsset>> fetchRingtones() => _wait(const [
    MediaAsset(id: 'r1', title: 'श्याम घंटा', subtitle: '12 सेकंड'),
    MediaAsset(id: 'r2', title: 'आरती टोन', subtitle: '18 सेकंड'),
    MediaAsset(id: 'r3', title: 'श्याम नाम', subtitle: '22 सेकंड'),
  ]);

  Future<List<MediaAsset>> fetchCallerTunes() => _wait(const [
    MediaAsset(id: 'ct1', title: 'जय श्याम ट्यून', subtitle: 'कॉलर ट्यून'),
    MediaAsset(id: 'ct2', title: 'भक्ति बीप', subtitle: 'कॉलर ट्यून'),
  ]);
}
