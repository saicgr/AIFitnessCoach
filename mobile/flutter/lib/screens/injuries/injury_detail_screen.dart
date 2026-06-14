import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/injury.dart';
import '../../data/services/api_client.dart';
import '../../widgets/design_system/zealova.dart';
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
    final tc = ThemeColors.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tc.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          AppLocalizations.of(context).injuryDetailMarkAsHealed.toUpperCase(),
          style: ZType.disp(20, color: tc.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).injuryDetailAreYouSureThis,
          style: ZType.ser(14, color: tc.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).buttonCancel.toUpperCase(),
              style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 1.5),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.success,
              foregroundColor: tc.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
            child: Text(AppLocalizations.of(context).injuryDetailYesHealed),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = tc.isDark;
    final backgroundColor = tc.background;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final elevated = tc.surface;
    final cardBorder = AppColors.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).injuryDetailInjuryDetails,
        kicker: 'RECOVERY',
        actions: [
          if (_injury != null && _injury!.status.toLowerCase() != 'healed')
            GestureDetector(
              onTap: _showCheckInSheet,
              child: Icon(Icons.edit_note, size: 24, color: tc.textPrimary),
            ),
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
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: tc.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).workoutGenerationSomethingWentWrong.toUpperCase(),
              style: ZType.disp(20, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? AppLocalizations.of(context).subscriptionManagementUnknownError,
              style: ZType.ser(14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ZealovaButton(
              label: AppLocalizations.of(context).workoutStateCardsTryAgain,
              variant: ZealovaButtonVariant.ghost,
              expand: false,
              onTap: _loadInjuryDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: textMuted),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).injuryDetailInjuryNotFound.toUpperCase(),
              style: ZType.disp(20, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).injuryDetailThisInjuryMayHave,
              style: ZType.ser(14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ZealovaButton(
              label: AppLocalizations.of(context).workoutCompleteScreenGoBack,
              variant: ZealovaButtonVariant.ghost,
              expand: false,
              onTap: () => context.pop(),
            ),
          ],
        ),
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showMarkHealedDialog,
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ThemeColors.of(context).success,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: ThemeColors.of(context).background),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).injuryDetailMarkAsHealed2.toUpperCase(),
                        style: ZType.lbl(14,
                            color: ThemeColors.of(context).background,
                            letterSpacing: 2.5),
                      ),
                    ],
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
    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.personal_injury,
                  color: severityColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      injury.bodyPartDisplay.toUpperCase(),
                      style: ZType.disp(24, color: textPrimary),
                    ),
                    if (injury.injuryType != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatInjuryType(injury.injuryType!),
                        style: ZType.ser(14, color: textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  injury.severityDisplay.toUpperCase(),
                  style: ZType.lbl(10, color: severityColor, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                'Reported ${DateFormat('MMM d').format(injury.reportedAt)}',
                textSecondary,
              ),
              _buildInfoChip(
                Icons.healing,
                injury.recoveryPhaseDisplay,
                textSecondary,
              ),
              if (injury.painLevel != null)
                _buildInfoChip(
                  Icons.sentiment_dissatisfied,
                  'Pain: ${injury.painLevel}/10',
                  _getPainColor(injury.painLevel!),
                ),
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
        const SizedBox(width: 5),
        Text(
          text.toUpperCase(),
          style: ZType.lbl(10, color: color, letterSpacing: 1),
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
    final tc = ThemeColors.of(context);
    final progressColor = injury.recoveryProgress >= 75
        ? tc.success
        : injury.recoveryProgress >= 50
            ? tc.warning
            : tc.error;

    return ZealovaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ZealovaSectionKicker(
                    AppLocalizations.of(context).injuryDetailRecoveryProgress),
              ),
              Text(
                '${injury.recoveryProgress.toInt()}%',
                style: ZType.disp(28, color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: injury.recoveryProgress / 100,
              backgroundColor: AppColors.hairlineStrong,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 10,
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
                  style: ZType.lbl(10, color: textMuted, letterSpacing: 1),
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
    return ZealovaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZealovaSectionKicker(
              AppLocalizations.of(context).injuryDetailPainLevelHistory),
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
                      style: ZType.data(13, color: color),
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
                      style: ZType.lbl(9, color: textMuted, letterSpacing: 0.5),
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
    final tc = ThemeColors.of(context);
    return ZealovaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: tc.warning, size: 18),
              const SizedBox(width: 8),
              ZealovaSectionKicker(
                  AppLocalizations.of(context).injuryDetailAffectedExercises),
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
                  color: tc.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tc.warning.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _formatExerciseName(exercise).toUpperCase(),
                  style: ZType.lbl(10, color: tc.warning, letterSpacing: 1),
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
              AppLocalizations.of(context).injuryDetailRehabExercises.toUpperCase(),
              style: ZType.disp(20, color: textPrimary),
            ),
            TextButton(
              onPressed: () => context.push('/library?filter=rehab'),
              child: Text('View All'.toUpperCase(),
                  style: ZType.lbl(11,
                      color: ThemeColors.of(context).accent, letterSpacing: 1.5)),
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
    return ZealovaCard(
      variant: ZealovaCardVariant.flat,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: textMuted, size: 18),
              const SizedBox(width: 8),
              ZealovaSectionKicker(
                  AppLocalizations.of(context).syncedWorkoutDetailNotes),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            injury.notes!,
            style: ZType.ser(14, color: textMuted, style: FontStyle.normal),
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
