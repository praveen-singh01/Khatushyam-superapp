import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';

/// Live / VOD YouTube player via system WebView (not youtube_player_flutter).
///
/// Uses an official embed iframe with `baseUrl: https://www.youtube.com` so
/// YouTube gets a valid Referer — avoids "can't play in another app" / error 153
/// that the old IFrame API wrapper often hit on temple live streams.
class LiveYoutubePlayer extends StatefulWidget {
  const LiveYoutubePlayer({
    super.key,
    required this.videoId,
    this.autoPlay = true,
    this.showLiveBadge = true,
    this.loop = false,
  });

  final String videoId;
  final bool autoPlay;
  final bool showLiveBadge;
  final bool loop;

  /// Pause every mounted player (tab change / push to another screen).
  static void pauseAll() {
    for (final state in List<_LiveYoutubePlayerState>.from(_registry)) {
      state.pause();
    }
  }

  static final Set<_LiveYoutubePlayerState> _registry = {};

  @override
  State<LiveYoutubePlayer> createState() => _LiveYoutubePlayerState();
}

class _LiveYoutubePlayerState extends State<LiveYoutubePlayer>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  var _loading = true;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pause other players before registering this one.
    if (widget.autoPlay) {
      LiveYoutubePlayer.pauseAll();
    }
    LiveYoutubePlayer._registry.add(this);
    _initController();
  }

  void _initController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Ignore subresource noise; only surface main-frame failures.
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _failed = true;
                _loading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            final host = uri.host.toLowerCase();
            final allowed =
                host.isEmpty ||
                host.contains('youtube.com') ||
                host.contains('youtu.be') ||
                host.contains('youtube-nocookie.com') ||
                host.contains('google.com') ||
                host.contains('googlevideo.com') ||
                host.contains('gstatic.com') ||
                host.contains('ytimg.com');
            if (!allowed) {
              // External links (channel, ads) → open outside the in-app player.
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _loadVideo(widget.videoId);
  }

  String _embedHtml(String videoId) {
    final autoplay = widget.autoPlay ? '1' : '0';
    final loop = widget.loop ? '1' : '0';
    final loopParams =
        widget.loop ? '&loop=1&playlist=${Uri.encodeComponent(videoId)}' : '';
    final src =
        'https://www.youtube.com/embed/${Uri.encodeComponent(videoId)}'
        '?playsinline=1'
        '&rel=0'
        '&modestbranding=1'
        '&controls=1'
        '&fs=1'
        '&enablejsapi=1'
        '&origin=${Uri.encodeComponent('https://www.youtube.com')}'
        '&autoplay=$autoplay'
        '$loopParams';

    // baseUrl below must be youtube.com so Referer passes embed checks.
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
    iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe
    id="player"
    src="$src"
    title="YouTube"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
    allowfullscreen
    referrerpolicy="strict-origin-when-cross-origin"
    data-loop="$loop"
  ></iframe>
  <script>
    function pauseYt() {
      var iframe = document.getElementById('player');
      if (!iframe || !iframe.contentWindow) return;
      iframe.contentWindow.postMessage(
        JSON.stringify({ event: 'command', func: 'pauseVideo', args: [] }),
        '*'
      );
    }
  </script>
</body>
</html>
''';
  }

  Future<void> _loadVideo(String videoId) async {
    final controller = _controller;
    if (controller == null || videoId.isEmpty) return;
    setState(() {
      _failed = false;
      _loading = true;
    });
    await controller.loadHtmlString(
      _embedHtml(videoId),
      baseUrl: 'https://www.youtube.com/',
    );
  }

  Future<void> pause() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript('pauseYt();');
    } catch (_) {}
  }

  Future<void> _openInYouTube() async {
    final id = widget.videoId;
    final appUri = Uri.parse('vnd.youtube:$id');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$id');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  void didUpdateWidget(covariant LiveYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.loop != widget.loop) {
      _loadVideo(widget.videoId);
    }
  }

  @override
  void deactivate() {
    pause();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LiveYoutubePlayer._registry.remove(this);
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SoftCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && !_failed)
                WebViewWidget(
                  controller: controller,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<HorizontalDragGestureRecognizer>(
                      HorizontalDragGestureRecognizer.new,
                    ),
                    Factory<VerticalDragGestureRecognizer>(
                      VerticalDragGestureRecognizer.new,
                    ),
                    Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
                  },
                ),
              if (_loading && !_failed)
                const ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.orange,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              if (_failed)
                ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Video yahan play nahi ho paya',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _openInYouTube,
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('YouTube mein kholen'),
                          ),
                          TextButton(
                            onPressed: () => _loadVideo(widget.videoId),
                            child: const Text(
                              'Dobara try karein',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.showLiveBadge)
                const Positioned(left: 10, top: 10, child: _LiveChip()),
              Positioned(
                right: 8,
                bottom: 8,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _openInYouTube,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'YouTube',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
