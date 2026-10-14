import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';

/// Live / VOD YouTube player via system WebView.
///
/// Loads an HTML shell from our API (`/v1/content/youtube-embed/:id`) so the
/// document origin is a real HTTPS domain. Direct YouTube embeds from Android
/// WebViews often fail with error 153 (`EMBEDDER_IDENTITY_DENIED`).
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
    if (widget.autoPlay) {
      LiveYoutubePlayer.pauseAll();
    }
    LiveYoutubePlayer._registry.add(this);
    _initController();
  }

  Uri _embedPageUri(String videoId) {
    final base = AppConfig.development.apiBaseUrl;
    return Uri.parse('$base/v1/content/youtube-embed/$videoId').replace(
      queryParameters: {
        'autoplay': widget.autoPlay ? '1' : '0',
        'mute': '0',
        if (widget.loop) 'loop': '1',
        // Bust any intermediate caches while iterating on embed fixes.
        'v': '2',
      },
    );
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
      ..addJavaScriptChannel(
        'YtBridge',
        onMessageReceived: (message) {
          if (message.message == 'error' && mounted) {
            setState(() {
              _failed = true;
              _loading = false;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _failed = false;
              });
            }
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() => _loading = false);
            await _injectErrorWatcher();
          },
          onWebResourceError: (error) {
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
                host.contains('ytimg.com') ||
                host.contains('yaaro.online');
            if (!allowed) {
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

  Future<void> _loadVideo(String videoId) async {
    final controller = _controller;
    if (controller == null || videoId.isEmpty) return;
    setState(() {
      _failed = false;
      _loading = true;
    });
    await controller.loadRequest(_embedPageUri(videoId));
  }

  Future<void> _injectErrorWatcher() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript('''
        (function() {
          var tries = 0;
          var timer = setInterval(function() {
            tries++;
            var text = (document.body && document.body.innerText) || '';
            if (/unavailable|error 153|configuration error/i.test(text)) {
              clearInterval(timer);
              if (window.YtBridge) YtBridge.postMessage('error');
            }
            if (tries > 10) clearInterval(timer);
          }, 700);
        })();
      ''');
    } catch (_) {}
  }

  Future<void> pause() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript(
        'try { pauseYt(); } catch (e) {}',
      );
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
    // Don't pause here — ListView / route rebuilds call deactivate and would
    // stop Live Darshan mid-play. pauseAll() + lifecycle cover real leaves.
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

  Widget _buildWebView(WebViewController controller) {
    final gestures = <Factory<OneSequenceGestureRecognizer>>{
      Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
    };
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: platform,
          displayWithHybridComposition: true,
          gestureRecognizers: gestures,
        ),
      );
    }
    return WebViewWidget(
      controller: controller,
      gestureRecognizers: gestures,
    );
  }

  Widget _thumbnailFallback() {
    final thumb = 'https://i.ytimg.com/vi/${widget.videoId}/hqdefault.jpg';
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            thumb,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          Container(color: Colors.black54),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'In-app play block ho gaya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'YouTube app / browser mein kholen',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _openInYouTube,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play on YouTube'),
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
        ],
      ),
    );
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
              if (controller != null && !_failed) _buildWebView(controller),
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
              if (_failed) _thumbnailFallback(),
              if (widget.showLiveBadge)
                const Positioned(left: 10, top: 10, child: _LiveChip()),
              if (!_failed)
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
