#!/usr/bin/env python3
"""Generate 5x5 Linear Progression program - all anchor durations."""
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

# ============================================================================
# 5x5 Linear Progression - Based on Stronglifts/Starting Strength methodology
# Alternating Workout A and Workout B, 3x/week
# Progressive overload: add 5lbs each session for upper, 10lbs for lower
# ============================================================================

def make_workout_a(week, intensity_pct, add_weight):
    """Workout A: Squat, Bench, Barbell Row + accessories."""
    base = f"Week {week} base"
    return wo(f"Workout A", "strength", 60, [
        ex("Barbell Back Squat", 5, 5, 180, f"{intensity_pct}% 1RM, add {add_weight}lbs/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Break at hips first, chest up, drive through heels", "Goblet Squat"),
        ex("Barbell Bench Press", 5, 5, 180, f"{intensity_pct}% 1RM, add 5lbs/session", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, arch back slightly, touch mid-chest", "Dumbbell Bench Press"),
        ex("Barbell Bent-Over Row", 5, 5, 180, f"{intensity_pct}% 1RM, add 5lbs/session", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate", "45-degree torso angle, pull to lower chest", "Dumbbell Row"),
        ex("Barbell Curl", 2, 8, 60, "Moderate", "Barbell", "Arms", "Biceps", ["Forearms"], "beginner", "No swinging, control the weight", "Dumbbell Curl"),
        ex("Plank", 3, 1, 60, "Bodyweight, 45-60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Straight line from head to heels", "Dead Bug"),
    ])

def make_workout_b(week, intensity_pct, add_weight):
    """Workout B: Squat, Overhead Press, Deadlift + accessories."""
    return wo(f"Workout B", "strength", 60, [
        ex("Barbell Back Squat", 5, 5, 180, f"{intensity_pct}% 1RM, add {add_weight}lbs/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Break at hips first, chest up, drive through heels", "Goblet Squat"),
        ex("Overhead Press", 5, 5, 180, f"{intensity_pct}% 1RM, add 5lbs/session", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest", "Core"], "intermediate", "Tight core, press straight up, lock out overhead", "Dumbbell Shoulder Press"),
        ex("Barbell Deadlift", 1, 5, 180, f"{intensity_pct + 5}% 1RM, add 10lbs/session", "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings", "Trapezius", "Forearms"], "intermediate", "Push floor away, hips and shoulders rise together", "Trap Bar Deadlift"),
        ex("Chin-Up", 2, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Full extension, chin over bar", "Lat Pulldown"),
        ex("Hanging Leg Raise", 2, 10, 60, "Bodyweight", "Pull-Up Bar", "Core", "Lower Abdominals", ["Hip Flexors", "Obliques"], "intermediate", "Control the swing, curl pelvis up", "Lying Leg Raise"),
    ])

def make_week(week_num, total_weeks):
    """Generate a week with A/B/A pattern and proper progression."""
    # Progressive intensity
    progress = week_num / total_weeks
    if progress <= 0.25:
        intensity = 65
        add_wt = 5
    elif progress <= 0.5:
        intensity = 70
        add_wt = 5
    elif progress <= 0.75:
        intensity = 75
        add_wt = 5
    else:
        intensity = 80
        add_wt = 2.5

    # A/B/A for odd weeks, B/A/B for even weeks
    if week_num % 2 == 1:
        workouts = [
            make_workout_a(week_num, intensity, add_wt),
            make_workout_b(week_num, intensity, add_wt),
            make_workout_a(week_num, intensity, add_wt),
        ]
    else:
        workouts = [
            make_workout_b(week_num, intensity, add_wt),
            make_workout_a(week_num, intensity, add_wt),
            make_workout_b(week_num, intensity, add_wt),
        ]

    # Rename with day numbers
    for i, w in enumerate(workouts):
        w["workout_name"] = f"Day {i+1} - {w['workout_name']}"

    return workouts

# Build all anchor durations: 1w, 2w, 4w, 8w, 12w
weeks_data = {}

for duration in [1, 2, 4, 8, 12]:
    weeks = {}
    for w in range(1, duration + 1):
        focus_map = {
            1: "Introduction - Learning the lifts with light weight",
            2: "Form refinement and initial loading",
        }
        if duration <= 2:
            focus = focus_map.get(w, f"Week {w} - Progressive loading")
        else:
            progress = w / duration
            if progress <= 0.25:
                focus = f"Foundation - Learning movement patterns, light weight (Week {w})"
            elif progress <= 0.5:
                focus = f"Building - Adding weight consistently, form solidifying (Week {w})"
            elif progress <= 0.75:
                focus = f"Pushing - Heavier loads, grinding reps (Week {w})"
            elif progress <= 0.9:
                focus = f"Peaking - Near-max effort on compounds (Week {w})"
            else:
                focus = f"Deload/Test - Reduce volume, test new maxes (Week {w})"

        weeks[w] = {
            "focus": focus,
            "workouts": make_week(w, duration)
        }
    weeks_data[(duration, 3)] = weeks

success = helper.insert_full_program(
    program_name="5x5 Linear Progression",
    category_name="Strength",
    description="Classic linear progression - add weight every session. Based on Stronglifts methodology with alternating A/B workouts.",
    durations=[1, 2, 4, 8, 12],
    sessions_per_week=[3],
    has_supersets=False,
    priority="High",
    weeks_data=weeks_data,
    migration_num=migration_num,
)

if success:
    helper.update_tracker("5x5 Linear Progression", "Done")
    print("5x5 Linear Progression - ALL DONE")
else:
    print("5x5 Linear Progression - FAILED")

helper.close()
