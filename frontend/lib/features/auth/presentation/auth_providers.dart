import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../data/fake_auth_service.dart';
import '../data/firebase_auth_service.dart';
import '../domain/auth_service.dart';
import '../domain/auth_user.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.development);

final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.firebaseConfigured) {
    return FirebaseAuthService();
  }
  // Safe default until FlutterFire is configured — UI + tests still work.
  return FakeAuthService();
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    authService: ref.watch(authServiceProvider),
    config: ref.watch(appConfigProvider),
  );
});
