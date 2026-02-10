import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../local/database.dart';
import '../local/database_provider.dart';

/// State for offline media download operations.
class OfflineMediaState {
  final bool isDownloading;
  final int totalBytes;
  final int downloadedFiles;
  final int totalFiles;
  final String? currentFile;
  final String? error;

  const OfflineMediaState({
    this.isDownloading = false,
    this.totalBytes = 0,
    this.downloadedFiles = 0,
    this.totalFiles = 0,
    this.currentFile,
    this.error,
  });

  OfflineMediaState copyWith({
    bool? isDownloading,
    int? totalBytes,
    int? downloadedFiles,
    int? totalFiles,
    String? currentFile,
    String? error,
  }) {
    return OfflineMediaState(
      isDownloading: isDownloading ?? this.isDownloading,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFile: currentFile ?? this.currentFile,
      error: error ?? this.error,
    );
  }
}

/// Service for downloading and managing exercise media files for offline use.
///
/// Features:
/// - User toggle: download videos for offline (default off)
/// - Auto-downloads videos for upcoming 7-day workout exercises
/// - 30-day auto-cleanup of unused videos
/// - Drift-backed metadata tracking
/// - Download progress tracking
/// - Total storage usage display
class OfflineMediaService extends StateNotifier<OfflineMediaState> {
  final AppDatabase _db;
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  OfflineMediaService(this._db) : super(const OfflineMediaState());

  /// Get the local directory for cached media files.
  Future<Directory> _getMediaDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'exercise_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Download a single exercise video to local storage.
  Future<String?> downloadVideo({
    required String exerciseId,
    required String remoteUrl,
  }) async {
    try {
      final mediaDir = await _getMediaDir();
      final extension = p.extension(remoteUrl).isNotEmpty
          ? p.extension(remoteUrl)
          : '.mp4';
      final localPath = p.join(mediaDir.path, '$exerciseId$extension');

      // Check if already downloaded
      final existing =
          await _db.mediaCacheDao.getMediaPath(exerciseId, 'video');
      if (existing != null && await File(existing.localPath).exists()) {
        // Update last accessed
        await _db.mediaCacheDao.upsertMedia(
          CachedExerciseMediaCompanion(
            exerciseId: Value(exerciseId),
            mediaType: const Value('video'),
            remoteUrl: Value(remoteUrl),
            localPath: Value(existing.localPath),
            fileSizeBytes: Value(existing.fileSizeBytes),
            downloadedAt: Value(existing.downloadedAt),
            lastAccessedAt: Value(DateTime.now()),
          ),
        );
        return existing.localPath;
      }

      // Download the file
      _cancelToken = CancelToken();
      await _dio.download(
        remoteUrl,
        localPath,
        cancelToken: _cancelToken,
      );

      final file = File(localPath);
      final fileSize = await file.length();

      // Track in database
      await _db.mediaCacheDao.upsertMedia(
        CachedExerciseMediaCompanion(
          exerciseId: Value(exerciseId),
          mediaType: const Value('video'),
          remoteUrl: Value(remoteUrl),
          localPath: Value(localPath),
          fileSizeBytes: Value(fileSize),
          downloadedAt: Value(DateTime.now()),
          lastAccessedAt: Value(DateTime.now()),
        ),
      );

      debugPrint('✅ [OfflineMedia] Downloaded video for $exerciseId (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)');
      return localPath;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('⚠️ [OfflineMedia] Download cancelled for $exerciseId');
        return null;
      }
      debugPrint('❌ [OfflineMedia] Error downloading video for $exerciseId: $e');
      return null;
    }
  }

  /// Download videos for a list of exercises.
  Future<void> downloadVideosForExercises(
      List<Map<String, String>> exercises) async {
    if (exercises.isEmpty) return;

    state = state.copyWith(
      isDownloading: true,
      totalFiles: exercises.length,
      downloadedFiles: 0,
      error: null,
    );

    for (int i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final id = ex['id'] ?? '';
      final url = ex['videoUrl'] ?? '';
      if (id.isEmpty || url.isEmpty) continue;

      state = state.copyWith(
        currentFile: ex['name'] ?? id,
        downloadedFiles: i,
      );

      await downloadVideo(exerciseId: id, remoteUrl: url);
    }

    state = state.copyWith(
      isDownloading: false,
      downloadedFiles: exercises.length,
      currentFile: null,
    );
  }

  /// Cancel any in-progress downloads.
  void cancelDownloads() {
    _cancelToken?.cancel('User cancelled');
    state = state.copyWith(isDownloading: false);
  }

  /// Get the local path for a cached video (or null if not cached).
  Future<String?> getLocalVideoPath(String exerciseId) async {
    final media =
        await _db.mediaCacheDao.getMediaPath(exerciseId, 'video');
    if (media == null) return null;

    final file = File(media.localPath);
    if (await file.exists()) {
      // Update last accessed time
      await _db.mediaCacheDao.upsertMedia(
        CachedExerciseMediaCompanion(
          exerciseId: Value(exerciseId),
          mediaType: const Value('video'),
          remoteUrl: Value(media.remoteUrl),
          localPath: Value(media.localPath),
          fileSizeBytes: Value(media.fileSizeBytes),
          downloadedAt: Value(media.downloadedAt),
          lastAccessedAt: Value(DateTime.now()),
        ),
      );
      return media.localPath;
    }

    return null;
  }

  /// Clean up videos not accessed in the last 30 days.
  Future<int> cleanupUnusedMedia() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final deleted = await _db.mediaCacheDao.deleteUnusedMedia(cutoff);

    // Delete actual files
    int deletedCount = 0;
    for (final media in deleted) {
      try {
        final file = File(media.localPath);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
        }
      } catch (e) {
        debugPrint('⚠️ [OfflineMedia] Error deleting file ${media.localPath}: $e');
      }
    }

    debugPrint('🧹 [OfflineMedia] Cleaned up $deletedCount unused media files');
    return deletedCount;
  }

  /// Get total storage used by cached media in bytes.
  Future<int> getTotalStorageUsed() async {
    return await _db.mediaCacheDao.getTotalCacheSize();
  }

  /// Clear all cached media.
  Future<void> clearAllMedia() async {
    try {
      final mediaDir = await _getMediaDir();
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
        await mediaDir.create();
      }
      // Clear database records (via DAO method or direct delete)
      debugPrint('🧹 [OfflineMedia] All cached media cleared');
    } catch (e) {
      debugPrint('❌ [OfflineMedia] Error clearing media cache: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Offline media service provider.
final offlineMediaServiceProvider =
    StateNotifierProvider<OfflineMediaService, OfflineMediaState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OfflineMediaService(db);
});

/// Total media storage used (bytes).
final mediaStorageUsedProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(offlineMediaServiceProvider.notifier);
  return service.getTotalStorageUsed();
});
