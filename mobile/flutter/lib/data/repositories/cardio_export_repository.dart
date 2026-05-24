import 'dart:typed_data';

import 'package:dio/dio.dart' show Options, ResponseType;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Downloads a single cardio_log as GPX / TCX / FIT bytes from the backend
/// `GET /cardio-logs/{id}/export?format=…` endpoint. Tracks the suggested
/// filename via the Content-Disposition header so the share sheet shows
/// something sensible.
class CardioExportRepository {
  final ApiClient _client;
  CardioExportRepository(this._client);

  Future<CardioExportResult> download(String cardioLogId, String format) async {
    final res = await _client.dio.get<List<int>>(
      '/cardio-logs/$cardioLogId/export',
      queryParameters: {'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    final cd = res.headers.value('content-disposition') ?? '';
    final match = RegExp(r'filename="([^"]+)"').firstMatch(cd);
    final filename = match?.group(1) ?? 'cardio.$format';
    final mime = res.headers.value('content-type') ?? 'application/octet-stream';
    return CardioExportResult(bytes: bytes, filename: filename, mime: mime);
  }
}

class CardioExportResult {
  final Uint8List bytes;
  final String filename;
  final String mime;
  const CardioExportResult({
    required this.bytes,
    required this.filename,
    required this.mime,
  });
}

final cardioExportRepositoryProvider = Provider<CardioExportRepository>((ref) {
  return CardioExportRepository(ref.read(apiClientProvider));
});
