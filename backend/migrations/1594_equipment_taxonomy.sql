-- Migration 1594: Equipment Taxonomy
-- Creates equipment_types and equipment_substitutions tables,
-- seeds canonical equipment data, and adds a resolve_equipment_name() function.

-- ============================================================================
-- Table 1: equipment_types - canonical equipment definitions
-- ============================================================================

CREATE TABLE IF NOT EXISTS equipment_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canonical_name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  category TEXT NOT NULL,
  aliases TEXT[] DEFAULT '{}',
  is_portable BOOLEAN DEFAULT false,
  requires_gym BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index on category for filtered queries
CREATE INDEX IF NOT EXISTS idx_equipment_types_category ON equipment_types(category);

-- ============================================================================
-- Seed equipment_types
-- ============================================================================

INSERT INTO equipment_types (canonical_name, display_name, category, aliases, is_portable, requires_gym) VALUES
  -- Bodyweight
  ('bodyweight', 'Bodyweight', 'bodyweight', '{body weight, none, ""}', true, false),

  -- Free Weights
  ('dumbbells', 'Dumbbells', 'free_weights', '{dumbbell, dumb bell, db}', true, false),
  ('barbell', 'Barbell', 'free_weights', '{bar bell, olympic bar}', false, false),
  ('kettlebell', 'Kettlebell', 'free_weights', '{kettle bell, kb, kettlebells}', true, false),
  ('ez_bar', 'EZ Bar', 'free_weights', '{ez-bar, curl bar}', false, false),
  ('trap_bar', 'Trap Bar', 'free_weights', '{hex bar}', false, false),
  ('weight_plate', 'Weight Plate', 'free_weights', '{plate}', false, false),

  -- Cables
  ('cable_machine', 'Cable Machine', 'cables', '{cable, cable pulley, cable pulley machine, dual cable pulley machine, crossover machine, resistance cable}', false, true),

  -- Machines
  ('lat_pulldown', 'Lat Pulldown Machine', 'machines', '{lat pull down machine, lat_pulldown}', false, true),
  ('leg_press', 'Leg Press Machine', 'machines', '{leg_press, leg press machine}', false, true),
  ('leg_extension', 'Leg Extension Machine', 'machines', '{leg_extension_machine, lever leg extension}', false, true),
  ('leg_curl', 'Leg Curl Machine', 'machines', '{leg_curl_machine, lying leg curl machine, seated leg curl machine, kneeling leg curl machine}', false, true),
  ('chest_press_machine', 'Chest Press Machine', 'machines', '{chest_press_machine, hammer strength chest press}', false, true),
  ('shoulder_press_machine', 'Shoulder Press Machine', 'machines', '{shoulder_press_machine, iso-lateral shoulder press}', false, true),
  ('smith_machine', 'Smith Machine', 'machines', '{smith}', false, true),
  ('hack_squat', 'Hack Squat Machine', 'machines', '{hack_squat}', false, true),
  ('hip_abductor_machine', 'Hip Abductor Machine', 'machines', '{seated hip abductor, multi hip machine}', false, true),
  ('pec_fly_machine', 'Pec Fly Machine', 'machines', '{chest_fly_machine, dual pec fly, pec deck, dual pec deck}', false, true),
  ('assisted_pullup_machine', 'Assisted Pull-Up Machine', 'machines', '{assisted_pullup_machine, assisted pull up machine}', false, true),
  ('hyperextension_bench', 'Hyperextension Bench', 'machines', '{}', false, true),
  ('seated_dip_machine', 'Seated Dip Machine', 'machines', '{triceps dips machine, triceps extension machine}', false, true),
  ('seated_row_machine', 'Seated Row Machine', 'machines', '{seated_row_machine, cable row machine}', false, true),

  -- Accessories
  ('resistance_band', 'Resistance Band', 'accessories', '{band, loop resistance band, resistance bands}', true, false),
  ('exercise_ball', 'Exercise/Stability Ball', 'accessories', '{stability ball, swiss ball, exercise ball}', true, false),
  ('bosu_ball', 'Bosu Ball', 'accessories', '{bosu}', true, false),
  ('medicine_ball', 'Medicine Ball', 'accessories', '{med ball, weighted ball}', true, false),
  ('slam_ball', 'Slam Ball', 'accessories', '{ball slam}', true, false),
  ('foam_roller', 'Foam Roller', 'accessories', '{foam_roller}', true, false),
  ('ab_wheel', 'Ab Wheel', 'accessories', '{ab roller, ab_roller}', true, false),
  ('jump_rope', 'Jump Rope', 'accessories', '{jump_rope, skipping rope}', true, false),
  ('yoga_mat', 'Yoga Mat', 'accessories', '{}', true, false),

  -- Bars and Racks
  ('bench', 'Bench', 'bars_racks', '{flat bench, incline bench, decline bench}', false, false),
  ('pull_up_bar', 'Pull-Up Bar', 'bars_racks', '{pullup bar, chin-up bar, chinup bar, pull up bar, pull_up_bar, fixed pole bar}', true, false),
  ('dip_station', 'Dip Station', 'bars_racks', '{dip stand, dip pull up station, parallel bar}', false, false),
  ('landmine', 'Landmine', 'bars_racks', '{}', false, false),

  -- Specialty
  ('suspension_trainer', 'Suspension Trainer', 'specialty', '{trx, suspension}', true, false),
  ('battle_ropes', 'Battle Ropes', 'specialty', '{battle rope}', false, false),
  ('gymnastic_rings', 'Gymnastic Rings', 'specialty', '{rings, ring}', true, false),
  ('agility_ladder', 'Agility Ladder', 'specialty', '{}', true, false),
  ('box', 'Plyo Box', 'specialty', '{step box, plyometric box}', false, false),

  -- Unconventional
  ('sandbag', 'Sandbag', 'unconventional', '{}', true, false),
  ('tire', 'Tire', 'unconventional', '{}', false, false),
  ('sled', 'Sled', 'unconventional', '{}', false, false),

  -- Cardio Equipment
  ('treadmill', 'Treadmill', 'cardio_equipment', '{}', false, true),
  ('stationary_bike', 'Stationary Bike', 'cardio_equipment', '{stationary_bike, exercise bike}', false, true),
  ('rowing_machine', 'Rowing Machine', 'cardio_equipment', '{rowing_machine}', false, true),
  ('ski_erg', 'Ski Ergometer', 'cardio_equipment', '{ski_erg, ski ergometer}', false, true),
  ('elliptical', 'Elliptical', 'cardio_equipment', '{elliptical machine}', false, true),
  ('stair_climber', 'Stair Climber', 'cardio_equipment', '{stair_climber, stepmill}', false, true),
  ('assault_bike', 'Assault Bike', 'cardio_equipment', '{assault_bike, airbike, air bike}', false, true),
  ('rebounder', 'Rebounder', 'cardio_equipment', '{mini trampoline}', true, false)
