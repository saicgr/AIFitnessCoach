part of 'workout_complete_screen.dart';

/// Methods extracted from _WorkoutCompleteScreenState
extension __WorkoutCompleteScreenStateExt1 on _WorkoutCompleteScreenState {

  void _extInitState() {
    debugPrint('🏁 [Complete] Workout complete screen loaded: ${widget.workout.id}');
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Track workout complete screen viewed
    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_complete_screen_viewed',
      properties: {
        'workout_id': widget.workout.id ?? '',
        'calories': widget.calories,
        'duration_seconds': widget.duration,
        'total_sets': widget.totalSets ?? 0,
        'has_prs': widget.personalRecords?.isNotEmpty == true,
      },
    );

    // Play workout completion sound
    Future.microtask(() {
      ref.read(soundPreferencesProvider.notifier).playWorkoutCompletion();
    });

    _loadAICoachFeedback();

    // Load total workout count for milestone detection
    _loadTotalWorkoutCount();

    // Use API-provided PRs if available (preferred as they're more accurate)
    if (widget.personalRecords != null && widget.personalRecords!.isNotEmpty) {
      _newPRs = widget.personalRecords!.map((pr) => {
        'exercise_name': pr.exerciseName,
        'weight_kg': pr.weightKg,
        'reps': pr.reps,
        'estimated_1rm_kg': pr.estimated1rmKg,
        'previous_pr': pr.previous1rmKg,
        'improvement_kg': pr.improvementKg,
        'improvement_percent': pr.improvementPercent,
        'celebration_message': pr.celebrationMessage,
        'is_all_time_pr': pr.isAllTimePr,
      }).toList();
      _isLoadingAchievements = false;

      // Award first-time PR bonus (+100 XP)
      ref.read(xpProvider.notifier).checkFirstPRBonus();

      // Show full-screen trophy celebration overlay
      Future.microtask(() {
        _showTrophyCelebration();
      });
      debugPrint('🏆 [Complete] Using ${_newPRs.length} PRs from API - showing celebration');
    } else {
      // Fall back to client-side detection
      _loadAchievements();
    }

    // Skip loading these for simplified single-screen layout
    // _loadExerciseProgress();
    // _loadProgressionSuggestions();
    _syncWorkoutWithGoals();
    _syncWorkoutToHealth();

