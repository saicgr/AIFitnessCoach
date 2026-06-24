import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Signature-v2 onPrimary ink — text/icon color on the solid orange accent.
const Color _onAccent = Color(0xFF160B03);

/// Dialog shown after completing a challenge workout
/// Displays victory/attempt result with stats comparison
class ChallengeCompleteDialog extends StatelessWidget {
  final String challengerName;
  final String workoutName;
  final bool didBeat;
  final Map<String, dynamic> yourStats;
  final Map<String, dynamic> theirStats;
  final String? challengeId;
  final VoidCallback? onViewFeed; // Optional: Navigate to see the post
  final VoidCallback? onViewDetails; // Navigate to compare screen
  final VoidCallback? onDismiss;

  const ChallengeCompleteDialog({
    super.key,
    required this.challengerName,
    required this.workoutName,
    required this.didBeat,
    required this.yourStats,
    required this.theirStats,
    this.challengeId,
    this.onViewFeed,
    this.onViewDetails,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with result
            _buildHeader(context, isDark),

            // Stats comparison
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsComparison(context, isDark),
            ),

            const SizedBox(height: 20),

            // Share notification
            if (didBeat)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildShareNotification(context, isDark),
              ),

            const SizedBox(height: 20),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildActions(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accent = didBeat ? const Color(0xFFFFD700) : orange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          // Trophy or strength emoji
          Text(
            didBeat ? '🏆' : '💪',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 12),

          // Victory or attempt message
          Text(
            (didBeat
                    ? AppLocalizations.of(context).challengeCompleteVictory
                    : AppLocalizations.of(context)
                        .challengeCompleteChallengeAttempted)
                .toUpperCase(),
            textAlign: TextAlign.center,
            style: ZType.disp(26, color: accent, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),

          // Challenge description
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: ZType.ser(15, color: textPrimary),
              children: [
                TextSpan(
                  text: didBeat ? 'You beat ' : 'You challenged ',
                ),
                TextSpan(
                  text: '$challengerName\'s',
                  style: ZType.ser(15,
                      color: textPrimary, weight: FontWeight.w600),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: workoutName,
                  style: ZType.ser(15, color: orange, weight: FontWeight.w600),
                ),
                const TextSpan(text: '!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsComparison(BuildContext context, bool isDark) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final yourDuration = yourStats['duration_minutes'];
    final yourVolume = yourStats['total_volume'];
    final theirDuration = theirStats['duration_minutes'];
    final theirVolume = theirStats['total_volume'];

    final accent = didBeat ? Colors.green : orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)
                .challengeCompletePerformanceComparison
                .toUpperCase(),
            style: ZType.lbl(12, color: accent, letterSpacing: 1.8),
          ),
          const SizedBox(height: 16),

          // Duration
          if (yourDuration != null && theirDuration != null) ...[
            _buildStatRow(
              context: context,
              isDark: isDark,
              emoji: '⏱️',
              label: AppLocalizations.of(context).challengeCompleteTime,
              yourLabel: AppLocalizations.of(context).challengeCompleteYou,
              themLabel: AppLocalizations.of(context).challengeCompleteThem,
              yourValue: AppLocalizations.of(context)
                  .challengeCompleteDialogMin(yourDuration),
              theirValue: AppLocalizations.of(context)
                  .challengeCompleteDialogMin2(theirDuration),
              youWon: didBeat && yourDuration <= theirDuration,
            ),
            const SizedBox(height: 14),
          ],

          // Volume
          if (yourVolume != null && theirVolume != null)
            _buildStatRow(
              context: context,
              isDark: isDark,
              emoji: '💪',
              label: AppLocalizations.of(context).challengeCompleteVolume,
              yourLabel: AppLocalizations.of(context).challengeCompleteYou,
              themLabel: AppLocalizations.of(context).challengeCompleteThem,
              yourValue: '${yourVolume.toStringAsFixed(0)} lbs',
              theirValue: AppLocalizations.of(context)
                  .challengeCompleteDialogLbs(theirVolume.toStringAsFixed(0)),
              youWon: didBeat && yourVolume >= theirVolume,
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required BuildContext context,
    required bool isDark,
    required String emoji,
    required String label,
    required String yourLabel,
    required String themLabel,
    required String yourValue,
    required String theirValue,
    required bool youWon,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Your stat
                  Row(
                    children: [
                      Text(
                        '$yourLabel ',
                        style: ZType.lbl(11,
                            color: textMuted, letterSpacing: 0.5),
                      ),
                      Text(
                        yourValue,
                        style: ZType.data(13.5,
                            color: youWon ? Colors.green : textPrimary),
                      ),
                      if (youWon) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),

                  // Their stat
                  Row(
                    children: [
                      Text(
                        '$themLabel ',
                        style: ZType.lbl(11,
                            color: textMuted, letterSpacing: 0.5),
                      ),
                      Text(
                        theirValue,
                        style: ZType.data(13.5, color: textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareNotification(BuildContext context, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.share, size: 18, color: cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).challengeCompleteYourVictoryHasBeen,
              style: ZType.sans(12,
                  color: textMuted, weight: FontWeight.w500, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return Column(
      children: [
        // View in feed button (if victory)
        if (didBeat && onViewFeed != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onViewFeed?.call();
              },
              icon: Icon(Icons.feed, size: 18, color: cyan),
              label: Text(
                AppLocalizations.of(context)
                    .challengeCompleteViewInFeed
                    .toUpperCase(),
                style: ZType.lbl(13, color: cyan, letterSpacing: 1.2),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cyan.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        if (didBeat && onViewFeed != null) const SizedBox(height: 10),

        // View full comparison button
        if (onViewDetails != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onViewDetails?.call();
              },
              icon: const Icon(Icons.compare_arrows_rounded,
                  size: 18, color: _onAccent),
              label: Text(
                AppLocalizations.of(context)
                    .challengeCompleteViewFullComparison
                    .toUpperCase(),
                style: ZType.lbl(13, color: _onAccent, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: _onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Continue button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)
                  .challengeCompleteContinue
                  .toUpperCase(),
              style: ZType.lbl(13, color: textPrimary, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
