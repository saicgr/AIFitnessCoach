#!/usr/bin/env python3
"""
Generate Equipment-Specific HIGH priority programs (Category 13).
Programs: Kettlebell Only, Kettlebell Flow, Kettlebell HIIT, Single Dumbbell HIIT
IMPORTANT: ONLY use the specified equipment per program.
"""
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent))
from program_sql_helper import ProgramSQLHelper


def ex(name, sets, reps, rest, guidance, equip, body, primary, secondary, diff, cue, sub):
    return {
        "name": name, "exercise_library_id": None, "in_library": False,
        "sets": sets, "reps": reps, "rest_seconds": rest,
        "weight_guidance": guidance, "equipment": equip,
        "body_part": body, "primary_muscle": primary,
        "secondary_muscles": secondary, "difficulty": diff,
        "form_cue": cue, "substitution": sub,
    }


def generate_kettlebell_only(helper, mig):
    """Kettlebell Only - 2,4,8,12w x 3-4/wk - Complete KB training. ONLY kettlebell exercises."""

    day1_lower = {
        "workout_name": "Day 1 - KB Lower Body Strength",
        "type": "strength",
        "exercises": [
            ex("Kettlebell Goblet Squat", 4, 12, 60, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hold KB at chest, sit deep, drive through heels", "KB Sumo Squat"),
            ex("Kettlebell Swing", 4, 15, 45, "Moderate-heavy KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip snap drives the bell, arms are along for the ride", "KB Deadlift"),
            ex("Kettlebell Single Leg Deadlift", 3, 10, 45, "Moderate KB", "Kettlebell", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Hinge at hip, KB in opposite hand of standing leg", "KB Romanian Deadlift"),
            ex("Kettlebell Lateral Lunge", 3, 10, 45, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Hip Adductors", "Gluteus Maximus"], "intermediate", "Hold KB at chest, step wide, sit back", "KB Goblet Squat"),
            ex("Kettlebell Sumo Deadlift", 3, 12, 60, "Heavy KB", "Kettlebell", "Legs", "Hamstrings", ["Gluteus Maximus", "Quadriceps", "Core"], "intermediate", "Wide stance, KB between feet, drive up", "KB Swing"),
            ex("Kettlebell Calf Raise", 3, 15, 30, "Moderate KB held at side", "Kettlebell", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Hold KB at side, rise on toes", "Bodyweight Calf Raise"),
        ],
    }

    day2_upper = {
        "workout_name": "Day 2 - KB Upper Body",
        "type": "strength",
        "exercises": [
            ex("Kettlebell Clean and Press", 4, 8, 60, "Moderate KB", "Kettlebell", "Full Body", "Anterior Deltoid", ["Latissimus Dorsi", "Triceps", "Core"], "intermediate", "Clean to rack, press overhead, control lowering", "KB Strict Press"),
            ex("Kettlebell Row", 4, 10, 45, "Moderate-heavy KB", "Kettlebell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull KB to hip, squeeze at top", "KB High Pull"),
            ex("Kettlebell Floor Press", 3, 10, 45, "Moderate KB", "Kettlebell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Lie on floor, press KB up, elbows touch floor each rep", "KB Push-Up on KB"),
            ex("Kettlebell Halo", 3, 10, 30, "Light-moderate KB", "Kettlebell", "Shoulders", "Deltoids", ["Trapezius", "Core"], "beginner", "Circle KB around head, keep core tight", "KB Overhead Hold"),
            ex("Kettlebell High Pull", 3, 12, 45, "Moderate KB", "Kettlebell", "Shoulders", "Rear Deltoid", ["Trapezius", "Biceps"], "intermediate", "Hip drive, pull to chin level, elbows high", "KB Upright Row"),
            ex("Kettlebell Crush Curl", 3, 12, 30, "Light KB held by horns", "Kettlebell", "Arms", "Biceps Brachii", ["Forearms"], "beginner", "Hold KB bottom-up by bell, curl up", "KB Hammer Curl"),
        ],
    }

    day3_full = {
        "workout_name": "Day 3 - KB Full Body Power",
        "type": "strength",
        "exercises": [
            ex("Kettlebell Turkish Get-Up", 3, 3, 60, "Moderate KB", "Kettlebell", "Full Body", "Core", ["Shoulders", "Hip Flexors", "Gluteus Maximus"], "intermediate", "Slow controlled rise from floor to standing and back", "KB Half Get-Up"),
            ex("Kettlebell Snatch", 4, 8, 60, "Moderate KB", "Kettlebell", "Full Body", "Shoulders", ["Core", "Gluteus Maximus", "Hamstrings"], "intermediate", "One motion floor to overhead, punch through at top", "KB Clean and Press"),
            ex("Kettlebell Front Squat", 3, 10, 60, "Moderate KB, rack position", "Kettlebell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "KB in rack, squat deep, elbows up", "KB Goblet Squat"),
            ex("Kettlebell Windmill", 3, 6, 45, "Light-moderate KB", "Kettlebell", "Core", "Obliques", ["Shoulders", "Hamstrings", "Hip Flexors"], "intermediate", "KB overhead, hinge to opposite foot, eyes on KB", "KB Side Bend"),
            ex("Kettlebell Swing to Squat", 3, 10, 45, "Moderate KB", "Kettlebell", "Full Body", "Gluteus Maximus", ["Quadriceps", "Hamstrings", "Core"], "intermediate", "Swing up, catch at chest, squat, press out, swing again", "KB Swing"),
            ex("Kettlebell Farmer's Walk", 3, 1, 45, "Heavy KBs - walk 30 sec", "Kettlebell", "Full Body", "Forearms", ["Trapezius", "Core", "Grip Strength"], "intermediate", "Tall posture, tight grip, controlled steps", "KB Suitcase Carry"),
        ],
    }

    day4_conditioning = {
        "workout_name": "Day 4 - KB Conditioning",
        "type": "circuit",
        "exercises": [
            ex("Kettlebell Swing", 5, 20, 30, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Powerful hip snap each rep", "KB Deadlift"),
            ex("Kettlebell Thruster", 3, 10, 45, "Moderate KB", "Kettlebell", "Full Body", "Quadriceps", ["Anterior Deltoid", "Triceps", "Core"], "intermediate", "Squat then press overhead in one motion", "KB Clean and Press"),
            ex("Kettlebell Alternating Snatch", 3, 12, 45, "Moderate KB", "Kettlebell", "Full Body", "Shoulders", ["Core", "Gluteus Maximus"], "intermediate", "Alternate arms each rep", "KB High Pull"),
            ex("Kettlebell Figure 8", 3, 12, 30, "Moderate KB", "Kettlebell", "Core", "Obliques", ["Hip Flexors", "Forearms"], "intermediate", "Pass KB through legs in figure-8 pattern", "KB Swing"),
            ex("Kettlebell Renegade Row", 3, 8, 45, "Two moderate KBs", "Kettlebell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank on KBs, row alternating sides", "KB Row"),
            ex("Kettlebell Overhead Carry", 3, 1, 30, "Moderate KB - walk 30 sec each arm", "Kettlebell", "Shoulders", "Deltoids", ["Core", "Trapezius"], "intermediate", "KB locked out overhead, walk controlled", "KB Farmer's Walk"),
        ],
    }

    w3 = [day1_lower, day2_upper, day3_full]
    w4 = [day1_lower, day2_upper, day3_full, day4_conditioning]

    weeks_data = {}

    weeks_data[(2, 3)] = {
        1: {"focus": "KB fundamentals - swing, squat, press technique", "workouts": w3},
        2: {"focus": "Increased load and volume", "workouts": w3},
    }
    weeks_data[(2, 4)] = {
        1: {"focus": "KB fundamentals with conditioning", "workouts": w4},
        2: {"focus": "Progressive loading across all days", "workouts": w4},
    }

    weeks_data[(4, 3)] = dict(weeks_data[(2, 3)])
    weeks_data[(4, 3)][3] = {"focus": "Advanced KB skills - snatch, TGU refinement", "workouts": w3}
    weeks_data[(4, 3)][4] = {"focus": "Peak performance, heavier KBs", "workouts": w3}
    weeks_data[(4, 4)] = dict(weeks_data[(2, 4)])
    weeks_data[(4, 4)][3] = {"focus": "Advanced skills with conditioning push", "workouts": w4}
    weeks_data[(4, 4)][4] = {"focus": "Peak performance week", "workouts": w4}

    weeks_data[(8, 3)] = dict(weeks_data[(4, 3)])
    weeks_data[(8, 3)][5] = {"focus": "Cycle 2 - heavier KB progression", "workouts": w3}
    weeks_data[(8, 3)][6] = {"focus": "Cycle 2 - volume increase", "workouts": w3}
    weeks_data[(8, 3)][7] = {"focus": "Cycle 2 - peak intensity", "workouts": w3}
    weeks_data[(8, 3)][8] = {"focus": "Deload and assessment", "workouts": w3}
    weeks_data[(8, 4)] = dict(weeks_data[(4, 4)])
    weeks_data[(8, 4)][5] = {"focus": "Cycle 2 with heavy conditioning", "workouts": w4}
    weeks_data[(8, 4)][6] = {"focus": "Cycle 2 volume peak", "workouts": w4}
    weeks_data[(8, 4)][7] = {"focus": "Cycle 2 peak performance", "workouts": w4}
    weeks_data[(8, 4)][8] = {"focus": "Deload and test", "workouts": w4}

    weeks_data[(12, 3)] = dict(weeks_data[(8, 3)])
    weeks_data[(12, 3)][9] = {"focus": "Cycle 3 - complex KB flows", "workouts": w3}
    weeks_data[(12, 3)][10] = {"focus": "Cycle 3 - progressive overload", "workouts": w3}
    weeks_data[(12, 3)][11] = {"focus": "Cycle 3 - peak", "workouts": w3}
    weeks_data[(12, 3)][12] = {"focus": "Final assessment, maintenance plan", "workouts": w3}
    weeks_data[(12, 4)] = dict(weeks_data[(8, 4)])
    weeks_data[(12, 4)][9] = {"focus": "Cycle 3 - complex flows + conditioning", "workouts": w4}
    weeks_data[(12, 4)][10] = {"focus": "Cycle 3 progressive overload", "workouts": w4}
    weeks_data[(12, 4)][11] = {"focus": "Cycle 3 peak week", "workouts": w4}
    weeks_data[(12, 4)][12] = {"focus": "Final assessment and plan", "workouts": w4}

    return helper.insert_full_program(
        program_name="Kettlebell Only",
        category_name="Equipment-Specific",
        description="Complete kettlebell training program using only kettlebells. Covers strength, power, conditioning, and mobility through fundamental KB movements including swings, cleans, presses, snatches, Turkish get-ups, and flows.",
        durations=[2, 4, 8, 12],
        sessions_per_week=[3, 4],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def generate_kettlebell_flow(helper, mig):
    """Kettlebell Flow - 1,2,4w x 4-5/wk - Continuous movement sequences. ONLY kettlebells."""

    day1 = {
        "workout_name": "Day 1 - Foundation Flow",
        "type": "circuit",
        "exercises": [
            ex("KB Deadlift to Swing", 3, 10, 30, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Deadlift first rep, transition to swings", "KB Swing"),
            ex("KB Clean to Rack Hold", 3, 8, 30, "Moderate KB", "Kettlebell", "Full Body", "Latissimus Dorsi", ["Biceps", "Core", "Forearms"], "intermediate", "Clean to rack, hold 3 sec, lower, repeat", "KB High Pull"),
            ex("KB Halo to Goblet Squat", 3, 8, 30, "Moderate KB", "Kettlebell", "Full Body", "Deltoids", ["Quadriceps", "Gluteus Maximus", "Core"], "intermediate", "Circle head once, then squat, repeat", "KB Goblet Squat"),
            ex("KB Swing to Park", 3, 10, 30, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Swing, hike back between legs, park. Reset and repeat.", "KB Deadlift"),
            ex("KB Around the World", 3, 10, 20, "Light-moderate KB", "Kettlebell", "Core", "Obliques", ["Forearms", "Shoulders"], "beginner", "Pass KB around body, switch directions halfway", "KB Figure 8"),
            ex("KB Overhead Hold Walk", 3, 1, 30, "Moderate KB - 20 sec/arm", "Kettlebell", "Shoulders", "Deltoids", ["Core", "Trapezius"], "intermediate", "Lock out overhead, walk slowly", "KB Rack Walk"),
        ],
    }

    day2 = {
        "workout_name": "Day 2 - Power Flow",
        "type": "circuit",
        "exercises": [
            ex("KB Swing to Clean", 3, 8, 30, "Moderate KB", "Kettlebell", "Full Body", "Gluteus Maximus", ["Latissimus Dorsi", "Biceps", "Core"], "intermediate", "Swing, catch into clean on upswing", "KB Clean"),
            ex("KB Clean to Press to Windmill", 3, 5, 45, "Light-moderate KB", "Kettlebell", "Full Body", "Shoulders", ["Obliques", "Hamstrings", "Core"], "intermediate", "Clean, press overhead, windmill down, return. Each side.", "KB Clean and Press"),
            ex("KB Snatch", 4, 8, 45, "Moderate KB", "Kettlebell", "Full Body", "Shoulders", ["Gluteus Maximus", "Core", "Hamstrings"], "intermediate", "One fluid motion floor to lockout", "KB Clean and Press"),
            ex("KB Figure 8 to Hold", 3, 10, 30, "Moderate KB", "Kettlebell", "Core", "Obliques", ["Hip Flexors", "Forearms"], "intermediate", "Figure-8 between legs, catch and hold at front", "KB Figure 8"),
            ex("KB Single Arm Swing", 3, 10, 30, "Moderate KB per arm", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core", "Grip Strength"], "intermediate", "Same as 2-hand swing but one arm, switch at top", "KB Two Hand Swing"),
            ex("KB Rack Walk to Press", 3, 1, 30, "Moderate KB - walk 15 sec, press 5", "Kettlebell", "Full Body", "Deltoids", ["Core", "Quadriceps"], "intermediate", "Walk in rack, stop and press, continue", "KB Overhead Walk"),
        ],
    }

    day3 = {
        "workout_name": "Day 3 - Strength Flow",
        "type": "strength",
        "exercises": [
            ex("KB Turkish Get-Up", 3, 3, 60, "Moderate KB", "Kettlebell", "Full Body", "Core", ["Shoulders", "Hip Flexors", "Gluteus Maximus"], "intermediate", "Slow and controlled, every position counts", "KB Half Get-Up"),
            ex("KB Front Squat to Press", 3, 8, 45, "Moderate KB", "Kettlebell", "Full Body", "Quadriceps", ["Anterior Deltoid", "Triceps", "Core"], "intermediate", "Squat with KB in rack, press at top", "KB Thruster"),
            ex("KB Row to Clean", 3, 8, 45, "Moderate KB", "Kettlebell", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Row from bent position, then clean to rack", "KB Row"),
            ex("KB Goblet Squat to Curl", 3, 10, 30, "Moderate KB", "Kettlebell", "Full Body", "Quadriceps", ["Biceps Brachii", "Gluteus Maximus"], "intermediate", "Squat holding bell, at bottom curl KB, stand", "KB Goblet Squat"),
            ex("KB Deadlift to High Pull", 3, 10, 45, "Moderate KB", "Kettlebell", "Full Body", "Hamstrings", ["Trapezius", "Rear Deltoid", "Core"], "intermediate", "Deadlift, then hip drive into high pull", "KB Swing to High Pull"),
            ex("KB Suitcase Carry", 3, 1, 30, "Heavy KB - 30 sec/side", "Kettlebell", "Core", "Obliques", ["Forearms", "Trapezius"], "intermediate", "One KB at side, walk tall, resist leaning", "KB Farmer's Walk"),
        ],
    }

    day4 = {
        "workout_name": "Day 4 - Endurance Flow",
        "type": "circuit",
        "exercises": [
            ex("KB Swing (2-Hand)", 5, 20, 20, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "20 unbroken swings, powerful hip snap each rep", "KB Deadlift"),
            ex("KB Clean and Jerk", 3, 8, 45, "Moderate KB", "Kettlebell", "Full Body", "Anterior Deltoid", ["Quadriceps", "Core", "Triceps"], "intermediate", "Clean to rack, dip and drive overhead", "KB Clean and Press"),
            ex("KB Alternating Swing", 3, 16, 30, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Grip Strength"], "intermediate", "Switch hands at the top of each swing", "KB Single Arm Swing"),
            ex("KB Squat and Rotate", 3, 10, 30, "Light-moderate KB", "Kettlebell", "Full Body", "Quadriceps", ["Obliques", "Shoulders"], "intermediate", "Goblet squat, at top rotate KB to one side", "KB Goblet Squat"),
            ex("KB Floor Press Alternating", 3, 10, 30, "Two moderate KBs", "Kettlebell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Lie on floor, press one at a time", "KB Floor Press"),
            ex("KB Farmer's Walk", 3, 1, 30, "Two heavy KBs - walk 40 sec", "Kettlebell", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Heavy grip challenge, tall posture", "KB Suitcase Carry"),
        ],
    }

    day5 = {
        "workout_name": "Day 5 - Recovery Flow",
        "type": "flexibility",
        "exercises": [
            ex("KB Halo", 3, 10, 20, "Light KB", "Kettlebell", "Shoulders", "Deltoids", ["Trapezius", "Core"], "beginner", "Slow circles, gentle warmup", "KB Around the World"),
            ex("KB Goblet Squat Hold", 3, 5, 30, "Light KB - hold 20 sec", "Kettlebell", "Legs", "Quadriceps", ["Hip Adductors", "Core"], "beginner", "Deep squat, use elbows to push knees open", "KB Goblet Squat"),
            ex("KB Arm Bar", 3, 4, 30, "Light KB - hold 20 sec/side", "Kettlebell", "Shoulders", "Rotator Cuff", ["Thoracic Spine", "Core"], "beginner", "Lie on side, KB overhead, open chest", "KB Overhead Hold"),
            ex("KB Around the World", 3, 10, 20, "Light KB", "Kettlebell", "Core", "Obliques", ["Forearms"], "beginner", "Slow pass around body", "KB Halo"),
            ex("KB Single Leg Deadlift (Light)", 3, 8, 30, "Light KB", "Kettlebell", "Legs", "Hamstrings", ["Gluteus Maximus"], "beginner", "Balance focus, gentle stretch", "KB Romanian Deadlift"),
            ex("KB Overhead Hold Walk", 3, 1, 20, "Light KB - 20 sec/arm", "Kettlebell", "Shoulders", "Deltoids", ["Core"], "beginner", "Gentle cooldown walk", "KB Rack Walk"),
        ],
    }

    w4 = [day1, day2, day3, day4]
    w5 = [day1, day2, day3, day4, day5]

    weeks_data = {}
    weeks_data[(1, 4)] = {1: {"focus": "Learn fundamental KB flow patterns", "workouts": w4}}
    weeks_data[(1, 5)] = {1: {"focus": "Complete KB flow introduction with recovery", "workouts": w5}}

    weeks_data[(2, 4)] = {
        1: {"focus": "Foundation flows and transitions", "workouts": w4},
        2: {"focus": "Increased speed and fluidity", "workouts": w4},
    }
    weeks_data[(2, 5)] = {
        1: {"focus": "Foundation with recovery day", "workouts": w5},
        2: {"focus": "Faster transitions, heavier KB", "workouts": w5},
    }

    weeks_data[(4, 4)] = dict(weeks_data[(2, 4)])
    weeks_data[(4, 4)][3] = {"focus": "Complex multi-move flows", "workouts": w4}
    weeks_data[(4, 4)][4] = {"focus": "Peak flow performance", "workouts": w4}
    weeks_data[(4, 5)] = dict(weeks_data[(2, 5)])
    weeks_data[(4, 5)][3] = {"focus": "Complex flows with recovery", "workouts": w5}
    weeks_data[(4, 5)][4] = {"focus": "Peak performance week", "workouts": w5}

    return helper.insert_full_program(
        program_name="Kettlebell Flow",
        category_name="Equipment-Specific",
        description="Continuous kettlebell movement sequences linking fundamental KB exercises into fluid flows. Develops coordination, grip endurance, and full-body conditioning through seamless transitions between swings, cleans, presses, snatches, and carries.",
        durations=[1, 2, 4],
        sessions_per_week=[4, 5],
        has_supersets=False,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def generate_kettlebell_hiit(helper, mig):
    """Kettlebell HIIT - 1,2,4w x 3-4/wk - High intensity KB intervals. ONLY kettlebells."""

    day1 = {
        "workout_name": "Day 1 - KB Swing Intervals",
        "type": "hiit",
        "exercises": [
            ex("KB Swing (2-Hand)", 5, 20, 30, "Moderate-heavy KB - 30 sec work", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Maximum power each rep, 30 sec on / 30 sec off", "KB Single Arm Swing"),
            ex("KB Goblet Squat", 4, 12, 30, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Deep squat, fast up, controlled down", "KB Sumo Squat"),
            ex("KB Clean", 4, 10, 30, "Moderate KB - alternating", "Kettlebell", "Full Body", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Explosive clean to rack, 5 per side", "KB High Pull"),
            ex("KB Snatch", 4, 8, 30, "Moderate KB - alternating", "Kettlebell", "Full Body", "Shoulders", ["Core", "Gluteus Maximus"], "intermediate", "Floor to lockout in one motion, 4/side", "KB Clean and Press"),
            ex("KB Push-Up on KB", 3, 10, 30, "Bodyweight with KB handles", "Kettlebell", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Hands on KB handles, deep push-up", "KB Floor Press"),
            ex("KB Farmer's Walk Sprint", 3, 1, 30, "Two KBs - fast walk 20 sec", "Kettlebell", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Walk as fast as controlled, grip hard", "KB Suitcase Carry"),
        ],
    }

    day2 = {
        "workout_name": "Day 2 - KB Complex Circuit",
        "type": "hiit",
        "exercises": [
            ex("KB Clean and Press", 4, 8, 45, "Moderate KB", "Kettlebell", "Full Body", "Anterior Deltoid", ["Latissimus Dorsi", "Triceps", "Core"], "intermediate", "Clean to rack, press overhead, lower in one motion", "KB Strict Press"),
            ex("KB Thruster", 4, 10, 30, "Moderate KB", "Kettlebell", "Full Body", "Quadriceps", ["Anterior Deltoid", "Triceps"], "intermediate", "Squat and press in one explosive motion", "KB Front Squat to Press"),
            ex("KB High Pull", 4, 12, 30, "Moderate KB", "Kettlebell", "Full Body", "Rear Deltoid", ["Trapezius", "Gluteus Maximus"], "intermediate", "Hip drive, pull to chin, elbow high", "KB Upright Row"),
            ex("KB Single Arm Swing", 4, 12, 30, "Moderate KB - 6/side", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Grip Strength"], "intermediate", "Powerful hip snap, one hand", "KB Two Hand Swing"),
            ex("KB Renegade Row", 3, 8, 30, "Two moderate KBs", "Kettlebell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank on KBs, row alternating, no rotation", "KB Row"),
            ex("KB Goblet Pulse Squat", 3, 15, 30, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Small pulses at bottom of squat", "KB Goblet Squat"),
        ],
    }

    day3 = {
        "workout_name": "Day 3 - KB Tabata-Style",
        "type": "hiit",
        "exercises": [
            ex("KB Swing", 8, 1, 10, "Moderate KB - 20 sec work / 10 sec rest x 8", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Classic Tabata: max reps in 20 sec, 10 sec rest", "KB Deadlift"),
            ex("KB Goblet Squat Jump", 3, 8, 30, "Light KB", "Kettlebell", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Hold light KB, squat and jump, soft landing", "KB Goblet Squat"),
            ex("KB Alternating Snatch", 4, 12, 30, "Moderate KB", "Kettlebell", "Full Body", "Shoulders", ["Core", "Gluteus Maximus"], "intermediate", "Switch hands at the top", "KB Clean"),
            ex("KB Figure 8", 3, 16, 30, "Moderate KB", "Kettlebell", "Core", "Obliques", ["Hip Flexors", "Forearms"], "intermediate", "Fast figure-8 between legs", "KB Around the World"),
            ex("KB Floor Press", 3, 12, 30, "Moderate KB - alternating", "Kettlebell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Explosive press from floor", "KB Push-Up"),
            ex("KB Swing Pyramid", 1, 1, 0, "10-15-20-15-10 reps, 15 sec rest between", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Ascending then descending rep scheme", "KB Swing"),
        ],
    }

    day4 = {
        "workout_name": "Day 4 - KB AMRAP Challenge",
        "type": "hiit",
        "exercises": [
            ex("KB Clean and Press", 3, 10, 30, "Moderate KB - 5/arm", "Kettlebell", "Full Body", "Anterior Deltoid", ["Latissimus Dorsi", "Triceps"], "intermediate", "As many quality reps as possible", "KB Push Press"),
            ex("KB Goblet Squat", 3, 15, 30, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Deep, fast reps", "KB Front Squat"),
            ex("KB Swing", 3, 20, 30, "Moderate-heavy KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Unbroken set", "KB Deadlift to Swing"),
            ex("KB Row", 3, 10, 30, "Moderate-heavy KB - 5/arm", "Kettlebell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Bent over, explosive pull", "KB High Pull"),
            ex("KB Overhead Carry", 3, 1, 30, "Moderate KB - 20 sec/arm", "Kettlebell", "Shoulders", "Deltoids", ["Core", "Trapezius"], "intermediate", "Active recovery between rounds", "KB Rack Walk"),
            ex("KB Sumo Deadlift High Pull", 3, 12, 30, "Moderate KB", "Kettlebell", "Full Body", "Trapezius", ["Gluteus Maximus", "Hamstrings", "Core"], "intermediate", "Wide stance, pull to chin", "KB High Pull"),
        ],
    }

    w3 = [day1, day2, day3]
    w4 = [day1, day2, day3, day4]

    weeks_data = {}
    weeks_data[(1, 3)] = {1: {"focus": "KB HIIT introduction - learn interval pacing", "workouts": w3}}
    weeks_data[(1, 4)] = {1: {"focus": "Full KB HIIT exposure including AMRAP", "workouts": w4}}

    weeks_data[(2, 3)] = {
        1: {"focus": "Foundation intervals - moderate intensity", "workouts": w3},
        2: {"focus": "Push intensity - shorter rest, more reps", "workouts": w3},
    }
    weeks_data[(2, 4)] = {
        1: {"focus": "Foundation with AMRAP challenge", "workouts": w4},
        2: {"focus": "Maximal effort all sessions", "workouts": w4},
    }

    weeks_data[(4, 3)] = dict(weeks_data[(2, 3)])
    weeks_data[(4, 3)][3] = {"focus": "Peak intensity - heavier KB, shorter rest", "workouts": w3}
    weeks_data[(4, 3)][4] = {"focus": "Test week - max output per session", "workouts": w3}
    weeks_data[(4, 4)] = dict(weeks_data[(2, 4)])
    weeks_data[(4, 4)][3] = {"focus": "Peak intensity across all formats", "workouts": w4}
    weeks_data[(4, 4)][4] = {"focus": "Final test - AMRAP records", "workouts": w4}

    return helper.insert_full_program(
        program_name="Kettlebell HIIT",
        category_name="Equipment-Specific",
        description="High-intensity interval training using only kettlebells. Includes swing intervals, complex circuits, Tabata protocols, and AMRAP challenges. Builds explosive power, cardiovascular conditioning, and mental toughness with nothing but a kettlebell.",
        durations=[1, 2, 4],
        sessions_per_week=[3, 4],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def generate_single_dumbbell_hiit(helper, mig):
    """Single Dumbbell HIIT - 1,2,4w x 3-4/wk - One dumbbell cardio circuits. ONLY one dumbbell."""

    day1 = {
        "workout_name": "Day 1 - Single DB Total Body Blast",
        "type": "hiit",
        "exercises": [
            ex("Single DB Thruster", 4, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Full Body", "Quadriceps", ["Anterior Deltoid", "Triceps", "Core"], "intermediate", "Squat holding DB at shoulder, press overhead as you stand", "Single DB Goblet Squat"),
            ex("Single DB Swing", 4, 15, 30, "Moderate DB", "Dumbbell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Two hands on one DB end, hip drive swing", "Single DB Sumo Deadlift"),
            ex("Single DB Snatch", 4, 8, 30, "Moderate DB - 4/side", "Dumbbell", "Full Body", "Shoulders", ["Core", "Gluteus Maximus", "Triceps"], "intermediate", "Floor to overhead in one motion, alternate arms", "Single DB Clean and Press"),
            ex("Single DB Renegade Row", 3, 8, 30, "Moderate DB", "Dumbbell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank, row with DB, switch hand at midpoint", "Single DB Row"),
            ex("Single DB Goblet Squat Jump", 3, 8, 30, "Light-moderate DB", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Hold DB at chest, squat and jump, soft land", "Single DB Goblet Squat"),
            ex("Single DB Russian Twist", 3, 16, 30, "Moderate DB", "Dumbbell", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate side to side holding DB", "Single DB Woodchop"),
            ex("Single DB Farmer's Walk", 3, 1, 20, "Heavy DB - 20 sec/side", "Dumbbell", "Core", "Obliques", ["Forearms", "Trapezius"], "intermediate", "One hand, resist leaning, walk fast", "Single DB Overhead Walk"),
        ],
    }

    day2 = {
        "workout_name": "Day 2 - Single DB Complex Circuit",
        "type": "hiit",
        "exercises": [
            ex("Single DB Clean and Press", 4, 8, 30, "Moderate DB - 4/side", "Dumbbell", "Full Body", "Anterior Deltoid", ["Biceps", "Core", "Legs"], "intermediate", "Clean from floor to shoulder, press up", "Single DB Push Press"),
            ex("Single DB Reverse Lunge", 4, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "intermediate", "Hold DB at shoulder, lunge back", "Single DB Split Squat"),
            ex("Single DB Row", 4, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Bent over, pull to hip, squeeze", "Single DB High Pull"),
            ex("Single DB Floor Press", 3, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Lie on floor, press one arm at a time", "Single DB Push-Up"),
            ex("Single DB Woodchop", 3, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Core", "Obliques", ["Shoulders", "Hip Flexors"], "intermediate", "High to low diagonal chop, rotate hips", "Single DB Russian Twist"),
            ex("Single DB Sumo Squat", 3, 12, 30, "Moderate-heavy DB", "Dumbbell", "Legs", "Quadriceps", ["Hip Adductors", "Gluteus Maximus"], "intermediate", "Wide stance, DB hangs at center, deep squat", "Single DB Goblet Squat"),
            ex("Single DB Overhead Walk", 3, 1, 20, "Moderate DB - 20 sec/arm", "Dumbbell", "Shoulders", "Deltoids", ["Core", "Trapezius"], "intermediate", "Lock out overhead, walk with control", "Single DB Farmer's Walk"),
        ],
    }

    day3 = {
        "workout_name": "Day 3 - Single DB Tabata",
        "type": "hiit",
        "exercises": [
            ex("Single DB Swing", 8, 1, 10, "Moderate DB - 20 sec work / 10 sec rest x 8", "Dumbbell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Max reps in 20 sec, 10 sec rest", "Single DB Sumo Deadlift"),
            ex("Single DB Goblet Squat", 4, 12, 30, "Moderate DB", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Deep and fast, maintain form", "Single DB Sumo Squat"),
            ex("Single DB High Pull", 4, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Full Body", "Rear Deltoid", ["Trapezius", "Core"], "intermediate", "Hip drive, pull to chin level", "Single DB Clean"),
            ex("Single DB Lateral Lunge", 3, 10, 30, "Moderate DB", "Dumbbell", "Legs", "Quadriceps", ["Hip Adductors", "Gluteus Maximus"], "intermediate", "Hold DB at chest, wide step", "Single DB Goblet Squat"),
            ex("Single DB Push-Up with Row", 3, 8, 30, "Moderate DB", "Dumbbell", "Full Body", "Pectoralis Major", ["Latissimus Dorsi", "Core"], "intermediate", "Push-up, row DB, switch hand at midpoint", "Single DB Floor Press"),
            ex("Single DB Curl to Press", 3, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Arms", "Biceps Brachii", ["Anterior Deltoid", "Triceps"], "intermediate", "Curl up, rotate, press overhead", "Single DB Clean and Press"),
        ],
    }

    day4 = {
        "workout_name": "Day 4 - Single DB AMRAP",
        "type": "hiit",
        "exercises": [
            ex("Single DB Thruster", 3, 10, 30, "Moderate DB - 5/side", "Dumbbell", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Max quality reps", "Single DB Push Press"),
            ex("Single DB Swing", 3, 20, 30, "Moderate DB", "Dumbbell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Unbroken set", "Single DB Sumo Deadlift"),
            ex("Single DB Clean and Press", 3, 8, 30, "Moderate DB", "Dumbbell", "Full Body", "Anterior Deltoid", ["Core", "Legs"], "intermediate", "Smooth transitions", "Single DB Push Press"),
            ex("Single DB Goblet Squat", 3, 15, 30, "Moderate DB", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Deep, fast, controlled", "Single DB Sumo Squat"),
            ex("Single DB Bent-Over Row", 3, 10, 30, "Moderate-heavy DB - 5/side", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull hard", "Single DB High Pull"),
            ex("Single DB Overhead Carry", 3, 1, 20, "Moderate DB - 20 sec/arm", "Dumbbell", "Shoulders", "Deltoids", ["Core"], "intermediate", "Active recovery carry", "Single DB Farmer's Walk"),
        ],
    }

    w3 = [day1, day2, day3]
    w4 = [day1, day2, day3, day4]

    weeks_data = {}
    weeks_data[(1, 3)] = {1: {"focus": "Single DB HIIT introduction", "workouts": w3}}
    weeks_data[(1, 4)] = {1: {"focus": "Full single DB HIIT with AMRAP", "workouts": w4}}

    weeks_data[(2, 3)] = {
        1: {"focus": "Learn single DB complexes at moderate intensity", "workouts": w3},
        2: {"focus": "Push pace - shorter rest, more reps", "workouts": w3},
    }
    weeks_data[(2, 4)] = {
        1: {"focus": "Foundation with AMRAP day", "workouts": w4},
        2: {"focus": "Maximal effort all sessions", "workouts": w4},
    }

    weeks_data[(4, 3)] = dict(weeks_data[(2, 3)])
    weeks_data[(4, 3)][3] = {"focus": "Peak intensity - heavier DB, less rest", "workouts": w3}
    weeks_data[(4, 3)][4] = {"focus": "Final test - beat previous records", "workouts": w3}
    weeks_data[(4, 4)] = dict(weeks_data[(2, 4)])
    weeks_data[(4, 4)][3] = {"focus": "Peak week across all formats", "workouts": w4}
    weeks_data[(4, 4)][4] = {"focus": "Record-breaking test week", "workouts": w4}

    return helper.insert_full_program(
        program_name="Single Dumbbell HIIT",
        category_name="Equipment-Specific",
        description="High-intensity interval training using only a single dumbbell. Perfect for home or travel workouts. Includes total body blasts, complex circuits, Tabata protocols, and AMRAP challenges all with just one dumbbell.",
        durations=[1, 2, 4],
        sessions_per_week=[3, 4],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def main():
    helper = ProgramSQLHelper()
    mig = helper.get_next_migration_num()

    programs = [
        ("Kettlebell Only", generate_kettlebell_only),
        ("Kettlebell Flow", generate_kettlebell_flow),
        ("Kettlebell HIIT", generate_kettlebell_hiit),
        ("Single Dumbbell HIIT", generate_single_dumbbell_hiit),
    ]

    results = {}
    for name, gen_func in programs:
        if helper.check_program_exists(name):
            print(f"  SKIP (exists): {name}")
            results[name] = "skipped"
            continue
        print(f"\nGenerating: {name} (migration #{mig})")
        try:
            success = gen_func(helper, mig)
            results[name] = "OK" if success else "FAILED"
            if success:
                helper.update_tracker(name, "Done", f"{mig}_program_*.sql")
            mig += 1
        except Exception as e:
            print(f"  ERROR: {e}")
            results[name] = f"ERROR: {e}"
            mig += 1

    print("\n=== Equipment-Specific Results ===")
    for name, status in results.items():
        print(f"  {name}: {status}")

    helper.close()


if __name__ == "__main__":
    main()
