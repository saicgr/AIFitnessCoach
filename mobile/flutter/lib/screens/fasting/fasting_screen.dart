import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/fasting_timer_service.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/pill_swipe_navigation.dart';
import 'widgets/fasting_timer_widget.dart';
import 'widgets/fasting_zone_timeline.dart';
import 'widgets/fasting_stats_card.dart';
import 'widgets/fasting_score_card.dart';
import 'widgets/fasting_history_list.dart';
import 'widgets/start_fast_sheet.dart';
import 'widgets/protocol_selector_chip.dart';
import 'widgets/protocol_selector_sheet.dart';
import 'widgets/time_schedule_row.dart';
import 'widgets/fasting_settings_sheet.dart';

/// Fasting tracker screen with timer and zone visualization
class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen>
    with SingleTickerProviderStateMixin, PillSwipeNavigationMixin {
  // PillSwipeNavigationMixin: Fasting is index 3
  @override
  int get currentPillIndex => 3;

  late TabController _tabController;
  bool _initialized = false;

  // Inline fast configuration state
  FastingProtocol _selectedProtocol = FastingProtocol.sixteen8;
  int _customHours = 16;
  DateTime _startTime = DateTime.now();
  bool _isStartingFast = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
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
    // Use monochrome accent instead of purple
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
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
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 48,
                      color: accentColor,
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
                        backgroundColor: accentColor,
                        foregroundColor: accentContrast,
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
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: wrapWithSwipeDetector(
        child: SafeArea(
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
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
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
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Settings icon
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: textMuted,
                      size: 24,
                    ),
                    onPressed: () => _showFastingSettings(context, fastingState),
                    tooltip: 'Fasting Settings',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: SegmentedTabBar(
                  controller: _tabController,
                  showIcons: false,
                  tabs: [
                    SegmentedTabItem(label: 'Timer', icon: Icons.timer_outlined),
                    SegmentedTabItem(label: 'History', icon: Icons.history),
                  ],
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
                accentColor,
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
                accentColor,
                textPrimary,
                textMuted,
              ),
            ],
          ),
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
    Color accentColor,
    Color textPrimary,
    Color textMuted,
    Color elevated,
  ) {
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final hasFast = fastingState.hasFast;
    final durationMinutes = _selectedProtocol == FastingProtocol.custom
        ? _customHours * 60
        : _selectedProtocol.fastingHours * 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          // Protocol Selector (only when not fasting)
          if (!hasFast) ...[
            ProtocolSelectorChip(
              selectedProtocol: _selectedProtocol,
              onTap: () => _showProtocolSelector(context),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],

          // Timer Widget with Start button in center
          FastingTimerWidget(
            activeFast: fastingState.activeFast,
            onEndFast: userId != null
                ? () => _showEndFastDialog(context, userId)
                : null,
            onStartFast: userId != null && !hasFast
                ? () => _startFastDirectly(userId)
                : null,
            isDark: isDark,
          ),

          // Inline controls (only when not fasting)
          if (!hasFast) ...[
            const SizedBox(height: 12),

            // Time Schedule Row
            TimeScheduleRow(
              startTime: _startTime,
              durationMinutes: durationMinutes,
              onStartTimeChanged: (newTime) {
                setState(() => _startTime = newTime);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Start Fast Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isStartingFast || userId == null
                      ? null
                      : () => _startFastDirectly(userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: accentContrast,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                  ),
                  child: _isStartingFast
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Start Fast',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 24),
          ],

          // Zone Timeline (only when fasting)
          if (hasFast) ...[
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
              score: fastingState.score,
              scoreTrend: fastingState.scoreTrend,
              weightCorrelation: fastingState.weightCorrelation,
              isDark: isDark,
              onScoreTap: fastingState.score != null
                  ? () => _showScoreDetails(context, fastingState.score!)
                  : null,
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
    Color accentColor,
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
              color: accentColor.withValues(alpha: 0.3),
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

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StartFastSheet(
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
      ),
    ).then((_) {
      // Show nav bar when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  /// Show the protocol selector sheet
  void _showProtocolSelector(BuildContext context) {
    HapticService.light();

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: ProtocolSelectorSheet(
          currentProtocol: _selectedProtocol,
          currentCustomHours: _customHours,
          onSelect: (protocol, customHours) {
            setState(() {
              _selectedProtocol = protocol;
              if (customHours != null) {
                _customHours = customHours;
              }
            });
          },
        ),
      ),
    );
  }

  /// Start fast directly without the full sheet
  Future<void> _startFastDirectly(String userId) async {
    if (_isStartingFast) return;

    setState(() => _isStartingFast = true);
    HapticService.medium();

    try {
      final customMinutes = _selectedProtocol == FastingProtocol.custom
          ? _customHours * 60
          : null;

      // Check if start time is in the future (scheduled) or now
      final now = DateTime.now();
      final isScheduled = _startTime.isAfter(now.add(const Duration(minutes: 1)));
      final startTime = isScheduled ? _startTime : null;

      await ref.read(fastingProvider.notifier).startFast(
            userId: userId,
            protocol: _selectedProtocol,
            customDurationMinutes: customMinutes,
            startTime: startTime,
          );

      // Start timer service monitoring
      final activeFast = ref.read(fastingProvider).activeFast;
      if (activeFast != null) {
        ref.read(fastingTimerServiceProvider).startZoneMonitoring(activeFast);
        ref.read(fastingTimerServiceProvider).showFastStartedNotification(_selectedProtocol);
      }

      // Reset start time for next fast
      if (mounted) {
        setState(() {
          _startTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start fast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingFast = false);
      }
    }
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
                color: isDark ? AppColors.accent : AppColorsLight.accent,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // End fast BEFORE closing dialog to ensure proper context
              final result =
                  await ref.read(fastingProvider.notifier).endFast(userId: userId);

              if (!context.mounted) return;
              Navigator.pop(context);

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
              } else {
                // Show error if endFast failed
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to end fast. Please try again.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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

  /// Show detailed fasting score breakdown in a bottom sheet
  void _showScoreDetails(BuildContext context, FastingScore score) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final fastingState = ref.read(fastingProvider);

    HapticService.light();

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score card with full breakdown
              FastingScoreCard(
                score: score,
                trend: fastingState.scoreTrend,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show fasting settings bottom sheet
  void _showFastingSettings(BuildContext context, FastingState fastingState) {
    // Create default preferences if none exist
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    final preferences = fastingState.preferences ?? FastingPreferences(
      userId: userId,
      defaultProtocol: '16:8',
    );

    HapticService.light();

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: FastingSettingsSheet(preferences: preferences),
      ),
    );
  }
}
