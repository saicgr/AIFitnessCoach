/// Preview bottom-sheet for the cross-app nutrition importer.
///
/// Shows the dry-run result from `GET /nutrition/import/{job_id}` (the
/// `preview` block) so the user can eyeball the entry count, date range,
/// a handful of sample rows, and — when relevant — choose how to handle
/// dates that already have logged meals and whether to also pull in
/// body-weight rows, BEFORE the irreversible commit.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

/// Parsed view of the backend `preview` payload. Defensive against missing /
/// null keys — a partial preview should still render rather than crash.
class NutritionImportPreview {
  const NutritionImportPreview({
    required this.count,
    required this.days,
    required this.dateRangeLo,
    required this.dateRangeHi,
    required this.sampleRows,
    required this.unmappedColumns,
    required this.overlapDays,
    required this.weightRows,
    required this.unreadableRows,
  });

  final int count;
  final int days;
  final String? dateRangeLo;
  final String? dateRangeHi;
  final List<Map<String, dynamic>> sampleRows;
  final List<String> unmappedColumns;
  final int overlapDays;
  final int weightRows;
  final int unreadableRows;

  bool get hasOverlap => overlapDays > 0;
  bool get hasWeight => weightRows > 0;
  bool get hasUnmapped => unmappedColumns.isNotEmpty;
  bool get hasRows => count > 0;

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  factory NutritionImportPreview.fromJson(Map<String, dynamic> json) {
    final range = (json['date_range'] as List?) ?? const [];
    final rawSamples = (json['sample_rows'] as List?) ?? const [];
    return NutritionImportPreview(
      count: _asInt(json['count']),
      days: _asInt(json['days']),
      dateRangeLo: range.isNotEmpty ? range[0]?.toString() : null,
      dateRangeHi: range.length > 1 ? range[1]?.toString() : null,
      sampleRows: [
        for (final r in rawSamples)
          if (r is Map) r.map((k, v) => MapEntry(k.toString(), v)),
      ],
      unmappedColumns: [
        for (final c in (json['unmapped_columns'] as List?) ?? const [])
          c.toString(),
      ],
      overlapDays: _asInt(json['overlap_days']),
      weightRows: _asInt(json['weight_rows']),
      unreadableRows: _asInt(json['unreadable_rows']),
    );
  }
}

/// The user's confirmed import choices, returned via [Navigator.pop].
class NutritionImportChoice {
  const NutritionImportChoice({
    required this.overlapStrategy,
    required this.includeWeight,
  });

  /// One of `skip` | `merge` | `replace`.
  final String overlapStrategy;
  final bool includeWeight;
}

/// Show the preview sheet. Returns the chosen [NutritionImportChoice] when the
/// user confirms, or `null` on cancel / dismissal.
Future<NutritionImportChoice?> showNutritionImportPreviewSheet({
  required BuildContext context,
  required NutritionImportPreview preview,
  required String sourceLabel,
}) {
  return showGlassSheet<NutritionImportChoice>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.92,
      child: _PreviewSheetBody(preview: preview, sourceLabel: sourceLabel),
    ),
  );
}

class _PreviewSheetBody extends StatefulWidget {
  const _PreviewSheetBody({required this.preview, required this.sourceLabel});

  final NutritionImportPreview preview;
  final String sourceLabel;

  @override
  State<_PreviewSheetBody> createState() => _PreviewSheetBodyState();
}

