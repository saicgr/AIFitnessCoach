#!/usr/bin/env python3
"""Batch 4: HIIT (12) + Conditioning (10) + Quick Hit (20) + Mood Quick (12) + Fasted (15) = 69 programs."""

from exercise_lib import *


###############################################################################
# HIIT (12 programs)
###############################################################################

def sprint_intervals():
    return [workout("Sprint Intervals", "hiit", 25, [
        cardio_ex("Dynamic Warm-Up Jog", 120, "Easy pace to warm up", diff="beginner"),
        ex("Sprint", 8, 1, 30, "30 seconds max effort / 30 seconds walk",
           "Bodyweight", "Full Body", "Quadriceps",
           ["Glutes", "Hamstrings", "Calves", "Core"], "advanced",
           "Pump arms, drive knees high, full extension", "High Knees",
           duration_seconds=30),
        ex("Walking Recovery", 8, 1, 0, "30 seconds between sprints",
           "Bodyweight", "Full Body", "Cardiovascular",
           ["Calves"], "beginner",
           "Slow walk, controlled breathing", "March in Place",
           duration_seconds=30),
        cardio_ex("Cool-Down Walk", 180, "Slow pace, bring heart rate down", diff="beginner"),
    ])]


def bodyweight_hiit():
    return [workout("Bodyweight HIIT", "hiit", 25, [
        BURPEE(1, 10, 15),
        JUMP_SQUAT(3, 12, 20),
        MOUNTAIN_CLIMBER(3, 30, 15),
        HIGH_KNEES(3, 30, 15),
        PUSHUP(3, 12, 15),
        ex("Squat Thrust", 3, 10, 15, "Explosive pace",
           "Bodyweight", "Full Body", "Quadriceps",
           ["Core", "Shoulders"], "intermediate",
           "Drop to plank, jump feet back in, stand", "Burpee"),
        ex("Plank Jack", 3, 20, 15, "Fast pace",
           "Bodyweight", "Core", "Rectus Abdominis",
           ["Shoulders", "Hip Abductors"], "intermediate",
           "Plank position, jump feet wide and narrow", "Jumping Jacks"),
        JUMPING_LUNGE(3, 10, 15),
    ])]


def boxing_hiit():
    return [workout("Boxing HIIT", "hiit", 25, [
        ex("Jab-Cross Combo", 4, 1, 15, "30 seconds max effort",
           "Bodyweight", "Full Body", "Shoulders",
           ["Core", "Chest", "Triceps"], "intermediate",
           "Guard up, rotate hips, snap punches back", "Shadowboxing",
           duration_seconds=30),
        ex("Hook-Uppercut Combo", 4, 1, 15, "30 seconds",
           "Bodyweight", "Full Body", "Obliques",
           ["Shoulders", "Core", "Biceps"], "intermediate",
           "Pivot feet, rotate torso, short compact punches", "Shadowboxing",
           duration_seconds=30),
        ex("Bob and Weave", 4, 1, 15, "30 seconds",
           "Bodyweight", "Legs", "Quadriceps",
           ["Core", "Obliques"], "intermediate",
           "Bend knees, slip side to side, stay low", "Bodyweight Squat",
           duration_seconds=30),
        BURPEE(3, 8, 20),
        MOUNTAIN_CLIMBER(3, 30, 15),
        ex("Speed Punches", 3, 1, 15, "20 seconds max speed",
           "Bodyweight", "Full Body", "Shoulders",
           ["Core", "Triceps"], "beginner",
           "Light fast punches alternating, guard up", "High Knees",
           duration_seconds=20),
    ])]


def battle_rope_hiit():
    return [workout("Battle Rope HIIT", "hiit", 25, [
        BATTLE_ROPES(4, 1, 20),
        ex("Battle Rope Slams", 4, 1, 20, "30 seconds all-out",
           "Battle Ropes", "Full Body", "Shoulders",
           ["Core", "Back", "Arms"], "intermediate",
           "Raise ropes high, slam down with force, hinge hips", "Battle Ropes",
           duration_seconds=30),
        ex("Alternating Rope Waves", 4, 1, 20, "30 seconds",
           "Battle Ropes", "Full Body", "Shoulders",
           ["Core", "Arms"], "intermediate",
           "Alternate arms, create waves, stay athletic", "Battle Ropes",
           duration_seconds=30),
        ex("Rope Circles", 3, 1, 20, "30 seconds each direction",
           "Battle Ropes", "Full Body", "Shoulders",
           ["Core", "Forearms"], "intermediate",
           "Circle ropes outward then inward, engage core", "Battle Ropes",
           duration_seconds=30),
        JUMP_SQUAT(3, 10, 20),
        BURPEE(3, 6, 20),
    ])]


def staircase_hiit():
    return [workout("Staircase HIIT", "hiit", 25, [
        ex("Stair Sprint", 6, 1, 30, "Sprint up, walk down",
           "Bodyweight", "Legs", "Quadriceps",
           ["Calves", "Glutes", "Cardiovascular"], "intermediate",
           "Drive knees, pump arms, light on feet", "High Knees",
           duration_seconds=30),
        ex("Stair Two-Step", 4, 1, 30, "Take two steps at a time",
           "Bodyweight", "Legs", "Glutes",
           ["Quadriceps", "Hamstrings"], "intermediate",
           "Drive through heels, push off powerfully each step", "Step-Up",
           duration_seconds=30),
        ex("Stair Calf Raise", 3, 15, 20, "On stair edge",
           "Bodyweight", "Legs", "Calves",
           ["Tibialis Anterior"], "beginner",
           "Heels off edge, full stretch and squeeze", "Standing Calf Raise"),
        BODYWEIGHT_SQUAT(3, 15, 20),
        MOUNTAIN_CLIMBER(3, 30, 15),
    ])]


def rowing_hiit():
    return [workout("Rowing HIIT", "hiit", 25, [
        ex("Rowing Sprint", 6, 1, 30, "30 seconds max effort",
           "Rowing Machine", "Full Body", "Back",
           ["Legs", "Arms", "Core", "Cardiovascular"], "intermediate",
           "Legs-back-arms, fast powerful strokes", "Battle Ropes",
           duration_seconds=30),
        ex("Rowing Recovery", 6, 1, 0, "30 seconds easy pace",
           "Rowing Machine", "Full Body", "Back",
           ["Legs", "Core"], "beginner",
           "Slow controlled strokes, catch breath", "Walking",
           duration_seconds=30),
        BURPEE(3, 8, 20),
        PUSHUP(3, 12, 15),
        PLANK(2, 1, 15),
    ])]


def cycle_hiit():
    return [workout("Cycle HIIT", "hiit", 25, [
        ex("Cycling Sprint", 8, 1, 30, "30 seconds max effort, high resistance",
           "Stationary Bike", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings", "Calves", "Cardiovascular"], "intermediate",
           "Seated or standing, high cadence, push hard", "High Knees",
           duration_seconds=30),
        ex("Cycling Recovery", 8, 1, 0, "30 seconds low resistance",
           "Stationary Bike", "Legs", "Quadriceps",
           ["Calves"], "beginner",
           "Easy spin, control breathing", "Walking",
           duration_seconds=30),
        ex("Standing Climb", 4, 1, 20, "45 seconds high resistance",
           "Stationary Bike", "Legs", "Glutes",
           ["Quadriceps", "Hamstrings"], "intermediate",
           "Out of saddle, high resistance, grind up", "Step-Up",
           duration_seconds=45),
    ])]


