import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// One Personal Best tile — the heaviest lift the user has ever logged.
class HeaviestLift {
  final String exerciseName;
  final double weightLb;
  final int reps;
  final String? date; // YYYY-MM-DD

  const HeaviestLift({
    required this.exerciseName,
    required this.weightLb,
    required this.reps,
    required this.date,
  });

  factory HeaviestLift.fromJson(Map<String, dynamic> json) {
    return HeaviestLift(
      exerciseName: json['exercise_name']?.toString() ?? 'Lift',
      weightLb: (json['weight_lb'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString(),
    );
  }
}

class LongestSession {
  final String workoutName;
  final int durationMinutes;
  final String? date;

  const LongestSession({
    required this.workoutName,
    required this.durationMinutes,
    required this.date,
  });

  factory LongestSession.fromJson(Map<String, dynamic> json) {
    return LongestSession(
      workoutName: json['workout_name']?.toString() ?? 'Workout',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString(),
    );
  }
}

class MostVolume {
  final String workoutName;
  final double totalVolumeLb;
  final String? date;

  const MostVolume({
    required this.workoutName,
    required this.totalVolumeLb,
    required this.date,
  });

  factory MostVolume.fromJson(Map<String, dynamic> json) {
    return MostVolume(
      workoutName: json['workout_name']?.toString() ?? 'Workout',
      totalVolumeLb: (json['total_volume_lb'] as num?)?.toDouble() ?? 0,
      date: json['date']?.toString(),
    );
  }
}

class PersonalBests {
  final HeaviestLift? heaviestLift;
  final LongestSession? longestSession;
  final MostVolume? mostVolume;

  const PersonalBests({
    this.heaviestLift,
    this.longestSession,
    this.mostVolume,
  });

  bool get isEmpty =>
      heaviestLift == null && longestSession == null && mostVolume == null;

  factory PersonalBests.fromJson(Map<String, dynamic> json) {
    final hl = json['heaviest_lift'];
    final ls = json['longest_session'];
    final mv = json['most_volume'];
    return PersonalBests(
      heaviestLift: hl is Map
          ? HeaviestLift.fromJson(hl.cast<String, dynamic>())
          : null,
      longestSession: ls is Map
          ? LongestSession.fromJson(ls.cast<String, dynamic>())
          : null,
      mostVolume: mv is Map
          ? MostVolume.fromJson(mv.cast<String, dynamic>())
          : null,
    );
  }
}

/// Personal Bests grid source. autoDispose so the cached reply isn't kept
/// after leaving the Badge Hub — refetch on next visit is cheap.
final personalBestsProvider =
    FutureProvider.autoDispose<PersonalBests>((ref) async {
  final userId = ref.watch(authStateProvider).user?.id;
  if (userId == null) return const PersonalBests();

  final api = ref.watch(apiClientProvider);
  try {
    final resp = await api.get('/personal_bests/$userId');
    if (resp.statusCode == 200 && resp.data is Map) {
      return PersonalBests.fromJson(
        (resp.data as Map).cast<String, dynamic>(),
      );
    }
  } catch (e) {
    debugPrint('personalBestsProvider error: $e');
  }
  return const PersonalBests();
});
