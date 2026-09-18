/// Rewrite exam-bank image URLs onto the domestic OSS/CDN host.
///
/// Production: set CDN_BASE, e.g. https://cdn.math-agent.cn
/// The backend also rewrites stemHtml before it reaches the app.
String rewriteCdnUrl(String url, {required String apiBase, required String cdnBase}) {
  final raw = url.trim();
  if (raw.isEmpty || raw.startsWith('data:') || raw.startsWith('blob:')) {
    return raw;
  }
  if (cdnBase.isEmpty) return raw;
  final cdn = cdnBase.replaceAll(RegExp(r'/$'), '');
  var abs = raw;
  if (abs.startsWith('//')) abs = 'https:$abs';
  if (abs.startsWith('/')) abs = '$apiBase$abs';
  final uri = Uri.tryParse(abs);
  if (uri == null) return raw;
  var path = uri.path;
  const marker = '/storage/v1/object/public/';
  if (path.contains(marker)) {
    path = path.split(marker).last;
    return '$cdn/exam/${path.replaceFirst(RegExp(r'^/'), '')}';
  }
  return '$cdn$path';
}

String rewriteHtmlImages(String html, {required String apiBase, required String cdnBase}) {
  return html.replaceAllMapped(
    RegExp(r'''(<img\b[^>]*?\bsrc=["'])([^"']+)(["'])''', caseSensitive: false),
    (m) => '${m[1]}${rewriteCdnUrl(m[2]!, apiBase: apiBase, cdnBase: cdnBase)}${m[3]}',
  );
}
