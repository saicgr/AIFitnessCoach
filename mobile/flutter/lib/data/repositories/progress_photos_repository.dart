import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_photos.dart';
import '../services/api_client.dart';

/// Progress photos repository provider
final progressPhotosRepositoryProvider = Provider<ProgressPhotosRepository>((ref) {
  return ProgressPhotosRepository(ref.watch(apiClientProvider));
});

/// Progress photos repository for all photo-related API calls
class ProgressPhotosRepository {
  final ApiClient _client;

  ProgressPhotosRepository(this._client);

  // ============================================
  // Photo Upload & Management
  // ============================================

  /// Upload a new progress photo
  Future<ProgressPhoto> uploadPhoto({
    required String userId,
    required File imageFile,
    required PhotoViewType viewType,
    DateTime? takenAt,
    double? bodyWeightKg,
    String? notes,
    String? measurementId,
    PhotoVisibility visibility = PhotoVisibility.private,
  }) async {
    try {
      debugPrint('📸 [ProgressPhotos] Uploading ${viewType.displayName} photo for $userId');

      final formData = FormData.fromMap({
        'user_id': userId,
        'view_type': viewType.value,
        'visibility': visibility.value,
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: '${viewType.value}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        if (takenAt != null) 'taken_at': takenAt.toIso8601String(),
        if (bodyWeightKg != null) 'body_weight_kg': bodyWeightKg.toString(),
        if (notes != null) 'notes': notes,
        if (measurementId != null) 'measurement_id': measurementId,
      });

      final response = await _client.post(
        '/progress-photos/photos',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      debugPrint('✅ [ProgressPhotos] Photo uploaded successfully');
      return ProgressPhoto.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error uploading photo: $e');
      rethrow;
    }
  }

  /// Get all progress photos for a user
  Future<List<ProgressPhoto>> getPhotos({
    required String userId,
    PhotoViewType? viewType,
    int limit = 50,
    int offset = 0,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      debugPrint('🔍 [ProgressPhotos] Fetching photos for $userId');

      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (viewType != null) {
        queryParams['view_type'] = viewType.value;
      }
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
      }

      final response = await _client.get(
        '/progress-photos/photos/$userId',
        queryParameters: queryParams,
      );

      final photos = (response.data as List)
          .map((json) => ProgressPhoto.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [ProgressPhotos] Fetched ${photos.length} photos');
      return photos;
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error fetching photos: $e');
      rethrow;
    }
  }

  /// Get latest photos by view type
  Future<LatestPhotosByView> getLatestPhotosByView(String userId) async {
    try {
      debugPrint('🔍 [ProgressPhotos] Fetching latest photos by view for $userId');

      final response = await _client.get(
        '/progress-photos/photos/$userId/latest',
      );

      debugPrint('✅ [ProgressPhotos] Fetched latest photos by view');
      return LatestPhotosByView.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error fetching latest photos: $e');
      rethrow;
    }
  }

  /// Get a specific photo
  Future<ProgressPhoto> getPhoto({
    required String userId,
    required String photoId,
  }) async {
    try {
      debugPrint('🔍 [ProgressPhotos] Fetching photo $photoId');

      final response = await _client.get(
        '/progress-photos/photos/$userId/$photoId',
      );

      debugPrint('✅ [ProgressPhotos] Fetched photo');
      return ProgressPhoto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error fetching photo: $e');
      rethrow;
    }
  }

  /// Update a photo's metadata
  Future<ProgressPhoto> updatePhoto({
    required String photoId,
    required String userId,
    String? notes,
    double? bodyWeightKg,
    bool? isComparisonReady,
    PhotoVisibility? visibility,
  }) async {
    try {
      debugPrint('📝 [ProgressPhotos] Updating photo $photoId');

      final updateData = <String, dynamic>{};
      if (notes != null) updateData['notes'] = notes;
      if (bodyWeightKg != null) updateData['body_weight_kg'] = bodyWeightKg;
      if (isComparisonReady != null) updateData['is_comparison_ready'] = isComparisonReady;
      if (visibility != null) updateData['visibility'] = visibility.value;

      final response = await _client.put(
        '/progress-photos/photos/$photoId',
        queryParameters: {'user_id': userId},
        data: updateData,
      );

      debugPrint('✅ [ProgressPhotos] Photo updated');
      return ProgressPhoto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error updating photo: $e');
      rethrow;
    }
  }

  /// Delete a photo
  Future<void> deletePhoto({
    required String photoId,
    required String userId,
  }) async {
    try {
      debugPrint('🗑️ [ProgressPhotos] Deleting photo $photoId');

      await _client.delete(
        '/progress-photos/photos/$photoId',
        queryParameters: {'user_id': userId},
      );

      debugPrint('✅ [ProgressPhotos] Photo deleted');
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error deleting photo: $e');
      rethrow;
    }
  }

  // ============================================
  // Photo Comparisons
  // ============================================

  /// Create a before/after comparison
  Future<PhotoComparison> createComparison({
    required String userId,
    required String beforePhotoId,
    required String afterPhotoId,
    String? title,
    String? description,
  }) async {
    try {
      debugPrint('📊 [ProgressPhotos] Creating comparison for $userId');

      final response = await _client.post(
        '/progress-photos/comparisons',
        data: {
          'user_id': userId,
          'before_photo_id': beforePhotoId,
          'after_photo_id': afterPhotoId,
          if (title != null) 'title': title,
          if (description != null) 'description': description,
        },
      );

      debugPrint('✅ [ProgressPhotos] Comparison created');
      return PhotoComparison.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error creating comparison: $e');
      rethrow;
    }
  }

  /// Get all comparisons for a user
  Future<List<PhotoComparison>> getComparisons({
    required String userId,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 [ProgressPhotos] Fetching comparisons for $userId');

      final response = await _client.get(
        '/progress-photos/comparisons/$userId',
        queryParameters: {'limit': limit},
      );

      final comparisons = (response.data as List)
          .map((json) => PhotoComparison.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [ProgressPhotos] Fetched ${comparisons.length} comparisons');
      return comparisons;
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error fetching comparisons: $e');
      rethrow;
    }
  }

  /// Update a comparison's settings, layout, AI summary, etc.
  Future<PhotoComparison> updateComparison({
    required String comparisonId,
    required String userId,
    String? title,
    String? description,
    String? layout,
    Map<String, dynamic>? settingsJson,
    String? aiSummary,
    String? exportedImageUrl,
    List<Map<String, dynamic>>? photosJson,
  }) async {
    try {
      debugPrint('📝 [ProgressPhotos] Updating comparison $comparisonId');

      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (layout != null) data['layout'] = layout;
      if (settingsJson != null) data['settings_json'] = settingsJson;
      if (aiSummary != null) data['ai_summary'] = aiSummary;
      if (exportedImageUrl != null) data['exported_image_url'] = exportedImageUrl;
      if (photosJson != null) data['photos_json'] = photosJson;

      final response = await _client.put(
        '/progress-photos/comparisons/$comparisonId',
        queryParameters: {'user_id': userId},
        data: data,
      );

      debugPrint('✅ [ProgressPhotos] Comparison updated');
      return PhotoComparison.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error updating comparison: $e');
      rethrow;
    }
  }

  /// Get AI-generated progress summary for two photos
  Future<String> getAiSummary({
    required String beforePhotoUrl,
    required String afterPhotoUrl,
    required int daysBetween,
    double? weightChangeKg,
  }) async {
    try {
      debugPrint('🤖 [ProgressPhotos] Requesting AI summary');

      final response = await _client.post(
        '/progress-photos/ai-summary',
        data: {
          'before_photo_url': beforePhotoUrl,
          'after_photo_url': afterPhotoUrl,
          'days_between': daysBetween,
          if (weightChangeKg != null) 'weight_change_kg': weightChangeKg,
        },
      );

      final summary = (response.data as Map<String, dynamic>)['summary'] as String;
      debugPrint('✅ [ProgressPhotos] AI summary received');
      return summary;
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error getting AI summary: $e');
      rethrow;
    }
  }

  /// Delete a comparison (does not delete the photos)
  Future<void> deleteComparison({
    required String comparisonId,
    required String userId,
  }) async {
    try {
      debugPrint('🗑️ [ProgressPhotos] Deleting comparison $comparisonId');

      await _client.delete(
        '/progress-photos/comparisons/$comparisonId',
        queryParameters: {'user_id': userId},
      );

      debugPrint('✅ [ProgressPhotos] Comparison deleted');
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error deleting comparison: $e');
      rethrow;
    }
  }

  // ============================================
  // Statistics
  // ============================================

  /// Get photo statistics for a user
  Future<PhotoStats> getStats(String userId) async {
    try {
      debugPrint('📊 [ProgressPhotos] Fetching stats for $userId');

      final response = await _client.get(
        '/progress-photos/stats/$userId',
      );

      debugPrint('✅ [ProgressPhotos] Fetched stats');
      return PhotoStats.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [ProgressPhotos] Error fetching stats: $e');
      rethrow;
    }
  }
}

// ============================================
// Riverpod State Management
// ============================================

/// State for progress photos
class ProgressPhotosState {
  final List<ProgressPhoto> photos;
  final LatestPhotosByView? latestByView;
  final List<PhotoComparison> comparisons;
  final PhotoStats? stats;
  final bool isLoading;
  final String? error;

  const ProgressPhotosState({
    this.photos = const [],
    this.latestByView,
    this.comparisons = const [],
    this.stats,
    this.isLoading = false,
    this.error,
  });

  ProgressPhotosState copyWith({
    List<ProgressPhoto>? photos,
    LatestPhotosByView? latestByView,
    List<PhotoComparison>? comparisons,
    PhotoStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return ProgressPhotosState(
      photos: photos ?? this.photos,
      latestByView: latestByView ?? this.latestByView,
      comparisons: comparisons ?? this.comparisons,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Progress photos state notifier
class ProgressPhotosNotifier extends StateNotifier<ProgressPhotosState> {
  final ProgressPhotosRepository _repository;
  final String _userId;

  ProgressPhotosNotifier(this._repository, this._userId)
      : super(const ProgressPhotosState());

  /// Load all photos data
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repository.getPhotos(userId: _userId),
        _repository.getLatestPhotosByView(_userId),
        _repository.getComparisons(userId: _userId),
        _repository.getStats(_userId),
      ]);

      state = state.copyWith(
        photos: results[0] as List<ProgressPhoto>,
        latestByView: results[1] as LatestPhotosByView,
        comparisons: results[2] as List<PhotoComparison>,
        stats: results[3] as PhotoStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load photos only
  Future<void> loadPhotos({PhotoViewType? viewType}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final photos = await _repository.getPhotos(
        userId: _userId,
        viewType: viewType,
      );
      state = state.copyWith(photos: photos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load latest photos by view
  Future<void> loadLatestByView() async {
    try {
      final latestByView = await _repository.getLatestPhotosByView(_userId);
      state = state.copyWith(latestByView: latestByView);
    } catch (e) {
      debugPrint('Error loading latest by view: $e');
    }
  }

  /// Upload a new photo
  Future<ProgressPhoto?> uploadPhoto({
    required File imageFile,
    required PhotoViewType viewType,
    DateTime? takenAt,
    double? bodyWeightKg,
    String? notes,
    String? measurementId,
    PhotoVisibility visibility = PhotoVisibility.private,
  }) async {
    try {
      final photo = await _repository.uploadPhoto(
        userId: _userId,
        imageFile: imageFile,
        viewType: viewType,
        takenAt: takenAt,
        bodyWeightKg: bodyWeightKg,
        notes: notes,
        measurementId: measurementId,
        visibility: visibility,
      );

      // Refresh photos list
      await loadPhotos();
      await loadLatestByView();

      return photo;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Delete a photo
  Future<bool> deletePhoto(String photoId) async {
    try {
      await _repository.deletePhoto(photoId: photoId, userId: _userId);

      // Remove from local state
      final updatedPhotos = state.photos.where((p) => p.id != photoId).toList();
      state = state.copyWith(photos: updatedPhotos);

      // Refresh latest by view
      await loadLatestByView();

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Create a comparison
  Future<PhotoComparison?> createComparison({
    required String beforePhotoId,
    required String afterPhotoId,
    String? title,
    String? description,
  }) async {
    try {
      final comparison = await _repository.createComparison(
        userId: _userId,
        beforePhotoId: beforePhotoId,
        afterPhotoId: afterPhotoId,
        title: title,
        description: description,
      );

      // Add to local state
      final updatedComparisons = [comparison, ...state.comparisons];
      state = state.copyWith(comparisons: updatedComparisons);

      return comparison;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update a comparison
  Future<PhotoComparison?> updateComparison({
    required String comparisonId,
    String? title,
    String? description,
    String? layout,
    Map<String, dynamic>? settingsJson,
    String? aiSummary,
    String? exportedImageUrl,
    List<Map<String, dynamic>>? photosJson,
  }) async {
    try {
      final updated = await _repository.updateComparison(
        comparisonId: comparisonId,
        userId: _userId,
        title: title,
        description: description,
        layout: layout,
        settingsJson: settingsJson,
        aiSummary: aiSummary,
        exportedImageUrl: exportedImageUrl,
        photosJson: photosJson,
      );

      // Update in local state
      final updatedComparisons = state.comparisons.map((c) {
        return c.id == comparisonId ? updated : c;
      }).toList();
      state = state.copyWith(comparisons: updatedComparisons);

      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get AI progress summary
  Future<String?> getAiSummary({
    required String beforePhotoUrl,
    required String afterPhotoUrl,
    required int daysBetween,
    double? weightChangeKg,
  }) async {
    try {
      return await _repository.getAiSummary(
        beforePhotoUrl: beforePhotoUrl,
        afterPhotoUrl: afterPhotoUrl,
        daysBetween: daysBetween,
        weightChangeKg: weightChangeKg,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Delete a comparison
  Future<bool> deleteComparison(String comparisonId) async {
    try {
      await _repository.deleteComparison(
        comparisonId: comparisonId,
        userId: _userId,
      );

      // Remove from local state
      final updatedComparisons =
          state.comparisons.where((c) => c.id != comparisonId).toList();
      state = state.copyWith(comparisons: updatedComparisons);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for progress photos state
final progressPhotosNotifierProvider = StateNotifierProvider.family<
    ProgressPhotosNotifier, ProgressPhotosState, String>(
  (ref, userId) => ProgressPhotosNotifier(
    ref.watch(progressPhotosRepositoryProvider),
    userId,
  ),
);
