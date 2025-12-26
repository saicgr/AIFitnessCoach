import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Template type for shareable workout images
enum GalleryTemplateType {
  stats('stats'),
  prs('prs'),
  photoOverlay('photo_overlay'),
  motivational('motivational');

  final String value;
  const GalleryTemplateType(this.value);

  static GalleryTemplateType fromString(String value) {
    return GalleryTemplateType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GalleryTemplateType.stats,
    );
  }
}

/// Workout snapshot data for gallery image
class WorkoutSnapshot {
  final String? workoutName;
  final int? durationSeconds;
  final int? calories;
  final double? totalVolumeKg;
  final int? totalSets;
  final int? totalReps;
  final int? exercisesCount;

  const WorkoutSnapshot({
    this.workoutName,
    this.durationSeconds,
    this.calories,
    this.totalVolumeKg,
    this.totalSets,
    this.totalReps,
    this.exercisesCount,
  });

  Map<String, dynamic> toJson() => {
        if (workoutName != null) 'workout_name': workoutName,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (calories != null) 'calories': calories,
        if (totalVolumeKg != null) 'total_volume_kg': totalVolumeKg,
        if (totalSets != null) 'total_sets': totalSets,
        if (totalReps != null) 'total_reps': totalReps,
        if (exercisesCount != null) 'exercises_count': exercisesCount,
      };
}

/// Gallery image data model
class WorkoutGalleryImage {
  final String id;
  final String userId;
  final String? workoutLogId;
  final String imageUrl;
  final String? thumbnailUrl;
  final GalleryTemplateType templateType;
  final String? workoutName;
  final int? durationSeconds;
  final int? calories;
  final double? totalVolumeKg;
  final int? totalSets;
  final int? totalReps;
  final int? exercisesCount;
  final String? userPhotoUrl;
  final List<Map<String, dynamic>> prsData;
  final List<Map<String, dynamic>> achievementsData;
  final bool sharedToFeed;
  final bool sharedExternally;
  final int externalSharesCount;
  final DateTime createdAt;

  const WorkoutGalleryImage({
    required this.id,
    required this.userId,
    this.workoutLogId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.templateType,
    this.workoutName,
    this.durationSeconds,
    this.calories,
    this.totalVolumeKg,
    this.totalSets,
    this.totalReps,
    this.exercisesCount,
    this.userPhotoUrl,
    this.prsData = const [],
    this.achievementsData = const [],
    this.sharedToFeed = false,
    this.sharedExternally = false,
    this.externalSharesCount = 0,
    required this.createdAt,
  });

