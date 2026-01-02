-- Skill Progression System Migration
-- Creates tables for tracking calisthenics skill progressions
-- Links exercises in progression order (beginner -> advanced)

-- ============================================
-- SCHEMA DEFINITIONS
-- ============================================

-- Skill Progression Chains table
-- Links exercises in progression order (beginner -> advanced)
CREATE TABLE IF NOT EXISTS exercise_progression_chains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,  -- e.g., "Pushup Mastery", "Handstand Journey"
    description TEXT,
    category VARCHAR(50),  -- pushup, pullup, squat, handstand, lever, planche
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual steps in a progression chain
CREATE TABLE IF NOT EXISTS exercise_progression_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chain_id UUID REFERENCES exercise_progression_chains(id) ON DELETE CASCADE,
    exercise_name VARCHAR(200) NOT NULL,
    step_order INTEGER NOT NULL,  -- 1, 2, 3, etc.
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 10),
    prerequisites TEXT,  -- JSON array of requirements
    unlock_criteria JSONB,  -- e.g., {"reps": 10, "sets": 3, "consecutive_sessions": 3}
    tips TEXT,
    video_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chain_id, step_order)
);

-- User's progress on each chain
CREATE TABLE IF NOT EXISTS user_skill_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chain_id UUID REFERENCES exercise_progression_chains(id) ON DELETE CASCADE,
    current_step_order INTEGER DEFAULT 1,
    unlocked_steps INTEGER[] DEFAULT ARRAY[1],  -- Array of unlocked step orders
    attempts_at_current INTEGER DEFAULT 0,
    best_reps_at_current INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_practiced_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, chain_id)
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_progression_steps_chain ON exercise_progression_steps(chain_id);
CREATE INDEX IF NOT EXISTS idx_progression_steps_order ON exercise_progression_steps(chain_id, step_order);
CREATE INDEX IF NOT EXISTS idx_user_skill_progress_user ON user_skill_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_skill_progress_chain ON user_skill_progress(chain_id);
CREATE INDEX IF NOT EXISTS idx_progression_chains_category ON exercise_progression_chains(category);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE exercise_progression_chains ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_progression_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skill_progress ENABLE ROW LEVEL SECURITY;

-- Public read for chains and steps (everyone can see available progressions)
DROP POLICY IF EXISTS "Anyone can read progression chains" ON exercise_progression_chains;
CREATE POLICY "Anyone can read progression chains" ON exercise_progression_chains FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can read progression steps" ON exercise_progression_steps;
CREATE POLICY "Anyone can read progression steps" ON exercise_progression_steps FOR SELECT USING (true);

-- Users can only manage their own progress
DROP POLICY IF EXISTS "Users manage own skill progress" ON user_skill_progress;
CREATE POLICY "Users manage own skill progress" ON user_skill_progress FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- SEED DATA: PROGRESSION CHAINS
-- ============================================

-- Clear existing data for clean seed (optional, comment out if you want to preserve existing data)
-- DELETE FROM user_skill_progress;
-- DELETE FROM exercise_progression_steps;
-- DELETE FROM exercise_progression_chains;

-- Insert Progression Chains
INSERT INTO exercise_progression_chains (id, name, description, category) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Pushup Mastery',
     'Progress from wall pushups to the legendary one-arm pushup. Build chest, shoulders, and triceps strength through progressive overload.',
     'pushup'),
    ('22222222-2222-2222-2222-222222222222', 'Pullup Journey',
     'Master the pullup from complete beginner to one-arm pullup. Develop back, biceps, and grip strength systematically.',
     'pullup'),
    ('33333333-3333-3333-3333-333333333333', 'Squat Progressions',
     'Build leg strength from assisted squats to the impressive pistol squat. Develop balance, mobility, and single-leg strength.',
     'squat'),
    ('44444444-4444-4444-4444-444444444444', 'Handstand Journey',
     'Progress from basic wall holds to freestanding handstand pushups. Develop shoulder strength, balance, and body control.',
     'handstand'),
    ('55555555-5555-5555-5555-555555555555', 'Muscle-Up Mastery',
     'Combine pulling and pushing strength to achieve the muscle-up. A milestone skill that demonstrates complete upper body control.',
     'muscle_up'),
    ('66666666-6666-6666-6666-666666666666', 'Front Lever Progressions',
     'Build the core and back strength needed for the front lever. One of the most impressive static holds in calisthenics.',
     'front_lever'),
    ('77777777-7777-7777-7777-777777777777', 'Planche Progressions',
     'The ultimate pushing strength skill. Progress through lean holds to achieve the full planche.',
     'planche')
