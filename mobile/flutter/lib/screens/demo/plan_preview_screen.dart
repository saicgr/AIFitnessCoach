import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../onboarding/onboarding_experiments.dart';
import '../onboarding/pre_auth_quiz_screen.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/exercise_image.dart';
import '../../data/models/exercise.dart';
import '../workout/widgets/exercise_info_sheet.dart';
import 'preview_exercise_catalog.dart';
part 'plan_preview_screen_ui.dart';

/// Signature v2 type system (docs/planning/app-redesign-2026-06/signature-v2.html):
/// Anton = uppercase display headings, Barlow Condensed = letter-spaced
/// kickers/labels/CTAs, single orange accent (AppColors.orange ≈ #F97316).
const String _kSigDisplay = 'Anton';
const String _kSigLabel = 'Barlow Condensed';
const Color _kSigAccent = Color(0xFFF97316);

/// Full Plan Preview Screen
/// Shows the user's complete personalized 4-week workout plan BEFORE asking them to subscribe
/// This addresses the user complaint: "After giving all the personal information, it requires subscription to see the personal plan."
///
/// Two entry contexts:
///  - Guest-session timer (default): browsing, can subscribe or continue free.
///  - Onboarding funnel ([fromOnboarding] = true, route `?from=onboarding`):
///    a personalized pre-paywall reveal — single forward CTA into the
///    value screen, no back button, honors its PostHog kill-switch.
class PlanPreviewScreen extends ConsumerStatefulWidget {
  /// True when reached from the onboarding funnel (`/plan-preview?from=onboarding`).
  final bool fromOnboarding;

  const PlanPreviewScreen({super.key, this.fromOnboarding = false});

  @override
  ConsumerState<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends ConsumerState<PlanPreviewScreen>
    with SingleTickerProviderStateMixin {
  int _selectedWeek = 0;
  bool _isLoading = true;
  late AnimationController _pulseController;

  /// Gravl-gap kill-switch `onboarding_split_rationale` (default ON). When on,
  /// each session card in the preview surfaces its primary muscle-group chips.
  /// Resolved async in [initState]; defaults true so the chips show unless the
  /// flag is explicitly disabled.
  bool _showSplitRationale = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Resolve the split-rationale kill-switch (fail-open: stays on if absent).
    OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagSplitRationale,
    ).then((enabled) {
      if (mounted) setState(() => _showSplitRationale = enabled);
    });

    // Onboarding conversion v6: inside the funnel, honor the remote
    // kill-switch and log the view.
    if (widget.fromOnboarding) {
      _maybeSkipForOnboarding();
      ref
          .read(posthogServiceProvider)
          .capture(eventName: 'onboarding_plan_preview_viewed');
    }

