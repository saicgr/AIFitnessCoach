import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/food_search_service.dart' as search;
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../food_history_screen.dart';
import 'food_report_dialog.dart';

/// Filter tabs for the food browser browse mode
enum FoodBrowserFilter { recent, saved, foodDb }

/// Display mode for search results
enum _SearchDisplayMode { pages, list, carousel }

/// A group of search results sharing the same matchedQuery
class _FoodGroup {
  final String label;
  final List<search.FoodSearchResult> results;

  const _FoodGroup({required this.label, required this.results});
}

/// Inline food browser panel: shows Recent + Saved foods when text is empty,
/// live search results when typing.
class FoodBrowserPanel extends ConsumerStatefulWidget {
  final String userId;
  final MealType mealType;
  final bool isDark;
  final String searchQuery;
  final FoodBrowserFilter filter;
  final ValueChanged<FoodBrowserFilter> onFilterChanged;
  final VoidCallback onFoodLogged;

  const FoodBrowserPanel({
    super.key,
    required this.userId,
    required this.mealType,
    required this.isDark,
    required this.searchQuery,
    required this.filter,
    required this.onFilterChanged,
    required this.onFoodLogged,
  });

  @override
  ConsumerState<FoodBrowserPanel> createState() => _FoodBrowserPanelState();
}

class _FoodBrowserPanelState extends ConsumerState<FoodBrowserPanel> {
  // Saved foods data
  List<SavedFood> _savedFoods = [];
  bool _savedFoodsLoading = true;
  int _savedOffset = 0;
  bool _savedHasMore = true;
  static const _savedPageSize = 20;

  // Source filter for Food DB tab and search mode
  String? _selectedDbSource;

  // Per-item logging state: food name -> logging/done
  final Map<String, _LogState> _logStates = {};

  // Expanded item index for NL accordion (-1 = none, 0 = first auto-expanded)
  int _expandedNLIndex = 0;

  // Search result display state
  PageController? _searchPageController;
  int _currentSearchPage = 0;
  _SearchDisplayMode _displayMode = _SearchDisplayMode.pages;
  String? _expandedSearchKey; // key of expanded search card (only one at a time)


  @override
  void initState() {
    super.initState();
    _loadSavedFoods();
  }

  @override
  void didUpdateWidget(FoodBrowserPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset search state when query changes
    if (widget.searchQuery != oldWidget.searchQuery) {
      _expandedSearchKey = null;
      _currentSearchPage = 0;
      _searchPageController?.dispose();
      _searchPageController = null;
    }
  }

