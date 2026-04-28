import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/food_search_service.dart' as search;
import '../../../data/services/last_used_service.dart';
import '../../../widgets/common/last_used_badge.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/constants/country_codes.dart';
import '../food_history_screen.dart';
import 'companion_picker_sheet.dart';
import 'food_report_dialog.dart';
import 'food_source_indicator.dart';
import '../../../data/models/companion_suggestion.dart';


part 'food_browser_panel_part_food_browser_filter.dart';
part 'food_browser_panel_part_search_display_mode.dart';
part 'food_browser_panel_part_food_browser_item.dart';
part 'food_browser_panel_part_expandable_search_card_state.dart';
part 'food_browser_panel_part_display_mode_toggle.dart';
part 'food_browser_panel_part_n_l_item_section_state.dart';

part 'food_browser_panel_ui.dart';
part 'food_browser_panel_part_n_l_item_section_state_ext.dart';


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
  final DateTime? selectedDate;

  const FoodBrowserPanel({
    super.key,
    required this.userId,
    required this.mealType,
    required this.isDark,
    required this.searchQuery,
    required this.filter,
    required this.onFilterChanged,
    required this.onFoodLogged,
    this.selectedDate,
  });

  @override
  ConsumerState<FoodBrowserPanel> createState() => _FoodBrowserPanelState();
}

