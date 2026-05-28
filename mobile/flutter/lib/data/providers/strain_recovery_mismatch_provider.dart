/// `strainRecoveryMismatchProvider` — 21-day strain trend vs recovery trend.
///
/// Backed by `GET /api/v1/insights/strain-recovery-mismatch`. Returns the
/// classified trend pair and whether a deload is recommended (strain "up"
/// while recovery is "flat" or "down").
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

class StrainRecoveryMismatchApi {
  final String strainTrend; // "up" | "flat" | "down"
  final String recoveryTrend; // "up" | "flat" | "down"
  final bool recommendDeload;
  final int weeksObserved;

  const StrainRecoveryMismatchApi({
    required this.strainTrend,
    required this.recoveryTrend,
    required this.recommendDeload,
    required this.weeksObserved,
  });

  factory StrainRecoveryMismatchApi.fromJson(Map<String, dynamic> json) {
    return StrainRecoveryMismatchApi(
      strainTrend: (json['strain_trend'] as String?) ?? 'flat',
      recoveryTrend: (json['recovery_trend'] as String?) ?? 'flat',
      recommendDeload: (json['recommend_deload'] as bool?) ?? false,
      weeksObserved: (json['weeks_observed'] as num?)?.toInt() ?? 3,
    );
  }
}

final strainRecoveryMismatchApiProvider =
    FutureProvider.autoDispose<StrainRecoveryMismatchApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, dynamic>>(
    '/insights/strain-recovery-mismatch',
  );
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const StrainRecoveryMismatchApi(
      strainTrend: 'flat',
      recoveryTrend: 'flat',
      recommendDeload: false,
      weeksObserved: 3,
    );
  }
  return StrainRecoveryMismatchApi.fromJson(data);
});
