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
import '../../widgets/app_loading.dart';
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
import '../../widgets/glass_sheet.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../widgets/main_shell.dart';
import 'log_measurement_sheet.dart';
import 'comparison_view.dart';
import 'photo_editor_screen.dart';
import 'widgets/readiness_checkin_card.dart';
import 'widgets/strength_overview_card.dart';
import 'widgets/pr_summary_card.dart';

part 'progress_screen_part_analytics_nav_card.dart';

part 'progress_screen_ui.dart';

part 'progress_screen_ext.dart';


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
        appBar: PillAppBar(
          title: 'Progress',
          actions: [
            PillAppBarAction(
              icon: Icons.compare_arrows,
              onTap: _userId != null ? _showComparisonPicker : null,
            ),
          ],
        ),
        body: _isLoading || _userId == null
            ? AppLoading.fullScreen()
            : Column(
                children: [
                  SegmentedTabBar(
                    controller: _tabController,
                    showIcons: true,
                    tabs: const [
                      SegmentedTabItem(label: 'Scores', icon: Icons.fitness_center),
                      SegmentedTabItem(label: 'Photos', icon: Icons.photo_library),
                      SegmentedTabItem(label: 'Measurements', icon: Icons.straighten),
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
        floatingActionButton: _buildFAB(),
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
          const SnackBar(
            content: Text('Failed to process photo. Please try again.'),
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
          const SnackBar(
            content: Text('Failed to process photo. Please try again.'),
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