def jump_rope_hiit():
    return [workout("Jump Rope HIIT", "hiit", 20, [
        JUMP_ROPE(4, 1, 20),
        ex("Double Unders", 4, 1, 20, "30 seconds or max reps",
           "Jump Rope", "Full Body", "Calves",
           ["Shoulders", "Core", "Cardiovascular"], "advanced",
           "Wrists spin fast, jump higher, rope passes twice", "Jump Rope",
           duration_seconds=30),
        ex("Jump Rope High Knees", 3, 1, 20, "30 seconds",
           "Jump Rope", "Full Body", "Hip Flexors",
           ["Calves", "Core", "Cardiovascular"], "intermediate",
           "Drive knees up with each jump, stay on balls of feet", "High Knees",
           duration_seconds=30),
        BURPEE(3, 8, 15),
        MOUNTAIN_CLIMBER(3, 30, 15),
    ])]


def medicine_ball_hiit():
    return [workout("Medicine Ball HIIT", "hiit", 25, [
        ex("Medicine Ball Slam", 4, 10, 20, "8-15 lb ball, explosive",
           "Medicine Ball", "Full Body", "Shoulders",
           ["Core", "Back", "Arms"], "intermediate",
           "Lift overhead, slam down hard, hinge at hips", "Battle Rope Slams"),
        ex("Med Ball Wall Throw", 4, 10, 20, "Explosive chest pass",
           "Medicine Ball", "Full Body", "Chest",
           ["Triceps", "Core", "Shoulders"], "intermediate",
           "Chest pass into wall, catch and repeat rapidly", "Push-Up"),
        ex("Med Ball Russian Twist", 3, 20, 15, "Per side",
           "Medicine Ball", "Core", "Obliques",
           ["Rectus Abdominis"], "intermediate",
           "Lean back, rotate ball side to side, feet elevated", "Russian Twist"),
        ex("Med Ball Squat Press", 3, 12, 20, "Squat then press overhead",
           "Medicine Ball", "Full Body", "Quadriceps",
           ["Shoulders", "Core", "Glutes"], "intermediate",
           "Deep squat, stand and press ball overhead explosively", "Thruster"),
        BURPEE(3, 8, 15),
        MOUNTAIN_CLIMBER(3, 30, 15),
    ])]


def sandbag_hiit():
    return [workout("Sandbag HIIT", "hiit", 25, [
        ex("Sandbag Clean and Press", 4, 8, 20, "Moderate weight",
           "Sandbag", "Full Body", "Shoulders",
           ["Legs", "Core", "Back"], "intermediate",
           "Deadlift up, clean to shoulder, press overhead", "Dumbbell Clean and Press"),
        ex("Sandbag Bear Hug Squat", 4, 10, 20, "Hug bag tight",
           "Sandbag", "Legs", "Quadriceps",
           ["Glutes", "Core", "Arms"], "intermediate",
           "Hug bag to chest, squat deep, drive through heels", "Goblet Squat"),
        ex("Sandbag Shoulder Carry", 3, 1, 30, "40 yards per side",
           "Sandbag", "Full Body", "Core",
           ["Shoulders", "Traps", "Glutes"], "intermediate",
           "Bag on one shoulder, tight core, quick steps", "Farmer's Walk",
           duration_seconds=30),
        ex("Sandbag Rotational Throw", 3, 8, 20, "Per side",
           "Sandbag", "Core", "Obliques",
           ["Shoulders", "Hips"], "intermediate",
           "Rotate and toss bag to side, pick up, repeat", "Russian Twist"),
        BURPEE(3, 6, 15),
    ])]


def trx_hiit():
    return [workout("TRX HIIT", "hiit", 25, [
        ex("TRX Jump Squat", 4, 10, 20, "Hold straps for balance",
           "TRX", "Legs", "Quadriceps",
           ["Glutes", "Calves"], "intermediate",
           "Squat deep, jump up, land soft using TRX for stability", "Jump Squat"),
        ex("TRX Atomic Push-Up", 3, 10, 20, "Feet in straps",
           "TRX", "Full Body", "Pectoralis Major",
           ["Core", "Hip Flexors", "Triceps"], "advanced",
           "Push-up then drive knees to chest while suspended", "Push-Up"),
        ex("TRX Row Sprint", 4, 12, 15, "Fast controlled reps",
           "TRX", "Back", "Rhomboids",
           ["Biceps", "Latissimus Dorsi"], "intermediate",
           "Lean back, pull chest to handles quickly, controlled lower", "Inverted Row"),
        ex("TRX Mountain Climber", 3, 30, 15, "Feet in straps",
           "TRX", "Core", "Core",
           ["Hip Flexors", "Shoulders"], "intermediate",
           "Drive knees alternately, keep hips level", "Mountain Climber"),
        ex("TRX Burpee", 3, 8, 20, "Feet in straps, advanced",
           "TRX", "Full Body", "Full Body",
           ["Chest", "Core", "Legs"], "advanced",
           "Push-up, jump feet to hands, stand, reverse", "Burpee"),
        PLANK(2, 1, 15),
    ])]


def dumbbell_hiit():
    return [workout("Dumbbell HIIT", "hiit", 25, [
        ex("Dumbbell Thruster", 4, 10, 20, "Moderate dumbbells",
           "Dumbbell", "Full Body", "Quadriceps",
           ["Shoulders", "Glutes", "Core"], "intermediate",
           "Front squat into overhead press in one fluid motion", "Goblet Squat to Press"),
        ex("Dumbbell Snatch", 4, 8, 20, "Per arm, moderate weight",
           "Dumbbell", "Full Body", "Shoulders",
           ["Glutes", "Hamstrings", "Core"], "intermediate",
           "Hinge, pull dumbbell floor to overhead in one motion", "Kettlebell Swing"),
        ex("Renegade Row", 3, 10, 20, "Per side",
           "Dumbbell", "Full Body", "Latissimus Dorsi",
           ["Core", "Chest", "Biceps"], "intermediate",
           "Plank with DBs, row one at a time, keep hips stable", "Dumbbell Row"),
        DB_LUNGE(3, 10, 15),
        PUSHUP(3, 12, 15),
        MOUNTAIN_CLIMBER(3, 30, 15),
    ])]


###############################################################################
# CONDITIONING (10 programs)
###############################################################################

