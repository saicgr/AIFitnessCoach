/// Workout Plan Drawer
///
/// Full workout plan view with reorderable exercises.
/// Opened via up arrow in set tracking header.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Show the workout plan drawer as a bottom sheet
Future<void> showWorkoutPlanDrawer({
  required BuildContext context,
  required List<WorkoutExercise> exercises,
  required int currentExerciseIndex,
  required Map<int, int> completedSetsPerExercise,
  required Map<int, int> totalSetsPerExercise,
  required Function(int) onJumpToExercise,
  required Function(List<WorkoutExercise>) onReorder,
  required Function(int) onSwapExercise,
  required Function(int) onDeleteExercise,
  required VoidCallback onAddExercise,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WorkoutPlanDrawer(
      exercises: exercises,
      currentExerciseIndex: currentExerciseIndex,
      completedSetsPerExercise: completedSetsPerExercise,
      totalSetsPerExercise: totalSetsPerExercise,
      onJumpToExercise: onJumpToExercise,
      onReorder: onReorder,
      onSwapExercise: onSwapExercise,
      onDeleteExercise: onDeleteExercise,
      onAddExercise: onAddExercise,
    ),
  );
}

/// Workout plan drawer widget
class WorkoutPlanDrawer extends StatefulWidget {
  final List<WorkoutExercise> exercises;
  final int currentExerciseIndex;
  final Map<int, int> completedSetsPerExercise;
  final Map<int, int> totalSetsPerExercise;
  final Function(int) onJumpToExercise;
  final Function(List<WorkoutExercise>) onReorder;
  final Function(int) onSwapExercise;
  final Function(int) onDeleteExercise;
  final VoidCallback onAddExercise;

  const WorkoutPlanDrawer({
    super.key,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.completedSetsPerExercise,
    required this.totalSetsPerExercise,
    required this.onJumpToExercise,
    required this.onReorder,
    required this.onSwapExercise,
    required this.onDeleteExercise,
    required this.onAddExercise,
  });

  @override
  State<WorkoutPlanDrawer> createState() => _WorkoutPlanDrawerState();
}

class _WorkoutPlanDrawerState extends State<WorkoutPlanDrawer> {
  late List<WorkoutExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.exercises);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
    HapticFeedback.mediumImpact();
    widget.onReorder(_exercises);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.nearBlack : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt_rounded,
                  color: AppColors.cyan,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Workout Plan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_exercises.length} exercises',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),

          // Exercise list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _exercises.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final animValue = Curves.easeInOut.transform(animation.value);
                    final elevation = 8.0 * animValue;
                    return Material(
                      elevation: elevation,
                      color: Colors.transparent,
                      shadowColor: AppColors.cyan.withOpacity(0.3),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                final isCurrent = index == widget.currentExerciseIndex;
                final isCompleted = index < widget.currentExerciseIndex;
                final completedSets = widget.completedSetsPerExercise[index] ?? 0;
                final totalSets = widget.totalSetsPerExercise[index] ?? exercise.sets ?? 3;
                final allSetsComplete = completedSets >= totalSets;

                return _ExerciseRow(
                  key: ValueKey(exercise.id ?? index),
                  exercise: exercise,
                  index: index,
                  isCurrent: isCurrent,
                  isCompleted: isCompleted || allSetsComplete,
                  completedSets: completedSets,
                  totalSets: totalSets,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onJumpToExercise(index);
                    Navigator.pop(context);
                  },
                  onSwap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    widget.onSwapExercise(index);
                  },
                  onDelete: () => _confirmDelete(context, exercise, index, isDark),
                );
              },
            ),
          ),

          // Add exercise FAB area
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    widget.onAddExercise();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Exercise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WorkoutExercise exercise,
    int index,
    bool isDark,
  ) {
    final completedSets = widget.completedSetsPerExercise[index] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove ${exercise.name}?',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: completedSets > 0
            ? Text(
                'You have $completedSets set${completedSets > 1 ? 's' : ''} logged. They will be deleted.',
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              widget.onDeleteExercise(index);
              HapticFeedback.heavyImpact();
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual exercise row in the drawer
class _ExerciseRow extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isCurrent;
  final bool isCompleted;
  final int completedSets;
  final int totalSets;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onSwap;
  final VoidCallback onDelete;

  const _ExerciseRow({
    super.key,
    required this.exercise,
    required this.index,
    required this.isCurrent,
    required this.isCompleted,
    required this.completedSets,
    required this.totalSets,
    required this.isDark,
    required this.onTap,
    required this.onSwap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    // Compact mode for narrow screens
    final isCompact = screenWidth < 360;

    // Determine colors
    Color borderColor;
    Color bgColor;
    if (isCurrent) {
      borderColor = AppColors.electricBlue;
      bgColor = AppColors.electricBlue.withOpacity(0.08);
    } else if (isCompleted) {
      borderColor = AppColors.success.withOpacity(0.5);
      bgColor = AppColors.success.withOpacity(0.05);
    } else {
      borderColor = Colors.transparent;
      bgColor = Colors.transparent;
    }

    // Use Dismissible for swipe-to-delete functionality
    return Dismissible(
      key: ValueKey(exercise.id ?? index),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Show confirmation before delete
        onDelete();
        return false; // We handle deletion ourselves
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16, vertical: 4),
          padding: EdgeInsets.all(isCompact ? 8 : 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(right: isCompact ? 8 : 12),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: isCompact ? 20 : 24,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : Colors.black.withOpacity(0.3),
                  ),
                ),
              ),

              // Thumbnail
              Container(
                width: isCompact ? 40 : 50,
                height: isCompact ? 40 : 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? CachedNetworkImage(
                            imageUrl: exercise.gifUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildPlaceholder(isCompact),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(isCompact),
                          )
                        : _buildPlaceholder(isCompact),
                    // Completed overlay
                    if (isCompleted)
                      Container(
                        color: AppColors.success.withOpacity(0.8),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: isCompact ? 20 : 28,
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(width: isCompact ? 8 : 12),

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: isCompact ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? (isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.5))
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Current badge
                        if (isCurrent)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 6 : 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCompact ? 'Now' : 'Current',
                              style: TextStyle(
                                fontSize: isCompact ? 9 : 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Set progress
                    Text(
                      'Set $completedSets/$totalSets${exercise.weight != null && !isCompact ? ' • ${exercise.weight?.toStringAsFixed(0)}kg × ${exercise.reps}' : ''}',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 13,
                        color: isCompleted
                            ? AppColors.success
                            : (isDark
                                ? AppColors.textMuted
                                : AppColorsLight.textMuted),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action buttons - smaller on compact screens
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Swap button
                  IconButton(
                    onPressed: onSwap,
                    padding: isCompact ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
                    constraints: isCompact
                        ? const BoxConstraints(minWidth: 32, minHeight: 32)
                        : null,
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      size: isCompact ? 18 : 20,
                      color: AppColors.purple,
                    ),
                    tooltip: 'Swap exercise',
                  ),
                  // Delete button
                  IconButton(
                    onPressed: onDelete,
                    padding: isCompact ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
                    constraints: isCompact
                        ? const BoxConstraints(minWidth: 32, minHeight: 32)
                        : null,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: isCompact ? 18 : 20,
                      color: AppColors.error.withOpacity(0.7),
                    ),
                    tooltip: 'Remove exercise',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder([bool isCompact = false]) {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: isCompact ? 18 : 24,
        color: isDark
            ? Colors.white.withOpacity(0.3)
            : Colors.black.withOpacity(0.2),
      ),
    );
  }
}
