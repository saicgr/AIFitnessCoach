import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Workstream 2 — week-1 cohort detection.
/// Powers Home rank card visibility + share prompt triggers.
/// Matches backend /users/me/cohort response (migration 1939).
@immutable
class UserCohort {
  final bool isWeek1;
  final int dayNumber;
  final DateTime? firstWorkoutAt;
  final DateTime? createdAt;

  const UserCohort({
    required this.isWeek1,
    required this.dayNumber,
    this.firstWorkoutAt,
    this.createdAt,
  });

  factory UserCohort.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) {
      if (v == null || v is! String || v.isEmpty) return null;
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }

    return UserCohort(
      isWeek1: json['is_week_1'] as bool? ?? false,
      dayNumber: json['day_number'] as int? ?? 0,
      firstWorkoutAt: parse(json['first_workout_at']),
      createdAt: parse(json['created_at']),
    );
  }

  static const empty = UserCohort(isWeek1: false, dayNumber: 0);
}

final userCohortProvider = FutureProvider<UserCohort>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/users/me/cohort');
    return UserCohort.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('userCohortProvider failed: $e');
    return UserCohort.empty;
  }
});

/// Convenience: true while user is in their first 7 days.
final isWeek1UserProvider = Provider<bool>((ref) {
  final cohort = ref.watch(userCohortProvider);
  return cohort.maybeWhen(data: (c) => c.isWeek1, orElse: () => false);
});
