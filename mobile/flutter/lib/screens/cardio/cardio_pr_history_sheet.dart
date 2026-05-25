import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/cardio_pr.dart';
import '../../data/repositories/cardio_pr_repository.dart';
import '../../widgets/glass_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
/// Bottom sheet showing all cardio PRs grouped by sport. Each row expands
/// inline to a sparkline (line chart of last N attempts) when tapped.
///
/// Pattern mirrors `trophies_earned_sheet.dart`:
/// `showGlassSheet(... child: GlassSheet(child: _Body))`.
Future<void> showCardioPrHistorySheet(BuildContext context) async {
  HapticFeedback.mediumImpact();
  return showGlassSheet<void>(
    context: context,
    builder: (_) => const GlassSheet(
      showHandle: false,
      child: _CardioPrHistoryBody(),
    ),
  );
}

class _CardioPrHistoryBody extends ConsumerWidget {
  const _CardioPrHistoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cardioPrsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7043), Color(0xFFEF5350)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7043).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_run_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).cardioPrHistoryCardioPrs,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary)),
                    Text(AppLocalizations.of(context).cardioPrHistoryAllTimeBestsBy,
                        style: TextStyle(fontSize: 14, color: textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: textSecondary),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

        // Content
        Flexible(
          child: async.when(
            data: (groups) {
              if (groups.isEmpty) {
                return _EmptyState(textPrimary: textPrimary, textSecondary: textSecondary);
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int gi = 0; gi < groups.length; gi++)
                      _SportGroupSection(
                        group: groups[gi],
                        animationDelay: 150 + (gi * 60),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load cardio PRs: $err',
                  style: TextStyle(color: textSecondary)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  const _EmptyState({required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.timer_outlined, size: 48, color: textSecondary),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).cardioPrHistoryNoCardioPrsYet,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).cardioPrHistoryLogACardioSession,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSecondary)),
        ],
      ),
    );
  }
}

class _SportGroupSection extends StatelessWidget {
  final CardioPrGroup group;
  final int animationDelay;

  const _SportGroupSection({
    required this.group,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _sportColor(group.sport).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_sportIcon(group.sport),
                  color: _sportColor(group.sport), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sportLabel(group.sport),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary)),
                  Text(
                    '${group.items.length} ${group.items.length == 1 ? "record" : "records"}',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final item in group.items)
          _CardioPrRow(record: item)
              .animate(delay: Duration(milliseconds: animationDelay))
              .fadeIn()
              .slideX(begin: 0.08),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CardioPrRow extends ConsumerStatefulWidget {
  final CardioPersonalRecord record;
  const _CardioPrRow({required this.record});

  @override
  ConsumerState<_CardioPrRow> createState() => _CardioPrRowState();
}

class _CardioPrRowState extends ConsumerState<_CardioPrRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final r = widget.record;
    final delta = r.formatDelta();
    final sportColor = _sportColor(r.sport);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sportColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_kindIcon(r.kind), color: sportColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.kindLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  )),
                            ),
                            if (r.isFirstTimeActivity)
                              _FirstTimeBadge(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(r.formatValue(),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: sportColor,
                                )),
                            if (delta != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_upward,
                                        size: 11, color: AppColors.green),
                                    const SizedBox(width: 2),
                                    Text(delta,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.green,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            _InlineSparkline(record: r)
                .animate()
                .fadeIn(duration: 200.ms)
                .slideY(begin: -0.05),
        ],
      ),
    );
  }
}

class _InlineSparkline extends ConsumerWidget {
  final CardioPersonalRecord record;
  const _InlineSparkline({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = CardioPrHistoryParams(
      kind: record.kind,
      sport: record.sport,
      limit: 30,
    );
    final async = ref.watch(cardioPrHistoryProvider(params));
    final color = _sportColor(record.sport);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        height: 120,
        child: async.when(
          data: (points) {
            // Prefer endpoint data; fall back to inline sparkline.
            final source = points.isNotEmpty
                ? points
                : record.sparkline;
            if (source.length < 2) {
              return Center(
                child: Text(
                  source.isEmpty
                      ? AppLocalizations.of(context).cardioPrHistoryNoHistoryYet
                      : 'Log another session to see your trend.',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }
            final spots = <FlSpot>[
              for (int i = 0; i < source.length; i++)
                FlSpot(i.toDouble(), source[i].recordValue),
            ];
            return LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 2.5,
                    color: color,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Center(
            child: Text(AppLocalizations.of(context).cardioPrHistoryCouldNotLoadTrend,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _FirstTimeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AppLocalizations.of(context).cardioPrHistoryFirstTime,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.orange,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sport visual mapping (module-private; re-used by row + group header).
// ---------------------------------------------------------------------------

IconData _sportIcon(String sport) {
  switch (sport) {
    case 'running':
      return Icons.directions_run_rounded;
    case 'cycling':
      return Icons.directions_bike_rounded;
    case 'walking':
      return Icons.directions_walk_rounded;
    case 'hiking':
      return Icons.terrain_rounded;
    case 'rowing':
      return Icons.rowing_rounded;
    case 'swimming':
      return Icons.pool_rounded;
    case 'elliptical':
    case 'stairs':
      return Icons.stairs_rounded;
    case 'skiing':
    case 'snowboarding':
      return Icons.downhill_skiing_rounded;
    default:
      return Icons.favorite_rounded;
  }
}

Color _sportColor(String sport) {
  switch (sport) {
    case 'running':
      return AppColors.orange;
    case 'cycling':
      return AppColors.cyan;
    case 'walking':
      return AppColors.green;
    case 'hiking':
      return const Color(0xFF8D6E63);
    case 'rowing':
      return AppColors.purple;
    case 'swimming':
      return const Color(0xFF26C6DA);
    default:
      return AppColors.orange;
  }
}

String _sportLabel(String sport) {
  if (sport.isEmpty) return sport;
  return sport[0].toUpperCase() + sport.substring(1);
}

IconData _kindIcon(String kind) {
  switch (kind) {
    case 'longest_distance':
    case 'biggest_weekly_distance_km':
      return Icons.straighten_rounded;
    case 'longest_duration_session':
      return Icons.timer_rounded;
    case 'fastest_mile':
    case 'fastest_5k':
    case 'fastest_10k':
      return Icons.bolt_rounded;
    case 'best_avg_speed':
      return Icons.speed_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}
