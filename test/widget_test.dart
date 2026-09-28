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

  test('paper html shows exam masthead above question stems', () {
    final html = paperQuestionsHtml(
      [
        {'index': 1, 'stemHtml': '<p>已知集合</p>'},
      ],
      headerHtml:
          '<p>深圳实验学校高中部2023-2024学年度第一学期第二阶段考试</p><p>高一数学</p><p>时间：120分钟 满分：150分</p>',
    );
    expect(html.contains('paper-masthead'), isTrue);
    expect(html.contains('深圳实验学校高中部'), isTrue);
    expect(html.contains('时间：120分钟'), isTrue);
    expect(
      html.indexOf('深圳实验学校高中部') < html.indexOf('已知集合'),
      isTrue,
    );
  });

  test('paper html groups stems under type section banners', () {
    final html = paperQuestionsHtml(
      [
        {'index': 1, 'stemHtml': '<p>单选题干</p>', 'type_code': 'single_choice'},
        {'index': 2, 'stemHtml': '<p>多选题干</p>', 'type_code': 'multi_choice'},
      ],
      sections: [
        {
          'title': '一、单项选择题：本题共1小题，每小题5分，共5分.',
          'titleHtml': '<p>一、单项选择题：本题共1小题，每小题5分，共5分.</p>',
          'questionIndexes': [1],
        },
        {
          'title': '二、多项选择题：本题共1小题，每小题5分，共5分.',
          'titleHtml': '<p>二、多项选择题：本题共1小题，每小题5分，共5分.</p>',
          'questionIndexes': [2],
        },
      ],
    );
    expect(html.contains('paper-section'), isTrue);
    expect(html.contains('一、单项选择题'), isTrue);
    expect(html.contains('二、多项选择题'), isTrue);
    expect(html.indexOf('一、单项选择题') < html.indexOf('单选题干'), isTrue);
    expect(html.indexOf('单选题干') < html.indexOf('二、多项选择题'), isTrue);
    expect(html.indexOf('二、多项选择题') < html.indexOf('多选题干'), isTrue);
  });
}
