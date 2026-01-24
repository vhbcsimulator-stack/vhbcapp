import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mobile/desktop embed using a YouTube iframe and minimal navigation blocking
/// so the player can bootstrap correctly.
Widget buildYouTubeEmbed(String videoId) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0xFF000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          final host = uri.host.toLowerCase();

          // Allow YouTube (any path) and its asset hosts so playback can proceed.
          final isAssetHost =
              host.contains('googlevideo.com') || host.contains('ytimg.com') || host.contains('ggpht.com');
          final isYouTubeHost = host.contains('youtube.com') || host.contains('youtube-nocookie.com');
          if (isAssetHost || isYouTubeHost) return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
      ),
    )
    // Keep the embed simple: a plain iframe with no extra restrictions or blocking.
    ..loadHtmlString('''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
            iframe { border: 0; width: 100%; height: 100%; }
          </style>
        </head>
        <body>
          <iframe
            src="https://www.youtube.com/embed/$videoId?rel=0&playsinline=1&modestbranding=1&controls=1&iv_load_policy=3&showinfo=0&fs=1&loop=1&playlist=$videoId&origin=https://www.youtube.com"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
            allowfullscreen>
          </iframe>
        </body>
      </html>
    ''');

  return WebViewWidget(controller: controller);
}
