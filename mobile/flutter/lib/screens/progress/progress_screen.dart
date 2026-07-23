import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/progress_photos.dart';
import '../../core/animations/app_animations.dart';
import '../../data/models/muscle_status.dart';
import '../../data/models/scores.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/measurements_repository.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/glass_sheet.dart';
import '../reports/widgets/report_share_sheet.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../widgets/main_shell.dart';
import 'log_measurement_sheet.dart';
import 'comparison_view.dart';
import 'photo_editor_screen.dart';
import 'widgets/readiness_checkin_card.dart';
import 'widgets/strength_overview_card.dart';
import 'widgets/pr_summary_card.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
part 'progress_screen_part_analytics_nav_card.dart';

part 'progress_screen_ui.dart';

part 'progress_screen_ext.dart';


class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({
    super.key,
    this.initialTab,
    this.preuploadedPhotoS3Keys,
  });

  /// Open with a specific tab selected. Used by the Imports feature
  /// (`progress?tab=photos`) and by deep links.
  final int? initialTab;

  /// Imports feature — when the share funnel routes a progress photo (or
  /// a multi-photo batch) here, the keys are pre-uploaded to S3 by the
  /// `/share/classify` pipeline. The Photos tab picks these up on first
  /// build and runs through the normal "create progress photo" flow.
  final List<String>? preuploadedPhotoS3Keys;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  String? _userId;
  late TabController _tabController;
  bool _isLoading = true;
  PhotoViewType? _selectedViewFilter;
  final GlobalKey _reportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    ref.read(posthogServiceProvider).capture(eventName: 'progress_screen_viewed');
    _loadData();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final tabNames = ['scores', 'photos', 'measurements'];
      ref.read(posthogServiceProvider).capture(
        eventName: 'progress_tab_changed',
        properties: <String, Object>{'tab_name': tabNames[_tabController.index]},
      );
    }
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
      // Load photos and measurements data
      ref.read(progressPhotosNotifierProvider(userId).notifier).loadAll();
      ref.read(measurementsProvider.notifier).loadAllMeasurements(userId);
    }
  }

  /// Opens the unified ReportShareSheet for the Progress screen. We use
  /// `periodInsights` as the report type since Progress is scoped to the
  /// current month and funnels the same four headline stats (workouts,
  /// minutes, calories, streak) that the Insights screen does.
  Future<void> _openShareSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final user = ref.read(currentUserProvider).asData?.value;
    final scores = ref.read(scoresProvider);
    final overview = scores.overview;
    final periodLabel =
        DateFormat('MMM yyyy').format(DateTime.now()).toUpperCase();

    // Pull primary stats from the scores overview when available; otherwise
    // the share card hero falls back to "—". We prefer the strength score as
    // the hero because Progress is primarily a scores surface.
    final stats = <String, dynamic>{};
    final highlights = <ReportHighlight>[];
    if (overview != null) {
      stats['hero_value'] = overview.overallStrengthScore;
      stats['hero_unit'] = 'strength';
      highlights.add(ReportHighlight(
        label: AppLocalizations.of(context).workoutsStrength,
        value: '${overview.overallStrengthScore}',
      ));
      if (overview.prCount30Days > 0) {
        highlights.add(ReportHighlight(
          label: AppLocalizations.of(context).progressPrs30d,
          value: '${overview.prCount30Days}',
        ));
      }
      if (overview.overallFitnessScore != null) {
        highlights.add(ReportHighlight(
          label: AppLocalizations.of(context).progressFitness,
          value: '${overview.overallFitnessScore}',
        ));
      }
    }

    final data = ReportShareData(
      reportType: ReportType.periodInsights,
      title: AppLocalizations.of(context).navProgress,
      periodLabel: periodLabel,
      primaryStats: stats,
      highlights: highlights,
      userDisplayName: user?.displayName,
      accentColor: accent,
      deepLinkUrl: null,
    );
    if (!mounted) return;
    await ReportShareSheet.show(context, data: data);
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
                      AppLocalizations.of(context).progressProgressTracking,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).progressTrackYourFitnessJourney,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch, size: 20),
                            SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context).progressSignUpToUnlock,
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
        appBar: PillAppBar(
          title: AppLocalizations.of(context).navProgress,
          showBack: false,
          actions: [
            PillAppBarAction(
              icon: Icons.ios_share_rounded,
              onTap: _userId == null ? null : _openShareSheet,
            ),
            PillAppBarAction(
              icon: Icons.compare_arrows,
              onTap: _userId != null ? _showComparisonPicker : null,
            ),
          ],
        ),
        body: _isLoading || _userId == null
            // Instant-load: a layout-matched skeleton instead of a blocking
            // full-screen spinner. `_userId` is resolved from a fast local
            // SharedPreferences read, so this skeleton is on screen only for
            // the brief moment before the first frame's microtask completes.
            ? _buildLoadingSkeleton()
            : RepaintBoundary(
                key: _reportKey,
                child: Container(
                  color: colorScheme.surface,
                  child: Column(
                    children: [
                      SegmentedTabBar(
                        controller: _tabController,
                        showIcons: true,
                        tabs: [
                          SegmentedTabItem(label: AppLocalizations.of(context).progressScores, icon: Icons.fitness_center),
                          SegmentedTabItem(label: AppLocalizations.of(context).progressPhotos, icon: Icons.photo_library),
                          SegmentedTabItem(label: AppLocalizations.of(context).quickLogMeasurementsMeasurements, icon: Icons.straighten),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildScoresTab(),
                            _buildPhotosTab(),
                            _buildMeasurementsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  /// Layout-matched first-open skeleton for the whole Progress screen —
  /// mirrors the segmented tab bar plus the Scores tab's stack of cards so
  /// the skeleton → content swap does not reflow. Replaces the old blocking
  /// full-screen spinner.
  Widget _buildLoadingSkeleton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented tab bar placeholder.
            const SkeletonBox(height: 44, radius: 12),
            const SizedBox(height: 16),
            // Stacked content cards (readiness, strength, PRs, analytics).
            const SkeletonBox(height: 120, radius: 16),
            const SizedBox(height: 16),
            const SkeletonBox(height: 160, radius: 16),
            const SizedBox(height: 16),
            const SkeletonBox(height: 120, radius: 16),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: SkeletonBox(height: 96, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 96, radius: 16)),
              ],
            ),
          ],
        ),
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

  Widget _buildViewTypeFilter() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: Text(AppLocalizations.of(context).syncedWorkoutsHistoryAll),
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

  // ============================================
  // Actions
  // ============================================

  /// Add photo for a specific view type — skips the view type selection step
  Future<void> _addPhotoForViewType(PhotoViewType viewType) async {
    // Pick image source directly
    final source = await showGlassSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context).progressTakePhoto),
                subtitle: Text(AppLocalizations.of(context).progressUseCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context).progressChooseFromGallery),
                subtitle: Text(AppLocalizations.of(context).progressSelectExistingPhoto),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null || !mounted) return;

      final editedFile = await Navigator.push<File>(
        context,
        AppPageRoute(
          builder: (context) => PhotoEditorScreen(
            imageFile: File(pickedFile.path),
            viewTypeName: viewType.displayName,
          ),
        ),
      );

      if (editedFile != null && mounted) {
        _uploadPhoto(editedFile, viewType);
      }
    } catch (e) {
      debugPrint('❌ [Progress] Error picking/editing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).progressFailedToProcessPhoto),
          ),
        );
      }
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).progressSelectViewType,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context).progressTakePhoto),
              subtitle: Text(AppLocalizations.of(context).progressUseCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).progressChooseFromGallery),
              subtitle: Text(AppLocalizations.of(context).progressSelectExistingPhoto),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
      ),
    );

    if (source == null || !mounted) return;

    try {
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
    } catch (e) {
      debugPrint('❌ [Progress] Error picking/editing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).progressFailedToProcessPhoto),
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto(File imageFile, PhotoViewType viewType) async {
    if (_userId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(AppLocalizations.of(context).quickActionsRowUploadingPhoto),
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
        title: Text(AppLocalizations.of(context).progressPhotoSaved),
        content: Text(
          'Your ${viewType.displayName} progress photo has been saved successfully.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).progressGreat),
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
        title: Text(AppLocalizations.of(context).progressUploadFailed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).progressWeCouldnTSave,
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
            child: Text(AppLocalizations.of(context).progressOk),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _showAddMeasurementSheet() {
    if (_userId == null) return;
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: LogMeasurementSheet(userId: _userId!),
      ),
    );
  }

  void _showPhotoDetail(ProgressPhoto photo) {
    final colorScheme = Theme.of(context).colorScheme;
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
                                    label: Text(AppLocalizations.of(context).buttonDelete),
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
        title: Text(AppLocalizations.of(context).progressDeletePhoto),
        content: Text(AppLocalizations.of(context).workoutActionsThisActionCannotBe),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context).buttonDelete),
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
      AppPageRoute(
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
      default:
        return Icons.camera_alt;
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
      default:
        return 'Pose for a ${type.displayName} photo';
    }
  }
}
