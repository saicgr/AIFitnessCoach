import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/progress_photos.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/animations/app_animations.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/activity_heatmap.dart';
import '../../widgets/exercise_search_results.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../widgets/workout_day_detail_sheet.dart';
import '../progress/comparison_view.dart';
import '../progress/photo_editor_screen.dart';
import '../progress/widgets/readiness_checkin_card.dart';
import '../progress/widgets/strength_overview_card.dart';
import '../progress/widgets/pr_summary_card.dart';
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
import 'widgets/date_range_filter_sheet.dart';
import 'widgets/export_stats_sheet.dart';
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
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() {
        _userId = userId;
      });
      // Load photos data
      ref.read(progressPhotosNotifierProvider(userId).notifier).loadAll();

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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Stats & Scores',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          // Compare Photos (only show on Photos tab - index 1)
          if (_userId != null && _currentTabIndex == 1)
            IconButton(
              icon: Icon(Icons.compare_arrows, color: textPrimary),
              onPressed: () => _showComparisonPicker(),
              tooltip: 'Compare Photos',
            ),
          // Time Range Selector
          IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: textPrimary),
            onPressed: () {
              HapticService.light();
              DateRangeFilterSheet.show(context, ref);
            },
            tooltip: 'Time Range',
          ),
          // Export
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: textPrimary),
            onPressed: () {
              HapticService.light();
              ExportStatsSheet.show(context, ref);
            },
            tooltip: 'Export',
          ),
          // Share
          IconButton(
            icon: Icon(Icons.ios_share_outlined, color: textPrimary),
            onPressed: () {
              HapticService.light();
              ShareStatsSheet.show(context, ref);
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: const [
              SegmentedTabItem(label: 'Overview'),
              SegmentedTabItem(label: 'Photos'),
              SegmentedTabItem(label: 'Strength'),
              SegmentedTabItem(label: 'Body'),
              SegmentedTabItem(label: 'Nutrition'),
              SegmentedTabItem(label: 'Mood'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(),
                _PhotosTab(userId: _userId, openPhotoSheet: widget.openPhotoSheet),
                _StrengthTab(userId: _userId),
                _BodyTab(),
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
                  value: '12.5h',
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

  void _updateHighlightedDates(String? searchQuery) {
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

    // Get search results and update highlighted dates
    final apiClient = ref.read(apiClientProvider);
    final timeRange = ref.read(heatmapTimeRangeProvider);

    apiClient.getUserId().then((userId) {
      if (userId != null && mounted) {
        ref
            .read(exerciseSearchProvider((
              userId: userId,
              exerciseName: searchQuery,
              weeks: timeRange.weeks,
            )).future)
            .then((response) {
          if (mounted) {
            setState(() {
              _highlightedDates = response.matchingDates.toSet();
            });
          }
        }).catchError((_) {
          // Ignore errors
        });
      }
    });
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
      return const Center(child: CircularProgressIndicator());
    }

    final state = ref.watch(progressPhotosNotifierProvider(widget.userId!));
    final colorScheme = Theme.of(context).colorScheme;

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

              // Photo Grid
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.photos.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyPhotosState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final filteredPhotos = _selectedViewFilter == null
                            ? state.photos
                            : state.photos
                                .where((p) =>
                                    p.viewTypeEnum == _selectedViewFilter)
                                .toList();
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
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoStatsCard(ProgressPhotosState state) {
    final stats = state.stats;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Photo Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              // Add Photo button
              FilledButton.icon(
                onPressed: () => _showAddPhotoSheet(),
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${stats?.totalPhotos ?? 0}',
                'Total Photos',
                Icons.photo_library,
              ),
              _buildStatItem(
                '${stats?.viewTypesCaptured ?? 0}/4',
                'Views Captured',
                Icons.view_carousel,
              ),
              _buildStatItem(
                stats?.formattedTrackingDuration ?? '-',
                'Tracking',
                Icons.calendar_month,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 24, color: colorScheme.onPrimaryContainer),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildViewTypeFilter() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedViewFilter == null,
            onSelected: (_) => setState(() => _selectedViewFilter = null),
          ),
          const SizedBox(width: 8),
          ...PhotoViewType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.displayName),
                  selected: _selectedViewFilter == type,
                  onSelected: (_) =>
                      setState(() => _selectedViewFilter = type),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLatestPhotosByView(LatestPhotosByView latest) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest by View',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: PhotoViewType.values.map((type) {
                final photo = latest.getPhoto(type);
                return _buildLatestViewCard(type, photo);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestViewCard(PhotoViewType type, ProgressPhoto? photo) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: photo != null
                      ? colorScheme.primary.withOpacity(0.5)
                      : colorScheme.outline.withOpacity(0.3),
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
                        errorWidget: (_, __, ___) => Icon(
                          Icons.broken_image,
                          color: colorScheme.error,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.add_a_photo,
                        color: colorScheme.outline,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ProgressPhoto photo) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showPhotoDetail(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.thumbnailUrl ?? photo.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: colorScheme.errorContainer,
                  child: Icon(Icons.broken_image, color: colorScheme.error),
                ),
              ),
              // Gradient overlay for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.viewTypeEnum.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        photo.formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 9,
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

  Widget _buildEmptyPhotosState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 80,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Progress Photos Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take photos from different angles to track your visual progress over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPhotoSheet,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take First Photo'),
            ),
          ],
        ),
      ),
    );
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
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(scoresProvider.notifier).loadScoresOverview(userId: userId);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Readiness Check-in Card
            ReadinessCheckinCard(
              userId: userId!,
              onCheckInComplete: () {
                // Refresh overview after check-in
                ref.read(scoresProvider.notifier).loadScoresOverview();
              },
            ),
            const SizedBox(height: 16),

            // Strength Overview Card
            StrengthOverviewCard(
              userId: userId!,
              onTapMuscleGroup: (muscleGroup) {
                // Navigate to muscle analytics detail
                context.push('/stats/muscle-analytics/$muscleGroup');
              },
            ),
            const SizedBox(height: 16),

            // Personal Records Summary Card
            PRSummaryCard(userId: userId!),
            const SizedBox(height: 16),

            // Analytics Navigation Cards
            _buildAnalyticsNavigationSection(context),
            const SizedBox(height: 80), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsNavigationSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Analytics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AnalyticsNavCard(
                icon: Icons.history,
                title: 'Exercise History',
                subtitle: 'Per-exercise progress & PRs',
                color: colorScheme.primary,
                onTap: () => context.push('/stats/exercise-history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnalyticsNavCard(
                icon: Icons.fitness_center,
                title: 'Muscle Analytics',
                subtitle: 'Training volume & balance',
                color: colorScheme.secondary,
                onTap: () => context.push('/stats/muscle-analytics'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Navigation card for analytics sections
class _AnalyticsNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnalyticsNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'View',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
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

class _BodyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight tracking
          _SectionHeader(
            title: 'Weight Tracking',
            onViewAll: () => context.push('/measurements'),
          ),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 200,
            message: 'Weight trend over time',
          ),

          const SizedBox(height: 24),

          // Current measurements
          _SectionHeader(title: 'Current Measurements'),
          const SizedBox(height: 12),
          _MeasurementsList(),

          const SizedBox(height: 24),

          // Add measurement button
          ElevatedButton.icon(
            onPressed: () => context.push('/measurements'),
            icon: const Icon(Icons.add),
            label: const Text('Log New Measurement'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          // Bottom padding for floating nav bar
          const SizedBox(height: 80),
        ],
      ),
    );
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

    return SingleChildScrollView(
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
    final chartMax = (maxCal * 1.2).ceilToDouble();

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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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

          const SizedBox(height: 16),

          // Log Mood button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showMoodPickerSheet(context, ref),
              icon: const Icon(Icons.mood),
              label: const Text('Log Mood'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

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

class _AchievementsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BadgeIcon(icon: '🏆', label: 'First Workout', unlocked: true),
          _BadgeIcon(icon: '🔥', label: '7 Day Streak', unlocked: true),
          _BadgeIcon(icon: '💪', label: '10 Workouts', unlocked: true),
          _BadgeIcon(icon: '🎯', label: '30 Days', unlocked: false),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final String icon;
  final String label;
  final bool unlocked;

  const _BadgeIcon({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          icon,
          style: TextStyle(
            fontSize: 32,
            color: unlocked ? null : Colors.grey.withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

class _PlaceholderGraph extends StatelessWidget {
  final double height;
  final String message;

  const _PlaceholderGraph({required this.height, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(Coming soon)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PRList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final prs = [
      {'exercise': 'Bench Press', 'weight': '100 kg', 'date': '2024-01-15'},
      {'exercise': 'Squat', 'weight': '140 kg', 'date': '2024-01-10'},
      {'exercise': 'Deadlift', 'weight': '160 kg', 'date': '2024-01-08'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: prs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final pr = prs[index];
          return ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.orange),
            title: Text(pr['exercise']!),
            subtitle: Text(pr['date']!),
            trailing: Text(
              pr['weight']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MeasurementsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final measurements = [
      {'label': 'Weight', 'value': '75.0 kg', 'change': '-2.5 kg'},
      {'label': 'Body Fat', 'value': '15.2%', 'change': '-1.8%'},
      {'label': 'Chest', 'value': '102 cm', 'change': '+3 cm'},
      {'label': 'Waist', 'value': '82 cm', 'change': '-5 cm'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: measurements.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final measurement = measurements[index];
          final isPositive = measurement['change']!.startsWith('+');
          final isNegative = measurement['change']!.startsWith('-');

          return ListTile(
            title: Text(measurement['label']!),
            subtitle: Text(measurement['change']!),
            trailing: Text(
              measurement['value']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? AppColors.success
                    : isNegative
                        ? AppColors.orange
                        : AppColors.cyan,
              ),
            ),
          );
        },
      ),
    );
  }
}
