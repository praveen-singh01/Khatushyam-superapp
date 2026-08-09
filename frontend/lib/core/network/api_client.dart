import 'package:dio/dio.dart';

import '../../features/auth/domain/auth_service.dart';
import '../../features/subscription/data/subscription_repository.dart';
import '../../features/subscription/domain/subscription_state.dart';
import '../config/app_config.dart';

/// HTTP client that attaches `Authorization: Bearer <Firebase ID token>`.
class ApiClient {
  ApiClient({
    required AuthService authService,
    required AppConfig config,
    Dio? dio,
  }) : _authService = authService,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 20),
               headers: const {'Accept': 'application/json'},
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getIdToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final AuthService _authService;
  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }
}

/// Production subscription repo backed by `/v1/entitlement` and checkout APIs.
class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository(this._api);

  final ApiClient _api;

  @override
  Future<SubscriptionState> fetchEntitlement() async {
    final response = await _api.get<Map<String, dynamic>>('/v1/entitlement');
    final data = response.data ?? const <String, dynamic>{};
    return SubscriptionState.fromJson(data);
  }

  @override
  Future<SubscriptionState> startCheckout(SubscriptionPlanId plan) async {
    final planId = switch (plan) {
      SubscriptionPlanId.trialMonthly => 'trial_monthly',
      SubscriptionPlanId.weekly => 'weekly',
      SubscriptionPlanId.monthly => 'monthly',
    };
    final response = await _api.post<Map<String, dynamic>>(
      '/v1/subscriptions/razorpay/start',
      data: {'plan': planId},
    );
    final data = response.data ?? const <String, dynamic>{};
    return SubscriptionState.fromJson(data);
  }

  @override
  Future<SubscriptionState> startMonthlyCheckout() =>
      startCheckout(SubscriptionPlanId.monthly);
}
