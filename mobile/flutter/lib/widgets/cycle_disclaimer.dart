import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';

import '../l10n/generated/app_localizations.dart';
/// Reusable non-contraceptive / not-medical-advice safety disclaimer for the
/// cycle-tracking feature.
///
/// WHY THIS EXISTS — legal + safety (see the cycle plan's "Privacy & Safety"
/// section): the cycle tracker must NEVER be worded or perceived as a
/// contraceptive method. Doing so would make it an FDA-regulated medical
/// device. Every cycle prediction is a *statistical estimate*, not a clinical
/// fact, and the app gives no medical advice. This widget is the single,
/// consistent surface for that message so the copy never drifts between
/// screens.
///
/// It is intentionally placed under `lib/widgets/` (not `lib/screens/cycle/`)
/// so the Cycle screen — built by another agent — and the onboarding /
/// settings flows can all import the SAME widget. Do not fork the copy.
///
/// Two presentation variants:
///  * [CycleDisclaimer.banner] — a compact inline card for the Insights tab
///    and any always-visible context.
///  * [CycleDisclaimer.onboarding] — a slightly more prominent block with a
///    heading, used on the cycle-tracking setup step.
class CycleDisclaimer extends StatelessWidget {
  /// `banner` (compact, default) or `onboarding` (with heading).
  final _CycleDisclaimerVariant _variant;

  /// Optional override for the bottom margin; defaults to 0.
  final EdgeInsetsGeometry? margin;

  const CycleDisclaimer.banner({super.key, this.margin})
      : _variant = _CycleDisclaimerVariant.banner;

  const CycleDisclaimer.onboarding({super.key, this.margin})
      : _variant = _CycleDisclaimerVariant.onboarding;

  /// The canonical disclaimer sentence. Exposed as a constant so non-widget
  /// contexts (e.g. an AI-coach system prompt or a tooltip) can reuse the
  /// exact wording without duplicating it.
  static const String text =
      'Cycle predictions are estimates based on your logged history — '
      'they are not a birth-control method and not medical advice. '
      'For contraception or health concerns, talk to a clinician.';

  /// Shorter one-liner for tight spaces (e.g. a chart caption).
  static const String shortText =
      'Predictions are estimates, not birth control or medical advice.';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final bodyStyle = TextStyle(
      fontSize: 12,
      height: 1.45,
      color: textMuted,
    );

    Widget content;
    switch (_variant) {
      case _CycleDisclaimerVariant.banner:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: bodyStyle)),
          ],
        );
        break;
      case _CycleDisclaimerVariant.onboarding:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).cycleDisclaimerBeforeYouStart,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: bodyStyle),
          ],
        );
        break;
    }

    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: content,
    );
  }
}

enum _CycleDisclaimerVariant { banner, onboarding }
