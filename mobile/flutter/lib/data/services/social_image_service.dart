import 'dart:convert';
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

  /// Upload an image for a social post using pre-signed URL.
  /// The image goes directly to S3 -- zero bytes through the API server.
  ///
  /// Returns the public image URL if successful, null otherwise.
  Future<String?> uploadPostImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      debugPrint('[SocialImage] Starting presigned upload for user: $userId');

      // Step 1: Get pre-signed URL from backend
      final presignResponse = await _apiClient.post(
        '/social/images/presign',
        queryParameters: {
          'user_id': userId,
          'file_extension': 'jpg',
          'content_type': 'image/jpeg',
        },
      );

      if (presignResponse.statusCode != 200 || presignResponse.data == null) {
        debugPrint('[SocialImage] Failed to get presigned URL: ${presignResponse.statusCode}');
        return null;
      }

      final uploadUrl = presignResponse.data['upload_url'] as String;
      final publicUrl = presignResponse.data['public_url'] as String;

      // Step 2: Upload directly to S3 via pre-signed URL
      final bytes = await imageFile.readAsBytes();
      debugPrint('[SocialImage] Uploading ${bytes.length} bytes directly to S3');

      final httpClient = HttpClient();
      try {
        final request = await httpClient.putUrl(Uri.parse(uploadUrl));
        request.headers.set('Content-Type', 'image/jpeg');
        // Must set contentLength explicitly — otherwise Dart uses chunked
        // transfer encoding which S3 presigned URLs don't support (causes 501).
        request.contentLength = bytes.length;
        request.add(bytes);
        final response = await request.close();

        if (response.statusCode == 200) {
          debugPrint('[SocialImage] Presigned upload successful: $publicUrl');
          return publicUrl;
        } else {
          final body = await response.transform(utf8.decoder).join();
          debugPrint('[SocialImage] S3 upload failed: ${response.statusCode} - $body');
          return null;
        }
      } finally {
        httpClient.close();
      }
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
