import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';

/// Result from the superset edit sheet
class SupersetEditResult {
  final List<WorkoutExercise> exercises;
  final List<WorkoutExercise> removedExercises;

  SupersetEditResult({
    required this.exercises,
    required this.removedExercises,
  });

  bool get hasChanges => removedExercises.isNotEmpty;
}

/// Shows a bottom sheet for editing exercises within a superset (reorder & remove)
Future<SupersetEditResult?> showSupersetEditSheet(
  BuildContext context, {
  required List<WorkoutExercise> exercises,
  required int groupNumber,
}) async {
  return await showModalBottomSheet<SupersetEditResult>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => _SupersetEditSheet(
      exercises: exercises,
      groupNumber: groupNumber,
    ),
  );
}

// Keep old function name for backward compatibility
Future<List<WorkoutExercise>?> showSupersetReorderSheet(
  BuildContext context, {
  required List<WorkoutExercise> exercises,
  required int groupNumber,
}) async {
  final result = await showSupersetEditSheet(
    context,
    exercises: exercises,
    groupNumber: groupNumber,
  );
  return result?.exercises;
}

class _SupersetEditSheet extends ConsumerStatefulWidget {
  final List<WorkoutExercise> exercises;
  final int groupNumber;

  const _SupersetEditSheet({
    required this.exercises,
    required this.groupNumber,
  });

  @override
  ConsumerState<_SupersetEditSheet> createState() => _SupersetEditSheetState();
}

class _SupersetEditSheetState extends ConsumerState<_SupersetEditSheet> {
  late List<WorkoutExercise> _orderedExercises;
  late List<WorkoutExercise> _originalOrder;
  final List<WorkoutExercise> _removedExercises = [];

  @override
  void initState() {
    super.initState();
    _orderedExercises = List.from(widget.exercises);
    _originalOrder = List.from(widget.exercises);
  }

  String get _typeLabel {
    return switch (_orderedExercises.length) {
      0 => 'Empty',
      1 => 'Single',
      2 => 'Superset',
      3 => 'Tri-Set',
      _ => 'Giant Set',
    };
  }

  String get _originalTypeLabel {
    return switch (_originalOrder.length) {
      2 => 'Superset',
      3 => 'Tri-Set',
      _ => 'Giant Set',
    };
  }

  void _onReorder(int oldIndex, int newIndex) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _orderedExercises.removeAt(oldIndex);
      _orderedExercises.insert(newIndex, item);
    });
  }

  void _removeExercise(int index) {
    if (_orderedExercises.length <= 2) {
      // Can't remove - would break the superset
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A superset needs at least 2 exercises'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      final removed = _orderedExercises.removeAt(index);
      _removedExercises.add(removed);
    });
  }

  void _resetChanges() {
    HapticFeedback.lightImpact();
    setState(() {
      _orderedExercises = List.from(_originalOrder);
      _removedExercises.clear();
    });
  }

  void _applyChanges() {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      SupersetEditResult(
        exercises: _orderedExercises,
        removedExercises: _removedExercises,
      ),
    );
  }

  bool get _hasOrderChanges {
    if (_orderedExercises.length != _originalOrder.length) return true;
    for (int i = 0; i < _orderedExercises.length; i++) {
      final current = _orderedExercises[i];
      final original = _originalOrder[i];
      final currentKey = current.id ?? current.name;
      final originalKey = original.id ?? original.name;
      if (currentKey != originalKey) {
        return true;
      }
    }
    return false;
  }

  bool get _hasRemovals => _removedExercises.isNotEmpty;

  bool get _hasChanges => _hasOrderChanges || _hasRemovals;

  String _getPositionLabel(int index) {
    return switch (index) {
      0 => '1st',
      1 => '2nd',
      2 => '3rd',
      _ => '${index + 1}th',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit $_originalTypeLabel ${widget.groupNumber}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                          ),
                          Text(
                            '${_orderedExercises.length} exercises${_hasRemovals ? ' (${_removedExercises.length} removed)' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasRemovals ? errorColor : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),

              // Instruction
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drag to reorder, swipe left to remove',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Exercise List with ReorderableListView
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: _orderedExercises.length,
                    onReorder: _onReorder,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final elevation = Tween<double>(begin: 0, end: 8)
                              .animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ))
                              .value;
                          return Material(
                            elevation: elevation,
                            borderRadius: BorderRadius.circular(12),
                            color: cardBackground,
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final exercise = _orderedExercises[index];
                      final isLast = index == _orderedExercises.length - 1;
                      final canRemove = _orderedExercises.length > 2;

                      return Column(
                        key: ValueKey(exercise.id ?? exercise.name),
                        children: [
                          Dismissible(
                            key: ValueKey('dismiss-${exercise.id ?? exercise.name}'),
                            direction: canRemove
                                ? DismissDirection.endToStart
                                : DismissDirection.none,
                            onDismissed: (_) => _removeExercise(index),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: errorColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.link_off,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Remove',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: _buildExerciseItem(
                              exercise: exercise,
                              index: index,
                              cardBackground: cardBackground,
                              glassSurface: glassSurface,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              textMuted: textMuted,
                              accentColor: accentColor,
                              canRemove: canRemove,
                              onRemove: () => _removeExercise(index),
                            ),
                          ),
                          // Show connector between exercises (not after last)
                          if (!isLast)
                            _buildConnector(accentColor, textMuted),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (_hasChanges) ...[
                        TextButton.icon(
                          onPressed: _resetChanges,
                          icon: Icon(Icons.refresh, size: 18, color: textMuted),
                          label: Text(
                            'Reset',
                            style: TextStyle(color: textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _hasChanges ? _applyChanges : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            disabledBackgroundColor: glassSurface,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _hasChanges ? Icons.check : Icons.check,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hasChanges ? 'Apply Changes' : 'No Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem({
    required WorkoutExercise exercise,
    required int index,
    required Color cardBackground,
    required Color glassSurface,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color accentColor,
    required bool canRemove,
    required VoidCallback onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getPositionLabel(index),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Exercise GIF
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: exercise.gifUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(
                        Icons.fitness_center,
                        color: textMuted,
                        size: 20,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.fitness_center,
                        color: textMuted,
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.fitness_center,
                      color: textMuted,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.muscleGroup ?? exercise.primaryMuscle ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: glassSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.drag_handle,
                  color: textMuted,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(Color accentColor, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_downward,
            size: 14,
            color: accentColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'No rest between',
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
