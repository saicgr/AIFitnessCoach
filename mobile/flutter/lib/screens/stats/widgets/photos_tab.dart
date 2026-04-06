import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/animations/app_animations.dart';
import '../../../data/models/progress_photos.dart';
import '../../../data/repositories/progress_photos_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/glass_sheet.dart';
import '../../progress/comparison_view.dart';
import '../../progress/comparison_gallery.dart';
import '../../progress/photo_editor_screen.dart';

part 'photos_tab_ui.dart';


// ═══════════════════════════════════════════════════════════════════
// PHOTOS TAB - Progress photos from different angles
// ═══════════════════════════════════════════════════════════════════

class PhotosTab extends ConsumerStatefulWidget {
  final String? userId;
  final bool openPhotoSheet;

  const PhotosTab({super.key, this.userId, this.openPhotoSheet = false});

  @override
  ConsumerState<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<PhotosTab>
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
                child: _buildGridControls(state.stats?.totalPhotos ?? 0),
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
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accentColor : elevated,
              borderRadius: BorderRadius.circular(18),
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
      height: 48,
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

  Widget _buildGridControls(int totalPhotos) {
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
          // Photo count
          Text(
            '$totalPhotos photo${totalPhotos == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
          ),
          const SizedBox(width: 8),
          // Sort toggle (icon only)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                _sortNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 18,
                color: textSecondary,
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
          const SizedBox(width: 12),
          // Compare button
          GestureDetector(
            onTap: () {
              HapticService.light();
              if (widget.userId != null) {
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => ComparisonView(userId: widget.userId!),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    'Compare',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
                  ),
                ],
              ),
            ),
          ),
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
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: PhotoViewType.values.map((type) => ListTile(
                        leading: Icon(_getViewTypeIcon(type)),
                        title: Text(type.displayName),
                        subtitle: Text(_getViewTypeDescription(type)),
                        onTap: () => Navigator.pop(context, type),
                      )).toList(),
                ),
              ),
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
