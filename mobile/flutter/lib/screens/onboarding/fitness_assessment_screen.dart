import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/foldable_quiz_scaffold.dart';

/// Fitness Assessment Screen
/// Single scrollable screen with 6 questions (~2 min)
/// Appears after coach selection, before paywall
/// Data is sent to the AI for personalized workout generation
class FitnessAssessmentScreen extends ConsumerStatefulWidget {
  const FitnessAssessmentScreen({super.key});

  @override
  ConsumerState<FitnessAssessmentScreen> createState() =>
      _FitnessAssessmentScreenState();
}

class _FitnessAssessmentScreenState
    extends ConsumerState<FitnessAssessmentScreen> {
  // Local state for selections
  String? _pushupCapacity;
  String? _pullupCapacity;
  String? _plankCapacity;
  String? _squatCapacity;
  String? _cardioCapacity;
  String? _trainingExperience;

  bool _isLoading = false;

  // Question definitions with scoring
  static const _pushupOptions = [
    {'id': 'none', 'label': 'None / Difficult', 'description': 'Can\'t do any or struggle', 'score': 1},
    {'id': '1-10', 'label': '1-10', 'description': 'Getting started', 'score': 2},
    {'id': '11-25', 'label': '11-25', 'description': 'Solid foundation', 'score': 3},
    {'id': '26-40', 'label': '26-40', 'description': 'Strong', 'score': 4},
    {'id': '40+', 'label': '40+', 'description': 'Very strong', 'score': 5},
  ];

  static const _pullupOptions = [
    {'id': 'none', 'label': 'None', 'description': 'Can\'t do unassisted', 'score': 1},
    {'id': 'assisted', 'label': 'Assisted (1-5)', 'description': 'With bands or machine', 'score': 2},
    {'id': '1-5', 'label': '1-5 unassisted', 'description': 'Building strength', 'score': 3},
    {'id': '6-10', 'label': '6-10', 'description': 'Solid pulling strength', 'score': 4},
    {'id': '10+', 'label': '10+', 'description': 'Very strong', 'score': 5},
  ];

  static const _plankOptions = [
    {'id': '<15sec', 'label': '< 15 seconds', 'description': 'Just starting', 'score': 1},
    {'id': '15-30sec', 'label': '15-30 seconds', 'description': 'Building core', 'score': 2},
    {'id': '31-60sec', 'label': '31-60 seconds', 'description': 'Good core strength', 'score': 3},
    {'id': '1-2min', 'label': '1-2 minutes', 'description': 'Strong core', 'score': 4},
    {'id': '2+min', 'label': '2+ minutes', 'description': 'Very strong core', 'score': 5},
  ];

  static const _squatOptions = [
    {'id': '0-10', 'label': '0-10', 'description': 'Just starting', 'score': 1},
    {'id': '11-25', 'label': '11-25', 'description': 'Building endurance', 'score': 2},
    {'id': '26-40', 'label': '26-40', 'description': 'Good leg strength', 'score': 3},
    {'id': '40+', 'label': '40+', 'description': 'Strong legs', 'score': 4},
  ];

  static const _experienceOptions = [
    {'id': 'never', 'label': 'Never / Just starting', 'description': 'Brand new to lifting', 'score': 1},
    {'id': '3-12mo', 'label': '3-12 months', 'description': 'Learning the basics', 'score': 2},
    {'id': '1-3yr', 'label': '1-3 years', 'description': 'Building consistency', 'score': 3},
    {'id': '3-5yr', 'label': '3-5 years', 'description': 'Solid experience', 'score': 4},
    {'id': '5+yr', 'label': '5+ years', 'description': 'Veteran lifter', 'score': 5},
  ];

  static const _cardioOptions = [
    {'id': '<5min', 'label': '< 5 minutes', 'description': 'Building stamina', 'score': 1},
    {'id': '5-15min', 'label': '5-15 minutes', 'description': 'Getting there', 'score': 2},
    {'id': '15-30min', 'label': '15-30 minutes', 'description': 'Good endurance', 'score': 3},
    {'id': '30+min', 'label': '30+ minutes', 'description': 'Great cardio', 'score': 4},
  ];

  bool get _canContinue =>
      _pushupCapacity != null &&
      _pullupCapacity != null &&
      _plankCapacity != null &&
      _squatCapacity != null &&
      _cardioCapacity != null &&
      _trainingExperience != null;

  int _getScore(String? id, List<Map<String, dynamic>> options) {
    if (id == null) return 1;
    for (final option in options) {
      if (option['id'] == id) {
        return option['score'] as int;
      }
    }
    return 1; // Default score if not found
  }

  String _calculateFitnessLevel() {
    final pushupScore = _getScore(_pushupCapacity, _pushupOptions);
    final pullupScore = _getScore(_pullupCapacity, _pullupOptions);
    final plankScore = _getScore(_plankCapacity, _plankOptions);
    final squatScore = _getScore(_squatCapacity, _squatOptions);
    final experienceScore = _getScore(_trainingExperience, _experienceOptions);
    final cardioScore = _getScore(_cardioCapacity, _cardioOptions);

    final strengthAvg =
        (pushupScore + pullupScore + plankScore + squatScore) / 4;
    final overall =
        strengthAvg * 0.5 + experienceScore * 0.3 + cardioScore * 0.2;

    if (overall < 2.0) return 'beginner';
    if (overall < 3.5) return 'intermediate';
    return 'advanced';
  }

  Future<void> _continue() async {
    if (!_canContinue || _isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    // Save to provider
    final quizNotifier = ref.read(preAuthQuizProvider.notifier);
    await quizNotifier.setPushupCapacity(_pushupCapacity!);
    await quizNotifier.setPullupCapacity(_pullupCapacity!);
    await quizNotifier.setPlankCapacity(_plankCapacity!);
    await quizNotifier.setSquatCapacity(_squatCapacity!);
    await quizNotifier.setCardioCapacity(_cardioCapacity!);
    await quizNotifier.setTrainingExperience(_trainingExperience!);

    // Calculate and save fitness level
    final calculatedLevel = _calculateFitnessLevel();
    await quizNotifier.setFitnessLevel(calculatedLevel);

    // Navigate directly to paywall features
    if (mounted) {
      context.go('/paywall-features');
    }
  }

  void _skip() {
    HapticFeedback.mediumImpact();
    // Skip without saving fitness data — defaults will be used
    if (mounted) {
      context.go('/paywall-features');
    }
  }

  Widget _buildAssessmentInfo(bool isDark, Color textPrimary, Color textSecondary) {
    final items = [
      {'icon': Icons.fitness_center, 'label': 'Exercise difficulty'},
      {'icon': Icons.repeat, 'label': 'Sets & rep ranges'},
      {'icon': Icons.timer_outlined, 'label': 'Rest periods'},
      {'icon': Icons.trending_up, 'label': 'Progression pace'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Why section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Why this matters',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your answers help the AI calibrate workouts to your exact fitness level — no guessing.',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // What gets customized
        Text(
          'What gets personalized',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 16,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 12),

        // Reassurance
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: textSecondary.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'No wrong answers — just be honest!',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderOverlay(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/coach-selection');
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                size: 18,
              ),
            ),
          ),

          // Skip button
          GestureDetector(
            onTap: _skip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);
    final gap = isFoldable ? 8.0 : 16.0;
    final hPad = isFoldable ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: 'Quick Fitness Check',
          headerSubtitle: 'Help us personalize your workouts (~2 min)',
          headerExtra: _buildAssessmentInfo(isDark, textPrimary, textSecondary),
          headerOverlay: _buildHeaderOverlay(isDark),
          content: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show header inline only on phone (foldable shows it in the left pane)
                if (!isFoldable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildHeader(textPrimary, textSecondary),
                  ),

                SizedBox(height: isFoldable ? 4.0 : 8.0),

                // Question 1: Push-ups
                _buildQuestionCard(
                  index: 0,
                  icon: Icons.fitness_center,
                  iconColor: AppColors.orange,
                  title: 'Push-ups',
                  subtitle: 'How many consecutive push-ups with good form?',
                  options: _pushupOptions,
                  selectedValue: _pushupCapacity,
                  onChanged: (value) =>
                      setState(() => _pushupCapacity = value),
                  isDark: isDark,
                  compact: isFoldable,
                ),

                SizedBox(height: gap),

                // Question 2: Pull-ups
                _buildQuestionCard(
                  index: 1,
                  icon: Icons.sports_gymnastics,
                  iconColor: AppColors.cyan,
                  title: 'Pull-ups',
                  subtitle: 'How many pull-ups can you do?',
                  options: _pullupOptions,
                  selectedValue: _pullupCapacity,
                  onChanged: (value) =>
                      setState(() => _pullupCapacity = value),
                  isDark: isDark,
                  compact: isFoldable,
                ),

                SizedBox(height: gap),

                // Question 3: Plank
                _buildQuestionCard(
                  index: 2,
                  icon: Icons.accessibility_new,
                  iconColor: AppColors.purple,
                  title: 'Plank Hold',
                  subtitle: 'How long can you hold a plank?',
                  options: _plankOptions,
                  selectedValue: _plankCapacity,
                  onChanged: (value) =>
                      setState(() => _plankCapacity = value),
                  isDark: isDark,
                  compact: isFoldable,
                ),

                SizedBox(height: gap),

                // Question 4: Squats
                _buildQuestionCard(
                  index: 3,
                  icon: Icons.airline_seat_legroom_extra,
                  iconColor: AppColors.success,
                  title: 'Bodyweight Squats',
                  subtitle: 'How many can you do continuously?',
                  options: _squatOptions,
                  selectedValue: _squatCapacity,
                  onChanged: (value) =>
                      setState(() => _squatCapacity = value),
                  isDark: isDark,
                  compact: isFoldable,
                ),

                SizedBox(height: gap),

                // Question 5: Experience
                _buildQuestionCard(
                  index: 4,
                  icon: Icons.history,
                  iconColor: AppColors.warning,
                  title: 'Training Experience',
                  subtitle: 'How long have you been lifting weights?',
                  options: _experienceOptions,
                  selectedValue: _trainingExperience,
                  onChanged: (value) =>
                      setState(() => _trainingExperience = value),
                  isDark: isDark,
                  compact: isFoldable,
                ),

                SizedBox(height: gap),

                // Question 6: Cardio
                _buildQuestionCard(
                  index: 5,
                  icon: Icons.directions_run,
                  iconColor: AppColors.error,
                  title: 'Cardio Capacity',
                  subtitle: 'How long can you do continuous cardio?',
                  options: _cardioOptions,
                  selectedValue: _cardioCapacity,
                  onChanged: (value) =>
                      setState(() => _cardioCapacity = value),
                  isDark: isDark,
                  compact: isFoldable,
                ),

                SizedBox(height: isFoldable ? 60 : 100), // Space for button
              ],
            ),
          ),
          button: _buildContinueButton(isDark),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.assessment, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Fitness Check',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Help us personalize your workouts (~2 min)',
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
      ],
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildQuestionCard({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
    required bool isDark,
    bool compact = false,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final cardPad = compact ? 10.0 : 16.0;
    final iconPad = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 20.0;
    final titleSize = compact ? 14.0 : 16.0;
    final subtitleSize = compact ? 11.0 : 12.0;
    final chipHPad = compact ? 10.0 : 12.0;
    final chipVPad = compact ? 6.0 : 8.0;
    final chipFontSize = compact ? 12.0 : 13.0;
    final chipSpacing = compact ? 6.0 : 8.0;
    final headerChipGap = compact ? 8.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: cardBorder),
      ),
      padding: EdgeInsets.all(cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: headerChipGap),

          // Options as chips
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: options.map((option) {
              final isSelected = selectedValue == option['id'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(option['id'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.symmetric(horizontal: chipHPad, vertical: chipVPad),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.orange,
                              AppColors.orange.withValues(alpha: 0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark
                            ? AppColors.glassSurface
                            : AppColorsLight.glassSurface),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.orange : cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: chipFontSize,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: (100 + index * 80).ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _buildContinueButton(bool isDark) {
    final isEnabled = _canContinue && !_isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite)
                .withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: isEnabled ? _continue : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.orange
                  : (isDark ? AppColors.elevated : AppColorsLight.elevated),
              borderRadius: BorderRadius.circular(14),
              border: isEnabled
                  ? null
                  : Border.all(
                      color:
                          isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    ),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textSecondary
                                    : AppColorsLight.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: isEnabled
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSecondary
                                  : AppColorsLight.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
      ),
    );
  }
}
