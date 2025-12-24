import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Dialog shown after completing a challenge workout
/// Displays victory/attempt result with stats comparison
class ChallengeCompleteDialog extends StatelessWidget {
  final String challengerName;
  final String workoutName;
  final bool didBeat;
  final Map<String, dynamic> yourStats;
  final Map<String, dynamic> theirStats;
  final VoidCallback? onViewFeed; // Optional: Navigate to see the post
  final VoidCallback? onDismiss;

  const ChallengeCompleteDialog({
    super.key,
    required this.challengerName,
    required this.workoutName,
    required this.didBeat,
    required this.yourStats,
    required this.theirStats,
    this.onViewFeed,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(24),
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
            _buildHeader(context),

            // Stats comparison
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsComparison(context),
            ),

            const SizedBox(height: 20),

            // Share notification
            if (didBeat)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildShareNotification(context),
              ),

            const SizedBox(height: 20),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: didBeat
              ? [
                  const Color(0xFFFFD700).withValues(alpha: 0.3),
                  Colors.orange.withValues(alpha: 0.3),
                ]
              : [
                  AppColors.orange.withValues(alpha: 0.2),
                  AppColors.orange.withValues(alpha: 0.1),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            didBeat ? 'VICTORY!' : 'CHALLENGE ATTEMPTED',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: didBeat ? const Color(0xFFFFD700) : AppColors.orange,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Challenge description
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15),
              children: [
                TextSpan(
                  text: didBeat ? 'You beat ' : 'You challenged ',
                ),
                TextSpan(
                  text: '$challengerName\'s',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: workoutName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
                const TextSpan(text: '!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsComparison(BuildContext context) {
    final yourDuration = yourStats['duration_minutes'];
    final yourVolume = yourStats['total_volume'];
    final theirDuration = theirStats['duration_minutes'];
    final theirVolume = theirStats['total_volume'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: didBeat
            ? Colors.green.withValues(alpha: 0.1)
            : AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: didBeat
              ? Colors.green.withValues(alpha: 0.3)
              : AppColors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: didBeat ? Colors.green : AppColors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance Comparison',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: didBeat ? Colors.green : AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Duration
          if (yourDuration != null && theirDuration != null) ...[
            _buildStatRow(
              emoji: '⏱️',
              label: 'Time',
              yourValue: '$yourDuration min',
              theirValue: '$theirDuration min',
              youWon: didBeat && yourDuration <= theirDuration,
            ),
            const SizedBox(height: 12),
          ],

          // Volume
          if (yourVolume != null && theirVolume != null)
            _buildStatRow(
              emoji: '💪',
              label: 'Volume',
              yourValue: '${yourVolume.toStringAsFixed(0)} lbs',
              theirValue: '${theirVolume.toStringAsFixed(0)} lbs',
              youWon: didBeat && yourVolume >= theirVolume,
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String emoji,
    required String label,
    required String yourValue,
    required String theirValue,
    required bool youWon,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Your stat
                  Row(
                    children: [
                      Text(
                        'You: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        yourValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: youWon ? Colors.green : null,
                        ),
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
                        'Them: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        theirValue,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildShareNotification(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.share, size: 18, color: AppColors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your victory has been shared with your friends! 🎉',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // View in feed button (if victory)
        if (didBeat && onViewFeed != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onViewFeed?.call();
              },
              icon: const Icon(Icons.feed, size: 18),
              label: const Text(
                'View in Feed',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        if (didBeat && onViewFeed != null) const SizedBox(height: 10),

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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
