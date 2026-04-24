import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sort_spec.dart';
import '../../../../widgets/glass_sheet.dart';

/// Bottom sheet for configuring the Menu Analysis multi-sort.
///
/// Replaces the old inline strip of 8+ sort pills with a single full-height
/// sheet that (a) scales to new health-signal sort dimensions without
/// cramping the header, and (b) makes the 3-level multi-sort legible — the
/// ranked list at the top shows exactly what "Cheap AND high-protein"
/// means in ORDER BY terms.
///
/// UX contract:
///  • Top section = active sort stack (1..3 entries). Each entry has a rank
///    badge, field label, a direction toggle, and a remove button.
///  • Bottom section = all available sort fields. Tapping an inactive
///    field appends it as the next tiebreaker (up to [kMaxSortDepth]).
///    Tapping an already-active field promotes it to primary.
///  • Footer = "Clear all" and "Done" actions. Done pops with the current
///    SortSpecList; Cancel (swipe-down) pops with null.
class SortOptionsSheet extends StatefulWidget {
  final SortSpecList initial;

  const SortOptionsSheet({super.key, required this.initial});

  static Future<SortSpecList?> show(
    BuildContext context, {
    required SortSpecList initial,
  }) {
    return showGlassSheet<SortSpecList>(
      context: context,
      builder: (_) => SortOptionsSheet(initial: initial),
    );
  }

  @override
  State<SortOptionsSheet> createState() => _SortOptionsSheetState();
}

class _SortOptionsSheetState extends State<SortOptionsSheet> {
  late SortSpecList _sort;

  @override
  void initState() {
    super.initState();
    _sort = widget.initial;
  }

  void _flipDirection(SortField field) {
    HapticFeedback.selectionClick();
    final current = _sort.directionOf(field);
    if (current == null) return;
    setState(() {
      _sort = SortSpecList(
        _sort.specs
            .map((s) => s.field == field
                ? s.copyWith(direction: current.reversed)
                : s)
            .toList(),
      );
    });
  }

  void _toggleField(SortField field) {
    HapticFeedback.selectionClick();
    final active = _sort.directionOf(field) != null;
    setState(() {
      if (active) {
        // Promote existing entry to primary.
        _sort = _sort.promote(field);
      } else {
        // Append as tiebreaker (no-op if list is already at max depth).
        _sort = _sort.addTiebreaker(field);
      }
    });
  }

  void _remove(SortField field) {
    HapticFeedback.lightImpact();
    setState(() => _sort = _sort.remove(field));
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() => _sort = SortSpecList.empty);
  }

  void _reorder(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() => _sort = _sort.reorder(oldIndex, newIndex));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted =
        isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black54;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.sort_rounded, color: textPrimary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Sort menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                if (!_sort.isEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Active sort stack ──
          if (!_sort.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort order (up to $kMaxSortDepth)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Keep the reorder list small so it doesn't steal space from the
            // field-picker below on short screens.
            SizedBox(
              // Max height = 3 rows × 56pt + slack. Constrains ReorderableListView
              // (which wants unbounded height by default) without needing
              // Expanded; the inactive field picker below stays scrollable.
              height: (_sort.specs.length * 56.0) + 8,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _sort.specs.length,
                onReorder: _reorder,
                itemBuilder: (context, index) {
                  final spec = _sort.specs[index];
                  return _ActiveSortTile(
                    key: ValueKey('active_${spec.field.name}'),
                    rank: index + 1,
                    spec: spec,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onFlip: () => _flipDirection(spec.field),
                    onRemove: () => _remove(spec.field),
                    dragHandle: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle,
                          size: 20, color: textMuted),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ],

          // ── Available fields ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _sort.isEmpty ? 'Sort by' : 'Add tiebreaker',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: SortField.values.map((field) {
                final active = _sort.directionOf(field) != null;
                final atCapacity =
                    !active && _sort.specs.length >= kMaxSortDepth;
                return _FieldTile(
                  field: field,
                  active: active,
                  disabled: atCapacity,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  onTap: atCapacity ? null : () => _toggleField(field),
                );
              }).toList(),
            ),
          ),

          // ── Done ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_sort),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSortTile extends StatelessWidget {
  final int rank;
  final SortSpec spec;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onFlip;
  final VoidCallback onRemove;
  final Widget dragHandle;

  const _ActiveSortTile({
    super.key,
    required this.rank,
    required this.spec,
    required this.textPrimary,
    required this.textMuted,
    required this.onFlip,
    required this.onRemove,
    required this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final isAsc = spec.direction == SortDirection.asc;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge (1, 2, 3).
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              spec.field.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          // Direction toggle.
          InkWell(
            onTap: onFlip,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAsc
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAsc ? 'Low → High' : 'High → Low',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
            splashRadius: 16,
          ),
          const SizedBox(width: 2),
          dragHandle,
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final SortField field;
  final bool active;
  final bool disabled;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback? onTap;

  const _FieldTile({
    required this.field,
    required this.active,
    required this.disabled,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = disabled
        ? textMuted.withValues(alpha: 0.5)
        : (active ? AppColors.orange : textPrimary);
    return ListTile(
      dense: true,
      onTap: onTap,
      enabled: !disabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        field.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: labelColor,
        ),
      ),
      trailing: active
          ? Icon(Icons.check_circle, color: AppColors.orange, size: 20)
          : (disabled
              ? null
              : Icon(Icons.add_circle_outline,
                  color: textMuted.withValues(alpha: 0.7), size: 20)),
    );
  }
}
