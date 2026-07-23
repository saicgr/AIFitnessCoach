/// L5 — per-dish logging adjustment.
///
/// Restaurant menu data is "as served"; what the user actually ate is
/// almost always different. When a user selects a menu dish to log, this
/// sheet lets them correct it BEFORE it hits `food_logs`:
///
///  - one-tap quick-adjust chips that frame on HOW MUCH WAS EATEN
///    (`Ate ½` · `Ate ⅓` · `Ate most` · `Shared it` · `+ Bread/sides`
///    · `Lunch/small size` · `Extra portion`);
///  - a free-text field parsed by the SAME streaming text-analysis
///    "correction" engine the plate-photo Refine flow uses
///    (`analyzeFoodFromTextStreaming` framed as a CORRECTION).
///
/// C11 edge cases handled here:
///  - "+ Bread/sides" adds a SEPARATE item, never scales the dish.
///  - per-dish (this sheet is opened once per dish — not one blanket
///    setting when logging several dishes).
///  - free-text wins over a conflicting chip: if the user typed a note
///    AND tapped a how-much chip, the note is sent to the correction
///    engine and the engine's result is authoritative; the chip is
///    surfaced in the prompt only as a hint.
///  - "took leftovers" without an amount is ambiguous → there is no
///    "leftovers" chip; every how-much chip names a concrete fraction,
///    and a free-text-only note that lacks an amount still goes through
///    the correction engine which estimates conservatively.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/companion_suggestion.dart';
import '../../../../data/models/menu_item.dart';
import '../../../../widgets/glass_sheet.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Outcome of the per-dish adjustment step.
class MenuDishAdjustResult {
  /// Portion multiplier to apply to the dish itself (1.0 = as-served).
  /// A how-much chip sets this; free-text leaves it at 1.0 because the
  /// correction engine bakes the amount into [refinedDishOverride].
  final double portionMultiplier;

  /// When the user typed free-text, the correction engine returns a
  /// re-estimated version of this dish. Non-null = use these macros
  /// verbatim (already reflects the eaten amount); null = use the menu
  /// macros scaled by [portionMultiplier].
  final Map<String, dynamic>? refinedDishOverride;

  /// Extra SEPARATE items to log alongside the dish — produced by the
  /// `+ Bread/sides` / `Extra portion` chips and by any sides the
  /// correction engine split out. Never folded into the dish macros.
  final List<Map<String, dynamic>> extraItems;

  /// Human-readable summary of what was applied, echoed back to the user
  /// (C2-style "applied: …" transparency).
  final String summary;

  const MenuDishAdjustResult({
    required this.portionMultiplier,
    required this.refinedDishOverride,
    required this.extraItems,
    required this.summary,
  });
}

/// One how-much-did-you-eat chip. Exclusive single-select: picking one
/// replaces any other.
class _Chip {
  final String id;
  final String label;

  /// Scales the dish's menu macros by this factor.
  final double? multiplier;

  const _Chip(this.id, this.label, {this.multiplier});
}

/// Quick-adjust chips — how much of the dish was eaten. Exclusive
/// single-select. There is deliberately no "took leftovers" chip: it gives no
/// amount (C11).
///
/// There is also no generic "+ Bread/sides" chip any more. It invented a
/// 150-cal side out of thin air; the real sides are printed on the menu the
/// user just scanned, and they're offered below with their real macros.
const List<_Chip> _kChips = [
  _Chip('half', 'Ate ½', multiplier: 0.5),
  _Chip('third', 'Ate ⅓', multiplier: 0.33),
  _Chip('most', 'Ate most', multiplier: 0.85),
  _Chip('shared', 'Shared it', multiplier: 0.5),
  _Chip('lunch_size', 'Lunch/small size', multiplier: 0.7),
  _Chip('extra', 'Extra portion', multiplier: 1.5),
];

/// Show the per-dish adjustment sheet. [item] is the dish being logged.
/// [onRefine] runs the shared streaming correction engine for free-text:
/// it receives the dish + the typed note (+ chip hint) and returns the
/// corrected item list, or null on failure / no input.
///
/// [menuAddons] are the sauces / sides / enhancements from the SAME scanned
/// menu — real names, real macros, real prices. [companions] are the
/// history/global suggestions from `/nutrition/companions`, used only when
/// the menu itself listed no add-ons, so the user is never left with nothing
/// to attach.
///
/// [openOnAddons] scrolls straight to the add-on block (used when the dish
/// says "served with choice of one side and one sauce").
///
/// Returns null if the user cancelled.
Future<MenuDishAdjustResult?> showMenuDishAdjustSheet(
  BuildContext context, {
  required MenuItem item,
  required Future<List<Map<String, dynamic>>?> Function(String note) onRefine,
  List<MenuItem> menuAddons = const [],
  List<CompanionSuggestion> companions = const [],
  bool openOnAddons = false,
}) {
  return showGlassSheet<MenuDishAdjustResult>(
    context: context,
    builder: (_) => GlassSheet(
      showHandle: true,
      maxHeightFraction: 0.9,
      child: _MenuDishAdjustBody(
        item: item,
        onRefine: onRefine,
        menuAddons: menuAddons,
        companions: companions,
        openOnAddons: openOnAddons,
      ),
    ),
  );
}

