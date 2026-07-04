-- ============================================================================
-- Migration 2302 — Program-finisher achievement types
-- ----------------------------------------------------------------------------
-- Seeds the three "you finished a program" trophies awarded by the workout
-- completion hook in api/v1/workouts/crud_completion.py (_award_program_finisher).
-- When a user completes their Nth program (user_program_assignments.status
-- flips to 'completed'), the hook awards exactly the tier whose threshold
-- equals the new completed-program count: 1st, 3rd, 5th.
--
-- user_achievements.achievement_id has an FK to achievement_types.id, so these
-- rows MUST exist before the hook fires — a missing row would raise an FK
-- violation inside the detached task (swallowed, but the trophy is lost).
--
-- Column list mirrors migration 162 (the expanded-achievements insert):
--   id, name, description, category, icon, tier, tier_level, points,
--   threshold_value, threshold_unit, xp_reward, sort_order.
-- Category 'consistency' matches the existing streak/habit family.
-- IDEMPOTENT: ON CONFLICT (id) DO NOTHING.
-- ============================================================================

INSERT INTO achievement_types (
    id, name, description, category, icon, tier, tier_level,
    points, threshold_value, threshold_unit, xp_reward, sort_order, is_repeatable
) VALUES
    (
        'program_finisher_1',
        'Finisher',
        'Complete your first training program from start to finish.',
        'consistency', '🏁', 'gold', 3,
        250, 1, 'programs', 500, 900, false
    ),
    (
        'program_finisher_3',
        'Serial Finisher',
        'Complete three training programs from start to finish.',
        'consistency', '🎖️', 'gold', 3,
        500, 3, 'programs', 750, 901, false
    ),
    (
        'program_finisher_5',
        'Program Veteran',
        'Complete five training programs from start to finish.',
        'consistency', '🏆', 'platinum', 4,
        1000, 5, 'programs', 1000, 902, false
    )
ON CONFLICT (id) DO NOTHING;