def jump_rope_mastery():
    return [workout("Jump Rope Mastery", "conditioning", 30, [
        JUMP_ROPE(3, 1, 30),
        ex("Alternating Foot Jump", 3, 1, 30, "60 seconds",
           "Jump Rope", "Full Body", "Calves",
           ["Core", "Cardiovascular"], "beginner",
           "Like running in place with rope, light quick feet", "Jump Rope",
           duration_seconds=60),
        ex("Double Unders", 3, 1, 30, "30 seconds max reps",
           "Jump Rope", "Full Body", "Calves",
           ["Shoulders", "Core"], "advanced",
           "Jump higher, spin wrists faster, rope passes twice", "Jump Rope",
           duration_seconds=30),
        ex("Criss-Cross Jump Rope", 3, 1, 30, "30 seconds",
           "Jump Rope", "Full Body", "Shoulders",
           ["Core", "Calves", "Coordination"], "intermediate",
           "Cross arms at navel, jump through, uncross", "Jump Rope",
           duration_seconds=30),
        ex("Side Swing Jump", 3, 1, 30, "30 seconds",
           "Jump Rope", "Full Body", "Shoulders",
           ["Core", "Coordination"], "intermediate",
           "Swing rope to side, then jump on return", "Jump Rope",
           duration_seconds=30),
        BODYWEIGHT_SQUAT(3, 15, 20),
        CALF_RAISE(3, 15, 20),
    ])]


def battle_rope_conditioning():
    return [workout("Battle Rope Conditioning", "conditioning", 30, [
        BATTLE_ROPES(4, 1, 20),
        ex("Battle Rope Slams", 4, 1, 20, "30 seconds max power",
           "Battle Ropes", "Full Body", "Shoulders",
           ["Core", "Back", "Legs"], "intermediate",
           "Lift high, slam hard, hinge at hips each slam", "Battle Ropes",
           duration_seconds=30),
        ex("Battle Rope Snakes", 3, 1, 20, "30 seconds",
           "Battle Ropes", "Full Body", "Core",
           ["Shoulders", "Arms"], "intermediate",
           "Move ropes side to side creating snake pattern on floor", "Battle Ropes",
           duration_seconds=30),
        ex("Battle Rope Circles", 3, 1, 20, "30 seconds per direction",
           "Battle Ropes", "Full Body", "Shoulders",
           ["Core", "Forearms"], "intermediate",
           "Circle ropes outward, then inward", "Battle Ropes",
           duration_seconds=30),
        ex("Battle Rope Jumping Slams", 3, 1, 20, "30 seconds",
           "Battle Ropes", "Full Body", "Quadriceps",
           ["Shoulders", "Core", "Calves"], "advanced",
           "Jump and slam ropes at the same time", "Battle Rope Slams",
           duration_seconds=30),
        PLANK(3, 1, 15),
    ])]


def rowing_conditioning():
    return [workout("Rowing Conditioning", "conditioning", 35, [
        ROWING(1, 1, 60),
        ex("Rowing 500m Sprint", 4, 1, 90, "Max effort 500m",
           "Rowing Machine", "Full Body", "Back",
           ["Legs", "Arms", "Core", "Cardiovascular"], "intermediate",
           "Powerful leg drive, lean back, pull to chest", "Battle Ropes",
           duration_seconds=120),
        ex("Rowing Pyramid", 1, 1, 60, "1 min hard, 1 min easy, repeat increasing",
           "Rowing Machine", "Full Body", "Back",
           ["Legs", "Core", "Arms"], "intermediate",
           "Build intensity each round, maintain form", "Battle Ropes",
           duration_seconds=600),
        PUSHUP(3, 12, 20),
        PLANK(3, 1, 20),
    ])]


def sled_work():
    return [workout("Sled Work", "conditioning", 35, [
        SLED_PUSH(4, 1, 60),
        ex("Sled Pull", 4, 1, 60, "40 yards, moderate weight",
           "Sled", "Full Body", "Back",
           ["Biceps", "Glutes", "Hamstrings"], "intermediate",
           "Face sled, pull hand over hand, athletic stance", "Cable Row",
           duration_seconds=30),
        ex("Sled Drag", 3, 1, 60, "40 yards backward",
           "Sled", "Legs", "Quadriceps",
           ["Glutes", "Calves", "Core"], "intermediate",
           "Walk backward, short steps, chest up", "Walking Lunge",
           duration_seconds=30),
        ex("Sled Lateral Drag", 3, 1, 60, "20 yards each direction",
           "Sled", "Legs", "Hip Abductors",
           ["Glutes", "Quadriceps", "Core"], "intermediate",
           "Side shuffle while dragging sled, stay low", "Lateral Band Walk",
           duration_seconds=30),
        FARMER_WALK(3, 1, 45),
    ])]


def bear_crawl_conditioning():
    return [workout("Bear Crawl Conditioning", "conditioning", 30, [
        ex("Bear Crawl Forward", 4, 1, 30, "40 yards",
           "Bodyweight", "Full Body", "Core",
           ["Shoulders", "Quadriceps", "Hip Flexors"], "intermediate",
           "Knees hover, opposite hand and foot move together", "Mountain Climber",
           duration_seconds=30),
        ex("Bear Crawl Backward", 3, 1, 30, "40 yards",
           "Bodyweight", "Full Body", "Core",
           ["Shoulders", "Glutes"], "intermediate",
           "Reverse the pattern, look behind you, stay low", "Bear Crawl Forward",
           duration_seconds=30),
        ex("Lateral Bear Crawl", 3, 1, 30, "20 yards each direction",
           "Bodyweight", "Full Body", "Core",
           ["Shoulders", "Hip Abductors"], "intermediate",
           "Move sideways keeping knees low, stay stable", "Lateral Shuffle",
           duration_seconds=30),
        BURPEE(3, 8, 20),
        MOUNTAIN_CLIMBER(3, 30, 15),
        PLANK(3, 1, 15),
    ])]


def tire_flip_training():
    return [workout("Tire Flip Training", "conditioning", 35, [
        ex("Tire Flip", 5, 5, 60, "Heavy tire, explosive",
           "Tire", "Full Body", "Posterior Chain",
           ["Glutes", "Quadriceps", "Shoulders", "Core"], "advanced",
           "Deep squat grip under, drive with legs, flip over", "Deadlift"),
        ex("Tire Box Jump", 3, 8, 45, "Jump onto tire",
           "Tire", "Legs", "Quadriceps",
           ["Glutes", "Calves"], "intermediate",
           "Swing arms, land softly on tire, full hip extension", "Box Jump"),
        ex("Tire Sledgehammer Slam", 4, 10, 30, "Per side",
           "Tire", "Full Body", "Core",
           ["Shoulders", "Back", "Arms"], "intermediate",
           "Rotate and slam, alternate sides", "Medicine Ball Slam"),
        BURPEE(3, 8, 20),
        FARMER_WALK(3, 1, 30),
    ])]


