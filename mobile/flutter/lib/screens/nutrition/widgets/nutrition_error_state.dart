import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

import '../../../l10n/generated/app_localizations.dart';
class NutritionErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const NutritionErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: errorColor.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).nutritionErrorStateUnableToLoadNutrition.toUpperCase(),
              style: ZType.disp(22, color: textPrimary, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).nutritionErrorStatePleaseCheckYourConnection,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            // Surface the ACTUAL error so the cause is visible on-device when
            // console logs aren't (release builds strip debugPrint). e.g. a
            // 401, a FormatException (parse), or a SocketException (offline).
            if (error.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.length > 240 ? '${error.substring(0, 240)}…' : error,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: textSecondary,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(AppLocalizations.of(context).workoutStateCardsTryAgain),
              style: FilledButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
