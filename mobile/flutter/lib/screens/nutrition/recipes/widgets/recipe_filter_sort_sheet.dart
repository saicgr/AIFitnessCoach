/// Bottom sheet for filtering + sorting the "My Recipes" grid.
///
/// Mirrors the visual pattern of [ExerciseFilterSheet]: DraggableScrollableSheet
/// with blurred backdrop, a drag handle, section headers, pill multi-select
/// chips, and an Apply button that pops with the new state.
///
/// Usage:
/// ```dart
/// final next = await showRecipeFilterSortSheet(
///   context: context,
///   current: _filterSort,
///   isDark: isDark,
///   accent: accent,
/// );
/// if (next != null) setState(() => _filterSort = next);
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;

/// Sentinel class for [RecipeFilterSortState.copyWith]. A dedicated class is
/// used (rather than `Object()`, which is NOT a const constructor) so callers
/// can explicitly pass `mealType: null` to clear the meal-type filter,
/// distinguished from omitting the argument (which preserves the value).
class _Sentinel {
  const _Sentinel();
}
const _Sentinel _sentinel = _Sentinel();

/// Meal-type chip options shared by the sheet and the active-chip toolbar.
/// First entry (`null`) represents "all meal types" — no filter applied.
const List<(String?, String)> kRecipeMealTypes = [
  (null, 'All'),
  ('breakfast', '🌅 Breakfast'),
  ('lunch', '☀️ Lunch'),
  ('dinner', '🌙 Dinner'),
  ('snack', '🍎 Snack'),
  ('dessert', '🍰 Dessert'),
  ('drink', '🥤 Drink'),
];

// ─────────────────────────────────────────────────────────────────────────────
// State model
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the filter + sort selection.
///
/// [sourceTypeIn] is an OR-list of backend `source_type` values, e.g.
/// `['improvized', 'imported', 'imported_url']`. An empty list means "all
/// sources" (no filter).
///
/// [sortBy] is one of:
///   - `created_desc` (default — newest first)
///   - `name_asc`     (alphabetical A→Z)
///   - `most_logged`  (most frequently logged first)
///   - `last_cooked`  (most recently cooked first)
class RecipeFilterSortState {
  /// Backend `category` filter — one of breakfast/lunch/dinner/snack/
  /// dessert/drink, or null for "all meal types".
  final String? mealType;
  final List<String> sourceTypeIn;
  final bool hasLeftoversOnly;
  final bool favoritesOnly;
  final String sortBy;

  const RecipeFilterSortState({
    this.mealType,
    this.sourceTypeIn = const [],
    this.hasLeftoversOnly = false,
    this.favoritesOnly = false,
    this.sortBy = 'created_desc',
  });

  /// True when the state equals the app-default (no filters, default sort).
  bool get isDefault =>
      mealType == null &&
      sourceTypeIn.isEmpty &&
      !hasLeftoversOnly &&
      !favoritesOnly &&
      sortBy == 'created_desc';

  /// Count of active filter facets (ignores sort — sort is always "on").
  /// Meal type + leftovers + favorites + one count for the source group.
  int get activeFilterCount {
    var n = 0;
    if (mealType != null) n++;
    if (hasLeftoversOnly) n++;
    if (favoritesOnly) n++;
    if (sourceTypeIn.isNotEmpty) n++;
    return n;
  }

