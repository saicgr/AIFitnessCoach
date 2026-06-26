import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/weekly_plan.dart';
import '../../../data/services/api_client.dart';
import '../../../services/mesocycle_planner.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Header widget showing weekly plan overview
class PlanHeader extends StatelessWidget {
  final WeeklyPlan plan;

  const PlanHeader({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                plan.dateRangeDisplay,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (plan.isCurrentWeek)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context).workoutCompleteThisWeek,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          // Periodization label — "Week X of N · Phase" (Calorii-audit P4.2).
          // Self-hides when there's no active mesocycle.
          const _MesocyclePhaseChip(),
          // Recommended training block from the strength→skill ratio
          // (Dr-Yaad audit #7). Self-hides until there's enough signal.
          const _BlockRecommendationChip(),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                icon: Icons.fitness_center,
                label: AppLocalizations.of(context).settingsTrainingSection,
                value: AppLocalizations.of(context)!.planHeaderDays(plan.trainingDayCount),
                color: Colors.green,
              ),
              _buildStatItem(
                context,
                icon: Icons.self_improvement,
                label: AppLocalizations.of(context).workoutSummaryAdvancedRest,
                value: AppLocalizations.of(context)!.planHeaderDays2(plan.restDayCount),
                color: Colors.grey,
              ),
              _buildStatItem(
                context,
                icon: Icons.local_fire_department,
                label: AppLocalizations.of(context).weeklyCheckinSheetAvgCalories,
                value: '${plan.avgDailyCalories}',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fasting & Nutrition info
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (plan.fastingProtocol != null)
                _buildChip(
                  context,
                  icon: Icons.timer,
                  label: plan.fastingProtocol!,
                  color: colorScheme.secondary,
                ),
              _buildChip(
                context,
                icon: Icons.restaurant,
                label: plan.parsedNutritionStrategy.displayName,
                color: colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Week X of N · <phase>" chip. Loads the active mesocycle context async and
/// hides itself when none is set. (Calorii-audit P4.2 — periodization label.)
class _MesocyclePhaseChip extends StatefulWidget {
  const _MesocyclePhaseChip();

  @override
  State<_MesocyclePhaseChip> createState() => _MesocyclePhaseChipState();
}

/// Recommended training block from the strength→skill ratio (Dr-Yaad #7).
/// Fetches `/progress/block-recommendation`; self-hides on no data / error.
class _BlockRecommendationChip extends ConsumerStatefulWidget {
  const _BlockRecommendationChip();

  @override
  ConsumerState<_BlockRecommendationChip> createState() =>
      _BlockRecommendationChipState();
}

class _BlockRecommendationChipState
    extends ConsumerState<_BlockRecommendationChip> {
  String? _block;
  String? _reason;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) return;
    try {
      final resp = await ref.read(apiClientProvider).get(
            '/progress/block-recommendation',
            queryParameters: {'user_id': userId},
          );
      final data = resp.data as Map?;
      if (mounted && data != null) {
        setState(() {
          _block = data['block'] as String?;
          _reason = data['reason'] as String?;
        });
      }
    } catch (_) {
      // Non-critical — chip stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = _block;
    if (block == null || block.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Tooltip(
        message: _reason ?? '',
        triggerMode: TooltipTriggerMode.tap,
        child: Row(
          children: [
            Icon(Icons.recommend_rounded,
                size: 16, color: cs.onPrimaryContainer),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Recommended block: $block',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline_rounded,
                size: 13, color: cs.onPrimaryContainer.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _MesocyclePhaseChipState extends State<_MesocyclePhaseChip> {
  MesocycleContext? _ctx;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await MesocyclePlanner.getCurrentContext();
      if (mounted) setState(() => _ctx = c);
    } catch (_) {
      // Non-critical — chip simply stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _ctx;
    if (ctx == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.timeline_rounded, size: 16, color: cs.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            'Week ${ctx.weekNumber} of ${ctx.totalWeeks} · ${ctx.phaseDisplayName}',
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
