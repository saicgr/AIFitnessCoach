/// Phase-2 §2.9: Region/restaurant variant dropdown for the per-item edit
/// affordance in [LogMealSheet].
///
/// Renders ONLY when the dish has multiple regional/restaurant variants in
/// `food_nutrition_overrides_canonical`. For dishes with no alternates
/// (~80% of cases), the widget builds nothing — zero clutter on the card.
///
/// Integration point in food_item_ranking_card.dart (or anywhere a user can
/// edit a logged food_item):
///
///   RegionVariantDropdown(
///     foodLogId: log.id,
///     foodItemIndex: itemIndex,
///     dishName: item.name,
///     onSwapped: (result) => setState(() {
///       item.calories = result.newCalories;
///       item.proteinG = result.newProteinG;
///       // ...
///     }),
///   )
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/nutrition_repository.dart';

import '../../../l10n/generated/app_localizations.dart';
class RegionVariantDropdown extends ConsumerStatefulWidget {
  /// The food_log row id this item belongs to. Required for the swap RPC.
  final String foodLogId;

  /// Index of this food_item within food_log.food_items[]. The swap endpoint
  /// updates this specific item's macros + override_id pointer.
  final int foodItemIndex;

  /// The dish name from the logged item (e.g. "Chicken Biryani"). The
  /// dropdown queries the backend for variants matching this name.
  final String dishName;

  /// Optional currently-selected override id (so the dropdown can mark the
  /// active selection). When null, defaults to the first variant returned.
  final int? currentOverrideId;

  /// Callback after a successful swap with the new macros. Caller should
  /// update local state so the card re-renders.
  final void Function(DishVariantSwapResult) onSwapped;

  const RegionVariantDropdown({
    super.key,
    required this.foodLogId,
    required this.foodItemIndex,
    required this.dishName,
    required this.onSwapped,
    this.currentOverrideId,
  });

  @override
  ConsumerState<RegionVariantDropdown> createState() =>
      _RegionVariantDropdownState();
}

class _RegionVariantDropdownState extends ConsumerState<RegionVariantDropdown> {
  List<DishVariant>? _variants;
  bool _loading = true;
  bool _swapping = false;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentOverrideId;
    _fetchVariants();
  }

  Future<void> _fetchVariants() async {
    final repo = ref.read(nutritionRepositoryProvider);
    final variants = await repo.fetchDishVariants(widget.dishName);
    if (!mounted) return;
    setState(() {
      _variants = variants;
      _loading = false;
      // Default selection: keep current if it's in the list, else pick first.
      if (_selectedId == null && variants.isNotEmpty) {
        _selectedId = variants.first.id;
      }
    });
  }

  Future<void> _onSelected(int? id) async {
    if (id == null || id == _selectedId || _swapping) return;
    setState(() => _swapping = true);
    final repo = ref.read(nutritionRepositoryProvider);
    final result = await repo.swapDishVariant(
      foodLogId: widget.foodLogId,
      foodItemIndex: widget.foodItemIndex,
      newOverrideId: id,
    );
    if (!mounted) return;
    setState(() {
      _swapping = false;
      if (result?.success == true) {
        _selectedId = id;
      }
    });
    if (result?.success == true) {
      widget.onSwapped(result!);
    } else {
      // Show a subtle failure indicator — toast/snackbar is the parent's job
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).regionVariantDropdownCouldNotSwapVariant),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything while loading OR if there's only one variant.
    // Per Phase-2 §2.9: zero card-clutter for dishes with no alternates.
    if (_loading) return const SizedBox.shrink();
    final variants = _variants;
    if (variants == null || variants.length <= 1) {
      return const SizedBox.shrink();
    }

    final colors = ThemeColors.of(context);
    final muted = colors.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.public, size: 14, color: muted),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).regionVariantDropdownRegion,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: muted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedId,
                    isExpanded: true,
                    isDense: true,
                    icon: _swapping
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.arrow_drop_down, size: 18, color: muted),
                    style: TextStyle(
                      fontSize: 13, color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: colors.surface,
                    items: variants
                        .map((v) => DropdownMenuItem<int>(
                              value: v.id,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      v.dropdownLabel,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (v.caloriesPer100g != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${v.caloriesPer100g!.toStringAsFixed(0)} kcal/100g',
                                      style: TextStyle(
                                        fontSize: 11, color: muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: _swapping ? null : _onSelected,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
