import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wrapped_data.dart';
import 'api_client.dart';

final wrappedServiceProvider = Provider<WrappedService>((ref) {
  return WrappedService(ref.read(apiClientProvider));
});

class WrappedService {
  final ApiClient _apiClient;

  WrappedService(this._apiClient);

  Future<WrappedData> getWrapped(String periodKey) async {
    try {
      final response = await _apiClient.get('/wrapped/$periodKey');
      debugPrint('✅ [Wrapped] Fetched wrapped data for $periodKey');
      return WrappedData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Wrapped] Error fetching wrapped data: $e');
      rethrow;
    }
  }

  Future<List<String>> getAvailablePeriods() async {
    try {
      final response = await _apiClient.get('/wrapped/available');
      final data = response.data as Map<String, dynamic>;
      debugPrint('✅ [Wrapped] Fetched available periods');
      return List<String>.from(data['periods'] as List);
    } catch (e) {
      debugPrint('❌ [Wrapped] Error fetching available periods: $e');
      rethrow;
    }
  }
}
