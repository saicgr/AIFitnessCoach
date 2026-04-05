import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/insights_report.dart';
import '../../data/models/weekly_summary.dart';
import '../../data/providers/insights_provider.dart';
import '../../data/repositories/weekly_summary_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';

part 'insights_screen_part_period_selector.dart';
part 'insights_screen_part_body_card.dart';


// ---------------------------------------------------------------------------
// InsightsScreen — main Insights tab replacing the old WeeklySummaryScreen.
// Shows period-selectable data cards and a list of past weekly reports.
// ---------------------------------------------------------------------------

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'insights_viewed');
    });
  }

  Future<void> _loadInitialData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (!mounted || userId == null) return;
    setState(() => _userId = userId);
    ref.read(insightsProvider.notifier).loadReport(userId);
    ref.read(weeklySummaryProvider.notifier).loadSummaries(userId);
  }

  Future<void> _refresh() async {
    if (_userId == null) return;
    await Future.wait([
      ref.read(insightsProvider.notifier).loadReport(_userId!),
      ref.read(weeklySummaryProvider.notifier).loadSummaries(_userId!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insightsState = ref.watch(insightsProvider);
    final summaryState = ref.watch(weeklySummaryProvider);

    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Insights'),
      body: Column(
        children: [
          // Period selector
          _PeriodSelector(
            selected: insightsState.selectedPeriod,
            isDark: isDark,
            onSelect: (period) {
              if (_userId == null) return;
              ref
                  .read(insightsProvider.notifier)
                  .selectPeriod(period, _userId!);
            },
          ),

          // Main content
          Expanded(
            child: insightsState.isLoadingReport
                ? _LoadingState(isDark: isDark)
                : insightsState.error != null && insightsState.report == null
                    ? _ErrorState(
                        error: insightsState.error!,
                        isDark: isDark,
                        onRetry: _refresh,
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: purple,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 8),

                            // Data cards
                            if (insightsState.report != null) ...[
                              _OverviewCard(
                                totals: insightsState.report!.totals,
                                previousTotals:
                                    insightsState.report!.previousTotals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 50.ms)
                                  .slideY(begin: 0.1),
                              _NutritionCard(
                                totals: insightsState.report!.totals,
                                previousTotals:
                                    insightsState.report!.previousTotals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 100.ms)
                                  .slideY(begin: 0.1),
                              _RecoveryCard(
                                totals: insightsState.report!.totals,
                                previousTotals:
                                    insightsState.report!.previousTotals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 150.ms)
                                  .slideY(begin: 0.1),
                              _BodyCard(
                                totals: insightsState.report!.totals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.1),
                            ],

                            // AI Narrative section
                            _AiNarrativeSection(
                              narrative: insightsState.narrative,
                              isGenerating: insightsState.isGeneratingNarrative,
                              hasReport: insightsState.report != null,
                              isDark: isDark,
                              onGenerate: () {
                                if (_userId == null) return;
                                ref
                                    .read(insightsProvider.notifier)
                                    .generateNarrative(_userId!);
                              },
                            )
                                .animate()
                                .fadeIn(delay: 250.ms)
                                .slideY(begin: 0.1),

                            const SizedBox(height: 24),

                            // Past Reports section
                            _SectionHeader(
                              title: 'Past Reports',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),

                            if (summaryState.isLoading)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: purple,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (summaryState.summaries.isEmpty)
                              _EmptyPastReports(isDark: isDark)
                            else
                              ...summaryState.summaries
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return _PastReportCard(
                                  summary: entry.value,
                                  isDark: isDark,
                                  onTap: () {
                                    context.push(
                                      '/insights/detail',
                                      extra: entry.value,
                                    );
                                  },
                                )
                                    .animate()
                                    .fadeIn(delay: (300 + 50 * entry.key).ms)
                                    .slideY(begin: 0.1);
                              }),

                            // Bottom padding for safe area
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 24,
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
