import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Status of a video download
enum VideoDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

/// Information about a cached video
class CachedVideoInfo {
  final String exerciseName;
  final String exerciseId;
  final String localPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String? sourceUrl;

  CachedVideoInfo({
    required this.exerciseName,
    required this.exerciseId,
    required this.localPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    this.sourceUrl,
  });

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'exerciseId': exerciseId,
        'localPath': localPath,
        'fileSizeBytes': fileSizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
        'sourceUrl': sourceUrl,
      };

  factory CachedVideoInfo.fromJson(Map<String, dynamic> json) => CachedVideoInfo(
        exerciseName: json['exerciseName'] as String,
        exerciseId: json['exerciseId'] as String,
        localPath: json['localPath'] as String,
        fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
        sourceUrl: json['sourceUrl'] as String?,
      );
}

/// Download progress info
class VideoDownloadProgress {
  final String exerciseId;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final VideoDownloadStatus status;
  final String? error;

  VideoDownloadProgress({
    required this.exerciseId,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.status,
    this.error,
  });

  factory VideoDownloadProgress.initial(String exerciseId) => VideoDownloadProgress(
        exerciseId: exerciseId,
        progress: 0,
        downloadedBytes: 0,
        totalBytes: 0,
        status: VideoDownloadStatus.notDownloaded,
      );

  VideoDownloadProgress copyWith({
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    VideoDownloadStatus? status,
    String? error,
  }) =>
      VideoDownloadProgress(
        exerciseId: exerciseId,
        progress: progress ?? this.progress,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        status: status ?? this.status,
        error: error ?? this.error,
      );
}

/// Service for downloading and caching exercise videos for offline use
class VideoCacheService {
  static const String _cacheMetadataKey = 'video_cache_metadata';
  static const String _videoSubdir = 'exercise_videos';

  // Maximum cache size (500 MB)
  static const int _maxCacheSizeBytes = 500 * 1024 * 1024;

  final Dio _dio = Dio();

  // In-memory cache of downloaded videos
  Map<String, CachedVideoInfo> _cachedVideos = {};

  // Active download controllers
  final Map<String, CancelToken> _activeDownloads = {};

  // Download progress streams
  final Map<String, StreamController<VideoDownloadProgress>> _progressControllers = {};

  // ── Concurrency limiter (semaphore pattern) ──────────────────────────────
  // Cap concurrent downloads to keep the network usable for foreground
  // requests (chat, food search, etc.). Three is a sensible balance for
  // mobile bandwidth without serializing a 30-exercise weekly batch. ✅
  static const int _maxConcurrentDownloads = 3;
  int _inFlightDownloads = 0;
  final List<Completer<void>> _downloadQueue = [];

  // Throttle progress emissions per-download — 60fps progress updates
  // on a 50MB video would repaint the UI thousands of times per download.
  // 250ms cadence is smooth visually and ~25x cheaper. ⚠️
  static const Duration _progressEmitInterval = Duration(milliseconds: 250);
  final Map<String, DateTime> _lastEmitAt = {};

  Future<void> _acquireDownloadSlot() async {
    if (_inFlightDownloads < _maxConcurrentDownloads) {
      _inFlightDownloads++;
      return;
    }
    final completer = Completer<void>();
    _downloadQueue.add(completer);
    await completer.future;
    _inFlightDownloads++;
  }

  void _releaseDownloadSlot() {
    _inFlightDownloads--;
    if (_inFlightDownloads < 0) _inFlightDownloads = 0;
    if (_downloadQueue.isNotEmpty) {
      final next = _downloadQueue.removeAt(0);
      if (!next.isCompleted) next.complete();
    }
  }

  /// Emit a progress update — throttled to one emission per
  /// [_progressEmitInterval] per [exerciseId]. Terminal states
  /// ([VideoDownloadStatus.downloaded] / [VideoDownloadStatus.error])
  /// always emit immediately so consumers never miss completion.
  void _emitProgress(String exerciseId, VideoDownloadProgress progress) {
    final isTerminal = progress.status == VideoDownloadStatus.downloaded ||
        progress.status == VideoDownloadStatus.error;
    final now = DateTime.now();
    final last = _lastEmitAt[exerciseId];
    if (!isTerminal && last != null && now.difference(last) < _progressEmitInterval) {
      return;
    }
    _lastEmitAt[exerciseId] = now;
    _lastProgressByExercise[exerciseId] = progress;
    _progressControllers[exerciseId]?.add(progress);
  }

