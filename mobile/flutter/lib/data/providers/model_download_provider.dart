import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/device_capability_service.dart';
import '../../services/model_download_service.dart';

/// State notifier for managing model download lifecycle.
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  final Ref _ref;
  final ModelDownloadService _downloadService = ModelDownloadService();

  ModelDownloadNotifier(this._ref) : super(const ModelDownloadState()) {
    _checkInitialState();
  }

  /// Check if any models are already downloaded on startup.
  Future<void> _checkInitialState() async {
    try {
      for (final type in GemmaModelType.values) {
        if (type == GemmaModelType.embeddingGemma300M) continue; // Skip embedding model
        final isDownloaded = await _downloadService.isModelDownloaded(type);
        if (isDownloaded) {
          final info = GemmaModelInfo.fromType(type);
          state = state.copyWith(
            status: DownloadStatus.downloaded,
            model: info,
            progress: 1.0,
          );
          debugPrint('✅ [ModelDownloadProvider] Found downloaded model: ${info.displayName}');
          return;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ModelDownloadProvider] Error checking initial state: $e');
    }
  }

  /// Select a model type (without downloading).
  void selectModel(GemmaModelType type) {
    final modelInfo = GemmaModelInfo.fromType(type);
    state = ModelDownloadState(
      status: DownloadStatus.notDownloaded,
      model: modelInfo,
    );
  }

  /// Start downloading the currently selected model.
  Future<void> startDownload() async {
    if (state.model == null) return;
    await downloadModel(state.model!.type);
  }

  /// Cancel an in-progress download.
  void cancelDownload() {
    state = ModelDownloadState(
      status: DownloadStatus.notDownloaded,
      model: state.model,
    );
  }

  /// Start downloading a model.
  Future<void> downloadModel(GemmaModelType modelType) async {
    final modelInfo = GemmaModelInfo.fromType(modelType);

    state = ModelDownloadState(
      status: DownloadStatus.downloading,
      progress: 0.0,
      model: modelInfo,
      totalBytes: modelInfo.sizeBytes,
      downloadedBytes: 0,
    );

    debugPrint('🔍 [ModelDownloadProvider] Starting download: ${modelInfo.displayName}');

    try {
      await _downloadService.downloadModel(
        modelType,
        onProgress: (progress) {
          if (mounted) {
            state = state.copyWith(
              progress: progress,
              downloadedBytes: (progress * modelInfo.sizeBytes).round(),
            );
          }
        },
      );

      if (mounted) {
        state = state.copyWith(
          status: DownloadStatus.downloaded,
          progress: 1.0,
          downloadedBytes: modelInfo.sizeBytes,
        );
        debugPrint('✅ [ModelDownloadProvider] Download complete: ${modelInfo.displayName}');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          status: DownloadStatus.failed,
          error: e.toString(),
        );
        debugPrint('❌ [ModelDownloadProvider] Download failed: $e');
      }
    }
  }

  /// Delete the currently selected/downloaded model, or a specific model by type.
  Future<void> deleteModel([GemmaModelType? modelType]) async {
    final type = modelType ?? state.model?.type;
    if (type == null) return;
    try {
      await _downloadService.deleteModel(type);
      state = const ModelDownloadState(
        status: DownloadStatus.notDownloaded,
        progress: 0.0,
      );
      debugPrint('✅ [ModelDownloadProvider] Model deleted: ${type.name}');
    } catch (e) {
      debugPrint('❌ [ModelDownloadProvider] Error deleting model: $e');
    }
  }

  /// Check if a specific model is downloaded.
  Future<bool> isModelDownloaded(GemmaModelType modelType) async {
    return _downloadService.isModelDownloaded(modelType);
  }

  /// Get the local path for a downloaded model.
  Future<String?> getModelPath(GemmaModelType modelType) async {
    return _downloadService.getModelPath(modelType);
  }

  /// Refresh download state for a model type.
  Future<void> refreshState(GemmaModelType modelType) async {
    final isDownloaded = await _downloadService.isModelDownloaded(modelType);
    final modelInfo = GemmaModelInfo.fromType(modelType);

    if (isDownloaded) {
      state = ModelDownloadState(
        status: DownloadStatus.downloaded,
        progress: 1.0,
        model: modelInfo,
        totalBytes: modelInfo.sizeBytes,
        downloadedBytes: modelInfo.sizeBytes,
      );
    } else {
      state = ModelDownloadState(
        status: DownloadStatus.notDownloaded,
        model: modelInfo,
      );
    }
  }
}

/// Provider for model download state and operations.
final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>((ref) {
  return ModelDownloadNotifier(ref);
});

/// Provider for total model storage used (in bytes).
final modelStorageProvider = FutureProvider<int>((ref) async {
  final service = ModelDownloadService();
  return service.getTotalModelStorageBytes();
});
