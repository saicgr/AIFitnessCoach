/// Full-screen glassmorphic sheet for analyzing menus, buffets, and large
/// plate scans. v2 redesign — sections, filters, multi-sort, search,
/// circular budget rings, recommended picks, allergen warnings,
/// portion stepper, menu photo strip, elapsed time, and bookmark-to-
/// history. See plan at
/// /Users/saichetangrandhe/.claude/plans/i-love-menu-analysis-ticklish-scroll.md
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/allergen.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/sort_spec.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../services/menu_recommendation_service.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/menu_analysis/macro_budget_ring.dart';
import 'widgets/menu_analysis/menu_analysis_item_card.dart';
import 'widgets/menu_analysis/menu_filter_sheet.dart';
import 'widgets/menu_analysis/menu_filter_state.dart';
import 'widgets/menu_analysis/recommendation_explain_sheet.dart';

/// Streaming controller retained from v1 so existing callers don't break.
class MenuAnalysisStreamingController extends ChangeNotifier {
  int _currentPage;
  int _totalPages;
  bool _done = false;
  final List<int> _failedPages = [];
  final List<Map<String, dynamic>> _pendingItems = [];

  MenuAnalysisStreamingController({required int totalPages, int currentPage = 1})
      : _totalPages = totalPages,
        _currentPage = currentPage;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isDone => _done;
  List<int> get failedPages => List.unmodifiable(_failedPages);

  List<Map<String, dynamic>> consumePending() {
    final copy = List<Map<String, dynamic>>.from(_pendingItems);
    _pendingItems.clear();
    return copy;
  }

  void appendItems(List<Map<String, dynamic>> items, {int? page, int? totalPages}) {
    _pendingItems.addAll(items);
    if (page != null) _currentPage = page;
    if (totalPages != null) _totalPages = totalPages;
    notifyListeners();
  }

  void markPageError(int page) {
    _failedPages.add(page);
    notifyListeners();
  }

  void markDone() {
    _done = true;
    notifyListeners();
  }
}

class MenuAnalysisSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> foodItems;
  final String analysisType;
  final bool isDark;
  final void Function(List<Map<String, dynamic>>) onLogItems;
  final MenuAnalysisStreamingController? streamingController;

  /// URLs of the menu pages Gemini actually parsed. Rendered as a photo
  /// strip in the header so the user can verify the AI saw the right
  /// images.
  final List<String> menuPhotoUrls;

  /// Gemini elapsed time in seconds — shown as a subtle counts-line
  /// entry ("23 items · 6 sections · 1.8s"). Falls back to null when
  /// not available (older invocations).
  final double? elapsedSeconds;

  /// Optional restaurant name Gemini surfaced — helps when saving to
  /// history as "Indian place near work".
  final String? restaurantName;

  const MenuAnalysisSheet({
    super.key,
    required this.foodItems,
    required this.analysisType,
    required this.isDark,
    required this.onLogItems,
    this.streamingController,
    this.menuPhotoUrls = const [],
    this.elapsedSeconds,
    this.restaurantName,
  });

  /// Preserve the v1 call pattern — used by log-meal + chat flows.
  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> foodItems,
    required String analysisType,
    required bool isDark,
    required void Function(List<Map<String, dynamic>>) onLogItems,
    MenuAnalysisStreamingController? streamingController,
    List<String> menuPhotoUrls = const [],
    double? elapsedSeconds,
    String? restaurantName,
  }) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => MenuAnalysisSheet(
        foodItems: foodItems,
        analysisType: analysisType,
        isDark: isDark,
        onLogItems: onLogItems,
        streamingController: streamingController,
        menuPhotoUrls: menuPhotoUrls,
        elapsedSeconds: elapsedSeconds,
        restaurantName: restaurantName,
      ),
    );
  }

  @override
  ConsumerState<MenuAnalysisSheet> createState() => _MenuAnalysisSheetState();
}

