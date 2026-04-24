/// Grocery list — aisle-grouped checkable items, add custom, export.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/grocery_list.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/pill_app_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await ref.read(recipeRepositoryProvider).getGroceryList(widget.listId);
      if (mounted) setState(() { _list = l; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

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
          const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  /// Consolidated overflow menu. Previous UI leaked two top-bar icons (the
  /// mystery eye + the overflow dots); this collapses every secondary action
  /// into one sheet so the app bar reads clean.
  Future<void> _showMoreMenu(BuildContext ctx, Color muted, Color text) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: widget.isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                _showStaples ? Icons.visibility_off : Icons.visibility,
                color: text,
              ),
              title: Text(
                _showStaples ? 'Hide pantry staples' : 'Show pantry staples',
                style: TextStyle(color: text),
              ),
              subtitle: Text(
                _showStaples
                    ? 'Hiding keeps the list focused on what you actually need'
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
              title: Text('Copy as text', style: TextStyle(color: text)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _export('text');
              },
            ),
            ListTile(
              leading: Icon(Icons.ios_share, color: text),
              title: Text('Share as CSV', style: TextStyle(color: text)),
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

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
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
                  'Add item',
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
                    labelText: 'Item name',
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
                          labelText: 'Qty',
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
                          labelText: 'Unit (g, cup, ...)',
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
                  'Aisle (optional)',
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
                    child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
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
        title: _list?.name ?? 'Grocery list',
        actions: [
          PillAppBarAction(
            icon: Icons.more_horiz,
            onTap: () => _showMoreMenu(context, muted, text),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
              label: const Text('Add item', style: TextStyle(fontWeight: FontWeight.w600)),
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
                'No items yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button below to add ingredients.',
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
