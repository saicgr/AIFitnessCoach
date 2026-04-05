import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

// ─────────────────────────────────────────────────────────────────
// String Extension
// ─────────────────────────────────────────────────────────────────

extension WorkoutDetailStringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────

class WorkoutDetailStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool useAnimatedFire;

  const WorkoutDetailStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.useAnimatedFire = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (useAnimatedFire)
              AnimatedFireIcon(size: 24, color: color)
            else
              Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Param Item (helper for parameters modal)
// ─────────────────────────────────────────────────────────────────

class ParamItem {
  final String label;
  final String value;

  ParamItem(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────────
// Animated Fire Icon - Flickering flame effect for calorie stat
// ─────────────────────────────────────────────────────────────────

class AnimatedFireIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedFireIcon({
    super.key,
    this.size = 24,
    this.color = const Color(0xFFF97316),
  });

  @override
  State<AnimatedFireIcon> createState() => _AnimatedFireIconState();
}

class _AnimatedFireIconState extends State<AnimatedFireIcon>
    with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late AnimationController _glowController;
  late Animation<double> _flickerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.95), weight: 1),
    ]).animate(_flickerController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _flickerController.repeat();
    _glowController.repeat();
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flickerController, _glowController]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.yellow.withValues(alpha: _flickerAnimation.value),
                    widget.color,
                    const Color(0xFFDC2626).withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: Icon(
                Icons.local_fire_department,
                size: widget.size,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Animated Hell Badge - Radiating glow for maximum intensity
// ─────────────────────────────────────────────────────────────────

class AnimatedHellBadge extends StatefulWidget {
  final String label;
  final String value;

  const AnimatedHellBadge({
    super.key,
    this.label = 'Difficulty',
    this.value = 'Hell',
  });

  @override
  State<AnimatedHellBadge> createState() => _AnimatedHellBadgeState();
}

class _AnimatedHellBadgeState extends State<AnimatedHellBadge>
    with TickerProviderStateMixin {
  static const Color hellRed = Color(0xFFEF4444);

  late AnimationController _glowController;
  late AnimationController _fireController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fireScaleAnimation;
  late Animation<double> _fireRotationAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fireController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.2), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _fireScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOut,
    ));

    _fireRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOut,
    ));

    _glowController.repeat();
    _fireController.repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _fireController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: hellRed.withValues(alpha: _glowAnimation.value),
                blurRadius: 8 + (_glowAnimation.value * 12),
                spreadRadius: _glowAnimation.value * 4,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hellRed.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hellRed.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: _fireRotationAnimation.value,
                  child: Transform.scale(
                    scale: _fireScaleAnimation.value,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.yellow,
                            Color(0xFFF97316),
                            hellRed,
                          ],
                          stops: [0.0, 0.4, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: hellRed.withValues(alpha: 0.8),
                      ),
                    ),
                    const Text(
                      'Hell',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hellRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exercise Display Item (for grouping supersets)
// ─────────────────────────────────────────────────────────────────

/// Display item for exercise list - either a single exercise or a superset group (2+ exercises)
class ExerciseDisplayItem {
  final bool isSuperset;
  final int? singleIndex;
  final List<int>? supersetIndices;
  final int? groupNumber;

  ExerciseDisplayItem.single({required int index})
      : isSuperset = false,
        singleIndex = index,
        supersetIndices = null,
        groupNumber = null;

  ExerciseDisplayItem.superset({
    required List<int> indices,
    required int group,
  })  : isSuperset = true,
        supersetIndices = indices,
        groupNumber = group,
        singleIndex = null;

  int? get firstIndex => supersetIndices?.isNotEmpty == true ? supersetIndices!.first : null;
  int? get secondIndex => supersetIndices != null && supersetIndices!.length > 1 ? supersetIndices![1] : null;
  int get exerciseCount => supersetIndices?.length ?? 0;
}

/// Groups exercises for display, grouping all superset exercises together (supports 2+ exercises)
List<ExerciseDisplayItem> groupExercisesForDisplay(List<WorkoutExercise> exercises) {
  final items = <ExerciseDisplayItem>[];
  final processed = <int>{};

  final supersetGroups = <int, List<int>>{};
  for (int i = 0; i < exercises.length; i++) {
    final ex = exercises[i];
    if (ex.isInSuperset) {
      supersetGroups.putIfAbsent(ex.supersetGroup!, () => []).add(i);
    }
  }

  for (final group in supersetGroups.values) {
    group.sort((a, b) =>
        (exercises[a].supersetOrder ?? 0).compareTo(exercises[b].supersetOrder ?? 0));
  }

  for (int i = 0; i < exercises.length; i++) {
    if (processed.contains(i)) continue;
    final ex = exercises[i];

    if (ex.isInSuperset && supersetGroups.containsKey(ex.supersetGroup)) {
      final groupIndices = supersetGroups[ex.supersetGroup]!;
      if (groupIndices.isNotEmpty) {
        items.add(ExerciseDisplayItem.superset(
          indices: List.from(groupIndices),
          group: ex.supersetGroup!,
        ));
        processed.addAll(groupIndices);
        continue;
      }
    }

    if (!ex.isInSuperset) {
      items.add(ExerciseDisplayItem.single(index: i));
      processed.add(i);
    }
  }
  return items;
}

// ─────────────────────────────────────────────────────────────────
// Equipment Change Analysis Helpers
// ─────────────────────────────────────────────────────────────────

class EquipmentChangeAnalysis {
  final List<ExerciseWeightAdjustment> weightAdjustments;
  final List<WorkoutExercise> exercisesToReplace;

  EquipmentChangeAnalysis({
    required this.weightAdjustments,
    required this.exercisesToReplace,
  });
}

class ExerciseWeightAdjustment {
  final WorkoutExercise exercise;
  final double oldWeight;
  final double newWeight;

  ExerciseWeightAdjustment({
    required this.exercise,
    required this.oldWeight,
    required this.newWeight,
  });
}

/// Progress dialog for quick exercise replacement
class QuickReplaceProgressDialog extends StatelessWidget {
  final int total;

  const QuickReplaceProgressDialog({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'Updating Exercises',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Replacing $total exercise${total > 1 ? 's' : ''} for available equipment...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