ON CONFLICT DO NOTHING;

-- ============================================
-- SEED DATA: PUSHUP PROGRESSIONS (10 steps)
-- ============================================

INSERT INTO exercise_progression_steps (chain_id, exercise_name, step_order, difficulty_level, prerequisites, unlock_criteria, tips) VALUES
    -- Pushup Chain
    ('11111111-1111-1111-1111-111111111111', 'Wall Pushups', 1, 1,
     '["None - this is the starting point"]',
     '{"reps": 20, "sets": 3, "consecutive_sessions": 2}',
     'Stand arm''s length from the wall. Keep your body straight and core engaged. Focus on full range of motion.'),

    ('11111111-1111-1111-1111-111111111111', 'Incline Pushups', 2, 2,
     '["Wall Pushups: 20 reps x 3 sets"]',
     '{"reps": 15, "sets": 3, "consecutive_sessions": 3}',
     'Use a bench, stairs, or sturdy elevated surface. Lower the incline as you get stronger. Keep elbows at 45 degrees.'),

    ('11111111-1111-1111-1111-111111111111', 'Knee Pushups', 3, 2,
     '["Incline Pushups: 15 reps x 3 sets"]',
     '{"reps": 15, "sets": 3, "consecutive_sessions": 3}',
     'Cross your ankles and keep your hips in line with shoulders. Don''t let your lower back sag.'),

    ('11111111-1111-1111-1111-111111111111', 'Standard Pushups', 4, 3,
     '["Knee Pushups: 15 reps x 3 sets"]',
     '{"reps": 12, "sets": 3, "consecutive_sessions": 3}',
     'Hands shoulder-width apart, fingers spread. Lower until chest nearly touches ground. Full lockout at top.'),

    ('11111111-1111-1111-1111-111111111111', 'Diamond Pushups', 5, 4,
     '["Standard Pushups: 12 reps x 3 sets"]',
     '{"reps": 10, "sets": 3, "consecutive_sessions": 3}',
     'Hands together forming a diamond under your chest. Excellent triceps builder. Keep elbows close to body.'),

    ('11111111-1111-1111-1111-111111111111', 'Wide Pushups', 6, 4,
     '["Standard Pushups: 12 reps x 3 sets"]',
     '{"reps": 12, "sets": 3, "consecutive_sessions": 3}',
     'Hands wider than shoulder width. Great for chest development. Control the descent.'),

    ('11111111-1111-1111-1111-111111111111', 'Decline Pushups', 7, 5,
     '["Diamond Pushups: 10 reps x 3 sets", "Wide Pushups: 12 reps x 3 sets"]',
     '{"reps": 10, "sets": 3, "consecutive_sessions": 3}',
     'Feet elevated on bench or stairs. Targets upper chest and shoulders more. Keep core tight.'),

    ('11111111-1111-1111-1111-111111111111', 'Pike Pushups', 8, 6,
     '["Decline Pushups: 10 reps x 3 sets"]',
     '{"reps": 10, "sets": 3, "consecutive_sessions": 3}',
     'Hips high, body forms inverted V. Head goes forward between hands. Excellent handstand prep.'),

    ('11111111-1111-1111-1111-111111111111', 'Archer Pushups', 9, 7,
     '["Pike Pushups: 10 reps x 3 sets"]',
     '{"reps": 8, "sets": 3, "consecutive_sessions": 4}',
     'Wide hand placement. Lower to one side while extending the other arm. Alternate sides. One-arm pushup preparation.'),

    ('11111111-1111-1111-1111-111111111111', 'One-Arm Pushups', 10, 9,
     '["Archer Pushups: 8 reps each side x 3 sets"]',
     '{"reps": 5, "sets": 3, "consecutive_sessions": 5}',
     'Wide stance for balance. Keep hips level (don''t rotate). Free hand behind back or on hip. The ultimate pushing strength.')
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: PULLUP PROGRESSIONS (8 steps)
-- ============================================

