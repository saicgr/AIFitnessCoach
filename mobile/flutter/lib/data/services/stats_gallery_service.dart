import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Template type for shareable stats images
enum StatsTemplateType {
  overview('overview'),
  achievements('achievements'),
  prs('prs');

  final String value;
  const StatsTemplateType(this.value);

  static StatsTemplateType fromString(String value) {
    return StatsTemplateType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StatsTemplateType.overview,
    );
  }
}

/// Stats snapshot data for gallery image
class StatsSnapshot {
  final int? totalWorkouts;
  final int? weeklyCompleted;
  final int? weeklyGoal;
  final int? currentStreak;
  final int? longestStreak;
  final int? totalTimeMinutes;
  final double? totalVolumeKg;
  final int? totalCalories;
  final String? dateRangeLabel;

  const StatsSnapshot({
    this.totalWorkouts,
    this.weeklyCompleted,
    this.weeklyGoal,
    this.currentStreak,
    this.longestStreak,
    this.totalTimeMinutes,
    this.totalVolumeKg,
    this.totalCalories,
    this.dateRangeLabel,
  });

  Map<String, dynamic> toJson() => {
        if (totalWorkouts != null) 'total_workouts': totalWorkouts,
        if (weeklyCompleted != null) 'weekly_completed': weeklyCompleted,
        if (weeklyGoal != null) 'weekly_goal': weeklyGoal,
        if (currentStreak != null) 'current_streak': currentStreak,
        if (longestStreak != null) 'longest_streak': longestStreak,
        if (totalTimeMinutes != null) 'total_time_minutes': totalTimeMinutes,
        if (totalVolumeKg != null) 'total_volume_kg': totalVolumeKg,
        if (totalCalories != null) 'total_calories': totalCalories,
        if (dateRangeLabel != null) 'date_range_label': dateRangeLabel,
      };
}

/// Stats gallery image data model
class StatsGalleryImage {
  final String id;
  final String userId;
  final String imageUrl;
  final String? thumbnailUrl;
  final StatsTemplateType templateType;
  final Map<String, dynamic>? statsSnapshot;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final List<Map<String, dynamic>> prsData;
  final List<Map<String, dynamic>> achievementsData;
  final bool sharedToFeed;
  final bool sharedExternally;
  final int externalSharesCount;
  final DateTime createdAt;

  const StatsGalleryImage({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.templateType,
    this.statsSnapshot,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.prsData = const [],
    this.achievementsData = const [],
    this.sharedToFeed = false,
    this.sharedExternally = false,
    this.externalSharesCount = 0,
    required this.createdAt,
  });

  factory StatsGalleryImage.fromJson(Map<String, dynamic> json) {
    return StatsGalleryImage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      templateType: StatsTemplateType.fromString(json['template_type'] as String),
      statsSnapshot: json['stats_snapshot'] as Map<String, dynamic>?,
      dateRangeStart: json['date_range_start'] != null
          ? DateTime.parse(json['date_range_start'] as String)
          : null,
      dateRangeEnd: json['date_range_end'] != null
          ? DateTime.parse(json['date_range_end'] as String)
          : null,
      prsData: (json['prs_data'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      achievementsData: (json['achievements_data'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      sharedToFeed: json['shared_to_feed'] as bool? ?? false,
      sharedExternally: json['shared_externally'] as bool? ?? false,
      externalSharesCount: json['external_shares_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Stats gallery service provider
final statsGalleryServiceProvider = Provider<StatsGalleryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatsGalleryService(apiClient);
});

/// Service for managing stats gallery images
class StatsGalleryService {
  final ApiClient _client;

  StatsGalleryService(this._client);

  /// Upload a stats image to the gallery
  Future<StatsGalleryImage> uploadImage({
    required String userId,
    required StatsTemplateType templateType,
    required Uint8List imageBytes,
    required StatsSnapshot statsSnapshot,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    List<Map<String, dynamic>>? prsData,
    List<Map<String, dynamic>>? achievementsData,
  }) async {
    try {
      debugPrint('🔍 [StatsGallery] Uploading stats image...');

      final imageBase64 = base64Encode(imageBytes);

      final response = await _client.post(
        '/stats-gallery/upload',
        queryParameters: {'user_id': userId},
        data: {
          'template_type': templateType.value,
          'image_base64': imageBase64,
          'stats_snapshot': statsSnapshot.toJson(),
          if (dateRangeStart != null)
            'date_range_start': dateRangeStart.toIso8601String().split('T')[0],
          if (dateRangeEnd != null)
            'date_range_end': dateRangeEnd.toIso8601String().split('T')[0],
          'prs_data': prsData ?? [],
          'achievements_data': achievementsData ?? [],
        },
      );

      debugPrint('✅ [StatsGallery] Image uploaded successfully');
      return StatsGalleryImage.fromJson(response.data['image']);
    } catch (e) {
      debugPrint('❌ [StatsGallery] Error uploading image: $e');
      rethrow;
    }
  }

  /// Share a stats image to the social feed
  Future<String> shareToFeed({
    required String userId,
    required String imageId,
    String? caption,
  }) async {
    try {
      debugPrint('🔍 [StatsGallery] Sharing to feed...');

      final response = await _client.post(
        '/stats-gallery/$imageId/share-to-feed',
        queryParameters: {'user_id': userId},
        data: {
          if (caption != null) 'caption': caption,
          'visibility': 'friends',
        },
      );

      debugPrint('✅ [StatsGallery] Shared to feed successfully');
      return response.data['activity_id'] as String;
    } catch (e) {
      debugPrint('❌ [StatsGallery] Error sharing to feed: $e');
      rethrow;
    }
  }

  /// Track external share (Instagram, system share)
  Future<void> trackExternalShare({
    required String userId,
    required String imageId,
  }) async {
    try {
      debugPrint('🔍 [StatsGallery] Tracking external share...');

      await _client.put(
        '/stats-gallery/$imageId/track-external-share',
        queryParameters: {'user_id': userId},
      );

      debugPrint('✅ [StatsGallery] External share tracked');
    } catch (e) {
      debugPrint('❌ [StatsGallery] Error tracking external share: $e');
      // Don't rethrow - tracking failure shouldn't block the share
    }
  }

  /// List stats gallery images
  Future<List<StatsGalleryImage>> listImages({
    required String userId,
    int page = 1,
    int pageSize = 20,
    StatsTemplateType? templateType,
  }) async {
    try {
      debugPrint('🔍 [StatsGallery] Listing images...');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (templateType != null) {
        queryParams['template_type'] = templateType.value;
      }

      final response = await _client.get(
        '/stats-gallery/$userId',
        queryParameters: queryParams,
      );

      final images = (response.data['images'] as List<dynamic>)
          .map((json) => StatsGalleryImage.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [StatsGallery] Got ${images.length} images');
      return images;
    } catch (e) {
      debugPrint('❌ [StatsGallery] Error listing images: $e');
      rethrow;
    }
  }

  /// Delete a stats gallery image
  Future<void> deleteImage({
    required String userId,
    required String imageId,
  }) async {
    try {
      debugPrint('🔍 [StatsGallery] Deleting image...');

      await _client.delete(
        '/stats-gallery/$imageId',
        queryParameters: {'user_id': userId},
      );

      debugPrint('✅ [StatsGallery] Image deleted');
    } catch (e) {
      debugPrint('❌ [StatsGallery] Error deleting image: $e');
      rethrow;
    }
  }
}
