import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'device_capability_service.dart';

/// Status of a model download operation
enum DownloadStatus {
  /// Model has not been downloaded
  notDownloaded,

  /// Model is currently downloading
  downloading,

  /// Model has been downloaded and is ready to use
  downloaded,

  /// Download failed
  failed,
}

/// State for model download tracking
class ModelDownloadState {
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0
  final String? error;
  final int? downloadedBytes;
  final int? totalBytes;
  final GemmaModelInfo? model;

  const ModelDownloadState({
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
    this.downloadedBytes,
    this.totalBytes,
    this.model,
  });

  ModelDownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? error,
    int? downloadedBytes,
    int? totalBytes,
    GemmaModelInfo? model,
  }) {
    return ModelDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      model: model ?? this.model,
    );
  }

  /// Human-readable progress string (e.g., "150 MB / 700 MB")
  String get progressDisplay {
    if (downloadedBytes == null || totalBytes == null) return '';
    final downloadedMB = (downloadedBytes! / (1024 * 1024)).toStringAsFixed(0);
    final totalMB = (totalBytes! / (1024 * 1024)).toStringAsFixed(0);
    return '$downloadedMB MB / $totalMB MB';
  }

  /// Whether the download is in an active state
  bool get isActive => status == DownloadStatus.downloading;

  /// Whether the model is ready to use
  bool get isReady => status == DownloadStatus.downloaded;
}

/// Manages downloading, storing, and deleting Gemma model files.
///
/// Models are stored in {applicationDocumentsDirectory}/models/
class ModelDownloadService {
  static const String _modelsDirName = 'models';

  // Placeholder model download URLs - will be configured with actual hosting later
  static const Map<GemmaModelType, String> _modelUrls = {
    GemmaModelType.functionGemma270M: 'https://storage.googleapis.com/gemma-models/function_gemma_270m.bin',
    GemmaModelType.gemma3_1B: 'https://storage.googleapis.com/gemma-models/gemma3_1b.bin',
    GemmaModelType.gemma3n_E2B: 'https://storage.googleapis.com/gemma-models/gemma3n_e2b.bin',
    GemmaModelType.gemma3n_E4B: 'https://storage.googleapis.com/gemma-models/gemma3n_e4b.bin',
    GemmaModelType.embeddingGemma300M: 'https://storage.googleapis.com/gemma-models/embedding_gemma_300m.bin',
  };

  /// Get the local directory for storing model files.
  Future<Directory> _getModelsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/$_modelsDirName');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
      debugPrint('🔍 [ModelDownload] Created models directory: ${modelsDir.path}');
    }
    return modelsDir;
  }

  /// Get the local file path for a specific model.
  Future<String> _getModelFilePath(GemmaModelType model) async {
    final modelsDir = await _getModelsDir();
    final modelInfo = GemmaModelInfo.fromType(model);
    return '${modelsDir.path}/${modelInfo.fileName}';
  }

  /// Check if a model has been downloaded.
  Future<bool> isModelDownloaded(GemmaModelType model) async {
    final filePath = await _getModelFilePath(model);
    final file = File(filePath);
    final exists = await file.exists();
    debugPrint('🔍 [ModelDownload] ${model.name} downloaded: $exists');
    return exists;
  }

  /// Get the local path of a downloaded model, or null if not downloaded.
  Future<String?> getModelPath(GemmaModelType model) async {
    final filePath = await _getModelFilePath(model);
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  /// Download a Gemma model file to local storage.
  ///
  /// Progress is reported via [onProgress] callback (0.0 - 1.0).
  /// Throws on network errors or insufficient storage.
  Future<void> downloadModel(
    GemmaModelType model, {
    Function(double)? onProgress,
  }) async {
    final url = _modelUrls[model];
    if (url == null) {
      throw Exception('No download URL configured for model: ${model.name}');
    }

    final filePath = await _getModelFilePath(model);
    final modelInfo = GemmaModelInfo.fromType(model);
    debugPrint('🔍 [ModelDownload] Starting download: ${modelInfo.displayName} -> $filePath');

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Download failed with status ${response.statusCode} for ${modelInfo.displayName}',
        );
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          final progress = receivedBytes / totalBytes;
          onProgress?.call(progress);
        }
      }

      await sink.flush();
      await sink.close();

      debugPrint('✅ [ModelDownload] Download complete: ${modelInfo.displayName} ($receivedBytes bytes)');
    } catch (e) {
      // Clean up partial download on failure
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ [ModelDownload] Cleaned up partial download: $filePath');
      }
      debugPrint('❌ [ModelDownload] Download failed: $e');
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  /// Delete a downloaded model file.
  Future<void> deleteModel(GemmaModelType model) async {
    final filePath = await _getModelFilePath(model);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑️ [ModelDownload] Deleted model: ${model.name}');
    } else {
      debugPrint('⚠️ [ModelDownload] Model not found for deletion: ${model.name}');
    }
  }

  /// Get total storage used by all downloaded models in bytes.
  Future<int> getTotalModelStorageBytes() async {
    final modelsDir = await _getModelsDir();
    int totalBytes = 0;
    try {
      await for (final entity in modelsDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalBytes += stat.size;
        }
      }
    } catch (e) {
      debugPrint('❌ [ModelDownload] Error calculating storage: $e');
    }
    debugPrint('🔍 [ModelDownload] Total model storage: ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB');
    return totalBytes;
  }

  /// Get human-readable total storage used by models.
  Future<String> getFormattedStorageUsed() async {
    final totalBytes = await getTotalModelStorageBytes();
    if (totalBytes >= 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  /// Get download status for all model types.
  Future<Map<GemmaModelType, bool>> getAllModelStatuses() async {
    final statuses = <GemmaModelType, bool>{};
    for (final type in GemmaModelType.values) {
      statuses[type] = await isModelDownloaded(type);
    }
    return statuses;
  }
}