  @override
  void dispose() {
    _searchPageController?.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFoods() async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final response = await repo.getSavedFoods(
        userId: widget.userId,
        limit: _savedPageSize,
        sortBy: 'times_logged',
        sortOrder: 'desc',
      );
      if (!mounted) return;
      setState(() {
        _savedFoods = response.items;
        _savedFoodsLoading = false;
        _savedHasMore = response.items.length >= _savedPageSize;
      });
    } catch (e) {
      debugPrint('FoodBrowser: Error loading saved foods: $e');
      if (mounted) setState(() => _savedFoodsLoading = false);
    }
  }

  Future<void> _loadMoreSaved() async {
    if (!_savedHasMore) return;
    _savedOffset += _savedPageSize;
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final response = await repo.getSavedFoods(
        userId: widget.userId,
        limit: _savedPageSize,
        offset: _savedOffset,
        sortBy: 'times_logged',
        sortOrder: 'desc',
      );
      if (!mounted) return;
      setState(() {
        _savedFoods.addAll(response.items);
        _savedHasMore = response.items.length >= _savedPageSize;
      });
    } catch (e) {
      debugPrint('FoodBrowser: Error loading more saved foods: $e');
    }
  }

  Future<void> _logFood(String description, String itemKey) async {
    setState(() => _logStates[itemKey] = _LogState.loading);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: widget.mealType.value,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      if (!mounted) return;
      setState(() => _logStates[itemKey] = _LogState.done);
      widget.onFoodLogged();
      // Reset checkmark after brief delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _logStates.remove(itemKey));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(itemKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _relogSavedFood(SavedFood food) async {
    final key = 'saved_${food.id}';
    setState(() => _logStates[key] = _LogState.loading);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.relogSavedFood(
        userId: widget.userId,
        savedFoodId: food.id,
        mealType: widget.mealType.value,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      if (!mounted) return;
      setState(() => _logStates[key] = _LogState.done);
      widget.onFoodLogged();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _logStates.remove(key));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _relogFoodLog(FoodLog log) async {
    final key = 'recent_${log.id}';
    setState(() => _logStates[key] = _LogState.loading);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.copyFoodLog(logId: log.id, mealType: widget.mealType.value);
      ref.read(xpProvider.notifier).markMealLogged();
      if (!mounted) return;
      setState(() => _logStates[key] = _LogState.done);
      widget.onFoodLogged();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _logStates.remove(key));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = widget.searchQuery.trim().isNotEmpty;

    if (isSearching) {
      return _buildSearchMode();
    }
    return _buildBrowseMode();
  }

  // ─── Browse Mode ─────────────────────────────────────────────

  Widget _buildBrowseMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter tabs
        _BrowseFilterTabs(
          selected: widget.filter,
          onChanged: widget.onFilterChanged,
          isDark: widget.isDark,
        ),
        const SizedBox(height: 8),
        // Content based on selected filter
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildBrowseContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseContent() {
    switch (widget.filter) {
      case FoodBrowserFilter.recent:
        return _buildRecentAndSavedView();
      case FoodBrowserFilter.saved:
        return _buildSavedOnlyView();
      case FoodBrowserFilter.foodDb:
        return _buildFoodDbView();
    }
  }

  Widget _buildRecentAndSavedView() {
    final state = ref.watch(nutritionProvider);
    final recentLogs = state.recentLogs;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Deduplicate recent items by food name
    final seen = <String>{};
    final uniqueRecent = <FoodLog>[];
    for (final log in recentLogs) {
      final name = log.foodItems.isNotEmpty ? log.foodItems.first.name : log.mealType;
      if (seen.add(name.toLowerCase())) {
        uniqueRecent.add(log);
      }
      if (uniqueRecent.length >= 8) break;
    }

    if (uniqueRecent.isEmpty && _savedFoods.isEmpty && !_savedFoodsLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_outlined, color: textMuted, size: 40),
              const SizedBox(height: 12),
              Text(
                'Log a meal to see your history here',
                style: TextStyle(color: textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        // Recent section
        if (uniqueRecent.isNotEmpty) ...[
          _BrowseSectionHeader(
            icon: Icons.schedule,
            title: 'RECENT',
            count: uniqueRecent.length,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FoodHistoryScreen(userId: widget.userId)),
              );
            },
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ...uniqueRecent.map((log) {
            final name = log.foodItems.isNotEmpty ? log.foodItems.first.name : log.mealType;
            final key = 'recent_${log.id}';
            return _FoodBrowserItem(
              name: name,
              calories: log.totalCalories,
              logState: _logStates[key],
              onAdd: () => _relogFoodLog(log),
              isDark: widget.isDark,
            );
          }),
          const SizedBox(height: 12),
        ],
        // Saved section
        if (_savedFoodsLoading)
          ..._buildShimmerRows(3)
        else if (_savedFoods.isNotEmpty) ...[
          _BrowseSectionHeader(
            icon: Icons.bookmark_outline,
            title: 'SAVED',
            count: _savedFoods.length,
            onSeeAll: () {
              widget.onFilterChanged(FoodBrowserFilter.saved);
            },
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ..._savedFoods.take(5).map((food) {
            final key = 'saved_${food.id}';
            return _FoodBrowserItem(
              name: food.name,
              calories: food.totalCalories ?? 0,
              logState: _logStates[key],
              onAdd: () => _relogSavedFood(food),
              isDark: widget.isDark,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSavedOnlyView() {
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (_savedFoodsLoading) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _BrowseSectionHeader(
            icon: Icons.bookmark,
            title: 'YOUR SAVED FOODS',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ..._buildShimmerRows(5),
        ],
      );
    }

    if (_savedFoods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, color: textMuted, size: 40),
              const SizedBox(height: 12),
              Text(
                'No saved foods yet',
                style: TextStyle(color: textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Star foods after logging to save them',
                style: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
          _loadMoreSaved();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _BrowseSectionHeader(
            icon: Icons.bookmark,
            title: 'YOUR SAVED FOODS',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ..._savedFoods.map((food) {
            final key = 'saved_${food.id}';
            return _FoodBrowserItem(
              name: food.name,
              calories: food.totalCalories ?? 0,
              subtitle: food.description,
              logState: _logStates[key],
              onAdd: () => _relogSavedFood(food),
              isDark: widget.isDark,
            );
          }),
          if (_savedHasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.isDark ? AppColors.teal : AppColorsLight.teal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodDbView() {
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      children: [
        // Source sub-filter chips
        _SourceDropdownPill(
          selected: _selectedDbSource,
          onChanged: (source) {
            setState(() => _selectedDbSource = source);
            ref.read(search.foodSearchServiceProvider).setSource(source);
          },
          isDark: widget.isDark,
        ),
        const SizedBox(height: 24),
        // Prompt to search
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, color: textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Search 528,000+ foods from USDA, Canadian, Indian & more databases',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start typing above...',
                    style: TextStyle(color: textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Search Mode ─────────────────────────────────────────────

  Widget _buildSearchMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source filter chips
        _SourceDropdownPill(
          selected: _selectedDbSource,
          onChanged: (source) {
            setState(() => _selectedDbSource = source);
            final service = ref.read(search.foodSearchServiceProvider);
            service.setSource(source);
            // Re-trigger search with new source
            if (widget.searchQuery.trim().isNotEmpty) {
              final cachedLogs = ref.read(nutritionProvider).recentLogs;
              service.search(widget.searchQuery, widget.userId, cachedLogs: cachedLogs);
            }
          },
          isDark: widget.isDark,
        ),
        const SizedBox(height: 8),
        // Search results
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchState = ref.watch(search.foodSearchStateProvider);
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return searchState.when(
      data: (state) {
        // ── NL states ──────────────────────────────────────────
        if (state is search.FoodSearchNLLoading) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: _buildShimmerRows(5),
          );
        }
        if (state is search.FoodSearchNLError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: textMuted, size: 36),
                const SizedBox(height: 8),
                Text(state.message, style: TextStyle(color: textMuted, fontSize: 13)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(search.foodSearchServiceProvider).analyzeNaturalLanguage(widget.searchQuery);
                  },
                  child: Text('Retry', style: TextStyle(color: teal)),
                ),
              ],
            ),
          );
        }
        if (state is search.FoodSearchNLResults) {
          return _buildNLResults(state.result);
        }

        // ── Existing keyword search states ─────────────────────
        if (state is search.FoodSearchLoading) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: _buildShimmerRows(5),
          );
        }
        if (state is search.FoodSearchError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: textMuted, size: 36),
                const SizedBox(height: 8),
                Text(state.message, style: TextStyle(color: textMuted, fontSize: 13)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    final cachedLogs = ref.read(nutritionProvider).recentLogs;
                    ref.read(search.foodSearchServiceProvider).search(widget.searchQuery, widget.userId, cachedLogs: cachedLogs);
                  },
                  child: Text('Retry', style: TextStyle(color: teal)),
                ),
              ],
            ),
          );
        }
        if (state is search.FoodSearchResults) {
          if (state.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, color: textMuted, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No foods found for "${state.query}"',
                      style: TextStyle(color: textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use Analyze for AI estimation',
                      style: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          // Trigger AI review after results load
          // User goals for tag generation
          final userGoals = ref.read(authStateProvider).user?.goalsList ?? [];

          // Group results: personal (saved + recent) and database
          final personalResults = [...state.saved, ...state.recent];
          final dbResults = [...state.database, ...state.foodDatabase];
          final foodGroups = _groupDbResults(dbResults);
          final isMultiGroup = foodGroups.length > 1;

          // Default display mode: pages for multi-group, list for single
          final effectiveMode = isMultiGroup ? _displayMode : _SearchDisplayMode.list;

          return Column(
            children: [
              // Search timing + results
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.searchTimeMs != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${state.totalCount} results \u00b7 ${state.searchTimeMs}ms',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ),
                    // Personal results (always shown above groups)
                    if (personalResults.isNotEmpty) ...[
                      _BrowseSectionHeader(
                        icon: Icons.person_outline,
                        title: 'YOUR FOODS',
                        count: personalResults.length,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 6),
                      ...personalResults.map((result) {
                        final key = 'search_${result.source.name}_${result.id}';
                        return _ExpandableSearchCard(
                          result: result,
                          logState: _logStates[key],
                          isExpanded: _expandedSearchKey == key,
                          onTap: () => setState(() {
                            _expandedSearchKey = _expandedSearchKey == key ? null : key;
                          }),
                          onLog: (desc) => _logFood(desc, key),
                          isWeightEditable: false,
                          isDark: widget.isDark,
                          goalTags: _buildGoalTags(
                            goals: userGoals,
                            calories: result.calories,
                            protein: result.protein ?? 0,
                            carbs: result.carbs ?? 0,
                            fat: result.fat ?? 0,
                            isDark: widget.isDark,
                          ),
                          apiClient: ref.read(apiClientProvider),
                          searchService: ref.read(search.foodSearchServiceProvider),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              // DB results with display mode
              Expanded(
                child: _SearchResultsPageView(
                  groups: foodGroups,
                  displayMode: effectiveMode,
                  currentPage: _currentSearchPage,
                  expandedSearchKey: _expandedSearchKey,
                  logStates: _logStates,
                  userGoals: userGoals,
                  isDark: widget.isDark,
                  selectedDbSource: _selectedDbSource,
                  onPageChanged: (page) => setState(() => _currentSearchPage = page),
                  onExpandCard: (key) => setState(() {
                    _expandedSearchKey = _expandedSearchKey == key ? null : key;
                  }),
                  onLogFood: (desc, key) => _logFood(desc, key),
                  apiClient: ref.read(apiClientProvider),
                  searchService: ref.read(search.foodSearchServiceProvider),
                ),
              ),
              // Display mode toggle (only for multi-group)
              if (isMultiGroup)
                _DisplayModeToggle(
                  mode: _displayMode,
                  onChanged: (mode) => setState(() => _displayMode = mode),
                  isDark: widget.isDark,
                ),
            ],
          );
        }
        // FoodSearchInitial
        return const SizedBox.shrink();
      },
      loading: () => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: _buildShimmerRows(5),
      ),
      error: (e, _) => Center(
        child: Text('Search error', style: TextStyle(color: textMuted)),
      ),
    );
  }

  /// Group DB results by matched_query, preserving order
  List<_FoodGroup> _groupDbResults(List<search.FoodSearchResult> dbResults) {
    if (dbResults.isEmpty) return [];

    final hasGroups = dbResults.any((r) => r.matchedQuery != null);
    if (!hasGroups) {
      final title = _selectedDbSource != null
          ? 'Food Database (${_sourceLabel(_selectedDbSource!)})'
          : 'Food Database';
      return [_FoodGroup(label: title, results: dbResults)];
    }

    final groups = <String, List<search.FoodSearchResult>>{};
    final groupOrder = <String>[];
    for (final result in dbResults) {
      final group = result.matchedQuery ?? '';
      if (!groups.containsKey(group)) {
        groups[group] = [];
        groupOrder.add(group);
      }
      groups[group]!.add(result);
    }

    return groupOrder.map((group) {
      final title = group.isNotEmpty
          ? group[0].toUpperCase() + group.substring(1)
          : 'Other';
      return _FoodGroup(label: title, results: groups[group]!);
    }).toList();
  }

  // ─── NL Results UI (Compact Accordion with Inline Picker) ───

  // Keys for _NLItemSection GlobalKeys to read state
  final Map<int, GlobalKey<_NLItemSectionState>> _nlSectionKeys = {};

  GlobalKey<_NLItemSectionState> _nlKey(int index) {
    return _nlSectionKeys.putIfAbsent(index, () => GlobalKey<_NLItemSectionState>());
  }

  /// Recalculate summary totals from all section states
  int get _nlTotalCalories {
    int total = 0;
    for (final entry in _nlSectionKeys.entries) {
      final state = entry.value.currentState;
      if (state != null) total += state.displayCalories;
    }
    return total;
  }

  /// Count how many items are already logged (done)
  int get _nlDoneCount {
    int count = 0;
    for (final entry in _nlSectionKeys.entries) {
      final key = 'nl_${entry.key}';
      if (_logStates[key] == _LogState.done) count++;
    }
    return count;
  }

  Widget _buildNLResults(search.FoodAnalysisResult result) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    const orange = Color(0xFFF97316);

    if (result.foodItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, color: textMuted, size: 36),
              const SizedBox(height: 8),
              Text('Could not parse any food items', style: TextStyle(color: textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final allKey = 'nl_all';
    final allState = _logStates[allKey];
    final doneCount = _nlDoneCount;
    final totalItems = result.foodItems.length;
    final totalCal = _nlTotalCalories > 0 ? _nlTotalCalories : result.totalCalories;

    // Compute remaining calories (subtract done items)
    int remainingCal = 0;
    for (int i = 0; i < totalItems; i++) {
      final key = 'nl_$i';
      if (_logStates[key] != _LogState.done) {
        final sectionState = _nlSectionKeys[i]?.currentState;
        remainingCal += sectionState?.displayCalories ?? result.foodItems[i].calories;
      }
    }

    final hasLoggedSome = doneCount > 0 && doneCount < totalItems;
    final buttonLabel = allState == _LogState.done
        ? 'Logged!'
        : hasLoggedSome
            ? 'Log Remaining ($remainingCal kcal)'
            : 'Log All ($totalCal kcal)';

    return Column(
      children: [
        // ── Summary banner (live-updating) ──
        Container(
          margin: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: teal.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: teal),
              const SizedBox(width: 6),
              Text(
                '$totalItems items',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teal),
              ),
              const Spacer(),
              Text(
                '$totalCal kcal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
              ),
            ],
          ),
        ),

        // ── Coach Tip from NL analysis (if review fields present) ──
        if (_hasNLReviewData(result))
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: _FoodReviewCard(
              review: search.FoodReview(
                encouragements: result.encouragements ?? [],
                warnings: result.warnings ?? [],
                aiSuggestion: result.aiSuggestion,
                recommendedSwap: result.recommendedSwap,
                healthScore: result.healthScore,
              ),
              isLoading: false,
              isDark: isDark,
            ),
          ),

        // ── Compact accordion list ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: totalItems + 2,
            itemBuilder: (context, index) {
              // "Log All" / "Log Remaining" button
              if (index == totalItems) {
                final anyLoading = _logStates.values.any((s) => s == _LogState.loading);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (allState == _LogState.loading || anyLoading)
                          ? null
                          : () => _logAllNLItems(result, allKey),
                      icon: allState == _LogState.loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : allState == _LogState.done
                              ? const Icon(Icons.check, size: 18)
                              : const Icon(Icons.playlist_add_check, size: 18),
                      label: Text(
                        buttonLabel,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allState == _LogState.done ? teal : orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: orange.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                );
              }

              // "Search instead" escape hatch
              if (index == totalItems + 1) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        final service = ref.read(search.foodSearchServiceProvider);
                        final cachedLogs = ref.read(nutritionProvider).recentLogs;
                        service.searchImmediate(widget.searchQuery, widget.userId, cachedLogs: cachedLogs);
                      },
                      child: Text(
                        'Looking for a specific product? Search instead',
                        style: TextStyle(
                          fontSize: 12,
                          color: teal,
                          decoration: TextDecoration.underline,
                          decorationColor: teal.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Food item sections (accordion with inline picker)
              final item = result.foodItems[index];
              final key = 'nl_$index';
              final logState = _logStates[key];
              final isExpanded = _expandedNLIndex == index;

              return _NLItemSection(
                key: _nlKey(index),
                item: item,
                isExpanded: isExpanded,
                logState: logState,
                onTap: () {
                  setState(() {
                    _expandedNLIndex = isExpanded ? -1 : index;
                  });
                },
                onLog: (description) => _logSingleNLItem(description, key),
                onStateChanged: () {
                  // Trigger banner rebuild when selection/qty/weight changes
                  setState(() {});
                },
                isDark: isDark,
                showHint: index == 0 && _expandedNLIndex == 0 && totalItems > 1,
                searchService: ref.read(search.foodSearchServiceProvider),
                userId: widget.userId,
                apiClient: ref.read(apiClientProvider),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Check if NL result has any review data to show
  bool _hasNLReviewData(search.FoodAnalysisResult result) {
    return (result.encouragements != null && result.encouragements!.isNotEmpty) ||
           (result.warnings != null && result.warnings!.isNotEmpty) ||
           (result.aiSuggestion != null && result.aiSuggestion!.isNotEmpty) ||
           (result.recommendedSwap != null && result.recommendedSwap!.isNotEmpty);
  }

  /// Log a single NL food item using the description from the section
  Future<void> _logSingleNLItem(String description, String key) async {
    setState(() => _logStates[key] = _LogState.loading);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: widget.mealType.value,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      if (!mounted) return;
      setState(() => _logStates[key] = _LogState.done);
      widget.onFoodLogged();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _logStates.remove(key));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// Log all NL food items using current state from each section
  Future<void> _logAllNLItems(search.FoodAnalysisResult result, String key) async {
    setState(() => _logStates[key] = _LogState.loading);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      // Build descriptions from current section states, skipping done items
      final descriptions = <String>[];
      for (int i = 0; i < result.foodItems.length; i++) {
        final itemKey = 'nl_$i';
        if (_logStates[itemKey] == _LogState.done) continue; // skip already logged
        final sectionState = _nlSectionKeys[i]?.currentState;
        if (sectionState != null) {
          descriptions.add(sectionState.buildDescription());
        } else {
          final item = result.foodItems[i];
          descriptions.add(item.amount != null ? '${item.amount} ${item.name}' : item.name);
        }
      }
      if (descriptions.isEmpty) return;
      await repo.logFoodFromText(
        userId: widget.userId,
        description: descriptions.join(', '),
        mealType: widget.mealType.value,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      if (!mounted) return;
      setState(() => _logStates[key] = _LogState.done);
      widget.onFoodLogged();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _logStates.remove(key));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'usda': return 'USDA';
      case 'usda_branded': return 'Branded';
      case 'cnf': return 'Canadian';
      case 'indb': return 'Indian';
      case 'openfoodfacts': return 'Open Food Facts';
      default: return source;
    }
  }

  List<Widget> _buildShimmerRows(int count) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    return List.generate(count, (i) => Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: elevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
    ));
  }
}