    // Complete challenge if this workout was from a challenge
    if (widget.challengeId != null && widget.workoutLogId != null) {
      _completeChallenge();
    }
  }


  /// Show full-screen trophy celebration overlay
  void _showTrophyCelebration() {
    // Get new achievements from achievements map
    final newAchievements = (_achievements?['new_achievements'] as List?)
        ?.map((a) => Map<String, dynamic>.from(a as Map))
        .toList();

    // Check for milestone
    final milestone = _getWorkoutMilestone();

    // Get current streak
    final currentStreak = _achievements?['current_streak'] as int?;

    // Only show celebration if there are trophies to celebrate
    final hasTrophies = _newPRs.isNotEmpty ||
        (newAchievements != null && newAchievements.isNotEmpty) ||
        milestone != null;

    if (!hasTrophies || !mounted) return;

    debugPrint('🏆 [Complete] Showing trophy celebration: ${_newPRs.length} PRs, ${newAchievements?.length ?? 0} achievements, milestone: $milestone');

    // Play confetti on the underlying screen
    _confettiController.play();

    // Show full-screen celebration overlay
    showTrophyCelebration(
      context: context,
      newPRs: _newPRs,
      newAchievements: newAchievements,
      workoutMilestone: milestone,
      currentStreak: currentStreak,
    );
  }


  /// Complete challenge and show result dialog
  Future<void> _completeChallenge() async {
    try {
      final challengesService = ChallengesService(ref.read(apiClientProvider));
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      // Calculate challenged stats
      final challengedStats = {
        'duration_minutes': widget.duration,
        'total_volume': (widget.totalVolumeKg ?? 0) * 2.20462, // Convert to lbs
        'exercises_count': widget.exercisesPerformance?.length ?? 0,
        'total_sets': widget.totalSets ?? 0,
        'total_reps': widget.totalReps ?? 0,
        'exercises_performance': widget.exercisesPerformance,
      };

      debugPrint('🏆 [Challenge] Completing challenge ${widget.challengeId}');
      debugPrint('📊 [Challenge] Stats: $challengedStats');

      // Call complete challenge API
      final result = await challengesService.completeChallenge(
        userId: userId,
        challengeId: widget.challengeId!,
        workoutLogId: widget.workoutLogId!,
        challengedStats: challengedStats,
      );

      final didBeat = result['did_beat'] as bool? ?? false;
      final challengerName = widget.challengeData?['challenger_name'] ?? 'them';
      final workoutData = widget.challengeData?['workout_data'] as Map<String, dynamic>? ?? {};

      debugPrint(didBeat ? '🎉 [Challenge] VICTORY!' : '💪 [Challenge] Good attempt!');

      // Show challenge complete dialog after a short delay
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => ChallengeCompleteDialog(
                challengerName: challengerName,
                workoutName: widget.workout.name ?? 'Workout',
                didBeat: didBeat,
                yourStats: challengedStats,
                theirStats: workoutData,
                challengeId: widget.challengeId,
                onViewFeed: () {
                  // Navigate to social feed
                  if (mounted) {
                    context.go('/social');
                  }
                },
                onViewDetails: () {
                  // Navigate to challenge compare screen
                  if (mounted && widget.challengeId != null) {
                    context.push('/challenge-compare', extra: widget.challengeId);
                  }
                },
                onDismiss: () {
                  // Dialog dismissed
                },
              ),
            );

            // Trigger confetti if victory!
            if (didBeat) {
              _confettiController.play();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ [Challenge] Error completing challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing challenge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  /// Show Challenge Friends dialog
  Future<void> _showSaunaDialog() async {
    final result = await showSaunaDialog(context: context);
    if (result != null && mounted) {
      setState(() {
        _saunaMinutes = result.durationMinutes;
        _saunaCalories = result.estimatedCalories;
      });
      // Fire-and-forget: log to backend
      try {
        final apiClient = ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();
        if (userId != null) {
          final repo = ref.read(saunaRepositoryProvider);
          final log = await repo.logSauna(
            userId: userId,
            durationMinutes: result.durationMinutes,
            workoutId: widget.workout.id,
          );
          // Update with server-calculated calories (more accurate)
          if (mounted && log.estimatedCalories != null) {
            setState(() => _saunaCalories = log.estimatedCalories);
          }
        }
      } catch (e) {
        debugPrint('❌ [Sauna] Error logging: $e');
      }
    }
  }


  Future<void> _showChallengeFriendsDialog() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null || widget.workoutLogId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to challenge friends at this time'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Fetch friends list (mutual friends who follow each other)
      debugPrint('🔍 [Challenge] Fetching friends list...');
      final response = await apiClient.get(
        '/social/connections/friends/$userId',
      );

      // Backend returns list of UserProfile objects directly
      final friendsList = (response.data as List?) ?? [];
      final friends = friendsList.map((f) {
        return {
          'id': f['id'],
          'name': f['name'] ?? 'Unknown',
          'avatar_url': f['avatar_url'],
        };
      }).toList();

      if (friends.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You don\'t have any friends yet. Add some friends first!'),
              backgroundColor: AppColors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Prepare workout data for challenge
      final workoutData = {
        'duration_minutes': widget.duration,
        'total_volume': (widget.totalVolumeKg ?? 0) * 2.20462, // Convert to lbs
        'exercises_count': widget.exercisesPerformance?.length ?? 0,
        'total_sets': widget.totalSets ?? 0,
        'total_reps': widget.totalReps ?? 0,
      };

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ChallengeFriendsDialog(
            userId: userId,
            workoutLogId: widget.workoutLogId!,
            workoutName: widget.workout.name ?? 'Workout',
            workoutData: workoutData,
            friends: friends,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Challenge] Error showing challenge dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  Future<void> _loadAICoachFeedback() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      // Debug logging to track the AI Coach feedback flow
      debugPrint('🤖 [AI Coach] Starting feedback load...');
      debugPrint('🤖 [AI Coach] userId: $userId');
      debugPrint('🤖 [AI Coach] workoutLogId: ${widget.workoutLogId}');
      debugPrint('🤖 [AI Coach] workoutId: ${widget.workout.id}');
      debugPrint('🤖 [AI Coach] exercisesPerformance: ${widget.exercisesPerformance?.length ?? 0} exercises');
      debugPrint('🤖 [AI Coach] plannedExercises: ${widget.plannedExercises?.length ?? 0} exercises');
      debugPrint('🤖 [AI Coach] totalSets: ${widget.totalSets}, totalReps: ${widget.totalReps}');

      // Try to call AI Coach API if we have minimum required data (userId and workoutId)
      // workoutLogId is optional - we can still generate feedback without it
      if (userId != null && widget.workout.id != null) {
        // Build exercises list from workout exercises or provided performance data
        final exercisesList = widget.exercisesPerformance ??
            widget.workout.exercises.map((e) => {
              'name': e.name,
              'sets': e.sets ?? 3,
              'reps': e.reps ?? 10,
              'weight_kg': e.weight ?? 0.0,
            }).toList();

        // Build planned exercises list for skip detection (from widget or from workout definition)
        final plannedExercisesList = widget.plannedExercises ??
            widget.workout.exercises.map((e) => {
              'name': e.name,
              'target_sets': e.sets ?? 3,
              'target_reps': e.reps ?? 10,
              'target_weight_kg': e.weight ?? 0.0,
            }).toList();

        // Get AI settings for coach personality
        final aiSettings = ref.read(aiSettingsProvider);

        // Use actual workoutLogId if available, otherwise use a temp ID (won't be indexed)
        final effectiveWorkoutLogId = widget.workoutLogId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

        final feedback = await workoutRepo.getAICoachFeedback(
          workoutLogId: effectiveWorkoutLogId,
          workoutId: widget.workout.id!,
          userId: userId,
          workoutName: widget.workout.name ?? 'Workout',
          workoutType: widget.workout.type ?? 'strength',
          exercises: exercisesList,
          totalTimeSeconds: widget.duration,
          totalRestSeconds: widget.totalRestSeconds ?? 0,
          avgRestSeconds: widget.avgRestSeconds ?? 0.0,
          caloriesBurned: widget.calories,
          totalSets: widget.totalSets ?? 0, // Use actual value, don't fake it
          totalReps: widget.totalReps ?? 0, // Use actual value, don't fake it
          totalVolumeKg: widget.totalVolumeKg ?? 0.0,
          // Pass coach personality settings
          coachName: aiSettings.coachName,
          coachingStyle: aiSettings.coachingStyle,
          communicationTone: aiSettings.communicationTone,
          encouragementLevel: aiSettings.encouragementLevel,
          // Pass enhanced context for skip detection and timing
          plannedExercises: plannedExercisesList,
          exerciseTimeSeconds: widget.exerciseTimeSeconds,
          // Pass trophy/achievement context for personalized feedback
          earnedPRs: _newPRs.isNotEmpty ? _newPRs : null,
          earnedAchievements: (_achievements?['new_achievements'] as List?)
              ?.map((a) => Map<String, dynamic>.from(a as Map))
              .toList(),
          totalWorkoutsCompleted: _totalWorkoutCount > 0 ? _totalWorkoutCount : null,
          nextMilestone: _getNextMilestone(),
        );

        debugPrint('🤖 [AI Coach] API call completed, feedback: ${feedback != null ? "received (${feedback.length} chars)" : "null"}');
        if (feedback != null && mounted) {
          setState(() {
            _aiSummary = feedback;
            _isLoadingSummary = false;
          });
          return;
        } else {
          debugPrint('🤖 [AI Coach] API returned null feedback, using fallback');
        }
      } else {
        debugPrint('🤖 [AI Coach] Skipping API call - missing required data');
        debugPrint('🤖 [AI Coach] userId is null: ${userId == null}');
        debugPrint('🤖 [AI Coach] workoutId is null: ${widget.workout.id == null}');
        debugPrint('🤖 [AI Coach] workout.id value: "${widget.workout.id}"');
      }

      // Fallback to generated summary if API call fails
      debugPrint('🤖 [AI Coach] Using fallback summary');
      setState(() {
        _aiSummary = _generateFallbackSummary();
        _isLoadingSummary = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [AI Coach] Error loading feedback: $e');
      debugPrint('❌ [AI Coach] Stack trace: $stackTrace');
      setState(() {
        _aiSummary = _generateFallbackSummary();
        _isLoadingSummary = false;
      });
    }
  }


  Future<void> _loadAchievements() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        final achievements = await workoutRepo.getUserAchievements(userId: userId);

        if (achievements.isNotEmpty && mounted) {
          // Detect new PRs from this workout
          final newPRs = _detectNewPRs(achievements);

          setState(() {
            _achievements = achievements;
            _newPRs = newPRs;
            _isLoadingAchievements = false;
          });

          // Award first-time PR bonus (+100 XP) if PRs were detected
          if (newPRs.isNotEmpty) {
            ref.read(xpProvider.notifier).checkFirstPRBonus();
          }

          // Show full-screen trophy celebration if there are trophies
          Future.microtask(() {
            _showTrophyCelebration();
          });
          return;
        }
      }

      setState(() {
        _isLoadingAchievements = false;
      });
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      setState(() {
        _isLoadingAchievements = false;
      });
    }
  }


  Future<void> _loadExerciseProgress() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      final exercises = widget.exercisesPerformance ?? widget.workout.exercises.map((e) => {
        'name': e.name,
      }).toList();

      // Load progress for each exercise
      final progressData = <String, List<Map<String, dynamic>>>{};
      for (final ex in exercises.take(5)) {
        final exName = ex['name'] ?? ex['exercise_name'] ?? '';
        if (exName.isEmpty) continue;

        final history = await workoutRepo.getExerciseProgress(
          userId: userId,
          exerciseName: exName,
        );

        if (history.isNotEmpty) {
          progressData[exName] = history;
          _expandedExercises[exName] = false;
        }
      }

      if (mounted) {
        setState(() {
          _exerciseProgressData = progressData;
        });
      }
    } catch (e) {
      debugPrint('Error loading exercise progress: $e');
    }
  }


  /// Load progression suggestions for exercises the user has mastered
  Future<void> _loadProgressionSuggestions() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        setState(() => _isLoadingProgressions = false);
        return;
      }

      debugPrint('Loading progression suggestions for user: $userId');
      final suggestions = await workoutRepo.getProgressionSuggestions(userId: userId);

      if (mounted) {
        setState(() {
          _progressionSuggestions = suggestions;
          _isLoadingProgressions = false;
        });

        if (suggestions.isNotEmpty) {
          debugPrint('Found ${suggestions.length} progression suggestions');
        }
      }
    } catch (e) {
      debugPrint('Error loading progression suggestions: $e');
      if (mounted) {
        setState(() => _isLoadingProgressions = false);
      }
    }
  }


  /// Sync workout with personal weekly goals
  ///
  /// After workout completion, automatically updates any weekly_volume goals
  /// that match exercises from this workout.
  Future<void> _syncWorkoutWithGoals() async {
    // Only sync if we have exercise performance data
    if (widget.exercisesPerformance == null || widget.exercisesPerformance!.isEmpty) {
      debugPrint('[GoalSync] No exercise performance data, skipping goal sync');
      return;
    }

    setState(() => _isLoadingGoalSync = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        debugPrint('[GoalSync] No user ID, skipping goal sync');
        setState(() => _isLoadingGoalSync = false);
        return;
      }

      final goalsService = PersonalGoalsService(apiClient);

      // Convert exercise performance data to the format expected by the service
      final exercises = widget.exercisesPerformance!.map((ex) {
        final name = ex['name'] ?? ex['exercise_name'] ?? '';
        final sets = ex['sets_completed'] ?? ex['sets'] ?? 0;
        final reps = ex['reps'] ?? ex['total_reps'] ?? 0;

        // Calculate total reps: sets * reps (if reps is per set) or use total_reps directly
        int totalReps = 0;
        if (ex['total_reps'] != null) {
          totalReps = ex['total_reps'] as int;
        } else if (sets > 0 && reps > 0) {
          totalReps = (sets as int) * (reps as int);
        }

        return ExercisePerformanceData(
          exerciseName: name as String,
          totalReps: totalReps,
          totalSets: sets as int,
          maxRepsInSet: reps as int,
          maxWeightKg: ex['weight_kg'] != null ? (ex['weight_kg'] as num).toDouble() : null,
        );
      }).toList();

      debugPrint('[GoalSync] Syncing ${exercises.length} exercises with goals');

      final result = await goalsService.syncWorkoutWithGoals(
        userId: userId,
        workoutLogId: widget.workoutLogId,
        exercises: exercises,
      );

      if (mounted) {
        setState(() {
          _goalSyncResult = result;
          _isLoadingGoalSync = false;
        });

        // Show notification if goals were updated
        if (result.hasUpdates) {
          debugPrint('[GoalSync] Updated ${result.totalGoalsUpdated} goals');

          // Show a snackbar with the result
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    result.hasNewPrs ? Icons.emoji_events : Icons.flag,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.message,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: result.hasNewPrs ? AppColors.orange : AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View Goals',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/goals');
                },
              ),
            ),
          );

          // Play confetti if there are new PRs from goal sync
          if (result.hasNewPrs) {
            _confettiController.play();
          }
        } else {
          debugPrint('[GoalSync] No matching goals found');
        }
      }
    } catch (e) {
      debugPrint('[GoalSync] Error syncing workout with goals: $e');
      if (mounted) {
        setState(() => _isLoadingGoalSync = false);
      }
      // Don't show error to user - this is a non-critical feature
    }
  }


  /// Handle accepting a progression suggestion
  Future<void> _acceptProgression(ProgressionSuggestion suggestion) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      final success = await workoutRepo.respondToProgressionSuggestion(
        userId: userId,
        exerciseName: suggestion.exerciseName,
        newExerciseName: suggestion.suggestedNextVariant,
        accepted: true,
      );

      if (success && mounted) {
        // Remove from suggestions list
        setState(() {
          _progressionSuggestions.removeWhere(
            (s) => s.exerciseName == suggestion.exerciseName
          );
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Great! ${suggestion.suggestedNextVariant} will be included in future workouts.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Play confetti for progression!
        _confettiController.play();
      }
    } catch (e) {
      debugPrint('Error accepting progression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  /// Handle declining a progression suggestion
  Future<void> _declineProgression(ProgressionSuggestion suggestion, [String? reason]) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      await workoutRepo.respondToProgressionSuggestion(
        userId: userId,
        exerciseName: suggestion.exerciseName,
        newExerciseName: suggestion.suggestedNextVariant,
        accepted: false,
        declineReason: reason,
      );

      if (mounted) {
        // Remove from suggestions list
        setState(() {
          _progressionSuggestions.removeWhere(
            (s) => s.exerciseName == suggestion.exerciseName
          );
        });
      }
    } catch (e) {
      debugPrint('Error declining progression: $e');
    }
  }


  /// Show the share workout bottom sheet — delegates to the unified
  /// `ShareableSheet` via `WorkoutAdapter` so the captured card always
  /// shows real volume / sets / reps (Bug #10), uses neutral charcoal
  /// instead of arbitrary blue/orange tints (Bug #12), and the preview
  /// renders cleanly on first tap (Bug #11 — eager-built gallery).
  Future<void> _showShareSheet() async {
    HapticFeedback.mediumImpact();

    final shareable = WorkoutAdapter.fromCompletion(
      ref: ref,
      workoutName: widget.workout.name ?? 'Workout',
      durationSeconds: widget.duration,
      plannedExercises: widget.workout.exercises,
      calories: widget.calories,
      totalVolumeKgFromCaller: widget.totalVolumeKg,
      totalSets: widget.totalSets,
      totalReps: widget.totalReps,
      newPRs: _newPRs.isNotEmpty
          ? _newPRs.map((pr) => {
                'exercise': pr['exercise_name'],
                'weight_kg': pr['weight_kg'],
                'pr_type': 'weight',
                'improvement': pr['previous_pr'] != null
                    ? (pr['weight_kg'] as double) -
                        (pr['previous_pr'] as double)
                    : null,
              }).toList()
          : null,
      currentStreak: _achievements?['streak_days'] as int?,
      totalWorkouts: _achievements?['total_workouts'] as int?,
      musclesWorked: extractMuscles(widget.workout.exercises),
      userDisplayName: ref.read(authStateProvider).user?.displayName,
    );

    if (!mounted) return;
    if (shareable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workout data to share yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final workoutLogId = widget.workoutLogId;
    await ShareableSheet.show(
      context,
      data: shareable,
      onGenerateShareLink: workoutLogId == null || workoutLogId.isEmpty
          ? null
          : () => _generateShareLink(workoutLogId),
    );
  }

  /// Calls the backend `POST /workouts/{id}/share-link` endpoint and
  /// returns the public URL so the share sheet can show it in the
  /// `ShareLinkPill`. Returns null on any failure — the pill will reflect
  /// that as "Get share link" still tappable.
  Future<String?> _generateShareLink(String workoutId) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/api/v1/workouts/$workoutId/share-link');
      final data = res.data;
      if (data is Map && data['url'] is String) {
        return data['url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('share link generation failed: $e');
      return null;
    }
  }


  /// Handle "Do More" - extend the workout with additional AI-generated exercises
  Future<void> _extendWorkout() async {
    setState(() => _isExtendingWorkout = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null || widget.workout.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to extend workout'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isExtendingWorkout = false);
        return;
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final extendedWorkout = await workoutRepo.extendWorkout(
        workoutId: widget.workout.id!,
        userId: userId,
        additionalExercises: 3,
        additionalDurationMinutes: 15,
        focusSameMuscles: true,
      );

      setState(() => _isExtendingWorkout = false);

      if (extendedWorkout != null) {
        // Navigate to the active workout screen with the extended workout
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${extendedWorkout.exercises.length - widget.workout.exercises.length} more exercises!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to active workout with the extended workout
          context.go('/workout/active', extra: extendedWorkout);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to extend workout. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isExtendingWorkout = false);
      debugPrint('❌ Error extending workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  Future<void> _submitFeedback() async {
    debugPrint('📝 [Feedback] Starting feedback submission (async background)...');

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate your workout'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate home IMMEDIATELY — the user already tapped Done; they don't
    // need to watch three sequential API round-trips complete before the
    // home screen appears. Fire the feedback POSTs as unawaited futures.
    // Errors surface via the existing error-reporting on api_client
    // (and the logs below) without blocking navigation.
    setState(() => _isSubmitting = true);

    // Snapshot the data we need so background work is unaffected by
    // state disposal.
    final apiClient = ref.read(apiClientProvider);
    final workoutId = widget.workout.id;
    final rating = _rating;
    final difficulty = _difficulty;
    final energyLevel = _getEnergyLevel();
    final moodAfter = _moodAfter;
    final energyAfter = _energyAfter;
    final confidenceLevel = _confidenceLevel;
    final feelingStronger = _feelingStronger;
    final exerciseFeedbackSnapshot = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
      if (_exerciseRatings.containsKey(i)) {
        exerciseFeedbackSnapshot.add({
          'exercise_name': exercise.name,
          'exercise_index': i,
          'rating': _exerciseRatings[i],
          'difficulty_felt': _exerciseDifficulties[i] ?? 'just_right',
          'would_do_again': true,
        });
      }
    }
    final subjectiveNotifier = ref.read(subjectiveFeedbackProvider.notifier);
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final scoresNotifier = ref.read(scoresProvider.notifier);

    // Kick off all background work without awaiting.
    // ignore: unawaited_futures
    _runFeedbackBackground(
      apiClient: apiClient,
      workoutId: workoutId,
      rating: rating,
      difficulty: difficulty,
      energyLevel: energyLevel,
      moodAfter: moodAfter,
      energyAfter: energyAfter,
      confidenceLevel: confidenceLevel,
      feelingStronger: feelingStronger,
      exerciseFeedback: exerciseFeedbackSnapshot,
      subjectiveNotifier: subjectiveNotifier,
      workoutsNotifier: workoutsNotifier,
      scoresNotifier: scoresNotifier,
    );

    // Navigate home immediately — home screen doesn't depend on these
    // posts completing.
    if (mounted) {
      context.go('/home');
    }
  }

  /// Runs the feedback POSTs, streak refresh, and score recompute in the
  /// background after navigation. All failures are logged but not bubbled
  /// because the user has already moved on to the home screen.
  Future<void> _runFeedbackBackground({
    required ApiClient apiClient,
    required String? workoutId,
    required int rating,
    required String difficulty,
    required String energyLevel,
    required int? moodAfter,
    required int? energyAfter,
    required int? confidenceLevel,
    required bool feelingStronger,
    required List<Map<String, dynamic>> exerciseFeedback,
    required SubjectiveFeedbackNotifier subjectiveNotifier,
    required WorkoutsNotifier workoutsNotifier,
    required ScoresNotifier scoresNotifier,
  }) async {
    try {
      final userId = await apiClient.getUserId();
      if (userId != null && workoutId != null) {
        // Stamp user_id on each exercise feedback row now that we have it.
        final exerciseFeedbackWithUser = exerciseFeedback
            .map((e) => {...e, 'user_id': userId, 'workout_id': workoutId})
            .toList();

        await apiClient.post(
          '/feedback/workout/$workoutId',
          data: {
            'user_id': userId,
            'workout_id': workoutId,
            'overall_rating': rating,
            'overall_difficulty': difficulty,
            'energy_level': energyLevel,
            'would_recommend': rating >= 3,
            'exercise_feedback': exerciseFeedbackWithUser,
          },
        );

        if (moodAfter != null) {
          try {
            await subjectiveNotifier.createPostCheckin(
              workoutId: workoutId,
              moodAfter: moodAfter,
              energyAfter: energyAfter,
              confidenceLevel: confidenceLevel,
              feelingStronger: feelingStronger,
            );
          } catch (e) {
            debugPrint('⚠️ [Subjective Feedback] background error: $e');
          }
        }
      }
      await workoutsNotifier.silentRefresh();
      scoresNotifier.loadScoresOverview(userId: await apiClient.getUserId());
      debugPrint('✅ [Feedback] Background submission complete');
    } catch (e) {
      debugPrint('❌ [Feedback] Background submission failed (non-blocking): $e');
    }
  }

}