  factory WorkoutGalleryImage.fromJson(Map<String, dynamic> json) {
    return WorkoutGalleryImage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutLogId: json['workout_log_id'] as String?,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      templateType: GalleryTemplateType.fromString(json['template_type'] as String),
      workoutName: json['workout_name'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      calories: json['calories'] as int?,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      totalSets: json['total_sets'] as int?,
      totalReps: json['total_reps'] as int?,
      exercisesCount: json['exercises_count'] as int?,
      userPhotoUrl: json['user_photo_url'] as String?,
      prsData: (json['prs_data'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      achievementsData: (json['achievements_data'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      sharedToFeed: json['shared_to_feed'] as bool? ?? false,
      sharedExternally: json['shared_externally'] as bool? ?? false,
      externalSharesCount: json['external_shares_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Duration formatted as mm:ss or hh:mm:ss
  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;
    final seconds = durationSeconds! % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Volume formatted with unit
  String get formattedVolume {
    if (totalVolumeKg == null) return '--';
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeKg!.toStringAsFixed(0)} kg';
  }
}

/// Paginated gallery image list
class WorkoutGalleryImageList {
  final List<WorkoutGalleryImage> images;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const WorkoutGalleryImageList({
    required this.images,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory WorkoutGalleryImageList.fromJson(Map<String, dynamic> json) {
    return WorkoutGalleryImageList(
      images: (json['images'] as List<dynamic>)
          .map((e) => WorkoutGalleryImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      hasMore: json['has_more'] as bool,
    );
  }
}

/// Service for workout gallery operations
class WorkoutGalleryService {
  final ApiClient _apiClient;

  WorkoutGalleryService(this._apiClient);

  // ============================================================
  // UPLOAD
  // ============================================================

  /// Upload a workout gallery image
  Future<WorkoutGalleryImage> uploadImage({
    required String userId,
    required String workoutLogId,
    required GalleryTemplateType templateType,
    required Uint8List imageBytes,
    required WorkoutSnapshot workoutSnapshot,
    List<Map<String, dynamic>>? prsData,
    List<Map<String, dynamic>>? achievementsData,
    Uint8List? userPhotoBytes,
  }) async {
    try {
      final imageBase64 = base64Encode(imageBytes);
      final userPhotoBase64 =
          userPhotoBytes != null ? base64Encode(userPhotoBytes) : null;

      final response = await _apiClient.post(
        '/workout-gallery/upload',
        queryParameters: {'user_id': userId},
        data: {
          'workout_log_id': workoutLogId,
          'template_type': templateType.value,
          'image_base64': imageBase64,
          'workout_snapshot': workoutSnapshot.toJson(),
          'prs_data': prsData ?? [],
          'achievements_data': achievementsData ?? [],
          if (userPhotoBase64 != null) 'user_photo_base64': userPhotoBase64,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['image'] != null) {
          debugPrint('✅ [Gallery] Image uploaded: ${templateType.value}');
          return WorkoutGalleryImage.fromJson(
              data['image'] as Map<String, dynamic>);
        } else {
          throw Exception(data['message'] ?? 'Upload failed');
        }
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Gallery] Error uploading image: $e');
      rethrow;
    }
  }

  // ============================================================
  // LIST & GET
  // ============================================================

  /// Get user's gallery images with pagination
  Future<WorkoutGalleryImageList> getGalleryImages({
    required String userId,
    int page = 1,
    int pageSize = 20,
    GalleryTemplateType? templateType,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (templateType != null) 'template_type': templateType.value,
      };

      final response = await _apiClient.get(
        '/workout-gallery/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint(
            '✅ [Gallery] Loaded ${(response.data['images'] as List).length} images');
        return WorkoutGalleryImageList.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to get gallery: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Gallery] Error getting gallery: $e');
      rethrow;
    }
  }

  /// Get a single gallery image by ID
  Future<WorkoutGalleryImage> getGalleryImage({
    required String userId,
    required String imageId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/workout-gallery/$userId/$imageId',
      );

      if (response.statusCode == 200) {
        return WorkoutGalleryImage.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to get image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Gallery] Error getting image: $e');
      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Soft delete a gallery image
  Future<void> deleteImage({
    required String userId,
    required String imageId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/workout-gallery/$imageId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Gallery] Image deleted: $imageId');
      } else {
        throw Exception('Failed to delete image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Gallery] Error deleting image: $e');
      rethrow;
    }
  }

  // ============================================================
  // SHARE TO FEED
  // ============================================================

  /// Share a gallery image to the social feed
  Future<String> shareToFeed({
    required String userId,
    required String imageId,
    String? caption,
    String visibility = 'friends',
  }) async {
    try {
      final response = await _apiClient.post(
        '/workout-gallery/$imageId/share-to-feed',
        queryParameters: {'user_id': userId},
        data: {
          if (caption != null) 'caption': caption,
          'visibility': visibility,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          debugPrint('✅ [Gallery] Image shared to feed');
          return data['activity_id'] as String;
        } else {
          throw Exception(data['message'] ?? 'Share failed');
        }
      } else {
        throw Exception('Failed to share to feed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Gallery] Error sharing to feed: $e');
      rethrow;
    }
  }

  // ============================================================
  // EXTERNAL SHARE TRACKING
  // ============================================================

  /// Track when image is shared to external platform (Instagram, etc.)
  Future<int> trackExternalShare({
    required String userId,
    required String imageId,
  }) async {
    try {
      final response = await _apiClient.put(
        '/workout-gallery/$imageId/track-external-share',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Gallery] External share tracked');
        return data['external_shares_count'] as int;
      } else {
        throw Exception('Failed to track share: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Gallery] Error tracking external share: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Get recent gallery images for profile preview (max 4)
  Future<List<WorkoutGalleryImage>> getRecentImagesForProfile({
    required String userId,
    int limit = 4,
  }) async {
    try {
      final result = await getGalleryImages(
        userId: userId,
        page: 1,
        pageSize: limit,
      );
      return result.images;
    } catch (e) {
      debugPrint('⚠️ [Gallery] Error getting profile images: $e');
      return [];
    }
  }

  /// Check if user has any gallery images
  Future<bool> hasGalleryImages(String userId) async {
    try {
      final result = await getGalleryImages(
        userId: userId,
        page: 1,
        pageSize: 1,
      );
      return result.total > 0;
    } catch (e) {
      return false;
    }
  }
}
