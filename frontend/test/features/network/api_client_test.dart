import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khatushyam_app/core/config/app_config.dart';
import 'package:khatushyam_app/core/network/api_client.dart';
import 'package:khatushyam_app/features/auth/data/fake_auth_service.dart';
import 'package:khatushyam_app/features/auth/domain/auth_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient', () {
    test('attaches Firebase ID token as Bearer Authorization', () async {
      final auth = FakeAuthService(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      late RequestOptions captured;

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = _CapturingAdapter((options) {
        captured = options;
      });

      final client = ApiClient(
        authService: auth,
        config: const AppConfig(apiBaseUrl: 'https://api.example.com'),
        dio: dio,
      );

      await client.get<Map<String, dynamic>>('/v1/entitlement');

      expect(captured.headers['Authorization'], 'Bearer fake-id-token-u1');
      auth.dispose();
    });

    test('omits Authorization when signed out', () async {
      final auth = FakeAuthService();
      late RequestOptions captured;

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = _CapturingAdapter((options) {
        captured = options;
      });

      final client = ApiClient(
        authService: auth,
        config: const AppConfig(apiBaseUrl: 'https://api.example.com'),
        dio: dio,
      );

      await client.get<Map<String, dynamic>>('/v1/health');

      expect(captured.headers['Authorization'], isNull);
      auth.dispose();
    });
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.onRequest);

  final void Function(RequestOptions options) onRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
