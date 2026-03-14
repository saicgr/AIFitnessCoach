import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/training_preferences_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../widgets/glass_back_button.dart';
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

// ─── Training Split Info Data ────────────────────────────────────────────────

class _SplitInfo {
  final String title;
  final String tagline;
  final String description;
  final List<String> schedule;
  final String bestFor;
  final List<String> pros;
  final List<String> cons;

  const _SplitInfo({
    required this.title,
    required this.tagline,
    required this.description,
    required this.schedule,
    required this.bestFor,
    required this.pros,
    required this.cons,
  });
}

const _kSplitInfoMap = <String, _SplitInfo>{
  'push_pull_legs': _SplitInfo(
    title: 'Push / Pull / Legs (PPL)',
    tagline: '3-day cycle, 5–6 days/week',
    description:
        'You alternate three types of sessions: Push (chest, shoulders, triceps), '
        'Pull (back, biceps), and Legs. Running the cycle twice per week gives every '
        'muscle 2 hits, making PPL one of the best evidence-based programs for muscle growth.',
    schedule: [
      'Mon — Push  (Chest · Shoulders · Triceps)',
      'Tue — Pull  (Back · Biceps · Rear Delts)',
      'Wed — Legs  (Quads · Hamstrings · Glutes · Calves)',
      'Thu — Push  (repeat)',
      'Fri — Pull  (repeat)',
      'Sat — Legs  (repeat)',
      'Sun — Rest',
    ],
    bestFor: 'Intermediate to advanced lifters training 5–6 days/week who want to build muscle efficiently.',
    pros: [
      'High muscle frequency (2×/week per group)',
      'Clear, simple structure',
      'Scales well with volume',
    ],
    cons: [
      'Needs 5–6 days to work as designed',
      'Leg sessions can be very demanding',
    ],
  ),
  'full_body': _SplitInfo(
    title: 'Full Body',
    tagline: 'All muscles every session, 2–4 days/week',
    description:
        'Every session trains all major muscle groups (chest, back, legs, shoulders, arms). '
        'Each workout uses compound movements — squats, deadlifts, bench press, rows — '
        'so you hit every muscle frequently with less time in the gym.',
    schedule: [
      'Mon — Full Body (Squat · Press · Row · Core)',
      'Tue — Rest',
      'Wed — Full Body (Deadlift · Press · Pull · Core)',
      'Thu — Rest',
      'Fri — Full Body (variation)',
      'Sat — Rest',
      'Sun — Rest',
    ],
    bestFor: 'Beginners, people with 2–3 days available, or those returning after a break.',
    pros: [
      'Maximum muscle frequency per week',
      'Time-efficient — works on 2 days/week',
      'Great for strength & beginners',
    ],
    cons: [
      'Each session is long and tiring',
      'Limited specialization per muscle',
    ],
  ),
  'upper_lower': _SplitInfo(
    title: 'Upper / Lower',
    tagline: 'Alternating upper & lower days, 4 days/week',
    description:
        'You alternate between upper-body days (chest, back, shoulders, arms) and '
        'lower-body days (quads, hamstrings, glutes, calves). Each muscle group gets '
        'trained twice per week with built-in rest for recovery.',
    schedule: [
      'Mon — Upper  (Bench · Row · Overhead · Curls)',
      'Tue — Lower  (Squat · Romanian Deadlift · Leg Press)',
      'Wed — Rest',
      'Thu — Upper  (repeat, varied)',
      'Fri — Lower  (Deadlift · Bulgarian Split · Calf)',
      'Sat — Rest',
      'Sun — Rest',
    ],
    bestFor: 'Intermediate lifters who want high frequency with manageable session length.',
    pros: [
      'Good balance of frequency & volume',
      'Manageable session lengths',
      'Flexible — add a 5th day easily',
    ],
    cons: [
      'Needs at least 4 days to be effective',
      'Less daily volume than body-part splits',
    ],
  ),
  'phul': _SplitInfo(
    title: 'PHUL — Power Hypertrophy Upper Lower',
    tagline: '4 days/week · Strength + Size',
    description:
        'Created by powerlifter Brandon Campbell, PHUL combines heavy power training '
        '(low reps, compound lifts) with high-volume hypertrophy work. Two days focus '
        'on maximal strength; two days on muscle-building volume.',
    schedule: [
      'Mon — Upper Power  (heavy Bench · Row · Press · Pull)',
      'Tue — Lower Power  (heavy Squat · Deadlift · Leg Press)',
      'Wed — Rest',
      'Thu — Upper Hypertrophy  (moderate weight, more sets)',
      'Fri — Lower Hypertrophy  (lunges · leg curls · extensions)',
      'Sat — Rest',
      'Sun — Rest',
    ],
    bestFor: 'Intermediate lifters who want to get both stronger and bigger at the same time.',
    pros: [
      'Develops strength AND muscle simultaneously',
      'Well-structured 4-day schedule',
      'Excellent for intermediate progress',
    ],
    cons: [
      'Power days are demanding — requires good technique',
      'Not ideal for pure beginners',
    ],
  ),
  'phat': _SplitInfo(
    title: 'PHAT — Power Hypertrophy Adaptive Training',
    tagline: '5 days/week · Power + Volume blend',
    description:
        'Designed by Dr. Layne Norton (PhD Nutritional Sciences, natural bodybuilder & powerlifter), '
        'PHAT uses 2 power days and 3 hypertrophy days across 5 sessions. Each muscle gets both '
        'heavy compound work and high-rep isolation work every week.',
    schedule: [
      'Mon — Upper Power  (heavy compounds)',
      'Tue — Lower Power  (squat / deadlift focus)',
      'Wed — Rest',
      'Thu — Back/Shoulders Hypertrophy',
      'Fri — Lower Hypertrophy',
      'Sat — Chest/Arms Hypertrophy',
      'Sun — Rest',
    ],
    bestFor: 'Dedicated intermediate/advanced lifters wanting peak strength AND aesthetics.',
    pros: [
      'Covers both strength and hypertrophy goals',
      'Science-backed by Layne Norton',
      'Good weekly volume per muscle',
    ],
    cons: [
      'Complex — requires planning and tracking',
      'Demanding 5-day commitment',
      'Not for beginners',
    ],
  ),
  'pplul': _SplitInfo(
    title: 'PPLUL — Push / Pull / Legs / Upper / Lower',
    tagline: '5 days/week · High variety',
    description:
        'A hybrid that blends the PPL cycle with an Upper/Lower finish for maximum '
        'weekly volume and variety. You get the muscle-isolation focus of PPL plus '
        'the compound frequency of Upper/Lower in one 5-day block.',
    schedule: [
      'Mon — Push  (Chest · Shoulders · Triceps)',
      'Tue — Pull  (Back · Biceps)',
      'Wed — Legs  (Quads · Hamstrings · Glutes)',
      'Thu — Upper  (balanced compound day)',
      'Fri — Lower  (Deadlift variation focus)',
      'Sat — Rest',
      'Sun — Rest',
    ],
    bestFor: 'Intermediate lifters training 5 days who want variety and high volume without repeating sessions.',
    pros: [
      'High training variety — no repeated sessions',
      'Good volume distribution across 5 days',
      'Balances isolation and compound work',
    ],
    cons: [
      'Can feel inconsistent vs. pure PPL',
      'Harder to track progressive overload across 5 different sessions',
    ],
  ),
  'body_part': _SplitInfo(
    title: 'Body Part Split (Bro Split)',
    tagline: '1 muscle group per day, 5–6 days/week',
    description:
        'The classic bodybuilder "bro split" — one dedicated day per muscle group. '
        'You can hammer each muscle with extremely high volume in a single session, '
        'then let it rest for the rest of the week.',
    schedule: [
      'Mon — Chest  (all chest exercises)',
      'Tue — Back  (all back exercises)',
      'Wed — Shoulders  (all shoulder exercises)',
      'Thu — Arms  (Biceps + Triceps)',
      'Fri — Legs  (all leg exercises)',
      'Sat — Rest or Abs/Cardio',
      'Sun — Rest',
    ],
    bestFor: 'Experienced lifters who can sustain high volume per session and have 5+ days/week.',
    pros: [
      'Extremely high volume per muscle group',
      'Long recovery time per muscle (6 days)',
      'Proven by classic bodybuilders',
    ],
    cons: [
      'Low muscle frequency (each muscle hit once/week)',
      'Modern research favors 2× frequency',
      'Requires 5–6 days',
    ],
  ),
  'arnold_split': _SplitInfo(
    title: 'Arnold Split',
    tagline: '6 days/week · Chest+Back · Shoulders+Arms · Legs',
    description:
        'The training split used by Arnold Schwarzenegger in his prime. '
        'Three muscle pairings are trained twice per week on a 6-day schedule: '
        'Chest & Back together (the pump from chest stretches the back and vice versa), '
        'Shoulders & Arms, and Legs.',
    schedule: [
      'Mon — Chest + Back',
      'Tue — Shoulders + Arms (Biceps & Triceps)',
      'Wed — Legs',
      'Thu — Chest + Back (repeat)',
      'Fri — Shoulders + Arms (repeat)',
      'Sat — Legs (repeat)',
      'Sun — Rest',
    ],
    bestFor: 'Advanced lifters who can recover from 6-day training and want classic bodybuilder volume.',
    pros: [
      'Pairs antagonist muscles efficiently',
      'High frequency (2×/week per group)',
      'Battle-tested by elite bodybuilders',
    ],
    cons: [
      'Chest + Back sessions are very long',
      'Requires high recovery capacity',
      'Not sustainable for most natural lifters',
    ],
  ),
};

