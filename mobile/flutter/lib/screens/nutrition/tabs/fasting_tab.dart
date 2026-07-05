import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/providers/guest_mode_provider.dart';
import '../../../data/providers/guest_usage_limits_provider.dart';
import '../../../data/services/fasting_timer_service.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../fasting/widgets/protocol_selector_sheet.dart';
import '../../fasting/widgets/fasting_settings_sheet.dart';
import '../../fasting/widgets/fasting_history_list.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Full Fasting tab for the nutrition screen - complete fasting experience with Timer + History tabs
class FastingTab extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const FastingTab({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<FastingTab> createState() => _FastingTabState();
}

class _FastingTabState extends ConsumerState<FastingTab>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _initialized = false;
  bool _isProcessing = false;
  bool _tabControllerInitialized = false;

  // Fast configuration
  FastingProtocol _selectedProtocol = FastingProtocol.sixteen8;
  int _customHours = 16;
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabControllerInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (widget.userId.isNotEmpty) {
      await ref.read(fastingProvider.notifier).initialize(widget.userId);
      await ref.read(fastingTimerServiceProvider).initialize();
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor =
        widget.isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast =
        widget.isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final hairline =
        widget.isDark ? AppColors.hairline : AppColorsLight.cardBorder;
    final cardBorder =
        widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final surface =
        widget.isDark ? AppColors.surface : AppColorsLight.surface;

    // Guest mode check
    final isGuest = ref.watch(isGuestModeProvider);
    final fastingEnabled = ref.watch(isFastingEnabledProvider);

    if (isGuest && !fastingEnabled) {
      return _buildGuestLockState(
        textPrimary,
        textSecondary,
        accentColor,
        accentContrast,
      );
    }

    final fastingState = ref.watch(fastingProvider);

    // Loading state - also check if tab controller is ready
    if (!_initialized || fastingState.isLoading || !_tabControllerInitialized || _tabController == null) {
      return Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    return Column(
      children: [
        // Fasting TabBar (Timer / History)
        _buildFastingTabBar(elevated, accentColor, accentContrast, textMuted),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: [
              // Timer Tab
              _buildTimerTab(
                fastingState,
                accentColor,
                accentContrast,
                textPrimary,
                textSecondary,
                textMuted,
                elevated,
                hairline,
                cardBorder,
                surface,
              ),
              // History Tab
              _buildHistoryTab(
                fastingState,
                accentColor,
                textPrimary,
                textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB BAR ====================
  Widget _buildFastingTabBar(
      Color elevated, Color accentColor, Color accentContrast, Color textMuted) {
    final fastingState = ref.watch(fastingProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        children: [
          // Tab Bar
          Expanded(
            child: SegmentedTabBar(
              controller: _tabController!,
              showIcons: false,
              tabs: [
                SegmentedTabItem(label: AppLocalizations.of(context).fastingTimer, icon: Icons.timer_outlined),
                SegmentedTabItem(label: AppLocalizations.of(context).workoutHistory, icon: Icons.history),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Settings button
          GestureDetector(
            onTap: () => _showFastingSettings(context, fastingState),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.surface : AppColorsLight.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.cardBorder
                      : AppColorsLight.cardBorder,
                ),
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 20,
                color: textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TIMER TAB ====================
  Widget _buildTimerTab(
    FastingState fastingState,
    Color accentColor,
    Color accentContrast,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color elevated,
    Color hairline,
    Color cardBorder,
    Color surface,
  ) {
    final hasFast = fastingState.hasFast;
    final activeFast = fastingState.activeFast;

    // Watch timer for live updates
    final timerValue = ref.watch(fastingTimerProvider);
    final elapsedSeconds = timerValue.value ?? 0;
    final elapsedMinutes = elapsedSeconds ~/ 60;

    // Calculate remaining time
    final goalMinutes =
        activeFast?.goalDurationMinutes ?? _selectedProtocol.fastingHours * 60;
    final remainingMinutes =
        hasFast ? (goalMinutes - elapsedMinutes).clamp(0, goalMinutes) : goalMinutes;

    // Calculate end time
    final endTime = hasFast && activeFast != null
        ? activeFast.startTime.add(Duration(minutes: goalMinutes))
        : _startTime.add(Duration(minutes: goalMinutes));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Section
          _buildHeroSection(
            hasFast,
            activeFast,
            remainingMinutes,
            endTime,
            accentColor,
            textPrimary,
            textSecondary,
            textMuted,
            surface: surface,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // Primary CTA
          _buildPrimaryCTA(
            hasFast,
            accentColor,
            accentContrast,
          ),

          const SizedBox(height: 12),

          // Secondary Action
          if (!hasFast)
            TextButton(
              onPressed: () => _showProtocolSelector(context),
              child: Text(
                AppLocalizations.of(context).fastingEditSchedule,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Schedule Row
          if (!hasFast)
            _buildScheduleRow(
              _startTime,
              endTime,
              surface,
              cardBorder,
              textPrimary,
              textMuted,
            ),

          const SizedBox(height: 24),

          // Signature hairline rule separating hero/CTA from stats.
          Divider(color: hairline, height: 1, thickness: 1),

          const SizedBox(height: 24),

          // Stats Section
          _buildStatsSection(
            fastingState,
            surface,
            cardBorder,
            hairline,
            accentColor,
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
    bool hasFast,
    FastingRecord? activeFast,
    int remainingMinutes,
    DateTime endTime,
    Color accentColor,
    Color textPrimary,
    Color textSecondary,
    Color textMuted, {
    Color? surface,
    Color? cardBorder,
  }) {
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    final seconds = hasFast
        ? ((remainingMinutes * 60) - (hours * 3600 + minutes * 60)) % 60
        : 0;

    final statusText = hasFast ? 'Fasting' : 'Not Fasting';
    final countdownText =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final isEndTimeTomorrow =
        endTime.day != now.day || endTime.month != now.month;
    final endTimeText = hasFast
        ? 'Ends at ${DateFormat('h:mm a').format(endTime)}${isEndTimeTomorrow ? ' Tomorrow' : ''}'
        : 'Ready to start';

    final planText = '${_selectedProtocol.displayName} plan';

    return Column(
      children: [
        // Status Label — Barlow uppercase kicker.
        Text(
          statusText.toUpperCase(),
          style: ZType.lbl(
            14,
            color: hasFast ? accentColor : textMuted,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 12),

        // Countdown Display (HERO) — Anton display numerals.
        Text(
          countdownText,
          style: ZType.disp(
            58,
            color: textPrimary,
            letterSpacing: 0,
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
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardBorder ?? accentColor.withValues(alpha: 0.3),
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
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: textMuted,
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
    bool hasFast,
    Color accentColor,
    Color accentContrast,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing || widget.userId.isEmpty
            ? null
            : () {
                if (hasFast) {
                  _showEndFastDialog(context, widget.userId);
                } else {
                  _startFast(widget.userId);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: accentContrast,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
        ),
        child: _isProcessing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: accentContrast,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasFast
                        ? Icons.stop_circle_outlined
                        : Icons.play_arrow_rounded,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasFast ? AppLocalizations.of(context).heroFastingCardEndFast : AppLocalizations.of(context).heroFastingCardStartFast,
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
    Color surface,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final now = DateTime.now();
    final isEndTimeTomorrow =
        endTime.day != now.day || endTime.month != now.month;

    return Row(
      children: [
        Expanded(
          child: _buildScheduleChip(
            icon: Icons.play_arrow,
            label: 'Start ${DateFormat('h:mm a').format(startTime)}',
            surface: surface,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScheduleChip(
            icon: Icons.stop_circle_outlined,
            label:
                'End ${DateFormat('h:mm a').format(endTime)}${isEndTimeTomorrow ? ' Tomorrow' : ''}',
            surface: surface,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleChip({
    required IconData icon,
    required String label,
    required Color surface,
    required Color cardBorder,
    required Color textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 48,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
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
    Color surface,
    Color cardBorder,
    Color hairline,
    Color accentColor,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final stats = fastingState.stats;
    final hasStats = stats != null && stats.completedFasts > 0;

    if (!hasStats) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hairline),
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
              AppLocalizations.of(context).fastingStartYourFirstFast,
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
          label: AppLocalizations.of(context).xpProgressCardStreak,
          surface: surface,
          cardBorder: cardBorder,
          accentColor: accentColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _buildStatCard(
          icon: Icons.check_circle_outline,
          value: '${stats.completedFasts}',
          label: AppLocalizations.of(context).fastingTotalFasts,
          surface: surface,
          cardBorder: cardBorder,
          accentColor: accentColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _buildStatCard(
          icon: Icons.schedule,
          value: '${(stats.avgDurationMinutes / 60).toStringAsFixed(1)}h',
          label: AppLocalizations.of(context).fastingScreenRedesignedAvgDuration,
          surface: surface,
          cardBorder: cardBorder,
          accentColor: accentColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _buildStatCard(
          icon: Icons.star_outline,
          value: '${(stats.longestFastMinutes / 60).toStringAsFixed(1)}h',
          label: AppLocalizations.of(context).fastingScreenRedesignedLongestFast,
          surface: surface,
          cardBorder: cardBorder,
          accentColor: accentColor,
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
    required Color surface,
    required Color cardBorder,
    required Color accentColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: textMuted),
          const SizedBox(height: 8),
          // Anton display numeral.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: ZType.disp(24, color: textPrimary, letterSpacing: 0),
            ),
          ),
          const SizedBox(height: 4),
          // Barlow uppercase label.
          Text(
            label.toUpperCase(),
            style: ZType.lbl(11, color: textMuted, letterSpacing: 1.5),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== HISTORY TAB ====================
  Widget _buildHistoryTab(
    FastingState fastingState,
    Color accentColor,
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
                AppLocalizations.of(context).fastingScreenRedesignedNoFastingHistoryYet,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).fastingCompleteYourFirstFast,
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
      isDark: widget.isDark,
    );
  }

  // ==================== GUEST LOCK STATE ====================
  Widget _buildGuestLockState(
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    Color accentContrast,
  ) {
    return Center(
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
              AppLocalizations.of(context).fastingScreenRedesignedFastingTracker,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).fastingTrackYourIntermittentFastin,
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
                  await ref
                      .read(guestModeProvider.notifier)
                      .exitGuestMode(convertedToSignup: true);
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch, size: 20),
                    SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).progressSignUpToUnlock,
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
    );
  }

  // ==================== ACTIONS ====================
  Future<void> _startFast(String userId) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticService.medium();

    try {
      ref.read(posthogServiceProvider).capture(
        eventName: 'fast_started',
        properties: <String, Object>{'protocol': _selectedProtocol.displayName},
      );
      final durationMinutes = _selectedProtocol.fastingHours * 60;
      await ref.read(fastingProvider.notifier).startFast(
            userId: userId,
            protocol: _selectedProtocol,
            startTime: _startTime,
            customDurationMinutes: durationMinutes,
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
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context).fastingEndFast,
            style: TextStyle(color: textPrimary),
          ),
          content: Text(
            AppLocalizations.of(context).fastingAreYouSureYou,
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).buttonCancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _endFast(userId);
              },
              child: Text(AppLocalizations.of(context).heroFastingCardEndFast),
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
      await ref.read(fastingProvider.notifier).endFast(userId: userId);
      ref.read(posthogServiceProvider).capture(
        eventName: 'fast_completed',
        properties: <String, Object>{},
      );
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
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showFastingSettings(BuildContext context, FastingState fastingState) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: FastingSettingsSheet(
          preferences:
              fastingState.preferences ?? const FastingPreferences(userId: ''),
        ),
      ),
    );
  }
}
