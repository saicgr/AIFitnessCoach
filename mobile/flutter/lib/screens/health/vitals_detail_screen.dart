import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/vitals_repository.dart';
import '../../widgets/glass_back_button.dart';
import '../pillar/widgets/ask_coach_button.dart';

/// Vitals detail screen — route `/health/vitals`.
///
/// Five overnight bio-signals (resting HR, HRV, respiratory rate, blood
/// oxygen, skin temperature) each scored against the user's own trailing
/// 28-day baseline. The hero is a row of per-signal "deviation capsules": a
/// shaded normal band (±1.5 SD) with a dot at last night's reading — inside
/// the band reads calm, outside flags an out-of-range signal. Honest per-signal
/// empty states when no wearable reading exists.
class VitalsDetailScreen extends ConsumerWidget {
  const VitalsDetailScreen({super.key});

  static const Color _danger = Color(0xFFF97316); // warm amber-orange

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final async = ref.watch(vitalsProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  const GlassBackButton(),
                  const SizedBox(width: 12),
                  Text('Vitals',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const Spacer(),
                  AskCoachButton(
                    contextLabel: 'Vitals · overnight signals',
                    statSnapshot: const {'pillar': 'vitals'},
                    source: 'vitals',
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => _Empty(
                    isDark: isDark,
                    text: 'Couldn\'t load your vitals. Pull to retry.'),
                data: (data) =>
                    _buildBody(context, ref, isDark, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, bool isDark, VitalsData data) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final card = isDark ? AppColors.surface : AppColorsLight.surface;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(vitalsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ── Hero: status headline + deviation capsules ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.outOfRangeCount > 0
                    ? [_danger.withValues(alpha: 0.16), card]
                    : [accent.withValues(alpha: 0.14), card],
              ),
              border: Border.all(
                  color: (data.outOfRangeCount > 0 ? _danger : accent)
                      .withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.hasAnyReading
                      ? (data.outOfRangeCount > 0
                          ? '${data.outOfRangeCount} out of range'
                          : 'All vitals in range')
                      : 'No overnight reading',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: data.outOfRangeCount > 0 ? _danger : textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: _VitalsBars(
                    signals: data.signals,
                    accent: accent,
                    danger: _danger,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Grounded coach read ──
          if (data.body.isNotEmpty)
            _InsightCard(
              headline: data.headline,
              body: data.body,
              accent: accent,
              card: card,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isFallback: data.delivery != 'gemini',
            ),
          const SizedBox(height: 14),

          // ── Per-signal rows ──
          ...data.signals.map((s) => _SignalRow(
                signal: s,
                card: card,
                accent: accent,
                danger: _danger,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              )),
        ],
      ),
    );
  }
}

/// The hero row of per-signal deviation capsules.
class _VitalsBars extends StatelessWidget {
  final List<VitalSignal> signals;
  final Color accent;
  final Color danger;
  final bool isDark;
  const _VitalsBars({
    required this.signals,
    required this.accent,
    required this.danger,
    required this.isDark,
  });

  IconData _icon(String key) {
    switch (key) {
      case 'resting_hr':
        return Icons.favorite_rounded;
      case 'hrv':
        return Icons.monitor_heart_rounded;
      case 'respiratory_rate':
        return Icons.air_rounded;
      case 'spo2':
        return Icons.bloodtype_rounded;
      case 'skin_temp':
        return Icons.thermostat_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: signals.map((s) {
        final color = s.state == 'out_of_range'
            ? danger
            : (s.state == 'no_data'
                ? (isDark ? Colors.white24 : Colors.black26)
                : accent);
        return Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _CapsulePainter(
                    z: s.z,
                    state: s.state,
                    color: color,
                    isDark: isDark,
                  ),
                  child: const SizedBox(width: double.infinity),
                ),
              ),
              const SizedBox(height: 8),
              Icon(_icon(s.key), size: 16, color: color),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// One vertical capsule: shaded normal band (±1.5 SD) + dot at the reading's z.
class _CapsulePainter extends CustomPainter {
  final double? z;
  final String state;
  final Color color;
  final bool isDark;
  const _CapsulePainter({
    required this.z,
    required this.state,
    required this.color,
    required this.isDark,
  });

  static const double _zRange = 3.0; // capsule spans z = [-3, +3]
  static const double _bandZ = 1.5; // normal band = ±1.5 SD

  @override
  void paint(Canvas canvas, Size size) {
    const capW = 16.0;
    final cx = size.width / 2;
    final rect = Rect.fromLTWH(cx - capW / 2, 0, capW, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Track.
    canvas.drawRRect(
      rrect,
      Paint()..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
    );

    double yForZ(double zz) =>
        size.height / 2 - (zz / _zRange).clamp(-1.0, 1.0) * (size.height / 2);

    // Normal band (±1.5 SD) — calm tint.
    if (state != 'no_data') {
      final bandTop = yForZ(_bandZ);
      final bandBot = yForZ(-_bandZ);
      final bandRect = Rect.fromLTRB(cx - capW / 2, bandTop, cx + capW / 2, bandBot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, const Radius.circular(8)),
        Paint()..color = color.withValues(alpha: 0.22),
      );
      // Baseline center line.
      canvas.drawLine(
        Offset(cx - capW / 2, size.height / 2),
        Offset(cx + capW / 2, size.height / 2),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1.5,
      );
    }

    // Dot at the latest reading.
    if (state != 'no_data' && z != null) {
      final dy = yForZ(z!);
      canvas.drawCircle(Offset(cx, dy), 7, Paint()..color = color);
      canvas.drawCircle(Offset(cx, dy), 3, Paint()..color = Colors.white);
    } else if (state == 'no_data') {
      // Dashed "no reading" hint at center.
      final p = Paint()
        ..color = color
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx - 4, size.height / 2),
          Offset(cx + 4, size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(covariant _CapsulePainter old) =>
      old.z != z || old.state != state || old.color != color;
}

class _SignalRow extends StatelessWidget {
  final VitalSignal signal;
  final Color card;
  final Color accent;
  final Color danger;
  final Color textPrimary;
  final Color textSecondary;
  const _SignalRow({
    required this.signal,
    required this.card,
    required this.accent,
    required this.danger,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = signal.state == 'out_of_range';
    final noData = signal.state == 'no_data';
    final pillColor = isOut ? danger : accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 2),
                Text(
                  noData
                      ? 'Needs a compatible wearable'
                      : (signal.baseline != null
                          ? 'Baseline ${_fmt(signal.baseline!)} ${signal.unit}'
                          : 'Building baseline'),
                  style: TextStyle(fontSize: 12.5, color: textSecondary),
                ),
              ],
            ),
          ),
          if (!noData && signal.value != null) ...[
            Text('${_fmt(signal.value!)} ',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary)),
            Text(signal.unit,
                style: TextStyle(fontSize: 12, color: textSecondary)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: pillColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOut ? 'High/Low' : 'In range',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: pillColor),
              ),
            ),
          ] else
            Icon(Icons.watch_rounded,
                size: 20, color: textSecondary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _InsightCard extends StatelessWidget {
  final String headline;
  final String body;
  final Color accent;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final bool isFallback;
  const _InsightCard({
    required this.headline,
    required this.body,
    required this.accent,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.isFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(headline,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 14, height: 1.4, color: textSecondary)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isDark;
  final String text;
  const _Empty({required this.isDark, required this.text});
  @override
  Widget build(BuildContext context) {
    final c = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text,
            textAlign: TextAlign.center, style: TextStyle(color: c)),
      ),
    );
  }
}
