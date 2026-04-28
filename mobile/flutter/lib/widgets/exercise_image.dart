import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../data/services/api_client.dart';
import '../data/services/image_url_cache.dart';

/// Dedicated CacheManager for exercise illustrations.
///
/// Why a custom manager?
/// - The default `DefaultCacheManager` shares its HTTP queue with every other
///   `CachedNetworkImage` in the app. When a 50-row exercise grid mounts, the
///   shared client serializes requests and later rows render blank for seconds.
/// - This manager keeps a larger object cache (500) and a longer stale period
///   (30 days) since exercise illustrations rarely change. Concurrency is
///   handled by giving exercise images their own queue, isolated from food
///   thumbnails / progress photos. ✅
class _ExerciseImageCacheManager {
  static const String _key = 'exerciseImagesV1';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );
}

/// A reusable widget for displaying exercise images
/// Fetches presigned URLs from the API and caches them
class ExerciseImage extends ConsumerStatefulWidget {
  /// The exercise name to display image for
  final String exerciseName;

  /// Pre-resolved image URL (e.g., presigned URL from library API).
  /// If this is a valid HTTP(S) URL, it is used directly without an API call.
  final String? imageUrl;

  /// Width of the image container
  final double width;

  /// Height of the image container
  final double height;

  /// Border radius for the image container
  final double borderRadius;

  /// Background color when loading or on error
  final Color? backgroundColor;

  /// Icon color for the fallback icon
  final Color? iconColor;

  /// Box fit for the image
  final BoxFit fit;

  const ExerciseImage({
    super.key,
    required this.exerciseName,
    this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.borderRadius = 8,
    this.backgroundColor,
    this.iconColor,
    this.fit = BoxFit.cover,
  });

  @override
  ConsumerState<ExerciseImage> createState() => _ExerciseImageState();
}

class _ExerciseImageState extends ConsumerState<ExerciseImage> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  @override
  void didUpdateWidget(ExerciseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName ||
        oldWidget.imageUrl != widget.imageUrl) {
      _loadImageUrl();
    }
  }

  Future<void> _loadImageUrl() async {
    // Reset state for fresh load (important when widget updates)
    _hasError = false;
    _isLoading = true;
    _imageUrl = null;

    final exerciseName = widget.exerciseName;

    // If a pre-resolved HTTP URL is provided (e.g., presigned URL from library API),
    // use it directly without an API call.
    final preResolved = widget.imageUrl;
    if (preResolved != null && preResolved.startsWith('http')) {
      if (mounted) {
        setState(() {
          _imageUrl = preResolved;
          _isLoading = false;
        });
      }
      // Cache for future use by name-only lookups
      if (exerciseName.isNotEmpty) {
        ImageUrlCache.set(exerciseName, preResolved);
      }
      return;
    }

    if (exerciseName.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    // Check persistent cache first
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F5));
    final fallbackIconColor = widget.iconColor ??
        (isDark ? Colors.white38 : Colors.black38);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildContent(fallbackIconColor),
    );
  }

  Widget _buildContent(Color fallbackIconColor) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _imageUrl == null) {
      return Icon(
        Icons.fitness_center,
        color: fallbackIconColor,
        size: widget.width.isFinite ? widget.width * 0.5 : 40,
      );
    }

    return CachedNetworkImage(
      imageUrl: _imageUrl!,
      // Dedicated cache manager isolates exercise-illustration HTTP traffic
      // from the rest of the app so a 50-row grid doesn't starve other
      // image loads (and vice versa). ✅
      cacheManager: _ExerciseImageCacheManager.instance,
      // Use exercise name as stable cache key so presigned URL rotation
      // doesn't duplicate images in disk cache.
      cacheKey: widget.exerciseName.isNotEmpty ? widget.exerciseName : null,
      fit: widget.fit,
      // Perf fix 2.2: constrain decoded image size in memory cache
      memCacheWidth: widget.width.isFinite ? (widget.width * 2).toInt().clamp(100, 400) : null,
      memCacheHeight: widget.height.isFinite ? (widget.height * 2).toInt().clamp(100, 400) : null,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(
        Icons.fitness_center,
        color: fallbackIconColor,
        size: widget.width.isFinite ? widget.width * 0.5 : 40,
      ),
    );
  }
}
