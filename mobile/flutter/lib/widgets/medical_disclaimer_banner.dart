import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          'AI-generated content - not medical advice',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: mutedColor,
          ),
        ),
      ),
    );
  }
}
