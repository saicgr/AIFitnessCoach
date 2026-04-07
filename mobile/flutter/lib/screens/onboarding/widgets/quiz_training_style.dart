import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Training style selection widget (Screen 8: Phase 2 personalization).
///
/// Allows user to select:
/// - Training split (AI Decide, PPL, Full Body, Upper/Lower, etc.)
/// - Workout type preference (Strength, Cardio, Mixed)
///
/// Shows compatibility warnings if split doesn't match days per week.
class QuizTrainingStyle extends StatefulWidget {
  final String? selectedSplit;
  final String? selectedWorkoutType;
  final String? selectedWorkoutVariety;  // 'consistent' or 'varied'
  final int daysPerWeek;
  final ValueChanged<String> onSplitChanged;
  final ValueChanged<String> onWorkoutTypeChanged;
  final ValueChanged<String>? onWorkoutVarietyChanged;
  final ValueChanged<int>? onDaysPerWeekChanged;
  final bool showHeader;
  final bool showSplitSection;

  const QuizTrainingStyle({
    super.key,
    required this.selectedSplit,
    required this.selectedWorkoutType,
    this.selectedWorkoutVariety,
    required this.daysPerWeek,
    required this.onSplitChanged,
    required this.onWorkoutTypeChanged,
    this.onWorkoutVarietyChanged,
    this.onDaysPerWeekChanged,
    this.showHeader = true,
    this.showSplitSection = true,
  });

  @override
  State<QuizTrainingStyle> createState() => _QuizTrainingStyleState();
}

class _QuizTrainingStyleState extends State<QuizTrainingStyle> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _scrollController.hasClients) {
        if (_scrollController.position.maxScrollExtent > 0) {
          // Keep showing indicator
        } else {
          setState(() => _showScrollIndicator = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 20 && _showScrollIndicator) {
      setState(() => _showScrollIndicator = false);
    } else if (_scrollController.offset <= 10 && !_showScrollIndicator) {
      if (_scrollController.position.maxScrollExtent > 50) {
        setState(() => _showScrollIndicator = true);
      }
    }
  }

  String _getRecommendedSplit() {
    if (widget.daysPerWeek <= 2) return 'full_body';
    if (widget.daysPerWeek == 3) return 'full_body';
    if (widget.daysPerWeek == 4) return 'upper_lower';
    return 'push_pull_legs';
  }

  int? _getRecommendedDaysForSplit(String? split) {
    if (split == null || split == 'ai_decide') return null;

    switch (split) {
      case 'full_body':
        return 3;
      case 'upper_lower':
        return 4;
      case 'phul':
        return 4;
      case 'push_pull_legs':
        return 6;
      case 'phat':
      case 'pplul':
        return 5;
      case 'body_part':
      case 'arnold_split':
        return 6;
      default:
        return null;
    }
  }

  bool get _isCompatible {
    if (widget.selectedSplit == null || widget.selectedSplit == 'ai_decide') return true;

    switch (widget.selectedSplit) {
      case 'full_body':
        return widget.daysPerWeek >= 2 && widget.daysPerWeek <= 4;
      case 'upper_lower':
      case 'phul':
        return widget.daysPerWeek >= 4 && widget.daysPerWeek <= 5;
      case 'push_pull_legs':
        return widget.daysPerWeek >= 3 && widget.daysPerWeek <= 6;
      case 'phat':
      case 'pplul':
        return widget.daysPerWeek == 5;
      case 'body_part':
      case 'arnold_split':
        return widget.daysPerWeek >= 5;
      default:
        return true;
    }
  }

