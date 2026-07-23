import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/pill_app_bar.dart';
import '../../common/app_refresh_indicator.dart';

/// Manage the user's persistent exercise substitutions ("swap going forward").
///
/// Each row is an A -> B mapping created when a swap is made with "Apply to
/// future workouts" on. Future AI generations replace A with B, and progressive
/// overload follows the swap. Removing a row reverts future generations to the
/// AI's own choice for that exercise. Backed by GET/DELETE /workouts/substitutions.
class ExerciseSubstitutionsScreen extends ConsumerStatefulWidget {
  const ExerciseSubstitutionsScreen({super.key});

  @override
  ConsumerState<ExerciseSubstitutionsScreen> createState() =>
      _ExerciseSubstitutionsScreenState();
}

class _ExerciseSubstitutionsScreenState
    extends ConsumerState<ExerciseSubstitutionsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _subs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final rows = await ref.read(workoutRepositoryProvider).listSubstitutions();
    if (!mounted) return;
    setState(() {
      _subs = rows;
      _loading = false;
    });
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    HapticService.light();
    // Optimistic removal.
    setState(() => _subs = _subs.where((r) => r['id'] != row['id']).toList());
    final ok = await ref.read(workoutRepositoryProvider).deleteSubstitution(id);
    if (!ok && mounted) {
      // Reload to restore on failure.
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: const PillAppBar(title: 'Swapped Exercises'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : AppRefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.event_repeat, size: 18, color: c.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These swaps apply to all future workouts and keep your '
                              'progress on the new exercise. Remove one to let the AI '
                              'choose again.',
                              style: TextStyle(
                                  fontSize: 13, color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_subs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            'No saved swaps yet.\nTurn on "Apply to future workouts" when swapping an exercise.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 14, color: c.textMuted),
                          ),
                        ),
                      )
                    else
                      ..._subs.map((row) => _SubTile(
                            from: (row['original_exercise_name'] ?? '').toString(),
                            to: (row['substitute_exercise_name'] ?? '').toString(),
                            onRemove: () => _remove(row),
                          )),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  const _SubTile({
    required this.from,
    required this.to,
    required this.onRemove,
  });

  final String from;
  final String to;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  from,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 14, color: c.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        to,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: c.textMuted),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
