import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/cardio_dedup_repository.dart';

import '../../l10n/generated/app_localizations.dart';
/// Manage Duplicate Imports
///
/// Surfaces dedup groups created by `cardio_dedup_service` so the user can:
///   • see which Strava/Garmin/Apple-Health/Health-Connect rows were merged,
///   • override the primary (pick a different source as the kept one),
///   • unlink a row when the heuristic produced a false positive.
///
/// Routing: the Settings entry that points here is owned by another agent
/// in this swarm wave. To let that agent wire to us without importing
/// internals, we export a stable route name as a `static const`.
class ManageDuplicateImportsScreen extends ConsumerStatefulWidget {
  const ManageDuplicateImportsScreen({super.key});

  /// Stable route name — referenced by the Settings entry (owned by another
  /// agent) once that wave lands. Keeping the constant here means the
  /// Settings agent only has to import this file's symbol.
  static const String routeName = '/settings/manage-duplicate-imports';

  @override
  ConsumerState<ManageDuplicateImportsScreen> createState() =>
      _ManageDuplicateImportsScreenState();
}

class _ManageDuplicateImportsScreenState
    extends ConsumerState<ManageDuplicateImportsScreen> {
  late Future<List<DedupGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DedupGroup>> _load() {
    return ref.read(cardioDedupRepositoryProvider).listGroups();
  }

  Future<void> _refresh() async {
    final fresh = _load();
    setState(() => _future = fresh);
    await fresh;
  }

  Future<void> _makePrimary(DedupGroup group, DedupCardioLogSummary row) async {
    final repo = ref.read(cardioDedupRepositoryProvider);
    try {
      await repo.overridePrimary(group.groupId, row.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Made ${_sourceLabel(row.sourceApp)} the primary')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update primary: $e')),
      );
    }
  }

  Future<void> _unlink(DedupCardioLogSummary row) async {
    final repo = ref.read(cardioDedupRepositoryProvider);
    try {
      await repo.unlink(row.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).manageDuplicateImportsUnlinkedFromGroup)),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not unlink: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).manageDuplicateImportsDuplicateImports),
      ),
      body: FutureBuilder<List<DedupGroup>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(error: snap.error!, onRetry: _refresh);
          }
          final groups = snap.data ?? const <DedupGroup>[];
          if (groups.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  _EmptyState(),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final g = groups[i];
                return _GroupCard(
                  group: g,
                  onMakePrimary: (row) => _makePrimary(g, row),
                  onUnlink: _unlink,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 56,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).manageDuplicateImportsNoDuplicateImportsDetected,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We compare imports from Strava, Garmin, Apple Health, and Health '
            'Connect to avoid double-counting your workouts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).manageDuplicateImportsCouldNotLoadDuplicate,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).buttonRetry)),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final DedupGroup group;
  final void Function(DedupCardioLogSummary row) onMakePrimary;
  final void Function(DedupCardioLogSummary row) onUnlink;

  const _GroupCard({
    required this.group,
    required this.onMakePrimary,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: sport icon + date.
          Row(
            children: [
              Icon(_sportIcon(group.primary.activityType), color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_sportLabel(group.primary.activityType)} · '
                  '${_formatDate(group.primary.performedAt)}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                '${group.allMembers.length} sources',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...group.allMembers.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MemberRow(
                row: row,
                accent: accent,
                onMakePrimary: row.isPrimary ? null : () => onMakePrimary(row),
                onUnlink: () => onUnlink(row),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final DedupCardioLogSummary row;
  final Color accent;
  final VoidCallback? onMakePrimary;
  final VoidCallback onUnlink;

  const _MemberRow({
    required this.row,
    required this.accent,
    required this.onMakePrimary,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: row.isPrimary
              ? accent.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
          width: row.isPrimary ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                label: row.isPrimary ? AppLocalizations.of(context).nutritionSettingsScreenPrimary : AppLocalizations.of(context).manageDuplicateImportsHidden,
                color: row.isPrimary ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _sourceLabel(row.sourceApp),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: AppLocalizations.of(context).manageDuplicateImportsUnlinkFromGroup,
                position: PopupMenuPosition.under,
                onSelected: (v) {
                  if (v == 'unlink') onUnlink();
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'unlink',
                    child: Row(
                      children: [
                        const Icon(Icons.link_off_rounded, size: 18, color: AppColors.error),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context).manageDuplicateImportsUnlinkFromGroup,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatTime(row.performedAt)} · ${_formatDuration(row.durationSeconds)}'
            '${row.distanceM != null ? " · ${_formatDistance(row.distanceM!)}" : ""}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (onMakePrimary != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onMakePrimary,
                child: Text(AppLocalizations.of(context).manageDuplicateImportsMakeThisPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers (file-local, no new util file needed).
// ---------------------------------------------------------------------------

IconData _sportIcon(String activity) {
  switch (activity) {
    case 'run':
    case 'trail_run':
    case 'treadmill':
      return Icons.directions_run;
    case 'walk':
    case 'hike':
      return Icons.directions_walk;
    case 'cycle':
    case 'indoor_cycle':
    case 'mountain_bike':
    case 'gravel_bike':
      return Icons.directions_bike;
    case 'row':
    case 'erg':
      return Icons.rowing;
    case 'swim':
    case 'open_water_swim':
      return Icons.pool;
    default:
      return Icons.fitness_center;
  }
}

String _sportLabel(String activity) {
  return activity.replaceAll('_', ' ');
}

String _sourceLabel(String source) {
  switch (source) {
    case 'apple_health':
      return 'Apple Health';
    case 'health_connect':
      return 'Health Connect';
    case 'strava':
      return 'Strava';
    case 'garmin':
      return 'Garmin';
    case 'manual':
      return 'Manual entry';
    default:
      return source;
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${_pad(local.month)}-${_pad(local.day)}';
}

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  return '${_pad(local.hour)}:${_pad(local.minute)}';
}

String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

String _formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

String _pad(int v) => v < 10 ? '0$v' : '$v';
