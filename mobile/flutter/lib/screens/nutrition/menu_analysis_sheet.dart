/// Full-screen glassmorphic sheet for analyzing menus, buffets, and large
/// plate scans. v2 redesign — sections, filters, multi-sort, search,
/// circular budget rings, recommended picks, allergen warnings,
/// portion stepper, menu photo strip, elapsed time, and bookmark-to-
/// history. See plan at
/// /Users/saichetangrandhe/.claude/plans/i-love-menu-analysis-ticklish-scroll.md
library;

import 'dart:async';
import 'dart:ui';

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
import 'widgets/menu_analysis/diet_heuristics.dart';
import 'widgets/menu_analysis/menu_filter_sheet.dart';
import 'widgets/menu_analysis/menu_filter_state.dart';
import 'widgets/menu_analysis/sort_options_sheet.dart';
import '../../widgets/tooltips/tooltips.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showRecommended = true;
  final Map<String, bool> _sectionExpanded = {};
  bool _logged = false;
  bool _bookmarking = false;

  // Spotlight targets for the first-run tip tour. The tour rings each
  // anchored widget so the (otherwise unfamiliar) Menu Analysis controls
  // — quick sort pills, filter button, recommended block, and the
  // multi-select footer — are introduced one tap at a time.
  // Spotlight target keys for `menu_analysis_v1` now live in
  // `widgets/tooltips/tooltip_anchors.dart`. Local getters kept so the
  // existing `key: _xKey` wiring inside the sheet body stays readable.
  GlobalKey get _sortRowKey => TooltipAnchors.menuAnalysisSortRow;
  GlobalKey get _filterButtonKey => TooltipAnchors.menuAnalysisFilter;
  GlobalKey get _recommendedKey => TooltipAnchors.menuAnalysisRecommended;
  GlobalKey get _selectFooterKey => TooltipAnchors.menuAnalysisSelectFooter;

  // Persisted per-user sort preference. Reload on open so the user doesn't
  // have to redo "Protein high → Carbs low" every time they scan a menu.
  static const _sortPrefsKey = 'menu_analysis_sort_v1';

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
    _loadPersistedSort();
  }

  Future<void> _loadPersistedSort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sortPrefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final specs = <SortSpec>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final fieldName = entry['field'];
        final dirName = entry['direction'];
        if (fieldName is! String || dirName is! String) continue;
        final field = SortField.values
            .where((f) => f.name == fieldName)
            .firstOrNull;
        final direction = SortDirection.values
            .where((d) => d.name == dirName)
            .firstOrNull;
        if (field == null || direction == null) continue;
        specs.add(SortSpec(field, direction));
        if (specs.length >= kMaxSortDepth) break;
      }
      if (!mounted || specs.isEmpty) return;
      setState(() => _sort = SortSpecList(specs));
    } catch (_) {
      // Persistence is best-effort — never block the menu render.
    }
  }

  Future<void> _persistSort(SortSpecList sort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (sort.isEmpty) {
        await prefs.remove(_sortPrefsKey);
        return;
      }
      final encoded = jsonEncode([
        for (final s in sort.specs)
          {'field': s.field.name, 'direction': s.direction.name}
      ]);
      await prefs.setString(_sortPrefsKey, encoded);
    } catch (_) {
      // ignore — see _loadPersistedSort
    }
  }

  /// Single source of truth for sort mutations. Keeps state + persistence
  /// in sync so the user's choice survives sheet close + restaurant scan.
  void _setSort(SortSpecList next) {
    setState(() => _sort = next);
    _persistSort(next);
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

  /// When the filter result is empty, look for the most likely cause and
  /// return a one-line hint. Common culprit: the user picked a "What are
  /// you in the mood for?" preset (Gut-friendly, Blood-sugar friendly,
  /// Anti-inflammatory, Whole foods) but Gemini didn't tag the menu with
  /// the relevant field, so every dish gets dropped. Returning the
  /// missing-signal hint stops users from blaming the filter itself.
  String? _diagnoseEmptyResult() {
    if (_items.isEmpty) return null;
    final presets = _filter.smartPresets;
    if (presets.isEmpty) return null;
    bool hasAny(bool Function(MenuItem) test) => _items.any(test);

    if (presets.contains('gut_friendly') &&
        !hasAny((i) => i.fodmapRating != null)) {
      return 'Gemini didn’t tag this menu with FODMAP data, so the Gut-friendly filter has nothing to keep.';
    }
    if (presets.contains('blood_sugar') &&
        !hasAny((i) => i.glycemicLoad != null)) {
      return 'No glycemic-load data on this menu — the Blood-sugar filter can’t identify safe picks.';
    }
    if (presets.contains('anti_inflammatory') &&
        !hasAny((i) => i.inflammationScore != null)) {
      return 'No inflammation scoring on this menu yet — try removing the Anti-inflammatory filter.';
    }
    if (presets.contains('clean') &&
        !hasAny((i) => i.isUltraProcessed != null)) {
      return 'No ultra-processed labeling on this menu — the Whole foods filter can’t tell.';
    }
    return null;
  }

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

  /// Switch to a single flat "Results" list whenever the user is narrowing
  /// OR re-ranking the menu — so sort applies across the whole menu instead
  /// of within sections. Users expect "Sort by Protein" to surface the
  /// highest-protein dish at the top regardless of whether it's a Main or
  /// a Side; the prior section-bound behaviour buried it under the section
  /// header. Recommended stays anchored above this list.
  bool get _showFlatList => _filter.hasAnyFilter || !_sort.isEmpty;

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
      // Every health-condition score that Gemini computed for this dish must
      // ride along into food_logs — otherwise the user logs the meal and
      // loses the inflammation / diabetes / FODMAP context they just saw.
      // See migration 1908 (inflammation) + 1977 (diabetes + FODMAP).
      payload.add({
        'name': item.name,
        'calories': item.scaledCalories.round(),
        'protein_g': double.parse(item.scaledProteinG.toStringAsFixed(1)),
        'carbs_g': double.parse(item.scaledCarbsG.toStringAsFixed(1)),
        'fat_g': double.parse(item.scaledFatG.toStringAsFixed(1)),
        if (item.fiberG != null) 'fiber_g': double.parse((item.fiberG! * item.portionMultiplier).toStringAsFixed(1)),
        if (item.weightG != null) 'weight_g': item.scaledWeightG!.round(),
        if (item.portionMultiplier != 1.0) 'portion_multiplier': item.portionMultiplier,
        if (item.amount != null) 'amount': item.amount,
        if (item.inflammationScore != null) 'inflammation_score': item.inflammationScore,
        if (item.isUltraProcessed != null) 'is_ultra_processed': item.isUltraProcessed,
        if (item.glycemicLoad != null) 'glycemic_load': item.glycemicLoad,
        if (item.fodmapRating != null) 'fodmap_rating': item.fodmapRating,
        if (item.fodmapReason != null) 'fodmap_reason': item.fodmapReason,
        if (item.rating != null) 'rating': item.rating,
        if (item.ratingReason != null) 'rating_reason': item.ratingReason,
        if (item.coachTip != null) 'coach_tip': item.coachTip,
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

  // ───────────────────────── glass tint helpers ─────────────────────────

  /// Theme-aware semi-transparent overlay tint. In light mode the base is
  /// black so glass overlays read as a subtle darken against the bright
  /// backdrop; in dark mode the base is white so they read as a lift.
  /// Replaces hard-coded `Colors.white.withValues(alpha:)` overlay calls.
  Color _glassTint(BuildContext context, double alpha) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return (isLight ? Colors.black : Colors.white).withValues(alpha: alpha);
  }

  /// Theme-aware border tint counterpart for [_glassTint] — used for hairline
  /// strokes around glass cards. Same flip rule as the fill helper.
  Color _glassBorder(BuildContext context, double alpha) =>
      _glassTint(context, alpha);

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return GlassSheet(
      // Match the food log sheet proportions — leaves room for the Dynamic
      // Island / notch on top while keeping a tall working surface. The
      // drag handle and glass blur are preserved at this height.
      maxHeightFraction: 0.92,
      child: Stack(
        children: [
          Column(
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
                      ..._itemsBySection.entries.map(
                          (e) => _sectionBlock(e.key, e.value, colors)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              _bottomBar(colors),
            ],
          ),
          // First-run spotlight tour. Anchors + copy live in
          // `widgets/tooltips/tours/menu_analysis_tour.dart`.
          MenuAnalysisTour.overlay(),
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

    // Inner BackdropFilter so the glassmorphism reads even when the outer
    // GlassSheet's blur is partially obscured by content. ClipRRect is
    // required for the blur to honour the rounded corners.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _glassTint(context, 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _glassBorder(context, 0.10),
                width: 0.5,
              ),
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
          ),
        ),
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
                // Always-on search field — the filter pipeline is wired
                // through `_filter.searchQuery`, so leaving it dormant
                // behind a tap-to-open button just made the bar feel idle.
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: _onSearchChanged,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'Search dishes',
                    hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                    prefixIcon: Icon(Icons.search, size: 18, color: colors.textMuted),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close, size: 18, color: colors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filter = _filter.copyWith(searchQuery: ''));
                            },
                          ),
                    filled: true,
                    fillColor: _glassTint(context, 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _glassBorder(context, 0.10), width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.orange.withValues(alpha: 0.55), width: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              KeyedSubtree(
                key: _filterButtonKey,
                child: Material(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _openFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.tune,
                          size: 20, color: AppColors.orange),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Quick-sort pills + "More…" entry point. Pills cover the four
          // dimensions that drive almost every sort the user actually
          // wants on a menu (Protein high, Carbs low, Fat low, least
          // Inflammation); everything else stays one tap away in the
          // full sort sheet. Tapping the same pill cycles direction
          // (default → reversed → off) via SortSpecList.tap.
          KeyedSubtree(
            key: _sortRowKey,
            child: _quickSortRow(colors),
          ),
        ],
      ),
    );
  }

  /// Horizontal-scrolling row of quick-sort pills. Each pill applies a
  /// single-field sort via [SortSpecList.tap]; that helper cycles
  /// off → default → reversed → off so the user can disable a sort with
  /// repeat taps. The right-most "More…" pill opens the full sheet for
  /// multi-sort + every other dimension (Calories, Health, Blood sugar,
  /// Added sugar, Ultra-processed, Price, Weight).
  Widget _quickSortRow(ThemeColors colors) {
    const quickFields = [
      SortField.protein,
      SortField.carbs,
      SortField.fat,
      SortField.inflammation,
    ];
    final extraCount = _sort.specs
        .where((s) => !quickFields.contains(s.field))
        .length;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Leading "Sort:" label so the pills read as a sort affordance
          // rather than a generic chip filter row.
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded,
                      size: 16, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Sort:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final field in quickFields) ...[
            _quickSortPill(field, colors),
            const SizedBox(width: 8),
          ],
          _moreSortPill(colors, extraCount: extraCount),
        ],
      ),
    );
  }

  Widget _quickSortPill(SortField field, ThemeColors colors) {
    final direction = _sort.directionOf(field);
    final isPrimary = _sort.specs.isNotEmpty && _sort.specs.first.field == field;
    final active = direction != null;
    final IconData? arrow = direction == null
        ? null
        : (direction == SortDirection.asc
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);
    return Material(
      color: active
          ? AppColors.orange.withValues(alpha: 0.15)
          : _glassTint(context, 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _setSort(_sort.tap(field));
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(
                    color: AppColors.orange.withValues(
                        alpha: isPrimary ? 0.55 : 0.3),
                    width: isPrimary ? 1.2 : 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                field.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? AppColors.orange : colors.textSecondary,
                ),
              ),
              if (arrow != null) ...[
                const SizedBox(width: 4),
                Icon(arrow, size: 12, color: AppColors.orange),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreSortPill(ThemeColors colors, {required int extraCount}) {
    final highlighted = extraCount > 0;
    return Material(
      color: highlighted
          ? AppColors.orange.withValues(alpha: 0.15)
          : _glassTint(context, 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _openSortSheet,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: highlighted
                ? Border.all(color: AppColors.orange.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded,
                  size: 14,
                  color:
                      highlighted ? AppColors.orange : colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                highlighted ? 'More (+$extraCount)' : 'More…',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      highlighted ? AppColors.orange : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact button that summarises the current sort (primary field +
  /// direction + tiebreaker count) and opens the full sort sheet on tap.
  // ignore: unused_element
  Widget _sortButton(ThemeColors colors) {
    final hasSort = !_sort.isEmpty;
    final primary = hasSort ? _sort.specs.first : null;
    final extraCount = hasSort ? _sort.specs.length - 1 : 0;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: hasSort
            ? AppColors.orange.withValues(alpha: 0.15)
            : _glassTint(context, 0.05),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: _openSortSheet,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: hasSort
                  ? Border.all(color: AppColors.orange.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert,
                    size: 16,
                    color: hasSort ? AppColors.orange : colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  hasSort ? 'Sort: ${primary!.field.label}' : 'Sort',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasSort ? AppColors.orange : colors.textSecondary,
                  ),
                ),
                if (hasSort) ...[
                  const SizedBox(width: 4),
                  Icon(
                    primary!.direction == SortDirection.asc
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color: AppColors.orange,
                  ),
                ],
                if (extraCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+$extraCount more',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSortSheet() async {
    HapticFeedback.lightImpact();
    final result = await SortOptionsSheet.show(context, initial: _sort);
    if (result != null) _setSort(result);
  }

  Widget _activeFilterChips() {
    final chips = <_ActiveChip>[];
    // Smart presets + diets first — those are the top-of-sheet selections
    // the user picked, so showing them first matches where their attention is.
    for (final id in _filter.smartPresets) {
      final preset = SmartPresets.byId(id);
      if (preset == null) continue;
      chips.add(_ActiveChip('${preset.emoji} ${preset.label}', () => setState(() {
        final next = {..._filter.smartPresets}..remove(id);
        _filter = _filter.copyWith(smartPresets: next);
      })));
    }
    for (final tag in _filter.diets) {
      final label = DietHeuristics.labels[tag];
      if (label == null) continue;
      chips.add(_ActiveChip(label, () => setState(() {
        final next = {..._filter.diets}..remove(tag);
        _filter = _filter.copyWith(diets: next);
      })));
    }
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
    return KeyedSubtree(
      key: _recommendedKey,
      child: _collapsibleSection(
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
      ),
    );
  }

  Widget _recommendedCard(RecommendedItem pick, int rank, int total) {
    // Rank badge + explain button sit on their OWN row above the card so they
    // never overlap the card's built-in "Moderate"/"Skip" rating pill on the
    // right edge of the title. Prior Positioned(top:8,right:8) overlay
    // collided with the rating pill visually on every recommended item.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 4, top: 2, bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: _glassTint(context, 0.08),
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
        MenuAnalysisItemCard(
          item: pick.item,
          isSelected: _selected.contains(pick.item.id),
          allergenProfile: _allergenProfile(),
          onToggle: (v) => _toggleItem(pick.item, v),
          onPortionChanged: (m) => _updatePortion(pick.item, m),
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
      // Diagnose which preset(s) are likely the culprit so the user
      // doesn't have to bisect their filter selection by hand. We surface
      // a hint when the chosen preset depends on a Gemini-supplied field
      // the menu doesn't carry (FODMAP, GL, inflammation, ultra-processed).
      final missingDataHint = _diagnoseEmptyResult();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_rounded,
                size: 32, color: colors.textMuted),
            const SizedBox(height: 8),
            Text(
              'No dishes match your filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (missingDataHint != null) ...[
              const SizedBox(height: 4),
              Text(
                missingDataHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _filter = MenuFilterState.empty),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orange,
              ),
            ),
          ],
        ),
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
    final hasSelection = _selected.isNotEmpty;
    // GlassSheet already appends a bottom spacer equal to the home-indicator
    // inset. Wrapping in SafeArea here would double that padding and push
    // the Log pill ~34pt above the bezel. Render the bar flush — the parent
    // sheet handles the gesture-area clearance.
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      decoration: BoxDecoration(
        color: _glassTint(context, 0.35),
        border: Border(top: BorderSide(color: _glassBorder(context, 0.10))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSelection) ...[
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
            const SizedBox(height: 6),
          ],
          KeyedSubtree(
            key: _selectFooterKey,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(_logged ? Icons.check : Icons.add_circle_outline),
                label: Text(_logged
                    ? 'Logged'
                    : hasSelection
                        ? 'Log ${_selected.length} item${_selected.length == 1 ? '' : 's'}'
                        : 'Select dishes to log'),
                onPressed: (_selected.isEmpty || _logged) ? null : _handleLog,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
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
