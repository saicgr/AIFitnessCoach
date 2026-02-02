import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/progress_photos.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/activity_heatmap.dart';
import '../../widgets/exercise_search_results.dart';
import '../../widgets/workout_day_detail_sheet.dart';
import '../progress/comparison_view.dart';
import '../progress/photo_editor_screen.dart';
import '../progress/widgets/readiness_checkin_card.dart';
import '../progress/widgets/strength_overview_card.dart';
import '../progress/widgets/pr_summary_card.dart';
import 'widgets/date_range_filter_sheet.dart';
import 'widgets/export_stats_sheet.dart';
import 'widgets/share_stats_sheet.dart';

/// Comprehensive Stats Screen
/// Combines: Workout stats, achievements, body measurements, progress graphs, nutrition
class ComprehensiveStatsScreen extends ConsumerStatefulWidget {
  /// If true, opens the add photo sheet immediately after loading
  final bool openPhotoSheet;

  const ComprehensiveStatsScreen({
    super.key,
    this.openPhotoSheet = false,
  });

  @override
  ConsumerState<ComprehensiveStatsScreen> createState() => _ComprehensiveStatsScreenState();
}

class _ComprehensiveStatsScreenState extends ConsumerState<ComprehensiveStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    // Use dynamic accent color from provider
    final cyan = ref.colors(context).accent;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        automaticallyImplyLeading: false,
        title: Text(
          'Your Progress',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          // Compare Photos (only show when photos tab visible)
          if (_userId != null)
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: cyan,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Photos'),
                Tab(text: 'Strength'),
                Tab(text: 'Body'),
                Tab(text: 'Nutrition'),
              ],
            ),
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
                _NutritionTab(),
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
      MaterialPageRoute(
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
            icon: Icons.insights,
            label: 'View Detailed Metrics',
            onTap: () => context.push('/metrics'),
          ),
          const SizedBox(height: 8),
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

class _PhotosTabState extends ConsumerState<_PhotosTab> {
  PhotoViewType? _selectedViewFilter;
  bool _hasOpenedPhotoSheet = false;

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
    if (widget.userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = ref.watch(progressPhotosNotifierProvider(widget.userId!));

    return RefreshIndicator(
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
    selectedType = await showModalBottomSheet<PhotoViewType>(
      context: context,
      useRootNavigator: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
    );

    if (selectedType == null || !mounted) return;

    // Then pick image source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
    );

    if (source == null || !mounted) return;

    // Pick the image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null || !mounted) return;

    // Open photo editor for cropping and logo overlay
    final editedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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

class _NutritionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Daily Averages (7 days)'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '2,150',
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.opacity,
                  label: 'Water',
                  value: '2.1L',
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'Macro Breakdown'),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 150,
            message: 'Protein / Carbs / Fats pie chart',
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'Calorie Trend'),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 200,
            message: 'Daily calorie intake over time',
          ),

          const SizedBox(height: 24),

          // Quick action to nutrition screen
          ElevatedButton.icon(
            onPressed: () => context.go('/nutrition'),
            icon: const Icon(Icons.restaurant),
            label: const Text('Track Nutrition'),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
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
