import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/food_search_service.dart' as search;
import '../../../data/providers/xp_provider.dart';
import '../food_history_screen.dart';

/// Filter tabs for the food browser browse mode
enum FoodBrowserFilter { recent, saved, foodDb }

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

  @override
  void initState() {
    super.initState();
    _loadSavedFoods();
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

          // Group results: personal (saved + recent) and database
          final personalResults = [...state.saved, ...state.recent];
          final dbResults = [...state.database, ...state.foodDatabase];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
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
                  return _FoodBrowserItemEditable(
                    name: result.name,
                    baseCalories: result.calories,
                    subtitle: result.source.label,
                    logState: _logStates[key],
                    isWeightEditable: false,
                    onAdd: (desc) => _logFood(desc, key),
                    isDark: widget.isDark,
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (dbResults.isNotEmpty) ...[
                _BrowseSectionHeader(
                  icon: Icons.storage_outlined,
                  title: _selectedDbSource != null
                      ? 'FOOD DATABASE (${_sourceLabel(_selectedDbSource!)})'
                      : 'FOOD DATABASE',
                  count: dbResults.length,
                  isDark: widget.isDark,
                ),
                const SizedBox(height: 6),
                ...dbResults.map((result) {
                  final key = 'search_db_${result.id}';
                  return _FoodBrowserItemEditable(
                    name: result.name,
                    baseCalories: result.calories,
                    subtitle: result.brand ?? result.servingSize,
                    logState: _logStates[key],
                    isWeightEditable: true,
                    baseWeightG: 100.0,
                    onAdd: (desc) => _logFood(desc, key),
                    isDark: widget.isDark,
                  );
                }),
              ],
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

// ─── Editable Food Browser Item (Search Mode) ─────────────────

class _FoodBrowserItemEditable extends StatefulWidget {
  final String name;
  final int baseCalories;
  final String? subtitle;
  final _LogState? logState;
  final bool isWeightEditable;
  final double baseWeightG;
  final void Function(String description) onAdd;
  final bool isDark;

  const _FoodBrowserItemEditable({
    required this.name,
    required this.baseCalories,
    this.subtitle,
    this.logState,
    this.isWeightEditable = false,
    this.baseWeightG = 100.0,
    required this.onAdd,
    required this.isDark,
  });

  @override
  State<_FoodBrowserItemEditable> createState() => _FoodBrowserItemEditableState();
}

class _FoodBrowserItemEditableState extends State<_FoodBrowserItemEditable> {
  int _qty = 1;
  late double _weightG;
  late TextEditingController _qtyController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightG = widget.baseWeightG;
    _qtyController = TextEditingController(text: '1');
    _weightController = TextEditingController(text: _weightG.round().toString());
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  int get _displayCalories {
    if (widget.isWeightEditable) {
      return (widget.baseCalories * _qty * (_weightG / widget.baseWeightG)).round();
    }
    return widget.baseCalories * _qty;
  }

  String get _description {
    if (widget.isWeightEditable) {
      if (_qty > 1) return '$_qty x ${widget.name}, ${_weightG.round()}g';
      return '${widget.name}, ${_weightG.round()}g';
    }
    if (_qty > 1) return '$_qty x ${widget.name}';
    return widget.name;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, calories, add button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(color: textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.logState == null ? () => widget.onAdd(_description) : null,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: _buildAddButton(teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Qty stepper + optional weight stepper
          Row(
            children: [
              // Qty stepper
              _buildStepper(
                controller: _qtyController,
                label: 'qty',
                value: _qty.toDouble(),
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
              // Weight stepper (food DB only)
              if (widget.isWeightEditable) ...[
                const SizedBox(width: 12),
                _buildStepper(
                  controller: _weightController,
                  label: 'g',
                  value: _weightG,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required TextEditingController controller,
    required String label,
    required double value,
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
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: BorderRadius.circular(4),
            ),
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
            style: TextStyle(
              fontSize: 13,
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              filled: true,
              fillColor: glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
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
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.add, size: 14, color: textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(Color teal) {
    if (widget.logState == _LogState.loading) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: teal),
        ),
      );
    }
    if (widget.logState == _LogState.done) {
      return Icon(Icons.check_circle, color: Colors.green, size: 24);
    }
    return Icon(Icons.add_circle, color: teal, size: 24);
  }
}
