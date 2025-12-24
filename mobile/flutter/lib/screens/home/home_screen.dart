import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
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

    // Only check regeneration once per session
    final hasChecked = ref.read(hasCheckedRegenerationProvider);
    if (hasChecked) {
      debugPrint(
        'Debug: [HomeScreen] Skipping regeneration check - already done this session',
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

        // Mark as checked for this session
        ref.read(hasCheckedRegenerationProvider.notifier).state = true;

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
                  completedCount,
                  weeklyProgress.$1,
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

              // Library Quick Access
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LibraryQuickAccessCard(isDark: isDark),
                ),
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
    int completedCount,
    int weeklyCount,
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
          StatBadge(
            icon: Icons.check_circle_outline,
            value: '$completedCount',
            color: AppColors.success,
            tooltip: 'Total workouts completed',
          ),
          const SizedBox(width: 8),
          StatBadge(
            icon: Icons.local_fire_department,
            value: '$weeklyCount',
            color: AppColors.orange,
            tooltip: 'Workouts this week',
          ),
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
