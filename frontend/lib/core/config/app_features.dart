/// App feature identifiers for entitlement gating.
///
/// Free forever: [story], [chamatkar], [liveDarshan].
/// Everything else requires an active Razorpay monthly subscription.
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
  bool get isFree =>
      this == AppFeature.story ||
      this == AppFeature.chamatkar ||
      this == AppFeature.liveDarshan;

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
