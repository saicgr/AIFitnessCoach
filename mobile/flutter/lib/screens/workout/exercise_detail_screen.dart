import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/glass_back_button.dart';
import '../../core/providers/warmup_duration_provider.dart';
import '../../data/models/exercise.dart';
import '../../data/services/api_client.dart';

/// Full-screen exercise detail with autoplay video
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

/// Model for previous set performance
class PreviousSetData {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final String setType;
  final int? rir;
  final int? rpe;

  PreviousSetData({
    required this.setNumber,
    this.weightKg,
    this.reps,
    required this.setType,
    this.rir,
    this.rpe,
  });
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  VideoPlayerController? _videoController;
  String? _imageUrl;
  String? _videoUrl;
  bool _isLoadingMedia = true;
  bool _videoInitialized = false;
  bool _showVideo = true;

  // Rest timer
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _isResting = false;

  // Previous performance
  List<PreviousSetData> _previousSets = [];
  bool _isLoadingPrevious = true;

  @override
  void initState() {
    super.initState();
    _loadMediaAndAutoplay();
    _loadPreviousPerformance();
  }

  Future<void> _loadPreviousPerformance() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingPrevious = false);
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      final response = await apiClient.get(
        '/performance-db/exercise-last-performance/${Uri.encodeComponent(exerciseName)}',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final sets = response.data['sets'] as List?;
        if (sets != null && sets.isNotEmpty) {
          _previousSets = sets.map((s) => PreviousSetData(
            setNumber: s['set_number'] ?? 0,
            weightKg: (s['weight_kg'] as num?)?.toDouble(),
            reps: s['reps_completed'] as int?,
            setType: s['set_type'] ?? 'working',
            rir: s['rir'] as int?,
            rpe: s['rpe'] as int?,
          )).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading previous performance: $e');
    }

    if (mounted) {
      setState(() => _isLoadingPrevious = false);
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadMediaAndAutoplay() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingMedia = false);
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);

      // First check if exercise already has a gifUrl from the database
      final exerciseGifUrl = widget.exercise.gifUrl;
      if (exerciseGifUrl != null && exerciseGifUrl.isNotEmpty) {
        _imageUrl = exerciseGifUrl;
      } else {
        // Load image from API as fallback
        try {
          final imageResponse = await apiClient.get(
            '/exercise-images/${Uri.encodeComponent(exerciseName)}',
          );
          if (imageResponse.statusCode == 200 && imageResponse.data != null) {
            _imageUrl = imageResponse.data['url'] as String?;
          }
        } catch (_) {}
      }

      // Load and autoplay video
      try {
        final videoResponse = await apiClient.get(
          '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
        );
        if (videoResponse.statusCode == 200 && videoResponse.data != null) {
          _videoUrl = videoResponse.data['url'] as String?;
          if (_videoUrl != null) {
            _videoController = VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
            await _videoController!.initialize();
            _videoController!.setLooping(true);
            _videoController!.setVolume(0);
            _videoController!.play();
            _videoInitialized = true;
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading media: $e');
    }

    if (mounted) {
      setState(() => _isLoadingMedia = false);
    }
  }

  void _toggleVideo() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  void _startRestTimer() {
    final restTime = widget.exercise.restSeconds ?? 120;
    setState(() {
      _isResting = true;
      _restSeconds = restTime;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        _stopRestTimer();
      }
    });

    HapticFeedback.mediumImpact();
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSeconds = 0;
    });
    HapticFeedback.lightImpact();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _getRepRange() {
    if (widget.exercise.reps != null) {
      final reps = widget.exercise.reps!;
      if (reps <= 6) return '${reps - 1}-${reps + 1}';
      if (reps <= 12) return '${reps - 2}-${reps + 2}';
      return '${reps - 3}-${reps + 3}';
    }
    return '8-12';
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final totalSets = exercise.sets ?? 3;
    final warmupSets = 2;
    final repRange = _getRepRange();
    final restSeconds = exercise.restSeconds ?? 120;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App bar with video
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                automaticallyImplyLeading: false, // Remove default back button
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildVideoSection(elevated, textMuted),
                ),
              ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Target muscle
                  if (exercise.primaryMuscle != null || exercise.muscleGroup != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise.primaryMuscle ?? exercise.muscleGroup ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                        if (exercise.equipment != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: glassSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exercise.equipment!,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Instructions
                  if (exercise.instructions != null &&
                      exercise.instructions!.isNotEmpty)
                    _buildInstructionsSection(exercise.instructions!, elevated, textSecondary),

                  // Rest Timer Card
                  _buildRestTimerCard(restSeconds, elevated, textMuted, textPrimary),
                  const SizedBox(height: 24),

                  // Set table header
                  Text(
                    'SETS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Set table
                  _buildSetTable(warmupSets, totalSets, repRange, exercise.weight, elevated, glassSurface, cardBorder, textPrimary, textMuted, textSecondary),
                  const SizedBox(height: 24),

                  // Workout Preferences section
                  _buildWorkoutPreferencesSection(elevated, cardBorder, textPrimary, textMuted),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Floating back button
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        child: GlassBackButton(
          onTap: () => context.pop(),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(Color elevated, Color textMuted) {
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    return GestureDetector(
      onTap: _toggleVideo,
      child: Container(
        color: elevated,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isLoadingMedia)
              Center(
                child: CircularProgressIndicator(color: accentColor),
              )
            else if (_videoInitialized && _showVideo && _videoController != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else if (_imageUrl != null)
              CachedNetworkImage(
                imageUrl: _imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: CircularProgressIndicator(color: accentColor),
                ),
                errorWidget: (_, __, ___) => _buildPlaceholder(elevated, textMuted),
              )
            else
              _buildPlaceholder(elevated, textMuted),

            // Play/Pause overlay
            if (_videoInitialized && _videoController != null)
              Center(
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Video/Image toggle
            if (_videoUrl != null && _imageUrl != null)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showVideo = !_showVideo;
                      if (_showVideo && _videoController != null) {
                        _videoController!.play();
                      } else if (_videoController != null) {
                        _videoController!.pause();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showVideo ? Icons.image : Icons.play_circle,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showVideo ? 'Image' : 'Video',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color elevated, Color textMuted) {
    return Container(
      color: elevated,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 64,
          color: textMuted,
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(String instructions, Color elevated, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            instructions,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerCard(int defaultSeconds, Color elevated, Color textMuted, Color textPrimary) {
    final mins = defaultSeconds ~/ 60;
    final secs = defaultSeconds % 60;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    return GestureDetector(
      onTap: _isResting ? _stopRestTimer : _startRestTimer,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _isResting
              ? LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isResting ? null : elevated,
          borderRadius: BorderRadius.circular(12),
          border: _isResting
              ? Border.all(color: accentColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: _isResting ? accentColor : textMuted,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest Timer',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isResting ? accentColor : textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isResting
                        ? _formatTime(_restSeconds)
                        : '${mins}m ${secs}s',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isResting ? accentColor : textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isResting ? 'SKIP' : 'START',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPreferencesSection(Color elevated, Color cardBorder, Color textPrimary, Color textMuted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final warmupState = ref.watch(warmupDurationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORKOUT PREFERENCES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              // Warmup toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.whatshot, color: orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warmup Phase',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Dynamic warmup before workouts',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: warmupState.warmupEnabled,
                      onChanged: warmupState.isLoading
                          ? null
                          : (value) {
                              HapticFeedback.lightImpact();
                              ref.read(warmupDurationProvider.notifier).setWarmupEnabled(value);
                            },
                      activeTrackColor: orange,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
              // Stretch toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.self_improvement, color: cyan, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cooldown Stretch',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Stretching after workouts',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: warmupState.stretchEnabled,
                      onChanged: warmupState.isLoading
                          ? null
                          : (value) {
                              HapticFeedback.lightImpact();
                              ref.read(warmupDurationProvider.notifier).setStretchEnabled(value);
                            },
                      activeTrackColor: cyan,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get previous performance for a specific set
  PreviousSetData? _getPreviousSet(int setNumber, bool isWarmup) {
    final setType = isWarmup ? 'warmup' : 'working';
    try {
      return _previousSets.firstWhere(
        (s) => s.setNumber == setNumber && s.setType == setType,
      );
    } catch (_) {
      // Try to find any set with same number regardless of type
      try {
        return _previousSets.firstWhere((s) => s.setNumber == setNumber);
      } catch (_) {
        return null;
      }
    }
  }

  /// Format previous set display (e.g., "40 × 7")
  String _formatPreviousSet(PreviousSetData? previous) {
    if (previous == null) return '-';
    final weight = previous.weightKg;
    final reps = previous.reps;
    if (weight == null && reps == null) return '-';
    if (weight == null) return '× $reps';
    if (reps == null) return '${weight.toInt()}';
    return '${weight.toInt()} × $reps';
  }

  /// Get RIR color based on value (matching WorkoutDesign colors)
  Color _getRirColor(int rir) {
    if (rir <= 0) return const Color(0xFFEF4444); // Red - failure
    if (rir == 1) return const Color(0xFFF97316); // Orange
    if (rir == 2) return const Color(0xFFEAB308); // Yellow
    return const Color(0xFF22C55E); // Green for 3+
  }

  /// Get RIR text color for contrast
  Color _getRirTextColor(int rir) {
    if (rir == 2) return Colors.black87; // Dark text on yellow
    return Colors.white;
  }

  Widget _buildSetTable(int warmupSets, int workingSets, String repRange, double? weight, Color elevated, Color glassSurface, Color cardBorder, Color textPrimary, Color textMuted, Color textSecondary) {
    final hasPrevious = _previousSets.isNotEmpty;
    final exercise = widget.exercise;
    final setTargets = exercise.setTargets ?? [];

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header - matches active workout screen: Set | Previous | Target (weight × reps + RIR)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('Set', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.3))),
                Expanded(
                  flex: 2,
                  child: Text('Previous', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.3)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.3)),
                ),
              ],
            ),
          ),

          // Build rows from setTargets - NO FALLBACK, must fail if setTargets is empty
          ...setTargets.asMap().entries.map((entry) {
            final index = entry.key;
            final target = entry.value;
            final isWarmup = target.setType == 'warmup';
            final previous = _getPreviousSet(target.setNumber, isWarmup);

            return _buildTableRow(
              setLabel: isWarmup ? 'W' : '${target.setNumber}',
              isWarmup: isWarmup,
              previousData: previous,
              hasPrevious: hasPrevious,
              targetWeight: target.targetWeightKg,
              targetReps: target.targetReps,
              targetRir: target.targetRir,
              isLast: index == setTargets.length - 1,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
              textSecondary: textSecondary,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String setLabel,
    required bool isWarmup,
    PreviousSetData? previousData,
    required bool hasPrevious,
    double? targetWeight,
    int? targetReps,
    int? targetRir,
    required bool isLast,
    required Color cardBorder,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
  }) {
    final previousDisplay = _formatPreviousSet(previousData);

    // Format target display
    String targetDisplay = '-';
    if (targetWeight != null && targetReps != null) {
      targetDisplay = '${targetWeight.toInt()} × $targetReps';
    } else if (targetReps != null) {
      targetDisplay = '× $targetReps';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cardBorder.withValues(alpha: 0.2),
                ),
              ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : null,
      ),
      child: Row(
        children: [
          // Set badge
          SizedBox(
            width: 36,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isWarmup
                    ? textMuted.withValues(alpha: 0.15)
                    : textPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  setLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isWarmup ? textMuted : textPrimary,
                  ),
                ),
              ),
            ),
          ),

          // Previous column - weight × reps + RIR
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight x Reps
                Text(
                  previousDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: previousDisplay == '-' ? textMuted : textSecondary,
                    fontWeight: previousDisplay != '-' ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                // RIR pill (if available)
                if (previousData?.rir != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRirColor(previousData!.rir!).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RIR ${previousData.rir}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getRirColor(previousData.rir!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Target column - weight × reps + RIR
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target weight x reps
                Text(
                  targetDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: targetDisplay == '-' ? textMuted : textPrimary,
                    fontWeight: targetDisplay != '-' ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                // Target RIR pill
                if (targetRir != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRirColor(targetRir).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RIR $targetRir',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getRirColor(targetRir),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
