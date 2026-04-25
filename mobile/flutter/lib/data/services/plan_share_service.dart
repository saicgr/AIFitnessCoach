/// Plan / period share token API client.
///
/// Wraps `POST /api/v1/plans/share-link` and friends. Used by the Workout
/// tab share button, AI chat share-artifact tool, and the home More tile.
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class PlanShareLinkResponse {
  final String url;
  final String token;
  final String scope;
  final String period;
  final String startDate;
  final String endDate;
  final String deepLink;

  PlanShareLinkResponse({
    required this.url,
    required this.token,
    required this.scope,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.deepLink,
  });

  factory PlanShareLinkResponse.fromJson(Map<String, dynamic> j) {
    return PlanShareLinkResponse(
      url: j['url'] as String,
      token: j['token'] as String,
      scope: (j['scope'] as String?) ?? 'plan',
      period: j['period'] as String,
      startDate: j['start_date'] as String,
      endDate: j['end_date'] as String,
      deepLink: (j['deep_link'] as String?) ?? '',
    );
  }
}

class PlanShareService {
  final ApiClient _api;

  PlanShareService(this._api);

  /// Create a public plan-share token. `period` is one of
  /// day | week | month | ytd | custom. `startDate` defaults to today
  /// (or anchor for week/month). `endDate` is required only for custom.
  Future<PlanShareLinkResponse?> create({
    required String period,
    String scope = 'plan',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'period': period,
        'scope': scope,
        if (startDate != null) 'start_date': _ymd(startDate),
        if (endDate != null) 'end_date': _ymd(endDate),
      };
      final res = await _api.dio.post('/api/v1/plans/share-link', data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return PlanShareLinkResponse.fromJson(data);
      }
      if (data is Map) {
        return PlanShareLinkResponse.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      debugPrint('plan share link failed: $e');
      return null;
    }
  }

  /// Revoke an existing token. Returns true on success.
  Future<bool> revoke(String token) async {
    try {
      final res = await _api.dio.delete('/api/v1/plans/share-link/$token');
      return res.statusCode != null && res.statusCode! < 400;
    } catch (e) {
      debugPrint('plan share revoke failed: $e');
      return false;
    }
  }

  static String _ymd(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
