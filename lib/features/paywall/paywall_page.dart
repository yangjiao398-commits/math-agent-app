import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('开通会员')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            member['entitled'] == true
                ? '当前会员：${member['plan']}，至 ${member['expires_at']}'
                : '未开通或已过期，选择套餐后用微信或支付宝支付。',
          ),
          const SizedBox(height: 8),
          Text(
            mock
                ? '当前为开发模拟支付，确认后立即开通。上线请配置微信/支付宝商户号并将 APP_PAY_PROVIDER=live。'
                : '支付成功后会员时长从当前到期日顺延。',
            style: const TextStyle(color: Color(0xFF5C6B7A), fontSize: 13),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Color(0xFFB42318))),
          ],
          if (pay.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      pay['mock'] == true
                          ? '请确认完成${pay['channel'] == 'alipay' ? '支付宝' : '微信'}支付'
                          : '${pay['instruction'] ?? '请完成支付'}',
                    ),
                    if (qr.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      QrImageView(data: qr, size: 220),
                    ],
                    if (waiting) ...[
                      const SizedBox(height: 12),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('等待支付结果…'),
                    ],
                    if (pay['mock'] == true) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: busy ? null : _confirmMock,
                        child: const Text('确认支付'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...plans.map((raw) {
            final p = raw as Map<String, dynamic>;
            final fen = p['price_fen'] as int? ?? 0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${p['title']}'),
                      subtitle: Text('${p['days']} 天'),
                      trailing: Text('¥${(fen / 100).toStringAsFixed(0)}'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: busy ? null : () => _startPay(p, 'wechat'),
                            child: const Text('微信支付'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busy ? null : () => _startPay(p, 'alipay'),
                            child: const Text('支付宝'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
