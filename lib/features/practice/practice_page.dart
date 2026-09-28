import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../ui/widgets.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(error!, style: const TextStyle(color: AppTheme.danger)),
                  ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择知识点', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('可多选，查找后预览公式题干。', style: TextStyle(color: AppTheme.muted)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: _search, child: const Text('查找题目'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: _preview, child: const Text('预览公式'))),
                  ],
                ),
                const SizedBox(height: 12),
                Text('已选 ${selected.length} 个知识点 · 命中 ${found.length} 题', style: const TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 8),
                ...preview.map((raw) {
                  final q = raw as Map<String, dynamic>;
                  return AppCard(
                    child: KatexWebView(
                      html: '${q['stemHtml'] ?? ''}',
                      cssUrl: cssUrl,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
