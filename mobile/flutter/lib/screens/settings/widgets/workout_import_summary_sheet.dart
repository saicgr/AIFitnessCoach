/// Post-completion summary bottom-sheet for workout-history file imports.
///
/// Shown once [WorkoutImportJob] reaches `completed`. Surfaces:
///   • imported strength + cardio counts (with duplicates-skipped)
///   • unresolved exercises with a "Fix these" CTA into the bulk-remap sheet
///   • creator program template (if the file contained one), with an
///     "Activate program" toggle
///   • warnings from the importer
library;

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout_import_job.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

/// Caller-side summary action — what the user decided once the summary sheet
/// closed. Consumers typically use [fixUnresolved] to launch the bulk-remap
/// sheet, and [activateTemplate] to kick off program activation.
@immutable
class WorkoutImportSummaryResult {
  const WorkoutImportSummaryResult({
    this.fixUnresolved = false,
    this.activateTemplate = false,
  });
  final bool fixUnresolved;
  final bool activateTemplate;
}

Future<WorkoutImportSummaryResult?> showWorkoutImportSummarySheet({
  required BuildContext context,
  required WorkoutImportJob job,
}) async {
  return showGlassSheet<WorkoutImportSummaryResult>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.9,
      child: _SummaryBody(job: job),
    ),
  );
}

class _SummaryBody extends StatefulWidget {
  const _SummaryBody({required this.job});
  final WorkoutImportJob job;

  @override
  State<_SummaryBody> createState() => _SummaryBodyState();
}

class _SummaryBodyState extends State<_SummaryBody> {
  bool _activate = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final job = widget.job;

    final failed = job.status == WorkoutImportJobStatus.failed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header -------------------------------------------------
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (failed ? Colors.red : Colors.green).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  failed
                      ? Icons.error_outline_rounded
                      : Icons.celebration_rounded,
                  color: failed ? Colors.red : Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      failed ? 'Import failed' : 'Import complete',
                      style: theme.textTheme.titleLarge,
                    ),
                    if (job.sourceApp != null && job.sourceApp!.isNotEmpty)
                      Text(
                        'Source: ${_formatSource(job.sourceApp!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
          const SizedBox(height: 12),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (failed) _FailureBlock(job: job) else _SuccessSummary(job: job, accent: accent),
                  if (job.unresolvedExercises.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _UnresolvedSection(
                      names: job.unresolvedExercises,
                      onFix: () {
                        HapticService.light();
                        Navigator.of(context).pop(
                          const WorkoutImportSummaryResult(fixUnresolved: true),
                        );
                      },
                    ),
                  ],
                  if (!failed && job.templateId != null) ...[
                    const SizedBox(height: 18),
                    _TemplateSection(
                      templateId: job.templateId!,
                      activate: _activate,
                      onChanged: (v) => setState(() => _activate = v),
                      accent: accent,
                    ),
                  ],
                  if (job.warnings.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _WarningsBlock(warnings: job.warnings),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: () {
                HapticService.light();
                Navigator.of(context).pop(
                  WorkoutImportSummaryResult(activateTemplate: _activate),
                );
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatSource(String slug) => slug
      .split('_')
      .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}

class _SuccessSummary extends StatelessWidget {
  const _SuccessSummary({required this.job, required this.accent});
  final WorkoutImportJob job;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _SummaryTile(
            icon: Icons.fitness_center_rounded,
            value: '${job.insertedStrengthRows}',
            label: 'Strength sets added',
            accent: accent,
          ),
          const SizedBox(width: 10),
          _SummaryTile(
            icon: Icons.directions_run_rounded,
            value: '${job.insertedCardioRows}',
            label: 'Cardio sessions added',
            accent: accent,
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _SummaryTile(
            icon: Icons.repeat_rounded,
            value:
                '${job.duplicateStrengthRows + job.duplicateCardioRows}',
            label: 'Duplicates skipped',
            accent: accent,
          ),
          const SizedBox(width: 10),
          _SummaryTile(
            icon: Icons.event_note_rounded,
            value: job.templateId != null ? 'Yes' : 'No',
            label: 'Program template',
            accent: accent,
          ),
        ]),
        const SizedBox(height: 12),
        Text(
          'Weight suggestions across the app will start reflecting this history within a minute.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
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

class _FailureBlock extends StatelessWidget {
  const _FailureBlock({required this.job});
  final WorkoutImportJob job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "We couldn't finish your import.",
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            job.errorMessage ?? 'Unknown error — please try again or contact support.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _UnresolvedSection extends StatelessWidget {
  const _UnresolvedSection({required this.names, required this.onFix});
  final List<String> names;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = names.take(8).toList();
    final more = names.length - preview.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, size: 18),
              const SizedBox(width: 6),
              Text(
                '${names.length} unresolved exercise${names.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onFix,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Fix these'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'These rows were imported but aren\'t matched to a library exercise yet. Mapping them improves weight suggestions + charts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in preview)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
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
      ),
    );
  }
}

class _TemplateSection extends StatelessWidget {
  const _TemplateSection({
    required this.templateId,
    required this.activate,
    required this.onChanged,
    required this.accent,
  });

  final String templateId;
  final bool activate;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Creator program detected',
                    style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'We parsed a multi-week program template. Activating it will schedule its workouts starting next Monday.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: activate,
            onChanged: (v) {
              HapticService.light();
              onChanged(v);
            },
            title: const Text('Activate program'),
            activeThumbColor: accent,
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Warnings', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        for (final w in warnings)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('•  $w', style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}
