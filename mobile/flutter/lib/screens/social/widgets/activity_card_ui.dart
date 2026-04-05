part of 'activity_card.dart';

/// UI builder methods extracted from _ActivityCardState
extension _ActivityCardStateUI on _ActivityCardState {

  Widget _buildActivityContent(BuildContext context) {
    switch (widget.activityType) {
      case 'workout_completed':
      case 'workout_shared':
        return _buildWorkoutContent(context);
      case 'achievement_earned':
        return _buildAchievementContent(context);
      case 'personal_record':
        return _buildPRContent(context);
      case 'weight_milestone':
        return _buildWeightMilestoneContent(context);
      case 'streak_milestone':
        return _buildStreakContent(context);
      case 'challenge_victory':
        return _buildChallengeVictoryContent(context);
      case 'challenge_completed':
        return _buildChallengeCompletedContent(context);
      case 'manual_post':
        return _buildManualPostContent(context);
      default:
        return _buildGenericContent(context);
    }
  }


  Widget _buildManualPostContent(BuildContext context) {
    final caption = widget.activityData['caption'] as String? ?? '';
    final flairs = (widget.activityData['flairs'] as List<dynamic>?)?.cast<String>() ?? [];
    final hasImage = widget.activityData['has_image'] as bool? ?? false;
    final imageUrl = widget.activityData['image_url'] as String?;
    final imageUrls = (widget.activityData['image_urls'] as List<dynamic>?)?.cast<String>();
    final hasVideo = widget.activityData['has_video'] as bool? ?? false;
    final videoUrl = widget.activityData['video_url'] as String?;
    final thumbnailUrl = widget.activityData['thumbnail_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Flair tags
        if (flairs.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: flairs.map((flair) {
              final color = _getFlairColor(flair);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getFlairIcon(flair), size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      _getFlairLabel(flair),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Caption text with hashtag rendering (F10)
        if (caption.isNotEmpty) _buildCaptionWithHashtags(caption, context),

        // Video if present (F2)
        if (hasVideo && videoUrl != null) ...[
          const SizedBox(height: 12),
          SocialVideoPlayer(
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
          ),
        ],

        // Multi-image carousel (F1) or single image
        if (!hasVideo && imageUrls != null && imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          _buildImageCarousel(context, imageUrls),
        ] else if (!hasVideo && hasImage && imageUrl != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }


  /// Build a multi-image carousel with page indicator (F1)
  Widget _buildImageCarousel(BuildContext context, List<String> imageUrls) {
    final pageController = PageController();
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: pageController,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: pageController,
          count: imageUrls.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Theme.of(context).colorScheme.primary,
            dotColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }


  /// Build caption text with tappable hashtags and @mentions
  Widget _buildCaptionWithHashtags(String text, BuildContext context) {
    final pattern = RegExp(r'(#\w+|@\w+)');
    final hasSpecialText = pattern.hasMatch(text);

    if (!hasSpecialText) {
      return Text(text, style: const TextStyle(fontSize: 15));
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final token = match.group(0)!;
      final isHashtag = token.startsWith('#');

      spans.add(TextSpan(
        text: token,
        style: TextStyle(
          color: isHashtag
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.tertiary,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (isHashtag) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HashtagFeedScreen(hashtagName: token.substring(1)),
                ),
              );
            } else {
              // @mention — navigate to friend profile
              _navigateToMentionedUser(context, token.substring(1));
            }
          },
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15, inherit: false),
        children: spans,
      ),
    );
  }


  Widget _buildWorkoutContent(BuildContext context) {
    final workoutName = widget.activityData['workout_name'] ?? 'a workout';
    final duration = widget.activityData['duration_minutes'] ?? 0;
    final exercises = widget.activityData['exercises_count'] ?? 0;
    final totalVolume = widget.activityData['total_volume'];

    final verb = widget.activityType == 'workout_shared' ? 'shared' : 'completed';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/shared-workout', extra: {
          'activityId': widget.activityId,
          'currentUserId': widget.currentUserId,
          'posterName': widget.userName,
          'posterAvatar': widget.userAvatar,
          'activityType': widget.activityType,
          'activityData': widget.activityData,
          'savedWorkoutsService': _savedWorkoutsService,
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display badges if available
          if (widget.badges != null && widget.badges!.isNotEmpty) ...[
            _buildBadges(context, widget.badges!),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(text: '$verb '),
                      TextSpan(
                        text: workoutName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStat(Icons.timer_outlined, '$duration min'),
              _buildStat(Icons.fitness_center_outlined, '$exercises exercises'),
              if (totalVolume != null)
                _buildStat(Icons.trending_up_outlined, '${totalVolume.toStringAsFixed(0)} lbs'),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildAchievementContent(BuildContext context) {
    final achievementName = widget.activityData['achievement_name'] ?? 'an achievement';
    final achievementIcon = widget.activityData['achievement_icon'] ?? '🏆';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withValues(alpha: 0.3),
                AppColors.pink.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              achievementIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'earned an achievement',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                achievementName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPRContent(BuildContext context) {
    final exercise = widget.activityData['exercise_name'] ?? 'an exercise';
    final value = widget.activityData['record_value'] ?? 0;
    final unit = widget.activityData['record_unit'] ?? '';

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          const TextSpan(text: 'set a new PR in '),
          TextSpan(
            text: exercise,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ': '),
          TextSpan(
            text: '$value $unit',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWeightMilestoneContent(BuildContext context) {
    final weightChange = widget.activityData['weight_change'] ?? 0;
    final direction = weightChange < 0 ? 'lost' : 'gained';

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: '$direction '),
          TextSpan(
            text: '${weightChange.abs()} lbs',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  Widget _buildStreakContent(BuildContext context) {
    final days = widget.activityData['streak_days'] ?? 0;

    return Row(
      children: [
        const Icon(
          Icons.local_fire_department,
          color: AppColors.orange,
          size: 24,
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'reached a '),
              TextSpan(
                text: '$days-day streak',
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
    );
  }


  Widget _buildChallengeVictoryContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workoutName = widget.activityData['workout_name'] ?? 'a workout';
    final challengerName = widget.activityData['challenger_name'] ?? 'someone';
    final yourDuration = widget.activityData['your_duration'];
    final yourVolume = widget.activityData['your_volume'];
    final theirDuration = widget.activityData['their_duration'];
    final theirVolume = widget.activityData['their_volume'];
    final timeDifference = widget.activityData['time_difference'];
    final volumeDifference = widget.activityData['volume_difference'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Victory header with trophy
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow.withValues(alpha: 0.4),
                    Colors.orange.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VICTORY!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(text: 'beat '),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Comparison stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Time comparison
              if (yourDuration != null && theirDuration != null) ...[
                _buildVictoryComparison(
                  emoji: '⏱️',
                  label: 'Time',
                  yourValue: '$yourDuration min',
                  theirValue: '$theirDuration min',
                  improvement: timeDifference != null && timeDifference > 0
                      ? '${timeDifference.abs()} min faster'
                      : null,
                ),
                const SizedBox(height: 8),
              ],

              // Volume comparison
              if (yourVolume != null && theirVolume != null)
                _buildVictoryComparison(
                  emoji: '💪',
                  label: 'Volume',
                  yourValue: '${yourVolume.toStringAsFixed(0)} lbs',
                  theirValue: '${theirVolume.toStringAsFixed(0)} lbs',
                  improvement: volumeDifference != null && volumeDifference > 0
                      ? '+${volumeDifference.toStringAsFixed(0)} lbs'
                      : null,
                ),
            ],
          ),
        ),

        // Mini leaderboard
        _ChallengeLeaderboard(activityId: widget.activityId),
      ],
    );
  }


  Widget _buildVictoryComparison({
    required String emoji,
    required String label,
    required String yourValue,
    required String theirValue,
    String? improvement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        yourValue,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Them',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        theirValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (improvement != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  improvement,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }


  Widget _buildChallengeCompletedContent(BuildContext context) {
    final workoutName = widget.activityData['workout_name'] ?? 'a workout';
    final challengerName = widget.activityData['challenger_name'] ?? 'someone';
    final yourDuration = widget.activityData['your_duration'];
    final yourVolume = widget.activityData['your_volume'];
    final theirDuration = widget.activityData['their_duration'];
    final theirVolume = widget.activityData['their_volume'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Challenge attempted header
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('💪', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHALLENGE ATTEMPTED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(text: 'challenged '),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Stats comparison
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keep training! Every attempt makes you stronger',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats
              if (yourDuration != null && theirDuration != null) ...[
                _buildChallengeStatRow('Time', '$yourDuration min', '$theirDuration min'),
                const SizedBox(height: 8),
              ],
              if (yourVolume != null && theirVolume != null)
                _buildChallengeStatRow('Volume', '${yourVolume.toStringAsFixed(0)} lbs', '${theirVolume.toStringAsFixed(0)} lbs'),
            ],
          ),
        ),

        // Mini leaderboard
        _ChallengeLeaderboard(activityId: widget.activityId),
      ],
    );
  }


  Widget _buildChallengeStatRow(String label, String yourValue, String targetValue) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'You: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    yourValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('|', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  Text(
                    'Target: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    targetValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }


  /// Build badge chips (TRENDING, HALL OF FAME, BEAST MODE, etc.)
  Widget _buildBadges(BuildContext context, List<Map<String, dynamic>> badges) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges.map((badge) {
        final type = badge['type'] as String;
        final label = badge['label'] as String;
        final colorStr = badge['color'] as String;

        // Map color strings to actual colors
        Color badgeColor;
        switch (colorStr.toLowerCase()) {
          case 'orange':
            badgeColor = AppColors.orange;
            break;
          case 'gold':
            badgeColor = const Color(0xFFFFD700);
            break;
          case 'red':
            badgeColor = AppColors.red;
            break;
          case 'purple':
            badgeColor = AppColors.purple;
            break;
          default:
            badgeColor = AppColors.cyan;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        );
      }).toList(),
    );
  }

}
