import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/health_import_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/health_import_service.dart'
    show PendingWorkoutImport;
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/sheet_header.dart';

// ---------------------------------------------------------------------------
// External Workout import sheet — the user-facing review + import flow for a
// workout discovered in Health Connect / Apple Health (a walk, run, ride, …).
//
// Mirrors the competitor's "External Workout" card: a Health-Connect header
// with the time, a stat grid (Distance / Duration / Energy / Avg HR / Pace),
// then a "Rate your Effort" Light/Moderate/Hard step that maps to recovery
// days, then Import Workout (primary) + Skip.
//
// All numbers come from the enriched `PendingWorkoutImport` — no mock data.
// Pace is computed from distance ÷ duration; when there's no distance the
// pace tile is hidden (e.g. a strength session synced from a watch).
//
// Persistence reuses the proven import path in `HealthImportNotifier`
// (`importAsNewWorkout` → POST /workouts/ + /complete), so this sheet does
// not invent a new endpoint. The chosen effort maps to the workout
// `difficulty` the backend stores, which the recovery model later reads.
// ---------------------------------------------------------------------------

/// Effort level the user picks on the "Rate your Effort" step. Each level maps
/// to a recovery-day count (Light → 1, Moderate → 2, Hard → 3) and to the
/// `difficulty` string the import endpoint persists.
enum ImportEffort { light, moderate, hard }

extension ImportEffortMapping on ImportEffort {
  /// User-facing chip label.
  String get label {
    switch (this) {
      case ImportEffort.light:
        return 'Light';
      case ImportEffort.moderate:
        return 'Moderate';
      case ImportEffort.hard:
        return 'Hard';
    }
  }

  /// Recovery days this effort implies. Feeds the recovery-aware coach loop:
  /// a hard external session pushes tomorrow's plan toward a deload/swap.
  int get recoveryDays {
    switch (this) {
      case ImportEffort.light:
        return 1;
      case ImportEffort.moderate:
        return 2;
      case ImportEffort.hard:
        return 3;
    }
  }

  /// Maps to the `difficulty` string `importAsNewWorkout` persists on the
  /// workout (the value the recovery model + analytics read back).
  String get difficulty {
    switch (this) {
      case ImportEffort.light:
        return 'beginner';
      case ImportEffort.moderate:
        return 'intermediate';
      case ImportEffort.hard:
        return 'advanced';
    }
  }

  /// One-line recovery caption shown under the chips.
  String get recoveryCaption {
    switch (this) {
      case ImportEffort.light:
        return 'Low effort workouts need 1 day of recovery.';
      case ImportEffort.moderate:
        return 'Moderate workouts need about 2 days of recovery.';
      case ImportEffort.hard:
        return 'Hard workouts need around 3 days of recovery.';
    }
  }

  /// Accent for the chip when selected.
  Color color(BuildContext context) {
    switch (this) {
      case ImportEffort.light:
        return const Color(0xFF22C55E); // green
      case ImportEffort.moderate:
        return const Color(0xFFF59E0B); // amber
      case ImportEffort.hard:
        return const Color(0xFFEF4444); // red
    }
  }
}

/// Shows the External Workout import sheet for [import_]. Returns true when
/// the user imported the workout, false/null when they skipped or dismissed.
///
/// Call site (entry point): the workouts screen surfaces an
/// "N external workouts to import" pill from [pendingExternalWorkoutsProvider]
/// and opens this sheet for the first pending item. It can also be opened from
/// anywhere a `PendingWorkoutImport` is in hand.
Future<bool?> showExternalWorkoutImportSheet(
  BuildContext context,
  WidgetRef ref,
  PendingWorkoutImport import_,
) {
  return showGlassSheet<bool>(
    context: context,
    builder: (ctx) => GlassSheet(
      showHandle: true,
      child: _ExternalWorkoutImportSheet(import_: import_),
    ),
  );
}