class _MenuDishAdjustBody extends StatefulWidget {
  final MenuItem item;
  final Future<List<Map<String, dynamic>>?> Function(String note) onRefine;
  final List<MenuItem> menuAddons;
  final List<CompanionSuggestion> companions;
  final bool openOnAddons;

  const _MenuDishAdjustBody({
    required this.item,
    required this.onRefine,
    this.menuAddons = const [],
    this.companions = const [],
    this.openOnAddons = false,
  });

  @override
  State<_MenuDishAdjustBody> createState() => _MenuDishAdjustBodyState();
}

class _MenuDishAdjustBodyState extends State<_MenuDishAdjustBody> {
  final _noteController = TextEditingController();

  /// Selected how-much-eaten chip id (only one at a time).
  String? _scalingChipId;

  /// Add-ons picked off THIS menu, keyed by MenuItem.id.
  final Set<String> _menuAddonIds = {};

  /// Companion suggestions picked, keyed by lowercased name.
  final Set<String> _companionKeys = {};

  bool _refining = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _multiplier {
    if (_scalingChipId == null) return 1.0;
    final chip = _kChips.firstWhere((c) => c.id == _scalingChipId);
    return chip.multiplier ?? 1.0;
  }

  /// Every picked add-on, as its own log payload.
  ///
  /// Add-ons are logged as SEPARATE rows, never folded into the dish — a
  /// béarnaise is 180 calories the user should be able to see, edit and
  /// delete on its own. `parent_dish_name` is what keeps the pairing legible
  /// afterwards.
  List<Map<String, dynamic>> get _extraItems => [
    for (final addon in widget.menuAddons)
      if (_menuAddonIds.contains(addon.id))
        {
          'name': addon.name,
          'calories': addon.calories.round(),
          'protein_g': addon.proteinG,
          'carbs_g': addon.carbsG,
          'fat_g': addon.fatG,
          if (addon.fiberG != null) 'fiber_g': addon.fiberG,
          if (addon.weightG != null) 'weight_g': addon.weightG!.round(),
          if (addon.description != null) 'description': addon.description,
          if (addon.addonGroup != null) 'addon_group': addon.addonGroup,
          'parent_dish_name': widget.item.name,
          if (addon.inflammationScore != null)
            'inflammation_score': addon.inflammationScore,
          if (addon.isUltraProcessed != null)
            'is_ultra_processed': addon.isUltraProcessed,
          if (addon.glycemicLoad != null) 'glycemic_load': addon.glycemicLoad,
          if (addon.fodmapRating != null) 'fodmap_rating': addon.fodmapRating,
          if (addon.fodmapReason != null) 'fodmap_reason': addon.fodmapReason,
          if (addon.addedSugarG != null) 'added_sugar_g': addon.addedSugarG,
          if (addon.inflammationTriggers != null)
            'inflammation_triggers': addon.inflammationTriggers,
          if (addon.rating != null) 'rating': addon.rating,
          if (addon.ratingReason != null) 'rating_reason': addon.ratingReason,
        },
    for (final companion in widget.companions)
      if (_companionKeys.contains(_companionKey(companion)))
        {
          ...companion.toLogItem(),
          'parent_dish_name': widget.item.name,
        },
  ];

  int get _selectedAddonCount => _menuAddonIds.length + _companionKeys.length;

  /// Calories the picked add-ons contribute on top of the dish.
  double get _addonCalories {
    double total = 0;
    for (final addon in widget.menuAddons) {
      if (_menuAddonIds.contains(addon.id)) total += addon.calories;
    }
    for (final companion in widget.companions) {
      if (_companionKeys.contains(_companionKey(companion))) {
        total += companion.estCalories;
      }
    }
    return total;
  }

  static String _companionKey(CompanionSuggestion c) =>
      c.name.trim().toLowerCase();

