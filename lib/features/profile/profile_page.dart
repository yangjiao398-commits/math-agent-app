import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/env.dart';
import '../../core/auth/session.dart';
import '../../core/push/push_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final member = session.user?['membership'] as Map<String, dynamic>? ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(title: const Text('手机号'), subtitle: Text('${session.user?['phone'] ?? ''}')),
          ListTile(
            title: const Text('会员'),
            subtitle: Text(
              member['entitled'] == true
                  ? '${member['plan']} · 至 ${member['expires_at']}'
                  : '未开通或已过期',
            ),
          ),
          ListTile(
            title: const Text('推送'),
            subtitle: Text(
              'iOS: APNs；Android: ${AppEnv.androidPush} + 华为/小米/OPPO/vivo',
            ),
          ),
          ListTile(
            title: const Text('注册本机推送令牌'),
            onTap: () async {
              try {
                await context.read<PushService>().registerIfPossible();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已尝试上报设备令牌（开发包可能为空）')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
          ),
          ListTile(
            title: const Text('退出登录'),
            onTap: () => session.signOut(),
          ),
        ],
      ),
    );
  }
}