  RecipeFilterSortState copyWith({
    Object? mealType = _sentinel,
    List<String>? sourceTypeIn,
    bool? hasLeftoversOnly,
    bool? favoritesOnly,
    String? sortBy,
  }) {
    return RecipeFilterSortState(
      mealType: identical(mealType, _sentinel)
          ? this.mealType
          : mealType as String?,
      sourceTypeIn: sourceTypeIn ?? this.sourceTypeIn,
      hasLeftoversOnly: hasLeftoversOnly ?? this.hasLeftoversOnly,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RecipeFilterSortState &&
      other.mealType == mealType &&
      _listEq(other.sourceTypeIn, sourceTypeIn) &&
      other.hasLeftoversOnly == hasLeftoversOnly &&
      other.favoritesOnly == favoritesOnly &&
      other.sortBy == sortBy;

  @override
  int get hashCode => Object.hash(mealType, Object.hashAll(sourceTypeIn),
      hasLeftoversOnly, favoritesOnly, sortBy);

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source chip definitions
// ─────────────────────────────────────────────────────────────────────────────

/// A single source-filter chip option. `values` is the OR-list of backend
/// `source_type` strings that this chip stands for — e.g. "Imported" covers
/// all of `imported`, `imported_url`, `imported_text`, `imported_handwritten`.
class _SourceOption {
  final String label;
  final List<String> values;
  const _SourceOption(this.label, this.values);
}

/// Source chips — shown in the "Source" section of the sheet.
///
/// NOTE: "Mine" is a special-cased chip representing "my hand-made recipes"
/// (i.e. `manual`). "Curated" is intentionally omitted here because curated
/// recipes live on the Discover screen, not in the user's library.
const List<_SourceOption> _kSourceOptions = [
  _SourceOption('Mine', ['manual']),
  _SourceOption('Imported', [
    'imported',
    'imported_url',
    'imported_text',
    'imported_handwritten',
  ]),
  _SourceOption('Improvized', ['improvized']),
  _SourceOption('Cloned', ['from_share']),
  _SourceOption('AI-generated', ['ai_generated']),
];

// Sort is no longer in this sheet — the inline `_SortDropdown` in
// `recipes_tab.dart` owns the sort selection. Kept here as a note so nobody
// re-adds a "Sort by" section to the sheet by accident.

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the filter + sort sheet and resolves with the new state if the user
/// taps Apply. Resolves with `null` if the user dismisses by swiping or
/// tapping the scrim — the caller should leave state untouched in that case.
///
/// Hides the root floating nav bar while the sheet is open so it doesn't
/// overlap the sheet's bottom controls, and restores it on dismissal (covers
/// both tap-outside and Apply paths via `whenComplete`).
Future<RecipeFilterSortState?> showRecipeFilterSortSheet({
  required BuildContext context,
  required WidgetRef ref,
  required RecipeFilterSortState current,
  required bool isDark,
  required Color accent,
}) {
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;
  return showGlassSheet<RecipeFilterSortState>(
    context: context,
    builder: (_) => GlassSheet(
      maxHeightFraction: 0.92,
      child: _RecipeFilterSortBody(
        initial: current,
        isDark: isDark,
        accent: accent,
      ),
    ),
  ).whenComplete(() {
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet implementation
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeFilterSortBody extends StatefulWidget {
  final RecipeFilterSortState initial;
  final bool isDark;
  final Color accent;

  const _RecipeFilterSortBody({
    required this.initial,
    required this.isDark,
    required this.accent,
  });

  @override
  State<_RecipeFilterSortBody> createState() => _RecipeFilterSortBodyState();
}

class _RecipeFilterSortBodyState extends State<_RecipeFilterSortBody> {
  late RecipeFilterSortState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initial;
  }

  /// Toggle a source option. Each _SourceOption maps to a set of backend
  /// source_type strings — we add or remove the whole group as a unit so the
  /// chip's selected state is unambiguous.
  void _toggleSource(_SourceOption opt) {
    final current = List<String>.from(_state.sourceTypeIn);
    final isSelected = opt.values.any(current.contains);
    if (isSelected) {
      current.removeWhere(opt.values.contains);
    } else {
      for (final v in opt.values) {
        if (!current.contains(v)) current.add(v);
      }
    }
    setState(() => _state = _state.copyWith(sourceTypeIn: current));
  }

  bool _isSourceSelected(_SourceOption opt) =>
      opt.values.any(_state.sourceTypeIn.contains);

  void _clearAll() {
    setState(() => _state = const RecipeFilterSortState());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = widget.accent;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // GlassSheet already provides the blurred surface + drag handle + safe
    // area. This body only owns the header, scrollable content, and the
    // sticky Apply button.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header: title + Clear all ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              _ClearAllPill(
                enabled: !_state.isDefault,
                accent: accent,
                textMuted: textMuted,
                onTap: _clearAll,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Scrollable sections ────────────────────────────────────────
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                        // ── Meal type ─────────────────────────────────────
                        _SectionLabel(
                          icon: Icons.restaurant_menu_rounded,
                          label: 'Meal type',
                          accent: accent,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in kRecipeMealTypes)
                              _FilterChipPill(
                                label: m.$2,
                                selected: _state.mealType == m.$1,
                                accent: accent,
                                isDark: isDark,
                                onTap: () => setState(() => _state =
                                    _state.copyWith(mealType: m.$1)),
                              ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ── Source ────────────────────────────────────────
                        _SectionLabel(
                          icon: Icons.category_outlined,
                          label: 'Source',
                          accent: accent,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final opt in _kSourceOptions)
                              _FilterChipPill(
                                label: opt.label,
                                selected: _isSourceSelected(opt),
                                accent: accent,
                                isDark: isDark,
                                onTap: () => _toggleSource(opt),
                              ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ── Other toggles ─────────────────────────────────
                        _SectionLabel(
                          icon: Icons.tune_rounded,
                          label: 'Other',
                          accent: accent,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChipPill(
                              label: '⭐ Favorites only',
                              selected: _state.favoritesOnly,
                              accent: accent,
                              isDark: isDark,
                              onTap: () => setState(() => _state = _state
                                  .copyWith(favoritesOnly: !_state.favoritesOnly)),
                            ),
                            _FilterChipPill(
                              label: '🍱 Has leftovers only',
                              selected: _state.hasLeftoversOnly,
                              accent: accent,
                              isDark: isDark,
                              onTap: () => setState(() => _state =
                                  _state.copyWith(
                                      hasLeftoversOnly:
                                          !_state.hasLeftoversOnly)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

        // ── Apply button ──────────────────────────────────────────────
        // GlassSheet already pads the home-indicator safe area, so only add
        // breathing room above/below the button itself.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_state),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: text,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : muted.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14, color: accent),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? accent : text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearAllPill extends StatelessWidget {
  final bool enabled;
  final Color accent;
  final Color textMuted;
  final VoidCallback onTap;

  const _ClearAllPill({
    required this.enabled,
    required this.accent,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Visually disable when there's nothing to clear — keeps the pill in place
    // so the header doesn't reflow when filters go on/off.
    final color = enabled ? accent : textMuted.withValues(alpha: 0.5);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(
          'Clear all',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
