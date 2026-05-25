/// Grocery list — aisle-grouped checkable items, add custom, export.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/grocery_list.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/services/data_cache_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/pill_app_bar.dart';

import '../../../l10n/generated/app_localizations.dart';
class GroceryListScreen extends ConsumerStatefulWidget {
  final String listId;
  final String userId;
  final bool isDark;
  const GroceryListScreen({super.key, required this.listId, required this.userId, required this.isDark});
  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  GroceryList? _list;
  bool _loading = true;
  String? _error;
  bool _showStaples = false;

  /// Per-list SharedPreferences slot — keyed by listId so each list caches
  /// independently.
  String get _cacheKey => 'cache_grocery_list_${widget.listId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Cache-first load (Part-1 instant-load standard):
  /// 1. Render the disk-cached list immediately so a cold open shows real
  ///    items on first frame (no spinner).
  /// 2. Revalidate over the network and write-through-persist the fresh list.
  Future<void> _load() async {
    // ---- Step 1: disk cache -------------------------------------------------
    try {
      final cached = await DataCacheService.instance
          .getCached(_cacheKey, userId: widget.userId);
      if (cached != null && mounted) {
        setState(() {
          _list = GroceryList.fromJson(cached);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('🛒 [GroceryList] cache read failed: $e');
    }

    // ---- Step 2: network revalidate ----------------------------------------
    try {
      final l = await ref.read(recipeRepositoryProvider).getGroceryList(widget.listId);
      if (mounted) setState(() { _list = l; _loading = false; _error = null; });
      await _persistToCache(l);
    } catch (e) {
      // Keep the cached list visible on a network failure; only escalate to
      // the error view when nothing was rendered (cold-cache path).
      if (mounted && _list == null) {
        setState(() { _error = e.toString(); _loading = false; });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Write the current list through to disk. `GroceryList`/`GroceryListItem`
  /// have no `toJson`, so we re-emit the exact snake_case shape their
  /// `fromJson` factories expect — a loss-free round-trip.
  Future<void> _persistToCache(GroceryList l) async {
    try {
      await DataCacheService.instance.cache(
        _cacheKey,
        _encodeList(l),
        userId: widget.userId,
      );
    } catch (e) {
      debugPrint('🛒 [GroceryList] cache write failed: $e');
    }
  }

  /// Encode a [GroceryList] to the JSON map `GroceryList.fromJson` consumes.
  static Map<String, dynamic> _encodeList(GroceryList l) => {
        'id': l.id,
        'user_id': l.userId,
        'meal_plan_id': l.mealPlanId,
        'source_recipe_id': l.sourceRecipeId,
        'name': l.name,
        'notes': l.notes,
        'created_at': l.createdAt.toIso8601String(),
        'updated_at': l.updatedAt.toIso8601String(),
        'items': l.items
            .map((i) => <String, dynamic>{
                  'id': i.id,
                  'list_id': i.listId,
                  'ingredient_name': i.ingredientName,
                  'quantity': i.quantity,
                  'unit': i.unit,
                  'aisle': i.aisle?.value,
                  'is_checked': i.isChecked,
                  'is_staple_suppressed': i.isStapleSuppressed,
                  'source_recipe_ids': i.sourceRecipeIds,
                  'notes': i.notes,
                })
            .toList(),
      };

  Future<void> _toggle(GroceryListItem item) async {
    setState(() {
      _list = GroceryList(
        id: _list!.id, userId: _list!.userId,
        mealPlanId: _list!.mealPlanId, sourceRecipeId: _list!.sourceRecipeId,
        name: _list!.name, notes: _list!.notes,
        items: _list!.items
            .map((i) => i.id == item.id ? i.copyWith(isChecked: !i.isChecked) : i)
            .toList(),
        createdAt: _list!.createdAt, updatedAt: DateTime.now(),
      );
    });
    // Persist the optimistic toggle so a restart reflects it instantly.
    if (_list != null) _persistToCache(_list!);
    try {
      await ref.read(recipeRepositoryProvider)
          .updateGroceryItem(widget.listId, item.id, {'is_checked': !item.isChecked});
    } catch (e) {
      // revert on failure
      _load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _export(String format) async {
    final txt = await ref.read(recipeRepositoryProvider).exportGroceryList(widget.listId, format: format);
    if (format == 'csv') {
      await Share.share(txt, subject: '${_list?.name ?? "Grocery list"}.csv');
    } else {
      await Clipboard.setData(ClipboardData(text: txt));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).recipeShareCopiedToClipboard)));
    }
  }

  /// Consolidated overflow menu. Previous UI leaked two top-bar icons (the
  /// mystery eye + the overflow dots); this collapses every secondary action
  /// into one sheet so the app bar reads clean.
  Future<void> _showMoreMenu(BuildContext ctx, Color muted, Color text) async {
    HapticFeedback.lightImpact();
    await showGlassSheet<void>(
      context: ctx,
      builder: (sheetCtx) => GlassSheet(
        opaque: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _showStaples ? Icons.visibility_off : Icons.visibility,
                color: text,
              ),
              title: Text(
                _showStaples ? AppLocalizations.of(context).groceryListHidePantryStaples : AppLocalizations.of(context).groceryListShowPantryStaples,
                style: TextStyle(color: text),
              ),
              subtitle: Text(
                _showStaples
                    ? AppLocalizations.of(context).groceryListHidingKeepsTheList
                    : 'Also show items you likely already have (salt, oil, etc.)',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _showStaples = !_showStaples);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.content_copy, color: text),
              title: Text(AppLocalizations.of(context).groceryListCopyAsText, style: TextStyle(color: text)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _export('text');
              },
            ),
            ListTile(
              leading: Icon(Icons.ios_share, color: text),
              title: Text(AppLocalizations.of(context).groceryListShareAsCsv, style: TextStyle(color: text)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _export('csv');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddItemSheet() async {
    HapticFeedback.lightImpact();
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController();
    Aisle? selectedAisle;

    await showGlassSheet<void>(
      context: context,
      builder: (sheetContext) {
        return GlassSheet(
          opaque: true,
          child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).groceryListAddItem,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).groceryListItemName,
                    labelStyle: TextStyle(color: muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: text),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).groceryListQty,
                          labelStyle: TextStyle(color: muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: unitController,
                        style: TextStyle(color: text),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).groceryListUnitGCup,
                          labelStyle: TextStyle(color: muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: accent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).groceryListAisleOptional,
                  style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Aisle.values.map((a) {
                    final isSelected = selectedAisle == a;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setSheetState(() {
                          selectedAisle = isSelected ? null : a;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accent.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? accent : muted.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          a.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? accent : muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final qty = double.tryParse(qtyController.text.trim());
                      final unit = unitController.text.trim();

                      Navigator.of(sheetContext).pop();
                      await _addItem(
                        name: name,
                        quantity: qty,
                        unit: unit.isEmpty ? null : unit,
                        aisle: selectedAisle,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context).tilePickerAdd, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Future<void> _addItem({
    required String name,
    double? quantity,
    String? unit,
    Aisle? aisle,
  }) async {
    try {
      await ref.read(recipeRepositoryProvider).addGroceryItem(widget.listId, {
        'ingredient_name': name,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (aisle != null) 'aisle': aisle.value,
      });
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: bg,
      appBar: PillAppBar(
        title: _list?.name ?? AppLocalizations.of(context).recipeDetailGroceryList,
        actions: [
          PillAppBarAction(
            icon: Icons.more_horiz,
            onTap: () => _showMoreMenu(context, muted, text),
          ),
        ],
      ),
      body: _loading
          // Layout-matched skeleton — only on a true cold-cache first open.
          ? const _GroceryListSkeleton()
          : _error != null
              ? Center(child: Text('Error: $_error', style: TextStyle(color: muted)))
              : _buildBody(accent, text, muted, surface),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddItemSheet,
              backgroundColor: accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).groceryListAddItem, style: TextStyle(fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildBody(Color accent, Color text, Color muted, Color surface) {
    final items = _showStaples
        ? _list!.items
        : _list!.items.where((i) => !i.isStapleSuppressed).toList();
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 64,
                color: muted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).groceryListNoItemsYet,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).groceryListTapTheButtonBelow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: muted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final byAisle = <Aisle, List<GroceryListItem>>{};
    for (final i in items) {
      byAisle.putIfAbsent(i.aisle ?? Aisle.other, () => []).add(i);
    }
    final aisles = byAisle.keys.toList()..sort((a, b) => a.label.compareTo(b.label));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        for (final aisle in aisles) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
            child: Text(
              aisle.label.toUpperCase(),
              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          ...byAisle[aisle]!.map((i) => CheckboxListTile(
                value: i.isChecked,
                dense: true,
                onChanged: (_) => _toggle(i),
                title: Text(
                  i.ingredientName,
                  style: TextStyle(
                    color: text,
                    decoration: i.isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: i.quantity != null
                    ? Text('${i.quantity!.toStringAsFixed(i.quantity == i.quantity!.toInt() ? 0 : 1)} ${i.unit ?? ""}',
                        style: TextStyle(color: muted, fontSize: 11))
                    : null,
              )),
        ],
      ],
    );
  }
}

/// Layout-matched loading placeholder for the grocery list. Mirrors the
/// aisle-header + checkbox-row stack so the skeleton → content cross-fade
/// doesn't reflow. Shown only on a genuine cold-cache first open.
class _GroceryListSkeleton extends StatelessWidget {
  const _GroceryListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: const [
        SkeletonBox(width: 90, height: 12), // aisle header
        SizedBox(height: 10),
        SkeletonList(itemCount: 4, spacing: 8),
        SizedBox(height: 20),
        SkeletonBox(width: 110, height: 12), // aisle header
        SizedBox(height: 10),
        SkeletonList(itemCount: 3, spacing: 8),
      ],
    );
  }
}