// ─────────────────────────────────────────────────────────────────────────────

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
            headerOverlay: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassBackButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/weight-projection');
                      },
                    ),
                  ),
                  _buildProgressIndicator(isDark),
                ],
              ),
            ),
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
    final inactiveColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    // Current step index (0-based): this is step 3 (Split)
    const currentStep = 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildStepDot(1, 'Sign In', true, orange, isDark, 0),
          _buildProgressLine(0, currentStep, orange, inactiveColor, 1),
          _buildStepDot(2, 'About You', true, orange, isDark, 2),
          _buildProgressLine(1, currentStep, orange, inactiveColor, 3),
          _buildStepDot(3, 'Split', true, orange, isDark, 4),
          _buildProgressLine(2, currentStep, orange, inactiveColor, 5),
          _buildStepDot(4, 'Privacy', false, orange, isDark, 6),
          _buildProgressLine(3, currentStep, orange, inactiveColor, 7),
          _buildStepDot(5, 'Coach', false, orange, isDark, 8),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int segmentIndex, int currentStep, Color activeColor, Color inactiveColor, int animOrder) {
    final isComplete = segmentIndex < currentStep;
    final delay = 100 + (animOrder * 80);

    return Expanded(
      child: Container(
        height: 2,
        color: inactiveColor,
        child: isComplete
            ? Container(height: 2, color: activeColor)
                .animate()
                .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft,
                    delay: Duration(milliseconds: delay), duration: 300.ms,
                    curve: Curves.easeOut)
            : null,
      ),
    );
  }

  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor, bool isDark, int animOrder) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final delay = 100 + (animOrder * 80);

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
        ).animate()
         .scaleXY(begin: 0, end: 1, delay: Duration(milliseconds: delay), duration: 300.ms, curve: Curves.easeOutBack),
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
    final hasInfo = _kSplitInfoMap.containsKey(id);

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
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.orange : textPrimary,
                          ),
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
            // Info button — only for named splits
            if (hasInfo) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showSplitInfoSheet(context, id);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: isSelected
                        ? AppColors.orange
                        : (isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }

  void _showSplitInfoSheet(BuildContext context, String id) {
    final info = _kSplitInfoMap[id];
    if (info == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final surface = isDark ? const Color(0xFF1C1C28) : Colors.white;
    const orange = Color(0xFFF97316);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      children: [
                        // Title row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fitness_center_rounded, color: orange, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: orange.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      info.tagline,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Description
                        Text(
                          info.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Weekly schedule
                        _infoSectionHeader('Weekly Schedule', Icons.calendar_month_rounded, textPrimary),
                        const SizedBox(height: 10),
                        ...info.schedule.map((day) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 7),
                                    decoration: const BoxDecoration(
                                      color: orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),

                        // Best for
                        _infoSectionHeader('Best For', Icons.person_rounded, textPrimary),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: orange.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            info.bestFor,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pros & Cons
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoSectionHeader('Pros', Icons.thumb_up_rounded, textPrimary),
                                  const SizedBox(height: 10),
                                  ...info.pros.map((p) => _bulletItem(p, Colors.green.shade400, textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoSectionHeader('Cons', Icons.thumb_down_rounded, textPrimary),
                                  const SizedBox(height: 10),
                                  ...info.cons.map((c) => _bulletItem(c, Colors.red.shade400, textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Close button
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: orange,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                'Got it',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoSectionHeader(String label, IconData icon, Color textPrimary) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFF97316)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _bulletItem(String text, Color dotColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
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
