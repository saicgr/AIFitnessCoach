part of 'workout_complete_screen.dart';

/// Methods extracted from _WorkoutCompleteScreenState
extension __WorkoutCompleteScreenStateExt2 on _WorkoutCompleteScreenState {

  Future<void> _handleSkipRating() async {
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Rating?'),
        content: const Text(
          'Ratings help our AI create better workouts. Skip anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (shouldSkip != true || !mounted) return;

    // Submit subjective feedback (mood/energy) if provided, even when skipping star rating
    if (_moodAfter != null && widget.workout.id != null) {
      try {
        debugPrint('📝 [Skip Rating] Submitting subjective feedback only: mood=$_moodAfter, energy=$_energyAfter');
        final notifier = ref.read(subjectiveFeedbackProvider.notifier);
        await notifier.createPostCheckin(
          workoutId: widget.workout.id!,
          moodAfter: _moodAfter!,
          energyAfter: _energyAfter,
          confidenceLevel: _confidenceLevel,
          feelingStronger: _feelingStronger,
        );
        debugPrint('✅ [Skip Rating] Subjective feedback submitted');
      } catch (e) {
        debugPrint('⚠️ [Skip Rating] Subjective feedback error (non-blocking): $e');
      }
    }

    // Refresh workouts silently and navigate home
    await ref.read(workoutsProvider.notifier).silentRefresh();

    if (mounted) {
      context.go('/home');
    }
  }


  /// Show detailed heart rate metrics in a bottom sheet
  void _showHeartRateMetricsSheet({
    required List<HeartRateReading> readings,
    required int maxHR,
    required int? restingHR,
    required int durationMinutes,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.read(accentColorProvider).getColor(isDark);

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
                children: [
                  GlassSheetHandle(isDark: isDark),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 20,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Heart Rate Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  // Scrollable content with all metrics
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: HeartRateWorkoutChart(
                        readings: readings,
                        avgBpm: widget.avgHeartRate,
                        maxBpm: widget.maxHeartRate,
                        minBpm: widget.minHeartRate,
                        maxHR: maxHR,
                        restingHR: restingHR,
                        durationMinutes: durationMinutes,
                        totalCalories: widget.calories,
                        showZoneBreakdown: true,
                        showTrainingEffect: true,
                        showVO2Max: restingHR != null,
                        showFatBurnMetrics: true,
                      ),
                    ),
                  ),
                ],
              ),
          ),
        ),
      );
  }


  /// Compact exercise feedback list for inline display
  Widget _buildCompactExerciseFeedback() {
    final exercises = widget.workout.exercises;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final rating = _exerciseRatings[index] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (starIdx) {
                  return GestureDetector(
                    onTap: () => setState(() => _exerciseRatings[index] = starIdx + 1),
                    child: Icon(
                      (starIdx + 1) <= rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: (starIdx + 1) <= rating ? AppColors.orange : AppColors.textMuted,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }


  /// Build the post-workout subjective feedback section
  /// Allows users to track mood, energy, and confidence after workout
  Widget _buildSubjectiveFeedbackSection() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cyan.withOpacity(0.1),
                AppColors.purple.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with expand/collapse toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showSubjectiveFeedback = !_showSubjectiveFeedback;
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.mood,
                          size: 20,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How do you feel now?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyan,
                              ),
                            ),
                            Text(
                              'Track your mood to see your progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showSubjectiveFeedback ? Icons.expand_less : Icons.expand_more,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content
              if (_showSubjectiveFeedback) ...[
                Divider(height: 1, color: cardBorder.withOpacity(0.5)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood after workout
                      Text(
                        'Mood',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final level = index + 1;
                          final isSelected = _moodAfter == level;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _moodAfter = level;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? level.moodColor.withOpacity(0.2)
                                    : elevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? level.moodColor : cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  level.moodEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (_moodAfter != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _moodAfter!.moodLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _moodAfter!.moodColor,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Energy after workout
                      Text(
                        'Energy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final level = index + 1;
                          final isSelected = _energyAfter == level;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _energyAfter = level;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.orange.withOpacity(0.2)
                                    : elevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.orange : cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  level.energyEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (_energyAfter != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _energyAfter!.energyLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Feeling stronger toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _feelingStronger = !_feelingStronger;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _feelingStronger
                                ? AppColors.success.withOpacity(0.15)
                                : elevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _feelingStronger
                                  ? AppColors.success
                                  : cardBorder,
                              width: _feelingStronger ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _feelingStronger
                                      ? AppColors.success
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _feelingStronger
                                        ? AppColors.success
                                        : textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: _feelingStronger
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Feeling stronger today!',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _feelingStronger
                                            ? AppColors.success
                                            : textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Notice improvements in your strength or endurance?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_feelingStronger)
                                const Text(
                                  '\u{1F4AA}',
                                  style: TextStyle(fontSize: 24),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 530.ms);
  }


  /// Build the per-exercise feedback section (expandable)
  Widget _buildExerciseFeedbackSection() {
    return Builder(
      builder: (context) {
        final isDarkFeedback = Theme.of(context).brightness == Brightness.dark;
        final elevatedFeedback = isDarkFeedback ? AppColors.elevated : AppColorsLight.elevated;
        final cardBorderFeedback = isDarkFeedback ? AppColors.cardBorder : AppColorsLight.cardBorder;
        final textSecondaryFeedback = isDarkFeedback ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final textPrimaryFeedback = isDarkFeedback ? AppColors.textPrimary : AppColorsLight.textPrimary;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: elevatedFeedback,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderFeedback),
          ),
          child: Column(
            children: [
              // Header with expand/collapse toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showExerciseFeedback = !_showExerciseFeedback;
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rate Individual Exercises',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orange,
                              ),
                            ),
                            Text(
                              _exerciseRatings.isEmpty
                                  ? 'Optional - helps AI adapt workouts'
                                  : '${_exerciseRatings.length} of ${widget.workout.exercises.length} rated',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondaryFeedback,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showExerciseFeedback ? Icons.expand_less : Icons.expand_more,
                        color: textSecondaryFeedback,
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content - exercise list
              if (_showExerciseFeedback) ...[
                Divider(height: 1, color: cardBorderFeedback),
                ...widget.workout.exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  final rating = _exerciseRatings[index] ?? 0;
                  final difficulty = _exerciseDifficulties[index] ?? 'just_right';

                  return _buildExerciseRatingTile(
                    index: index,
                    exerciseName: exercise.name,
                    rating: rating,
                    difficulty: difficulty,
                    textPrimary: textPrimaryFeedback,
                    textSecondary: textSecondaryFeedback,
                    cardBorder: cardBorderFeedback,
                  );
                }),
              ],
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 720.ms);
  }


  /// Build a single exercise rating tile
  Widget _buildExerciseRatingTile({
    required int index,
    required String exerciseName,
    required int rating,
    required String difficulty,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise name
              Text(
                exerciseName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Star rating row
              Row(
                children: [
                  // Stars
                  ...List.generate(5, (starIndex) {
                    final starValue = starIndex + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _exerciseRatings[index] = starValue;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          size: 24,
                          color: starValue <= rating
                              ? AppColors.orange
                              : textSecondary,
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Quick difficulty buttons
                  MiniDifficultyButton(
                    label: 'Easy',
                    isSelected: difficulty == 'too_easy',
                    color: AppColors.success,
                    onTap: () {
                      setState(() {
                        _exerciseDifficulties[index] = 'too_easy';
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  MiniDifficultyButton(
                    label: 'OK',
                    isSelected: difficulty == 'just_right',
                    color: AppColors.cyan,
                    onTap: () {
                      setState(() {
                        _exerciseDifficulties[index] = 'just_right';
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  MiniDifficultyButton(
                    label: 'Hard',
                    isSelected: difficulty == 'too_hard',
                    color: AppColors.error,
                    onTap: () {
                      setState(() {
                        _exerciseDifficulties[index] = 'too_hard';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (index < widget.workout.exercises.length - 1)
          Divider(height: 1, color: cardBorder),
      ],
    );
  }


  Widget _buildExerciseProgressSection() {
    return Builder(
      builder: (context) {
        final isDarkProgress = Theme.of(context).brightness == Brightness.dark;
        final elevatedProgress = isDarkProgress ? AppColors.elevated : AppColorsLight.elevated;
        final cardBorderProgress = isDarkProgress ? AppColors.cardBorder : AppColorsLight.cardBorder;
        final textSecondaryProgress = isDarkProgress ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: elevatedProgress,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderProgress),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with expand/collapse toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showExerciseProgress = !_showExerciseProgress;
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          size: 16,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Exercise Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                      Icon(
                        _showExerciseProgress ? Icons.expand_less : Icons.expand_more,
                        color: textSecondaryProgress,
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content
              if (_showExerciseProgress) ...[
                Divider(height: 1, color: cardBorderProgress),
                ...(_exerciseProgressData.entries.map((entry) => _buildExerciseProgressTile(
                  entry.key,
                  entry.value,
                ))),
              ],
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 600.ms);
  }


  Widget _buildExerciseProgressTile(String exerciseName, List<Map<String, dynamic>> history) {
    final isExpanded = _expandedExercises[exerciseName] ?? false;
    final maxWeight = history.fold<double>(0, (max, item) =>
      (item['weight_kg'] ?? 0.0).toDouble() > max ? (item['weight_kg'] ?? 0.0).toDouble() : max
    );

    return Builder(
      builder: (context) {
        final isDarkTile = Theme.of(context).brightness == Brightness.dark;
        final textPrimaryTile = isDarkTile ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondaryTile = isDarkTile ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final textMutedTile = isDarkTile ? AppColors.textMuted : AppColorsLight.textMuted;
        final cardBorderTile = isDarkTile ? AppColors.cardBorder : AppColorsLight.cardBorder;

        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedExercises[exerciseName] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textPrimaryTile,
                        ),
                      ),
                    ),
                    Text(
                      'PR: ${maxWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryTile,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: textMutedTile,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded && history.isNotEmpty) ...[
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSimpleProgressChart(history, maxWeight),
              ),
            ],
            Divider(height: 1, color: cardBorderTile),
          ],
        );
      },
    );
  }

}
