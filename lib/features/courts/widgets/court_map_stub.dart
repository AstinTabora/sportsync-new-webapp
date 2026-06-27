import 'package:flutter/material.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Non-web map renderer. Loads the same `maps/embed?pb=...` URL the web build
/// uses, but inside a [WebView]. Google's embed URL is public — no API key.
/// If a court has no `mapUrl`, falls back to a styled placeholder.
Widget buildCourtMap(Court court) {
  final url = court.mapUrl;
  if (url == null || url.isEmpty) return const _MapPlaceholder();
  return _CourtMapWebView(url: url);
}

class _CourtMapWebView extends StatefulWidget {
  const _CourtMapWebView({required this.url});

  final String url;

  @override
  State<_CourtMapWebView> createState() => _CourtMapWebViewState();
}

class _CourtMapWebViewState extends State<_CourtMapWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(_wrapInIframe(widget.url));
  }

  /// Google's `maps/embed?pb=...` URL refuses to render unless it's loaded
  /// inside an `<iframe>` (it serves "Google Maps Embed API must be used
  /// in an iframe" otherwise). Wrap the URL in a tiny HTML host page that
  /// embeds it as a child frame — mirrors what the web build does via
  /// HtmlElementView.
  static String _wrapInIframe(String mapUrl) {
    return '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<style>html,body{margin:0;padding:0;height:100%;background:transparent;}iframe{display:block;border:0;width:100%;height:100%;}</style>
</head>
<body>
<iframe src="$mapUrl" allowfullscreen="false" loading="lazy" referrerpolicy="no-referrer-when-downgrade"></iframe>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8EFE6), Color(0xFFD4E2D1)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.location_on, color: AppColors.primary, size: 32),
      ),
    );
  }
}
