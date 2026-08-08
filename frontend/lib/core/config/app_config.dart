/// Runtime configuration. Secrets and Firebase options are never hardcoded.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.firebaseConfigured = false,
    this.useBackendApi = false,
  });

  /// Base URL for the Node backend (verifies Firebase ID tokens).
  final String apiBaseUrl;

  /// True only after a real `firebase_options.dart` is generated via FlutterFire.
  final bool firebaseConfigured;

  /// When true, entitlement/checkout hit the Node API (local or prod).
  /// Pair with FakeAuth (`Bearer free|premium`) or Firebase tokens.
  final bool useBackendApi;

  /// Default local/dev config — override with `--dart-define`.
  static AppConfig get development {
    const rawUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://baba.yaaro.online',
    );
    return AppConfig(
      apiBaseUrl: sanitizeApiBaseUrl(rawUrl),
      firebaseConfigured: const bool.fromEnvironment(
        'FIREBASE_CONFIGURED',
        // firebase_options.dart is checked in — production Google sign-in by default.
        // Pass --dart-define=FIREBASE_CONFIGURED=false for FakeAuth UI-only work.
        defaultValue: true,
      ),
      useBackendApi: const bool.fromEnvironment(
        'USE_BACKEND_API',
        defaultValue: true,
      ),
    );
  }

  /// Store / production build flags (HTTPS API + real Firebase required).
  ///
  /// ```bash
  /// flutter build appbundle \
  ///   --dart-define=API_BASE_URL=https://baba.yaaro.online \
  ///   --dart-define=FIREBASE_CONFIGURED=true \
  ///   --dart-define=USE_BACKEND_API=true
  /// ```
  static AppConfig get production => development;

  /// Strips accidental trailing junk (e.g. shell `~`) so Dio can parse the URI.
  static String sanitizeApiBaseUrl(String raw) {
    var url = raw.trim();
    while (url.endsWith('~') || url.endsWith('/') || url.endsWith('\\')) {
      url = url.substring(0, url.length - 1).trimRight();
    }
    return url;
  }
}
