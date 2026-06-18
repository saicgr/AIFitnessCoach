import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Casual per-workout photo (gym selfie / lift snapshot) captured optionally at
/// workout completion. Mirrors the backend `WorkoutPhotoResponse` shape.
@immutable
class WorkoutPhoto {
  final String id;
  final String userId;
  final String? workoutId;
  final String photoUrl;
  final String? thumbnailUrl;
  final String? storageKey;
  final DateTime takenAt;
  final String? caption;
  final String visibility;
  final DateTime? createdAt;

  const WorkoutPhoto({
    required this.id,
    required this.userId,
    this.workoutId,
    required this.photoUrl,
    this.thumbnailUrl,
    this.storageKey,
    required this.takenAt,
    this.caption,
    this.visibility = 'private',
    this.createdAt,
  });

  factory WorkoutPhoto.fromJson(Map<String, dynamic> json) {
    return WorkoutPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String?,
      photoUrl: json['photo_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      storageKey: json['storage_key'] as String?,
      takenAt: DateTime.parse(json['taken_at'] as String),
      caption: json['caption'] as String?,
      visibility: (json['visibility'] as String?) ?? 'private',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

/// Workout photos repository provider.
final workoutPhotosRepositoryProvider = Provider<WorkoutPhotosRepository>((ref) {
  return WorkoutPhotosRepository(ref.watch(apiClientProvider));
});

/// Repository for casual per-workout photo upload / retrieval / deletion.
/// Mirrors [ProgressPhotosRepository] but stores informal post-workout snaps
/// instead of structured body-transformation shots.
class WorkoutPhotosRepository {
  final ApiClient _client;

  WorkoutPhotosRepository(this._client);

  /// Upload a casual workout photo. Detects PNG vs JPEG from the file
  /// extension (edited photos are saved as .png) and sets the matching
  /// content type so the backend magic-byte check passes.
  Future<WorkoutPhoto> uploadPhoto({
    required String userId,
    required File imageFile,
    String? workoutId,
    DateTime? takenAt,
    String? caption,
    String visibility = 'private',
  }) async {
    try {
      debugPrint('📸 [WorkoutPhotos] Uploading photo for $userId (workout=$workoutId)');

      final ext = imageFile.path.split('.').last.toLowerCase();
      final isPng = ext == 'png';
      final filename =
          'workout_${DateTime.now().millisecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}';
      final contentType =
          isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      final formData = FormData.fromMap({
        'user_id': userId,
        'visibility': visibility,
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
          contentType: contentType,
        ),
        if (workoutId != null) 'workout_id': workoutId,
        if (takenAt != null) 'taken_at': takenAt.toIso8601String(),
        if (caption != null) 'caption': caption,
      });

      final response = await _client.post(
        '/workout-photos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      debugPrint('✅ [WorkoutPhotos] Photo uploaded successfully');
      return WorkoutPhoto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [WorkoutPhotos] Error uploading photo: $e');
      rethrow;
    }
  }

  /// Fetch a user's workout photos, optionally filtered by workout / date range.
  Future<List<WorkoutPhoto>> getPhotos({
    required String userId,
    String? workoutId,
    int limit = 50,
    int offset = 0,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      debugPrint('🔍 [WorkoutPhotos] Fetching photos for $userId');

      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (workoutId != null) queryParams['workout_id'] = workoutId;
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
      }

      final response = await _client.get(
        '/workout-photos/$userId',
        queryParameters: queryParams,
      );

      final photos = (response.data as List)
          .map((json) => WorkoutPhoto.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WorkoutPhotos] Fetched ${photos.length} photos');
      return photos;
    } catch (e) {
      debugPrint('❌ [WorkoutPhotos] Error fetching photos: $e');
      rethrow;
    }
  }

  /// Delete a workout photo (removes the S3 object + DB row server-side).
  Future<void> deletePhoto({
    required String photoId,
    required String userId,
  }) async {
    try {
      debugPrint('🗑️ [WorkoutPhotos] Deleting photo $photoId');

      await _client.delete(
        '/workout-photos/$photoId',
        queryParameters: {'user_id': userId},
      );

      debugPrint('✅ [WorkoutPhotos] Photo deleted');
    } catch (e) {
      debugPrint('❌ [WorkoutPhotos] Error deleting photo: $e');
      rethrow;
    }
  }
}
