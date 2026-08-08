import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/live_stream_repository.dart';
import '../domain/live_stream_state.dart';

final liveStreamRepositoryProvider = Provider<LiveStreamRepository>((ref) {
  return ApiLiveStreamRepository(ref.watch(apiClientProvider));
});

final liveStreamProvider = FutureProvider.autoDispose<LiveStreamState>((
  ref,
) async {
  try {
    return await ref.watch(liveStreamRepositoryProvider).fetchLiveStream();
  } catch (error, stack) {
    // Offline / bad API_BASE_URL / cleartext blocked — empty state.
    // ignore: avoid_print
    print('liveStreamProvider failed: $error\n$stack');
    return LiveStreamState.offline();
  }
});
