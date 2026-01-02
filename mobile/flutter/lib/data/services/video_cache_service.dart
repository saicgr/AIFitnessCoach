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
        fileSizeBytes: json['fileSizeBytes'] as int,
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

  /// Download a video for offline use
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
      debugPrint('📹 $exerciseName already cached');
      return getLocalVideoPath(exerciseId);
    }

    // Check cache size and clean up if needed
    await _ensureCacheSpace();

    final cancelToken = CancelToken();
    _activeDownloads[exerciseId] = cancelToken;

    // Initialize progress stream
    _progressControllers[exerciseId] ??= StreamController<VideoDownloadProgress>.broadcast();
    _progressControllers[exerciseId]!.add(VideoDownloadProgress(
      exerciseId: exerciseId,
      progress: 0,
      downloadedBytes: 0,
      totalBytes: 0,
      status: VideoDownloadStatus.downloading,
    ));

    try {
      final cacheDir = await _getCacheDirectory();
      final sanitizedName = exerciseName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final localPath = '${cacheDir.path}/${exerciseId}_$sanitizedName.mp4';

      debugPrint('📹 Downloading $exerciseName to $localPath');

      await _dio.download(
        videoUrl,
        localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _progressControllers[exerciseId]?.add(VideoDownloadProgress(
              exerciseId: exerciseId,
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
              status: VideoDownloadStatus.downloading,
            ));
          }
        },
      );

      // Get file size
      final file = File(localPath);
      final fileSize = await file.length();

      // Save to cache
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
      _progressControllers[exerciseId]?.add(VideoDownloadProgress(
        exerciseId: exerciseId,
        progress: 1.0,
        downloadedBytes: fileSize,
        totalBytes: fileSize,
        status: VideoDownloadStatus.downloaded,
      ));

      debugPrint('📹 Downloaded $exerciseName (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)');
      return localPath;
    } catch (e) {
      _activeDownloads.remove(exerciseId);
      _progressControllers[exerciseId]?.add(VideoDownloadProgress(
        exerciseId: exerciseId,
        progress: 0,
        downloadedBytes: 0,
        totalBytes: 0,
        status: VideoDownloadStatus.error,
        error: e.toString(),
      ));
      debugPrint('📹 Error downloading $exerciseName: $e');
      return null;
    }
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
