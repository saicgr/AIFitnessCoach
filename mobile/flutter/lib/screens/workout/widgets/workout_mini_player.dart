/// Workout Mini Player Widget
///
/// YouTube-style floating mini player that appears when a workout is minimized.
/// Shows timer, current exercise, and progress. Tap to restore full workout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/workout_mini_player_provider.dart';
import '../../../core/theme/theme_colors.dart';

/// Position options for the mini player
enum MiniPlayerPosition {
  bottomLeft,
  bottomRight,
}

/// Floating mini player for minimized workouts
class WorkoutMiniPlayer extends ConsumerStatefulWidget {
  /// Callback when mini player is tapped (to restore)
  final VoidCallback onTap;

  /// Callback when close button is tapped
  final VoidCallback onClose;

  /// Initial position
  final MiniPlayerPosition initialPosition;

  const WorkoutMiniPlayer({
    super.key,
    required this.onTap,
    required this.onClose,
    this.initialPosition = MiniPlayerPosition.bottomRight,
  });

  @override
  ConsumerState<WorkoutMiniPlayer> createState() => _WorkoutMiniPlayerState();
}

class _WorkoutMiniPlayerState extends ConsumerState<WorkoutMiniPlayer>
    with SingleTickerProviderStateMixin {
  late MiniPlayerPosition _currentPosition;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  EdgeInsets _safeArea = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Offset _getPosition(MiniPlayerPosition position, Size screenSize, double width) {
    const padding = 16.0;
    final bottomPadding = _safeArea.bottom + 90; // Above floating nav bar

    switch (position) {
      case MiniPlayerPosition.bottomLeft:
        return Offset(padding, screenSize.height - 72 - bottomPadding);
      case MiniPlayerPosition.bottomRight:
        return Offset(
          screenSize.width - width - padding,
          screenSize.height - 72 - bottomPadding,
        );
    }
  }

  MiniPlayerPosition _getNearestPosition(Offset currentPos, Size screenSize) {
    final centerX = screenSize.width / 2;
    return currentPos.dx < centerX
        ? MiniPlayerPosition.bottomLeft
        : MiniPlayerPosition.bottomRight;
  }

  void _onDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width - 32; // Full width minus padding
    final currentPos = _getPosition(_currentPosition, screenSize, width) + _dragOffset;
    final nearestPos = _getNearestPosition(currentPos, screenSize);

    setState(() {
      _currentPosition = nearestPos;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
    _animationController.reverse();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutMiniPlayerProvider);

    if (!state.isMinimized) return const SizedBox.shrink();

    _safeArea = MediaQuery.of(context).padding;
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width - 32; // Full width minus padding

    final basePosition = _getPosition(_currentPosition, screenSize, width);
    final position = basePosition + _dragOffset;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: _buildMiniPlayer(state, width),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(WorkoutMiniPlayerState state, double width) {
    final colors = ref.colors(context);
    final isDark = context.isDarkMode;

    // Use a grayer surface for dark mode (not pitch black)
    final backgroundColor = isDark
        ? const Color(0xFF2A2A2A) // Softer gray for dark mode
        : colors.elevated;

    final borderColor = _isDragging
        ? colors.accent.withAlpha(150)
        : colors.cardBorder;

    final shadowColor = _isDragging
        ? colors.accent.withAlpha(50)
        : Colors.black.withAlpha(75);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: 64,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: _isDragging ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: _isDragging ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Exercise thumbnail
                _buildExerciseThumbnail(state, colors),

                const SizedBox(width: 10),

                // Timer with icon
                _buildTimerSection(state, colors),

                const SizedBox(width: 10),

                // Vertical divider
                Container(
                  width: 1,
                  height: 32,
                  color: colors.cardBorder,
                ),

                const SizedBox(width: 10),

                // Exercise info (expandable)
                Expanded(
                  child: _buildExerciseInfo(state, colors),
                ),

                const SizedBox(width: 8),

                // Pause/Play button
                _buildPlayPauseButton(state, colors),

                const SizedBox(width: 4),

                // Close button
                _buildCloseButton(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseThumbnail(WorkoutMiniPlayerState state, ThemeColors colors) {
    final hasImage = state.currentExerciseImageUrl != null &&
        state.currentExerciseImageUrl!.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.accent.withAlpha(75),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: state.currentExerciseImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildThumbnailPlaceholder(colors),
              errorWidget: (context, url, error) => _buildThumbnailPlaceholder(colors),
            )
          : _buildThumbnailPlaceholder(colors),
    );
  }

  Widget _buildThumbnailPlaceholder(ThemeColors colors) {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: 20,
        color: colors.textMuted,
      ),
    );
  }

  Widget _buildTimerSection(WorkoutMiniPlayerState state, ThemeColors colors) {
    final timerColor = state.isPaused ? AppColors.orange : colors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          state.isPaused ? Icons.pause : Icons.timer_outlined,
          size: 18,
          color: timerColor,
        ),
        const SizedBox(width: 6),
        Text(
          state.formattedTime,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: state.isPaused ? AppColors.orange : colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseInfo(WorkoutMiniPlayerState state, ThemeColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise name
        Text(
          state.currentExerciseName ?? 'Workout',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // Progress indicator - use Flexible to prevent overflow
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${state.currentExerciseIndex + 1}/${state.totalExercises}',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (state.isResting) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.accent.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${state.restSecondsRemaining}s',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(WorkoutMiniPlayerState state, ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(workoutMiniPlayerProvider.notifier).togglePause();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.accent.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          size: 22,
          color: colors.accent,
        ),
      ),
    );
  }

  Widget _buildCloseButton(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showCloseConfirmation(colors);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 20,
          color: Colors.red,
        ),
      ),
    );
  }

  void _showCloseConfirmation(ThemeColors colors) {
    final isDark = context.isDarkMode;
    final dialogBg = isDark ? const Color(0xFF2A2A2A) : colors.elevated;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'End Workout?',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'Your workout progress will not be saved.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onClose();
            },
            child: const Text(
              'End Workout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
