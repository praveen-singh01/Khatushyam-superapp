import '../mock/mock_models.dart';

/// Local Hindu calendar helpers (approximate tithi + known auspicious days).
/// Good enough for devotion UX; replace with temple panchang feed later.
class HinduCalendar {
  HinduCalendar._();

  static const _weekdayHi = [
    'Somvaar',
    'Mangalvaar',
    'Budhvaar',
    'Guruvaar',
    'Shukravaar',
    'Shanivaar',
    'Ravivaar',
  ];
  static const _weekdayEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _tithiHi = [
    'Pratipada',
    'Dwitiya',
    'Tritiya',
    'Chaturthi',
    'Panchami',
    'Shashthi',
    'Saptami',
    'Ashtami',
    'Navami',
    'Dashami',
    'Ekadashi',
    'Dwadashi',
    'Trayodashi',
    'Chaturdashi',
    'Purnima',
    'Pratipada',
    'Dwitiya',
    'Tritiya',
    'Chaturthi',
    'Panchami',
    'Shashthi',
    'Saptami',
    'Ashtami',
    'Navami',
    'Dashami',
    'Ekadashi',
    'Dwadashi',
    'Trayodashi',
    'Chaturdashi',
    'Amavasya',
  ];

  static const _tithiEn = [
    'Pratipada',
    'Dwitiya',
    'Tritiya',
    'Chaturthi',
    'Panchami',
    'Shashthi',
    'Saptami',
    'Ashtami',
    'Navami',
    'Dashami',
    'Ekadashi',
    'Dwadashi',
    'Trayodashi',
    'Chaturdashi',
    'Purnima',
    'Pratipada',
    'Dwitiya',
    'Tritiya',
    'Chaturthi',
    'Panchami',
    'Shashthi',
    'Saptami',
    'Ashtami',
    'Navami',
    'Dashami',
    'Ekadashi',
    'Dwadashi',
    'Trayodashi',
    'Chaturdashi',
    'Amavasya',
  ];

  /// Approximate tithi index 0–29 from a known new-moon epoch.
  static int tithiIndex(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    // Approx new moon: 2000-01-06 18:14 UTC
    final epoch = DateTime.utc(2000, 1, 6, 18, 14);
    const synodic = 29.530588853;
    final days =
        local.toUtc().difference(epoch).inMilliseconds / 86400000.0;
    final age = days % synodic;
    final idx = (age / (synodic / 30)).floor();
    return idx.clamp(0, 29);
  }

  static String pakshaHi(int index) =>
      index < 15 ? 'Shukla Paksha' : 'Krishna Paksha';

  static String pakshaEn(int index) =>
      index < 15 ? 'Shukla Paksha' : 'Krishna Paksha';

  static ({String hi, String en, bool special}) festivalFor(DateTime date) {
    final t = tithiIndex(date);
    final md = '${date.month}-${date.day}';

    // Fixed / approximate annual devotion markers (Gregorian anchors).
    const fixed = <String, ({String hi, String en})>{
      '3-14': (hi: 'Holi / Phalgun utsav', en: 'Holi / Phalgun fest'),
      '8-16': (hi: 'Janmashtami', en: 'Janmashtami'),
      '10-20': (hi: 'Diwali', en: 'Diwali'),
      '11-5': (hi: 'Govardhan Puja', en: 'Govardhan Puja'),
    };

    if (fixed.containsKey(md)) {
      final f = fixed[md]!;
      return (hi: f.hi, en: f.en, special: true);
    }

    // Recurring lunar-auspicious days.
    if (t == 10 || t == 25) {
      return (
        hi: 'Ekadashi vrat',
        en: 'Ekadashi vrat',
        special: true,
      );
    }
    if (t == 14) {
      return (hi: 'Purnima', en: 'Purnima', special: true);
    }
    if (t == 29) {
      return (hi: 'Amavasya', en: 'Amavasya', special: true);
    }
    // Monday + Shyam devotion cue
    if (date.weekday == DateTime.monday) {
      return (
        hi: 'Somvaar Shyam bhakti',
        en: 'Monday Shyam devotion',
        special: true,
      );
    }
    return (hi: '', en: '', special: false);
  }

  static CalendarDay dayFor(DateTime date, {DateTime? today}) {
    final d = DateTime(date.year, date.month, date.day);
    final now = today ?? DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final t = tithiIndex(d);
    final fest = festivalFor(d);
    final weekdayIndex = d.weekday - 1; // Mon=0
    final title =
        fest.hi.isNotEmpty
            ? fest.hi
            : '${pakshaHi(t)} · ${_tithiHi[t]}';
    final note =
        fest.en.isNotEmpty
            ? '${_weekdayEn[weekdayIndex]} · ${pakshaEn(t)} · ${_tithiEn[t]} · ${fest.en}'
            : '${_weekdayEn[weekdayIndex]} · ${pakshaEn(t)} · ${_tithiEn[t]}';

    return CalendarDay(
      date: d,
      title: title,
      note: note,
      isSpecial: fest.special,
      weekdayHi: _weekdayHi[weekdayIndex],
      weekdayEn: _weekdayEn[weekdayIndex],
      tithiHi: '${pakshaHi(t)} ${_tithiHi[t]}',
      tithiEn: '${pakshaEn(t)} ${_tithiEn[t]}',
      isToday: d == todayOnly,
    );
  }

  static List<CalendarDay> monthDays(DateTime month, {DateTime? today}) {
    final first = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 1);
    final days = next.difference(first).inDays;
    return List.generate(
      days,
      (i) => dayFor(DateTime(month.year, month.month, i + 1), today: today),
    );
  }

  /// Leading blanks so grid starts on Monday.
  static int leadingBlanks(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    return first.weekday - 1; // Mon=0 … Sun=6
  }
}
