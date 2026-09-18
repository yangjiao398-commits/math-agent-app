import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/session.dart';
import 'legal_copy.dart';
import 'legal_doc_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final code = TextEditingController();
  bool busy = false;
  String hint = '开发环境验证码为 888888';
  String? ageGroup;
  bool acceptMinor = false;
  bool acceptIp = false;
  bool guardianConsent = false;

  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _legal {
    final raw = context.read<SessionController>().remoteConfig?['legal'];
    return raw is Map<String, dynamic> ? raw : {};
  }

  String get _version => '${_legal['version'] ?? legalVersion}';

  String _docTitle(String id, String fallback) {
    final docs = _legal['documents'] as List? ?? [];
    for (final raw in docs) {
      final doc = raw as Map<String, dynamic>;
      if (doc['id'] == id) return '${doc['title'] ?? fallback}';
    }
    return fallback;
  }

  String _docBody(String id, String fallback) {
    final docs = _legal['documents'] as List? ?? [];
    for (final raw in docs) {
      final doc = raw as Map<String, dynamic>;
      if (doc['id'] == id) return '${doc['body'] ?? fallback}';
    }
    return fallback;
  }

  bool get _needsGuardian => ageGroup == 'teen' || ageGroup == 'child';

  bool get _accepted {
    if (ageGroup == null || ageGroup!.isEmpty || !acceptMinor || !acceptIp) return false;
    if (_needsGuardian && !guardianConsent) return false;
    return true;
  }

  void _openDoc(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocPage(title: title, body: body)),
    );
  }

  Future<void> _sms() async {
    if (!_accepted) {
      setState(() => hint = '请先选择年龄情况并同意全部必要条款');
      return;
    }
    setState(() => busy = true);
    try {
      final data = await context.read<SessionController>().sendSms(phone.text.trim());
      setState(() {
        hint = data['dev_code'] != null
            ? '验证码已生成：${data['dev_code']}'
            : '验证码已发送';
      });
    } catch (e) {
      setState(() => hint = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _login() async {
    if (!_accepted) {
      setState(() => hint = '请先选择年龄情况并同意全部必要条款');
      return;
    }
    setState(() => busy = true);
    try {
      await context.read<SessionController>().login(
            phone.text.trim(),
            code.text.trim(),
            ageGroup: ageGroup ?? '',
            acceptMinorTerms: acceptMinor,
            acceptIpTerms: acceptIp,
            guardianConsent: guardianConsent,
            termsVersion: _version,
          );
    } catch (e) {
      setState(() => hint = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minorTitle = _docTitle('minor', minorTermsTitle);
    final ipTitle = _docTitle('ip', ipTermsTitle);
    final minorBody = _docBody('minor', minorTermsBody);
    final ipBody = _docBody('ip', ipTermsBody);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Text('数理助理', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('付费使用高考数学题库、知识点训练与公式预览。注册前须阅读并同意未成年人保护及知识产权条款。'),
            const SizedBox(height: 24),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '手机号'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '短信验证码'),
            ),
            const SizedBox(height: 20),
            const Text('请选择年龄情况（必选）', style: TextStyle(fontWeight: FontWeight.w600)),
            RadioGroup<String>(
              groupValue: ageGroup,
              onChanged: (v) => setState(() => ageGroup = v),
              child: const Column(
                children: const [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('已满18周岁'),
                    value: 'adult',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('已满14周岁未满18周岁'),
                    value: 'teen',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('未满14周岁（须监护人代为注册）'),
                    value: 'child',
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: acceptMinor,
              onChanged: (v) => setState(() => acceptMinor = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: _linkLine('我已阅读并同意', minorTitle, () => _openDoc(minorTitle, minorBody)),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: acceptIp,
              onChanged: (v) => setState(() => acceptIp = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: _linkLine('我已阅读并同意', ipTitle, () => _openDoc(ipTitle, ipBody)),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: guardianConsent,
              onChanged: (v) => setState(() => guardianConsent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                _needsGuardian
                    ? '监护人已代为阅读并同意上述条款（未满18周岁必选）'
                    : '监护人已代为阅读并同意上述条款（未成年人使用时勾选）',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: busy || !_accepted ? null : _sms,
                  child: const Text('获取验证码'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: busy || !_accepted ? null : _login,
                  child: const Text('同意并注册/登录'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _linkLine(String prefix, String title, VoidCallback onTap) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('《$title》'),
        ),
      ],
    );
  }
}
