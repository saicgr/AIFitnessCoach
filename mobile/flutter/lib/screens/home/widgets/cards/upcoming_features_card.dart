import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/feature_request.dart';
import '../../../../data/providers/feature_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// Compact home screen card showing upcoming features (Robinhood-style)
/// Shows both voting features and planned releases
class UpcomingFeaturesCard extends ConsumerStatefulWidget {
  const UpcomingFeaturesCard({super.key});

  @override
  ConsumerState<UpcomingFeaturesCard> createState() =>
      _UpcomingFeaturesCardState();
}

class _UpcomingFeaturesCardState extends ConsumerState<UpcomingFeaturesCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featuresAsync = ref.watch(featuresProvider);
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return featuresAsync.when(
      loading: () => _buildDefaultCard(context, elevated, textColor, textMuted),
      error: (_, __) => _buildDefaultCard(context, elevated, textColor, textMuted),
      data: (features) {
        // Get features currently being voted on
        final votingFeatures = features
            .where((f) => f.isVoting)
            .toList()
          ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

        // Get planned features with countdown timers
        final plannedFeatures = features
            .where((f) => f.status == 'planned' && f.releaseDate != null)
            .take(2)
            .toList();

        // If no features at all, show the "Vote on features" card
        if (votingFeatures.isEmpty && plannedFeatures.isEmpty) {
          return _buildDefaultCard(context, elevated, textColor, textMuted);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: elevated,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.cyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/features'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - Robinhood style
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.how_to_vote_rounded,
                          color: AppColors.cyan,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What should we build?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Vote on upcoming features',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: textMuted,
                      ),
                    ],
                  ),

                  // Voting features section
                  if (votingFeatures.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...votingFeatures.take(3).map((feature) =>
                        _buildVotingFeatureRow(feature, isDark, textColor, textMuted)),
                  ],

                  // Planned features with countdown
                  if (plannedFeatures.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'COMING SOON',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...plannedFeatures.map((feature) =>
                        _buildCompactFeatureRow(feature, isDark)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Default card shown when no features are loaded
  Widget _buildDefaultCard(
    BuildContext context,
    Color elevated,
    Color textColor,
    Color textMuted,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: elevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.cyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/features'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  color: AppColors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What should we build next?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vote on features and suggest ideas',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a voting feature row with vote count
  Widget _buildVotingFeatureRow(
    FeatureRequest feature,
    bool isDark,
    Color textColor,
    Color textMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Vote indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: feature.userHasVoted
                  ? AppColors.cyan.withOpacity(0.15)
                  : textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  feature.userHasVoted
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  size: 12,
                  color: feature.userHasVoted ? AppColors.cyan : textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${feature.voteCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: feature.userHasVoted ? AppColors.cyan : textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Feature title
          Expanded(
            child: Text(
              feature.title,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFeatureRow(FeatureRequest feature, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Feature title
          Expanded(
            child: Text(
              feature.title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Countdown timer
          _buildMiniCountdown(feature),
        ],
      ),
    );
  }

  Widget _buildMiniCountdown(FeatureRequest feature) {
    // Robinhood-style mini countdown pill
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            feature.formattedCountdown,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
