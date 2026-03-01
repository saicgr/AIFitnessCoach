#!/usr/bin/env python3
"""Generate Strong Foundations program - beginner-friendly 3x/week full body."""
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

# Strong Foundations - True beginner program
# 3 days/week, full body, machine + dumbbell friendly
# Focus on learning movement patterns with manageable loads

def day1(week, total):
    """Day 1 - Lower Body Focus + Push."""
    p = week / total
    if p <= 0.33:
        reps, sets = 12, 2
        wg = "Very light - focus on form"
    elif p <= 0.66:
        reps, sets = 10, 3
        wg = "Light-moderate"
    else:
        reps, sets = 8, 3
        wg = "Moderate - challenging last 2 reps"

    return wo("Day 1 - Lower Body & Push", "strength", 50, [
        ex("Goblet Squat", sets, reps, 90, wg, "Dumbbell", "Legs", "Quadriceps",
           ["Glutes", "Core"], "beginner", "Hold dumbbell at chest, sit back and down, knees out", "Bodyweight Squat"),
        ex("Dumbbell Bench Press", sets, reps, 90, wg, "Dumbbells", "Chest", "Pectoralis Major",
           ["Triceps", "Anterior Deltoid"], "beginner", "Control the weight down, press up evenly", "Push-Up"),
        ex("Dumbbell Romanian Deadlift", sets, reps, 90, wg, "Dumbbells", "Legs", "Hamstrings",
           ["Glutes", "Lower Back"], "beginner", "Soft knees, push hips back, feel hamstring stretch", "Bodyweight Good Morning"),
        ex("Seated Dumbbell Shoulder Press", sets, reps, 60, wg, "Dumbbells", "Shoulders", "Anterior Deltoid",
           ["Triceps"], "beginner", "Press straight up, don't arch excessively", "Machine Shoulder Press"),
        ex("Leg Press", sets, reps, 90, wg, "Machine", "Legs", "Quadriceps",
           ["Glutes"], "beginner", "Feet shoulder width, full range of motion", "Bodyweight Squat"),
        ex("Plank", 3, 1, 60, "Hold 20-40 seconds", "Bodyweight", "Core", "Rectus Abdominis",
           ["Obliques"], "beginner", "Straight line, squeeze abs and glutes", "Dead Bug"),
    ])

def day2(week, total):
    """Day 2 - Upper Body Focus."""
    p = week / total
    if p <= 0.33:
        reps, sets = 12, 2
        wg = "Very light"
    elif p <= 0.66:
        reps, sets = 10, 3
        wg = "Light-moderate"
    else:
        reps, sets = 8, 3
        wg = "Moderate"

    return wo("Day 2 - Upper Body", "strength", 50, [
        ex("Lat Pulldown", sets, reps, 90, wg, "Cable Machine", "Back", "Latissimus Dorsi",
           ["Biceps", "Rear Deltoid"], "beginner", "Pull to upper chest, squeeze shoulder blades", "Band-Assisted Pull-Up"),
        ex("Dumbbell Incline Press", sets, reps, 90, wg, "Dumbbells", "Chest", "Upper Pectoralis",
           ["Triceps", "Anterior Deltoid"], "beginner", "30-degree incline, elbows at 45", "Incline Push-Up"),
        ex("Seated Cable Row", sets, reps, 90, wg, "Cable Machine", "Back", "Rhomboids",
           ["Latissimus Dorsi", "Biceps"], "beginner", "Sit tall, pull to belly button", "Dumbbell Row"),
        ex("Dumbbell Lateral Raise", sets, 12, 45, "Light", "Dumbbells", "Shoulders", "Lateral Deltoid",
           ["Anterior Deltoid"], "beginner", "Slight bend in elbows, raise to shoulder height", "Cable Lateral Raise"),
        ex("Dumbbell Curl", sets, reps, 60, wg, "Dumbbells", "Arms", "Biceps",
           ["Forearms"], "beginner", "Alternate arms, no swinging", "Band Curl"),
        ex("Triceps Pushdown", sets, reps, 60, wg, "Cable Machine", "Arms", "Triceps",
           [], "beginner", "Lock elbows at sides, full extension", "Chair Dips"),
    ])

def day3(week, total):
    """Day 3 - Full Body."""
    p = week / total
    if p <= 0.33:
        reps, sets = 12, 2
        wg = "Very light"
    elif p <= 0.66:
        reps, sets = 10, 3
        wg = "Light-moderate"
    else:
        reps, sets = 8, 3
        wg = "Moderate"

    return wo("Day 3 - Full Body", "strength", 50, [
        ex("Leg Press", sets, reps, 90, wg, "Machine", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings"], "beginner", "Feet shoulder width, full ROM", "Goblet Squat"),
        ex("Machine Chest Press", sets, reps, 90, wg, "Machine", "Chest", "Pectoralis Major",
           ["Triceps"], "beginner", "Push evenly, don't lock elbows", "Push-Up"),
        ex("Leg Curl", sets, reps, 60, wg, "Machine", "Legs", "Hamstrings",
           [], "beginner", "Control the negative, squeeze at top", "Dumbbell RDL"),
        ex("Machine Row", sets, reps, 90, wg, "Machine", "Back", "Latissimus Dorsi",
           ["Biceps", "Rhomboids"], "beginner", "Pull to lower chest, squeeze", "Dumbbell Row"),
        ex("Dumbbell Step-Up", sets, reps, 60, wg, "Dumbbell", "Legs", "Quadriceps",
           ["Glutes"], "beginner", "Drive through front foot, control descent", "Bodyweight Step-Up"),
        ex("Bird Dog", 3, 10, 45, "Bodyweight, alternate sides", "Bodyweight", "Core", "Erector Spinae",
           ["Glutes", "Core"], "beginner", "Extend opposite arm and leg, keep hips level", "Dead Bug"),
    ])

def make_week(w, total):
    return [day1(w, total), day2(w, total), day3(w, total)]

weeks_data = {}
for dur in [2, 4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.33:
            focus = f"Week {w} - Introduction: learning movements with light weight"
        elif p <= 0.66:
            focus = f"Week {w} - Building: increasing weight gradually"
        else:
            focus = f"Week {w} - Progressing: challenging weights, building confidence"
        weeks[w] = {"focus": focus, "workouts": make_week(w, dur)}
    weeks_data[(dur, 3)] = weeks

success = helper.insert_full_program(
    program_name="Strong Foundations",
    category_name="Strength",
    description="Beginner-friendly 3-day full body program focusing on fundamental movement patterns",
    durations=[2, 4, 8],
    sessions_per_week=[3],
    has_supersets=False,
    priority="High",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
if success:
    helper.update_tracker("Strong Foundations", "Done")
    print("Strong Foundations - ALL DONE")
else:
    print("Strong Foundations - FAILED")
helper.close()
