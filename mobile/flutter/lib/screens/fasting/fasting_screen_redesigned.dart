import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/line_icon.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/fasting_timer_service.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/main_shell.dart';
import 'widgets/fasting_ai_insight_card.dart';
import 'widgets/fasting_date_strip.dart';
import 'widgets/fasting_edit_sheet.dart';
import 'widgets/fasting_history_list.dart';
import 'widgets/fasting_hydration_row.dart';
import 'widgets/fasting_mood_checkin.dart';
import 'widgets/fasting_plan_cards.dart';
import 'widgets/fasting_stage_card.dart';
import 'widgets/fasting_stage_model.dart';
import 'widgets/fasting_stage_timer.dart';
import 'widgets/protocol_selector_sheet.dart';
import 'widgets/fasting_settings_sheet.dart';

/// Premium redesigned fasting screen.
///
/// - Live ticking H:MM:SS timer with a segmented metabolic-stage ring.
/// - Per-stage central visual + stage indicator card.
/// - Single continuous scroll: timer hero → stats → History (no tabs).
/// - Floating glass back button, instant first paint with background init.
class FastingScreenRedesigned extends ConsumerStatefulWidget {
  const FastingScreenRedesigned({super.key});

  @override
  ConsumerState<FastingScreenRedesigned> createState() =>
      _FastingScreenRedesignedState();
}

