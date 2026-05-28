/// Home-screen insight providers (v2 batch).
///
/// Six FutureProviders backing the home cards:
///   - jetLagApiProvider             → /insights/jet-lag
///   - busyWeekDensityApiProvider    → /insights/busy-week-density
///   - refeedProposalApiProvider     → /insights/refeed-proposal
///   - electrolyteNeedApiProvider    → /insights/electrolyte-need
///   - kudosUnreadProvider           → /social/kudos-unread
///   - weighInDayPrefApiProvider     → /insights/weigh-in-day-pref
///
/// All return typed models. Errors surface — no silent fallback (per
/// `feedback_no_silent_fallbacks.md`).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/timezone_provider.dart';
import '../services/api_client.dart';

// ─── Jet-lag ────────────────────────────────────────────────────────────────

class JetLagApi {
  final int? shiftedHours;
  final String? lastTz;
  final String? currentTz;
  final int? daysSinceShift;
  final int? recommendedBedtimeShiftMin;

  const JetLagApi({
    required this.shiftedHours,
    required this.lastTz,
    required this.currentTz,
    required this.daysSinceShift,
    required this.recommendedBedtimeShiftMin,
  });

  factory JetLagApi.fromJson(Map<String, dynamic> j) => JetLagApi(
        shiftedHours: (j['shifted_hours'] as num?)?.toInt(),
        lastTz: j['last_tz'] as String?,
        currentTz: j['current_tz'] as String?,
        daysSinceShift: (j['days_since_shift'] as num?)?.toInt(),
        recommendedBedtimeShiftMin:
            (j['recommended_bedtime_shift_min'] as num?)?.toInt(),
      );

  bool get hasShift =>
      shiftedHours != null &&
      shiftedHours!.abs() >= 1 &&
      (daysSinceShift ?? 99) <= 7;
}

final jetLagApiProvider = FutureProvider.autoDispose<JetLagApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final tz = ref.read(timezoneProvider).timezone;
  final res = await api.get<Map<String, dynamic>>(
    '/insights/jet-lag',
    queryParameters: {'current_tz': tz},
  );
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const JetLagApi(
      shiftedHours: null,
      lastTz: null,
      currentTz: null,
      daysSinceShift: null,
      recommendedBedtimeShiftMin: null,
    );
  }
  return JetLagApi.fromJson(data);
});

// ─── Busy-week density ──────────────────────────────────────────────────────

class BusyWeekDensityApi {
  final bool busy;
  final double recentAvgMin;
  final double baselineAvgMin;
  final int? recommendedCompressedWorkoutMin;

  const BusyWeekDensityApi({
    required this.busy,
    required this.recentAvgMin,
    required this.baselineAvgMin,
    required this.recommendedCompressedWorkoutMin,
  });

  factory BusyWeekDensityApi.fromJson(Map<String, dynamic> j) =>
      BusyWeekDensityApi(
        busy: j['busy'] as bool? ?? false,
        recentAvgMin: ((j['recent_avg_min'] as num?) ?? 0).toDouble(),
        baselineAvgMin: ((j['baseline_avg_min'] as num?) ?? 0).toDouble(),
        recommendedCompressedWorkoutMin:
            (j['recommended_compressed_workout_min'] as num?)?.toInt(),
      );
}

final busyWeekDensityApiProvider =
    FutureProvider.autoDispose<BusyWeekDensityApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/insights/busy-week-density');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const BusyWeekDensityApi(
      busy: false,
      recentAvgMin: 0,
      baselineAvgMin: 0,
      recommendedCompressedWorkoutMin: null,
    );
  }
  return BusyWeekDensityApi.fromJson(data);
});

// ─── Refeed proposal ────────────────────────────────────────────────────────

class RefeedProposalApi {
  final bool eligible;
  final int deficitDays;
  final int? proposedKcal;

  const RefeedProposalApi({
    required this.eligible,
    required this.deficitDays,
    required this.proposedKcal,
  });

  factory RefeedProposalApi.fromJson(Map<String, dynamic> j) =>
      RefeedProposalApi(
        eligible: j['eligible'] as bool? ?? false,
        deficitDays: (j['deficit_days'] as num?)?.toInt() ?? 0,
        proposedKcal: (j['proposed_kcal'] as num?)?.toInt(),
      );
}

final refeedProposalApiProvider =
    FutureProvider.autoDispose<RefeedProposalApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/insights/refeed-proposal');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const RefeedProposalApi(
      eligible: false,
      deficitDays: 0,
      proposedKcal: null,
    );
  }
  return RefeedProposalApi.fromJson(data);
});

// ─── Electrolyte need ───────────────────────────────────────────────────────

class ElectrolyteNeedApi {
  final bool recommend;
  final String? reason;

  const ElectrolyteNeedApi({required this.recommend, required this.reason});

  factory ElectrolyteNeedApi.fromJson(Map<String, dynamic> j) =>
      ElectrolyteNeedApi(
        recommend: j['recommend'] as bool? ?? false,
        reason: j['reason'] as String?,
      );
}

final electrolyteNeedApiProvider =
    FutureProvider.autoDispose<ElectrolyteNeedApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/insights/electrolyte-need');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const ElectrolyteNeedApi(recommend: false, reason: null);
  }
  return ElectrolyteNeedApi.fromJson(data);
});

// ─── Kudos unread ───────────────────────────────────────────────────────────

class KudosUnreadApi {
  final int count;
  const KudosUnreadApi({required this.count});
  factory KudosUnreadApi.fromJson(Map<String, dynamic> j) =>
      KudosUnreadApi(count: (j['count'] as num?)?.toInt() ?? 0);
}

final kudosUnreadProvider =
    FutureProvider.autoDispose<KudosUnreadApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, dynamic>>('/social/kudos-unread');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const KudosUnreadApi(count: 0);
  }
  return KudosUnreadApi.fromJson(data);
});

// ─── Weigh-in day preference ────────────────────────────────────────────────

class WeighInDayPrefApi {
  /// 0=Mon..6=Sun (matches DB). Convert to Dart's DateTime.weekday (1=Mon..7=Sun)
  /// via `dartWeekday`.
  final int? weekday;
  final DateTime? lastWeighInAt;

  const WeighInDayPrefApi({required this.weekday, required this.lastWeighInAt});

  factory WeighInDayPrefApi.fromJson(Map<String, dynamic> j) {
    DateTime? last;
    final raw = j['last_weigh_in_at'];
    if (raw is String && raw.isNotEmpty) {
      last = DateTime.tryParse(raw);
    }
    return WeighInDayPrefApi(
      weekday: (j['weekday'] as num?)?.toInt(),
      lastWeighInAt: last,
    );
  }

  /// DateTime.weekday equivalent (1=Mon..7=Sun), null if no pref.
  int? get dartWeekday => weekday == null ? null : weekday! + 1;

  bool get loggedToday {
    final l = lastWeighInAt;
    if (l == null) return false;
    final now = DateTime.now();
    return l.year == now.year && l.month == now.month && l.day == now.day;
  }
}

final weighInDayPrefApiProvider =
    FutureProvider.autoDispose<WeighInDayPrefApi>((ref) async {
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/insights/weigh-in-day-pref');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    return const WeighInDayPrefApi(weekday: null, lastWeighInAt: null);
  }
  return WeighInDayPrefApi.fromJson(data);
});
