import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workout_gallery_service.dart';
import '../services/api_client.dart';

/// Workout gallery service provider
final workoutGalleryServiceProvider = Provider<WorkoutGalleryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutGalleryService(apiClient);
});

/// Gallery images list provider (paginated)
final galleryImagesProvider = FutureProvider.autoDispose
    .family<WorkoutGalleryImageList, GalleryQueryParams>((ref, params) async {
  final service = ref.watch(workoutGalleryServiceProvider);
  return await service.getGalleryImages(
    userId: params.userId,
    page: params.page,
    pageSize: params.pageSize,
    templateType: params.templateType,
  );
});

/// Single gallery image provider
final galleryImageProvider = FutureProvider.autoDispose
    .family<WorkoutGalleryImage, GalleryImageParams>((ref, params) async {
  final service = ref.watch(workoutGalleryServiceProvider);
  return await service.getGalleryImage(
    userId: params.userId,
    imageId: params.imageId,
  );
});

/// Recent gallery images for profile preview (max 4)
final recentGalleryImagesProvider = FutureProvider.autoDispose
    .family<List<WorkoutGalleryImage>, String>((ref, userId) async {
  final service = ref.watch(workoutGalleryServiceProvider);
  return await service.getRecentImagesForProfile(userId: userId);
});

/// Check if user has any gallery images
final hasGalleryImagesProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  final service = ref.watch(workoutGalleryServiceProvider);
  return await service.hasGalleryImages(userId);
});

/// Query params for gallery images
class GalleryQueryParams {
  final String userId;
  final int page;
  final int pageSize;
  final GalleryTemplateType? templateType;

  const GalleryQueryParams({
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
    this.templateType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryQueryParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          page == other.page &&
          pageSize == other.pageSize &&
          templateType == other.templateType;

  @override
  int get hashCode =>
      userId.hashCode ^
      page.hashCode ^
      pageSize.hashCode ^
      templateType.hashCode;
}

/// Params for single gallery image
class GalleryImageParams {
  final String userId;
  final String imageId;

  const GalleryImageParams({
    required this.userId,
    required this.imageId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryImageParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          imageId == other.imageId;

  @override
  int get hashCode => userId.hashCode ^ imageId.hashCode;
}

/// State notifier for managing gallery upload operations
class GalleryUploadNotifier extends StateNotifier<AsyncValue<WorkoutGalleryImage?>> {
  final WorkoutGalleryService _service;

  GalleryUploadNotifier(this._service) : super(const AsyncValue.data(null));

  /// Upload a gallery image
  Future<WorkoutGalleryImage?> uploadImage({
    required String userId,
    required String workoutLogId,
    required GalleryTemplateType templateType,
    required Uint8List imageBytes,
    required WorkoutSnapshot workoutSnapshot,
    List<Map<String, dynamic>>? prsData,
    List<Map<String, dynamic>>? achievementsData,
    Uint8List? userPhotoBytes,
  }) async {
    state = const AsyncValue.loading();

    try {
      final image = await _service.uploadImage(
        userId: userId,
        workoutLogId: workoutLogId,
        templateType: templateType,
        imageBytes: imageBytes,
        workoutSnapshot: workoutSnapshot,
        prsData: prsData,
        achievementsData: achievementsData,
        userPhotoBytes: userPhotoBytes,
      );

      state = AsyncValue.data(image);
      return image;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Gallery upload state provider
final galleryUploadProvider =
    StateNotifierProvider.autoDispose<GalleryUploadNotifier, AsyncValue<WorkoutGalleryImage?>>(
        (ref) {
  final service = ref.watch(workoutGalleryServiceProvider);
  return GalleryUploadNotifier(service);
});

/// State notifier for managing share to feed operations
class ShareToFeedNotifier extends StateNotifier<AsyncValue<String?>> {
  final WorkoutGalleryService _service;

  ShareToFeedNotifier(this._service) : super(const AsyncValue.data(null));

  /// Share image to social feed
  Future<String?> shareToFeed({
    required String userId,
    required String imageId,
    String? caption,
    String visibility = 'friends',
  }) async {
    state = const AsyncValue.loading();

    try {
      final activityId = await _service.shareToFeed(
        userId: userId,
        imageId: imageId,
        caption: caption,
        visibility: visibility,
      );

      state = AsyncValue.data(activityId);
      return activityId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Share to feed state provider
final shareToFeedProvider =
    StateNotifierProvider.autoDispose<ShareToFeedNotifier, AsyncValue<String?>>((ref) {
  final service = ref.watch(workoutGalleryServiceProvider);
  return ShareToFeedNotifier(service);
});

/// State notifier for managing delete operations
class GalleryDeleteNotifier extends StateNotifier<AsyncValue<bool>> {
  final WorkoutGalleryService _service;

  GalleryDeleteNotifier(this._service) : super(const AsyncValue.data(false));

  /// Delete a gallery image
  Future<bool> deleteImage({
    required String userId,
    required String imageId,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.deleteImage(
        userId: userId,
        imageId: imageId,
      );

      state = const AsyncValue.data(true);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(false);
  }
}

/// Gallery delete state provider
final galleryDeleteProvider =
    StateNotifierProvider.autoDispose<GalleryDeleteNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(workoutGalleryServiceProvider);
  return GalleryDeleteNotifier(service);
});