def medicine_ball_conditioning():
    return [workout("Medicine Ball Conditioning", "conditioning", 30, [
        ex("Medicine Ball Slam", 4, 12, 20, "10-20 lb ball",
           "Medicine Ball", "Full Body", "Shoulders",
           ["Core", "Back", "Arms"], "intermediate",
           "Lift overhead, slam down hard, hinge and catch", "Battle Rope Slams"),
        ex("Med Ball Wall Ball", 4, 12, 20, "Target 10 ft mark",
           "Medicine Ball", "Full Body", "Quadriceps",
           ["Shoulders", "Glutes", "Core"], "intermediate",
           "Squat deep, throw ball high on wall, catch, repeat", "Thruster"),
        ex("Med Ball Rotational Throw", 3, 10, 20, "Per side",
           "Medicine Ball", "Core", "Obliques",
           ["Shoulders", "Hips"], "intermediate",
           "Rotate and throw into wall, catch, repeat", "Russian Twist"),
        ex("Med Ball Overhead Throw", 3, 10, 20, "Backward over head",
           "Medicine Ball", "Full Body", "Back",
           ["Shoulders", "Core", "Glutes"], "intermediate",
           "Squat, swing ball between legs, throw overhead backward", "Kettlebell Swing"),
        MOUNTAIN_CLIMBER(3, 30, 15),
    ])]


def agility_ladder_drills():
    return [workout("Agility Ladder Drills", "conditioning", 30, [
        ex("Ladder High Knees", 4, 1, 20, "Through ladder and back",
           "Agility Ladder", "Full Body", "Hip Flexors",
           ["Calves", "Core", "Cardiovascular"], "beginner",
           "One foot per box, drive knees, pump arms", "High Knees",
           duration_seconds=15),
        ex("Ladder Lateral Shuffle", 4, 1, 20, "Side to side through ladder",
           "Agility Ladder", "Legs", "Hip Abductors",
           ["Calves", "Quadriceps"], "beginner",
           "Stay low, quick feet in each box", "Lateral Shuffle",
           duration_seconds=15),
        ex("In-In-Out-Out", 4, 1, 20, "Ickey shuffle",
           "Agility Ladder", "Full Body", "Calves",
           ["Quadriceps", "Coordination"], "intermediate",
           "Two feet in, two feet out, move laterally", "Lateral Shuffle",
           duration_seconds=15),
        ex("Ladder Hop Scotch", 4, 1, 20, "Two feet in, one out each side",
           "Agility Ladder", "Legs", "Calves",
           ["Quadriceps", "Coordination", "Glutes"], "beginner",
           "Alternate wide and narrow stance through ladder", "Jumping Jacks",
           duration_seconds=15),
        ex("Ladder Carioca", 3, 1, 20, "Grapevine through ladder",
           "Agility Ladder", "Full Body", "Hip Abductors",
           ["Core", "Calves", "Coordination"], "intermediate",
           "Cross behind, step in box, cross in front", "Lateral Shuffle",
           duration_seconds=15),
        BODYWEIGHT_SQUAT(3, 15, 20),
    ])]


def speed_training():
    return [workout("Speed Training", "conditioning", 35, [
        ex("A-Skip", 3, 1, 20, "30 yards",
           "Bodyweight", "Legs", "Hip Flexors",
           ["Calves", "Quadriceps"], "beginner",
           "Skip with high knee drive, opposite arm, rhythmic", "High Knees",
           duration_seconds=15),
        ex("B-Skip", 3, 1, 20, "30 yards",
           "Bodyweight", "Legs", "Hamstrings",
           ["Hip Flexors", "Calves"], "intermediate",
           "High knee, extend and claw foot down, cycle legs", "A-Skip",
           duration_seconds=15),
        ex("Bounding", 3, 1, 30, "30 yards",
           "Bodyweight", "Legs", "Glutes",
           ["Quadriceps", "Calves", "Core"], "intermediate",
           "Exaggerated running strides, maximum distance each step", "Jump Squat",
           duration_seconds=15),
        ex("Acceleration Sprint", 5, 1, 60, "40 yards building speed",
           "Bodyweight", "Full Body", "Quadriceps",
           ["Glutes", "Hamstrings", "Calves"], "intermediate",
           "Low start, build to full speed, stay low first 10 yards", "Sprint",
           duration_seconds=15),
        ex("Lateral Sprint", 3, 1, 30, "20 yards each direction",
           "Bodyweight", "Legs", "Hip Abductors",
           ["Quadriceps", "Calves"], "intermediate",
           "Stay low, push off lateral foot, quick feet", "Lateral Shuffle",
           duration_seconds=15),
        BODYWEIGHT_SQUAT(3, 15, 20),
    ])]


def conditioning_circuit():
    return [workout("Conditioning Circuit", "conditioning", 40, [
        KETTLEBELL_SWING(3, 15, 30),
        BATTLE_ROPES(3, 1, 20),
        SLED_PUSH(3, 1, 30),
        FARMER_WALK(3, 1, 30),
        ex("Ball Slam", 3, 10, 20, "Medicine ball, explosive",
           "Medicine Ball", "Full Body", "Shoulders",
           ["Core", "Back"], "intermediate",
           "Lift overhead, slam down, hinge at hips", "Battle Rope Slams"),
        BURPEE(3, 8, 20),
        ROWING(1, 1, 30),
        PLANK(2, 1, 15),
    ])]


###############################################################################
# QUICK HIT (20 programs) - short targeted 15-30 min
###############################################################################

def quick_upper_pump():
    return [workout("Quick Upper Pump", "strength", 20, [
        PUSHUP(3, 15, 30),
        DB_ROW(3, 12, 30),
        DB_OHP(3, 10, 30),
        DB_CURL(3, 12, 30),
        TRICEP_PUSHDOWN(3, 12, 30),
        DB_LATERAL_RAISE(3, 15, 20),
    ])]


def express_chest_tris():
    return [workout("Express Chest & Tris", "strength", 20, [
        DB_BENCH(3, 12, 45),
        DB_INCLINE_PRESS(3, 10, 45),
        DB_FLY(3, 12, 30),
        DIAMOND_PUSHUP(3, 12, 30),
        TRICEP_PUSHDOWN(3, 12, 30),
        BENCH_DIP(3, 12, 20),
    ])]


def rapid_back_bis():
    return [workout("Rapid Back & Bis", "strength", 20, [
        LAT_PULLDOWN(3, 12, 45),
        DB_ROW(3, 10, 45),
        CABLE_ROW(3, 12, 30),
        FACE_PULL(3, 15, 20),
        DB_CURL(3, 12, 30),
        HAMMER_CURL(3, 10, 20),
    ])]


def shoulder_blaster_quick():
    return [workout("Shoulder Blaster Quick", "strength", 20, [
        DB_OHP(3, 10, 45),
        DB_LATERAL_RAISE(4, 15, 20),
        FACE_PULL(3, 15, 20),
        ARNOLD_PRESS(3, 10, 30),
        BAND_PULL_APART(3, 15, 15),
        ex("Front Raise", 3, 12, 20, "Light dumbbells",
           "Dumbbell", "Shoulders", "Anterior Deltoid",
           ["Lateral Deltoid"], "beginner",
           "Arms straight, raise to shoulder height, controlled lower", "Cable Front Raise"),
    ])]


def arm_day_express():
    return [workout("Arm Day Express", "strength", 20, [
        DB_CURL(3, 12, 30),
        TRICEP_PUSHDOWN(3, 12, 30),
        HAMMER_CURL(3, 10, 30),
        TRICEP_OVERHEAD(3, 12, 30),
        CONCENTRATION_CURL(3, 12, 20),
        DIAMOND_PUSHUP(3, 12, 20),
    ])]