class _MenuAnalysisSheetState extends ConsumerState<MenuAnalysisSheet> {
  late List<MenuItem> _items;
  final Set<String> _selected = {};
  SortSpecList _sort = SortSpecList.empty;
  MenuFilterState _filter = MenuFilterState.empty;
  RecommendationResult? _recommendation;
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showRecommended = true;
  final Map<String, bool> _sectionExpanded = {};
  bool _logged = false;
  bool _bookmarking = false;

  @override
  void initState() {
    super.initState();
    _items = _itemsFromMaps(widget.foodItems);
    // Default: hide dishes matching the user's allergens if any are set.
    // Resolved after first build via addPostFrameCallback because we need
    // `ref`.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAllergenDefault());
    widget.streamingController?.addListener(_onStreamingUpdate);
    _refreshRecommendation();
  }

  @override
  void dispose() {
    widget.streamingController?.removeListener(_onStreamingUpdate);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _initAllergenDefault() {
    if (!mounted) return;
    final state = ref.read(nutritionPreferencesProvider);
    final prefs = state.preferences;
    final hasAllergens = prefs != null &&
        (prefs.allergies.isNotEmpty || prefs.customAllergens.isNotEmpty);
    if (hasAllergens && !_filter.hideAllergenDishes) {
      setState(() => _filter = _filter.copyWith(hideAllergenDishes: true));
    }
  }

  List<MenuItem> _itemsFromMaps(List<Map<String, dynamic>> raw) {
    final photoFallback =
        widget.menuPhotoUrls.isNotEmpty ? widget.menuPhotoUrls.first : null;
    return [
      for (int i = 0; i < raw.length; i++)
        MenuItem.fromJson(raw[i], id: 'item_$i', fallbackImageUrl: photoFallback),
    ];
  }

  void _onStreamingUpdate() {
    final controller = widget.streamingController;
    if (controller == null || !mounted) return;
    final pending = controller.consumePending();
    if (pending.isNotEmpty) {
      final more = [
        for (int i = 0; i < pending.length; i++)
          MenuItem.fromJson(
            pending[i],
            id: 'item_${_items.length + i}',
            fallbackImageUrl: widget.menuPhotoUrls.isNotEmpty ? widget.menuPhotoUrls.first : null,
          ),
      ];
      setState(() => _items = [..._items, ...more]);
      _refreshRecommendation();
    } else {
      setState(() {});
    }
  }

  // ───────────────────────── recommendation ─────────────────────────

  Future<void> _refreshRecommendation() async {
    // Local scoring only in this pass; pre-fetched ChromaDB semantic
    // matches stay an empty list if the pre-fetch endpoint hasn't run.
    // Pipeline handles empty gracefully.
    if (!mounted) return;
    final state = ref.read(nutritionPreferencesProvider);
    final prefs = state.preferences;
    final summary = ref.read(nutritionProvider).todaySummary;

    final ctx = RecommendationContext(
      calorieTarget: state.currentCalorieTarget.toDouble(),
      proteinTarget: state.currentProteinTarget.toDouble(),
      carbsTarget: state.currentCarbsTarget.toDouble(),
      fatTarget: state.currentFatTarget.toDouble(),
      consumedCalories: (summary?.totalCalories ?? 0).toDouble(),
      consumedProteinG: (summary?.totalProteinG ?? 0).toDouble(),
      consumedCarbsG: (summary?.totalCarbsG ?? 0).toDouble(),
      consumedFatG: (summary?.totalFatG ?? 0).toDouble(),
      dietaryRestrictions: prefs?.dietaryRestrictions ?? const [],
      dislikedFoods: prefs?.dislikedFoods ?? const [],
      allergenProfile: UserAllergenProfile(
        allergens: Allergen.parseAll(prefs?.allergies ?? const []),
        customAllergens: prefs?.customAllergens ?? const [],
      ),
      inflammationSensitivity: prefs?.inflammationSensitivity ?? 3,
      mealBudgetUsd: prefs?.mealBudgetUsd,
      todayItemNames: summary?.meals
              .expand((m) => m.foodItems.map((f) => f.name))
              .toList() ??
          const [],
      coldStart: (summary?.meals.length ?? 0) < 5,
    );

    final result = const MenuRecommendationService().recommend(
      items: _items,
      context: ctx,
      topK: 3,
    );
    if (mounted) setState(() => _recommendation = result);
  }

  // ───────────────────────── filtered + sorted ─────────────────────────

  List<MenuItem> get _filteredItems {
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    final profile = UserAllergenProfile(
      allergens: Allergen.parseAll(prefs?.allergies ?? const []),
      customAllergens: prefs?.customAllergens ?? const [],
    );
    var filtered = _items.where((i) => _filter.accepts(i, profile: profile)).toList();
    if (_sort.isEmpty) return filtered;
    filtered.sort(_sort.comparator<MenuItem>((item, field) => item.sortValue(field)));
    return filtered;
  }

  /// Items grouped by section (for non-filtered/non-searched state).
  Map<String, List<MenuItem>> get _itemsBySection {
    final grouped = <String, List<MenuItem>>{};
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }
    final sorted = <String, List<MenuItem>>{};
    for (final key in kCanonicalSectionOrder) {
      if (grouped.containsKey(key)) sorted[key] = grouped[key]!;
    }
    return sorted;
  }