  /// Menu add-ons grouped by kind, in the order a menu prints them.
  Map<String, List<MenuItem>> get _addonsByGroup {
    const order = ['side', 'sauce', 'topping', 'enhancement', 'upgrade'];
    final grouped = <String, List<MenuItem>>{};
    for (final addon in widget.menuAddons) {
      final key = addon.addonGroup ?? 'side';
      grouped.putIfAbsent(key, () => []).add(addon);
    }
    return {
      for (final key in order)
        if (grouped.containsKey(key)) key: grouped[key]!,
      for (final entry in grouped.entries)
        if (!order.contains(entry.key)) entry.key: entry.value,
    };
  }

  void _toggleChip(_Chip chip) {
    HapticFeedback.selectionClick();
    // How-much-eaten chips are exclusive single-select.
    setState(() {
      _scalingChipId = _scalingChipId == chip.id ? null : chip.id;
    });
  }

  void _toggleMenuAddon(MenuItem addon) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_menuAddonIds.remove(addon.id)) _menuAddonIds.add(addon.id);
    });
  }

  void _toggleCompanion(CompanionSuggestion companion) {
    HapticFeedback.selectionClick();
    setState(() {
      final key = _companionKey(companion);
      if (!_companionKeys.remove(key)) _companionKeys.add(key);
    });
  }

  /// Apply: when there's free-text, run the correction engine — the note
  /// WINS over any scaling chip (C11). Otherwise apply the chips directly.
  Future<void> _apply() async {
    final note = _noteController.text.trim();

    if (note.isEmpty) {
      // Chips-only path — no network round-trip needed.
      Navigator.pop(
        context,
        MenuDishAdjustResult(
          portionMultiplier: _multiplier,
          refinedDishOverride: null,
          extraItems: _extraItems,
          summary: _chipSummary(),
        ),
      );
      return;
    }

    if (note.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).menuDishAdjustAddABitMore),
        ),
      );
      return;
    }

    setState(() => _refining = true);
    // Free-text wins: pass the typed note plus the chip only as a hint so
    // the correction engine reconciles them and its result is final.
    final hinted = _scalingChipId == null
        ? note
        : '$note (rough portion hint: '
              '${_kChips.firstWhere((c) => c.id == _scalingChipId).label})';
    List<Map<String, dynamic>>? corrected;
    try {
      corrected = await widget.onRefine(hinted);
    } finally {
      if (mounted) setState(() => _refining = false);
    }
    if (!mounted) return;

    if (corrected == null || corrected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).menuDishAdjustCouldnTRefineThat,
          ),
        ),
      );
      return;
    }

    // First returned item = the (re-estimated) dish; any remaining items
    // are separate sides the engine split out — kept as extraItems so we
    // never fold a side's macros into the dish (C11).
    final dish = corrected.first;
    final engineExtras = corrected.length > 1
        ? corrected.sublist(1)
        : const <Map<String, dynamic>>[];

    Navigator.pop(
      context,
      MenuDishAdjustResult(
        // Free-text result is already "as eaten" → no extra scaling.
        portionMultiplier: 1.0,
        refinedDishOverride: dish,
        extraItems: [..._extraItems, ...engineExtras],
        summary: 'Refined from your note: "$note"',
      ),
    );
  }

  String _chipSummary() {
    final parts = <String>[];
    if (_scalingChipId != null) {
      parts.add(_kChips.firstWhere((c) => c.id == _scalingChipId).label);
    }
    for (final addon in widget.menuAddons) {
      if (_menuAddonIds.contains(addon.id)) parts.add('+ ${addon.name}');
    }
    for (final companion in widget.companions) {
      if (_companionKeys.contains(_companionKey(companion))) {
        parts.add('+ ${companion.name}');
      }
    }
    return parts.isEmpty ? 'Logged as served' : 'Applied: ${parts.join(', ')}';
  }

  /// "Add from this menu" — the sauces / sides / enhancements printed on the
  /// menu the user just scanned, with their real macros and prices.
  ///
  /// Falls back to `/nutrition/companions` suggestions only when the menu
  /// listed no add-ons of its own, and labels them differently so it's clear
  /// those are suggestions rather than something the restaurant offers.
  List<Widget> _buildAddonSection(ThemeColors colors, Color accent) {
    final grouped = _addonsByGroup;
    final hasMenuAddons = grouped.isNotEmpty;
    final hasCompanions = widget.companions.isNotEmpty;
    if (!hasMenuAddons && !hasCompanions) return const [];

    return [
      Row(
        children: [
          Icon(Icons.add_circle_outline, size: 14, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasMenuAddons ? 'Add from this menu' : 'Often eaten with this',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          if (_selectedAddonCount > 0)
            Text(
              '+${_addonCalories.round()} cal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
        ],
      ),
      // What the price already covers, in the menu's own words.
      if (widget.item.includedChoices != null) ...[
        const SizedBox(height: 4),
        Text(
          widget.item.includedChoices!,
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: colors.textMuted,
          ),
        ),
      ],
      const SizedBox(height: 8),
      if (hasMenuAddons)
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              _groupLabel(entry.key, entry.value.length),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colors.textMuted,
              ),
            ),
          ),
          for (final addon in entry.value)
            _addonRow(
              colors: colors,
              accent: accent,
              selected: _menuAddonIds.contains(addon.id),
              title: addon.name,
              subtitle: _addonSubtitle(addon),
              detail: addon.description,
              onTap: () => _toggleMenuAddon(addon),
            ),
        ]
      else
        for (final companion in widget.companions)
          _addonRow(
            colors: colors,
            accent: accent,
            selected: _companionKeys.contains(_companionKey(companion)),
            title: companion.name,
            subtitle: '${companion.estCalories} cal'
                '${companion.estProteinG > 0 ? ' · ${companion.estProteinG.toStringAsFixed(0)}g P' : ''}',
            detail: companion.why.isEmpty ? null : companion.why,
            onTap: () => _toggleCompanion(companion),
          ),
      const SizedBox(height: 16),
    ];
  }

  static String _groupLabel(String group, int count) {
    final plural = count == 1 ? '' : 'S';
    return switch (group) {
      'sauce' => 'SAUCE$plural',
      'side' => 'SIDE$plural',
      'topping' => 'TOPPING$plural',
      'enhancement' => 'ENHANCEMENT$plural',
      'upgrade' => 'UPGRADE$plural',
      _ => group.toUpperCase(),
    };
  }

  static String _addonSubtitle(MenuItem addon) {
    final parts = <String>['${addon.calories.round()} cal'];
    if (addon.proteinG > 0) {
      parts.add('${addon.proteinG.toStringAsFixed(0)}g P');
    }
    if (addon.price != null) {
      parts.add('\$${addon.price!.toStringAsFixed(2)}');
    }
    return parts.join(' · ');
  }

  Widget _addonRow({
    required ThemeColors colors,
    required Color accent,
    required bool selected,
    required String title,
    required String subtitle,
    String? detail,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.10) : colors.elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? accent : colors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (detail != null && detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final accent = colors.accent;

    // Live preview of the scaled dish macros (chip-only path).
    final previewCal = (widget.item.calories * _multiplier).round();
    final previewP = (widget.item.proteinG * _multiplier).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).menuDishAdjustAdjustThisDish,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context).menuDishAdjustMenuMacrosAreAs,
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            const SizedBox(height: 14),
            // ── Quick-adjust chips ──
            Text(
              AppLocalizations.of(context).menuDishAdjustHowMuchDidYou,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in _kChips) _chipWidget(chip, colors, accent),
              ],
            ),
            const SizedBox(height: 16),
            // ── Add-ons from THIS menu ──
            ..._buildAddonSection(colors, accent),
            // ── Free-text correction ──
            Text(
              AppLocalizations.of(context).menuDishAdjustOrDescribeIt,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText:
                    "e.g. 'added more bread', 'skipped the rice', "
                    "'doubled the chicken'",
                hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: colors.textMuted.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent.withValues(alpha: 0.55)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // C11: free-text wins over a conflicting chip — make it explicit.
            if (_scalingChipId != null)
              Text(
                'Tip: if you also type a note, the note wins — the chip just '
                'becomes a hint.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.textMuted,
                  height: 1.3,
                ),
              ),
            const SizedBox(height: 14),
            // ── Live preview (chip-only path) ──
            if (_noteController.text.trim().isEmpty)
              Text(
                'This dish: ~$previewCal cal · ${previewP}g protein'
                '${_selectedAddonCount == 0 ? '' : '  (+$_selectedAddonCount add-on'
                    '${_selectedAddonCount == 1 ? '' : 's'}, +${_addonCalories.round()} cal, logged separately)'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _refining ? null : () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).buttonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _refining ? null : _apply,
                    icon: _refining
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      _refining
                          ? AppLocalizations.of(context).menuDishAdjustRefining
                          : AppLocalizations.of(
                              context,
                            ).setAdjustmentSheetApply,
                    ),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipWidget(_Chip chip, ThemeColors colors, Color accent) {
    final active = _scalingChipId == chip.id;
    return Material(
      color: active
          ? accent.withValues(alpha: 0.15)
          : colors.textMuted.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _toggleChip(chip),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: accent.withValues(alpha: 0.55), width: 1)
                : null,
          ),
          child: Text(
            chip.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? accent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
