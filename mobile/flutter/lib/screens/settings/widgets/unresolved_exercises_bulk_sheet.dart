/// Full-height bulk sheet for resolving every unresolved raw exercise name.
///
/// Lists each unresolved group returned by
/// `GET /workout-history/unresolved/{user_id}`. Each row shows the raw name,
/// how many imports used it, and the top resolver suggestion as an inline
/// primary chip. Tapping "Fix" opens [showUnresolvedExerciseSheet] for
/// detailed remediation; the "Undo" pill restores the previous mapping via
/// the audit_id returned by the last remap.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout_import_preview.dart';
import '../../../data/repositories/workout_history_import_file_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import 'unresolved_exercises_sheet.dart';

Future<void> showUnresolvedExercisesBulkSheet({
  required BuildContext context,
  required WorkoutHistoryImportFileRepository repository,
  required String userId,
  Future<UnresolvedExerciseResolution?> Function(BuildContext, UnresolvedGroup)?
      onSearchLibrary,
}) async {
  await showGlassSheet<void>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.95,
      child: _BulkBody(
        repository: repository,
        userId: userId,
        onSearchLibrary: onSearchLibrary,
      ),
    ),
  );
}

class _BulkBody extends StatefulWidget {
  const _BulkBody({
    required this.repository,
    required this.userId,
    this.onSearchLibrary,
  });

  final WorkoutHistoryImportFileRepository repository;
  final String userId;
  final Future<UnresolvedExerciseResolution?> Function(
      BuildContext, UnresolvedGroup)? onSearchLibrary;

  @override
  State<_BulkBody> createState() => _BulkBodyState();
}

class _BulkBodyState extends State<_BulkBody> {
  late Future<List<UnresolvedGroup>> _future;
  // audit_id of the LAST remap — used by the undo button. Only the most
  // recent remap is one-tap undoable; historical undo requires Settings.
  String? _lastAuditId;
  String? _lastMappedRawName;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getUnresolved(userId: widget.userId);
  }

  void _refresh() {
    setState(() {
      _future = widget.repository.getUnresolved(userId: widget.userId);
    });
  }

  Future<void> _applyRemap({
    required UnresolvedGroup group,
    required UnresolvedExerciseResolution resolution,
  }) async {
    try {
      final result = await widget.repository.remap(
        userId: widget.userId,
        rawName: group.rawName,
        canonicalName: resolution.canonicalName,
        exerciseId: resolution.exerciseId,
        sourceApp: group.sourceApps.isNotEmpty ? group.sourceApps.first : null,
      );
      if (!mounted) return;
      _lastAuditId = result.auditId;
      _lastMappedRawName = group.rawName;
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mapped ${result.rowsAffected} rows to "${resolution.canonicalName}".',
          ),
          action: result.auditId.isNotEmpty
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: () => _undo(result.auditId),
                )
              : null,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remap failed: $e')),
      );
    }
  }

  Future<void> _undo(String auditId) async {
    try {
      final res = await widget.repository.undoRemap(auditId);
      if (!mounted) return;
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reverted ${res.rowsAffected} rows.')),
      );
      _lastAuditId = null;
      _lastMappedRawName = null;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Undo failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fix unresolved exercises',
                        style: theme.textTheme.titleLarge),
                    Text(
                      'Map raw names from your imports to library exercises.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_lastAuditId != null && _lastAuditId!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _undo(_lastAuditId!),
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: Text(
                    'Undo "${_lastMappedRawName ?? ''}"',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: FutureBuilder<List<UnresolvedGroup>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 40),
                        const SizedBox(height: 8),
                        Text('Could not load: ${snap.error}'),
                        const SizedBox(height: 8),
                        FilledButton(
                          style:
                              FilledButton.styleFrom(backgroundColor: accent),
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final groups = snap.data ?? const <UnresolvedGroup>[];
                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green.shade600, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Nothing to fix — every imported exercise is mapped!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _GroupTile(
                    group: groups[i],
                    onApply: (res) => _applyRemap(group: groups[i], resolution: res),
                    onOpenDetail: () async {
                      final res = await showUnresolvedExerciseSheet(
                        context: context,
                        group: groups[i],
                        onSearchLibrary: widget.onSearchLibrary == null
                            ? null
                            : () => widget.onSearchLibrary!(context, groups[i]),
                      );
                      if (res != null) {
                        await _applyRemap(group: groups[i], resolution: res);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.onApply,
    required this.onOpenDetail,
  });

  final UnresolvedGroup group;
  final Future<void> Function(UnresolvedExerciseResolution) onApply;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final top = group.suggestions.isNotEmpty ? group.suggestions.first : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.rawName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${group.rowCount} rows',
                    style: theme.textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _sub(group),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (top != null)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      HapticService.light();
                      onApply(UnresolvedExerciseResolution(
                        canonicalName: top.canonicalName,
                        exerciseId: top.exerciseId,
                      ));
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(
                      'Map → ${top.canonicalName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    'No auto-suggestion — open to pick manually.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onOpenDetail,
                child: const Text('More…'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _sub(UnresolvedGroup g) {
    final parts = <String>[];
    parts.add('${g.sessionCount} session${g.sessionCount == 1 ? '' : 's'}');
    if (g.sourceApps.isNotEmpty) {
      parts.add(g.sourceApps.join(', '));
    }
    return parts.join(' · ');
  }
}