/// Drop-in entry point: "N external workouts to import" pill. Renders nothing
/// when there are no pending imports (so it's safe to place unconditionally).
/// Tapping opens the import sheet for the first pending workout; after it's
/// handled the pill re-reads the (now shorter) pending list and either shows
/// the next count or disappears.
///
/// Wiring (one line, e.g. in the workouts screen header):
/// ```dart
/// const ExternalWorkoutImportBanner(),
/// ```
/// It self-gates on [pendingExternalWorkoutsProvider]; the host screen is
/// responsible for having called `checkForUnimportedWorkouts()` at least once
/// (home_screen + the workouts screen already do on resume) so the list is
/// populated.
class ExternalWorkoutImportBanner extends ConsumerWidget {
  const ExternalWorkoutImportBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingExternalWorkoutsProvider);
    if (pending.isEmpty) return const SizedBox.shrink();

    final colors = ThemeColors.of(context);
    final count = pending.length;
    final label = count == 1
        ? '1 external workout to import'
        : '$count external workouts to import';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            final first = ref.read(pendingExternalWorkoutsProvider);
            if (first.isNotEmpty) {
              showExternalWorkoutImportSheet(context, ref, first.first);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.sync_rounded, size: 20, color: colors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExternalWorkoutImportSheet extends ConsumerStatefulWidget {
  final PendingWorkoutImport import_;

  const _ExternalWorkoutImportSheet({required this.import_});

  @override
  ConsumerState<_ExternalWorkoutImportSheet> createState() =>
      _ExternalWorkoutImportSheetState();
}

class _ExternalWorkoutImportSheetState
    extends ConsumerState<_ExternalWorkoutImportSheet> {
  /// The (possibly enriched) import we render + persist. Starts as the raw
  /// import passed in; replaced by the enriched copy once full metrics load
  /// (HR, energy, etc.) so the stat grid fills in without a blocking spinner.
  late PendingWorkoutImport _import = widget.import_;

  ImportEffort _effort = ImportEffort.moderate;
  bool _enriching = false;
  bool _importing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // If we don't yet have the rich metrics (no HR series → likely not
    // enriched), pull them in the background so the grid fills in. The import
    // itself also enriches if needed, so this is purely for display.
    if (widget.import_.hrSamples.isEmpty &&
        widget.import_.avgHeartRate == null) {
      _enrichForDisplay();
    }
  }

  /// Pull full Health Connect metrics (HR, energy, …) for the workout window
  /// so the stat grid fills in, without a blocking spinner. Routes through the
  /// notifier's existing per-index enrich so we reuse one HealthService and the
  /// enriched copy lands back in the shared pending list. Best-effort:
  /// `importAsNewWorkout` enriches again on persist regardless, so a display
  /// enrich failure never blocks the import.
  Future<void> _enrichForDisplay() async {
    setState(() => _enriching = true);
    try {
      final notifier = ref.read(healthImportProvider.notifier);
      final pending = ref.read(healthImportProvider).pendingImports;
      final index = pending.indexWhere((p) => p.uuid == _import.uuid);
      if (index >= 0) {
        await notifier.enrichCurrentWorkoutHR(index);
        final updated = ref
            .read(healthImportProvider)
            .pendingImports
            .where((p) => p.uuid == _import.uuid)
            .toList();
        if (mounted && updated.isNotEmpty) {
          setState(() => _import = updated.first);
        }
      }
    } catch (_) {
      // Degrade to the envelope metrics — no error UI for display enrichment.
    } finally {
      if (mounted) setState(() => _enriching = false);
    }
  }

  // -------------------------------------------------------------------------
  // Formatting helpers (no fabricated data — null → tile hidden)
  // -------------------------------------------------------------------------

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $ampm';
  }

  String? _distanceLabel() {
    final m = _import.distanceMeters;
    if (m == null || m <= 0) return null;
    if (m >= 1000) {
      final km = m / 1000;
      return '${km.toStringAsFixed(km >= 10 ? 1 : 2)} km';
    }
    return '${m.round()} m';
  }

  String _durationLabel() {
    final mins = _import.durationMinutes;
    if (mins >= 60) {
      final h = mins ~/ 60;
      final r = mins % 60;
      return r == 0 ? '${h}h' : '${h}h ${r}m';
    }
    return '${mins}m';
  }

  String? _energyLabel() {
    final kcal = _import.caloriesBurned ?? _import.totalCalories;
    if (kcal == null || kcal <= 0) return null;
    return '${kcal.round()} kcal';
  }

  String? _avgHrLabel() {
    final hr = _import.avgHeartRate;
    if (hr == null || hr <= 0) return null;
    return '$hr bpm';
  }

  /// Pace from distance ÷ duration → min/km. Hidden when there's no distance
  /// (the requirement: zero distance → hide pace).
  String? _paceLabel() {
    final m = _import.distanceMeters;
    final mins = _import.durationMinutes;
    if (m == null || m <= 0 || mins <= 0) return null;
    final km = m / 1000;
    if (km <= 0) return null;
    final secPerKm = (mins * 60) / km;
    final paceMin = secPerKm ~/ 60;
    final paceSec = (secPerKm % 60).round();
    return '$paceMin:${paceSec.toString().padLeft(2, '0')} /km';
  }

  String _titleForKind(String kind) {
    final notifierName = {
      'walking': 'Walk',
      'running': 'Run',
      'cycling': 'Ride',
      'swimming': 'Swim',
      'rowing': 'Row',
      'hiking': 'Hike',
      'elliptical': 'Elliptical',
      'stairs': 'Stair Climb',
      'skating': 'Skate',
      'dance': 'Dance',
      'yoga': 'Yoga',
      'pilates': 'Pilates',
      'hiit': 'HIIT',
      'tennis': 'Tennis',
      'basketball': 'Basketball',
      'football': 'Football',
      'soccer': 'Soccer',
      'strength': 'Strength',
    };
    return notifierName[kind] ?? 'Workout';
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'running':
        return Icons.directions_run_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'swimming':
        return Icons.pool_rounded;
      case 'rowing':
        return Icons.rowing_rounded;
      case 'hiking':
        return Icons.terrain_rounded;
      case 'elliptical':
      case 'stairs':
        return Icons.stairs_rounded;
      case 'yoga':
      case 'pilates':
        return Icons.self_improvement_rounded;
      case 'hiit':
        return Icons.bolt_rounded;
      case 'strength':
        return Icons.fitness_center_rounded;
      default:
        return Icons.monitor_heart_rounded;
    }
  }

  // -------------------------------------------------------------------------
  // Import / skip
  // -------------------------------------------------------------------------

  Future<void> _import_() async {
    HapticService.medium();
    setState(() {
      _importing = true;
      _error = null;
    });

    // Stamp the chosen effort onto the import so the persisted metadata
    // carries the user's perceived effort (the envelope effortScore is an
    // HR-derived estimate; the user's RPE is the ground truth the recovery
    // model should trust). We map Light/Moderate/Hard → 30/60/90 on the
    // 0-100 effort scale so it slots into the same field.
    final effortScore = {
      ImportEffort.light: 30,
      ImportEffort.moderate: 60,
      ImportEffort.hard: 90,
    }[_effort]!;
    final stamped = _import.copyWith(effortScore: effortScore);

    try {
      final notifier = ref.read(healthImportProvider.notifier);
      await notifier.importAsNewWorkout(stamped, _effort.difficulty);

      // The notifier surfaces failures via state.error rather than throwing.
      final err = ref.read(healthImportProvider).error;
      if (err != null) {
        if (!mounted) return;
        setState(() {
          _importing = false;
          _error = 'Couldn\'t import this workout. Please try again.';
        });
        return;
      }

      if (!mounted) return;
      HapticService.success();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _error = 'Couldn\'t import this workout. Please try again.';
      });
    }
  }

  void _skip() {
    HapticService.light();
    // ignore: discarded_futures
    ref.read(healthImportProvider.notifier).skipWorkout(_import);
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final kind = _import.activityKind;
    final accent = _iconAccent(kind);

    final stats = <_StatTile>[
      if (_distanceLabel() != null)
        _StatTile(
          icon: Icons.straighten_rounded,
          label: 'Distance',
          value: _distanceLabel()!,
        ),
      _StatTile(
        icon: Icons.timer_outlined,
        label: 'Duration',
        value: _durationLabel(),
      ),
      if (_energyLabel() != null)
        _StatTile(
          icon: Icons.local_fire_department_rounded,
          label: 'Energy',
          value: _energyLabel()!,
        ),
      if (_avgHrLabel() != null)
        _StatTile(
          icon: Icons.favorite_rounded,
          label: 'Avg HR',
          value: _avgHrLabel()!,
        ),
      if (_paceLabel() != null)
        _StatTile(
          icon: Icons.speed_rounded,
          label: 'Pace',
          value: _paceLabel()!,
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          icon: _iconForKind(kind),
          iconColor: accent,
          title: 'External Workout',
          subtitle: _headerSubtitle(),
          showHandle: false,
          onClose: () => Navigator.of(context).pop(false),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row: workout kind + source app.
                Text(
                  _titleForKind(kind),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if ((_import.sourceName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'from ${_import.sourceName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Stat grid.
                _StatGrid(tiles: stats),
                if (_enriching) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading details…',
                        style:
                            TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Rate your Effort.
                Text(
                  'Rate your Effort',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final e in ImportEffort.values) ...[
                      Expanded(
                        child: _EffortChip(
                          effort: e,
                          selected: _effort == e,
                          onTap: () {
                            HapticService.selection();
                            setState(() => _effort = e);
                          },
                        ),
                      ),
                      if (e != ImportEffort.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.bedtime_outlined,
                        size: 14, color: colors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _effort.recoveryCaption,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Import (primary) + Skip.
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _importing ? null : _import_,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentContrast,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _importing
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colors.accentContrast,
                            ),
                          )
                        : const Text(
                            'Import Workout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton(
                    onPressed: _importing ? null : _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// "Health Connect · 7:42 AM" style header subtitle.
  String _headerSubtitle() {
    final platform = _import.sourceName?.isNotEmpty == true
        ? _import.sourceName!
        : 'Health Connect';
    return '$platform · ${_formatTime(_import.startTime)}';
  }

  Color _iconAccent(String kind) {
    switch (kind) {
      case 'running':
      case 'walking':
      case 'hiking':
        return const Color(0xFF22C55E);
      case 'cycling':
        return const Color(0xFF3B82F6);
      case 'swimming':
      case 'rowing':
        return const Color(0xFF06B6D4);
      case 'hiit':
      case 'strength':
        return const Color(0xFFEF4444);
      case 'yoga':
      case 'pilates':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

// ---------------------------------------------------------------------------
// Stat grid
// ---------------------------------------------------------------------------

class _StatTile {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatGrid extends StatelessWidget {
  final List<_StatTile> tiles;

  const _StatGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in tiles)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96, maxWidth: 160),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(t.icon, size: 14, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Effort chip
// ---------------------------------------------------------------------------

class _EffortChip extends StatelessWidget {
  final ImportEffort effort;
  final bool selected;
  final VoidCallback onTap;

  const _EffortChip({
    required this.effort,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final color = effort.color(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : colors.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : colors.cardBorder,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              effort.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? color : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${effort.recoveryDays}d',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
