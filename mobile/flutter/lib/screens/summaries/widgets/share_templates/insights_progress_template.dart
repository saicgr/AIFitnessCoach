import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: body + readiness + nutrition snapshot for the
/// selected insights period. Values are optional — empty rows are skipped
/// rather than showing "--" placeholders.
class InsightsProgressTemplate extends StatelessWidget {
  final String periodLabel;
  final String periodName;
  final String dateRangeLabel;
  final double? weightChangeKg;
  final String weightUnit; // "kg" or "lbs" depending on user preference
  final double? bodyFatChange;
  final double? avgReadiness; // 0-100
  final double? avgNutritionAdherence; // 0-100
  final int maxStreak;
  final bool showWatermark;

  const InsightsProgressTemplate({
    super.key,
    required this.periodLabel,
    required this.periodName,
    required this.dateRangeLabel,
    required this.maxStreak,
    this.weightChangeKg,
    this.weightUnit = 'kg',
    this.bodyFatChange,
    this.avgReadiness,
    this.avgNutritionAdherence,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (weightChangeKg != null) {
      final displayValue = weightUnit == 'lbs'
          ? (weightChangeKg! * 2.20462)
          : weightChangeKg!;
      rows.add(_MetricRow(
        icon: Icons.monitor_weight_rounded,
        label: 'WEIGHT',
        value: '${displayValue >= 0 ? '+' : ''}'
            '${displayValue.toStringAsFixed(1)} $weightUnit',
        color: const Color(0xFFE879F9),
        isPositive: weightChangeKg! < 0, // loss is "good" for most; neutral tag
        showDirection: true,
      ));
    }
    if (bodyFatChange != null) {
      rows.add(_MetricRow(
        icon: Icons.percent_rounded,
        label: 'BODY FAT',
        value: '${bodyFatChange! >= 0 ? '+' : ''}'
            '${bodyFatChange!.toStringAsFixed(1)}%',
        color: const Color(0xFFFB7185),
        isPositive: bodyFatChange! < 0,
        showDirection: true,
      ));
    }
    if (avgReadiness != null) {
      rows.add(_MetricRow(
        icon: Icons.bolt_rounded,
        label: 'READINESS',
        value: '${avgReadiness!.round()} / 100',
        color: const Color(0xFF60A5FA),
        showDirection: false,
      ));
    }
    if (avgNutritionAdherence != null) {
      rows.add(_MetricRow(
        icon: Icons.restaurant_rounded,
        label: 'NUTRITION',
        value: '${avgNutritionAdherence!.round()}%',
        color: const Color(0xFF34D399),
        showDirection: false,
      ));
    }
    rows.add(_MetricRow(
      icon: Icons.local_fire_department_rounded,
      label: 'MAX STREAK',
      value: '$maxStreak days',
      color: const Color(0xFFF97316),
      showDirection: false,
    ));

    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF180C2E),
            Color(0xFF2D1B4E),
            Color(0xFF180C2E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HaloPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE879F9).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        periodLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFF0ABFC),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateRangeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  periodName,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6,
                  ),
                ),
                const Text(
                  'BODY & RECOVERY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i < rows.length - 1) const SizedBox(height: 8),
                ],
                const Spacer(),
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  /// When true, [isPositive] drives the color of the value text (green/red).
  /// When false, the value is shown in white (neutral metric).
  final bool showDirection;
  final bool isPositive;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showDirection = false,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = showDirection
        ? (isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE879F9).withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.2),
        radius: size.width * 0.55,
      ));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
