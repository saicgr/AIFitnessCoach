-- Migration 1595: Classify exercises with NULL equipment
-- Assigns equipment values to ~725 exercises in exercise_library where equipment IS NULL.
-- Order matters: specific name patterns BEFORE general catch-alls.

-- ============================================================================
-- Group 1: body_part IS NULL (~274 exercises)
-- ============================================================================

-- Kettlebell exercises
UPDATE exercise_library SET equipment = 'Kettlebell' WHERE equipment IS NULL AND exercise_name ILIKE 'kettlebell%';

-- Dumbbell exercises
UPDATE exercise_library SET equipment = 'Dumbbells' WHERE equipment IS NULL AND (exercise_name ILIKE 'dumbbell%' OR exercise_name ILIKE 'dumbbells%');
UPDATE exercise_library SET equipment = 'Dumbbells' WHERE equipment IS NULL AND exercise_name ILIKE '%dumbbell%';

-- Barbell exercises
UPDATE exercise_library SET equipment = 'Barbell' WHERE equipment IS NULL AND exercise_name ILIKE 'barbell%';

-- Resistance band exercises
UPDATE exercise_library SET equipment = 'Resistance Band' WHERE equipment IS NULL AND (exercise_name ILIKE 'band %' OR exercise_name ILIKE 'banded %' OR exercise_name ILIKE '%resistance band%');

-- Cable exercises
UPDATE exercise_library SET equipment = 'Cable Machine' WHERE equipment IS NULL AND exercise_name ILIKE 'cable%';

-- Landmine exercises
UPDATE exercise_library SET equipment = 'Landmine' WHERE equipment IS NULL AND exercise_name ILIKE 'landmine%';

-- Foam Roller
UPDATE exercise_library SET equipment = 'Foam Roller' WHERE equipment IS NULL AND exercise_name ILIKE 'foam roller%';

-- Rebounder
UPDATE exercise_library SET equipment = 'Rebounder' WHERE equipment IS NULL AND exercise_name ILIKE 'rebounder%';

-- Battle Rope
UPDATE exercise_library SET equipment = 'Battle Ropes' WHERE equipment IS NULL AND exercise_name ILIKE 'battle rope%';

-- Ring exercises
UPDATE exercise_library SET equipment = 'Gymnastic Rings' WHERE equipment IS NULL AND exercise_name ILIKE '%ring dips%';

-- Agility Ladder
UPDATE exercise_library SET equipment = 'Agility Ladder' WHERE equipment IS NULL AND exercise_name ILIKE 'agility ladder%';

-- Medicine Ball
UPDATE exercise_library SET equipment = 'Medicine Ball' WHERE equipment IS NULL AND exercise_name ILIKE '%med ball%';

-- Slam Ball (Ball Slams)
UPDATE exercise_library SET equipment = 'Slam Ball' WHERE equipment IS NULL AND exercise_name ILIKE '%ball slam%';

-- Stair Climber
UPDATE exercise_library SET equipment = 'Stair Climber' WHERE equipment IS NULL AND exercise_name ILIKE 'stepmill%';

-- Treadmill
UPDATE exercise_library SET equipment = 'Treadmill' WHERE equipment IS NULL AND exercise_name ILIKE 'treadmill%';
UPDATE exercise_library SET equipment = 'Treadmill' WHERE equipment IS NULL AND exercise_name ILIKE 'walking fast%';

-- Hammer Strength machines
UPDATE exercise_library SET equipment = 'Machine' WHERE equipment IS NULL AND exercise_name ILIKE 'hammer strength%';

-- Push Pull machine
UPDATE exercise_library SET equipment = 'Machine' WHERE equipment IS NULL AND exercise_name ILIKE 'push pull%';

-- Svend Press needs weight plate
UPDATE exercise_library SET equipment = 'Weight Plate' WHERE equipment IS NULL AND exercise_name ILIKE 'svend press%';

-- ============================================================================
-- Group 2: body_part = 'Bodyweight' (~354 exercises)
-- ============================================================================

