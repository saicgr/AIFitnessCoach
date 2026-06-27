import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/program_template.dart';
import '../../../data/services/haptic_service.dart';

// ===========================================================================
// Shared program-variant picker — the single implementation used by BOTH the
// full-screen Program Detail page (WEEKS / PER WEEK selectors) and the
// Start-Program bottom sheet (Length & frequency). Extracted from
// program_detail_screen.dart so the two surfaces can't drift.
//
// The widget renders two "dropdown" controls (Duration + Per week) plus an
// optional trailing static tile (e.g. MINUTES) and, when there is more than
// one intensity, an intensity chip row. Tapping a control opens a bottom-sheet
// picker. Selection resolves to the matching variant on a SPARSE matrix and is
// handed back via [onSelect]; [onResetToDefault] reverts to the program's
// recommended variant.
//
// Perf: the distinct weeks list + sessions-per-week map are precomputed ONCE
// (in initState / didUpdateWidget when the variant list changes), never per
// open — opening a picker is now allocation-free.
// ===========================================================================

/// Resolve the best variant for [weeks] × [sessions] on a sparse matrix.
///
/// Priority: (1) exact match; (2) nearest sessions-per-week for [weeks]
/// (min abs diff, tiebreak lower); (3) the default variant; (4) the first.
/// Never returns null while [variants] is non-empty.
ProgramVariantOption resolveProgramVariant(
  List<ProgramVariantOption> variants,
  int weeks,
  int sessions,
) {
  // 1. Exact match.
  for (final v in variants) {
    if (v.weeks == weeks && v.sessionsPerWeek == sessions) return v;
  }

  // 2. Nearest sessions for the requested weeks.
  final sameWeek = variants.where((v) => v.weeks == weeks).toList();
  if (sameWeek.isNotEmpty) {
    sameWeek.sort((a, b) {
      final da = (a.sessionsPerWeek - sessions).abs();
      final db = (b.sessionsPerWeek - sessions).abs();
      if (da != db) return da.compareTo(db);
      return a.sessionsPerWeek.compareTo(b.sessionsPerWeek);
    });
    return sameWeek.first;
  }

  // 3. Default variant.
  for (final v in variants) {
    if (v.isDefault) return v;
  }

  // 4. First variant.
  return variants.first;
}

/// The program's default/recommended variant, or null when single-plan
/// (`variants.length <= 1`). Prefers `is_default`, then [defaultVariantId],
/// then the first option.
ProgramVariantOption? defaultProgramVariant(
  List<ProgramVariantOption> variants,
  String? defaultVariantId,
) {
  if (variants.length <= 1) return null;
  return variants.firstWhere(
    (v) => v.isDefault,
    orElse: () => variants.firstWhere(
      (v) => v.variantId == defaultVariantId,
      orElse: () => variants.first,
    ),
  );
}

/// Resolve the currently-selected variant from [selectedVariantId], falling
/// back to the DEFAULT option (never blindly the first / lowest-weeks plan).
ProgramVariantOption? selectedProgramVariant(
  List<ProgramVariantOption> variants,
  String? selectedVariantId,
  String? defaultVariantId,
) {
  if (variants.isEmpty) return null;
  for (final v in variants) {
    if (v.variantId == selectedVariantId) return v;
  }
  return defaultProgramVariant(variants, defaultVariantId) ?? variants.first;
}

class VariantSelectorRow extends StatefulWidget {
  /// All variant rows for the program (assumed length > 1 — single-plan
  /// programs should not render this widget).
  final List<ProgramVariantOption> variants;

  /// The currently-selected variant id (null falls back to the default).
  final String? selectedVariantId;

  /// The program's default variant id — tags the "✓ Recommended" option.
  final String? defaultVariantId;

  /// Optional trailing tile rendered after the two dropdowns (e.g. a static
  /// MINUTES stat). Wrapped in [Expanded] internally to share the row evenly.
  final Widget? trailing;

  /// Called with the resolved variant when the user picks a duration / sessions
  /// / intensity option.
  final ValueChanged<ProgramVariantOption> onSelect;

  /// Called when the user taps "Reset to default" in a picker sheet.
  final VoidCallback onResetToDefault;

  const VariantSelectorRow({
    super.key,
    required this.variants,
    required this.selectedVariantId,
    required this.onSelect,
    required this.onResetToDefault,
    this.defaultVariantId,
    this.trailing,
  });

  @override
  State<VariantSelectorRow> createState() => _VariantSelectorRowState();
}

class _VariantSelectorRowState extends State<VariantSelectorRow> {
  // Precomputed once per variant list (not per picker open).
  late List<int> _distinctWeeks;
  late Map<int, List<int>> _sessionsByWeeks;
  late List<String> _distinctIntensities;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(covariant VariantSelectorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recompute only when the variant SET changes (identity or length); the
    // selected id changing alone never alters the distinct lists.
    if (!identical(oldWidget.variants, widget.variants) ||
        oldWidget.variants.length != widget.variants.length) {
      _recompute();
    }
  }

  void _recompute() {
    final weeks = widget.variants.map((v) => v.weeks).toSet().toList()..sort();
    _distinctWeeks = weeks;
    final map = <int, Set<int>>{};
    for (final v in widget.variants) {
      (map[v.weeks] ??= <int>{}).add(v.sessionsPerWeek);
    }
    _sessionsByWeeks = {
      for (final e in map.entries) e.key: (e.value.toList()..sort()),
    };
    _distinctIntensities = widget.variants
        .map((v) => v.intensity)
        .toSet()
        .toList();
  }

