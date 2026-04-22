import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../widgets/pill_app_bar.dart';
import '../../data/models/nutrition.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/food_search_service.dart';
import 'widgets/food_report_dialog.dart';
import 'widgets/food_search_bar.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/portion_amount_input.dart';

part 'food_history_screen_part_date_range.dart';
part 'food_history_screen_part_frequent_food_chip.dart';


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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'food_history_viewed');
    });
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

  void _editFoodLog(FoodLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditFoodLogSheet(
        log: log,
        isDark: isDark,
        onSave: (multiplier) async {
          final repo = ref.read(nutritionRepositoryProvider);
          try {
            await repo.updateFoodLog(
              logId: log.id,
              totalCalories: (log.totalCalories * multiplier).round(),
              proteinG: log.proteinG * multiplier,
              carbsG: log.carbsG * multiplier,
              fatG: log.fatG * multiplier,
              fiberG: log.fiberG != null ? log.fiberG! * multiplier : null,
              portionMultiplier: multiplier,
            );
            if (!mounted) return;
            Navigator.of(ctx).pop();
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Updated to ${(multiplier * 100).round()}% portion',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update food log'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
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
      appBar: const PillAppBar(title: 'Food History'),
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
                            onEditFoodLog: _editFoodLog,
                            onDeleteFoodLog: _deleteFoodLog,
                            getMealEmoji: _getMealEmoji,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textMuted: textMuted,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            teal: teal,
                            apiClient: ref.read(apiClientProvider),
                          ),
          ),
        ],
      ),
    );
  }
}
