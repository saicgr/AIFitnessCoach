import 'package:flutter/foundation.dart';
import '../models/referral_summary.dart';
import '../services/api_client.dart';

class ReferralRepository {
  final ApiClient _client;
  ReferralRepository(this._client);

  Future<ReferralSummary> getSummary() async {
    try {
      final response = await _client.get('/xp/referrals/summary');
      return ReferralSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting referral summary: $e');
      rethrow;
    }
  }

  /// Apply a referral code. Returns the success flag + server message.
  Future<({bool success, String message, String? referrerId})> applyCode(String code) async {
    final response = await _client.post(
      '/xp/referrals/apply',
      data: {'code': code.toUpperCase()},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? '',
      referrerId: data['referrer_id'] as String?,
    );
  }
}