  ProgramVariantOption? get _selected => selectedProgramVariant(
    widget.variants,
    widget.selectedVariantId,
    widget.defaultVariantId,
  );

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final weeksLabel = selected?.weeks.toString() ?? '—';
    final sessionsLabel = selected?.sessionsPerWeek.toString() ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IntrinsicHeight bounds the row so any stretch resolves to the tallest
        // control instead of throwing an infinite-height constraint inside a
        // sliver.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DropdownControl(
                  caption: 'DURATION',
                  value: weeksLabel,
                  unit: 'WK',
                  onTap: _openWeeksPicker,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownControl(
                  caption: 'PER WEEK',
                  value: sessionsLabel,
                  unit: '×',
                  onTap: _openSessionsPicker,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 10),
                Expanded(child: widget.trailing!),
              ],
            ],
          ),
        ),
        if (_distinctIntensities.length > 1) ...[
          const SizedBox(height: 10),
          _IntensityChipRow(
            intensities: _distinctIntensities,
            selectedIntensity: selected?.intensity ?? '',
            onSelect: (intensity) {
              final currentWeeks =
                  selected?.weeks ?? widget.variants.first.weeks;
              final candidate = widget.variants.firstWhere(
                (v) => v.intensity == intensity && v.weeks == currentWeeks,
                orElse: () => widget.variants.firstWhere(
                  (v) => v.intensity == intensity,
                  orElse: () => widget.variants.first,
                ),
              );
              widget.onSelect(candidate);
            },
          ),
        ],
      ],
    );
  }

  void _openWeeksPicker() {
    HapticService.light();
    final selected = _selected;
    final currentSessions =
        selected?.sessionsPerWeek ?? widget.variants.first.sessionsPerWeek;
    final def = defaultProgramVariant(widget.variants, widget.defaultVariantId);

    _showPicker(
      title: 'Program length',
      options: [
        for (final w in _distinctWeeks)
          _PickerOption(
            label: '$w weeks',
            isSelected: selected?.weeks == w,
            isRecommended: def?.weeks == w,
            onTap: () => widget.onSelect(
              resolveProgramVariant(widget.variants, w, currentSessions),
            ),
          ),
      ],
    );
  }

  void _openSessionsPicker() {
    HapticService.light();
    final selected = _selected;
    final currentWeeks = selected?.weeks ?? widget.variants.first.weeks;
    final sessions = _sessionsByWeeks[currentWeeks] ?? const <int>[];
    final def = defaultProgramVariant(widget.variants, widget.defaultVariantId);

    _showPicker(
      title: 'Sessions per week',
      options: [
        for (final s in sessions)
          _PickerOption(
            label: '$s per week',
            isSelected: selected?.sessionsPerWeek == s,
            isRecommended:
                def?.weeks == currentWeeks && def?.sessionsPerWeek == s,
            onTap: () => widget.onSelect(
              resolveProgramVariant(widget.variants, currentWeeks, s),
            ),
          ),
      ],
    );
  }

  /// Shared bottom-sheet shell for the weeks / sessions pickers — a tappable
  /// row per option (✓ Recommended tag on the default) + a "Reset to default".
  void _showPicker({
    required String title,
    required List<_PickerOption> options,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title.toUpperCase(),
                  style: ZType.lbl(
                    12,
                    color: AppColors.textMuted,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                for (final opt in options)
                  _PickerRow(
                    option: opt,
                    onTap: () {
                      opt.onTap();
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    widget.onResetToDefault();
                    Navigator.of(sheetContext).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange,
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset to default'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Dropdown control — the unmistakable "select"-style box used for DURATION and
// PER WEEK. Caption + big value + a full-opacity ▾ chevron; reads clearly as
// "tap to change", distinct from a plain static stat tile.
// ===========================================================================

class _DropdownControl extends StatelessWidget {
  final String caption;
  final String value;
  final String unit;
  final VoidCallback onTap;

  const _DropdownControl({
    required this.caption,
    required this.value,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              style: ZType.lbl(
                10,
                color: AppColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.disp(26, color: AppColors.textPrimary),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: ZType.lbl(
                        10,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Picker option model + row.
// ===========================================================================

class _PickerOption {
  final String label;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PickerOption({
    required this.label,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });
}

class _PickerRow extends StatelessWidget {
  final _PickerOption option;
  final VoidCallback onTap;

  const _PickerRow({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: option.isSelected
              ? AppColors.orange.withValues(alpha: 0.12)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: option.isSelected ? AppColors.orange : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                style: ZType.sans(
                  15,
                  color: AppColors.textPrimary,
                  weight: option.isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (option.isRecommended) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✓ Recommended',
                  style: ZType.lbl(
                    9,
                    color: AppColors.orange,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Icon(
              option.isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: option.isSelected ? AppColors.orange : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Intensity chip row — shown beneath the selector row when there is more than
// one distinct intensity (e.g. Light / Medium / Hard).
// ===========================================================================

class _IntensityChipRow extends StatelessWidget {
  final List<String> intensities;
  final String selectedIntensity;
  final ValueChanged<String> onSelect;

  const _IntensityChipRow({
    required this.intensities,
    required this.selectedIntensity,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'INTENSITY',
          style: ZType.lbl(10, color: AppColors.textMuted, letterSpacing: 1.4),
        ),
        const SizedBox(width: 10),
        Wrap(
          spacing: 8,
          children: intensities.map((intensity) {
            final isSelected = intensity == selectedIntensity;
            return GestureDetector(
              onTap: () => onSelect(intensity),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.orange.withValues(alpha: 0.18)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.orange : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  intensity,
                  style: ZType.sans(
                    12,
                    color: isSelected
                        ? AppColors.orange
                        : AppColors.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
