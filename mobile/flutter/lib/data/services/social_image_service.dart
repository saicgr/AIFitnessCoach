import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Provider for social image upload service
final socialImageServiceProvider = Provider<SocialImageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialImageService(apiClient);
});

/// Service for uploading images for social posts
class SocialImageService {
  final ApiClient _apiClient;

  SocialImageService(this._apiClient);

  /// Upload an image for a social post
  ///
  /// Returns the image URL if successful, null otherwise
  Future<String?> uploadPostImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      debugPrint('[SocialImage] Uploading image for user: $userId');

      // Read file as bytes
      final fileName = imageFile.path.split('/').last;

      // Create multipart form data
      final formData = FormData.fromMap({
        'user_id': userId,
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // Upload to backend
      final response = await _apiClient.post(
        '/social/images/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          // Increase timeout for file uploads
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final imageUrl = response.data['image_url'] as String?;
        debugPrint('[SocialImage] Upload successful: $imageUrl');
        return imageUrl;
      }

      debugPrint('[SocialImage] Upload failed: status ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('[SocialImage] DioException: ${e.message}');
      debugPrint('[SocialImage] Response: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('[SocialImage] Error uploading image: $e');
      return null;
    }
  }
}
