import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/session.dart';
import '../papers/papers_page.dart';
import '../paywall/paywall_page.dart';
import '../practice/practice_page.dart';
import '../profile/profile_page.dart';
import '../scan/sheet_scan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Scaffold(
      appBar: AppBar(title: const Text('数理助理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            session.entitled ? '会员有效，可使用全部题库。' : '试用或会员到期后需付费开通。',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _tile(context, '已入库试卷', '按试卷练习，公式与现网 preview 一致', const PapersPage()),
          _tile(context, '答卷扫描', '拍照识别答题卡，对照标准答案自动评分', const SheetScanPage()),
          _tile(context, '知识点专项训练', '跨试卷选题训练', const PracticePage()),
          _tile(context, '开通会员', '微信支付 / 支付宝', const PaywallPage()),
          _tile(context, '我的', '登录态、推送通道、会员', const ProfilePage()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String subtitle, Widget page) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}