// ─── Log State ─────────────────────────────────────────────────

enum _LogState { loading, done }

// ─── Browse Filter Tabs ────────────────────────────────────────

class _BrowseFilterTabs extends StatelessWidget {
  final FoodBrowserFilter selected;
  final ValueChanged<FoodBrowserFilter> onChanged;
  final bool isDark;

  const _BrowseFilterTabs({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    Widget tab(FoodBrowserFilter filter, String label, IconData icon) {
      final isActive = selected == filter;
      return GestureDetector(
        onTap: () => onChanged(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? teal : elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? teal : cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          tab(FoodBrowserFilter.recent, 'Recent', Icons.schedule),
          const SizedBox(width: 8),
          tab(FoodBrowserFilter.saved, 'Saved', Icons.bookmark_outline),
          const SizedBox(width: 8),
          tab(FoodBrowserFilter.foodDb, 'Food DB', Icons.storage_outlined),
        ],
      ),
    );
  }
}

// ─── Source Dropdown Pill ──────────────────────────────────────

class _SourceDropdownPill extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _SourceDropdownPill({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  static const _sources = <(String?, String)>[
    (null, 'All Sources'),
    ('usda', 'USDA'),
    ('usda_branded', 'Branded'),
    ('cnf', 'Canadian'),
    ('indb', 'Indian'),
    ('openfoodfacts', 'Open Food Facts'),
  ];

  String get _selectedLabel =>
      _sources.firstWhere((s) => s.$1 == selected, orElse: () => _sources.first).$2;

  @override
  Widget build(BuildContext context) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final isFiltered = selected != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: PopupMenuButton<String?>(
        onSelected: onChanged,
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        position: PopupMenuPosition.under,
        itemBuilder: (_) => _sources.map((s) {
          final (value, label) = s;
          final isActive = selected == value;
          return PopupMenuItem<String?>(
            value: value,
            height: 40,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: isActive
                      ? Icon(Icons.check, size: 16, color: cyan)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? cyan : (isDark ? AppColors.textPrimary : AppColorsLight.textPrimary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isFiltered ? cyan : elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isFiltered ? cyan : cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 14, color: isFiltered ? Colors.white : textMuted),
              const SizedBox(width: 4),
              Text(
                _selectedLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFiltered ? Colors.white : textMuted,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 16, color: isFiltered ? Colors.white : textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────

class _BrowseSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final VoidCallback? onSeeAll;
  final bool isDark;

  const _BrowseSectionHeader({
    required this.icon,
    required this.title,
    this.count,
    this.onSeeAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textMuted),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: teal),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: teal),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── NL Item Section (Stateful Accordion with Inline Picker) ──

class _NLItemSection extends StatefulWidget {
  final search.NLFoodItem item;
  final bool isExpanded;
  final _LogState? logState;
  final VoidCallback onTap;
  final void Function(String description) onLog;
  final VoidCallback onStateChanged;
  final bool isDark;
  final bool showHint;
  final search.FoodSearchService searchService;
  final String userId;
  final ApiClient apiClient;

  const _NLItemSection({
    super.key,
    required this.item,
    required this.isExpanded,
    this.logState,
    required this.onTap,
    required this.onLog,
    required this.onStateChanged,
    required this.isDark,
    this.showHint = false,
    required this.searchService,
    required this.userId,
    required this.apiClient,
  });

  @override
  State<_NLItemSection> createState() => _NLItemSectionState();
}

class _ModifierState {
  double? weightG;
  int? count;
  bool enabled;
  String? selectedPhrase;

  _ModifierState({this.weightG, this.count, this.enabled = true, this.selectedPhrase});
}


class _NLItemSectionState extends State<_NLItemSection> {
  // Selection
  search.FoodSearchResult? _selectedAlt;
  List<search.FoodSearchResult> _alternatives = [];
  bool _altsLoading = false;
  String? _altsError;
  bool _altsFetched = false;

  // Qty / weight
  late int _qty;
  late double _weightG;
  late TextEditingController _qtyCtrl;
  late TextEditingController _weightCtrl;

  // Mini search
  late TextEditingController _searchCtrl;
  Timer? _searchDebounce;

  // Modifier controls
  final Map<String, _ModifierState> _modifierStates = {};
  late TextEditingController _modSearchCtrl;
  Timer? _modSearchDebounce;
  List<search.FoodModifier> _modSearchResults = [];
  bool _modSearchLoading = false;

  int _parseOriginalQty = 1;
  double? _originalPieceWeight;

  @override
  void initState() {
    super.initState();
    // Parse qty from amount string (e.g. "5×" or "5 pieces" or "2 cups")
    _parseOriginalQty = _parseQtyFromAmount(widget.item.amount);
    _qty = _parseOriginalQty;
    _weightG = widget.item.weightG ?? 100.0;
    _originalPieceWeight = _qty > 0 ? _weightG / _qty : null;

    _qtyCtrl = TextEditingController(text: _qty.toString());
    _weightCtrl = TextEditingController(text: _weightG.round().toString());
    _searchCtrl = TextEditingController();
    _modSearchCtrl = TextEditingController();
    // Initialize modifier states from item's detected modifiers
    for (final mod in widget.item.modifiers) {
      _initModifierState(mod);
    }
  }

  void _initModifierState(search.FoodModifier mod) {
    switch (mod.type) {
      case search.FoodModifierType.addon:
        final weight = mod.defaultWeightG;
        int? count;
        if (mod.weightPerUnitG != null && weight != null) {
          count = (weight / mod.weightPerUnitG!).round();
        }
        _modifierStates[mod.phrase] = _ModifierState(weightG: weight, count: count, enabled: true);
        break;
      case search.FoodModifierType.doneness:
      case search.FoodModifierType.cookingMethod:
      case search.FoodModifierType.sizePortion:
        _modifierStates[mod.phrase] = _ModifierState(selectedPhrase: mod.phrase, enabled: true);
        break;
      case search.FoodModifierType.removal:
        _modifierStates[mod.phrase] = _ModifierState(enabled: true);
        break;
      default:
        _modifierStates[mod.phrase] = _ModifierState(enabled: true);
    }
  }

  @override
  void didUpdateWidget(_NLItemSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-fetch alternatives on first expand
    if (widget.isExpanded && !oldWidget.isExpanded && !_altsFetched) {
      _fetchAlternatives(widget.item.name);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _weightCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _modSearchCtrl.dispose();
    _modSearchDebounce?.cancel();
    super.dispose();
  }

  int _parseQtyFromAmount(String? amount) {
    if (amount == null || amount.isEmpty) return 1;
    final match = RegExp(r'(\d+)').firstMatch(amount);
    if (match != null) {
      final n = int.tryParse(match.group(1)!);
      if (n != null && n > 0) return n;
    }
    return 1;
  }

  /// Calories: per-serving cal * weightG / servingWeight + modifier deltas
  int get displayCalories {
    int baseCal;
    if (_selectedAlt != null) {
      final altBaseWeight = _selectedAlt!.servingWeightG ?? _selectedAlt!.weightPerUnitG ?? 100.0;
      baseCal = (_selectedAlt!.calories * _weightG / altBaseWeight).round();
    } else {
      final origW = widget.item.weightG;
      if (origW != null && origW > 0) {
        final calPer100 = widget.item.calories / _parseOriginalQty / origW * 100;
        baseCal = (calPer100 * _weightG / 100).round();
      } else {
        baseCal = (widget.item.calories / _parseOriginalQty * _qty).round();
      }
    }
    // Add modifier deltas
    int modifierTotal = 0;
    for (final mod in widget.item.modifiers) {
      final state = _modifierStates[mod.phrase];
      if (state == null) continue;
      modifierTotal += _calcModifierCalDelta(mod, state);
    }
    // Also add any user-added modifiers not in original list
    for (final entry in _modifierStates.entries) {
      final isOriginal = widget.item.modifiers.any((m) => m.phrase == entry.key);
      if (!isOriginal) {
        final addedMod = _modSearchResults.where((m) => m.phrase == entry.key).firstOrNull;
        if (addedMod != null) {
          modifierTotal += _calcModifierCalDelta(addedMod, entry.value);
        }
      }
    }
    return baseCal + modifierTotal;
  }

  int _calcModifierCalDelta(search.FoodModifier mod, _ModifierState state) {
    if (!state.enabled) return 0;
    switch (mod.type) {
      case search.FoodModifierType.addon:
        if (mod.perGram != null && state.weightG != null) {
          return (mod.perGram!.calories * state.weightG!).round();
        }
        return mod.delta['calories']?.round() ?? 0;
      case search.FoodModifierType.doneness:
      case search.FoodModifierType.cookingMethod:
      case search.FoodModifierType.sizePortion:
        if (mod.groupOptions.isNotEmpty && state.selectedPhrase != null) {
          final opt = mod.groupOptions.where((o) => o.phrase == state.selectedPhrase).firstOrNull;
          if (opt != null) return opt.calDelta;
        }
        return mod.delta['calories']?.round() ?? 0;
      case search.FoodModifierType.removal:
        return state.enabled ? (mod.delta['calories']?.round() ?? 0) : 0;
      default:
        return 0;
    }
  }

  String get displayName => _selectedAlt?.name ?? widget.item.name;

  void _openFlagDialog() {
    showFoodReportDialog(
      context,
      apiClient: widget.apiClient,
      foodName: displayName,
      originalCalories: displayCalories,
      originalProtein: widget.item.proteinG,
      originalCarbs: widget.item.carbsG,
      originalFat: widget.item.fatG,
      dataSource: 'ai_analysis',
    );
  }

  String get _displayAmount {
    if (_qty > 1) return '$_qty×';
    return '';
  }

  String buildDescription() {
    final name = displayName;
    final modParts = <String>[];
    for (final mod in widget.item.modifiers) {
      final state = _modifierStates[mod.phrase];
      if (state == null) continue;
      if (mod.type == search.FoodModifierType.doneness ||
          mod.type == search.FoodModifierType.cookingMethod ||
          mod.type == search.FoodModifierType.sizePortion) {
        modParts.add(state.selectedPhrase ?? mod.phrase);
      } else if (mod.type == search.FoodModifierType.addon && state.enabled) {
        final w = state.weightG?.round() ?? mod.defaultWeightG?.round();
        modParts.add('${w}g ${mod.displayLabel ?? mod.phrase}');
      } else if (mod.type == search.FoodModifierType.removal && state.enabled) {
        modParts.add(mod.phrase);
      }
    }
    // Include user-added modifiers
    for (final entry in _modifierStates.entries) {
      final isOriginal = widget.item.modifiers.any((m) => m.phrase == entry.key);
      if (!isOriginal && entry.value.enabled) {
        final w = entry.value.weightG?.round();
        modParts.add(w != null ? '${w}g ${entry.key}' : entry.key);
      }
    }
    final modStr = modParts.isNotEmpty ? ' (${modParts.join(", ")})' : '';
    if (_qty > 1) return '$_qty x $name$modStr, ${_weightG.round()}g';
    return '$name$modStr, ${_weightG.round()}g';
  }

  Future<void> _fetchAlternatives(String query) async {
    setState(() {
      _altsLoading = true;
      _altsError = null;
    });
    try {
      final results = await widget.searchService.searchAlternatives(query, widget.userId);
      if (!mounted) return;
      setState(() {
        _alternatives = results;
        _altsLoading = false;
        _altsFetched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _altsLoading = false;
        _altsError = 'Couldn\'t load alternatives';
        _altsFetched = true;
      });
    }
  }

  void _onAltSelected(search.FoodSearchResult alt) {
    final oldPieceWeight = _selectedAlt?.weightPerUnitG ?? _originalPieceWeight;
    setState(() {
      _selectedAlt = alt;
      // Auto-adjust weight if piece weight differs
      if (alt.weightPerUnitG != null && alt.weightPerUnitG! > 0) {
        _weightG = _qty * alt.weightPerUnitG!;
        _weightCtrl.text = _weightG.round().toString();
      } else if (oldPieceWeight != null && oldPieceWeight > 0) {
        // Keep same total weight pattern
      }
    });
    widget.onStateChanged();
  }

  void _onOriginalSelected() {
    setState(() {
      _selectedAlt = null;
      // Restore original weight
      _weightG = widget.item.weightG ?? 100.0;
      _weightCtrl.text = _weightG.round().toString();
    });
    widget.onStateChanged();
  }

  void _onMiniSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      // Revert to original alternatives
      _fetchAlternatives(widget.item.name);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchAlternatives(query.trim());
    });
  }

  void _updateQty(int newQty) {
    if (newQty < 1 || newQty > 99) return;
    final pieceWeight = _selectedAlt?.weightPerUnitG ?? _originalPieceWeight;
    setState(() {
      _qty = newQty;
      _qtyCtrl.text = newQty.toString();
      // Auto-adjust total weight if we know piece weight
      if (pieceWeight != null && pieceWeight > 0) {
        _weightG = newQty * pieceWeight;
        _weightCtrl.text = _weightG.round().toString();
      }
    });
    widget.onStateChanged();
  }

  void _updateWeight(double newWeight) {
    if (newWeight < 1 || newWeight > 9999) return;
    setState(() {
      _weightG = newWeight;
      _weightCtrl.text = newWeight.round().toString();
    });
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final glassSurface = widget.isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: widget.isExpanded ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: widget.isExpanded ? elevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: widget.isExpanded
              ? Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row (always visible) ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_displayAmount.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(_displayAmount, style: TextStyle(color: textMuted, fontSize: 12)),
                ],
                const SizedBox(width: 10),
                Text(
                  '$displayCalories',
                  style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(' kcal', style: TextStyle(color: textMuted, fontSize: 11)),
                const SizedBox(width: 4),
                _FlagIconButton(
                  isDark: widget.isDark,
                  onTap: () => _openFlagDialog(),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 18, color: textMuted.withValues(alpha: 0.6)),
                ),
              ],
            ),

            // ── Divider for collapsed rows ──
            if (!widget.isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Divider(
                  height: 1, thickness: 0.5,
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                ),
              ),

            // ── Expanded section ──
            if (widget.isExpanded) ...[
              const SizedBox(height: 10),

              // Qty + Weight steppers
              Row(
                children: [
                  _buildStepper(
                    controller: _qtyCtrl,
                    label: 'qty',
                    onDecrease: () => _updateQty(_qty - 1),
                    onIncrease: () => _updateQty(_qty + 1),
                    onSubmitted: (v) {
                      final n = int.tryParse(v);
                      if (n != null) _updateQty(n);
                    },
                    fieldWidth: 36,
                    glassSurface: glassSurface,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 12),
                  _buildStepper(
                    controller: _weightCtrl,
                    label: 'g',
                    onDecrease: () => _updateWeight(_weightG - 10),
                    onIncrease: () => _updateWeight(_weightG + 10),
                    onSubmitted: (v) {
                      final n = double.tryParse(v);
                      if (n != null) _updateWeight(n);
                    },
                    fieldWidth: 46,
                    glassSurface: glassSurface,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const Spacer(),
                  // Log this item button
                  _buildLogButton(teal),
                ],
              ),

              const SizedBox(height: 10),

              // ── Modifier controls ──
              if (widget.item.modifiers.isNotEmpty || _modifierStates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildModifierSection(textPrimary, textMuted, teal, glassSurface, elevated),
                ),

              // ── Mini search bar ──
              GestureDetector(
                onTap: () {}, // absorb tap so it doesn't collapse
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search alternatives...',
                      hintStyle: TextStyle(fontSize: 13, color: textMuted.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onMiniSearch,
                    onTap: () {}, // prevent parent GestureDetector
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Alternatives list ──
              _buildAlternativesList(textPrimary, textMuted, teal, glassSurface),

              // Hint text
              if (widget.showHint) ...[
                const SizedBox(height: 6),
                Text(
                  'Tap items to adjust or pick alternatives',
                  style: TextStyle(fontSize: 11, color: textMuted.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativesList(Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    // Loading shimmer
    if (_altsLoading) {
      return Column(
        children: List.generate(3, (_) => Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: glassSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        )),
      );
    }

    // Error state
    if (_altsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: textMuted),
            const SizedBox(width: 6),
            Text(_altsError!, style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _fetchAlternatives(widget.item.name),
              child: Text('Retry', style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    // Build list: original item first as radio, then alternatives
    final hasAlts = _alternatives.isNotEmpty;
    final isOriginalSelected = _selectedAlt == null;

    return GestureDetector(
      onTap: () {}, // absorb taps so list doesn't collapse
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original parsed item (always shown as first radio option)
          _buildAltRow(
            name: widget.item.name,
            calPer100g: _getOriginalCalPer100g(),
            isSelected: isOriginalSelected,
            onTap: _onOriginalSelected,
            textPrimary: textPrimary,
            textMuted: textMuted,
            teal: teal,
          ),
          // Alternative items from search
          if (hasAlts)
            ...(_alternatives.take(6).map((alt) => _buildAltRow(
              name: alt.name,
              calPer100g: alt.calories,
              isSelected: _selectedAlt?.id == alt.id,
              onTap: () => _onAltSelected(alt),
              textPrimary: textPrimary,
              textMuted: textMuted,
              teal: teal,
              subtitle: alt.brand,
            )))
          else if (_altsFetched && !_altsLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Only match found',
                style: TextStyle(fontSize: 11, color: textMuted.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  int _getOriginalCalPer100g() {
    final w = widget.item.weightG;
    if (w != null && w > 0) {
      return (widget.item.calories / _parseOriginalQty / w * 100).round();
    }
    return widget.item.calories;
  }

  Widget _buildAltRow({
    required String name,
    required int calPer100g,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color teal,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected ? teal : textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? textPrimary : textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 10, color: textMuted.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$calPer100g cal/100g',
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({
    required TextEditingController controller,
    required String label,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required ValueChanged<String> onSubmitted,
    required double fieldWidth,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return GestureDetector(
      onTap: () {}, // absorb tap so it doesn't collapse
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrease,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.remove, size: 14, color: textMuted),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: fieldWidth,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                filled: true,
                fillColor: glassSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onIncrease,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.add, size: 14, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modifier section ──

  Widget _buildModifierSection(Color textPrimary, Color textMuted, Color teal, Color glassSurface, Color elevated) {
    // Backend-provided modifiers (excluding doneness/cooking from defaults)
    final backendModifiers = <search.FoodModifier>[...widget.item.modifiers];
    // Include user-added modifiers from search
    for (final entry in _modifierStates.entries) {
      final isOriginal = widget.item.modifiers.any((m) => m.phrase == entry.key);
      if (!isOriginal) {
        final addedMod = _modSearchResults.where((m) => m.phrase == entry.key).firstOrNull;
        if (addedMod != null) backendModifiers.add(addedMod);
      }
    }

    if (backendModifiers.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {}, // absorb tap
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backendModifiers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Modifiers', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
            // Backend-provided modifiers (addons, removals, doneness, cooking, etc.)
            ...backendModifiers.map((mod) => _buildModifierControl(mod, textPrimary, textMuted, teal, glassSurface)),
          ],
          const SizedBox(height: 8),
          // Modifier search bar
          SizedBox(
            height: 34,
            child: TextField(
              controller: _modSearchCtrl,
              style: TextStyle(fontSize: 12, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Add modifier...',
                hintStyle: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.add_circle_outline, size: 16, color: textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                filled: true,
                fillColor: glassSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onChanged: _onModifierSearch,
              onTap: () {},
            ),
          ),
          if (_modSearchLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: teal)),
            ),
          if (_modSearchResults.isNotEmpty && _modSearchCtrl.text.isNotEmpty)
            ..._modSearchResults.where((m) => !_modifierStates.containsKey(m.phrase)).take(6).map((mod) =>
              GestureDetector(
                onTap: () => _addModifierFromSearch(mod),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: teal),
                      const SizedBox(width: 6),
                      Expanded(child: Text(mod.displayLabel ?? mod.phrase.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '), style: TextStyle(fontSize: 12, color: textPrimary))),
                      Text('${(mod.delta['calories']?.round() ?? 0) >= 0 ? "+" : ""}${mod.delta['calories']?.round() ?? 0}', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
                      Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModifierControl(search.FoodModifier mod, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    final state = _modifierStates[mod.phrase];
    if (state == null) return const SizedBox.shrink();

    switch (mod.type) {
      case search.FoodModifierType.addon:
        return _buildAddonControl(mod, state, textPrimary, textMuted, teal, glassSurface);
      case search.FoodModifierType.doneness:
        return _buildDonenessControl(mod, state, textPrimary, textMuted, teal, glassSurface);
      case search.FoodModifierType.cookingMethod:
      case search.FoodModifierType.sizePortion:
        return _buildDropdownControl(mod, state, textPrimary, textMuted, teal, glassSurface);
      case search.FoodModifierType.removal:
        return _buildRemovalControl(mod, state, textPrimary, textMuted, teal);
      case search.FoodModifierType.qualityLabel:
      case search.FoodModifierType.stateTemp:
        return _buildInfoTag(mod, textMuted);
    }
  }

  Widget _buildAddonControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    final calDelta = _calcModifierCalDelta(mod, state);
    final label = mod.displayLabel ?? mod.phrase.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500))),
              Text('${calDelta >= 0 ? "+" : ""}$calDelta', style: TextStyle(fontSize: 11, color: calDelta >= 0 ? teal : Colors.orange, fontWeight: FontWeight.w600)),
              Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Weight stepper
              _buildMiniStepper(
                value: '${state.weightG?.round() ?? 0}',
                label: 'g',
                onDecrease: () {
                  final newW = (state.weightG ?? 0) - 5;
                  if (newW < 0) return;
                  setState(() {
                    state.weightG = newW;
                    if (mod.weightPerUnitG != null && mod.weightPerUnitG! > 0) {
                      state.count = (newW / mod.weightPerUnitG!).round();
                    }
                  });
                  widget.onStateChanged();
                },
                onIncrease: () {
                  setState(() {
                    state.weightG = (state.weightG ?? 0) + 5;
                    if (mod.weightPerUnitG != null && mod.weightPerUnitG! > 0) {
                      state.count = (state.weightG! / mod.weightPerUnitG!).round();
                    }
                  });
                  widget.onStateChanged();
                },
                glassSurface: glassSurface,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              // Count stepper (only for countable addons)
              if (mod.weightPerUnitG != null) ...[
                const SizedBox(width: 12),
                _buildMiniStepper(
                  value: '${state.count ?? 0}',
                  label: mod.unitName ?? 'pc',
                  onDecrease: () {
                    final newC = (state.count ?? 0) - 1;
                    if (newC < 0) return;
                    setState(() {
                      state.count = newC;
                      state.weightG = newC * (mod.weightPerUnitG ?? 0);
                    });
                    widget.onStateChanged();
                  },
                  onIncrease: () {
                    setState(() {
                      state.count = (state.count ?? 0) + 1;
                      state.weightG = state.count! * (mod.weightPerUnitG ?? 0);
                    });
                    widget.onStateChanged();
                  },
                  glassSurface: glassSurface,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonenessControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    if (mod.groupOptions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Doneness', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: mod.groupOptions.map((opt) {
              final isSelected = state.selectedPhrase == opt.phrase;
              return GestureDetector(
                onTap: () {
                  setState(() => state.selectedPhrase = opt.phrase);
                  widget.onStateChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? teal.withValues(alpha: 0.15) : glassSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? teal : Colors.transparent, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(opt.label, style: TextStyle(fontSize: 11, color: isSelected ? teal : textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                      Text('${opt.calDelta >= 0 ? "+" : ""}${opt.calDelta}', style: TextStyle(fontSize: 9, color: textMuted)),
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

  Widget _buildDropdownControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    if (mod.groupOptions.isEmpty) return const SizedBox.shrink();
    final calDelta = _calcModifierCalDelta(mod, state);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(mod.type == search.FoodModifierType.cookingMethod ? Icons.local_fire_department : Icons.straighten, size: 14, color: textMuted),
          const SizedBox(width: 4),
          Text(mod.type == search.FoodModifierType.cookingMethod ? 'Cooking' : 'Size', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(6)),
            child: DropdownButton<String>(
              value: state.selectedPhrase,
              underline: const SizedBox.shrink(),
              isDense: true,
              style: TextStyle(fontSize: 12, color: textPrimary),
              dropdownColor: glassSurface,
              items: mod.groupOptions.map((opt) => DropdownMenuItem(
                value: opt.phrase,
                child: Text('${opt.label} (${opt.calDelta >= 0 ? "+" : ""}${opt.calDelta})', style: TextStyle(fontSize: 12, color: textPrimary)),
              )).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => state.selectedPhrase = v);
                widget.onStateChanged();
              },
            ),
          ),
          const Spacer(),
          Text('${calDelta >= 0 ? "+" : ""}$calDelta', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
          Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildRemovalControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal) {
    final calDelta = state.enabled ? (mod.delta['calories']?.round() ?? 0) : 0;
    final label = mod.displayLabel ?? mod.phrase.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: Checkbox(
              value: state.enabled,
              onChanged: (v) {
                setState(() => state.enabled = v ?? false);
                widget.onStateChanged();
              },
              activeColor: teal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: textPrimary))),
          Text('$calDelta', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500)),
          Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildInfoTag(search.FoodModifier mod, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.label_outline, size: 14, color: textMuted.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(mod.displayLabel ?? mod.phrase, style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMiniStepper({
    required String value,
    required String label,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
            child: Icon(Icons.remove, size: 12, color: textMuted),
          ),
        ),
        const SizedBox(width: 3),
        Container(
          constraints: const BoxConstraints(minWidth: 30),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
          child: Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 10, color: textMuted)),
        const SizedBox(width: 3),
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
            child: Icon(Icons.add, size: 12, color: textMuted),
          ),
        ),
      ],
    );
  }

  void _onModifierSearch(String query) {
    _modSearchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _modSearchResults = [];
        _modSearchLoading = false;
      });
      return;
    }
    setState(() => _modSearchLoading = true);
    _modSearchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await widget.searchService.searchModifiers(query.trim(), widget.userId);
        if (!mounted) return;
        setState(() {
          _modSearchResults = results;
          _modSearchLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _modSearchLoading = false);
      }
    });
  }

  void _addModifierFromSearch(search.FoodModifier mod) {
    setState(() {
      _modifierStates[mod.phrase] = _ModifierState(
        weightG: mod.defaultWeightG,
        count: mod.weightPerUnitG != null && mod.defaultWeightG != null
            ? (mod.defaultWeightG! / mod.weightPerUnitG!).round()
            : null,
        enabled: true,
        selectedPhrase: mod.groupOptions.isNotEmpty ? mod.phrase : null,
      );
      _modSearchCtrl.clear();
    });
    widget.onStateChanged();
  }

  Widget _buildLogButton(Color teal) {
    if (widget.logState == _LogState.loading) {
      return SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: teal));
    }
    if (widget.logState == _LogState.done) {
      return Icon(Icons.check_circle, color: teal, size: 26);
    }
    return GestureDetector(
      onTap: () => widget.onLog(buildDescription()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: teal),
            const SizedBox(width: 2),
            Text('Log', style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Food Browser Item ─────────────────────────────────────────

class _FoodBrowserItem extends StatelessWidget {
  final String name;
  final int calories;
  final String? subtitle;
  final _LogState? logState;
  final VoidCallback onAdd;
  final bool isDark;

  const _FoodBrowserItem({
    required this.name,
    required this.calories,
    this.subtitle,
    this.logState,
    required this.onAdd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$calories',
            style: TextStyle(
              color: teal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' kcal',
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
          const SizedBox(width: 8),
          // Add button with loading/done states
          GestureDetector(
            onTap: logState == null ? onAdd : null,
            child: SizedBox(
              width: 28,
              height: 28,
              child: _buildAddButton(teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Color teal) {
    if (logState == _LogState.loading) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: teal),
        ),
      );
    }
    if (logState == _LogState.done) {
      return Icon(Icons.check_circle, color: Colors.green, size: 24);
    }
    return Icon(Icons.add_circle, color: teal, size: 24);
  }
}

// ─── Goal Tag Chip ─────────────────────────────────────────────

class _GoalTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _GoalTag({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Build goal tags based on user goals and food macros (per 100g).
List<_GoalTag> _buildGoalTags({
  required List<String> goals,
  required int calories,
  required double protein,
  required double carbs,
  required double fat,
  double? fiber,
  required bool isDark,
}) {
  if (goals.isEmpty) return [];
  final tags = <_GoalTag>[];
  final green = isDark ? AppColors.green : AppColorsLight.green;
  const orange = Color(0xFFF97316);

  final hasMuscleGoal = goals.any((g) => g.contains('build_muscle') || g.contains('gain_muscle'));
  final hasWeightLossGoal = goals.any((g) => g.contains('lose_weight') || g.contains('lose_fat'));

  if (hasMuscleGoal && protein > 20) {
    tags.add(_GoalTag(label: 'High protein', color: green, isDark: isDark));
  }
  if (hasWeightLossGoal && calories > 300) {
    tags.add(_GoalTag(label: 'Calorie-dense', color: orange, isDark: isDark));
  }
  if (hasWeightLossGoal && calories < 100) {
    tags.add(_GoalTag(label: 'Low cal', color: green, isDark: isDark));
  }
  if (fiber != null && fiber > 5) {
    tags.add(_GoalTag(label: 'High fiber', color: green, isDark: isDark));
  }
  if (fat > 30 && !hasMuscleGoal) {
    tags.add(_GoalTag(label: 'High fat', color: orange, isDark: isDark));
  }
  if (protein < 1 && carbs < 1 && fat > 90) {
    tags.add(_GoalTag(label: 'Pure fat', color: orange, isDark: isDark));
  }
  return tags;
}

// ─── AI Food Review Card (Coach Tip) ───────────────────────────

class _FoodReviewCard extends StatefulWidget {
  final search.FoodReview? review;
  final bool isLoading;
  final bool isDark;

  const _FoodReviewCard({
    required this.review,
    required this.isLoading,
    required this.isDark,
  });

  @override
  State<_FoodReviewCard> createState() => _FoodReviewCardState();
}

class _FoodReviewCardState extends State<_FoodReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading && widget.review == null) return const SizedBox.shrink();

    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // While loading, show compact loading header
    if (widget.isLoading) {
      return _buildCollapsedHeader(teal, textPrimary, textMuted, loading: true);
    }

    final r = widget.review!;
    final hasContent = r.encouragements.isNotEmpty ||
        r.warnings.isNotEmpty ||
        (r.aiSuggestion != null && r.aiSuggestion!.isNotEmpty) ||
        (r.recommendedSwap != null && r.recommendedSwap!.isNotEmpty);
    if (!hasContent) return const SizedBox.shrink();

    // Collapsed: just the header row (icon + "Coach Tip" + score + chevron)
    if (!_isExpanded) {
      return _buildCollapsedHeader(teal, textPrimary, textMuted);
    }

    // Expanded: full card
    final encourageColor = widget.isDark ? AppColors.green : AppColorsLight.green;
    final warningColor = widget.isDark ? AppColors.error : AppColorsLight.error;
    final swapColor = widget.isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.1),
            teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable header
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isExpanded = false),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.psychology, size: 16, color: teal),
                ),
                const SizedBox(width: 8),
                Text(
                  'Coach Tip',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                if (r.healthScore != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _scoreColor(r.healthScore!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${r.healthScore}/10',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _scoreColor(r.healthScore!),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(Icons.expand_less, size: 18, color: textMuted),
              ],
            ),
          ),

          // Encouragements
          if (r.encouragements.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...r.encouragements.take(2).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.thumb_up, size: 12, color: encourageColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(fontSize: 12, color: encourageColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Warnings
          if (r.warnings.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...r.warnings.take(2).map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, size: 12, color: warningColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      w,
                      style: TextStyle(fontSize: 12, color: warningColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],

          // AI suggestion
          if (r.aiSuggestion != null && r.aiSuggestion!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              r.aiSuggestion!,
              style: TextStyle(fontSize: 12, color: textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Recommended swap
          if (r.recommendedSwap != null && r.recommendedSwap!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: swapColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: swapColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: swapColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.recommendedSwap!,
                      style: TextStyle(fontSize: 11, color: swapColor, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedHeader(Color teal, Color textPrimary, Color textMuted, {bool loading = false}) {
    final r = widget.review;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teal.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.psychology, size: 16, color: teal),
            ),
            const SizedBox(width: 8),
            Text(
              'Coach Tip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            if (!loading && r?.healthScore != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _scoreColor(r!.healthScore!).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.healthScore}/10',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(r.healthScore!),
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (loading)
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: teal),
              )
            else
              Icon(Icons.expand_more, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 7) return widget.isDark ? AppColors.green : AppColorsLight.green;
    if (score >= 4) return const Color(0xFFF97316);
    return widget.isDark ? AppColors.error : AppColorsLight.error;
  }
}

// ─── Shared Flag Icon Button ─────────────────────────────────────────────────

class _FlagIconButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _FlagIconButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.flag_outlined,
          size: 14,
          color: textMuted.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ─── Expandable Search Result Card ───────────────────────────────

class _ExpandableSearchCard extends StatefulWidget {
  final search.FoodSearchResult result;
  final _LogState? logState;
  final bool isExpanded;
  final VoidCallback onTap;
  final void Function(String description) onLog;
  final bool isWeightEditable;
  final double baseWeightG;
  final bool isDark;
  final List<_GoalTag> goalTags;
  final ApiClient? apiClient;
  final search.FoodSearchService searchService;

  const _ExpandableSearchCard({
    required this.result,
    this.logState,
    required this.isExpanded,
    required this.onTap,
    required this.onLog,
    this.isWeightEditable = true,
    this.baseWeightG = 100.0,
    required this.isDark,
    this.goalTags = const [],
    this.apiClient,
    required this.searchService,
  });

  @override
  State<_ExpandableSearchCard> createState() => _ExpandableSearchCardState();
}

class _ExpandableSearchCardState extends State<_ExpandableSearchCard> {
  int _qty = 1;
  late double _weightG;
  late TextEditingController _qtyController;
  late TextEditingController _weightController;

  // Dynamic modifiers from backend
  List<search.FoodModifier> _modifiers = [];
  bool _modifiersLoading = false;
  bool _modifiersFetched = false;
  final Map<String, _ModifierState> _modifierStates = {};

  @override
  void initState() {
    super.initState();
    _weightG = widget.baseWeightG;
    _qtyController = TextEditingController(text: '1');
    _weightController = TextEditingController(text: _weightG.round().toString());
  }

  @override
  void didUpdateWidget(_ExpandableSearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fetch modifiers on first expand
    if (widget.isExpanded && !oldWidget.isExpanded && !_modifiersFetched) {
      _fetchModifiers();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _fetchModifiers() async {
    setState(() => _modifiersLoading = true);
    try {
      final mods = await widget.searchService.getFoodModifiers(widget.result.name);
      if (!mounted) return;
      setState(() {
        _modifiers = mods;
        _modifiersLoading = false;
        _modifiersFetched = true;
        for (final mod in mods) {
          _initModifierState(mod);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modifiersLoading = false;
        _modifiersFetched = true;
      });
    }
  }

  void _initModifierState(search.FoodModifier mod) {
    switch (mod.type) {
      case search.FoodModifierType.addon:
        final weight = mod.defaultWeightG;
        int? count;
        if (mod.weightPerUnitG != null && weight != null) {
          count = (weight / mod.weightPerUnitG!).round();
        }
        _modifierStates[mod.phrase] = _ModifierState(weightG: weight, count: count, enabled: true);
        break;
      case search.FoodModifierType.doneness:
      case search.FoodModifierType.cookingMethod:
      case search.FoodModifierType.sizePortion:
        _modifierStates[mod.phrase] = _ModifierState(selectedPhrase: mod.phrase, enabled: true);
        break;
      case search.FoodModifierType.removal:
        _modifierStates[mod.phrase] = _ModifierState(enabled: true);
        break;
      default:
        _modifierStates[mod.phrase] = _ModifierState(enabled: true);
    }
  }

  int get _displayCalories {
    int base;
    if (widget.isWeightEditable) {
      base = (widget.result.calories * _qty * (_weightG / widget.baseWeightG)).round();
    } else {
      base = widget.result.calories * _qty;
    }
    // Add modifier deltas
    int modDelta = 0;
    for (final mod in _modifiers) {
      final state = _modifierStates[mod.phrase];
      if (state == null || !state.enabled) continue;
      if (mod.type == search.FoodModifierType.doneness ||
          mod.type == search.FoodModifierType.cookingMethod ||
          mod.type == search.FoodModifierType.sizePortion) {
        if (mod.groupOptions.isNotEmpty && state.selectedPhrase != null) {
          final opt = mod.groupOptions.where((o) => o.phrase == state.selectedPhrase).firstOrNull;
          if (opt != null) modDelta += opt.calDelta;
        }
      } else if (mod.type == search.FoodModifierType.addon) {
        if (mod.perGram != null && state.weightG != null) {
          modDelta += (mod.perGram!.calories * state.weightG!).round();
        } else {
          modDelta += mod.delta['calories']?.round() ?? 0;
        }
      } else if (mod.type == search.FoodModifierType.removal) {
        modDelta += mod.delta['calories']?.round() ?? 0;
      }
    }
    return base + modDelta;
  }

  String get _description {
    final modParts = <String>[];
    for (final mod in _modifiers) {
      final state = _modifierStates[mod.phrase];
      if (state == null || !state.enabled) continue;
      if (mod.type == search.FoodModifierType.doneness ||
          mod.type == search.FoodModifierType.cookingMethod ||
          mod.type == search.FoodModifierType.sizePortion) {
        if (state.selectedPhrase != null && state.selectedPhrase != mod.phrase) {
          modParts.add(state.selectedPhrase!);
        }
      } else if (mod.type == search.FoodModifierType.addon) {
        final w = state.weightG?.round() ?? mod.defaultWeightG?.round();
        modParts.add('${w}g ${mod.displayLabel ?? mod.phrase}');
      } else if (mod.type == search.FoodModifierType.removal) {
        modParts.add(mod.phrase);
      }
    }
    final modStr = modParts.isNotEmpty ? ' (${modParts.join(", ")})' : '';
    if (widget.isWeightEditable) {
      if (_qty > 1) return '$_qty x ${widget.result.name}$modStr, ${_weightG.round()}g';
      return '${widget.result.name}$modStr, ${_weightG.round()}g';
    }
    if (_qty > 1) return '$_qty x ${widget.result.name}$modStr';
    return '${widget.result.name}$modStr';
  }

  void _updateQty(int newQty) {
    if (newQty < 1 || newQty > 99) return;
    setState(() {
      _qty = newQty;
      _qtyController.text = newQty.toString();
    });
  }

  void _updateWeight(double newWeight) {
    if (newWeight < 1 || newWeight > 5000) return;
    setState(() {
      _weightG = newWeight;
      _weightController.text = newWeight.round().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = widget.isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isExpanded
                ? teal.withValues(alpha: 0.3)
                : cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Collapsed row (always visible) ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.result.name,
                        style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.result.brand != null || widget.result.servingSize != null)
                        Text(
                          widget.result.brand ?? widget.result.servingSize ?? '',
                          style: TextStyle(color: textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.goalTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Wrap(spacing: 4, runSpacing: 2, children: widget.goalTags),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_displayCalories',
                  style: TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(' kcal', style: TextStyle(color: textMuted, fontSize: 11)),
                if (widget.apiClient != null) ...[
                  const SizedBox(width: 4),
                  _FlagIconButton(
                    isDark: widget.isDark,
                    onTap: () => showFoodReportDialog(
                      context,
                      apiClient: widget.apiClient!,
                      food: widget.result,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                // Add button (collapsed mode quick-add)
                if (!widget.isExpanded)
                  GestureDetector(
                    onTap: widget.logState == null ? () => widget.onLog(_description) : null,
                    child: SizedBox(
                      width: 28, height: 28,
                      child: _buildAddIcon(teal),
                    ),
                  ),
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 18, color: textMuted.withValues(alpha: 0.6)),
                ),
              ],
            ),

            // ── Expanded section ──
            if (widget.isExpanded) ...[
              const SizedBox(height: 10),
              // Qty + Weight steppers + Log button
              GestureDetector(
                onTap: () {}, // absorb tap so card doesn't collapse
                child: Row(
                  children: [
                    _buildStepper(
                      controller: _qtyController,
                      label: 'qty',
                      onDecrease: () => _updateQty(_qty - 1),
                      onIncrease: () => _updateQty(_qty + 1),
                      onSubmitted: (v) {
                        final n = int.tryParse(v);
                        if (n != null) _updateQty(n);
                      },
                      fieldWidth: 36,
                      glassSurface: glassSurface,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    if (widget.isWeightEditable) ...[
                      const SizedBox(width: 12),
                      _buildStepper(
                        controller: _weightController,
                        label: 'g',
                        onDecrease: () => _updateWeight(_weightG - 10),
                        onIncrease: () => _updateWeight(_weightG + 10),
                        onSubmitted: (v) {
                          final n = double.tryParse(v);
                          if (n != null) _updateWeight(n);
                        },
                        fieldWidth: 46,
                        glassSurface: glassSurface,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                    const Spacer(),
                    _buildLogButton(teal),
                  ],
                ),
              ),

              // Modifiers from backend
              if (_modifiersLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: teal)),
                      const SizedBox(width: 6),
                      Text('Loading modifiers...', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              if (_modifiers.isNotEmpty)
                GestureDetector(
                  onTap: () {}, // absorb tap
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildModifierControls(textPrimary, textMuted, teal, glassSurface),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModifierControls(Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modifiers', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        ..._modifiers.map((mod) {
          final state = _modifierStates[mod.phrase];
          if (state == null) return const SizedBox.shrink();

          // Doneness / cooking method / size: chip group
          if ((mod.type == search.FoodModifierType.doneness ||
               mod.type == search.FoodModifierType.cookingMethod ||
               mod.type == search.FoodModifierType.sizePortion) &&
              mod.groupOptions.isNotEmpty) {
            final label = mod.type == search.FoodModifierType.doneness ? 'Doneness' : 'Cooking';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: mod.groupOptions.map((opt) {
                      final isSelected = state.selectedPhrase == opt.phrase;
                      return GestureDetector(
                        onTap: () {
                          setState(() => state.selectedPhrase = opt.phrase);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? teal.withValues(alpha: 0.15) : glassSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSelected ? teal : Colors.transparent, width: 1),
                          ),
                          child: Text(
                            '${opt.label} (${opt.calDelta >= 0 ? "+" : ""}${opt.calDelta})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? teal : textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          // Addon
          if (mod.type == search.FoodModifierType.addon) {
            final calDelta = mod.perGram != null && state.weightG != null
                ? (mod.perGram!.calories * state.weightG!).round()
                : mod.delta['calories']?.round() ?? 0;
            final label = mod.displayLabel ?? mod.phrase;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500))),
                  Text('${calDelta >= 0 ? "+" : ""}$calDelta', style: TextStyle(fontSize: 11, color: calDelta >= 0 ? teal : Colors.orange, fontWeight: FontWeight.w600)),
                  Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted)),
                ],
              ),
            );
          }

          // Removal
          if (mod.type == search.FoodModifierType.removal) {
            final calDelta = state.enabled ? (mod.delta['calories']?.round() ?? 0) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: state.enabled,
                      onChanged: (v) => setState(() => state.enabled = v ?? false),
                      activeColor: teal,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(mod.displayLabel ?? mod.phrase, style: TextStyle(fontSize: 12, color: textPrimary))),
                  Text('$calDelta', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500)),
                  Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted)),
                ],
              ),
            );
          }

          // Info tag
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.label_outline, size: 14, color: textMuted.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(mod.displayLabel ?? mod.phrase, style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepper({
    required TextEditingController controller,
    required String label,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required ValueChanged<String> onSubmitted,
    required double fieldWidth,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
            child: Icon(Icons.remove, size: 14, color: textMuted),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              filled: true,
              fillColor: glassSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            ),
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 12, color: textMuted)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
            child: Icon(Icons.add, size: 14, color: textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildLogButton(Color teal) {
    if (widget.logState == _LogState.loading) {
      return SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: teal));
    }
    if (widget.logState == _LogState.done) {
      return Icon(Icons.check_circle, color: teal, size: 26);
    }
    return GestureDetector(
      onTap: () => widget.onLog(_description),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: teal),
            const SizedBox(width: 2),
            Text('Log', style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddIcon(Color teal) {
    if (widget.logState == _LogState.loading) {
      return Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: teal)));
    }
    if (widget.logState == _LogState.done) {
      return Icon(Icons.check_circle, color: Colors.green, size: 24);
    }
    return Icon(Icons.add_circle, color: teal, size: 24);
  }
}

// ─── Search Results PageView ──────────────────────────────────────

class _SearchResultsPageView extends StatefulWidget {
  final List<_FoodGroup> groups;
  final _SearchDisplayMode displayMode;
  final int currentPage;
  final String? expandedSearchKey;
  final Map<String, _LogState> logStates;
  final List<String> userGoals;
  final bool isDark;
  final String? selectedDbSource;
  final ValueChanged<int> onPageChanged;
  final void Function(String key) onExpandCard;
  final void Function(String desc, String key) onLogFood;
  final ApiClient apiClient;
  final search.FoodSearchService searchService;

  const _SearchResultsPageView({
    required this.groups,
    required this.displayMode,
    required this.currentPage,
    this.expandedSearchKey,
    required this.logStates,
    required this.userGoals,
    required this.isDark,
    this.selectedDbSource,
    required this.onPageChanged,
    required this.onExpandCard,
    required this.onLogFood,
    required this.apiClient,
    required this.searchService,
  });

  @override
  State<_SearchResultsPageView> createState() => _SearchResultsPageViewState();
}

class _SearchResultsPageViewState extends State<_SearchResultsPageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SearchResultsPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset page controller when groups change
    if (widget.groups.length != oldWidget.groups.length) {
      _pageController.dispose();
      _pageController = PageController(initialPage: 0);
      widget.onPageChanged(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return const SizedBox.shrink();

    switch (widget.displayMode) {
      case _SearchDisplayMode.pages:
        return _buildPageView();
      case _SearchDisplayMode.list:
        return _buildListView();
      case _SearchDisplayMode.carousel:
        return _buildCarouselView();
    }
  }

  Widget _buildPageView() {
    final isMultiPage = widget.groups.length > 1;
    return Column(
      children: [
        // Dot indicators for multi-page
        if (isMultiPage) ...[
          _PageDotIndicator(
            count: widget.groups.length,
            current: widget.currentPage,
            isDark: widget.isDark,
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.groups.length,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, pageIndex) {
              final group = widget.groups[pageIndex];
              return _buildGroupPage(group, pageIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupPage(_FoodGroup group, int pageIndex) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: group.results.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _BrowseSectionHeader(
              icon: Icons.restaurant_outlined,
              title: group.label.toUpperCase(),
              count: group.results.length,
              isDark: widget.isDark,
            ),
          );
        }
        final result = group.results[index - 1];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildListView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        for (int g = 0; g < widget.groups.length; g++) ...[
          if (g > 0) const SizedBox(height: 12),
          _BrowseSectionHeader(
            icon: widget.groups.length > 1 ? Icons.restaurant_outlined : Icons.storage_outlined,
            title: widget.groups[g].label.toUpperCase(),
            count: widget.groups[g].results.length,
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ...widget.groups[g].results.map((result) => _buildResultCard(result)),
        ],
      ],
    );
  }

  Widget _buildCarouselView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        for (int g = 0; g < widget.groups.length; g++) ...[
          if (g > 0) const SizedBox(height: 12),
          _BrowseSectionHeader(
            icon: Icons.restaurant_outlined,
            title: widget.groups[g].label.toUpperCase(),
            count: widget.groups[g].results.length,
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.groups[g].results.length,
              itemBuilder: (context, index) {
                final result = widget.groups[g].results[index];
                return _buildCarouselCard(result);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCarouselCard(search.FoodSearchResult result) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final key = 'search_db_${result.id}';

    return GestureDetector(
      onTap: () => widget.onExpandCard(key),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              result.name,
              style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${result.calories}', style: TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(' kcal', style: TextStyle(color: textMuted, fontSize: 10)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.logStates[key] == null
                      ? () => widget.onLogFood('${result.name}, ${(result.servingWeightG ?? result.weightPerUnitG ?? 100.0).round()}g', key)
                      : null,
                  child: SizedBox(
                    width: 22, height: 22,
                    child: _buildSmallAddIcon(teal, widget.logStates[key]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAddIcon(Color teal, _LogState? logState) {
    if (logState == _LogState.loading) {
      return Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: teal)));
    }
    if (logState == _LogState.done) {
      return Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    return Icon(Icons.add_circle, color: teal, size: 20);
  }

  Widget _buildResultCard(search.FoodSearchResult result) {
    final key = 'search_db_${result.id}';
    return _ExpandableSearchCard(
      result: result,
      logState: widget.logStates[key],
      isExpanded: widget.expandedSearchKey == key,
      onTap: () => widget.onExpandCard(key),
      onLog: (desc) => widget.onLogFood(desc, key),
      isWeightEditable: true,
      baseWeightG: result.servingWeightG ?? result.weightPerUnitG ?? 100.0,
      isDark: widget.isDark,
      goalTags: _buildGoalTags(
        goals: widget.userGoals,
        calories: result.calories,
        protein: result.protein ?? 0,
        carbs: result.carbs ?? 0,
        fat: result.fat ?? 0,
        isDark: widget.isDark,
      ),
      apiClient: widget.apiClient,
      searchService: widget.searchService,
    );
  }
}

// ─── Page Dot Indicator ────────────────────────────────────────────

class _PageDotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final bool isDark;

  const _PageDotIndicator({
    required this.count,
    required this.current,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? teal : textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Display Mode Toggle ──────────────────────────────────────────

class _DisplayModeToggle extends StatelessWidget {
  final _SearchDisplayMode mode;
  final ValueChanged<_SearchDisplayMode> onChanged;
  final bool isDark;

  const _DisplayModeToggle({
    required this.mode,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    Widget modeButton(_SearchDisplayMode m, IconData icon, String label) {
      final isActive = mode == m;
      return GestureDetector(
        onTap: () => onChanged(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? teal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          modeButton(_SearchDisplayMode.pages, Icons.view_carousel_outlined, 'Pages'),
          modeButton(_SearchDisplayMode.list, Icons.view_list_outlined, 'List'),
          modeButton(_SearchDisplayMode.carousel, Icons.view_column_outlined, 'Carousel'),
        ],
      ),
    );
  }
}
