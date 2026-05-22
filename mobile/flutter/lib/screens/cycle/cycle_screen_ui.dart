/// Tab bodies for the Cycle screen — Today / Calendar / Insights.
///
/// Kept in a `part` of `cycle_screen.dart` so the three tab builders share
/// the screen's state (providers, accent, helper methods) without a wall of
/// constructor plumbing.
part of 'cycle_screen.dart';

extension _CycleScreenUi on _CycleScreenState {
  // =========================================================================
  // TODAY TAB
  // =========================================================================

  Widget buildTodayTab() {
    final predictionAsync = ref.watch(cyclePredictionProvider);
    final rawLogsAsync = ref.watch(cycleRawLogsProvider(120));
    final accent = _accent;

    return RefreshIndicator(
      color: accent,
      onRefresh: () async {
        ref.invalidate(cyclePredictionProvider);
        ref.invalidate(cyclePeriodsProvider);
        ref.invalidate(cycleRawLogsProvider);
        ref.invalidate(cycleAiInsightProvider);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, _bottomInset(context)),
        children: [
          predictionAsync.when(
            loading: () => const _CycleLoading(),
            error: (e, _) => _CycleError(
              accent: accent,
              onRetry: () => ref.invalidate(cyclePredictionProvider),
            ),
            data: (prediction) {
              if (prediction == null || !prediction.predictionsAvailable) {
                return _CycleEmptyToday(
                  accent: accent,
                  prediction: prediction,
                  onLogPeriod: _openLogPeriod,
                );
              }
              final bbtSamples = _bbtSamples(rawLogsAsync.value, prediction);
              final hasBbt = bbtSamples.isNotEmpty;
              return Column(
                children: [
                  // Phase ring is always the anchor.
                  CyclePhaseRing(prediction: prediction, accent: accent),
                  const SizedBox(height: 18),
                  // TTC conception meter.
                  if (prediction.trackingMode == CycleTrackingMode.ttc) ...[
                    CycleConceptionMeter(
                      prediction: prediction,
                      accent: accent,
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Adaptive headline: temperature chart leads when BBT
                  // data exists; otherwise the phase ribbon (above) leads
                  // and the chart drops below the AI insight.
                  if (hasBbt) ...[
                    CycleTemperatureChart(
                      samples: bbtSamples,
                      prediction: prediction,
                      accent: accent,
                      fahrenheit: _fahrenheit,
                      onDayTap: (s) => _openDayDetailFromSample(s, prediction),
                      onAskCoach: (s) => openCycleChat(
                        context,
                        cycleDaySeed(s.date,
                            cycleDay: s.cycleDay,
                            phase: cyclePhaseForDate(prediction, s.date)),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  CycleAiInsightCard(accent: accent),
                  const SizedBox(height: 14),
                  if (!hasBbt) ...[
                    CycleTemperatureChart(
                      samples: const [],
                      prediction: prediction,
                      accent: accent,
                      fahrenheit: _fahrenheit,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _CyclePhaseGuidanceCard(
                    prediction: prediction,
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  CycleSuggestedChips(
                    phase: prediction.currentPhase,
                    mode: prediction.trackingMode,
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  _quickLogRow(accent),
                  const SizedBox(height: 10),
                  if (prediction.notes.isNotEmpty)
                    _CycleNotesBlock(notes: prediction.notes),
                  const SizedBox(height: 8),
                  const _CycleDisclaimer(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _quickLogRow(Color accent) {
    return Row(
      children: [
        Expanded(
          child: _QuickLogButton(
            icon: Icons.water_drop_rounded,
            label: 'Log period',
            color: CyclePhaseColors.menstrual,
            onTap: _openLogPeriod,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickLogButton(
            icon: Icons.add_chart_rounded,
            label: 'Daily check-in',
            color: accent,
            onTap: _openCheckIn,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // CALENDAR TAB
  // =========================================================================

  Widget buildCalendarTab() {
    final predictionAsync = ref.watch(cyclePredictionProvider);
    final periodsAsync = ref.watch(cyclePeriodsProvider);
    final rawLogsAsync = ref.watch(cycleRawLogsProvider(180));
    final accent = _accent;

    return RefreshIndicator(
      color: accent,
      onRefresh: () async {
        ref.invalidate(cyclePredictionProvider);
        ref.invalidate(cyclePeriodsProvider);
        ref.invalidate(cycleRawLogsProvider);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, _bottomInset(context)),
        children: [
          predictionAsync.when(
            loading: () => const _CycleLoading(),
            error: (e, _) => _CycleError(
              accent: accent,
              onRetry: () => ref.invalidate(cyclePredictionProvider),
            ),
            data: (prediction) {
              final logsByDay = _logsByDay(rawLogsAsync.value);
              return Column(
                children: [
                  CycleCalendar(
                    prediction: prediction,
                    periods: periodsAsync.value ?? const [],
                    logsByDay: logsByDay,
                    accent: accent,
                    onDayTap: (day, log) {
                      showCycleDayDetailSheet(
                        context,
                        day: day,
                        log: log,
                        phase: prediction == null
                            ? null
                            : cyclePhaseForDate(prediction, day),
                        accent: accent,
                        fahrenheit: _fahrenheit,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _quickLogRow(accent),
                  const SizedBox(height: 10),
                  const _CycleDisclaimer(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // INSIGHTS TAB
  // =========================================================================

  Widget buildInsightsTab() {
    final predictionAsync = ref.watch(cyclePredictionProvider);
    final periodsAsync = ref.watch(cyclePeriodsProvider);
    final rawLogsAsync = ref.watch(cycleRawLogsProvider(120));
    final accent = _accent;

    return RefreshIndicator(
      color: accent,
      onRefresh: () async {
        ref.invalidate(cyclePredictionProvider);
        ref.invalidate(cyclePeriodsProvider);
        ref.invalidate(cycleRawLogsProvider);
        ref.invalidate(cycleAiInsightProvider);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, _bottomInset(context)),
        children: [
          predictionAsync.when(
            loading: () => const _CycleLoading(),
            error: (e, _) => _CycleError(
              accent: accent,
              onRetry: () => ref.invalidate(cyclePredictionProvider),
            ),
            data: (prediction) {
              final periods = periodsAsync.value ?? const [];
              final logs = rawLogsAsync.value ?? const [];
              final cycleLengths = _cycleLengthsFromPeriods(periods);
              final symptomCounts = _symptomCounts(logs);
              final phaseDays = _phaseDays(prediction, logs);
              final bbtSamples =
                  _bbtSamples(logs, prediction);

              return Column(
                children: [
                  CycleAiInsightCard(accent: accent),
                  const SizedBox(height: 14),
                  CycleMonthlySummary(
                    prediction: prediction,
                    symptomCounts: symptomCounts,
                    bbtDaysLogged: bbtSamples.length,
                    checkInDays: logs.length,
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  CycleStatsBlock(
                    stats: prediction?.stats ?? const CycleStats(),
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  CycleLengthHistoryChart(
                    cycleLengths: cycleLengths,
                    stats: prediction?.stats ?? const CycleStats(),
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  // Full BBT chart (All range available).
                  CycleTemperatureChart(
                    samples: bbtSamples,
                    prediction: prediction,
                    accent: accent,
                    fahrenheit: _fahrenheit,
                    onDayTap: prediction == null
                        ? null
                        : (s) => _openDayDetailFromSample(s, prediction),
                    onAskCoach: prediction == null
                        ? null
                        : (s) => openCycleChat(
                              context,
                              cycleDaySeed(s.date,
                                  cycleDay: s.cycleDay,
                                  phase: cyclePhaseForDate(
                                      prediction, s.date)),
                            ),
                  ),
                  const SizedBox(height: 14),
                  CycleSymptomHeatmap(
                    symptomCounts: symptomCounts,
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  CyclePhaseDonut(
                    phaseDays: phaseDays,
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  const _CycleDisclaimer(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Small shared widgets for the Cycle screen
// ===========================================================================

double _bottomInset(BuildContext context) =>
    MediaQuery.of(context).viewPadding.bottom + 90;

class _QuickLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phase-specific guidance card for the Today tab.
class _CyclePhaseGuidanceCard extends StatelessWidget {
  final CyclePrediction prediction;
  final Color accent;

  const _CyclePhaseGuidanceCard({
    required this.prediction,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final phase = prediction.currentPhase;
    final color = CyclePhaseColors.of(phase);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(CyclePhaseColors.emoji(phase),
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${phase?.displayName ?? 'Cycle'} phase',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  CyclePhaseColors.tagline(phase),
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (phase != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Suggested training: ${phase.workoutIntensity}',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Engine notes / limitations block.
class _CycleNotesBlock extends StatelessWidget {
  final List<String> notes;
  const _CycleNotesBlock({required this.notes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notes
            .map((n) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 13,
                          color: fg.withValues(alpha: 0.4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          n,
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.55),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Non-contraceptive safety disclaimer — shown on every tab.
class _CycleDisclaimer extends StatelessWidget {
  const _CycleDisclaimer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        'Predictions are estimates based on your logged data, not a '
        'birth-control method and not medical advice. See a clinician for '
        'any health concern.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fg.withValues(alpha: 0.38),
          fontSize: 10,
          height: 1.4,
        ),
      ),
    );
  }
}

class _CycleLoading extends StatelessWidget {
  const _CycleLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .then()
            .fade(begin: 1, end: 0.5, duration: 600.ms);
    return Column(
      children: [box(220), box(96), box(200)],
    );
  }
}

class _CycleError extends StatelessWidget {
  final Color accent;
  final VoidCallback onRetry;

  const _CycleError({required this.accent, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 40, color: fg.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            "Couldn't load your cycle data",
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again.',
            style: TextStyle(
              color: fg.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Empty Today tab — no prediction yet (zero periods, symptom-only profile,
/// or pregnancy mode).
class _CycleEmptyToday extends StatelessWidget {
  final Color accent;
  final CyclePrediction? prediction;
  final VoidCallback onLogPeriod;

  const _CycleEmptyToday({
    required this.accent,
    required this.prediction,
    required this.onLogPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final isPregnancy =
        prediction?.trackingMode == CycleTrackingMode.pregnancy;
    final note = prediction?.notes.isNotEmpty == true
        ? prediction!.notes.first
        : 'Log your first period to start predictions.';

    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(
            isPregnancy
                ? Icons.pregnant_woman_rounded
                : Icons.calendar_month_rounded,
            size: 44,
            color: accent,
          ),
          const SizedBox(height: 14),
          Text(
            isPregnancy ? 'Pregnancy mode is on' : 'Start tracking',
            style: TextStyle(
              color: fg,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (!isPregnancy) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: onLogPeriod,
              icon: const Icon(Icons.water_drop_rounded, size: 18),
              label: const Text('Log a period'),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 360.ms);
  }
}
