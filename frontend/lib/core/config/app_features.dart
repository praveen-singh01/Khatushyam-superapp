/// App feature identifiers for entitlement gating.
///
/// Temporary: entire app is free (`kAppFreeMode`). When billing launches,
/// set [kAppFreeMode] to false so only story / chamatkar / live stay free.
const bool kAppFreeMode = bool.fromEnvironment(
  'APP_FREE_MODE',
  defaultValue: true,
);

enum AppFeature {
  story,
  chamatkar,
  liveDarshan,
  calendar,
  aartiAlarms,
  events,
  singers,
  templeStatus,
  travelGuides,
  bhajans,
  posters,
  wallpapers,
  ringtones,
  callerTunes,
}

extension AppFeatureAccess on AppFeature {
  bool get isFree {
    if (kAppFreeMode) return true;
    return this == AppFeature.story ||
        this == AppFeature.chamatkar ||
        this == AppFeature.liveDarshan;
  }

  String get routeSegment => switch (this) {
    AppFeature.story => 'story',
    AppFeature.chamatkar => 'chamatkar',
    AppFeature.liveDarshan => 'live-darshan',
    AppFeature.calendar => 'calendar',
    AppFeature.aartiAlarms => 'aarti-alarms',
    AppFeature.events => 'events',
    AppFeature.singers => 'singers',
    AppFeature.templeStatus => 'temple-status',
    AppFeature.travelGuides => 'travel-guides',
    AppFeature.bhajans => 'bhajans',
    AppFeature.posters => 'posters',
    AppFeature.wallpapers => 'wallpapers',
    AppFeature.ringtones => 'ringtones',
    AppFeature.callerTunes => 'caller-tunes',
  };

  static AppFeature? fromRouteSegment(String segment) {
    for (final feature in AppFeature.values) {
      if (feature.routeSegment == segment) return feature;
    }
    return null;
  }
}

/// Paid features shown on Home / paywall.
const List<AppFeature> kPremiumFeatures = [
  AppFeature.calendar,
  AppFeature.aartiAlarms,
  AppFeature.events,
  AppFeature.singers,
  AppFeature.templeStatus,
  AppFeature.travelGuides,
  AppFeature.bhajans,
  AppFeature.posters,
  AppFeature.wallpapers,
  AppFeature.ringtones,
  AppFeature.callerTunes,
];
