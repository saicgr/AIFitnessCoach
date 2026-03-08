-- Migration 1596: Normalize equipment values in exercise_library
-- Consolidates ~96 distinct equipment strings to canonical display names,
-- then adds NOT NULL constraint with default.

-- ============================================================================
-- Bodyweight normalization
-- ============================================================================

UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IN ('bodyweight', 'body weight', 'Body Weight', 'None', 'none', '');

-- ============================================================================
-- Free Weights
-- ============================================================================

UPDATE exercise_library SET equipment = 'Kettlebell' WHERE equipment IN ('Kettlebells', 'kettlebells', 'kettlebell', 'Kettle Bell');
UPDATE exercise_library SET equipment = 'Dumbbells' WHERE equipment IN ('Dumbbell', 'dumbbell', 'dumbbells', 'Dumb Bell', 'dumb bell');
UPDATE exercise_library SET equipment = 'Barbell' WHERE equipment IN ('barbell', 'Bar Bell', 'Olympic Bar');
UPDATE exercise_library SET equipment = 'EZ Bar' WHERE equipment IN ('EZ-Bar', 'ez bar', 'ez-bar', 'Curl Bar');
UPDATE exercise_library SET equipment = 'Trap Bar' WHERE equipment IN ('trap bar', 'Hex Bar', 'hex bar');
UPDATE exercise_library SET equipment = 'Weight Plate' WHERE equipment IN ('Plate', 'plate', 'weight plate');

-- ============================================================================
-- Cables
-- ============================================================================

UPDATE exercise_library SET equipment = 'Cable Machine' WHERE equipment IN (
  'Cable', 'cable', 'Cable Pulley Machine', 'cable_machine',
  'Dual Cable Pulley Machine', 'Crossover machine', 'crossover machine',
  'Resistance Cable', 'Cable Pulley', 'cable pulley'
);

-- ============================================================================
-- Machines
-- ============================================================================

UPDATE exercise_library SET equipment = 'Lat Pulldown Machine' WHERE equipment IN ('lat_pulldown', 'Lat Pull Down Machine');
UPDATE exercise_library SET equipment = 'Leg Press Machine' WHERE equipment IN ('leg_press', 'Leg Press', 'leg press');
UPDATE exercise_library SET equipment = 'Leg Extension Machine' WHERE equipment IN ('leg_extension_machine', 'Lever Leg Extension');
UPDATE exercise_library SET equipment = 'Leg Curl Machine' WHERE equipment IN ('leg_curl_machine', 'Lying Leg Curl Machine', 'Seated Leg Curl Machine', 'Kneeling Leg Curl Machine');
UPDATE exercise_library SET equipment = 'Chest Press Machine' WHERE equipment IN ('chest_press_machine', 'Hammer Strength Chest Press');
UPDATE exercise_library SET equipment = 'Shoulder Press Machine' WHERE equipment IN ('shoulder_press_machine', 'Iso-Lateral Shoulder Press');
UPDATE exercise_library SET equipment = 'Smith Machine' WHERE equipment IN ('smith machine', 'smith_machine', 'Smith');
UPDATE exercise_library SET equipment = 'Hack Squat Machine' WHERE equipment IN ('hack_squat', 'Hack Squat');
UPDATE exercise_library SET equipment = 'Hip Abductor Machine' WHERE equipment IN ('Seated Hip Abductor', 'Multi Hip Machine');
UPDATE exercise_library SET equipment = 'Pec Fly Machine' WHERE equipment IN ('chest_fly_machine', 'Dual Pec Fly', 'Pec Deck', 'Dual Pec Deck', 'pec deck');
UPDATE exercise_library SET equipment = 'Assisted Pull-Up Machine' WHERE equipment IN ('assisted_pullup_machine', 'Assisted Pull Up Machine');
UPDATE exercise_library SET equipment = 'Seated Dip Machine' WHERE equipment IN ('Triceps Dips Machine', 'Triceps Extension Machine');
UPDATE exercise_library SET equipment = 'Seated Row Machine' WHERE equipment IN ('seated_row_machine', 'Cable Row Machine');

