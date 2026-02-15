import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/services/haptic_service.dart';
import 'glass_sheet.dart';

/// Shows a bottom sheet asking the user whether they want comeback mode (reduced workout)
/// or a full workout after returning from a break.
///
/// Returns `true` if user wants a full workout (skip comeback),
/// `false` if user wants the reduced comeback workout,
/// `null` if dismissed without choosing.
Future<bool?> showComebackModeSheet(
  BuildContext context, {
  required int daysSinceLastWorkout,
}) {
  return showGlassSheet<bool>(
    context: context,
    builder: (sheetContext) => _ComebackModeSheet(
      daysSinceLastWorkout: daysSinceLastWorkout,
    ),
  );
}

class _ComebackModeSheet extends ConsumerWidget {
  final int daysSinceLastWorkout;

  const _ComebackModeSheet({required this.daysSinceLastWorkout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GlassSheet(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Welcome icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  size: 32,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                "You haven't worked out in $daysSinceLastWorkout days",
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Comeback mode reduces sets and intensity to help prevent injury after a break.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Ease back in button (primary)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticService.medium();
                    Navigator.pop(context, false); // false = don't skip comeback
                  },
                  icon: const Icon(Icons.trending_up, size: 20),
                  label: const Text(
                    'Ease me back in',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Full workout button (secondary)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticService.medium();
                    Navigator.pop(context, true); // true = skip comeback
                  },
                  icon: Icon(Icons.bolt, size: 20, color: accentColor),
                  label: Text(
                    "I'm ready for a full workout",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: accentColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: accentColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
