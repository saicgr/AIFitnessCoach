/// API client for the Imports feature (/api/v1/share/*).
///
/// Three endpoint families:
///   * Image classifier      — /share/classify, /share/classify-batch
///   * Payload pipelines     — SSE: /share/import-text, /share/fetch-url,
///                                  /share/import-audio, /share/import-pdf
///   * History               — /share/history (list/detail/retry/bulk/delete)
library imports_api_service;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import 'api_client.dart';

/// One SSE event parsed off the wire.
class ShareSseEvent {
  ShareSseEvent(this.data);
  final Map<String, dynamic> data;
  String get stage => data['stage'] as String? ?? '';
}

/// Result of a single-image classify call.
class ClassifyResult {
  ClassifyResult({
    required this.contentType,
    required this.confidence,
    required this.routingHint,
    this.s3Key,
  });
  final String contentType;
  final String confidence;     // high|medium|low
  final String routingHint;
  final String? s3Key;

  factory ClassifyResult.fromJson(Map<String, dynamic> j) => ClassifyResult(
        contentType: (j['content_type'] ?? 'unknown') as String,
        confidence: (j['confidence'] ?? 'low') as String,
        routingHint: (j['routing_hint'] ?? 'chooser') as String,
        s3Key: j['s3_key'] as String?,
      );
}

