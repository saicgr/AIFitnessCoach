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
  /// Returns the raw JSON map from the backend endpoint
  /// `GET /dashboard/weekly/{user_id}`.
  Future<Map<String, dynamic>> getWeeklyDashboard(String userId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiConstants.dashboard}/weekly/$userId',
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ [Dashboard] Fetched weekly dashboard for $userId');
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
