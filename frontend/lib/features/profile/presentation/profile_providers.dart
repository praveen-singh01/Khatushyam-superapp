import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/legal_policies.dart';
import '../domain/app_profile.dart';

final legalPoliciesProvider = FutureProvider<LegalPolicies>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/v1/legal/policies');
  return LegalPolicies.fromJson(response.data ?? const {});
});

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<AppProfile> fetchMe() async {
    final response = await _api.get<Map<String, dynamic>>('/v1/auth/me');
    final user = response.data?['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw StateError('Missing user in /v1/auth/me');
    }
    return AppProfile.fromJson(user);
  }

  Future<AppProfile> completeOnboarding({
    required String phone,
    String? displayName,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/v1/auth/onboarding',
      data: {
        'phone': phone,
        if (displayName != null && displayName.trim().isNotEmpty)
          'displayName': displayName.trim(),
      },
    );
    final user = response.data?['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw StateError('Missing user in onboarding response');
    }
    return AppProfile.fromJson(user);
  }

  Future<AppProfile> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/v1/auth/me',
      data: {
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (phone != null) 'phone': phone,
      },
    );
    final user = response.data?['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw StateError('Missing user in profile update');
    }
    return AppProfile.fromJson(user);
  }

  Future<String> uploadProfilePhoto({
    required List<int> bytes,
    required String contentType,
  }) async {
    final presign = await _api.post<Map<String, dynamic>>(
      '/v1/uploads/presign',
      data: {'contentType': contentType, 'purpose': 'profile_photo'},
    );
    final data = presign.data ?? const <String, dynamic>{};
    final uploadUrl = data['uploadUrl'] as String?;
    final publicUrl = data['publicUrl'] as String?;
    if (uploadUrl == null || publicUrl == null) {
      throw StateError('Presign missing uploadUrl/publicUrl');
    }
    final put = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (put.statusCode < 200 || put.statusCode >= 300) {
      throw DioException(
        requestOptions: RequestOptions(path: uploadUrl),
        message: 'S3 upload failed (${put.statusCode})',
      );
    }
    return publicUrl;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

/// Backend profile (name/phone/onboarding). Refetches when auth uid changes.
final appProfileProvider =
    AsyncNotifierProvider<AppProfileController, AppProfile?>(
      AppProfileController.new,
    );

class AppProfileController extends AsyncNotifier<AppProfile?> {
  @override
  Future<AppProfile?> build() async {
    final auth = ref.watch(authStateProvider);
    final uid = auth.asData?.value?.uid;
    if (uid == null) return null;
    return ref.read(profileRepositoryProvider).fetchMe();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid == null) return null;
      return ref.read(profileRepositoryProvider).fetchMe();
    });
  }

  Future<AppProfile> completeOnboarding({
    required String phone,
    String? displayName,
  }) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .completeOnboarding(phone: phone, displayName: displayName);
    state = AsyncData(profile);
    return profile;
  }

  Future<AppProfile> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .updateProfile(
          displayName: displayName,
          photoUrl: photoUrl,
          phone: phone,
        );
    state = AsyncData(profile);
    return profile;
  }
}