INSERT INTO exercise_progression_steps (chain_id, exercise_name, step_order, difficulty_level, prerequisites, unlock_criteria, tips) VALUES
    -- Pullup Chain
    ('22222222-2222-2222-2222-222222222222', 'Dead Hang', 1, 1,
     '["None - this is the starting point"]',
     '{"hold_seconds": 30, "sets": 3, "consecutive_sessions": 2}',
     'Hang from bar with arms fully extended. Build grip strength and shoulder stability. Relax your shoulders away from ears initially.'),

    ('22222222-2222-2222-2222-222222222222', 'Scapular Pulls', 2, 2,
     '["Dead Hang: 30 seconds x 3 sets"]',
     '{"reps": 15, "sets": 3, "consecutive_sessions": 3}',
     'From dead hang, pull shoulder blades down and together without bending arms. Small movement, big impact on back strength.'),

    ('22222222-2222-2222-2222-222222222222', 'Assisted Pullups', 3, 3,
     '["Scapular Pulls: 15 reps x 3 sets"]',
     '{"reps": 10, "sets": 3, "consecutive_sessions": 3}',
     'Use resistance bands or machine for assistance. Focus on form: chin over bar, full extension at bottom. Reduce assistance over time.'),

    ('22222222-2222-2222-2222-222222222222', 'Negative Pullups', 4, 4,
     '["Assisted Pullups: 10 reps x 3 sets"]',
     '{"reps": 8, "sets": 3, "time_under_tension_seconds": 5, "consecutive_sessions": 3}',
     'Jump to top position, lower slowly (5+ seconds). Excellent strength builder. Control the entire descent.'),

    ('22222222-2222-2222-2222-222222222222', 'Full Pullups', 5, 5,
     '["Negative Pullups: 8 reps x 3 sets (5 sec each)"]',
     '{"reps": 8, "sets": 3, "consecutive_sessions": 3}',
     'Pull chin above bar, lower with control. No kipping. Squeeze shoulder blades at top. Full lockout at bottom.'),

    ('22222222-2222-2222-2222-222222222222', 'Wide Grip Pullups', 6, 6,
     '["Full Pullups: 8 reps x 3 sets"]',
     '{"reps": 8, "sets": 3, "consecutive_sessions": 4}',
     'Hands wider than shoulder width. Targets lats more. Pull to chest if possible for extra range.'),

    ('22222222-2222-2222-2222-222222222222', 'Archer Pullups', 7, 8,
     '["Wide Grip Pullups: 8 reps x 3 sets"]',
     '{"reps": 6, "sets": 3, "consecutive_sessions": 4}',
     'Wide grip, pull to one side while extending other arm along bar. Alternate sides. One-arm pullup preparation.'),

    ('22222222-2222-2222-2222-222222222222', 'One-Arm Pullups', 8, 10,
     '["Archer Pullups: 6 reps each side x 3 sets"]',
     '{"reps": 3, "sets": 3, "consecutive_sessions": 5}',
     'The holy grail of pulling strength. Use other hand on wrist, then forearm, then unassisted. Years of dedication required.')
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: SQUAT PROGRESSIONS (8 steps)
-- ============================================

