import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_history_import_file_repository.dart';
import '../../data/repositories/workout_history_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/pill_app_bar.dart';
import 'widgets/unresolved_exercises_bulk_sheet.dart';
import 'widgets/workout_import_preview_sheet.dart';
import 'widgets/workout_import_progress_sheet.dart';
import 'widgets/workout_import_summary_sheet.dart';

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
  WorkoutHistoryImportFileRepository? _fileRepository;

  @override
  void initState() {
    super.initState();
    // Initialize repository after first frame when ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiClient = ref.read(apiClientProvider);
      _repository = WorkoutHistoryRepository(apiClient);
      _fileRepository = WorkoutHistoryImportFileRepository(apiClient);
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

      if (!mounted) return;
      setState(() {
        _strengthSummary = results[0] as List<StrengthSummary>;
        _recentHistory = results[1] as List<WorkoutHistoryRecord>;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // ─────────────────────── File-import flow ────────────────────────────

  /// End-to-end file import flow:
  ///   1. Pick file → options sheet (unit + source hint)
  ///   2. POST /import/preview → preview sheet
  ///   3. POST /import/file → progress sheet (polls media-jobs)
  ///   4. Summary sheet → optional bulk-remap follow-up
  Future<void> _runFileImport() async {
    HapticService.light();
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null || _fileRepository == null) return;

    // 1. Pick file. withData:true guarantees `file.bytes` is populated on web
    //    and on platforms where the picker normally returns a path only.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file.')),
      );
      return;
    }

    // 2. Collect unit + source hint. Default unit = workout unit preference.
    final defaultUnit = ref.read(workoutWeightUnitProvider).toLowerCase();
    final opts = await _pickImportOptions(defaultUnit: defaultUnit);
    if (opts == null) return;

    // 3. Preview (sync dry-run).
    setState(() => _isLoading = true);
    try {
      final preview = await _fileRepository!.previewFile(
        bytes: bytes,
        filename: picked.name,
        unitHint: opts.unit,
        timezoneHint: DateTime.now().timeZoneName,
        sourceAppHint: opts.sourceAppHint,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      final confirmed = await showWorkoutImportPreviewSheet(
        context: context,
        preview: preview,
        filename: picked.name,
      );
      if (!confirmed) return;

      // 4. Enqueue the real job.
      setState(() => _isLoading = true);
      final jobId = await _fileRepository!.uploadFile(
        bytes: bytes,
        filename: picked.name,
        unitHint: opts.unit,
        timezoneHint: DateTime.now().timeZoneName,
        sourceAppHint: opts.sourceAppHint,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      // 5. Progress sheet (polls every 1.5s).
      final finalJob = await showWorkoutImportProgressSheet(
        context: context,
        jobId: jobId,
        repository: _fileRepository!,
        sourceAppLabel: _formatSourceApp(preview.sourceApp),
      );
      if (finalJob == null || !mounted) return;

      // 6. Summary sheet.
      final summary = await showWorkoutImportSummarySheet(
        context: context,
        job: finalJob,
      );

      // 7. Refresh strength summaries so the list reflects the new data.
      _loadData();

      if (!mounted) return;
      if (summary?.fixUnresolved == true) {
        await showUnresolvedExercisesBulkSheet(
          context: context,
          repository: _fileRepository!,
          userId: user.id,
        );
        _loadData();
      }
      // NOTE: program activation — when the backend adds a dedicated
      // /program/activate endpoint we'll wire it here. For now the toggle
      // value just surfaces whether the user wanted activation.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<_ImportOptions?> _pickImportOptions({required String defaultUnit}) {
    return showGlassSheet<_ImportOptions>(
      context: context,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.68,
        child: _ImportOptionsSheet(defaultUnit: defaultUnit),
      ),
    );
  }

  // ───────────────────────── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const PillAppBar(title: 'Import Workout History'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File-import section — ABOVE the manual entry form so
                  // it's the first thing users see.
                  _FileImportSection(onPickFile: _runFileImport),
                  const SizedBox(height: 24),

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

  static String _formatSourceApp(String slug) {
    if (slug.isEmpty || slug == 'unknown') return 'export';
    return slug
        .split('_')
        .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }
}

// ───────────────────────── Widgets ──────────────────────────────────────

/// The "Import from file" card that sits above the manual entry form.
class _FileImportSection extends StatelessWidget {
  const _FileImportSection({required this.onPickFile});
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.folder_open_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Import from file',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Export from Hevy, Strong, Fitbod, Jeff Nippard, Renaissance '
            'Periodization, Wendler 5/3/1, Apple Health, Garmin, Strava, '
            'Peloton, and more.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Supports CSV, XLSX, XLSM, JSON, Parquet, PDF, FIT, XML, ZIP.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: onPickFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Choose File'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The unit + source-hint sheet shown after file selection.
class _ImportOptions {
  const _ImportOptions({required this.unit, this.sourceAppHint});
  final String unit;
  final String? sourceAppHint;
}

class _ImportOptionsSheet extends StatefulWidget {
  const _ImportOptionsSheet({required this.defaultUnit});
  final String defaultUnit;

  @override
  State<_ImportOptionsSheet> createState() => _ImportOptionsSheetState();
}

class _ImportOptionsSheetState extends State<_ImportOptionsSheet> {
  late String _unit;
  String _hint = 'auto';

  // Source hint slugs must match detect() / adapter module names.
  static const _sources = <({String slug, String label})>[
    (slug: 'auto', label: 'Auto-detect'),
    (slug: 'hevy', label: 'Hevy'),
    (slug: 'strong', label: 'Strong'),
    (slug: 'fitbod', label: 'Fitbod'),
    (slug: 'jefit', label: 'Jefit'),
    (slug: 'fitnotes', label: 'FitNotes'),
    (slug: 'garmin', label: 'Garmin'),
    (slug: 'apple_health', label: 'Apple Health'),
    (slug: 'strava', label: 'Strava'),
    (slug: 'peloton', label: 'Peloton'),
    (slug: 'nippard', label: 'Jeff Nippard'),
    (slug: 'rp', label: 'Renaissance Periodization'),
    (slug: 'wendler_531', label: 'Wendler 5/3/1'),
    (slug: 'nsuns', label: 'nSuns'),
    (slug: 'gzclp', label: 'GZCLP'),
    (slug: 'starting_strength', label: 'Starting Strength'),
    (slug: 'stronglifts', label: 'StrongLifts'),
    (slug: 'generic_sheet', label: 'Other / generic spreadsheet'),
  ];

  @override
  void initState() {
    super.initState();
    // Normalize 'lbs' → 'lb' to match backend contract.
    _unit = widget.defaultUnit.startsWith('lb') ? 'lb' : 'kg';
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
          Text('Before we parse…', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Which unit is the weight column in? And if you know the source app, select it — helps disambiguate sibling formats (Hevy vs. Strong CSVs).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text('Weight unit', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Pounds (lb)'),
                  value: 'lb',
                  groupValue: _unit,
                  onChanged: (v) => setState(() => _unit = v ?? 'lb'),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Kilograms (kg)'),
                  value: 'kg',
                  groupValue: _unit,
                  onChanged: (v) => setState(() => _unit = v ?? 'kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Source app', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: DropdownButtonFormField<String>(
                initialValue: _hint,
                items: [
                  for (final s in _sources)
                    DropdownMenuItem(value: s.slug, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _hint = v ?? 'auto'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: () {
                HapticService.light();
                Navigator.of(context).pop(_ImportOptions(
                  unit: _unit,
                  sourceAppHint: _hint == 'auto' ? null : _hint,
                ));
              },
              child: const Text('Preview import'),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
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

