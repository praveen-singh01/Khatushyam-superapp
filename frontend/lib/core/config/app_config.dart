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
      defaultValue: 'http://10.0.2.2:4000',
    );
    return AppConfig(
      apiBaseUrl: sanitizeApiBaseUrl(rawUrl),
      firebaseConfigured: const bool.fromEnvironment(
        'FIREBASE_CONFIGURED',
        defaultValue: false,
      ),
      useBackendApi: const bool.fromEnvironment(
        'USE_BACKEND_API',
        defaultValue: true,
      ),
    );
  }

  /// Strips accidental trailing junk (e.g. shell `~`) so Dio can parse the URI.
  static String sanitizeApiBaseUrl(String raw) {
    var url = raw.trim();
    while (url.endsWith('~') || url.endsWith('/') || url.endsWith('\\')) {
      url = url.substring(0, url.length - 1).trimRight();
    }
    return url;
  }
}
