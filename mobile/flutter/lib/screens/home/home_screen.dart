import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import 'widgets/components/components.dart';
import 'widgets/cards/cards.dart';
import 'widgets/daily_activity_card.dart';

/// The main home screen displaying workouts, progress, and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCheckingWorkouts = false;
  String? _generationStartDate;
  int _generationWeeks = 0;
  int _totalExpected = 0;
  int _totalGenerated = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkouts();
    });
  }

  Future<void> _initializeWorkouts() async {
    final notifier = ref.read(workoutsProvider.notifier);

    // First refresh to get current workouts
    await notifier.refresh();

    // Clear banner state if workouts exist
    if (notifier.nextWorkout != null && mounted) {
      setState(() {
        _generationStartDate = null;
        _generationWeeks = 0;
        _totalExpected = 0;
        _totalGenerated = 0;
      });
    }

    // Check if we've already checked today (persisted across app restarts)
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDate = prefs.getString('last_workout_check_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Also check session-level flag (for tab switching within same session)
    final hasCheckedSession = ref.read(hasCheckedRegenerationProvider);

    if (lastCheckDate == today || hasCheckedSession) {
      debugPrint(
        'Debug: [HomeScreen] Skipping regeneration check - already done today ($lastCheckDate)',
      );
      return;
    }

    // Check if we need to generate more (runs in background)
    if (!_isCheckingWorkouts) {
      setState(() => _isCheckingWorkouts = true);
      try {
        final result = await notifier.checkAndRegenerateIfNeeded();
        debugPrint(
          'Debug: [HomeScreen] Workout check result: ${result['message']}',
        );

        // Mark as checked for this session AND persist today's date
        ref.read(hasCheckedRegenerationProvider.notifier).state = true;
        await prefs.setString('last_workout_check_date', today);

        // If generation was triggered, store details for display
        if (result['needs_generation'] == true && mounted) {
          setState(() {
            _generationStartDate = result['start_date'] as String?;
            _generationWeeks = (result['weeks'] as int?) ?? 4;
            _totalExpected = (result['total_expected'] as int?) ?? 0;
            _totalGenerated = (result['total_generated'] as int?) ?? 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Generating your upcoming workouts...'),
              backgroundColor: AppColors.elevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCheckingWorkouts = false);
        }
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final workoutsState = ref.watch(workoutsProvider);
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final user = authState.user;
    final isAIGenerating = ref.watch(aiGeneratingWorkoutProvider);

    final nextWorkout = workoutsNotifier.nextWorkout;
    final upcomingWorkouts = workoutsNotifier.upcomingWorkouts;
    final completedCount = workoutsNotifier.completedCount;
    final weeklyProgress = workoutsNotifier.weeklyProgress;
    final currentStreak = workoutsNotifier.currentStreak;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => workoutsNotifier.refresh(),
        color: AppColors.cyan,
        backgroundColor: elevatedColor,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(
                  context,
                  user?.displayName ?? 'User',
                  currentStreak,
                  isDark,
                ),
              ),

              // Generation Banner
              if (_generationStartDate != null &&
                  _generationWeeks > 0 &&
                  nextWorkout == null)
                SliverToBoxAdapter(
                  child: MoreWorkoutsLoadingBanner(
                    isDark: isDark,
                    startDate: _generationStartDate!,
                    weeks: _generationWeeks,
                    totalExpected: _totalExpected,
                    totalGenerated: _totalGenerated,
                  ),
                ),

              // Section: TODAY
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'TODAY'),
              ),

              // Daily Activity Card
              const SliverToBoxAdapter(
                child: DailyActivityCard(),
              ),

              // Next Workout Card
              SliverToBoxAdapter(
                child: _buildNextWorkoutSection(
                  context,
                  workoutsState,
                  workoutsNotifier,
                  nextWorkout,
                  isAIGenerating,
                ),
              ),

              // Quick Actions Row
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: QuickActionsRow(),
                ),
              ),

              // Section: YOUR WEEK
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'YOUR WEEK'),
              ),

              // Weekly Progress
              SliverToBoxAdapter(
                child: WeeklyProgressCard(
                  completed: weeklyProgress.$1,
                  total: weeklyProgress.$2,
                  isDark: isDark,
                ).animateSlideRotate(delay: const Duration(milliseconds: 50)),
              ),

              // Weekly Goals Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: WeeklyGoalsCard(isDark: isDark)
                      .animateSlideRotate(delay: const Duration(milliseconds: 100)),
                ),
              ),

              // Section: UPCOMING
              if (upcomingWorkouts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'UPCOMING',
                    subtitle: '${upcomingWorkouts.length} workouts',
                    actionText: 'View All',
                    onAction: () {
                      HapticService.light();
                      context.push('/schedule');
                    },
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= upcomingWorkouts.length) return null;
                      final workout = upcomingWorkouts[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: AppAnimations.listItem,
                        child: SlideAnimation(
                          verticalOffset: 20,
                          curve: AppAnimations.fastOut,
                          child: FadeInAnimation(
                            curve: AppAnimations.fastOut,
                            child: UpcomingWorkoutCard(
                              workout: workout,
                              onTap: () => context.push('/workout/${workout.id}'),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: upcomingWorkouts.length.clamp(0, 3),
                  ),
                ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName,
    int currentStreak,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  userName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Streak Badge
          _StreakBadge(streak: currentStreak, isDark: isDark),
          const SizedBox(width: 8),
          _LibraryButton(isDark: isDark),
          const SizedBox(width: 4),
          NotificationBellButton(isDark: isDark),
          const SizedBox(width: 4),
          ProgramMenuButton(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildNextWorkoutSection(
    BuildContext context,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
  ) {
    return workoutsState.when(
      loading: () => const LoadingCard(),
      error: (e, _) => ErrorCard(
        message: 'Failed to load workouts',
        onRetry: () => workoutsNotifier.refresh(),
      ),
      data: (_) => (isAIGenerating && nextWorkout == null)
          ? const GeneratingWorkoutsCard(
              message: 'AI is generating your workout...',
            )
          : nextWorkout != null
              ? NextWorkoutCard(
                  workout: nextWorkout,
                  onStart: () => context.push('/workout/${nextWorkout.id}'),
                )
              : _isCheckingWorkouts
                  ? const GeneratingWorkoutsCard()
                  : EmptyWorkoutCard(
                      onGenerate: () async {
                        setState(() => _isCheckingWorkouts = true);
                        final result = await workoutsNotifier
                            .checkAndRegenerateIfNeeded();
                        if (mounted) {
                          setState(() => _isCheckingWorkouts = false);
                          if (result['needs_generation'] != true) {
                            context.go('/onboarding');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Generating your workouts...'),
                                backgroundColor: AppColors.elevated,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
    );
  }
}

/// A button that navigates to the library screen
class _LibraryButton extends StatelessWidget {
  final bool isDark;

  const _LibraryButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/library');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 16,
                color: AppColors.purple,
              ),
              const SizedBox(width: 6),
              Text(
                'Library',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A badge showing the current workout streak with fire icon
class _StreakBadge extends StatelessWidget {
  final int streak;
  final bool isDark;

  const _StreakBadge({
    required this.streak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Tooltip(
      message: streak > 0 ? '$streak day streak!' : 'Start your streak!',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: streak > 0
                ? AppColors.orange.withOpacity(0.5)
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: streak > 0 ? AppColors.orange : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: streak > 0 ? AppColors.orange : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
