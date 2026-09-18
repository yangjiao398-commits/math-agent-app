import 'package:flutter_test/flutter_test.dart';

import 'package:math_agent_app/core/cdn/image_url.dart';

void main() {
  test('rewrites supabase public objects onto OSS/CDN', () {
    final out = rewriteCdnUrl(
      'https://xxx.supabase.co/storage/v1/object/public/exam-assets/a.png',
      apiBase: 'http://127.0.0.1:3010',
      cdnBase: 'https://cdn.math-agent.cn',
    );
    expect(out, 'https://cdn.math-agent.cn/exam/exam-assets/a.png');
  });

  test('rewrites img tags inside KaTeX preview HTML', () {
    const html = '<span class="katex">x</span><img src="/files/j/a.png">';
    final out = rewriteHtmlImages(
      html,
      apiBase: 'http://127.0.0.1:3010',
      cdnBase: 'https://cdn.math-agent.cn',
    );
    expect(out.contains('class="katex"'), isTrue);
    expect(out.contains('https://cdn.math-agent.cn/files/j/a.png'), isTrue);
  });
}