  // Singleton
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  /// Initialize the cache service
  Future<void> initialize() async {
    await _loadMetadata();
    await _cleanupOrphanedFiles();
  }

  /// Load cached video metadata from SharedPreferences
  Future<void> _loadMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey);
      if (metadataJson != null) {
        final Map<String, dynamic> data = json.decode(metadataJson);
        _cachedVideos = data.map(
          (key, value) => MapEntry(key, CachedVideoInfo.fromJson(value as Map<String, dynamic>)),
        );
        debugPrint('📹 Loaded ${_cachedVideos.length} cached videos from metadata');
      }
    } catch (e) {
      debugPrint('📹 Error loading video cache metadata: $e');
      _cachedVideos = {};
    }
  }

  /// Save metadata to SharedPreferences
  Future<void> _saveMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _cachedVideos.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_cacheMetadataKey, json.encode(data));
    } catch (e) {
      debugPrint('📹 Error saving video cache metadata: $e');
    }
  }

  /// Clean up any files that exist but aren't in metadata
  Future<void> _cleanupOrphanedFiles() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return;

      final validPaths = _cachedVideos.values.map((v) => v.localPath).toSet();

      await for (final entity in cacheDir.list()) {
        if (entity is File && !validPaths.contains(entity.path)) {
          await entity.delete();
          debugPrint('📹 Cleaned up orphaned video: ${entity.path}');
        }
      }
    } catch (e) {
      debugPrint('📹 Error cleaning up orphaned files: $e');
    }
  }

  /// Get the cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_videoSubdir');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Check if a video is cached
  bool isVideoCached(String exerciseId) {
    final cached = _cachedVideos[exerciseId];
    if (cached == null) return false;

    // Verify file exists
    final file = File(cached.localPath);
    return file.existsSync();
  }

  /// Get download status for an exercise
  VideoDownloadStatus getDownloadStatus(String exerciseId) {
    if (_activeDownloads.containsKey(exerciseId)) {
      return VideoDownloadStatus.downloading;
    }
    if (isVideoCached(exerciseId)) {
      return VideoDownloadStatus.downloaded;
    }
    return VideoDownloadStatus.notDownloaded;
  }

  /// Get cached video info
  CachedVideoInfo? getCachedVideoInfo(String exerciseId) {
    return _cachedVideos[exerciseId];
  }

  /// Get local path for cached video (returns null if not cached)
  String? getLocalVideoPath(String exerciseId) {
    final cached = _cachedVideos[exerciseId];
    if (cached == null) return null;

    final file = File(cached.localPath);
    if (!file.existsSync()) {
      // File was deleted, remove from cache
      _cachedVideos.remove(exerciseId);
      _saveMetadata();
      return null;
    }

    return cached.localPath;
  }

  /// Get a stream of download progress for an exercise
  Stream<VideoDownloadProgress> getProgressStream(String exerciseId) {
    _progressControllers[exerciseId] ??= StreamController<VideoDownloadProgress>.broadcast();
    return _progressControllers[exerciseId]!.stream;
  }

  /// Last-known progress snapshot for an exercise. Used by UIs that mount
  /// AFTER a download has already started (e.g. opening the exercise sheet
  /// while a "Download this week's videos" batch is mid-flight) — the
  /// broadcast stream above doesn't replay, so we mirror the latest emit
  /// here. Returns null if no download has been observed for this exercise.
  VideoDownloadProgress? _lastProgress(String exerciseId) =>
      _lastProgressByExercise[exerciseId];
  VideoDownloadProgress? getProgress(String exerciseId) => _lastProgress(exerciseId);

  final Map<String, VideoDownloadProgress> _lastProgressByExercise = {};

  /// Download a video for offline use.
  ///
  /// Reliability:
  /// - Concurrency capped via [_acquireDownloadSlot] semaphore.
  /// - Up to 3 attempts with exponential backoff (1s / 3s / 9s) on transient
  ///   network failures; user-cancellation is NOT retried.
  /// - Progress emissions throttled to 250ms cadence.
  Future<String?> downloadVideo({
    required String exerciseId,
    required String exerciseName,
    required String videoUrl,
  }) async {
    // Already downloading?
    if (_activeDownloads.containsKey(exerciseId)) {
      debugPrint('📹 Already downloading $exerciseName');
      return null;
    }

    // Already cached?
    if (isVideoCached(exerciseId)) {
      debugPrint('✅ $exerciseName already cached');
      return getLocalVideoPath(exerciseId);
    }

    // Wait for a slot in the concurrency limiter before starting any work.
    await _acquireDownloadSlot();

    // Re-check cache after acquiring the slot — earlier-queued duplicate
    // downloads may have completed while we were waiting. ⚠️
    if (isVideoCached(exerciseId)) {
      _releaseDownloadSlot();
      return getLocalVideoPath(exerciseId);
    }

    await _ensureCacheSpace();

    final cancelToken = CancelToken();
    _activeDownloads[exerciseId] = cancelToken;

    _progressControllers[exerciseId] ??= StreamController<VideoDownloadProgress>.broadcast();
    _emitProgress(exerciseId, VideoDownloadProgress(
      exerciseId: exerciseId,
      progress: 0,
      downloadedBytes: 0,
      totalBytes: 0,
      status: VideoDownloadStatus.downloading,
    ));

    final cacheDir = await _getCacheDirectory();
    final sanitizedName = exerciseName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final localPath = '${cacheDir.path}/${exerciseId}_$sanitizedName.mp4';

    // Exponential backoff: 1s, 3s, 9s
    const backoffs = [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 9),
    ];
    const maxAttempts = 3;

    Object? lastError;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // User-cancelled? Bail out without retry.
      if (cancelToken.isCancelled) break;
      try {
        debugPrint('📹 Downloading $exerciseName (attempt ${attempt + 1}/$maxAttempts)');
        await _dio.download(
          videoUrl,
          localPath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              _emitProgress(exerciseId, VideoDownloadProgress(
                exerciseId: exerciseId,
                progress: progress,
                downloadedBytes: received,
                totalBytes: total,
                status: VideoDownloadStatus.downloading,
              ));
            }
          },
        );

        // Success — record metadata and exit retry loop.
        final file = File(localPath);
        final fileSize = await file.length();

        final cachedInfo = CachedVideoInfo(
          exerciseName: exerciseName,
          exerciseId: exerciseId,
          localPath: localPath,
          fileSizeBytes: fileSize,
          downloadedAt: DateTime.now(),
          sourceUrl: videoUrl,
        );

        _cachedVideos[exerciseId] = cachedInfo;
        await _saveMetadata();

        _activeDownloads.remove(exerciseId);
        _emitProgress(exerciseId, VideoDownloadProgress(
          exerciseId: exerciseId,
          progress: 1.0,
          downloadedBytes: fileSize,
          totalBytes: fileSize,
          status: VideoDownloadStatus.downloaded,
        ));
        _releaseDownloadSlot();
        debugPrint('✅ Downloaded $exerciseName (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)');
        return localPath;
      } catch (e) {
        lastError = e;
        // Don't retry user-cancellations
        if (e is DioException && CancelToken.isCancel(e)) {
          break;
        }
        debugPrint('⚠️ Download attempt ${attempt + 1} failed for $exerciseName: $e');
        // Wait before next attempt unless this was the last one
        if (attempt < maxAttempts - 1) {
          try {
            await Future.delayed(backoffs[attempt]);
          } catch (_) {}
        }
      }
    }

    // All retries exhausted (or user cancelled). Report error.
    _activeDownloads.remove(exerciseId);
    // Best-effort cleanup of partial file so it doesn't masquerade as cached
    try {
      final partial = File(localPath);
      if (await partial.exists()) await partial.delete();
    } catch (_) {}

    _emitProgress(exerciseId, VideoDownloadProgress(
      exerciseId: exerciseId,
      progress: 0,
      downloadedBytes: 0,
      totalBytes: 0,
      status: VideoDownloadStatus.error,
      error: lastError?.toString() ?? 'Download failed',
    ));
    _releaseDownloadSlot();
    debugPrint('❌ Failed to download $exerciseName after $maxAttempts attempts: $lastError');
    return null;
  }

  /// Queue a batch of videos for download (e.g. "Download all videos for
  /// this week's plan"). Each entry is `{exerciseId, exerciseName, videoUrl}`.
  /// Honours the same concurrency cap as single downloads — entries are
  /// awaited sequentially from the caller's perspective but execute in
  /// parallel up to [_maxConcurrentDownloads].
  Future<void> queueDownloads(List<Map<String, String>> items) async {
    if (items.isEmpty) return;
    debugPrint('📹 Queuing ${items.length} videos for download');
    // Fire-and-forget each download — the semaphore inside [downloadVideo]
    // serializes execution. Wait for all to complete (success or error)
    // so callers can show a "completed" toast. ✅
    await Future.wait(items.map((item) async {
      final id = item['exerciseId'];
      final name = item['exerciseName'];
      final url = item['videoUrl'];
      if (id == null || name == null || url == null) return;
      try {
        await downloadVideo(
          exerciseId: id,
          exerciseName: name,
          videoUrl: url,
        );
      } catch (e) {
        debugPrint('⚠️ Batch download item failed: $e');
      }
    }));
  }

  /// Cancel an active download
  void cancelDownload(String exerciseId) {
    final cancelToken = _activeDownloads[exerciseId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled download');
      _activeDownloads.remove(exerciseId);
      _progressControllers[exerciseId]?.add(VideoDownloadProgress(
        exerciseId: exerciseId,
        progress: 0,
        downloadedBytes: 0,
        totalBytes: 0,
        status: VideoDownloadStatus.notDownloaded,
      ));
      // Perf fix 2.6: close StreamController immediately on cancel to prevent leak
      _progressControllers[exerciseId]?.close();
      _progressControllers.remove(exerciseId);
      _lastEmitAt.remove(exerciseId);
    }
  }

  /// Delete a cached video
  Future<void> deleteVideo(String exerciseId) async {
    final cached = _cachedVideos[exerciseId];
    if (cached == null) return;

    try {
      final file = File(cached.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('📹 Error deleting video file: $e');
    }

    _cachedVideos.remove(exerciseId);
    await _saveMetadata();

    _progressControllers[exerciseId]?.add(VideoDownloadProgress.initial(exerciseId));
    debugPrint('📹 Deleted cached video: ${cached.exerciseName}');
  }

  /// Clear all cached videos
  Future<void> clearAllVideos() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
    } catch (e) {
      debugPrint('📹 Error clearing video cache: $e');
    }

    _cachedVideos.clear();
    await _saveMetadata();

    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();

    debugPrint('📹 Cleared all cached videos');
  }

  /// Get total cache size in bytes
  int get totalCacheSizeBytes {
    return _cachedVideos.values.fold(0, (sum, v) => sum + v.fileSizeBytes);
  }

  /// Get formatted cache size string
  String get formattedCacheSize {
    final bytes = totalCacheSizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Get number of cached videos
  int get cachedVideoCount => _cachedVideos.length;

  /// Get all cached videos
  List<CachedVideoInfo> get allCachedVideos => _cachedVideos.values.toList();

  /// Ensure we have space for new downloads (LRU eviction)
  Future<void> _ensureCacheSpace() async {
    while (totalCacheSizeBytes > _maxCacheSizeBytes && _cachedVideos.isNotEmpty) {
      // Find oldest cached video
      CachedVideoInfo? oldest;
      for (final video in _cachedVideos.values) {
        if (oldest == null || video.downloadedAt.isBefore(oldest.downloadedAt)) {
          oldest = video;
        }
      }

      if (oldest != null) {
        debugPrint('📹 Evicting oldest video: ${oldest.exerciseName}');
        await deleteVideo(oldest.exerciseId);
      } else {
        break;
      }
    }
  }

  /// Dispose resources
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}

/// Global instance
final videoCacheService = VideoCacheService();
