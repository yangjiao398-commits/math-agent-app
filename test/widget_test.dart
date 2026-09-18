import 'package:flutter_test/flutter_test.dart';
import 'package:math_agent_app/core/cdn/image_url.dart';
import 'package:math_agent_app/features/question/katex_html.dart';

void main() {
  testWidgets('CDN helper keeps KaTeX markup', (tester) async {
    const html = '<span class="katex">a</span>';
    expect(
      rewriteHtmlImages(html, apiBase: 'http://x', cdnBase: ''),
      html,
    );
  });

  test('paper html concatenates stems so the reader can scroll one document', () {
    final html = paperQuestionsHtml([
      {'index': 1, 'stemHtml': '<p>第一题</p>', 'answerHtml': 'A'},
      {'index': 2, 'stemHtml': '<p>第二题</p>', 'analysisHtml': '解析'},
    ]);
    expect(html.contains('第 1 题'), isTrue);
    expect(html.contains('第 2 题'), isTrue);
    expect(html.contains('第一题'), isTrue);
    expect(html.contains('第二题'), isTrue);
    expect(html.contains('【答案】'), isFalse);
    expect(html.contains('【分析】'), isFalse);
    expect(html.contains('【详解】'), isFalse);
  });
}
