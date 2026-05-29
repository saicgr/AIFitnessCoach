/// Repository layer for the Timeline aggregator endpoint.
///
/// Wraps `GET /api/v1/timeline?user_id=X&date=YYYY-MM-DD&days=N`. Backend
/// already caches at 60s TTL; we additionally cache the most-recent
/// response in memory so the home screen renders instantly when the user
/// returns from a sub-screen.
library;

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/timeline_entry.dart';
import '../services/api_client.dart';

class TimelineRepository {
  final ApiClient _apiClient;

  TimelineRepository(this._apiClient);

  /// Fetch the Timeline for `date` (defaults to today) covering `days`
  /// consecutive days back. Returns the parsed [TimelineResponse].
  Future<TimelineResponse> fetch({
    required String userId,
    String? date,
    int days = 1,
    int limit = 200,
    bool metricsOnly = false,
  }) async {
    try {
      final params = <String, dynamic>{
        'user_id': userId,
        'days': days,
        'limit': limit,
      };
      if (date != null) {
        params['date'] = date;
      }
      if (metricsOnly) {
        // Summaries-only: backend omits per-day `entries`, returning just the
        // `summary` rollups the Home trend rail needs over a 14-day window.
        params['metrics_only'] = true;
      }
      final response = await _apiClient.dio.get(
        ApiConstants.timeline,
        queryParameters: params,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TimelineResponse.fromJson(data);
      }
      throw Exception('Unexpected timeline payload shape');
    } on DioException {
      rethrow;
    }
  }

  /// Edit a Timeline entry via PATCH /events/{id}.
  Future<bool> editEntry({
    required String userId,
    required String eventId,
    required String domain,
    required Map<String, dynamic> patch,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.events}/$eventId',
        data: {'user_id': userId, 'domain': domain, 'patch': patch},
      );
      return response.statusCode == 200 && response.data['updated'] == true;
    } on DioException {
      return false;
    }
  }

  /// Delete a Timeline entry via DELETE /events/{id}.
  Future<bool> deleteEntry({
    required String userId,
    required String eventId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.events}/$eventId',
        queryParameters: {'user_id': userId},
      );
      return response.statusCode == 200 && response.data['deleted'] == true;
    } on DioException {
      return false;
    }
  }

  /// Undo a recent log via POST /events/undo with the signed token.
  Future<bool> undoEntry({
    required String userId,
    required String undoToken,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.events}/undo',
        data: {'user_id': userId, 'undo_token': undoToken},
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
