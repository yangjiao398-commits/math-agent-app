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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await context.read<ApiClient>().get('/api/app/papers');
      papers = data['papers'] as List? ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('已入库试卷')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView.builder(
                  itemCount: papers.length,
                  itemBuilder: (context, i) {
                    final p = papers[i] as Map<String, dynamic>;
                    return ListTile(
                      title: Text('${p['title'] ?? ''}'),
                      subtitle: Text(
                        '${p['semester'] ?? ''} ${p['exam_type'] ?? ''} · ${p['question_count'] ?? 0} 题',
                      ),
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
    );
  }
}
