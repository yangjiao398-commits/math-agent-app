import 'package:flutter_test/flutter_test.dart';
import 'package:math_agent_app/features/question/katex_html.dart';

void main() {
  test('phone loads KaTeX from the reachable API instead of loopback', () {
    const serverCss = 'http://127.0.0.1:3010/vendor/katex/katex.min.css';
    final css = katexCssUrl(
      serverCss,
      apiBase: 'http://192.168.1.202:3010',
    );
    expect(css, 'http://192.168.1.202:3010/vendor/katex/katex.min.css');
  });

  test('rewrites loopback asset URLs inside question HTML', () {
    const html =
        '<img src="http://localhost:3010/files/fig.png"><span class="katex">x</span>';
    final out = rewriteLoopbackToApi(
      html,
      apiBase: 'http://192.168.1.202:3010',
    );
    expect(out, contains('http://192.168.1.202:3010/files/fig.png'));
    expect(out, contains('class="katex"'));
  });

  test('keeps a public KaTeX host unchanged', () {
    const css = 'https://cdn.math-agent.cn/vendor/katex/katex.min.css';
    expect(
      katexCssUrl(css, apiBase: 'http://192.168.1.202:3010'),
      css,
    );
  });
}
