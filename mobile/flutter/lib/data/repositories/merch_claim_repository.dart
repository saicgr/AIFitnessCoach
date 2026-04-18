import 'package:flutter/foundation.dart';
import '../models/merch_claim.dart';
import '../services/api_client.dart';

/// Repository for physical merch claims earned at milestone levels.
class MerchClaimRepository {
  final ApiClient _client;

  MerchClaimRepository(this._client);

  /// Fetch all merch claims for the current user.
  Future<List<MerchClaim>> listClaims() async {
    final response = await _client.get('/xp/merch-claims');
    final data = response.data as Map<String, dynamic>;
    final list = (data['claims'] as List? ?? [])
        .map((j) => MerchClaim.fromJson(j as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// Accept the reward — ops will email the user to collect shipping details.
  Future<MerchClaim> accept(String claimId) async {
    try {
      final response = await _client.post('/xp/merch-claims/$claimId/accept');
      return MerchClaim.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error accepting merch claim: $e');
      rethrow;
    }
  }

  /// Cancel a pending merch claim.
  Future<MerchClaim> cancel(String claimId) async {
    try {
      final response = await _client.post('/xp/merch-claims/$claimId/cancel');
      return MerchClaim.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error cancelling merch claim: $e');
      rethrow;
    }
  }
}
