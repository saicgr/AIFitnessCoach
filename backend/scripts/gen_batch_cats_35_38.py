#!/usr/bin/env python3
"""Generate programs for categories 35-38: Cardio, Strongman, Outdoor, Longevity."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

def ex(name, sets, reps, rest, weight, equip, body, muscle, secondary, diff, cue, sub):
    return {"name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": weight, "equipment": equip, "body_part": body,
            "primary_muscle": muscle, "secondary_muscles": secondary,
            "difficulty": diff, "form_cue": cue, "substitution": sub}

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# ========================================================================
# CAT 35 - CARDIO & CONDITIONING (13 programs)
# ========================================================================

def pure_cardio_burn():
    return wo("Pure Cardio Burn", "cardio", 35, [
        ex("Jump Rope", 3, 1, 30, "1 minute rounds", "Jump Rope", "Full Body", "Calves", ["Quadriceps", "Shoulders", "Core"], "intermediate", "Light bounce, wrists turn the rope, elbows close", "High Knees"),
        ex("Burpee", 3, 8, 45, "Full burpees", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Squat, jump back, push-up, jump forward, jump up", "Squat Thrust"),
        ex("Mountain Climber", 3, 20, 30, "Alternating legs", "Bodyweight", "Core", "Hip Flexors", ["Quadriceps", "Shoulders", "Core"], "intermediate", "Plank position, drive knees to chest fast", "Slow Mountain Climber"),
        ex("High Knees", 3, 30, 30, "30 seconds", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core", "Calves"], "intermediate", "Drive knees above hip height, pump arms", "March in Place"),
        ex("Jumping Jack", 3, 25, 30, "Full extension", "Bodyweight", "Full Body", "Deltoids", ["Calves", "Quadriceps"], "beginner", "Jump feet out, arms overhead, return", "Step Jack"),
        ex("Squat Jump", 3, 12, 45, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Squat deep, explode up, soft landing", "Bodyweight Squat"),
    ])

def cardio_endurance_builder():
    return wo("Cardio Endurance Builder", "cardio", 40, [
        ex("Steady-State Jog", 1, 1, 0, "10 minutes at conversation pace", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "beginner", "Easy pace, nose breathing, relaxed shoulders", "Brisk Walk"),
        ex("Jump Rope", 3, 1, 30, "2 minutes each", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core"], "intermediate", "Steady rhythm, two-foot bounce", "Jumping Jacks"),
        ex("Step-Up", 3, 12, 30, "Each leg, moderate step", "Step Platform", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Drive through lead foot, stand tall at top", "Box Step-Up"),
        ex("High Knees", 3, 1, 30, "30 seconds each", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "intermediate", "Fast rhythm, keep torso upright", "Marching"),
        ex("Bicycle Crunch", 3, 20, 30, "Alternating", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Elbow to opposite knee, full extension", "Seated Bicycle"),
        ex("Cool Down Walk", 1, 1, 0, "5 minutes easy pace", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Hamstrings"], "beginner", "Gradually slow pace, let heart rate drop", "Standing in Place"),
    ])

def low_impact_cardio():
    return wo("Low Impact Cardio", "cardio", 30, [
        ex("March in Place", 3, 1, 30, "2 minutes each", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Calves"], "beginner", "Steady pace, pump arms, no jumping", "Seated March"),
        ex("Step Touch", 3, 1, 30, "1 minute each", "Bodyweight", "Legs", "Hip Abductors", ["Calves", "Quadriceps"], "beginner", "Step side to side, tap foot, swing arms", "Side Step"),
        ex("Low-Impact Squat Pulse", 3, 15, 30, "Stay low, pulse", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Quarter squat, small pulses, no bouncing", "Wall Sit"),
        ex("Standing Knee Drive", 3, 12, 30, "Each side", "Bodyweight", "Core", "Hip Flexors", ["Obliques"], "beginner", "Drive knee up, bring arms down to meet", "Seated Knee Raise"),
        ex("Lateral Slide", 3, 12, 30, "Each direction", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Glutes"], "beginner", "Slide step to side, stay low, push off", "Step Touch"),
        ex("Bird Dog", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Extend opposite arm and leg, slow and controlled", "Dead Bug"),
    ])

def jump_rope_mastery():
    return wo("Jump Rope Mastery", "cardio", 30, [
        ex("Basic Two-Foot Jump", 3, 1, 30, "1 minute rounds", "Jump Rope", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Light bounce on balls of feet, wrists turn rope", "Jumping Jacks"),
        ex("Alternate Foot Jump", 3, 1, 30, "1 minute rounds", "Jump Rope", "Legs", "Calves", ["Hip Flexors", "Core"], "intermediate", "Jog in place while jumping rope", "High Knees"),
        ex("Double Under", 3, 10, 45, "Build to consecutive", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core", "Quadriceps"], "advanced", "Jump higher, spin rope twice per jump, wrist speed", "Power Jump"),
        ex("Criss-Cross Jump", 3, 30, 30, "30 seconds", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core"], "intermediate", "Cross arms in front as rope passes under", "Basic Jump"),
        ex("Side Swing", 3, 30, 30, "30 seconds", "Jump Rope", "Shoulders", "Deltoids", ["Core", "Forearms"], "intermediate", "Swing rope to one side, then jump, alternate", "Arm Circle"),
        ex("Jump Rope Sprint", 3, 30, 60, "Max speed 30 seconds", "Jump Rope", "Full Body", "Calves", ["Quadriceps", "Core", "Shoulders"], "intermediate", "As fast as possible for 30 seconds", "Burpees"),
    ])

def battle_rope_conditioning():
    return wo("Battle Rope Conditioning", "conditioning", 30, [
        ex("Alternating Wave", 3, 30, 45, "30 seconds", "Battle Ropes", "Shoulders", "Deltoids", ["Core", "Biceps", "Forearms"], "intermediate", "Alternate arms in wave pattern, athletic stance", "Band Slams"),
        ex("Double Slam", 3, 15, 45, "Explosive", "Battle Ropes", "Full Body", "Deltoids", ["Core", "Latissimus Dorsi", "Quadriceps"], "intermediate", "Raise both ropes overhead, slam down with hip hinge", "Medicine Ball Slam"),
        ex("Side-to-Side Wave", 3, 30, 45, "30 seconds", "Battle Ropes", "Core", "Obliques", ["Shoulders", "Forearms"], "intermediate", "Sweep ropes side to side together", "Russian Twist"),
        ex("Rope Circle", 3, 30, 45, "Each direction", "Battle Ropes", "Shoulders", "Deltoids", ["Rotator Cuff", "Core"], "intermediate", "Make outward circles with each arm", "Arm Circle"),
        ex("Alternating Lunge Slam", 3, 10, 45, "Each side", "Battle Ropes", "Full Body", "Quadriceps", ["Deltoids", "Core", "Glutes"], "intermediate", "Lunge back while slamming ropes", "Lunge with Overhead Press"),
    ])

def rowing_conditioning():
    return wo("Rowing Conditioning", "cardio", 35, [
        ex("Rowing Machine Steady State", 1, 1, 0, "10 minutes moderate pace", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps", "Hamstrings", "Core", "Biceps"], "beginner", "Legs-back-arms sequence, controlled return", "Band Row"),
        ex("Rowing Intervals", 3, 1, 60, "500m hard, 1 min rest", "Rowing Machine", "Full Body", "Quadriceps", ["Latissimus Dorsi", "Core", "Biceps"], "intermediate", "Push hard with legs, pull through finish", "Burpees"),
        ex("Single-Arm Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, squeeze at top", "Band Row"),
        ex("Goblet Squat", 3, 12, 45, "Rowing leg drive", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Deep squat, chest up, drive through heels", "Bodyweight Squat"),
        ex("Plank Row", 3, 8, 30, "Each arm", "Dumbbell", "Core", "Latissimus Dorsi", ["Core", "Obliques", "Biceps"], "intermediate", "Plank position, row one dumbbell, alternate", "Band Row"),
    ])

def sled_work():
    return wo("Sled Work", "conditioning", 30, [
        ex("Sled Push", 4, 1, 60, "40 meters moderate weight", "Sled", "Legs", "Quadriceps", ["Calves", "Glutes", "Core"], "intermediate", "Low position, arms extended, drive with legs", "Wall Push"),
        ex("Sled Pull", 4, 1, 60, "40 meters with rope", "Sled", "Back", "Latissimus Dorsi", ["Biceps", "Core", "Hamstrings"], "intermediate", "Face sled, pull hand over hand", "Band Row"),
        ex("Sled Drag Backward", 3, 1, 60, "40 meters", "Sled", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Face sled, walk backward pulling", "Backward Lunge"),
        ex("Sled Sprint", 3, 1, 90, "20 meter sprint", "Sled", "Legs", "Glutes", ["Quadriceps", "Calves", "Core"], "advanced", "Explosive start, max effort sprint", "Hill Sprint"),
    ])

def bear_crawl_conditioning():
    return wo("Bear Crawl Conditioning", "conditioning", 25, [
        ex("Bear Crawl", 4, 1, 45, "20 meters forward", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps", "Hip Flexors"], "intermediate", "Hands and feet, knees hover off ground, opposite hand-foot", "Crawl on Knees"),
        ex("Bear Crawl Backward", 3, 1, 45, "20 meters", "Bodyweight", "Full Body", "Shoulders", ["Core", "Hamstrings"], "intermediate", "Reverse bear crawl, maintain low position", "Crawl on Knees"),
        ex("Lateral Bear Crawl", 3, 1, 45, "10 meters each direction", "Bodyweight", "Full Body", "Obliques", ["Shoulders", "Core", "Hip Abductors"], "intermediate", "Side movement in bear position", "Lateral Crawl on Knees"),
        ex("Bear Crawl to Push-Up", 3, 8, 45, "Crawl 5m, 2 push-ups, return", "Bodyweight", "Full Body", "Pectoralis Major", ["Shoulders", "Core", "Quadriceps"], "intermediate", "Bear crawl out, push-ups, crawl back", "Inchworm"),
        ex("Plank Hold", 3, 1, 30, "Hold 30 seconds between sets", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, recover in plank", "Knee Plank"),
    ])

def tire_flip_training():
    return wo("Tire Flip Training", "conditioning", 35, [
        ex("Tire Flip", 4, 6, 90, "Medium-heavy tire", "Tire", "Full Body", "Glutes", ["Hamstrings", "Quadriceps", "Chest", "Core"], "intermediate", "Sumo deadlift start, drive hips, push tire over", "Trap Bar Deadlift"),
        ex("Tire Sledgehammer Slam", 3, 15, 45, "Each side", "Sledgehammer", "Full Body", "Obliques", ["Shoulders", "Core", "Latissimus Dorsi"], "intermediate", "Rotate and slam hammer into tire", "Medicine Ball Slam"),
        ex("Tire Box Jump", 3, 8, 60, "Jump onto tire", "Tire", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Land softly on tire, step down", "Box Jump"),
        ex("Tire Push-Up", 3, 10, 30, "Hands on tire edge", "Tire", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Push-up with hands on tire rim", "Decline Push-Up"),
        ex("Tire Drag", 3, 1, 60, "30 meters", "Tire", "Full Body", "Hamstrings", ["Glutes", "Core", "Forearms"], "intermediate", "Attach rope, walk forward dragging tire", "Sled Drag"),
    ])

def medicine_ball_conditioning():
    return wo("Medicine Ball Conditioning", "conditioning", 30, [
        ex("Medicine Ball Slam", 3, 12, 30, "Explosive", "Medicine Ball", "Full Body", "Deltoids", ["Core", "Latissimus Dorsi", "Triceps"], "intermediate", "Reach overhead, slam ball to ground hard", "Battle Rope Slam"),
        ex("Medicine Ball Rotational Throw", 3, 10, 30, "Each side", "Medicine Ball", "Core", "Obliques", ["Shoulders", "Hips"], "intermediate", "Rotate and throw into wall, catch and repeat", "Russian Twist"),
        ex("Medicine Ball Chest Pass", 3, 12, 30, "Against wall", "Medicine Ball", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Explosive push from chest to wall, catch", "Push-Up"),
        ex("Medicine Ball Squat Throw", 3, 10, 45, "Wall ball style", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders", "Glutes", "Core"], "intermediate", "Squat deep, drive up and throw to target", "Thruster"),
        ex("Medicine Ball Russian Twist", 3, 15, 30, "Alternating sides", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Feet off ground, rotate and tap ball side to side", "Bodyweight Russian Twist"),
    ])

def agility_ladder_drills():
    return wo("Agility Ladder Drills", "conditioning", 25, [
        ex("Two Feet In Each", 3, 2, 30, "Full ladder length", "Agility Ladder", "Legs", "Calves", ["Quadriceps", "Hip Flexors"], "beginner", "Quick feet, both feet in each square", "Quick Feet in Place"),
        ex("Lateral Shuffle", 3, 2, 30, "Each direction", "Agility Ladder", "Legs", "Hip Abductors", ["Calves", "Quadriceps"], "intermediate", "Face sideways, quick lateral steps through", "Lateral Slide"),
        ex("In-Out Drill", 3, 2, 30, "Full ladder", "Agility Ladder", "Legs", "Hip Adductors", ["Calves", "Quadriceps"], "intermediate", "Two feet in, two feet out, move forward", "Side Step"),
        ex("Ickey Shuffle", 3, 2, 30, "Full ladder", "Agility Ladder", "Legs", "Hip Abductors", ["Calves", "Quadriceps"], "intermediate", "In-in-out pattern moving laterally", "Lateral Shuffle"),
        ex("Single-Leg Hop", 3, 2, 30, "Each leg, full ladder", "Agility Ladder", "Legs", "Calves", ["Quadriceps", "Core"], "intermediate", "Hop through each square on one foot", "Single-Leg Jump"),
        ex("Ali Shuffle", 3, 2, 30, "Full ladder", "Agility Ladder", "Legs", "Calves", ["Hip Flexors", "Core"], "advanced", "Straddle ladder, quick split switches", "Scissor Jumps"),
    ])

def speed_training():
    return wo("Speed Training", "conditioning", 35, [
        ex("A-Skip", 3, 20, 30, "20 meters each set", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Calves"], "intermediate", "Exaggerated skip, drive knee high, quick ground contact", "High Knees"),
        ex("B-Skip", 3, 20, 30, "20 meters each set", "Bodyweight", "Legs", "Hamstrings", ["Hip Flexors", "Quadriceps"], "intermediate", "A-skip with extension, pawing motion back to ground", "Butt Kicks"),
        ex("Sprint", 4, 1, 120, "40 meters at 90% effort", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Glutes", "Calves"], "intermediate", "Drive knees, pump arms, lean forward slightly", "High Knees"),
        ex("Bounding", 3, 8, 60, "Exaggerated strides", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Calves"], "intermediate", "Long leaping strides, drive knee forward and up", "Lunge Jump"),
        ex("Hill Sprint", 3, 1, 120, "20 meters uphill", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Calves", "Core"], "intermediate", "Lean into hill, pump arms, drive knees", "Stair Sprint"),
    ])

def conditioning_circuit():
    return wo("Conditioning Circuit", "conditioning", 30, [
        ex("Kettlebell Swing", 3, 15, 30, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hinge back, snap hips, float kettlebell to chest", "Dumbbell Swing"),
        ex("Push-Up", 3, 12, 30, "Steady pace", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Full range, maintain plank", "Incline Push-Up"),
        ex("Box Jump", 3, 10, 30, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explode up, land softly, step down", "Squat Jump"),
        ex("Renegade Row", 3, 8, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row one arm at a time", "Band Row"),
        ex("Burpee", 3, 8, 30, "Full burpees", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Down, back, push-up, forward, jump", "Squat Thrust"),
    ])

# Generate Cat 35 programs
cat35_programs = [
    ("Pure Cardio Burn", "Cardio & Conditioning", [2, 4, 8], [4, 5], "Cardio-only fat burning with high-energy movements", "High", False,
     lambda w, t: [pure_cardio_burn(), pure_cardio_burn(), pure_cardio_burn()]),
    ("Cardio Endurance Builder", "Cardio & Conditioning", [4, 8, 12], [4, 5], "Progressive aerobic capacity building program", "High", False,
     lambda w, t: [cardio_endurance_builder(), cardio_endurance_builder(), cardio_endurance_builder()]),
    ("Low Impact Cardio", "Cardio & Conditioning", [2, 4, 8], [5, 6], "Joint-friendly cardiovascular conditioning", "High", False,
     lambda w, t: [low_impact_cardio(), low_impact_cardio(), low_impact_cardio()]),
    ("Jump Rope Mastery", "Cardio & Conditioning", [1, 2, 4, 8], [4, 5], "Complete jump rope skill and conditioning program", "Med", False,
     lambda w, t: [jump_rope_mastery(), jump_rope_mastery(), jump_rope_mastery()]),
    ("Battle Rope Conditioning", "Cardio & Conditioning", [2, 4, 8], [3, 4], "Battle rope-based metabolic conditioning", "Med", True,
     lambda w, t: [battle_rope_conditioning(), battle_rope_conditioning(), battle_rope_conditioning()]),
    ("Rowing Conditioning", "Cardio & Conditioning", [2, 4, 8], [4, 5], "Rowing machine-based cardio and strength program", "Med", False,
     lambda w, t: [rowing_conditioning(), rowing_conditioning(), rowing_conditioning()]),
    ("Sled Work", "Cardio & Conditioning", [2, 4, 8], [3, 4], "Sled push and pull conditioning for full-body power", "Med", False,
     lambda w, t: [sled_work(), sled_work(), sled_work()]),
    ("Bear Crawl Conditioning", "Cardio & Conditioning", [2, 4, 8], [3, 4], "Crawling-based full-body conditioning program", "Med", False,
     lambda w, t: [bear_crawl_conditioning(), bear_crawl_conditioning(), bear_crawl_conditioning()]),
    ("Tire Flip Training", "Cardio & Conditioning", [2, 4, 8], [3, 4], "Tire-based functional conditioning and power", "Med", True,
     lambda w, t: [tire_flip_training(), tire_flip_training(), tire_flip_training()]),
    ("Medicine Ball Conditioning", "Cardio & Conditioning", [2, 4, 8], [3, 4], "Medicine ball-based power and conditioning circuits", "Med", True,
     lambda w, t: [medicine_ball_conditioning(), medicine_ball_conditioning(), medicine_ball_conditioning()]),
    ("Agility Ladder Drills", "Cardio & Conditioning", [2, 4, 8], [3, 4], "Footwork and agility training with ladder drills", "Med", False,
     lambda w, t: [agility_ladder_drills(), agility_ladder_drills(), agility_ladder_drills()]),
    ("Speed Training", "Cardio & Conditioning", [2, 4, 8], [3, 4], "Sprint mechanics and speed development program", "Med", False,
     lambda w, t: [speed_training(), speed_training(), speed_training()]),
    ("Conditioning Circuit", "Cardio & Conditioning", [1, 2, 4], [3, 4], "Multi-station cardio and strength circuit", "Low", True,
     lambda w, t: [conditioning_circuit(), conditioning_circuit(), conditioning_circuit()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat35_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Base: build aerobic foundation and learn techniques"
            elif p <= 0.66: focus = f"Week {w} - Build: increase intensity and work capacity"
            else: focus = f"Week {w} - Peak: maximum output and conditioning tests"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 35 CARDIO & CONDITIONING COMPLETE ===")

# ========================================================================
# CAT 36 - STRONGMAN/FUNCTIONAL (10 programs)
# ========================================================================

def strongman_basics():
    return wo("Strongman Basics", "strength", 45, [
        ex("Deadlift", 4, 5, 120, "Moderate to heavy", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae", "Quadriceps"], "intermediate", "Hips back, flat back, drive through floor", "Trap Bar Deadlift"),
        ex("Overhead Press", 4, 6, 90, "Barbell, strict", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core", "Upper Trapezius"], "intermediate", "Bar from shoulders, press overhead, lock out", "Dumbbell Press"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 40 meters", "Dumbbell", "Full Body", "Forearms", ["Trapezius", "Core", "Glutes"], "intermediate", "Tall posture, tight grip, brisk walk", "Suitcase Carry"),
        ex("Front Squat", 3, 6, 90, "Moderate weight", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes", "Upper Back"], "intermediate", "Elbows high, sit between legs, drive up", "Goblet Squat"),
        ex("Barbell Row", 3, 8, 60, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull to lower chest, squeeze", "Dumbbell Row"),
    ])

def farmers_walk_mastery():
    return wo("Farmer's Walk Mastery", "strength", 35, [
        ex("Farmer's Walk", 4, 1, 60, "Progressive weight, 50m", "Dumbbell", "Full Body", "Forearms", ["Trapezius", "Core", "Glutes"], "intermediate", "Tall posture, tight core, brisk walk", "Kettlebell Carry"),
        ex("Suitcase Carry", 3, 1, 60, "One side, 30m each", "Dumbbell", "Core", "Obliques", ["Forearms", "Trapezius"], "intermediate", "One dumbbell, stay upright, resist lean", "Farmer's Walk"),
        ex("Overhead Carry", 3, 1, 60, "Lighter weight, 30m", "Dumbbell", "Shoulders", "Deltoids", ["Core", "Trapezius"], "intermediate", "Lock arm overhead, walk steady, brace core", "Waiter Walk"),
        ex("Trap Bar Carry", 3, 1, 60, "Heavy, 40m", "Trap Bar", "Full Body", "Trapezius", ["Forearms", "Core", "Glutes"], "intermediate", "Heavy walk with trap bar, shoulders back", "Farmer's Walk"),
        ex("Grip Crush Hold", 3, 1, 30, "Hold 30 seconds", "Dumbbell", "Arms", "Forearms", ["Fingers"], "intermediate", "Squeeze dumbbell handle as hard as possible", "Plate Pinch"),
    ])

def odd_object_training():
    return wo("Odd Object Training", "functional", 40, [
        ex("Sandbag Clean", 3, 8, 60, "Moderate sandbag", "Sandbag", "Full Body", "Glutes", ["Core", "Biceps", "Shoulders"], "intermediate", "Pick from floor, lap, clean to shoulder", "Dumbbell Clean"),
        ex("Sandbag Carry", 3, 1, 60, "Bear hug, 40m", "Sandbag", "Full Body", "Core", ["Biceps", "Quadriceps"], "intermediate", "Hug tight to chest, walk with purpose", "Farmer's Walk"),
        ex("Keg Lift", 3, 6, 90, "Floor to shoulder", "Keg", "Full Body", "Glutes", ["Core", "Biceps", "Shoulders"], "intermediate", "Bear hug keg, lap it, muscle to shoulder", "Sandbag Clean"),
        ex("Stone Load to Platform", 3, 5, 120, "Atlas stone or heavy ball", "Atlas Stone", "Full Body", "Glutes", ["Hamstrings", "Biceps", "Core"], "advanced", "Straddle stone, bear hug, lap, extend hips to load", "Sandbag Shouldering"),
        ex("Tire Flip", 3, 6, 90, "Medium tire", "Tire", "Full Body", "Glutes", ["Chest", "Quadriceps", "Core"], "intermediate", "Sumo deadlift start, hip drive, push over", "Trap Bar Deadlift"),
    ])

def atlas_stone_training():
    return wo("Atlas Stone Training", "strength", 40, [
        ex("Atlas Stone Lap", 4, 5, 90, "Progressive weight", "Atlas Stone", "Full Body", "Glutes", ["Hamstrings", "Biceps", "Core"], "advanced", "Straddle stone, fingers underneath, lap to thighs", "Sandbag Lap"),
        ex("Atlas Stone to Shoulder", 3, 4, 120, "Medium stone", "Atlas Stone", "Full Body", "Glutes", ["Shoulders", "Biceps", "Core"], "advanced", "From lap, extend hips and roll to shoulder", "Sandbag Shouldering"),
        ex("Atlas Stone Over Bar", 3, 4, 120, "Load over yoke bar", "Atlas Stone", "Full Body", "Glutes", ["Hamstrings", "Quadriceps", "Core"], "advanced", "Lap stone, triple extend to load over bar", "Trap Bar Deadlift"),
        ex("Deadlift", 4, 5, 120, "Foundation strength", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "intermediate", "Build base pulling strength for stones", "Trap Bar Deadlift"),
        ex("Barbell Row", 3, 8, 60, "Upper back strength", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Bent over, pull to stomach, squeeze", "Dumbbell Row"),
    ])

def log_press_training():
    return wo("Log Press Training", "strength", 40, [
        ex("Log Clean", 4, 4, 90, "From floor to shoulders", "Log", "Full Body", "Shoulders", ["Core", "Biceps", "Glutes"], "advanced", "Deadlift to lap, roll up chest, rack on shoulders", "Barbell Clean"),
        ex("Log Press", 4, 4, 120, "From shoulders overhead", "Log", "Shoulders", "Deltoids", ["Triceps", "Core", "Upper Trapezius"], "advanced", "Slight dip, drive legs, press to lockout", "Overhead Press"),
        ex("Push Press", 3, 6, 90, "Barbell, moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps", "Core"], "intermediate", "Dip and drive with legs, press overhead", "Overhead Press"),
        ex("Front Squat", 3, 6, 90, "Build front rack strength", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows high, full depth, drive up", "Goblet Squat"),
        ex("Dumbbell Z-Press", 3, 8, 60, "Seated on floor, no back support", "Dumbbell", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Sit on floor, press overhead with no lean", "Seated Press"),
    ])

def yoke_walk_training():
    return wo("Yoke Walk Training", "strength", 35, [
        ex("Yoke Walk", 4, 1, 90, "Heavy, 30 meters", "Yoke", "Full Body", "Trapezius", ["Core", "Quadriceps", "Glutes"], "advanced", "Bar across back, tight brace, short fast steps", "Barbell Back Squat Walk"),
        ex("Back Squat", 4, 5, 120, "Build yoke strength", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core", "Erector Spinae"], "intermediate", "Full depth, controlled descent, strong drive", "Goblet Squat"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 40m", "Dumbbell", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Carry practice, brisk pace", "Kettlebell Carry"),
        ex("Plank Hold", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Obliques"], "intermediate", "Brace as if carrying yoke weight", "Dead Bug"),
    ])

def functional_athlete():
    return wo("Functional Athlete", "functional", 40, [
        ex("Deadlift", 3, 5, 90, "Moderate to heavy", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "intermediate", "Fundamental pulling pattern", "Trap Bar Deadlift"),
        ex("Overhead Press", 3, 6, 60, "Strict press", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strong overhead push", "Dumbbell Press"),
        ex("Pull-Up", 3, 8, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Dead hang, chin over bar", "Lat Pulldown"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 40m", "Dumbbell", "Full Body", "Forearms", ["Core", "Trapezius"], "intermediate", "Carry heavy loads efficiently", "Suitcase Carry"),
        ex("Front Squat", 3, 6, 90, "Moderate", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Upright torso, full depth", "Goblet Squat"),
        ex("Kettlebell Swing", 3, 15, 45, "Explosive hips", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hinge back, snap hips, float bell", "Dumbbell Swing"),
    ])

def power_builder():
    return wo("Power Builder", "strength", 45, [
        ex("Back Squat", 4, 5, 120, "Heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Deep squat, strong drive from hole", "Goblet Squat"),
        ex("Bench Press", 4, 5, 120, "Heavy", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Control down, pause, drive up", "Dumbbell Press"),
        ex("Deadlift", 4, 3, 180, "Heavy", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "intermediate", "Maximum pulling strength", "Trap Bar Deadlift"),
        ex("Barbell Row", 3, 8, 60, "Moderate", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to lower chest, squeeze", "Dumbbell Row"),
        ex("Overhead Press", 3, 6, 90, "Strict", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Press to lockout overhead", "Dumbbell Press"),
    ])

def grip_strength():
    return wo("Grip Strength", "strength", 30, [
        ex("Dead Hang", 3, 1, 60, "Hold to failure", "Pull-Up Bar", "Arms", "Forearms", ["Shoulders", "Latissimus Dorsi"], "beginner", "Full grip, hang as long as possible", "Towel Hang"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 30m", "Dumbbell", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Squeeze handles tight, walk with purpose", "Plate Pinch Walk"),
        ex("Plate Pinch Hold", 3, 1, 30, "Hold 20-30 seconds", "Weight Plate", "Arms", "Forearms", ["Fingers"], "intermediate", "Pinch two plates together, smooth sides out", "Towel Grip"),
        ex("Wrist Curl", 3, 15, 30, "Light dumbbell", "Dumbbell", "Arms", "Wrist Flexors", ["Forearms"], "beginner", "Forearms on thighs, curl wrist up", "Towel Wring"),
        ex("Reverse Wrist Curl", 3, 15, 30, "Light dumbbell", "Dumbbell", "Arms", "Wrist Extensors", ["Forearms"], "beginner", "Forearms on thighs palm down, extend wrist up", "Band Wrist Extension"),
        ex("Towel Pull-Up", 3, 5, 60, "Drape towels over bar", "Pull-Up Bar", "Back", "Forearms", ["Latissimus Dorsi", "Biceps"], "advanced", "Grip towels, pull chin to bar level", "Thick Grip Pull-Up"),
    ])

def general_athlete():
    return wo("General Athlete", "functional", 40, [
        ex("Power Clean", 3, 5, 90, "Moderate", "Barbell", "Full Body", "Glutes", ["Hamstrings", "Trapezius", "Core"], "intermediate", "Pull from floor, triple extend, rack on shoulders", "Hang Clean"),
        ex("Back Squat", 3, 6, 90, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Full depth, strong drive", "Goblet Squat"),
        ex("Pull-Up", 3, 8, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Dead hang to chin over bar", "Lat Pulldown"),
        ex("Box Jump", 3, 8, 60, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive jump, soft landing, step down", "Squat Jump"),
        ex("Push Press", 3, 6, 60, "Moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps"], "intermediate", "Dip and drive, press overhead", "Overhead Press"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Straight line, brace hard", "Dead Bug"),
    ])

# Generate Cat 36 programs
cat36_programs = [
    ("Strongman Basics", "Strongman/Functional", [4, 8, 12], [3, 4], "Introduction to strongman training with foundational lifts and carries", "High", True,
     lambda w, t: [strongman_basics(), strongman_basics(), strongman_basics()]),
    ("Farmer's Walk Mastery", "Strongman/Functional", [2, 4, 8], [3, 4], "Complete carry variation program for grip and full-body strength", "High", False,
     lambda w, t: [farmers_walk_mastery(), farmers_walk_mastery(), farmers_walk_mastery()]),
    ("Odd Object Training", "Strongman/Functional", [4, 8], [3, 4], "Sandbags, stones, kegs and unconventional object training", "High", True,
     lambda w, t: [odd_object_training(), odd_object_training(), odd_object_training()]),
    ("Atlas Stone Training", "Strongman/Functional", [4, 8], [3], "Stone lifting progression from lap to load", "Med", False,
     lambda w, t: [atlas_stone_training(), atlas_stone_training(), atlas_stone_training()]),
    ("Log Press Training", "Strongman/Functional", [4, 8], [3], "Overhead log pressing strength and technique", "Med", False,
     lambda w, t: [log_press_training(), log_press_training(), log_press_training()]),
    ("Yoke Walk Training", "Strongman/Functional", [2, 4, 8], [3], "Heavy yoke carry training for stability and leg drive", "Med", False,
     lambda w, t: [yoke_walk_training(), yoke_walk_training(), yoke_walk_training()]),
    ("Functional Athlete", "Strongman/Functional", [4, 8, 12], [4, 5], "Well-rounded functional strength for general athleticism", "Med", True,
     lambda w, t: [functional_athlete(), functional_athlete(), functional_athlete()]),
    ("Power Builder", "Strongman/Functional", [4, 8, 12], [4, 5], "Combine powerlifting strength with functional capacity", "Med", True,
     lambda w, t: [power_builder(), power_builder(), power_builder()]),
    ("Grip Strength", "Strongman/Functional", [4, 8, 12], [4, 5], "Dedicated grip strength training for crushing and pinch strength", "Med", True,
     lambda w, t: [grip_strength(), grip_strength(), grip_strength()]),
    ("General Athlete", "Strongman/Functional", [2, 4, 8, 12], [4, 5], "Multi-sport athletic foundation with power and agility", "Med", True,
     lambda w, t: [general_athlete(), general_athlete(), general_athlete()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat36_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: learn implements and build base strength"
            elif p <= 0.66: focus = f"Week {w} - Build: increase loads and add implement variety"
            else: focus = f"Week {w} - Peak: heavy loads, timed events, competition simulation"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 36 STRONGMAN/FUNCTIONAL COMPLETE ===")

# ========================================================================
# CAT 37 - LIFESTYLE/OUTDOOR CARDIO (15 programs)
# ========================================================================

def dog_walking_fitness():
    return wo("Dog Walking Fitness", "cardio", 30, [
        ex("Brisk Walk Interval", 3, 1, 30, "2 min fast, 1 min easy", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Walk fast enough to elevate heart rate, then recover", "March in Place"),
        ex("Walking Lunge", 2, 10, 30, "While dog sniffs", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step forward into lunge while paused", "Reverse Lunge"),
        ex("Calf Raise on Curb", 2, 15, 30, "At traffic stops", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Rise on toes on curb edge, lower below", "Standing Calf Raise"),
        ex("Standing Glute Squeeze", 3, 15, 30, "While walking", "Bodyweight", "Glutes", "Gluteus Maximus", [], "beginner", "Squeeze glutes intentionally with each stride", "Glute Bridge"),
        ex("Arm Swing Walk", 2, 1, 0, "2 minutes exaggerated", "Bodyweight", "Shoulders", "Deltoids", ["Core"], "beginner", "Walk with large deliberate arm swings", "Arm Circle"),
    ])

def running_with_dogs():
    return wo("Running with Dogs", "cardio", 35, [
        ex("Easy Jog", 1, 1, 0, "10 minute warmup", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Easy pace to warm up with dog, nose breathing", "Brisk Walk"),
        ex("Tempo Run", 3, 1, 60, "3 minutes at moderate effort", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "intermediate", "Comfortably hard pace, match dog's natural gait", "Fast Walk"),
        ex("Sprint Interval", 3, 30, 90, "30 second bursts", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "intermediate", "Sprint with dog, let them run full speed", "High Knees"),
        ex("Cool Down Jog", 1, 1, 0, "5 minutes easy", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Slow jog, let heart rate come down", "Walk"),
    ])

def dog_park_workout():
    return wo("Dog Park Workout", "general", 25, [
        ex("Bench Push-Up", 3, 12, 30, "Park bench", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Hands on bench, full push-ups while watching dog", "Incline Push-Up"),
        ex("Bench Step-Up", 3, 10, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Step up on bench, drive through lead leg", "Box Step-Up"),
        ex("Bench Dip", 3, 10, 30, "Hands on bench edge", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid"], "beginner", "Lower body by bending elbows, push back up", "Wall Push-Up"),
        ex("Bodyweight Squat", 3, 15, 30, "On grass", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth squats on park grass", "Chair Squat"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Plank on grass, watch dog play", "Knee Plank"),
    ])

def nature_walk_cardio():
    return wo("Nature Walk Cardio", "cardio", 40, [
        ex("Trail Walk", 1, 1, 0, "15 minutes moderate pace", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "beginner", "Walk on natural terrain, varied elevation", "Treadmill Walk"),
        ex("Hill Climb", 2, 1, 60, "3 minutes uphill", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Calves"], "beginner", "Lean slightly forward, drive with legs", "Incline Walk"),
        ex("Rock Step-Up", 2, 10, 30, "Find stable rock or log", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Step up on natural surface, alternate legs", "Step-Up"),
        ex("Standing Balance", 2, 1, 30, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "beginner", "Balance on uneven natural terrain", "Single-Leg Stand"),
    ])

def beach_workout():
    return wo("Beach Workout", "general", 35, [
        ex("Sand Sprint", 3, 1, 60, "30 seconds hard", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes", "Core"], "intermediate", "Sprint on sand for extra resistance", "Hill Sprint"),
        ex("Sand Burpee", 3, 8, 45, "Full burpees on sand", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Extra resistance from soft surface", "Squat Thrust"),
        ex("Bear Crawl on Sand", 3, 1, 45, "20 meters", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "intermediate", "Crawl on sand for extra shoulder work", "Bear Crawl"),
        ex("Sand Squat Jump", 3, 10, 45, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Jump from sand, land soft", "Squat Jump"),
        ex("Plank on Sand", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Unstable surface adds challenge", "Forearm Plank"),
    ])

def mountain_hiking_training():
    return wo("Mountain Hiking Prep", "cardio", 40, [
        ex("Stair Climb", 3, 1, 60, "5 minutes each set", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Climb stairs at steady pace, simulate elevation", "Step-Up"),
        ex("Walking Lunge", 3, 12, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Build leg endurance for trail hiking", "Reverse Lunge"),
        ex("Step-Up", 3, 10, 30, "Each leg, high step", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "High step simulates rock stepping", "Box Step-Up"),
        ex("Calf Raise", 3, 15, 30, "Slow eccentric", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Important for downhill control", "Seated Calf Raise"),
        ex("Single-Leg Balance", 2, 1, 30, "30 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius"], "beginner", "Simulate uneven trail footing", "Balance on Foam Pad"),
        ex("Rucksack Squat", 3, 10, 45, "Wear weighted backpack", "Backpack", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Squat with loaded pack for trail prep", "Goblet Squat"),
    ])

def urban_exploration():
    return wo("Urban Exploration Fitness", "cardio", 35, [
        ex("Stair Sprint", 3, 1, 60, "30 seconds up", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Sprint up public stairs, walk down", "Stair Climb"),
        ex("Park Bench Push-Up", 3, 12, 30, "Public bench", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Push-ups on park bench", "Wall Push-Up"),
        ex("Walking Lunge", 3, 10, 30, "On sidewalk", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Lunge walk down the block", "Reverse Lunge"),
        ex("Bench Step-Up", 3, 10, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Step up on park bench or wall", "Step-Up"),
        ex("Brisk Walk", 1, 1, 0, "10 minutes between stations", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Fast walk between exercise stations", "Jog"),
    ])

def stair_climbing():
    return wo("Stair Climbing", "cardio", 30, [
        ex("Steady Stair Climb", 3, 1, 60, "3 minutes continuous", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Steady pace up stairs, walk down", "Step-Up"),
        ex("Two-at-a-Time Stairs", 3, 1, 60, "2 minutes", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Hamstrings"], "intermediate", "Skip a step for bigger range of motion", "Walking Lunge"),
        ex("Stair Sprint", 3, 30, 90, "30 seconds max effort", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Sprint up fast, walk down", "Hill Sprint"),
        ex("Stair Calf Raise", 3, 15, 30, "On stair edge", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Heels off edge, rise and lower", "Standing Calf Raise"),
        ex("Stair Lunge", 2, 8, 30, "Each leg, going up", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Lunge up two steps at a time", "Walking Lunge"),
    ])

def trail_running_prep():
    return wo("Trail Running Prep", "cardio", 35, [
        ex("Easy Run", 1, 1, 0, "10 minutes", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Conversational pace warmup", "Brisk Walk"),
        ex("Hill Repeat", 3, 1, 90, "1 minute uphill hard", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Calves"], "intermediate", "Hard effort uphill, easy jog down", "Stair Sprint"),
        ex("Lateral Shuffle", 3, 30, 30, "30 seconds each direction", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Low stance, quick lateral steps", "Side Step"),
        ex("Single-Leg Hop", 3, 8, 30, "Each leg", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "intermediate", "Hop forward on one foot, land stable", "Single-Leg Balance"),
        ex("Ankle Stability Circle", 2, 10, 0, "Each direction, each foot", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves", "Ankle Stabilizers"], "beginner", "Single leg, circle free ankle", "Calf Raise"),
    ])

def outdoor_bootcamp():
    return wo("Outdoor Bootcamp", "general", 35, [
        ex("Burpee", 3, 10, 30, "Full burpees outdoors", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Get dirty, full burpees on grass", "Squat Thrust"),
        ex("Sprint", 3, 1, 60, "40 meters", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "All-out sprint across field", "High Knees"),
        ex("Push-Up", 3, 15, 30, "On grass", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Standard push-ups outdoors", "Incline Push-Up"),
        ex("Bodyweight Squat", 3, 20, 30, "Fast pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Quick squats between sprints", "Chair Squat"),
        ex("Mountain Climber", 3, 20, 30, "Fast pace", "Bodyweight", "Core", "Hip Flexors", ["Quadriceps", "Core"], "intermediate", "Fast alternating knee drives", "Plank"),
        ex("Bear Crawl", 3, 1, 30, "20 meters", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "intermediate", "Crawl across field, hands and feet", "Crawl on Knees"),
    ])

def kayaking_dryland():
    return wo("Kayaking Dryland", "strength", 30, [
        ex("Lat Pulldown", 3, 12, 45, "Wide grip", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Pull down paddle motion, squeeze at bottom", "Band Pulldown"),
        ex("Seated Cable Row", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "intermediate", "Pull to stomach, squeeze shoulder blades", "Band Row"),
        ex("Russian Twist", 3, 15, 30, "Simulate paddle rotation", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Rotate as if paddling, controlled", "Bodyweight Russian Twist"),
        ex("Shoulder External Rotation", 3, 12, 30, "Light band", "Resistance Band", "Shoulders", "Rotator Cuff", ["Rear Deltoids"], "beginner", "Elbow at side, rotate outward, prevent injury", "Cable External Rotation"),
        ex("Bicep Curl", 3, 12, 30, "Moderate weight", "Dumbbell", "Arms", "Biceps", ["Forearms"], "beginner", "Controlled curl, build paddle pulling strength", "Band Curl"),
    ])

def surfing_prep():
    return wo("Surfing Prep", "functional", 35, [
        ex("Pop-Up Burpee", 3, 10, 30, "Simulate pop-up", "Bodyweight", "Full Body", "Chest", ["Hip Flexors", "Core", "Quadriceps"], "intermediate", "Lie flat, explosive push to standing, one foot forward", "Burpee"),
        ex("Rotational Lunge", 3, 10, 30, "Each side", "Bodyweight", "Legs", "Quadriceps", ["Obliques", "Glutes"], "intermediate", "Lunge forward, rotate torso over lead leg", "Walking Lunge"),
        ex("Paddle Swim Simulation", 3, 15, 30, "Prone on bench", "Bodyweight", "Back", "Latissimus Dorsi", ["Rear Deltoids", "Rhomboids"], "beginner", "Lie face down, alternate arm swimming motion", "Prone Cobra"),
        ex("Single-Leg Balance", 3, 1, 30, "30 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "beginner", "Simulate board balance on one leg", "Bosu Ball Balance"),
        ex("Plank to Push-Up", 3, 8, 30, "Forearm to hand", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Forearm plank to hand plank, back down", "Push-Up"),
    ])

def rock_climbing_prep():
    return wo("Rock Climbing Prep", "strength", 35, [
        ex("Pull-Up", 4, 6, 60, "Various grips", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms", "Rhomboids"], "intermediate", "Dead hang, pull chin over bar, control down", "Lat Pulldown"),
        ex("Dead Hang", 3, 1, 30, "Hold to failure", "Pull-Up Bar", "Arms", "Forearms", ["Shoulders", "Latissimus Dorsi"], "beginner", "Full grip, hang as long as possible", "Active Hang"),
        ex("Fingerboard Hang", 3, 1, 45, "10 second hangs", "Hangboard", "Arms", "Forearms", ["Fingers", "Shoulders"], "intermediate", "Open hand crimp on edge, hang 10 seconds", "Dead Hang"),
        ex("Core Rotation", 3, 12, 30, "Cable or band", "Cable Machine", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Resist rotation, then controlled rotate", "Russian Twist"),
        ex("Hip Flexor Raise", 3, 10, 30, "Hanging", "Pull-Up Bar", "Core", "Hip Flexors", ["Rectus Abdominis"], "intermediate", "Hang, bring knees to chest with control", "Knee Raise"),
        ex("Antagonist Push-Up", 3, 12, 30, "Balance pulling work", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Balance climbing pull muscles", "Dumbbell Press"),
    ])

def snow_sport_prep():
    return wo("Snow Sport Prep", "functional", 35, [
        ex("Wall Sit", 3, 1, 30, "Hold 45-60 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Simulate ski tuck position, back against wall", "Bodyweight Squat"),
        ex("Lateral Lunge", 3, 10, 30, "Each side", "Bodyweight", "Legs", "Hip Adductors", ["Quadriceps", "Glutes"], "beginner", "Step wide to side, push hips back", "Side Step"),
        ex("Single-Leg Romanian Deadlift", 3, 8, 30, "Each leg", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Hinge on one leg, reach dumbbell toward floor", "Romanian Deadlift"),
        ex("Box Jump", 3, 8, 60, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive power for moguls and terrain", "Squat Jump"),
        ex("Side Plank", 3, 1, 30, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Gluteus Medius"], "beginner", "Lateral stability for edge control", "Modified Side Plank"),
        ex("Bosu Ball Squat", 3, 12, 30, "Balance on Bosu", "Bosu Ball", "Legs", "Quadriceps", ["Core", "Ankle Stabilizers"], "intermediate", "Squat on unstable surface, simulate terrain", "Single-Leg Balance"),
    ])

def adventure_race_prep():
    return wo("Adventure Race Prep", "functional", 40, [
        ex("Run", 1, 1, 0, "10 minutes moderate", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Build running base for race", "Brisk Walk"),
        ex("Burpee", 3, 10, 30, "Full burpees", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Obstacle race staple movement", "Squat Thrust"),
        ex("Pull-Up", 3, 6, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Wall climbing and obstacle clearance", "Lat Pulldown"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 40m", "Dumbbell", "Full Body", "Forearms", ["Core", "Trapezius"], "intermediate", "Carry practice for race carries", "Bucket Carry"),
        ex("Box Jump", 3, 8, 45, "Various heights", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Obstacle jumping practice", "Squat Jump"),
        ex("Bear Crawl", 3, 1, 30, "20 meters", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "intermediate", "Low crawl under obstacles", "Crawl"),
    ])

# Generate Cat 37 programs
cat37_programs = [
    ("Dog Walking Fitness", "Lifestyle/Outdoor Cardio", [2, 4, 8], [5, 6], "Structured fitness walks with your dog", "High", False,
     lambda w, t: [dog_walking_fitness(), dog_walking_fitness(), dog_walking_fitness()]),
    ("Running with Dogs", "Lifestyle/Outdoor Cardio", [4, 8, 12], [3, 4], "Canicross-style running with your dog", "High", False,
     lambda w, t: [running_with_dogs(), running_with_dogs(), running_with_dogs()]),
    ("Dog Park Workout", "Lifestyle/Outdoor Cardio", [1, 2, 4], [3, 4], "Bodyweight workout while at the dog park", "High", True,
     lambda w, t: [dog_park_workout(), dog_park_workout(), dog_park_workout()]),
    ("Nature Walk Cardio", "Lifestyle/Outdoor Cardio", [2, 4, 8], [5, 6], "Forest bathing combined with cardio movement", "Med", False,
     lambda w, t: [nature_walk_cardio(), nature_walk_cardio(), nature_walk_cardio()]),
    ("Beach Workout", "Lifestyle/Outdoor Cardio", [2, 4, 8], [3, 4], "Sand-based cardio and strength on the beach", "Med", True,
     lambda w, t: [beach_workout(), beach_workout(), beach_workout()]),
    ("Mountain Hiking Training", "Lifestyle/Outdoor Cardio", [8, 12, 16], [3, 4], "Elevation gain and endurance training for mountain hikes", "Med", False,
     lambda w, t: [mountain_hiking_training(), mountain_hiking_training(), mountain_hiking_training()]),
    ("Urban Exploration Fitness", "Lifestyle/Outdoor Cardio", [2, 4, 8], [4, 5], "City-based fitness using stairs, benches, and sidewalks", "Low", False,
     lambda w, t: [urban_exploration(), urban_exploration(), urban_exploration()]),
    ("Stair Climbing", "Lifestyle/Outdoor Cardio", [2, 4, 8], [4, 5], "Stair-based cardio and lower body conditioning", "Med", False,
     lambda w, t: [stair_climbing(), stair_climbing(), stair_climbing()]),
    ("Trail Running Prep", "Lifestyle/Outdoor Cardio", [4, 8, 12], [3, 4], "Off-road running preparation with agility and balance", "Med", False,
     lambda w, t: [trail_running_prep(), trail_running_prep(), trail_running_prep()]),
    ("Outdoor Bootcamp", "Lifestyle/Outdoor Cardio", [2, 4, 8], [3, 4], "Outdoor group-style bootcamp workout", "Med", True,
     lambda w, t: [outdoor_bootcamp(), outdoor_bootcamp(), outdoor_bootcamp()]),
    ("Kayaking Dryland", "Lifestyle/Outdoor Cardio", [4, 8], [3, 4], "Dryland training for kayaking and paddle sports", "Low", True,
     lambda w, t: [kayaking_dryland(), kayaking_dryland(), kayaking_dryland()]),
    ("Surfing Prep", "Lifestyle/Outdoor Cardio", [4, 8], [3, 4], "Dryland preparation for surfing with pop-ups and balance", "Low", False,
     lambda w, t: [surfing_prep(), surfing_prep(), surfing_prep()]),
    ("Rock Climbing Prep", "Lifestyle/Outdoor Cardio", [4, 8, 12], [3, 4], "Grip, pull, and core strength for climbing", "Low", False,
     lambda w, t: [rock_climbing_prep(), rock_climbing_prep(), rock_climbing_prep()]),
    ("Snow Sport Prep", "Lifestyle/Outdoor Cardio", [4, 8, 12], [3, 4], "Dryland training for skiing and snowboarding", "Low", False,
     lambda w, t: [snow_sport_prep(), snow_sport_prep(), snow_sport_prep()]),
    ("Adventure Race Prep", "Lifestyle/Outdoor Cardio", [4, 8, 12], [4, 5], "Multi-discipline race preparation with obstacles", "Low", True,
     lambda w, t: [adventure_race_prep(), adventure_race_prep(), adventure_race_prep()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat37_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Base: build movement capacity and learn terrain"
            elif p <= 0.66: focus = f"Week {w} - Build: increase distance, intensity, and skill"
            else: focus = f"Week {w} - Peak: simulate real outdoor conditions and distances"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 37 LIFESTYLE/OUTDOOR COMPLETE ===")

# ========================================================================
# CAT 38 - LONGEVITY & BIOHACKING (14 programs)
# ========================================================================

def zone_2_training():
    return wo("Zone 2 Training", "cardio", 45, [
        ex("Zone 2 Walk/Jog", 1, 1, 0, "30 minutes at 60-70% max HR", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "beginner", "Nose breathing, can hold conversation, fat-burning zone", "Brisk Walk"),
        ex("Mobility Cool Down", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Hip Flexors", ["Hamstrings", "Shoulders"], "beginner", "Light stretching post zone 2 work", "Standing Stretch"),
        ex("Diaphragmatic Breathing", 2, 10, 0, "Deep belly breaths", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale 4 seconds, hold 4, exhale 6, parasympathetic activation", "Box Breathing"),
    ])

def longevity_fitness():
    return wo("Longevity Fitness", "general", 40, [
        ex("Goblet Squat", 3, 10, 45, "Full depth", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat maintains hip mobility for life", "Bodyweight Squat"),
        ex("Farmer's Walk", 3, 1, 45, "30 meters moderate", "Dumbbell", "Full Body", "Forearms", ["Core", "Trapezius"], "beginner", "Grip strength correlates with longevity", "Suitcase Carry"),
        ex("Dead Hang", 2, 1, 30, "Hold 30 seconds", "Pull-Up Bar", "Arms", "Forearms", ["Shoulders"], "beginner", "Decompress spine, build grip endurance", "Active Hang"),
        ex("Push-Up", 3, 10, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Upper body pushing strength for daily life", "Incline Push-Up"),
        ex("Single-Leg Balance", 3, 1, 30, "30 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius"], "beginner", "Balance predicts fall risk and longevity", "Tandem Stand"),
        ex("Walking Lunge", 3, 8, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Maintain walking pattern strength", "Reverse Lunge"),
    ])

def cold_exposure_prep():
    return wo("Cold Exposure Prep", "general", 30, [
        ex("Wim Hof Breathing", 2, 30, 0, "30 breaths per round", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Deep inhale, passive exhale, 30 cycles, then hold", "Box Breathing"),
        ex("Bodyweight Squat", 3, 15, 30, "Generate heat", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Build metabolic heat before cold exposure", "Chair Squat"),
        ex("Push-Up", 3, 12, 30, "Fast pace", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Warm up body for cold tolerance", "Incline Push-Up"),
        ex("Burpee", 3, 8, 30, "Full body heat generation", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Metabolic heat before cold protocol", "Squat Thrust"),
        ex("Jumping Jack", 3, 20, 30, "Generate heat", "Bodyweight", "Full Body", "Deltoids", ["Calves"], "beginner", "Elevate heart rate and body temperature", "Step Jack"),
    ])

def heat_exposure_training():
    return wo("Heat Adaptation", "general", 30, [
        ex("Low-Intensity Walk", 1, 1, 0, "15 minutes easy", "Bodyweight", "Legs", "Quadriceps", ["Calves"], "beginner", "Easy walking to acclimate to heat gradually", "Brisk Walk"),
        ex("Bodyweight Squat", 3, 12, 30, "Moderate pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Build heat tolerance with compound movement", "Chair Squat"),
        ex("Push-Up", 3, 10, 30, "Steady pace", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Maintain output in warm conditions", "Incline Push-Up"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core work in heated conditions", "Knee Plank"),
        ex("Deep Breathing", 2, 10, 0, "Recovery breaths", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Nasal breathing, parasympathetic cool down", "Box Breathing"),
    ])

def vo2_max_training():
    return wo("VO2 Max Training", "cardio", 35, [
        ex("4x4 Interval", 4, 1, 180, "4 min at 90-95% max HR", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "advanced", "Run or row at near-max effort for 4 minutes, rest 3 min", "High Intensity Bike"),
        ex("Tabata Sprint", 4, 1, 10, "20 sec max, 10 sec rest", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "advanced", "All-out sprint for 20 seconds, 10 seconds rest x4", "Burpee"),
        ex("Cool Down Walk", 1, 1, 0, "5 minutes", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Easy walking to bring heart rate down", "Standing Rest"),
    ])

def mitochondrial_health():
    return wo("Mitochondrial Health", "general", 40, [
        ex("Zone 2 Jog", 1, 1, 0, "15 minutes at 60-70% max HR", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Steady aerobic work to build mitochondrial density", "Brisk Walk"),
        ex("Goblet Squat", 3, 10, 45, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Resistance training stimulates mitochondrial biogenesis", "Bodyweight Squat"),
        ex("Push-Up", 3, 12, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Upper body resistance for cellular health", "Incline Push-Up"),
        ex("Kettlebell Swing", 3, 15, 30, "Explosive", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "High intensity burst for mitochondrial stimulation", "Dumbbell Swing"),
        ex("Dead Hang", 2, 1, 30, "Hold 30 seconds", "Pull-Up Bar", "Arms", "Forearms", ["Shoulders"], "beginner", "Grip and spine decompression", "Active Hang"),
    ])

def joint_longevity():
    return wo("Joint Longevity", "mobility", 30, [
        ex("Cat-Cow", 2, 12, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Nourish spinal discs with movement", "Seated Cat-Cow"),
        ex("Hip Circle", 2, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Hip Adductors"], "beginner", "Big circles to lubricate hip joint", "Standing Hip Rotation"),
        ex("Ankle Circle", 2, 10, 0, "Each direction, each foot", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Full range ankle circles for joint health", "Calf Raise"),
        ex("Shoulder Circle", 2, 10, 0, "Each direction", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Big arm circles to maintain shoulder health", "Arm Circle"),
        ex("Wrist Circle", 2, 10, 0, "Each direction, each hand", "Bodyweight", "Arms", "Wrist Flexors", ["Wrist Extensors"], "beginner", "Full range circles for wrist health", "Wrist Stretch"),
        ex("Deep Squat Hold", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hip Adductors"], "beginner", "Asian squat hold for hip and knee longevity", "Bodyweight Squat"),
    ])

def spine_health():
    return wo("Spine Health", "mobility", 30, [
        ex("Cat-Cow", 3, 12, 0, "Slow and deliberate", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Nourish spinal discs, full flexion and extension", "Seated Cat-Cow"),
        ex("Bird Dog", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Anti-rotation and spinal stability", "Dead Bug"),
        ex("Dead Bug", 3, 10, 30, "Slow and controlled", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Low back pressed to floor, protect spine", "Bent-Knee Dead Bug"),
        ex("McGill Curl-Up", 3, 10, 30, "Hold 5 seconds each", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Hands under low back, tiny curl, spare spine", "Crunch"),
        ex("Side Plank", 2, 1, 30, "Hold 20 seconds each side", "Bodyweight", "Core", "Obliques", ["Quadratus Lumborum"], "beginner", "McGill big 3 for spine health", "Modified Side Plank"),
        ex("Thoracic Rotation", 2, 10, 0, "Each side", "Bodyweight", "Back", "Thoracic Erectors", ["Obliques"], "beginner", "Maintain thoracic mobility for spine health", "Seated Twist"),
    ])

def brain_body_connection():
    return wo("Brain-Body Connection", "general", 30, [
        ex("Cross-Body March", 2, 20, 30, "Opposite hand to knee", "Bodyweight", "Full Body", "Core", ["Hip Flexors", "Shoulders"], "beginner", "Touch right hand to left knee alternating, cross midline", "March in Place"),
        ex("Single-Leg Balance with Eyes Closed", 3, 1, 30, "Hold 15 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "intermediate", "Close eyes, challenge proprioception and vestibular system", "Single-Leg Balance"),
        ex("Juggling Practice", 2, 1, 0, "2 minutes", "Juggling Balls", "Full Body", "Forearms", ["Shoulders", "Core"], "beginner", "Start with 2 balls, builds hand-eye coordination", "Ball Toss"),
        ex("Tai Chi Slow Movement", 2, 1, 0, "3 minutes slow flow", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "beginner", "Slow deliberate movement, weight shifting, balance", "Yoga Flow"),
        ex("Contralateral Step Touch", 2, 15, 30, "Cross body pattern", "Bodyweight", "Full Body", "Hip Abductors", ["Core", "Shoulders"], "beginner", "Step to side, reach opposite hand across body", "Side Step"),
    ])

def anti_aging_movement():
    return wo("Anti-Aging Movement", "general", 35, [
        ex("Goblet Squat", 3, 10, 45, "Full depth", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Maintain squat depth throughout life", "Bodyweight Squat"),
        ex("Push-Up", 3, 10, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Upper body pushing strength maintenance", "Incline Push-Up"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pulling strength for daily tasks", "Band Row"),
        ex("Farmer's Walk", 3, 1, 45, "30 meters", "Dumbbell", "Full Body", "Forearms", ["Core", "Trapezius"], "beginner", "Grip strength predicts longevity", "Suitcase Carry"),
        ex("Single-Leg Balance", 3, 1, 30, "30 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius"], "beginner", "Balance is key anti-aging metric", "Tandem Stand"),
    ])

def hormesis_training():
    return wo("Hormesis Training", "general", 30, [
        ex("HIIT Sprint", 3, 30, 90, "30 seconds all-out", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Short intense burst triggers hormetic response", "High Knees"),
        ex("Bodyweight Squat Hold", 3, 1, 30, "Hold 30 seconds deep", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Isometric stress for adaptation", "Wall Sit"),
        ex("Cold Water Prep Breathing", 2, 20, 0, "20 deep breaths", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Prepare nervous system for stress exposure", "Box Breathing"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Moderate stress for adaptation response", "Knee Plank"),
        ex("Burpee", 3, 8, 30, "Controlled pace", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full body stress response training", "Squat Thrust"),
    ])

def fascia_training():
    return wo("Fascia Training", "mobility", 30, [
        ex("Foam Roll Full Body", 1, 1, 0, "5 minutes, all major areas", "Foam Roller", "Full Body", "Fascia", ["All Muscles"], "beginner", "Roll slowly, pause on tender spots 30 seconds", "Lacrosse Ball Rolling"),
        ex("Elastic Recoil Jump", 3, 10, 30, "Bouncy rebounds", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Achilles Tendon"], "beginner", "Small bouncy jumps, quick ground contact, elastic recoil", "Pogo Jump"),
        ex("Cat-Cow", 2, 12, 0, "Whole spine wave", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Undulating spinal wave, hydrate fascia", "Seated Wave"),
        ex("Arm Swing", 2, 20, 0, "Dynamic swings", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff", "Fascia"], "beginner", "Dynamic arm swings in all planes, rhythmic", "Arm Circle"),
        ex("Lateral Body Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi", "Intercostals"], "beginner", "Full lateral line stretch from foot to fingertip", "Side Bend"),
    ])

def autophagy_workout():
    return wo("Autophagy Workout", "general", 30, [
        ex("Fasted Walk", 1, 1, 0, "15 minutes easy", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Light movement in fasted state promotes cellular cleanup", "March in Place"),
        ex("Bodyweight Squat", 3, 12, 30, "Moderate pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Resistance in fasted state amplifies autophagy", "Chair Squat"),
        ex("Push-Up", 3, 10, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Upper body resistance in fasted state", "Incline Push-Up"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core engagement in fasted training", "Knee Plank"),
    ])

def circadian_rhythm_training():
    return wo("Circadian Rhythm Training", "general", 30, [
        ex("Morning Sun Walk", 1, 1, 0, "10 minutes outdoor walk", "Bodyweight", "Legs", "Quadriceps", ["Calves"], "beginner", "Morning light exposure resets circadian clock", "Indoor Walk"),
        ex("Bodyweight Squat", 3, 12, 30, "Morning energy boost", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Compound movement to boost morning cortisol", "Chair Squat"),
        ex("Push-Up", 3, 10, 30, "Energizing", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Upper body activation for daytime alertness", "Incline Push-Up"),
        ex("Evening Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Full Body", "Hamstrings", ["Hip Flexors", "Shoulders"], "beginner", "Evening parasympathetic stretching for sleep prep", "Seated Stretch"),
        ex("Diaphragmatic Breathing", 2, 10, 0, "Evening wind down", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "4-7-8 breathing pattern for sleep preparation", "Box Breathing"),
    ])

# Generate Cat 38 programs
cat38_programs = [
    ("Zone 2 Training Protocol", "Longevity & Biohacking", [4, 8, 12], [4, 5], "Optimal fat-burning zone 2 cardio for metabolic health", "High", False,
     lambda w, t: [zone_2_training(), zone_2_training(), zone_2_training()]),
    ("Longevity Fitness", "Longevity & Biohacking", [8, 12, 16], [4, 5], "Healthspan optimization through evidence-based exercise", "High", True,
     lambda w, t: [longevity_fitness(), longevity_fitness(), longevity_fitness()]),
    ("Cold Exposure Prep", "Longevity & Biohacking", [2, 4, 8], [3, 4], "Build cold tolerance with breathing and metabolic heat generation", "High", False,
     lambda w, t: [cold_exposure_prep(), cold_exposure_prep(), cold_exposure_prep()]),
    ("Heat Exposure Training", "Longevity & Biohacking", [2, 4, 8], [3, 4], "Heat adaptation with sauna-paired exercise protocols", "Med", False,
     lambda w, t: [heat_exposure_training(), heat_exposure_training(), heat_exposure_training()]),
    ("VO2 Max Training", "Longevity & Biohacking", [4, 8, 12], [3, 4], "Cardiovascular longevity through high-intensity intervals", "Low", False,
     lambda w, t: [vo2_max_training(), vo2_max_training(), vo2_max_training()]),
    ("Mitochondrial Health", "Longevity & Biohacking", [4, 8, 12], [4, 5], "Exercise protocols to optimize mitochondrial biogenesis", "Med", True,
     lambda w, t: [mitochondrial_health(), mitochondrial_health(), mitochondrial_health()]),
    ("Joint Longevity", "Longevity & Biohacking", [4, 8, 12], [4, 5], "Maintain joint health and range of motion for decades", "Med", False,
     lambda w, t: [joint_longevity(), joint_longevity(), joint_longevity()]),
    ("Spine Health", "Longevity & Biohacking", [4, 8, 12], [5, 6], "McGill-inspired spine health and back pain prevention", "Med", False,
     lambda w, t: [spine_health(), spine_health(), spine_health()]),
    ("Brain-Body Connection", "Longevity & Biohacking", [4, 8, 12], [4, 5], "Cross-body and coordination exercises for cognitive health", "Low", False,
     lambda w, t: [brain_body_connection(), brain_body_connection(), brain_body_connection()]),
    ("Anti-Aging Movement", "Longevity & Biohacking", [8, 12, 16], [4, 5], "Research-backed movement patterns to slow biological aging", "Med", True,
     lambda w, t: [anti_aging_movement(), anti_aging_movement(), anti_aging_movement()]),
    ("Hormesis Training", "Longevity & Biohacking", [4, 8], [3, 4], "Controlled stress exposure for cellular adaptation", "Med", False,
     lambda w, t: [hormesis_training(), hormesis_training(), hormesis_training()]),
    ("Fascia Training", "Longevity & Biohacking", [4, 8], [4, 5], "Fascial hydration and elasticity through bouncing and rolling", "Med", False,
     lambda w, t: [fascia_training(), fascia_training(), fascia_training()]),
    ("Autophagy Workout", "Longevity & Biohacking", [4, 8], [3, 4], "Fasted training protocols to promote cellular cleanup", "Med", True,
     lambda w, t: [autophagy_workout(), autophagy_workout(), autophagy_workout()]),
    ("Circadian Rhythm Training", "Longevity & Biohacking", [2, 4, 8], [5, 6], "Time-optimized workouts aligned with circadian biology", "Med", True,
     lambda w, t: [circadian_rhythm_training(), circadian_rhythm_training(), circadian_rhythm_training()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat38_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: establish baseline and learn protocols"
            elif p <= 0.66: focus = f"Week {w} - Optimization: refine protocols and increase stimulus"
            else: focus = f"Week {w} - Integration: combine protocols for peak health outcomes"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 38 LONGEVITY & BIOHACKING COMPLETE ===")

helper.close()
print("\n=== PART 2 (CATS 35-38) COMPLETE ===")
