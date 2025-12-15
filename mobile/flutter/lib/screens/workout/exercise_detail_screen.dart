import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
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

  PreviousSetData({
    required this.setNumber,
    this.weightKg,
    this.reps,
    required this.setType,
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
    return '${mins}:${secs.toString().padLeft(2, '0')}';
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with video
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black54 : Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, size: 20, color: isDark ? Colors.white : Colors.black87),
              ),
              onPressed: () => context.pop(),
            ),
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
                            color: AppColors.cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise.primaryMuscle ?? exercise.muscleGroup ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(Color elevated, Color textMuted) {
    return GestureDetector(
      onTap: _toggleVideo,
      child: Container(
        color: elevated,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isLoadingMedia)
              const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
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
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
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

    return GestureDetector(
      onTap: _isResting ? _stopRestTimer : _startRestTimer,
      child: Container(
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
          color: _isResting ? null : elevated,
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
                      color: _isResting ? AppColors.purple : textMuted,
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
                      color: _isResting ? AppColors.purple : textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isResting
                    ? AppColors.purple.withOpacity(0.2)
                    : AppColors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isResting ? 'SKIP' : 'START',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isResting ? AppColors.purple : AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
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

  /// Format previous set display (e.g., "40kg × 7")
  String _formatPreviousSet(PreviousSetData? previous) {
    if (previous == null) return '-';
    final weight = previous.weightKg;
    final reps = previous.reps;
    if (weight == null && reps == null) return '-';
    if (weight == null) return '× $reps';
    if (reps == null) return '${weight.toInt()}kg';
    return '${weight.toInt()}kg × $reps';
  }

  Widget _buildSetTable(int warmupSets, int workingSets, String repRange, double? weight, Color elevated, Color glassSurface, Color cardBorder, Color textPrimary, Color textMuted, Color textSecondary) {
    final hasPrevious = _previousSets.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('SET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5))),
                if (hasPrevious)
                  SizedBox(width: 80, child: Center(child: Text('PREVIOUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)))),
                Expanded(child: Center(child: Text('LBS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)))),
                SizedBox(width: 70, child: Center(child: Text('REPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5)))),
              ],
            ),
          ),

          // Warmup rows
          ...List.generate(warmupSets, (i) {
            final previous = _getPreviousSet(i + 1, true);
            return _buildTableRow(
              setLabel: 'W',
              setIndex: i + 1,
              isWarmup: true,
              weight: null,
              repRange: repRange,
              previousDisplay: _formatPreviousSet(previous),
              hasPrevious: hasPrevious,
              isLast: false,
              glassSurface: glassSurface,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
              textSecondary: textSecondary,
            );
          }),

          // Working set rows
          ...List.generate(workingSets, (i) {
            final previous = _getPreviousSet(i + 1, false);
            return _buildTableRow(
              setLabel: '${i + 1}',
              setIndex: i + 1,
              isWarmup: false,
              weight: weight,
              repRange: repRange,
              previousDisplay: _formatPreviousSet(previous),
              hasPrevious: hasPrevious,
              isLast: i == workingSets - 1,
              glassSurface: glassSurface,
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
    required int setIndex,
    required bool isWarmup,
    double? weight,
    required String repRange,
    required String previousDisplay,
    required bool hasPrevious,
    required bool isLast,
    required Color glassSurface,
    required Color cardBorder,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cardBorder.withOpacity(0.2),
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
            width: 40,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isWarmup
                    ? AppColors.orange.withOpacity(0.2)
                    : AppColors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  setLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isWarmup ? AppColors.orange : AppColors.cyan,
                  ),
                ),
              ),
            ),
          ),

          // Previous performance (only show if we have previous data)
          if (hasPrevious)
            SizedBox(
              width: 80,
              child: Center(
                child: Text(
                  previousDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: previousDisplay == '-' ? textMuted : textSecondary,
                    fontWeight: previousDisplay != '-' ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ),

          // Weight
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: glassSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  weight != null ? '${weight.toInt()}' : '-',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: weight != null ? textPrimary : textMuted,
                  ),
                ),
              ),
            ),
          ),

          // Rep range
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                repRange,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
