import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../paywall/paywall_page.dart';
import 'paper_reader_page.dart';

class PapersPage extends StatefulWidget {
  const PapersPage({super.key});

  @override
  State<PapersPage> createState() => _PapersPageState();
}

class _PapersPageState extends State<PapersPage> {
  bool loading = true;
  String? error;
  List<dynamic> papers = [];
  List<String> provinces = const [];
  List<String> gaokaoPapers = const [];
  String? province;
  String? gaokaoPaper;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = papers.isEmpty;
      error = null;
    });
    try {
      final qs = <String>[];
      if ((province ?? '').isNotEmpty) {
        qs.add('province=${Uri.encodeQueryComponent(province!)}');
      }
      if ((gaokaoPaper ?? '').isNotEmpty) {
        qs.add('gaokao_paper=${Uri.encodeQueryComponent(gaokaoPaper!)}');
      }
      final path = '/api/app/papers${qs.isEmpty ? '' : '?${qs.join('&')}'}';
      final data = await context.read<ApiClient>().get(path);
      papers = data['papers'] as List? ?? [];
      final filters = data['filters'] as Map<String, dynamic>? ?? {};
      provinces = (filters['provinces'] as List? ?? []).map((e) => '$e').toList();
      gaokaoPapers = (filters['gaokao_papers'] as List? ?? []).map((e) => '$e').toList();
    } on ApiException catch (e) {
      error = e.message;
      if (e.needsPay && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _subtitle(Map<String, dynamic> p) {
    final bits = [
      p['province'],
      p['gaokao_paper'],
      p['semester'],
      p['exam_type'],
    ].where((e) => (e ?? '').toString().trim().isNotEmpty).join(' · ');
    final count = p['question_count'] ?? 0;
    return bits.isEmpty ? '$count 题' : '$bits · $count 题';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('已入库试卷')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('province-filter-${provinces.length}-$province'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '省份',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    initialValue: province,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全部省份')),
                      ...provinces.map(
                        (p) => DropdownMenuItem(value: p, child: Text(p)),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => province = v);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('gaokao-filter-${gaokaoPapers.length}-$gaokaoPaper'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '全国卷',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    initialValue: gaokaoPaper,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全部试卷')),
                      ...gaokaoPapers.map(
                        (p) => DropdownMenuItem(value: p, child: Text(p)),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => gaokaoPaper = v);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!))
                    : papers.isEmpty
                        ? const Center(child: Text('没有符合条件的试卷'))
                        : ListView.builder(
                            itemCount: papers.length,
                            itemBuilder: (context, i) {
                              final p = papers[i] as Map<String, dynamic>;
                              return ListTile(
                                title: Text('${p['title'] ?? ''}'),
                                subtitle: Text(_subtitle(p)),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PaperReaderPage(
                                      paperId: '${p['id']}',
                                      title: '${p['title'] ?? '试卷'}',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
