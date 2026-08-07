/// Runtime configuration. Secrets and Firebase options are never hardcoded.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.firebaseConfigured = false});

  /// Base URL for the Node backend (verifies Firebase ID tokens).
  final String apiBaseUrl;

  /// True only after a real `firebase_options.dart` is generated via FlutterFire.
  final bool firebaseConfigured;

  /// Default local/dev config — override with `--dart-define`.
  static const AppConfig development = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:4000',
    ),
    firebaseConfigured: bool.fromEnvironment(
      'FIREBASE_CONFIGURED',
      defaultValue: false,
    ),
  );
}
