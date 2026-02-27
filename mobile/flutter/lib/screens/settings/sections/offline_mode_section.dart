import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

/// The offline mode settings section.
///
/// Displays the offline mode feature card.
/// Full offline mode (workout generation, pre-cache, video downloads,
/// sync engine) is planned for a future release.
class OfflineModeSection extends ConsumerWidget {
  const OfflineModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: AppColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Offline Mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Work out without internet. On-device AI, pre-cached workouts, exercise video downloads, and background sync.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