INSERT INTO exercise_progression_steps (chain_id, exercise_name, step_order, difficulty_level, prerequisites, unlock_criteria, tips) VALUES
    -- Squat Chain
    ('33333333-3333-3333-3333-333333333333', 'Assisted Squats', 1, 1,
     '["None - this is the starting point"]',
     '{"reps": 20, "sets": 3, "consecutive_sessions": 2}',
     'Hold onto something stable for balance. Focus on depth and keeping knees tracking over toes. Sit back into heels.'),

    ('33333333-3333-3333-3333-333333333333', 'Bodyweight Squats', 2, 2,
     '["Assisted Squats: 20 reps x 3 sets"]',
     '{"reps": 20, "sets": 3, "consecutive_sessions": 3}',
     'Feet shoulder-width apart. Go as deep as your mobility allows. Arms forward for balance. Keep chest up.'),

    ('33333333-3333-3333-3333-333333333333', 'Sumo Squats', 3, 3,
     '["Bodyweight Squats: 20 reps x 3 sets"]',
     '{"reps": 15, "sets": 3, "consecutive_sessions": 3}',
     'Wide stance with toes pointed out. Great for hip mobility and inner thighs. Sink hips straight down.'),

    ('33333333-3333-3333-3333-333333333333', 'Bulgarian Split Squats', 4, 4,
     '["Bodyweight Squats: 20 reps x 3 sets"]',
     '{"reps": 12, "sets": 3, "consecutive_sessions": 3}',
     'Rear foot elevated on bench. Keep torso upright. Excellent single-leg strength builder. Control the descent.'),

    ('33333333-3333-3333-3333-333333333333', 'Jump Squats', 5, 5,
     '["Bodyweight Squats: 20 reps x 3 sets", "Bulgarian Split Squats: 12 reps x 3 sets"]',
     '{"reps": 15, "sets": 3, "consecutive_sessions": 3}',
     'Explosive jump from squat position. Land softly with bent knees. Builds power and athleticism.'),

    ('33333333-3333-3333-3333-333333333333', 'Shrimp Squats', 6, 7,
     '["Bulgarian Split Squats: 12 reps x 3 sets"]',
     '{"reps": 8, "sets": 3, "consecutive_sessions": 4}',
     'Hold rear foot behind you, squat until knee touches ground. Incredible quad strength. Start assisted if needed.'),

    ('33333333-3333-3333-3333-333333333333', 'Dragon Squats', 7, 9,
     '["Shrimp Squats: 8 reps x 3 sets"]',
     '{"reps": 5, "sets": 3, "consecutive_sessions": 4}',
     'One leg crosses behind the other, squat down. Requires extreme mobility and strength. Very advanced variation.'),

    ('33333333-3333-3333-3333-333333333333', 'Pistol Squats', 8, 8,
     '["Shrimp Squats: 8 reps x 3 sets"]',
     '{"reps": 5, "sets": 3, "consecutive_sessions": 5}',
     'Single leg squat with other leg extended forward. The gold standard of leg bodyweight exercises. Master assisted versions first.')
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: HANDSTAND PROGRESSIONS (8 steps)
-- ============================================

INSERT INTO exercise_progression_steps (chain_id, exercise_name, step_order, difficulty_level, prerequisites, unlock_criteria, tips) VALUES
    -- Handstand Chain
    ('44444444-4444-4444-4444-444444444444', 'Wall Plank Hold', 1, 2,
     '["None - this is the starting point"]',
     '{"hold_seconds": 60, "sets": 3, "consecutive_sessions": 3}',
     'Feet on wall, hands on floor, body forms 45-90 degree angle. Build shoulder stability. Hollow body position.'),

    ('44444444-4444-4444-4444-444444444444', 'Wall Walk', 2, 3,
     '["Wall Plank Hold: 60 seconds x 3 sets"]',
     '{"reps": 5, "sets": 3, "consecutive_sessions": 3}',
     'Start in pushup, walk feet up wall while walking hands closer. Go as vertical as comfortable. Control the descent.'),

    ('44444444-4444-4444-4444-444444444444', 'Chest-to-Wall Handstand', 3, 4,
     '["Wall Walk: 5 reps x 3 sets"]',
     '{"hold_seconds": 30, "sets": 3, "consecutive_sessions": 4}',
     'Face wall, hands 6 inches from wall. Stack shoulders over wrists. Straight body line. Good for alignment work.'),

    ('44444444-4444-4444-4444-444444444444', 'Back-to-Wall Handstand', 4, 5,
     '["Chest-to-Wall Handstand: 30 seconds x 3 sets"]',
     '{"hold_seconds": 30, "sets": 3, "consecutive_sessions": 4}',
     'Kick up with back to wall. Practice balance and finding alignment. Work on taking feet off wall briefly.'),

    ('44444444-4444-4444-4444-444444444444', 'Freestanding Handstand', 5, 7,
     '["Back-to-Wall Handstand: 30 seconds x 3 sets"]',
     '{"hold_seconds": 15, "sets": 5, "consecutive_sessions": 5}',
     'No wall support. Master the kick-up. Use fingers to balance (press for underbalance, lift for overbalance). Practice daily.'),

    ('44444444-4444-4444-4444-444444444444', 'Handstand Walking', 6, 8,
     '["Freestanding Handstand: 15 seconds x 5 sets"]',
     '{"steps": 10, "sets": 3, "consecutive_sessions": 5}',
     'Walk on hands maintaining balance. Shift weight side to side. Start with just a few steps and build up.'),

    ('44444444-4444-4444-4444-444444444444', 'Wall Handstand Pushups', 7, 8,
     '["Chest-to-Wall Handstand: 30 seconds x 3 sets", "Pike Pushups: 10 reps x 3 sets"]',
     '{"reps": 5, "sets": 3, "consecutive_sessions": 5}',
     'Lower head to floor and press back up. Use wall for balance. Full range of motion. Incredible shoulder strength builder.'),

    ('44444444-4444-4444-4444-444444444444', 'Freestanding Handstand Pushups', 8, 10,
     '["Freestanding Handstand: 15 seconds x 5 sets", "Wall Handstand Pushups: 5 reps x 3 sets"]',
     '{"reps": 3, "sets": 3, "consecutive_sessions": 5}',
     'The ultimate skill: handstand pushup without wall. Requires exceptional balance and strength. Elite level achievement.')
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: MUSCLE-UP PROGRESSIONS (6 steps)
-- ============================================

