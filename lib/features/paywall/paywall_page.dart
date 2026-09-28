import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';
import '../../ui/widgets.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool busy = false;
  String? error;
  String? orderId;
  Map<String, dynamic> pay = {};
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Map<String, dynamic> get _payConfig {
    final raw = context.read<SessionController>().remoteConfig?['pay'];
    return raw is Map<String, dynamic> ? raw : {};
  }

  String _scene(String channel) {
    if (kIsWeb) return 'qr';
    return channel == 'alipay' ? 'wap' : 'h5';
  }

  Future<void> _startPay(Map<String, dynamic> plan, String channel) async {
    _poll?.cancel();
    setState(() {
      busy = true;
      error = null;
      orderId = null;
      pay = {};
    });
    try {
      final api = context.read<ApiClient>();
      final data = await api.post('/api/app/orders', {
        'plan': plan['code'],
        'channel': channel,
        'scene': _scene(channel),
      });
      final order = data['order'] as Map<String, dynamic>? ?? {};
      final nextPay = order['pay'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(order['pay'] as Map)
          : <String, dynamic>{};
      final id = '${order['id'] ?? ''}';
      if (!mounted) return;
      setState(() {
        orderId = id;
        pay = nextPay;
      });
      final url = '${nextPay['pay_url'] ?? ''}';
      if (nextPay['mock'] != true && url.isNotEmpty && '${nextPay['qr_code'] ?? ''}'.isEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      if (nextPay['mock'] != true) {
        _startPolling(id);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _startPolling(String id) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkPaid(id));
  }

  Future<void> _checkPaid(String id) async {
    try {
      final api = context.read<ApiClient>();
      final data = await api.get('/api/app/orders/$id');
      if (!mounted) return;
      final order = data['order'] as Map<String, dynamic>? ?? {};
      if (order['status'] != 'paid') return;
      await _onPaid();
    } catch (_) {}
  }

  Future<void> _confirmMock() async {
    final id = orderId;
    if (id == null) return;
    setState(() => busy = true);
    final api = context.read<ApiClient>();
    try {
      await api.post('/api/app/orders/$id/mock-pay');
      await _onPaid();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _onPaid() async {
    _poll?.cancel();
    final session = context.read<SessionController>();
    await session.refreshMe();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('支付成功，会员已开通')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final member = session.user?['membership'] as Map<String, dynamic>? ?? {};
    final cfg = _payConfig;
    final plans = cfg['plans'] as List? ?? [];
    final mock = cfg['mock'] == true || cfg['provider'] == 'dev';
    final qr = '${pay['qr_code'] ?? ''}';
    final waiting = orderId != null && pay['mock'] != true;
    final entitled = member['entitled'] == true;
    final expiry = formatExpiry(member['expires_at']);
    return Scaffold(
      appBar: AppBar(title: const Text('开通会员')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          AppCard(
            color: entitled ? AppTheme.successSoft : AppTheme.accentSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(
                  label: entitled ? '会员有效' : '待开通',
                  tone: entitled ? ChipTone.ok : ChipTone.warn,
                ),
                const SizedBox(height: 10),
                Text(
                  entitled
                      ? '当前套餐 ${member['plan'] ?? '会员'}${expiry.isEmpty ? '' : '，至 $expiry'}'
                      : '选择套餐后用微信或支付宝支付，开通后即可使用全部题库。',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.45),
                ),
                const SizedBox(height: 6),
                Text(
                  mock
                      ? '当前为开发模拟支付，确认后立即开通。'
                      : '支付成功后会员时长从当前到期日顺延。',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(error!, style: const TextStyle(color: AppTheme.danger)),
            ),
          if (pay.isNotEmpty)
            AppCard(
              child: Column(
                children: [
                  Text(
                    pay['mock'] == true
                        ? '请确认完成${pay['channel'] == 'alipay' ? '支付宝' : '微信'}支付'
                        : '${pay['instruction'] ?? '请完成支付'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  if (qr.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    QrImageView(data: qr, size: 200),
                  ],
                  if (waiting) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('等待支付结果…'),
                  ],
                  if (pay['mock'] == true) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : _confirmMock,
                        child: const Text('确认支付'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ...plans.map((raw) {
            final p = raw as Map<String, dynamic>;
            final fen = p['price_fen'] as int? ?? 0;
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p['title']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                            const SizedBox(height: 4),
                            Text('${p['days']} 天', style: const TextStyle(color: AppTheme.muted)),
                          ],
                        ),
                      ),
                      Text(
                        '¥${(fen / 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: busy ? null : () => _startPay(p, 'wechat'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF07C160)),
                          child: const Text('微信支付'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: busy ? null : () => _startPay(p, 'alipay'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1677FF)),
                          child: const Text('支付宝'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
