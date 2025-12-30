import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_history_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/repositories/auth_repository.dart';

/// Screen for importing past workout history to seed AI learning.
/// Addresses the "weird weights" issue by allowing users to input
/// their strength levels before completing workouts in the app.
class WorkoutHistoryImportScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryImportScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryImportScreen> createState() =>
      _WorkoutHistoryImportScreenState();
}

class _WorkoutHistoryImportScreenState
    extends ConsumerState<WorkoutHistoryImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController(text: '3');

  bool _isLoading = false;
  List<StrengthSummary> _strengthSummary = [];
  List<WorkoutHistoryRecord> _recentHistory = [];

  WorkoutHistoryRepository? _repository;

  @override
  void initState() {
    super.initState();
    // Initialize repository after first frame when ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiClient = ref.read(apiClientProvider);
      _repository = WorkoutHistoryRepository(apiClient);
      _loadData();
    });
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null || _repository == null) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _repository!.getStrengthSummary(userId: user.id),
        _repository!.getHistory(userId: user.id, limit: 10),
      ]);

      setState(() {
        _strengthSummary = results[0] as List<StrengthSummary>;
        _recentHistory = results[1] as List<WorkoutHistoryRecord>;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null || _repository == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _repository!.importSingleEntry(
        userId: user.id,
        exerciseName: _exerciseController.text.trim(),
        weightKg: double.parse(_weightController.text),
        reps: int.parse(_repsController.text),
        sets: int.parse(_setsController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _exerciseController.clear();
        _weightController.clear();
        _repsController.clear();
        _setsController.text = '3';

        // Reload data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null || _repository == null) return;

    final success = await _repository!.deleteEntry(
      userId: user.id,
      entryId: entryId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Workout History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add your past workout data so the AI can generate workouts with weights that match your strength level.',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Import form
                  Text(
                    'Add Exercise',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _exerciseController,
                          decoration: const InputDecoration(
                            labelText: 'Exercise Name',
                            hintText: 'e.g., Bench Press, Squat',
                            prefixIcon: Icon(Icons.fitness_center),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an exercise name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  hintText: 'e.g., 60',
                                  prefixIcon: Icon(Icons.monitor_weight),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final weight = double.tryParse(value);
                                  if (weight == null || weight < 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _repsController,
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  hintText: 'e.g., 10',
                                  prefixIcon: Icon(Icons.repeat),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final reps = int.tryParse(value);
                                  if (reps == null || reps < 1) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _setsController,
                                decoration: const InputDecoration(
                                  labelText: 'Sets',
                                  hintText: 'e.g., 3',
                                  prefixIcon: Icon(Icons.format_list_numbered),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _submitEntry,
                            icon: const Icon(Icons.add),
                            label: const Text('Add to History'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Strength summary
                  if (_strengthSummary.isNotEmpty) ...[
                    Text(
                      'Your Strength Data',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The AI uses this data to set appropriate weights',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _strengthSummary.length,
                      itemBuilder: (context, index) {
                        final summary = _strengthSummary[index];
                        return _StrengthSummaryTile(summary: summary);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Recent imports
                  if (_recentHistory.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Imports',
                          style: theme.textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            // Could navigate to full history
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentHistory.length,
                      itemBuilder: (context, index) {
                        final record = _recentHistory[index];
                        return _HistoryRecordTile(
                          record: record,
                          onDelete: () => _deleteEntry(record.id),
                        );
                      },
                    ),
                  ],

                  // Empty state
                  if (_strengthSummary.isEmpty && _recentHistory.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No workout history yet',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your past workout data above to help the AI generate better workouts for you.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StrengthSummaryTile extends StatelessWidget {
  final StrengthSummary summary;

  const _StrengthSummaryTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(summary.exerciseName),
        subtitle: Text(
          '${summary.sourceDescription}  •  ${summary.totalSessions} sessions',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${summary.lastWeightKg.toStringAsFixed(1)} kg',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Max: ${summary.maxWeightKg.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRecordTile extends StatelessWidget {
  final WorkoutHistoryRecord record;
  final VoidCallback onDelete;

  const _HistoryRecordTile({
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(record.exerciseName),
        subtitle: Text(
          '${record.sets} sets × ${record.reps} reps @ ${record.weightKg.toStringAsFixed(1)} kg',
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: colorScheme.error,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Entry?'),
                content: Text(
                    'Remove ${record.exerciseName} from your workout history?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