INSERT INTO exercise_progression_steps (chain_id, exercise_name, step_order, difficulty_level, prerequisites, unlock_criteria, tips) VALUES
    -- Muscle-Up Chain
    ('55555555-5555-5555-5555-555555555555', 'High Pullups', 1, 5,
     '["Full Pullups: 10 reps x 3 sets"]',
     '{"reps": 8, "sets": 3, "consecutive_sessions": 3}',
     'Pull until chest reaches bar level. Develops the pulling height needed for muscle-up. Strong lat activation.'),

    ('55555555-5555-5555-5555-555555555555', 'Explosive Pullups', 2, 6,
     '["High Pullups: 8 reps x 3 sets"]',
     '{"reps": 8, "sets": 3, "consecutive_sessions": 3}',
     'Pull as explosively as possible, release at top briefly. Build power. Hands should leave the bar momentarily.'),

    ('55555555-5555-5555-5555-555555555555', 'Chest-to-Bar Pullups', 3, 7,
     '["Explosive Pullups: 8 reps x 3 sets"]',
     '{"reps": 6, "sets": 3, "consecutive_sessions": 4}',
     'Pull until chest touches bar. Maximum range of motion. Essential muscle-up prerequisite.'),

    ('55555555-5555-5555-5555-555555555555', 'Kipping Muscle-Ups', 4, 8,
     '["Chest-to-Bar Pullups: 6 reps x 3 sets"]',
     '{"reps": 5, "sets": 3, "consecutive_sessions": 4}',
     'Use momentum from leg swing to assist transition. Learn the timing. Good entry point to muscle-ups.'),

    ('55555555-5555-5555-5555-555555555555', 'Slow Muscle-Ups', 5, 9,
     '["Kipping Muscle-Ups: 5 reps x 3 sets"]',
     '{"reps": 3, "sets": 3, "consecutive_sessions": 5}',
     'Minimal kip, controlled transition. Focus on the turning of wrists and pushing out of the bottom of dip.'),

    ('55555555-5555-5555-5555-555555555555', 'Strict Muscle-Ups', 6, 10,
     '["Slow Muscle-Ups: 3 reps x 3 sets"]',
     '{"reps": 3, "sets": 3, "consecutive_sessions": 5}',
     'Zero momentum, pure strength. The benchmark of calisthenics mastery. Requires exceptional pulling and transition strength.')
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: FRONT LEVER PROGRESSIONS (6 steps)
-- ============================================

INSERT INTO exercise_progression_steps (chain_id, exercise_name, step_order, difficulty_level, prerequisites, unlock_criteria, tips) VALUES
    -- Front Lever Chain
    ('66666666-6666-6666-6666-666666666666', 'Hanging Leg Raises', 1, 4,
     '["Dead Hang: 30 seconds x 3 sets", "Full Pullups: 5 reps"]',
     '{"reps": 12, "sets": 3, "consecutive_sessions": 3}',
     'Hang from bar, raise straight legs to horizontal or higher. Builds core strength needed for front lever. No swinging.'),

    ('66666666-6666-6666-6666-666666666666', 'Tuck Front Lever', 2, 5,
     '["Hanging Leg Raises: 12 reps x 3 sets"]',
     '{"hold_seconds": 15, "sets": 3, "consecutive_sessions": 4}',
     'Hang with knees tucked to chest, back parallel to ground. Straight arms, depressed shoulders. Foundation of front lever.'),

    ('66666666-6666-6666-6666-666666666666', 'Advanced Tuck Front Lever', 3, 6,
     '["Tuck Front Lever: 15 seconds x 3 sets"]',
     '{"hold_seconds": 12, "sets": 3, "consecutive_sessions": 4}',
     'Tuck position with knees further from chest. Hips should be at shoulder height. Increases leverage difficulty.'),

    ('66666666-6666-6666-6666-666666666666', 'Single Leg Front Lever', 4, 7,
     '["Advanced Tuck Front Lever: 12 seconds x 3 sets"]',
     '{"hold_seconds": 10, "sets": 3, "consecutive_sessions": 5}',
     'One leg extended, one tucked. Alternate legs. Big jump in difficulty. Focus on hip position.'),

    ('66666666-6666-6666-6666-666666666666', 'Straddle Front Lever', 5, 8,
     '["Single Leg Front Lever: 10 seconds each x 3 sets"]',
     '{"hold_seconds": 8, "sets": 3, "consecutive_sessions": 5}',
     'Both legs extended in straddle (wide V). Shortens lever arm. Keep body parallel to ground. Very advanced.'),

    ('66666666-6666-6666-6666-666666666666', 'Full Front Lever', 6, 10,
     '["Straddle Front Lever: 8 seconds x 3 sets"]',
     '{"hold_seconds": 5, "sets": 3, "consecutive_sessions": 5}',
     'Body completely straight and parallel to ground. Arms straight. One of the most impressive static holds. Years of training.')
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: PLANCHE PROGRESSIONS (6 steps)
-- ============================================

