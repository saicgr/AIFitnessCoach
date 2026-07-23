/// The Cycle screen — the dedicated period + fertility experience.
///
/// A 3-tab layout (Today / Calendar / Insights) with the pink feature accent.
/// The app bar carries a persistent AI coach icon (badged when a fresh
/// proactive insight is waiting) and a tracking-mode toggle (tracking / TTC /
/// pregnancy) that persists to the hormonal profile.
///
/// Routed at `/cycle` (Phase C) — no 6th bottom-nav tab. Reached from the
/// Home cycle card, the Profile/"You" hub Cycle row, and the legacy
/// `cycle_tracker_widget` on the hormonal-health hub.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../widgets/floating_tab_bar.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/nav_bar_hider_mixin.dart';
import '../../data/models/hormonal_health.dart';
import '../../data/providers/hormonal_health_provider.dart';
import '../../data/providers/cycle_reminder_sync_provider.dart';
import '../../data/repositories/hormonal_health_repository.dart';
import '../../data/services/haptic_service.dart';
import '../hormonal_health/widgets/hormone_log_sheet.dart';
import 'cycle_chat.dart';
import 'cycle_visuals.dart';
import 'widgets/cycle_ai_insight_card.dart';
import 'widgets/cycle_calendar.dart';
import 'widgets/cycle_conception_meter.dart';
import 'widgets/cycle_day_detail_sheet.dart';
import 'widgets/cycle_insights_charts.dart';
import 'widgets/cycle_monthly_summary.dart';
import 'widgets/cycle_phase_ring.dart';
import 'widgets/cycle_suggested_chips.dart';
import 'widgets/cycle_temperature_chart.dart';
import 'widgets/log_period_sheet.dart';
import 'widgets/today_cycle_length_sparkline.dart';
import 'widgets/today_fertility_window_strip.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
part 'cycle_screen_ui.dart';

/// Cycle-feature accent — pink, per the plan. Mirrors `AccentColor.pink`'s
/// hue so it harmonises with the app while staying distinct as the cycle
/// feature's own colour.
const Color kCycleAccent = Color(0xFFE5567B);

class CycleScreen extends ConsumerStatefulWidget {
  /// Initial tab — 0 Today, 1 Calendar, 2 Insights.
  final int initialTab;

