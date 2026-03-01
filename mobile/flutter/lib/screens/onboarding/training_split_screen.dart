import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/training_preferences_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/foldable_quiz_scaffold.dart';

/// Training Split Selection Screen - shown after weight projection, before AI consent.
/// Lets the user pick their preferred training split (PPL, Full Body, etc.)
/// or let the AI decide automatically.
class TrainingSplitScreen extends ConsumerStatefulWidget {
  const TrainingSplitScreen({super.key});

  @override
  ConsumerState<TrainingSplitScreen> createState() => _TrainingSplitScreenState();
}

class _TrainingSplitScreenState extends ConsumerState<TrainingSplitScreen> {
  String? _selectedSplit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing selection from pre-auth quiz data
    final quizData = ref.read(preAuthQuizProvider);
    _selectedSplit = quizData.trainingSplit;
  }

  int get _daysPerWeek {
    final quizData = ref.read(preAuthQuizProvider);
    return quizData.daysPerWeek ?? 4;
  }

  /// Get recommended days per week for selected split
  int? _getRecommendedDaysForSplit(String? split) {
    if (split == null || split == 'ai_decide') return null;
    switch (split) {
      case 'full_body':
        return 3;
      case 'upper_lower':
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

  /// Check if selected split is compatible with days per week
  bool get _isCompatible {
    if (_selectedSplit == null || _selectedSplit == 'ai_decide') return true;
    switch (_selectedSplit) {
      case 'full_body':
        return _daysPerWeek >= 2 && _daysPerWeek <= 4;
      case 'upper_lower':
      case 'phul':
        return _daysPerWeek >= 4 && _daysPerWeek <= 5;
      case 'push_pull_legs':
        return _daysPerWeek >= 3 && _daysPerWeek <= 6;
      case 'phat':
      case 'pplul':
        return _daysPerWeek == 5;
      case 'body_part':
      case 'arnold_split':
        return _daysPerWeek >= 5;
      default:
        return true;
    }
  }

  /// Get friendly name for split ID
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

  Future<void> _continueToNextScreen() async {
    if (_isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final split = _selectedSplit ?? 'ai_decide';

      // Save to pre-auth quiz provider (SharedPreferences)
      await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(split);

      // Also sync to backend via training preferences provider
      await ref.read(trainingPreferencesProvider.notifier).setTrainingSplit(split);

      debugPrint('   [TrainingSplit] Saved split: $split');

      if (mounted) {
        context.go('/ai-consent');
      }
    } catch (e) {
      debugPrint('   [TrainingSplit] Error saving split: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    // Default to AI Decide when skipping
    ref.read(preAuthQuizProvider.notifier).setTrainingSplit('ai_decide');
    ref.read(trainingPreferencesProvider.notifier).setTrainingSplit('ai_decide');
    debugPrint('   [TrainingSplit] Skipped - defaulting to ai_decide');
    context.go('/ai-consent');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.pureBlack,
                    AppColors.pureBlack.withValues(alpha: 0.95),
                    const Color(0xFF0D0D1A),
                  ]
                : [
                    AppColorsLight.pureWhite,
                    AppColorsLight.pureWhite.withValues(alpha: 0.95),
                    const Color(0xFFF5F5FA),
                  ],
          ),
        ),
        child: SafeArea(
          child: FoldableQuizScaffold(
            headerTitle: 'Training Split',
            headerSubtitle: 'How do you want to structure your workouts?',
            headerExtra: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.white, size: 26),
            ),
            progressBar: _buildProgressIndicator(isDark),
            content: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show header inline only on phone
                  Consumer(builder: (context, ref, _) {
                    final windowState = ref.watch(windowModeProvider);
                    if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildHeader(isDark, textPrimary, textSecondary),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Days per week info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.cyan : AppColorsLight.cyan).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? AppColors.cyan : AppColorsLight.cyan).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'You selected $_daysPerWeek days/week',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),

                  // Split options
                  _buildSplitOption(
                    id: 'ai_decide',
                    title: 'Let AI Decide',
                    description: 'Automatically optimized for your schedule (Recommended)',
                    recommended: true,
                    isDark: isDark,
                    delay: 250.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'push_pull_legs',
                    title: 'Push / Pull / Legs (PPL)',
                    description: 'Best for 5-6 days/week',
                    isDark: isDark,
                    delay: 300.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'full_body',
                    title: 'Full Body',
                    description: 'Train all muscles each workout (2-4 days)',
                    isDark: isDark,
                    delay: 350.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'upper_lower',
                    title: 'Upper / Lower',
                    description: 'Split between upper and lower body (4 days)',
                    isDark: isDark,
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'phul',
                    title: 'PHUL',
                    description: 'Power + Hypertrophy, Upper + Lower (4 days)',
                    isDark: isDark,
                    delay: 450.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'phat',
                    title: 'PHAT',
                    description: 'Power Hypertrophy Adaptive Training (5 days)',
                    isDark: isDark,
                    delay: 500.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'pplul',
                    title: 'PPLUL',
                    description: 'Push/Pull/Legs/Upper/Lower (5 days)',
                    isDark: isDark,
                    delay: 550.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'body_part',
                    title: 'Body Part Split',
                    description: 'One muscle group per day (5+ days)',
                    isDark: isDark,
                    delay: 600.ms,
                  ),
                  const SizedBox(height: 12),
                  _buildSplitOption(
                    id: 'arnold_split',
                    title: 'Arnold Split',
                    description: 'Chest/Back, Shoulders/Arms, Legs (6 days)',
                    isDark: isDark,
                    delay: 650.ms,
                  ),

                  // Compatibility warning
                  if (!_isCompatible) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
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
                            '${_getSplitName(_selectedSplit!)} requires ${_getRecommendedDaysForSplit(_selectedSplit)} days/week, but you selected $_daysPerWeek days/week.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final recommended = _getRecommendedDaysForSplit(_selectedSplit);
                                if (recommended != null) {
                                  await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(recommended);
                                  setState(() {});
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_fix_high_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Update to ${_getRecommendedDaysForSplit(_selectedSplit)} days/week',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().shake(delay: 300.ms),
                  ],

                  const SizedBox(height: 24),

                  // Skip option
                  Center(
                    child: GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Skip - Let AI Decide',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: textSecondary,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
            button: _buildContinueButton(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Split',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'How do you want to structure your workouts?',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: -0.1),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    const orange = Color(0xFFF97316);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepDot(1, 'Sign In', true, orange, isDark),
              Expanded(child: Container(height: 2, color: orange)),
              _buildStepDot(2, 'About You', true, orange, isDark),
              Expanded(child: Container(height: 2, color: orange)),
              _buildStepDot(3, 'Split', true, orange, isDark),
              Expanded(
                child: Container(
                  height: 2,
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                ),
              ),
              _buildStepDot(4, 'Privacy', false, orange, isDark),
              Expanded(
                child: Container(
                  height: 2,
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                ),
              ),
              _buildStepDot(5, 'Coach', false, orange, isDark),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor, bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? activeColor : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete ? activeColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              width: 2,
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isComplete ? activeColor : textSecondary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitOption({
    required String id,
    required String title,
    required String description,
    bool recommended = false,
    required bool isDark,
    required Duration delay,
  }) {
    final isSelected = _selectedSplit == id;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedSplit = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.15)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.orange
                : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
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
                  color: isSelected ? AppColors.orange : textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.orange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                          color: isSelected ? AppColors.orange : textPrimary,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
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
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }

  Widget _buildContinueButton(bool isDark) {
    const orange = Color(0xFFF97316);
    final hasSelection = _selectedSplit != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite).withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: (_isLoading || !hasSelection) ? null : _continueToNextScreen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: hasSelection ? orange : orange.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}
