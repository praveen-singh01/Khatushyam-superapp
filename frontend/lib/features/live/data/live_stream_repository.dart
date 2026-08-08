import '../../../core/network/api_client.dart';
import '../domain/live_stream_state.dart';

abstract class LiveStreamRepository {
  Future<LiveStreamState> fetchLiveStream();
}

class ApiLiveStreamRepository implements LiveStreamRepository {
  ApiLiveStreamRepository(this._api);

  final ApiClient _api;

  @override
  Future<LiveStreamState> fetchLiveStream() async {
    final response = await _api.get<Map<String, dynamic>>('/v1/content/live');
    final data = response.data;
    if (data == null) return LiveStreamState.offline();
    return LiveStreamState.fromJson(data);
  }
}