INSERT INTO exercise_progression_steps (chain_id, exercise_name, step_order, difficulty_level, prerequisites, unlock_criteria, tips) VALUES
    -- Planche Chain
    ('77777777-7777-7777-7777-777777777777', 'Planche Lean', 1, 4,
     '["Standard Pushups: 20 reps x 3 sets"]',
     '{"hold_seconds": 30, "sets": 3, "consecutive_sessions": 3}',
     'Pushup position, lean forward until shoulders are past wrists. Keep arms straight. Builds wrist and shoulder strength.'),

    ('77777777-7777-7777-7777-777777777777', 'Frog Stand', 2, 5,
     '["Planche Lean: 30 seconds x 3 sets"]',
     '{"hold_seconds": 30, "sets": 3, "consecutive_sessions": 4}',
     'Hands on floor, knees resting on elbows. Find balance point. Foundation for planche balance. Also called crow pose.'),

    ('77777777-7777-7777-7777-777777777777', 'Tuck Planche', 3, 6,
     '["Frog Stand: 30 seconds x 3 sets"]',
     '{"hold_seconds": 10, "sets": 3, "consecutive_sessions": 5}',
     'Knees tucked to chest, no contact with arms. Body horizontal. Straight arms essential. Major milestone.'),

    ('77777777-7777-7777-7777-777777777777', 'Advanced Tuck Planche', 4, 7,
     '["Tuck Planche: 10 seconds x 3 sets"]',
     '{"hold_seconds": 8, "sets": 3, "consecutive_sessions": 5}',
     'Knees away from chest, back more horizontal. Hips lower. Increased leverage demand. Prepare for leg extension.'),

    ('77777777-7777-7777-7777-777777777777', 'Straddle Planche', 5, 9,
     '["Advanced Tuck Planche: 8 seconds x 3 sets"]',
     '{"hold_seconds": 5, "sets": 3, "consecutive_sessions": 5}',
     'Legs extended in wide straddle. Massive shoulder and core strength needed. Elite level skill. Protract shoulders hard.'),

    ('77777777-7777-7777-7777-777777777777', 'Full Planche', 6, 10,
     '["Straddle Planche: 5 seconds x 3 sets"]',
     '{"hold_seconds": 3, "sets": 3, "consecutive_sessions": 5}',
     'Body completely straight, horizontal, arms straight. The pinnacle of pushing strength. Only achieved by dedicated athletes.')
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE exercise_progression_chains IS 'Defines skill progression chains that link exercises from beginner to advanced';
COMMENT ON TABLE exercise_progression_steps IS 'Individual exercises within a progression chain with difficulty and unlock criteria';
COMMENT ON TABLE user_skill_progress IS 'Tracks user progress through skill progression chains';

COMMENT ON COLUMN exercise_progression_chains.category IS 'Categories: pushup, pullup, squat, handstand, muscle_up, front_lever, planche';
COMMENT ON COLUMN exercise_progression_steps.unlock_criteria IS 'JSONB with keys like reps, sets, hold_seconds, consecutive_sessions, etc.';
COMMENT ON COLUMN user_skill_progress.unlocked_steps IS 'Array of step_order values that user has unlocked';