class _PreviewSheetBodyState extends State<_PreviewSheetBody> {
  // Default to the safest strategy — never silently overwrite existing logs.
  String _overlapStrategy = 'skip';
  late bool _includeWeight = widget.preview.hasWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;
    final preview = widget.preview;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header ----------------------------------------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.restaurant_menu_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preview import', style: theme.textTheme.titleLarge),
                    Text(
                      'From ${widget.sourceLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: onSurfaceVar),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scrollable body -------------------------------------------
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeadlineBanner(preview: preview, accent: accent, isDark: isDark),
                  const SizedBox(height: 16),
                  if (preview.unreadableRows > 0) ...[
                    _SkippedRowsNote(count: preview.unreadableRows),
                    const SizedBox(height: 16),
                  ],
                  _SampleRowsBlock(sampleRows: preview.sampleRows),
                  if (preview.hasOverlap) ...[
                    const SizedBox(height: 20),
                    _OverlapControl(
                      overlapDays: preview.overlapDays,
                      selected: _overlapStrategy,
                      accent: accent,
                      onChanged: (v) => setState(() => _overlapStrategy = v),
                    ),
                  ],
                  if (preview.hasWeight) ...[
                    const SizedBox(height: 16),
                    _WeightSwitch(
                      weightRows: preview.weightRows,
                      value: _includeWeight,
                      accent: accent,
                      onChanged: (v) => setState(() => _includeWeight = v),
                    ),
                  ],
                  if (preview.hasUnmapped) ...[
                    const SizedBox(height: 16),
                    _UnmappedNote(columns: preview.unmappedColumns),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          _ActionRow(
            accent: accent,
            canConfirm: preview.hasRows || (preview.hasWeight && _includeWeight),
            onConfirm: () {
              HapticService.light();
              Navigator.of(context).pop(
                NutritionImportChoice(
                  overlapStrategy: _overlapStrategy,
                  includeWeight: preview.hasWeight && _includeWeight,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeadlineBanner extends StatelessWidget {
  const _HeadlineBanner({
    required this.preview,
    required this.accent,
    required this.isDark,
  });

  final NutritionImportPreview preview;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = accent.withValues(alpha: isDark ? 0.10 : 0.08);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${preview.count} ${preview.count == 1 ? 'entry' : 'entries'} · '
                  '${preview.days} ${preview.days == 1 ? 'day' : 'days'}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (preview.dateRangeLo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatRange(preview.dateRangeLo, preview.dateRangeHi),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRange(String? lo, String? hi) {
    if (lo == null) return '';
    if (hi == null || hi == lo) return lo;
    return '$lo → $hi';
  }
}

class _SampleRowsBlock extends StatelessWidget {
  const _SampleRowsBlock({required this.sampleRows});
  final List<Map<String, dynamic>> sampleRows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sampleRows.isEmpty) {
      return Text(
        'No sample rows to preview.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sample entries', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < sampleRows.take(8).length; i++)
                _SampleRow(
                  row: sampleRows[i],
                  isLast: i == sampleRows.take(8).length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SampleRow extends StatelessWidget {
  const _SampleRow({required this.row, required this.isLast});
  final Map<String, dynamic> row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;
    final date = '${row['date'] ?? ''}';
    final meal = '${row['meal'] ?? ''}';
    final calories = row['calories'];
    final items = '${row['items'] ?? ''}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (date.isNotEmpty)
                      Text(date, style: theme.textTheme.labelMedium),
                    if (date.isNotEmpty && meal.isNotEmpty)
                      Text('  ·  ',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: onSurfaceVar)),
                    if (meal.isNotEmpty)
                      Text(
                        meal,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: onSurfaceVar),
                      ),
                  ],
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    items,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVar),
                  ),
                ],
              ],
            ),
          ),
          if (calories != null) ...[
            const SizedBox(width: 10),
            Text(
              '${_asInt(calories)} kcal',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse('${v ?? ''}') ?? 0;
  }
}

class _OverlapControl extends StatelessWidget {
  const _OverlapControl({
    required this.overlapDays,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final int overlapDays;
  final String selected;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;
    const options = <(String, String, String)>[
      ('skip', 'Keep mine', 'Leave those days as they are'),
      ('merge', 'Add both', 'Append imported meals alongside yours'),
      ('replace', 'Use imported', 'Replace my meals on those days'),
    ];
    final selectedDesc =
        options.firstWhere((o) => o.$1 == selected, orElse: () => options.first).$3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.layers_rounded, size: 18, color: onSurfaceVar),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$overlapDays ${overlapDays == 1 ? 'day already has' : 'days already have'} logged meals',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Segmented selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final o in options)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticService.light();
                      onChanged(o.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selected == o.$1 ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        o.$2,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected == o.$1
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          selectedDesc,
          style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVar),
        ),
      ],
    );
  }
}

class _WeightSwitch extends StatelessWidget {
  const _WeightSwitch({
    required this.weightRows,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final int weightRows;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_outlined,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Also import weight ($weightRows ${weightRows == 1 ? 'entry' : 'entries'})',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: accent,
            onChanged: (v) {
              HapticService.light();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _SkippedRowsNote extends StatelessWidget {
  const _SkippedRowsNote({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = Colors.amber.shade700;
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: warn),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'row' : 'rows'} couldn\'t be read and will be skipped',
            style: theme.textTheme.bodySmall?.copyWith(color: warn),
          ),
        ),
      ],
    );
  }
}

class _UnmappedNote extends StatelessWidget {
  const _UnmappedNote({required this.columns});
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;
    final capped = columns.take(6).toList();
    final more = columns.length - capped.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${columns.length} ${columns.length == 1 ? 'column' : 'columns'} ignored',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: onSurfaceVar, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in capped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(c, style: theme.textTheme.labelSmall),
              ),
            if (more > 0)
              Text('+$more more',
                  style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVar)),
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.accent,
    required this.canConfirm,
    required this.onConfirm,
  });
  final Color accent;
  final bool canConfirm;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticService.light();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: canConfirm ? onConfirm : null,
            style: FilledButton.styleFrom(backgroundColor: accent),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Import'),
          ),
        ),
      ],
    );
  }
}
