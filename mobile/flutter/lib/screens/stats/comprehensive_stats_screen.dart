import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/pill_app_bar.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/progress_photos.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/models/milestone.dart';
import '../../data/providers/milestones_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/animations/app_animations.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/activity_heatmap.dart';
import '../../widgets/exercise_search_results.dart';
import '../../widgets/glass_sheet.dart';
import 'package:flutter/services.dart';
import '../../widgets/workout_day_detail_sheet.dart';
import '../progress/comparison_gallery.dart';
import '../progress/comparison_view.dart';
import '../progress/photo_editor_screen.dart';
import '../progress/widgets/readiness_checkin_card.dart';
import '../progress/widgets/strength_overview_card.dart';
import '../../data/providers/mood_history_provider.dart';
import '../../widgets/mood_picker_sheet.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/providers/nutrition_stats_provider.dart';
import '../../widgets/nutrition/health_metrics_card.dart';
import '../../widgets/nutrition/food_mood_analytics_card.dart';
import '../mood/widgets/mood_weekly_chart.dart';
import '../mood/widgets/mood_streak_card.dart';
import '../mood/widgets/mood_analytics_card.dart';
import '../mood/widgets/mood_calendar_heatmap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/measurements_repository.dart';
import 'widgets/date_range_filter_sheet.dart';
import 'widgets/export_stats_sheet.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/share_stats_sheet.dart';

/// Comprehensive Stats Screen
/// Combines: Workout stats, achievements, body measurements, progress graphs, nutrition
class ComprehensiveStatsScreen extends ConsumerStatefulWidget {
  /// If true, opens the add photo sheet immediately after loading
  final bool openPhotoSheet;

  /// If set, opens this tab index on load
  final int? initialTab;

  const ComprehensiveStatsScreen({
    super.key,
    this.openPhotoSheet = false,
    this.initialTab,
  });

  @override
  ConsumerState<ComprehensiveStatsScreen> createState() => _ComprehensiveStatsScreenState();
}

