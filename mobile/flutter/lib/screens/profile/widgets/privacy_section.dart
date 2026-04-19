import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Compact Profile-screen entry point for privacy settings.
///
/// Renders as a single row matching the sibling "Reports & Insights" / "View
/// Stats" buttons below it (same padding, radius, typography, height). No
/// section header — with only one row, the adjacent "PRIVACY" caps header
/// was redundant against the row title itself. Taps push to the dedicated
/// settings page with all three toggles.
class PrivacySection extends ConsumerWidget {
  const PrivacySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return InkWell(
      onTap: () {
        HapticService.selection();
        context.push('/settings/leaderboard-privacy');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: accent, size: 20),
            const SizedBox(width: 10),
            Text(
              'Privacy',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
