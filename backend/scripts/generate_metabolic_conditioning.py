#!/usr/bin/env python3
"""Generate Metabolic Conditioning - Fat Loss Category (High Priority)
Durations: 2, 4, 8w | Sessions: 4-5/wk | Supersets: Yes
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from program_sql_helper import ProgramSQLHelper

def build_weeks_data():
    weeks_data = {}

    # ========== 2 WEEKS, 4 sessions/week ==========
    weeks_data[(2, 4)] = {
        1: {
            "focus": "Circuit Foundation - Build Work Capacity",
            "workouts": [
                {
                    "workout_name": "Day 1 - Full Body Circuit A",
                    "type": "conditioning",
                    "duration_minutes": 40,
                    "exercises": [
                        {"name": "Kettlebell Swings", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Powerful hip snap, arms passive", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
                        {"name": "Dumbbell Push Press", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Dip knees, drive DBs overhead", "substitution": "Overhead Press", "exercise_library_id": None, "in_library": False},
                        {"name": "Goblet Squat", "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy dumbbell", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Sit deep, elbows between knees", "substitution": "Bodyweight Squat", "exercise_library_id": None, "in_library": False},
                        {"name": "Renegade Rows", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Plank position, row alternating, keep hips square", "substitution": "Bent Over Row", "exercise_library_id": None, "in_library": False},
                        {"name": "Box Jumps", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "20-24 inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Swing arms, land softly on box", "substitution": "Step-Ups", "exercise_library_id": None, "in_library": False},
                        {"name": "Battle Ropes", "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms"], "difficulty": "intermediate", "form_cue": "Alternating waves, stay low", "substitution": "Jumping Jacks", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 2 - Upper Body Metabolic",
                    "type": "conditioning",
                    "duration_minutes": 40,
                    "exercises": [
                        {"name": "Dumbbell Bench Press", "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate weight, fast tempo", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Controlled lower, explosive press", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
                        {"name": "Pull-Ups", "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight or assisted", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "intermediate", "form_cue": "Full hang to chin over bar", "substitution": "Lat Pulldown", "exercise_library_id": None, "in_library": False},
                        {"name": "Arnold Press", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Rotate palms as you press up", "substitution": "Shoulder Press", "exercise_library_id": None, "in_library": False},
                        {"name": "TRX Row", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight, adjust angle", "equipment": "TRX", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "beginner", "form_cue": "Body straight, pull chest to hands", "substitution": "Inverted Row", "exercise_library_id": None, "in_library": False},
                        {"name": "Medicine Ball Slams", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "15-20 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "intermediate", "form_cue": "Overhead to slam with max force", "substitution": "Dumbbell Woodchops", "exercise_library_id": None, "in_library": False},
                        {"name": "Dumbbell Tricep Kickback to Curl", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Kickback, then stand and curl", "substitution": "Dumbbell Curls + Pushdowns", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 3 - Lower Body Metabolic",
                    "type": "conditioning",
                    "duration_minutes": 45,
                    "exercises": [
                        {"name": "Barbell Back Squat", "sets": 4, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate - RPE 7", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
                        {"name": "Romanian Deadlift", "sets": 4, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, bar slides down thighs", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
                        {"name": "Dumbbell Walking Lunges", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Long stride, upright torso", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Sumo Squat", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Heavy kettlebell", "equipment": "Kettlebell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Adductors", "Glutes"], "difficulty": "beginner", "form_cue": "Wide stance, toes out, sit deep", "substitution": "Sumo Squat", "exercise_library_id": None, "in_library": False},
                        {"name": "Jump Squats", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up, soft landing", "substitution": "Bodyweight Squats", "exercise_library_id": None, "in_library": False},
                        {"name": "Sled Push", "sets": 4, "reps": 30, "rest_seconds": 45, "weight_guidance": "Moderate load, 30m", "equipment": "Sled", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Low angle, drive through legs", "substitution": "Walking Lunges", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 4 - Conditioning Finisher",
                    "type": "conditioning",
                    "duration_minutes": 35,
                    "exercises": [
                        {"name": "Thrusters", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps", "Glutes"], "difficulty": "intermediate", "form_cue": "Squat deep, press overhead in one motion", "substitution": "Goblet Squat to Press", "exercise_library_id": None, "in_library": False},
                        {"name": "Rowing Machine Intervals", "sets": 5, "reps": 250, "rest_seconds": 45, "weight_guidance": "250m sprint rows", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Core", "Arms"], "difficulty": "intermediate", "form_cue": "Drive with legs, lean back, pull to chest", "substitution": "Assault Bike", "exercise_library_id": None, "in_library": False},
                        {"name": "Burpees", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight - max speed", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump explosively", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False},
                        {"name": "Farmer's Walk", "sets": 3, "reps": 40, "rest_seconds": 45, "weight_guidance": "Heavy DBs, 40m walks", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Traps", "Core", "Legs"], "difficulty": "beginner", "form_cue": "Tall posture, brisk pace", "substitution": "Suitcase Carry", "exercise_library_id": None, "in_library": False},
                        {"name": "Medicine Ball Wall Sit Throws", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "10-15 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Hold wall sit, throw and catch ball", "substitution": "Wall Balls", "exercise_library_id": None, "in_library": False},
                        {"name": "Mountain Climbers", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Drive knees to chest rapidly", "substitution": "Plank", "exercise_library_id": None, "in_library": False}
                    ]
                }
            ]
        },
        2: {
            "focus": "Intensity Ramp - Reduced Rest, Higher Volume",
            "workouts": [
                {
                    "workout_name": "Day 1 - Barbell Complex Day",
                    "type": "conditioning",
                    "duration_minutes": 45,
                    "exercises": [
                        {"name": "Barbell Complex (Deadlift + Row + Hang Clean + Front Squat + Push Press)", "sets": 5, "reps": 6, "rest_seconds": 60, "weight_guidance": "Light to moderate barbell - no rest between movements", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Legs", "Back", "Shoulders"], "difficulty": "advanced", "form_cue": "Flow through all 5 movements, 6 reps each", "substitution": "Dumbbell Complex", "exercise_library_id": None, "in_library": False},
                        {"name": "Assault Bike Sprints", "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "15-calorie sprints", "equipment": "Assault Bike", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Arms", "Core"], "difficulty": "intermediate", "form_cue": "Max effort each interval", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Turkish Get-Up", "sets": 3, "reps": 4, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Glutes", "Legs"], "difficulty": "advanced", "form_cue": "Slow and controlled, eyes on weight", "substitution": "Windmill", "exercise_library_id": None, "in_library": False},
                        {"name": "Wall Balls", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "14-20 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Deep squat, throw to 10ft target", "substitution": "Thrusters", "exercise_library_id": None, "in_library": False},
                        {"name": "Double Unders", "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "Jump rope - 30 reps", "equipment": "Jump Rope", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Wrists drive the rope, slight bounce", "substitution": "Single Unders (60 reps)", "exercise_library_id": None, "in_library": False},
                        {"name": "Plank to Push-Up", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Chest", "Triceps"], "difficulty": "intermediate", "form_cue": "Alternate lead arm, minimize hip sway", "substitution": "Plank Hold", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 2 - Dumbbell Metabolic Circuit",
                    "type": "conditioning",
                    "duration_minutes": 40,
                    "exercises": [
                        {"name": "Dumbbell Clean and Press", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Legs", "Core", "Traps"], "difficulty": "intermediate", "form_cue": "Clean to shoulders, press overhead", "substitution": "Kettlebell Clean and Press", "exercise_library_id": None, "in_library": False},
                        {"name": "Dumbbell Reverse Lunge to Curl", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Biceps"], "difficulty": "intermediate", "form_cue": "Lunge back, curl at bottom, stand up", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
                        {"name": "Dumbbell Bench Over Row", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Hinge over, pull to chest, squeeze", "substitution": "Bent Over Row", "exercise_library_id": None, "in_library": False},
                        {"name": "Devil Press", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Light to moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Shoulders", "Legs"], "difficulty": "advanced", "form_cue": "Burpee with DBs, snatch overhead", "substitution": "Burpee to Press", "exercise_library_id": None, "in_library": False},
                        {"name": "Dumbbell Squat to Press", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps"], "difficulty": "intermediate", "form_cue": "Deep squat, drive up and press", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
                        {"name": "V-Ups", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Touch toes at top, lower with control", "substitution": "Crunches", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 3 - Kettlebell Conditioning",
                    "type": "conditioning",
                    "duration_minutes": 40,
                    "exercises": [
                        {"name": "Kettlebell Snatch", "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate kettlebell, each arm", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Explosive hip drive, punch through at top", "substitution": "Kettlebell Swings", "exercise_library_id": None, "in_library": False},
                        {"name": "Double Kettlebell Front Squat", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate kettlebells", "equipment": "Kettlebells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Glutes"], "difficulty": "intermediate", "form_cue": "KBs in rack position, sit deep", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Clean", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Biceps", "Core", "Forearms"], "difficulty": "intermediate", "form_cue": "Swing to rack position, absorb with legs", "substitution": "Dumbbell Clean", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Windmill", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Kettlebell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Hamstrings"], "difficulty": "intermediate", "form_cue": "KB overhead, hinge to touch floor", "substitution": "Side Bends", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Swings", "sets": 4, "reps": 20, "rest_seconds": 20, "weight_guidance": "Heavy kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap, bell to chest height", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Halo", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light to moderate", "equipment": "Kettlebell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Triceps"], "difficulty": "beginner", "form_cue": "Circle KB around head, alternate directions", "substitution": "Plate Halos", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 4 - AMRAP Challenge",
                    "type": "conditioning",
                    "duration_minutes": 35,
                    "exercises": [
                        {"name": "Power Clean", "sets": 4, "reps": 5, "rest_seconds": 45, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Traps", "Shoulders"], "difficulty": "advanced", "form_cue": "Explosive extension, catch in front rack", "substitution": "Hang Clean", "exercise_library_id": None, "in_library": False},
                        {"name": "Box Jump Overs", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "20-24 inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Jump over, turn and repeat", "substitution": "Step-Ups", "exercise_library_id": None, "in_library": False},
                        {"name": "Man Makers", "sets": 3, "reps": 6, "rest_seconds": 45, "weight_guidance": "Light to moderate DBs", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Back", "Shoulders", "Legs"], "difficulty": "advanced", "form_cue": "Push-up, row each arm, squat clean, press", "substitution": "Burpee to Press", "exercise_library_id": None, "in_library": False},
                        {"name": "Sled Pull", "sets": 3, "reps": 30, "rest_seconds": 45, "weight_guidance": "Moderate load, 30m", "equipment": "Sled", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Biceps", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Face sled, pull hand over hand", "substitution": "Rowing Machine", "exercise_library_id": None, "in_library": False},
                        {"name": "Sprawls", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Core", "Legs"], "difficulty": "intermediate", "form_cue": "Quick drop, spread legs, pop back up", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                        {"name": "Pallof Press", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Moderate cable", "equipment": "Cable Machine", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "intermediate", "form_cue": "Press out, resist rotation", "substitution": "Plank with Shoulder Tap", "exercise_library_id": None, "in_library": False}
                    ]
                }
            ]
        }
    }

    # ========== 4 WEEKS, 4 sessions/week ==========
    w4 = {}
    w4[1] = weeks_data[(2, 4)][1]
    w4[2] = weeks_data[(2, 4)][2]
    w4[3] = {
        "focus": "Progressive Overload - Heavier Loads, Complex Movements",
        "workouts": [
            {
                "workout_name": "Day 1 - Heavy Compound Circuit",
                "type": "conditioning",
                "duration_minutes": 50,
                "exercises": [
                    {"name": "Trap Bar Deadlift", "sets": 5, "reps": 5, "rest_seconds": 60, "weight_guidance": "Heavy - RPE 8", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Quadriceps", "Traps"], "difficulty": "intermediate", "form_cue": "Drive through floor, chest up", "substitution": "Barbell Deadlift", "exercise_library_id": None, "in_library": False},
                    {"name": "Barbell Bench Press", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Touch chest, press explosively", "substitution": "Dumbbell Bench Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Weighted Pull-Ups", "sets": 4, "reps": 6, "rest_seconds": 45, "weight_guidance": "Add 10-25 lbs", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "advanced", "form_cue": "Full range, chin over bar", "substitution": "Pull-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Step-Ups", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells, high box", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Drive through lead leg, full extension", "substitution": "Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Snatch", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Explosive pull, catch overhead", "substitution": "Kettlebell Swings", "exercise_library_id": None, "in_library": False},
                    {"name": "Ab Wheel Rollout", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "intermediate", "form_cue": "Extend fully, pull back with abs", "substitution": "Plank", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 2 - Tempo Metabolic",
                "type": "conditioning",
                "duration_minutes": 45,
                "exercises": [
                    {"name": "Front Squat", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "3-1-1 tempo, moderate weight", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Glutes"], "difficulty": "intermediate", "form_cue": "3 sec down, 1 sec pause, 1 sec up", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
                    {"name": "Incline Dumbbell Press", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Upper Pectoralis", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Slow lower, explosive press", "substitution": "Incline Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Cable Row", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Cable Machine", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Squeeze back at contraction, 2 sec hold", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
                    {"name": "Bulgarian Split Squat", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Rear foot elevated, drop knee toward floor", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Landmine Press", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press at angle, brace core throughout", "substitution": "Overhead Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Russian Twists", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "10-20 lb weight", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Lean back, rotate fully side to side", "substitution": "Bicycle Crunches", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 3 - Machine & Bodyweight HIIT",
                "type": "conditioning",
                "duration_minutes": 40,
                "exercises": [
                    {"name": "Rowing Machine Intervals", "sets": 5, "reps": 300, "rest_seconds": 60, "weight_guidance": "300m max effort rows", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms", "Core"], "difficulty": "intermediate", "form_cue": "Power 10 strokes, maintain pace", "substitution": "Assault Bike", "exercise_library_id": None, "in_library": False},
                    {"name": "Push-Ups", "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight - max speed", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, maintain straight body", "substitution": "Knee Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Ski Erg Sprints", "sets": 4, "reps": 200, "rest_seconds": 45, "weight_guidance": "200m sprints", "equipment": "Ski Erg", "body_part": "Full Body", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Hinge at hips, pull down with lats", "substitution": "Lat Pulldown", "exercise_library_id": None, "in_library": False},
                    {"name": "Air Squats", "sets": 4, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Below parallel, fast tempo", "substitution": "Jump Squats", "exercise_library_id": None, "in_library": False},
                    {"name": "Burpees", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Fast transitions", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False},
                    {"name": "Hanging Leg Raises", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Lower Abs", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Control the movement, no swinging", "substitution": "Lying Leg Raises", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 4 - Loaded Carries & Core",
                "type": "conditioning",
                "duration_minutes": 40,
                "exercises": [
                    {"name": "Farmer's Walk", "sets": 4, "reps": 50, "rest_seconds": 60, "weight_guidance": "Heavy DBs, 50m walks", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Traps", "Core", "Legs"], "difficulty": "beginner", "form_cue": "Tall posture, brisk pace", "substitution": "Suitcase Carry", "exercise_library_id": None, "in_library": False},
                    {"name": "Overhead Carry", "sets": 3, "reps": 40, "rest_seconds": 60, "weight_guidance": "Moderate KB or DB, 40m", "equipment": "Kettlebell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Traps"], "difficulty": "intermediate", "form_cue": "Lock arm out, brace core, walk", "substitution": "Farmer's Walk", "exercise_library_id": None, "in_library": False},
                    {"name": "Sandbag Bear Hug Carry", "sets": 3, "reps": 40, "rest_seconds": 60, "weight_guidance": "Heavy sandbag, 40m", "equipment": "Sandbag", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Biceps", "Legs"], "difficulty": "intermediate", "form_cue": "Hug sandbag to chest, walk upright", "substitution": "Goblet Carry", "exercise_library_id": None, "in_library": False},
                    {"name": "Sled Push", "sets": 4, "reps": 30, "rest_seconds": 45, "weight_guidance": "Heavy load, 30m", "equipment": "Sled", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Low body angle, drive hard", "substitution": "Walking Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Turkish Get-Up", "sets": 3, "reps": 4, "rest_seconds": 45, "weight_guidance": "Moderate KB", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "advanced", "form_cue": "Slow, controlled, eyes on weight", "substitution": "Windmill", "exercise_library_id": None, "in_library": False},
                    {"name": "Dead Bug", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Lower back pressed into floor", "substitution": "Bird Dog", "exercise_library_id": None, "in_library": False}
                ]
            }
        ]
    }
    w4[4] = {
        "focus": "Peak Performance - Maximum Metabolic Output",
        "workouts": weeks_data[(2, 4)][2]["workouts"]
    }
    weeks_data[(4, 4)] = w4

    # ========== 8 WEEKS, 5 sessions/week ==========
    w8 = {}
    for wk in range(1, 5):
        w8[wk] = w4[wk]
    w8[5] = {
        "focus": "Active Recovery - Technique & Mobility",
        "workouts": [
            {
                "workout_name": "Day 1 - Light Full Body Movement",
                "type": "conditioning",
                "duration_minutes": 35,
                "exercises": [
                    {"name": "Goblet Squat", "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Light weight - RPE 5", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Focus on perfect depth and form", "substitution": "Bodyweight Squat", "exercise_library_id": None, "in_library": False},
                    {"name": "Push-Ups", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Bodyweight - slow tempo", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "3 sec down, 1 sec pause, 2 sec up", "substitution": "Incline Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Row", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light - RPE 5", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Smooth reps, focus on squeeze", "substitution": "Inverted Row", "exercise_library_id": None, "in_library": False},
                    {"name": "Band Pull-Aparts", "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull apart at chest height", "substitution": "Face Pulls", "exercise_library_id": None, "in_library": False},
                    {"name": "Plank", "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30-second holds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Straight line, brace", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 2 - Mobility & Light Conditioning",
                "type": "conditioning",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Kettlebell Swings", "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Light KB - RPE 5", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Smooth, focus on hip hinge", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
                    {"name": "Walking Lunges", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Controlled pace, full range", "substitution": "Step-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Rowing Machine", "sets": 2, "reps": 500, "rest_seconds": 90, "weight_guidance": "Easy pace 500m", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms"], "difficulty": "beginner", "form_cue": "Smooth strokes, moderate effort", "substitution": "Stationary Bike", "exercise_library_id": None, "in_library": False},
                    {"name": "Bird Dog", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Opposite arm and leg, hold 2 sec", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 3 - Light Upper Body",
                "type": "conditioning",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Incline Dumbbell Press", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light - RPE 5", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Upper Pectoralis", "secondary_muscles": ["Triceps"], "difficulty": "beginner", "form_cue": "Mind-muscle connection", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Lat Pulldown", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light - RPE 5", "equipment": "Cable Machine", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Slow eccentric, stretch at top", "substitution": "Band Pulldowns", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Lateral Raises", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Light", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Controlled, no momentum", "substitution": "Band Lateral Raises", "exercise_library_id": None, "in_library": False},
                    {"name": "Glute Bridge", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Squeeze at top 2 sec", "substitution": "Hip Thrust", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 4 - Yoga-Inspired Recovery",
                "type": "conditioning",
                "duration_minutes": 25,
                "exercises": [
                    {"name": "Cat-Cow Stretch", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Flow between arch and round", "substitution": "Seated Spinal Twist", "exercise_library_id": None, "in_library": False},
                    {"name": "World's Greatest Stretch", "sets": 2, "reps": 8, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings", "Thoracic Spine"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach", "substitution": "Leg Swings", "exercise_library_id": None, "in_library": False},
                    {"name": "Side-Lying Hip Abduction", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Glutes", "primary_muscle": "Gluteus Medius", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Lie on side, raise top leg", "substitution": "Clamshells", "exercise_library_id": None, "in_library": False},
                    {"name": "Dead Bug", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Slow, controlled, lower back down", "substitution": "Bird Dog", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 5 - Light Lower Body",
                "type": "conditioning",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Leg Press", "sets": 3, "reps": 12, "rest_seconds": 60, "weight_guidance": "Light - RPE 5", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Full range, slow tempo", "substitution": "Bodyweight Squat", "exercise_library_id": None, "in_library": False},
                    {"name": "Romanian Deadlift", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Light - RPE 5", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "Feel the stretch", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
                    {"name": "Step-Ups", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Bodyweight", "equipment": "Bench", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Drive through lead leg", "substitution": "Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Calf Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range", "substitution": "Seated Calf Raises", "exercise_library_id": None, "in_library": False},
                    {"name": "Side Plank", "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30-sec holds each side", "equipment": "None", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "Hips stacked, body straight", "substitution": "Pallof Press", "exercise_library_id": None, "in_library": False}
                ]
            }
        ]
    }
    w8[6] = w4[3]  # Progressive overload week
    w8[7] = w4[4]  # Peak performance
    w8[8] = weeks_data[(2, 4)][2]  # Final push with barbell complexes
    weeks_data[(8, 5)] = w8

    return weeks_data


def main():
    helper = ProgramSQLHelper()
    migration_num = helper.get_next_migration_num()

    print(f"Generating Metabolic Conditioning (migration #{migration_num})...")

    weeks_data = build_weeks_data()

    success = helper.insert_full_program(
        program_name="Metabolic Conditioning",
        category_name="Fat Loss",
        description="Circuit-based fat loss program combining strength training with cardiovascular conditioning. Features barbell complexes, kettlebell flows, loaded carries, and machine intervals to maximize calorie burn and build functional fitness.",
        durations=[2, 4, 8],
        sessions_per_week=[4, 4, 5],
        has_supersets=True,
        priority="High",
        weeks_data=weeks_data,
        migration_num=migration_num,
        write_sql=True,
    )

    if success:
        print("Metabolic Conditioning inserted successfully!")
        helper.update_tracker("Metabolic Conditioning", "Done")
    else:
        print("Failed to insert Metabolic Conditioning")

    helper.close()


if __name__ == "__main__":
    main()
