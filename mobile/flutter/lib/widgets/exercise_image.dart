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

  /// Optional equipment hint used to pick a more specific fallback icon
  /// when the backend returns no image. Pass the first item from the
  /// exercise's equipment list (e.g. "barbell", "dumbbells", "cable",
  /// "bodyweight", "kettlebell"). When omitted, the generic dumbbell
  /// silhouette is used. Fix for the "Barbell Close Grip Press shows a
  /// dumbbell" bug — placeholder now mirrors the exercise's actual gear.
  final String? equipmentHint;

  /// Optional library UUID. When supplied, the API call passes
  /// `?exercise_id=` so the backend resolves the exact library row instead
  /// of an ilike-on-name match — eliminates the "two exercises share a
  /// display name, the wrong dupe wins" class of bugs.
  final String? exerciseId;

  /// When true, an exercise with no resolvable illustration renders the
  /// Zealova mark on black instead of a guessed equipment icon. Use on
  /// surfaces (e.g. the plan preview) where a wrong icon reads worse than a
  /// clean brand placeholder.
  final bool brandFallback;

  /// Optional bundled-asset path (e.g. a baked preview illustration). When set
  /// it is shown FIRST — instant, offline, no network — and falls back to the
  /// normal URL-resolution flow if the asset is missing.
  final String? assetPath;

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
    this.equipmentHint,
    this.exerciseId,
    this.brandFallback = false,
    this.assetPath,
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
    // A baked asset is the source of truth — don't fire the (slow) network
    // resolve at all; the asset's errorBuilder falls back to the brand mark.
    if (widget.assetPath != null) {
      _isLoading = false;
    } else {
      _loadImageUrl();
    }
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

    // Check persistent cache first. Key by id when available so two exercises
    // that happen to share a display name don't pollute each other's cache.
    final cacheKey = widget.exerciseId ?? exerciseName;
    final cachedUrl = ImageUrlCache.get(cacheKey);
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
      final queryParams = <String, dynamic>{};
      if (widget.exerciseId != null && widget.exerciseId!.isNotEmpty) {
        queryParams['exercise_id'] = widget.exerciseId;
      }
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          // Store in persistent cache under id-keyed slot when we have one,
          // and always also under the name for the legacy lookup path.
          await ImageUrlCache.set(cacheKey, url);
          if (cacheKey != exerciseName) {
            await ImageUrlCache.set(exerciseName, url);
          }
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
    final bgColor =
        widget.backgroundColor ??
        (widget.brandFallback
            ? const Color(0xFF0A0A0B)
            : (isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F5)));
    final fallbackIconColor =
        widget.iconColor ?? (isDark ? Colors.white38 : Colors.black38);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      clipBehavior: Clip.hardEdge,
      child: widget.assetPath != null
          ? Image.asset(
              widget.assetPath!,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              // Baked asset missing → fall back to URL resolution / brand mark.
              errorBuilder: (_, __, ___) => _buildContent(fallbackIconColor),
            )
          : _buildContent(fallbackIconColor),
    );
  }

  /// Zealova mark on black — the brand placeholder when there's no
  /// illustration and [ExerciseImage.brandFallback] is set.
  Widget _brandMark() {
    return Center(
      child: Image.asset(
        'assets/icon/splash_logo.png',
        width: widget.width.isFinite ? widget.width * 0.58 : 34,
        height: widget.height.isFinite ? widget.height * 0.58 : 34,
        fit: BoxFit.contain,
      ),
    );
  }

  /// A layout-matched placeholder — the equipment-specific fallback icon
  /// centered on the container's background. Used both while the URL is being
  /// resolved AND while `CachedNetworkImage` downloads the bytes. Plan A9:
  /// prefer a placeholder that occupies the exact final layout box (no spinner
  /// pop / layout shift) so a grid of thumbnails settles instantly.
  Widget _placeholder(Color fallbackIconColor) {
    return Center(
      child: Icon(
        _fallbackIconForEquipment(widget.equipmentHint, widget.exerciseName),
        color: fallbackIconColor,
        size: widget.width.isFinite ? widget.width * 0.5 : 40,
      ),
    );
  }

  Widget _buildContent(Color fallbackIconColor) {
    // While resolving the URL, show the layout-matched placeholder (icon),
    // not a spinner — keeps the box stable from first to final frame. In
    // brand-fallback mode show a plain black box while loading (no logo
    // flash before the real image fades in).
    if (_isLoading) {
      return widget.brandFallback
          ? const SizedBox.expand()
          : _placeholder(fallbackIconColor);
    }

    if (_hasError || _imageUrl == null) {
      return widget.brandFallback
          ? _brandMark()
          : _placeholder(fallbackIconColor);
    }

    return CachedNetworkImage(
      imageUrl: _imageUrl!,
      // Dedicated cache manager isolates exercise-illustration HTTP traffic
      // from the rest of the app so a 50-row grid doesn't starve other
      // image loads (and vice versa). The CacheManager is disk-backed
      // (JsonCacheInfoRepository + HttpFileService), so downloaded bytes
      // persist across app restarts — only the URL needed a separate
      // persistent cache (see ImageUrlCache, plan A9). ✅
      cacheManager: _ExerciseImageCacheManager.instance,
      // Use exercise name as stable cache key so presigned URL rotation
      // doesn't duplicate images in disk cache.
      cacheKey: widget.exerciseName.isNotEmpty ? widget.exerciseName : null,
      fit: widget.fit,
      // Perf fix 2.2: constrain decoded image size in memory cache
      memCacheWidth: widget.width.isFinite
          ? (widget.width * 2).toInt().clamp(100, 400)
          : null,
      memCacheHeight: widget.height.isFinite
          ? (widget.height * 2).toInt().clamp(100, 400)
          : null,
      // Plan A9: gentle fade so a cold-cache load doesn't pop. A disk-cache
      // hit decodes synchronously and skips the fade entirely.
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: const Duration(milliseconds: 120),
      // Layout-matched placeholder (icon), not a spinner — no layout shift.
      placeholder: (_, __) => widget.brandFallback
          ? const SizedBox.expand()
          : _placeholder(fallbackIconColor),
      errorWidget: (_, __, ___) =>
          widget.brandFallback ? _brandMark() : _placeholder(fallbackIconColor),
    );
  }
}