-- Exercise Ball exercises
UPDATE exercise_library SET equipment = 'Exercise Ball' WHERE equipment IS NULL AND exercise_name ILIKE 'exercise ball%';
UPDATE exercise_library SET equipment = 'Exercise Ball' WHERE equipment IS NULL AND exercise_name ILIKE '%stability ball%';
UPDATE exercise_library SET equipment = 'Exercise Ball' WHERE equipment IS NULL AND exercise_name ILIKE '%on stability ball%';

-- Bosu Ball
UPDATE exercise_library SET equipment = 'Bosu Ball' WHERE equipment IS NULL AND exercise_name ILIKE '%bosu%';

-- Bench exercises within bodyweight category
UPDATE exercise_library SET equipment = 'Bench' WHERE equipment IS NULL AND (exercise_name ILIKE 'bench %' OR exercise_name ILIKE 'decline bench%');

-- Hanging exercises need a pull-up bar
UPDATE exercise_library SET equipment = 'Pull-Up Bar' WHERE equipment IS NULL AND exercise_name ILIKE 'hanging%';

-- Dumbbell exercises mislabeled as bodyweight
UPDATE exercise_library SET equipment = 'Dumbbells' WHERE equipment IS NULL AND exercise_name ILIKE '%dumbbell%';

-- Resistance band within bodyweight
UPDATE exercise_library SET equipment = 'Resistance Band' WHERE equipment IS NULL AND exercise_name ILIKE '%resistance band%';

-- ============================================================================
-- Group 3: body_part = 'Resistance' (~85 exercises)
-- ============================================================================

-- Band exercises
UPDATE exercise_library SET equipment = 'Resistance Band' WHERE equipment IS NULL AND (exercise_name ILIKE 'band %' OR exercise_name ILIKE '%resistance band%');

-- Cable exercises
UPDATE exercise_library SET equipment = 'Cable Machine' WHERE equipment IS NULL AND exercise_name ILIKE 'cable%';

-- Machine exercises
UPDATE exercise_library SET equipment = 'Machine' WHERE equipment IS NULL AND exercise_name ILIKE '%machine%';
UPDATE exercise_library SET equipment = 'Machine' WHERE equipment IS NULL AND exercise_name ILIKE 'captains chair%';

-- Mislabeled bodyweight exercises in Resistance category
UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IS NULL AND exercise_name ILIKE 'mountain climbers%';
UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IS NULL AND exercise_name ILIKE 'lying leg raise%';
UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IS NULL AND exercise_name ILIKE 'middle crunches%';
UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IS NULL AND exercise_name ILIKE 'oblique crunch%';
UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IS NULL AND exercise_name ILIKE 'assisted sit ups%';
UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IS NULL AND exercise_name ILIKE '5 sec fist%';

-- ============================================================================
-- Group 4: body_part = 'Free Weights' (~12 exercises)
-- ============================================================================

UPDATE exercise_library SET equipment = 'Barbell' WHERE equipment IS NULL AND exercise_name ILIKE 'barbell%';
UPDATE exercise_library SET equipment = 'Barbell' WHERE equipment IS NULL AND exercise_name ILIKE 'chest bench press correct stance%';
UPDATE exercise_library SET equipment = 'Dumbbells' WHERE equipment IS NULL AND exercise_name ILIKE '%dumbbell%';
UPDATE exercise_library SET equipment = 'Medicine Ball' WHERE equipment IS NULL AND (exercise_name ILIKE '%medicine ball%' OR exercise_name ILIKE '%weighted ball%');
UPDATE exercise_library SET equipment = 'Trap Bar' WHERE equipment IS NULL AND exercise_name ILIKE 'trap bar%';
UPDATE exercise_library SET equipment = 'Weight Plate' WHERE equipment IS NULL AND exercise_name ILIKE 'plate%';

-- ============================================================================
-- Final catch-all: everything remaining is bodyweight (MUST BE LAST)
-- ============================================================================

UPDATE exercise_library SET equipment = 'Bodyweight' WHERE equipment IS NULL;
