import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';

/// Demo Tasks Screen — Onboarding v5
///
/// Two optional pre-signup demos. Users self-select through action: those
/// who complete both are highest-intent. Skipping is always allowed via
/// the persistent "Build My Plan" CTA.
///
/// Completion is tracked via SharedPrefs so users returning to this screen
/// see their progress (e.g., after sign-up, after backgrounding).
class DemoTasksScreen extends ConsumerStatefulWidget {
  const DemoTasksScreen({super.key});

  static const String workoutDoneKey = 'demo_workout_completed';
  static const String nutritionDoneKey = 'demo_nutrition_completed';

  @override
  ConsumerState<DemoTasksScreen> createState() => _DemoTasksScreenState();
}

class _DemoTasksScreenState extends ConsumerState<DemoTasksScreen> {
  bool _workoutDone = false;
  bool _nutritionDone = false;

  @override
  void initState() {
    super.initState();
    _loadCompletion();
  }

  Future<void> _loadCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _workoutDone = prefs.getBool(DemoTasksScreen.workoutDoneKey) ?? false;
        _nutritionDone =
            prefs.getBool(DemoTasksScreen.nutritionDoneKey) ?? false;
      });
    }
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_demo_tasks_completed',
          properties: {
            'workout_done': _workoutDone,
            'nutrition_done': _nutritionDone,
          },
        );
    // `context.go` resets the stack, so a Back tap on /sign-in would
    // skip all onboarding history and land back on /intro. `push`
    // preserves demo-tasks underneath so Back returns here.
    context.push('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final completionCount =
        (_workoutDone ? 1 : 0) + (_nutritionDone ? 1 : 0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                'See it in action',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
              const SizedBox(height: 6),
              Text(
                "Try one or both. Skip if you want.",
                style: TextStyle(fontSize: 15, color: textSecondary),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 28),

              if (completionCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF2ECC71), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        completionCount == 2
                            ? 'Both demos completed'
                            : '1 of 2 completed',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DemoCard(
                      delay: 350,
                      icon: Icons.fitness_center_rounded,
                      iconColor: const Color(0xFF00BCD4),
                      label: 'Workout',
                      detail: 'See how training works',
                      duration: '~45 sec',
                      done: _workoutDone,
                      onTap: () async {
                        await context.push('/demo-workout-showcase');
                        await _loadCompletion();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _DemoCard(
                      delay: 500,
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFF2ECC71),
                      label: 'Nutrition',
                      detail: 'Snap a menu, log a meal',
                      duration: '~30 sec',
                      done: _nutritionDone,
                      onTap: () async {
                        await context.push('/demo-nutrition-showcase');
                        await _loadCompletion();
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: _continue,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.onboardingAccent, Color(0xFFFF6B00)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.onboardingAccent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      completionCount > 0 ? 'Continue' : 'Build My Plan',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final int delay;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String detail;
  final String duration;
  final bool done;
  final VoidCallback onTap;
  final bool isDark;

  const _DemoCard({
    required this.delay,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.detail,
    required this.duration,
    required this.done,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done
                ? const Color(0xFF2ECC71).withValues(alpha: 0.5)
                : iconColor.withValues(alpha: 0.25),
            width: done ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (done)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: done ? const Color(0xFF2ECC71) : textSecondary,
              size: done ? 24 : 16,
            ),
          ],
        ),
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
