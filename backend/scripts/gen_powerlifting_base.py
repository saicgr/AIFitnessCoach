#!/usr/bin/env python3
"""Generate Powerlifting Base program - Squat/Bench/Deadlift focus, 4x/week."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()
migration_num = helper.get_next_migration_num()

def ex(name, sets, reps, rest, weight, equip, body, muscle, secondary, diff, cue, sub):
    return {
        "name": name, "exercise_library_id": None, "in_library": False,
        "sets": sets, "reps": reps, "rest_seconds": rest,
        "weight_guidance": weight, "equipment": equip, "body_part": body,
        "primary_muscle": muscle, "secondary_muscles": secondary,
        "difficulty": diff, "form_cue": cue, "substitution": sub
    }

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# Powerlifting Base - 4 days/week
# Day 1: Heavy Squat + accessories
# Day 2: Heavy Bench + accessories
# Day 3: Light Squat + Volume Bench
# Day 4: Heavy Deadlift + accessories

def squat_heavy_day(week, total):
    p = week / total
    if p <= 0.25:
        main_s, main_r, main_w = 4, 5, "70-75% 1RM"
        acc_s, acc_r = 3, 10
    elif p <= 0.5:
        main_s, main_r, main_w = 5, 4, "75-80% 1RM"
        acc_s, acc_r = 3, 8
    elif p <= 0.75:
        main_s, main_r, main_w = 5, 3, "80-85% 1RM"
        acc_s, acc_r = 3, 8
    else:
        main_s, main_r, main_w = 4, 2, "85-90% 1RM"
        acc_s, acc_r = 2, 6
    return wo("Day 1 - Heavy Squat", "strength", 75, [
        ex("Barbell Back Squat", main_s, main_r, 240, main_w, "Barbell", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings", "Core"], "intermediate", "Break at hips, brace core, drive up", "Front Squat"),
        ex("Paused Squat", 3, 3, 180, "60-65% 1RM, 2-sec pause", "Barbell", "Legs", "Quadriceps",
           ["Glutes", "Core"], "intermediate", "Pause at bottom, stay tight", "Pin Squat"),
        ex("Bulgarian Split Squat", acc_s, acc_r, 90, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings"], "intermediate", "Upright torso, front knee tracks toe", "Reverse Lunge"),
        ex("Leg Press", acc_s, acc_r, 90, "Moderate-heavy", "Machine", "Legs", "Quadriceps",
           ["Glutes"], "beginner", "Full depth, don't lock knees", "Hack Squat"),
        ex("Leg Curl", 3, 12, 60, "Moderate", "Machine", "Legs", "Hamstrings",
           ["Calves"], "beginner", "Control the negative", "Nordic Curl"),
        ex("Ab Wheel Rollout", 3, 10, 60, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis",
           ["Obliques", "Hip Flexors"], "intermediate", "Tight core throughout, don't sag", "Plank"),
    ])

def bench_heavy_day(week, total):
    p = week / total
    if p <= 0.25:
        main_s, main_r, main_w = 4, 5, "70-75% 1RM"
    elif p <= 0.5:
        main_s, main_r, main_w = 5, 4, "75-80% 1RM"
    elif p <= 0.75:
        main_s, main_r, main_w = 5, 3, "80-85% 1RM"
    else:
        main_s, main_r, main_w = 4, 2, "85-90% 1RM"
    return wo("Day 2 - Heavy Bench", "strength", 75, [
        ex("Barbell Bench Press", main_s, main_r, 240, main_w, "Barbell", "Chest", "Pectoralis Major",
           ["Triceps", "Anterior Deltoid"], "intermediate", "Arch back, retract scapula, leg drive", "Dumbbell Bench Press"),
        ex("Close-Grip Bench Press", 3, 6, 120, "65-70% bench 1RM", "Barbell", "Chest", "Triceps",
           ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Hands shoulder width, elbows tucked", "Dumbbell Close-Grip Press"),
        ex("Overhead Press", 3, 8, 120, "Moderate-heavy", "Barbell", "Shoulders", "Anterior Deltoid",
           ["Triceps", "Upper Chest"], "intermediate", "Tight core, press straight up", "Dumbbell Shoulder Press"),
        ex("Dumbbell Flye", 3, 12, 60, "Light-moderate", "Dumbbells", "Chest", "Pectoralis Major",
           ["Anterior Deltoid"], "beginner", "Slight elbow bend, stretch at bottom", "Cable Flye"),
        ex("Triceps Pushdown", 3, 12, 60, "Moderate", "Cable Machine", "Arms", "Triceps",
           ["Anconeus"], "beginner", "Lock elbows at sides, full extension", "Dumbbell Kickback"),
        ex("Face Pull", 3, 15, 45, "Light", "Cable Machine", "Shoulders", "Rear Deltoid",
           ["Rhomboids", "External Rotators"], "beginner", "Pull to forehead, squeeze back", "Band Pull-Apart"),
    ])

def light_squat_volume_bench(week, total):
    p = week / total
    return wo("Day 3 - Light Squat / Volume Bench", "strength", 70, [
        ex("Barbell Back Squat", 3, 8, 120, "60-65% 1RM (light day)", "Barbell", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings"], "intermediate", "Focus on speed and technique", "Front Squat"),
        ex("Barbell Bench Press", 4, 8, 120, "65% 1RM (volume)", "Barbell", "Chest", "Pectoralis Major",
           ["Triceps", "Anterior Deltoid"], "intermediate", "Touch and go, consistent tempo", "Dumbbell Bench Press"),
        ex("Incline Dumbbell Press", 3, 10, 90, "Moderate", "Dumbbells", "Chest", "Upper Pectoralis",
           ["Anterior Deltoid", "Triceps"], "intermediate", "30-degree angle, controlled", "Incline Barbell Press"),
        ex("Dumbbell Lateral Raise", 3, 15, 45, "Light", "Dumbbells", "Shoulders", "Lateral Deltoid",
           ["Anterior Deltoid"], "beginner", "Slight bend in elbows, don't swing", "Cable Lateral Raise"),
        ex("Barbell Curl", 3, 10, 60, "Moderate", "Barbell", "Arms", "Biceps",
           ["Forearms"], "beginner", "No swinging, squeeze at top", "Dumbbell Curl"),
        ex("Hanging Leg Raise", 3, 12, 60, "Bodyweight", "Pull-Up Bar", "Core", "Lower Abdominals",
           ["Hip Flexors"], "intermediate", "Control swing, curl pelvis", "Lying Leg Raise"),
    ])

def deadlift_day(week, total):
    p = week / total
    if p <= 0.25:
        main_s, main_r, main_w = 3, 5, "70-75% 1RM"
    elif p <= 0.5:
        main_s, main_r, main_w = 4, 4, "75-80% 1RM"
    elif p <= 0.75:
        main_s, main_r, main_w = 4, 3, "80-85% 1RM"
    else:
        main_s, main_r, main_w = 3, 2, "85-92% 1RM"
    return wo("Day 4 - Heavy Deadlift", "strength", 75, [
        ex("Barbell Deadlift", main_s, main_r, 300, main_w, "Barbell", "Back", "Erector Spinae",
           ["Glutes", "Hamstrings", "Trapezius", "Forearms"], "intermediate", "Flat back, push floor away, lockout", "Trap Bar Deadlift"),
        ex("Deficit Deadlift", 3, 4, 180, "60-65% DL 1RM, 1-2 inch deficit", "Barbell", "Back", "Erector Spinae",
           ["Glutes", "Hamstrings"], "advanced", "Same form as regular, increased ROM", "Block Pull"),
        ex("Barbell Bent-Over Row", 4, 8, 90, "Moderate-heavy", "Barbell", "Back", "Latissimus Dorsi",
           ["Rhomboids", "Biceps"], "intermediate", "45-degree angle, pull to lower sternum", "Dumbbell Row"),
        ex("Pull-Up", 3, 8, 90, "Bodyweight or weighted", "Pull-Up Bar", "Back", "Latissimus Dorsi",
           ["Biceps", "Rear Deltoid"], "intermediate", "Full extension, pull to chin", "Lat Pulldown"),
        ex("Good Morning", 3, 10, 90, "Light-moderate barbell", "Barbell", "Back", "Erector Spinae",
           ["Hamstrings", "Glutes"], "intermediate", "Soft knees, hinge at hips", "Romanian Deadlift"),
        ex("Farmer's Walk", 3, 1, 90, "Heavy dumbbells, 40 yards", "Dumbbells", "Full Body", "Forearms",
           ["Trapezius", "Core", "Glutes"], "beginner", "Tall posture, tight grip, steady pace", "Suitcase Carry"),
    ])

def make_week(w, total):
    return [squat_heavy_day(w, total), bench_heavy_day(w, total),
            light_squat_volume_bench(w, total), deadlift_day(w, total)]

weeks_data = {}
for dur in [4, 8, 12, 16]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25:
            focus = f"Week {w} - Hypertrophy/Volume phase: moderate weight, higher reps"
        elif p <= 0.5:
            focus = f"Week {w} - Strength phase: increasing intensity, moderate volume"
        elif p <= 0.75:
            focus = f"Week {w} - Peaking phase: heavy singles/doubles/triples"
        elif p <= 0.9:
            focus = f"Week {w} - Taper: reduced volume, maintain intensity"
        else:
            focus = f"Week {w} - Test week: attempt new PRs on competition lifts"
        weeks[w] = {"focus": focus, "workouts": make_week(w, dur)}
    weeks_data[(dur, 4)] = weeks

success = helper.insert_full_program(
    program_name="Powerlifting Base",
    category_name="Strength",
    description="Squat/Bench/Deadlift focus with proper periodization for intermediate lifters",
    durations=[4, 8, 12, 16],
    sessions_per_week=[4],
    has_supersets=False,
    priority="High",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
if success:
    helper.update_tracker("Powerlifting Base", "Done")
    print("Powerlifting Base - ALL DONE")
else:
    print("Powerlifting Base - FAILED")
helper.close()
