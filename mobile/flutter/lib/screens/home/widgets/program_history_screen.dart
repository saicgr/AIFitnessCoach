import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/program_history.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/app_dialog.dart';
import 'components/sheet_theme_colors.dart';

class ProgramHistoryScreen extends ConsumerStatefulWidget {
  const ProgramHistoryScreen({super.key});

  @override
  ConsumerState<ProgramHistoryScreen> createState() =>
      _ProgramHistoryScreenState();
}

class _ProgramHistoryScreenState extends ConsumerState<ProgramHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProgramHistory> _programs = [];

  @override
  void initState() {
    super.initState();
    _loadProgramHistory();
  }

  Future<void> _loadProgramHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final programs = await workoutRepo.getProgramHistory(userId);

      if (mounted) {
        setState(() {
          _programs = programs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreProgram(ProgramHistory program) async {
    // Show confirmation dialog
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Restore Program?',
      message: 'This will restore "${program.displayName}" as your current program. '
          'You can regenerate workouts after restoring.',
      confirmText: 'Restore',
      icon: Icons.restore_rounded,
    );

    if (confirmed != true) return;

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      await workoutRepo.restoreProgram(userId, program.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload the list to update "CURRENT" badge
        _loadProgramHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore program: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Program History'),
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.cyan))
          : _errorMessage != null
              ? _buildErrorState(colors)
              : _programs.isEmpty
                  ? _buildEmptyState(colors)
                  : _buildProgramList(colors),
    );
  }

  Widget _buildErrorState(SheetColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load program history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadProgramHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SheetColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Program History Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you customize your program, snapshots will be saved here.',
              style: TextStyle(fontSize: 14, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramList(SheetColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _programs.length,
      itemBuilder: (context, index) {
        final program = _programs[index];
        return _buildProgramCard(program, colors);
      },
    );
  }

  Widget _buildProgramCard(ProgramHistory program, SheetColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? colors.elevated : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: program.isCurrent
              ? colors.cyan
              : colors.cardBorder.withOpacity(0.3),
          width: program.isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and current badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    program.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (program.isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.cyan),
                    ),
                    child: Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.cyan,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Created date
            Text(
              'Created ${_formatDate(program.createdAt)}',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),

            if (program.description != null) ...[
              const SizedBox(height: 4),
              Text(
                program.description!,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],

            const SizedBox(height: 12),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (program.difficulty != null)
                  _buildChip(
                    label: program.difficulty!,
                    icon: Icons.trending_up,
                    color: colors.error,
                  ),
                if (program.durationMinutes != null)
                  _buildChip(
                    label: '${program.durationMinutes} min',
                    icon: Icons.timer,
                    color: colors.success,
                  ),
                _buildChip(
                  label: '${program.selectedDays.length} days/week',
                  icon: Icons.calendar_today,
                  color: colors.cyan,
                ),
              ],
            ),

            // Days of week
            if (program.dayNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                program.dayNames.join(', '),
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],

            // Equipment tags
            if (program.equipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: program.equipment.map((eq) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eq,
                      style: TextStyle(fontSize: 10, color: colors.purple),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Completion stats (if available)
            if (program.totalWorkoutsCompleted > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: colors.success),
                    const SizedBox(width: 4),
                    Text(
                      '${program.totalWorkoutsCompleted} workouts completed',
                      style: TextStyle(fontSize: 12, color: colors.success),
                    ),
                  ],
                ),
              ),
            ],

            // Restore button (only for non-current programs)
            if (!program.isCurrent) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _restoreProgram(program),
                  icon: Icon(Icons.restore, size: 18, color: colors.cyan),
                  label: Text(
                    'Restore Program',
                    style: TextStyle(color: colors.cyan),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.cyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      }
    } catch (_) {
      return dateString;
    }
  }
}
