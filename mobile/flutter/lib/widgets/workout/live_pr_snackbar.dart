/// Live mid-set PR snackbar.
///
/// Lightweight, transient celebration — used while the user is mid-workout
/// (the heavy [showPRFullCelebration] sheet is reserved for end-of-workout
/// or 10%+ epic PRs). 3s auto-dismiss, tap-to-dismiss, haptic on show.
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../services/live_pr_detector.dart';

import '../../l10n/generated/app_localizations.dart';
/// Show the live PR snackbar.
///
/// [useKg] toggles the display unit; the underlying [PrDetectionResult] values
/// are always stored in kg per the codebase weight-unit-separation convention.
void showLivePrSnackBar(
  BuildContext context, {
  required PrDetectionResult result,
  required bool useKg,
}) {
  // Fire a heavy haptic so the user FEELS the PR even if they're not looking.
  HapticService.multiPrAchievement();

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  // Convert to the user's preferred unit just for display.
  final unitLabel = useKg ? 'kg' : 'lb';
  final displayedWeight = useKg
      ? result.weightKg
      : LivePrDetector.kgToLb(result.weightKg);
  final displayed1rm = useKg
      ? result.newEstimated1rmKg
      : LivePrDetector.kgToLb(result.newEstimated1rmKg);
  final displayedDelta = useKg
      ? result.improvementKg
      : LivePrDetector.kgToLb(result.improvementKg);

  // Round to nearest whole unit for snackbar readability — full precision
  // stays in the underlying result for analytics / history.
  final weightStr = displayedWeight.round();
  final oneRmStr = displayed1rm.round();
  final deltaStr = displayedDelta.round();

  // Dismiss anything already on screen so consecutive PRs don't stack weirdly.
  messenger.hideCurrentSnackBar();

  final snackBar = SnackBar(
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF1A1A1A),
    elevation: 8,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: const Color(0xFFFFD700).withOpacity(0.6),
        width: 1.5,
      ),
    ),
    content: GestureDetector(
      onTap: () => messenger.hideCurrentSnackBar(),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // Trophy icon with soft glow.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Text column.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).stackedBannerPanelNewPr,
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$weightStr$unitLabel×${result.reps}  →  $oneRmStr $unitLabel 1RM, '
                  '+$deltaStr $unitLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Subtle dismiss affordance.
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.close,
              color: AppColors.textSecondary.withOpacity(0.6),
              size: 18,
            ),
          ),
        ],
      ),
    ),
  );

  messenger.showSnackBar(snackBar);
}
