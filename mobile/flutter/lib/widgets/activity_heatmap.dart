import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
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
        final heatmapAsync = ref.watch(
          activityHeatmapProvider((userId: userId, weeks: timeRange.weeks)),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time range selector
            _buildHeader(context),
            const SizedBox(height: 12),

            // Heatmap grid
            heatmapAsync.when(
              data: (data) => _buildHeatmapGrid(context, data),
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

    return Row(
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
                    ? AppColors.cyan.withOpacity(0.2)
                    : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.isSearchActive
                      ? AppColors.cyan.withOpacity(0.5)
                      : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search,
                size: 14,
                color: widget.isSearchActive
                    ? AppColors.cyan
                    : AppColors.textMuted,
              ),
            ),
          ),
        const Spacer(),
        // Time range selector chips - wrapped in Flexible to prevent overflow
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: HeatmapTimeRange.values.map((range) {
                final isSelected = range == timeRange;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _TimeRangeChip(
                    label: range.label,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(heatmapTimeRangeProvider.notifier).state = range;
                      // Scroll to end when range changes
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController
                              .jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
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

    // Calculate weeks to display
    final endDate = DateTime.parse(data.endDate);
    final startDate = DateTime.parse(data.startDate);
    final totalDays = endDate.difference(startDate).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    // Generate month labels
    final monthLabels = _generateMonthLabels(startDate, totalWeeks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels row
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Row(
                  children: monthLabels.map((label) {
                    return SizedBox(
                      width: label.weekSpan * 14.0,
                      child: Text(
                        label.month,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                      ),
                    );
                  }).toList(),
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
                        height: 14,
                        width: 20,
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
                          );
                        }),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Less',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
        ),
        const SizedBox(width: 4),
        // Rest/None
        _LegendCell(color: Colors.white.withOpacity(0.05)),
        // Light activity
        _LegendCell(color: AppColors.success.withOpacity(0.3)),
        // Medium activity
        _LegendCell(color: AppColors.success.withOpacity(0.6)),
        // High activity
        const _LegendCell(color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          'More',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
        ),
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
  final VoidCallback onTap;

  const _TimeRangeChip({
    required this.label,
    required this.isSelected,
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
              ? AppColors.cyan.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan.withOpacity(0.5)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
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

  const _HeatmapCell({
    required this.date,
    required this.status,
    this.workoutName,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getColor(),
          borderRadius: BorderRadius.circular(2),
          border: isHighlighted
              ? Border.all(color: AppColors.cyan, width: 1.5)
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

  Color _getColor() {
    switch (status) {
      case CalendarStatus.completed:
        return AppColors.success;
      case CalendarStatus.missed:
        return AppColors.coral.withOpacity(0.6);
      case CalendarStatus.future:
        return Colors.white.withOpacity(0.02);
      case CalendarStatus.rest:
        return Colors.white.withOpacity(0.05);
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
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.elevated,
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