/// Map an equipment hint (or exercise name keywords as fallback) to a
/// Material icon that visually matches the gear. Used as the placeholder
/// when `/exercise-images/{name}` 404s so we don't render a barbell
/// movement as a dumbbell silhouette.
IconData _fallbackIconForEquipment(String? equipmentHint, String exerciseName) {
  final hint = (equipmentHint ?? '').toLowerCase();
  final name = exerciseName.toLowerCase();
  bool h(String token) => hint.contains(token) || name.contains(token);

  if (h('barbell') || h('ez bar') || h('trap bar')) return Icons.straighten;
  if (h('cable') || h('pulley') || h('lat pull')) return Icons.linear_scale;
  if (h('kettlebell')) return Icons.sports_handball;
  if (h('band') || h('resistance')) return Icons.adjust;
  if (h('treadmill') || h('run')) return Icons.directions_run;
  if (h('bike') || h('cycle')) return Icons.directions_bike;
  if (h('row')) return Icons.rowing;
  if (h('plate')) return Icons.album;
  if (h('bodyweight') ||
      h('push-up') ||
      h('pushup') ||
      h('pull-up') ||
      h('pullup') ||
      h('squat') ||
      h('plank') ||
      h('lunge') ||
      h('burpee')) {
    return Icons.accessibility_new;
  }
  if (h('dumbbell')) return Icons.fitness_center;
  // Default — generic gym icon, never the dumbbell silhouette for
  // ambiguous cases (avoids the original "every fallback is a dumbbell"
  // problem).
  return Icons.sports_gymnastics;
}
