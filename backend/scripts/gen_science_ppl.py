#!/usr/bin/env python3
"""Generate Science-Based PPL (Push/Pull/Legs) - 6x/week evidence-based bodybuilding."""
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

# Science-Based PPL - Based on Jeff Nippard / Renaissance Periodization style
# P/P/L/P/P/L, 6 days/week
# Heavy day (low rep) + Volume day (high rep) each muscle 2x/week
# Progressive overload via double progression

def push_heavy(week, total):
    """Push A - Heavy compounds + moderate accessories."""
    p = week / total
    sets_main = 4 if p < 0.75 else 3
    reps_main = 5 if p < 0.5 else (4 if p < 0.75 else 3)
    return wo("Push A (Heavy)", "hypertrophy", 65, [
        ex("Barbell Bench Press", sets_main, reps_main, 180, f"RPE 8-9", "Barbell", "Chest", "Pectoralis Major",
           ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, leg drive, controlled descent", "Dumbbell Bench Press"),
        ex("Overhead Press", 3, 8, 120, "RPE 7-8", "Barbell", "Shoulders", "Anterior Deltoid",
           ["Triceps", "Upper Chest", "Serratus"], "intermediate", "Tight core, slight lean back at start", "Dumbbell Shoulder Press"),
        ex("Incline Dumbbell Press", 3, 10, 90, "RPE 7-8, 30-degree incline", "Dumbbells", "Chest", "Upper Pectoralis",
           ["Anterior Deltoid", "Triceps"], "intermediate", "Elbows at 45 degrees, full stretch", "Incline Barbell Press"),
        ex("Dumbbell Lateral Raise", 4, 15, 45, "Light, strict form", "Dumbbells", "Shoulders", "Lateral Deltoid",
           ["Anterior Deltoid", "Trapezius"], "beginner", "Lead with elbows, slight pinky-up rotation", "Cable Lateral Raise"),
        ex("Overhead Triceps Extension", 3, 12, 60, "Moderate cable or dumbbell", "Cable Machine", "Arms", "Triceps Long Head",
           ["Triceps Lateral Head"], "beginner", "Full stretch overhead, elbows stay fixed", "Skull Crusher"),
        ex("Triceps Pushdown", 3, 15, 45, "Light-moderate", "Cable Machine", "Arms", "Triceps Lateral Head",
           ["Triceps Medial Head"], "beginner", "Lock elbows at sides, full contraction", "Diamond Push-Up"),
    ])

def push_volume(week, total):
    """Push B - Volume/hypertrophy focus."""
    return wo("Push B (Volume)", "hypertrophy", 65, [
        ex("Dumbbell Bench Press", 4, 10, 90, "RPE 7-8", "Dumbbells", "Chest", "Pectoralis Major",
           ["Triceps", "Anterior Deltoid"], "intermediate", "Full ROM, pause at bottom stretch", "Machine Chest Press"),
        ex("Seated Dumbbell Shoulder Press", 4, 10, 90, "RPE 7-8", "Dumbbells", "Shoulders", "Anterior Deltoid",
           ["Triceps", "Upper Chest"], "intermediate", "Controlled descent, don't bounce at bottom", "Machine Shoulder Press"),
        ex("Cable Flye", 3, 15, 60, "Light-moderate, constant tension", "Cable Machine", "Chest", "Pectoralis Major",
           ["Anterior Deltoid"], "beginner", "Slight bend in elbows, squeeze at peak", "Dumbbell Flye"),
        ex("Machine Lateral Raise", 3, 15, 45, "Moderate", "Machine", "Shoulders", "Lateral Deltoid",
           ["Anterior Deltoid"], "beginner", "Controlled, focus on mind-muscle connection", "Cable Lateral Raise"),
        ex("Close-Grip Bench Press", 3, 10, 90, "65-70% bench 1RM", "Barbell", "Chest", "Triceps",
           ["Pectoralis Major"], "intermediate", "Hands shoulder-width, elbows tucked", "Dumbbell Close-Grip Press"),
        ex("Cable Overhead Extension", 3, 15, 45, "Light", "Cable Machine", "Arms", "Triceps Long Head",
           ["Triceps Lateral Head"], "beginner", "Full stretch, squeeze at extension", "Dumbbell Kickback"),
    ])

def pull_heavy(week, total):
    """Pull A - Heavy back + moderate biceps."""
    p = week / total
    sets_main = 4 if p < 0.75 else 3
    return wo("Pull A (Heavy)", "hypertrophy", 65, [
        ex("Barbell Bent-Over Row", sets_main, 6, 120, "RPE 8-9", "Barbell", "Back", "Latissimus Dorsi",
           ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate", "45-degree torso, pull to lower chest", "T-Bar Row"),
        ex("Weighted Pull-Up", 4, 6, 120, "Add 10-25lbs", "Pull-Up Bar", "Back", "Latissimus Dorsi",
           ["Biceps", "Rear Deltoid", "Teres Major"], "advanced", "Full extension, pull to upper chest", "Lat Pulldown"),
        ex("Chest-Supported Row", 3, 10, 90, "Moderate dumbbells", "Dumbbells", "Back", "Rhomboids",
           ["Latissimus Dorsi", "Rear Deltoid"], "intermediate", "Chest on bench, squeeze shoulder blades", "Seated Cable Row"),
        ex("Face Pull", 4, 15, 45, "Light, external rotation at top", "Cable Machine", "Shoulders", "Rear Deltoid",
           ["Rhomboids", "External Rotators", "Lower Trapezius"], "beginner", "Pull to forehead, rotate hands out", "Band Pull-Apart"),
        ex("Barbell Curl", 3, 8, 60, "RPE 8, strict form", "Barbell", "Arms", "Biceps",
           ["Forearms", "Brachialis"], "beginner", "No swinging, full ROM", "Dumbbell Curl"),
        ex("Incline Dumbbell Curl", 3, 12, 45, "Light-moderate, full stretch", "Dumbbells", "Arms", "Biceps Long Head",
           ["Forearms"], "beginner", "Arms hang back, curl without swinging", "Cable Curl"),
    ])

def pull_volume(week, total):
    """Pull B - Volume back + biceps."""
    return wo("Pull B (Volume)", "hypertrophy", 65, [
        ex("Seated Cable Row", 4, 10, 90, "RPE 7-8, V-grip", "Cable Machine", "Back", "Rhomboids",
           ["Latissimus Dorsi", "Biceps"], "intermediate", "Pull to lower chest, squeeze 1 sec", "Machine Row"),
        ex("Lat Pulldown", 4, 10, 90, "RPE 7-8, wide grip", "Cable Machine", "Back", "Latissimus Dorsi",
           ["Biceps", "Teres Major"], "beginner", "Pull to upper chest, lean back slightly", "Pull-Up"),
        ex("Dumbbell Row", 3, 12, 60, "Moderate-heavy, each arm", "Dumbbells", "Back", "Latissimus Dorsi",
           ["Rhomboids", "Biceps"], "intermediate", "Support on bench, pull to hip", "Machine Row"),
        ex("Reverse Pec Deck", 3, 15, 45, "Light-moderate", "Machine", "Shoulders", "Rear Deltoid",
           ["Rhomboids"], "beginner", "Squeeze shoulder blades together", "Cable Reverse Flye"),
        ex("Hammer Curl", 3, 10, 60, "Moderate", "Dumbbells", "Arms", "Brachialis",
           ["Biceps", "Forearms"], "beginner", "Neutral grip, no swinging", "Cable Hammer Curl"),
        ex("Preacher Curl", 3, 12, 45, "Light-moderate", "EZ Bar", "Arms", "Biceps Short Head",
           ["Forearms"], "beginner", "Full extension, don't hyperextend elbows", "Machine Preacher Curl"),
    ])

def legs_heavy(week, total):
    """Legs A - Quad dominant heavy."""
    p = week / total
    sets_main = 4 if p < 0.75 else 3
    reps_main = 6 if p < 0.5 else (5 if p < 0.75 else 4)
    return wo("Legs A (Quad Focus)", "hypertrophy", 70, [
        ex("Barbell Back Squat", sets_main, reps_main, 180, "RPE 8-9", "Barbell", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings", "Core"], "intermediate", "Break at hips, chest up, drive through heels", "Leg Press"),
        ex("Romanian Deadlift", 3, 10, 120, "RPE 7-8", "Barbell", "Legs", "Hamstrings",
           ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, slight knee bend, feel hamstring stretch", "Dumbbell RDL"),
        ex("Leg Press", 3, 12, 90, "Moderate-heavy, feet high on platform", "Machine", "Legs", "Quadriceps",
           ["Glutes"], "beginner", "Full depth, don't lock knees, control negative", "Hack Squat"),
        ex("Leg Extension", 3, 15, 60, "RPE 8, hold 1 sec at top", "Machine", "Legs", "Quadriceps",
           ["Rectus Femoris"], "beginner", "Full extension, squeeze quad at top", "Sissy Squat"),
        ex("Seated Leg Curl", 3, 12, 60, "RPE 8", "Machine", "Legs", "Hamstrings",
           ["Calves"], "beginner", "Full ROM, control the negative", "Nordic Curl"),
        ex("Standing Calf Raise", 4, 12, 60, "Heavy, 2-sec pause at bottom", "Machine", "Legs", "Gastrocnemius",
           ["Soleus"], "beginner", "Full stretch at bottom, rise onto toes", "Seated Calf Raise"),
    ])

def legs_volume(week, total):
    """Legs B - Glute/hamstring emphasis volume."""
    return wo("Legs B (Glute/Ham Focus)", "hypertrophy", 70, [
        ex("Front Squat", 4, 8, 120, "RPE 7-8", "Barbell", "Legs", "Quadriceps",
           ["Core", "Upper Back", "Glutes"], "intermediate", "Elbows high, upright torso, full depth", "Goblet Squat"),
        ex("Hip Thrust", 4, 10, 90, "RPE 8-9, heavy barbell", "Barbell", "Glutes", "Gluteus Maximus",
           ["Hamstrings", "Core"], "intermediate", "Drive through heels, squeeze glutes at top", "Glute Bridge"),
        ex("Walking Lunges", 3, 12, 90, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps",
           ["Glutes", "Hamstrings"], "intermediate", "Long stride for glutes, upright torso", "Reverse Lunges"),
        ex("Lying Leg Curl", 3, 12, 60, "RPE 8", "Machine", "Legs", "Hamstrings",
           ["Calves"], "beginner", "Squeeze at top, slow negative", "Swiss Ball Leg Curl"),
        ex("Leg Extension", 3, 15, 45, "Light-moderate, drop set on last set", "Machine", "Legs", "Quadriceps",
           [], "beginner", "Full ROM, pump focus", "Sissy Squat"),
        ex("Seated Calf Raise", 4, 15, 45, "Moderate, 2-sec squeeze", "Machine", "Legs", "Soleus",
           ["Gastrocnemius"], "beginner", "Full stretch, squeeze at top", "Standing Calf Raise"),
    ])

def make_week(w, total):
    """Generate PPL/PPL week."""
    return [
        push_heavy(w, total),
        pull_heavy(w, total),
        legs_heavy(w, total),
        push_volume(w, total),
        pull_volume(w, total),
        legs_volume(w, total),
    ]

weeks_data = {}
for dur in [4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25:
            focus = f"Week {w} - Accumulation: moderate weight, focus on form and volume"
        elif p <= 0.5:
            focus = f"Week {w} - Intensification: increase weight, maintain volume"
        elif p <= 0.75:
            focus = f"Week {w} - Overreaching: peak volume, push RPE to 9"
        elif p <= 0.9:
            focus = f"Week {w} - Deload: reduce volume 40%, maintain intensity"
        else:
            focus = f"Week {w} - Resensitization: fresh start with higher baseline"
        weeks[w] = {"focus": focus, "workouts": make_week(w, dur)}
    weeks_data[(dur, 6)] = weeks

success = helper.insert_full_program(
    program_name="Science-Based PPL",
    category_name="Hypertrophy/Muscle Building",
    description="Evidence-based Push/Pull/Legs split hitting each muscle 2x/week with optimal volume",
    durations=[4, 8, 12],
    sessions_per_week=[6],
    has_supersets=True,
    priority="High",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
if success:
    helper.update_tracker("Science-Based PPL", "Done")
    print("Science-Based PPL - ALL DONE")
else:
    print("Science-Based PPL - FAILED")
helper.close()
