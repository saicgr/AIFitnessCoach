#!/usr/bin/env python3
"""Generate Flexibility/Stretches HIGH priority programs (Category 5):
- Morning Mobility (1, 2, 4w x 7/wk)
- Full Body Flexibility (2, 4, 8w x 4-5/wk)
- Office Worker Recovery (1, 2, 4w x 5-7/wk)
- Flexibility for Beginners (1, 2, 4w x 3-4/wk)
- Contortionist Basics (4, 8, 12w x 5-6/wk)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from program_sql_helper import ProgramSQLHelper


def build_morning_mobility():
    weeks_data = {}

    day_a = {
        "workout_name": "Day 1 - Upper Body Mobility Flow",
        "type": "stretching",
        "duration_minutes": 15,
        "exercises": [
            {"name": "Cat-Cow Stretch", "sets": 2, "reps": 10, "rest_seconds": 10, "weight_guidance": "Bodyweight - flow with breath", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Thoracic Spine"], "difficulty": "beginner", "form_cue": "Inhale arch, exhale round, slow rhythm", "substitution": "Seated Spinal Rotation", "exercise_library_id": None, "in_library": False},
            {"name": "Thread the Needle", "sets": 2, "reps": 8, "rest_seconds": 10, "weight_guidance": "Hold each side 5 seconds", "equipment": "None", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Shoulders", "Obliques"], "difficulty": "beginner", "form_cue": "From all fours, reach one arm under and rotate", "substitution": "Seated Spinal Twist", "exercise_library_id": None, "in_library": False},
            {"name": "Arm Circles", "sets": 2, "reps": 15, "rest_seconds": 10, "weight_guidance": "Forward then backward", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Rotator Cuff"], "difficulty": "beginner", "form_cue": "Full range, start small and increase", "substitution": "Shoulder Rolls", "exercise_library_id": None, "in_library": False},
            {"name": "Cross-Body Shoulder Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each arm", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Posterior Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull arm across chest, gentle pressure", "substitution": "Doorway Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Neck Circles", "sets": 2, "reps": 8, "rest_seconds": 10, "weight_guidance": "Slow and controlled", "equipment": "None", "body_part": "Neck", "primary_muscle": "Neck Muscles", "secondary_muscles": ["Upper Trapezius"], "difficulty": "beginner", "form_cue": "Gentle circles, no forcing range", "substitution": "Neck Side Bends", "exercise_library_id": None, "in_library": False}
        ]
    }

    day_b = {
        "workout_name": "Day 2 - Lower Body Mobility Flow",
        "type": "stretching",
        "duration_minutes": 15,
        "exercises": [
            {"name": "Hip Circles", "sets": 2, "reps": 10, "rest_seconds": 10, "weight_guidance": "Large circles each direction", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Glutes", "Adductors"], "difficulty": "beginner", "form_cue": "Standing, circle knee in large orbit", "substitution": "Leg Swings", "exercise_library_id": None, "in_library": False},
            {"name": "World's Greatest Stretch", "sets": 2, "reps": 6, "rest_seconds": 10, "weight_guidance": "Hold each position 3 seconds", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings", "Thoracic Spine", "Quadriceps"], "difficulty": "beginner", "form_cue": "Lunge, rotate, reach overhead", "substitution": "90-90 Hip Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Leg Swings (Front-Back)", "sets": 2, "reps": 12, "rest_seconds": 10, "weight_guidance": "Controlled swings, increasing range", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings", "Glutes"], "difficulty": "beginner", "form_cue": "Hold wall for balance, swing freely", "substitution": "Hip Circles", "exercise_library_id": None, "in_library": False},
            {"name": "Leg Swings (Side-Side)", "sets": 2, "reps": 12, "rest_seconds": 10, "weight_guidance": "Lateral swings", "equipment": "None", "body_part": "Hips", "primary_muscle": "Adductors", "secondary_muscles": ["Hip Abductors", "Glutes"], "difficulty": "beginner", "form_cue": "Face wall, swing leg side to side", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Ankle Circles", "sets": 2, "reps": 10, "rest_seconds": 10, "weight_guidance": "Both directions each ankle", "equipment": "None", "body_part": "Legs", "primary_muscle": "Tibialis Anterior", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full range, slow and deliberate", "substitution": "Calf Raises", "exercise_library_id": None, "in_library": False}
        ]
    }

    day_c = {
        "workout_name": "Day 3 - Full Body Wake-Up Flow",
        "type": "stretching",
        "duration_minutes": 15,
        "exercises": [
            {"name": "Sun Salutation A", "sets": 3, "reps": 1, "rest_seconds": 10, "weight_guidance": "Flow through sequence", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Core", "Shoulders", "Hamstrings"], "difficulty": "beginner", "form_cue": "Mountain pose-forward fold-plank-cobra-downward dog-forward fold-mountain", "substitution": "Cat-Cow + Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Downward Dog to Cobra Flow", "sets": 3, "reps": 5, "rest_seconds": 10, "weight_guidance": "Flow with breath", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Hamstrings", "secondary_muscles": ["Shoulders", "Back", "Core"], "difficulty": "beginner", "form_cue": "Push hips high then flow forward to cobra", "substitution": "Cat-Cow", "exercise_library_id": None, "in_library": False},
            {"name": "Pigeon Pose", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Glutes", "secondary_muscles": ["Hip Flexors", "Piriformis"], "difficulty": "beginner", "form_cue": "Front shin across mat, sink hips down", "substitution": "Figure Four Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Quad Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, push hips forward", "substitution": "Kneeling Quad Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Forward Fold", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds, relax into it", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves", "Lower Back"], "difficulty": "beginner", "form_cue": "Let gravity pull you down, bend knees if needed", "substitution": "Seated Forward Fold", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 1w x 7/wk - alternate between the 3 routines
    weeks_data[(1, 7)] = {
        1: {"focus": "Daily Mobility Kickstart", "workouts": [day_a, day_b, day_c, day_a, day_b, day_c, day_a]}
    }

    # 2w x 7/wk
    weeks_data[(2, 7)] = {
        1: {"focus": "Establish Morning Mobility Habit", "workouts": [day_a, day_b, day_c, day_a, day_b, day_c, day_a]},
        2: {"focus": "Deepen Ranges - Longer Holds", "workouts": [day_b, day_c, day_a, day_b, day_c, day_a, day_b]}
    }

    # 4w x 7/wk
    weeks_data[(4, 7)] = {
        1: {"focus": "Foundation - Learn Each Flow", "workouts": [day_a, day_b, day_c, day_a, day_b, day_c, day_a]},
        2: {"focus": "Build - Increase Hold Times", "workouts": [day_b, day_c, day_a, day_b, day_c, day_a, day_b]},
        3: {"focus": "Deepen - Push Comfortable Range", "workouts": [day_c, day_a, day_b, day_c, day_a, day_b, day_c]},
        4: {"focus": "Maintain - Solidify Morning Routine", "workouts": [day_a, day_b, day_c, day_a, day_b, day_c, day_a]}
    }

    return weeks_data


def build_full_body_flexibility():
    weeks_data = {}

    session_a = {
        "workout_name": "Day 1 - Upper Body & Spine Flexibility",
        "type": "stretching",
        "duration_minutes": 30,
        "exercises": [
            {"name": "Cat-Cow Stretch", "sets": 3, "reps": 10, "rest_seconds": 15, "weight_guidance": "Slow, controlled flow", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Inhale into extension, exhale into flexion", "substitution": "Seated Spinal Rotation", "exercise_library_id": None, "in_library": False},
            {"name": "Thread the Needle", "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Hold 5 seconds each side", "equipment": "None", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Reach under and rotate, feel thoracic opening", "substitution": "Seated Spinal Twist", "exercise_library_id": None, "in_library": False},
            {"name": "Doorway Chest Stretch", "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds each arm", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on doorframe at 90 degrees, lean through", "substitution": "Wall Chest Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Overhead Lat Stretch", "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Obliques", "Triceps"], "difficulty": "beginner", "form_cue": "Grab door frame or bar, lean away and feel lat stretch", "substitution": "Side Bend Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Shoulder Sleeper Stretch", "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Infraspinatus", "secondary_muscles": ["Posterior Deltoid"], "difficulty": "beginner", "form_cue": "Lie on side, arm at 90 degrees, gently push forearm down", "substitution": "Cross-Body Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Sphinx Pose", "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Elbows under shoulders, gentle back extension", "substitution": "Cobra Pose", "exercise_library_id": None, "in_library": False}
        ]
    }

    session_b = {
        "workout_name": "Day 2 - Lower Body Flexibility",
        "type": "stretching",
        "duration_minutes": 30,
        "exercises": [
            {"name": "90-90 Hip Stretch", "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Glutes", "secondary_muscles": ["Hip Flexors", "Adductors"], "difficulty": "beginner", "form_cue": "Front leg 90, back leg 90, sit tall", "substitution": "Pigeon Pose", "exercise_library_id": None, "in_library": False},
            {"name": "Couch Stretch (Hip Flexor)", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Psoas"], "difficulty": "beginner", "form_cue": "Rear foot against wall/couch, drive hips forward", "substitution": "Kneeling Hip Flexor Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Hamstring Stretch", "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds each leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Foot on elevated surface, hinge at hips", "substitution": "Seated Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Butterfly Stretch", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds", "equipment": "None", "body_part": "Hips", "primary_muscle": "Adductors", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Soles of feet together, press knees down gently", "substitution": "Seated Straddle", "exercise_library_id": None, "in_library": False},
            {"name": "Pigeon Pose", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Glutes", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Front shin across mat, fold forward", "substitution": "Figure Four Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Wall Calf Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Hands on wall, straight back leg, lean in", "substitution": "Step Calf Stretch", "exercise_library_id": None, "in_library": False}
        ]
    }

    session_c = {
        "workout_name": "Day 3 - Full Body Flow",
        "type": "stretching",
        "duration_minutes": 35,
        "exercises": [
            {"name": "Sun Salutation A", "sets": 3, "reps": 1, "rest_seconds": 10, "weight_guidance": "Flow with breath", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Core", "Shoulders", "Hamstrings"], "difficulty": "beginner", "form_cue": "Mountain-fold-plank-cobra-downward dog-fold-mountain", "substitution": "Cat-Cow Flow", "exercise_library_id": None, "in_library": False},
            {"name": "World's Greatest Stretch", "sets": 2, "reps": 6, "rest_seconds": 15, "weight_guidance": "Hold each position 5 seconds", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Thoracic Spine", "Hamstrings"], "difficulty": "beginner", "form_cue": "Lunge, rotate open, reach overhead", "substitution": "Walking Spiderman", "exercise_library_id": None, "in_library": False},
            {"name": "Seated Straddle Stretch", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds, walk hands forward", "equipment": "None", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Wide legs, hinge forward from hips", "substitution": "Butterfly Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Scorpion Stretch", "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Alternating sides", "equipment": "None", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Hip Flexors", "Chest"], "difficulty": "intermediate", "form_cue": "Lie face down, swing one leg over to opposite side", "substitution": "Prone Spinal Twist", "exercise_library_id": None, "in_library": False},
            {"name": "Child's Pose", "sets": 2, "reps": 45, "rest_seconds": 10, "weight_guidance": "Hold 45 seconds, breathe deep", "equipment": "None", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Knees wide, reach arms forward, relax", "substitution": "Prayer Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Supine Spinal Twist", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Glutes", "Thoracic Spine"], "difficulty": "beginner", "form_cue": "Lie on back, drop knees to one side, arms out", "substitution": "Seated Spinal Twist", "exercise_library_id": None, "in_library": False}
        ]
    }

    session_d = {
        "workout_name": "Day 4 - Active Flexibility & PNF",
        "type": "stretching",
        "duration_minutes": 30,
        "exercises": [
            {"name": "PNF Hamstring Stretch", "sets": 2, "reps": 3, "rest_seconds": 15, "weight_guidance": "Contract 5 sec, relax and deepen 15 sec", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": [], "difficulty": "intermediate", "form_cue": "Lie on back, leg up, push against resistance then stretch deeper", "substitution": "Standing Hamstring Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "PNF Quad Stretch", "sets": 2, "reps": 3, "rest_seconds": 15, "weight_guidance": "Contract 5 sec, relax and deepen", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Side lying, pull heel to glute, push against hand then stretch deeper", "substitution": "Standing Quad Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Active Straight Leg Raise", "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Raise and hold 5 seconds", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Lie on back, raise straight leg using muscle strength alone", "substitution": "Leg Swings", "exercise_library_id": None, "in_library": False},
            {"name": "Frog Stretch", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds, rock gently", "equipment": "None", "body_part": "Hips", "primary_muscle": "Adductors", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Knees wide on floor, sink hips down", "substitution": "Butterfly Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Pancake Stretch", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Adductors", "Lower Back"], "difficulty": "intermediate", "form_cue": "Wide straddle, walk hands forward, chest to floor", "substitution": "Seated Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Deep Squat Hold", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Adductors", "Ankles", "Core"], "difficulty": "beginner", "form_cue": "Squat deep, heels down, hold bottom position", "substitution": "Supported Deep Squat", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 2w x 4/wk
    weeks_data[(2, 4)] = {
        1: {"focus": "Flexibility Foundation - Assess & Begin", "workouts": [session_a, session_b, session_c, session_d]},
        2: {"focus": "Deepen - Longer Holds, Greater Range", "workouts": [session_b, session_d, session_a, session_c]}
    }

    # 4w x 4/wk
    weeks_data[(4, 4)] = {
        1: {"focus": "Assess Current Flexibility", "workouts": [session_a, session_b, session_c, session_d]},
        2: {"focus": "Build - Push Comfortable Range", "workouts": [session_b, session_d, session_a, session_c]},
        3: {"focus": "Deepen - PNF & Active Stretching", "workouts": [session_d, session_a, session_c, session_b]},
        4: {"focus": "Maintain - Solidify New Ranges", "workouts": [session_a, session_b, session_c, session_d]}
    }

    # 8w x 5/wk
    weeks_data[(8, 5)] = {
        1: {"focus": "Foundation Assessment", "workouts": [session_a, session_b, session_c, session_d, session_a]},
        2: {"focus": "Build Range", "workouts": [session_b, session_d, session_a, session_c, session_b]},
        3: {"focus": "PNF Introduction", "workouts": [session_d, session_a, session_c, session_b, session_d]},
        4: {"focus": "Active Flexibility", "workouts": [session_c, session_d, session_b, session_a, session_c]},
        5: {"focus": "Recovery Week - Gentle Stretching", "workouts": [session_a, session_b, session_c, session_a, session_b]},
        6: {"focus": "Push Limits - Longer Holds", "workouts": [session_d, session_c, session_b, session_d, session_a]},
        7: {"focus": "Advanced Range Building", "workouts": [session_c, session_d, session_a, session_b, session_d]},
        8: {"focus": "Final Assessment - Test New Ranges", "workouts": [session_a, session_b, session_c, session_d, session_a]}
    }

    return weeks_data


def build_office_worker_recovery():
    weeks_data = {}

    desk_relief = {
        "workout_name": "Day 1 - Desk Worker Relief",
        "type": "stretching",
        "duration_minutes": 15,
        "exercises": [
            {"name": "Neck Side Bends", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Neck", "primary_muscle": "Upper Trapezius", "secondary_muscles": ["Levator Scapulae", "Scalenes"], "difficulty": "beginner", "form_cue": "Gently tilt ear to shoulder, opposite hand behind back", "substitution": "Neck Rotations", "exercise_library_id": None, "in_library": False},
            {"name": "Doorway Chest Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds, open chest", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arm on door frame, lean through, feel chest open", "substitution": "Wall Chest Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Seated Spinal Twist", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Thoracic Spine"], "difficulty": "beginner", "form_cue": "Sit tall, rotate gently, look over shoulder", "substitution": "Supine Spinal Twist", "exercise_library_id": None, "in_library": False},
            {"name": "Hip Flexor Stretch (Kneeling)", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Psoas", "Quadriceps"], "difficulty": "beginner", "form_cue": "Half-kneeling, drive hips forward, squeeze glute", "substitution": "Standing Hip Flexor Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Wrist Flexor & Extensor Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each direction", "equipment": "None", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Wrists"], "difficulty": "beginner", "form_cue": "Arm straight, pull fingers back then down", "substitution": "Wrist Circles", "exercise_library_id": None, "in_library": False}
        ]
    }

    posture_reset = {
        "workout_name": "Day 2 - Posture Reset",
        "type": "stretching",
        "duration_minutes": 15,
        "exercises": [
            {"name": "Wall Angels", "sets": 3, "reps": 10, "rest_seconds": 15, "weight_guidance": "Slow and controlled", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Lower Trapezius", "secondary_muscles": ["Serratus Anterior", "Rhomboids"], "difficulty": "beginner", "form_cue": "Back flat on wall, slide arms up and down like snow angel", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Chin Tucks", "sets": 3, "reps": 10, "rest_seconds": 10, "weight_guidance": "Hold each 3 seconds", "equipment": "None", "body_part": "Neck", "primary_muscle": "Deep Neck Flexors", "secondary_muscles": ["Upper Trapezius"], "difficulty": "beginner", "form_cue": "Pull chin straight back, make double chin", "substitution": "Neck Retractions", "exercise_library_id": None, "in_library": False},
            {"name": "Cat-Cow Stretch", "sets": 2, "reps": 10, "rest_seconds": 10, "weight_guidance": "Slow flow", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Alternate arch and round", "substitution": "Seated Cat-Cow", "exercise_library_id": None, "in_library": False},
            {"name": "Thoracic Extension Over Roller", "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Roll up and extend over foam roller", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Roller at mid-back, extend over it, return", "substitution": "Cat-Cow Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Band Pull-Aparts", "sets": 3, "reps": 15, "rest_seconds": 15, "weight_guidance": "Light band", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull band apart at chest height, squeeze back", "substitution": "Reverse Flyes", "exercise_library_id": None, "in_library": False}
        ]
    }

    hip_back = {
        "workout_name": "Day 3 - Hip & Back Release",
        "type": "stretching",
        "duration_minutes": 15,
        "exercises": [
            {"name": "Pigeon Pose", "sets": 2, "reps": 45, "rest_seconds": 10, "weight_guidance": "Hold 45 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Glutes", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Front shin across, fold forward, relax", "substitution": "Figure Four Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Child's Pose", "sets": 2, "reps": 45, "rest_seconds": 10, "weight_guidance": "Hold 45 seconds", "equipment": "None", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Knees wide, reach forward, breathe deep", "substitution": "Prayer Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Supine Figure Four Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Piriformis", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Ankle on opposite knee, pull thigh toward chest", "substitution": "Pigeon Pose", "exercise_library_id": None, "in_library": False},
            {"name": "Knee to Chest Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Back", "primary_muscle": "Lower Back", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Lie on back, pull one knee to chest, feel lower back release", "substitution": "Both Knees to Chest", "exercise_library_id": None, "in_library": False},
            {"name": "Supine Spinal Twist", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each side", "equipment": "None", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Glutes", "Thoracic Spine"], "difficulty": "beginner", "form_cue": "Drop knees to one side, arms out, relax", "substitution": "Seated Twist", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 1w x 5/wk
    weeks_data[(1, 5)] = {
        1: {"focus": "Immediate Desk Relief", "workouts": [desk_relief, posture_reset, hip_back, desk_relief, posture_reset]}
    }

    # 2w x 5/wk
    weeks_data[(2, 5)] = {
        1: {"focus": "Establish Recovery Routine", "workouts": [desk_relief, posture_reset, hip_back, desk_relief, posture_reset]},
        2: {"focus": "Deepen Stretches - Build Habit", "workouts": [posture_reset, hip_back, desk_relief, posture_reset, hip_back]}
    }

    # 4w x 7/wk
    weeks_data[(4, 7)] = {
        1: {"focus": "Daily Desk Relief Foundation", "workouts": [desk_relief, posture_reset, hip_back, desk_relief, posture_reset, hip_back, desk_relief]},
        2: {"focus": "Build - Posture Focus", "workouts": [posture_reset, hip_back, desk_relief, posture_reset, hip_back, desk_relief, posture_reset]},
        3: {"focus": "Deepen - Longer Holds", "workouts": [hip_back, desk_relief, posture_reset, hip_back, desk_relief, posture_reset, hip_back]},
        4: {"focus": "Maintain - Sustainable Daily Routine", "workouts": [desk_relief, posture_reset, hip_back, desk_relief, posture_reset, hip_back, desk_relief]}
    }

    return weeks_data


def build_flexibility_beginners():
    weeks_data = {}

    gentle_a = {
        "workout_name": "Day 1 - Gentle Full Body Stretch",
        "type": "stretching",
        "duration_minutes": 20,
        "exercises": [
            {"name": "Neck Side Bends", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each side", "equipment": "None", "body_part": "Neck", "primary_muscle": "Upper Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Gentle tilt, no forcing", "substitution": "Neck Rotations", "exercise_library_id": None, "in_library": False},
            {"name": "Cross-Body Shoulder Stretch", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each arm", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Posterior Deltoid", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull arm across chest gently", "substitution": "Behind Back Shoulder Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Quad Stretch", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each leg, use wall for balance", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, keep knees together", "substitution": "Lying Quad Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Hamstring Stretch", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Foot on low step, hinge at hips, keep back flat", "substitution": "Seated Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Calf Stretch", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Hands on wall, straight back leg, lean forward", "substitution": "Step Calf Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Cat-Cow Stretch", "sets": 2, "reps": 8, "rest_seconds": 10, "weight_guidance": "Slow and gentle", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Flow with breath, no pain", "substitution": "Seated Spinal Rotation", "exercise_library_id": None, "in_library": False}
        ]
    }

    gentle_b = {
        "workout_name": "Day 2 - Floor-Based Stretching",
        "type": "stretching",
        "duration_minutes": 20,
        "exercises": [
            {"name": "Knee to Chest Stretch", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each leg", "equipment": "None", "body_part": "Back", "primary_muscle": "Lower Back", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Lie on back, pull knee gently to chest", "substitution": "Both Knees to Chest", "exercise_library_id": None, "in_library": False},
            {"name": "Supine Figure Four Stretch", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Piriformis", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Ankle on knee, pull thigh toward you", "substitution": "Seated Piriformis Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Supine Spinal Twist", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds each side", "equipment": "None", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Thoracic Spine"], "difficulty": "beginner", "form_cue": "Knees to one side, arms out, relax", "substitution": "Seated Twist", "exercise_library_id": None, "in_library": False},
            {"name": "Child's Pose", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds", "equipment": "None", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Knees wide, reach forward, breathe", "substitution": "Prayer Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Butterfly Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds", "equipment": "None", "body_part": "Hips", "primary_muscle": "Adductors", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Soles together, gentle pressure on knees", "substitution": "Seated Straddle", "exercise_library_id": None, "in_library": False},
            {"name": "Cobra Stretch", "sets": 2, "reps": 20, "rest_seconds": 10, "weight_guidance": "Hold 20 seconds", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Hands under shoulders, press up gently, hips on floor", "substitution": "Sphinx Pose", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 1w x 3/wk
    weeks_data[(1, 3)] = {
        1: {"focus": "First Steps - Learn Basic Stretches", "workouts": [gentle_a, gentle_b, gentle_a]}
    }

    # 2w x 3/wk
    weeks_data[(2, 3)] = {
        1: {"focus": "Learn Basic Stretching", "workouts": [gentle_a, gentle_b, gentle_a]},
        2: {"focus": "Build Confidence - Slightly Longer Holds", "workouts": [gentle_b, gentle_a, gentle_b]}
    }

    # 4w x 4/wk
    weeks_data[(4, 4)] = {
        1: {"focus": "Foundation - Basic Stretch Literacy", "workouts": [gentle_a, gentle_b, gentle_a, gentle_b]},
        2: {"focus": "Build - Increase Hold Duration", "workouts": [gentle_b, gentle_a, gentle_b, gentle_a]},
        3: {"focus": "Progress - Deeper Ranges", "workouts": [gentle_a, gentle_b, gentle_a, gentle_b]},
        4: {"focus": "Consolidate - Sustainable Routine", "workouts": [gentle_b, gentle_a, gentle_b, gentle_a]}
    }

    return weeks_data


def build_contortionist_basics():
    weeks_data = {}

    splits_focus = {
        "workout_name": "Day 1 - Splits Progression",
        "type": "stretching",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Hip Flexor Stretch (Kneeling)", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Psoas", "Quadriceps"], "difficulty": "intermediate", "form_cue": "Half kneeling, drive hips forward, squeeze glute", "substitution": "Couch Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Hamstring Stretch", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds each leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Elevated surface, hinge at hips", "substitution": "Seated Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Front Split Progression", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds each side, use blocks for support", "equipment": "Yoga Blocks", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Hip Flexors", "Quadriceps"], "difficulty": "advanced", "form_cue": "Slide forward slowly, support weight with hands/blocks", "substitution": "Low Lunge Hold", "exercise_library_id": None, "in_library": False},
            {"name": "Pigeon Pose", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Glutes", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "intermediate", "form_cue": "Front shin across mat, fold forward, breathe deep", "substitution": "Figure Four Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Couch Stretch", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors", "Psoas"], "difficulty": "intermediate", "form_cue": "Rear foot on wall/couch, drive hips forward", "substitution": "Kneeling Quad Stretch", "exercise_library_id": None, "in_library": False}
        ]
    }

    backbend_focus = {
        "workout_name": "Day 2 - Backbend Progression",
        "type": "stretching",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Cat-Cow Stretch", "sets": 3, "reps": 10, "rest_seconds": 10, "weight_guidance": "Warm up spine", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Full range each direction", "substitution": "Spinal Waves", "exercise_library_id": None, "in_library": False},
            {"name": "Cobra Stretch", "sets": 3, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Hip Flexors", "Core"], "difficulty": "beginner", "form_cue": "Press up, hips on floor, relax lower back", "substitution": "Sphinx Pose", "exercise_library_id": None, "in_library": False},
            {"name": "Bridge Hold", "sets": 3, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes", "Shoulders"], "difficulty": "intermediate", "form_cue": "Press into full bridge, push chest over hands", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Doorway Chest Stretch", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds each position", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Arms at 3 different heights", "substitution": "Wall Chest Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Thoracic Extension Over Roller", "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Roll and extend at each segment", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Thoracic Spine", "secondary_muscles": ["Erector Spinae"], "difficulty": "intermediate", "form_cue": "Roller at upper back, extend over it slowly", "substitution": "Cat-Cow Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Shoulder Overhead Stretch", "sets": 2, "reps": 45, "rest_seconds": 10, "weight_guidance": "Hold 45 seconds", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Pectoralis Minor", "Triceps"], "difficulty": "intermediate", "form_cue": "Hands on door frame overhead, lean through", "substitution": "Overhead Lat Stretch", "exercise_library_id": None, "in_library": False}
        ]
    }

    middle_splits = {
        "workout_name": "Day 3 - Middle Splits & Hips",
        "type": "stretching",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Butterfly Stretch", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds, gentle pressure", "equipment": "None", "body_part": "Hips", "primary_muscle": "Adductors", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Soles together, press knees gently", "substitution": "Seated Straddle", "exercise_library_id": None, "in_library": False},
            {"name": "Frog Stretch", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds, rock gently", "equipment": "None", "body_part": "Hips", "primary_muscle": "Adductors", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Knees wide, hips sink down", "substitution": "Butterfly Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Pancake Stretch", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Adductors"], "difficulty": "intermediate", "form_cue": "Wide straddle, walk hands forward", "substitution": "Seated Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Middle Split Progression", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds, use wall or blocks", "equipment": "None", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Hamstrings"], "difficulty": "advanced", "form_cue": "Slide feet apart, support with hands, breathe", "substitution": "Wide Straddle Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "90-90 Hip Stretch", "sets": 2, "reps": 45, "rest_seconds": 15, "weight_guidance": "Hold 45 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Glutes", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Front and back leg at 90 degrees", "substitution": "Pigeon Pose", "exercise_library_id": None, "in_library": False}
        ]
    }

    active_flex = {
        "workout_name": "Day 4 - Active Flexibility & Strength",
        "type": "stretching",
        "duration_minutes": 35,
        "exercises": [
            {"name": "Active Straight Leg Raise", "sets": 3, "reps": 10, "rest_seconds": 15, "weight_guidance": "Hold top 5 seconds each rep", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Raise leg using muscle only, no momentum", "substitution": "Assisted Leg Raise", "exercise_library_id": None, "in_library": False},
            {"name": "Jefferson Curl", "sets": 3, "reps": 8, "rest_seconds": 15, "weight_guidance": "Bodyweight or very light weight", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Round down one vertebra at a time, reverse back up", "substitution": "Standing Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Wall Slides", "sets": 3, "reps": 10, "rest_seconds": 15, "weight_guidance": "Slow and controlled", "equipment": "None", "body_part": "Shoulders", "primary_muscle": "Serratus Anterior", "secondary_muscles": ["Lower Trapezius"], "difficulty": "beginner", "form_cue": "Back to wall, slide arms up maintaining contact", "substitution": "Wall Angels", "exercise_library_id": None, "in_library": False},
            {"name": "Hollow Body Hold", "sets": 3, "reps": 20, "rest_seconds": 15, "weight_guidance": "Hold 20 seconds", "equipment": "None", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors", "Transverse Abdominis"], "difficulty": "intermediate", "form_cue": "Lower back pressed down, arms and legs extended", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False},
            {"name": "Deep Squat Hold", "sets": 2, "reps": 60, "rest_seconds": 15, "weight_guidance": "Hold 60 seconds", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Adductors", "Ankles"], "difficulty": "beginner", "form_cue": "Heels down, chest up, relax into bottom", "substitution": "Supported Deep Squat", "exercise_library_id": None, "in_library": False}
        ]
    }

    full_flow = {
        "workout_name": "Day 5 - Full Contortion Flow",
        "type": "stretching",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Sun Salutation A", "sets": 3, "reps": 1, "rest_seconds": 10, "weight_guidance": "Warm up flow", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Flow through full sequence", "substitution": "Cat-Cow Flow", "exercise_library_id": None, "in_library": False},
            {"name": "Front Split Progression", "sets": 2, "reps": 90, "rest_seconds": 15, "weight_guidance": "Hold 90 seconds each side", "equipment": "Yoga Blocks", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Sink gradually, breathe through discomfort", "substitution": "Low Lunge Hold", "exercise_library_id": None, "in_library": False},
            {"name": "Middle Split Progression", "sets": 2, "reps": 90, "rest_seconds": 15, "weight_guidance": "Hold 90 seconds", "equipment": "None", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": [], "difficulty": "advanced", "form_cue": "Gentle descent, use hands for support", "substitution": "Frog Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Bridge Hold", "sets": 3, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds, push chest over hands", "equipment": "None", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Shoulders", "Glutes"], "difficulty": "intermediate", "form_cue": "Full bridge, work toward straightening arms", "substitution": "Cobra Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Shoulder Stand", "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Hold 30 seconds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Back"], "difficulty": "intermediate", "form_cue": "Support lower back, legs straight up", "substitution": "Legs Up the Wall", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 4w x 5/wk
    weeks_data[(4, 5)] = {
        1: {"focus": "Assess & Build Foundation", "workouts": [splits_focus, backbend_focus, middle_splits, active_flex, full_flow]},
        2: {"focus": "Push Ranges - Longer Holds", "workouts": [backbend_focus, middle_splits, splits_focus, full_flow, active_flex]},
        3: {"focus": "Active Flexibility Integration", "workouts": [middle_splits, splits_focus, backbend_focus, active_flex, full_flow]},
        4: {"focus": "Test & Document Progress", "workouts": [splits_focus, backbend_focus, middle_splits, active_flex, full_flow]}
    }

    # 8w x 5/wk
    w8 = {}
    for wk in range(1, 5):
        w8[wk] = weeks_data[(4, 5)][wk]
    w8[5] = {"focus": "Recovery Week - Gentle Maintenance", "workouts": [active_flex, full_flow, splits_focus, active_flex, full_flow]}
    w8[6] = {"focus": "Second Push - New Personal Bests", "workouts": [splits_focus, middle_splits, backbend_focus, active_flex, full_flow]}
    w8[7] = {"focus": "Advanced Holds - Maximum Duration", "workouts": [backbend_focus, splits_focus, middle_splits, full_flow, active_flex]}
    w8[8] = {"focus": "Final Assessment - Measure Transformation", "workouts": [splits_focus, backbend_focus, middle_splits, active_flex, full_flow]}
    weeks_data[(8, 5)] = w8

    # 12w x 6/wk
    w12 = {}
    for wk in range(1, 9):
        w12[wk] = w8[wk]
    w12[9] = {"focus": "Third Build - Deeper Backbends", "workouts": [backbend_focus, splits_focus, middle_splits, active_flex, full_flow, backbend_focus]}
    w12[10] = {"focus": "Advanced Splits Work", "workouts": [splits_focus, middle_splits, backbend_focus, active_flex, full_flow, splits_focus]}
    w12[11] = {"focus": "Consolidate All Ranges", "workouts": [full_flow, active_flex, splits_focus, backbend_focus, middle_splits, full_flow]}
    w12[12] = {"focus": "Final Showcase - Full Flexibility Test", "workouts": [splits_focus, backbend_focus, middle_splits, active_flex, full_flow, active_flex]}
    weeks_data[(12, 6)] = w12

    return weeks_data


def main():
    helper = ProgramSQLHelper()

    # 1. Morning Mobility
    mig = helper.get_next_migration_num()
    print(f"\n1. Generating Morning Mobility (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Morning Mobility",
        category_name="Flexibility/Stretches",
        description="A daily 15-minute morning mobility routine to wake up your body and improve range of motion. Alternates between upper body, lower body, and full body flows for a balanced approach to daily flexibility.",
        durations=[1, 2, 4], sessions_per_week=[7, 7, 7],
        has_supersets=False, priority="High",
        weeks_data=build_morning_mobility(), migration_num=mig, write_sql=True)
    if success:
        print("   Morning Mobility inserted!")
        helper.update_tracker("Morning Mobility", "Done")

    # 2. Full Body Flexibility
    mig = helper.get_next_migration_num()
    print(f"\n2. Generating Full Body Flexibility (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Full Body Flexibility",
        category_name="Flexibility/Stretches",
        description="Comprehensive stretching program covering all major muscle groups. Includes static holds, PNF techniques, and active flexibility work for total body range of motion improvement.",
        durations=[2, 4, 8], sessions_per_week=[4, 4, 5],
        has_supersets=False, priority="High",
        weeks_data=build_full_body_flexibility(), migration_num=mig, write_sql=True)
    if success:
        print("   Full Body Flexibility inserted!")
        helper.update_tracker("Full Body Flexibility", "Done")

    # 3. Office Worker Recovery
    mig = helper.get_next_migration_num()
    print(f"\n3. Generating Office Worker Recovery (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Office Worker Recovery",
        category_name="Flexibility/Stretches",
        description="Short daily stretching routines designed to counteract the effects of prolonged sitting. Targets neck, shoulders, chest, hip flexors, and lower back with desk-job-specific relief.",
        durations=[1, 2, 4], sessions_per_week=[5, 5, 7],
        has_supersets=False, priority="High",
        weeks_data=build_office_worker_recovery(), migration_num=mig, write_sql=True)
    if success:
        print("   Office Worker Recovery inserted!")
        helper.update_tracker("Office Worker Recovery", "Done")

    # 4. Flexibility for Beginners
    mig = helper.get_next_migration_num()
    print(f"\n4. Generating Flexibility for Beginners (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Flexibility for Beginners",
        category_name="Flexibility/Stretches",
        description="A gentle introduction to stretching for people who have never followed a flexibility routine. Short sessions with basic stretches, using supported positions and manageable hold times.",
        durations=[1, 2, 4], sessions_per_week=[3, 3, 4],
        has_supersets=False, priority="High",
        weeks_data=build_flexibility_beginners(), migration_num=mig, write_sql=True)
    if success:
        print("   Flexibility for Beginners inserted!")
        helper.update_tracker("Flexibility for Beginners", "Done")

    # 5. Contortionist Basics
    mig = helper.get_next_migration_num()
    print(f"\n5. Generating Contortionist Basics (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Contortionist Basics",
        category_name="Flexibility/Stretches",
        description="An extreme flexibility program for those pursuing front splits, middle splits, and deep backbends. Features long holds, PNF stretching, and progressive overload applied to flexibility training.",
        durations=[4, 8, 12], sessions_per_week=[5, 5, 6],
        has_supersets=False, priority="High",
        weeks_data=build_contortionist_basics(), migration_num=mig, write_sql=True)
    if success:
        print("   Contortionist Basics inserted!")
        helper.update_tracker("Contortionist Basics", "Done")

    helper.close()
    print("\nAll flexibility programs complete!")


if __name__ == "__main__":
    main()
