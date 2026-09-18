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
  html, body { margin: 0; background: transparent; }
  $rootOverflow
  body {
    color: #1c2430;
    $bodyPad
    font-family: "Source Han Serif SC", "Noto Serif SC", "Songti SC", "PingFang SC", serif;
  }
  .rich-content { line-height: 1.75; font-size: 16px; padding: 2px 0 8px; }
  .rich-content .katex { font-size: 1.05em; }
  .rich-content .katex-display { margin: 8px 0; overflow-x: auto; }
  .rich-content img {
    max-width: 100%; height: auto; display: inline-block;
    vertical-align: middle; border-radius: 6px; background: #fff; margin: 4px 0;
  }
  .q-card {
    background: #fff;
    border-radius: 12px;
    padding: 12px 14px;
    margin: 0 0 12px;
    box-shadow: 0 1px 2px rgba(28, 36, 48, 0.08);
  }
  .q-no { font-weight: 600; margin-bottom: 8px; }
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

String paperQuestionsHtml(List<dynamic> questions) {
  if (questions.isEmpty) {
    return '<p>未能解析出题目。</p>';
  }
  final buf = StringBuffer();
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i] as Map<String, dynamic>;
    final index = q['index'] ?? i + 1;
    buf.write('<article class="q-card"><div class="q-no">第 $index 题</div>');
    buf.write(q['stemHtml'] ?? '');
    buf.write('</article>');
  }
  return buf.toString();
}