  const CycleScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen>
    with SingleTickerProviderStateMixin, NavBarHiderMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 2);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedTab,
    );
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index != _selectedTab) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Shared accessors used by the UI part ────────────────────────────────

  Color get _accent => kCycleAccent;

  bool get _fahrenheit {
    final user = ref.read(currentUserProvider).value;
    return user?.weightUnit != 'kg';
  }

  // ── Logging entry points ────────────────────────────────────────────────

  Future<void> _openLogPeriod() async {
    final saved = await showLogPeriodSheet(context);
    if (saved == true && mounted) {
      _showMicroInsight('period');
    }
  }

  Future<void> _openCheckIn() async {
    final saved = await showGlassSheet<bool>(
      context: context,
      builder: (_) => const GlassSheet(child: HormoneLogSheet()),
    );
    if (saved == true && mounted) {
      _showMicroInsight('check-in');
    }
  }

  void _openDayDetailFromSample(
    CycleBbtSample sample,
    CyclePrediction prediction,
  ) {
    showCycleDayDetailSheet(
      context,
      day: sample.date,
      log: _logForDate(sample.date),
      phase: cyclePhaseForDate(prediction, sample.date),
      accent: _accent,
      fahrenheit: _fahrenheit,
    );
  }

  /// Post-logging micro-insight — a one-line AI reaction surfaced inline
  /// after a log saves (Phase F). The proactive insight is recomputed
  /// server-side; here we re-fetch it and show a brief snackbar pointer.
  void _showMicroInsight(String what) {
    ref.invalidate(cycleAiInsightProvider);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final mqBottom = MediaQuery.of(context).viewPadding.bottom;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: kFloatingTabBarHeight + mqBottom + 24,
        ),
        backgroundColor: _accent,
        content: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                what == 'period'
                    ? AppLocalizations.of(context).cyclePeriodSavedYourCoach
                    : 'Logged — tap your coach for a quick read on today',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: AppLocalizations.of(context).recipesOpen,
          textColor: Colors.white,
          onPressed: () => openCycleChat(
            context,
            'I just logged my $what. Anything I should know?',
          ),
        ),
      ),
    );
  }

  // ── Tracking-mode toggle ────────────────────────────────────────────────

  Future<void> _showModeSheet(CycleTrackingMode current) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final picked = await showGlassSheet<CycleTrackingMode>(
      context: context,
      builder: (_) => GlassSheet(
        opaque: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).cycleTrackingMode,
                style: TextStyle(
                  color: fg,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).cycleSwitchHowTheCycle,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ...CycleTrackingMode.values.map((m) {
                final selected = m == current;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, m),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withValues(alpha: 0.12)
                            : fg.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? _accent.withValues(alpha: 0.4)
                              : fg.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_modeIcon(m),
                              color: selected
                                  ? _accent
                                  : fg.withValues(alpha: 0.6),
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.displayName,
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  _modeBlurb(m),
                                  style: TextStyle(
                                    color: fg.withValues(alpha: 0.55),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded,
                                color: _accent, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != current && mounted) {
      await _persistMode(picked);
    }
  }

  Future<void> _persistMode(CycleTrackingMode mode) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    HapticService.light();
    try {
      final repo = ref.read(hormonalHealthRepositoryProvider);
      // `tracking_mode` is a Phase-A column on `hormonal_profiles`; the
      // upsert accepts arbitrary profile fields.
      await repo.upsertProfile(user.id, {'tracking_mode': mode.value});
      ref.invalidate(hormonalProfileProvider);
      ref.invalidate(cyclePredictionProvider);
      if (mounted) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to ${mode.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not switch mode: $e')),
        );
      }
    }
  }

  IconData _modeIcon(CycleTrackingMode m) {
    switch (m) {
      case CycleTrackingMode.tracking:
        return Icons.calendar_month_rounded;
      case CycleTrackingMode.ttc:
        return Icons.favorite_rounded;
      case CycleTrackingMode.pregnancy:
        return Icons.pregnant_woman_rounded;
    }
  }

  String _modeBlurb(CycleTrackingMode m) {
    switch (m) {
      case CycleTrackingMode.tracking:
        return 'Period prediction and cycle insights';
      case CycleTrackingMode.ttc:
        return 'Fertile window, peak days and conception meter';
      case CycleTrackingMode.pregnancy:
        return 'Predictions pause; copy switches to pregnancy';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    // Keep the date-anchored cycle reminders in lockstep with the live
    // prediction whenever the Cycle screen is open (the main daily touchpoint).
    ref.watch(cycleReminderSyncProvider);

    final mode = ref.watch(cycleTrackingModeProvider);
    final insightAsync = ref.watch(cycleAiInsightProvider);
    final hasFreshInsight = insightAsync.maybeWhen(
      data: (d) => d != null,
      orElse: () => false,
    );
    final prediction = ref.watch(cyclePredictionProvider).value;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: fg),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    AppLocalizations.of(context).overviewCycle,
                    style: TextStyle(
                      color: fg,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  // Tracking-mode pill.
                  GestureDetector(
                    onTap: () => _showModeSheet(mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accent.withValues(alpha: 0.32)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_modeIcon(mode), size: 13, color: _accent),
                          const SizedBox(width: 5),
                          Text(
                            mode == CycleTrackingMode.tracking
                                ? 'Tracking'
                                : mode == CycleTrackingMode.ttc
                                    ? 'TTC'
                                    : 'Pregnancy',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more_rounded,
                              size: 13, color: _accent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Persistent AI coach icon — badged when a fresh insight
                  // is waiting. Present on all three tabs.
                  _CoachAppBarButton(
                    accent: _accent,
                    fg: fg,
                    badged: hasFreshInsight,
                    onTap: () => openCycleChat(
                      context,
                      cycleOpenerSeed(prediction),
                    ),
                  ),
                ],
              ),
            ),
            // ── Tab bodies + bottom-docked floating tab bar ────────────
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        buildTodayTab(),
                        buildCalendarTab(),
                        buildInsightsTab(),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    // Hidden main floating nav (see NavBarHiderMixin) means
                    // we sit just above the safe-area inset with a small gap.
                    bottom:
                        MediaQuery.of(context).viewPadding.bottom + 14,
                    child: Center(
                      child: FloatingTabBar(
                        mode: FloatingTabBarMode.viewSwitcher,
                        accentColor: _accent,
                        selectedIndex: _selectedTab,
                        items: [
                          FloatingTabItem(
                              label: AppLocalizations.of(context).todayScoreCardToday,
                              icon: Icons.today_rounded),
                          FloatingTabItem(
                              label: AppLocalizations.of(context).habitDetailCalendar,
                              icon: Icons.calendar_month_rounded),
                          FloatingTabItem(
                              label: AppLocalizations.of(context).muscleDetailInsights,
                              icon: Icons.insights_rounded),
                        ],
                        onTap: (i) {
                          if (_tabController.index != i) {
                            _tabController.animateTo(i);
                          }
                          setState(() => _selectedTab = i);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Data-derivation helpers (used by the UI part)
  // =========================================================================

  /// Build the [CycleBbtSample] list from raw `hormone_logs` rows.
  List<CycleBbtSample> _bbtSamples(
    List<Map<String, dynamic>>? rawLogs,
    CyclePrediction? prediction,
  ) {
    if (rawLogs == null) return const [];
    final out = <CycleBbtSample>[];
    for (final row in rawLogs) {
      final temp = _asDouble(row['basal_body_temperature']);
      if (temp == null) continue;
      final date = _asDate(row['log_date']);
      if (date == null) continue;
      int? cycleDay;
      final lastStart = prediction?.lastPeriodStart;
      if (lastStart != null && !date.isBefore(lastStart)) {
        cycleDay = date.difference(lastStart).inDays + 1;
      }
      out.add(CycleBbtSample(
        date: date,
        celsius: temp,
        cycleDay: cycleDay,
        symptoms: _symptomList(row['symptoms']),
      ));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Build the calendar's day-log map from raw rows.
  Map<DateTime, CycleDayLog> _logsByDay(
      List<Map<String, dynamic>>? rawLogs) {
    final out = <DateTime, CycleDayLog>{};
    if (rawLogs == null) return out;
    for (final row in rawLogs) {
      final date = _asDate(row['log_date']);
      if (date == null) continue;
      out[date] = CycleDayLog(
        date: date,
        bbtCelsius: _asDouble(row['basal_body_temperature']),
        periodFlow: row['period_flow']?.toString(),
        symptoms: _symptomList(row['symptoms']),
        mucus: row['cervical_mucus']?.toString(),
        lhResult: row['lh_test_result']?.toString(),
      );
    }
    return out;
  }

  CycleDayLog? _logForDate(DateTime date) {
    final raw = ref.read(cycleRawLogsProvider(120)).value;
    return _logsByDay(raw)[CycleDates.dateOnly(date)];
  }

  /// Observed cycle lengths (days between consecutive period starts).
  List<int> _cycleLengthsFromPeriods(List<CyclePeriod> periods) {
    final starts = periods.map((p) => CycleDates.dateOnly(p.startDate)).toList()
      ..sort();
    final out = <int>[];
    for (var i = 0; i < starts.length - 1; i++) {
      final gap = starts[i + 1].difference(starts[i]).inDays;
      if (gap >= 15 && gap <= 60) out.add(gap);
    }
    return out;
  }

  /// Symptom display-name → count over the raw logs.
  Map<String, int> _symptomCounts(List<Map<String, dynamic>> rawLogs) {
    final counts = <String, int>{};
    for (final row in rawLogs) {
      for (final s in _symptomList(row['symptoms'])) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Phase → day count, approximated by counting each logged day's phase.
  Map<CyclePhase, int> _phaseDays(
    CyclePrediction? prediction,
    List<Map<String, dynamic>> rawLogs,
  ) {
    final out = <CyclePhase, int>{};
    if (prediction == null) return out;
    for (final row in rawLogs) {
      final date = _asDate(row['log_date']);
      if (date == null) continue;
      final phase = cyclePhaseForDate(prediction, date);
      if (phase == null) continue;
      out[phase] = (out[phase] ?? 0) + 1;
    }
    return out;
  }

  // ── Tiny permissive parsers ─────────────────────────────────────────────

  double? _asDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  DateTime? _asDate(Object? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  List<String> _symptomList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e
            .toString()
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' '))
        .toList();
  }
}

/// The persistent AI coach app-bar button — badged when a fresh proactive
/// insight is waiting.
class _CoachAppBarButton extends StatelessWidget {
  final Color accent;
  final Color fg;
  final bool badged;
  final VoidCallback onTap;

  const _CoachAppBarButton({
    required this.accent,
    required this.fg,
    required this.badged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: AppLocalizations.of(context).cycleAskYourCycleCoach,
          icon: Icon(Icons.auto_awesome_rounded, color: fg),
          onPressed: () {
            HapticService.light();
            onTap();
          },
        ),
        if (badged)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.35, 1.35),
                  duration: 900.ms,
                ),
          ),
      ],
    );
  }
}