class _FastingScreenRedesignedState
    extends ConsumerState<FastingScreenRedesigned> {
  // Fast configuration (used while not fasting).
  FastingProtocol _selectedProtocol = FastingProtocol.sixteen8;
  int _customHours = 16;
  DateTime _startTime = DateTime.now();
  bool _isProcessing = false;

  /// Date-strip selection (Section B). Defaults to today (live timer view).
  /// A past day swaps the timer for that day's completed-fast summary.
  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  /// True once the scheduled protocol has been applied for this session, so a
  /// user override is not clobbered on rebuild (Task G).
  bool _appliedScheduledProtocol = false;

  /// Captured ProviderContainer — used in [dispose] to safely restore the
  /// floating nav bar. Reading the container off `context` in `dispose()`
  /// throws ("deactivated widget"), so we grab it in didChangeDependencies.
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    // Render immediately; do all heavy init off the first frame so the
    // screen never blocks on a spinner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'fasting_viewed');
      ref.read(navBarLabelsExpandedProvider.notifier).state = false;
      // Fix #2: hide the floating bottom nav bar while this pushed
      // full screen is open.
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      _initializeInBackground();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the container now so dispose() can safely restore the nav bar
    // even after this widget is deactivated.
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    // Fix #2: restore the floating nav bar on exit. Setting provider state
    // SYNCHRONOUSLY here throws StateNotifierListenerError — dispose() runs
    // during the locked finalizeTree phase and MainShell listens to this
    // provider. Defer to a microtask: the captured container outlives this
    // widget, and the restore then runs after the tree is unlocked.
    final container = _container;
    if (container != null) {
      Future.microtask(() {
        try {
          container.read(floatingNavBarVisibleProvider.notifier).state = true;
        } catch (_) {/* container torn down — nav bar already moot */}
      });
    }
    super.dispose();
  }

  /// Heavy init (provider data + timer service) runs in the background.
  /// The provider keeps an in-memory cache, so cached state shows instantly
  /// and this just refreshes it; no `setState`/gating involved.
  Future<void> _initializeInBackground() async {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;
    // initialize() is a no-op if already loaded for this user.
    unawaitedSafe(ref.read(fastingProvider.notifier).initialize(userId));
    unawaitedSafe(ref.read(fastingTimerServiceProvider).initialize());
    // Re-arm the live fast surface if a fast is already running (e.g. the
    // app was killed and re-opened mid-fast).
    unawaitedSafe(() async {
      await ref.read(fastingProvider.notifier).initialize(userId);
      final active = ref.read(fastingProvider).activeFast;
      if (active != null && active.isActive) {
        final svc = ref.read(fastingTimerServiceProvider);
        await svc.initialize();
        await svc.startLiveSurface(
          active,
          notificationsEnabled: _fastingNotificationsEnabled,
        );
      }
    }());
  }

  /// Fire-and-forget a future without surfacing the unawaited lint.
  void unawaitedSafe(Future<void> future) {
    future.catchError((_) {});
  }

  /// Whether the user has fasting notifications enabled — gates the ongoing
  /// live fast surface (actionable notification + iOS Live Activity).
  /// Defaults to `true` when preferences haven't loaded yet.
  bool get _fastingNotificationsEnabled =>
      ref.read(fastingProvider).preferences?.notificationsEnabled ?? true;

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);

    // Guest gate.
    final isGuest = ref.watch(isGuestModeProvider);
    final fastingEnabled = ref.watch(isFastingEnabledProvider);
    if (isGuest && !fastingEnabled) {
      return _buildGuestLockScreen(context, colors);
    }

    final fastingState = ref.watch(fastingProvider);
    final userId = ref.watch(authStateProvider).user?.id;

    // Task G: pre-select today's scheduled protocol (once, non-overriding).
    _maybeApplyScheduledProtocol(fastingState);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── Main scroll ──────────────────────────────────────────
            CustomScrollView(
              slivers: [
                // Header (leaves room for the floating back button).
                SliverToBoxAdapter(
                  child: _buildHeader(context, fastingState, colors),
                ),
                // Week date strip (Section B).
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: FastingDateStrip(
                      selectedDay: _selectedDay,
                      records: _allDayRecords(fastingState),
                      onDaySelected: (day) =>
                          setState(() => _selectedDay = day),
                    ),
                  ),
                ),
                // Timer hero + stats (or a past day's summary).
                SliverToBoxAdapter(
                  child: _buildTimerSection(
                      context, fastingState, userId, colors),
                ),
                // History section header + list, on the same scroll.
                _buildHistorySliver(fastingState, colors),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 96,
                  ),
                ),
              ],
            ),
            // ── Floating glass back button ──────────────────────────
            Positioned(
              top: 8,
              left: 12,
              child: GlassBackButton(onTap: () => context.go('/home')),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(
    BuildContext context,
    FastingState fastingState,
    ThemeColors colors,
  ) {
    final streak = fastingState.streak;
    return Padding(
      // Left padding clears the 40px floating back button.
      padding: const EdgeInsets.fromLTRB(64, 12, 12, 4),
      child: Row(
        children: [
          Text(
            'Fasting',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const Spacer(),
          if (streak != null && streak.currentStreak > 0)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Text(
                    '${streak.currentStreak}',
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          // Fasting Guide entry (Task H) — placed BEFORE the settings gear.
          IconButton(
            icon: Icon(Icons.help_outline_rounded,
                color: colors.textMuted, size: 24),
            onPressed: () {
              HapticService.light();
              context.push('/fasting/guide');
            },
            tooltip: 'Fasting guide',
          ),
          IconButton(
            icon: LineIcon('custom_trend',
                color: colors.textMuted, size: 24),
            onPressed: () {
              HapticService.light();
              context.push('/trends/custom',
                  extra: TrendMetric.fastingHours);
            },
            tooltip: 'View trends',
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: colors.textMuted, size: 24),
            onPressed: () => _showFastingSettings(context, fastingState),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  /// All records relevant to the date strip — completed history plus the
  /// in-progress fast (so today's dot reflects an active fast too).
  List<FastingRecord> _allDayRecords(FastingState state) {
    final active = state.activeFast;
    return [
      ...state.history,
      if (active != null) active,
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _selectedIsToday {
    final now = DateTime.now();
    return _isSameDay(_selectedDay, DateTime(now.year, now.month, now.day));
  }

  // ==================== TIMER SECTION ====================
  Widget _buildTimerSection(
    BuildContext context,
    FastingState fastingState,
    String? userId,
    ThemeColors colors,
  ) {
    // Section B: a past day shows that day's fast summary instead of the
    // live timer. Today keeps the live timer (default).
    if (!_selectedIsToday) {
      return _buildPastDaySection(fastingState, colors);
    }

    final hasFast = fastingState.hasFast;
    final activeFast = fastingState.activeFast;

    // Live timer tick — rebuilds every second. The raw provider value is
    // `now - startTime`; it does NOT account for paused time, so we subtract
    // the fast's total paused seconds here. While paused this freezes the
    // displayed elapsed time (the deduction grows in lock-step with the
    // raw tick), which is what makes "Pause Fast" visibly do something.
    final rawElapsed = ref.watch(fastingTimerProvider).value ?? 0;
    final isPausedNow = activeFast?.isPaused ?? false;
    final elapsedSeconds = hasFast && activeFast != null
        ? (rawElapsed - activeFast.totalPausedSeconds)
            .clamp(0, rawElapsed)
        : rawElapsed;

    final goalMinutes = activeFast?.goalDurationMinutes ??
        (_selectedProtocol == FastingProtocol.custom
            ? _customHours * 60
            : _selectedProtocol.fastingHours * 60);

    // Current metabolic stage.
    final stage = hasFast
        ? FastingStage.forElapsedHours(elapsedSeconds / 3600.0)
        : FastingStage.fed;

    // Times.
    //
    // Fix #1: derive the displayed start from the LIVE elapsed seconds rather
    // than formatting `activeFast.startTime` directly. The backend serializes
    // `start_time` as a naive UTC timestamp, so `DateTime.parse` produces a
    // DateTime whose wall-clock value is UTC but whose `isUtc` flag is false —
    // `DateFormat.format()` then renders it shifted by the device's UTC
    // offset (e.g. a 10:08 PM start showing as "2:51 AM Tomorrow").
    // The fasting timer already computes elapsed correctly via
    // `DateTime.now().difference(startTime)`, so reconstructing the start as
    // `now - elapsed` yields the real start in guaranteed device-local time.
    // Use RAW elapsed (not pause-adjusted) — the wall-clock start time does
    // not move when the fast is paused.
    final DateTime startTime;
    if (hasFast && activeFast != null) {
      startTime = DateTime.now()
          .subtract(Duration(seconds: rawElapsed));
    } else {
      startTime = _startTime;
    }
    final endTime = startTime.add(Duration(minutes: goalMinutes));

    final remainingSeconds =
        hasFast ? (goalMinutes * 60 - elapsedSeconds) : goalMinutes * 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // Today's plan banner from the weekly schedule (Task G).
          if (!hasFast) _buildTodaysPlanBanner(fastingState, colors),

          // Status label.
          Text(
            hasFast
                ? (isPausedNow ? 'Fast Paused' : 'Fasting')
                : 'Not Fasting',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: hasFast
                  ? (isPausedNow ? colors.warning : stage.color)
                  : colors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Live stage timer. While paused, a "Paused" chip overlays the ring
          // and the elapsed value is frozen (see elapsedSeconds above).
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FastingStageTimer(
                elapsedSeconds: elapsedSeconds,
                goalMinutes: goalMinutes,
                isActive: hasFast,
                stage: stage,
              ),
              if (isPausedNow)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.warning.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle_filled_rounded,
                            size: 15, color: colors.warning),
                        const SizedBox(width: 5),
                        Text(
                          'Paused',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: colors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // The current stage (name + next-stage hint) is integrated INTO the
          // timer ring itself (see FastingStageTimer), so it's visible on
          // first paint with no separate pill. The full FastingStageCard
          // still renders below for the detailed description.
          const SizedBox(height: 16),

          // Remaining / goal line.
          if (hasFast)
            Text(
              remainingSeconds > 0
                  ? '${_formatHms(remainingSeconds)} until goal'
                  : 'Goal reached — great work!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: remainingSeconds > 0
                    ? colors.textSecondary
                    : colors.success,
              ),
            )
          else
            GestureDetector(
              onTap: () => _showProtocolSelector(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: colors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedProtocol.displayName} plan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_outlined,
                        size: 14, color: colors.accent),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Dated start / end pills.
          _buildScheduleRow(startTime, endTime, colors),
          const SizedBox(height: 16),

          // Primary CTA.
          _buildPrimaryCTA(context, hasFast, userId, stage, colors),

          // Pause / Resume control (Task I) — only while fasting.
          if (hasFast && activeFast != null) ...[
            const SizedBox(height: 10),
            _buildPauseResumeButton(userId, activeFast, colors),
          ],

          // Stage indicator card with the `>` Body Status affordance
          // (Task A) — only while fasting.
          if (hasFast) ...[
            const SizedBox(height: 18),
            FastingStageCard(
              elapsedSeconds: elapsedSeconds,
              stage: stage,
              onOpenBodyStatus: () {
                HapticService.light();
                context.push('/fasting/body-status');
              },
            ),
          ],

          const SizedBox(height: 18),

          // Hydration quick-log (Section E) — wired to the shared
          // hydrationProvider, the same count used app-wide.
          const FastingHydrationRow(),

          const SizedBox(height: 16),

          // AI fasting insight (Section D).
          const FastingAiInsightCard(),

          // Goal-framed plan cards (Section C) — only when not fasting.
          if (!hasFast) ...[
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: FastingPlanCards(
                selectedProtocol: _selectedProtocol,
                onSelect: _onPlanCardSelected,
              ),
            ),
          ],

          const SizedBox(height: 22),

          // Stats — only when there genuinely is history.
          _buildStatsSection(fastingState, colors),
        ],
      ),
    );
  }

  /// Banner surfacing today's scheduled protocol from the weekly schedule
  /// (Task G). Hidden when there is no custom schedule.
  Widget _buildTodaysPlanBanner(
      FastingState fastingState, ThemeColors colors) {
    final prefs = fastingState.preferences;
    if (prefs == null || !prefs.hasWeeklySchedule) {
      return const SizedBox.shrink();
    }
    final planned = prefs.plannedProtocolForToday();
    final isRest = planned == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              isRest
                  ? Icons.restaurant_rounded
                  : Icons.event_available_rounded,
              size: 17,
              color: colors.accent,
            ),
            const SizedBox(width: 8),
            Text(
              isRest ? "Today's plan: " : "Today's plan: ",
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            Text(
              isRest ? 'Rest day' : planned.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pause/Resume control for an active fast (Task I).
  ///
  /// Styled as a deliberate SECONDARY to the End Fast primary: same width,
  /// same 16px radius, a height that reads as a clear sibling button, and a
  /// clean tonal (filled-light) accent surface — never raw orange. When the
  /// fast is paused it flips to a "Resume Fast" affordance.
  Widget _buildPauseResumeButton(
    String? userId,
    FastingRecord activeFast,
    ThemeColors colors,
  ) {
    final paused = activeFast.isPaused;
    final enabled = !_isProcessing && userId != null;
    // Tonal secondary: a soft accent fill with an accent label/icon. Reads
    // unmistakably as a button and pairs cleanly with the primary CTA.
    final tint = colors.accent;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: enabled ? () => _togglePause(userId, paused) : null,
        style: TextButton.styleFrom(
          backgroundColor: tint.withValues(alpha: 0.12),
          foregroundColor: tint,
          disabledBackgroundColor: tint.withValues(alpha: 0.06),
          disabledForegroundColor: tint.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tint.withValues(alpha: 0.28)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 21,
            ),
            const SizedBox(width: 8),
            Text(
              paused ? 'Resume Fast' : 'Pause Fast',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Past-day view (Section B): shows that day's completed fast summary in
  /// place of the live timer, or an honest "No fast yet" empty state.
  Widget _buildPastDaySection(FastingState fastingState, ThemeColors colors) {
    final fasts = FastingDateStrip.fastsForDay(
      _allDayRecords(fastingState),
      _selectedDay,
    );
    final dayLabel = _dayLabel(_selectedDay);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                '$dayLabel · ${DateFormat('MMM d').format(_selectedDay)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (fasts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.no_meals_rounded,
                      size: 44, color: colors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No fast yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You did not log a fast on this day.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            // Multiple fasts in one day are all shown.
            Column(
              children: [
                for (var i = 0; i < fasts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  FastingHistoryCard(
                    record: fasts[i],
                    isDark: colors.isDark,
                    onEdit: () => _showEditFastSheet(fasts[i]),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: () {
                final now = DateTime.now();
                setState(() => _selectedDay =
                    DateTime(now.year, now.month, now.day));
              },
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text('Back to today'),
              style: TextButton.styleFrom(
                foregroundColor: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SCHEDULE ROW (dated) ==========
  Widget _buildScheduleRow(
    DateTime startTime,
    DateTime endTime,
    ThemeColors colors,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildScheduleChip(
            icon: Icons.play_arrow_rounded,
            caption: 'Start',
            dateLabel: _dayLabel(startTime),
            timeLabel: DateFormat('h:mm a').format(startTime),
            colors: colors,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScheduleChip(
            icon: Icons.flag_rounded,
            caption: 'End',
            dateLabel: _dayLabel(endTime),
            timeLabel: DateFormat('h:mm a').format(endTime),
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleChip({
    required IconData icon,
    required String caption,
    required String dateLabel,
    required String timeLabel,
    required ThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                // Date + time, no ellipsis truncation.
                Text(
                  '$dateLabel $timeLabel',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  softWrap: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== COMPACT STAGE SUMMARY (above the fold) ==========
  /// Human day label: "Today", "Tomorrow", "Yesterday" or "May 18".
  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  // ========== PRIMARY CTA ==========
  Widget _buildPrimaryCTA(
    BuildContext context,
    bool hasFast,
    String? userId,
    FastingStage stage,
    ThemeColors colors,
  ) {
    final ctaColor = hasFast ? stage.color : colors.accent;
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
          backgroundColor: ctaColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: ctaColor.withValues(alpha: 0.5),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
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

  // ========== STATS SECTION ==========
  Widget _buildStatsSection(FastingState fastingState, ThemeColors colors) {
    final stats = fastingState.stats;
    final hasStats = stats != null && stats.completedFasts > 0;

    // Fix #5: no empty placeholder during an active fast or with no
    // genuine history. Only render the grid when real stats exist.
    if (!hasStats) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Your stats', colors),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _buildStatCard(
              icon: Icons.local_fire_department,
              value: '${fastingState.streak?.currentStreak ?? 0}',
              label: 'Day Streak',
              colors: colors,
            ),
            _buildStatCard(
              icon: Icons.check_circle_outline,
              value: '${stats.completedFasts}',
              label: 'Total Fasts',
              colors: colors,
            ),
            _buildStatCard(
              icon: Icons.schedule,
              value: '${(stats.avgDurationMinutes / 60).toStringAsFixed(1)}h',
              label: 'Avg Duration',
              colors: colors,
            ),
            _buildStatCard(
              icon: Icons.star_outline,
              value: '${(stats.longestFastMinutes / 60).toStringAsFixed(1)}h',
              label: 'Longest Fast',
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required ThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: colors.accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }

  // ==================== HISTORY SLIVER ====================
  Widget _buildHistorySliver(FastingState fastingState, ThemeColors colors) {
    final history = fastingState.history;
    final activeFast = fastingState.activeFast;
    final hasHistory = history.isNotEmpty;
    // Fix #4: only show the true empty state when there is neither an active
    // fast nor any completed history.
    final showEmptyState = !hasHistory && activeFast == null;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('History', colors),
            const SizedBox(height: 4),
            if (showEmptyState)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history,
                          size: 48, color: colors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No fasting history yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete a fast to see it here',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 12),
                  // Fix #4: surface the in-progress fast as the top entry.
                  if (activeFast != null) ...[
                    _buildInProgressHistoryCard(activeFast, colors),
                    if (hasHistory) const SizedBox(height: 12),
                  ],
                  // Completed fasts below.
                  if (hasHistory)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: history.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => FastingHistoryCard(
                        record: history[index],
                        isDark: colors.isDark,
                        onEdit: () => _showEditFastSheet(history[index]),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// History entry for the currently-active fast, labeled "In progress".
  /// Rebuilds live with the fasting timer so elapsed time stays current.
  Widget _buildInProgressHistoryCard(
    FastingRecord activeFast,
    ThemeColors colors,
  ) {
    // Pause-aware elapsed: the provider value is `now - startTime`, so we
    // deduct the fast's total paused seconds (frozen while paused).
    final rawElapsed = ref.watch(fastingTimerProvider).value ?? 0;
    final elapsedSeconds =
        (rawElapsed - activeFast.totalPausedSeconds).clamp(0, rawElapsed);
    final stage = FastingStage.forElapsedHours(elapsedSeconds / 3600.0);
    final goalMinutes = activeFast.goalDurationMinutes;
    final progress = goalMinutes > 0
        ? (elapsedSeconds / (goalMinutes * 60)).clamp(0.0, 1.0)
        : 0.0;
    // Derive the start in device-local time from live elapsed (see Fix #1).
    // Use the RAW (non-pause-adjusted) elapsed here — the wall-clock start
    // doesn't move when the fast is paused.
    final startTime =
        DateTime.now().subtract(Duration(seconds: rawElapsed));
    final timeFormat = DateFormat('h:mm a');
    final elapsedMinutes = elapsedSeconds ~/ 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stage.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_dayLabel(startTime)} fast',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Started ${timeFormat.format(startTime)} · Ongoing',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stage.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stage.color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'In progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stage.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: stage.color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(stage.color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                _formatDurationMinutes(elapsedMinutes),
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              const SizedBox(width: 12),
              Icon(Icons.flag, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Goal: ${_formatDurationMinutes(goalMinutes)}',
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              const Spacer(),
              if (activeFast.protocol.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activeFast.protocol.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
          // Before → after mood / energy (Task F). On an in-progress fast
          // only the "before" values exist; the delta widget renders "—" for
          // the missing "after" until the fast ends.
          if (activeFast.moodBefore != null ||
              activeFast.energyLevelBefore != null) ...[
            const SizedBox(height: 10),
            MoodEnergyDelta(
              moodBefore: activeFast.moodBefore,
              moodAfter: activeFast.moodAfter,
              energyBefore: activeFast.energyLevelBefore,
              energyAfter: activeFast.energyLevelAfter,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDurationMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  // ==================== GUEST LOCK SCREEN ====================
  Widget _buildGuestLockScreen(BuildContext context, ThemeColors colors) {
    return Scaffold(
      backgroundColor: colors.background,
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
                    color: colors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.timer_outlined,
                      size: 48, color: colors.accent),
                ),
                const SizedBox(height: 24),
                Text(
                  'Fasting Tracker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Track your intermittent fasting with metabolic stage '
                  'insights, smart notifications, and detailed history.',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textSecondary,
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
                      if (mounted) context.go('/pre-auth-quiz');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentContrast,
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
                    style:
                        TextStyle(fontSize: 15, color: colors.textSecondary),
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
  String _formatHms(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }

  /// Handle a tap on a goal-framed plan card (Section C). Custom opens the
  /// protocol selector so the user can set the window length.
  void _onPlanCardSelected(FastingPlanOption plan) {
    if (plan.protocol == FastingProtocol.custom) {
      _showProtocolSelector(context);
      return;
    }
    setState(() => _selectedProtocol = plan.protocol);
  }

  /// Apply today's scheduled protocol as the pre-selected one (Task G).
  /// Runs once per screen session and never overrides an active fast or a
  /// manual user choice.
  void _maybeApplyScheduledProtocol(FastingState fastingState) {
    if (_appliedScheduledProtocol) return;
    if (fastingState.hasFast) return;
    final prefs = fastingState.preferences;
    if (prefs == null || !prefs.hasWeeklySchedule) return;
    final planned = prefs.plannedProtocolForToday();
    _appliedScheduledProtocol = true;
    if (planned != null && planned != FastingProtocol.custom) {
      // Defer so we don't setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedProtocol = planned);
      });
    }
  }

  /// Pause or resume the active fast (Task I).
  Future<void> _togglePause(String userId, bool currentlyPaused) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticService.light();
    try {
      final notifier = ref.read(fastingProvider.notifier);
      if (currentlyPaused) {
        await notifier.resumeFast(userId);
      } else {
        await notifier.pauseFast(userId);
      }
      // Reflect the new pause-state on the live surface immediately.
      final updated = ref.read(fastingProvider).activeFast;
      if (updated != null) {
        unawaitedSafe(ref.read(fastingTimerServiceProvider).updateLiveSurface(
              updated,
              notificationsEnabled: _fastingNotificationsEnabled,
            ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Open the edit-past-fast sheet (Task I).
  void _showEditFastSheet(FastingRecord record) {
    HapticService.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FastingEditSheet(record: record),
    );
  }

  Future<void> _startFast(String userId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticService.medium();
    try {
      final customMinutes = _selectedProtocol == FastingProtocol.custom
          ? _customHours * 60
          : _selectedProtocol.fastingHours * 60;
      final now = DateTime.now();
      final isScheduled =
          _startTime.isAfter(now.add(const Duration(minutes: 1)));
      await ref.read(fastingProvider.notifier).startFast(
            userId: userId,
            protocol: _selectedProtocol,
            startTime: isScheduled ? _startTime : null,
            customDurationMinutes: customMinutes,
          );
      // Start timer service monitoring + notifications + live surface.
      final activeFast = ref.read(fastingProvider).activeFast;
      if (activeFast != null) {
        final svc = ref.read(fastingTimerServiceProvider);
        svc.startZoneMonitoring(activeFast);
        svc.showFastStartedNotification(_selectedProtocol);
        unawaitedSafe(svc.startLiveSurface(
          activeFast,
          notificationsEnabled: _fastingNotificationsEnabled,
        ));
      }
      if (mounted) setState(() => _startTime = DateTime.now());
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// End-fast flow: open the mood + energy check-in sheet (Task F). The sheet
  /// itself confirms the end (its primary CTA is "End Fast"); "Skip" ends with
  /// no mood data.
  void _showEndFastDialog(BuildContext context, String userId) {
    HapticService.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeColors.of(context).elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => FastingMoodCheckInSheet(
        onSubmit: (result) {
          Navigator.of(sheetCtx).pop();
          _endFast(
            userId,
            moodAfter: result.mood?.value,
            energyLevel: result.energyLevel,
          );
        },
      ),
    );
  }

  Future<void> _endFast(
    String userId, {
    String? moodAfter,
    int? energyLevel,
  }) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticService.medium();
    // Capture the fast id BEFORE ending, so Undo can target it (Task I).
    final endedFastId = ref.read(fastingProvider).activeFast?.id;
    try {
      final result = await ref.read(fastingProvider.notifier).endFast(
            userId: userId,
            moodAfter: moodAfter,
            energyLevel: energyLevel,
          );
      if (result != null) {
        final svc = ref.read(fastingTimerServiceProvider);
        await svc.cancelAllNotifications();
        await svc.endLiveSurface();
        await svc.showFastCompletedNotification(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.encouragingMessage),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 8),
              // Undo affordance — accidental-end recovery (Task I).
              action: endedFastId == null
                  ? null
                  : SnackBarAction(
                      label: 'UNDO',
                      onPressed: () => _undoEndFast(userId, endedFastId),
                    ),
            ),
          );
        }
      }
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Undo a just-ended fast — re-opens it within the backend's undo window
  /// (Task I).
  Future<void> _undoEndFast(String userId, String fastId) async {
    HapticService.light();
    final ok = await ref
        .read(fastingProvider.notifier)
        .undoEndFast(userId: userId, fastId: fastId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Fast resumed — your timer is back.'
              : 'Could not undo — the undo window may have passed.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    if (ok) {
      // Re-arm zone monitoring + live surface for the reopened fast.
      final reopened = ref.read(fastingProvider).activeFast;
      if (reopened != null) {
        final svc = ref.read(fastingTimerServiceProvider);
        svc.startZoneMonitoring(reopened);
        unawaitedSafe(svc.startLiveSurface(
          reopened,
          notificationsEnabled: _fastingNotificationsEnabled,
        ));
      }
    }
  }

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
              if (customHours != null) _customHours = customHours;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showFastingSettings(
      BuildContext context, FastingState fastingState) {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;
    final preferences = fastingState.preferences ??
        FastingPreferences(userId: userId, defaultProtocol: '16:8');
    HapticService.light();
    showGlassSheet(
      context: context,
      // Fix #8: the settings sheet renders its own glass surface + drag
      // handle, so the wrapper must NOT add a second one.
      builder: (context) => GlassSheet(
        showHandle: false,
        child: FastingSettingsSheet(preferences: preferences),
      ),
    );
  }
}
