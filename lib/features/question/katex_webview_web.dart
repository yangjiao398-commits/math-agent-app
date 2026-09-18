import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'katex_html.dart';

/// Chrome / Flutter web: iframe + KaTeX CSS. webview_flutter cannot
/// setJavaScriptMode on web.
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
  late final String _viewType;
  double _height = 120;
  web.HTMLIFrameElement? _iframe;
  Timer? _measureTimer;

  @override
  void initState() {
    super.initState();
    _height = widget.minHeight < 120 ? 120 : widget.minHeight;
    _viewType =
        'katex-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'transparent';
      if (widget.expand) {
        iframe.style.overflow = 'auto';
      } else {
        // Let the Flutter ListView receive wheel / drag, otherwise the iframe
        // swallows scroll and later questions cannot be reached.
        iframe.style
          ..overflow = 'hidden'
          ..pointerEvents = 'none';
      }
      iframe.onLoad.listen((_) => _scheduleMeasure(iframe));
      iframe.srcdoc = _document().toJS;
      _iframe = iframe;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(KatexWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html ||
        oldWidget.cssUrl != widget.cssUrl ||
        oldWidget.expand != widget.expand) {
      final iframe = _iframe;
      if (iframe != null) {
        iframe.srcdoc = _document().toJS;
      }
    }
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    super.dispose();
  }

  String _document() {
    return katexDocument(
      html: widget.html,
      cssUrl: widget.cssUrl,
      scrollable: widget.expand,
    );
  }

  void _scheduleMeasure(web.HTMLIFrameElement iframe) {
    if (widget.expand) return;
    _applyHeight(iframe);
    _measureTimer?.cancel();
    var ticks = 0;
    _measureTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      ticks += 1;
      _applyHeight(iframe);
      if (ticks >= 10) timer.cancel();
    });
  }

  void _applyHeight(web.HTMLIFrameElement iframe) {
    final doc = iframe.contentDocument;
    if (doc == null || !mounted) return;
    final content = doc.getElementById('c');
    final candidates = <num>[
      content?.scrollHeight ?? 0,
      doc.body?.scrollHeight ?? 0,
      doc.documentElement?.scrollHeight ?? 0,
    ];
    var h = 0.0;
    for (final n in candidates) {
      if (n > h) h = n.toDouble();
    }
    if (h <= 0) return;
    final next = h.clamp(widget.minHeight, 20000).toDouble();
    if ((next - _height).abs() < 1) return;
    setState(() => _height = next);
  }

  @override
  Widget build(BuildContext context) {
    final view = HtmlElementView(viewType: _viewType);
    if (widget.expand) {
      return SizedBox.expand(child: view);
    }
    return IgnorePointer(
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: view,
      ),
    );
  }
}
