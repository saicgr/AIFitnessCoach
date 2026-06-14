import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import 'package:fitwiz/widgets/design_system/zealova.dart';
import '../../data/models/nutrition.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/food_search_service.dart';
import 'widgets/food_report_dialog.dart';
import 'widgets/food_search_bar.dart';
import '../../widgets/glass_sheet.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/portion_amount_input.dart';

import '../../l10n/generated/app_localizations.dart';
part 'food_history_screen_part_date_range.dart';
part 'food_history_screen_part_frequent_food_chip.dart';

/// SharedPreferences key holding the JSON snapshot of the most recent
/// "all logs / all meal types" food-history load. Persisting only the default
/// (unfiltered) view keeps the blob small and means a cold start renders the
/// list instantly while the network revalidates in the background.
const String _kFoodHistoryCacheKey = 'cachefirst::food_history_default::v1';


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
    // Cache-first: paint the last-seen logs instantly from disk (no await
    // blocks the first frame), then revalidate over the network in _loadData.
    _hydrateFromCache();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'food_history_viewed');
    });
  }

  /// User-scoped cache key — two accounts on the same device never collide.
  String get _cacheKey => '$_kFoodHistoryCacheKey::${widget.userId}';

  /// Read the persisted snapshot of the default (unfiltered) history view and
  /// emit it immediately. Best-effort: any failure degrades to a clean cache
  /// miss so the network load still drives the screen.
  Future<void> _hydrateFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final logsJson = decoded['logs'];
      final freqJson = decoded['frequentFoods'];
      if (logsJson is! List || freqJson is! List) return;
      final logs = logsJson
          .whereType<Map<String, dynamic>>()
          .map(FoodLog.fromJson)
          .toList();
      final freq = freqJson
          .whereType<Map<String, dynamic>>()
          .map(SavedFood.fromJson)
          .toList();
      // A network result may already have landed first — never overwrite
      // fresher data with the stale cache.
      if (!mounted || !_isLoading) return;
      setState(() {
        _logs = logs;
        _frequentFoods = freq;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('💾 [FoodHistory] cache hydrate failed: $e');
    }
  }

  /// Persist the default (unfiltered) view so the next cold start is instant.
  /// Only the all-logs / all-meal-types view is cached to keep the blob small.
  Future<void> _writeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode({
        'logs': _logs.map((l) => l.toJson()).toList(),
        'frequentFoods': _frequentFoods.map((f) => f.toJson()).toList(),
      }));
    } catch (e) {
      debugPrint('💾 [FoodHistory] cache write failed: $e');
    }
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
    // Only show the blocking placeholder when there is genuinely nothing on
    // screen yet. A cache hit (or any prior content) keeps content visible
    // while the network revalidates — no spinner flash for returning users.
    if (_logs.isEmpty && _frequentFoods.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

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

      // Write-through the default (unfiltered) view so the next cold start is
      // instant. Filtered views are intentionally not cached.
      if (_selectedMealFilter == null &&
          _selectedDateRange == _DateRange.all) {
        await _writeCache();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Keep any already-visible (cached) content rather than blanking to an
        // error screen — only surface the error on a genuine cold failure.
        if (_logs.isEmpty && _frequentFoods.isEmpty) {
          _error = 'Failed to load food history. Please try again.';
        }
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
          content: Text(AppLocalizations.of(context)!.foodHistoryScreenReLoggedAs(food.name, mealType)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.foodHistoryScreenFailedToReLog(food.name)),
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
          content: Text(AppLocalizations.of(context)!.foodHistoryScreenReLoggedAs2(foodName, mealType)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).foodHistoryFailedToReLog),
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
          content: Text(AppLocalizations.of(context)!.foodHistoryScreenDeleted(foodName)),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: AppLocalizations.of(context).workoutUiBuildersUndo,
            onPressed: () => _relogFoodLog(log),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).foodHistoryFailedToDeleteFood),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editFoodLog(FoodLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGlassSheet<void>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: _EditFoodLogSheet(
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
              SnackBar(
                content: Text(AppLocalizations.of(context).foodHistoryFailedToUpdateFood),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
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
    final tc = ThemeColors.of(context);
    final isDark = tc.isDark;
    final bg = tc.background;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final cardBg = tc.surface;
    final cardBorder = AppColors.cardBorder;
    final teal = tc.accent;
    final isSearching = _activeSearchQuery != null && _activeSearchQuery!.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: ZealovaAppBar(
        kicker: 'NUTRITION',
        title: AppLocalizations.of(context).foodHistoryFoodHistory,
        titleSize: 26,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            child: FoodSearchBar(
              userId: widget.userId,
              hintText: AppLocalizations.of(context).foodHistorySearchMealsFoodsHigh,
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
                // Layout-matched skeleton instead of a blocking spinner — a
                // returning user with a warm cache never reaches this branch.
                ? const SkeletonList(
                    scrollable: true,
                    itemCount: 7,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  )
                : _error != null
                    ? _ErrorState(
                        message: _error!,
                        onRetry: _loadData,
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