def quick_leg_day():
    return [workout("Quick Leg Day", "strength", 20, [
        GOBLET_SQUAT(3, 12, 45),
        DB_RDL(3, 12, 45),
        DB_LUNGE(3, 10, 30),
        LEG_EXT(3, 12, 30),
        LEG_CURL(3, 12, 30),
        CALF_RAISE(3, 15, 20),
    ])]


def glute_express():
    return [workout("Glute Express", "strength", 20, [
        HIP_THRUST(3, 12, 45),
        BULGARIAN_SPLIT_SQUAT(3, 10, 45),
        CABLE_KICKBACK(3, 15, 20),
        GLUTE_BRIDGE(3, 15, 20),
        DONKEY_KICK(3, 15, 15),
        FIRE_HYDRANT(3, 15, 15),
    ])]


def quad_killer_quick():
    return [workout("Quad Killer Quick", "strength", 20, [
        LEG_PRESS(3, 12, 60),
        GOBLET_SQUAT(3, 12, 45),
        LEG_EXT(3, 15, 30),
        DB_LUNGE(3, 10, 30),
        WALL_SIT(3, 1, 20),
        JUMP_SQUAT(3, 10, 20),
    ])]


def hamstring_glute_rapid():
    return [workout("Hamstring & Glute Rapid", "strength", 20, [
        DB_RDL(3, 12, 45),
        LEG_CURL(3, 12, 30),
        HIP_THRUST(3, 12, 45),
        SINGLE_LEG_RDL(3, 10, 30),
        GLUTE_BRIDGE(3, 15, 20),
        DONKEY_KICK(3, 15, 15),
    ])]


def calf_core_combo():
    return [workout("Calf & Core Combo", "strength", 20, [
        CALF_RAISE(4, 15, 20),
        SEATED_CALF_RAISE(4, 15, 20),
        PLANK(3, 1, 15),
        BICYCLE_CRUNCH(3, 20, 15),
        HANGING_LEG_RAISE(3, 10, 30),
        RUSSIAN_TWIST(3, 20, 15),
    ])]


def twenty_min_full_body():
    return [workout("20-Minute Full Body", "strength", 20, [
        GOBLET_SQUAT(3, 12, 30),
        PUSHUP(3, 15, 30),
        DB_ROW(3, 10, 30),
        DB_OHP(3, 10, 30),
        DB_RDL(3, 12, 30),
        PLANK(2, 1, 15),
    ])]


def thirty_min_total_body():
    return [workout("30-Minute Total Body", "strength", 30, [
        BARBELL_SQUAT(3, 8, 60),
        BARBELL_BENCH(3, 8, 60),
        BARBELL_ROW(3, 8, 60),
        BARBELL_OHP(3, 8, 60),
        RDL(3, 8, 60),
        PLANK(2, 1, 15),
        CALF_RAISE(3, 15, 15),
    ])]


def express_compound_only():
    return [workout("Express Compound Only", "strength", 25, [
        DEADLIFT(1, 5, 120),
        BARBELL_SQUAT(3, 5, 90),
        BARBELL_BENCH(3, 5, 90),
        BARBELL_ROW(3, 5, 60),
        BARBELL_OHP(3, 5, 60),
    ])]


def metabolic_quick_hit():
    return [workout("Metabolic Quick Hit", "hiit", 20, [
        ex("Dumbbell Thruster", 3, 10, 15, "Moderate dumbbells",
           "Dumbbell", "Full Body", "Quadriceps",
           ["Shoulders", "Core", "Glutes"], "intermediate",
           "Front squat into overhead press, fluid motion", "Goblet Squat to Press"),
        ex("Renegade Row", 3, 10, 15, "Per side",
           "Dumbbell", "Full Body", "Latissimus Dorsi",
           ["Core", "Chest", "Biceps"], "intermediate",
           "Plank on DBs, row one then other, hips stable", "Dumbbell Row"),
        JUMP_SQUAT(3, 12, 15),
        BURPEE(3, 8, 15),
        MOUNTAIN_CLIMBER(3, 30, 10),
        PLANK(2, 1, 10),
    ])]


def dumbbell_only_express():
    return [workout("Dumbbell Only Express", "strength", 25, [
        GOBLET_SQUAT(3, 12, 30),
        DB_BENCH(3, 12, 30),
        DB_ROW(3, 10, 30),
        DB_OHP(3, 10, 30),
        DB_RDL(3, 12, 30),
        DB_CURL(3, 12, 20),
        DB_LATERAL_RAISE(3, 15, 15),
    ])]


def fifteen_min_hiit_blast():
    return [workout("15-Minute HIIT Blast", "hiit", 15, [
        BURPEE(3, 10, 15),
        JUMP_SQUAT(3, 12, 15),
        MOUNTAIN_CLIMBER(3, 30, 10),
        HIGH_KNEES(3, 30, 10),
        PUSHUP(3, 12, 10),
        JUMPING_LUNGE(3, 10, 10),
    ])]


def twenty_min_steady_state():
    return [workout("20-Minute Steady State", "cardio", 20, [
        cardio_ex("Brisk Walk Warm-Up", 120, "Moderate pace to warm up", diff="beginner"),
        ex("Steady State Jog", 1, 1, 0, "15 minutes moderate intensity",
           "Bodyweight", "Full Body", "Cardiovascular",
           ["Quadriceps", "Calves", "Glutes"], "beginner",
           "Conversational pace, rhythmic breathing, relax shoulders", "Brisk Walk",
           duration_seconds=900),
        cardio_ex("Cool-Down Walk", 180, "Slow pace, bring heart rate down", diff="beginner"),
    ])]


def tabata_express():
    return [workout("Tabata Express", "hiit", 16, [
        BURPEE(8, 1, 10),
        JUMP_SQUAT(8, 1, 10),
        MOUNTAIN_CLIMBER(8, 1, 10),
        HIGH_KNEES(8, 1, 10),
    ])]


def jump_rope_quick_burn():
    return [workout("Jump Rope Quick Burn", "cardio", 15, [
        JUMP_ROPE(4, 1, 15),
        ex("Double Unders", 3, 1, 20, "30 seconds",
           "Jump Rope", "Full Body", "Calves",
           ["Shoulders", "Core", "Cardiovascular"], "advanced",
           "Jump higher, spin rope twice under feet", "Jump Rope",
           duration_seconds=30),
        ex("Jump Rope Sprint", 3, 1, 20, "30 seconds max speed",
           "Jump Rope", "Full Body", "Calves",
           ["Cardiovascular", "Core"], "intermediate",
           "Maximum cadence, stay on balls of feet", "High Knees",
           duration_seconds=30),
        BODYWEIGHT_SQUAT(2, 15, 15),
    ])]


