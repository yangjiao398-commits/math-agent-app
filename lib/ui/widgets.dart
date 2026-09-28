import 'package:flutter/material.dart';

import '../config/theme.dart';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B74D6), AppTheme.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        '数',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Card(
      color: color ?? AppTheme.surface,
      child: onTap == null
          ? body
          : InkWell(onTap: onTap, child: body),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = ChipTone.neutral});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      ChipTone.ok => (AppTheme.successSoft, AppTheme.success),
      ChipTone.warn => (AppTheme.goldSoft, AppTheme.gold),
      ChipTone.accent => (AppTheme.accentSoft, AppTheme.accent),
      ChipTone.neutral => (const Color(0xFFF1EDE4), AppTheme.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum ChipTone { ok, warn, accent, neutral }

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

String formatExpiry(dynamic raw) {
  final text = '${raw ?? ''}'.trim();
  if (text.isEmpty) return '';
  final dt = DateTime.tryParse(text);
  if (dt == null) return text;
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

String maskPhone(dynamic raw) {
  final phone = '${raw ?? ''}';
  if (phone.length < 7) return phone;
  return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
}
