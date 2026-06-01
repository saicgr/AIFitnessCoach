part of 'measurement_detail_screen.dart';

/// UI builder methods extracted from _MeasurementDetailScreenState
extension _MeasurementDetailScreenStateUI on _MeasurementDetailScreenState {

  /// Renders the measurement history with the shared interactive [TrendChart]
  /// (Phase G7). The chart provides EWMA-smoothed trend line over raw dots,
  /// pinch-zoom + pan, a drag-scrub crosshair tooltip, and a min/avg/max row.
  Widget _buildChart(
    List<MeasurementEntry> history, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    if (history.isEmpty) return const SizedBox.shrink();

    // history is newest-first — TrendChart sorts internally, but build the
    // points oldest-first for clarity.
    final points = [
      for (final e in history.reversed)
        TrendPoint(date: e.recordedAt, value: e.getValueInUnit(_isMetric)),
    ];

    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;

    // MacroFactor-style smoothing only makes sense with enough points; with
    // 1–2 entries fall back to the raw line (alpha 1.0 = no smoothing).
    final alpha = points.length >= 3 ? 0.25 : 1.0;

    // Convert the gendered health-zone HorizontalLines into TrendZoneBands.
    final zoneBands = [
      for (final line in _getHealthZoneLines())
        TrendZoneBand(
          value: line.y,
          label: line.label.labelResolver(line),
          color: line.color ?? cyan,
        ),
    ];

    return TrendChart(
      accent: cyan,
      // We own the hero (avg + period change), the honest MIN/AVG/MAX stat
      // row and the period breakdown, so suppress TrendChart's built-in
      // legend + stat row to avoid showing MIN/AVG/MAX twice.
      showBuiltInChrome: false,
      primary: TrendChartSeries(
        label: AppLocalizations.of(context)!.measurementDetailScreenUiTrend(_type.displayName),
        unit: unit,
        points: points,
        smoothingAlpha: alpha,
        zoneBands: zoneBands,
      ),
    );
  }


