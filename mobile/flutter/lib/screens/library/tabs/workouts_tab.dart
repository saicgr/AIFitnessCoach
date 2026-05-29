import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout_studio_models.dart';
import '../../../data/providers/workout_studio_providers.dart';
import '../../../data/services/haptic_service.dart';
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

class _WorkoutsTabState extends ConsumerState<WorkoutsTab> {
  Future<List<Map<String, dynamic>>>? _future;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    // Defer the first load to didChangeDependencies so `ref` reads are safe
    // and we pick up the resolved auth state.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = ref.read(currentUserIdProvider);
    // (Re)load when the signed-in user changes or on first build.
    if (uid != null && uid != _loadedForUserId) {
      _loadedForUserId = uid;
      _future = _load(uid);
    }
  }

  Future<List<Map<String, dynamic>>> _load(String uid) {
    return ref
        .read(savedWorkoutsServiceProvider)
        .getSavedWorkouts(userId: uid);
  }

  Future<void> _refresh() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final f = _load(uid);
    setState(() => _future = f);
    await f;
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

    final accent = ref.watch(accentColorProvider).getColor(isDark);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _buildNew,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Build a workout'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(child: _buildList(textSecondary, textMuted)),
      ],
    );
  }

  Widget _buildList(Color textSecondary, Color textMuted) {
    final future = _future;
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorRetry(
            message: 'Could not load your workouts.',
            detail: snapshot.error.toString(),
            onRetry: _refresh,
            color: textSecondary,
            mutedColor: textMuted,
          );
        }

        final workouts = snapshot.data ?? const [];

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
      },
    );
  }

  Widget _buildWorkoutTile({required Map<String, dynamic> workout}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
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
      color: elevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/workout/${workout['id']}');
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.35),
                      AppColors.purple.withValues(alpha: 0.30),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
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
                      subtitleParts.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12.5,
                      ),
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
