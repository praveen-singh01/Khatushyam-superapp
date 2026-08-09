import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/legal_policies.dart';

final legalPoliciesProvider = FutureProvider<LegalPolicies>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/v1/legal/policies');
  return LegalPolicies.fromJson(response.data ?? const {});
});

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    await _api.patch<Map<String, dynamic>>(
      '/v1/auth/me',
      data: {
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );
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
