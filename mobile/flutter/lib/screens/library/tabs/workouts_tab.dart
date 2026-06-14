import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton_list.dart';
import '../../../data/models/workout_studio_models.dart';
import '../../../data/providers/workout_studio_providers.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../workout/customization_studio_sheet.dart';

/// "Workouts" tab of the Library — the user's saved custom workouts.
///
/// Reads [currentUserIdProvider]; if signed out, shows a friendly sign-in
/// prompt. Otherwise loads via [SavedWorkoutsService.getSavedWorkouts] and
/// renders a pull-to-refresh list of tiles. Each tile has a 3-dot menu with
/// Do-now / Rename / Delete. No mock data, no silent fallback — load errors
/// surface a retry state.
class WorkoutsTab extends ConsumerStatefulWidget {
  const WorkoutsTab({super.key});

  @override
  ConsumerState<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends ConsumerState<WorkoutsTab>
    with AutomaticKeepAliveClientMixin {
  // Keep the tab alive so swiping between Library tabs doesn't dispose this
  // state and re-trigger a fetch every time the user flicks across.
  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    // Drop the cached future and await a fresh fetch so pull-to-refresh and
    // post-mutation reloads always hit the network.
    ref.invalidate(savedWorkoutsListProvider(uid));
    await ref.read(savedWorkoutsListProvider(uid).future);
  }

  /// Open the Customization Studio in CREATE mode (no workoutId → builds &
  /// persists a brand-new workout), then jump straight into it.
  Future<void> _buildNew() async {
    HapticService.selection();
    final BuiltWorkout? result = await showCustomizationStudio(context);
    if (!mounted || result == null) return;
    if (result.workoutId != null) {
      context.push('/workout/${result.workoutId}');
    }
    await _refresh();
  }

  // ---- Actions ----------------------------------------------------------

  Future<void> _doNow(Map<String, dynamic> w) async {
    HapticService.selection();
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = await ref.read(savedWorkoutsServiceProvider).doWorkoutNow(
            userId: uid,
            savedWorkoutId: w['id'].toString(),
          );
      if (!mounted) return;
      final id = (session['id'] ?? session['source_id'] ?? w['id']).toString();
      context.push('/workout/$id');
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not start workout: $e')),
      );
    }
  }

  Future<void> _rename(Map<String, dynamic> w) async {
    HapticService.selection();
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final controller = TextEditingController(
      text: (w['workout_name'] ?? '').toString(),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.read(accentColorProvider).getColor(isDark);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: const Text('Rename workout'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Workout name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;
    if (newName == (w['workout_name'] ?? '').toString()) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(savedWorkoutsServiceProvider).updateSavedWorkout(
            userId: uid,
            savedWorkoutId: w['id'].toString(),
            workoutName: newName,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Workout renamed')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Rename failed: $e')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> w) async {
    HapticService.selection();
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (w['workout_name'] ?? 'this workout').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: const Text('Delete workout?'),
        content: Text('"$name" will be removed from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(savedWorkoutsServiceProvider).deleteSavedWorkout(
            userId: uid,
            savedWorkoutId: w['id'].toString(),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Workout deleted')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  // ---- Build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    final uid = ref.watch(currentUserIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (uid == null) {
      return _CenteredMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to see your workouts',
        subtitle:
            'Your saved custom workouts live here once you sign in.',
        color: textSecondary,
        mutedColor: textMuted,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: ZealovaButton(
            label: 'Build a workout',
            trailingIcon: Icons.tune_rounded,
            onTap: _buildNew,
            height: 48,
          ),
        ),
        Expanded(child: _buildList(uid, textSecondary, textMuted)),
      ],
    );
  }

  Widget _buildList(String uid, Color textSecondary, Color textMuted) {
    final async = ref.watch(savedWorkoutsListProvider(uid));

    // Prefer freshly loaded data; otherwise fall back to the session cache so
    // re-entering the tab paints instantly while the network revalidates.
    final workouts = async.valueOrNull ?? cachedSavedWorkouts(uid);

    if (workouts == null) {
      // Nothing to show yet (true cold load or error with no cached data).
      if (async.hasError) {
        return _ErrorRetry(
          message: 'Could not load your workouts.',
          detail: async.error.toString(),
          onRetry: _refresh,
          color: textSecondary,
          mutedColor: textMuted,
        );
      }
      // Layout-matched skeleton instead of a centered spinner.
      return const SkeletonList(
        itemCount: 6,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
        scrollable: true,
        itemBuilder: _workoutSkeletonRow,
      );
    }

    if (workouts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            _CenteredMessage(
              icon: Icons.bookmark_border_rounded,
              title: 'No saved workouts yet',
              subtitle:
                  'Tap "Build a workout" above, or generate one in chat and tap Save.',
              color: textSecondary,
              mutedColor: textMuted,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: workouts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildWorkoutTile(workout: workouts[index]),
      ),
    );
  }

  /// Skeleton row sized to roughly match a real workout tile (icon + 2 lines).
  static Widget _workoutSkeletonRow(BuildContext context, int index) =>
      const SkeletonCard(showLeading: true, leadingSize: 44, lines: 2);

  Widget _buildWorkoutTile({required Map<String, dynamic> workout}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    final name = (workout['workout_name'] ?? 'Custom workout').toString();
    final exercises = (workout['total_exercises'] as num?)?.toInt() ?? 0;
    final duration =
        (workout['estimated_duration_minutes'] as num?)?.toInt();

    final subtitleParts = <String>[
      '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}',
      if (duration != null && duration > 0) '$duration min',
    ];

    return Material(
      color: tc.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticService.light();
          context.push('/workout/${workout['id']}');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tc.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleParts.join(' • ').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: textMuted),
                color: elevated,
                onSelected: (value) {
                  switch (value) {
                    case 'do_now':
                      _doNow(workout);
                      break;
                    case 'rename':
                      _rename(workout);
                      break;
                    case 'delete':
                      _delete(workout);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'do_now',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_rounded, color: accent, size: 20),
                        const SizedBox(width: 10),
                        const Text('Do now'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: textPrimary, size: 20),
                        const SizedBox(width: 10),
                        const Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered icon + title + subtitle used for empty / sign-in states.
class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color mutedColor;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: mutedColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry button.
class _ErrorRetry extends StatelessWidget {
  final String message;
  final String detail;
  final Future<void> Function() onRetry;
  final Color color;
  final Color mutedColor;

  const _ErrorRetry({
    required this.message,
    required this.detail,
    required this.onRetry,
    required this.color,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: mutedColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
