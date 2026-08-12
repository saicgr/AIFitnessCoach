import 'package:flutter/material.dart';
import '../../core/stats/state_valence.dart';

/// Callers must name a [GoodDirection] to build this chip, so it travels with
/// the widget rather than forcing a second import at every call site.
export '../../core/stats/state_valence.dart' show GoodDirection;

/// A small ▲/▼ delta chip ("+12%", "-0.4 kg") used beneath a [BigStat].
///
/// The tint is the semantic state ramp (supports/neutral/strains) and encodes
/// VALENCE, not direction: the caller declares the metric's [valence], so a
/// drop in resting HR reads "supports" while the same drop in steps reads
/// "strains". A magnitude at or below [neutralEpsilon] renders as a muted "no
/// change" pill — never a fabricated trend.
///
/// [valence] is required: there is no sane default for "which way is good",
/// and the old `positiveIsGood: true` default silently claimed higher-is-better
/// for every metric that forgot to pass it.
class StatDeltaChip extends StatelessWidget {
  /// Signed change. Sign drives the arrow; sign + [valence] drive the tint.
  final double value;

  /// Pre-formatted magnitude text, e.g. "12%", "0.4 kg", "3". Sign is added
  /// by the chip, so pass the absolute magnitude.
  final String magnitudeLabel;

  /// Optional flat-change label (defaults to "—").
  final String? flatLabel;

  /// Which way is good for this metric. `higher` → an increase supports the
  /// goal; `lower` → a decrease does; `neutral` → we don't judge (body weight,
  /// calories) and the chip stays muted.
  final GoodDirection valence;
  final double neutralEpsilon;
  final bool isDark;

  const StatDeltaChip({
    super.key,
    required this.value,
    required this.magnitudeLabel,
    required this.isDark,
    required this.valence,
    this.flatLabel,
    this.neutralEpsilon = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isFlat = value.abs() <= neutralEpsilon;
    final isUp = value > 0;

    final Color color = SemanticState.resolve(
      valence: valence,
      deviation: value,
      epsilon: neutralEpsilon,
    ).colorFor(isDark);
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
