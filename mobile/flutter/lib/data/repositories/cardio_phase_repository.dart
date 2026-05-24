import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Period-aware cardio intensity recommendation surfaced by
/// `GET /cardio/phase-recommendation`.
///
/// `recommendedIntensity` is null when the predictor is still calibrating
/// (first cycle / very low history) — the UI shows a softer "tracking
/// calibrating" state in that case. The whole payload is null when the
/// backend returns 204 (user opted out, pregnant, post-menopausal,
/// on hormonal contraceptives, or no hormonal profile) — render nothing.
@immutable
class PhaseRecommendation {
  /// Refined phase id: `menstrual`, `follicular`, `ovulation`,
  /// `early_luteal`, `late_luteal`, or `tracking calibration`.
  final String phase;

  /// `low` | `moderate` | `high` | null (calibration).
  final String? recommendedIntensity;
  final String rationale;
  final String evidenceCitation;
  final int? cycleDay;

  /// `low` | `moderate` | `high` — predictor confidence (advisory only).
  final String? confidence;

  const PhaseRecommendation({
    required this.phase,
    required this.recommendedIntensity,
    required this.rationale,
    required this.evidenceCitation,
    this.cycleDay,
    this.confidence,
  });

  bool get isCalibration => recommendedIntensity == null;

  /// Short, human-readable phase label for the inline banner.
  String get phaseLabel {
    switch (phase) {
      case 'menstrual':
        return 'Menstrual phase';
      case 'follicular':
        return 'Follicular phase';
      case 'ovulation':
        return 'Ovulation window';
      case 'early_luteal':
        return 'Early luteal phase';
      case 'late_luteal':
        return 'Late luteal phase';
      case 'tracking calibration':
        return 'Cycle tracking calibrating';
      default:
        return phase;
    }
  }

  factory PhaseRecommendation.fromJson(Map<String, dynamic> json) {
    return PhaseRecommendation(
      phase: json['phase'] as String? ?? 'unknown',
      recommendedIntensity: json['recommended_intensity'] as String?,
      rationale: json['rationale'] as String? ?? '',
      evidenceCitation: json['evidence_citation'] as String? ?? '',
      cycleDay: json['cycle_day'] as int?,
      confidence: json['confidence'] as String?,
    );
  }
}

/// Thin wrapper around `GET /cardio/phase-recommendation`. The backend
/// returns 204 when no banner should render — we surface that as `null`
/// so callers can write `if (rec == null) return SizedBox.shrink()`.
class CardioPhaseRepository {
  final ApiClient _api;
  CardioPhaseRepository(this._api);

  Future<PhaseRecommendation?> fetchToday() async {
    debugPrint('🩸 [CardioPhase] fetchToday');
    try {
      final resp = await _api.get('/cardio/phase-recommendation');
      // 204 = no banner (opted out / pregnant / post-menopause / no profile).
      if (resp.statusCode == 204) return null;
      if (resp.statusCode != 200) {
        debugPrint('⚠️ [CardioPhase] unexpected status ${resp.statusCode}');
        return null;
      }
      final data = resp.data;
      if (data == null || data is! Map) return null;
      return PhaseRecommendation.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      // Fail closed — never show a banner if the API hiccups. Cycle content
      // must never appear due to a misread; absence is the safe default.
      debugPrint('❌ [CardioPhase] fetch failed: $e');
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod
// ---------------------------------------------------------------------------

final cardioPhaseRepositoryProvider = Provider<CardioPhaseRepository>((ref) {
  return CardioPhaseRepository(ref.watch(apiClientProvider));
});

/// Once-per-day-per-user cached recommendation. `keepAlive` so cardio plan +
/// log-cardio start screens share the same fetch without re-hitting the API
/// on every mount; invalidated manually after a period-log change if needed.
final cardioPhaseRecommendationProvider =
    FutureProvider<PhaseRecommendation?>((ref) async {
  final repo = ref.watch(cardioPhaseRepositoryProvider);
  return repo.fetchToday();
});
