import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/user.dart';

void main() {
  group('WorkoutDayOverride.gymProfileId', () {
    test('round-trips gym_profile_id through toJson/fromJson', () {
      const o = WorkoutDayOverride(
        focus: 'upper_body',
        durationMin: 45,
        intensity: 'hard',
        gymProfileId: 'gym-1',
      );
      final json = o.toJson();
      expect(json['gym_profile_id'], 'gym-1');

      final back = WorkoutDayOverride.fromJson(json);
      expect(back.gymProfileId, 'gym-1');
      expect(back.focus, 'upper_body');
      expect(back.durationMin, 45);
      expect(back.intensity, 'hard');
    });

    test('omits gym_profile_id from json when null/empty (falls back to active gym)', () {
      const o = WorkoutDayOverride(focus: 'full_body');
      expect(o.toJson().containsKey('gym_profile_id'), isFalse);

      const o2 = WorkoutDayOverride(focus: 'full_body', gymProfileId: '');
      expect(o2.toJson().containsKey('gym_profile_id'), isFalse);
    });

    test('fromJson tolerates a missing gym_profile_id key', () {
      final back = WorkoutDayOverride.fromJson({'focus': 'legs'});
      expect(back.gymProfileId, isNull);
      expect(back.focus, 'legs');
    });

    test('copyWith sets and clears gymProfileId; equality reflects it', () {
      const base = WorkoutDayOverride(focus: 'push');
      final assigned = base.copyWith(gymProfileId: 'gym-2');
      expect(assigned.gymProfileId, 'gym-2');
      expect(assigned == base, isFalse); // props includes gymProfileId

      final cleared = assigned.copyWith(clearGymProfileId: true);
      expect(cleared.gymProfileId, isNull);
      expect(cleared, base);
    });
  });
}
