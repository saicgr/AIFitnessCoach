#!/usr/bin/env python3
"""Generate HIIT Burner - Fat Loss Category (High Priority)
Durations: 1, 2, 4, 6w | Sessions: 3-4/wk | Supersets: Yes
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from program_sql_helper import ProgramSQLHelper

def build_weeks_data():
    weeks_data = {}

    # ========== 1 WEEK, 3 sessions/week ==========
    weeks_data[(1, 3)] = {
        1: {
            "focus": "HIIT Introduction - Learn the Intensity",
            "workouts": [
                {
                    "workout_name": "Day 1 - Tabata Total Body",
                    "type": "hiit",
                    "duration_minutes": 30,
                    "exercises": [
                        {"name": "Burpees", "sets": 4, "reps": 8, "rest_seconds": 20, "weight_guidance": "Bodyweight - 20s work / 10s rest", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump at top", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False},
                        {"name": "Jump Squats", "sets": 4, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Deep squat, explode up, soft landing", "substitution": "Bodyweight Squats", "exercise_library_id": None, "in_library": False},
                        {"name": "Mountain Climbers", "sets": 4, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast pace", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Drive knees to chest rapidly", "substitution": "High Knees", "exercise_library_id": None, "in_library": False},
                        {"name": "Push-Up to Shoulder Tap", "sets": 4, "reps": 8, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Push-up, then tap opposite shoulder", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
                        {"name": "Skater Jumps", "sets": 4, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Adductors"], "difficulty": "intermediate", "form_cue": "Leap side to side, touch floor", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
                        {"name": "Plank Jacks", "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Hip Abductors", "Shoulders"], "difficulty": "beginner", "form_cue": "Plank position, jump feet wide and back", "substitution": "Plank Hold", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 2 - Kettlebell HIIT",
                    "type": "hiit",
                    "duration_minutes": 30,
                    "exercises": [
                        {"name": "Kettlebell Swings", "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "Hip snap, arms are just along for the ride", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Goblet Squat", "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "beginner", "form_cue": "Sit deep between heels, chest up", "substitution": "Bodyweight Squat", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Clean and Press", "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate kettlebell each hand", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Legs", "Biceps"], "difficulty": "intermediate", "form_cue": "Clean to rack position, press overhead", "substitution": "Dumbbell Clean and Press", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Sumo High Pull", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Trapezius", "secondary_muscles": ["Shoulders", "Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Wide stance, pull to chin height with elbows high", "substitution": "Upright Row", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Figure 8", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Kettlebell", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Legs", "Arms"], "difficulty": "intermediate", "form_cue": "Pass between legs in figure-8 pattern", "substitution": "Russian Twists", "exercise_library_id": None, "in_library": False},
                        {"name": "Kettlebell Snatch", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Explosive hip drive, punch through at top", "substitution": "Kettlebell Swings", "exercise_library_id": None, "in_library": False}
                    ]
                },
                {
                    "workout_name": "Day 3 - Bodyweight AMRAP",
                    "type": "hiit",
                    "duration_minutes": 25,
                    "exercises": [
                        {"name": "Burpee to Tuck Jump", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight - max effort", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "advanced", "form_cue": "Burpee then tuck jump instead of regular jump", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                        {"name": "Spider-Man Push-Ups", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Obliques", "Hip Flexors", "Triceps"], "difficulty": "intermediate", "form_cue": "Bring knee to elbow as you lower", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
                        {"name": "Jumping Lunges", "sets": 3, "reps": 16, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Switch legs in air, land softly", "substitution": "Walking Lunges", "exercise_library_id": None, "in_library": False},
                        {"name": "V-Ups", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Touch toes at top, lower with control", "substitution": "Crunches", "exercise_library_id": None, "in_library": False},
                        {"name": "Broad Jumps", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves"], "difficulty": "intermediate", "form_cue": "Swing arms, jump forward, land softly", "substitution": "Squat Jumps", "exercise_library_id": None, "in_library": False},
                        {"name": "Bear Crawls", "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "20 meters each set", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps"], "difficulty": "intermediate", "form_cue": "Hips low, opposite hand and foot move together", "substitution": "Mountain Climbers", "exercise_library_id": None, "in_library": False}
                    ]
                }
            ]
        }
    }

    # ========== 2 WEEKS, 3 sessions/week ==========
    w2 = {1: weeks_data[(1, 3)][1]}
    w2[2] = {
        "focus": "Intensity Ramp - Shorter Rest, Higher Output",
        "workouts": [
            {
                "workout_name": "Day 1 - Sprint Interval Training",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Treadmill Sprints", "sets": 8, "reps": 30, "rest_seconds": 30, "weight_guidance": "30-sec sprint at 85-90% max effort", "equipment": "Treadmill", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "intermediate", "form_cue": "High knees, pump arms, lean slightly forward", "substitution": "High Knees in Place", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Thrusters", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps", "Glutes"], "difficulty": "intermediate", "form_cue": "Deep squat, drive up and press", "substitution": "Squat to Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Box Jumps", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "20-24 inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Swing arms, land soft with full foot on box", "substitution": "Step-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Medicine Ball Slams", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "15-25 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "intermediate", "form_cue": "Overhead to slam, max force", "substitution": "Dumbbell Woodchops", "exercise_library_id": None, "in_library": False},
                    {"name": "Battle Ropes Alternating Waves", "sets": 3, "reps": 30, "rest_seconds": 20, "weight_guidance": "30-second intervals", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms"], "difficulty": "intermediate", "form_cue": "Fast alternating waves, stay low", "substitution": "Jumping Jacks", "exercise_library_id": None, "in_library": False},
                    {"name": "Sprawls", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Core", "Chest", "Legs"], "difficulty": "intermediate", "form_cue": "Quick drop to floor, pop back up", "substitution": "Burpees", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 2 - Dumbbell HIIT Complex",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Dumbbell Hang Clean", "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Traps", "secondary_muscles": ["Shoulders", "Biceps", "Legs"], "difficulty": "intermediate", "form_cue": "Hip drive, shrug and catch at shoulders", "substitution": "Upright Row", "exercise_library_id": None, "in_library": False},
                    {"name": "Renegade Rows", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Plank position, row one arm, minimize rotation", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Reverse Lunge to Curl", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Biceps"], "difficulty": "intermediate", "form_cue": "Reverse lunge, curl at bottom, stand up", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Devil Press", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Light to moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Shoulders", "Legs"], "difficulty": "advanced", "form_cue": "Burpee with DBs, snatch both overhead", "substitution": "Burpee to Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Woodchops", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Rotate from core, diagonal movement", "substitution": "Russian Twists", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Squat Jump", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Light dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Hold DBs at sides, squat and jump", "substitution": "Bodyweight Jump Squats", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 3 - Cardio Machine HIIT",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Assault Bike Sprints", "sets": 6, "reps": 15, "rest_seconds": 45, "weight_guidance": "15-cal sprints", "equipment": "Assault Bike", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Arms", "Core"], "difficulty": "intermediate", "form_cue": "All-out effort each round", "substitution": "Stationary Bike Sprints", "exercise_library_id": None, "in_library": False},
                    {"name": "Rowing Machine Intervals", "sets": 5, "reps": 200, "rest_seconds": 45, "weight_guidance": "200m sprint rows", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms", "Core"], "difficulty": "intermediate", "form_cue": "Legs-back-arms on pull, arms-back-legs on return", "substitution": "Dumbbell Bent Over Row", "exercise_library_id": None, "in_library": False},
                    {"name": "Ski Erg Sprints", "sets": 4, "reps": 200, "rest_seconds": 45, "weight_guidance": "200m sprints", "equipment": "Ski Erg", "body_part": "Full Body", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Hinge at hips, pull down with lats", "substitution": "Lat Pulldown", "exercise_library_id": None, "in_library": False},
                    {"name": "Sled Push", "sets": 4, "reps": 25, "rest_seconds": 60, "weight_guidance": "Moderate load, 25-meter pushes", "equipment": "Sled", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Low angle, drive through legs", "substitution": "Walking Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Farmer's Walk", "sets": 3, "reps": 40, "rest_seconds": 45, "weight_guidance": "Heavy dumbbells, 40m", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Traps", "Core", "Legs"], "difficulty": "beginner", "form_cue": "Tall posture, brisk pace", "substitution": "Suitcase Carry", "exercise_library_id": None, "in_library": False}
                ]
            }
        ]
    }
    weeks_data[(2, 3)] = w2

    # ========== 4 WEEKS, 4 sessions/week ==========
    w4 = {}
    w4[1] = weeks_data[(1, 3)][1]
    w4[2] = w2[2]
    w4[3] = {
        "focus": "Peak Conditioning - Maximum Heart Rate Training",
        "workouts": [
            {
                "workout_name": "Day 1 - EMOM Strength",
                "type": "hiit",
                "duration_minutes": 35,
                "exercises": [
                    {"name": "Power Clean", "sets": 5, "reps": 3, "rest_seconds": 60, "weight_guidance": "Moderate - every minute on the minute", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Traps", "Shoulders"], "difficulty": "advanced", "form_cue": "Explosive hip extension, catch at shoulders", "substitution": "Hang Clean", "exercise_library_id": None, "in_library": False},
                    {"name": "Push Press", "sets": 5, "reps": 5, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Dip and drive with legs, lock out overhead", "substitution": "Overhead Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Front Squat", "sets": 5, "reps": 5, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Glutes"], "difficulty": "intermediate", "form_cue": "Elbows high, sit between heels", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
                    {"name": "Barbell Row", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Flat back, pull to lower chest", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
                    {"name": "Kettlebell Swings", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Heavy kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Powerful hip snap", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
                    {"name": "Toes to Bar", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Lats"], "difficulty": "advanced", "form_cue": "Kip or strict, touch toes to bar", "substitution": "Hanging Knee Raises", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 2 - Bodyweight HIIT Circuits",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Burpee Pull-Ups", "sets": 4, "reps": 6, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Back", "Chest", "Legs"], "difficulty": "advanced", "form_cue": "Burpee under bar, jump into pull-up", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                    {"name": "Pistol Squats", "sets": 3, "reps": 6, "rest_seconds": 30, "weight_guidance": "Bodyweight or assisted", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "advanced", "form_cue": "Single leg squat, extend other leg forward", "substitution": "Bulgarian Split Squat", "exercise_library_id": None, "in_library": False},
                    {"name": "Handstand Push-Up (Wall)", "sets": 3, "reps": 6, "rest_seconds": 45, "weight_guidance": "Bodyweight against wall", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Kick up to wall, lower head to floor, press up", "substitution": "Pike Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Plyometric Lunges", "sets": 3, "reps": 16, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Switch legs mid-air, land softly", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Clap Push-Ups", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Shoulders"], "difficulty": "advanced", "form_cue": "Explosive push, clap, catch softly", "substitution": "Explosive Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "L-Sit Hold", "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Hold for 20 seconds", "equipment": "Parallettes", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Hip Flexors", "Triceps"], "difficulty": "advanced", "form_cue": "Legs parallel to floor, arms straight", "substitution": "Hanging Knee Raises", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 3 - Conditioning Circuit",
                "type": "hiit",
                "duration_minutes": 35,
                "exercises": [
                    {"name": "Wall Balls", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "14-20 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core", "Glutes"], "difficulty": "intermediate", "form_cue": "Deep squat, throw to 10ft target", "substitution": "Thrusters", "exercise_library_id": None, "in_library": False},
                    {"name": "Calorie Row", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "15-cal intervals", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms"], "difficulty": "intermediate", "form_cue": "Max effort each round", "substitution": "Assault Bike", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Snatch", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Explosive pull from floor to overhead", "substitution": "Kettlebell Swings", "exercise_library_id": None, "in_library": False},
                    {"name": "Box Jump Overs", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "20-24 inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Jump over box, turn and repeat", "substitution": "Step-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Double Unders", "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 reps or 30 seconds", "equipment": "Jump Rope", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "intermediate", "form_cue": "Wrists drive the rope, slight jump", "substitution": "Single Unders (60 reps)", "exercise_library_id": None, "in_library": False},
                    {"name": "Sit-Ups", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Full range, touch toes at top", "substitution": "Crunches", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 4 - Metabolic Finisher",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Thrusters", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate barbell or dumbbells", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Squat, drive up, press overhead in one motion", "substitution": "Goblet Squat to Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Man Makers", "sets": 3, "reps": 6, "rest_seconds": 45, "weight_guidance": "Light to moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Back", "Shoulders", "Legs"], "difficulty": "advanced", "form_cue": "Push-up, row each arm, squat clean, press", "substitution": "Burpee to Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Assault Bike Sprints", "sets": 5, "reps": 10, "rest_seconds": 30, "weight_guidance": "10-calorie sprints", "equipment": "Assault Bike", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Arms", "Core"], "difficulty": "intermediate", "form_cue": "Sprint all-out each round", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                    {"name": "Medicine Ball Over-the-Shoulder Throws", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "15-25 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "intermediate", "form_cue": "Pick up, throw over alternating shoulders", "substitution": "Medicine Ball Slams", "exercise_library_id": None, "in_library": False},
                    {"name": "Tuck Jumps", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Calves"], "difficulty": "intermediate", "form_cue": "Jump high, knees to chest", "substitution": "Jump Squats", "exercise_library_id": None, "in_library": False}
                ]
            }
        ]
    }
    w4[4] = {
        "focus": "Final Push - All-Out Effort",
        "workouts": [
            {
                "workout_name": "Day 1 - Total Body Tabata",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Barbell Complex (Deadlift + Hang Clean + Push Press + Back Squat)", "sets": 5, "reps": 5, "rest_seconds": 60, "weight_guidance": "Light to moderate barbell", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Legs", "Back", "Shoulders"], "difficulty": "advanced", "form_cue": "Flow through all 4 movements without putting bar down", "substitution": "Dumbbell Thrusters", "exercise_library_id": None, "in_library": False},
                    {"name": "Burpee to Box Jump", "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "20 inch box", "equipment": "Plyo Box", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Legs", "Chest", "Core"], "difficulty": "advanced", "form_cue": "Burpee then immediately box jump", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                    {"name": "Kettlebell Turkish Get-Up", "sets": 3, "reps": 4, "rest_seconds": 45, "weight_guidance": "Moderate kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Glutes", "Legs"], "difficulty": "advanced", "form_cue": "Slow and controlled, eyes on weight", "substitution": "Windmill", "exercise_library_id": None, "in_library": False},
                    {"name": "Battle Ropes Double Slam", "sets": 4, "reps": 15, "rest_seconds": 20, "weight_guidance": "Max power each slam", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats", "Legs"], "difficulty": "intermediate", "form_cue": "Both arms together, slam with hip hinge", "substitution": "Medicine Ball Slams", "exercise_library_id": None, "in_library": False},
                    {"name": "Plyo Push-Ups", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Shoulders"], "difficulty": "advanced", "form_cue": "Push off explosively, catch softly", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Bicycle Crunches", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Touch elbow to opposite knee", "substitution": "Russian Twists", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 2 - Sprint & Strength HIIT",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Dumbbell Clean and Jerk", "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Legs", "Core", "Traps"], "difficulty": "intermediate", "form_cue": "Clean to shoulders, dip and drive overhead", "substitution": "Dumbbell Clean and Press", "exercise_library_id": None, "in_library": False},
                    {"name": "Assault Bike Tabata", "sets": 8, "reps": 20, "rest_seconds": 10, "weight_guidance": "20s max effort / 10s rest x 8", "equipment": "Assault Bike", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Arms", "Core"], "difficulty": "advanced", "form_cue": "All-out sprint every round", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                    {"name": "Weighted Burpees", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Hold light dumbbells throughout", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "advanced", "form_cue": "Push-up with DBs, jump with DBs", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
                    {"name": "Sled Sprint", "sets": 4, "reps": 30, "rest_seconds": 45, "weight_guidance": "Moderate load, 30m sprints", "equipment": "Sled", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Low drive, pump arms, full sprint", "substitution": "Sprint in Place", "exercise_library_id": None, "in_library": False},
                    {"name": "Hanging Windshield Wipers", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Lats"], "difficulty": "advanced", "form_cue": "Hang from bar, rotate straight legs side to side", "substitution": "Russian Twists", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 3 - Dumbbell Death Circuit",
                "type": "hiit",
                "duration_minutes": 30,
                "exercises": [
                    {"name": "Dumbbell Snatch", "sets": 4, "reps": 10, "rest_seconds": 20, "weight_guidance": "Moderate dumbbell, alternate arms", "equipment": "Dumbbell", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Explosive pull, catch overhead", "substitution": "Kettlebell Swings", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Bench Over Row", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Hinge over, row to chest, squeeze", "substitution": "Bent Over Row", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Push-Up to Row", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Chest", "secondary_muscles": ["Back", "Core"], "difficulty": "intermediate", "form_cue": "Push-up, row right, push-up, row left", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Reverse Lunge to Press", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "intermediate", "form_cue": "Reverse lunge, drive up, press overhead", "substitution": "Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Lateral Shuffle", "sets": 3, "reps": 16, "rest_seconds": 20, "weight_guidance": "Light dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Adductors", "Glutes"], "difficulty": "intermediate", "form_cue": "Low stance, shuffle laterally touching DB to ground", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
                    {"name": "Dumbbell Floor Wipers", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "No weight needed", "equipment": "None", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Lie on back, legs up, rotate side to side", "substitution": "Russian Twists", "exercise_library_id": None, "in_library": False}
                ]
            },
            {
                "workout_name": "Day 4 - Grand Finale HIIT",
                "type": "hiit",
                "duration_minutes": 35,
                "exercises": [
                    {"name": "Thrusters", "sets": 5, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps"], "difficulty": "intermediate", "form_cue": "Squat deep, press overhead in one motion", "substitution": "Dumbbell Thrusters", "exercise_library_id": None, "in_library": False},
                    {"name": "Calorie Row", "sets": 4, "reps": 20, "rest_seconds": 45, "weight_guidance": "20-cal max effort rows", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms"], "difficulty": "intermediate", "form_cue": "All-out effort each round", "substitution": "Assault Bike", "exercise_library_id": None, "in_library": False},
                    {"name": "Burpees", "sets": 4, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight - max speed", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump at top", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False},
                    {"name": "Kettlebell Swings", "sets": 4, "reps": 20, "rest_seconds": 20, "weight_guidance": "Heavy kettlebell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
                    {"name": "Box Jumps", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "24 inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Quick rebounds, soft landing", "substitution": "Tuck Jumps", "exercise_library_id": None, "in_library": False}
                ]
            }
        ]
    }
    weeks_data[(4, 4)] = w4

    # ========== 6 WEEKS, 4 sessions/week ==========
    w6 = {}
    for wk in range(1, 5):
        w6[wk] = w4[wk]
    w6[5] = w4[3]  # Repeat peak conditioning
    w6[6] = w4[4]  # Repeat all-out final push
    weeks_data[(6, 4)] = w6

    return weeks_data


def main():
    helper = ProgramSQLHelper()
    migration_num = helper.get_next_migration_num()

    print(f"Generating HIIT Burner (migration #{migration_num})...")

    weeks_data = build_weeks_data()

    success = helper.insert_full_program(
        program_name="HIIT Burner",
        category_name="Fat Loss",
        description="High intensity interval training designed to maximize calorie burn in minimal time. Features Tabata protocols, EMOM workouts, and sprint intervals using bodyweight, dumbbells, kettlebells, and cardio machines.",
        durations=[1, 2, 4, 6],
        sessions_per_week=[3, 3, 4, 4],
        has_supersets=True,
        priority="High",
        weeks_data=weeks_data,
        migration_num=migration_num,
        write_sql=True,
    )

    if success:
        print("HIIT Burner inserted successfully!")
        helper.update_tracker("HIIT Burner", "Done")
    else:
        print("Failed to insert HIIT Burner")

    helper.close()


if __name__ == "__main__":
    main()
