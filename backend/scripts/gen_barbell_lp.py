#!/usr/bin/env python3
"""Generate Barbell LP (Linear Progression) program - beginner barbell fundamentals."""
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

# Barbell LP - Based on Starting Strength/Greyskull LP
# 3 days/week, full body, compound focused
# A: Squat, Press, Deadlift  |  B: Squat, Bench, Row
# Last set AMRAP (as many reps as possible) on Greyskull variation

def day_a(week, total, phase):
    """Day A: Squat, Press, Deadlift."""
    p = week / total
    if p <= 0.33:
        sq_w, pr_w, dl_w = "Empty bar to 65lbs", "Empty bar to 55lbs", "135lbs"
    elif p <= 0.66:
        sq_w, pr_w, dl_w = "95-135lbs", "65-85lbs", "155-185lbs"
    else:
        sq_w, pr_w, dl_w = "135-185lbs", "85-105lbs", "185-225lbs"

    return wo(f"Day A - Squat/Press/Deadlift", "strength", 55, [
        ex("Barbell Back Squat", 3, 5, 180, sq_w, "Barbell", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings", "Core"], "beginner",
           "Sit back and down, knees track toes, chest up", "Goblet Squat"),
        ex("Overhead Press", 3, 5, 180, pr_w, "Barbell", "Shoulders", "Anterior Deltoid",
           ["Triceps", "Upper Chest", "Core"], "beginner",
           "Tight core, elbows slightly forward, press straight up", "Dumbbell Shoulder Press"),
        ex("Barbell Deadlift", 1, 5, 300, dl_w, "Barbell", "Back", "Erector Spinae",
           ["Glutes", "Hamstrings", "Trapezius"], "beginner",
           "Flat back, push floor away, lockout at top", "Trap Bar Deadlift"),
        ex("Chin-Up", 2, 6, 90, "Bodyweight or assisted", "Pull-Up Bar", "Back", "Latissimus Dorsi",
           ["Biceps"], "beginner", "Full hang, chin over bar", "Band-Assisted Chin-Up"),
    ])

def day_b(week, total, phase):
    """Day B: Squat, Bench, Row."""
    p = week / total
    if p <= 0.33:
        sq_w, bn_w, rw_w = "Empty bar to 65lbs", "Empty bar to 65lbs", "65lbs"
    elif p <= 0.66:
        sq_w, bn_w, rw_w = "95-135lbs", "85-115lbs", "85-105lbs"
    else:
        sq_w, bn_w, rw_w = "135-185lbs", "115-155lbs", "105-135lbs"

    return wo(f"Day B - Squat/Bench/Row", "strength", 55, [
        ex("Barbell Back Squat", 3, 5, 180, sq_w, "Barbell", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings", "Core"], "beginner",
           "Sit back and down, knees track toes, chest up", "Goblet Squat"),
        ex("Barbell Bench Press", 3, 5, 180, bn_w, "Barbell", "Chest", "Pectoralis Major",
           ["Triceps", "Anterior Deltoid"], "beginner",
           "Retract scapula, feet flat, bar to mid-chest", "Dumbbell Bench Press"),
        ex("Barbell Bent-Over Row", 3, 5, 180, rw_w, "Barbell", "Back", "Latissimus Dorsi",
           ["Rhomboids", "Biceps", "Rear Deltoid"], "beginner",
           "45-degree torso, pull to lower chest", "Dumbbell Row"),
        ex("Plank", 3, 1, 60, "Hold 30-60 seconds", "Bodyweight", "Core", "Rectus Abdominis",
           ["Obliques", "Transverse Abdominis"], "beginner",
           "Straight line from head to heels, squeeze everything", "Dead Bug"),
    ])

def make_week(w, total):
    p = w / total
    if p <= 0.25:
        phase = "foundation"
    elif p <= 0.5:
        phase = "building"
    elif p <= 0.75:
        phase = "pushing"
    else:
        phase = "testing"

    if w % 2 == 1:
        workouts = [day_a(w, total, phase), day_b(w, total, phase), day_a(w, total, phase)]
    else:
        workouts = [day_b(w, total, phase), day_a(w, total, phase), day_b(w, total, phase)]

    for i, workout in enumerate(workouts):
        workout["workout_name"] = f"Day {i+1} - {workout['workout_name']}"
    return workouts

weeks_data = {}
for dur in [1, 2, 4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25:
            focus = f"Week {w} - Learning barbell basics with empty bar/light weight"
        elif p <= 0.5:
            focus = f"Week {w} - Adding weight, grooving movement patterns"
        elif p <= 0.75:
            focus = f"Week {w} - Consistent progression, building work capacity"
        else:
            focus = f"Week {w} - Pushing weights up, testing strength gains"
        weeks[w] = {"focus": focus, "workouts": make_week(w, dur)}
    weeks_data[(dur, 3)] = weeks

success = helper.insert_full_program(
    program_name="Barbell LP",
    category_name="Strength",
    description="Beginner barbell fundamentals - learn squat, bench, deadlift, press, and row with linear progression",
    durations=[1, 2, 4, 8, 12],
    sessions_per_week=[3],
    has_supersets=False,
    priority="High",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
if success:
    helper.update_tracker("Barbell LP", "Done")
    print("Barbell LP - ALL DONE")
else:
    print("Barbell LP - FAILED")
helper.close()
