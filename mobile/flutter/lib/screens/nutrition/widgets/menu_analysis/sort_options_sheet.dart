import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sort_spec.dart';
import '../../../../widgets/glass_sheet.dart' show GlassSheet, showGlassSheet;

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
    // Opaque sheet + stronger scrim. The Menu Analysis sheet that opens this
    // sheet is itself a translucent glass sheet — without an opaque surface
    // here, the menu cards underneath bled through the sort UI and the user
    // saw both stacked on top of each other.
    return showGlassSheet<SortSpecList>(
      context: context,
      opaque: true,
      builder: (_) => GlassSheet(
        opaque: true,
        showHandle: true,
        child: SortOptionsSheet(initial: initial),
      ),
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
        // Tap on an active row deselects. Reorder priority is handled by
        // the drag handle, not by re-tapping (the prior "promote on tap"
        // behaviour confused users — the checkmark looked like a toggle).
        _sort = _sort.remove(field);
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

    // Build a single ordered list: active fields in rank order first, then
    // inactive fields in their declaration order. One list ⇒ no duplicate
    // top section, ⇒ tapping any row toggles in place.
    final activeFields =
        _sort.specs.map((s) => s.field).toList(growable: false);
    final inactiveFields = SortField.values
        .where((f) => !activeFields.contains(f))
        .toList(growable: false);
    final orderedFields = <SortField>[...activeFields, ...inactiveFields];
    final activeCount = activeFields.length;

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
                const SizedBox(width: 8),
                Text(
                  '$activeCount/$kMaxSortDepth',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
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

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _sort.isEmpty
                    ? 'Tap a field to sort by it.'
                    : 'Tap to add or remove. Drag the handle to reorder priority.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          // ── Unified field list ──
          // Active items render first with rank/direction/drag-handle; the
          // rest follow as plain rows. ReorderableListView lets the user
          // reprioritise active rows by dragging the handle; reorders that
          // would cross into the inactive partition are clamped.
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: orderedFields.length,
              onReorder: (oldIndex, newIndex) {
                // Clamp into the active range: drag handles are only shown
                // on active rows, but the listview itself doesn't know that.
                if (oldIndex >= activeCount) return;
                final clampedNew = newIndex > activeCount
                    ? activeCount
                    : newIndex;
                if (clampedNew == oldIndex || clampedNew == oldIndex + 1) {
                  return;
                }
                _reorder(oldIndex, clampedNew);
              },
              itemBuilder: (context, index) {
                final field = orderedFields[index];
                final isActive = index < activeCount;
                final spec = isActive ? _sort.specs[index] : null;
                final atCapacity =
                    !isActive && activeCount >= kMaxSortDepth;
                return _UnifiedFieldTile(
                  key: ValueKey('field_${field.name}'),
                  field: field,
                  isActive: isActive,
                  rank: isActive ? index + 1 : null,
                  direction: spec?.direction,
                  disabled: atCapacity,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  onTap: atCapacity ? null : () => _toggleField(field),
                  onFlip: isActive ? () => _flipDirection(field) : null,
                  onRemove: isActive ? () => _remove(field) : null,
                  dragHandle: isActive
                      ? ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_handle,
                              size: 20, color: textMuted),
                        )
                      : null,
                );
              },
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

/// One row that handles every state — selected (with rank, direction
/// toggle, drag handle, deselect tap target) and unselected (plain field
/// tappable to add). Replaces the prior split _ActiveSortTile/_FieldTile
/// where the same field could appear twice and the checkmark wasn't a
/// deselect affordance.
class _UnifiedFieldTile extends StatelessWidget {
  final SortField field;
  final bool isActive;
  final int? rank;
  final SortDirection? direction;
  final bool disabled;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback? onTap;
  final VoidCallback? onFlip;
  final VoidCallback? onRemove;
  final Widget? dragHandle;

  const _UnifiedFieldTile({
    super.key,
    required this.field,
    required this.isActive,
    required this.rank,
    required this.direction,
    required this.disabled,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
    required this.onFlip,
    required this.onRemove,
    required this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      final isAsc = direction == SortDirection.asc;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap, // Tap row body → deselect.
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      '${rank ?? 1}',
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
                      field.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  // Direction toggle (independent tap target).
                  InkWell(
                    onTap: onFlip,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                  // Explicit deselect (in addition to tapping the row).
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(Icons.check_circle,
                        color: AppColors.orange, size: 22),
                    padding: EdgeInsets.zero,
                    tooltip: 'Remove from sort',
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                  if (dragHandle != null) ...[
                    const SizedBox(width: 2),
                    dragHandle!,
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Inactive row: plain, tap to add.
    final labelColor = disabled
        ? textMuted.withValues(alpha: 0.5)
        : textPrimary;
    return ListTile(
      dense: true,
      onTap: onTap,
      enabled: !disabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        field.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: labelColor,
        ),
      ),
      trailing: disabled
          ? null
          : Icon(Icons.add_circle_outline,
              color: textMuted.withValues(alpha: 0.7), size: 20),
    );
  }
}
