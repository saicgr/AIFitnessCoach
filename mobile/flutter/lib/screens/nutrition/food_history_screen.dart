import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/food_search_service.dart';
import 'widgets/food_search_bar.dart';

/// Smart food history screen with search, frequently eaten, and date-grouped logs.
class FoodHistoryScreen extends ConsumerStatefulWidget {
  final String userId;

  const FoodHistoryScreen({super.key, required this.userId});

  @override
  ConsumerState<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends ConsumerState<FoodHistoryScreen> {
  List<FoodLog> _logs = [];
  List<SavedFood> _frequentFoods = [];
  bool _isLoading = true;
  String? _error;
  String? _activeSearchQuery;
  String? _selectedMealFilter;
  String? _selectedSourceFilter;
  int _currentLimit = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Date range filter
  _DateRange _selectedDateRange = _DateRange.all;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Get fromDate/toDate strings based on selected date range
  (String?, String?) _getDateRangeParams() {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    switch (_selectedDateRange) {
      case _DateRange.today:
        final d = fmt.format(now);
        return (d, d);
      case _DateRange.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (fmt.format(start), fmt.format(now));
      case _DateRange.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return (fmt.format(start), fmt.format(now));
      case _DateRange.last30:
        return (fmt.format(now.subtract(const Duration(days: 30))), fmt.format(now));
      case _DateRange.custom:
        if (_customDateRange != null) {
          return (fmt.format(_customDateRange!.start), fmt.format(_customDateRange!.end));
        }
        return (null, null);
      case _DateRange.all:
        return (null, null);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final (fromDate, toDate) = _getDateRangeParams();

      final results = await Future.wait([
        repo.getFoodLogs(
          widget.userId,
          limit: _currentLimit,
          mealType: _selectedMealFilter,
          fromDate: fromDate,
          toDate: toDate,
        ),
        repo.getSavedFoods(
          userId: widget.userId,
          limit: 10,
          sortBy: 'times_logged',
          sortOrder: 'desc',
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _logs = results[0] as List<FoodLog>;
        _frequentFoods = (results[1] as SavedFoodsResponse)
            .items
            .where((f) => f.timesLogged > 0)
            .take(8)
            .toList();
        _hasMore = _logs.length >= _currentLimit;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load food history. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final repo = ref.read(nutritionRepositoryProvider);
      _currentLimit += 50;
      final (fromDate, toDate) = _getDateRangeParams();
      final logs = await repo.getFoodLogs(
        widget.userId,
        limit: _currentLimit,
        mealType: _selectedMealFilter,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (!mounted) return;
      setState(() {
        _logs = logs;
        _hasMore = logs.length >= _currentLimit;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onMealFilterChanged(String? filter) {
    setState(() {
      _selectedMealFilter = filter;
      _currentLimit = 50;
    });
    _loadData();
  }

  void _onSourceFilterChanged(String? source) {
    setState(() => _selectedSourceFilter = source);
    final searchService = ref.read(foodSearchServiceProvider);
    searchService.setSource(source);
    if (_activeSearchQuery != null && _activeSearchQuery!.isNotEmpty) {
      searchService.search(_activeSearchQuery!, widget.userId);
    }
  }

  void _onDateRangeChanged(_DateRange range) async {
    if (range == _DateRange.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customDateRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      );
      if (picked == null) return;
      setState(() {
        _customDateRange = picked;
        _selectedDateRange = _DateRange.custom;
        _currentLimit = 50;
      });
    } else {
      setState(() {
        _selectedDateRange = range;
        _currentLimit = 50;
      });
    }
    _loadData();
  }

  String _getSuggestedMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 17) return 'snack';
    return 'dinner';
  }

  Future<void> _relogSavedFood(SavedFood food) async {
    final mealType = _getSuggestedMealType();
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.relogSavedFood(
        userId: widget.userId,
        savedFoodId: food.id,
        mealType: mealType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Re-logged ${food.name} as $mealType'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to re-log ${food.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _relogFoodLog(FoodLog log) async {
    final mealType = _getSuggestedMealType();
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.copyFoodLog(logId: log.id, mealType: mealType);
      if (!mounted) return;
      final foodName = log.foodItems.isNotEmpty
          ? log.foodItems.first.name
          : log.mealType;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Re-logged $foodName as $mealType'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to re-log food'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteFoodLog(FoodLog log) async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.deleteFoodLog(log.id);
      if (!mounted) return;
      setState(() => _logs.remove(log));
      final foodName = log.foodItems.isNotEmpty
          ? log.foodItems.first.name
          : log.mealType;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted $foodName'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _relogFoodLog(log),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete food log'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getMealEmoji(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🥗';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍴';
    }
  }

  /// Group logs by date (Today, Yesterday, or formatted date)
  Map<String, List<FoodLog>> _groupLogsByDate(List<FoodLog> logs) {
    final grouped = <String, List<FoodLog>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final log in logs) {
      final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      String label;
      if (logDate == today) {
        label = 'Today';
      } else if (logDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEEE, MMM d').format(logDate);
      }
      grouped.putIfAbsent(label, () => []).add(log);
    }
    return grouped;
  }

  /// Compute quick stats from loaded logs
  _QuickStats _computeStats() {
    if (_logs.isEmpty) return const _QuickStats();
    final totalCals = _logs.fold<int>(0, (sum, l) => sum + l.totalCalories);
    final totalProtein = _logs.fold<double>(0, (sum, l) => sum + l.proteinG);

    // Unique days
    final days = <String>{};
    for (final l in _logs) {
      days.add(DateFormat('yyyy-MM-dd').format(l.loggedAt));
    }
    final avgCals = days.isNotEmpty ? totalCals ~/ days.length : 0;

    // Highest calorie meal
    FoodLog? topMeal;
    for (final l in _logs) {
      if (topMeal == null || l.totalCalories > topMeal.totalCalories) {
        topMeal = l;
      }
    }

    return _QuickStats(
      totalMeals: _logs.length,
      avgDailyCals: avgCals,
      totalProteinG: totalProtein,
      daysTracked: days.length,
      topMeal: topMeal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final isSearching = _activeSearchQuery != null && _activeSearchQuery!.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Food History',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            child: FoodSearchBar(
              userId: widget.userId,
              hintText: 'Search meals, foods, "high protein"...',
              onSearch: (query) {
                setState(() {
                  _activeSearchQuery = query.trim().isEmpty ? null : query;
                });
              },
            ),
          ),

          // Collapsible filter bar (date range + meal type in one row)
          _CollapsibleFilterBar(
            selectedDateRange: _selectedDateRange,
            customDateRange: _customDateRange,
            selectedMealFilter: _selectedMealFilter,
            selectedSourceFilter: _selectedSourceFilter,
            onDateRangeChanged: _onDateRangeChanged,
            onMealFilterChanged: _onMealFilterChanged,
            onSourceFilterChanged: _onSourceFilterChanged,
            isDark: isDark,
          ),

          const SizedBox(height: 6),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: teal),
                  )
                : _error != null
                    ? _ErrorState(
                        message: _error!,
                        onRetry: _loadData,
                        isDark: isDark,
                      )
                    : isSearching
                        ? _SearchResultsView(
                            userId: widget.userId,
                            isDark: isDark,
                            onRelogResult: (result) {
                              if (result.source == FoodSearchSource.recent &&
                                  result.originalData != null) {
                                final log = FoodLog.fromJson(result.originalData!);
                                _relogFoodLog(log);
                              }
                            },
                          )
                        : _HistoryListView(
                            logs: _logs,
                            frequentFoods: _frequentFoods,
                            groupedLogs: _groupLogsByDate(_logs),
                            stats: _computeStats(),
                            hasMore: _hasMore,
                            isLoadingMore: _isLoadingMore,
                            isDark: isDark,
                            onLoadMore: _loadMore,
                            onRelogSavedFood: _relogSavedFood,
                            onRelogFoodLog: _relogFoodLog,
                            onDeleteFoodLog: _deleteFoodLog,
                            getMealEmoji: _getMealEmoji,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textMuted: textMuted,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            teal: teal,
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Range Enum ────────────────────────────────────────────────────────

enum _DateRange {
  all('All Time'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  last30('Last 30d'),
  custom('Custom');

  final String label;
  const _DateRange(this.label);
}

// ─── Collapsible Filter Bar ─────────────────────────────────────────────────

class _CollapsibleFilterBar extends StatefulWidget {
  final _DateRange selectedDateRange;
  final DateTimeRange? customDateRange;
  final String? selectedMealFilter;
  final String? selectedSourceFilter;
  final ValueChanged<_DateRange> onDateRangeChanged;
  final ValueChanged<String?> onMealFilterChanged;
  final ValueChanged<String?> onSourceFilterChanged;
  final bool isDark;

  const _CollapsibleFilterBar({
    required this.selectedDateRange,
    required this.customDateRange,
    required this.selectedMealFilter,
    required this.selectedSourceFilter,
    required this.onDateRangeChanged,
    required this.onMealFilterChanged,
    required this.onSourceFilterChanged,
    required this.isDark,
  });

  @override
  State<_CollapsibleFilterBar> createState() => _CollapsibleFilterBarState();
}

class _CollapsibleFilterBarState extends State<_CollapsibleFilterBar> {
  bool _expanded = false;

  String get _dateLabel {
    if (widget.selectedDateRange == _DateRange.custom && widget.customDateRange != null) {
      final fmt = DateFormat('MMM d');
      return '${fmt.format(widget.customDateRange!.start)} - ${fmt.format(widget.customDateRange!.end)}';
    }
    return widget.selectedDateRange.label;
  }

  String get _mealLabel {
    if (widget.selectedMealFilter == null) return 'All Meals';
    return widget.selectedMealFilter![0].toUpperCase() +
        widget.selectedMealFilter!.substring(1);
  }

  String get _sourceLabel {
    switch (widget.selectedSourceFilter) {
      case 'usda': return 'USDA';
      case 'usda_branded': return 'Branded';
      case 'openfoodfacts': return 'Open Food Facts';
      case 'indb': return 'Indian';
      case 'cnf': return 'Canadian';
      default: return 'All DBs';
    }
  }

  bool get _hasActiveFilters =>
      widget.selectedDateRange != _DateRange.all ||
      widget.selectedMealFilter != null ||
      widget.selectedSourceFilter != null;

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final cyan = widget.isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Collapsed summary bar — always visible
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _hasActiveFilters ? teal : cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 16,
                    color: _hasActiveFilters ? teal : textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_dateLabel  ·  $_mealLabel  ·  $_sourceLabel',
                    style: TextStyle(
                      color: _hasActiveFilters ? textSecondary : textMuted,
                      fontSize: 13,
                      fontWeight: _hasActiveFilters ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded filter rows
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range chips
                  Text(
                    'DATE RANGE',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _DateRange.values.map((range) {
                      final isSelected = widget.selectedDateRange == range;
                      return _buildChip(
                        label: range.label,
                        icon: range == _DateRange.custom ? Icons.calendar_today : null,
                        isSelected: isSelected,
                        accentColor: cyan,
                        textMuted: textMuted,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        onTap: () => widget.onDateRangeChanged(range),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Meal type chips
                  Text(
                    'MEAL TYPE',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      (null, 'All', '🍴'),
                      ('breakfast', 'Breakfast', '🍳'),
                      ('lunch', 'Lunch', '🥗'),
                      ('dinner', 'Dinner', '🌙'),
                      ('snack', 'Snack', '🍎'),
                    ].map((filter) {
                      final (value, label, emoji) = filter;
                      final isSelected = widget.selectedMealFilter == value;
                      return _buildChip(
                        label: '$emoji $label',
                        isSelected: isSelected,
                        accentColor: teal,
                        textMuted: textMuted,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        onTap: () => widget.onMealFilterChanged(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Database source chips
                  Text(
                    'DATABASE',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      (null, 'All'),
                      ('usda', 'USDA'),
                      ('usda_branded', 'Branded'),
                      ('openfoodfacts', 'Open Food Facts'),
                      ('indb', 'Indian'),
                      ('cnf', 'Canadian'),
                    ].map((filter) {
                      final (value, label) = filter;
                      final isSelected = widget.selectedSourceFilter == value;
                      return _buildChip(
                        label: label,
                        isSelected: isSelected,
                        accentColor: cyan,
                        textMuted: textMuted,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        onTap: () => widget.onSourceFilterChanged(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color accentColor,
    required Color textMuted,
    required Color cardBg,
    required Color cardBorder,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? accentColor : cardBg;
    final textColor = isSelected ? Colors.white : textMuted;
    final border = isSelected ? accentColor : cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Stats ────────────────────────────────────────────────────────────

class _QuickStats {
  final int totalMeals;
  final int avgDailyCals;
  final double totalProteinG;
  final int daysTracked;
  final FoodLog? topMeal;

  const _QuickStats({
    this.totalMeals = 0,
    this.avgDailyCals = 0,
    this.totalProteinG = 0,
    this.daysTracked = 0,
    this.topMeal,
  });
}

class _QuickStatsCard extends StatelessWidget {
  final _QuickStats stats;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;

  const _QuickStatsCard({
    required this.stats,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
  });

  @override
  Widget build(BuildContext context) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final yellow = AppColors.yellow;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.restaurant,
            value: '${stats.totalMeals}',
            label: 'Meals',
            color: teal,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          _statDivider(),
          _StatItem(
            icon: Icons.local_fire_department,
            value: '${stats.avgDailyCals}',
            label: 'Avg/day',
            color: cyan,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          _statDivider(),
          _StatItem(
            icon: Icons.fitness_center,
            value: '${stats.totalProteinG.round()}g',
            label: 'Protein',
            color: purple,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          _statDivider(),
          _StatItem(
            icon: Icons.calendar_today,
            value: '${stats.daysTracked}',
            label: 'Days',
            color: yellow,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: cardBorder,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Results View ────────────────────────────────────────────────────

class _SearchResultsView extends ConsumerWidget {
  final String userId;
  final bool isDark;
  final Function(FoodSearchResult result)? onRelogResult;

  const _SearchResultsView({
    required this.userId,
    required this.isDark,
    this.onRelogResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(foodSearchStateProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return searchState.when(
      data: (state) {
        if (state is FoodSearchLoading) {
          return Center(child: CircularProgressIndicator(color: teal));
        }
        if (state is FoodSearchError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: textMuted, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: TextStyle(color: textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }
        if (state is FoodSearchResults) {
          final results = state;
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, color: textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No results for "${results.query}"',
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final allResults = results.allResults;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allResults.length,
            itemBuilder: (context, index) {
              final result = allResults[index];
              return _SearchResultTile(
                result: result,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                cardBg: cardBg,
                cardBorder: cardBorder,
                teal: teal,
                onTap: () => onRelogResult?.call(result),
              );
            },
          );
        }
        // FoodSearchInitial
        return const SizedBox.shrink();
      },
      loading: () => Center(child: CircularProgressIndicator(color: teal)),
      error: (e, _) => Center(
        child: Text(
          'Search error',
          style: TextStyle(color: textMuted),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final FoodSearchResult result;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final VoidCallback? onTap;

  const _SearchResultTile({
    required this.result,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              result.source.label.substring(0, 1),
              style: TextStyle(
                color: teal,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          result.name,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              '${result.calories} cal',
              style: TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (result.protein != null) ...[
              Text('  ', style: TextStyle(color: textMuted, fontSize: 12)),
              Text(
                '${result.protein!.round()}g P',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
            Text(
              '  ${result.source.label}',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.add_circle_outline, color: teal, size: 22),
        onTap: onTap,
      ),
    );
  }
}

// ─── History List View ──────────────────────────────────────────────────────

class _HistoryListView extends StatelessWidget {
  final List<FoodLog> logs;
  final List<SavedFood> frequentFoods;
  final Map<String, List<FoodLog>> groupedLogs;
  final _QuickStats stats;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isDark;
  final VoidCallback onLoadMore;
  final Function(SavedFood) onRelogSavedFood;
  final Function(FoodLog) onRelogFoodLog;
  final Function(FoodLog) onDeleteFoodLog;
  final String Function(String) getMealEmoji;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;

  const _HistoryListView({
    required this.logs,
    required this.frequentFoods,
    required this.groupedLogs,
    required this.stats,
    required this.hasMore,
    required this.isLoadingMore,
    required this.isDark,
    required this.onLoadMore,
    required this.onRelogSavedFood,
    required this.onRelogFoodLog,
    required this.onDeleteFoodLog,
    required this.getMealEmoji,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty && frequentFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined, color: textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              'No food history yet',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging meals to see your history here!',
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Quick stats card
        if (stats.totalMeals > 0) ...[
          _QuickStatsCard(
            stats: stats,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            cardBg: cardBg,
            cardBorder: cardBorder,
            teal: teal,
          ),
          const SizedBox(height: 16),
        ],

        // Frequently Eaten section
        if (frequentFoods.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.bolt,
            title: 'Frequently Eaten',
            textPrimary: textPrimary,
            teal: teal,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: frequentFoods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final food = frequentFoods[index];
                return _FrequentFoodChip(
                  food: food,
                  rank: index + 1,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  teal: teal,
                  onTap: () => onRelogSavedFood(food),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Recent History section
        if (logs.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.schedule,
            title: 'Recent',
            textPrimary: textPrimary,
            teal: teal,
          ),
          const SizedBox(height: 8),
          ...groupedLogs.entries.expand((entry) {
            // Per-day summary
            final dayLogs = entry.value;
            final dayCals = dayLogs.fold<int>(0, (s, l) => s + l.totalCalories);
            final dayProtein = dayLogs.fold<double>(0, (s, l) => s + l.proteinG);

            return [
              // Date header with day totals
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Row(
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$dayCals cal',
                      style: TextStyle(
                        color: teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dayProtein.round()}g P',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Food log items for this date
              ...dayLogs.map((log) => _FoodLogTile(
                    log: log,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    teal: teal,
                    getMealEmoji: getMealEmoji,
                    onTap: () => onRelogFoodLog(log),
                    onDismissed: () => onDeleteFoodLog(log),
                  )),
            ];
          }),

          // Load more button
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: isLoadingMore
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: teal,
                        ),
                      )
                    : TextButton(
                        onPressed: onLoadMore,
                        child: Text(
                          'Load More',
                          style: TextStyle(
                            color: teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textPrimary;
  final Color teal;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.textPrimary,
    required this.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: teal, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Frequent Food Chip ─────────────────────────────────────────────────────

class _FrequentFoodChip extends StatelessWidget {
  final SavedFood food;
  final int rank;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final VoidCallback onTap;

  const _FrequentFoodChip({
    required this.food,
    required this.rank,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    required this.onTap,
  });

  String _rankMedal(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _rankMedal(rank),
                  style: TextStyle(fontSize: rank <= 3 ? 14 : 11),
                ),
                const Spacer(),
                Icon(Icons.add_circle_outline, size: 16, color: teal),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              food.name,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${food.totalCalories ?? 0}',
                  style: TextStyle(
                    color: teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' cal',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '${food.timesLogged}x',
                  style: TextStyle(
                    color: purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Food Log Tile ──────────────────────────────────────────────────────────

class _FoodLogTile extends StatelessWidget {
  final FoodLog log;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final String Function(String) getMealEmoji;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _FoodLogTile({
    required this.log,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    required this.getMealEmoji,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final foodName = log.foodItems.isNotEmpty
        ? log.foodItems.first.name
        : log.mealType;
    final extraCount = log.foodItems.length > 1 ? ' +${log.foodItems.length - 1}' : '';
    final timeStr = DateFormat('h:mm a').format(log.loggedAt);

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Text(
                getMealEmoji(log.mealType),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$foodName$extraCount',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${log.proteinG.round()}P / ${log.carbsG.round()}C / ${log.fatG.round()}F',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${log.totalCalories}',
                style: TextStyle(
                  color: teal,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' cal',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error State ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: teal),
            label: Text(
              'Retry',
              style: TextStyle(color: teal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
