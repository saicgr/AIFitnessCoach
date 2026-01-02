import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/video_cache_service.dart';

/// State for video cache management
class VideoCacheState {
  final int cachedVideoCount;
  final int totalCacheSizeBytes;
  final String formattedCacheSize;
  final List<CachedVideoInfo> cachedVideos;
  final Map<String, VideoDownloadProgress> downloadProgress;
  final bool isInitialized;

  const VideoCacheState({
    this.cachedVideoCount = 0,
    this.totalCacheSizeBytes = 0,
    this.formattedCacheSize = '0 B',
    this.cachedVideos = const [],
    this.downloadProgress = const {},
    this.isInitialized = false,
  });

  VideoCacheState copyWith({
    int? cachedVideoCount,
    int? totalCacheSizeBytes,
    String? formattedCacheSize,
    List<CachedVideoInfo>? cachedVideos,
    Map<String, VideoDownloadProgress>? downloadProgress,
    bool? isInitialized,
  }) {
    return VideoCacheState(
      cachedVideoCount: cachedVideoCount ?? this.cachedVideoCount,
      totalCacheSizeBytes: totalCacheSizeBytes ?? this.totalCacheSizeBytes,
      formattedCacheSize: formattedCacheSize ?? this.formattedCacheSize,
      cachedVideos: cachedVideos ?? this.cachedVideos,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Check if a video is cached
  bool isVideoCached(String exerciseId) {
    return cachedVideos.any((v) => v.exerciseId == exerciseId);
  }

  /// Get download status for an exercise
  VideoDownloadStatus getDownloadStatus(String exerciseId) {
    final progress = downloadProgress[exerciseId];
    if (progress != null) {
      return progress.status;
    }
    if (isVideoCached(exerciseId)) {
      return VideoDownloadStatus.downloaded;
    }
    return VideoDownloadStatus.notDownloaded;
  }

  /// Get download progress (0.0 to 1.0)
  double getDownloadProgress(String exerciseId) {
    return downloadProgress[exerciseId]?.progress ?? 0.0;
  }
}

/// Video cache provider
final videoCacheProvider =
    StateNotifierProvider<VideoCacheNotifier, VideoCacheState>((ref) {
  return VideoCacheNotifier();
});

/// Notifier for managing video cache state
class VideoCacheNotifier extends StateNotifier<VideoCacheState> {
  final VideoCacheService _service = videoCacheService;

  VideoCacheNotifier() : super(const VideoCacheState()) {
    _init();
  }

  /// Initialize the video cache service
  Future<void> _init() async {
    await _service.initialize();
    _refreshState();
  }

  /// Refresh state from service
  void _refreshState() {
    state = state.copyWith(
      cachedVideoCount: _service.cachedVideoCount,
      totalCacheSizeBytes: _service.totalCacheSizeBytes,
      formattedCacheSize: _service.formattedCacheSize,
      cachedVideos: _service.allCachedVideos,
      isInitialized: true,
    );
  }

  /// Download a video for offline use
  Future<String?> downloadVideo({
    required String exerciseId,
    required String exerciseName,
    required String videoUrl,
  }) async {
    // Subscribe to progress updates
    _service.getProgressStream(exerciseId).listen((progress) {
      final newProgress = Map<String, VideoDownloadProgress>.from(state.downloadProgress);
      newProgress[exerciseId] = progress;
      state = state.copyWith(downloadProgress: newProgress);

      // Refresh state when download completes
      if (progress.status == VideoDownloadStatus.downloaded ||
          progress.status == VideoDownloadStatus.error) {
        _refreshState();
      }
    });

    final result = await _service.downloadVideo(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      videoUrl: videoUrl,
    );

    return result;
  }

  /// Cancel an active download
  void cancelDownload(String exerciseId) {
    _service.cancelDownload(exerciseId);
    final newProgress = Map<String, VideoDownloadProgress>.from(state.downloadProgress);
    newProgress.remove(exerciseId);
    state = state.copyWith(downloadProgress: newProgress);
  }

  /// Delete a cached video
  Future<void> deleteVideo(String exerciseId) async {
    await _service.deleteVideo(exerciseId);
    _refreshState();
  }

  /// Clear all cached videos
  Future<void> clearAllVideos() async {
    await _service.clearAllVideos();
    state = state.copyWith(
      cachedVideoCount: 0,
      totalCacheSizeBytes: 0,
      formattedCacheSize: '0 B',
      cachedVideos: [],
      downloadProgress: {},
    );
  }

  /// Get local path for a cached video
  String? getLocalVideoPath(String exerciseId) {
    return _service.getLocalVideoPath(exerciseId);
  }

  /// Check if a video is cached
  bool isVideoCached(String exerciseId) {
    return _service.isVideoCached(exerciseId);
  }
}

/// Provider for checking if a specific exercise video is cached
final isVideoCachedProvider = Provider.family<bool, String>((ref, exerciseId) {
  final cacheState = ref.watch(videoCacheProvider);
  return cacheState.isVideoCached(exerciseId);
});

/// Provider for getting download status of a specific exercise
final videoDownloadStatusProvider =
    Provider.family<VideoDownloadStatus, String>((ref, exerciseId) {
  final cacheState = ref.watch(videoCacheProvider);
  return cacheState.getDownloadStatus(exerciseId);
});

/// Provider for getting download progress of a specific exercise
final videoDownloadProgressProvider =
    Provider.family<double, String>((ref, exerciseId) {
  final cacheState = ref.watch(videoCacheProvider);
  return cacheState.getDownloadProgress(exerciseId);
});
