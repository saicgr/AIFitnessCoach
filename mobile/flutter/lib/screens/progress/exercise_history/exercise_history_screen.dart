import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/exercise_history.dart';
import '../../../data/models/scores.dart';
import '../../../data/providers/exercise_history_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/exercise_history_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/pill_app_bar.dart';

/// Main screen showing list of most performed exercises and personal records
/// Two-tab layout: "Exercises" tab and "PRs" tab
class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  ConsumerState<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;
  DateTime? _screenOpenTime;

  @override
  void initState() {
    super.initState();
    _screenOpenTime = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
    ref.read(posthogServiceProvider).capture(eventName: 'exercise_history_viewed');
  }

  @override
  void dispose() {
    _logViewDuration();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _logViewDuration() {
    if (_screenOpenTime != null) {
      final duration = DateTime.now().difference(_screenOpenTime!).inSeconds;
      ref.read(exerciseHistoryRepositoryProvider).logView(
        exerciseName: 'list_view',
        sessionDurationSeconds: duration,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const PillAppBar(
        title: 'Exercises & PRs',
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.fitness_center), text: 'Exercises'),
              Tab(icon: Icon(Icons.emoji_events), text: 'PRs'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExercisesTab(theme),
                const _PRsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesTab(ThemeData theme) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);

    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(exerciseSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              ref.read(exerciseSearchQueryProvider.notifier).state = value;
            },
          ),
        ),

        // Exercise list
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(theme, error.toString()),
            data: (exercises) {
              if (exercises.isEmpty) {
                return _buildEmptyState(theme);
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(mostPerformedExercisesProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return _ExerciseCard(
                      exercise: exercise,
                      rank: index + 1,
                      onTap: () {
                        context.push('/stats/exercise-history/${Uri.encodeComponent(exercise.exerciseName)}');
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Exercise History Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete some workouts to see your exercise history and track your progress over time.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load exercises',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(mostPerformedExercisesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// PRs tab showing personal records summary and list
class _PRsTab extends ConsumerStatefulWidget {
  const _PRsTab();

  @override
  ConsumerState<_PRsTab> createState() => _PRsTabState();
}

class _PRsTabState extends ConsumerState<_PRsTab> {
  String? _userId;
  bool _hasLoadedPrs = false;

  @override
  void initState() {
    super.initState();
    _loadPRs();
  }

  Future<void> _loadPRs() async {
    final apiClient = ref.read(apiClientProvider);
    _userId = await apiClient.getUserId();
    if (_userId != null && !_hasLoadedPrs) {
      _hasLoadedPrs = true;
      ref.read(scoresProvider.notifier).loadPersonalRecords(
        userId: _userId,
        limit: 50,
        periodDays: 30,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoresState = ref.watch(scoresProvider);
    final prStats = scoresState.prStats;

    if (scoresState.isLoading && prStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prStats == null) {
      return _buildEmptyPRState(theme);
    }

    final recentPrs = prStats.recentPrs;

    return RefreshIndicator(
      onRefresh: () async {
        if (_userId != null) {
          await ref.read(scoresProvider.notifier).loadPersonalRecords(
            userId: _userId,
            limit: 50,
            periodDays: 30,
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          _buildSummaryCard(theme, prStats),
          const SizedBox(height: 16),

          // Recent PRs header
          if (recentPrs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Recent Personal Records',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // PR items
            ...recentPrs.map((pr) => _buildPRItem(theme, pr)),
          ],

          if (recentPrs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: _buildEmptyPRState(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, PRStats prStats) {
    return Card(
      color: Colors.amber.withOpacity(0.12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryStatItem(
              value: prStats.totalPrs.toString(),
              label: 'Total PRs',
              icon: Icons.emoji_events,
              color: Colors.amber,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.amber.withOpacity(0.3),
            ),
            _SummaryStatItem(
              value: prStats.prsThisPeriod.toString(),
              label: 'Last 30 Days',
              icon: Icons.calendar_month,
              color: Colors.amber.shade700,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.amber.withOpacity(0.3),
            ),
            _SummaryStatItem(
              value: prStats.currentPrStreak.toString(),
              label: 'PR Streak',
              icon: Icons.local_fire_department,
              color: Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRItem(ThemeData theme, PersonalRecordScore pr) {
    final isAllTime = pr.isAllTimePr;
    final trophyColor = isAllTime ? Colors.amber : theme.colorScheme.primary;

    String formattedDate;
    try {
      final date = DateTime.parse(pr.achievedAt);
      formattedDate = DateFormat.yMMMd().format(date);
    } catch (_) {
      formattedDate = pr.achievedAt;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: trophyColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.emoji_events,
                color: trophyColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.exerciseDisplayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (pr.muscleGroup != null)
                    Text(
                      pr.muscleGroup!
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
                          .join(' '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    pr.liftDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Improvement badge + date column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pr.improvementPercent != null && pr.improvementPercent! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${pr.improvementPercent!.toStringAsFixed(1)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (isAllTime)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'ALL-TIME',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPRState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Personal Records Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Keep training and pushing your limits. Your personal records will appear here as you get stronger.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary stat item for the PR summary card
class _SummaryStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryStatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Card displaying a single exercise with stats
class _ExerciseCard extends StatelessWidget {
  final MostPerformedExercise exercise;
  final int rank;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getRankColor(rank, theme),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: rank <= 3 ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (exercise.muscleGroup != null) ...[
                          _StatChip(
                            icon: Icons.fitness_center,
                            label: exercise.formattedMuscleGroup,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _StatChip(
                          icon: Icons.repeat,
                          label: exercise.formattedTimesPerformed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (exercise.maxWeightKg != null && exercise.maxWeightKg! > 0)
                    Text(
                      exercise.formattedMaxWeight,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.formattedLastPerformed,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank, ThemeData theme) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
