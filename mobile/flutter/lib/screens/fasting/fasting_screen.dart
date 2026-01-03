import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/providers/multi_screen_tour_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/fasting_timer_service.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/multi_screen_tour_helper.dart';
import 'widgets/fasting_timer_widget.dart';
import 'widgets/fasting_zone_timeline.dart';
import 'widgets/fasting_stats_card.dart';
import 'widgets/fasting_history_list.dart';
import 'widgets/start_fast_sheet.dart';
import 'fasting_onboarding_screen.dart';

/// Fasting tracker screen with timer and zone visualization
class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _initialized = false;

  // Tour key for Start Fast button
  final GlobalKey _startFastKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should show tour step when this screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTourStep();
    });
  }

  /// Check and show the tour step for fasting screen
  void _checkAndShowTourStep() {
    final tourState = ref.read(multiScreenTourProvider);

    if (!tourState.isActive || tourState.isLoading) return;

    final currentStep = tourState.currentStep;
    if (currentStep == null) return;

    // Fasting screen handles step 4 (start_fast_button)
    if (currentStep.screenRoute != '/fasting') return;

    if (currentStep.targetKeyId == 'start_fast_button') {
      final helper = MultiScreenTourHelper(context: context, ref: ref);
      helper.checkAndShowTour('/fasting', _startFastKey);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      await ref.read(fastingProvider.notifier).initialize(userId);
      // Initialize timer service
      await ref.read(fastingTimerServiceProvider).initialize();
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Check if guest - fasting is disabled for guests
    final isGuest = ref.watch(isGuestModeProvider);
    final fastingEnabled = ref.watch(isFastingEnabledProvider);

    if (isGuest && !fastingEnabled) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 48,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fasting Tracker',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track your intermittent fasting with smart zone notifications, progress insights, and detailed history.',
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
                        if (mounted) {
                          context.go('/pre-auth-quiz');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Sign Up to Unlock',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 15,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final fastingState = ref.watch(fastingProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    // Show loading state
    if (!_initialized || fastingState.isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: purple),
        ),
      );
    }

    // Show onboarding if not completed
    if (!fastingState.onboardingCompleted) {
      // Hide nav bar during onboarding
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      });
      return const FastingOnboardingScreen();
    } else {
      // Show nav bar when onboarding is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxScrolled) {
            return [
              // App bar with tabs
              SliverAppBar(
                backgroundColor: backgroundColor,
                pinned: true,
                floating: true,
                title: Text(
                  'Fasting',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                actions: [
                  // Streak indicator
                  if (fastingState.streak != null &&
                      fastingState.streak!.currentStreak > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${fastingState.streak!.currentStreak}',
                            style: TextStyle(
                              color: purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: textMuted,
                      dividerHeight: 0,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: const [
                        Tab(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timer_outlined, size: 18),
                              SizedBox(width: 6),
                              Text('Timer'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 18),
                              SizedBox(width: 6),
                              Text('History'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Timer Tab
              _buildTimerTab(
                context,
                fastingState,
                userId,
                isDark,
                purple,
                textPrimary,
                textMuted,
                elevated,
              ),
              // History Tab
              _buildHistoryTab(
                context,
                fastingState,
                userId,
                isDark,
                purple,
                textPrimary,
                textMuted,
              ),
            ],
          ),
        ),
      ),
      // FAB removed - Start Fast button is now in the center of the timer dial
    );
  }

  Widget _buildTimerTab(
    BuildContext context,
    FastingState fastingState,
    String? userId,
    bool isDark,
    Color purple,
    Color textPrimary,
    Color textMuted,
    Color elevated,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Timer Widget with Start button in center
          Container(
            key: _startFastKey,
            child: FastingTimerWidget(
              activeFast: fastingState.activeFast,
              onEndFast: userId != null
                  ? () => _showEndFastDialog(context, userId)
                  : null,
              onStartFast: userId != null
                  ? () => _showStartFastSheet(context, userId)
                  : null,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 24),

          // Zone Timeline (only when fasting)
          if (fastingState.hasFast) ...[
            FastingZoneTimeline(
              activeFast: fastingState.activeFast!,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],

          // Quick Stats Card
          if (fastingState.stats != null)
            FastingStatsCard(
              stats: fastingState.stats!,
              streak: fastingState.streak,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    FastingState fastingState,
    String? userId,
    bool isDark,
    Color purple,
    Color textPrimary,
    Color textMuted,
  ) {
    if (fastingState.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: purple.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No fasting history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first fast to see it here',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return FastingHistoryList(
      history: fastingState.history,
      isDark: isDark,
      onLoadMore: userId != null
          ? () => ref.read(fastingProvider.notifier).refreshHistory(userId)
          : null,
    );
  }

  void _showStartFastSheet(BuildContext context, String? userId) {
    if (userId == null) return;

    final preferences = ref.read(fastingProvider).preferences;
    HapticService.light();

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StartFastSheet(
        userId: userId,
        defaultProtocol: preferences?.defaultProtocol != null
            ? FastingProtocol.fromString(preferences!.defaultProtocol)
            : null,
        onStartFast: (protocol, customMinutes, startTime) async {
          await ref.read(fastingProvider.notifier).startFast(
                userId: userId,
                protocol: protocol,
                customDurationMinutes: customMinutes,
                startTime: startTime,
              );

          // Start timer service monitoring
          final activeFast = ref.read(fastingProvider).activeFast;
          if (activeFast != null) {
            ref.read(fastingTimerServiceProvider).startZoneMonitoring(activeFast);
            ref.read(fastingTimerServiceProvider).showFastStartedNotification(protocol);
          }

          if (mounted) Navigator.pop(context);
        },
      ),
    ).then((_) {
      // Show nav bar when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  void _showEndFastDialog(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final fastingState = ref.read(fastingProvider);

    HapticService.light();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        title: Text(
          'End Fast?',
          style: TextStyle(color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve been fasting for ${fastingState.elapsedTimeFormatted}',
              style: TextStyle(color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              fastingState.activeFast != null &&
                      fastingState.activeFast!.progress >= 0.8
                  ? 'Great progress! You\'re almost at your goal.'
                  : 'Ending now will record your progress.',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Fasting',
              style: TextStyle(
                color: isDark ? AppColors.purple : AppColorsLight.purple,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result =
                  await ref.read(fastingProvider.notifier).endFast(userId: userId);
              if (result != null) {
                // Cancel scheduled notifications
                await ref.read(fastingTimerServiceProvider).cancelAllNotifications();
                // Show completion notification
                await ref
                    .read(fastingTimerServiceProvider)
                    .showFastCompletedNotification(result);

                if (mounted) {
                  _showFastCompletedSnackbar(context, result);
                }
              }
            },
            child: const Text(
              'End Fast',
              style: TextStyle(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  void _showFastCompletedSnackbar(BuildContext context, FastEndResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.encouragingMessage),
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
