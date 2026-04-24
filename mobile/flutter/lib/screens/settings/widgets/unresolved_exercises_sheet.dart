/// Single-exercise remediation sheet.
///
/// Shown when the user taps a specific unresolved raw name — lets them pick
/// one of up to 3 resolver suggestions or fall back to a manual search. Keeps
/// the UI simple; the batch flow lives in [unresolved_exercises_bulk_sheet.dart].
library;

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout_import_preview.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

/// The resolution the caller should apply. Returned via [Navigator.pop].
@immutable
class UnresolvedExerciseResolution {
  const UnresolvedExerciseResolution({
    required this.canonicalName,
    this.exerciseId,
  });
  final String canonicalName;
  final String? exerciseId;
}

Future<UnresolvedExerciseResolution?> showUnresolvedExerciseSheet({
  required BuildContext context,
  required UnresolvedGroup group,
  // Hook for the "Search library…" escape hatch. Returns the full mapping
  // the user picked from a library browser, or null if they backed out.
  Future<UnresolvedExerciseResolution?> Function()? onSearchLibrary,
}) async {
  return showGlassSheet<UnresolvedExerciseResolution>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.72,
      child: _SingleResolutionBody(group: group, onSearchLibrary: onSearchLibrary),
    ),
  );
}

class _SingleResolutionBody extends StatefulWidget {
  const _SingleResolutionBody({
    required this.group,
    this.onSearchLibrary,
  });

  final UnresolvedGroup group;
  final Future<UnresolvedExerciseResolution?> Function()? onSearchLibrary;

  @override
  State<_SingleResolutionBody> createState() => _SingleResolutionBodyState();
}

class _SingleResolutionBodyState extends State<_SingleResolutionBody> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final g = widget.group;

    // Pre-fill the custom field with the raw name so the user can quickly
    // accept "as-is" (canonicalize to itself) for unusual/creator exercises.
    if (_customController.text.isEmpty) {
      _customController.text = g.rawName;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Map exercise', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'You imported "${g.rawName}" ${g.rowCount} time${g.rowCount == 1 ? '' : 's'}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (g.suggestions.isNotEmpty) ...[
                    Text('Suggestions', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in g.suggestions)
                          _SuggestionChip(
                            suggestion: s,
                            onTap: () {
                              HapticService.light();
                              Navigator.of(context).pop(
                                UnresolvedExerciseResolution(
                                  canonicalName: s.canonicalName,
                                  exerciseId: s.exerciseId,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No automatic suggestions for this name.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  // Custom / manual entry
                  Text('Or type a canonical name', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.edit_rounded),
                      hintText: 'e.g., Barbell Back Squat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (widget.onSearchLibrary != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        HapticService.light();
                        final res = await widget.onSearchLibrary!();
                        if (res != null && context.mounted) {
                          Navigator.of(context).pop(res);
                        }
                      },
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Search library…'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
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
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () {
                    final name = _customController.text.trim();
                    if (name.isEmpty) return;
                    HapticService.light();
                    Navigator.of(context).pop(
                      UnresolvedExerciseResolution(canonicalName: name),
                    );
                  },
                  child: const Text('Apply mapping'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.suggestion, required this.onTap});
  final UnresolvedSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final pct = (suggestion.confidence * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              suggestion.canonicalName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct% · ${suggestion.source}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
