import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A small ▲/▼ delta chip ("+12%", "-0.4 kg") used beneath a [BigStat].
///
/// The tint encodes good/bad rather than up/down: pass [positiveIsGood] =
/// false for metrics where a decrease is the win (e.g. body weight in a cut),
/// so "down" reads green. A magnitude at or below [neutralEpsilon] renders as
/// a muted "no change" pill — never a fabricated trend.
class StatDeltaChip extends StatelessWidget {
  /// Signed change. Sign drives the arrow; [positiveIsGood] drives the tint.
  final double value;

  /// Pre-formatted magnitude text, e.g. "12%", "0.4 kg", "3". Sign is added
  /// by the chip, so pass the absolute magnitude.
  final String magnitudeLabel;

  /// Optional flat-change label (defaults to "—").
  final String? flatLabel;

  final bool positiveIsGood;
  final double neutralEpsilon;
  final bool isDark;

  const StatDeltaChip({
    super.key,
    required this.value,
    required this.magnitudeLabel,
    required this.isDark,
    this.flatLabel,
    this.positiveIsGood = true,
    this.neutralEpsilon = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final isFlat = value.abs() <= neutralEpsilon;
    final isUp = value > 0;
    final isGood = isUp == positiveIsGood;

    final Color color = isFlat
        ? muted
        : (isGood ? AppColors.success : AppColors.error);
    final IconData icon = isFlat
        ? Icons.trending_flat
        : (isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);
    final String text = isFlat
        ? (flatLabel ?? '—')
        : '${isUp ? '+' : '-'}$magnitudeLabel';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
