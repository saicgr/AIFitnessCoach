/// Breathing Guide Sheet
///
/// Displays exercise-specific breathing patterns with
/// animated visuals to help users breathe correctly.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Breathing pattern types
enum BreathingPattern {
  push, // Press/push exercises - exhale on effort (pushing up)
  pull, // Row/pull exercises - exhale on effort (pulling)
  compound, // Squats/deadlifts - brace and controlled
  core, // Core exercises - exhale on contraction
  general, // Default pattern
}

/// Get breathing pattern for an exercise
BreathingPattern getBreathingPattern(WorkoutExercise exercise) {
  final name = exercise.name.toLowerCase();
  final bodyPart = exercise.bodyPart?.toLowerCase() ?? '';

  // Push exercises
  if (name.contains('press') ||
      name.contains('push') ||
      name.contains('fly') ||
      name.contains('dip') ||
      name.contains('extension') && bodyPart == 'triceps') {
    return BreathingPattern.push;
  }

  // Pull exercises
  if (name.contains('row') ||
      name.contains('pull') ||
      name.contains('curl') ||
      name.contains('pulldown') ||
      name.contains('chin') ||
      name.contains('lat')) {
    return BreathingPattern.pull;
  }

  // Compound leg exercises
  if (name.contains('squat') ||
      name.contains('deadlift') ||
      name.contains('lunge') ||
      name.contains('leg press') ||
      name.contains('hip thrust')) {
    return BreathingPattern.compound;
  }

  // Core exercises
  if (bodyPart == 'core' ||
      bodyPart == 'abs' ||
      bodyPart == 'waist' ||
      name.contains('crunch') ||
      name.contains('plank') ||
      name.contains('sit-up') ||
      name.contains('twist') ||
      name.contains('raise') && bodyPart.contains('core')) {
    return BreathingPattern.core;
  }

  return BreathingPattern.general;
}

/// Show breathing guide bottom sheet
Future<void> showBreathingGuide({
  required BuildContext context,
  required WorkoutExercise exercise,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => BreathingGuideSheet(exercise: exercise),
  );
}

/// Breathing guide sheet widget
class BreathingGuideSheet extends StatefulWidget {
  final WorkoutExercise exercise;

  const BreathingGuideSheet({
    super.key,
    required this.exercise,
  });

  @override
  State<BreathingGuideSheet> createState() => _BreathingGuideSheetState();
}

class _BreathingGuideSheetState extends State<BreathingGuideSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  bool _isInhaling = true;
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // 3s inhale + 3s exhale
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isInhaling = false);
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _isInhaling = true);
        _breathingController.forward();
      }
    });

    // Start with inhale
    _breathingController.forward();

    // Haptic feedback synced with breathing
    _startHapticFeedback();
  }

  void _startHapticFeedback() {
    _hapticTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pattern = getBreathingPattern(widget.exercise);
    final patternInfo = _getPatternInfo(pattern);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.air_rounded,
                color: AppColors.purple,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Breathing Guide',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Exercise name
          Text(
            widget.exercise.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.electricBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Animated breathing circle
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (_isInhaling ? AppColors.cyan : AppColors.purple)
                          .withOpacity(0.3),
                      (_isInhaling ? AppColors.cyan : AppColors.purple)
                          .withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: _isInhaling ? AppColors.cyan : AppColors.purple,
                    width: 3,
                  ),
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isInhaling
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: _isInhaling ? AppColors.cyan : AppColors.purple,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isInhaling ? 'INHALE' : 'EXHALE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                _isInhaling ? AppColors.cyan : AppColors.purple,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Pattern instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.elevated.withOpacity(0.5)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                _buildInstructionRow(
                  icon: Icons.arrow_downward_rounded,
                  phase: patternInfo.downPhase,
                  instruction: patternInfo.downInstruction,
                  color: AppColors.cyan,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildInstructionRow(
                  icon: Icons.arrow_upward_rounded,
                  phase: patternInfo.upPhase,
                  instruction: patternInfo.upInstruction,
                  color: AppColors.purple,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patternInfo.tip,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondary : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildInstructionRow({
    required IconData icon,
    required String phase,
    required String instruction,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phase,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                instruction,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _PatternInfo _getPatternInfo(BreathingPattern pattern) {
    switch (pattern) {
      case BreathingPattern.push:
        return _PatternInfo(
          downPhase: 'DOWN',
          downInstruction: 'Inhale (breathe in)',
          upPhase: 'UP',
          upInstruction: 'Exhale (breathe out)',
          tip:
              'Exhale on the push/press motion. This engages your core and provides stability.',
        );
      case BreathingPattern.pull:
        return _PatternInfo(
          downPhase: 'RELEASE',
          downInstruction: 'Inhale (breathe in)',
          upPhase: 'PULL',
          upInstruction: 'Exhale (breathe out)',
          tip:
              'Exhale as you pull the weight toward you. This helps engage your back muscles.',
        );
      case BreathingPattern.compound:
        return _PatternInfo(
          downPhase: 'BEFORE LIFT',
          downInstruction: 'Brace core, deep inhale',
          upPhase: 'AT TOP',
          upInstruction: 'Exhale and reset',
          tip:
              'For heavy compound lifts, take a deep breath and brace your core before the lift. Never hold your breath at the bottom!',
        );
      case BreathingPattern.core:
        return _PatternInfo(
          downPhase: 'RELEASE',
          downInstruction: 'Inhale (breathe in)',
          upPhase: 'CONTRACT',
          upInstruction: 'Exhale (breathe out)',
          tip:
              'Exhale during the contraction phase. This helps activate your core muscles more effectively.',
        );
      case BreathingPattern.general:
        return _PatternInfo(
          downPhase: 'ECCENTRIC',
          downInstruction: 'Inhale (breathe in)',
          upPhase: 'CONCENTRIC',
          upInstruction: 'Exhale (breathe out)',
          tip:
              'Breathe out during the effort phase. Never hold your breath under heavy weight.',
        );
    }
  }
}

class _PatternInfo {
  final String downPhase;
  final String downInstruction;
  final String upPhase;
  final String upInstruction;
  final String tip;

  _PatternInfo({
    required this.downPhase,
    required this.downInstruction,
    required this.upPhase,
    required this.upInstruction,
    required this.tip,
  });
}
