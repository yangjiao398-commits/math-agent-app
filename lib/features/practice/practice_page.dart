import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../question/katex_webview.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  bool loading = true;
  String? error;
  List<dynamic> points = [];
  final selected = <String>{};
  List<dynamic> found = [];
  List<dynamic> preview = [];
  String? cssUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<ApiClient>().get('/api/app/knowledge-points');
      points = data['knowledge_points'] as List? ?? [];
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _search() async {
    setState(() => error = null);
    try {
      final data = await context.read<ApiClient>().post(
        '/api/app/questions-by-knowledge',
        {'codes': selected.toList(), 'match': 'any'},
      );
      found = data['questions'] as List? ?? [];
      setState(() {});
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _preview() async {
    final ids = found.map((q) => (q as Map)['id']).whereType<String>().take(20).toList();
    if (ids.isEmpty) return;
    try {
      final data = await context.read<ApiClient>().post(
        '/api/app/practice/preview',
        {'question_ids': ids},
      );
      preview = data['questions'] as List? ?? [];
      cssUrl = data['katex']?['css_url'] as String?;
      setState(() {});
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('知识点专项训练')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (error != null) Text(error!),
                Wrap(
                  spacing: 8,
                  children: points.take(40).map((raw) {
                    final p = raw as Map<String, dynamic>;
                    final code = '${p['code']}';
                    final on = selected.contains(code);
                    return FilterChip(
                      label: Text(code),
                      selected: on,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            selected.add(code);
                          } else {
                            selected.remove(code);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(onPressed: _search, child: const Text('查找题目')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _preview, child: const Text('预览公式')),
                  ],
                ),
                Text('命中 ${found.length} 题'),
                ...preview.map((raw) {
                  final q = raw as Map<String, dynamic>;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: KatexWebView(
                        html: '${q['stemHtml'] ?? ''}',
                        cssUrl: cssUrl,
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
