import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/injury.dart';
import 'widgets/rehab_exercise_card.dart';

/// Screen for viewing detailed information about an injury
class InjuryDetailScreen extends ConsumerStatefulWidget {
  final String injuryId;

  const InjuryDetailScreen({super.key, required this.injuryId});

  @override
  ConsumerState<InjuryDetailScreen> createState() => _InjuryDetailScreenState();
}

class _InjuryDetailScreenState extends ConsumerState<InjuryDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Injury? _injury;
  List<PainHistoryEntry> _painHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInjuryDetails();
  }

  Future<void> _loadInjuryDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample data for demonstration
      _injury = Injury(
        id: widget.injuryId,
        userId: 'user1',
        bodyPart: 'shoulder',
        injuryType: 'strain',
        severity: 'moderate',
        reportedAt: DateTime.now().subtract(const Duration(days: 7)),
        occurredAt: DateTime.now().subtract(const Duration(days: 8)),
        expectedRecoveryDate: DateTime.now().add(const Duration(days: 14)),
        recoveryPhase: 'subacute',
        painLevel: 4,
        affectsExercises: ['overhead_press', 'bench_press', 'lateral_raise'],
        affectsMuscles: ['deltoid', 'rotator_cuff'],
        notes: 'Happened during heavy overhead press. Felt a sharp pain in the anterior deltoid area.',
        status: 'active',
        rehabExercises: [
          const RehabExercise(
            exerciseName: 'Shoulder Pendulum',
            exerciseType: 'mobility',
            sets: 3,
            reps: 10,
            frequencyPerDay: 2,
            notes: 'Gentle swinging motion',
          ),
          const RehabExercise(
            exerciseName: 'External Rotation Stretch',
            exerciseType: 'stretch',
            sets: 3,
            holdSeconds: 30,
            frequencyPerDay: 2,
          ),
          const RehabExercise(
            exerciseName: 'Band External Rotation',
            exerciseType: 'strength',
            sets: 3,
            reps: 15,
            frequencyPerDay: 1,
            notes: 'Use light resistance band',
          ),
        ],
      );

      _painHistory = [
        PainHistoryEntry(date: DateTime.now().subtract(const Duration(days: 7)), painLevel: 7),
        PainHistoryEntry(date: DateTime.now().subtract(const Duration(days: 5)), painLevel: 6),
        PainHistoryEntry(date: DateTime.now().subtract(const Duration(days: 3)), painLevel: 5),
        PainHistoryEntry(date: DateTime.now().subtract(const Duration(days: 1)), painLevel: 4),
      ];

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showCheckInSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckInSheet(
        injury: _injury!,
        onSubmit: (painLevel, notes) async {
          // TODO: API call to log check-in
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in logged successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadInjuryDetails();
        },
      ),
    );
  }

  void _showMarkHealedDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark as Healed?',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure this injury has fully healed? This will move it to your injury history.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: API call to mark as healed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Congratulations on your recovery!'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Healed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Injury Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_injury != null && _injury!.status.toLowerCase() != 'healed')
            IconButton(
              icon: Icon(Icons.edit_note, color: textPrimary),
              onPressed: _showCheckInSheet,
              tooltip: 'Log Check-in',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(textPrimary, textSecondary)
              : _injury == null
                  ? _buildEmptyState(textPrimary, textSecondary, textMuted)
                  : _buildContent(isDark, textPrimary, textSecondary, textMuted, elevated, cardBorder),
    );
  }

  Widget _buildErrorState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInjuryDetails,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: textMuted),
          const SizedBox(height: 16),
          Text(
            'Injury not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This injury may have been deleted',
            style: TextStyle(color: textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    final injury = _injury!;
    final severityColor = _getSeverityColor(injury.severity);
    final isHealed = injury.status.toLowerCase() == 'healed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _buildHeaderCard(injury, severityColor, isDark, textPrimary, textSecondary, elevated),

          const SizedBox(height: 24),

          // Recovery progress
          if (!isHealed)
            _buildRecoveryProgressCard(injury, textPrimary, textMuted, elevated, cardBorder),

          if (!isHealed) const SizedBox(height: 24),

          // Pain history chart
          if (_painHistory.isNotEmpty)
            _buildPainHistoryCard(textPrimary, textMuted, elevated, cardBorder),

          if (_painHistory.isNotEmpty) const SizedBox(height: 24),

          // Affected exercises
          if (injury.affectsExercises.isNotEmpty)
            _buildAffectedExercisesCard(injury, textPrimary, textMuted, elevated, cardBorder),

          if (injury.affectsExercises.isNotEmpty) const SizedBox(height: 24),

          // Rehab exercises
          if (injury.rehabExercises?.isNotEmpty ?? false)
            _buildRehabExercisesSection(injury, textPrimary, textSecondary, textMuted, elevated),

          if (injury.rehabExercises?.isNotEmpty ?? false) const SizedBox(height: 24),

          // Notes
          if (injury.notes != null && injury.notes!.isNotEmpty)
            _buildNotesCard(injury, textPrimary, textMuted, elevated),

          if (injury.notes != null && injury.notes!.isNotEmpty) const SizedBox(height: 24),

          // Mark as healed button
          if (!isHealed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showMarkHealedDialog,
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Healed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    Injury injury,
    Color severityColor,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color elevated,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.personal_injury,
                  color: severityColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      injury.bodyPartDisplay,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (injury.injuryType != null)
                      Text(
                        _formatInjuryType(injury.injuryType!),
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  injury.severityDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                'Reported ${DateFormat('MMM d').format(injury.reportedAt)}',
                textSecondary,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.healing,
                injury.recoveryPhaseDisplay,
                textSecondary,
              ),
              if (injury.painLevel != null) ...[
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.sentiment_dissatisfied,
                  'Pain: ${injury.painLevel}/10',
                  _getPainColor(injury.painLevel!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryProgressCard(
    Injury injury,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    final progressColor = injury.recoveryProgress >= 75
        ? AppColors.success
        : injury.recoveryProgress >= 50
            ? AppColors.warning
            : AppColors.coral;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recovery Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '${injury.recoveryProgress.toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: injury.recoveryProgress / 100,
              backgroundColor: cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 12,
            ),
          ),
          if (injury.expectedRecoveryDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  'Expected recovery: ${DateFormat('MMM d, yyyy').format(injury.expectedRecoveryDate!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPainHistoryCard(
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pain Level History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _painHistory.map((entry) {
                final color = _getPainColor(entry.painLevel);
                final heightPercent = entry.painLevel / 10;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.painLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 60 * heightPercent,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('M/d').format(entry.date),
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffectedExercisesCard(
    Injury injury,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Affected Exercises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: injury.affectsExercises.map((exercise) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _formatExerciseName(exercise),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warning,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRehabExercisesSection(
    Injury injury,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color elevated,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rehab Exercises',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to rehab exercise list
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(injury.rehabExercises ?? []).map((exercise) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RehabExerciseCard(
              exercise: exercise,
              onToggleComplete: () {
                // TODO: Toggle completion
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesCard(Injury injury, Color textPrimary, Color textMuted, Color elevated) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: textMuted, size: 20),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            injury.notes!,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return AppColors.success;
      case 'moderate':
        return AppColors.warning;
      case 'severe':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  Color _getPainColor(int painLevel) {
    if (painLevel <= 3) return AppColors.success;
    if (painLevel <= 6) return AppColors.warning;
    return AppColors.error;
  }

  String _formatInjuryType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatExerciseName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

/// Pain history entry model
class PainHistoryEntry {
  final DateTime date;
  final int painLevel;

  PainHistoryEntry({required this.date, required this.painLevel});
}

/// Bottom sheet for logging check-ins
class _CheckInSheet extends StatefulWidget {
  final Injury injury;
  final Function(int painLevel, String? notes) onSubmit;

  const _CheckInSheet({
    required this.injury,
    required this.onSubmit,
  });

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  int _painLevel = 5;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _painLevel = widget.injury.painLevel ?? 5;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final painColor = _painLevel <= 3
        ? AppColors.success
        : _painLevel <= 6
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Daily Check-in',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How is your ${widget.injury.bodyPartDisplay.toLowerCase()} feeling today?',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // Pain level selector
              Center(
                child: Column(
                  children: [
                    Text(
                      '$_painLevel',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: painColor,
                      ),
                    ),
                    Text(
                      '/10',
                      style: TextStyle(
                        fontSize: 20,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Slider(
                value: _painLevel.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: painColor,
                inactiveColor: painColor.withValues(alpha: 0.2),
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _painLevel = value.round();
                  });
                },
              ),

              const SizedBox(height: 24),

              // Notes field
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Any notes about how it feels today...',
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: isDark ? AppColors.pureBlack : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.coral, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          await widget.onSubmit(
                            _painLevel,
                            _notesController.text.isNotEmpty ? _notesController.text : null,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Log Check-in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