class _FoodBrowserPanelState extends ConsumerState<FoodBrowserPanel> {
  /// Returns YYYY-MM-DD string if a non-today date is selected, null otherwise
  String? get _targetDateString {
    final d = widget.selectedDate;
    if (d == null) return null;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return null;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // Saved foods data
  List<SavedFood> _savedFoods = [];
  bool _savedFoodsLoading = true;
  int _savedOffset = 0;
  bool _savedHasMore = true;
  static const _savedPageSize = 20;

  // Source filter for Food DB tab and search mode
  String? _selectedDbSource;

  // Country filter (ISO alpha-2) for food database search
  String? _selectedCountry;

  // Per-item logging state: food name -> logging/done
  final Map<String, _LogState> _logStates = {};

  // Expanded item index for NL accordion (-1 = none, 0 = first auto-expanded)
  int _expandedNLIndex = 0;

  // Search result display state
  PageController? _searchPageController;
  int _currentSearchPage = 0;
  _SearchDisplayMode _displayMode = _SearchDisplayMode.pages;
  String? _expandedSearchKey; // key of expanded search card (only one at a time)

  // Multi-select state for search results
  final Set<String> _selectedSearchKeys = {};
  final Map<String, search.FoodSearchResult> _selectedSearchResults = {};


  @override
  void initState() {
    super.initState();
    _loadSavedFoods();
    _loadDefaultCountry();
  }

  Future<void> _loadDefaultCountry() async {
    final defaultCountry = await search.FoodSearchService.getDefaultCountry();
    if (defaultCountry != null && mounted) {
      setState(() => _selectedCountry = defaultCountry);
      final service = ref.read(search.foodSearchServiceProvider);
      service.setCountry(defaultCountry);
    }
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
      final response = await repo.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: widget.mealType.value,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      ref.read(nutritionProvider.notifier).spliceLog(response, widget.mealType.value, widget.userId);
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
      final response = await repo.relogSavedFood(
        userId: widget.userId,
        savedFoodId: food.id,
        mealType: widget.mealType.value,
        date: _targetDateString,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      ref.read(nutritionProvider.notifier).spliceLog(response, widget.mealType.value, widget.userId);
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

  // Companion-aware re-log (Fix 2 decision tree).
  //
  //   tap(food_log)
  //   ├── same food logged <30 min ago?     → silent log, skip sheet
  //   ├── log has >1 food_items (group)     → open sheet in "pick from group" mode
  //   └── log has 1 food_item (solo)
  //         ├── /nutrition/companions returns empty → silent log, skip sheet
  //         └── otherwise → open sheet in "add sides?" mode
  //
  // Per [feedback_no_silent_fallbacks]: if the backend companions call fails
  // entirely, fall back to logging the primary silently rather than showing
  // a broken sheet. Per [feedback_no_silent_fallbacks]: never re-add
  // companions the user didn't tick.
  static const Duration _relogDedupWindow = Duration(minutes: 30);
  final Map<String, DateTime> _recentRelogTimestamps = <String, DateTime>{};

  Future<void> _relogFoodLog(FoodLog log) async {
    final key = 'recent_${log.id}';
    setState(() => _logStates[key] = _LogState.loading);

    final primaryName = log.foodItems.isNotEmpty
        ? log.foodItems.first.name
        : log.mealType;

    // 30-min dedup: if the user just logged this same food, the sheet is
    // almost always noise. Log silently and move on.
    final dedupKey = primaryName.toLowerCase();
    final lastTap = _recentRelogTimestamps[dedupKey];
    final now = DateTime.now();
    if (lastTap != null && now.difference(lastTap) < _relogDedupWindow) {
      _recentRelogTimestamps[dedupKey] = now;
      await _logLegacyCopy(log, key);
      return;
    }
    _recentRelogTimestamps[dedupKey] = now;

    try {
      final repo = ref.read(nutritionRepositoryProvider);

      // Build the sheet's inputs based on the source log's shape.
      final siblings = log.foodItems.length > 1
          ? log.foodItems.skip(1).toList()
          : const <FoodItem>[];

      // Only call the companions endpoint for solo logs — multi-item logs
      // already surface siblings via same-log history, and asking for more
      // on every re-log would double the Gemini spend.
      final companions = siblings.isEmpty
          ? await repo.fetchCompanions(
              userId: widget.userId,
              primaryFoodName: primaryName,
              mealType: widget.mealType.value,
            )
          : const <CompanionSuggestion>[];

      // Silent-log path: nothing else to offer.
      if (siblings.isEmpty && companions.isEmpty) {
        await _logLegacyCopy(log, key);
        return;
      }

      if (!mounted) return;
      setState(() => _logStates.remove(key));

      final result = await showModalBottomSheet<CompanionPickerResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CompanionPickerSheet(
          primaryName: primaryName,
          primaryCalories: log.totalCalories,
          primaryImageUrl: log.imageUrl,
          primarySourceType: log.sourceType,
          primaryItem: log.foodItems.isNotEmpty ? log.foodItems.first : null,
          sameLogSiblings: siblings,
          companions: companions,
        ),
      );

      if (result == null) return; // user dismissed — no log

      await _logFromPickerResult(log, result, key);

      // Teach the resolver about any globally-suggested items the user
      // unchecked, so we stop suggesting them next time. Fire-and-forget.
      for (final rejected in result.rejectedCompanions) {
        // ignore: discarded_futures
        repo.rejectCompanion(
          userId: widget.userId,
          primaryFoodName: primaryName,
          companionName: rejected.name,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Fallback / silent-log path — clones the source log as-is via the
  /// existing backend endpoint. Preserves every food_item from the source.
  Future<void> _logLegacyCopy(FoodLog log, String stateKey) async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.copyFoodLog(
        logId: log.id,
        mealType: widget.mealType.value,
        date: _targetDateString,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      // Source log has all nutrition data already — splice a copy immediately
      final now = DateTime.now();
      ref.read(nutritionProvider.notifier).spliceRawLog(
        FoodLog(
          id: 'optimistic_${now.millisecondsSinceEpoch}',
          userId: widget.userId,
          mealType: widget.mealType.value,
          loggedAt: now,
          foodItems: log.foodItems,
          totalCalories: log.totalCalories,
          proteinG: log.proteinG,
          carbsG: log.carbsG,
          fatG: log.fatG,
          fiberG: log.fiberG,
          imageUrl: log.imageUrl,
          sourceType: log.sourceType,
          userQuery: log.userQuery,
          createdAt: now,
        ),
        widget.userId,
      );
      if (!mounted) return;
      setState(() => _logStates[stateKey] = _LogState.done);
      widget.onFoodLogged();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _logStates.remove(stateKey));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(stateKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Compose a log payload from the primary + user-selected siblings and
  /// companion suggestions, then push it via the existing /log-direct path
  /// so item-level edits + image URLs stay consistent with the image-log
  /// flow (Fix 1).
  Future<void> _logFromPickerResult(
    FoodLog source,
    CompanionPickerResult result,
    String stateKey,
  ) async {
    setState(() => _logStates[stateKey] = _LogState.loading);
    try {
      final repo = ref.read(nutritionRepositoryProvider);

      // Primary item — keep as the first entry.
      final primary = source.foodItems.isNotEmpty
          ? source.foodItems.first
          : null;
      final items = <Map<String, dynamic>>[
        if (primary != null) primary.toJson(),
        for (final sib in result.historicItems) sib.toJson(),
        for (final c in result.newCompanions) c.toLogItem(),
      ];

      int totalCal = source.totalCalories ~/
          (source.foodItems.isEmpty ? 1 : source.foodItems.length);
      // More accurate: sum per-item calories from what we're actually logging.
      totalCal = items.fold<int>(
        0,
        (sum, it) => sum + ((it['calories'] as num?)?.toInt() ?? 0),
      );
      final totalP = items.fold<double>(
        0,
        (s, it) => s + ((it['protein_g'] as num?)?.toDouble() ?? 0),
      );
      final totalC = items.fold<double>(
        0,
        (s, it) => s + ((it['carbs_g'] as num?)?.toDouble() ?? 0),
      );
      final totalF = items.fold<double>(
        0,
        (s, it) => s + ((it['fat_g'] as num?)?.toDouble() ?? 0),
      );

      final response = await repo.logAdjustedFood(
        userId: widget.userId,
        mealType: widget.mealType.value,
        foodItems: items,
        totalCalories: totalCal,
        totalProtein: totalP.round(),
        totalCarbs: totalC.round(),
        totalFat: totalF.round(),
        sourceType: 'recent',
        imageUrl: source.imageUrl,
      );

      ref.read(xpProvider.notifier).markMealLogged();
      ref.read(nutritionProvider.notifier).spliceLog(response, widget.mealType.value, widget.userId);
      if (!mounted) return;
      setState(() => _logStates[stateKey] = _LogState.done);
      widget.onFoodLogged();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _logStates.remove(stateKey));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStates.remove(stateKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _logSelectedItems() {
    for (final entry in _selectedSearchResults.entries) {
      final key = entry.key;
      final result = entry.value;
      final weightG = (result.servingWeightG ?? result.weightPerUnitG ?? 100.0).round();
      _logFood('${result.name}, ${weightG}g', key);
    }
    setState(() {
      _selectedSearchKeys.clear();
      _selectedSearchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = widget.searchQuery.trim().isNotEmpty;

    if (isSearching) {
      return _buildSearchMode();
    }
    return _buildBrowseMode();
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
        // Filter row: source + country
        Row(
          children: [
            _SourceDropdownPill(
              selected: _selectedDbSource,
              onChanged: (source) {
                setState(() => _selectedDbSource = source);
                final service = ref.read(search.foodSearchServiceProvider);
                service.setSource(source);
                if (widget.searchQuery.trim().isNotEmpty) {
                  final cachedLogs = ref.read(nutritionProvider).recentLogs;
                  service.search(widget.searchQuery, widget.userId, cachedLogs: cachedLogs);
                }
              },
              isDark: widget.isDark,
            ),
            const SizedBox(width: 8),
            _CountrySearchPill(
              selected: _selectedCountry,
              onChanged: (code) {
                setState(() => _selectedCountry = code);
                final service = ref.read(search.foodSearchServiceProvider);
                service.setCountry(code);
                if (widget.searchQuery.trim().isNotEmpty) {
                  final cachedLogs = ref.read(nutritionProvider).recentLogs;
                  service.search(widget.searchQuery, widget.userId, cachedLogs: cachedLogs);
                }
              },
              isDark: widget.isDark,
            ),
          ],
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
                          isSelected: _selectedSearchKeys.contains(key),
                          onToggleSelect: () => setState(() {
                            if (_selectedSearchKeys.contains(key)) {
                              _selectedSearchKeys.remove(key);
                              _selectedSearchResults.remove(key);
                            } else {
                              _selectedSearchKeys.add(key);
                              _selectedSearchResults[key] = result;
                            }
                          }),
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
                  selectedKeys: _selectedSearchKeys,
                  onToggleSelect: (key, result) => setState(() {
                    if (_selectedSearchKeys.contains(key)) {
                      _selectedSearchKeys.remove(key);
                      _selectedSearchResults.remove(key);
                    } else {
                      _selectedSearchKeys.add(key);
                      _selectedSearchResults[key] = result;
                    }
                  }),
                ),
              ),
              // Display mode toggle (only for multi-group)
              if (isMultiGroup)
                _DisplayModeToggle(
                  mode: _displayMode,
                  onChanged: (mode) => setState(() => _displayMode = mode),
                  isDark: widget.isDark,
                ),
              // "Log Selected" button when items are selected
              if (_selectedSearchKeys.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logSelectedItems,
                      icon: const Icon(Icons.playlist_add_check, size: 18),
                      label: Text(
                        'Log Selected (${_selectedSearchKeys.length} items)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
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
      final response = await repo.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: widget.mealType.value,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      ref.read(nutritionProvider.notifier).spliceLog(response, widget.mealType.value, widget.userId);
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
      final response = await repo.logFoodFromText(
        userId: widget.userId,
        description: descriptions.join(', '),
        mealType: widget.mealType.value,
      );
      ref.read(xpProvider.notifier).markMealLogged();
      ref.read(nutritionProvider.notifier).spliceLog(response, widget.mealType.value, widget.userId);
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
