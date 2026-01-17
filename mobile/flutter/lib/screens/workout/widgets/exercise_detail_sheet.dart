import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';

/// Shows a detailed exercise view with set tracking table
/// Similar to the Hevy app design
Future<void> showExerciseDetailSheet(
  BuildContext context,
  WidgetRef ref, {
  required WorkoutExercise exercise,
  int? warmupSets,
  List<SetData>? previousSets,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    builder: (context) => ExerciseDetailSheet(
      exercise: exercise,
      warmupSets: warmupSets ?? 0,
      previousSets: previousSets ?? [],
    ),
  );
}

/// Data class for tracking set information
class SetData {
  final int setNumber;
  final bool isWarmup;
  final double? weight;
  final String repRange;
  final int? actualReps;
  final bool isCompleted;

  const SetData({
    required this.setNumber,
    this.isWarmup = false,
    this.weight,
    required this.repRange,
    this.actualReps,
    this.isCompleted = false,
  });

  SetData copyWith({
    int? setNumber,
    bool? isWarmup,
    double? weight,
    String? repRange,
    int? actualReps,
    bool? isCompleted,
  }) {
    return SetData(
      setNumber: setNumber ?? this.setNumber,
      isWarmup: isWarmup ?? this.isWarmup,
      weight: weight ?? this.weight,
      repRange: repRange ?? this.repRange,
      actualReps: actualReps ?? this.actualReps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ExerciseDetailSheet extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final int warmupSets;
  final List<SetData> previousSets;

  const ExerciseDetailSheet({
    super.key,
    required this.exercise,
    this.warmupSets = 0,
    this.previousSets = const [],
  });

  @override
  ConsumerState<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<ExerciseDetailSheet> {
  // Set tracking
  late List<SetData> _sets;
  int _restSeconds = 0;
  Timer? _restTimer;
  bool _isResting = false;

  // Video/Image
  String? _imageUrl;
  String? _videoUrl;
  VideoPlayerController? _videoController;
  bool _isPlayingVideo = false;
  bool _isLoadingMedia = true;

  @override
  void initState() {
    super.initState();
    _initializeSets();
    _loadMedia();
  }

  void _initializeSets() {
    final totalWorkingSets = widget.exercise.sets ?? 3;
    final warmupCount = widget.warmupSets;
    final repRange = _getRepRange();

    _sets = [];

    // Add warmup sets
    for (int i = 0; i < warmupCount; i++) {
      _sets.add(SetData(
        setNumber: i + 1,
        isWarmup: true,
        repRange: repRange,
      ));
    }

    // Add working sets
    for (int i = 0; i < totalWorkingSets; i++) {
      _sets.add(SetData(
        setNumber: i + 1,
        isWarmup: false,
        weight: widget.exercise.weight,
        repRange: repRange,
      ));
    }
  }

  String _getRepRange() {
    if (widget.exercise.reps != null) {
      final reps = widget.exercise.reps!;
      // If reps is a single number, show as range (e.g., 10 -> 8-12)
      if (reps <= 6) {
        return '${reps - 1}-${reps + 1}';
      } else if (reps <= 12) {
        return '${reps - 2}-${reps + 2}';
      } else {
        return '${reps - 3}-${reps + 3}';
      }
    } else if (widget.exercise.durationSeconds != null) {
      return '${widget.exercise.durationSeconds}s';
    }
    return '8-12';
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingMedia = false);
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);

      // Load image
      final imageResponse = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );
      if (imageResponse.statusCode == 200 && imageResponse.data != null) {
        _imageUrl = imageResponse.data['url'] as String?;
      }

      // Load video URL (don't initialize yet)
      final videoResponse = await apiClient.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );
      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        _videoUrl = videoResponse.data['url'] as String?;
      }
    } catch (e) {
      // Media not found, that's ok
    }

    if (mounted) {
      setState(() => _isLoadingMedia = false);
    }
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

  void _toggleVideo() async {
    if (_videoUrl == null) return;

    if (_isPlayingVideo) {
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      setState(() => _isPlayingVideo = false);
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);
      _videoController!.play();
      setState(() => _isPlayingVideo = true);
    }
  }

  void _completeSet(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _sets[index] = _sets[index].copyWith(isCompleted: true);
    });

    // Start rest timer if not the last set
    if (index < _sets.length - 1) {
      _startRestTimer();
    }
  }

  void _updateSetWeight(int index, double? weight) {
    setState(() {
      _sets[index] = _sets[index].copyWith(weight: weight);
    });
  }

  String _formatRestTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}min ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final defaultRestSeconds = widget.exercise.restSeconds ?? 120;
    final restMins = defaultRestSeconds ~/ 60;
    final restSecs = defaultRestSeconds % 60;

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Exercise Image/Video
                    _buildMediaSection(cardBackground, textMuted),
                    const SizedBox(height: 16),

                    // Exercise Name
                    Text(
                      widget.exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    // Unilateral indicator (like Gravl - "each side")
                    if (widget.exercise.isUnilateral == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '(each side)',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Target muscle
                    if (widget.exercise.primaryMuscle != null ||
                        widget.exercise.muscleGroup != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.exercise.primaryMuscle ??
                              widget.exercise.muscleGroup ??
                              '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.cyan,
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Equipment tag
                    if (widget.exercise.equipment != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Text(
                            widget.exercise.equipment!,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Instructions
                    if (widget.exercise.instructions != null &&
                        widget.exercise.instructions!.isNotEmpty)
                      _buildInstructionsSection(cardBackground, textSecondary),

                    // Rest Timer Display
                    _buildRestTimerCard(restMins, restSecs, cardBackground, textMuted, textPrimary),
                    const SizedBox(height: 20),

                    // Set Tracking Table
                    _buildSetTable(glassSurface, cardBackground, cardBorder, textMuted, textPrimary, textSecondary),
                    const SizedBox(height: 20),

                    // Previous Performance (if available)
                    if (widget.previousSets.isNotEmpty)
                      _buildPreviousPerformance(cardBackground, textMuted),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaSection(Color cardBackground, Color textMuted) {
    return GestureDetector(
      onTap: _videoUrl != null ? _toggleVideo : null,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isLoadingMedia)
              const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              )
            else if (_isPlayingVideo &&
                _videoController != null &&
                _videoController!.value.isInitialized)
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
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                ),
                errorWidget: (_, __, ___) => _buildPlaceholder(textMuted),
              )
            else
              _buildPlaceholder(textMuted),

            // Play button overlay
            if (_videoUrl != null && !_isPlayingVideo)
              Center(
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

            // Stop button when playing
            if (_isPlayingVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause,
                    size: 24,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color textMuted) {
    return Center(
      child: Icon(
        Icons.fitness_center,
        size: 64,
        color: textMuted,
      ),
    );
  }

  Widget _buildInstructionsSection(Color cardBackground, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.exercise.instructions!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerCard(int restMins, int restSecs, Color cardBackground, Color textMuted, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _isResting
            ? LinearGradient(
                colors: [
                  AppColors.purple.withOpacity(0.3),
                  AppColors.purple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isResting ? null : cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: _isResting
            ? Border.all(color: AppColors.purple.withOpacity(0.5))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: _isResting ? AppColors.purple : textMuted,
            size: 24,
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
                    color: _isResting ? AppColors.purple : textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isResting
                      ? _formatRestTime(_restSeconds)
                      : '${restMins}m ${restSecs}s',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isResting ? AppColors.purple : textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cyan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isResting
                ? TextButton(
                    onPressed: _stopRestTimer,
                    child: const Text(
                      'SKIP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                : TextButton(
                    onPressed: _startRestTimer,
                    child: const Text(
                      'START',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetTable(Color glassSurface, Color cardBackground, Color cardBorder, Color textMuted, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: glassSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  'SET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'LBS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    'REP RANGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 50),
            ],
          ),
        ),

        // Table rows
        Container(
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Column(
            children: List.generate(_sets.length, (index) {
              final set = _sets[index];
              final isLast = index == _sets.length - 1;

              return _buildSetRow(set, index, isLast, cardBorder, glassSurface, textPrimary, textMuted, textSecondary);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSetRow(SetData set, int index, bool isLast, Color cardBorder, Color glassSurface, Color textPrimary, Color textMuted, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cardBorder.withOpacity(0.3),
                ),
              ),
        color: set.isCompleted
            ? AppColors.success.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Set number (W for warmup, number for working)
          SizedBox(
            width: 50,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: set.isWarmup
                    ? AppColors.orange.withOpacity(0.2)
                    : set.isCompleted
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  set.isWarmup ? 'W' : '${set.setNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: set.isWarmup
                        ? AppColors.orange
                        : set.isCompleted
                            ? AppColors.success
                            : AppColors.cyan,
                  ),
                ),
              ),
            ),
          ),

          // Weight input
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => _showWeightInput(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    set.weight != null
                        ? '${set.weight!.toInt()}'
                        : '-',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: set.weight != null
                          ? textPrimary
                          : textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Rep range
          SizedBox(
            width: 80,
            child: Center(
              child: Text(
                set.repRange,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ),
          ),

          // Complete button
          SizedBox(
            width: 50,
            child: IconButton(
              onPressed: set.isCompleted ? null : () => _completeSet(index),
              icon: Icon(
                set.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: set.isCompleted ? AppColors.success : textMuted,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightInput(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final controller = TextEditingController(
      text: _sets[index].weight?.toInt().toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          'Enter Weight (lbs)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixText: 'lbs',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              _updateSetWeight(index, weight);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousPerformance(Color cardBackground, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREVIOUS PERFORMANCE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: widget.previousSets.map((set) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      set.isWarmup ? 'W' : 'Set ${set.setNumber}',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${set.weight?.toInt() ?? '-'} lbs × ${set.actualReps ?? set.repRange}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
