import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/session.dart';

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

  Future<void> _sms() async {
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
      setState(() => busy = false);
    }
  }

  Future<void> _login() async {
    setState(() => busy = true);
    try {
      await context.read<SessionController>().login(
            phone.text.trim(),
            code.text.trim(),
          );
    } catch (e) {
      setState(() => hint = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              Text('数理助理', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('付费使用高考数学题库、知识点训练与公式预览。'),
              const SizedBox(height: 28),
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
              Row(
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : _sms,
                    child: const Text('获取验证码'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: busy ? null : _login,
                    child: const Text('登录'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(hint, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
