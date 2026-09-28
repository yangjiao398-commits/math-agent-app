import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../ui/widgets.dart';
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

  List<String> _chips(Map<String, dynamic> p) {
    return [
      p['province'],
      p['gaokao_paper'],
      p['semester'],
      p['exam_type'],
      p['question_count'] == null ? null : '${p['question_count']} 题',
    ].where((e) => (e ?? '').toString().trim().isNotEmpty).map((e) => '$e').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('已入库试卷')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey('province-filter-${provinces.length}-$province'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '省份',
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
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? EmptyHint(icon: Icons.error_outline, text: error!)
                    : papers.isEmpty
                        ? const EmptyHint(icon: Icons.menu_book_outlined, text: '没有符合条件的试卷')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: papers.length,
                            itemBuilder: (context, i) {
                              final p = papers[i] as Map<String, dynamic>;
                              final chips = _chips(p);
                              return AppCard(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PaperReaderPage(
                                      paperId: '${p['id']}',
                                      title: '${p['title'] ?? '试卷'}',
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p['title'] ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (chips.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: chips
                                            .map((c) => StatusChip(label: c, tone: ChipTone.accent))
                                            .toList(),
                                      ),
                                    ],
                                  ],
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
