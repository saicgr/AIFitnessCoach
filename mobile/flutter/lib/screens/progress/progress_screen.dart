import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/progress_photos.dart';
import '../../data/models/scores.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/main_shell.dart';
import 'log_measurement_sheet.dart';
import 'comparison_view.dart';
import 'photo_editor_screen.dart';
import 'widgets/readiness_checkin_card.dart';
import 'widgets/strength_overview_card.dart';
import 'widgets/pr_summary_card.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  String? _userId;
  late TabController _tabController;
  bool _isLoading = true;
  PhotoViewType? _selectedViewFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  void _handleTabChange() {
    // Trigger rebuild when tab changes for FAB visibility
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null) {
      setState(() {
        _userId = userId;
        _isLoading = false;
      });
      // Load photos data
      ref.read(progressPhotosNotifierProvider(userId).notifier).loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if guest - progress tracking is disabled for guests
    final isGuest = ref.watch(isGuestModeProvider);
    final progressEnabled = ref.watch(isProgressTrackingEnabledProvider);

    if (isGuest && !progressEnabled) {
      final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
      final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
      final teal = isDark ? AppColors.teal : AppColorsLight.teal;

      return MainShell(
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.insights,
                        size: 48,
                        color: teal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Progress Tracking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Track your fitness journey with progress photos, body measurements, and strength scores. See how far you\'ve come!',
                      style: TextStyle(
                        fontSize: 15,
                        color: textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
                          if (mounted) {
                            context.go('/pre-auth-quiz');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Sign Up to Unlock',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 15,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MainShell(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Progress'),
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Compare Photos',
              onPressed: _userId != null ? _showComparisonPicker : null,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.fitness_center), text: 'Scores'),
              Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
              Tab(icon: Icon(Icons.straighten), text: 'Measurements'),
            ],
          ),
        ),
        body: _isLoading || _userId == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildScoresTab(),
                  _buildPhotosTab(),
                  _buildMeasurementsTab(),
                ],
              ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget? _buildFAB() {
    // No FAB for Scores tab (index 0)
    if (_tabController.index == 0) return null;

    final isPhotosTab = _tabController.index == 1;
    return FloatingActionButton.extended(
      onPressed: () => isPhotosTab
          ? _showAddPhotoSheet()
          : _showAddMeasurementSheet(),
      icon: Icon(isPhotosTab ? Icons.camera_alt : Icons.add),
      label: Text(isPhotosTab ? 'Add Photo' : 'Log Measurement'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  // ============================================
  // Scores Tab
  // ============================================

  Widget _buildScoresTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(scoresProvider.notifier).loadScoresOverview(userId: _userId);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Readiness Check-in Card
            ReadinessCheckinCard(
              userId: _userId!,
              onCheckInComplete: () {
                // Refresh overview after check-in
                ref.read(scoresProvider.notifier).loadScoresOverview();
              },
            ),
            const SizedBox(height: 16),

            // Strength Overview Card
            StrengthOverviewCard(
              userId: _userId!,
              onTapMuscleGroup: (muscleGroup) {
                // Navigate to muscle detail - we could add a detailed view later
                _showMuscleDetail(muscleGroup);
              },
            ),
            const SizedBox(height: 16),

            // Personal Records Summary Card
            PRSummaryCard(userId: _userId!),
            const SizedBox(height: 16),

            // Analytics Navigation Cards
            _buildAnalyticsNavigationSection(),
            const SizedBox(height: 80), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsNavigationSection() {
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

  void _showMuscleDetail(String muscleGroup) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      _formatMuscleGroupName(muscleGroup),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final scoresState = ref.watch(scoresProvider);
                      final muscleData =
                          scoresState.strengthScores?.muscleScores[muscleGroup];

                      if (muscleData == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No data for this muscle group yet',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete workouts targeting this muscle\nto see your strength progress.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Level card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Color(muscleData.levelColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(muscleData.levelColor)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(muscleData.levelColor),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${muscleData.strengthScore}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        muscleData.levelDisplayName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(muscleData.levelColor),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: muscleData.progressToNextLevel,
                                          backgroundColor: colorScheme.outline
                                              .withOpacity(0.2),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(muscleData.levelColor),
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Progress to next level',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Stats
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Best Exercise',
                            muscleData.bestExerciseName ?? 'N/A',
                            Icons.star,
                          ),
                          if (muscleData.bestEstimated1rmKg != null)
                            _buildDetailRow(
                              'Estimated 1RM',
                              '${muscleData.bestEstimated1rmKg!.toStringAsFixed(1)} kg',
                              Icons.fitness_center,
                            ),
                          if (muscleData.bodyweightRatio != null)
                            _buildDetailRow(
                              'Bodyweight Ratio',
                              '${muscleData.bodyweightRatio!.toStringAsFixed(2)}x',
                              Icons.monitor_weight,
                            ),
                          _buildDetailRow(
                            'Weekly Sets',
                            '${muscleData.weeklySets}',
                            Icons.repeat,
                          ),
                          _buildDetailRow(
                            'Weekly Volume',
                            '${muscleData.weeklyVolumeKg.toStringAsFixed(0)} kg',
                            Icons.trending_up,
                          ),
                          _buildDetailRow(
                            'Trend',
                            muscleData.trend[0].toUpperCase() +
                                muscleData.trend.substring(1),
                            _getTrendIcon(muscleData.trendDirection),
                            valueColor:
                                _getTrendColor(muscleData.trendDirection),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMuscleGroupName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return Icons.trending_up;
      case TrendDirection.declining:
        return Icons.trending_down;
      case TrendDirection.maintaining:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return Colors.green;
      case TrendDirection.declining:
        return Colors.red;
      case TrendDirection.maintaining:
        return Colors.grey;
    }
  }

  // ============================================
  // Photos Tab
  // ============================================

  Widget _buildPhotosTab() {
    final state = ref.watch(progressPhotosNotifierProvider(_userId!));
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(progressPhotosNotifierProvider(_userId!).notifier)
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
    final colorScheme = Theme.of(context).colorScheme;
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

  // ============================================
  // Measurements Tab
  // ============================================

  Widget _buildMeasurementsTab() {
    // TODO: Implement measurements tab with body_measurements data
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.straighten_outlined,
              size: 80,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Body Measurements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your body measurements to see detailed progress beyond the scale.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddMeasurementSheet,
              icon: const Icon(Icons.add),
              label: const Text('Log Measurements'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Actions
  // ============================================

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
    if (_userId == null) return;

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
          .read(progressPhotosNotifierProvider(_userId!).notifier)
          .uploadPhoto(
            imageFile: imageFile,
            viewType: viewType,
          );

      // Award first-time progress photo bonus (+75 XP)
      ref.read(xpProvider.notifier).checkFirstProgressPhotoBonus();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        // Show success dialog - more prominent than snackbar
        _showUploadSuccessDialog(viewType);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        // Show error dialog - more prominent than snackbar
        _showUploadErrorDialog(e.toString());
      }
    }
  }

  void _showUploadSuccessDialog(PhotoViewType viewType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
        ),
        title: const Text('Photo Saved!'),
        content: Text(
          'Your ${viewType.displayName} progress photo has been saved successfully.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _showUploadErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
        ),
        title: const Text('Upload Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We couldn\'t save your photo. Please try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _showAddMeasurementSheet() {
    if (_userId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogMeasurementSheet(userId: _userId!),
    );
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

    if (confirmed == true && mounted) {
      Navigator.pop(context); // Close detail sheet
      await ref
          .read(progressPhotosNotifierProvider(_userId!).notifier)
          .deletePhoto(photo.id);
    }
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