  bool get _showFlatList =>
      _filter.hasAnyFilter || _sort.length > 0;

  // ───────────────────────── totals ─────────────────────────

  _Totals get _selectedTotals {
    double cal = 0, p = 0, c = 0, f = 0, price = 0;
    bool anyPrice = false;
    for (final item in _items) {
      if (!_selected.contains(item.id)) continue;
      cal += item.scaledCalories;
      p += item.scaledProteinG;
      c += item.scaledCarbsG;
      f += item.scaledFatG;
      if (item.price != null) {
        price += item.price!;
        anyPrice = true;
      }
    }
    return _Totals(cal: cal, protein: p, carbs: c, fat: f, price: anyPrice ? price : null);
  }

  // ───────────────────────── actions ─────────────────────────

  void _toggleItem(MenuItem item, bool? selected) {
    setState(() {
      if (selected ?? !_selected.contains(item.id)) {
        _selected.add(item.id);
      } else {
        _selected.remove(item.id);
      }
    });
  }

  void _updatePortion(MenuItem item, double multiplier) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx >= 0) _items[idx] = _items[idx].copyWith(portionMultiplier: multiplier);
    });
  }

  void _toggleSort(SortField field) {
    HapticFeedback.selectionClick();
    setState(() => _sort = _sort.tap(field));
  }

  Future<void> _longPressSort(SortField field) async {
    HapticFeedback.mediumImpact();
    setState(() => _sort = _sort.addTiebreaker(field));
  }

  Future<void> _openFilterSheet() async {
    HapticFeedback.lightImpact();
    final result = await MenuFilterSheet.show(
      context,
      initial: _filter,
      allItems: _items,
      resultCount: _filteredItems.length,
    );
    if (result != null) setState(() => _filter = result);
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _filter = _filter.copyWith(searchQuery: v));
    });
  }

  void _handleLog() {
    if (_logged || _selected.isEmpty) return;
    final payload = <Map<String, dynamic>>[];
    for (final item in _items) {
      if (!_selected.contains(item.id)) continue;
      payload.add({
        'name': item.name,
        'calories': item.scaledCalories.round(),
        'protein_g': double.parse(item.scaledProteinG.toStringAsFixed(1)),
        'carbs_g': double.parse(item.scaledCarbsG.toStringAsFixed(1)),
        'fat_g': double.parse(item.scaledFatG.toStringAsFixed(1)),
        if (item.portionMultiplier != 1.0) 'portion_multiplier': item.portionMultiplier,
        if (item.amount != null) 'amount': item.amount,
      });
    }
    widget.onLogItems(payload);
    setState(() => _logged = true);
  }

  Future<void> _bookmarkAnalysis() async {
    if (_bookmarking) return;
    final controller = TextEditingController(text: widget.restaurantName ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save this menu'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(hintText: 'e.g. Indian place near work'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (title == null || !mounted) return;

    setState(() => _bookmarking = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/nutrition/menu-analyses', data: {
        'title': title.isEmpty ? null : title,
        'restaurant_name': widget.restaurantName,
        'analysis_type': widget.analysisType,
        'sections': <Map<String, dynamic>>[],
        'food_items': widget.foodItems,
        'menu_photo_urls': widget.menuPhotoUrls,
        'elapsed_seconds': widget.elapsedSeconds,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved to your menu history'),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Couldn\'t save: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _bookmarking = false);
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return GlassSheet(
      maxHeightFraction: 0.95,
      child: Column(
        children: [
          _header(colors),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _budgetRings(colors),
                if (widget.menuPhotoUrls.isNotEmpty) _photoStrip(),
                _countsLine(colors),
                _searchAndControls(colors),
                if (_filter.hasAnyFilter) _activeFilterChips(),
                if (_recommendation != null &&
                    _recommendation!.picks.isNotEmpty &&
                    !_showFlatList)
                  _recommendedSection(colors),
                const SizedBox(height: 6),
                if (_showFlatList)
                  _flatList(colors)
                else
                  ..._itemsBySection.entries.map((e) => _sectionBlock(e.key, e.value, colors)),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _bottomBar(colors),
        ],
      ),
    );
  }

  Widget _header(ThemeColors colors) {
    final title = switch (widget.analysisType) {
      'menu' => 'Menu Analysis',
      'buffet' => 'Buffet Analysis',
      _ => 'Food Analysis',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Save menu',
            icon: _bookmarking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.bookmark_add_outlined, color: colors.textSecondary),
            onPressed: _bookmarkAnalysis,
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _budgetRings(ThemeColors colors) {
    final state = ref.watch(nutritionPreferencesProvider);
    final summary = ref.watch(nutritionProvider).todaySummary;
    final totals = _selectedTotals;
    final consumedCal = (summary?.totalCalories ?? 0) + totals.cal;
    final consumedP = (summary?.totalProteinG ?? 0) + totals.protein;
    final consumedC = (summary?.totalCarbsG ?? 0) + totals.carbs;
    final consumedF = (summary?.totalFatG ?? 0) + totals.fat;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MacroBudgetRing(
            label: 'Cal',
            consumed: consumedCal.toDouble(),
            target: state.currentCalorieTarget.toDouble(),
            color: AppColors.coral,
          ),
          MacroBudgetRing(
            label: 'Protein',
            consumed: consumedP,
            target: state.currentProteinTarget.toDouble(),
            color: AppColors.macroProtein,
            unit: 'g',
          ),
          MacroBudgetRing(
            label: 'Carbs',
            consumed: consumedC,
            target: state.currentCarbsTarget.toDouble(),
            color: AppColors.macroCarbs,
            unit: 'g',
          ),
          MacroBudgetRing(
            label: 'Fat',
            consumed: consumedF,
            target: state.currentFatTarget.toDouble(),
            color: AppColors.macroFat,
            unit: 'g',
          ),
        ],
      ),
    );
  }

  Widget _photoStrip() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.menuPhotoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(widget.menuPhotoUrls[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.menuPhotoUrls[i],
                width: 52, height: 52, fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 52, height: 52, color: Colors.black26),
                errorWidget: (_, __, ___) => Container(
                  width: 52, height: 52, color: Colors.black26,
                  child: const Icon(Icons.broken_image_outlined, size: 18, color: Colors.white54),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPhotoViewer(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _countsLine(ThemeColors colors) {
    final sectionCount = _items.map((i) => i.section).toSet().length;
    final elapsed = widget.elapsedSeconds == null
        ? ''
        : ' · ${widget.elapsedSeconds!.toStringAsFixed(1)}s';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '${_items.length} items · $sectionCount section${sectionCount == 1 ? '' : 's'}$elapsed',
        style: TextStyle(fontSize: 11, color: colors.textMuted),
      ),
    );
  }

  Widget _searchAndControls(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _searchOpen
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'Search dishes…',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _searchOpen = false;
                              _searchController.clear();
                              _filter = _filter.copyWith(searchQuery: '');
                            }),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : InkWell(
                        onTap: () => setState(() => _searchOpen = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 18, color: colors.textMuted),
                              const SizedBox(width: 6),
                              Text('Search dishes', style: TextStyle(fontSize: 13, color: colors.textMuted)),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _openFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.tune, size: 20, color: AppColors.orange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Sort:', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                const SizedBox(width: 6),
                for (final field in SortField.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _sortPill(field, colors),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortPill(SortField field, ThemeColors colors) {
    final index = _sort.indexOf(field);
    final isActive = index >= 0;
    final dir = _sort.directionOf(field);
    return GestureDetector(
      onTap: () => _toggleSort(field),
      onLongPress: () => _longPressSort(field),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.orange.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: AppColors.orange.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive && _sort.length > 1) ...[
              Container(
                width: 14, height: 14, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text('${index + 1}', style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white,
                )),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              field.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.orange : colors.textSecondary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 2),
              Icon(
                dir == SortDirection.asc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12, color: AppColors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _activeFilterChips() {
    final chips = <_ActiveChip>[];
    for (final r in _filter.healthRatings) {
      chips.add(_ActiveChip('Health: $r', () => setState(() {
        final next = {..._filter.healthRatings}..remove(r);
        _filter = _filter.copyWith(healthRatings: next);
      })));
    }
    for (final b in _filter.inflammationBuckets) {
      chips.add(_ActiveChip('$b inflam.', () => setState(() {
        final next = {..._filter.inflammationBuckets}..remove(b);
        _filter = _filter.copyWith(inflammationBuckets: next);
      })));
    }
    if (_filter.minProteinG != null) {
      chips.add(_ActiveChip('P > ${_filter.minProteinG!.round()}g',
          () => setState(() => _filter = _filter.copyWith(clearMinProteinG: true))));
    }
    if (_filter.maxCarbsG != null) {
      chips.add(_ActiveChip('C < ${_filter.maxCarbsG!.round()}g',
          () => setState(() => _filter = _filter.copyWith(clearMaxCarbsG: true))));
    }
    if (_filter.maxFatG != null) {
      chips.add(_ActiveChip('F < ${_filter.maxFatG!.round()}g',
          () => setState(() => _filter = _filter.copyWith(clearMaxFatG: true))));
    }
    if (_filter.maxCalories != null) {
      chips.add(_ActiveChip('Cal < ${_filter.maxCalories!.round()}',
          () => setState(() => _filter = _filter.copyWith(clearMaxCalories: true))));
    }
    if (_filter.maxPriceUsd != null) {
      chips.add(_ActiveChip('\$ < ${_filter.maxPriceUsd!.toStringAsFixed(0)}',
          () => setState(() => _filter = _filter.copyWith(clearMaxPriceUsd: true))));
    }
    if (_filter.hideAllergenDishes) {
      chips.add(_ActiveChip('No allergens',
          () => setState(() => _filter = _filter.copyWith(hideAllergenDishes: false))));
    }
    for (final s in _filter.sections) {
      chips.add(_ActiveChip(displaySectionName(s), () => setState(() {
        final next = {..._filter.sections}..remove(s);
        _filter = _filter.copyWith(sections: next);
      })));
    }
    if (_filter.searchQuery.isNotEmpty) {
      chips.add(_ActiveChip('"${_filter.searchQuery}"', () {
        _searchController.clear();
        setState(() => _filter = _filter.copyWith(searchQuery: ''));
      }));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final c in chips)
            InputChip(
              label: Text(c.label, style: const TextStyle(fontSize: 11)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: c.onRemove,
              visualDensity: VisualDensity.compact,
            ),
          ActionChip(
            label: const Text('Clear all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            onPressed: () => setState(() => _filter = MenuFilterState.empty),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _recommendedSection(ThemeColors colors) {
    final rec = _recommendation!;
    return _collapsibleSection(
      title: 'Recommended for you',
      icon: Icons.auto_awesome,
      titleColor: AppColors.orange,
      subtitleCount: rec.picks.length,
      expanded: _showRecommended,
      onToggle: () => setState(() => _showRecommended = !_showRecommended),
      children: [
        for (int i = 0; i < rec.picks.length; i++) _recommendedCard(rec.picks[i], i + 1, rec.picks.length),
      ],
      colors: colors,
    );
  }

  Widget _recommendedCard(RecommendedItem pick, int rank, int total) {
    return Stack(
      children: [
        MenuAnalysisItemCard(
          item: pick.item,
          isSelected: _selected.contains(pick.item.id),
          allergenProfile: _allergenProfile(),
          onToggle: (v) => _toggleItem(pick.item, v),
          onPortionChanged: (m) => _updatePortion(pick.item, m),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#$rank', style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white,
                )),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => RecommendationExplainSheet.show(
                    context, pick: pick, rank: rank, totalAccepted: total,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.question_mark, size: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  UserAllergenProfile _allergenProfile() {
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    return UserAllergenProfile(
      allergens: Allergen.parseAll(prefs?.allergies ?? const []),
      customAllergens: prefs?.customAllergens ?? const [],
    );
  }

  Widget _sectionBlock(String section, List<MenuItem> items, ThemeColors colors) {
    final expanded = _sectionExpanded[section] ?? true;
    return _collapsibleSection(
      title: displaySectionName(section),
      icon: null,
      subtitleCount: items.length,
      expanded: expanded,
      onToggle: () => setState(() => _sectionExpanded[section] = !expanded),
      children: [
        for (final item in items)
          MenuAnalysisItemCard(
            item: item,
            isSelected: _selected.contains(item.id),
            allergenProfile: _allergenProfile(),
            onToggle: (v) => _toggleItem(item, v),
            onPortionChanged: (m) => _updatePortion(item, m),
          ),
      ],
      colors: colors,
    );
  }

  Widget _flatList(ThemeColors colors) {
    final items = _filteredItems;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text(
          'No dishes match your filters',
          style: TextStyle(color: colors.textMuted),
        )),
      );
    }
    return _collapsibleSection(
      title: 'Results',
      icon: null,
      subtitleCount: items.length,
      expanded: true,
      onToggle: () {},
      children: [
        for (final item in items)
          MenuAnalysisItemCard(
            item: item,
            isSelected: _selected.contains(item.id),
            allergenProfile: _allergenProfile(),
            onToggle: (v) => _toggleItem(item, v),
            onPortionChanged: (m) => _updatePortion(item, m),
          ),
      ],
      colors: colors,
    );
  }

  Widget _collapsibleSection({
    required String title,
    required IconData? icon,
    Color? titleColor,
    required int subtitleCount,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
    required ThemeColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: titleColor ?? colors.textSecondary),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: titleColor ?? colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: (titleColor ?? colors.textMuted).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subtitleCount.toString(),
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: titleColor ?? colors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: expanded ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_up, size: 20, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Column(children: children)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _bottomBar(ThemeColors colors) {
    final totals = _selectedTotals;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '${_selected.length} selected',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${totals.cal.round()} cal  ${totals.protein.toStringAsFixed(0)}g P  '
                  '${totals.carbs.toStringAsFixed(0)}g C  ${totals.fat.toStringAsFixed(0)}g F'
                  '${totals.price != null ? '  ·  \$${totals.price!.toStringAsFixed(2)}' : ''}',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(_logged ? Icons.check : Icons.add_circle_outline),
                label: Text(_logged
                    ? 'Logged'
                    : 'Log ${_selected.length} item${_selected.length == 1 ? '' : 's'}'),
                onPressed: (_selected.isEmpty || _logged) ? null : _handleLog,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals {
  final double cal;
  final double protein;
  final double carbs;
  final double fat;
  final double? price;
  const _Totals({
    required this.cal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.price,
  });
}

class _ActiveChip {
  final String label;
  final VoidCallback onRemove;
  _ActiveChip(this.label, this.onRemove);
}
