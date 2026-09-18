import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';
import '../question/katex_html.dart';
import '../question/katex_webview.dart';
import 'share_pdf.dart';

class PaperReaderPage extends StatefulWidget {
  const PaperReaderPage({super.key, required this.paperId, required this.title});

  final String paperId;
  final String title;

  @override
  State<PaperReaderPage> createState() => _PaperReaderPageState();
}

class _PaperReaderPageState extends State<PaperReaderPage> {
  bool loading = true;
  bool sharing = false;
  String? error;
  List<dynamic> questions = [];
  String? cssUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = context.read<SessionController>();
      cssUrl = session.remoteConfig?['katex']?['css_url'] as String?;
      final data = await context.read<ApiClient>().get(
            '/api/app/papers/${widget.paperId}/preview',
          );
      questions = data['questions'] as List? ?? [];
      cssUrl = (data['katex']?['css_url'] as String?) ?? cssUrl;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _pdfFilename() {
    final cleaned = widget.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${cleaned.isEmpty ? '试卷' : cleaned}.pdf';
  }

  Future<void> _sharePdf(BuildContext buttonContext) async {
    if (sharing) return;
    setState(() => sharing = true);
    final api = context.read<ApiClient>();
    try {
      final bytes = await api.getBytes(
            '/api/app/papers/${widget.paperId}/pdf',
          );
      if (!mounted || !buttonContext.mounted) return;
      final box = buttonContext.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await sharePdfBytes(
        bytes: bytes,
        filename: _pdfFilename(),
        origin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败：$e')),
      );
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Material(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            Builder(
                              builder: (buttonContext) {
                                return FilledButton.icon(
                                  onPressed: sharing
                                      ? null
                                      : () => _sharePdf(buttonContext),
                                  icon: sharing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.share),
                                  label: Text(sharing ? '正在生成 PDF…' : '分享到微信'),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '仅题干转成 PDF，手机上可选微信发给好友。',
                                style: TextStyle(fontSize: 12, color: Color(0xFF5C6B7A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: KatexWebView(
                        html: paperQuestionsHtml(questions),
                        cssUrl: cssUrl,
                        expand: true,
                      ),
                    ),
                  ],
                ),
    );
  }
}
