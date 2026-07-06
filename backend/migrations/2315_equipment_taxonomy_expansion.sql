-- Migration 2315: Equipment Taxonomy Expansion
-- Extends the equipment_types / equipment_substitutions taxonomy seeded in
-- migration 1594 with (A) canonical rows for equipment concepts that appear in
-- exercise_library's real equipment tags but had no canonical row yet, plus five
-- new specialty bars; (B) search/matching aliases appended to existing rows; and
-- (C) substitution edges linking the specialty bars back to a generic barbell.
--
-- Fully idempotent — safe to re-run. Matches 1594's schema exactly:
--   equipment_types(canonical_name, display_name, category, aliases,
--                   is_portable, requires_gym)  ON CONFLICT (canonical_name)
--   equipment_substitutions(source_equipment, target_equipment, compatibility,
--                   bidirectional, notes)        ON CONFLICT (source_equipment,
--                                                             target_equipment)

-- ============================================================================
-- A) New canonical equipment_types rows
-- ============================================================================
-- Machines require_gym=true / not portable (mirrors 1594's machine rows).
-- Accessories are portable / not gym-bound. Specialty bars mirror the existing
-- barbell/ez_bar/trap_bar rows (free_weights, not portable, not gym-required).
-- NOTE: hip_adductor_machine is a NEW row opposing the pre-existing
-- hip_abductor_machine (1594) — inner-thigh vs outer-hip, NOT merged.

INSERT INTO equipment_types (canonical_name, display_name, category, aliases, is_portable, requires_gym) VALUES
  -- Machines (concepts already tagged in exercise_library, no canonical row yet)
  ('ab_crunch_machine', 'Ab Crunch Machine', 'machines', '{ab crunch machine, abdominal crunch machine, crunch machine}', false, true),
  ('assisted_dip_machine', 'Assisted Dip Machine', 'machines', '{assisted dip machine, assisted dip, dip assist machine}', false, true),
  ('hip_adductor_machine', 'Hip Adductor Machine', 'machines', '{hip adductor machine, seated hip adductor, adductor machine, inner thigh machine}', false, true),
  ('lateral_raise_machine', 'Lateral Raise Machine', 'machines', '{lateral raise machine, lateral raise}', false, true),
  ('multi_hip_machine', 'Multi-Hip Machine', 'machines', '{multi hip machine, multi-hip machine, multi hip}', false, true),
  ('push_pull_machine', 'Push-Pull Machine', 'machines', '{push pull machine, push-pull machine}', false, true),

  -- Accessories
  ('grip_trainer', 'Grip Trainer', 'accessories', '{grip trainer, hand gripper, grip strengthener, gripper}', true, false),
  ('yoga_block', 'Yoga Block', 'accessories', '{yoga block, yoga blocks, cork block}', true, false),

  -- Specialty bars (free_weights) — barbell/ez_bar/trap_bar already exist
  ('safety_squat_bar', 'Safety Squat Bar', 'free_weights', '{ssb, safety bar, safety squat bar}', false, false),
  ('cambered_bar', 'Cambered Bar', 'free_weights', '{cambered bar, camber bar}', false, false),
  ('swiss_bar', 'Swiss Bar', 'free_weights', '{swiss bar, football bar, multi-grip bar, multi grip bar}', false, false),
  ('log_bar', 'Log Bar', 'free_weights', '{log bar, log press bar, strongman log}', false, false),
  ('olympic_barbell', 'Olympic Weightlifting Bar', 'free_weights', '{olympic weightlifting bar, oly bar, weightlifting bar}', false, false)
ON CONFLICT (canonical_name) DO NOTHING;

-- ============================================================================
-- B) Append search/matching aliases to EXISTING rows (idempotent array-append)
-- ============================================================================
-- rowing_machine currently: {rowing_machine}
UPDATE equipment_types
   SET aliases = aliases || ARRAY['rower', 'erg', 'ergometer']
 WHERE canonical_name = 'rowing_machine'
   AND NOT (aliases @> ARRAY['rower', 'erg', 'ergometer']);

-- ski_erg currently: {ski_erg, ski ergometer}
UPDATE equipment_types
   SET aliases = aliases || ARRAY['ski erg', 'erg']
 WHERE canonical_name = 'ski_erg'
   AND NOT (aliases @> ARRAY['ski erg', 'erg']);

-- exercise_ball currently: {stability ball, swiss ball, exercise ball} — already
-- has "stability ball", so this guarded append is a documented no-op (kept for
-- idempotent completeness in case the row is ever re-seeded without it).
UPDATE equipment_types
   SET aliases = aliases || ARRAY['stability ball']
 WHERE canonical_name = 'exercise_ball'
   AND NOT (aliases @> ARRAY['stability ball']);

-- ============================================================================
-- C) Specialty-bar → barbell substitution edges (bidirectional)
-- ============================================================================
-- A user with only a plain barbell should get partial substitution credit for
-- specialty-bar movements and vice versa. All referenced canonical_names exist
-- (trap_bar/ez_bar/barbell from 1594; the five new bars from section A above).
INSERT INTO equipment_substitutions (source_equipment, target_equipment, compatibility, bidirectional, notes) VALUES
  ('trap_bar', 'barbell', 0.75, true, 'Trap bar deadlift/shrug variants substitute reasonably for barbell versions'),
  ('ez_bar', 'barbell', 0.80, true, 'EZ bar curls/extensions substitute for straight-bar versions'),
  ('safety_squat_bar', 'barbell', 0.75, true, 'SSB squats substitute for barbell back squat with altered bar path'),
  ('cambered_bar', 'barbell', 0.75, true, 'Cambered bar squats/good mornings substitute for barbell versions'),
  ('swiss_bar', 'barbell', 0.70, true, 'Neutral-grip pressing substitutes for barbell bench/press'),
  ('log_bar', 'barbell', 0.65, true, 'Log press substitutes for barbell overhead press, different stability demand'),
  ('olympic_barbell', 'barbell', 0.95, true, 'Functionally near-identical to standard barbell for most lifts')
ON CONFLICT (source_equipment, target_equipment) DO NOTHING;