def stair_climber_sprint():
    return [workout("Stair Climber Sprint", "cardio", 20, [
        ex("Stair Climber Warm-Up", 1, 1, 0, "3 minutes easy pace",
           "Stair Climber", "Legs", "Quadriceps",
           ["Glutes", "Calves", "Cardiovascular"], "beginner",
           "Easy pace, find rhythm, relax upper body", "Walking",
           duration_seconds=180),
        ex("Stair Climber Interval", 6, 1, 30, "30 seconds fast / 30 seconds slow",
           "Stair Climber", "Legs", "Quadriceps",
           ["Glutes", "Calves", "Cardiovascular"], "intermediate",
           "Fast climbing, skip steps if possible, drive through heels", "Stair Sprint",
           duration_seconds=30),
        ex("Stair Climber Steady", 1, 1, 0, "5 minutes moderate",
           "Stair Climber", "Legs", "Quadriceps",
           ["Glutes", "Calves", "Cardiovascular"], "beginner",
           "Consistent pace, no holding rails, upright posture", "Walking",
           duration_seconds=300),
        ex("Cool-Down", 1, 1, 0, "2 minutes easy",
           "Stair Climber", "Legs", "Cardiovascular",
           ["Calves"], "beginner",
           "Slow pace, bring heart rate down", "Walking",
           duration_seconds=120),
    ])]


###############################################################################
# MOOD QUICK (12 programs)
###############################################################################

def anxious_do_this():
    return [workout("Anxious? Do This", "mindfulness", 20, [
        ex("4-7-8 Breathing", 3, 5, 10, "Inhale 4s, hold 7s, exhale 8s",
           "Bodyweight", "Full Body", "Diaphragm",
           ["Core", "Nervous System"], "beginner",
           "Slow inhale through nose, long exhale through mouth", "Box Breathing"),
        cardio_ex("Easy Walk", 300, "Slow calming walk, focus on surroundings", diff="beginner"),
        stretch("Neck Rolls", 30, "Neck", "Cervical Spine",
                "Slow circles each direction, release tension", "Chin Tuck"),
        stretch("Standing Forward Fold", 45, "Legs", "Hamstrings",
                "Let head hang heavy, bend knees if needed", "Seated Forward Fold"),
        CHILDS_POSE(),
        CAT_COW(),
        LEGS_UP_WALL(),
        SAVASANA(),
    ])]


def stressed_do_this():
    return [workout("Stressed? Do This", "hiit", 20, [
        ex("Heavy Bag Punches", 3, 1, 20, "30 seconds, release tension",
           "Bodyweight", "Full Body", "Shoulders",
           ["Core", "Chest", "Triceps"], "beginner",
           "Jab-cross combos, breathe with each punch", "Shadowboxing",
           duration_seconds=30),
        ex("Shadowboxing Combo", 3, 1, 20, "30 seconds all out",
           "Bodyweight", "Full Body", "Shoulders",
           ["Core", "Legs"], "beginner",
           "Hooks, uppercuts, movement, release stress", "Jumping Jacks",
           duration_seconds=30),
        BURPEE(3, 8, 20),
        MOUNTAIN_CLIMBER(3, 30, 15),
        ex("Box Breathing", 3, 4, 10, "Inhale 4s, hold 4s, exhale 4s, hold 4s",
           "Bodyweight", "Full Body", "Diaphragm",
           ["Core"], "beginner",
           "Equal counts in, hold, out, hold", "Deep Breathing"),
        CHILDS_POSE(),
    ])]


def angry_do_this():
    return [workout("Angry? Do This", "hiit", 20, [
        BURPEE(4, 10, 15),
        JUMP_SQUAT(4, 15, 15),
        ex("Sprawl", 3, 10, 15, "Explosive, all-out",
           "Bodyweight", "Full Body", "Full Body",
           ["Core", "Legs", "Chest"], "intermediate",
           "Like a burpee but spread wide at bottom, explosive up", "Burpee"),
        MOUNTAIN_CLIMBER(3, 40, 10),
        HIGH_KNEES(3, 40, 10),
        ex("Primal Scream Push-Up", 3, 12, 15, "Exhale forcefully on each rep",
           "Bodyweight", "Chest", "Pectoralis Major",
           ["Triceps", "Core"], "beginner",
           "Hard exhale on the push, channel aggression", "Push-Up"),
    ])]


def sad_do_this():
    return [workout("Sad? Do This", "cardio", 20, [
        JUMPING_JACK(3, 30, 15),
        HIGH_KNEES(3, 30, 15),
        ex("Dance Cardio", 3, 1, 15, "60 seconds, move to favorite song",
           "Bodyweight", "Full Body", "Cardiovascular",
           ["Core", "Legs"], "beginner",
           "Move freely, smile, let music drive you", "Jumping Jacks",
           duration_seconds=60),
        JUMP_SQUAT(3, 10, 15),
        PUSHUP(3, 10, 15),
        ex("Star Jumps", 3, 10, 15, "Explosive and fun",
           "Bodyweight", "Full Body", "Quadriceps",
           ["Shoulders", "Calves", "Cardiovascular"], "beginner",
           "Jump up, spread arms and legs wide like a star", "Jumping Jacks"),
        BODYWEIGHT_SQUAT(3, 15, 15),
        GLUTE_BRIDGE(3, 15, 15),
    ])]


def low_energy_do_this():
    return [workout("Low Energy? Do This", "cardio", 15, [
        cardio_ex("Light March in Place", 120, "Gently get blood moving", diff="beginner"),
        CAT_COW(),
        BODYWEIGHT_SQUAT(2, 10, 20),
        stretch("Standing Side Stretch", 30, "Core", "Obliques",
                "Reach overhead, lean to each side gently", "Seated Side Bend"),
        ex("Arm Circles", 2, 15, 10, "Forward and backward",
           "Bodyweight", "Shoulders", "Deltoids",
           ["Rotator Cuff"], "beginner",
           "Gradual circles, increase range progressively", "Band Pull-Apart"),
        GLUTE_BRIDGE(2, 12, 15),
        DOWNWARD_DOG(),
        COBRA(),
    ])]


def cant_sleep_do_this():
    return [workout("Can't Sleep? Do This", "mindfulness", 20, [
        ex("4-7-8 Breathing", 5, 3, 10, "Inhale 4s, hold 7s, exhale 8s",
           "Bodyweight", "Full Body", "Diaphragm",
           ["Core"], "beginner",
           "Slow, calming breath cycle for deep relaxation", "Box Breathing"),
        CHILDS_POSE(),
        PIGEON_POSE(),
        SEATED_FORWARD_FOLD(),
        HAPPY_BABY(),
        RECLINED_TWIST(),
        LEGS_UP_WALL(),
        SAVASANA(),
    ])]


def bad_day_burner():
    return [workout("Bad Day Burner Express", "hiit", 20, [
        BURPEE(4, 10, 15),
        JUMP_SQUAT(4, 12, 15),
        MOUNTAIN_CLIMBER(4, 30, 10),
        HIGH_KNEES(3, 30, 10),
        PUSHUP(3, 15, 15),
        ex("Squat Thrust", 3, 10, 15, "Max speed",
           "Bodyweight", "Full Body", "Quadriceps",
           ["Core", "Shoulders"], "intermediate",
           "Drop, kick back, jump in, stand, repeat fast", "Burpee"),
    ])]


