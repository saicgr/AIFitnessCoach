import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';

/// Expanded exercise card that shows the SET/LBS/REP table inline
/// Tapping opens the full exercise detail screen with autoplay video
class ExpandedExerciseCard extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final int index;
  final String workoutId;
  final VoidCallback? onTap;
  final VoidCallback? onSwap;

  const ExpandedExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.workoutId,
    this.onTap,
    this.onSwap,
  });

  @override
  ConsumerState<ExpandedExerciseCard> createState() => _ExpandedExerciseCardState();
}

class _ExpandedExerciseCardState extends ConsumerState<ExpandedExerciseCard> {
  String? _imageUrl;
  bool _isLoadingImage = true;
  static final Map<String, String> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingImage = false);
      return;
    }

    final cacheKey = exerciseName.toLowerCase();
    if (_imageCache.containsKey(cacheKey)) {
      setState(() {
        _imageUrl = _imageCache[cacheKey];
        _isLoadingImage = false;
      });
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          _imageCache[cacheKey] = url;
          setState(() {
            _imageUrl = url;
            _isLoadingImage = false;
          });
          return;
        }
      }
    } catch (e) {
      // Image not found
    }

    if (mounted) {
      setState(() => _isLoadingImage = false);
    }
  }

  String _getRepRange() {
    if (widget.exercise.reps != null) {
      final reps = widget.exercise.reps!;
      if (reps <= 6) return '${reps - 1}-${reps + 1}';
      if (reps <= 12) return '${reps - 2}-${reps + 2}';
      return '${reps - 3}-${reps + 3}';
    } else if (widget.exercise.durationSeconds != null) {
      return '${widget.exercise.durationSeconds}s';
    }
    return '8-12';
  }

  String _formatRestTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0 && secs > 0) return '${mins}m ${secs}s';
    if (mins > 0) return '${mins}m';
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final totalSets = exercise.sets ?? 3;
    final warmupSets = 2; // Default 2 warmup sets
    final repRange = _getRepRange();
    final restSeconds = exercise.restSeconds ?? 90;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder.withOpacity(0.3),
          ),
        ),
        child: Material(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Image + Exercise Name + Actions (TAPPABLE)
            _buildHeader(context, exercise),

            // Divider
            Divider(
              color: AppColors.cardBorder.withOpacity(0.3),
              height: 1,
            ),

            // Rest Timer Row
            _buildRestTimerRow(restSeconds),

            // Divider
            Divider(
              color: AppColors.cardBorder.withOpacity(0.3),
              height: 1,
            ),

            // Set Table Header
            _buildTableHeader(),

            // Set Rows
            ...List.generate(warmupSets, (i) => _buildSetRow(
              setLabel: 'W',
              isWarmup: true,
              weight: null,
              repRange: repRange,
            )),
            ...List.generate(totalSets, (i) => _buildSetRow(
              setLabel: '${i + 1}',
              isWarmup: false,
              weight: exercise.weight,
              repRange: repRange,
            )),

            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkoutExercise exercise) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        print('🎯 [ExerciseCard] Header tapped: ${widget.exercise.name}');
        widget.onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Exercise Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: _buildImage(),
            ),
            const SizedBox(width: 12),

            // Exercise Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 12,
                        color: AppColors.cyan.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap for video & details',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.cyan.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Swap button (separate - has its own onPressed)
            if (widget.onSwap != null)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: AppColors.cyan,
                  ),
                ),
                onPressed: widget.onSwap,
                tooltip: 'Swap exercise',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoadingImage) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.cyan,
          ),
        ),
      );
    }

    if (_imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: _imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.glassSurface,
      child: const Icon(
        Icons.fitness_center,
        color: AppColors.textMuted,
        size: 28,
      ),
    );
  }

  Widget _buildRestTimerRow(int seconds) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 18,
            color: AppColors.purple,
          ),
          const SizedBox(width: 8),
          const Text(
            'Rest Timer:',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatRestTime(seconds),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassSurface.withOpacity(0.5),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              'SET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
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
                  color: AppColors.textMuted,
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
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow({
    required String setLabel,
    required bool isWarmup,
    double? weight,
    required String repRange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 50,
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

          // Weight
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  weight != null ? '${weight.toInt()}' : '-',
                  style: TextStyle(
                    fontSize: 15,
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
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