class _ComprehensiveStatsScreenState extends ConsumerState<ComprehensiveStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    if (widget.initialTab != null && widget.initialTab! >= 0 && widget.initialTab! < 6) {
      _tabController.index = widget.initialTab!;
    }
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'comprehensive_stats_viewed');
    });
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() {
        _userId = userId;
      });
      // Load photos data
      ref.read(progressPhotosNotifierProvider(userId).notifier).loadAll();
      // Load milestones data
      ref.read(milestonesProvider.notifier).loadMilestoneProgress(userId: userId);
      // Load scores overview (consistency, readiness, etc.)
      ref.read(scoresProvider.notifier).loadScoresOverview(userId: userId);
      // Load personal records
      ref.read(scoresProvider.notifier).loadPersonalRecords(userId: userId);

      // If openPhotoSheet is requested, switch to Photos tab
      if (widget.openPhotoSheet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tabController.animateTo(1); // Switch to Photos tab (index 1)
          }
        });
      }
    }
  }

  static const _tabLabels = ['Overview', 'Photos', 'Score', 'Measurements', 'Nutrition', 'Mood'];
  static const _tabIcons = [
    Icons.dashboard_rounded,      // Overview
    Icons.photo_library_rounded,  // Photos
    Icons.emoji_events_rounded,   // Score
    Icons.straighten_rounded,     // Measurements
    Icons.restaurant_rounded,     // Nutrition
    Icons.mood_rounded,           // Mood
  ];
  static const _tabColors = [
    Color(0xFF3B82F6), // Overview - Blue
    Color(0xFFA855F7), // Photos - Purple
    Color(0xFFF97316), // Score - Orange
    Color(0xFF22C55E), // Measurements - Green
    Color(0xFFEF4444), // Nutrition - Red
    Color(0xFFEC4899), // Mood - Pink
  ];

  Widget _buildPillTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(_tabLabels.length, (i) {
              final animValue = _tabController.animation?.value ?? 0.0;
              final progress = (1.0 - (animValue - i).abs()).clamp(0.0, 1.0);
              final isSelected = _tabController.index == i;
              final pillColor = _tabColors[i];

              final bg = Color.lerp(
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                pillColor,
                progress,
              )!;
              final fg = Color.lerp(mutedText, Colors.white, progress)!;

              return Padding(
                padding: EdgeInsets.only(right: i < _tabLabels.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _tabController.animateTo(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: pillColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tabIcons[i], size: 16, color: fg),
                        const SizedBox(width: 6),
                        Text(
                          _tabLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Stats & Scores',
        actions: [
          // Compare Photos (only on Photos tab)
          PillAppBarAction(
            icon: Icons.compare_arrows_rounded,
            visible: _userId != null && _currentTabIndex == 1,
            onTap: () => _showComparisonPicker(),
          ),
          // Time Range Selector (hide on Photos tab)
          PillAppBarAction(
            icon: Icons.calendar_month_outlined,
            visible: _currentTabIndex != 1,
            onTap: () => DateRangeFilterSheet.show(context, ref),
          ),
          // Export
          PillAppBarAction(
            icon: Icons.file_download_outlined,
            onTap: () => ExportStatsSheet.show(context, ref),
          ),
          // Share
          PillAppBarAction(
            icon: Icons.ios_share_outlined,
            onTap: () => ShareStatsSheet.show(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pill Tab Bar
          _buildPillTabBar(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(),
                _PhotosTab(userId: _userId, openPhotoSheet: widget.openPhotoSheet),
                _StrengthTab(userId: _userId),
                _MeasurementsTab(userId: _userId),
                _NutritionTab(userId: _userId),
                _MoodTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComparisonPicker() {
    if (_userId == null) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => ComparisonView(userId: _userId!),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// OVERVIEW TAB - Summary stats, recent achievements, weekly progress
// ═══════════════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  Set<String> _highlightedDates = {};
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final completedCount = workoutsNotifier.completedCount;
    final weeklyProgress = workoutsNotifier.weeklyProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final consistencyState = ref.watch(consistencyProvider);
    final currentStreak = consistencyState.currentStreak;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Update highlighted dates when search query changes
    _updateHighlightedDates(searchQuery);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Heatmap Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            child: Column(
              children: [
                ActivityHeatmap(
                  highlightedDates: _highlightedDates,
                  isSearchActive: _showSearch || (searchQuery != null && searchQuery.isNotEmpty),
                  onSearchTapped: () {
                    HapticService.light();
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        // Clear search when closing
                        ref.read(exerciseSearchQueryProvider.notifier).state = null;
                        _highlightedDates = {};
                      }
                    });
                  },
                  onDayTapped: (date) {
                    HapticService.light();
                    WorkoutDayDetailSheet.show(context, date);
                  },
                ),
                // Expandable Search Bar
                if (_showSearch) ...[
                  const SizedBox(height: 12),
                  ExerciseSearchBar(
                    onSearch: (exerciseName) {
                      // Search results will automatically update via provider
                    },
                    onClear: () {
                      setState(() {
                        _highlightedDates = {};
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          // Search Results (shown when search is active)
          if (searchQuery != null && searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExerciseSearchResults(
              exerciseName: searchQuery,
              onResultTapped: (date) {
                // Optionally highlight the tapped date
              },
            ),
          ],

          const SizedBox(height: 16),

          // Compact Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CompactStat(
                  icon: Icons.fitness_center,
                  value: '$completedCount',
                  label: 'Total',
                  color: AppColors.cyan,
                ),
                _StatDivider(),
                _CompactStat(
                  icon: Icons.local_fire_department,
                  value: '${weeklyProgress.$1}/${weeklyProgress.$2}',
                  label: 'Week',
                  color: AppColors.orange,
                ),
                _StatDivider(),
                _CompactStat(
                  icon: Icons.trending_up,
                  value: currentStreak > 0 ? '$currentStreak' : '0',
                  label: 'Streak',
                  color: AppColors.success,
                ),
                _StatDivider(),
                _CompactStat(
                  icon: Icons.timer_outlined,
                  value: workoutsNotifier.totalDurationFormatted,
                  label: 'Time',
                  color: AppColors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Achievements Preview
          _SectionHeader(
            title: 'Recent Achievements',
            onViewAll: () => context.push('/achievements'),
          ),
          const SizedBox(height: 12),
          _AchievementsPreview(),

          const SizedBox(height: 24),

          // Quick Actions
          _SectionHeader(title: 'Quick Access'),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.monitor_weight_outlined,
            label: 'Body Measurements',
            onTap: () => context.push('/measurements'),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.calendar_month,
            label: 'Weekly Summaries',
            onTap: () => context.push('/summaries'),
          ),

          // Bottom padding for floating nav bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _updateHighlightedDates(String? searchQuery) async {
    if (searchQuery == null || searchQuery.isEmpty) {
      if (_highlightedDates.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _highlightedDates = {};
            });
          }
        });
      }
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final timeRange = ref.read(heatmapTimeRangeProvider);

      final userId = await apiClient.getUserId();
      if (userId == null || !mounted) return;

      final response = await ref.read(exerciseSearchProvider((
        userId: userId,
        exerciseName: searchQuery,
        weeks: timeRange.weeks,
      )).future);

      if (!mounted) return;
      setState(() {
        _highlightedDates = response.matchingDates.toSet();
      });
    } catch (_) {
      // Ignore errors
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// PHOTOS TAB - Progress photos from different angles
// ═══════════════════════════════════════════════════════════════════

class _PhotosTab extends ConsumerStatefulWidget {
  final String? userId;
  final bool openPhotoSheet;

  const _PhotosTab({this.userId, this.openPhotoSheet = false});

  @override
  ConsumerState<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<_PhotosTab>
    with AutomaticKeepAliveClientMixin {
  PhotoViewType? _selectedViewFilter;
  bool _hasOpenedPhotoSheet = false;
  int _gridColumns = 3;
  bool _sortNewestFirst = true;
  bool _latestByViewExpanded = true;
  bool _savedComparisonsExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Open photo sheet if requested and not already opened
    if (widget.openPhotoSheet && !_hasOpenedPhotoSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasOpenedPhotoSheet) {
          _hasOpenedPhotoSheet = true;
          _showAddPhotoSheet();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    if (widget.userId == null) {
      return AppLoading.fullScreen();
    }

    final state = ref.watch(progressPhotosNotifierProvider(widget.userId!));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref
              .read(progressPhotosNotifierProvider(widget.userId!).notifier)
              .loadAll(),
          child: CustomScrollView(
            slivers: [
              // Stats Card
              SliverToBoxAdapter(
                child: _buildPhotoStatsCard(state),
              ),

              // View Type Filter
              SliverToBoxAdapter(
                child: _buildViewTypeFilter(),
              ),

              // Latest Photos by View
              if (state.latestByView != null && _selectedViewFilter == null)
                SliverToBoxAdapter(
                  child: _buildLatestPhotosByView(state.latestByView!),
                ),

              // Sort & Grid Controls
              SliverToBoxAdapter(
                child: _buildGridControls(),
              ),

              // Saved Comparisons section
              SliverToBoxAdapter(
                child: _buildSavedComparisonsSection(),
              ),

              // Photo Grid
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.photos.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyPhotosState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridColumns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 8,
                      childAspectRatio: _gridColumns == 2 ? 0.6 : _gridColumns == 4 ? 0.7 : 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var filteredPhotos = _selectedViewFilter == null
                            ? state.photos.toList()
                            : state.photos
                                .where((p) =>
                                    p.viewTypeEnum == _selectedViewFilter)
                                .toList();
                        if (!_sortNewestFirst) {
                          filteredPhotos = filteredPhotos.reversed.toList();
                        }
                        if (index >= filteredPhotos.length) return null;
                        return _buildPhotoCard(filteredPhotos[index]);
                      },
                      childCount: _selectedViewFilter == null
                          ? state.photos.length
                          : state.photos
                              .where(
                                  (p) => p.viewTypeEnum == _selectedViewFilter)
                              .length,
                    ),
                  ),
                ),

              // FAB spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
        // Camera FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _showAddPhotoSheet,
            backgroundColor: accentColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoStatsCard(ProgressPhotosState state) {
    final stats = state.stats;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final totalPhotos = stats?.totalPhotos ?? 0;
    final viewsCaptured = stats?.viewTypesCaptured ?? 0;
    final viewsTotal = PhotoViewType.values.length;
    final tracking = stats?.formattedTrackingDuration ?? '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            '$totalPhotos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          Text(
            ' photos',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('·', style: TextStyle(fontSize: 14, color: textMuted)),
          ),
          Text(
            '$viewsCaptured/$viewsTotal',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          Text(
            ' views',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('·', style: TextStyle(fontSize: 14, color: textMuted)),
          ),
          Flexible(
            child: Text(
              '$tracking tracking',
              style: TextStyle(fontSize: 13, color: textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTypeFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentContrast = isDark ? Colors.black : Colors.white;

    Widget buildPill(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () {
            HapticService.light();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? accentColor : elevated,
              borderRadius: BorderRadius.circular(20),
              border: selected ? null : Border.all(color: cardBorder),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? accentContrast : textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          buildPill('All', _selectedViewFilter == null, () {
            setState(() => _selectedViewFilter = null);
          }),
          ...PhotoViewType.values.map((type) => buildPill(
                type.displayName,
                _selectedViewFilter == type,
                () => setState(() => _selectedViewFilter = type),
              )),
        ],
      ),
    );
  }

  Widget _buildGridControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final gridIcons = {2: Icons.grid_on, 3: Icons.grid_view, 4: Icons.apps};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Sort toggle
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortNewestFirst ? 'Newest' : 'Oldest',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Grid column buttons
          ...([2, 3, 4]).map((cols) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _gridColumns = cols),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _gridColumns == cols
                      ? accentColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  gridIcons[cols] ?? Icons.grid_view,
                  size: 20,
                  color: _gridColumns == cols ? accentColor : textMuted,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSavedComparisonsSection() {
    if (widget.userId == null) return const SizedBox.shrink();

    final state = ref.watch(progressPhotosNotifierProvider(widget.userId!));
    final comparisons = state.comparisons;

    if (comparisons.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Text(
                'Saved Comparisons (${comparisons.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: AnimatedRotation(
                  turns: _savedComparisonsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.expand_more, color: textMuted),
                ),
                onPressed: () => setState(() => _savedComparisonsExpanded = !_savedComparisonsExpanded),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComparisonGalleryScreen(userId: widget.userId!),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comparisons.length > 5 ? 5 : comparisons.length,
                  itemBuilder: (context, index) {
                    final comparison = comparisons[index];
                    return _buildComparisonPreviewCard(comparison);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _savedComparisonsExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildComparisonPreviewCard(PhotoComparison comparison) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComparisonView(
              userId: widget.userId!,
              existingComparison: comparison,
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Before/After thumbnail row
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: comparison.beforePhoto.thumbnailUrl ?? comparison.beforePhoto.photoUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(width: 1, color: cardBorder),
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: comparison.afterPhoto.thumbnailUrl ?? comparison.afterPhoto.photoUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (comparison.formattedWeightChange != null)
                    Text(
                      comparison.formattedWeightChange!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (comparison.weightChangeKg ?? 0) < 0
                            ? (isDark ? AppColors.success : AppColorsLight.success)
                            : (isDark ? AppColors.orange : AppColorsLight.orange),
                      ),
                    ),
                  if (comparison.formattedDuration != null)
                    Text(
                      comparison.formattedDuration!,
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestPhotosByView(LatestPhotosByView latest) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Latest by View',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: AnimatedRotation(
                  turns: _latestByViewExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.expand_more, color: textMuted),
                ),
                onPressed: () => setState(() => _latestByViewExpanded = !_latestByViewExpanded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedCrossFade(
            firstChild: SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: PhotoViewType.values.map((type) {
                  final photo = latest.getPhoto(type);
                  return _buildLatestViewCard(type, photo);
                }).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _latestByViewExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestViewCard(PhotoViewType type, ProgressPhoto? photo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: photo == null ? () => _showAddPhotoForType(type) : null,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: photo != null
                        ? accentColor.withValues(alpha: 0.3)
                        : cardBorder,
                    width: photo != null ? 2 : 1,
                  ),
                ),
                child: photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: CachedNetworkImage(
                          imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.red,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.add_a_photo,
                          color: textMuted,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(ProgressPhoto photo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final dateStr = DateFormat('MMM d, yyyy').format(photo.takenAt);
    final timeStr = DateFormat('h:mm a').format(photo.takenAt);

    return GestureDetector(
      onTap: () => _showPhotoDetail(photo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: elevated,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: elevated,
                        child: const Icon(Icons.broken_image, color: Colors.red),
                      ),
                    ),
                    // View type badge
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          photo.viewTypeEnum.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Date and time below the photo
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotosState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentContrast = isDark ? Colors.black : Colors.white;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 56,
              color: textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No Progress Photos Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take photos from different angles to track your visual progress over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddPhotoSheet,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take First Photo'),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: accentContrast,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPhotoForType(PhotoViewType type) async {
    // Skip view type selection — go straight to image source picker
    final source = await showGlassSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null || !mounted) return;

    final editedFile = await Navigator.push<File>(
      context,
      AppPageRoute(
        builder: (context) => PhotoEditorScreen(
          imageFile: File(pickedFile.path),
          viewTypeName: type.displayName,
        ),
      ),
    );

    if (editedFile != null && mounted) {
      _uploadPhoto(editedFile, type);
    }
  }

  Future<void> _showAddPhotoSheet() async {
    final colorScheme = Theme.of(context).colorScheme;
    PhotoViewType? selectedType;

    // First, pick a view type
    selectedType = await showGlassSheet<PhotoViewType>(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select View Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...PhotoViewType.values.map((type) => ListTile(
                    leading: Icon(_getViewTypeIcon(type)),
                    title: Text(type.displayName),
                    subtitle: Text(_getViewTypeDescription(type)),
                    onTap: () => Navigator.pop(context, type),
                  )),
            ],
          ),
        ),
      ),
    );

    if (selectedType == null || !mounted) return;

    // Then pick image source
    final source = await showGlassSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    // Pick the image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null || !mounted) return;

    // Open photo editor for cropping and logo overlay
    final editedFile = await Navigator.push<File>(
      context,
      AppPageRoute(
        builder: (context) => PhotoEditorScreen(
          imageFile: File(pickedFile.path),
          viewTypeName: selectedType!.displayName,
        ),
      ),
    );

    // If user saved the edited photo, upload it
    if (editedFile != null && mounted) {
      _uploadPhoto(editedFile, selectedType);
    }
  }

  Future<void> _uploadPhoto(File imageFile, PhotoViewType viewType) async {
    if (widget.userId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Uploading photo...'),
          ],
        ),
      ),
    );

    try {
      await ref
          .read(progressPhotosNotifierProvider(widget.userId!).notifier)
          .uploadPhoto(
            imageFile: imageFile,
            viewType: viewType,
          );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${viewType.displayName} photo saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoDetail(ProgressPhoto photo) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Column(
            children: [
              GlassSheetHandle(isDark: isDark),
              // Photo
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 0.75,
                        child: CachedNetworkImage(
                          imageUrl: photo.photoUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.viewTypeEnum.displayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMMM d, yyyy').format(photo.takenAt),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (photo.formattedWeight != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Weight: ${photo.formattedWeight}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (photo.notes != null && photo.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                photo.notes!,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _deletePhoto(photo),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && widget.userId != null) {
      Navigator.pop(context); // Close detail sheet
      await ref
          .read(progressPhotosNotifierProvider(widget.userId!).notifier)
          .deletePhoto(photo.id);
    }
  }

  IconData _getViewTypeIcon(PhotoViewType type) {
    switch (type) {
      case PhotoViewType.front:
        return Icons.person;
      case PhotoViewType.sideLeft:
        return Icons.arrow_back;
      case PhotoViewType.sideRight:
        return Icons.arrow_forward;
      case PhotoViewType.back:
        return Icons.person_outline;
      case PhotoViewType.legs:
        return Icons.directions_walk;
      case PhotoViewType.glutes:
        return Icons.airline_seat_legroom_normal;
      case PhotoViewType.arms:
        return Icons.fitness_center;
      case PhotoViewType.abs:
        return Icons.grid_on;
      case PhotoViewType.chest:
        return Icons.shield;
      case PhotoViewType.custom:
        return Icons.photo_camera;
    }
  }

  String _getViewTypeDescription(PhotoViewType type) {
    switch (type) {
      case PhotoViewType.front:
        return 'Face the camera directly';
      case PhotoViewType.sideLeft:
        return 'Turn your left side to camera';
      case PhotoViewType.sideRight:
        return 'Turn your right side to camera';
      case PhotoViewType.back:
        return 'Turn your back to camera';
      case PhotoViewType.legs:
        return 'Show your leg muscles';
      case PhotoViewType.glutes:
        return 'Show your glute progress';
      case PhotoViewType.arms:
        return 'Flex your arms for the camera';
      case PhotoViewType.abs:
        return 'Show your core/abs';
      case PhotoViewType.chest:
        return 'Show your chest progress';
      case PhotoViewType.custom:
        return 'Any other angle or pose';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// STRENGTH TAB - Readiness, Strength Scores, PRs, Analytics
// ═══════════════════════════════════════════════════════════════════

class _StrengthTab extends ConsumerWidget {
  final String? userId;

  const _StrengthTab({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return AppLoading.fullScreen();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await ref.read(scoresProvider.notifier).loadAllScores(userId: userId);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fitness Score Summary
                _FitnessScoreCard(userId: userId!),
                const SizedBox(height: 16),

                // Strength Overview Card
                StrengthOverviewCard(
                  userId: userId!,
                  onTapMuscleGroup: (muscleGroup) {
                    context.push('/stats/muscle-analytics/$muscleGroup');
                  },
                ),
                const SizedBox(height: 24),

                // Recent Personal Records
                _SectionHeader(title: 'Recent Personal Records'),
                const SizedBox(height: 12),
                _PRList(),
                const SizedBox(height: 16),

                const SizedBox(height: 80), // Bottom padding for floating buttons
              ],
            ),
          ),
        ),

        // Floating analytics buttons at bottom
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _FloatingNavButton(
                    icon: Icons.emoji_events,
                    label: 'Exercises & PRs',
                    color: colorScheme.primary,
                    onTap: () => context.push('/stats/exercise-history'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FloatingNavButton(
                    icon: Icons.fitness_center,
                    label: 'Muscle Analytics',
                    color: colorScheme.secondary,
                    onTap: () => context.push('/stats/muscle-analytics'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

/// Fitness Score Summary Card showing overall score and 4 component breakdowns
class _FitnessScoreCard extends ConsumerWidget {
  final String userId;

  const _FitnessScoreCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final fitnessBreakdown = ref.watch(fitnessScoreBreakdownProvider);

    if (fitnessBreakdown == null) {
      return const SizedBox.shrink();
    }

    final overallScore = fitnessBreakdown.overallScore;
    final levelColor = Color(fitnessBreakdown.levelColorValue);

    final components = [
      _ScoreComponent('Strength', fitnessBreakdown.strengthScore, 0.40, const Color(0xFFEF4444)),
      _ScoreComponent('Consistency', fitnessBreakdown.consistencyScore, 0.30, const Color(0xFF3B82F6)),
      _ScoreComponent('Nutrition', fitnessBreakdown.nutritionScore, 0.20, const Color(0xFF22C55E)),
      _ScoreComponent('Readiness', fitnessBreakdown.readinessScore, 0.10, const Color(0xFFA855F7)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with overall score
          Row(
            children: [
              // Score circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$overallScore',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitness Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fitnessBreakdown.levelDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: levelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Component bars
          ...components.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${c.label} (${(c.weight * 100).toInt()}%)',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    Text(
                      '${c.score}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.score / 100,
                    minHeight: 6,
                    backgroundColor: c.color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(c.color),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ScoreComponent {
  final String label;
  final int score;
  final double weight;
  final Color color;

  const _ScoreComponent(this.label, this.score, this.weight, this.color);
}

class _FloatingNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingNavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BODY TAB - Weight, measurements, body composition
// ═══════════════════════════════════════════════════════════════════

class _MeasurementsTab extends ConsumerStatefulWidget {
  final String? userId;
  const _MeasurementsTab({this.userId});

  @override
  ConsumerState<_MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends ConsumerState<_MeasurementsTab> {
  String _selectedPeriod = '30d';
  MeasurementType _selectedType = MeasurementType.weight;
  List<MeasurementType> _measurementOrder = [];

  static const _defaultOrder = [
    MeasurementType.weight, MeasurementType.bodyFat,
    MeasurementType.chest, MeasurementType.waist, MeasurementType.hips,
    MeasurementType.shoulders, MeasurementType.neck,
    MeasurementType.bicepsLeft, MeasurementType.bicepsRight,
    MeasurementType.forearmLeft, MeasurementType.forearmRight,
    MeasurementType.thighLeft, MeasurementType.thighRight,
    MeasurementType.calfLeft, MeasurementType.calfRight,
  ];

  final _periods = [
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': 'All', 'value': 'all', 'days': 365},
  ];

  static const _measurementGroups = [
    {
      'title': 'Body Composition',
      'types': [MeasurementType.weight, MeasurementType.bodyFat],
    },
    {
      'title': 'Upper Body',
      'types': [
        MeasurementType.neck,
        MeasurementType.shoulders,
        MeasurementType.chest,
        MeasurementType.bicepsLeft,
        MeasurementType.bicepsRight,
        MeasurementType.forearmLeft,
        MeasurementType.forearmRight,
      ],
    },
    {
      'title': 'Core',
      'types': [MeasurementType.waist, MeasurementType.hips],
    },
    {
      'title': 'Lower Body',
      'types': [
        MeasurementType.thighLeft,
        MeasurementType.thighRight,
        MeasurementType.calfLeft,
        MeasurementType.calfRight,
      ],
    },
  ];

  static const _derivedMetricPlacement = <MeasurementType, List<DerivedMetricType>>{
    MeasurementType.weight: [DerivedMetricType.bmi, DerivedMetricType.ffmi, DerivedMetricType.leanBodyMass],
    MeasurementType.waist: [DerivedMetricType.waistToHipRatio, DerivedMetricType.waistToHeightRatio],
    MeasurementType.shoulders: [DerivedMetricType.shoulderToWaistRatio],
    MeasurementType.chest: [DerivedMetricType.chestToWaistRatio],
    MeasurementType.bicepsRight: [DerivedMetricType.armSymmetry],
    MeasurementType.thighRight: [DerivedMetricType.legSymmetry],
  };

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _loadMeasurements();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('measurement_order');
    if (saved != null && saved.isNotEmpty) {
      final order = <MeasurementType>[];
      for (final name in saved) {
        final t = MeasurementType.values.where((t) => t.name == name).firstOrNull;
        if (t != null) order.add(t);
      }
      // Add any missing types
      for (final t in _defaultOrder) {
        if (!order.contains(t)) order.add(t);
      }
      if (mounted) setState(() => _measurementOrder = order);
    } else {
      setState(() => _measurementOrder = List.from(_defaultOrder));
    }
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'measurement_order',
      _measurementOrder.map((t) => t.name).toList(),
    );
  }

  bool _seeded = false;

  Future<void> _loadMeasurements() async {
    final userId = widget.userId;
    if (userId == null) return;

    // Always force a fresh fetch from Supabase
    await ref.read(measurementsProvider.notifier).forceRefresh(userId);

    final state = ref.read(measurementsProvider);
    final weightHistory = state.historyByType[MeasurementType.weight] ?? [];
    debugPrint('🔍 [MeasurementsTab] Loaded ${weightHistory.length} weight entries, '
        '${state.historyByType.length} total types with data');

    // Seed body_measurements from profile if no weight data (one-time)
    if (!_seeded) {
      _seeded = true;
      if (weightHistory.isEmpty) {
        final auth = ref.read(authStateProvider);
        final profileWeight = auth.user?.weightKg;
        if (profileWeight != null && profileWeight > 0) {
          debugPrint('🌱 [MeasurementsTab] Seeding weight from profile: $profileWeight kg');
          final success = await ref.read(measurementsProvider.notifier).recordMeasurement(
            userId: userId,
            type: MeasurementType.weight,
            value: profileWeight,
            unit: 'kg',
            notes: 'Initial weight from profile',
          );
          debugPrint('🌱 [MeasurementsTab] Seed result: $success');
        }
      }
    }
  }

  List<MeasurementEntry> _filterByPeriod(List<MeasurementEntry> history) {
    if (_selectedPeriod == 'all') return history;
    final days = _periods.firstWhere((p) => p['value'] == _selectedPeriod)['days'] as int;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.recordedAt.isAfter(cutoff)).toList();
  }

  List<double> _computeEWMA(List<double> values, {double alpha = 0.3}) {
    if (values.isEmpty) return [];
    final result = <double>[values.first];
    for (int i = 1; i < values.length; i++) {
      result.add(alpha * values[i] + (1 - alpha) * result[i - 1]);
    }
    return result;
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final state = ref.watch(measurementsProvider);
    final summary = state.summary;
    final auth = ref.watch(authStateProvider);
    final heightCm = auth.user?.heightCm;
    final gender = auth.user?.gender;

    if (state.isLoading) return AppLoading.fullScreen();

    // Compute derived metrics - use profile weight as fallback
    Map<DerivedMetricType, DerivedMetricResult> derivedMetrics;
    if (summary != null && summary.latestByType.isNotEmpty) {
      derivedMetrics = computeDerivedMetrics(summary: summary, heightCm: heightCm, gender: gender);
    } else {
      derivedMetrics = computeDerivedMetrics(
        summary: MeasurementsSummary(
          latestByType: {
            if (auth.user?.weightKg != null && auth.user!.weightKg! > 0)
              MeasurementType.weight: MeasurementEntry(
                id: '', userId: '', type: MeasurementType.weight,
                value: auth.user!.weightKg!, unit: 'kg', recordedAt: DateTime.now(),
              ),
          },
          changeFromPrevious: {},
        ),
        heightCm: heightCm,
        gender: gender,
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadMeasurements,
          color: cyan,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero chart card
                _buildHeroChart(
                  state: state,
                  summary: summary,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                  cardBorder: cardBorder,
                ),
                const SizedBox(height: 16),

                // Unified grouped list
                _buildGroupedList(
                  state: state,
                  summary: summary,
                  derivedMetrics: derivedMetrics,
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cyan: cyan,
                  cardBorder: cardBorder,
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Floating FAB - quick add measurement
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showQuickAddSheet(context, ref, cyan, _selectedType),
            backgroundColor: cyan,
            child: Icon(Icons.add, color: isDark ? AppColors.pureBlack : Colors.white),
          ),
        ),
      ],
    );
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref, Color accent, [MeasurementType initialType = MeasurementType.weight]) {
    final auth = ref.read(authStateProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    MeasurementType selectedType = initialType;
    final valueController = TextEditingController();
    bool isSubmitting = false;

    String _unitFor(MeasurementType t) =>
        t == MeasurementType.weight ? 'kg' : (t == MeasurementType.bodyFat ? '%' : 'cm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log ${selectedType.displayName}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MeasurementType.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final type = MeasurementType.values[index];
                        final isSelected = selectedType == type;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedType = type);
                            valueController.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accent.withValues(alpha: 0.2) : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isSelected ? accent : colorScheme.outline.withValues(alpha: 0.2)),
                            ),
                            child: Text(type.displayName, style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? accent : colorScheme.onSurfaceVariant,
                            )),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: selectedType.displayName,
                      suffixText: _unitFor(selectedType),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : () async {
                        final val = double.tryParse(valueController.text.trim());
                        if (val == null || val <= 0) return;
                        setSheetState(() => isSubmitting = true);
                        final success = await ref.read(measurementsProvider.notifier).recordMeasurement(
                          userId: userId, type: selectedType, value: val, unit: _unitFor(selectedType),
                        );
                        if (success && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                        setSheetState(() => isSubmitting = false);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeRangeChips({
    required Color cyan,
    required Color elevated,
    required Color textMuted,
    required Color cardBorder,
  }) {
    return Row(
      children: _periods.map((period) {
        final isSelected = _selectedPeriod == period['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period['value'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? cyan.withOpacity(0.2) : elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? cyan : cardBorder),
              ),
              child: Center(
                child: Text(
                  period['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? cyan : textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeroChart({
    required MeasurementsState state,
    required MeasurementsSummary? summary,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
    required Color cardBorder,
  }) {
    final history = state.historyByType[_selectedType] ?? [];
    final filtered = _filterByPeriod(history).reversed.toList();
    final latest = summary?.latestByType[_selectedType];
    final change = summary?.changeFromPrevious[_selectedType];
    final unit = _selectedType == MeasurementType.weight
        ? 'kg'
        : (_selectedType == MeasurementType.bodyFat ? '%' : 'cm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: type name (left), latest value + change (right)
          Row(
            children: [
              Text(
                _selectedType.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (latest != null) ...[
                Text(
                  '${_formatValue(latest.value)} $unit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                if (change != null && change.abs() >= 0.1) ...[
                  const SizedBox(width: 6),
                  Icon(
                    change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: _getChangeColor(_selectedType, change),
                  ),
                  Text(
                    _formatValue(change.abs()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getChangeColor(_selectedType, change),
                    ),
                  ),
                ],
              ] else
                Text('— $unit', style: TextStyle(fontSize: 16, color: textMuted)),
            ],
          ),
          const SizedBox(height: 12),

          // Time range chips
          _buildTimeRangeChips(cyan: cyan, elevated: elevated, textMuted: textMuted, cardBorder: cardBorder),
          const SizedBox(height: 12),

          // Chart area with animated transitions
          SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildHeroChartContent(
                key: ValueKey('${_selectedType.name}_$_selectedPeriod'),
                filtered: filtered,
                isDark: isDark,
                textMuted: textMuted,
                cyan: cyan,
                unit: unit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChartContent({
    required Key key,
    required List<MeasurementEntry> filtered,
    required bool isDark,
    required Color textMuted,
    required Color cyan,
    required String unit,
  }) {
    if (filtered.isEmpty) {
      return Center(
        key: key,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 40, color: textMuted),
            const SizedBox(height: 8),
            Text(
              'Log ${_selectedType.displayName.toLowerCase()} to see trends',
              style: TextStyle(color: textMuted),
            ),
          ],
        ),
      );
    }

    if (filtered.length == 1) {
      return Center(
        key: key,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_formatValue(filtered.first.value)} $unit',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cyan),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(filtered.first.recordedAt),
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 8),
            Text('Log again to see trends', style: TextStyle(fontSize: 12, color: textMuted)),
          ],
        ),
      );
    }

    // 2+ entries: show chart
    if (_selectedType == MeasurementType.weight) {
      return KeyedSubtree(
        key: key,
        child: _buildWeightLineChart(filtered, cyan: cyan, textMuted: textMuted, isDark: isDark),
      );
    }
    return KeyedSubtree(
      key: key,
      child: _buildSingleLineChart(filtered, cyan: cyan, textMuted: textMuted, isDark: isDark),
    );
  }

  Widget _buildSingleLineChart(
    List<MeasurementEntry> data, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    final spots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.value)).toList();
    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                _formatValue(value),
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: (data.length / 4).ceil().toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(data[index].recordedAt),
                      style: TextStyle(fontSize: 9, color: textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cyan,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length < 20,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: cyan,
                strokeWidth: 1.5,
                strokeColor: isDark ? AppColors.pureBlack : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [cyan.withOpacity(0.2), cyan.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }

  Widget _buildWeightLineChart(
    List<MeasurementEntry> data, {
    required Color cyan,
    required Color textMuted,
    required bool isDark,
  }) {
    final rawValues = data.map((e) => e.value).toList();
    final ewmaValues = _computeEWMA(rawValues);

    final rawSpots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.value)).toList();
    final ewmaSpots = ewmaValues.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value)).toList();

    final allValues = [...rawValues, ...ewmaValues];
    final minY = allValues.reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.02;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) => Text(
                _formatValue(value),
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (data.length / 4).ceil().toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(data[index].recordedAt),
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          // Raw data - thin dotted line
          LineChartBarData(
            spots: rawSpots,
            isCurved: true,
            color: cyan.withOpacity(0.4),
            barWidth: 1.5,
            dashArray: [4, 4],
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: cyan.withOpacity(0.5),
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // EWMA trend - thick solid line
          LineChartBarData(
            spots: ewmaSpots,
            isCurved: true,
            color: cyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [cyan.withOpacity(0.3), cyan.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => isDark ? AppColors.nearBlack : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (spot.barIndex == 1) {
                  return LineTooltipItem(
                    'Trend: ${_formatValue(spot.y)} kg',
                    TextStyle(
                      color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                final date = index < data.length ? data[index].recordedAt : DateTime.now();
                return LineTooltipItem(
                  '${_formatValue(spot.y)} kg\n${DateFormat('MMM d').format(date)}',
                  TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDerivedPills({
    required MeasurementType type,
    required Map<DerivedMetricType, DerivedMetricResult> derivedMetrics,
    required bool isDark,
    required Color textMuted,
  }) {
    final placements = _derivedMetricPlacement[type];
    if (placements == null || placements.isEmpty) return const SizedBox.shrink();

    final pills = <Widget>[];
    for (final dType in placements) {
      final result = derivedMetrics[dType];
      if (result == null) continue;
      final valueStr = dType.unit.isNotEmpty
          ? '${_formatValue(result.value)} ${dType.unit}'
          : _formatValue(result.value);

      pills.add(
        GestureDetector(
          onTap: () {
            HapticService.light();
            context.push('/measurements/derived/${dType.name}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: result.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.label.isNotEmpty
                  ? '${dType.displayName} $valueStr ${result.label}'
                  : '${dType.displayName} $valueStr',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: result.color,
              ),
            ),
          ),
        ),
      );
    }

    if (pills.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8, top: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: pills,
      ),
    );
  }

  Widget _buildMeasurementRow({
    required MeasurementType type,
    required int index,
    required MeasurementsSummary? summary,
    required Map<DerivedMetricType, DerivedMetricResult> derivedMetrics,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
    required Color cardBorder,
    required bool isLast,
  }) {
    final entry = summary?.latestByType[type];
    final change = summary?.changeFromPrevious[type];
    final hasData = entry != null;
    final unit = type == MeasurementType.weight
        ? 'kg'
        : (type == MeasurementType.bodyFat ? '%' : 'cm');
    final isSelected = _selectedType == type;

    return Container(
      key: ValueKey(type),
      decoration: BoxDecoration(
        color: isSelected ? cyan.withValues(alpha: 0.06) : null,
        border: Border(
          left: isSelected
              ? BorderSide(color: cyan, width: 3)
              : BorderSide.none,
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: cardBorder, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticService.light();
              setState(() => _selectedType = type);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.drag_handle, color: textMuted, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hasData ? textPrimary : textMuted,
                          ),
                        ),
                        if (hasData && change != null && change.abs() >= 0.1)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 12,
                                color: _getChangeColor(type, change),
                              ),
                              Text(
                                '${_formatValue(change.abs())} ${entry.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getChangeColor(type, change),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  hasData
                      ? Text(
                          '${_formatValue(entry.value)} ${entry.unit}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        )
                      : Text(
                          '— $unit',
                          style: TextStyle(fontSize: 14, color: textMuted.withValues(alpha: 0.5)),
                        ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      context.push('/measurements/${type.name}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right, size: 18, color: textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDerivedPills(
            type: type,
            derivedMetrics: derivedMetrics,
            isDark: isDark,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList({
    required MeasurementsState state,
    required MeasurementsSummary? summary,
    required Map<DerivedMetricType, DerivedMetricResult> derivedMetrics,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cyan,
    required Color cardBorder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int gi = 0; gi < _measurementGroups.length; gi++) ...[
            // Group header
            Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16,
                top: gi == 0 ? 16 : 20,
                bottom: 4,
              ),
              child: Text(
                (_measurementGroups[gi]['title'] as String).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            // Group rows - get types for this group, filtered to user order
            Builder(builder: (context) {
              final groupTypes = _measurementGroups[gi]['types'] as List<MeasurementType>;
              // Order by the user's preference within the group
              final orderedGroupTypes = <MeasurementType>[];
              for (final t in _measurementOrder) {
                if (groupTypes.contains(t)) orderedGroupTypes.add(t);
              }
              // Add any missing types from the group
              for (final t in groupTypes) {
                if (!orderedGroupTypes.contains(t)) orderedGroupTypes.add(t);
              }

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: orderedGroupTypes.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  setState(() {
                    // Update position in the flat _measurementOrder
                    final item = orderedGroupTypes[oldIndex];
                    final otherItem = orderedGroupTypes[newIndex];
                    final flatOld = _measurementOrder.indexOf(item);
                    final flatNew = _measurementOrder.indexOf(otherItem);
                    if (flatOld >= 0 && flatNew >= 0) {
                      _measurementOrder.removeAt(flatOld);
                      final insertAt = _measurementOrder.indexOf(otherItem);
                      _measurementOrder.insert(
                        oldIndex < newIndex ? insertAt + 1 : insertAt,
                        item,
                      );
                    }
                  });
                  _saveOrder();
                },
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final type = orderedGroupTypes[index];
                  return _buildMeasurementRow(
                    type: type,
                    index: index,
                    summary: summary,
                    derivedMetrics: derivedMetrics,
                    isDark: isDark,
                    elevated: elevated,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cyan: cyan,
                    cardBorder: cardBorder,
                    isLast: index == orderedGroupTypes.length - 1 && gi == _measurementGroups.length - 1,
                  );
                },
              );
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getChangeColor(MeasurementType type, double change) {
    if (type == MeasurementType.weight || type == MeasurementType.bodyFat) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    return change > 0 ? AppColors.success : AppColors.error;
  }
}

// ═══════════════════════════════════════════════════════════════════
// NUTRITION TAB - Calorie trends, macro breakdown, goals
// ═══════════════════════════════════════════════════════════════════

class _NutritionTab extends ConsumerWidget {
  final String? userId;
  const _NutritionTab({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (userId == null || userId!.isEmpty) {
      return const Center(child: Text('Sign in to view nutrition stats'));
    }

    final weeklySummary = ref.watch(weeklySummaryProvider(userId!));
    final weeklyNutrition = ref.watch(weeklyNutritionProvider(userId!));
    final detailedTDEE = ref.watch(detailedTDEEProvider(userId!));
    final adherence = ref.watch(adherenceSummaryProvider(userId!));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weeklySummaryProvider(userId!));
        ref.invalidate(weeklyNutritionProvider(userId!));
        ref.invalidate(detailedTDEEProvider(userId!));
        ref.invalidate(adherenceSummaryProvider(userId!));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Weekly Overview Summary
            _WeeklyOverviewCard(
            weeklySummary: weeklySummary,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 2: Calorie Trend Chart
          _CalorieTrendCard(
            weeklyNutrition: weeklyNutrition,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 3: Macro Breakdown
          _MacroBreakdownCard(
            weeklyNutrition: weeklyNutrition,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 4: TDEE & Energy Balance
          _TDEECard(
            detailedTDEE: detailedTDEE,
            weeklySummary: weeklySummary,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 5: Adherence & Consistency
          _AdherenceCard(
            adherence: adherence,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Card 6: Health Metrics (existing)
          HealthMetricsCard(isDark: isDark),
          const SizedBox(height: 16),

          // Card 7: Food-Mood Analytics (existing)
          FoodMoodAnalyticsCard(userId: userId!, isDark: isDark),

          const SizedBox(height: 80),
        ],
      ),
    ),
    );
  }
}

// ── Card 1: Weekly Overview ──────────────────────────────────────

class _WeeklyOverviewCard extends StatelessWidget {
  final AsyncValue<WeeklySummaryData?> weeklySummary;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _WeeklyOverviewCard({
    required this.weeklySummary,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklySummary.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (_, __) => _errorRow('Could not load weekly summary'),
        data: (data) {
          if (data == null) return _errorRow('No data available');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatBadge(
                    label: 'Days Logged',
                    value: '${data.daysLogged}/7',
                    icon: Icons.calendar_today,
                    color: const Color(0xFF4CAF50),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: 'Avg Calories',
                    value: '${data.avgCalories}',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF9800),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: 'Avg Protein',
                    value: '${data.avgProtein}g',
                    icon: Icons.fitness_center,
                    color: const Color(0xFF009688),
                    isDark: isDark,
                  ),
                  if (data.weightChange != null) ...[
                    const SizedBox(width: 8),
                    _StatBadge(
                      label: 'Weight',
                      value:
                          '${data.weightChange! > 0 ? '+' : ''}${data.weightChange!.toStringAsFixed(1)} kg',
                      icon: data.weightChange! > 0
                          ? Icons.trending_up
                          : data.weightChange! < 0
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: const Color(0xFF2196F3),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _errorRow(String message) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: textMuted),
        const SizedBox(width: 8),
        Text(message, style: TextStyle(color: textMuted, fontSize: 13)),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card 2: Calorie Trend Chart ──────────────────────────────────

class _CalorieTrendCard extends StatelessWidget {
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _CalorieTrendCard({
    required this.weeklyNutrition,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklyNutrition.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (_, __) => SizedBox(
          height: 80,
          child: Center(
            child: Text('Could not load calorie data',
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          if (data == null || data.dailySummaries.isEmpty) {
            return SizedBox(
              height: 80,
              child: Center(
                child: Text('No nutrition data this week',
                    style: TextStyle(color: textMuted)),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Calorie Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'avg ${data.averageDailyCalories.round()} cal',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _CalorieBarChart(
                  entries: data.dailySummaries,
                  avgCalories: data.averageDailyCalories,
                  isDark: isDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalorieBarChart extends StatelessWidget {
  final List<DailyNutritionEntry> entries;
  final double avgCalories;
  final bool isDark;

  const _CalorieBarChart({
    required this.entries,
    required this.avgCalories,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxCal = entries
        .fold<double>(avgCalories, (m, e) => e.calories > m ? e.calories.toDouble() : m);
    final chartMax = maxCal > 0 ? (maxCal * 1.2).ceilToDouble() : 2000.0;

    return BarChart(
      BarChartData(
        maxY: chartMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark
                ? const Color(0xFF2A2A2A)
                : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x];
              return BarTooltipItem(
                '${entry.calories} cal\nP: ${entry.proteinG.round()}g  C: ${entry.carbsG.round()}g  F: ${entry.fatG.round()}g',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[idx].dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const SizedBox();
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: avgCalories,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                labelResolver: (_) => 'avg',
              ),
            ),
          ],
        ),
        barGroups: List.generate(entries.length, (i) {
          final cal = entries[i].calories.toDouble();
          final barColor = cal > 0
              ? (isDark ? const Color(0xFF4FC3F7) : const Color(0xFF1E88E5))
              : Colors.transparent;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cal > 0 ? cal : 0,
                color: barColor,
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Card 3: Macro Breakdown ──────────────────────────────────────

class _MacroBreakdownCard extends StatelessWidget {
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _MacroBreakdownCard({
    required this.weeklyNutrition,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklyNutrition.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text('Could not load macros',
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          if (data == null || data.daysWithData == 0) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text('No macro data this week',
                    style: TextStyle(color: textMuted)),
              ),
            );
          }
          final macros = data.averageMacros;
          final totalCals = (macros.protein * 4) +
              (macros.carbs * 4) +
              (macros.fat * 9);
          final proteinPct =
              totalCals > 0 ? (macros.protein * 4 / totalCals * 100) : 0.0;
          final carbsPct =
              totalCals > 0 ? (macros.carbs * 4 / totalCals * 100) : 0.0;
          final fatPct =
              totalCals > 0 ? (macros.fat * 9 / totalCals * 100) : 0.0;

          const proteinColor = Color(0xFF009688);
          const carbsColor = Color(0xFF42A5F5);
          const fatColor = Color(0xFFFF9800);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Macro Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Weekly average distribution',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 16),
              // Stacked bar showing macro distribution
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      if (proteinPct > 0)
                        Expanded(
                          flex: proteinPct.round().clamp(1, 100),
                          child: Container(color: proteinColor),
                        ),
                      if (carbsPct > 0)
                        Expanded(
                          flex: carbsPct.round().clamp(1, 100),
                          child: Container(color: carbsColor),
                        ),
                      if (fatPct > 0)
                        Expanded(
                          flex: fatPct.round().clamp(1, 100),
                          child: Container(color: fatColor),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Macro detail rows
              _MacroRow(
                label: 'Protein',
                grams: macros.protein,
                pct: proteinPct,
                color: proteinColor,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MacroRow(
                label: 'Carbs',
                grams: macros.carbs,
                pct: carbsPct,
                color: carbsColor,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MacroRow(
                label: 'Fat',
                grams: macros.fat,
                pct: fatPct,
                color: fatColor,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final double pct;
  final Color color;
  final bool isDark;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
        ),
        Text(
          '${grams.round()}g',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          '${pct.round()}%',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Card 4: TDEE & Energy Balance ────────────────────────────────

class _TDEECard extends StatelessWidget {
  final AsyncValue<DetailedTDEE?> detailedTDEE;
  final AsyncValue<WeeklySummaryData?> weeklySummary;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _TDEECard({
    required this.detailedTDEE,
    required this.weeklySummary,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: detailedTDEE.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text('Could not load TDEE data',
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (tdee) {
          if (tdee == null) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text('Not enough data for TDEE estimate',
                    style: TextStyle(color: textMuted, fontSize: 13)),
              ),
            );
          }

          final avgIntake =
              weeklySummary.valueOrNull?.avgCalories ?? 0;
          final confidenceColor = switch (tdee.confidenceLevel) {
            'high' => const Color(0xFF4CAF50),
            'medium' => const Color(0xFFFF9800),
            _ => const Color(0xFFF44336),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'TDEE & Energy Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tdee.confidenceLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: confidenceColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Main TDEE display
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tdee.tdee}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      'cal/day  ${tdee.uncertaintyDisplay}',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Intake vs TDEE
              if (avgIntake > 0) ...[
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 14, color: textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Avg intake: $avgIntake cal',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${avgIntake - tdee.tdee > 0 ? '+' : ''}${avgIntake - tdee.tdee} cal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (avgIntake - tdee.tdee).abs() < 100
                            ? const Color(0xFF4CAF50)
                            : (avgIntake > tdee.tdee
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF42A5F5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Weight trend
              Row(
                children: [
                  Icon(
                    tdee.weightTrend.direction == 'losing'
                        ? Icons.trending_down
                        : tdee.weightTrend.direction == 'gaining'
                            ? Icons.trending_up
                            : Icons.trending_flat,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Weight: ${tdee.weightTrend.formattedWeeklyRate}',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
              // Metabolic adaptation warning
              if (tdee.hasAdaptation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 16, color: Color(0xFFFF9800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tdee.metabolicAdaptation?.actionDescription ??
                              'Metabolic adaptation detected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Card 5: Adherence & Consistency ──────────────────────────────

class _AdherenceCard extends StatelessWidget {
  final AsyncValue<AdherenceSummary?> adherence;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _AdherenceCard({
    required this.adherence,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: adherence.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text('Could not load adherence data',
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          if (data == null) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text('Not enough data for adherence analysis',
                    style: TextStyle(color: textMuted, fontSize: 13)),
              ),
            );
          }

          final ratingColor = switch (data.sustainabilityRating) {
            'high' => const Color(0xFF4CAF50),
            'medium' => const Color(0xFFFF9800),
            _ => const Color(0xFFF44336),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Adherence & Consistency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ratingColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.sustainabilityRating.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ratingColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Overall adherence + sustainability row
              Row(
                children: [
                  // Circular progress for overall adherence
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (data.averageAdherence / 100).clamp(0.0, 1.0),
                          strokeWidth: 5,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(ratingColor),
                        ),
                        Text(
                          '${data.averageAdherence.round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniStatRow(
                          label: 'Consistency',
                          value: '${data.consistencyScore.round()}%',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 4),
                        _MiniStatRow(
                          label: 'Logging',
                          value: '${data.loggingScore.round()}%',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 4),
                        _MiniStatRow(
                          label: 'Weeks analyzed',
                          value: '${data.weeksAnalyzed}',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Weekly adherence mini chart
              if (data.weeklyAdherence.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Last ${data.weeklyAdherence.length} weeks',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: Row(
                    children: data.weeklyAdherence.map((w) {
                      final pct =
                          (w.avgOverallAdherence / 100).clamp(0.0, 1.0);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: pct > 0 ? pct : 0.05,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: ratingColor
                                            .withValues(alpha: 0.4 + pct * 0.6),
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              // AI recommendation
              if (data.recommendation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 14, color: textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.recommendation,
                          style:
                              TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MoodTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends ConsumerState<_MoodTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moodHistoryProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(moodHistoryProvider);
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    if (state.isLoading) {
      return AppLoading.fullScreen();
    }

    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly mood chart
              const MoodWeeklyChart(),
              const SizedBox(height: 16),

              // Mood streaks
              if (state.analytics != null)
                MoodStreakCard(streaks: state.analytics!.streaks),

              // Mood analytics summary
              if (state.analytics != null) ...[
                const SizedBox(height: 16),
                MoodAnalyticsCard(analytics: state.analytics!),
              ],

              const SizedBox(height: 16),

              // Calendar heatmap
              const MoodCalendarHeatmap(),

              // Link to full history
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/mood-history'),
                  child: Text('View Full History', style: TextStyle(color: teal)),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),

        // Floating Log Mood button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => showMoodPickerSheet(context, ref),
            backgroundColor: accentColor,
            child: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }
}

/// Compact stat widget for horizontal row display
class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CompactStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

/// Vertical divider for compact stats row
class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 40,
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }
}

class _AchievementsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final milestonesState = ref.watch(milestonesProvider);

    if (milestonesState.isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final achieved = milestonesState.achieved;
    final upcoming = milestonesState.upcoming;

    // Build display list: up to 4 items, achieved first then upcoming
    final displayItems = <MilestoneProgress>[];
    displayItems.addAll(achieved.take(4));
    if (displayItems.length < 4) {
      displayItems.addAll(upcoming.take(4 - displayItems.length));
    }

    if (displayItems.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.textMuted, size: 32),
              const SizedBox(height: 8),
              Text(
                'No achievements yet',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: displayItems.map((mp) {
          return _BadgeIcon(
            iconData: _categoryIcon(mp.milestone.category),
            label: mp.milestone.name,
            unlocked: mp.isAchieved,
            color: Color(mp.milestone.tier.colorValue),
          );
        }).toList(),
      ),
    );
  }

  static IconData _categoryIcon(MilestoneCategory category) {
    switch (category) {
      case MilestoneCategory.workouts:
        return Icons.fitness_center;
      case MilestoneCategory.streak:
        return Icons.local_fire_department;
      case MilestoneCategory.strength:
        return Icons.emoji_events;
      case MilestoneCategory.volume:
        return Icons.speed;
      case MilestoneCategory.time:
        return Icons.schedule;
      case MilestoneCategory.weight:
        return Icons.monitor_weight;
      case MilestoneCategory.prs:
        return Icons.military_tech;
      case MilestoneCategory.firstSteps:
        return Icons.rocket_launch;
    }
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData iconData;
  final String label;
  final bool unlocked;
  final Color color;

  const _BadgeIcon({
    required this.iconData,
    required this.label,
    required this.unlocked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 32,
            color: unlocked ? color : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _PRList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final prStats = ref.watch(prStatsProvider);
    final recentPrs = prStats?.recentPrs ?? [];

    if (recentPrs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text(
                'No Personal Records Yet',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personal records are tracked as you complete workouts. Start training to see your progress here!',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentPrs.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
        itemBuilder: (context, index) {
          final pr = recentPrs[index];
          final date = DateTime.tryParse(pr.achievedAt);
          final dateStr = date != null
              ? DateFormat('MMM d').format(date)
              : '';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pr.exerciseDisplayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pr.liftDescription}  •  $dateStr',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                ),
                if (pr.improvementPercent != null && pr.improvementPercent! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${pr.improvementPercent!.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