  Widget _buildRateOfChangeCard(
    List<MeasurementEntry> history, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (history.length < 2) return const SizedBox.shrink();

    final values = history.map((e) => e.getValueInUnit(_isMetric)).toList();
    final first = values.last; // oldest (history is newest-first)
    final last = values.first; // newest
    final totalChange = last - first;
    final daySpan = history.first.recordedAt.difference(history.last.recordedAt).inDays;
    if (daySpan <= 0) return const SizedBox.shrink();

    final weeklyRate = totalChange / (daySpan / 7);
    final monthlyRate = totalChange / (daySpan / 30);
    final unit = _isMetric ? _type.metricUnit : _type.imperialUnit;

    // For weight/body fat, decrease is good
    final isDecreaseGood = _type == MeasurementType.weight || _type == MeasurementType.bodyFat;
    Color rateColor(double rate) {
      if (rate.abs() < 0.01) return textMuted;
      final isGood = isDecreaseGood ? rate < 0 : rate > 0;
      return isGood ? AppColors.success : AppColors.error;
    }
    String formatRate(double rate) {
      final sign = rate >= 0 ? '+' : '';
      return '$sign${rate.toStringAsFixed(1)} $unit';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate of change', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).xpProgressCardWeekly, style: TextStyle(fontSize: 12, color: textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(weeklyRate >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16, color: rateColor(weeklyRate)),
                        const SizedBox(width: 4),
                        Text(formatRate(weeklyRate),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rateColor(weeklyRate))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).xpGoalsMonthly, style: TextStyle(fontSize: 12, color: textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(monthlyRate >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16, color: rateColor(monthlyRate)),
                        const SizedBox(width: 4),
                        Text(formatRate(monthlyRate),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rateColor(monthlyRate))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildHealthContextCard({
    required MeasurementEntry? latest,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (latest == null) return const SizedBox.shrink();
    final value = latest.getValueInUnit(_isMetric);
    final g = _userGender?.toLowerCase() ?? 'male';

    final String title;
    final String subtitle;
    final Color contextColor;
    final String source;

    switch (_type) {
      case MeasurementType.bodyFat:
        title = 'Your Body Fat: ${_formatValue(value)}%';
        if (g == 'female') {
          if (value < 14) { subtitle = 'Essential fat range'; contextColor = Colors.red; source = 'ACE'; }
          else if (value < 21) { subtitle = 'Athletes range (14-20%)'; contextColor = Colors.green; source = 'ACE'; }
          else if (value < 25) { subtitle = 'Fitness range (21-24%)'; contextColor = Colors.cyan; source = 'ACE'; }
          else if (value < 32) { subtitle = 'Acceptable range (25-31%)'; contextColor = Colors.amber; source = 'ACE'; }
          else { subtitle = 'Above acceptable range'; contextColor = Colors.red; source = 'ACE'; }
        } else {
          if (value < 6) { subtitle = 'Essential fat range'; contextColor = Colors.red; source = 'ACE'; }
          else if (value < 14) { subtitle = 'Athletes range (6-13%)'; contextColor = Colors.green; source = 'ACE'; }
          else if (value < 18) { subtitle = 'Fitness range (14-17%)'; contextColor = Colors.cyan; source = 'ACE'; }
          else if (value < 25) { subtitle = 'Acceptable range (18-24%)'; contextColor = Colors.amber; source = 'ACE'; }
          else { subtitle = 'Above acceptable range'; contextColor = Colors.red; source = 'ACE'; }
        }
      case MeasurementType.waist:
        final unitLabel = _isMetric ? 'cm' : 'in';
        title = 'Your Waist: ${_formatValue(value)} $unitLabel';
        final cmValue = _isMetric ? value : value * 2.54;
        if (g == 'female') {
          if (cmValue < 80) { subtitle = 'Low Risk - below 80cm threshold'; contextColor = Colors.green; source = 'CDC/WHO'; }
          else if (cmValue < 88) { subtitle = 'Moderate Risk (80-88cm)'; contextColor = Colors.amber; source = 'CDC/WHO'; }
          else { subtitle = 'High Risk - above 88cm threshold'; contextColor = Colors.red; source = 'CDC/WHO'; }
        } else {
          if (cmValue < 94) { subtitle = 'Low Risk - below 94cm threshold'; contextColor = Colors.green; source = 'CDC/WHO'; }
          else if (cmValue < 102) { subtitle = 'Moderate Risk (94-102cm)'; contextColor = Colors.amber; source = 'CDC/WHO'; }
          else { subtitle = 'High Risk - above 102cm threshold'; contextColor = Colors.red; source = 'CDC/WHO'; }
        }
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [contextColor.withOpacity(0.15), contextColor.withOpacity(0.05)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: contextColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: contextColor, fontWeight: FontWeight.w600)),
          if (source.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.measurementDetailScreenUiSourceGuideline(source), style: TextStyle(fontSize: 11, color: textMuted)),
          ],
        ],
      ),
    );
  }


  Widget _buildRelatedMetrics({
    required MeasurementsSummary? summary,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (summary == null) return const SizedBox.shrink();

    // Define related metrics per type
    final Map<MeasurementType, List<MeasurementType>> relatedMap = {
      MeasurementType.weight: [MeasurementType.bodyFat, MeasurementType.waist, MeasurementType.chest],
      MeasurementType.bodyFat: [MeasurementType.weight, MeasurementType.waist],
      MeasurementType.waist: [MeasurementType.hips, MeasurementType.shoulders, MeasurementType.chest],
      MeasurementType.chest: [MeasurementType.waist, MeasurementType.shoulders],
      MeasurementType.hips: [MeasurementType.waist, MeasurementType.thighLeft],
      MeasurementType.shoulders: [MeasurementType.waist, MeasurementType.chest],
      MeasurementType.bicepsLeft: [MeasurementType.bicepsRight, MeasurementType.forearmLeft],
      MeasurementType.bicepsRight: [MeasurementType.bicepsLeft, MeasurementType.forearmRight],
      MeasurementType.thighLeft: [MeasurementType.thighRight, MeasurementType.calfLeft],
      MeasurementType.thighRight: [MeasurementType.thighLeft, MeasurementType.calfRight],
    };

    final related = relatedMap[_type];
    if (related == null || related.isEmpty) return const SizedBox.shrink();

    // Filter to only metrics that have data
    final available = related.where((t) => summary.latestByType.containsKey(t)).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(AppLocalizations.of(context).measurementDetailScreenRelatedMetrics, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.5)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: available.map((t) {
              final entry = summary.latestByType[t]!;
              final change = summary.changeFromPrevious[t];
              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  // Navigate to that metric's detail
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeasurementDetailScreen(measurementType: t.name),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.displayName, style: TextStyle(fontSize: 11, color: textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatValue(entry.value)} ${entry.unit}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ],
                      ),
                      if (change != null && change.abs() >= 0.1) ...[
                        const SizedBox(width: 8),
                        Icon(
                          change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: _getRelatedChangeColor(t, change),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildHistoryList(
    List<MeasurementEntry> history, {
    required String unit,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    if (history.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 40, color: textMuted),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).volumeHistoryNoHistoryYet,
                    style: TextStyle(color: textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = history[index];
          final previousValue = index < history.length - 1
              ? history[index + 1].getValueInUnit(_isMetric)
              : null;
          final currentValue = entry.getValueInUnit(_isMetric);
          final change =
              previousValue != null ? currentValue - previousValue : null;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 4, 16, 4),
            child: Dismissible(
              key: Key(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsetsDirectional.only(end: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) => _confirmDelete(entry),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('d').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cyan,
                            ),
                          ),
                          Text(
                            DateFormat('MMM yy').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 9,
                              color: cyan,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            DateFormat('h:mm a').format(entry.recordedAt),
                            style: TextStyle(
                              fontSize: 8,
                              color: cyan.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatValue(currentValue)} $unit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          if (entry.notes?.isNotEmpty ?? false)
                            Text(
                              entry.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (change != null && change.abs() >= 0.01)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getChangeColor(change).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              change > 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: _getChangeColor(change),
                            ),
                            Text(
                              _formatValue(change.abs()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getChangeColor(change),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: history.length,
      ),
    );
  }

  /// Period breakdown — averages per sub-period across the selected range,
  /// mirroring Google Health's weekly breakdown. Buckets are weekly for
  /// ranges ≥ 30 days and daily for the shorter ranges (≤7D). Each row shows
  /// the bucket label and its average value; empty buckets are omitted (no
  /// fabricated zeros).
  Widget _buildPeriodBreakdown(
    List<MeasurementEntry> history, {
    required String unit,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    // Needs at least 2 entries spanning ≥ 2 buckets to be meaningful.
    if (history.length < 2) return const SizedBox.shrink();

    final daily = _selectedPeriod == '1d' ||
        _selectedPeriod == '3d' ||
        _selectedPeriod == '7d';

    // Bucket key → list of values (in the user's unit).
    final buckets = <DateTime, List<double>>{};
    DateTime keyFor(DateTime d) {
      if (daily) return DateTime(d.year, d.month, d.day);
      // Week bucket anchored to Monday (ISO week start).
      final dayOnly = DateTime(d.year, d.month, d.day);
      return dayOnly.subtract(Duration(days: dayOnly.weekday - 1));
    }

    for (final e in history) {
      final k = keyFor(e.recordedAt);
      (buckets[k] ??= []).add(e.getValueInUnit(_isMetric));
    }
    if (buckets.length < 2) return const SizedBox.shrink();

    // Newest bucket first, to match the history list ordering.
    final sortedKeys = buckets.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    String labelFor(DateTime start) {
      if (daily) {
        return DateFormat('EEE, MMM d').format(start);
      }
      final end = start.add(const Duration(days: 6));
      // Same-month weeks read "May 24–30"; cross-month "May 28 – Jun 3".
      if (start.month == end.month) {
        return '${DateFormat('MMM d').format(start)}–${DateFormat('d').format(end)}';
      }
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
    }

    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            daily ? 'Daily breakdown' : 'Weekly breakdown',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < sortedKeys.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: cardBorder.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labelFor(sortedKeys[i]),
                      style: TextStyle(fontSize: 14, color: textPrimary),
                    ),
                  ),
                  Text(
                    '${_formatValue(_avg(buckets[sortedKeys[i]]!))} $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cyan,
                    ),
                  ),
                  if (!daily && buckets[sortedKeys[i]]!.length > 1) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${buckets[sortedKeys[i]]!.length}×',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;

  /// "About [metric]" — a short, accurate explainer. Per-metric copy that is
  /// technique/health-correct, never generic filler.
  Widget _buildAboutSection({
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
  }) {
    final body = _aboutCopyFor(_type);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'About ${_type.displayName}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(fontSize: 13, height: 1.5, color: textMuted),
          ),
        ],
      ),
    );
  }

  /// Per-metric explainer copy. Cited to ACE / CDC / WHO norms where a
  /// numeric range is stated; girth metrics share a tape-measure technique
  /// note keyed by body site so each reads correctly.
  String _aboutCopyFor(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight:
        return 'Body weight naturally swings 1–2 kg (2–4 lb) day to day from '
            'water, food in transit, and glycogen. Weigh under the same '
            'conditions — first thing in the morning, after the bathroom, '
            'before eating — and read the trend line, not any single day.';
      case MeasurementType.bodyFat:
        return 'Body-fat percentage is the share of your weight that is fat '
            'mass. ACE reference ranges put male athletes around 6–13% and '
            'fitness 14–17%; female athletes 14–20% and fitness 21–24%. '
            'Home scales and calipers vary, so track your own trend rather '
            'than chasing an exact number.';
      case MeasurementType.waist:
        return 'Waist circumference is a strong marker of abdominal fat and '
            'metabolic risk. CDC/WHO flag raised risk above 94 cm (37 in) for '
            'men and 80 cm (31.5 in) for women. Measure at the midpoint '
            'between the lowest rib and the top of the hip bone, after a '
            'normal exhale — do not suck in.';
      case MeasurementType.hips:
        return 'Hip circumference is measured at the widest point of the '
            'buttocks with the tape level all the way around. Paired with '
            'waist it gives the waist-to-hip ratio, another fat-distribution '
            'marker. Keep the tape snug but not compressing the skin.';
      case MeasurementType.chest:
        return 'Chest circumference is measured around the fullest part of '
            'the chest, tape level under the armpits, at the end of a normal '
            'breath. Useful for tracking upper-body size changes from '
            'training.';
      case MeasurementType.shoulders:
        return 'Shoulder circumference wraps around the widest point of the '
            'deltoids with arms relaxed at your sides. It tracks upper-body '
            'width gained from pressing and pulling work.';
      case MeasurementType.neck:
        return 'Neck circumference is measured just below the larynx (Adam\'s '
            'apple) with the tape level. It feeds the U.S. Navy body-fat '
            'estimate alongside waist and height.';
      case MeasurementType.bicepsLeft:
      case MeasurementType.bicepsRight:
        return 'Upper-arm circumference is measured at the midpoint between '
            'shoulder and elbow. Measure relaxed for a consistent baseline, '
            'or flexed if you prefer — just stay consistent. Tracking left '
            'and right separately surfaces side-to-side imbalances.';
      case MeasurementType.forearmLeft:
      case MeasurementType.forearmRight:
        return 'Forearm circumference is measured at the thickest point below '
            'the elbow with the arm relaxed and palm up. Tracking each side '
            'separately helps catch grip or imbalance issues.';
      case MeasurementType.thighLeft:
      case MeasurementType.thighRight:
        return 'Thigh circumference is measured at the midpoint between hip '
            'and knee, or a fixed distance above the kneecap — pick one and '
            'stay consistent. Logging each leg separately reveals asymmetry '
            'common after injury.';
      case MeasurementType.calfLeft:
      case MeasurementType.calfRight:
        return 'Calf circumference is measured at the widest point of the '
            'lower leg with the muscle relaxed. Measure both legs at the same '
            'point each time to track growth and balance.';
    }
  }

}