def confidence_boost_quick():
    return [workout("Confidence Boost Quick", "strength", 20, [
        DB_BENCH(3, 12, 30),
        DB_OHP(3, 10, 30),
        DB_CURL(4, 12, 20),
        TRICEP_PUSHDOWN(3, 12, 20),
        PUSHUP(3, 15, 20),
        DB_LATERAL_RAISE(3, 15, 15),
    ])]


def overwhelmed_reset():
    return [workout("Overwhelmed Reset", "mindfulness", 15, [
        ex("Box Breathing", 5, 4, 10, "Inhale 4s, hold 4s, exhale 4s, hold 4s",
           "Bodyweight", "Full Body", "Diaphragm",
           ["Core"], "beginner",
           "Equal counts, find calm center", "Deep Breathing"),
        CAT_COW(),
        CHILDS_POSE(),
        DOWNWARD_DOG(),
        STANDING_FORWARD_FOLD(),
        stretch("Seated Spinal Twist", 30, "Core", "Obliques",
                "Twist gently, breathe into the stretch", "Reclined Twist"),
        SAVASANA(),
    ])]


def breakup_burn_session():
    return [workout("Breakup Burn Session", "hiit", 25, [
        BURPEE(4, 10, 15),
        JUMP_SQUAT(4, 15, 15),
        MOUNTAIN_CLIMBER(4, 40, 10),
        ex("Shadowboxing Fury", 3, 1, 15, "60 seconds all out",
           "Bodyweight", "Full Body", "Shoulders",
           ["Core", "Chest", "Legs"], "beginner",
           "Punch, move, sweat, let it all out", "Jumping Jacks",
           duration_seconds=60),
        HIGH_KNEES(3, 40, 10),
        PUSHUP(3, 15, 15),
        JUMPING_LUNGE(3, 12, 10),
    ])]


def monday_motivation_hit():
    return [workout("Monday Motivation Hit", "hiit", 20, [
        JUMPING_JACK(3, 30, 10),
        BURPEE(3, 8, 15),
        JUMP_SQUAT(3, 12, 15),
        PUSHUP(3, 15, 15),
        MOUNTAIN_CLIMBER(3, 30, 10),
        HIGH_KNEES(3, 30, 10),
        PLANK(2, 1, 10),
    ])]


def sunday_scaries_soother():
    return [workout("Sunday Scaries Soother", "mindfulness", 20, [
        cardio_ex("Gentle Walk", 300, "Slow, mindful walking", diff="beginner"),
        CAT_COW(),
        DOWNWARD_DOG(),
        WARRIOR_I(),
        WARRIOR_II(),
        TREE_POSE(),
        PIGEON_POSE(),
        CHILDS_POSE(),
        SAVASANA(),
    ])]


###############################################################################
# FASTED (15 programs)
###############################################################################

def fasted_cardio_16_8():
    return [workout("16:8 Fasted Cardio", "cardio", 30, [
        cardio_ex("Brisk Walk", 600, "Moderate pace, fat burning zone", diff="beginner"),
        cardio_ex("Light Jog", 600, "Easy pace, conversational", diff="beginner"),
        cardio_ex("Incline Walk", 600, "Treadmill incline or hill", diff="beginner"),
    ])]


def fasted_strength_16_8():
    return [workout("16:8 Fasted Strength", "strength", 35, [
        BARBELL_SQUAT(3, 8, 90),
        BARBELL_BENCH(3, 8, 90),
        BARBELL_ROW(3, 8, 90),
        DB_OHP(3, 10, 60),
        DB_CURL(3, 10, 45),
        PLANK(2, 1, 15),
    ])]


def fat_burner_18_6():
    return [workout("18:6 Fat Burner", "cardio", 30, [
        cardio_ex("Brisk Walk", 900, "Moderate pace, stay in fat-burning zone", diff="beginner"),
        BODYWEIGHT_SQUAT(3, 15, 30),
        DB_LUNGE(3, 10, 30),
        GLUTE_BRIDGE(3, 15, 20),
        cardio_ex("Cool-Down Walk", 300, "Easy pace, bring heart rate down", diff="beginner"),
    ])]


def warrior_workout_20_4():
    return [workout("20:4 Warrior Workout", "strength", 30, [
        GOBLET_SQUAT(3, 10, 60),
        PUSHUP(3, 12, 45),
        DB_ROW(3, 10, 45),
        DB_OHP(3, 10, 45),
        DB_RDL(3, 10, 45),
        PLANK(2, 1, 15),
    ])]


def omad_morning_burn():
    return [workout("OMAD Morning Burn", "cardio", 25, [
        cardio_ex("Brisk Walk", 600, "Easy to moderate pace", diff="beginner"),
        BODYWEIGHT_SQUAT(3, 12, 30),
        PUSHUP(3, 10, 30),
        GLUTE_BRIDGE(3, 12, 20),
        cardio_ex("Light Jog", 300, "Easy pace, don't overexert", diff="beginner"),
    ])]


def omad_evening_session():
    return [workout("OMAD Evening Session", "strength", 30, [
        GOBLET_SQUAT(3, 10, 60),
        DB_BENCH(3, 10, 60),
        DB_ROW(3, 10, 60),
        DB_LUNGE(3, 10, 45),
        DB_CURL(3, 10, 30),
        TRICEP_PUSHDOWN(3, 10, 30),
    ])]


def omad_strength_protocol():
    return [workout("OMAD Strength Protocol", "strength", 35, [
        BARBELL_SQUAT(3, 5, 120),
        BARBELL_BENCH(3, 5, 120),
        BARBELL_ROW(3, 5, 90),
        BARBELL_OHP(3, 5, 90),
        DEADLIFT(1, 5, 180),
    ])]


def fast_24h_workout():
    return [workout("24-Hour Fast Workout", "cardio", 25, [
        cardio_ex("Brisk Walk", 600, "Moderate pace, stay comfortable", diff="beginner"),
        BODYWEIGHT_SQUAT(2, 12, 30),
        PUSHUP(2, 10, 30),
        GLUTE_BRIDGE(2, 12, 20),
        cardio_ex("Easy Walk", 300, "Gentle pace", diff="beginner"),
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot on low surface, lean forward gently", "Seated Forward Fold"),
    ])]


def fast_36h_movement():
    return [workout("36-Hour Fast Movement", "cardio", 20, [
        cardio_ex("Gentle Walk", 600, "Easy comfortable pace", diff="beginner"),
        CAT_COW(),
        BODYWEIGHT_SQUAT(2, 10, 30),
        GLUTE_BRIDGE(2, 10, 20),
        DOWNWARD_DOG(),
        CHILDS_POSE(),
    ])]


def fast_48h_protocol():
    return [workout("48-Hour Fast Protocol", "mindfulness", 20, [
        cardio_ex("Slow Walk", 600, "Very easy pace, conserve energy", diff="beginner"),
        CAT_COW(),
        stretch("Seated Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Seated, reach toward toes gently", "Standing Forward Fold"),
        CHILDS_POSE(),
        DOWNWARD_DOG(),
        stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors",
                "Half kneeling, lean forward gently", "Pigeon Pose"),
        SAVASANA(),
    ])]


