import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';
import '../paywall/paywall_page.dart';

class SheetScanPage extends StatefulWidget {
  const SheetScanPage({super.key});

  @override
  State<SheetScanPage> createState() => _SheetScanPageState();
}

class _SheetScanPageState extends State<SheetScanPage> {
  final picker = ImagePicker();
  bool loadingPapers = true;
  bool grading = false;
  String? error;
  String? ocrHint;
  List<dynamic> papers = [];
  String? paperId;
  final photos = <MultipartImage>[];
  Map<String, dynamic>? report;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      loadingPapers = true;
      error = null;
    });
    final api = context.read<ApiClient>();
    try {
      try {
        final status = await api.get('/api/app/ocr-status');
        final engines = status['engines'] as List? ?? [];
        ocrHint = engines.isEmpty
            ? '服务端尚未配置 OCR，请安装 rapidocr-onnxruntime 或配置视觉模型密钥。'
            : '识别引擎：${engines.join(" / ")}';
      } catch (_) {
        ocrHint = null;
      }
      final data = await api.get('/api/app/papers');
      papers = data['papers'] as List? ?? [];
      if (papers.isNotEmpty && paperId == null) {
        paperId = '${(papers.first as Map)['id']}';
      }
    } on ApiException catch (e) {
      error = e.message;
      if (e.needsPay && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loadingPapers = false);
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final files = <XFile>[];
      if (source == ImageSource.gallery) {
        files.addAll(
          await picker.pickMultiImage(imageQuality: 85, maxWidth: 1600),
        );
      } else {
        final one = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (one != null) files.add(one);
      }
      for (final file in files) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        final name = file.name.isNotEmpty ? file.name : 'sheet-${photos.length + 1}.jpg';
        final mime = (file.mimeType != null && file.mimeType!.contains('/'))
            ? file.mimeType!
            : 'image/jpeg';
        photos.add(MultipartImage(bytes: bytes, filename: name, mime: mime));
      }
      if (mounted) {
        setState(() {
          report = null;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '无法打开相机或相册：$e');
    }
  }

  Future<void> _grade() async {
    final id = paperId;
    if (id == null || id.isEmpty) {
      setState(() => error = '请先选择试卷');
      return;
    }
    if (photos.isEmpty) {
      setState(() => error = '请先拍摄或选择答题卡照片');
      return;
    }
    setState(() {
      grading = true;
      error = null;
    });
    final api = context.read<ApiClient>();
    final name = '${context.read<SessionController>().user?['nickname'] ?? ''}';
    try {
      final data = await api.postMultipart(
        '/api/app/papers/$id/grade-sheet',
        fields: {'student_name': name},
        files: List<MultipartImage>.from(photos),
      );
      if (!mounted) return;
      setState(() => report = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
      if (e.needsPay) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => grading = false);
    }
  }

  Color _statusColor(String status, bool correct) {
    if (correct) return const Color(0xFF067647);
    if (status == 'needs_review') return const Color(0xFFB54708);
    if (status == 'missing') return const Color(0xFF667085);
    return const Color(0xFFB42318);
  }

  String _statusLabel(Map<String, dynamic> item) {
    if (item['is_correct'] == true) return '正确';
    final status = '${item['status'] ?? ''}';
    if (status == 'needs_review') return '待核对';
    if (status == 'missing') return '未识别';
    return '错误';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('答卷扫描')),
      body: loadingPapers
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('拍摄纸质答题卡，系统会 OCR 识别答案，并与所选试卷标准答案比对评分。'),
                if (ocrHint != null) ...[
                  const SizedBox(height: 8),
                  Text(ocrHint!, style: const TextStyle(color: Color(0xFF5C6B7A), fontSize: 13)),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Color(0xFFB42318))),
                ],
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '对应试卷',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: paperId,
                      hint: const Text('请选择试卷'),
                      items: papers.map((raw) {
                        final p = raw as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: '${p['id']}',
                          child: Text(
                            [
                              p['title'] ?? p['paper_code'] ?? '试卷',
                              p['province'],
                              p['gaokao_paper'],
                            ].where((e) => e != null && '$e'.trim().isNotEmpty).join(' · '),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: grading
                          ? null
                          : (v) => setState(() {
                                paperId = v;
                                report = null;
                              }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: grading ? null : () => _addPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('拍照'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: grading ? null : () => _addPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('相册'),
                      ),
                    ),
                  ],
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                photos[i].bytes,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: grading
                                    ? null
                                    : () => setState(() {
                                          photos.removeAt(i);
                                          report = null;
                                        }),
                                icon: const Icon(Icons.cancel, color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: grading ? null : _grade,
                  child: Text(grading ? '正在识别评分…' : '识别并评分'),
                ),
                if (grading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (report != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      title: Text(
                        '得分 ${report!['total_score']} / ${report!['max_score']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        '识别 ${report!['recognized_count']} 题 · 正确 ${report!['correct_count']} · '
                        '待核对 ${report!['needs_review_count']} · 未识别 ${report!['missing_count']}'
                        '${report!['ocr_engine'] != null && '${report!['ocr_engine']}'.isNotEmpty ? ' · 引擎 ${report!['ocr_engine']}' : ''}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(report!['items'] as List? ?? []).map((raw) {
                    final item = raw as Map<String, dynamic>;
                    final correct = item['is_correct'] == true;
                    final color = _statusColor('${item['status'] ?? ''}', correct);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          foregroundColor: color,
                          child: Text('${item['question_no']}'),
                        ),
                        title: Text('第 ${item['question_no']} 题 · ${item['type_label'] ?? ''}'),
                        subtitle: Text(
                          '作答：${item['student_answer'] == null || '${item['student_answer']}'.isEmpty ? '（空）' : item['student_answer']}\n'
                          '答案：${item['expected_answer'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          _statusLabel(item),
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