ON CONFLICT (canonical_name) DO NOTHING;

-- ============================================================================
-- Table 2: equipment_substitutions - substitution pairs with compatibility
-- ============================================================================

CREATE TABLE IF NOT EXISTS equipment_substitutions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_equipment TEXT NOT NULL REFERENCES equipment_types(canonical_name),
  target_equipment TEXT NOT NULL REFERENCES equipment_types(canonical_name),
  compatibility FLOAT NOT NULL DEFAULT 0.7,
  bidirectional BOOLEAN DEFAULT true,
  notes TEXT,
  UNIQUE(source_equipment, target_equipment)
);

-- Index for lookups by source equipment
CREATE INDEX IF NOT EXISTS idx_equipment_subs_source ON equipment_substitutions(source_equipment);

-- ============================================================================
-- Seed equipment_substitutions
-- ============================================================================

INSERT INTO equipment_substitutions (source_equipment, target_equipment, compatibility, bidirectional, notes) VALUES
  ('kettlebell', 'dumbbells', 0.85, true, 'Most dumbbell moves work with KB'),
  ('dumbbells', 'kettlebell', 0.75, true, 'Some KB-specific moves don''t translate'),
  ('barbell', 'dumbbells', 0.70, true, 'Can usually substitute with 2 DBs'),
  ('cable_machine', 'resistance_band', 0.70, true, 'Similar movement patterns'),
  ('resistance_band', 'cable_machine', 0.70, true, 'Similar movement patterns'),
  ('exercise_ball', 'bodyweight', 0.50, true, 'Can do floor version instead'),
  ('bosu_ball', 'bodyweight', 0.50, true, 'Can do floor version instead'),
  ('bench', 'bodyweight', 0.40, true, 'Floor press instead of bench press'),
  ('medicine_ball', 'dumbbells', 0.60, true, 'Similar weight, different grip'),
  ('slam_ball', 'medicine_ball', 0.90, true, 'Nearly interchangeable'),
  ('pull_up_bar', 'resistance_band', 0.50, true, 'Band-assisted or band rows'),
  ('dip_station', 'bench', 0.60, true, 'Bench dips as alternative'),
  ('ab_wheel', 'bodyweight', 0.50, true, 'Plank walkouts as substitute'),
  ('foam_roller', 'bodyweight', 0.30, true, 'Manual stretching alternative'),
  ('suspension_trainer', 'resistance_band', 0.55, true, 'Similar bodyweight-plus patterns'),
  ('landmine', 'barbell', 0.80, true, 'Landmine IS a barbell setup'),
  ('box', 'bench', 0.70, true, 'Step-ups, box squats on bench')
ON CONFLICT (source_equipment, target_equipment) DO NOTHING;

-- ============================================================================
-- Function: resolve_equipment_name - fuzzy match raw name to canonical_name
-- ============================================================================

CREATE OR REPLACE FUNCTION resolve_equipment_name(raw_name TEXT)
RETURNS TEXT AS $$
  SELECT canonical_name FROM equipment_types
  WHERE canonical_name = lower(raw_name)
     OR lower(raw_name) = ANY(aliases)
     OR display_name ILIKE raw_name
  LIMIT 1;
$$ LANGUAGE sql STABLE;