def fast_72h_gentle():
    return [workout("72-Hour Fast Gentle", "mindfulness", 15, [
        cardio_ex("Very Gentle Walk", 300, "Minimal exertion, just move", diff="beginner"),
        CAT_COW(),
        CHILDS_POSE(),
        stretch("Seated Spinal Twist", 30, "Core", "Obliques",
                "Very gentle twist, breathe slowly", "Reclined Twist"),
        LEGS_UP_WALL(),
        SAVASANA(),
    ])]


def fast_5day_light():
    return [workout("5-Day Fast Light Movement", "mindfulness", 15, [
        cardio_ex("Slow Walk", 300, "Very easy, just to stay mobile", diff="beginner"),
        stretch("Neck Stretch", 20, "Neck", "Cervical Spine",
                "Tilt ear to shoulder gently each side", "Chin Tuck"),
        stretch("Shoulder Roll", 20, "Shoulders", "Trapezius",
                "Roll shoulders forward and backward slowly", "Arm Circles"),
        CHILDS_POSE(),
        LEGS_UP_WALL(),
        SAVASANA(),
    ])]


def fast_7day_maintenance():
    return [workout("7-Day Fast Maintenance", "mindfulness", 15, [
        cardio_ex("Very Light Walk", 180, "Extremely easy, stay mobile", diff="beginner"),
        stretch("Ankle Circles", 20, "Ankles", "Ankle Joint",
                "Slow circles, maintain joint mobility", "Ankle Pumps"),
        stretch("Wrist Circles", 20, "Wrists", "Wrist Joint",
                "Slow circles both directions", "Wrist Flexion"),
        CHILDS_POSE(),
        SAVASANA(),
    ])]


def extended_fast_yoga():
    return [workout("Extended Fast Yoga", "mindfulness", 20, [
        CAT_COW(),
        CHILDS_POSE(),
        DOWNWARD_DOG(),
        COBRA(),
        PIGEON_POSE(),
        SEATED_FORWARD_FOLD(),
        HAPPY_BABY(),
        RECLINED_TWIST(),
        LEGS_UP_WALL(),
        SAVASANA(),
    ])]


def refeed_day_workout():
    return [workout("Refeed Day Workout", "strength", 40, [
        BARBELL_SQUAT(4, 8, 90),
        BARBELL_BENCH(4, 8, 90),
        BARBELL_ROW(4, 8, 90),
        BARBELL_OHP(3, 8, 60),
        DB_CURL(3, 12, 30),
        TRICEP_PUSHDOWN(3, 12, 30),
        LEG_EXT(3, 12, 30),
        PLANK(2, 1, 15),
    ])]


###############################################################################
# BATCH_WORKOUTS dict — maps program name → function returning list[workout]
###############################################################################

BATCH_WORKOUTS = {
    # HIIT (12)
    "Sprint Intervals": sprint_intervals,
    "Bodyweight HIIT": bodyweight_hiit,
    "Boxing HIIT": boxing_hiit,
    "Battle Rope HIIT": battle_rope_hiit,
    "Staircase HIIT": staircase_hiit,
    "Rowing HIIT": rowing_hiit,
    "Cycle HIIT": cycle_hiit,
    "Jump Rope HIIT": jump_rope_hiit,
    "Medicine Ball HIIT": medicine_ball_hiit,
    "Sandbag HIIT": sandbag_hiit,
    "TRX HIIT": trx_hiit,
    "Dumbbell HIIT": dumbbell_hiit,

    # Conditioning (10)
    "Jump Rope Mastery": jump_rope_mastery,
    "Battle Rope Conditioning": battle_rope_conditioning,
    "Rowing Conditioning": rowing_conditioning,
    "Sled Work": sled_work,
    "Bear Crawl Conditioning": bear_crawl_conditioning,
    "Tire Flip Training": tire_flip_training,
    "Medicine Ball Conditioning": medicine_ball_conditioning,
    "Agility Ladder Drills": agility_ladder_drills,
    "Speed Training": speed_training,
    "Conditioning Circuit": conditioning_circuit,

    # Quick Hit (20)
    "Quick Upper Pump": quick_upper_pump,
    "Express Chest & Tris": express_chest_tris,
    "Rapid Back & Bis": rapid_back_bis,
    "Shoulder Blaster Quick": shoulder_blaster_quick,
    "Arm Day Express": arm_day_express,
    "Quick Leg Day": quick_leg_day,
    "Glute Express": glute_express,
    "Quad Killer Quick": quad_killer_quick,
    "Hamstring & Glute Rapid": hamstring_glute_rapid,
    "Calf & Core Combo": calf_core_combo,
    "20-Minute Full Body": twenty_min_full_body,
    "30-Minute Total Body": thirty_min_total_body,
    "Express Compound Only": express_compound_only,
    "Metabolic Quick Hit": metabolic_quick_hit,
    "Dumbbell Only Express": dumbbell_only_express,
    "15-Minute HIIT Blast": fifteen_min_hiit_blast,
    "20-Minute Steady State": twenty_min_steady_state,
    "Tabata Express": tabata_express,
    "Jump Rope Quick Burn": jump_rope_quick_burn,
    "Stair Climber Sprint": stair_climber_sprint,

    # Mood Quick (12)
    "Anxious? Do This": anxious_do_this,
    "Stressed? Do This": stressed_do_this,
    "Angry? Do This": angry_do_this,
    "Sad? Do This": sad_do_this,
    "Low Energy? Do This": low_energy_do_this,
    "Can't Sleep? Do This": cant_sleep_do_this,
    "Bad Day Burner Express": bad_day_burner,
    "Confidence Boost Quick": confidence_boost_quick,
    "Overwhelmed Reset": overwhelmed_reset,
    "Breakup Burn Session": breakup_burn_session,
    "Monday Motivation Hit": monday_motivation_hit,
    "Sunday Scaries Soother": sunday_scaries_soother,

    # Fasted (15)
    "16:8 Fasted Cardio": fasted_cardio_16_8,
    "16:8 Fasted Strength": fasted_strength_16_8,
    "18:6 Fat Burner": fat_burner_18_6,
    "20:4 Warrior Workout": warrior_workout_20_4,
    "OMAD Morning Burn": omad_morning_burn,
    "OMAD Evening Session": omad_evening_session,
    "OMAD Strength Protocol": omad_strength_protocol,
    "24-Hour Fast Workout": fast_24h_workout,
    "36-Hour Fast Movement": fast_36h_movement,
    "48-Hour Fast Protocol": fast_48h_protocol,
    "72-Hour Fast Gentle": fast_72h_gentle,
    "5-Day Fast Light Movement": fast_5day_light,
    "7-Day Fast Maintenance": fast_7day_maintenance,
    "Extended Fast Yoga": extended_fast_yoga,
    "Refeed Day Workout": refeed_day_workout,
}
