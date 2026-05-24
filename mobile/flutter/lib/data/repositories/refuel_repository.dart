import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Refuel repository provider.
///
/// Wraps `GET /api/v1/cardio-refuel/{cardio_log_id}`. The endpoint may
/// return 204 No Content when no prescription is warranted (low-intensity
/// session or daily macros already met) — the repository converts that
/// (and any other "missing"-style response) to a plain `null`.
final refuelRepositoryProvider = Provider<RefuelRepository>((ref) {
  return RefuelRepository(ref.watch(apiClientProvider));
});

/// Loads the refuel prescription for a single cardio log id. `autoDispose`
/// + `family` so the data is bound to the screen showing it and refreshes
/// when the user navigates away and back.
final refuelPrescriptionProvider =
    FutureProvider.autoDispose.family<RefuelPrescription?, String>(
  (ref, cardioLogId) async {
    final repo = ref.watch(refuelRepositoryProvider);
    return repo.fetch(cardioLogId);
  },
);

/// Local DTO mirroring the backend `RefuelPrescription` pydantic model.
@immutable
class RefuelPrescription {
  final int waterMl;
  final int carbsG;
  final int proteinG;
  final int windowMinutes;
  final String rationale;

  const RefuelPrescription({
    required this.waterMl,
    required this.carbsG,
    required this.proteinG,
    required this.windowMinutes,
    required this.rationale,
  });

  factory RefuelPrescription.fromJson(Map<String, dynamic> json) {
    return RefuelPrescription(
      waterMl: (json['water_ml'] as num?)?.toInt() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toInt() ?? 0,
      windowMinutes: (json['window_minutes'] as num?)?.toInt() ?? 30,
      rationale: (json['rationale'] as String?) ?? '',
    );
  }
}

class RefuelRepository {
  final ApiClient _client;

  RefuelRepository(this._client);

  /// Returns the prescription, or null when the server says "nothing to
  /// recommend" (204) or the session is missing (404).
  Future<RefuelPrescription?> fetch(String cardioLogId) async {
    try {
      final response = await _client.get('/cardio-refuel/$cardioLogId');
      if (response.statusCode == 204 || response.data == null) {
        return null;
      }
      if (response.statusCode != 200) {
        debugPrint(
            '🥤 [Refuel] non-200 ${response.statusCode} for $cardioLogId');
        return null;
      }
      return RefuelPrescription.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      // 404 / 204 / network — silent: caller renders nothing.
      final code = e.response?.statusCode;
      if (code == 404 || code == 204) return null;
      debugPrint('🥤 [Refuel] error $code: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('🥤 [Refuel] unexpected: $e');
      return null;
    }
  }
}