  String _getSplitName(String splitId) {
    switch (splitId) {
      case 'ai_decide':
        return 'AI Decide';
      case 'push_pull_legs':
        return 'PPL';
      case 'full_body':
        return 'Full Body';
      case 'upper_lower':
        return 'Upper/Lower';
      case 'phul':
        return 'PHUL';
      case 'phat':
        return 'PHAT';
      case 'pplul':
        return 'PPLUL';
      case 'body_part':
        return 'Body Part Split';
      case 'arnold_split':
        return 'Arnold Split';
      default:
        return splitId;
    }
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Colors.white;
    final textSecondary = Colors.white.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) ...[
                const Text(
                  'Training Style',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to structure your workouts',
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
              ],

              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                if (widget.showSplitSection) ...[
                const Text(
                  'Training Split',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _buildSplitOption(
                  id: 'ai_decide',
                  title: 'Let AI Decide',
                  description: 'Automatically optimized for your schedule (Recommended)',
                  recommended: true,
                  delay: 300.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'push_pull_legs',
                  title: 'Push / Pull / Legs (PPL)',
                  description: 'Best for 5-6 days/week',
                  delay: 350.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'full_body',
                  title: 'Full Body',
                  description: 'Train all muscles each workout (2-4 days)',
                  delay: 400.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'upper_lower',
                  title: 'Upper / Lower',
                  description: 'Split between upper and lower body (4 days)',
                  delay: 450.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'phul',
                  title: 'PHUL',
                  description: 'Power + Hypertrophy, Upper + Lower (4 days)',
                  delay: 500.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'phat',
                  title: 'PHAT',
                  description: 'Power Hypertrophy Adaptive Training (5 days)',
                  delay: 550.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'pplul',
                  title: 'PPLUL',
                  description: 'Push/Pull/Legs/Upper/Lower (5 days)',
                  delay: 600.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'body_part',
                  title: 'Body Part Split',
                  description: 'One muscle group per day (5+ days)',
                  delay: 650.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'arnold_split',
                  title: 'Arnold Split',
                  description: 'Chest/Back, Shoulders/Arms, Legs (6 days)',
                  delay: 700.ms,
                ),

                // Compatibility warning with fix button
                if (!_isCompatible) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Schedule conflict',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getSplitName(widget.selectedSplit!) +
                              ' requires ${_getRecommendedDaysForSplit(widget.selectedSplit)} days/week, but you selected ${widget.daysPerWeek} days/week.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.onDaysPerWeekChanged != null)
                              SizedBox(
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          final recommended = _getRecommendedDaysForSplit(widget.selectedSplit);
                                          if (recommended != null) {
                                            widget.onDaysPerWeekChanged!(recommended);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withValues(alpha: 0.22),
                                                Colors.white.withValues(alpha: 0.12),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.auto_fix_high_rounded, size: 18, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Update to ${_getRecommendedDaysForSplit(widget.selectedSplit)} days/week',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().shake(delay: 600.ms),
                ],

                const SizedBox(height: 32),
                ],

                // Section B: Workout Type
                const Text(
                  'Workout Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTypeChip('strength', 'Strength', 650.ms),
                    _buildTypeChip('cardio', 'Cardio', 700.ms),
                    _buildTypeChip('mixed', 'Mixed', 750.ms),
                  ],
                ),

                // Section C: Exercise Variety
                if (widget.onWorkoutVarietyChanged != null) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'Exercise Variety',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Do you prefer the same exercises each week or variety?',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildVarietyChip('consistent', 'Consistent', 'Same exercises for progress tracking', Icons.repeat, 800.ms),
                      _buildVarietyChip('varied', 'Varied', 'Different exercises to keep it fresh', Icons.shuffle, 850.ms),
                    ],
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

          // Simple floating scroll indicator
          if (_showScrollIndicator)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 24,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeIn(duration: 400.ms)
                      .then()
                      .slideY(begin: 0, end: 0.3, duration: 800.ms, curve: Curves.easeInOut)
                      .then()
                      .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeInOut),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitOption({
    required String id,
    required String title,
    required String description,
    bool recommended = false,
    required Duration delay,
  }) {
    final isSelected = widget.selectedSplit == id;
    final textSecondary = Colors.white.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onSplitChanged(id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Color(0xFF0D9488))
                      : null,
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'BEST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }

  Widget _buildTypeChip(String id, String label, Duration delay) {
    final isSelected = widget.selectedWorkoutType == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onWorkoutTypeChanged(id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildVarietyChip(String id, String label, String description, IconData icon, Duration delay) {
    final isSelected = widget.selectedWorkoutVariety == id;
    final textSecondary = Colors.white.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onWorkoutVarietyChanged?.call(id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : textSecondary,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).scale(begin: const Offset(0.9, 0.9));
  }
}
