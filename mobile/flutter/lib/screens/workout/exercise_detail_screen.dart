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

  @override
  void initState() {
    super.initState();
    _loadMediaAndAutoplay();
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

      // Load image first
      try {
        final imageResponse = await apiClient.get(
          '/exercise-images/${Uri.encodeComponent(exerciseName)}',
        );
        if (imageResponse.statusCode == 200 && imageResponse.data != null) {
          _imageUrl = imageResponse.data['url'] as String?;
        }
      } catch (_) {}

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

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: CustomScrollView(
        slivers: [
          // App bar with video
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.pureBlack,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildVideoSection(),
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
                              color: AppColors.glassSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exercise.equipment!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Instructions
                  if (exercise.instructions != null &&
                      exercise.instructions!.isNotEmpty)
                    _buildInstructionsSection(exercise.instructions!),

                  // Rest Timer Card
                  _buildRestTimerCard(restSeconds),
                  const SizedBox(height: 24),

                  // Set table header
                  const Text(
                    'SETS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Set table
                  _buildSetTable(warmupSets, totalSets, repRange, exercise.weight),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return GestureDetector(
      onTap: _toggleVideo,
      child: Container(
        color: AppColors.elevated,
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
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

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

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.elevated,
      child: const Center(
        child: Icon(
          Icons.fitness_center,
          size: 64,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(String instructions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
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
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerCard(int defaultSeconds) {
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
          color: _isResting ? null : AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: _isResting
              ? Border.all(color: AppColors.purple.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: _isResting ? AppColors.purple : AppColors.textMuted,
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
                      color: _isResting ? AppColors.purple : AppColors.textMuted,
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
                      color: _isResting ? AppColors.purple : AppColors.textPrimary,
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

  Widget _buildSetTable(int warmupSets, int workingSets, String repRange, double? weight) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 50, child: Text('SET', style: _headerStyle)),
                Expanded(child: Center(child: Text('LBS', style: _headerStyle))),
                SizedBox(width: 80, child: Center(child: Text('REP RANGE', style: _headerStyle))),
              ],
            ),
          ),

          // Warmup rows
          ...List.generate(warmupSets, (i) => _buildTableRow(
            setLabel: 'W',
            isWarmup: true,
            weight: null,
            repRange: repRange,
            isLast: false,
          )),

          // Working set rows
          ...List.generate(workingSets, (i) => _buildTableRow(
            setLabel: '${i + 1}',
            isWarmup: false,
            weight: weight,
            repRange: repRange,
            isLast: i == workingSets - 1,
          )),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String setLabel,
    required bool isWarmup,
    double? weight,
    required String repRange,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.cardBorder.withOpacity(0.2),
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
            width: 50,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isWarmup
                    ? AppColors.orange.withOpacity(0.2)
                    : AppColors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  setLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isWarmup ? AppColors.orange : AppColors.cyan,
                  ),
                ),
              ),
            ),
          ),

          // Weight
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  weight != null ? '${weight.toInt()}' : '-',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: weight != null ? AppColors.textPrimary : AppColors.textMuted,
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
                repRange,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );
}
