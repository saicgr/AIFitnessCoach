import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../widgets/pill_app_bar.dart';
import '../../core/widgets/line_icon.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/providers/mood_history_provider.dart';
import 'widgets/mood_analytics_card.dart';
import 'widgets/mood_calendar_heatmap.dart';
import 'widgets/mood_history_item_card.dart';
import 'widgets/mood_streak_card.dart';
import 'widgets/mood_weekly_chart.dart';

/// Screen showing mood check-in history and analytics
class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  /// True only on the genuine first-ever open of this screen on this install.
  /// Controls whether the cold-start skeleton (vs. instant cached content) is
  /// shown. Resolved async in [initState] from a SharedPreferences flag.
  bool _isFirstEver = false;

  /// SharedPreferences flag key for the first-open affordance.
  static const String _seenKey = 'mood_history_screen';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Resolve the first-ever flag BEFORE the load resolves so the skeleton is
    // only ever shown on a true cold install — returning users see content.
    CacheFirstView.hasBeenSeen(_seenKey).then((seen) {
      if (mounted) setState(() => _isFirstEver = !seen);
    });
    // Kick off the load without blocking the first frame — the screen renders
    // a skeleton (first open) or stale cached content immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moodHistoryProvider.notifier).initialize();
      ref.read(posthogServiceProvider).capture(eventName: 'mood_history_viewed');
      CacheFirstView.markSeen(_seenKey);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(moodHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(moodHistoryProvider);
    final background = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: background,
      appBar: PillAppBar(
        title: 'Mood History & Analysis',
        actions: [
          PillAppBarAction(
            customIcon: LineIcon(
              'custom_trend',
              size: 20,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : AppColorsLight.textSecondary,
            ),
            onTap: () => context.push('/trends/custom',
                extra: TrendMetric.moodScore),
          ),
          PillAppBarAction(icon: Icons.refresh, onTap: () => ref.read(moodHistoryProvider.notifier).refresh()),
        ],
      ),
      // Cache-first: a cold install shows a layout-matched skeleton, a
      // returning user sees content instantly while the provider revalidates
      // silently. Map the legacy `MoodHistoryState` into an AsyncValue so the
      // shared `CacheFirstView` host can drive the skeleton↔content crossfade.
      body: CacheFirstView<MoodHistoryState>(
        value: _asAsync(state),
        isFirstEver: _isFirstEver,
        traceLabel: 'mood_history',
        skeletonBuilder: (context) => const _MoodHistorySkeleton(),
        contentBuilder: (context, data) => RefreshIndicator(
              onRefresh: () => ref.read(moodHistoryProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Weekly mood chart (always show at top)
                  const SliverToBoxAdapter(
                    child: MoodWeeklyChart(),
                  ),

                  // Analytics summary section
                  if (state.analytics != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Mood Insights',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last ${state.analytics!.summary.daysTracked} days',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: MoodStreakCard(
                        streaks: state.analytics!.streaks,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: MoodAnalyticsCard(
                        analytics: state.analytics!,
                      ),
                    ),
                    // Recommendations
                    if (state.analytics!.recommendations.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildRecommendations(
                          state.analytics!.recommendations,
                          isDark,
                        ),
                      ),
                  ],

                  // Monthly calendar heatmap
                  const SliverToBoxAdapter(
                    child: MoodCalendarHeatmap(),
                  ),
                  // History section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-in History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '${state.totalCount} total',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // History list
                  if (state.checkins.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(textPrimary, textSecondary),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == state.checkins.length) {
                            // Loading indicator at the bottom
                            if (state.isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final checkin = state.checkins[index];
                          final showDateHeader = index == 0 ||
                              !_isSameDay(
                                checkin.checkInTime,
                                state.checkins[index - 1].checkInTime,
                              );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateHeader)
                                _buildDateHeader(
                                  checkin.checkInTime,
                                  textPrimary,
                                  textSecondary,
                                ),
                              MoodHistoryItemCard(
                                item: checkin,
                                onWorkoutTap: checkin.workout?.id != null
                                    ? () => _navigateToWorkout(checkin.workout!.id!)
                                    : null,
                              ),
                            ],
                          );
                        },
                        childCount: state.checkins.length + 1,
                      ),
                    ),
                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  /// Map the [MoodHistoryState] into an [AsyncValue] for [CacheFirstView].
  ///
  /// The provider seeds `checkins` synchronously once loaded; until then a
  /// loading state with no rows drives the skeleton. Once any rows exist (even
  /// stale ones) we always return `AsyncData` so a silent refresh never blanks
  /// the screen back to a skeleton. A hard error with nothing to show surfaces
  /// as `AsyncError`.
  AsyncValue<MoodHistoryState> _asAsync(MoodHistoryState state) {
    final hasContent = state.checkins.isNotEmpty || state.analytics != null;
    if (hasContent) return AsyncValue.data(state);
    if (state.isLoading) return const AsyncValue.loading();
    if (state.error != null) {
      return AsyncValue.error(state.error!, StackTrace.current);
    }
    // Not loading, no error, no content → an empty result; render content
    // (the screen's own empty state) rather than trap behind a skeleton.
    return AsyncValue.data(state);
  }

  Widget _buildDateHeader(
    DateTime? date,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    String label;
    if (checkDate == today) {
      label = 'Today';
    } else if (checkDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('EEEE, MMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mood,
              size: 64,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No mood check-ins yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your mood to get personalized workout suggestions and see your patterns over time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(List<String> recommendations, bool isDark) {
    final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Insights & Suggestions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _navigateToWorkout(String workoutId) {
    context.push('/workout/$workoutId');
  }
}

/// Layout-matched cold-start placeholder for [MoodHistoryScreen].
///
/// Mirrors the real body's vertical rhythm — a weekly-chart block, an insights
/// header, two analytics cards, a calendar block and a short check-in list —
/// so the skeleton→content cross-fade does not reflow. Scrolls so it never
/// overflows on a small device (iPhone SE).
class _MoodHistorySkeleton extends StatelessWidget {
  const _MoodHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        // Weekly mood chart placeholder.
        SkeletonBox(height: 180, radius: 16),
        SizedBox(height: 20),
        // "Your Mood Insights" header + subtitle.
        SkeletonBox(width: 180, height: 20),
        SizedBox(height: 8),
        SkeletonBox(width: 110, height: 14),
        SizedBox(height: 16),
        // Streak + analytics cards.
        SkeletonBox(height: 96, radius: 16),
        SizedBox(height: 16),
        SkeletonBox(height: 140, radius: 16),
        SizedBox(height: 20),
        // Calendar heatmap placeholder.
        SkeletonBox(height: 220, radius: 16),
        SizedBox(height: 20),
        // Check-in history rows.
        SkeletonCard(),
        SizedBox(height: 12),
        SkeletonCard(),
        SizedBox(height: 12),
        SkeletonCard(),
      ],
    );
  }
}
