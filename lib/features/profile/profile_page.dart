import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../core/auth/session.dart';
import '../../core/push/push_service.dart';
import '../../ui/widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final member = session.user?['membership'] as Map<String, dynamic>? ?? {};
    final entitled = member['entitled'] == true;
    final expiry = formatExpiry(member['expires_at']);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          AppCard(
            child: Row(
              children: [
                const AppLogoMark(size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maskPhone(session.user?['phone']),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      StatusChip(
                        label: entitled
                            ? '${member['plan'] ?? '会员'} · 至 ${expiry.isEmpty ? '—' : expiry}'
                            : '未开通或已过期',
                        tone: entitled ? ChipTone.ok : ChipTone.warn,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('推送通道'),
                  subtitle: Text(
                    'iOS: APNs；Android: ${AppEnv.androidPush} + 华为/小米/OPPO/vivo',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phonelink_setup_outlined),
                  title: const Text('注册本机推送令牌'),
                  trailing: const Icon(Icons.chevron_right_rounded),
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
              ],
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
              title: const Text('退出登录', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
              onTap: () => session.signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
