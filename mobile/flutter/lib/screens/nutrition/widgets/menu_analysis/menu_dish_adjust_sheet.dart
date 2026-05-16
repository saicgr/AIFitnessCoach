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
import '../../../../data/models/menu_item.dart';
import '../../../../widgets/glass_sheet.dart';

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

/// One quick-adjust chip definition.
class _Chip {
  final String id;
  final String label;

  /// When non-null, the chip scales the dish by this multiplier
  /// (how-much-eaten chips). Mutually exclusive — picking one replaces
  /// any other scaling chip.
  final double? multiplier;

  /// When non-null, the chip ADDS a separate item with these macros
  /// rather than scaling the dish.
  final Map<String, dynamic>? extraItem;

  const _Chip(this.id, this.label, {this.multiplier, this.extraItem});
}

/// Quick-adjust chips. How-much-eaten chips carry a [multiplier];
/// add-a-side chips carry an [extraItem]. There is deliberately no
/// "took leftovers" chip — it gives no amount (C11).
const List<_Chip> _kChips = [
  _Chip('half', 'Ate ½', multiplier: 0.5),
  _Chip('third', 'Ate ⅓', multiplier: 0.33),
  _Chip('most', 'Ate most', multiplier: 0.85),
  _Chip('shared', 'Shared it', multiplier: 0.5),
  _Chip('lunch_size', 'Lunch/small size', multiplier: 0.7),
  _Chip('extra', 'Extra portion', multiplier: 1.5),
  _Chip(
    'bread',
    '+ Bread/sides',
    extraItem: {
      'name': 'Bread / side',
      'calories': 150,
      'protein_g': 4.0,
      'carbs_g': 28.0,
      'fat_g': 2.0,
    },
  ),
];

/// Show the per-dish adjustment sheet. [item] is the dish being logged.
/// [onRefine] runs the shared streaming correction engine for free-text:
/// it receives the dish + the typed note (+ chip hint) and returns the
/// corrected item list, or null on failure / no input.
///
/// Returns null if the user cancelled.
Future<MenuDishAdjustResult?> showMenuDishAdjustSheet(
  BuildContext context, {
  required MenuItem item,
  required Future<List<Map<String, dynamic>>?> Function(String note)
      onRefine,
}) {
  return showGlassSheet<MenuDishAdjustResult>(
    context: context,
    builder: (_) => GlassSheet(
      showHandle: true,
      child: _MenuDishAdjustBody(item: item, onRefine: onRefine),
    ),
  );
}

class _MenuDishAdjustBody extends StatefulWidget {
  final MenuItem item;
  final Future<List<Map<String, dynamic>>?> Function(String note) onRefine;

  const _MenuDishAdjustBody({required this.item, required this.onRefine});

  @override
  State<_MenuDishAdjustBody> createState() => _MenuDishAdjustBodyState();
}

class _MenuDishAdjustBodyState extends State<_MenuDishAdjustBody> {
  final _noteController = TextEditingController();

  /// Selected how-much-eaten chip id (only one at a time).
  String? _scalingChipId;

  /// Selected add-a-side chip ids (multiple allowed).
  final Set<String> _sideChipIds = {};

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

  List<Map<String, dynamic>> get _extraItems => [
        for (final id in _sideChipIds)
          Map<String, dynamic>.from(
            _kChips.firstWhere((c) => c.id == id).extraItem!,
          ),
      ];

  void _toggleChip(_Chip chip) {
    HapticFeedback.selectionClick();
    setState(() {
      if (chip.extraItem != null) {
        // Add-a-side chip — toggle independently.
        if (_sideChipIds.contains(chip.id)) {
          _sideChipIds.remove(chip.id);
        } else {
          _sideChipIds.add(chip.id);
        }
      } else {
        // How-much-eaten chip — exclusive single-select.
        _scalingChipId = _scalingChipId == chip.id ? null : chip.id;
      }
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
        const SnackBar(content: Text('Add a bit more detail to refine.')),
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
        const SnackBar(
          content: Text("Couldn't refine that — try rewording it."),
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
    for (final id in _sideChipIds) {
      parts.add(_kChips.firstWhere((c) => c.id == id).label);
    }
    return parts.isEmpty ? 'Logged as served' : 'Applied: ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final accent = colors.accent;

    // Live preview of the scaled dish macros (chip-only path).
    final previewCal = (widget.item.calories * _multiplier).round();
    final previewP = (widget.item.proteinG * _multiplier).round();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
                  'Adjust this dish',
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
            'Menu macros are "as served" — tell us what you actually ate.',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          // ── Quick-adjust chips ──
          Text(
            'How much did you eat?',
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
              for (final chip in _kChips)
                _chipWidget(chip, colors, accent),
            ],
          ),
          const SizedBox(height: 16),
          // ── Free-text correction ──
          Text(
            'Or describe it',
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: colors.textMuted.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: accent.withValues(alpha: 0.55)),
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
              '${_sideChipIds.isEmpty ? '' : '  (+${_sideChipIds.length} side)'}',
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
                  onPressed: _refining
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancel'),
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
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_refining ? 'Refining…' : 'Apply'),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipWidget(_Chip chip, ThemeColors colors, Color accent) {
    final isSide = chip.extraItem != null;
    final active = isSide
        ? _sideChipIds.contains(chip.id)
        : _scalingChipId == chip.id;
    return Material(
      color: active
          ? accent.withValues(alpha: 0.15)
          : colors.textMuted.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _toggleChip(chip),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(
                    color: accent.withValues(alpha: 0.55), width: 1)
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
