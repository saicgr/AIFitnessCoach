import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/training_preferences_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../widgets/glass_back_button.dart';
import '../../core/services/posthog_service.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/foldable_quiz_scaffold.dart';

part 'training_split_screen_part_split_info.dart';

part 'training_split_screen_ui.dart';

part 'training_split_screen_ext.dart';


/// Training Split Selection Screen - shown after weight projection, before AI consent.
/// Lets the user pick their preferred training split (PPL, Full Body, etc.)
/// or let the AI decide automatically.
class TrainingSplitScreen extends ConsumerStatefulWidget {
  const TrainingSplitScreen({super.key});

  @override
  ConsumerState<TrainingSplitScreen> createState() => _TrainingSplitScreenState();
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
    tagline: 'All muscles every session, 1–4 days/week',
    description:
        'Every session trains all major muscle groups (chest, back, legs, shoulders, arms). '
        'Each workout uses compound movements — squats, deadlifts, bench press, rows — '
        'so you hit every muscle frequently with less time in the gym. '
        'The only split that still works if you can only train once per week.',
    schedule: [
      'Mon — Full Body (Squat · Press · Row · Core)',
      'Tue — Rest',
      'Wed — Full Body (Deadlift · Press · Pull · Core)',
      'Thu — Rest',
      'Fri — Full Body (variation)',
      'Sat — Rest',
      'Sun — Rest',
    ],
    bestFor: 'Beginners, anyone training 1–3 days/week, or returning after a break.',
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
        return _daysPerWeek >= 1 && _daysPerWeek <= 4;
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
    final split = _selectedSplit ?? 'ai_decide';

    // Local save is fast (SharedPreferences) — await so the next screen sees it.
    await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(split);

    // Backend sync (PUT /users + refreshUser) is slow and the next screen
    // doesn't depend on it — fire-and-forget so navigation is instant.
    unawaited(
      ref
          .read(trainingPreferencesProvider.notifier)
          .setTrainingSplit(split)
          .catchError((Object e) {
        debugPrint('   [TrainingSplit] Background sync error: $e');
      }),
    );

    debugPrint('   [TrainingSplit] Saved split: $split');

    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_split_selected',
      properties: {'split_name': split},
    );

    if (mounted) {
      context.go('/ai-consent');
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

    // Cap OS-level text scaling on this dense onboarding screen so devices
    // with "Large text" accessibility (e.g. S25 Ultra default) don't overflow
    // the split cards. Users with scale < 1.0 still see smaller text.
    final mq = MediaQuery.of(context);
    final clampedScaler =
        mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.0);

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedScaler),
      child: Scaffold(
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
                          'You selected $_daysPerWeek ${_daysPerWeek == 1 ? 'day' : 'days'}/week',
                          style: TextStyle(
                            fontSize: 13,
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
                    description: 'Train all muscles each workout (1-4 days)',
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
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Schedule conflict',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_getSplitName(_selectedSplit!)} requires ${_getRecommendedDaysForSplit(_selectedSplit)} days/week, but you selected $_daysPerWeek ${_daysPerWeek == 1 ? 'day' : 'days'}/week.',
                            style: TextStyle(
                              fontSize: 12,
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
                                  const Icon(Icons.auto_fix_high_rounded, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Update to ${_getRecommendedDaysForSplit(_selectedSplit)} days/week',
                                    style: const TextStyle(
                                      fontSize: 13,
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
    ),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.15)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(14),
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
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.orange : textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.orange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.orange : textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Info button — only for named splits
            if (hasInfo) ...[
              const SizedBox(width: 6),
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
                    size: 18,
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
}
