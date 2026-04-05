part of 'stats_welcome_screen.dart';


/// Custom widget for a filling progress dot
class _FillingDot extends StatelessWidget {
  final double size;
  final double fillProgress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isCurrent;

  const _FillingDot({
    required this.size,
    required this.fillProgress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FillingDotPainter(
        fillProgress: fillProgress,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        isCurrent: isCurrent,
      ),
    );
  }
}


/// Custom painter for the filling dot animation
class _FillingDotPainter extends CustomPainter {
  final double fillProgress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isCurrent;

  _FillingDotPainter({
    required this.fillProgress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw inactive background circle
    final bgPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    if (fillProgress > 0) {
      // Draw filled portion using clip
      final fillPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;

      // Save canvas state
      canvas.save();

      // Clip to circle
      final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.clipPath(circlePath);

      // Draw fill from left to right based on progress
      final fillWidth = size.width * fillProgress;
      final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
      canvas.drawRect(fillRect, fillPaint);

      // Restore canvas
      canvas.restore();

      // Add glow effect for active dots
      if (fillProgress > 0.1) {
        final glowPaint = Paint()
          ..color = activeColor.withOpacity(0.3 * fillProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(center, radius, glowPaint);
      }
    }

    // Add subtle pulse effect for current dot
    if (isCurrent && fillProgress > 0) {
      final pulsePaint = Paint()
        ..color = activeColor.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + 2, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(_FillingDotPainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.isCurrent != isCurrent;
  }
}


/// Compact tier card for the welcome screen 2x2 grid
class _CompactTierCard extends StatelessWidget {
  final String tierName;
  final String price;
  final String period;
  final String highlight;
  final Color accentColor;
  final bool isDark;
  final IconData icon;
  final bool isPopular;
  final VoidCallback? onInfoTap;

  const _CompactTierCard({
    required this.tierName,
    required this.price,
    required this.period,
    required this.highlight,
    required this.accentColor,
    required this.isDark,
    required this.icon,
    this.isPopular = false,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withOpacity(isPopular ? 0.4 : 0.2),
          width: isPopular ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier name with icon and optional badge
          Row(
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tierName,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '★',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ),
              if (onInfoTap != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onInfoTap,
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                period,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Highlight text
          Text(
            highlight,
            style: TextStyle(
              color: textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}


/// Feature comparison item for the summary row
class _FeatureComparisonItem extends StatelessWidget {
  final String label;
  final String free;
  final String paid;
  final bool isDark;

  const _FeatureComparisonItem({
    required this.label,
    required this.free,
    required this.paid,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              free,
              style: TextStyle(
                color: textSecondary,
                fontSize: 9,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_forward, size: 8, color: textSecondary),
            const SizedBox(width: 3),
            Text(
              paid,
              style: TextStyle(
                color: accentColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


/// Tier header cell for the features comparison bottom sheet
class _TierHeaderCell extends StatelessWidget {
  final String name;
  final Color color;
  final bool isDark;

  const _TierHeaderCell({
    required this.name,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


/// Feature row for the comparison table
class _FeatureRow extends StatelessWidget {
  final String feature;
  final List<String> values; // [Free, Premium, Plus, Lifetime]
  final bool isDark;
  final bool isNegative;

  const _FeatureRow({
    required this.feature,
    required this.values,
    required this.isDark,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final tierColors = [
      AppColors.teal,
      AppColors.cyan,
      AppColors.purple,
      const Color(0xFFFFB800),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          ...List.generate(values.length, (index) {
            final value = values[index];
            final isCheck = value == '✓';
            final isDash = value == '—';
            final isNo = value == 'No';
            final isYes = value == 'Yes' && isNegative;

            Color valueColor;
            if (isCheck) {
              valueColor = tierColors[index];
            } else if (isDash || (isYes && isNegative)) {
              valueColor = textSecondary.withOpacity(0.5);
            } else if (isNo && isNegative) {
              valueColor = tierColors[index];
            } else {
              valueColor = textSecondary;
            }

            return Expanded(
              flex: 2,
              child: Text(
                isCheck ? '✓' : value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 10,
                  fontWeight: isCheck || (isNo && isNegative) ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}


/// Price summary chip for bottom sheet footer
class _PriceSummaryChip extends StatelessWidget {
  final String price;
  final String label;
  final Color color;

  const _PriceSummaryChip({
    required this.price,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          price,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

