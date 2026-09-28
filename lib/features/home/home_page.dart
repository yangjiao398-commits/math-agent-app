import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/session.dart';
import '../../ui/widgets.dart';
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
    final member = session.user?['membership'] as Map<String, dynamic>? ?? {};
    final entitled = session.entitled;
    final expiry = formatExpiry(member['expires_at']);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                const AppLogoMark(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('数理助理', style: Theme.of(context).textTheme.titleLarge),
                      const Text('高考数学题库 · 公式预览 · 答卷评分', style: TextStyle(color: AppTheme.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: entitled
                      ? const [Color(0xFF146C54), Color(0xFF0F7B5A)]
                      : const [Color(0xFF1A3260), Color(0xFF1F5FBF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entitled ? '会员有效' : '待开通',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                  const SizedBox(height: 12),
                  Text(
                    entitled ? '题库与训练已全部解锁' : '开通会员后可练习全部试卷',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entitled
                        ? (expiry.isEmpty ? '当前套餐：${member['plan'] ?? '会员'}' : '有效期至 $expiry')
                        : '试用结束后需付费开通，支持微信和支付宝。',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.86), height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('功能', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const _FeatureTile(
              icon: Icons.menu_book_rounded,
              color: AppTheme.accent,
              soft: AppTheme.accentSoft,
              title: '已入库试卷',
              subtitle: '按省份与全国卷筛选，公式与网页预览一致',
              page: const PapersPage(),
            ),
            const _FeatureTile(
              icon: Icons.document_scanner_outlined,
              color: const Color(0xFF0F7B5A),
              soft: AppTheme.successSoft,
              title: '答卷扫描',
              subtitle: '拍照识别答题卡，对照标准答案自动评分',
              page: const SheetScanPage(),
            ),
            const _FeatureTile(
              icon: Icons.hub_outlined,
              color: const Color(0xFF5B4BDB),
              soft: const Color(0xFFEEEBFF),
              title: '知识点专项训练',
              subtitle: '跨试卷选题，针对薄弱知识点加练',
              page: const PracticePage(),
            ),
            const _FeatureTile(
              icon: Icons.workspace_premium_outlined,
              color: AppTheme.gold,
              soft: AppTheme.goldSoft,
              title: '开通会员',
              subtitle: '微信支付 / 支付宝，时长从到期日顺延',
              page: const PaywallPage(),
            ),
            const _FeatureTile(
              icon: Icons.person_outline_rounded,
              color: AppTheme.ink,
              soft: const Color(0xFFEEF1F4),
              title: '我的',
              subtitle: '账号、会员状态与推送通道',
              page: const ProfilePage(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.muted, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}
