import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/workout_gallery_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/workout_gallery_service.dart';

/// Workout Gallery Section for Profile Screen
///
/// Shows a 2x2 grid of recent workout gallery images with a "See All" button.
/// Displays empty state if no images exist.
class WorkoutGallerySection extends ConsumerStatefulWidget {
  const WorkoutGallerySection({super.key});

  @override
  ConsumerState<WorkoutGallerySection> createState() => _WorkoutGallerySectionState();
}

class _WorkoutGallerySectionState extends ConsumerState<WorkoutGallerySection> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted && userId != null) {
      setState(() => _userId = userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final recentImagesAsync = ref.watch(recentGalleryImagesProvider(_userId!));

    return recentImagesAsync.when(
      data: (images) => _buildSection(context, images, elevated, isDark),
      loading: () => _buildLoadingSection(elevated),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSection(
    BuildContext context,
    List<WorkoutGalleryImage> images,
    Color elevated,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Workout Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (images.isNotEmpty)
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/workout-gallery');
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          if (images.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildGalleryGrid(images),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No workout images yet',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a workout and share it to build your gallery',
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

  Widget _buildGalleryGrid(List<WorkoutGalleryImage> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 9 / 16,
      ),
      itemCount: images.length > 4 ? 4 : images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildGalleryItem(image);
      },
    );
  }

  Widget _buildGalleryItem(WorkoutGalleryImage image) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showImageDetail(image);
      },
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
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.6, 1.0],
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

              // Workout name
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  image.workoutName ?? 'Workout',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
      errorWidget: (_, __, ___) => _buildImageErrorWidget(),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: AppColors.elevated,
      child: Icon(
        Icons.broken_image_rounded,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildLoadingSection(Color elevated) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Workout Gallery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showImageDetail(WorkoutGalleryImage image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageDetailSheet(image: image, userId: _userId!),
    );
  }
}

/// Image detail bottom sheet
class _ImageDetailSheet extends ConsumerWidget {
  final WorkoutGalleryImage image;
  final String userId;

  const _ImageDetailSheet({
    required this.image,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                Text(
                  image.workoutName ?? 'Workout Recap',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context, ref),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          // Image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildDetailImage(image.imageUrl),
              ),
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(Icons.timer_outlined, image.formattedDuration),
                if (image.exercisesCount != null)
                  _buildStat(Icons.fitness_center, '${image.exercisesCount} exercises'),
                if (image.calories != null)
                  _buildStat(Icons.local_fire_department_outlined, '${image.calories} cal'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Share info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (image.sharedToFeed) ...[
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Posted to feed',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (image.externalSharesCount > 0) ...[
                  Icon(Icons.share_rounded, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 4),
                  Text(
                    'Shared ${image.externalSharesCount} times',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Build detail image widget that handles both data URLs and network URLs
  Widget _buildDetailImage(String imageUrl) {
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
            child: Icon(Icons.broken_image_rounded, size: 48),
          ),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image_rounded, size: 48),
        );
      }
    }

    // Network URL - use CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_rounded, size: 48),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet

              final deleteNotifier = ref.read(galleryDeleteProvider.notifier);
              await deleteNotifier.deleteImage(
                userId: userId,
                imageId: image.id,
              );

              // Invalidate the gallery provider to refresh
              ref.invalidate(recentGalleryImagesProvider(userId));
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
}
