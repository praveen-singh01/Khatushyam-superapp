import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';

/// YouTube Live player card used on Home and the Live Darshan screen.
///
/// `youtube_player_flutter`'s built-in `isLive: true` UI uses an unclamped
/// Slider that asserts when position > duration (common on live streams).
/// We play the live videoId with the standard player and a simple LIVE chip.
class LiveYoutubePlayer extends StatefulWidget {
  const LiveYoutubePlayer({
    super.key,
    required this.videoId,
    this.autoPlay = true,
  });

  final String videoId;
  final bool autoPlay;

  @override
  State<LiveYoutubePlayer> createState() => _LiveYoutubePlayerState();
}

class _LiveYoutubePlayerState extends State<LiveYoutubePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: false,
        enableCaption: false,
        // Keep false — package LiveBottomBar slider crashes on live HLS.
        isLive: false,
        forceHD: false,
        disableDragSeek: true,
        hideControls: false,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LiveYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.load(widget.videoId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: false,
                bottomActions: const [
                  SizedBox(width: 14),
                  _LiveChip(),
                  Spacer(),
                  FullScreenButton(),
                  SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
