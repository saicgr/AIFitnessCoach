import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/workout_gallery_provider.dart';
import '../../data/services/api_client.dart';
import '../../data/services/workout_gallery_service.dart';
import '../../data/services/share_service.dart';
import 'package:dio/dio.dart';

/// Full Workout Gallery Screen
///
/// Shows all workout gallery images in a scrollable grid with:
/// - Filter by template type
/// - Tap to view full size
/// - Long press for options (delete, re-share)
class WorkoutGalleryScreen extends ConsumerStatefulWidget {
  const WorkoutGalleryScreen({super.key});

  @override
  ConsumerState<WorkoutGalleryScreen> createState() => _WorkoutGalleryScreenState();
}

class _WorkoutGalleryScreenState extends ConsumerState<WorkoutGalleryScreen> {
  String? _userId;
  GalleryTemplateType? _selectedFilter;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final List<WorkoutGalleryImage> _images = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted && userId != null) {
      setState(() => _userId = userId);
      _loadImages();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreImages();
    }
  }

  Future<void> _loadImages() async {
    if (_userId == null) return;

    setState(() {
      _currentPage = 1;
      _images.clear();
    });

    try {
      final service = ref.read(workoutGalleryServiceProvider);
      final result = await service.getGalleryImages(
        userId: _userId!,
        page: 1,
        pageSize: 20,
        templateType: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _images.addAll(result.images);
          _hasMore = result.hasMore;
        });
      }
    } catch (e) {
      debugPrint('Error loading gallery: $e');
    }
  }

  Future<void> _loadMoreImages() async {
    if (_userId == null || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final service = ref.read(workoutGalleryServiceProvider);
      final result = await service.getGalleryImages(
        userId: _userId!,
        page: _currentPage + 1,
        pageSize: 20,
        templateType: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _images.addAll(result.images);
          _currentPage++;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Workout Gallery'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadImages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Gallery grid
          Expanded(
            child: _buildGalleryGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(null, 'All'),
          const SizedBox(width: 8),
          _buildFilterChip(GalleryTemplateType.stats, 'Stats'),
          const SizedBox(width: 8),
          _buildFilterChip(GalleryTemplateType.prs, 'PRs'),
          const SizedBox(width: 8),
          _buildFilterChip(GalleryTemplateType.photoOverlay, 'Photo'),
          const SizedBox(width: 8),
          _buildFilterChip(GalleryTemplateType.motivational, 'Motivational'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(GalleryTemplateType? type, String label) {
    final isSelected = _selectedFilter == type;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = selected ? type : null);
        _loadImages();
      },
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      checkmarkColor: AppColors.cyan,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.cyan : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildGalleryGrid() {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_images.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadImages,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 9 / 16,
        ),
        itemCount: _images.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          return _buildGalleryItem(_images[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No images yet',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a workout and share it\nto start your gallery',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(WorkoutGalleryImage image) {
    return GestureDetector(
      onTap: () => _showImageDetail(image),
      onLongPress: () => _showImageOptions(image),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image - handles both data URLs and network URLs
              _buildGalleryImage(image.imageUrl),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Template type badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTemplateColor(image.templateType).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTemplateLabel(image.templateType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Shared badges
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (image.sharedToFeed)
                      _buildBadge(Icons.feed_rounded, AppColors.cyan),
                    if (image.sharedExternally) ...[
                      const SizedBox(width: 4),
                      _buildBadge(Icons.share_rounded, AppColors.purple),
                    ],
                  ],
                ),
              ),

              // Bottom info
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.workoutName ?? 'Workout',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          image.formattedDuration,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        if (image.totalVolumeKg != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.scale_outlined,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            image.formattedVolume,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build gallery image widget that handles both data URLs and network URLs
  Widget _buildGalleryImage(String imageUrl) {
    // Check if it's a data URL (base64 encoded image)
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 data from data URL
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageErrorWidget(),
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return _buildImageErrorWidget();
      }
    }

    // Network URL - use CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: AppColors.elevated,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, url, error) {
        debugPrint('Error loading image from $url: $error');
        return _buildImageErrorWidget();
      },
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: AppColors.elevated,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }

  Color _getTemplateColor(GalleryTemplateType type) {
    switch (type) {
      case GalleryTemplateType.stats:
        return AppColors.cyan;
      case GalleryTemplateType.prs:
        return const Color(0xFFFFD700);
      case GalleryTemplateType.photoOverlay:
        return AppColors.purple;
      case GalleryTemplateType.motivational:
        return AppColors.orange;
    }
  }

  String _getTemplateLabel(GalleryTemplateType type) {
    switch (type) {
      case GalleryTemplateType.stats:
        return 'Stats';
      case GalleryTemplateType.prs:
        return 'PRs';
      case GalleryTemplateType.photoOverlay:
        return 'Photo';
      case GalleryTemplateType.motivational:
        return 'Motivational';
    }
  }

  void _showImageDetail(WorkoutGalleryImage image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullImageScreen(
          image: image,
          userId: _userId!,
          onDelete: () {
            setState(() {
              _images.removeWhere((i) => i.id == image.id);
            });
          },
        ),
      ),
    );
  }

  void _showImageOptions(WorkoutGalleryImage image) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share_rounded, color: AppColors.cyan),
              title: const Text('Share Again'),
              onTap: () async {
                Navigator.pop(context);
                await _reshareImage(image);
              },
            ),
            if (!image.sharedToFeed)
              ListTile(
                leading: Icon(Icons.feed_rounded, color: AppColors.purple),
                title: const Text('Post to Feed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _postToFeed(image);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reshareImage(WorkoutGalleryImage image) async {
    try {
      Uint8List imageBytes;

      // Handle both data URLs and network URLs
      if (image.imageUrl.startsWith('data:image')) {
        final base64Data = image.imageUrl.split(',').last;
        imageBytes = Uint8List.fromList(base64Decode(base64Data));
      } else {
        // Download image bytes using dio
        final dio = Dio();
        final response = await dio.get<List<int>>(
          image.imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode != 200 || response.data == null) {
          _showError('Failed to load image');
          return;
        }
        imageBytes = Uint8List.fromList(response.data!);
      }

      await ShareService.shareGeneric(
        imageBytes,
        caption: 'Check out my ${image.workoutName ?? "workout"}!',
      );

      // Track external share
      final service = ref.read(workoutGalleryServiceProvider);
      await service.trackExternalShare(
        userId: _userId!,
        imageId: image.id,
      );
    } catch (e) {
      debugPrint('Error resharing image: $e');
      _showError('Failed to share');
    }
  }

  Future<void> _postToFeed(WorkoutGalleryImage image) async {
    try {
      final service = ref.read(workoutGalleryServiceProvider);
      await service.shareToFeed(
        userId: _userId!,
        imageId: image.id,
      );

      _showSuccess('Posted to feed!');
      _loadImages(); // Refresh to update shared status
    } catch (e) {
      _showError('Failed to post to feed');
    }
  }

  void _confirmDelete(WorkoutGalleryImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This will remove the image from your gallery.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final service = ref.read(workoutGalleryServiceProvider);
              await service.deleteImage(
                userId: _userId!,
                imageId: image.id,
              );

              setState(() {
                _images.removeWhere((i) => i.id == image.id);
              });

              _showSuccess('Image deleted');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

/// Full screen image view
class _FullImageScreen extends StatelessWidget {
  final WorkoutGalleryImage image;
  final String userId;
  final VoidCallback onDelete;

  const _FullImageScreen({
    required this.image,
    required this.userId,
    required this.onDelete,
  });

  /// Build image widget that handles both data URLs and network URLs
  Widget _buildImage(String imageUrl) {
    // Check if it's a data URL (base64 encoded image)
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 data from data URL
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
          ),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
        );
      }
    }

    // Network URL - use CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(image.workoutName ?? 'Workout Recap'),
      ),
      body: InteractiveViewer(
        child: Center(
          child: _buildImage(image.imageUrl),
        ),
      ),
    );
  }
}
