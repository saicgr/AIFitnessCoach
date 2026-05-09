/// Unit tests for the canonical muscle alias util (Issue 6 — post-
/// workout summary muscle highlighting). Verifies that:
/// 1. Core/Abdominals/Rectus Abdominis all canonicalize to 'Core'.
/// 2. Supabase exercise_library `body_part='waist'` rows
///    canonicalize to 'Core' (this was the production bug).
/// 3. `bodyAtlasIdsFor('Core')` returns the multi-segment rectus
///    abdominis + obliques IDs from the flutter_body_atlas package.
/// 4. Cardio + Other buckets return empty atlas-id lists.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/utils/muscle_aliases.dart';

void main() {
  group('canonicalMuscle', () {
    test('all Core synonyms collapse to Core', () {
      for (final raw in [
        'abs',
        'Abs',
        'ABDOMINALS',
        'rectus abdominis',
        'Rectus Abdominis',
        'transverse abdominis',
        'obliques',
        'lower abs',
        'upper abs',
        'core',
        'waist', // ← the production bug fix
      ]) {
        expect(canonicalMuscle(raw), 'Core', reason: 'input: $raw');
      }
    });

    test('Back synonyms collapse', () {
      for (final raw in ['lats', 'Latissimus Dorsi', 'middle back', 'traps', 'rhomboids']) {
        expect(canonicalMuscle(raw), 'Back', reason: 'input: $raw');
      }
    });

    test('Quads synonyms collapse', () {
      for (final raw in ['quads', 'quadriceps', 'rectus femoris', 'vastus lateralis']) {
        expect(canonicalMuscle(raw), 'Quads', reason: 'input: $raw');
      }
    });

    test('Glutes synonyms collapse', () {
      for (final raw in ['glutes', 'gluteus maximus', 'glute med', 'gluteus minimus']) {
        expect(canonicalMuscle(raw), 'Glutes', reason: 'input: $raw');
      }
    });

    test('parenthesized region (e.g. "Back (Latissimus Dorsi)") strips trailing parens', () {
      expect(canonicalMuscle('Back (Latissimus Dorsi)'), 'Back');
      expect(canonicalMuscle('Chest (Pectoralis Major)'), 'Chest');
    });

    test('empty / null-ish input returns Other', () {
      expect(canonicalMuscle(''), 'Other');
      expect(canonicalMuscle('   '), 'Other');
    });

    test('unknown muscle title-cases through', () {
      expect(canonicalMuscle('mystery muscle'), 'Mystery Muscle');
    });
  });

  group('bodyAtlasIdsFor', () {
    test('Core expands to rectus abdominis + obliques (front view)', () {
      final ids = bodyAtlasIdsFor('Core');
      expect(ids, contains('rectus_abdominis_1'));
      expect(ids, contains('rectus_abdominis_2_l'));
      expect(ids, contains('rectus_abdominis_4_r'));
      expect(ids, contains('external_oblique_l'));
      expect(ids, contains('external_oblique_8_r'));
      expect(ids.length, greaterThanOrEqualTo(20),
          reason: '7 rectus + 18 oblique segments expected');
    });

    test('Chest expands to pec major L + R', () {
      expect(bodyAtlasIdsFor('Chest'),
          containsAll(['pectoralis_major_l', 'pectoralis_major_r']));
    });

    test('Back expands to lats + traps (visible on back view)', () {
      final ids = bodyAtlasIdsFor('Back');
      expect(ids, contains('latissimus_dorsi_l'));
      expect(ids, contains('latissimus_dorsi_r'));
      expect(ids, contains('trapezius_middle_l'));
    });

    test('Cardio / Other / Full Body return empty (no atlas mapping)', () {
      expect(bodyAtlasIdsFor('Cardio'), isEmpty);
      expect(bodyAtlasIdsFor('Other'), isEmpty);
      expect(bodyAtlasIdsFor('Full Body'), isEmpty);
    });
  });

  group('isFrontMuscle / isBackMuscle', () {
    test('front-only muscles', () {
      expect(isFrontMuscle('Core'), true);
      expect(isFrontMuscle('Chest'), true);
      expect(isFrontMuscle('Quads'), true);
      expect(isFrontMuscle('Biceps'), true);
    });

    test('back-only muscles', () {
      expect(isBackMuscle('Hamstrings'), true);
      expect(isBackMuscle('Glutes'), true);
      expect(isBackMuscle('Calves'), true);
      expect(isBackMuscle('Triceps'), true);
    });

    test('shoulders straddle both views (anterior + posterior delts)', () {
      expect(isBackMuscle('Shoulders'), true);
      expect(isFrontMuscle('Shoulders'), false); // toggle still flips
    });
  });
}
