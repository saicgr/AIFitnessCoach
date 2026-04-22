/// S3 upload helper for per-set note media (audio + photo).
///
/// The mobile `EnhancedNotesSheet` produces local file paths
/// (`/tmp/.../recording_xxx.m4a` for audio, gallery file paths for photos).
/// Those local paths are meaningless to the backend — they must be
/// uploaded to S3 first so the `notes_audio_url` / `notes_photo_urls`
/// columns on the `set_performances` table hold canonical URLs.
///
/// Photos reuse the existing `/social/images/presign` endpoint since the
/// bucket is shared. Audio currently has no presign endpoint, so uploads
/// are deferred until `POST /workouts/set-notes/presign` ships — until
/// then the audio path is persisted as the local file path and surfaces
/// a loud log line.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api_client.dart';

class SetNoteMediaService {
  final ApiClient _apiClient;

  SetNoteMediaService(this._apiClient);

  /// Upload every photo in [localPaths] to S3. Returns the resolved
  /// (S3) URL list in the same order. Failed uploads are DROPPED from
  /// the returned list — we never persist a local file path as a photo
  /// URL (the server would serve a 404).
  Future<List<String>> uploadPhotos({
    required List<String> localPaths,
    required String userId,
  }) async {
    if (localPaths.isEmpty) return const [];
    final resolved = <String>[];
    for (final path in localPaths) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        // Already an S3 URL (re-save after prior upload). Pass through.
        resolved.add(path);
        continue;
      }
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('⚠️ [SetNoteMedia] Photo missing, skipping: $path');
        continue;
      }
      final url = await _uploadPhotoOne(file: file, userId: userId);
      if (url != null) resolved.add(url);
    }
    return resolved;
  }

  /// Upload an audio voice-note to S3 via the workout set-note audio
  /// presign endpoint (`POST /workouts/set-notes/audio/presign`).
  /// Returns the canonical `public_url` on success, null on failure.
  Future<String?> uploadAudio({
    required String localPath,
    required String userId,
  }) async {
    if (localPath.isEmpty) return null;
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }
    final file = File(localPath);
    if (!await file.exists()) {
      debugPrint('⚠️ [SetNoteMedia] Audio missing: $localPath');
      return null;
    }

    // Extension + content-type are inferred from the file path so we pass
    // the right values to the presign endpoint. `flutter_sound` / `record`
    // default to `.m4a` (AAC/MP4 container) on both iOS and Android.
    final ext = _extOf(localPath);
    final contentType = _audioContentTypeFor(ext);

    try {
      final presign = await _apiClient.post(
        '/workouts/set-notes/audio/presign',
        queryParameters: {
          'user_id': userId,
          'file_extension': ext,
          'content_type': contentType,
        },
      );
      if (presign.statusCode != 200 || presign.data == null) {
        debugPrint('❌ [SetNoteMedia] audio presign failed: ${presign.statusCode}');
        return null;
      }
      final uploadUrl = presign.data['upload_url'] as String;
      final publicUrl = presign.data['public_url'] as String;
      final bytes = await file.readAsBytes();

      final httpClient = HttpClient();
      try {
        final req = await httpClient.putUrl(Uri.parse(uploadUrl));
        req.headers.set('Content-Type', contentType);
        req.contentLength = bytes.length;
        req.add(bytes);
        final resp = await req.close();
        if (resp.statusCode == 200) {
          return publicUrl;
        }
        final body = await resp.transform(utf8.decoder).join();
        debugPrint(
            '❌ [SetNoteMedia] audio S3 upload failed ${resp.statusCode}: $body');
        return null;
      } finally {
        httpClient.close();
      }
    } catch (e) {
      debugPrint('❌ [SetNoteMedia] audio upload error: $e');
      return null;
    }
  }

  static String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return 'm4a';
    final raw = path.substring(dot + 1).toLowerCase();
    // Guard against query-strings on network-ish paths (shouldn't happen
    // here but be defensive).
    final clean = raw.split('?').first;
    return clean.isEmpty ? 'm4a' : clean;
  }

  static String _audioContentTypeFor(String ext) {
    switch (ext) {
      case 'm4a':
      case 'mp4':
        return 'audio/m4a';
      case 'aac':
        return 'audio/aac';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/m4a';
    }
  }

  Future<String?> _uploadPhotoOne({
    required File file,
    required String userId,
  }) async {
    try {
      final presign = await _apiClient.post(
        '/social/images/presign',
        queryParameters: {
          'user_id': userId,
          'file_extension': 'jpg',
          'content_type': 'image/jpeg',
        },
      );
      if (presign.statusCode != 200 || presign.data == null) {
        debugPrint('❌ [SetNoteMedia] presign failed: ${presign.statusCode}');
        return null;
      }
      final uploadUrl = presign.data['upload_url'] as String;
      final publicUrl = presign.data['public_url'] as String;
      final bytes = await file.readAsBytes();

      final httpClient = HttpClient();
      try {
        final req = await httpClient.putUrl(Uri.parse(uploadUrl));
        req.headers.set('Content-Type', 'image/jpeg');
        req.contentLength = bytes.length;
        req.add(bytes);
        final resp = await req.close();
        if (resp.statusCode == 200) {
          return publicUrl;
        }
        final body = await resp.transform(utf8.decoder).join();
        debugPrint(
            '❌ [SetNoteMedia] S3 upload failed ${resp.statusCode}: $body');
        return null;
      } finally {
        httpClient.close();
      }
    } catch (e) {
      debugPrint('❌ [SetNoteMedia] photo upload error: $e');
      return null;
    }
  }
}
