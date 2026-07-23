import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/posthog_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/consistency.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/design_system/zealova.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/services/api_client.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
/// Consistency Insights Dashboard Screen
/// Displays streak information, workout patterns, and recovery options
class ConsistencyScreen extends ConsumerStatefulWidget {
  const ConsistencyScreen({super.key});

  @override
  ConsumerState<ConsistencyScreen> createState() => _ConsistencyScreenState();
}

class _ConsistencyScreenState extends ConsumerState<ConsistencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fireAnimationController;
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fireAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    ref.read(posthogServiceProvider).capture(eventName: 'consistency_viewed');
    _loadData();
  }

  @override
  void dispose() {
    _fireAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() {
        _userId = userId;
      });
      final notifier = ref.read(consistencyProvider.notifier);
      notifier.setUserId(userId);
      await notifier.loadAll(userId: userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(consistencyProvider);

    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).scoreBreakdownConsistency,
        kicker: 'Progress',
      ),
      body: _isLoading || _userId == null
          ? AppLoading.fullScreen()
          : AppRefreshIndicator(
              color: tc.accent,
              onRefresh: () => ref
                  .read(consistencyProvider.notifier)
                  .refresh(userId: _userId),
              child: state.error != null
                  ? _buildErrorState(state.error!, colorScheme)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ★ FLAME + NUMBER hero
                          _buildStreakHero(state, colorScheme),
                          const SizedBox(height: 22),

                          // ★ WEEKLY MOMENTUM dots
                          _buildWeeklyMomentum(state, colorScheme),

                          // ★ Stat pair on hairline bars
                          _buildStreakStatPair(state, colorScheme),

                          // Calendar Heatmap
                          _buildCalendarHeatmap(state, colorScheme),

                          // Day Patterns
                          _buildDayPatternsSection(state, colorScheme),

                          // Monthly Stats
                          _buildMonthlyStatsSection(state, colorScheme),

                          // Weekly Trend
                          _buildWeeklyTrendSection(state, colorScheme),

                          // Recovery Card (if needed)
                          if (state.needsRecovery) ...[
                            const SizedBox(height: 24),
                            _buildRecoveryCard(state, colorScheme),
                          ],
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildErrorState(String error, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: tc.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).measurementsFailedToLoadData.toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.lbl(18, color: tc.textPrimary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: ZType.data(12, color: tc.textMuted),
            ),
            const SizedBox(height: 24),
            ZealovaButton(
              label: AppLocalizations.of(context).workoutStateCardsTryAgain,
              onTap: _loadData,
              trailingIcon: Icons.refresh,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ★ FLAME + NUMBER hero (no boxed card)
  // ============================================

  Widget _buildStreakHero(ConsistencyState state, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    final currentStreak = state.currentStreak;
    final longestStreak = state.longestStreak;
    final isActive = state.isStreakActive;
    final flameColor = isActive ? tc.accent : tc.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Flickering flame — the ONE accent
        AnimatedBuilder(
          animation: _fireAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_fireAnimationController.value * 0.1),
              child: Icon(
                Icons.local_fire_department,
                size: 64,
                color: flameColor,
              ),
            );
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currentStreak',
                    style: ZType.disp(64,
                        color: isActive ? tc.accent : tc.textPrimary,
                        height: 0.82),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppLocalizations.of(context)
                          .statsStreakFireDayStreak
                          .toUpperCase(),
                      style:
                          ZType.lbl(13, color: tc.textMuted, letterSpacing: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).consistencyStartFreshToday,
                style: ZType.ser(14, color: tc.textSecondary),
              ),
            ],
          ),
        ),
        // Best-streak chip — utility, top-right
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: tc.surface,
            border: Border.all(color: AppColors.hairlineStrong),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined, size: 14, color: tc.textMuted),
              const SizedBox(width: 5),
              Text(
                '$longestStreak',
                style: ZType.lbl(13, color: tc.textSecondary, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================
  // ★ WEEKLY MOMENTUM dots (derived from calendar)
  // ============================================

  /// Builds the current Mon–Sun completion map from the existing calendar
  /// heatmap data already read into [state] — no new provider reads.
  List<CalendarStatus?> _currentWeekStatuses(ConsistencyState state) {
    final result = List<CalendarStatus?>.filled(7, null);
    final data = state.calendarData?.data;
    if (data == null || data.isEmpty) return result;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday-anchored start of the current week.
    final monday = today.subtract(Duration(days: today.weekday - 1));

    for (final day in data) {
      final d = day.dateTime;
      final dd = DateTime(d.year, d.month, d.day);
      final idx = dd.difference(monday).inDays;
      if (idx >= 0 && idx < 7) {
        result[idx] = day.statusEnum;
      }
    }
    return result;
  }

  int _currentWeekday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).weekday - 1; // 0..6 (Mon..Sun)
  }

  Widget _buildWeeklyMomentum(ConsistencyState state, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    final statuses = _currentWeekStatuses(state);
    final todayIdx = _currentWeekday();
    final completedThisWeek =
        statuses.where((s) => s == CalendarStatus.completed).length;
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZealovaSectionKicker(
          '${AppLocalizations.of(context).nutritionStreakCardThisWeek} · $completedThisWeek / 7',
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final status = statuses[i];
            final isCompleted = status == CalendarStatus.completed;
            final isToday = i == todayIdx;

            Color boxColor;
            Color borderColor;
            Widget glyph;

            if (isCompleted) {
              boxColor = tc.accent;
              borderColor = tc.accent;
              glyph = Icon(Icons.check, size: 13, color: tc.accentContrast);
            } else if (isToday) {
              boxColor = tc.surface;
              borderColor = tc.accent;
              glyph = Container(
                width: 5,
                height: 5,
                decoration:
                    BoxDecoration(color: tc.accent, shape: BoxShape.circle),
              );
            } else {
              boxColor = tc.surface;
              borderColor = AppColors.hairlineStrong;
              glyph = const SizedBox.shrink();
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 6 ? 0 : 7),
                child: Column(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: boxColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: glyph),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weekdayLabels[i],
                      style: ZType.lbl(10,
                          color: isToday ? tc.accent : tc.textMuted,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
      ],
    ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ============================================
  // ★ Stat pair on hairline bars
  // ============================================

  Widget _buildStreakStatPair(ConsistencyState state, ColorScheme colorScheme) {
    final insights = state.insights;
    if (insights == null) {
      return const SizedBox.shrink();
    }
    final completed = insights.monthWorkoutsCompleted;
    final scheduled = insights.monthWorkoutsScheduled;
    final wkFraction = scheduled > 0 ? completed / scheduled : 0.0;

    return Column(
      children: [
        const ZealovaRule(),
        _buildHairlineBar(
          label: AppLocalizations.of(context).consistencyThisMonth,
          fraction: wkFraction.clamp(0.0, 1.0),
          valueText: '$completed/$scheduled',
          accentFill: false,
        ),
        const ZealovaRule(),
        _buildHairlineBar(
          label: AppLocalizations.of(context).statsStreakFireDayStreak,
          fraction: 1.0,
          valueText: '${state.longestStreak}',
          accentFill: true,
        ),
        const ZealovaRule(),
        const SizedBox(height: 18),
      ],
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms);
  }

  Widget _buildHairlineBar({
    required String label,
    required double fraction,
    required String valueText,
    required bool accentFill,
  }) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: AppColors.hairlineStrong,
                valueColor: AlwaysStoppedAnimation<Color>(
                    accentFill ? tc.accent : tc.textMuted),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: ZType.disp(15,
                  color: accentFill ? tc.accent : tc.textPrimary, height: 1),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Calendar Heatmap (hairline-led)
  // ============================================

  /// Consecutive-week streak (Gravl-style "X week streak"): walk back from the
  /// current Monday-anchored week, counting weeks that contain ≥1 completed
  /// workout, stopping at the first gap. The CURRENT week never breaks the
  /// streak if it's empty (the week isn't over yet) — we only start counting
  /// from the most recent week that has a completion. Derived purely from the
  /// calendar data already loaded into [state]; no extra fetch.
  ({int weeks, int restDays}) _weekStreakAndRest(ConsistencyState state) {
    final data = state.calendarData?.data;
    if (data == null || data.isEmpty) return (weeks: 0, restDays: 0);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));

    // Bucket completed-workout days by their week's Monday.
    final completedWeeks = <DateTime>{};
    var restDays = 0;
    for (final day in data) {
      final d = day.dateTime;
      final dd = DateTime(d.year, d.month, d.day);
      if (dd.isAfter(today)) continue; // ignore future cells
      switch (day.statusEnum) {
        case CalendarStatus.completed:
          final monday = dd.subtract(Duration(days: dd.weekday - 1));
          completedWeeks.add(DateTime(monday.year, monday.month, monday.day));
          break;
        case CalendarStatus.rest:
          restDays++;
          break;
        case CalendarStatus.missed:
        case CalendarStatus.future:
          break;
      }
    }
    if (completedWeeks.isEmpty) return (weeks: 0, restDays: restDays);

    // Start from the current week if it has a completion, otherwise from the
    // most recent prior week with one (so an in-progress empty week doesn't
    // zero out a real streak).
    var cursor = thisMonday;
    if (!completedWeeks.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 7));
    }
    var weeks = 0;
    while (completedWeeks.contains(cursor)) {
      weeks++;
      cursor = cursor.subtract(const Duration(days: 7));
    }
    return (weeks: weeks, restDays: restDays);
  }

  /// Gravl-parity streak banner shown above the heatmap: a "🔥 X week streak"
  /// pill plus a "🌙 N rest days" pill. Both are derived from the loaded
  /// calendar data. The banner hides entirely when there's no streak AND no
  /// rest day to report (nothing to celebrate yet — no placeholder zeros).
  Widget _buildStreakBanner(ConsistencyState state) {
    final tc = ThemeColors.of(context);
    final stats = _weekStreakAndRest(state);
    final weeks = stats.weeks;
    final restDays = stats.restDays;
    if (weeks <= 0 && restDays <= 0) return const SizedBox.shrink();

    Widget pill({
      required String emoji,
      required String value,
      required String label,
      required bool accent,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tc.surface,
            border: Border.all(
              color: accent
                  ? tc.accent.withValues(alpha: 0.45)
                  : AppColors.hairlineStrong,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.disp(
                        20,
                        color: accent ? tc.accent : tc.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.lbl(9,
                          color: tc.textMuted, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final children = <Widget>[];
    if (weeks > 0) {
      children.add(pill(
        emoji: '🔥',
        value: '$weeks',
        label: weeks == 1 ? 'week streak' : 'week streak',
        accent: true,
      ));
    }
    if (restDays > 0) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 10));
      children.add(pill(
        emoji: '🌙',
        value: '$restDays',
        label: restDays == 1 ? 'rest day' : 'rest days',
        accent: false,
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(children: children),
    ).animate().fadeIn(delay: 220.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCalendarHeatmap(
      ConsistencyState state, ColorScheme colorScheme) {
    final calendarData = state.calendarData;
    if (calendarData == null) {
      return const SizedBox.shrink();
    }

    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gravl-parity streak + rest-day banner, derived from loaded data.
        _buildStreakBanner(state),
        ZealovaSectionKicker(
          AppLocalizations.of(context).consistencyLast4Weeks,
        ),
        const SizedBox(height: 14),

        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style:
                          ZType.lbl(11, color: tc.textMuted, letterSpacing: 1),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        _buildCalendarGrid(calendarData.data, colorScheme),

        const SizedBox(height: 14),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Completed', tc.accent, colorScheme),
            const SizedBox(width: 16),
            _buildLegendItem('Missed', tc.textMuted, colorScheme),
            const SizedBox(width: 16),
            _buildLegendItem('Rest', AppColors.hairlineStrong, colorScheme),
          ],
        ),
        const SizedBox(height: 8),
        const ZealovaRule(margin: EdgeInsets.only(top: 14)),
        const SizedBox(height: 18),
      ],
    ).animate().fadeIn(delay: 240.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCalendarGrid(
      List<CalendarHeatmapData> data, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    if (data.isEmpty) {
      return const SizedBox(height: 150);
    }

    // Organize data into weeks
    final weeks = <List<CalendarHeatmapData?>>[];
    var currentWeek = <CalendarHeatmapData?>[];

    // Add padding for first week
    if (data.isNotEmpty) {
      final firstDayOfWeek = data.first.dayOfWeek;
      for (var i = 0; i < firstDayOfWeek; i++) {
        currentWeek.add(null);
      }
    }

    for (final day in data) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Add remaining days
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: week.map((day) {
              if (day == null) {
                return const SizedBox(width: 36, height: 36);
              }

              Color bgColor;
              Color textColor;
              Border? cellBorder;
              switch (day.statusEnum) {
                case CalendarStatus.completed:
                  bgColor = tc.accent;
                  textColor = tc.accentContrast;
                  break;
                case CalendarStatus.missed:
                  bgColor = tc.surface;
                  textColor = tc.textMuted;
                  cellBorder = Border.all(color: AppColors.hairlineStrong);
                  break;
                case CalendarStatus.rest:
                  bgColor = AppColors.hairlineStrong;
                  textColor = tc.textSecondary;
                  break;
                case CalendarStatus.future:
                  bgColor = tc.surface;
                  textColor = tc.textMuted;
                  cellBorder = Border.all(color: AppColors.hairline);
                  break;
              }

              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  border: cellBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    day.dateTime.day.toString(),
                    style: ZType.data(11, color: textColor),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(String label, Color color, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
        ),
      ],
    );
  }

  // ============================================
  // Day Patterns (hairline rows)
  // ============================================

  Widget _buildDayPatternsSection(
      ConsistencyState state, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZealovaSectionKicker(
          AppLocalizations.of(context).consistencyWorkoutPatterns,
        ),
        const SizedBox(height: 6),

        // Best Day
        if (insights.bestDay != null)
          _buildPatternRow(
            'Your best day',
            insights.bestDayDisplay ?? 'N/A',
            Icons.thumb_up_outlined,
            tc.accent,
            colorScheme,
          ),

        // Worst Day
        if (insights.worstDay != null)
          _buildPatternRow(
            'You tend to skip',
            insights.worstDayDisplay ?? 'N/A',
            Icons.warning_amber_outlined,
            tc.textMuted,
            colorScheme,
          ),

        // Preferred Time
        if (insights.preferredTime != null)
          _buildPatternRow(
            'Preferred time',
            _formatTimeOfDay(insights.preferredTime!),
            Icons.schedule_outlined,
            tc.textSecondary,
            colorScheme,
          ),

        const SizedBox(height: 18),
      ],
    ).animate().fadeIn(delay: 320.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPatternRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    ColorScheme colorScheme,
  ) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        const ZealovaRule(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1.2),
                ),
              ),
              Text(
                value,
                style:
                    ZType.lbl(14, color: tc.textPrimary, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(String timeKey) {
    final displays = {
      'early_morning': 'Early Morning',
      'morning': 'Morning',
      'midday': 'Midday',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'night': 'Night',
    };
    return displays[timeKey] ?? timeKey;
  }

  // ============================================
  // Monthly Stats (Anton numeral + hairline)
  // ============================================

  Widget _buildMonthlyStatsSection(
      ConsistencyState state, ColorScheme colorScheme) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    final tc = ThemeColors.of(context);
    final completed = insights.monthWorkoutsCompleted;
    final scheduled = insights.monthWorkoutsScheduled;
    final rate = insights.monthCompletionRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZealovaRule(),
        const SizedBox(height: 16),
        ZealovaSectionKicker(
          AppLocalizations.of(context).consistencyThisMonth,
        ),
        const SizedBox(height: 12),

        // Big number display
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$completed',
              style: ZType.disp(48, color: tc.accent, height: 1),
            ),
            const SizedBox(width: 8),
            Text(
              'of $scheduled workouts'.toUpperCase(),
              style: ZType.lbl(13, color: tc.textMuted, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: scheduled > 0 ? completed / scheduled : 0,
            backgroundColor: AppColors.hairlineStrong,
            valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 8),

        // Completion rate
        Text(
          '${rate.toStringAsFixed(0)}% completion rate'.toUpperCase(),
          style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: 18),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ============================================
  // Weekly Trend (thin precise bars)
  // ============================================

  Widget _buildWeeklyTrendSection(
      ConsistencyState state, ColorScheme colorScheme) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    final tc = ThemeColors.of(context);
    final weeklyRates = insights.weeklyCompletionRates;
    final avgRate = insights.averageWeeklyRate;
    final trend = insights.weeklyTrendEnum;

    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (trend) {
      case WeeklyTrend.improving:
        trendIcon = Icons.trending_up;
        trendColor = tc.success;
        trendText = 'Improving';
        break;
      case WeeklyTrend.declining:
        trendIcon = Icons.trending_down;
        trendColor = tc.error;
        trendText = 'Needs attention';
        break;
      case WeeklyTrend.stable:
        trendIcon = Icons.trending_flat;
        trendColor = tc.textSecondary;
        trendText = 'Stable';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZealovaRule(),
        const SizedBox(height: 16),
        Row(
          children: [
            ZealovaSectionKicker(
              AppLocalizations.of(context).consistencyWeeklyTrend,
            ),
            const Spacer(),
            Icon(trendIcon, size: 15, color: trendColor),
            const SizedBox(width: 5),
            Text(
              trendText.toUpperCase(),
              style: ZType.lbl(11, color: trendColor, letterSpacing: 1.2),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Thin precise bars
        if (weeklyRates.isNotEmpty) _buildWeeklyBars(weeklyRates, colorScheme),

        const SizedBox(height: 12),

        Text(
          'Average: ${avgRate.toStringAsFixed(0)}% weekly completion'
              .toUpperCase(),
          style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
      ],
    ).animate().fadeIn(delay: 480.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWeeklyBars(
      List<WeeklyConsistencyMetric> weeks, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    // Reverse to show oldest first
    final reversedWeeks = weeks.reversed.toList();

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: reversedWeeks.asMap().entries.map((entry) {
          final index = entry.key;
          final week = entry.value;
          final rate = week.completionRate / 100;
          final isLatest = index == reversedWeeks.length - 1;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bar
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 18,
                      height: math.max(4, rate * 50),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? tc.accent
                            : AppColors.hairlineStrong,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Label
                Text(
                  isLatest
                      ? AppLocalizations.of(context).nutritionStreakCardThisWeek
                      : 'Wk ${index + 1}',
                  style: ZType.lbl(9,
                      color: isLatest ? tc.accent : tc.textMuted,
                      letterSpacing: 0.8),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // Recovery Card
  // ============================================

  Widget _buildRecoveryCard(ConsistencyState state, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restart_alt,
                color: tc.accent,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).consistencyStartFreshToday,
                      style: ZType.lbl(16,
                          color: tc.textPrimary, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.insights?.recoverySuggestion ??
                          'Every day is a new opportunity to build your streak.',
                      style: ZType.ser(13, color: tc.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ZealovaButton(
                  label: AppLocalizations.of(context).consistencyFullWorkout,
                  onTap: () => _startRecovery('standard'),
                  trailingIcon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ZealovaButton(
                  label: AppLocalizations.of(context).consistencyQuick15min,
                  onTap: () => _startRecovery('quick_recovery'),
                  trailingIcon: Icons.timer,
                  variant: ZealovaButtonVariant.ghost,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 560.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Future<void> _startRecovery(String type) async {
    final response = await ref.read(consistencyProvider.notifier).initiateRecovery(
      recoveryType: type,
    );

    if (response != null && mounted) {
      AppSnackBar.success(context, response.motivationQuote ?? response.message);
      // Navigate to workout or home
      Navigator.of(context).pop();
    }
  }
}
