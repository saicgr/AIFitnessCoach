part of 'share_workout_sheet.dart';

/// Methods extracted from _ShareWorkoutSheetState
extension __ShareWorkoutSheetStateExt on _ShareWorkoutSheetState {

  Widget _buildTemplateCarousel() {
    final now = DateTime.now();
    final useKg = ref.watch(useKgForWorkoutProvider);
    final weightUnit = useKg ? 'kg' : 'lbs';
    // Convert volume to user's preferred unit
    final displayVolume = widget.totalVolumeKg != null && !useKg
        ? widget.totalVolumeKg! * 2.20462
        : widget.totalVolumeKg;

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _currentPage = index);
      },
      children: [
        // Stats Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[0],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(0),
                    child: StatsTemplate(
                      workoutName: widget.workoutName,
                      durationSeconds: widget.durationSeconds,
                      calories: widget.calories,
                      totalVolumeKg: displayVolume,
                      totalSets: widget.totalSets,
                      totalReps: widget.totalReps,
                      exercisesCount: widget.exercisesCount,
                      completedAt: now,
                      showWatermark: _showWatermark,
                      weightUnit: weightUnit,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // PRs Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[1],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(1),
                    child: PrsTemplate(
                      workoutName: widget.workoutName,
                      prsData: widget.newPRs ?? [],
                      achievementsData: widget.achievements,
                      completedAt: now,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Coach Review Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final aiSettings = ref.watch(aiSettingsProvider);
                    final coach = CoachPersona.findById(aiSettings.coachPersonaId)
                        ?? CoachPersona.defaultCoach;
                    return CapturableWidget(
                      captureKey: _captureKeys[2],
                      child: InstagramStoryWrapper(
                        backgroundGradient: _getGradientForTemplate(2),
                        child: CoachReviewTemplate(
                          workoutName: widget.workoutName,
                          durationSeconds: widget.durationSeconds,
                          calories: widget.calories,
                          totalVolumeKg: displayVolume,
                          exercisesCount: widget.exercisesCount,
                          totalSets: widget.totalSets,
                          totalReps: widget.totalReps,
                          coach: coach,
                          performanceRating: _calculatePerformanceRating(),
                          completedAt: now,
                          showWatermark: _showWatermark,
                          weightUnit: weightUnit,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Progress Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[3],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(3),
                    child: ProgressTemplate(
                      workoutName: widget.workoutName,
                      durationSeconds: widget.durationSeconds,
                      exercisesCount: widget.exercisesCount,
                      totalWorkouts: (widget.totalWorkouts ?? 0) > 0
                          ? widget.totalWorkouts
                          : 1, // At least 1 since they just finished
                      currentStreak: (widget.currentStreak ?? 0) > 0
                          ? widget.currentStreak
                          : 1, // At least 1 day
                      weeklyWorkouts: 1, // At least this session
                      totalVolumeLifted: displayVolume,
                      sessionVolume: displayVolume,
                      prsThisMonth: widget.newPRs?.length ?? 0,
                      completedAt: now,
                      showWatermark: _showWatermark,
                      weightUnit: weightUnit,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Photo Overlay Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[4],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(4),
                    child: PhotoOverlayTemplate(
                      workoutName: widget.workoutName,
                      durationSeconds: widget.durationSeconds,
                      calories: widget.calories,
                      totalVolumeKg: displayVolume,
                      exercisesCount: widget.exercisesCount,
                      userPhotoBytes: _userPhotoBytes,
                      completedAt: now,
                      showWatermark: _showWatermark,
                      weightUnit: weightUnit,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Motivational Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[5],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(5),
                    child: MotivationalTemplate(
                      workoutName: widget.workoutName,
                      currentStreak: widget.currentStreak,
                      totalWorkouts: widget.totalWorkouts ?? 1,
                      durationSeconds: widget.durationSeconds,
                      completedAt: now,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
