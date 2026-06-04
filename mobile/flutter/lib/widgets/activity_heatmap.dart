import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/stat_typography.dart';
import '../core/theme/accent_color_provider.dart';
import '../core/theme/theme_colors.dart';
import '../data/models/consistency.dart';
import '../data/providers/consistency_provider.dart';
import '../data/services/api_client.dart';

import '../l10n/generated/app_localizations.dart';
/// GitHub-style activity heatmap widget showing workout history
class ActivityHeatmap extends ConsumerStatefulWidget {
  final Function(String date)? onDayTapped;
  final Set<String>? highlightedDates;
  final VoidCallback? onSearchTapped;
  final bool isSearchActive;

  const ActivityHeatmap({
    super.key,
    this.onDayTapped,
    this.highlightedDates,
    this.onSearchTapped,
    this.isSearchActive = false,
  });

  @override
  ConsumerState<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends ConsumerState<ActivityHeatmap> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to end (most recent) after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeRange = ref.watch(heatmapTimeRangeProvider);
    final apiClient = ref.watch(apiClientProvider);

    return FutureBuilder<String?>(
      future: apiClient.getUserId(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const _HeatmapLoading();
        }

        final userId = userSnapshot.data!;
        // For YTD, use exact Jan 1 start date instead of weeks
        final now = DateTime.now();
        final heatmapParams = timeRange == HeatmapTimeRange.ytd
            ? (userId: userId, weeks: 0, startDate: '${now.year}-01-01', endDate: now.toIso8601String().split('T')[0])
            : (userId: userId, weeks: timeRange.weeks, startDate: null as String?, endDate: null as String?);
        final heatmapAsync = ref.watch(activityHeatmapProvider(heatmapParams));

        // The header shows a big "{totalCompleted} workouts" count, so it lives
        // inside the data branch (count only known once data resolves). During
        // loading/error we render a lightweight header that still exposes the
        // range dropdown so the user can change range to recover.
        return heatmapAsync.when(
          data: (data) {
            // Scroll to most recent after grid builds
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              }
            });
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, totalCompleted: data.totalCompleted),
                const SizedBox(height: 16),
                _buildHeatmapGrid(context, data),
                const SizedBox(height: 14),
                _buildLegend(context),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, totalCompleted: null),
              const SizedBox(height: 16),
              const _HeatmapLoading(),
            ],
          ),
          // Retry invalidates the EXACT params tuple in scope (including
          // startDate/endDate for the YTD range), so the rebuild re-runs
          // the same provider instance that failed.
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, totalCompleted: null),
              const SizedBox(height: 16),
              _HeatmapError(
                error: e.toString(),
                onRetry: () =>
                    ref.invalidate(activityHeatmapProvider(heatmapParams)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Clean Gravl-style header: a big "{totalCompleted} workouts" count on the
  /// left + a range dropdown on the right, plus an optional search icon.
  /// [totalCompleted] is null while the grid is loading or errored — we then
  /// fall back to a generic "Workouts" label so the chrome stays put.
  Widget _buildHeader(BuildContext context, {required int? totalCompleted}) {
    final timeRange = ref.watch(heatmapTimeRangeProvider);
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big bold workout count, e.g. "84 workouts".
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (totalCompleted != null)
                StatNumber(
                  value: totalCompleted.toString(),
                  unit: totalCompleted == 1 ? 'workout' : 'workouts',
                  size: StatType.primary,
                  color: colors.textPrimary,
                  unitColor: colors.textSecondary,
                )
              else
                Text(
                  AppLocalizations.of(context).activityHeatmapActivity,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                ),
            ],
          ),
        ),
        // Optional search affordance (exercise filtering) — small icon only.
        if (widget.onSearchTapped != null) ...[
          GestureDetector(
            onTap: widget.onSearchTapped,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isSearchActive
                    ? accentColor.withValues(alpha: 0.18)
                    : colors.elevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isSearchActive
                      ? accentColor.withValues(alpha: 0.5)
                      : colors.cardBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search,
                size: 16,
                color: widget.isSearchActive ? accentColor : colors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Range dropdown — replaces the old chip cluster. The preset ranges
        // (Week/1M/3M/6M/YTD/1Y) live behind this menu.
        _RangeDropdown(
          current: timeRange,
          accentColor: accentColor,
          colors: colors,
          onSelected: (range) {
            ref.read(heatmapTimeRangeProvider.notifier).state = range;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid(
      BuildContext context, CalendarHeatmapResponse data) {
    // Organize data by date for quick lookup
    final dataByDate = <String, CalendarHeatmapData>{};
    for (final day in data.data) {
      dataByDate[day.date] = day;
    }

    final endDate = DateTime.parse(data.endDate);
    final rawStart = DateTime.parse(data.startDate);

    // Snap the grid origin to the Monday on/before the data start so every
    // column is a real Mon→Sun week (DateTime.weekday: Mon=1..Sun=7). This lets
    // the day-label column be a fixed Mon..Sun and makes the grid Monday-first
    // like Gravl, regardless of which weekday the backend window began on.
    final gridStart = rawStart.subtract(Duration(days: rawStart.weekday - 1));
    final totalDays = endDate.difference(gridStart).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    // Build the 4-bucket volume ramp thresholds from the window's non-zero
    // volumes (relative quartile bucketing — see _computeVolumeThresholds).
    final thresholds = _computeVolumeThresholds(data.data);

    // Month labels are derived from the snapped grid origin.
    final monthLabels = _generateMonthLabels(gridStart, totalWeeks);

    const dayLabelWidth = 34.0; // fits 3-letter day labels (Mon..Sun)
    const cellGap = 3.0;

    // Mon-first 3-letter labels, aligned row-for-row with the grid.
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = ThemeColors.of(context);
        final availableWidth = constraints.maxWidth;
        final gridWidth = availableWidth - dayLabelWidth;
        // Larger cells than before: fill available width, capped 14-22px.
        final fitCellSize = gridWidth / totalWeeks;
        final cellSize = fitCellSize.clamp(14.0, 22.0);
        final colWidth = cellSize + cellGap;
        final needsScroll = colWidth * totalWeeks > gridWidth;

        final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            );

        Widget buildGrid() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels row
              Padding(
                padding: const EdgeInsets.only(left: dayLabelWidth),
                child: Row(
                  children: monthLabels.map((label) {
                    final width = label.weekSpan * colWidth;
                    return SizedBox(
                      width: width < 24.0 ? 24.0 : width,
                      child: Text(
                        label.month,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: labelStyle,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // Grid with day labels
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day labels column (Mon..Sun), aligned to each cell row.
                  Column(
                    children: dayLabels.map((day) {
                      return Container(
                        height: cellSize,
                        width: dayLabelWidth,
                        margin: const EdgeInsets.only(bottom: cellGap),
                        alignment: Alignment.centerLeft,
                        child: Text(day, style: labelStyle),
                      );
                    }).toList(),
                  ),

                  // Heatmap cells (column = week, row = Mon..Sun)
                  Row(
                    children: List.generate(totalWeeks, (weekIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(right: cellGap),
                        child: Column(
                          children: List.generate(7, (dayIndex) {
                            final dayOffset = weekIndex * 7 + dayIndex;
                            final date =
                                gridStart.add(Duration(days: dayOffset));
                            final dateStr =
                                DateFormat('yyyy-MM-dd').format(date);
                            final dayData = dataByDate[dateStr];
                            // Pre-window / post-window padding cells render as
                            // empty (no data), keeping the grid rectangular.
                            final inWindow = !date.isBefore(rawStart) &&
                                !date.isAfter(endDate);

                            return _HeatmapCell(
                              date: dateStr,
                              status: inWindow
                                  ? (dayData?.statusEnum ?? CalendarStatus.rest)
                                  : CalendarStatus.future,
                              volume: inWindow ? (dayData?.volume ?? 0) : 0,
                              thresholds: thresholds,
                              workoutName: dayData?.workoutName,
                              isHighlighted:
                                  widget.highlightedDates?.contains(dateStr) ??
                                      false,
                              onTap: () => widget.onDayTapped?.call(dateStr),
                              size: cellSize,
                              gap: cellGap,
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          );
        }

        if (needsScroll) {
          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: buildGrid(),
          );
        } else {
          return buildGrid();
        }
      },
    );
  }

  /// Compute the 3 ascending thresholds that split positive volumes into the
  /// top 3 of the 4 blue buckets. Bucketing is RELATIVE per-window by quantile
  /// (33rd/66th percentile of the sorted non-zero volumes) so the brightest
  /// blues always represent this window's biggest sessions — a single PR day
  /// can't wash everything else to the dimmest stop, and a low-volume window
  /// still gets a full ramp. Returns [t1, t2, t3] where:
  ///   0 < v <= t1            → bucket 1 (dimmest blue)
  ///   t1 < v <= t2           → bucket 2
  ///   t2 < v <= t3           → bucket 3
  ///   v  > t3                → bucket 4 (brightest blue)
  /// Returns null when there are no positive-volume days (ramp unused).
  List<double>? _computeVolumeThresholds(List<CalendarHeatmapData> days) {
    final volumes = days
        .map((d) => d.volume)
        .where((v) => v > 0)
        .toList()
      ..sort();
    if (volumes.isEmpty) return null;
    if (volumes.length < 4) {
      // Too few points for stable quantiles — split the observed range into
      // even thirds (max-relative) so the few days still spread across blues.
      final maxV = volumes.last;
      return [maxV * 0.25, maxV * 0.5, maxV * 0.75];
    }
    double quantile(double q) {
      final pos = (volumes.length - 1) * q;
      final lo = pos.floor();
      final hi = pos.ceil();
      if (lo == hi) return volumes[lo];
      final frac = pos - lo;
      return volumes[lo] * (1 - frac) + volumes[hi] * frac;
    }

    return [quantile(1 / 3), quantile(2 / 3), quantile(0.9)];
  }

  Widget _buildLegend(BuildContext context) {
    final colors = ThemeColors.of(context);
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        );
    return Row(
      children: [
        Text('Volume', style: mutedStyle),
        const Spacer(),
        Text('Less', style: mutedStyle),
        const SizedBox(width: 5),
        // Empty cell + the 4 ascending blue stops, dim → bright.
        _LegendCell(color: _VolumeRamp.emptyColor(colors.isDark)),
        const SizedBox(width: 3),
        ..._VolumeRamp.blueStops.map(
          (c) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: _LegendCell(color: c),
          ),
        ),
        const SizedBox(width: 2),
        Text('More', style: mutedStyle),
      ],
    );
  }

  List<_MonthLabel> _generateMonthLabels(DateTime startDate, int totalWeeks) {
    final labels = <_MonthLabel>[];
    String? currentMonth;
    int weekSpan = 0;

    for (int week = 0; week < totalWeeks; week++) {
      final weekStart = startDate.add(Duration(days: week * 7));
      final monthStr = DateFormat('MMM').format(weekStart);

      if (monthStr != currentMonth) {
        if (currentMonth != null) {
          labels.add(_MonthLabel(month: currentMonth, weekSpan: weekSpan));
        }
        currentMonth = monthStr;
        weekSpan = 1;
      } else {
        weekSpan++;
      }
    }

    if (currentMonth != null) {
      labels.add(_MonthLabel(month: currentMonth, weekSpan: weekSpan));
    }

    return labels;
  }
}

/// Year / range dropdown — replaces the old chip cluster. Renders the current
/// range label with a chevron (e.g. "3M ⌄") and pops a menu of all preset
/// ranges. Kept compact so it never overflows the header on iPhone SE.
class _RangeDropdown extends StatelessWidget {
  final HeatmapTimeRange current;
  final Color accentColor;
  final ThemeColors colors;
  final ValueChanged<HeatmapTimeRange> onSelected;

  const _RangeDropdown({
    required this.current,
    required this.accentColor,
    required this.colors,
    required this.onSelected,
  });

  /// Shows YTD as the literal year (Gravl "2026"), presets by their short label.
  String _labelFor(HeatmapTimeRange range) {
    if (range == HeatmapTimeRange.ytd) return DateTime.now().year.toString();
    return range.label;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HeatmapTimeRange>(
      onSelected: onSelected,
      tooltip: 'Change range',
      position: PopupMenuPosition.under,
      color: colors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.cardBorder),
      ),
      itemBuilder: (context) => HeatmapTimeRange.values.map((range) {
        final selected = range == current;
        return PopupMenuItem<HeatmapTimeRange>(
          value: range,
          height: 40,
          child: Row(
            children: [
              Text(
                _labelFor(range),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? accentColor : colors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              if (selected) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: accentColor),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labelFor(current),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// The semantic blue volume ramp — a fixed data-color scale (like the existing
/// AppColors.waterBlue), intentionally non-accent. Dim → bright = more volume.
/// Shared by [_HeatmapCell] and the legend so they never drift.
class _VolumeRamp {
  const _VolumeRamp._();

  /// Bucket 1 (dimmest) → bucket 4 (brightest).
  static const List<Color> blueStops = [
    Color(0xFF1E3A8A),
    Color(0xFF2563EB),
    Color(0xFF3B82F6),
    Color(0xFF60A5FA),
  ];

  /// Subtle dark fill for no-volume / rest / missed / future cells. No border.
  static Color emptyColor(bool isDark) => isDark
      ? AppColors.textSecondary.withValues(alpha: 0.08)
      : Colors.grey.withValues(alpha: 0.10);

  /// Resolve a cell's fill from its volume + status against the window
  /// thresholds [t1,t2,t3]. Completed-but-zero-volume days (e.g. imported
  /// cardio) get the lowest blue so a logged day never looks empty.
  static Color colorFor({
    required CalendarStatus status,
    required double volume,
    required List<double>? thresholds,
    required bool isDark,
  }) {
    if (volume <= 0) {
      if (status == CalendarStatus.completed) return blueStops[0];
      return emptyColor(isDark);
    }
    // Positive volume → 1 of 4 ascending blues by quantile thresholds.
    if (thresholds == null) return blueStops[0];
    if (volume <= thresholds[0]) return blueStops[0];
    if (volume <= thresholds[1]) return blueStops[1];
    if (volume <= thresholds[2]) return blueStops[2];
    return blueStops[3];
  }
}

/// Individual heatmap cell — colored by training VOLUME (blue ramp), not status.
class _HeatmapCell extends StatelessWidget {
  final String date;
  final CalendarStatus status;
  final double volume;
  final List<double>? thresholds;
  final String? workoutName;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final double size;
  final double gap;

  const _HeatmapCell({
    required this.date,
    required this.status,
    required this.volume,
    required this.thresholds,
    this.workoutName,
    this.isHighlighted = false,
    this.onTap,
    this.size = 16,
    this.gap = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AccentColorScope.of(context).getColor(isDark);
    final fill = _VolumeRamp.colorFor(
      status: status,
      volume: volume,
      thresholds: thresholds,
      isDark: isDark,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.only(bottom: gap),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(5),
          // Only the exercise-search highlight draws a ring — empty cells have
          // NO border (the Gravl-clean look).
          border: isHighlighted
              ? Border.all(color: accentColor, width: 1.5)
              : null,
        ),
      ),
    );
  }
}

/// Legend cell
class _LegendCell extends StatelessWidget {
  final Color color;

  const _LegendCell({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Month label data
class _MonthLabel {
  final String month;
  final int weekSpan;

  _MonthLabel({required this.month, required this.weekSpan});
}

/// Loading state for heatmap
class _HeatmapLoading extends StatelessWidget {
  const _HeatmapLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.cyan),
          ),
        ),
      ),
    );
  }
}

/// Error state for heatmap. Includes a Retry action that re-runs the exact
/// provider params that failed (passed in by the caller so the YTD range
/// re-fetches correctly).
class _HeatmapError extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _HeatmapError({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).myLibraryTabFailedToLoadActivity,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(AppLocalizations.of(context).buttonRetry),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Exercise search bar for heatmap filtering
class ExerciseSearchBar extends ConsumerStatefulWidget {
  final Function(String exerciseName)? onSearch;
  final VoidCallback? onClear;

  const ExerciseSearchBar({
    super.key,
    this.onSearch,
    this.onClear,
  });

  @override
  ConsumerState<ExerciseSearchBar> createState() => _ExerciseSearchBarState();
}

class _ExerciseSearchBarState extends ConsumerState<ExerciseSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _controller.text.isNotEmpty;
      });
    });
  }

  Future<void> _loadUserId() async {
    final apiClient = ref.read(apiClientProvider);
    _userId = await apiClient.getUserId();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(exerciseSearchQueryProvider);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).activityHeatmapSearchExercise,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _showSuggestions = value.isNotEmpty;
                    });
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _performSearch(value);
                    }
                  },
                ),
              ),
              if (searchQuery != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textMuted,
                  onPressed: () {
                    _controller.clear();
                    ref.read(exerciseSearchQueryProvider.notifier).state = null;
                    widget.onClear?.call();
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                ),
            ],
          ),
        ),

        // Suggestions dropdown
        if (_showSuggestions && _userId != null)
          _buildSuggestions(context, _userId!),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context, String userId) {
    final suggestionsAsync = ref.watch(
      exerciseSuggestionsProvider((userId: userId, query: _controller.text)),
    );

    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 4),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ListTile(
                dense: true,
                title: Text(
                  suggestion.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  '${suggestion.timesPerformed} times',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                onTap: () {
                  _controller.text = suggestion.name;
                  _performSearch(suggestion.name);
                  _focusNode.unfocus();
                  setState(() {
                    _showSuggestions = false;
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _performSearch(String query) {
    ref.read(exerciseSearchQueryProvider.notifier).state = query;
    widget.onSearch?.call(query);
  }
}
