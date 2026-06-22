import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';

/// Signature v2 single orange accent.
const Color _kSigAccent = Color(0xFFF97316);

/// "Built for how you train" — a strip of 4 NON-ATTRIBUTED benefit cards.
///
/// These are deliberately NOT testimonials: no names, no quotes, no ratings,
/// no fabricated social proof (Zealova has none yet, and fake proof is an App
/// Store 2.3.1 risk). Each card is a plain statement of what the product does
/// for the user, paired with a signature icon.
///
/// Styled to signature-v2: dark surface, 14px radius, a top hairline, a Barlow
/// Condensed uppercase section kicker, single warm-orange accent.
class PaywallBenefitStrip extends StatelessWidget {
  final ThemeColors colors;

  const PaywallBenefitStrip({super.key, required this.colors});

  static const List<(IconData, String)> _benefits = [
    (Icons.female_rounded, 'Period-aware coaching that remembers'),
    (Icons.menu_book_rounded, 'Scan & sort any menu'),
    (Icons.local_drink_rounded, 'Food, fasting & hydration in one place'),
    (Icons.self_improvement_rounded, 'Beginner-friendly easy workouts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUILT FOR HOW YOU TRAIN',
          style: TextStyle(
            fontFamily: 'Barlow Condensed',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: _kSigAccent,
          ),
        ),
        const SizedBox(height: 12),
        // 2x2 grid of benefit cards — even on narrow phones two-up reads
        // cleanly and keeps the strip compact.
        Row(
          children: [
            Expanded(child: _card(_benefits[0])),
            const SizedBox(width: 10),
            Expanded(child: _card(_benefits[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _card(_benefits[2])),
            const SizedBox(width: 10),
            Expanded(child: _card(_benefits[3])),
          ],
        ),
      ],
    );
  }

  Widget _card((IconData, String) benefit) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kSigAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(benefit.$1, size: 18, color: _kSigAccent),
          ),
          const Spacer(),
          Text(
            benefit.$2,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
