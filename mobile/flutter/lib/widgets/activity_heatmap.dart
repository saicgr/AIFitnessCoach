import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/consistency.dart';
import '../data/providers/consistency_provider.dart';
import '../data/services/api_client.dart';

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time range selector
            _buildHeader(context),
            const SizedBox(height: 12),

            // Heatmap grid
            heatmapAsync.when(
              data: (data) {
                // Scroll to most recent after grid builds
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return _buildHeatmapGrid(context, data);
              },
              loading: () => const _HeatmapLoading(),
              error: (e, _) => _HeatmapError(error: e.toString()),
            ),

            const SizedBox(height: 12),

            // Legend
            _buildLegend(context),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final timeRange = ref.watch(heatmapTimeRangeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentEnum = ref.watch(accentColorProvider);
    final apiClient = ref.read(apiClientProvider);
    final accentColor = accentEnum.getColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            // Search button
            if (widget.onSearchTapped != null)
              GestureDetector(
                onTap: widget.onSearchTapped,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isSearchActive
                        ? accentColor.withValues(alpha: 0.2)
                        : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.isSearchActive
                          ? accentColor.withValues(alpha: 0.5)
                          : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.search,
                    size: 14,
                    color: widget.isSearchActive
                        ? accentColor
                        : AppColors.textMuted,
                  ),
                ),
              ),
            const Spacer(),
            // Refresh button
            GestureDetector(
              onTap: () {
                final timeRange = ref.read(heatmapTimeRangeProvider);
                apiClient.getUserId().then((uid) {
                  if (uid != null) {
                    ref.invalidate(activityHeatmapProvider((userId: uid, weeks: timeRange.weeks, startDate: null, endDate: null)));
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                child: Icon(Icons.refresh, size: 14, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Time range selector chips — wrap to avoid overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...HeatmapTimeRange.values.map((range) {
                final isSelected = range == timeRange;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TimeRangeChip(
                    label: range.label,
                    isSelected: isSelected,
                    accentColor: accentColor,
                    onTap: () {
                      ref.read(heatmapTimeRangeProvider.notifier).state = range;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });
                    },
                  ),
                );
              }),
              // Custom date range — simple from/to picker
              GestureDetector(
                onTap: () => _showSimpleDateRangePicker(context, ref, apiClient, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    ),
                  ),
                  child: Icon(Icons.date_range, size: 14, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSimpleDateRangePicker(
    BuildContext context, WidgetRef ref, dynamic apiClient, bool isDark,
  ) async {
    final now = DateTime.now();

    // Pick "From" date
    final fromDate = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 90)),
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Select start date',
    );
    if (fromDate == null || !context.mounted) return;

    // Pick "To" date
    final toDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: fromDate,
      lastDate: now,
      helpText: 'Select end date',
    );
    if (toDate == null) return;

    final weeks = (toDate.difference(fromDate).inDays / 7).ceil();
    if (weeks < 1) return;

    final uid = await apiClient.getUserId();
    if (uid != null) {
      ref.invalidate(activityHeatmapProvider((userId: uid, weeks: weeks, startDate: null, endDate: null)));
    }
  }

  Widget _buildHeatmapGrid(
      BuildContext context, CalendarHeatmapResponse data) {
    // Organize data by date for quick lookup
    final dataByDate = <String, CalendarHeatmapData>{};
    for (final day in data.data) {
      dataByDate[day.date] = day;
    }

    // Calculate weeks to display
    final endDate = DateTime.parse(data.endDate);
    final startDate = DateTime.parse(data.startDate);
    final totalDays = endDate.difference(startDate).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    // Generate month labels
    final monthLabels = _generateMonthLabels(startDate, totalWeeks);

    const dayLabelWidth = 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final gridWidth = availableWidth - dayLabelWidth;
        // Fill available width, but cap cell size between 10-20px
        final fitCellSize = gridWidth / totalWeeks;
        final cellSize = fitCellSize.clamp(10.0, 20.0);
        final needsScroll = cellSize * totalWeeks > gridWidth;

        Widget buildGrid() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels row
              Padding(
                padding: EdgeInsets.only(left: dayLabelWidth),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                  children: monthLabels.map((label) {
                    final width = label.weekSpan * cellSize;
                    return SizedBox(
                      width: width < 24.0 ? 24.0 : width,
                      child: Text(
                        label.month,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              ),
              const SizedBox(height: 4),

              // Grid with day labels
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day labels column
                  Column(
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                      return SizedBox(
                        height: cellSize,
                        width: dayLabelWidth,
                        child: Text(
                          day,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Heatmap cells
                  Row(
                    children: List.generate(totalWeeks, (weekIndex) {
                      return Column(
                        children: List.generate(7, (dayIndex) {
                          final dayOffset = weekIndex * 7 + dayIndex;
                          final date = startDate.add(Duration(days: dayOffset));
                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final dayData = dataByDate[dateStr];

                          return _HeatmapCell(
                            date: dateStr,
                            status: dayData?.statusEnum ?? CalendarStatus.rest,
                            workoutName: dayData?.workoutName,
                            isHighlighted:
                                widget.highlightedDates?.contains(dateStr) ??
                                    false,
                            onTap: () => widget.onDayTapped?.call(dateStr),
                            size: cellSize - 2, // margin of 1 on each side
                          );
                        }),
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

  Widget _buildLegend(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.textMuted, fontSize: 10,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Missed indicator
        _LegendCell(color: AppColors.coral.withOpacity(0.6)),
        const SizedBox(width: 2),
        Text('Missed', style: mutedStyle),
        const SizedBox(width: 12),
        // Completed indicator
        const _LegendCell(color: AppColors.success),
        const SizedBox(width: 2),
        Text('Done', style: mutedStyle),
        const SizedBox(width: 12),
        // Rest indicator
        _LegendCell(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
        const SizedBox(width: 2),
        Text('Rest', style: mutedStyle),
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

/// Time range selector chip
class _TimeRangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TimeRangeChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? accentColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}

/// Individual heatmap cell
class _HeatmapCell extends StatelessWidget {
  final String date;
  final CalendarStatus status;
  final String? workoutName;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final double size;

  const _HeatmapCell({
    required this.date,
    required this.status,
    this.workoutName,
    this.isHighlighted = false,
    this.onTap,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getColor(Theme.of(context).brightness == Brightness.dark),
          borderRadius: BorderRadius.circular(2),
          border: isHighlighted
              ? Border.all(color: AppColors.cyan, width: 1.5)
              : (status == CalendarStatus.rest || status == CalendarStatus.future)
                  ? Border.all(color: Colors.grey.withOpacity(0.15), width: 0.5)
                  : null,
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Color _getColor(bool isDark) {
    switch (status) {
      case CalendarStatus.completed:
        return AppColors.success;
      case CalendarStatus.missed:
        return AppColors.coral.withOpacity(0.6);
      case CalendarStatus.future:
        return isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.06);
      case CalendarStatus.rest:
        return isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08);
    }
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

/// Error state for heatmap
class _HeatmapError extends StatelessWidget {
  final String error;

  const _HeatmapError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
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
              'Failed to load activity',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
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
                    hintText: 'Search exercise...',
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
