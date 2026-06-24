import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/models/custom_exercise.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/lottie_animations.dart';
import '../../widgets/glass_sheet.dart';
import '../custom_exercises/widgets/create_exercise_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
/// Custom Workout Builder Screen
///
/// Addresses the complaint: "It's much better to just use the Daily Strength app
/// and put together your own plan."
///
/// Allows users to:
/// 1. Create a workout from scratch
/// 2. Select exercises from the library
/// 3. Customize sets, reps, and weights
/// 4. Save and start the workout immediately
class CustomWorkoutBuilderScreen extends ConsumerStatefulWidget {
  const CustomWorkoutBuilderScreen({super.key});

  @override
  ConsumerState<CustomWorkoutBuilderScreen> createState() =>
      _CustomWorkoutBuilderScreenState();
}

class _CustomWorkoutBuilderScreenState
    extends ConsumerState<CustomWorkoutBuilderScreen> {
  final _nameController = TextEditingController(text: 'My Custom Workout');
  String _workoutType = 'strength';
  String _difficulty = 'medium';
  DateTime _scheduledDate = DateTime.now();
  final List<Map<String, dynamic>> _selectedExercises = [];
  bool _isCreating = false;
  bool _showExerciseSearch = false;
  // Auto-generate a warm-up + cool-down stretch set for this workout on
  // save/play (server-side; shown in the detail screen + Easy warm-up runner).
  bool _addWarmupStretch = true;
  // Monotonic superset group id; persists via exercises_json (superset_group /
  // superset_order — already read by the WorkoutExercise model + downstream).
  int _nextSupersetGroup = 1;

  // "✨ Ask AI" generation.
  final _aiPromptController = TextEditingController();
  bool _showAiPrompt = false;
  bool _isGenerating = false;
  String _genStatus = '';

  // Exercise search state
  bool _isSearching = false;
  List<LibraryExerciseItem> _searchResults = [];
  String _searchQuery = '';
  String? _selectedCategory;

  final _categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  @override
  void dispose() {
    _aiPromptController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _searchExercises(String query) async {
    if (query.isEmpty && _selectedCategory == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final libraryRepo = ref.read(libraryRepositoryProvider);
      final results = await libraryRepo.searchExercises(
        query: query.isNotEmpty ? query : null,
        bodyPart: _selectedCategory != null && _selectedCategory != 'All'
            ? _selectedCategory!.toLowerCase()
            : null,
        limit: 50,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching exercises: $e');
      setState(() => _isSearching = false);
    }
  }

  void _addExercise(LibraryExerciseItem exercise) {
    // Check if already added
    if (_selectedExercises.any((e) => e['name'] == exercise.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.customWorkoutBuilderScreenIsAlreadyInYour(exercise.name)),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _selectedExercises.add({
        'name': exercise.name,
        'sets': 3,
        'reps': 10,
        'weight_kg': 0.0,
        'rest_seconds': 60,
        // Timed mode (planks/holds) + superset grouping — persist via
        // exercises_json (the WorkoutExercise model already reads these keys).
        'is_timed': false,
        'duration_seconds': 30,
        'superset_group': null,
        'equipment': exercise.equipment ?? 'bodyweight',
        'muscle_group': exercise.targetMuscle ?? exercise.bodyPart ?? '',
        'notes': '',
        // Persist the image URL under the same field name the
        // WorkoutExercise model deserializes (`gif_url`) so the active-
        // workout thumbnail strip + exercise detail screen render the
        // illustration without an extra `/exercise-images/<name>` lookup
        // round-trip on first load.
        'gif_url': exercise.gifUrl ?? exercise.imageUrl,
        'image_s3_path': exercise.imageUrl,
      });
      _showExerciseSearch = false;
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  /// Extract focus muscle groups from the freeform AI prompt so we can steer
  /// `generateWorkoutStreaming` (which has no freeform-prompt param) toward
  /// what the user typed. Returns null when nothing recognizable is found —
  /// the caller then falls back to the user's saved program focus areas.
  List<String>? _focusFromPrompt(String prompt) {
    final p = prompt.toLowerCase();
    if (p.trim().isEmpty) return null;
    const map = <String, List<String>>{
      'Chest': ['chest', 'pec', 'push', 'bench'],
      'Back': ['back', 'lat', 'pull', 'row'],
      'Legs': ['leg', 'quad', 'hamstring', 'glute', 'calf', 'squat', 'lower'],
      'Shoulders': ['shoulder', 'delt', 'overhead'],
      'Arms': ['arm', 'bicep', 'tricep', 'curl'],
      'Core': ['core', 'ab', 'oblique', 'plank'],
      'Cardio': ['cardio', 'hiit', 'conditioning', 'run'],
      'Full Body': ['full body', 'full-body', 'total body'],
    };
    final found = <String>[];
    map.forEach((focus, kws) {
      if (kws.any(p.contains)) found.add(focus);
    });
    return found.isEmpty ? null : found;
  }

  /// 2c — "✨ Ask AI": generate the exercise list from the user's saved program
  /// preferences (difficulty / duration / equipment) plus an optional freeform
  /// focus prompt. The result populates `_selectedExercises` fully editable —
  /// nothing is saved until the user taps Create/Save. No backend change: this
  /// reuses the streaming generator and maps its `WorkoutExercise`s back into
  /// the builder's per-exercise map shape (inverse of `_addExercise`).
  Future<void> _generateWithAi() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _showAiPrompt = false;
      _genStatus = 'Reading your preferences…';
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) throw Exception('Not logged in');
      final repo = ref.read(workoutRepositoryProvider);
      final prefs = await repo.getProgramPreferences(userId);
      final promptFocus = _focusFromPrompt(_aiPromptController.text);

      // Adopt the prompt's workout type if it clearly names one.
      final pl = _aiPromptController.text.toLowerCase();
      if (pl.contains('cardio')) {
        _workoutType = 'cardio';
      } else if (pl.contains('mobility') || pl.contains('stretch')) {
        _workoutType = 'flexibility';
      }

      final stream = repo.generateWorkoutStreaming(
        userId: userId,
        goals: prefs?.focusAreas,
        equipment: prefs?.equipment.isEmpty ?? true ? null : prefs!.equipment,
        durationMinutes: prefs?.durationMinutes,
        focusAreas: promptFocus ??
            (prefs?.focusAreas.isEmpty ?? true ? null : prefs!.focusAreas),
        scheduledDate: _scheduledDate.toIso8601String().split('T').first,
      );

      await for (final progress in stream) {
        if (!mounted) return;
        if (progress.isLoading) {
          setState(() => _genStatus = progress.message);
        } else if (progress.status == WorkoutGenerationStatus.completed &&
            progress.workout != null) {
          final w = progress.workout!;
          setState(() {
            _selectedExercises
              ..clear()
              ..addAll(w.exercises.map((e) => <String, dynamic>{
                    'name': e.name,
                    'sets': e.sets ?? 3,
                    'reps': e.reps ?? 10,
                    'weight_kg': e.weight ?? 0.0,
                    'rest_seconds': e.restSeconds ?? 60,
                    'is_timed': e.isTimed ?? false,
                    'duration_seconds': e.durationSeconds ?? 30,
                    'superset_group': e.supersetGroup,
                    'equipment': e.equipment ?? 'bodyweight',
                    'muscle_group':
                        e.primaryMuscle ?? e.muscleGroup ?? '',
                    'notes': '',
                    'gif_url': e.gifUrl ?? e.imageS3Path,
                    'image_s3_path': e.imageS3Path,
                    'exercise_id': e.exerciseId,
                  }));
            // Borrow the AI's name only if the user hasn't titled it yet.
            final cur = _nameController.text.trim();
            if ((cur.isEmpty || cur == 'My Custom Workout') &&
                (w.name?.trim().isNotEmpty ?? false)) {
              _nameController.text = w.name!.trim();
            }
            if (w.difficulty != null && w.difficulty!.isNotEmpty) {
              _difficulty = w.difficulty!;
            }
            _isGenerating = false;
            _genStatus = '';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Added ${w.exercises.length} exercises — edit, then Create or Save'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return;
        } else if (progress.status == WorkoutGenerationStatus.error) {
          throw Exception(progress.message);
        }
      }
      if (mounted) setState(() => _isGenerating = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _genStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI generate failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Client-side "AI analysis" of the selected exercises: a muscle-group
  /// balance breakdown + which major groups are missing. No backend round-trip
  /// (works pre-save); the richer history/PR-aware review lives on the detail
  /// screen's AI Insights after Save.
  void _showAnalysis() {
    final counts = <String, int>{};
    for (final e in _selectedExercises) {
      final raw = (e['muscle_group'] as String?)?.trim() ?? '';
      final key = raw.isEmpty
          ? 'Other'
          : raw.split(',').first.split('(').first.trim();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount =
        sorted.isEmpty ? 1 : sorted.first.value;
    final present = counts.keys.join(' ').toLowerCase();
    bool has(List<String> kws) => kws.any((k) => present.contains(k));
    final missing = <String>[
      if (!has(['chest', 'pec'])) 'Chest',
      if (!has(['back', 'lat', 'row'])) 'Back',
      if (!has(['leg', 'quad', 'hamstring', 'glute', 'calf'])) 'Legs',
      if (!has(['shoulder', 'delt'])) 'Shoulders',
      if (!has(['core', 'ab', 'oblique'])) 'Core',
    ];
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Workout balance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ...sorted.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: e.value / maxCount,
                              minHeight: 8,
                              backgroundColor:
                                  AppColors.cyan.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.cyan),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.value}',
                            style: const TextStyle(
                                fontFamily: 'Space Mono', fontSize: 13)),
                      ],
                    ),
                  )),
              const SizedBox(height: 6),
              if (missing.isEmpty)
                Text('Well-rounded — every major group is covered. 💪',
                    style: TextStyle(color: AppColors.success, fontSize: 13))
              else
                Text('Consider adding: ${missing.join(' · ')}',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  /// Open the custom-exercise creator (reused from Settings), prefilled with the
  /// current search text. On success, add the new exercise straight into the
  /// builder list.
  void _createCustomExercise() {
    showGlassSheet(
      context: context,
      builder: (_) => CreateExerciseSheet(
        initialName: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      ),
    ).then((created) {
      if (created is CustomExercise && mounted) {
        setState(() {
          _selectedExercises.add({
            'name': created.name,
            'sets': 3,
            'reps': 10,
            'weight_kg': 0.0,
            'rest_seconds': 60,
            'is_timed': false,
            'duration_seconds': 30,
            'superset_group': null,
            'equipment': created.equipment,
            'muscle_group': created.primaryMuscle,
            'notes': '',
            'gif_url': null,
            'image_s3_path': null,
            'exercise_id': created.id,
          });
          _showExerciseSearch = false;
        });
      }
    });
  }

  void _updateExercise(int index, String field, dynamic value) {
    setState(() {
      _selectedExercises[index][field] = value;
    });
  }

  /// Group / ungroup this exercise with the NEXT one as a superset. Writes a
  /// shared `superset_group` + sequential `superset_order` (persists via
  /// exercises_json). Tapping again on a grouped pair ungroups it.
  void _toggleSupersetWithNext(int index) {
    if (index + 1 >= _selectedExercises.length) return;
    setState(() {
      final cur = _selectedExercises[index];
      final nxt = _selectedExercises[index + 1];
      final g = cur['superset_group'];
      if (g != null && nxt['superset_group'] == g) {
        cur['superset_group'] = null;
        cur['superset_order'] = null;
        nxt['superset_group'] = null;
        nxt['superset_order'] = null;
      } else {
        final group = (g is int) ? g : _nextSupersetGroup++;
        cur['superset_group'] = group;
        cur['superset_order'] = 1;
        nxt['superset_group'] = group;
        nxt['superset_order'] = 2;
      }
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final exercise = _selectedExercises.removeAt(oldIndex);
      _selectedExercises.insert(newIndex, exercise);
    });
  }

  Future<void> _createWorkout() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).customWorkoutBuilderPleaseAddAtLeast),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).customWorkoutBuilderPleaseEnterAWorkout),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.createCustomWorkout(
        userId: userId,
        name: _nameController.text.trim(),
        workoutType: _workoutType,
        difficulty: _difficulty,
        // Send exercises as-is (incl. gif_url / image_s3_path so the active
        // workout screen can render the illustration immediately on load).
        exercises: _selectedExercises
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        durationMinutes: _estimateDuration(),
        scheduledDate: _scheduledDate,
      );

      setState(() => _isCreating = false);

      if (workout != null) {
        // Fire-and-forget warm-up + stretch generation (server-side); the
        // detail screen / Easy warm-up runner read them when ready.
        if (_addWarmupStretch && workout.id != null) {
          unawaited(workoutRepo.generateWarmupAndStretches(workout.id!));
        }
        // Track custom workout created
        ref.read(posthogServiceProvider).capture(
          eventName: 'custom_workout_created',
          properties: {
            'workout_name': _nameController.text.trim(),
            'workout_type': _workoutType,
            'difficulty': _difficulty,
            'exercise_count': _selectedExercises.length,
            'estimated_duration_minutes': _estimateDuration(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).customWorkoutBuilderCustomWorkoutCreated),
              backgroundColor: AppColors.success,
            ),
          );
          // Start the workout in the active-workout PLAYER. Must be
          // `/active-workout` (takes the Workout via extra) — NOT
          // `/workout/active`, which matches the detail route `/workout/:id`
          // with id="active" and fires summary/generation-params/refresh calls
          // with the literal "active" (→ 422/500 + "Refresh failed" banner).
          // `push` (not `go`) also preserves the back stack so the player's
          // back button works ("There is nothing to pop").
          context.push('/active-workout', extra: workout);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).customWorkoutBuilderFailedToCreateWorkout),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isCreating = false);
      debugPrint('Error creating custom workout: $e');
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

  /// Save (reusable) — distinct from Play. Creates + schedules the workout,
  /// marks it favorite so it lands in "My Workouts", and opens the DETAIL
  /// screen (whose AI Insights section is the AI review) WITHOUT starting it.
  Future<void> _saveWorkout() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).customWorkoutBuilderPleaseAddAtLeast),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).customWorkoutBuilderPleaseEnterAWorkout),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _isCreating = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) throw Exception('User not logged in');
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.createCustomWorkout(
        userId: userId,
        name: _nameController.text.trim(),
        workoutType: _workoutType,
        difficulty: _difficulty,
        exercises:
            _selectedExercises.map((e) => Map<String, dynamic>.from(e)).toList(),
        durationMinutes: _estimateDuration(),
        scheduledDate: _scheduledDate,
      );
      setState(() => _isCreating = false);
      if (workout != null) {
        // Mark reusable so it appears in My Workouts. Best-effort.
        if (workout.id != null) {
          try {
            await workoutRepo.toggleWorkoutFavorite(workout.id!);
          } catch (_) {}
        }
        if (_addWarmupStretch && workout.id != null) {
          unawaited(workoutRepo.generateWarmupAndStretches(workout.id!));
        }
        ref.read(posthogServiceProvider).capture(
          eventName: 'custom_workout_saved',
          properties: {
            'exercise_count': _selectedExercises.length,
            'difficulty': _difficulty,
            'workout_type': _workoutType,
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Saved to My Workouts'),
            backgroundColor: AppColors.success,
          ));
          // Open the detail screen (AI Insights = the review). Real UUID, so
          // the summary/insight endpoints resolve correctly.
          if (workout.id != null) {
            context.pushReplacement('/workout/${workout.id}', extra: workout);
          } else {
            context.pop();
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).customWorkoutBuilderFailedToCreateWorkout),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  String _formatScheduledDate(DateTime date) {
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(t).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  int _estimateDuration() {
    // Estimate duration based on exercises
    // Average ~5 min per exercise
    return (_selectedExercises.length * 5).clamp(15, 120);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      appBar: PillAppBar(
        title: AppLocalizations.of(context).customWorkoutBuilderBuildCustomWorkout,
        actions: [
          // Save (reusable) — stores + favorites + opens the detail screen
          // (its AI Insights section is the review), WITHOUT starting.
          PillAppBarAction(
            icon: Icons.bookmark_add_outlined,
            visible: !_isCreating,
            onTap: _selectedExercises.isEmpty ? null : _saveWorkout,
          ),
          // Play — creates + jumps straight into the active-workout player.
          PillAppBarAction(
            icon: Icons.play_arrow_rounded,
            visible: !_isCreating,
            onTap: _selectedExercises.isEmpty ? null : _createWorkout,
          ),
        ],
      ),
      body: _showExerciseSearch
          ? _buildExerciseSearch(surface, textPrimary, textSecondary)
          : _buildWorkoutBuilder(surface, textPrimary, textSecondary),
      // Persistent bottom bar for the primary "Add Exercise" action.
      // Replaces the previous FloatingActionButton.extended which was
      // rendering its label clipped against the FAB pill on iOS.
      bottomNavigationBar: _showExerciseSearch
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showExerciseSearch = true;
                        _searchQuery = '';
                        _selectedCategory = null;
                        _searchResults = [];
                      });
                      _searchExercises('');
                    },
                    icon: const Icon(Icons.add, size: 22),
                    label: Text(
                      AppLocalizations.of(context).workoutSummaryAddExercise,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWorkoutBuilder(
      Color surface, Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).customWorkoutBuilderWorkoutName,
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // ✨ Ask AI — generate the exercise list from your preferences (+ an
          // optional focus prompt), editable before you save.
          GestureDetector(
            onTap: _isGenerating
                ? null
                : () => setState(() => _showAiPrompt = !_showAiPrompt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.cyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isGenerating
                          ? (_genStatus.isEmpty ? 'Generating…' : _genStatus)
                          : 'Ask AI to build it',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_isGenerating)
                    const SizedBox(
                        width: 18, height: 18, child: LottieLoading(size: 18))
                  else
                    Icon(_showAiPrompt ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.cyan),
                ],
              ),
            ),
          ),
          if (_showAiPrompt && !_isGenerating) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _aiPromptController,
              decoration: InputDecoration(
                hintText: 'e.g. 45-min push day, dumbbells only',
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: TextStyle(color: textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _generateWithAi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Generate',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Workout Type
          Text(AppLocalizations.of(context).workoutSettingsWorkoutType,
              style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('strength', 'Strength', Icons.fitness_center),
              const SizedBox(width: 8),
              _buildTypeChip('cardio', 'Cardio', Icons.directions_run),
              const SizedBox(width: 8),
              _buildTypeChip('mixed', 'Mixed', Icons.all_inclusive),
            ],
          ),
          const SizedBox(height: 16),

          // Difficulty
          Text(AppLocalizations.of(context).workoutSummaryGeneralDifficulty,
              style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDifficultyChip('easy', 'Easy'),
              const SizedBox(width: 8),
              _buildDifficultyChip('medium', 'Medium'),
              const SizedBox(width: 8),
              _buildDifficultyChip('hard', 'Hard'),
              const SizedBox(width: 8),
              _buildDifficultyChip('hell', 'Hell'),
            ],
          ),
          const SizedBox(height: 16),

          // Scheduled date — lets user pick when this custom workout should
          // appear on their schedule (defaults to today).
          Text(AppLocalizations.of(context).customWorkoutBuilderScheduleFor,
              style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _scheduledDate,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _scheduledDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 20, color: AppColors.cyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatScheduledDate(_scheduledDate),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto warm-up & stretches toggle.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.whatshot_rounded, size: 20, color: AppColors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add warm-up & stretches',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _addWarmupStretch,
                  activeThumbColor: AppColors.cyan,
                  onChanged: (v) => setState(() => _addWarmupStretch = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Exercises List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.customWorkoutBuilderScreenExercises(_selectedExercises.length),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedExercises.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _showAnalysis,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 15, color: AppColors.cyan),
                          const SizedBox(width: 4),
                          Text('Analyze',
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '~${_estimateDuration()} min',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedExercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: textSecondary.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center,
                      size: 48, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).customWorkoutBuilderNoExercisesAddedYet,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).customWorkoutBuilderTapTheButtonBelow,
                    style: TextStyle(
                      color: textSecondary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedExercises.length,
              onReorder: _reorderExercises,
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return _buildExerciseCard(
                  key: ValueKey('exercise_$index'),
                  exercise: exercise,
                  index: index,
                  surface: surface,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _workoutType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _workoutType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cyan : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.cyan
                  : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label) {
    final isSelected = _difficulty == value;
    final color = value == 'easy'
        ? AppColors.success
        : (value == 'medium'
            ? AppColors.warning
            : (value == 'hell'
                ? const Color(0xFF8B1FB0) // distinct from hard's red
                : AppColors.error));

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required Key key,
    required Map<String, dynamic> exercise,
    required int index,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header with drag handle, thumbnail, and exercise name
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle, color: textSecondary),
                  ),
                ),
                // Thumbnail — shows the picked illustration so the user
                // confirms the exercise visually + persists through to the
                // active workout via gif_url / image_s3_path.
                _CustomBuilderThumb(
                  url: (exercise['gif_url'] as String?) ??
                      (exercise['image_s3_path'] as String?),
                  surface: surface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] ?? AppLocalizations.of(context).demoActiveWorkoutExercise,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise['muscle_group'] ?? '',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (exercise['superset_group'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('SUPERSET',
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              )),
                        ),
                      ],
                    ],
                  ),
                ),
                // Superset link with the next exercise (hidden on the last row).
                if (index < _selectedExercises.length - 1)
                  IconButton(
                    icon: Icon(
                      exercise['superset_group'] != null
                          ? Icons.link_off_rounded
                          : Icons.link_rounded,
                      color: AppColors.cyan,
                    ),
                    tooltip: 'Superset with next',
                    onPressed: () => _toggleSupersetWithNext(index),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  onPressed: () => _removeExercise(index),
                ),
              ],
            ),
          ),

          // Sets / Reps-or-Time / Weight, then Rest + a Reps|Time toggle.
          Builder(builder: (context) {
            final timed = exercise['is_timed'] == true;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberControl(
                          label: AppLocalizations.of(context).workoutSummaryGeneralSets,
                          value: exercise['sets'] ?? 3,
                          onChanged: (v) => _updateExercise(index, 'sets', v),
                          min: 1,
                          max: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reps OR Time (seconds) depending on the timed toggle.
                      Expanded(
                        child: timed
                            ? _buildNumberControl(
                                label: 'Time (s)',
                                value: ((exercise['duration_seconds'] ?? 30) as num).toInt(),
                                onChanged: (v) =>
                                    _updateExercise(index, 'duration_seconds', v),
                                min: 5,
                                max: 600,
                                step: 5,
                              )
                            : _buildNumberControl(
                                label: AppLocalizations.of(context).workoutSummaryGeneralReps,
                                value: exercise['reps'] ?? 10,
                                onChanged: (v) => _updateExercise(index, 'reps', v),
                                min: 1,
                                max: 30,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberControl(
                          label: AppLocalizations.of(context).workoutHistoryImportWeightKg,
                          value: (exercise['weight_kg'] ?? 0).toInt(),
                          onChanged: (v) =>
                              _updateExercise(index, 'weight_kg', v.toDouble()),
                          min: 0,
                          max: 200,
                          step: 5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberControl(
                          label: 'Rest (s)',
                          value: ((exercise['rest_seconds'] ?? 60) as num).toInt(),
                          onChanged: (v) =>
                              _updateExercise(index, 'rest_seconds', v),
                          min: 0,
                          max: 300,
                          step: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildRepsTimeToggle(timed, index)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNumberControl({
    required String label,
    required int value,
    required Function(int) onChanged,
    int min = 0,
    int max = 100,
    int step = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: value > min ? () => onChanged(value - step) : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: value > min
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                value.toString(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: value < max ? () => onChanged(value + step) : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: value < max
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Per-exercise Reps | Time segmented toggle. Flips `is_timed`, switching the
  /// middle control between a Reps stepper and a Time(seconds) stepper.
  Widget _buildRepsTimeToggle(bool timed, int index) {
    Widget seg(String label, bool active, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.cyan : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Mode',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              seg('Reps', !timed,
                  () => _updateExercise(index, 'is_timed', false)),
              seg('Time', timed,
                  () => _updateExercise(index, 'is_timed', true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseSearch(
      Color surface, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showExerciseSearch = false),
              ),
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).supersetExercisePickerSearchExercises,
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _searchExercises(value);
                  },
                ),
              ),
            ],
          ),
        ),

        // Category chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category ||
                  (category == 'All' && _selectedCategory == null);
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory =
                          (category == 'All' || !selected) ? null : category;
                    });
                    _searchExercises(_searchQuery);
                  },
                  selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.cyan,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Create your own exercise — surfaces the custom-exercise creator right
        // in the builder (it used to be buried in Settings → Exercise prefs).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: GestureDetector(
            onTap: _createCustomExercise,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: AppColors.cyan, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Create custom exercise',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Results
        Expanded(
          child: _isSearching
              ? const Center(child: LottieLoading(size: 50))
              : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty && _selectedCategory == null
                            ? 'Search for exercises or select a category'
                            : 'No exercises found',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final exercise = _searchResults[index];
                        final isAdded = _selectedExercises
                            .any((e) => e['name'] == exercise.name);
                        final exerciseImageUrl = exercise.gifUrl ?? exercise.imageUrl;
                        return ListTile(
                          leading: exerciseImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: exerciseImageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 50,
                                      height: 50,
                                      color: surface,
                                      child: const Center(
                                          child: LottieLoading(size: 20)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 50,
                                      height: 50,
                                      color: surface,
                                      child: const Icon(Icons.fitness_center),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.fitness_center),
                                ),
                          title: Text(
                            exercise.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            exercise.targetMuscle ?? exercise.bodyPart ?? exercise.equipment ?? '',
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                          trailing: isAdded
                              ? const Icon(Icons.check, color: AppColors.success)
                              : IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: AppColors.cyan),
                                  onPressed: () => _addExercise(exercise),
                                ),
                          onTap: isAdded ? null : () => _addExercise(exercise),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// Compact thumbnail used inside the custom workout builder's exercise card.
/// Falls back to a fitness-center glyph when no image URL is available.
class _CustomBuilderThumb extends StatelessWidget {
  final String? url;
  final Color surface;

  const _CustomBuilderThumb({required this.url, required this.surface});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fitness_center,
          size: 20, color: AppColors.textSecondary),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}
