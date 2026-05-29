part of 'workout_stats_section.dart';

/// The metric the trend chart is plotting. Each maps to the [TrendMetric] used
/// to seed the Custom Trends builder.
enum _TrendSegment {
  volume('Volume', TrendMetric.workoutVolume),
  sessions('Sessions', TrendMetric.pillarTrain),
  time('Time', TrendMetric.workoutVolume);

  const _TrendSegment(this.label, this.trendMetric);
  final String label;
  final TrendMetric trendMetric;
}

/// Selected metric segment, shared so the Custom Trends button can read it.
final _trendSegmentProvider =
    StateProvider.autoDispose<_TrendSegment>((ref) => _TrendSegment.volume);

/// Selected window (true = 12 weeks, false = 4 weeks).
final _trendTwelveWeekProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// 3. TREND CHART CARD.
///
/// Segmented control [Volume | Sessions | Time] and window [4W | 12W]. Volume
/// comes from [workoutVolumeTrendProvider] (kg → lbs); Sessions and Time come
/// from the consistency weekly metrics. A normalized readiness line is overlaid
/// when readiness history is available, and an ACWR load pill (deterministic,
/// from [trainingLoadCurrentProvider]) sits above the chart.
class _TrendChartCard extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _TrendChartCard({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(_trendSegmentProvider);
    final twelveWeek = ref.watch(_trendTwelveWeekProvider);
    final windowWeeks = twelveWeek ? 12 : 4;

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return StatCardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + window toggle.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Training trend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              _WindowToggle(
                twelveWeek: twelveWeek,
                isDark: isDark,
                accent: accent,
                onChanged: (v) =>
                    ref.read(_trendTwelveWeekProvider.notifier).state = v,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metric segmented control.
          _SegmentedControl(
            segments: _TrendSegment.values,
            selected: segment,
            isDark: isDark,
            accent: accent,
            onChanged: (s) =>
                ref.read(_trendSegmentProvider.notifier).state = s,
          ),
          const SizedBox(height: 8),
          // ACWR pill (deterministic load classification).
          _AcwrPill(isDark: isDark),
          const SizedBox(height: 12),
          // The chart itself.
          _TrendChartBody(
            segment: segment,
            windowWeeks: windowWeeks,
            isDark: isDark,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

/// The chart body: reads the right series for the selected segment, handles
/// loading / empty / error per segment, and overlays a readiness line.
class _TrendChartBody extends ConsumerWidget {
  final _TrendSegment segment;
  final int windowWeeks;
  final bool isDark;
  final Color accent;

  const _TrendChartBody({
    required this.segment,
    required this.windowWeeks,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Volume uses the dedicated FutureProvider; sessions/time use consistency.
    if (segment == _TrendSegment.volume) {
      final async = ref.watch(workoutVolumeTrendProvider);
      return async.when(
        loading: () => const SizedBox(height: 150, child: _CardSkeleton(height: 150)),
        error: (_, __) => _ChartEmpty(
          isDark: isDark,
          message: 'Volume trend is unavailable right now.',
        ),
        data: (trend) {
          final weeks = trend?.weeks ?? const [];
          if (weeks.isEmpty) {
            return _ChartEmpty(
              isDark: isDark,
              message: 'Log a few workouts to see your volume trend.',
            );
          }
          final windowed = weeks.length > windowWeeks
              ? weeks.sublist(weeks.length - windowWeeks)
              : weeks;
          final values =
              windowed.map((w) => _kgToLbs(w.volumeKg)).toList(growable: false);
          final labels = windowed
              .map((w) => DateFormat('M/d').format(w.weekStart))
              .toList(growable: false);
          return _BarsWithReadiness(
            values: values,
            labels: labels,
            unitSuffix: 'lbs',
            isDark: isDark,
            accent: accent,
          );
        },
      );
    }

    // Sessions + Time both read the consistency weekly metrics.
    final consistency = ref.watch(consistencyProvider);
    final weekly = consistency.insights?.weeklyCompletionRates ?? const [];

    if (consistency.isLoading && weekly.isEmpty) {
      return const SizedBox(height: 150, child: _CardSkeleton(height: 150));
    }
    if (weekly.isEmpty) {
      return _ChartEmpty(
        isDark: isDark,
        message: 'Complete a few weeks of workouts to see this trend.',
      );
    }

    final windowed = weekly.length > windowWeeks
        ? weekly.sublist(weekly.length - windowWeeks)
        : weekly;

    final List<double> values;
    final String unitSuffix;
    if (segment == _TrendSegment.sessions) {
      values =
          windowed.map((w) => w.workoutsCompleted.toDouble()).toList(growable: false);
      unitSuffix = 'sessions';
    } else {
      values = windowed
          .map((w) => w.totalWorkoutMinutes.toDouble())
          .toList(growable: false);
      unitSuffix = 'min';
    }

    final allZero = values.every((v) => v == 0);
    if (allZero) {
      return _ChartEmpty(
        isDark: isDark,
        message: segment == _TrendSegment.sessions
            ? 'No completed sessions in this window yet.'
            : 'No recorded workout time in this window yet.',
      );
    }

    final labels = windowed
        .map((w) => DateFormat('M/d').format(w.weekStartDate))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BarsWithReadiness(
          values: values,
          labels: labels,
          unitSuffix: unitSuffix,
          isDark: isDark,
          accent: accent,
        ),
        const SizedBox(height: 6),
        Text(
          'Bars: $unitSuffix per week',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }
}

/// Window toggle: 4W / 12W.
class _WindowToggle extends StatelessWidget {
  final bool twelveWeek;
  final bool isDark;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _WindowToggle({
    required this.twelveWeek,
    required this.isDark,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniToggle(
          label: '4W',
          selected: !twelveWeek,
          isDark: isDark,
          accent: accent,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 6),
        _MiniToggle(
          label: '12W',
          selected: twelveWeek,
          isDark: isDark,
          accent: accent,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.4)
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? accent : textMuted,
          ),
        ),
      ),
    );
  }
}

/// Metric segmented control.
class _SegmentedControl extends StatelessWidget {
  final List<_TrendSegment> segments;
  final _TrendSegment selected;
  final bool isDark;
  final Color accent;
  final ValueChanged<_TrendSegment> onChanged;

  const _SegmentedControl({
    required this.segments,
    required this.selected,
    required this.isDark,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: segments.map((s) {
          final isSel = s == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticService.selection();
                onChanged(s);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSel ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSel
                        ? ThemeColors.of(context).accentContrast
                        : textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Bars (selected metric) with an optional normalized readiness line overlaid.
///
/// fl_chart can't combine a [BarChart] and a [LineChart] in one widget, so this
/// stacks a transparent axis-less [MiniSparkline]-style readiness line over the
/// bar series, both sharing the same horizontal extent.
class _BarsWithReadiness extends ConsumerWidget {
  final List<double> values;
  final List<String> labels;
  final String unitSuffix;
  final bool isDark;
  final Color accent;

  const _BarsWithReadiness({
    required this.values,
    required this.labels,
    required this.unitSuffix,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Readiness overlay: align the most-recent N readiness scores to the bar
    // count. Real data only; if there are <2 points the line simply hides.
    final readinessHistory =
        ref.watch(scoresProvider.select((s) => s.readinessHistory));
    final readinessLine = _readinessSeries(readinessHistory, values.length);

    const chartHeight = 140.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: MiniBars(
                  values: values,
                  color: accent,
                  height: chartHeight,
                ),
              ),
              if (readinessLine != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: MiniSparkline(
                      values: readinessLine,
                      color: isDark
                          ? AppColors.success
                          : AppColorsLight.success,
                      height: chartHeight,
                      filled: false,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // x-axis labels: first + last only (avoids crowding on 12W).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(labels.isNotEmpty ? labels.first : '',
                style: TextStyle(fontSize: 10, color: textMuted)),
            Text(labels.isNotEmpty ? labels.last : '',
                style: TextStyle(fontSize: 10, color: textMuted)),
          ],
        ),
        if (readinessLine != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 14,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.success : AppColorsLight.success,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Readiness overlay',
                style: TextStyle(fontSize: 10.5, color: textMuted),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Take the last [count] readiness scores (0-100) as a plain series for the
  /// overlay. Returns null when there is too little data to draw a line, so the
  /// overlay is simply omitted rather than faked.
  static List<double>? _readinessSeries(
      ReadinessHistory? history, int count) {
    if (history == null) return null;
    final scores = history.readinessScores;
    if (scores.length < 2) return null;
    // readinessScores are most-recent-first or oldest-first depending on the
    // backend; sort by date ascending to be safe.
    final sorted = [...scores]
      ..sort((a, b) => a.scoreDate.compareTo(b.scoreDate));
    final tail =
        sorted.length > count ? sorted.sublist(sorted.length - count) : sorted;
    if (tail.length < 2) return null;
    return tail.map((s) => s.readinessScore.toDouble()).toList(growable: false);
  }
}

/// ACWR load pill — deterministic classification straight from the backend's
/// `state` (never LLM-classified). Shows the acute:chronic ratio + a short
/// cited interpretation string the backend provides.
class _AcwrPill extends ConsumerWidget {
  final bool isDark;

  const _AcwrPill({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trainingLoadCurrentProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        // During calibration there is not enough history for an honest ratio.
        if (state.isCalibration || state.acwr == null) {
          return _LoadPillChrome(
            isDark: isDark,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            stateLabel: 'Calibrating',
            detail: state.interpretation,
          );
        }
        final color = _stateColor(state.state, isDark);
        final acwr = state.acwr!.toStringAsFixed(2);
        return _LoadPillChrome(
          isDark: isDark,
          color: color,
          stateLabel: _stateLabel(state.state),
          detail: 'acute:chronic $acwr · ${state.interpretation}',
        );
      },
    );
  }

  static String _stateLabel(String state) {
    switch (state) {
      case 'detraining':
        return 'Detraining';
      case 'loading':
        return 'Loading';
      case 'overreaching':
        return 'Overreaching';
      case 'balanced':
        return 'Balanced';
      default:
        return state.isEmpty
            ? 'Load'
            : state[0].toUpperCase() + state.substring(1);
    }
  }

  static Color _stateColor(String state, bool isDark) {
    switch (state) {
      case 'overreaching':
        return isDark ? AppColors.error : AppColorsLight.error;
      case 'loading':
        return isDark ? AppColors.warning : AppColorsLight.warning;
      case 'detraining':
        return isDark ? AppColors.info : AppColorsLight.info;
      case 'balanced':
      default:
        return isDark ? AppColors.success : AppColorsLight.success;
    }
  }
}

class _LoadPillChrome extends StatelessWidget {
  final bool isDark;
  final Color color;
  final String stateLabel;
  final String detail;

  const _LoadPillChrome({
    required this.isDark,
    required this.color,
    required this.stateLabel,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stateLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, height: 1.3, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  final bool isDark;
  final String message;

  const _ChartEmpty({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 28, color: textMuted),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.35, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
