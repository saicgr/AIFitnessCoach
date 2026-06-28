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
  // Guards the self-heal so a genuinely-missing image can't loop: we re-resolve
  // a failed cached URL at most once.
  bool _healedAfterError = false;

  @override
  void initState() {
    super.initState();
    // Check in-memory cache synchronously to avoid loading spinner flash
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      _isLoading = false;
      _hasError = true;
      return;
    }
    final cachedUrl = ImageUrlCache.get(exerciseName);
    if (cachedUrl != null) {
      _imageUrl = cachedUrl;
      _isLoading = false;
    } else {
      _fetchImageUrl(exerciseName);
    }
  }

  Future<void> _fetchImageUrl(String exerciseName) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
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
    // Always reserve the slot so callers (e.g. the workout thumbnail strip)
    // can rely on N exercises producing N visible tiles. When we can't load
    // an illustration we render a same-size placeholder rather than
    // collapsing to SizedBox.shrink, which previously made a 4-exercise
    // workout look like it only had 3.
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: (_hasError && !_isLoading) ? _buildPlaceholder() : _buildContent(),
    );
  }

  Widget _buildPlaceholder() {
    final name = widget.exercise.name;
    final initial = (name.isNotEmpty ? name[0] : '?').toUpperCase();
    // Tile size scales; below ~32px the initial gets unreadable so fall back
    // to the dumbbell icon alone.
    if (widget.size < 32) {
      return Icon(
        Icons.fitness_center,
        color: AppColors.cyan.withOpacity(0.7),
        size: widget.size * 0.5,
      );
    }
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: widget.size * 0.42,
          fontWeight: FontWeight.w700,
          color: AppColors.cyan.withOpacity(0.85),
        ),
      ),
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

    // If no image URL, show a clean fitness icon placeholder
    if (_imageUrl == null) {
      return Icon(
        Icons.fitness_center,
        color: AppColors.cyan.withOpacity(0.7),
        size: widget.size * 0.45,
      );
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
      // On network error loading the image, self-heal once: a cached URL can be
      // stale (wrong S3 prefix, moved file, expired presign). Evict it and
      // re-resolve a fresh URL from the server. If that ALSO fails, fall back to
      // the lettered placeholder (genuinely missing image). This is why we never
      // need to bump the cache version for a stale-URL bug again.
      errorWidget: (_, __, ___) {
        if (!_healedAfterError) {
          _healedAfterError = true;
          final name = widget.exercise.name;
          ImageUrlCache.evict(name).then((_) {
            if (mounted) {
              setState(() {
                _imageUrl = null;
                _isLoading = true;
              });
              _fetchImageUrl(name);
            }
          });
        }
        return _buildPlaceholder();
      },
    );
  }
}
