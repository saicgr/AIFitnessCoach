import 'package:flutter/material.dart';
import 'onboarding_theme.dart';

/// Small contextual hint / "Recommended" banner used on optional quiz steps
/// (muscle focus, limitations, …). Reads the onboarding palette so it matches
/// the funnel's black + brand-orange identity. Material icon only (no emoji).
///
/// Part of the `onboarding_smart_defaults` Gravl-gap work: a soft nudge that
/// makes skipping an optional step read as a sound default rather than a blank
/// screen.
class OnboardingHintBanner extends StatelessWidget {
  const OnboardingHintBanner({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.badgeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.selectionAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: t.badgeText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: t.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
