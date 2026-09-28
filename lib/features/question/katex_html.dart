import '../../config/env.dart';
import '../../core/cdn/image_url.dart';

String katexCssUrl(String? cssUrl) {
  if (cssUrl != null && cssUrl.isNotEmpty) return cssUrl;
  return '${AppEnv.apiBase}/vendor/katex/katex.min.css';
}

String katexDocument({
  required String html,
  String? cssUrl,
  bool sizerScript = false,
  bool scrollable = false,
}) {
  final css = katexCssUrl(cssUrl);
  final body = rewriteHtmlImages(
    html,
    apiBase: AppEnv.apiBase,
    cdnBase: AppEnv.cdnBase,
  );
  final script = sizerScript
      ? '''
<script>
function report() {
  const el = document.getElementById('c');
  if (el && window.Sizer) Sizer.postMessage(String(el.scrollHeight));
}
window.addEventListener('load', report);
setTimeout(report, 80);
setTimeout(report, 320);
</script>
'''
      : '';
  final rootOverflow = scrollable
      ? 'html, body { height: 100%; overflow: auto; -webkit-overflow-scrolling: touch; }'
      : 'html, body { height: auto; overflow: hidden; }';
  final bodyPad = scrollable ? 'padding: 12px 12px 24px; box-sizing: border-box;' : '';
  return '''
<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
<link rel="stylesheet" href="$css"/>
<style>
  html, body { margin: 0; background: #F3EFE6; }
  $rootOverflow
  body {
    color: #1A2433;
    $bodyPad
    font-family: "Source Han Serif SC", "Noto Serif SC", "Songti SC", "PingFang SC", "Microsoft YaHei", serif;
  }
  .rich-content { line-height: 1.75; font-size: 16px; padding: 2px 0 8px; }
  .rich-content .katex { font-size: 1.05em; }
  .rich-content .katex-display { margin: 8px 0; overflow-x: auto; }
  .rich-content img {
    max-width: 100%; height: auto; display: inline-block;
    vertical-align: middle; border-radius: 8px; background: #fff; margin: 4px 0;
  }
  .rich-content table { border-collapse: collapse; width: 100%; margin: 8px 0; font-size: 15px; }
  .rich-content th, .rich-content td {
    border: 1px solid #E4DDD0; padding: 6px 8px; text-align: center;
  }
  .md-table-wrap { overflow-x: auto; }
  .q-card {
    background: #FFFCF7;
    border: 1px solid #E4DDD0;
    border-radius: 16px;
    padding: 14px 16px;
    margin: 0 0 12px;
  }
  .q-no { font-weight: 600; margin-bottom: 8px; }
  .paper-masthead {
    text-align: center;
    margin: 0 0 16px;
    line-height: 1.9;
    font-size: 16px;
  }
  .paper-masthead p { margin: 0.2em 0; }
  .paper-masthead img { max-width: 100%; max-height: 48px; height: auto; }
  .paper-section { margin: 0 0 16px; }
  .paper-section-title {
    font-weight: 700;
    margin: 0 0 10px;
    line-height: 1.75;
    font-size: 15px;
  }
  .paper-section-title p { margin: 0.15em 0; }
  .rich-content table, .md-table-wrap table {
    border-collapse: collapse;
    width: 100%;
    margin: 8px 0;
    font-size: 15px;
  }
  .rich-content th, .rich-content td {
    border: 1px solid #c5d0dc;
    padding: 6px 8px;
    text-align: center;
  }
  .q-block { margin-top: 12px; }
  .q-block h4 { margin: 0 0 6px; font-size: 14px; }
</style>
</head>
<body>
<div class="rich-content" id="c">$body</div>
$script
</body>
</html>
''';
}

String _scoreText(dynamic score) {
  if (score == null) return '';
  if (score is num) {
    final n = score.toDouble();
    final label = n == n.roundToDouble() ? '${n.toInt()}' : '$n';
    return '$label 分';
  }
  final raw = '$score'.trim();
  return raw.isEmpty ? '' : '$raw 分';
}

