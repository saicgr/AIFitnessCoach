import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/injury.dart';
import '../../data/services/api_client.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/glass_sheet.dart';
import 'injuries_list_screen.dart';
import 'widgets/rehab_exercise_card.dart';

import '../../l10n/generated/app_localizations.dart';
part 'injury_detail_screen_part_check_in_sheet.dart';


/// Screen for viewing detailed information about an injury
class InjuryDetailScreen extends ConsumerStatefulWidget {
  final String injuryId;

  const InjuryDetailScreen({super.key, required this.injuryId});

  @override
  ConsumerState<InjuryDetailScreen> createState() => _InjuryDetailScreenState();
}

class _InjuryDetailScreenState extends ConsumerState<InjuryDetailScreen>
    with CacheFirstMixin {
  bool _isLoading = true;
  String? _error;
  Injury? _injury;
  List<PainHistoryEntry> _painHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInjuryDetails();
  }

  /// Cache-first load: a valid disk blob (keyed by injury id) renders the
  /// detail screen instantly on a cold start; the network revalidate then
  /// swaps in fresh data. A network failure keeps any cached detail on screen.
  Future<void> _loadInjuryDetails() async {
    if (_injury == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    final apiClient = ref.read(apiClientProvider);
    await loadCacheFirst<Map<String, dynamic>>(
      // Keyed by injury id so each injury keeps its own detail slot.
      cacheKey: 'injury_detail_${widget.injuryId}',
      // Detail data is not multi-account sensitive at the key level (the id is
      // globally unique), but pass an empty scope explicitly.
      userId: '',
      ttl: const Duration(hours: 6),
      fetch: () async {
        final response =
            await apiClient.get('/injuries/detail/${widget.injuryId}');
        return response.data as Map<String, dynamic>;
      },
      // The detail payload is a raw JSON map — store/restore as-is.
      decode: (json) => json,
      encode: (data) => data,
      emit: (data, {required bool fromCache}) {
        if (!mounted) return;
        setState(() {
          _applyDetail(data);
          _isLoading = false;
        });
      },
      onError: (e, _) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          // Keep any cached detail on screen; only flag a cold miss.
          if (_injury == null) _error = e.toString();
        });
      },
    );
  }

  /// Parse an injury-detail payload into [_injury] + [_painHistory]. Shared by
  /// the cached and the fresh emit paths.
  void _applyDetail(Map<String, dynamic> data) {
    // Parse the injury from the InjuryWithDetails response.
    var injury = Injury.fromJson(data);

    // Parse pain history from check-ins.
    final checkIns = data['check_ins'] as List<dynamic>? ?? [];
    final painHistory = checkIns
        .where((c) => c['pain_level'] != null)
        .map((c) => PainHistoryEntry(
              date: DateTime.parse(c['checked_at'] as String),
              painLevel: (c['pain_level'] as num).toInt(),
            ))
        .toList();

    // Add the initial pain level from the injury itself if available.
    if (injury.painLevel != null) {
      painHistory.add(PainHistoryEntry(
        date: injury.reportedAt,
        painLevel: injury.painLevel!,
      ));
    }
    painHistory.sort((a, b) => a.date.compareTo(b.date));

    // Parse rehab exercises from the response if not already in injury model.
    if ((injury.rehabExercises == null || injury.rehabExercises!.isEmpty) &&
        (data['rehab_exercises'] as List<dynamic>?)?.isNotEmpty == true) {
      final rehabList = (data['rehab_exercises'] as List<dynamic>)
          .map((e) => RehabExercise.fromJson(e as Map<String, dynamic>))
          .toList();
      injury = injury.copyWith(rehabExercises: rehabList);
    }

    _injury = injury;
    _painHistory = painHistory;
  }

  void _showCheckInSheet() {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _CheckInSheet(
          injury: _injury!,
          onSubmit: (painLevel, notes) async {
            try {
              final apiClient = ref.read(apiClientProvider);
              await apiClient.post(
                '/injuries/${_injury!.id}/check-in',
                data: {
                  'pain_level': painLevel,
                  if (notes != null) 'notes': notes,
                },
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).injuryDetailCheckInLoggedSuccessfully),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to log check-in: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
            _loadInjuryDetails();
          },
        ),
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
          AppLocalizations.of(context).injuryDetailMarkAsHealed,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context).injuryDetailAreYouSureThis,
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).buttonCancel,
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiClient = ref.read(apiClientProvider);
                await apiClient.delete('/injuries/${_injury!.id}');
                // Refresh the injuries list
                ref.read(injuriesListProvider.notifier).loadInjuries();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).injuryDetailCongratulationsOnYourRecove),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to mark as healed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).injuryDetailYesHealed),
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
      appBar: PillAppBar(
        title: AppLocalizations.of(context).injuryDetailInjuryDetails,
        actions: [
          if (_injury != null && _injury!.status.toLowerCase() != 'healed')
            PillAppBarAction(icon: Icons.edit_note, onTap: _showCheckInSheet),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
              ? _buildErrorState(textPrimary, textSecondary)
              : _injury == null
                  ? _buildEmptyState(textPrimary, textSecondary, textMuted)
                  : _buildContent(isDark, textPrimary, textSecondary, textMuted, elevated, cardBorder),
    );
  }

  /// Layout-matched skeleton: header card, recovery-progress card, pain-history
  /// card and a rehab section — mirrors `_buildContent` so the swap is
  /// reflow-free.
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 150, radius: 20),
        SizedBox(height: 24),
        SkeletonBox(height: 110, radius: 16),
        SizedBox(height: 24),
        SkeletonBox(height: 170, radius: 16),
        SizedBox(height: 24),
        SkeletonBox(width: 160, height: 18),
        SizedBox(height: 12),
        SkeletonBox(height: 88, radius: 16),
      ],
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
            AppLocalizations.of(context).workoutGenerationSomethingWentWrong,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? AppLocalizations.of(context).subscriptionManagementUnknownError,
            style: TextStyle(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInjuryDetails,
            child: Text(AppLocalizations.of(context).workoutStateCardsTryAgain),
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
            AppLocalizations.of(context).injuryDetailInjuryNotFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).injuryDetailThisInjuryMayHave,
            style: TextStyle(color: textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context).workoutCompleteScreenGoBack),
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
                label: Text(AppLocalizations.of(context).injuryDetailMarkAsHealed2),
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
                AppLocalizations.of(context).injuryDetailRecoveryProgress,
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
            AppLocalizations.of(context).injuryDetailPainLevelHistory,
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
                AppLocalizations.of(context).injuryDetailAffectedExercises,
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
              AppLocalizations.of(context).injuryDetailRehabExercises,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/library?filter=rehab'),
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
                setState(() {
                  // Toggle completion state locally
                });
                HapticFeedback.selectionClick();
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
                AppLocalizations.of(context).syncedWorkoutDetailNotes,
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
