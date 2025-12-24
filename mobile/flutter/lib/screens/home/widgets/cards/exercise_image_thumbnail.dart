import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/image_url_cache.dart';

/// A thumbnail widget for displaying exercise images
/// Loads images from the API and caches them for performance
class ExerciseImageThumbnail extends ConsumerStatefulWidget {
  /// The exercise to display
  final WorkoutExercise exercise;

  /// Size of the thumbnail (width and height)
  final double size;

  const ExerciseImageThumbnail({
    super.key,
    required this.exercise,
    this.size = 44,
  });

  @override
  ConsumerState<ExerciseImageThumbnail> createState() =>
      _ExerciseImageThumbnailState();
}

class _ExerciseImageThumbnailState
    extends ConsumerState<ExerciseImageThumbnail> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  Future<void> _loadImageUrl() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    // Check persistent cache first (survives app restarts)
    final cachedUrl = ImageUrlCache.get(exerciseName);
    if (cachedUrl != null) {
      if (mounted) {
        setState(() {
          _imageUrl = cachedUrl;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          // Store in persistent cache
          await ImageUrlCache.set(exerciseName, url);
          setState(() {
            _imageUrl = url;
            _isLoading = false;
          });
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything if there's an error or no image (no fallback)
    if (_hasError && !_isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.cyan,
          ),
        ),
      );
    }

    // If no image URL, return empty - no fallback icons
    if (_imageUrl == null) {
      return const SizedBox.shrink();
    }

    return CachedNetworkImage(
      imageUrl: _imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.cyan,
          ),
        ),
      ),
      // On network error loading the image, show empty instead of fallback icon
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