/// One row of the Imports history.
class ImportHistoryRow {
  ImportHistoryRow({
    required this.id,
    required this.sourceKind,
    this.sourceOrigin,
    this.sourceUrl,
    this.classifierIntent,
    this.userOverrideIntent,
    this.targetEntityKind,
    this.targetEntityId,
    required this.status,
    this.errorMessage,
    required this.tags,
    this.rawTextPreview,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sourceKind;
  final String? sourceOrigin;
  final String? sourceUrl;
  final String? classifierIntent;
  final String? userOverrideIntent;
  final String? targetEntityKind;
  final String? targetEntityId;
  final String status;
  final String? errorMessage;
  final Map<String, dynamic> tags;
  final String? rawTextPreview;
  final String createdAt;
  final String updatedAt;

  String? get effectiveIntent => userOverrideIntent ?? classifierIntent;

  factory ImportHistoryRow.fromJson(Map<String, dynamic> j) => ImportHistoryRow(
        id: j['id'] as String,
        sourceKind: j['source_kind'] as String,
        sourceOrigin: j['source_origin'] as String?,
        sourceUrl: j['source_url'] as String?,
        classifierIntent: j['classifier_intent'] as String?,
        userOverrideIntent: j['user_override_intent'] as String?,
        targetEntityKind: j['target_entity_kind'] as String?,
        targetEntityId: j['target_entity_id'] as String?,
        status: j['status'] as String,
        errorMessage: j['error_message'] as String?,
        tags: (j['tags'] as Map?)?.cast<String, dynamic>() ?? const {},
        rawTextPreview: j['raw_text_preview'] as String?,
        createdAt: j['created_at'] as String,
        updatedAt: j['updated_at'] as String,
      );
}

class ImportsApiService {
  ImportsApiService(this._api);
  final ApiClient _api;

  // ---------------------------------------------------------------------------
  // /share/classify (single)
  // ---------------------------------------------------------------------------

  /// Classify a single image — provide [filePath] OR [s3Key].
  ///
  /// When [filePath] is provided we pre-compress to longest-edge 1024 px
  /// before upload. Cuts request size 2-4× and slashes the Gemini Vision
  /// token cost (per the plan's cost mitigations).
  Future<ClassifyResult> classifyImage({
    String? filePath,
    String? s3Key,
    String? userMessage,
    String sourceOrigin = 'photos',
    bool track = true,
  }) async {
    assert(filePath != null || s3Key != null,
        'classifyImage requires filePath or s3Key');

    MultipartFile? uploadFile;
    if (filePath != null) {
      final bytes = await _compressImage(File(filePath));
      uploadFile = MultipartFile.fromBytes(
        bytes,
        filename: _basename(filePath).replaceAll(RegExp(r'\.[^.]+$'), '') + '.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      );
    }
    final formMap = <String, dynamic>{
      if (s3Key != null) 's3_key': s3Key,
      if (userMessage != null) 'user_message': userMessage,
      'source_origin': sourceOrigin,
      'track': track.toString(),
      if (uploadFile != null) 'file': uploadFile,
    };
    final form = FormData.fromMap(formMap);
    final resp = await _api.post('/api/v1/share/classify', data: form);
    return ClassifyResult.fromJson(
        (resp.data as Map).cast<String, dynamic>());
  }

  /// Compress an image to longest-edge 1024 px, JPEG quality 85. Falls
  /// back to the original bytes if decoding fails (animated formats etc.).
  Future<Uint8List> _compressImage(File source) async {
    final bytes = await source.readAsBytes();
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final longestEdge = decoded.width > decoded.height ? decoded.width : decoded.height;
      if (longestEdge <= 1024) {
        // Already small enough — re-encode to JPEG to normalize format
        // (HEIC / PNG / WebP arrive from various sources).
        return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
      }
      final ratio = 1024 / longestEdge;
      final resized = img.copyResize(
        decoded,
        width: (decoded.width * ratio).round(),
        height: (decoded.height * ratio).round(),
        interpolation: img.Interpolation.linear,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return bytes;
    }
  }

  /// Classify multiple already-uploaded images by their s3 keys (up to 10).
  /// Returns the per-key list and a grouped view.
  Future<Map<String, dynamic>> classifyBatch(List<String> s3Keys) async {
    final resp = await _api.post(
      '/api/v1/share/classify-batch',
      data: {'s3_keys': s3Keys},
    );
    return (resp.data as Map).cast<String, dynamic>();
  }

  /// Quick host-rule URL kind. Cheap (no LLM).
  Future<Map<String, dynamic>> classifyUrl(String url) async {
    final resp = await _api.post('/api/v1/share/classify-url', data: {'url': url});
    return (resp.data as Map).cast<String, dynamic>();
  }

  // ---------------------------------------------------------------------------
  // SSE pipelines — yields events until {stage:"done"|"error"|"locked"}
  // ---------------------------------------------------------------------------

  /// SSE: post a text payload to the import-text pipeline.
  Stream<ShareSseEvent> importText({
    required String text,
    String? sourceHint,
    String? sourceUrl,
    String? locale,
  }) =>
      _sseRequest(
        path: '/share/import-text',
        body: {
          'text': text,
          if (sourceHint != null) 'source_hint': sourceHint,
          if (sourceUrl != null) 'source_url': sourceUrl,
          if (locale != null) 'locale': locale,
        },
      );

  /// SSE: fetch any URL → classify → extract.
  Stream<ShareSseEvent> fetchUrl({required String url, String? locale}) =>
      _sseRequest(
        path: '/share/fetch-url',
        body: {'url': url, if (locale != null) 'locale': locale},
      );

  /// SSE: upload an audio file (multipart). Useful for voice memos.
  Stream<ShareSseEvent> importAudio({
    required String filePath,
    String? locale,
  }) =>
      _sseMultipart(path: '/share/import-audio', filePath: filePath, fields: {
        if (locale != null) 'locale': locale,
      });

  /// SSE: upload a PDF (multipart).
  Stream<ShareSseEvent> importPdf({
    required String filePath,
    String? locale,
  }) =>
      _sseMultipart(path: '/share/import-pdf', filePath: filePath, fields: {
        if (locale != null) 'locale': locale,
      });

  // ---------------------------------------------------------------------------
  // /share/import-workout — persist a reviewed extracted workout
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> importWorkout({
    required String title,
    required List<Map<String, dynamic>> exercises,
    String? sharedItemId,
    int? estimatedDurationMin,
    List<String>? equipmentNeeded,
    String? difficulty,
    String? sourceUrl,
    String? notes,
  }) async {
    final resp = await _api.post('/api/v1/share/import-workout', data: {
      'title': title,
      'exercises': exercises,
      if (sharedItemId != null) 'shared_item_id': sharedItemId,
      if (estimatedDurationMin != null)
        'estimated_duration_min': estimatedDurationMin,
      if (equipmentNeeded != null) 'equipment_needed': equipmentNeeded,
      if (difficulty != null) 'difficulty': difficulty,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (notes != null) 'notes': notes,
    });
    return (resp.data as Map).cast<String, dynamic>();
  }

  // ---------------------------------------------------------------------------
  // History — list / detail / retry / bulk / delete / clear
  // ---------------------------------------------------------------------------

  Future<({List<ImportHistoryRow> rows, String? nextCursor})> history({
    String? category,
    String? format,
    String? origin,
    String? status,
    String? q,
    int limit = 30,
    String? cursor,
  }) async {
    final resp = await _api.get('/api/v1/share/history', queryParameters: {
      if (category != null) 'category': category,
      if (format != null) 'format': format,
      if (origin != null) 'origin': origin,
      if (status != null) 'status': status,
      if (q != null) 'q': q,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    final body = (resp.data as Map).cast<String, dynamic>();
    final rawRows = (body['rows'] as List? ?? []).cast<Map<String, dynamic>>();
    return (
      rows: rawRows.map(ImportHistoryRow.fromJson).toList(),
      nextCursor: body['next_cursor'] as String?,
    );
  }

  Future<Map<String, dynamic>> historyDetail(String id) async {
    final resp = await _api.get('/api/v1/share/history/$id');
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> retry(String id) async {
    final resp = await _api.post('/api/v1/share/history/$id/retry');
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<void> deleteOne(String id) async {
    await _api.delete('/api/v1/share/history/$id');
  }

  Future<void> clearAll() async {
    await _api.delete('/api/v1/share/history');
  }

  Future<int> bulkDelete(List<String> ids) async {
    final resp = await _api.post('/api/v1/share/history/bulk',
        data: {'action': 'delete', 'ids': ids});
    return ((resp.data as Map)['deleted'] as int?) ?? 0;
  }

  Future<int> bulkReclassify(List<String> ids) async {
    final resp = await _api.post('/api/v1/share/history/bulk',
        data: {'action': 'reclassify', 'ids': ids});
    return ((resp.data as Map)['reclassified'] as int?) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // SSE plumbing — uses Dio with ResponseType.stream + the existing
  // auth-interceptor so token refresh stays consistent with the rest of
  // the app. Each event is yielded as a parsed [ShareSseEvent].
  // ---------------------------------------------------------------------------

  Stream<ShareSseEvent> _sseRequest({
    required String path,
    required Map<String, dynamic> body,
  }) async* {
    try {
      final resp = await _api.post(
        '/api/v1$path',
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: const {'Accept': 'text/event-stream'},
        ),
      );
      final ResponseBody respBody = resp.data as ResponseBody;
      yield* _parseSse(respBody.stream);
    } on DioException catch (e) {
      yield ShareSseEvent({
        'stage': 'error',
        'http_status': e.response?.statusCode ?? 0,
        'message': 'Server returned ${e.response?.statusCode ?? 'no response'}',
      });
    }
  }

  Stream<ShareSseEvent> _sseMultipart({
    required String path,
    required String filePath,
    Map<String, String>? fields,
  }) async* {
    try {
      final form = FormData.fromMap({
        if (fields != null) ...fields,
        'file': await MultipartFile.fromFile(filePath, filename: _basename(filePath)),
      });
      final resp = await _api.post(
        '/api/v1$path',
        data: form,
        options: Options(
          responseType: ResponseType.stream,
          headers: const {'Accept': 'text/event-stream'},
        ),
      );
      final ResponseBody respBody = resp.data as ResponseBody;
      yield* _parseSse(respBody.stream);
    } on DioException catch (e) {
      yield ShareSseEvent({
        'stage': 'error',
        'http_status': e.response?.statusCode ?? 0,
        'message': 'Server returned ${e.response?.statusCode ?? 'no response'}',
      });
    }
  }

  Stream<ShareSseEvent> _parseSse(Stream<List<int>> bodyStream) async* {
    final decoder = utf8.decoder;
    final lineStream = bodyStream.transform(decoder).transform(const LineSplitter());
    final buffer = StringBuffer();
    await for (final line in lineStream) {
      if (line.isEmpty) {
        final raw = buffer.toString();
        buffer.clear();
        if (raw.isEmpty) continue;
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          yield ShareSseEvent(json);
        } catch (_) {
          // skip malformed
        }
        continue;
      }
      if (line.startsWith('data:')) {
        buffer.write(line.substring(5).trim());
      } else if (line.startsWith(':')) {
        // SSE comment — ignore
      }
    }
  }

  String _basename(String p) {
    final sep = Platform.pathSeparator;
    final i = p.lastIndexOf(sep);
    return i < 0 ? p : p.substring(i + 1);
  }
}

/// Riverpod provider for the imports API service.
final importsApiServiceProvider = Provider<ImportsApiService>((ref) {
  final api = ref.watch(apiClientProvider);
  return ImportsApiService(api);
});
