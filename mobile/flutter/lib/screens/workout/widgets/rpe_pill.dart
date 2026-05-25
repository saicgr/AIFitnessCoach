import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Phase 2.D — RPE pill for set logging.
///
/// Tap to cycle through 6 → 7 → 8 → 9 → 10. Tap-and-hold opens a quick scale
/// picker. Reps in Reserve (RIR) is the inverse: RPE 10 = 0 RIR, RPE 8 = 2 RIR.
/// We surface RPE because that's what the user reports; the backend computes
/// RIR from it and persists both on `set_rep_accuracy`.
///
/// Drives the auto-regulation rules in Phase 2.D:
///   - 3 consecutive RPE ≥ 9 vs target 8 → next set −5%
///   - rolling 7d avg RPE per exercise → next prescription
class RpePill extends StatelessWidget {
  const RpePill({
    super.key,
    required this.value,
    required this.onChanged,
    this.target,
    this.compact = false,
  });

  /// Current RPE (5.0–10.0). Null means user hasn't reported one yet.
  final double? value;

  /// Optional prescribed target (e.g. 8.0). Pill color shifts when value > target.
  final double? target;

  final ValueChanged<double> onChanged;

  /// Smaller variant for crowded set rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null;
    final v = value ?? target ?? 8.0;

    // Color = green at/below target, amber at +1, red at +2.
    final overshoot = target == null ? 0.0 : (v - target!);
    final Color tint = !hasValue
        ? Colors.grey.withOpacity(0.4)
        : overshoot <= 0
            ? const Color(0xFF22C55E)
            : overshoot <= 1
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () => _cycle(),
      onLongPress: () => _picker(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: tint.withOpacity(0.12),
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          border: Border.all(color: tint.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RPE',
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              hasValue ? v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1) : '–',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cycle() {
    final cur = value ?? 7;
    // 6 → 7 → 7.5 → 8 → 8.5 → 9 → 9.5 → 10 → 6
    const steps = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];
    final idx = steps.indexWhere((s) => (s - cur).abs() < 0.01);
    final next = steps[(idx + 1) % steps.length];
    onChanged(next);
  }

  Future<void> _picker(BuildContext context) async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RpePicker(initial: value ?? target ?? 8.0),
    );
    if (picked != null) onChanged(picked);
  }
}

class _RpePicker extends StatefulWidget {
  const _RpePicker({required this.initial});
  final double initial;

  @override
  State<_RpePicker> createState() => _RpePickerState();
}

class _RpePickerState extends State<_RpePicker> {
  late double _selected;

  static const _grid = [
    [6.0, 6.5, 7.0],
    [7.5, 8.0, 8.5],
    [9.0, 9.5, 10.0],
  ];

  // Note: const-map keys can't be `double` (overrides ==/hashCode). Use a
  // lookup function instead — same shape, runtime cost is negligible.
  static String _hintFor(double rpe) {
    if (rpe <= 6.0) return 'Very light';
    if (rpe <= 6.5) return 'Light';
    if (rpe <= 7.0) return 'Easy';
    if (rpe <= 7.5) return 'Moderate';
    if (rpe <= 8.0) return '2 reps left';
    if (rpe <= 8.5) return '1–2 reps left';
    if (rpe <= 9.0) return '1 rep left';
    if (rpe <= 9.5) return 'Just made it';
    return 'Failure';
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalizations.of(context).rpePillRpeRateOfPerceived,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hintFor(_selected),
              style: TextStyle(
                fontSize: 13,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 12),
            for (final row in _grid)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((rpe) {
                    final selected = (rpe - _selected).abs() < 0.01;
                    return ChoiceChip(
                      label: Text(
                        rpe.toStringAsFixed(rpe == rpe.roundToDouble() ? 0 : 1),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => _selected = rpe),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: Text(AppLocalizations.of(context).buttonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