-- ============================================================================
-- Accessories
-- ============================================================================

UPDATE exercise_library SET equipment = 'Resistance Band' WHERE equipment IN ('Resistance Bands', 'resistance band', 'resistance_band', 'Band', 'band', 'Loop Resistance Band');
UPDATE exercise_library SET equipment = 'Exercise Ball' WHERE equipment IN ('Stability Ball', 'stability ball', 'Swiss Ball', 'swiss ball', 'exercise ball');
UPDATE exercise_library SET equipment = 'Bosu Ball' WHERE equipment IN ('bosu', 'bosu ball', 'BOSU');
UPDATE exercise_library SET equipment = 'Medicine Ball' WHERE equipment IN ('medicine ball', 'Med Ball', 'med ball', 'Weighted Ball');
UPDATE exercise_library SET equipment = 'Slam Ball' WHERE equipment IN ('slam ball', 'Ball Slam');
UPDATE exercise_library SET equipment = 'Foam Roller' WHERE equipment IN ('foam_roller', 'foam roller');
UPDATE exercise_library SET equipment = 'Ab Wheel' WHERE equipment IN ('ab_roller', 'Ab Roller', 'ab roller');
UPDATE exercise_library SET equipment = 'Jump Rope' WHERE equipment IN ('jump_rope', 'Skipping Rope', 'skipping rope');

-- ============================================================================
-- Bars and Racks
-- ============================================================================

UPDATE exercise_library SET equipment = 'Bench' WHERE equipment IN ('Flat Bench', 'flat bench', 'Incline Bench', 'Decline Bench');
UPDATE exercise_library SET equipment = 'Pull-Up Bar' WHERE equipment IN ('pull_up_bar', 'Pull Up Bar', 'pull up bar', 'Pullup Bar', 'pullup bar', 'Chin-Up Bar', 'chinup bar', 'Fixed Pole Bar');
UPDATE exercise_library SET equipment = 'Dip Station' WHERE equipment IN ('Dip Stand', 'dip stand', 'Dip Pull Up Station', 'Parallel Bar', 'parallel bar');

-- ============================================================================
-- Specialty
-- ============================================================================

UPDATE exercise_library SET equipment = 'Suspension Trainer' WHERE equipment IN ('TRX', 'trx', 'Suspension', 'suspension');
UPDATE exercise_library SET equipment = 'Battle Ropes' WHERE equipment IN ('Battle Rope', 'battle rope', 'battle_rope');
UPDATE exercise_library SET equipment = 'Gymnastic Rings' WHERE equipment IN ('Rings', 'rings', 'Ring', 'ring');
UPDATE exercise_library SET equipment = 'Plyo Box' WHERE equipment IN ('Step Box', 'step box', 'Plyometric Box');

-- ============================================================================
-- Cardio Equipment
-- ============================================================================

UPDATE exercise_library SET equipment = 'Treadmill' WHERE equipment IN ('treadmill');
UPDATE exercise_library SET equipment = 'Stationary Bike' WHERE equipment IN ('stationary_bike', 'Exercise Bike', 'exercise bike');
UPDATE exercise_library SET equipment = 'Rowing Machine' WHERE equipment IN ('rowing_machine', 'Rower');
UPDATE exercise_library SET equipment = 'Stair Climber' WHERE equipment IN ('stair_climber', 'Stepmill', 'stepmill');
UPDATE exercise_library SET equipment = 'Assault Bike' WHERE equipment IN ('assault_bike', 'Airbike', 'Air Bike', 'air bike');
UPDATE exercise_library SET equipment = 'Elliptical' WHERE equipment IN ('elliptical', 'Elliptical Machine');

-- ============================================================================
-- Add NOT NULL constraint (after all nulls classified and values normalized)
-- ============================================================================

ALTER TABLE exercise_library ALTER COLUMN equipment SET DEFAULT 'Bodyweight';
ALTER TABLE exercise_library ALTER COLUMN equipment SET NOT NULL;