    // Simulate loading the personalized plan
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  /// Remote kill-switch for the onboarding plan-preview step. Absent flag
  /// keeps it on; an explicit disable jumps straight to the value screen.
  Future<void> _maybeSkipForOnboarding() async {
    final enabled = await OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagPlanPreview,
    );
    if (!enabled && mounted) {
      // Onboarding paywall: the signature-v2 features screen (marquee + honest
      // price anchor + Future ceiling). Replaces the legacy /onboarding-value
      // "$X stack" anchor, which is now orphaned.
      context.go('/paywall-features');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizData = ref.watch(preAuthQuizProvider);
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final backgroundColor = isDark
        ? AppColors.pureBlack
        : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingState(isDark, textPrimary, textSecondary)
          : _buildPlanContent(isDark, quizData, textPrimary, textSecondary),
    );
  }

  Widget _buildLoadingSteps(Color textPrimary, Color textSecondary) {
    final steps = [
      {'text': 'Personalizing exercises...', 'delay': 0},
      {'text': 'Optimizing workout split...', 'delay': 400},
      {'text': 'Calculating progression...', 'delay': 800},
    ];

    return Column(
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        step['text'] as String,
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  )
                  .animate(
                    delay: Duration(
                      milliseconds: (step['delay'] as num).toInt(),
                    ),
                  )
                  .fadeIn(),
        );
      }).toList(),
    );
  }

  Widget _buildPlanContent(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark
        ? AppColors.cardBorder
        : AppColorsLight.cardBorder;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(isDark, textPrimary, textSecondary),

          // Week selector tabs
          _buildWeekTabs(isDark, textPrimary, textSecondary, elevatedColor),

          // Plan content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // "This is YOUR personalized plan" header
                  _buildPersonalizedHeader(
                    isDark,
                    quizData,
                    textPrimary,
                    textSecondary,
                  ),

                  const SizedBox(height: 20),

                  // What you'll achieve section — lead with the 4-week outcome
                  // arc (master → build → intensity → peak) BEFORE the day-by-day
                  // mechanics. Leading with the transformation/outcome is the
                  // higher-converting order for a pre-paywall plan preview.
                  _buildAchievementsSection(
                    isDark,
                    quizData,
                    textPrimary,
                    textSecondary,
                    elevatedColor,
                    borderColor,
                  ),

                  const SizedBox(height: 24),

                  // Weekly workouts (the concrete proof, shown after the arc)
                  ..._buildWeeklyWorkouts(
                    isDark,
                    quizData,
                    textPrimary,
                    textSecondary,
                    elevatedColor,
                    borderColor,
                  ),

                  const SizedBox(height: 120), // Space for CTAs
                ],
              ),
            ),
          ),

          // Bottom CTAs
          _buildBottomCTAs(isDark, textPrimary),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // No back button inside the onboarding funnel — it is a
          // forward-only flow reached via context.go (nothing to pop to).
          if (!widget.fromOnboarding) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: textSecondary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  ).planPreviewYour4WeekPlan.toUpperCase(),
                  style: TextStyle(
                    fontFamily: _kSigDisplay,
                    fontSize: 27,
                    letterSpacing: 0.5,
                    color: textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, color: Colors.green, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context).planPreviewFreePreview,
                            style: TextStyle(
                              fontFamily: _kSigLabel,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildWeekTabs(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color elevatedColor,
  ) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isSelected = _selectedWeek == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedWeek = index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Week ${index + 1}'.toUpperCase(),
                    style: TextStyle(
                      fontFamily: _kSigLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: isSelected
                          ? const Color(0xFF160B03)
                          : textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildSummaryChip(IconData icon, String text, Color color) {
    // Signature v2: one accent across every chip (no rainbow). Callers pass
    // [_kSigAccent]; the param stays for the demo-screen's own reuse.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontFamily: _kSigLabel,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyWorkouts(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
    Color elevatedColor,
    Color borderColor,
  ) {
    final daysPerWeek = quizData.daysPerWeek ?? 3;
    final workoutDays =
        quizData.workoutDays ?? [0, 2, 4]; // Default Mon, Wed, Fri
    final goal = quizData.goal ?? 'build_muscle';

    // Generate workout schedule based on quiz answers
    final workouts = _generateWorkoutSchedule(
      goal,
      daysPerWeek,
      workoutDays,
      _selectedWeek,
    );

    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return List.generate(7, (dayIndex) {
      final workout = workouts[dayIndex];
      final isWorkoutDay = workout != null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child:
            Container(
                  decoration: BoxDecoration(
                    color: elevatedColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isWorkoutDay
                          ? (workout['color'] as Color).withOpacity(0.3)
                          : borderColor,
                    ),
                  ),
                  child: isWorkoutDay
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildWorkoutDayCard(
                              dayNames[dayIndex],
                              workout,
                              textPrimary,
                              textSecondary,
                            ),
                            // Gravl-gap: primary muscle groups this session trains,
                            // derived from its exercises (kill-switch gated).
                            if (_showSplitRationale)
                              _buildSessionMuscleChips(workout, textSecondary),
                          ],
                        )
                      : _buildRestDayCard(
                          dayNames[dayIndex],
                          textPrimary,
                          textSecondary,
                        ),
                )
                .animate(delay: Duration(milliseconds: 250 + dayIndex * 50))
                .fadeIn()
                .slideX(begin: 0.02),
      );
    });
  }

  /// Per-session muscle-group chips for a preview workout day. Derives a
  /// deduped, order-preserving set from the session's exercise `muscle` tags
  /// (e.g. Push → Chest, Shoulders, Triceps). Splits compound tags like
  /// "Chest/Triceps" so each group reads as its own chip, and caps at 6 to keep
  /// the collapsed card tidy on small screens.
  Widget _buildSessionMuscleChips(
    Map<String, dynamic> workout,
    Color textSecondary,
  ) {
    final color = workout['color'] as Color;
    final exercises = (workout['exercises'] as List)
        .cast<Map<String, dynamic>>();

    final muscles = <String>[];
    for (final ex in exercises) {
      final raw = ex['muscle'] as String? ?? '';
      for (final part in raw.split('/')) {
        final m = part.trim();
        if (m.isEmpty) continue;
        if (!muscles.contains(m)) muscles.add(m);
      }
    }
    if (muscles.isEmpty) return const SizedBox.shrink();

    final shown = muscles.take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fitness_center, size: 13, color: textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shown
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayCard(
    String dayName,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.self_improvement, color: Colors.grey, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Text(
                AppLocalizations.of(context).planPreviewRestRecovery,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generate workout schedule based on quiz answers
  Map<int, Map<String, dynamic>?> _generateWorkoutSchedule(
    String goal,
    int daysPerWeek,
    List<int> workoutDays,
    int weekIndex,
  ) {
    final schedule = <int, Map<String, dynamic>?>{};

    // Initialize all days as rest days
    for (int i = 0; i < 7; i++) {
      schedule[i] = null;
    }

    // Get workout types based on goal
    final workoutTypes = _getWorkoutTypesForGoal(goal, daysPerWeek);

    // Assign workouts to selected days
    for (int i = 0; i < workoutDays.length && i < workoutTypes.length; i++) {
      final dayIndex = workoutDays[i];
      final workoutType = workoutTypes[i];

      schedule[dayIndex] = {
        'type': workoutType['name'],
        'icon': workoutType['icon'],
        'color': workoutType['color'],
        'duration': 45 + (weekIndex * 5), // Progressive duration
        'exercises': _getExercisesForWorkout(
          workoutType['id'] as String,
          weekIndex,
        ),
      };
    }

    return schedule;
  }

  List<Map<String, dynamic>> _getWorkoutTypesForGoal(
    String goal,
    int daysPerWeek,
  ) {
    switch (goal) {
      case 'build_muscle':
      case 'increase_strength':
        if (daysPerWeek >= 4) {
          return [
            {
              'id': 'push',
              'name': 'Push',
              'icon': Icons.fitness_center,
              'color': AppColors.purple,
            },
            {
              'id': 'pull',
              'name': 'Pull',
              'icon': Icons.fitness_center,
              'color': AppColors.electricBlue,
            },
            {
              'id': 'legs',
              'name': 'Legs',
              'icon': Icons.directions_walk,
              'color': AppColors.teal,
            },
            {
              'id': 'upper',
              'name': 'Upper',
              'icon': Icons.fitness_center,
              'color': AppColors.purple,
            },
            {
              'id': 'lower',
              'name': 'Lower',
              'icon': Icons.directions_walk,
              'color': AppColors.teal,
            },
            {
              'id': 'full',
              'name': 'Full Body',
              'icon': Icons.accessibility_new,
              'color': AppColors.orange,
            },
            {
              'id': 'arms',
              'name': 'Arms',
              'icon': Icons.fitness_center,
              'color': AppColors.coral,
            },
          ];
        } else {
          return [
            {
              'id': 'upper',
              'name': 'Upper Body',
              'icon': Icons.fitness_center,
              'color': AppColors.purple,
            },
            {
              'id': 'lower',
              'name': 'Lower Body',
              'icon': Icons.directions_walk,
              'color': AppColors.teal,
            },
            {
              'id': 'full',
              'name': 'Full Body',
              'icon': Icons.accessibility_new,
              'color': AppColors.orange,
            },
          ];
        }

      case 'lose_weight':
        return [
          {
            'id': 'hiit',
            'name': 'HIIT',
            'icon': Icons.flash_on,
            'color': AppColors.coral,
          },
          {
            'id': 'strength',
            'name': 'Strength',
            'icon': Icons.fitness_center,
            'color': AppColors.purple,
          },
          {
            'id': 'cardio',
            'name': 'Cardio',
            'icon': Icons.directions_run,
            'color': AppColors.orange,
          },
          {
            'id': 'hiit',
            'name': 'HIIT',
            'icon': Icons.flash_on,
            'color': AppColors.coral,
          },
          {
            'id': 'full',
            'name': 'Full Body',
            'icon': Icons.accessibility_new,
            'color': AppColors.teal,
          },
          {
            'id': 'recovery',
            'name': 'Active Recovery',
            'icon': Icons.self_improvement,
            'color': AppColors.success,
          },
          {
            'id': 'cardio',
            'name': 'Cardio',
            'icon': Icons.directions_run,
            'color': AppColors.orange,
          },
        ];

      case 'improve_endurance':
        return [
          {
            'id': 'cardio',
            'name': 'Cardio',
            'icon': Icons.directions_run,
            'color': AppColors.orange,
          },
          {
            'id': 'intervals',
            'name': 'Intervals',
            'icon': Icons.timer,
            'color': AppColors.coral,
          },
          {
            'id': 'endurance',
            'name': 'Endurance',
            'icon': Icons.directions_bike,
            'color': AppColors.teal,
          },
          {
            'id': 'tempo',
            'name': 'Tempo',
            'icon': Icons.speed,
            'color': AppColors.electricBlue,
          },
          {
            'id': 'long',
            'name': 'Long Run',
            'icon': Icons.directions_run,
            'color': AppColors.orange,
          },
          {
            'id': 'recovery',
            'name': 'Recovery',
            'icon': Icons.self_improvement,
            'color': AppColors.success,
          },
          {
            'id': 'cross',
            'name': 'Cross Train',
            'icon': Icons.pool,
            'color': AppColors.purple,
          },
        ];

      default:
        return [
          {
            'id': 'full',
            'name': 'Full Body',
            'icon': Icons.accessibility_new,
            'color': AppColors.purple,
          },
          {
            'id': 'cardio',
            'name': 'Cardio',
            'icon': Icons.directions_run,
            'color': AppColors.orange,
          },
          {
            'id': 'strength',
            'name': 'Strength',
            'icon': Icons.fitness_center,
            'color': AppColors.electricBlue,
          },
          {
            'id': 'flexibility',
            'name': 'Flexibility',
            'icon': Icons.self_improvement,
            'color': AppColors.teal,
          },
          {
            'id': 'hiit',
            'name': 'HIIT',
            'icon': Icons.flash_on,
            'color': AppColors.coral,
          },
          {
            'id': 'active',
            'name': 'Active',
            'icon': Icons.directions_walk,
            'color': AppColors.success,
          },
          {
            'id': 'core',
            'name': 'Core',
            'icon': Icons.circle_outlined,
            'color': AppColors.purple,
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getExercisesForWorkout(
    String workoutId,
    int weekIndex,
  ) {
    // Curated, media-verified pool — each exercise carries its real
    // exercise_library id, so the preview rows render the baked illustration
    // (assets/preview_exercises/<id>.jpg) and resolve the demo video by id.
    // Replaces ~550 lines of hardcoded, image-less exercise names.
    final goal = ref.read(preAuthQuizProvider).goal ?? 'build_muscle';
    return curatedExercisesForType(workoutId, seed: weekIndex, goal: goal);
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Build Muscle';
      case 'lose_weight':
        return 'Lose Weight';
      case 'increase_strength':
        return 'Get Stronger';
      case 'improve_endurance':
        return 'Build Endurance';
      case 'stay_active':
        return 'Stay Active';
      case 'athletic_performance':
        return 'Athletic Performance';
      default:
        return 'Fitness Journey';
    }
  }

  String _formatLevel(String level) {
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }

  /// Human, adaptive equipment summary — never the robotic "Equipment count 83".
  String _formatEquipment(int count) {
    if (count <= 0) return 'Bodyweight only';
    if (count >= 15) return 'Full gym access';
    if (count == 1) return '1 piece of kit';
    return '$count pieces of kit';
  }

  /// Goal-aware 4-week milestone narrative for the "What You'll Achieve" card.
  /// Keeps the personalized promise honest — an endurance plan reads as an
  /// endurance arc, not a generic strength one.
  List<String> _milestonesForGoal(String goal) {
    switch (goal) {
      case 'improve_endurance':
        return [
          'Build your aerobic base',
          'Extend your stamina',
          'Push your threshold',
          'Peak conditioning week',
        ];
      case 'lose_weight':
        return [
          'Build the habit',
          'Ramp up the burn',
          'Push the intensity',
          'Peak fat-burn week',
        ];
      case 'increase_strength':
        return [
          'Groove the main lifts',
          'Build your strength base',
          'Intensify the load',
          'Peak strength week',
        ];
      case 'stay_active':
        return [
          'Find your rhythm',
          'Build consistency',
          'Add a challenge',
          'Hit your stride',
        ];
      case 'athletic_performance':
        return [
          'Build your base',
          'Develop power',
          'Sharpen & intensify',
          'Peak performance week',
        ];
      case 'build_muscle':
      default:
        return [
          'Master the movements',
          'Build your foundation',
          'Add volume & intensity',
          'Peak hypertrophy week',
        ];
    }
  }
}
