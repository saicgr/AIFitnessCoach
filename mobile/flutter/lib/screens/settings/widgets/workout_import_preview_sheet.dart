/// Preview bottom-sheet for file-based workout history import.
///
/// Shows the dry-run result from `POST /workout-history/import/preview` so the
/// user can eyeball the detected source app, row counts, sample rows, and
/// unresolved exercises BEFORE they confirm the async import.
library;

import 'package:flutter/material.dart';

import '../../../data/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout_import_preview.dart';
import '../../../widgets/glass_sheet.dart';

/// Result returned by the preview sheet via [Navigator.pop].
class WorkoutImportPreviewAction {
  const WorkoutImportPreviewAction._(this.confirmed);
  final bool confirmed;
  static const confirm = WorkoutImportPreviewAction._(true);
  static const cancel = WorkoutImportPreviewAction._(false);
}

/// Show the preview sheet. Returns `true` when the user hits "Looks right —
/// Import", `false` / null on dismissal or cancel.
Future<bool> showWorkoutImportPreviewSheet({
  required BuildContext context,
  required WorkoutImportPreview preview,
  required String filename,
}) async {
  final result = await showGlassSheet<WorkoutImportPreviewAction>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.92,
      child: _PreviewSheetBody(preview: preview, filename: filename),
    ),
  );
  return result?.confirmed ?? false;
}

class _PreviewSheetBody extends StatelessWidget {
  const _PreviewSheetBody({required this.preview, required this.filename});

  final WorkoutImportPreview preview;
  final String filename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header --------------------------------------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.insights_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preview import', style: theme.textTheme.titleLarge),
                    Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVar),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () =>
                    Navigator.of(context).pop(WorkoutImportPreviewAction.cancel),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scrollable body ---------------------------------------
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetectionBanner(preview: preview, accent: accent, isDark: isDark),
                  const SizedBox(height: 16),
                  _RowCountRow(preview: preview, accent: accent),
                  if (preview.warnings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _WarningsBlock(warnings: preview.warnings),
                  ],
                  if (preview.unresolvedExercises.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _UnresolvedBlock(names: preview.unresolvedExercises),
                  ],
                  const SizedBox(height: 16),
                  _SampleRowsBlock(sampleRows: preview.sampleRows),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          _ActionRow(accent: accent, canConfirm: preview.hasAnyRows || preview.hasTemplate),
        ],
      ),
    );
  }
}

class _DetectionBanner extends StatelessWidget {
  const _DetectionBanner({required this.preview, required this.accent, required this.isDark});

  final WorkoutImportPreview preview;
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
                  _formatSourceApp(preview.sourceApp),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mode: ${_formatMode(preview.mode)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _ConfidencePill(percent: preview.confidencePercent, accent: accent),
        ],
      ),
    );
  }

  static String _formatSourceApp(String slug) {
    if (slug.isEmpty || slug == 'unknown') return 'Unknown source';
    // Nippard_powerbuilding_v3 → Nippard Powerbuilding V3
    return slug
        .split('_')
        .map((part) => part.isEmpty
            ? ''
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _formatMode(String mode) {
    switch (mode) {
      case 'history':
        return 'Strength history';
      case 'template':
        return 'Creator program template';
      case 'program_with_filled_history':
        return 'Program + filled history';
      case 'cardio_only':
        return 'Cardio sessions';
      case 'ambiguous':
        return 'Mixed / ambiguous';
    }
    return mode;
  }
}

class _ConfidencePill extends StatelessWidget {
  const _ConfidencePill({required this.percent, required this.accent});
  final int percent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$percent%',
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RowCountRow extends StatelessWidget {
  const _RowCountRow({required this.preview, required this.accent});

  final WorkoutImportPreview preview;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'Strength rows',
          value: preview.strengthRowCount.toString(),
          icon: Icons.fitness_center_rounded,
          accent: accent,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'Cardio rows',
          value: preview.cardioRowCount.toString(),
          icon: Icons.directions_run_rounded,
          accent: accent,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'Template',
          value: preview.hasTemplate ? 'Yes' : 'No',
          icon: Icons.event_note_rounded,
          accent: accent,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningsBlock extends StatelessWidget {
  const _WarningsBlock({required this.warnings});
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = Colors.amber.shade700;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warn.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: warn, size: 18),
              const SizedBox(width: 8),
              Text(
                'Heads up',
                style: theme.textTheme.titleSmall?.copyWith(color: warn),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...warnings.map((w) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('•  $w', style: theme.textTheme.bodySmall),
              )),
        ],
      ),
    );
  }
}

class _UnresolvedBlock extends StatelessWidget {
  const _UnresolvedBlock({required this.names});
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Cap the displayed list — the full list lives in the summary sheet.
    final capped = names.take(10).toList();
    final more = names.length - capped.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline_rounded, size: 18),
            const SizedBox(width: 6),
            Text('Unmatched exercises', style: theme.textTheme.titleSmall),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${names.length}',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'These will still import — you can map them to canonical names after the job finishes.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final n in capped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(n, style: theme.textTheme.labelMedium),
              ),
            if (more > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('+$more more', style: theme.textTheme.labelMedium),
              ),
          ],
        ),
      ],
    );
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
        'No sample rows produced (the file may be empty or unrecognised).',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Collect column keys from the first few rows so heterogeneous adapters
    // (cardio+strength in one preview) don't blow up the table layout.
    final keys = <String>{};
    for (final row in sampleRows.take(5)) {
      keys.addAll(row.keys);
    }
    final columns = keys.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sample rows', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                columns: [for (final k in columns) DataColumn(label: Text(k))],
                rows: [
                  for (final r in sampleRows.take(20))
                    DataRow(cells: [
                      for (final k in columns)
                        DataCell(Text(
                          _stringify(r[k]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall,
                        )),
                    ]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _stringify(dynamic v) {
    if (v == null) return '—';
    if (v is num) return v.toString();
    if (v is String) return v;
    return v.toString();
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.accent, required this.canConfirm});
  final Color accent;
  final bool canConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticService.light();
              Navigator.of(context).pop(WorkoutImportPreviewAction.cancel);
            },
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: canConfirm
                ? () {
                    HapticService.light();
                    Navigator.of(context).pop(WorkoutImportPreviewAction.confirm);
                  }
                : null,
            style: FilledButton.styleFrom(backgroundColor: accent),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Looks right — Import'),
          ),
        ),
      ],
    );
  }
}