String _fallbackTypeLabel(String code) {
  switch (code) {
    case 'multi_choice':
      return '二、多项选择题';
    case 'fill_blank':
      return '三、填空题';
    case 'solution':
      return '四、解答题';
    case 'single_choice':
      return '一、单项选择题';
    default:
      return '';
  }
}

List<Map<String, dynamic>> _groupPaperQuestions(
  List<dynamic> questions, [
  List<dynamic>? sections,
]) {
  final byNo = <String, Map<String, dynamic>>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i] as Map<String, dynamic>;
    byNo['${q['index'] ?? i + 1}'] = {'q': q, 'i': i};
  }
  final used = <int>{};
  final groups = <Map<String, dynamic>>[];
  for (final raw in sections ?? const []) {
    if (raw is! Map) continue;
    final items = <Map<String, dynamic>>[];
    for (final number in (raw['questionIndexes'] as List?) ?? const []) {
      final hit = byNo['$number'];
      if (hit == null || used.contains(hit['i'] as int)) continue;
      used.add(hit['i'] as int);
      items.add(hit);
    }
    if (items.isEmpty) continue;
    groups.add({
      'title': '${raw['title'] ?? ''}',
      'titleHtml': '${raw['titleHtml'] ?? ''}',
      'items': items,
    });
  }
  final rest = <Map<String, dynamic>>[];
  for (var i = 0; i < questions.length; i++) {
    if (used.contains(i)) continue;
    rest.add({'q': questions[i] as Map<String, dynamic>, 'i': i});
  }
  if (rest.isEmpty) return groups;
  if (groups.isNotEmpty) {
    groups.add({'title': '', 'titleHtml': '', 'items': rest});
    return groups;
  }
  final buckets = <String, List<Map<String, dynamic>>>{};
  for (final hit in rest) {
    final code = '${(hit['q'] as Map<String, dynamic>)['type_code'] ?? ''}';
    buckets.putIfAbsent(code, () => []).add(hit);
  }
  for (final code in ['single_choice', 'multi_choice', 'fill_blank', 'solution']) {
    final items = buckets.remove(code);
    if (items == null || items.isEmpty) continue;
    groups.add({
      'title': _fallbackTypeLabel(code),
      'titleHtml': '',
      'items': items,
    });
  }
  buckets.forEach((code, items) {
    groups.add({
      'title': _fallbackTypeLabel(code),
      'titleHtml': '',
      'items': items,
    });
  });
  return groups;
}

String paperQuestionsHtml(
  List<dynamic> questions, {
  String? headerHtml,
  List<dynamic>? sections,
}) {
  final buf = StringBuffer();
  final header = (headerHtml ?? '').trim();
  if (header.isNotEmpty) {
    buf.write('<div class="paper-masthead">$header</div>');
  }
  if (questions.isEmpty) {
    if (header.isEmpty) return '<p>未能解析出题目。</p>';
    return buf.toString();
  }
  final groups = _groupPaperQuestions(questions, sections);
  for (final group in groups) {
    buf.write('<section class="paper-section">');
    final titleHtml = '${group['titleHtml'] ?? ''}'.trim();
    final title = '${group['title'] ?? ''}'.trim();
    if (titleHtml.isNotEmpty) {
      buf.write('<div class="paper-section-title">$titleHtml</div>');
    } else if (title.isNotEmpty) {
      buf.write('<div class="paper-section-title">$title</div>');
    }
    for (final hit in group['items'] as List) {
      final q = hit['q'] as Map<String, dynamic>;
      final i = hit['i'] as int;
      final index = q['index'] ?? i + 1;
      final score = _scoreText(q['score']);
      buf.write('<article class="q-card"><div class="q-no">第 $index 题');
      if (score.isNotEmpty) buf.write(' · $score');
      buf.write('</div>');
      buf.write(q['stemHtml'] ?? '');
      buf.write('</article>');
    }
    buf.write('</section>');
  }
  return buf.toString();
}
