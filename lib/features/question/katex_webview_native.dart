import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'katex_html.dart';

/// Android / iOS: WebView + KaTeX CSS, matching word-math-md preview.
class KatexWebView extends StatefulWidget {
  const KatexWebView({
    super.key,
    required this.html,
    this.cssUrl,
    this.minHeight = 72,
    this.expand = false,
  });

  final String html;
  final String? cssUrl;
  final double minHeight;
  final bool expand;

  @override
  State<KatexWebView> createState() => _KatexWebViewState();
}

class _KatexWebViewState extends State<KatexWebView> {
  WebViewController? _controller;
  double _height = 80;

  @override
  void initState() {
    super.initState();
    _height = widget.minHeight;
    _controller = _createController();
  }

  @override
  void didUpdateWidget(KatexWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html ||
        oldWidget.cssUrl != widget.cssUrl ||
        oldWidget.expand != widget.expand) {
      _controller?.loadHtmlString(
        _document(),
        baseUrl: _baseUrl(),
      );
    }
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    if (!widget.expand) {
      controller.addJavaScriptChannel(
        'Sizer',
        onMessageReceived: (message) {
          final next = double.tryParse(message.message);
          if (next == null || !mounted) return;
          setState(() => _height = next.clamp(widget.minHeight, 20000));
        },
      );
    }
    controller.loadHtmlString(_document(), baseUrl: _baseUrl());
    return controller;
  }

  String _document() {
    return katexDocument(
      html: widget.html,
      cssUrl: widget.cssUrl,
      sizerScript: !widget.expand,
      scrollable: widget.expand,
    );
  }

  String _baseUrl() {
    final css = katexCssUrl(widget.cssUrl);
    return css.replaceFirst(RegExp(r'katex\.min\.css$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return SizedBox(height: widget.minHeight);
    }
    final view = WebViewWidget(controller: controller);
    if (widget.expand) {
      return SizedBox.expand(child: view);
    }
    return SizedBox(
      height: _height,
      child: view,
    );
  }
}
