import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Dashboard repository provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

/// Repository for fetching the coach weekly dashboard data.
class DashboardRepository {
  final ApiClient _client;

  DashboardRepository(this._client);

  /// Fetch the weekly dashboard summary for a given user.
  ///
  /// When [quick] is true, only the fast subset (workout compliance, nutrition
  /// adherence, today's mood) is returned — measurements, active goals, and
  /// the full readiness sparkline come back empty. Use it to paint the top of
  /// the dashboard immediately, then follow up with a non-quick fetch to
  /// hydrate the rest.
  ///
  /// Returns the raw JSON map from `GET /dashboard/weekly/{user_id}`.
  Future<Map<String, dynamic>> getWeeklyDashboard(
    String userId, {
    bool quick = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiConstants.dashboard}/weekly/$userId',
        queryParameters: quick ? {'quick': 'true'} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint(
          '✅ [Dashboard] Fetched ${quick ? "quick" : "full"} dashboard for $userId',
        );
        return response.data!;
      }

      throw Exception('Unexpected status code: ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('❌ [Dashboard] Error fetching weekly dashboard: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }
}
