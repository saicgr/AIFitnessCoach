import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Cardio training-load state (Gap 3) — server-computed Banister TRIMP +
/// Acute:Chronic Workload Ratio (ACWR) + a 5-state classification. Surfaced as
/// a home tracking pill and a tile in the Combined Health hub.
///
/// Display-only: ALL the math is done server-side in `training_load_service.py`
/// (`GET /training-load/current`). The client never computes load.
@immutable
class TrainingLoad {
  /// detraining | balanced | loading | overreaching | calibration
  final String state;
  final double dailyTrimp;
  final double acuteLoad;
  final double chronicLoad;
  final double? acwr;
  final String interpretation;
  final int daysOfHistory;

  const TrainingLoad({
    required this.state,
    required this.dailyTrimp,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.acwr,
    required this.interpretation,
    required this.daysOfHistory,
  });

  /// True while the user has < 14 days of history — the UI shows a
  /// "Building baseline" affordance rather than a state label/number.
  bool get isCalibrating => state == 'calibration';

  factory TrainingLoad.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
    return TrainingLoad(
      state: (json['state'] as String?) ?? 'calibration',
      dailyTrimp: d(json['daily_trimp']),
      acuteLoad: d(json['acute_load']),
      chronicLoad: d(json['chronic_load']),
      acwr: json['acwr'] == null ? null : (json['acwr'] as num).toDouble(),
      interpretation: (json['interpretation'] as String?) ?? '',
      daysOfHistory: (json['days_of_history'] as num?)?.toInt() ?? 0,
    );
  }

  /// Short human label for the pill/tile.
  String get label {
    switch (state) {
      case 'overreaching':
        return 'Overreaching';
      case 'loading':
        return 'Building';
      case 'balanced':
        return 'Balanced';
      case 'detraining':
        return 'Detraining';
      default:
        return 'Building baseline';
    }
  }
}

/// Fetches the latest training-load state from the backend.
///
/// Mirrors `recoveryProvider`: `autoDispose` + `keepAlive` so it survives tab
/// switches but recomputes on a full app refresh. Returns null on any error or
/// when the server has no row yet (a NORMAL state — the UI hides the tile).
final trainingLoadProvider =
    FutureProvider.autoDispose<TrainingLoad?>((ref) async {
  ref.keepAlive();
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response =
        await apiClient.get<Map<String, dynamic>>('/training-load/current');
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return TrainingLoad.fromJson(data);
  } catch (e) {
    debugPrint('❌ [TrainingLoadProvider] Error fetching training load: $e');
    return null;
  }
});
