import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

import '../l10n/generated/app_localizations.dart';
/// Subtle single-line banner indicating AI-generated content is not medical advice.
/// Tappable - navigates to the medical disclaimer settings page.
class MedicalDisclaimerBanner extends StatelessWidget {
  const MedicalDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () => context.push('/settings/medical-disclaimer'),
      child: Padding(
        // Caption-weight footnote: the line must exist for compliance, but it
        // shouldn't cost a full text row of the composer's height (was 12sp
        // + 4px vertical, which read as its own UI band under the input).
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
        child: Text(
          AppLocalizations.of(context).medicalDisclaimerBannerAiGeneratedContentNot,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.2,
            color: mutedColor.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
