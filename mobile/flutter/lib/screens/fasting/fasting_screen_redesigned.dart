import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/fasting_timer_service.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/fasting_history_list.dart';
import 'widgets/protocol_selector_sheet.dart';
import 'widgets/fasting_settings_sheet.dart';

/// Premium redesigned fasting screen with crystal-clear UX
///
/// Design principles:
/// - Instant clarity: Status + countdown dominate
/// - Single primary action: Start or End (no confusion)
/// - Above-the-fold hero: All critical info visible without scroll
/// - 8pt spacing grid, 16px corner radius, minimal shadows
/// - Clear language: "Tomorrow" instead of "+1"
class FastingScreenRedesigned extends ConsumerStatefulWidget {
  const FastingScreenRedesigned({super.key});

  @override
  ConsumerState<FastingScreenRedesigned> createState() => _FastingScreenRedesignedState();
}

class _FastingScreenRedesignedState extends ConsumerState<FastingScreenRedesigned>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _initialized = false;

  // Fast configuration
  FastingProtocol _selectedProtocol = FastingProtocol.sixteen8;
  DateTime _startTime = DateTime.now();
  bool _isProcessing = false;

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
      await ref.read(fastingTimerServiceProvider).initialize();
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Guest mode check
    final isGuest = ref.watch(isGuestModeProvider);
    final fastingEnabled = ref.watch(isFastingEnabledProvider);

    if (isGuest && !fastingEnabled) {
      return _buildGuestLockScreen(context, backgroundColor, textPrimary, textSecondary, purple);
    }

    final fastingState = ref.watch(fastingProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    // Loading state
    if (!_initialized || fastingState.isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: purple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal AppBar
            _buildAppBar(context, fastingState, textPrimary, textMuted),

            // Compact TabBar
            _buildTabBar(elevated, purple, textMuted),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Timer Tab (redesigned)
                  _buildTimerTab(
                    context,
                    fastingState,
                    userId,
                    isDark,
                    purple,
                    textPrimary,
                    textSecondary,
                    textMuted,
                    elevated,
                  ),
                  // History Tab (unchanged)
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
          ],
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar(
    BuildContext context,
    FastingState fastingState,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Fasting',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: textMuted,
              size: 24,
            ),
            onPressed: () => _showFastingSettings(context, fastingState),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  // ==================== TAB BAR ====================
  Widget _buildTabBar(Color elevated, Color purple, Color textMuted) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      height: 48,
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
                Icon(Icons.timer_outlined, size: 16),
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
                Icon(Icons.history, size: 16),
                SizedBox(width: 6),
                Text('History'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TIMER TAB (REDESIGNED) ====================
  Widget _buildTimerTab(
    BuildContext context,
    FastingState fastingState,
    String? userId,
    bool isDark,
    Color purple,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color elevated,
  ) {
    final hasFast = fastingState.hasFast;
    final activeFast = fastingState.activeFast;

    // Watch timer for live updates
    final timerValue = ref.watch(fastingTimerProvider);
    final elapsedSeconds = timerValue.value ?? 0;
    final elapsedMinutes = elapsedSeconds ~/ 60;

    // Calculate remaining time
    final goalMinutes = activeFast?.goalDurationMinutes ?? _selectedProtocol.fastingHours * 60;
    final remainingMinutes = hasFast ? (goalMinutes - elapsedMinutes).clamp(0, goalMinutes) : goalMinutes;

    // Calculate end time
    final endTime = hasFast && activeFast != null
        ? activeFast.startedAt.add(Duration(minutes: goalMinutes))
        : _startTime.add(Duration(minutes: goalMinutes));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ========== HERO SECTION ==========
          _buildHeroSection(
            context,
            hasFast,
            activeFast,
            remainingMinutes,
            endTime,
            purple,
            textPrimary,
            textSecondary,
            textMuted,
          ),

          const SizedBox(height: 16),

          // ========== PRIMARY CTA ==========
          _buildPrimaryCTA(
            context,
            hasFast,
            userId,
            purple,
          ),

          const SizedBox(height: 12),

          // ========== SECONDARY ACTION ==========
          if (!hasFast)
            TextButton(
              onPressed: () => _showProtocolSelector(context),
              child: Text(
                'Edit Schedule',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ========== SCHEDULE ROW ==========
          if (!hasFast)
            _buildScheduleRow(
              _startTime,
              endTime,
              elevated,
              textPrimary,
              textMuted,
            ),

          const SizedBox(height: 24),

          // Divider
          Divider(color: textMuted.withValues(alpha: 0.2)),

          const SizedBox(height: 24),

          // ========== STATS SECTION ==========
          _buildStatsSection(
            fastingState,
            elevated,
            purple,
            textPrimary,
            textSecondary,
            textMuted,
          ),
        ],
      ),
    );
  }

  // ========== HERO SECTION ==========
  Widget _buildHeroSection(
    BuildContext context,
    bool hasFast,
    FastingRecord? activeFast,
    int remainingMinutes,
    DateTime endTime,
    Color purple,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    final seconds = hasFast ? ((remainingMinutes * 60) - (hours * 3600 + minutes * 60)) % 60 : 0;

    final statusText = hasFast ? 'Fasting' : 'Not Fasting';
    final countdownText = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final isEndTimeTomorrow = endTime.day != now.day || endTime.month != now.month;
    final endTimeText = hasFast
        ? 'Ends at ${DateFormat('h:mm a').format(endTime)}${isEndTimeTomorrow ? ' Tomorrow' : ''}'
        : 'Ready to start';

    final planText = '${_selectedProtocol.displayName} plan';

    return Column(
      children: [
        // Status Label
        Text(
          statusText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: hasFast ? purple : textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        // Countdown Display (HERO)
        Text(
          countdownText,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -2,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 8),

        // End Time Label
        Text(
          endTimeText,
          style: TextStyle(
            fontSize: 16,
            color: textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        // Plan Chip (tappable)
        if (!hasFast)
          GestureDetector(
            onTap: () => _showProtocolSelector(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: purple.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    planText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: purple,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: purple,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ========== PRIMARY CTA ==========
  Widget _buildPrimaryCTA(
    BuildContext context,
    bool hasFast,
    String? userId,
    Color purple,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing || userId == null
            ? null
            : () {
                if (hasFast) {
                  _showEndFastDialog(context, userId);
                } else {
                  _startFast(userId);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: purple.withValues(alpha: 0.5),
        ),
        child: _isProcessing
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
                  Icon(
                    hasFast ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasFast ? 'End Fast' : 'Start Fast',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ========== SCHEDULE ROW ==========
  Widget _buildScheduleRow(
    DateTime startTime,
    DateTime endTime,
    Color elevated,
    Color textPrimary,
    Color textMuted,
  ) {
    final now = DateTime.now();
    final isEndTimeTomorrow = endTime.day != now.day || endTime.month != now.month;

    return Row(
      children: [
        Expanded(
          child: _buildScheduleChip(
            icon: Icons.play_arrow,
            label: 'Start ${DateFormat('h:mm a').format(startTime)}',
            elevated: elevated,
            textPrimary: textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScheduleChip(
            icon: Icons.stop_circle_outlined,
            label: 'End ${DateFormat('h:mm a').format(endTime)}${isEndTimeTomorrow ? ' Tomorrow' : ''}',
            elevated: elevated,
            textPrimary: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleChip({
    required IconData icon,
    required String label,
    required Color elevated,
    required Color textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 48,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: textPrimary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ========== STATS SECTION ==========
  Widget _buildStatsSection(
    FastingState fastingState,
    Color elevated,
    Color purple,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final stats = fastingState.stats;
    final hasStats = stats != null && stats.totalCompleted > 0;

    if (!hasStats) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: elevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Start your first fast to build stats',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.local_fire_department,
          value: '${fastingState.streak?.currentStreak ?? 0}',
          label: 'Streak',
          elevated: elevated,
          purple: purple,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _buildStatCard(
          icon: Icons.check_circle_outline,
          value: '${stats.totalCompleted}',
          label: 'Total Fasts',
          elevated: elevated,
          purple: purple,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _buildStatCard(
          icon: Icons.schedule,
          value: '${stats.averageDurationHours.toStringAsFixed(1)}h',
          label: 'Avg Duration',
          elevated: elevated,
          purple: purple,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _buildStatCard(
          icon: Icons.star_outline,
          value: '${stats.longestDurationHours.toStringAsFixed(1)}h',
          label: 'Longest Fast',
          elevated: elevated,
          purple: purple,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color elevated,
    required Color purple,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: purple),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HISTORY TAB ====================
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: textMuted,
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FastingHistoryList(
      history: fastingState.history,
      isDark: isDark,
    );
  }

  // ==================== GUEST LOCK SCREEN ====================
  Widget _buildGuestLockScreen(
    BuildContext context,
    Color backgroundColor,
    Color textPrimary,
    Color textSecondary,
    Color purple,
  ) {
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

  // ==================== ACTIONS ====================
  Future<void> _startFast(String userId) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticService.medium();

    try {
      final durationMinutes = _selectedProtocol.fastingHours * 60;
      await ref.read(fastingProvider.notifier).startFast(
            userId: userId,
            protocol: _selectedProtocol,
            startTime: _startTime,
            goalDurationMinutes: durationMinutes,
          );

      // Start the timer service
      await ref.read(fastingTimerServiceProvider).startTimer(
            ref.read(fastingProvider).activeFast!,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start fast: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showEndFastDialog(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'End Fast?',
            style: TextStyle(color: textPrimary),
          ),
          content: Text(
            'Are you sure you want to end your fast now?',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _endFast(userId);
              },
              child: const Text('End Fast'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _endFast(String userId) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticService.medium();

    try {
      await ref.read(fastingProvider.notifier).endFast(userId);
      await ref.read(fastingTimerServiceProvider).stopTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end fast: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showProtocolSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProtocolSelectorSheet(
        selectedProtocol: _selectedProtocol,
        onProtocolSelected: (protocol) {
          setState(() {
            _selectedProtocol = protocol;
          });
          Navigator.of(context).pop();
        },
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  void _showFastingSettings(BuildContext context, FastingState fastingState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FastingSettingsSheet(
        currentSettings: fastingState.settings,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }
}
