#!/usr/bin/env python3
"""Generate Sleep & Recovery, Menstrual Cycle, Swimming & Aquatic,
Climbing & Vertical, and misc programs."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

def ex(n, s, r, rest, w, eq, bp, pm, sm, d, cue, sub):
    return {"name": n, "exercise_library_id": None, "in_library": False,
            "sets": s, "reps": r, "rest_seconds": rest, "weight_guidance": w,
            "equipment": eq, "body_part": bp, "primary_muscle": pm,
            "secondary_muscles": sm, "difficulty": d, "form_cue": cue, "substitution": sub}

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# ──────────────────────────────────────────────
# SLEEP & RECOVERY workout templates
# ──────────────────────────────────────────────

def recovery_foam_rolling():
    return wo("Foam Rolling & Release", "recovery", 25, [
        ex("Foam Roll Quads", 2, 1, 0, "Hold tender spots 30s", "Foam Roller", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Slow rolls, pause on knots", "Lacrosse Ball Quad Release"),
        ex("Foam Roll IT Band", 2, 1, 0, "Hold tender spots 30s", "Foam Roller", "Legs", "IT Band", ["Vastus Lateralis"], "beginner", "Roll from hip to knee slowly", "Side-Lying Stretch"),
        ex("Foam Roll Thoracic Spine", 2, 8, 0, "Gentle extensions", "Foam Roller", "Back", "Thoracic Spine", ["Rhomboids"], "beginner", "Arms crossed, extend over roller", "Cat-Cow"),
        ex("Foam Roll Glutes", 2, 1, 0, "Hold tender spots 30s", "Foam Roller", "Glutes", "Gluteus Maximus", ["Piriformis"], "beginner", "Cross ankle over knee, lean into it", "Figure-4 Stretch"),
        ex("Foam Roll Calves", 2, 1, 0, "Hold tender spots 30s", "Foam Roller", "Legs", "Calves", ["Soleus"], "beginner", "Stack legs for more pressure", "Calf Stretch on Step"),
        ex("Foam Roll Lats", 2, 1, 0, "Hold tender spots 30s", "Foam Roller", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Lie on side, roll armpit to mid-back", "Lat Stretch on Wall"),
    ])

def recovery_gentle_yoga():
    return wo("Gentle Yoga Flow", "flexibility", 25, [
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Yoga Mat", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, reach forward, breathe deeply", "Puppy Pose"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Core", "Obliques", ["Lower Back"], "beginner", "Knees to one side, look opposite", "Seated Twist"),
        ex("Reclined Pigeon", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Figure-4 on back, pull thigh gently", "Seated Figure-4"),
        ex("Legs Up the Wall", 2, 1, 0, "Hold 2-3 minutes", "Yoga Mat", "Legs", "Hamstrings", ["Calves", "Lower Back"], "beginner", "Hips close to wall, relax completely", "Elevated Leg Rest"),
        ex("Supported Bridge", 2, 1, 0, "Hold 60 seconds", "Yoga Block", "Hips", "Hip Flexors", ["Glutes", "Lower Back"], "beginner", "Block under sacrum, let body drape", "Glute Bridge Hold"),
        ex("Savasana with Breathing", 1, 1, 0, "5 minutes, 4-7-8 pattern", "Yoga Mat", "Full Body", "Diaphragm", ["Transverse Abdominis"], "beginner", "Inhale 4, hold 7, exhale 8", "Supine Relaxation"),
    ])

def recovery_light_movement():
    return wo("Light Active Recovery", "recovery", 20, [
        ex("Walking", 1, 1, 0, "10 minutes easy pace", "None", "Full Body", "Calves", ["Hamstrings", "Quadriceps"], "beginner", "Relaxed pace, swing arms naturally", "Marching in Place"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Yoga Mat", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round smoothly", "Seated Cat-Cow"),
        ex("Hip Circle", 2, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Large smooth circles", "Lying Hip Circle"),
        ex("Shoulder Dislocate", 2, 10, 0, "Use band or stick", "Resistance Band", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Wide grip, slow overhead arc", "Shoulder Circle"),
        ex("Ankle Circle", 2, 10, 0, "Each direction each foot", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Full range of motion circles", "Ankle Pump"),
        ex("Deep Breathing", 2, 5, 0, "Diaphragmatic 4-6 pattern", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "4 count in through nose, 6 count out through mouth", "Box Breathing"),
    ])

def recovery_parasympathetic():
    return wo("Parasympathetic Activation", "recovery", 25, [
        ex("Box Breathing", 2, 5, 0, "4-4-4-4 pattern", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale 4, hold 4, exhale 4, hold 4", "Belly Breathing"),
        ex("Progressive Muscle Relaxation", 1, 1, 0, "Full body scan 5 min", "Yoga Mat", "Full Body", "Various", ["Various"], "beginner", "Tense each group 5s, release 10s", "Body Scan Meditation"),
        ex("Supine Spinal Twist", 2, 1, 0, "Hold 60 seconds each side", "Yoga Mat", "Core", "Obliques", ["Erector Spinae"], "beginner", "Let gravity pull knees down gently", "Seated Twist"),
        ex("Supported Fish Pose", 2, 1, 0, "Hold 2 minutes", "Yoga Block", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Block under upper back, arms open", "Chest Opener on Wall"),
        ex("Humming Bee Breath", 2, 5, 0, "Bhramari pranayama", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Inhale deeply, hum on exhale", "Extended Exhale Breathing"),
        ex("Constructive Rest Position", 1, 1, 0, "Hold 5 minutes", "Yoga Mat", "Full Body", "Psoas", ["Hip Flexors"], "beginner", "Feet flat, knees together, arms rest", "Savasana"),
    ])

def recovery_deload_strength():
    return wo("Deload Strength", "strength", 30, [
        ex("Goblet Squat", 3, 8, 60, "50% normal weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Controlled tempo, full depth", "Bodyweight Squat"),
        ex("Dumbbell Bench Press", 3, 8, 60, "50% normal weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Slow eccentric, pause at bottom", "Push-up"),
        ex("Cable Row", 3, 10, 45, "Light weight, squeeze", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi"], "beginner", "Slow pull, 2 second squeeze", "Band Pull-Apart"),
        ex("Dumbbell Lateral Raise", 2, 12, 30, "Very light", "Dumbbell", "Shoulders", "Medial Deltoid", ["Trapezius"], "beginner", "Controlled raise, slow lower", "Band Lateral Raise"),
        ex("Glute Bridge", 3, 12, 30, "Bodyweight only", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze glutes hard at top", "Hip Thrust"),
        ex("Dead Bug", 2, 8, 30, "Slow controlled reps", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Low back pressed to floor", "Bird-Dog"),
    ])

def recovery_hrv_moderate():
    return wo("HRV-Based Moderate Session", "strength", 35, [
        ex("Kettlebell Goblet Squat", 3, 10, 60, "Moderate weight", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Elbows between knees at bottom", "Dumbbell Goblet Squat"),
        ex("Dumbbell Row", 3, 10, 45, "Moderate weight", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, squeeze back", "Cable Row"),
        ex("Push-up", 3, 12, 30, "Full range of motion", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Elbows 45 degrees, full depth", "Knee Push-up"),
        ex("Kettlebell Swing", 3, 12, 45, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap, float to chest height", "Dumbbell Swing"),
        ex("Pallof Press", 2, 10, 30, "Light band or cable", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "beginner", "Press out, resist rotation", "Band Anti-Rotation Hold"),
        ex("Walking Lunge", 3, 8, 45, "Bodyweight or light DB", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Reverse Lunge"),
    ])

def recovery_sleep_prep():
    return wo("Sleep Preparation Routine", "flexibility", 20, [
        ex("Neck Release", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear toward shoulder, gentle hand pressure", "Neck Roll"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 60 seconds", "Yoga Mat", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Hinge at hips, let head hang", "Standing Forward Fold"),
        ex("Supine Butterfly", 2, 1, 0, "Hold 2 minutes", "Yoga Mat", "Hips", "Adductors", ["Hip Flexors"], "beginner", "Soles together, knees drop open", "Seated Butterfly"),
        ex("Legs Up the Wall", 1, 1, 0, "Hold 3-5 minutes", "Yoga Mat", "Legs", "Hamstrings", ["Calves"], "beginner", "Hips near wall, relax fully", "Elevated Leg Rest"),
        ex("4-7-8 Breathing", 3, 4, 0, "Calming breath pattern", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Inhale 4, hold 7, exhale 8", "Belly Breathing"),
        ex("Body Scan Relaxation", 1, 1, 0, "5 minutes progressive", "Yoga Mat", "Full Body", "Various", ["Various"], "beginner", "Tense and release from toes to head", "Savasana"),
    ])

def recovery_weekend_warrior():
    return wo("Weekend Warrior Recovery", "recovery", 30, [
        ex("Foam Roll Full Body", 1, 1, 0, "5 minutes all major groups", "Foam Roller", "Full Body", "Various", ["Various"], "beginner", "Spend extra time on sore areas", "Lacrosse Ball Release"),
        ex("World's Greatest Stretch", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings"], "beginner", "Lunge, rotate, reach overhead", "Spiderman Stretch"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60 seconds each side", "Yoga Mat", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Doorway Chest Stretch", 2, 1, 0, "Hold 30 seconds", "Doorway", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm at 90 degrees, lean through", "Wall Chest Stretch"),
        ex("Couch Stretch", 2, 1, 0, "Hold 60 seconds each side", "Wall", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Rear knee near wall, upright torso", "Half-Kneeling Hip Flexor Stretch"),
        ex("Light Walk", 1, 1, 0, "10 minutes easy pace", "None", "Full Body", "Calves", ["Hamstrings"], "beginner", "Easy pace to flush metabolites", "Marching in Place"),
    ])

# ──────────────────────────────────────────────
# MENSTRUAL CYCLE workout templates
# ──────────────────────────────────────────────

def menstrual_follicular_strength():
    return wo("Follicular Strength", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 90, "70-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, brace core, drive through heels", "Goblet Squat"),
        ex("Barbell Bench Press", 4, 8, 90, "70-80% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch chest, controlled press up", "Dumbbell Bench Press"),
        ex("Pull-up", 3, 8, 60, "Add weight if possible", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full dead hang, chin over bar", "Lat Pulldown"),
        ex("Barbell Hip Thrust", 4, 10, 60, "Heavy, progressive load", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Pause at top, squeeze glutes", "Glute Bridge"),
        ex("Dumbbell Row", 3, 10, 45, "Moderate-heavy", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, retract scapula", "Cable Row"),
        ex("Hanging Leg Raise", 3, 10, 45, "Controlled movement", "Pull-up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "No swinging, raise to 90 degrees", "Lying Leg Raise"),
    ])

def menstrual_follicular_hiit():
    return wo("Follicular HIIT", "hiit", 30, [
        ex("Box Jump", 3, 10, 30, "20-24 inch box", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Explosive jump, soft landing", "Squat Jump"),
        ex("Battle Rope Slam", 3, 15, 30, "Maximum effort", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Back"], "intermediate", "Alternate arms rapidly, slam hard", "Medicine Ball Slam"),
        ex("Kettlebell Swing", 3, 15, 30, "Moderate-heavy KB", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Powerful hip snap", "Dumbbell Swing"),
        ex("Burpee", 3, 10, 30, "Full range with jump", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, max height jump", "Squat Thrust"),
        ex("Mountain Climber", 3, 20, 30, "Sprint pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders", "Core"], "beginner", "Rapid alternating knees to chest", "Plank Knee Tuck"),
        ex("Tuck Jump", 3, 8, 45, "Maximum height", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Calves"], "intermediate", "Knees to chest at peak", "Squat Jump"),
    ])

def menstrual_ovulation_power():
    return wo("Ovulation Power Session", "strength", 50, [
        ex("Barbell Deadlift", 4, 5, 120, "80-85% 1RM", "Barbell", "Full Body", "Glutes", ["Hamstrings", "Lower Back", "Quadriceps"], "intermediate", "Hips and shoulders rise together", "Trap Bar Deadlift"),
        ex("Barbell Overhead Press", 4, 6, 90, "75-80% 1RM", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, full lockout overhead", "Dumbbell Shoulder Press"),
        ex("Barbell Front Squat", 4, 6, 90, "70-75% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Elbows high, upright torso", "Goblet Squat"),
        ex("Weighted Pull-up", 3, 6, 90, "Add 10-25 lbs", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Full range, controlled descent", "Lat Pulldown"),
        ex("Barbell Hip Thrust", 4, 8, 60, "Heavy progressive load", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Powerful drive, 2s hold at top", "Single-Leg Hip Thrust"),
        ex("Plank to Push-up", 3, 10, 45, "Controlled transitions", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Alternate lead arm, minimize hip sway", "Plank"),
    ])

def menstrual_luteal_moderate():
    return wo("Luteal Phase Moderate", "strength", 35, [
        ex("Goblet Squat", 3, 12, 60, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Controlled tempo, full depth", "Bodyweight Squat"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Slow eccentric, controlled press", "Push-up"),
        ex("Seated Cable Row", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Squeeze shoulder blades together", "Band Row"),
        ex("Dumbbell Romanian Deadlift", 3, 10, 45, "Moderate weight", "Dumbbell", "Legs", "Hamstrings", ["Glutes"], "beginner", "Hinge at hips, slight knee bend", "Good Morning"),
        ex("Dumbbell Lateral Raise", 2, 12, 30, "Light weight", "Dumbbell", "Shoulders", "Medial Deltoid", ["Trapezius"], "beginner", "Slight bend in elbows, controlled", "Band Lateral Raise"),
        ex("Bird-Dog", 2, 10, 30, "Slow controlled reps", "Bodyweight", "Core", "Erector Spinae", ["Transverse Abdominis", "Glutes"], "beginner", "Extend opposite arm and leg, pause", "Dead Bug"),
    ])

def menstrual_phase_gentle():
    return wo("Menstrual Phase Gentle Movement", "flexibility", 20, [
        ex("Seated Cat-Cow", 2, 10, 0, "Gentle breathing rhythm", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round gently", "Standing Cat-Cow"),
        ex("Supported Child's Pose", 2, 1, 0, "Hold 90 seconds", "Yoga Block", "Back", "Latissimus Dorsi", ["Hips"], "beginner", "Bolster under torso, knees wide", "Child's Pose"),
        ex("Supine Butterfly", 2, 1, 0, "Hold 2 minutes", "Yoga Mat", "Hips", "Adductors", ["Hip Flexors"], "beginner", "Pillows under knees for support", "Seated Butterfly"),
        ex("Gentle Spinal Twist", 2, 1, 0, "Hold 60 seconds each side", "Yoga Mat", "Core", "Obliques", ["Erector Spinae"], "beginner", "Knees stacked, arms T position", "Seated Twist"),
        ex("Diaphragmatic Breathing", 3, 5, 0, "Belly breathing pattern", "Yoga Mat", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Hand on belly, feel it rise and fall", "Box Breathing"),
        ex("Gentle Walking", 1, 1, 0, "10-15 minutes easy", "None", "Full Body", "Calves", ["Hamstrings"], "beginner", "Very easy pace, enjoy movement", "Marching in Place"),
    ])

def menstrual_heavy_gentle():
    return wo("Heavy Period Gentle Session", "flexibility", 15, [
        ex("Supported Recline", 1, 1, 0, "Hold 3 minutes", "Yoga Block", "Chest", "Pectoralis Major", ["Hip Flexors"], "beginner", "Block under upper back, relax fully", "Savasana"),
        ex("Gentle Neck Stretch", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear to shoulder very gently", "Neck Roll"),
        ex("Ankle and Wrist Circles", 2, 10, 0, "Each direction", "Bodyweight", "Extremities", "Forearms", ["Calves"], "beginner", "Slow full circles, seated or lying", "Ankle Pump"),
        ex("Legs Up the Wall", 1, 1, 0, "Hold 5 minutes", "Yoga Mat", "Legs", "Hamstrings", ["Calves"], "beginner", "Hips near wall, eyes closed", "Elevated Leg Rest"),
        ex("Extended Exhale Breathing", 2, 5, 0, "Inhale 3, exhale 6", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Longer exhale activates calm response", "Belly Breathing"),
    ])

def menstrual_cycle_synced_cardio():
    return wo("Cycle-Synced Cardio", "conditioning", 30, [
        ex("Incline Walk", 1, 1, 0, "12-15 minutes moderate", "Treadmill", "Legs", "Calves", ["Glutes", "Hamstrings"], "beginner", "3-5% incline, brisk pace", "Outdoor Walking"),
        ex("Elliptical Intervals", 1, 1, 0, "10 minutes alternating pace", "Elliptical", "Full Body", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "30s fast, 60s moderate", "Stationary Bike"),
        ex("Bodyweight Squat", 3, 15, 30, "Moderate tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, controlled tempo", "Chair Squat"),
        ex("Step-up", 3, 10, 30, "Alternating legs", "Bench", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Drive through heel, stand tall", "Reverse Lunge"),
        ex("Lateral Shuffle", 3, 10, 30, "Each direction", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps"], "beginner", "Stay low, quick feet", "Side Step"),
        ex("Cool Down Walk", 1, 1, 0, "5 minutes easy", "None", "Full Body", "Calves", ["Hamstrings"], "beginner", "Gradually reduce pace", "Standing March"),
    ])

# ──────────────────────────────────────────────
# SWIMMING & AQUATIC workout templates
# ──────────────────────────────────────────────

def swim_water_aerobics():
    return wo("Water Aerobics", "conditioning", 40, [
        ex("Water Walking", 1, 1, 0, "5 minutes waist-deep", "Pool", "Full Body", "Quadriceps", ["Calves", "Core"], "beginner", "High knees, push through resistance", "Shallow End March"),
        ex("Water Jogging", 1, 1, 0, "5 minutes chest-deep", "Pool", "Full Body", "Hip Flexors", ["Core", "Calves"], "beginner", "Pump arms, keep upright posture", "Deep Water Jog"),
        ex("Aqua Jumping Jacks", 3, 15, 15, "Chest-deep water", "Pool", "Full Body", "Deltoids", ["Adductors", "Abductors"], "beginner", "Full range arms and legs", "Water Star Jumps"),
        ex("Water Arm Curl", 3, 15, 15, "Use foam dumbbells", "Pool Noodle", "Arms", "Biceps", ["Forearms"], "beginner", "Submerge and curl against resistance", "Resistance Band Curl"),
        ex("Aqua Lunge", 3, 10, 15, "Each leg alternating", "Pool", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Large step, knee over ankle", "Bodyweight Lunge"),
        ex("Pool Noodle Core Twist", 3, 15, 15, "Seated on noodle", "Pool Noodle", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Sit on noodle, rotate torso side to side", "Russian Twist"),
        ex("Water Bicycle", 3, 20, 15, "Deep end with noodle", "Pool Noodle", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "beginner", "Pedaling motion while floating", "Flutter Kick"),
    ])

def swim_aqua_jogging():
    return wo("Aqua Jogging Session", "conditioning", 35, [
        ex("Deep Water Jogging", 1, 1, 0, "10 minutes moderate", "Aqua Belt", "Full Body", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Upright posture, pump arms, no ground contact", "Water Walking"),
        ex("Aqua Sprints", 5, 1, 30, "30 seconds max effort", "Aqua Belt", "Full Body", "Quadriceps", ["Hamstrings", "Core"], "intermediate", "All-out effort, recover 30s", "Pool Wall Sprint"),
        ex("Cross Country Water Run", 1, 1, 0, "5 minutes moderate", "Aqua Belt", "Full Body", "Glutes", ["Hip Flexors"], "beginner", "Exaggerated arm and leg swing", "Deep Water Jog"),
        ex("Water High Knees", 3, 20, 15, "Chest-deep water", "Pool", "Legs", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Drive knees high, pump arms", "Pool March"),
        ex("Aqua Side Shuffle", 3, 10, 15, "Each direction", "Pool", "Legs", "Gluteus Medius", ["Adductors"], "beginner", "Stay low, push through water", "Lateral Shuffle"),
        ex("Water Cool Down Walk", 1, 1, 0, "5 minutes easy", "Pool", "Full Body", "Calves", ["Hamstrings"], "beginner", "Gentle walking, let heart rate drop", "Shallow End Walk"),
    ])

def swim_triathlon():
    return wo("Swim for Triathlon", "conditioning", 50, [
        ex("Freestyle Warm-up", 1, 1, 0, "200m easy freestyle", "Pool", "Full Body", "Latissimus Dorsi", ["Deltoids", "Core"], "intermediate", "Smooth stroke, bilateral breathing", "Backstroke Warm-up"),
        ex("Freestyle Drill - Catch-up", 4, 1, 15, "50m per set", "Pool", "Back", "Latissimus Dorsi", ["Deltoids"], "intermediate", "Touch hands before next stroke", "Fingertip Drag Drill"),
        ex("Freestyle Intervals", 6, 1, 30, "100m moderate-hard", "Pool", "Full Body", "Latissimus Dorsi", ["Deltoids", "Core", "Quadriceps"], "intermediate", "Hold pace, breathe every 3", "50m Repeats"),
        ex("Kick Set", 4, 1, 15, "50m with kickboard", "Kickboard", "Legs", "Quadriceps", ["Hip Flexors", "Calves"], "beginner", "Flutter kick from hips, toes pointed", "Kick on Back"),
        ex("Pull Set", 4, 1, 15, "100m with pull buoy", "Pull Buoy", "Back", "Latissimus Dorsi", ["Deltoids", "Pectoralis Major"], "intermediate", "Focus on catch and pull phase", "Paddle Pull Set"),
        ex("Cool Down Swim", 1, 1, 0, "200m easy choice stroke", "Pool", "Full Body", "Latissimus Dorsi", ["Deltoids"], "beginner", "Very easy pace, stretch out strokes", "Easy Backstroke"),
    ])

def swim_pool_recovery():
    return wo("Pool Recovery Session", "recovery", 25, [
        ex("Easy Backstroke", 1, 1, 0, "200m very easy", "Pool", "Full Body", "Latissimus Dorsi", ["Deltoids", "Core"], "beginner", "Relaxed stroke, feel the water support you", "Easy Breaststroke"),
        ex("Pool Walking", 1, 1, 0, "5 minutes waist-deep", "Pool", "Legs", "Quadriceps", ["Calves", "Core"], "beginner", "Walk forward and backward", "Shallow End March"),
        ex("Aqua Leg Swing", 2, 10, 0, "Each leg, hold wall", "Pool", "Hips", "Hip Flexors", ["Glutes", "Hamstrings"], "beginner", "Forward and back swings, let water resist", "Standing Leg Swing"),
        ex("Pool Spinal Twist", 2, 8, 0, "Hold wall for support", "Pool", "Core", "Obliques", ["Erector Spinae"], "beginner", "Gentle rotation in water", "Seated Twist"),
        ex("Floating Relaxation", 1, 1, 0, "3 minutes on back", "Pool Noodle", "Full Body", "Various", ["Various"], "beginner", "Noodle under knees, float and breathe", "Savasana"),
        ex("Gentle Flutter Kick", 2, 1, 0, "1 minute easy kick", "Kickboard", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Light kick from hips, stay relaxed", "Ankle Pump"),
    ])

def swim_aquatic_hiit():
    return wo("Aquatic HIIT", "hiit", 30, [
        ex("Pool Sprint", 5, 1, 30, "25m all-out", "Pool", "Full Body", "Latissimus Dorsi", ["Quadriceps", "Core"], "intermediate", "Maximum effort sprint, rest at wall", "Aqua Sprint on Spot"),
        ex("Water Burpee", 3, 8, 30, "Chest-deep water", "Pool", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Squat down, push off bottom, jump up", "Squat Jump in Water"),
        ex("Aqua Tuck Jump", 3, 10, 20, "Chest-deep water", "Pool", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Jump and tuck knees to chest", "Water Squat Jump"),
        ex("Pool Wall Push-up", 3, 12, 20, "Angle off pool wall", "Pool", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Push off wall explosively", "Water Arm Press"),
        ex("Water Mountain Climber", 3, 20, 20, "Hold wall, kick", "Pool", "Core", "Hip Flexors", ["Shoulders", "Core"], "beginner", "Alternating knees while holding wall", "Flutter Kick"),
        ex("Treading Water Intervals", 4, 1, 20, "30 seconds hard, 20 rest", "Pool", "Full Body", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Aggressive arm and leg movement", "Egg Beater Kick"),
    ])

def swim_technique():
    return wo("Swim Technique Session", "conditioning", 45, [
        ex("Catch-up Drill", 4, 1, 15, "50m per set", "Pool", "Back", "Latissimus Dorsi", ["Deltoids"], "intermediate", "Full extension before next stroke", "Single Arm Drill"),
        ex("Fingertip Drag Drill", 4, 1, 15, "50m per set", "Pool", "Shoulders", "Deltoids", ["Latissimus Dorsi"], "intermediate", "Drag fingertips along water surface", "Zipper Drill"),
        ex("Kick on Side Drill", 4, 1, 15, "50m per set, alternate", "Pool", "Core", "Obliques", ["Quadriceps", "Hip Flexors"], "intermediate", "Stay on side, bottom arm extended", "Kickboard Drill"),
        ex("Sculling Drill", 4, 1, 15, "25m per set", "Pool", "Shoulders", "Forearms", ["Deltoids"], "intermediate", "Small figure-8 motions with hands", "Water Treading"),
        ex("Sighting Drill", 4, 1, 15, "50m with head lifts", "Pool", "Neck", "Trapezius", ["Deltoids", "Core"], "intermediate", "Lift eyes forward every 4 strokes", "Head-Up Freestyle"),
        ex("Bilateral Breathing Sets", 4, 1, 15, "100m breathe every 3", "Pool", "Core", "Obliques", ["Latissimus Dorsi"], "intermediate", "Alternate breathing side each stroke cycle", "Breathe Every 5"),
    ])

def swim_arthritis_pool():
    return wo("Arthritis Pool Exercise", "flexibility", 30, [
        ex("Warm Water Walking", 1, 1, 0, "5 minutes gentle", "Pool", "Full Body", "Quadriceps", ["Calves"], "beginner", "Warm water, very gentle pace", "Standing March"),
        ex("Water Arm Circle", 2, 10, 0, "Each direction, submerged", "Pool", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Slow controlled circles underwater", "Arm Circle"),
        ex("Aqua Knee Lift", 2, 10, 0, "Alternating, hold wall", "Pool", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Gentle lift, water supports weight", "Standing Knee Raise"),
        ex("Pool Finger Squeeze", 2, 10, 0, "Squeeze foam ball underwater", "Pool", "Hands", "Forearms", ["Finger Flexors"], "beginner", "Squeeze and release slowly", "Hand Grip Exercise"),
        ex("Water Hip Abduction", 2, 10, 0, "Each leg, hold wall", "Pool", "Hips", "Gluteus Medius", ["Hip Flexors"], "beginner", "Leg out to side against water", "Standing Hip Abduction"),
        ex("Gentle Water Stretch", 2, 1, 0, "Hold 30 seconds each", "Pool", "Full Body", "Various", ["Various"], "beginner", "Use water buoyancy to deepen stretch gently", "Gentle Floor Stretch"),
    ])

# ──────────────────────────────────────────────
# CLIMBING & VERTICAL workout templates
# ──────────────────────────────────────────────

def climb_prep_strength():
    return wo("Rock Climbing Prep Strength", "strength", 45, [
        ex("Pull-up", 4, 6, 90, "Strict form", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full dead hang to chin over bar, controlled", "Lat Pulldown"),
        ex("Dead Hang", 3, 1, 60, "Hold 30-45 seconds", "Pull-up Bar", "Forearms", "Finger Flexors", ["Forearms", "Latissimus Dorsi"], "beginner", "Relax shoulders, engage grip", "Towel Hang"),
        ex("Inverted Row", 3, 10, 45, "Rings or bar", "Pull-up Bar", "Back", "Rhomboids", ["Biceps", "Rear Deltoid"], "beginner", "Body straight, pull chest to bar", "Seated Row"),
        ex("Hanging Knee Raise", 3, 12, 45, "Controlled movement", "Pull-up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "No swinging, slow controlled lift", "Lying Leg Raise"),
        ex("Dumbbell Shoulder Press", 3, 10, 60, "Moderate weight", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Full lockout, controlled descent", "Pike Push-up"),
        ex("Wrist Curl", 3, 15, 30, "Light dumbbell", "Dumbbell", "Forearms", "Forearm Flexors", ["Wrist Extensors"], "beginner", "Full range of motion, slow", "Reverse Wrist Curl"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Half-kneeling, push hips forward", "Couch Stretch"),
    ])

def climb_bouldering():
    return wo("Bouldering Strength", "strength", 40, [
        ex("Wide Grip Pull-up", 4, 6, 90, "Wider than shoulder width", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Teres Major", "Biceps"], "intermediate", "Wide grip, pull to upper chest", "Lat Pulldown Wide"),
        ex("Lock-off Hold", 3, 1, 60, "Hold at 90 degrees each arm", "Pull-up Bar", "Back", "Biceps", ["Latissimus Dorsi", "Forearms"], "advanced", "Pull up, hold with one arm assist", "Isometric Bicep Hold"),
        ex("Campus Board Touches", 3, 8, 60, "If available", "Campus Board", "Forearms", "Finger Flexors", ["Latissimus Dorsi"], "advanced", "Dynamic hand movements up rungs", "Dynamic Pull-up"),
        ex("Plank to Side Plank", 3, 6, 30, "Alternate sides", "Bodyweight", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Rotate with control, stack feet", "Side Plank"),
        ex("Pistol Squat Progression", 3, 5, 60, "Each leg, use box assist", "Box", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Controlled descent, drive up", "Bulgarian Split Squat"),
        ex("Reverse Wrist Curl", 3, 15, 30, "Light dumbbell", "Dumbbell", "Forearms", "Wrist Extensors", ["Forearm Extensors"], "beginner", "Slow controlled movement", "Wrist Roller"),
    ])

def climb_finger_strength():
    return wo("Finger Strength Training", "strength", 35, [
        ex("Dead Hang - Open Hand", 4, 1, 60, "Hold 20-30 seconds", "Hangboard", "Forearms", "Finger Flexors", ["Forearms"], "intermediate", "Open hand grip, 4 fingers, relax shoulders", "Bar Hang"),
        ex("Dead Hang - Half Crimp", 3, 1, 60, "Hold 10-15 seconds", "Hangboard", "Forearms", "Finger Flexors", ["Forearms"], "advanced", "Half crimp, never full crimp for training", "Towel Hang"),
        ex("Finger Extensor Band", 3, 15, 30, "Rubber band around fingers", "Rubber Band", "Forearms", "Finger Extensors", ["Forearm Extensors"], "beginner", "Open fingers against resistance", "Reverse Grip Squeeze"),
        ex("Pinch Block Hold", 3, 1, 45, "Hold 15-20 seconds each hand", "Weight Plate", "Forearms", "Thumb Muscles", ["Forearm Flexors"], "intermediate", "Pinch grip a plate or block", "Plate Pinch"),
        ex("Rice Bucket Training", 3, 15, 30, "Various hand movements", "Rice Bucket", "Forearms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Plunge, squeeze, rotate in rice", "Hand Grip Exercise"),
        ex("Wrist Roller", 2, 3, 45, "Light weight up and down", "Wrist Roller", "Forearms", "Forearm Flexors", ["Forearm Extensors"], "intermediate", "Roll up fully then lower slowly", "Wrist Curl"),
    ])

def climb_antagonist():
    return wo("Climbing Antagonist Training", "strength", 35, [
        ex("Push-up", 3, 15, 45, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Elbows 45 degrees, full depth", "Knee Push-up"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Counteract pulling dominance", "Floor Press"),
        ex("Dumbbell Lateral Raise", 3, 12, 30, "Light weight", "Dumbbell", "Shoulders", "Medial Deltoid", ["Trapezius"], "beginner", "Slight elbow bend, controlled", "Band Lateral Raise"),
        ex("Tricep Dip", 3, 10, 45, "Parallel bars or bench", "Dip Station", "Arms", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Full depth, control descent", "Bench Dip"),
        ex("External Rotation", 3, 12, 30, "Light band or cable", "Resistance Band", "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner", "Elbow at side, rotate out", "Face Pull"),
        ex("Wrist Extension", 3, 15, 30, "Light dumbbell", "Dumbbell", "Forearms", "Wrist Extensors", ["Forearm Extensors"], "beginner", "Balance pulling grip work", "Reverse Wrist Curl"),
    ])

def climb_wall_endurance():
    return wo("Wall Climbing Endurance", "conditioning", 40, [
        ex("ARC Training", 1, 1, 0, "20 minutes easy climbing", "Climbing Wall", "Full Body", "Forearms", ["Latissimus Dorsi", "Core"], "intermediate", "Stay on wall, easy moves, no pump", "Traverse Climbing"),
        ex("4x4 Boulder Circuit", 4, 1, 120, "4 easy problems back to back", "Climbing Wall", "Full Body", "Forearms", ["Latissimus Dorsi", "Core"], "intermediate", "Minimal rest between problems", "Pull-up Circuit"),
        ex("Climbing Traverse", 3, 1, 60, "2 min traverses each set", "Climbing Wall", "Full Body", "Forearms", ["Latissimus Dorsi", "Biceps"], "intermediate", "Stay low, smooth movement", "Horizontal Pull-up Hold"),
        ex("Dead Hang Endurance", 3, 1, 60, "Hold as long as possible", "Pull-up Bar", "Forearms", "Finger Flexors", ["Forearms"], "intermediate", "Time each hang, beat previous", "Towel Hang"),
        ex("Core L-Sit Progression", 3, 1, 45, "Hold 15-30 seconds", "Parallettes", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "intermediate", "Legs straight, push shoulders down", "Tuck L-Sit"),
        ex("Hip Flexibility Flow", 2, 5, 0, "Dynamic hip openers", "Bodyweight", "Hips", "Hip Flexors", ["Adductors", "Glutes"], "beginner", "Frog stretch, deep squat, pigeon", "Hip Circle"),
    ])

def climb_core():
    return wo("Climbing Core Training", "strength", 30, [
        ex("Hanging Leg Raise", 3, 10, 45, "Controlled movement", "Pull-up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Legs together, lift to 90 degrees", "Lying Leg Raise"),
        ex("Front Lever Progression", 3, 1, 60, "Tuck or advanced tuck hold", "Pull-up Bar", "Core", "Latissimus Dorsi", ["Rectus Abdominis", "Serratus Anterior"], "advanced", "Hollow body, engage lats fully", "Dragon Flag"),
        ex("Side Plank with Hip Dip", 3, 10, 30, "Each side", "Bodyweight", "Core", "Obliques", ["Gluteus Medius"], "intermediate", "Dip hip down and raise, controlled", "Side Plank Hold"),
        ex("Windshield Wiper", 3, 8, 45, "Hanging or lying", "Pull-up Bar", "Core", "Obliques", ["Rectus Abdominis"], "advanced", "Legs side to side with control", "Lying Windshield Wiper"),
        ex("Hollow Body Hold", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "intermediate", "Low back pressed to floor, arms overhead", "Hollow Rock"),
        ex("Pallof Press", 3, 10, 30, "Cable or band", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Press out, resist rotation fully", "Anti-Rotation Hold"),
    ])

def climb_stair():
    return wo("Stair Climbing Fitness", "conditioning", 35, [
        ex("Stair Walk-up", 1, 1, 0, "5 minutes steady", "Stairs", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "One step at a time, upright posture", "Step-up"),
        ex("Stair Sprint", 5, 1, 45, "20-30 seconds up", "Stairs", "Legs", "Quadriceps", ["Calves", "Glutes", "Hamstrings"], "intermediate", "Explosive, pump arms, walk down rest", "Box Jump"),
        ex("Stair Lunge", 3, 10, 30, "Alternating, skip a step", "Stairs", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Big step, drive through heel", "Walking Lunge"),
        ex("Stair Calf Raise", 3, 15, 30, "Edge of step", "Stairs", "Legs", "Calves", ["Soleus"], "beginner", "Full range of motion, pause at top", "Standing Calf Raise"),
        ex("Stair Push-up", 3, 12, 30, "Hands on step", "Stairs", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Incline angle, full range", "Regular Push-up"),
        ex("Stair Cool Down Walk", 1, 1, 0, "5 minutes easy walk down", "Stairs", "Legs", "Quadriceps", ["Calves"], "beginner", "Controlled descent, hold rail if needed", "Walking"),
    ])

def climb_rope_prep():
    return wo("Rope Climbing Prep", "strength", 35, [
        ex("Pull-up", 4, 6, 90, "Strict, full range", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Dead hang to chin over, no kipping", "Lat Pulldown"),
        ex("Towel Pull-up", 3, 5, 90, "Grip towel over bar", "Towel", "Back", "Latissimus Dorsi", ["Forearms", "Biceps"], "advanced", "Towel grip, pull chin over bar", "Fat Grip Pull-up"),
        ex("Leg Lift on Bar", 3, 10, 45, "Controlled", "Pull-up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Straight legs to 90 degrees", "Knee Raise"),
        ex("Rope Grip Hang", 3, 1, 60, "Hold 15-20 seconds", "Rope", "Forearms", "Finger Flexors", ["Biceps"], "intermediate", "Grip rope firmly, hang body weight", "Towel Hang"),
        ex("J-Hook Foot Lock Practice", 3, 5, 45, "Ground-level practice", "Rope", "Legs", "Calves", ["Tibialis Anterior"], "intermediate", "Wrap rope around foot and lock", "Calf Raise"),
        ex("Bicep Curl", 3, 10, 45, "Moderate weight", "Dumbbell", "Arms", "Biceps", ["Forearms"], "beginner", "Slow eccentric, full range", "Hammer Curl"),
    ])

# ──────────────────────────────────────────────
# MISC workout templates
# ──────────────────────────────────────────────

def medical_hiv_session():
    return wo("HIV/AIDS Safe Exercise", "strength", 35, [
        ex("Bodyweight Squat", 3, 12, 45, "Controlled tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, stand tall at top", "Chair Squat"),
        ex("Incline Push-up", 3, 10, 45, "Hands on bench", "Bench", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Lower chest to bench, push up", "Wall Push-up"),
        ex("Resistance Band Row", 3, 12, 30, "Light-moderate band", "Resistance Band", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Squeeze shoulder blades together", "Seated Row"),
        ex("Glute Bridge", 3, 12, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze glutes at top, pause", "Hip Thrust"),
        ex("Standing Shoulder Press", 2, 10, 30, "Light dumbbells", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Press overhead, control descent", "Band Overhead Press"),
        ex("Walking", 1, 1, 0, "10 minutes moderate pace", "None", "Full Body", "Calves", ["Hamstrings", "Quadriceps"], "beginner", "Steady pace, maintain throughout", "Marching in Place"),
    ])

def plyometric_deceleration():
    return wo("Deceleration Training", "plyometrics", 35, [
        ex("Depth Drop to Stick", 4, 6, 60, "Start 12-18 inch box", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Step off box, land and freeze, absorb force", "Squat Jump Land and Hold"),
        ex("Lateral Bound to Stick", 3, 8, 45, "Each side", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves"], "intermediate", "Bound sideways, land single leg, hold 2s", "Lateral Hop"),
        ex("Backpedal to Sprint Stop", 4, 4, 60, "10 yard backpedal", "Bodyweight", "Legs", "Hamstrings", ["Calves", "Quadriceps"], "intermediate", "Backpedal, plant, decelerate to stop", "Reverse Lunge Walk"),
        ex("Drop Lunge", 3, 8, 45, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Step back and across, absorb landing", "Reverse Lunge"),
        ex("180 Jump to Stick", 3, 6, 60, "Rotate and land", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Jump, rotate 180, land soft and stable", "Squat Jump"),
        ex("Eccentric Single-Leg Squat", 3, 6, 45, "Each leg, slow 4s descent", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "intermediate", "4 second lowering, controlled", "Eccentric Squat"),
    ])

def gamer_lan_recovery():
    return wo("LAN Party Recovery", "recovery", 15, [
        ex("Wrist Circle", 2, 10, 0, "Each direction each wrist", "Bodyweight", "Forearms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Slow full circles, open fingers", "Wrist Flex and Extend"),
        ex("Neck Stretch", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear to shoulder, gentle pressure", "Neck Roll"),
        ex("Doorway Chest Stretch", 2, 1, 0, "Hold 30 seconds", "Doorway", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arms at 90 degrees in doorway, lean in", "Wall Chest Stretch"),
        ex("Seated Figure-4 Stretch", 2, 1, 0, "Hold 30 seconds each side", "Chair", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Ankle on knee, lean forward", "Standing Figure-4"),
        ex("Standing Calf Raise", 2, 15, 0, "Slow tempo, get blood moving", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Rise high, lower slowly", "Toe Raise"),
        ex("Standing March", 1, 1, 0, "2 minutes to get moving", "Bodyweight", "Full Body", "Hip Flexors", ["Quadriceps"], "beginner", "High knees, pump arms, wake up body", "Walking"),
    ])

def endurance_vo2max():
    return wo("VO2 Max Builder", "conditioning", 45, [
        ex("Running Intervals", 5, 1, 60, "4 minutes hard, 3 min easy", "Treadmill", "Full Body", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "90-95% max heart rate on work intervals", "Cycling Intervals"),
        ex("Rowing Intervals", 4, 1, 60, "500m hard pulls", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps", "Core"], "intermediate", "Drive with legs, pull with back", "Ski Erg Intervals"),
        ex("Assault Bike Sprint", 4, 1, 45, "30 seconds all-out", "Assault Bike", "Full Body", "Quadriceps", ["Hamstrings", "Shoulders"], "intermediate", "Max RPM, push and pull arms", "Stationary Bike Sprint"),
        ex("Stair Climber Intervals", 3, 1, 45, "2 minutes fast, 1 min easy", "Stair Climber", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Skip steps for higher intensity", "Step-up"),
        ex("Burpee", 3, 10, 30, "Full burpee with jump", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, max height jump", "Squat Thrust"),
        ex("Cool Down Jog", 1, 1, 0, "5 minutes easy", "Treadmill", "Full Body", "Calves", ["Hamstrings"], "beginner", "Gradually reduce pace", "Walking"),
    ])

def endurance_for_lifters():
    return wo("Endurance for Lifters", "conditioning", 30, [
        ex("Kettlebell Swing", 3, 15, 30, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap, float to chest height", "Dumbbell Swing"),
        ex("Dumbbell Thruster", 3, 10, 45, "Light-moderate", "Dumbbell", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Squat to press in one fluid motion", "Barbell Thruster"),
        ex("Rowing Machine", 1, 1, 0, "5 minutes moderate pace", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps"], "beginner", "Drive with legs, lean back, pull arms", "Jump Rope"),
        ex("Farmer's Walk", 3, 1, 60, "40-50 meters each set", "Dumbbell", "Full Body", "Forearms", ["Core", "Trapezius"], "intermediate", "Heavy weight, upright posture, quick steps", "Suitcase Carry"),
        ex("Sled Push", 3, 1, 60, "30 meters moderate load", "Sled", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Low handles, drive through legs", "Prowler Push"),
        ex("Jump Rope", 3, 1, 30, "1 minute sets", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Light bounce, wrist rotation", "Jumping Jacks"),
    ])

def calisthenics_advanced():
    return wo("Advanced Calisthenics", "strength", 50, [
        ex("Muscle-up Progression", 4, 3, 120, "Band-assisted or full", "Pull-up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps"], "advanced", "Explosive pull, transition, push above bar", "High Pull-up"),
        ex("Handstand Push-up", 4, 5, 90, "Wall-assisted or freestanding", "Wall", "Shoulders", "Deltoids", ["Triceps", "Core"], "advanced", "Head to floor, press to lockout", "Pike Push-up"),
        ex("Front Lever Progression", 3, 1, 90, "Tuck or straddle hold 10-15s", "Pull-up Bar", "Core", "Latissimus Dorsi", ["Rectus Abdominis"], "advanced", "Hollow body, depress scapula", "Dragon Flag"),
        ex("Planche Lean", 3, 1, 60, "Hold 10-20 seconds", "Parallettes", "Shoulders", "Anterior Deltoid", ["Core", "Chest"], "advanced", "Lean forward, feet off ground", "Planche Push-up"),
        ex("Pistol Squat", 3, 5, 60, "Each leg, full range", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Full depth, stand without assist", "Bulgarian Split Squat"),
        ex("L-Sit Hold", 3, 1, 45, "Hold 15-30 seconds", "Parallettes", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "advanced", "Legs straight, push shoulders down", "Tuck L-Sit"),
    ])

def calisthenics_weights_hybrid():
    return wo("Calisthenics + Weights Hybrid", "strength", 45, [
        ex("Weighted Pull-up", 4, 6, 90, "Add 10-25 lbs", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Full dead hang, chin over, controlled", "Lat Pulldown"),
        ex("Barbell Back Squat", 4, 8, 90, "70-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, brace core", "Goblet Squat"),
        ex("Ring Dip", 3, 8, 60, "Rings or parallettes", "Gymnastic Rings", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Full depth, turn rings out at top", "Parallel Bar Dip"),
        ex("Barbell Romanian Deadlift", 3, 10, 60, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, slight knee bend", "Single-Leg RDL"),
        ex("Handstand Hold", 3, 1, 60, "Wall-supported 30-45s", "Wall", "Shoulders", "Deltoids", ["Core", "Trapezius"], "intermediate", "Hollow body position, fingers spread", "Pike Hold"),
        ex("Dragon Flag Progression", 3, 5, 60, "Tucked or full", "Bench", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "advanced", "Lower slowly, keep body rigid", "Hanging Leg Raise"),
    ])

def calisthenics_movement_flow():
    return wo("Movement Flow", "flexibility", 35, [
        ex("Animal Walk Flow", 2, 1, 0, "3 minutes continuous", "Bodyweight", "Full Body", "Various", ["Various"], "intermediate", "Bear crawl, crab walk, ape walk, flow between", "Crawling"),
        ex("Squat to Stand", 2, 8, 0, "Flow movement", "Bodyweight", "Legs", "Hamstrings", ["Hip Flexors"], "beginner", "Deep squat, straighten legs, roll up", "Good Morning"),
        ex("Scorpion Reach", 2, 8, 0, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Hip Flexors", "Obliques"], "intermediate", "Prone, reach foot to opposite hand", "Spiderman Twist"),
        ex("Cartwheel Progression", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Shoulders", ["Core", "Obliques"], "intermediate", "Hands down, kick over, land standing", "Lateral Bear Crawl"),
        ex("Ground to Stand Flow", 2, 5, 0, "Various transitions", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Hip Flexors"], "intermediate", "Sit to stand without hands, flow", "Turkish Get-up"),
        ex("Deep Squat Hold", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Hips", "Hip Flexors", ["Adductors", "Calves"], "beginner", "Sit deep, elbows push knees out", "Goblet Squat Hold"),
    ])

def calisthenics_animal_flow():
    return wo("Animal Flow", "conditioning", 30, [
        ex("Beast Crawl", 3, 1, 30, "30 seconds forward and back", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "intermediate", "Knees hover 1 inch, opposite hand-foot", "Bear Crawl"),
        ex("Crab Reach", 3, 8, 30, "Alternating sides", "Bodyweight", "Full Body", "Glutes", ["Shoulders", "Core"], "intermediate", "Bridge up, reach opposite hand over", "Glute Bridge"),
        ex("Scorpion Reach", 3, 8, 30, "Alternating sides", "Bodyweight", "Back", "Thoracic Spine", ["Hip Flexors"], "intermediate", "Prone position, foot reaches to opposite side", "Prone Y Raise"),
        ex("Ape Reach", 3, 8, 30, "Deep squat lateral travel", "Bodyweight", "Legs", "Quadriceps", ["Adductors", "Core"], "intermediate", "Deep squat, travel side to side", "Lateral Lunge"),
        ex("Wave Unload", 3, 6, 30, "Full body wave motion", "Bodyweight", "Core", "Erector Spinae", ["Rectus Abdominis"], "intermediate", "Start low, wave up through spine", "Cat-Cow"),
        ex("Underswitch", 3, 8, 30, "Alternating sides", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hip Flexors"], "intermediate", "From beast, kick through to crab", "Turkish Get-up"),
    ])

# ──────────────────────────────────────────────
# PROGRAM DEFINITIONS
# ──────────────────────────────────────────────

all_programs = []

# ── Sleep & Recovery (9) ──

all_programs.append(("Recovery-Focused Training", "Sleep & Recovery Optimization", [4, 8], [3, 4], "High",
    "Training program focused on active recovery techniques including foam rolling, gentle movement, and recovery-optimized workouts",
    lambda w, t: [recovery_foam_rolling(), recovery_light_movement(), recovery_gentle_yoga()] if t <= 4
                else [recovery_foam_rolling(), recovery_light_movement(), recovery_gentle_yoga(), recovery_parasympathetic()],
    "flow"))

all_programs.append(("Deload Week Protocols", "Sleep & Recovery Optimization", [1, 2], [3, 4], "High",
    "Structured deload protocols to reduce training volume and intensity for optimal recovery and supercompensation",
    lambda w, t: [recovery_deload_strength(), recovery_light_movement(), recovery_foam_rolling()] if t <= 1
                else [recovery_deload_strength(), recovery_light_movement(), recovery_foam_rolling(), recovery_gentle_yoga()],
    "flow"))

all_programs.append(("Active Recovery Mastery", "Sleep & Recovery Optimization", [2, 4], [4, 5], "High",
    "Master active recovery techniques with daily gentle movement, mobility work, and recovery practices",
    lambda w, t: [recovery_light_movement(), recovery_foam_rolling(), recovery_gentle_yoga(), recovery_parasympathetic()]
                if t <= 2 else [recovery_light_movement(), recovery_foam_rolling(), recovery_gentle_yoga(), recovery_parasympathetic(), recovery_sleep_prep()],
    "flow"))

all_programs.append(("Overtraining Recovery", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Med",
    "Structured return from overtraining with progressive volume and intensity restoration",
    lambda w, t: [recovery_light_movement(), recovery_foam_rolling(), recovery_gentle_yoga()] if t <= 2
                else [recovery_light_movement(), recovery_foam_rolling(), recovery_gentle_yoga(), recovery_deload_strength()],
    "flow"))

all_programs.append(("HRV-Based Training", "Sleep & Recovery Optimization", [4, 8, 12], [4, 5], "Med",
    "Heart rate variability guided training with auto-regulated intensity based on recovery status",
    lambda w, t: [recovery_hrv_moderate(), recovery_light_movement(), recovery_foam_rolling(), recovery_hrv_moderate()]
                if t <= 4 else [recovery_hrv_moderate(), recovery_light_movement(), recovery_foam_rolling(), recovery_hrv_moderate(), recovery_gentle_yoga()],
    "flow"))

all_programs.append(("Sleep Debt Recovery", "Sleep & Recovery Optimization", [2, 4], [3, 4], "Med",
    "Gentle training program designed for periods of sleep deprivation with low-intensity recovery focus",
    lambda w, t: [recovery_light_movement(), recovery_gentle_yoga(), recovery_sleep_prep()] if t <= 2
                else [recovery_light_movement(), recovery_gentle_yoga(), recovery_sleep_prep(), recovery_parasympathetic()],
    "flow"))

all_programs.append(("Parasympathetic Training", "Sleep & Recovery Optimization", [2, 4, 8], [4, 5], "Med",
    "Activate the parasympathetic nervous system through breathing, gentle yoga, and calming movement patterns",
    lambda w, t: [recovery_parasympathetic(), recovery_gentle_yoga(), recovery_sleep_prep(), recovery_light_movement()]
                if t <= 4 else [recovery_parasympathetic(), recovery_gentle_yoga(), recovery_sleep_prep(), recovery_light_movement(), recovery_foam_rolling()],
    "flow"))

all_programs.append(("Weekend Warrior Recovery", "Sleep & Recovery Optimization", [2, 4], [3, 4], "Low",
    "Recovery program for people who train hard on weekends and need structured weekday recovery",
    lambda w, t: [recovery_weekend_warrior(), recovery_foam_rolling(), recovery_light_movement()] if t <= 2
                else [recovery_weekend_warrior(), recovery_foam_rolling(), recovery_light_movement(), recovery_gentle_yoga()],
    "flow"))

all_programs.append(("Night Owl to Early Bird", "Sleep & Recovery Optimization", [4, 8], [5, 6], "Low",
    "Gradually shift your circadian rhythm with timed movement, sleep hygiene practices, and morning activation",
    lambda w, t: [recovery_light_movement(), recovery_hrv_moderate(), recovery_foam_rolling(), recovery_gentle_yoga(), recovery_sleep_prep()]
                if t <= 4 else [recovery_light_movement(), recovery_hrv_moderate(), recovery_foam_rolling(), recovery_gentle_yoga(), recovery_sleep_prep(), recovery_parasympathetic()],
    "flow"))

# ── Menstrual Cycle (8) ──

all_programs.append(("Follicular Phase Training", "Menstrual Cycle Synced", [2, 4], [4, 5], "High",
    "High-intensity training optimized for the follicular phase when estrogen is rising and energy is high",
    lambda w, t: [menstrual_follicular_strength(), menstrual_follicular_hiit(), menstrual_follicular_strength(), menstrual_follicular_hiit()]
                if t <= 2 else [menstrual_follicular_strength(), menstrual_follicular_hiit(), menstrual_follicular_strength(), menstrual_follicular_hiit(), menstrual_cycle_synced_cardio()],
    "flow"))

all_programs.append(("Ovulation Power Window", "Menstrual Cycle Synced", [1, 2], [5, 6], "High",
    "Peak performance training during ovulation when strength and power are at their highest",
    lambda w, t: [menstrual_ovulation_power(), menstrual_follicular_hiit(), menstrual_ovulation_power(), menstrual_follicular_strength(), menstrual_follicular_hiit()]
                if t <= 1 else [menstrual_ovulation_power(), menstrual_follicular_hiit(), menstrual_ovulation_power(), menstrual_follicular_strength(), menstrual_follicular_hiit(), menstrual_cycle_synced_cardio()],
    "flow"))

all_programs.append(("Luteal Phase Adaptation", "Menstrual Cycle Synced", [2, 4], [3, 4], "High",
    "Moderate intensity training adapted for the luteal phase with focus on steady-state work and recovery",
    lambda w, t: [menstrual_luteal_moderate(), menstrual_cycle_synced_cardio(), menstrual_luteal_moderate()]
                if t <= 2 else [menstrual_luteal_moderate(), menstrual_cycle_synced_cardio(), menstrual_luteal_moderate(), recovery_gentle_yoga()],
    "flow"))

all_programs.append(("Menstrual Phase Recovery", "Menstrual Cycle Synced", [1, 2], [3, 4], "High",
    "Gentle recovery-focused training during menstruation with restorative yoga and light movement",
    lambda w, t: [menstrual_phase_gentle(), recovery_gentle_yoga(), menstrual_phase_gentle()]
                if t <= 1 else [menstrual_phase_gentle(), recovery_gentle_yoga(), menstrual_phase_gentle(), recovery_light_movement()],
    "flow"))

all_programs.append(("Heavy Period Adaptation", "Menstrual Cycle Synced", [1, 2, 4], [2, 3], "Med",
    "Very gentle exercise for heavy periods focusing on comfort, circulation, and pain relief",
    lambda w, t: [menstrual_heavy_gentle(), menstrual_phase_gentle()]
                if t <= 1 else [menstrual_heavy_gentle(), menstrual_phase_gentle(), recovery_light_movement()],
    "flow"))

all_programs.append(("Full Cycle Synced", "Menstrual Cycle Synced", [4, 8, 12], [4, 5], "High",
    "Complete menstrual cycle synced program covering all four phases with appropriate intensity adjustments",
    lambda w, t: [menstrual_follicular_strength(), menstrual_follicular_hiit(), menstrual_luteal_moderate(), menstrual_phase_gentle()]
                if t <= 4 else [menstrual_follicular_strength(), menstrual_follicular_hiit(), menstrual_luteal_moderate(), menstrual_phase_gentle(), menstrual_cycle_synced_cardio()],
    "flow"))

all_programs.append(("Cycle-Synced Strength", "Menstrual Cycle Synced", [4, 8, 12], [3, 4], "Med",
    "Strength training periodized to the menstrual cycle with intensity varying by phase",
    lambda w, t: [menstrual_follicular_strength(), menstrual_ovulation_power(), menstrual_luteal_moderate()]
                if t <= 4 else [menstrual_follicular_strength(), menstrual_ovulation_power(), menstrual_luteal_moderate(), menstrual_phase_gentle()],
    "flow"))

all_programs.append(("Cycle-Synced Cardio", "Menstrual Cycle Synced", [4, 8], [4, 5], "Med",
    "Cardio training adapted to menstrual cycle phases from high-intensity in follicular to gentle in menstrual",
    lambda w, t: [menstrual_follicular_hiit(), menstrual_cycle_synced_cardio(), menstrual_luteal_moderate(), menstrual_phase_gentle()]
                if t <= 4 else [menstrual_follicular_hiit(), menstrual_cycle_synced_cardio(), menstrual_luteal_moderate(), menstrual_phase_gentle(), recovery_light_movement()],
    "flow"))

# ── Swimming & Aquatic (7) ──

all_programs.append(("Water Aerobics", "Swimming & Aquatic", [4, 8], [3, 4], "High",
    "Pool-based aerobic exercise using water resistance for a low-impact full body workout",
    lambda w, t: [swim_water_aerobics(), swim_aqua_jogging(), swim_water_aerobics()]
                if t <= 4 else [swim_water_aerobics(), swim_aqua_jogging(), swim_water_aerobics(), swim_pool_recovery()],
    "sport_specific"))

all_programs.append(("Aqua Jogging", "Swimming & Aquatic", [4, 8], [3, 4], "High",
    "Deep water jogging program for cardiovascular fitness with zero impact on joints",
    lambda w, t: [swim_aqua_jogging(), swim_water_aerobics(), swim_aqua_jogging()]
                if t <= 4 else [swim_aqua_jogging(), swim_water_aerobics(), swim_aqua_jogging(), swim_pool_recovery()],
    "sport_specific"))

all_programs.append(("Swim for Triathlon", "Swimming & Aquatic", [8, 12], [4, 5], "High",
    "Triathlon swim training focusing on freestyle technique, endurance, and open water preparation",
    lambda w, t: [swim_triathlon(), swim_technique(), swim_triathlon(), swim_aquatic_hiit()]
                if t <= 8 else [swim_triathlon(), swim_technique(), swim_triathlon(), swim_aquatic_hiit(), swim_pool_recovery()],
    "sport_specific"))

all_programs.append(("Pool Recovery", "Swimming & Aquatic", [2, 4], [2, 3], "Med",
    "Gentle pool-based recovery sessions using water buoyancy for active recovery and joint relief",
    lambda w, t: [swim_pool_recovery(), swim_arthritis_pool()]
                if t <= 2 else [swim_pool_recovery(), swim_arthritis_pool(), swim_pool_recovery()],
    "sport_specific"))

all_programs.append(("Aquatic HIIT", "Swimming & Aquatic", [2, 4, 8], [3], "Med",
    "High-intensity interval training in the pool combining sprints, water exercises, and resistance work",
    lambda w, t: [swim_aquatic_hiit(), swim_water_aerobics(), swim_aquatic_hiit()],
    "sport_specific"))

all_programs.append(("Swim Technique", "Swimming & Aquatic", [4, 8], [3, 4], "Med",
    "Improve swimming technique through drills, form work, and stroke correction",
    lambda w, t: [swim_technique(), swim_triathlon(), swim_technique()]
                if t <= 4 else [swim_technique(), swim_triathlon(), swim_technique(), swim_pool_recovery()],
    "sport_specific"))

all_programs.append(("Arthritis Pool Exercise", "Swimming & Aquatic", [4, 8, 12], [3, 4], "Med",
    "Gentle pool exercise program designed for arthritis sufferers using water buoyancy for joint protection",
    lambda w, t: [swim_arthritis_pool(), swim_pool_recovery(), swim_arthritis_pool()]
                if t <= 4 else [swim_arthritis_pool(), swim_pool_recovery(), swim_arthritis_pool(), swim_water_aerobics()],
    "sport_specific"))

# ── Climbing & Vertical (8) ──

all_programs.append(("Rock Climbing Prep", "Climbing & Vertical", [4, 8, 12], [3, 4], "High",
    "Comprehensive preparation for rock climbing with grip strength, pulling power, and mobility",
    lambda w, t: [climb_prep_strength(), climb_core(), climb_prep_strength()]
                if t <= 4 else [climb_prep_strength(), climb_core(), climb_prep_strength(), climb_antagonist()],
    "sport_specific"))

all_programs.append(("Bouldering Strength", "Climbing & Vertical", [4, 8], [3, 4], "High",
    "Build bouldering-specific strength with power moves, lock-offs, and campus board training",
    lambda w, t: [climb_bouldering(), climb_finger_strength(), climb_bouldering()]
                if t <= 4 else [climb_bouldering(), climb_finger_strength(), climb_bouldering(), climb_antagonist()],
    "sport_specific"))

all_programs.append(("Climber's Finger Strength", "Climbing & Vertical", [4, 8, 12], [3, 4], "High",
    "Progressive finger and grip strength training for climbers using hangboard and supplementary exercises",
    lambda w, t: [climb_finger_strength(), climb_antagonist(), climb_finger_strength()]
                if t <= 4 else [climb_finger_strength(), climb_antagonist(), climb_finger_strength(), climb_core()],
    "sport_specific"))

all_programs.append(("Climbing Antagonist Training", "Climbing & Vertical", [4, 8], [2, 3], "Med",
    "Push and antagonist exercises to balance the pulling-dominant demands of climbing",
    lambda w, t: [climb_antagonist(), climb_core()]
                if t <= 4 else [climb_antagonist(), climb_core(), climb_antagonist()],
    "sport_specific"))

all_programs.append(("Wall Climbing Endurance", "Climbing & Vertical", [4, 8], [3, 4], "Med",
    "Build climbing endurance through ARC training, traverses, and sustained wall time",
    lambda w, t: [climb_wall_endurance(), climb_core(), climb_wall_endurance()]
                if t <= 4 else [climb_wall_endurance(), climb_core(), climb_wall_endurance(), climb_antagonist()],
    "sport_specific"))

all_programs.append(("Climbing Core Training", "Climbing & Vertical", [4, 8], [3, 4], "Med",
    "Core-focused training for climbing with hanging exercises, levers, and rotational stability",
    lambda w, t: [climb_core(), climb_prep_strength(), climb_core()]
                if t <= 4 else [climb_core(), climb_prep_strength(), climb_core(), climb_antagonist()],
    "sport_specific"))

all_programs.append(("Stair Climbing Fitness", "Climbing & Vertical", [4, 8, 12], [3, 4], "Med",
    "Build cardiovascular fitness and leg strength through stair climbing intervals and drills",
    lambda w, t: [climb_stair(), climb_core(), climb_stair()]
                if t <= 4 else [climb_stair(), climb_core(), climb_stair(), climb_antagonist()],
    "sport_specific"))

all_programs.append(("Rope Climbing Prep", "Climbing & Vertical", [4, 8], [2, 3], "Low",
    "Prepare for rope climbing with pulling strength, grip endurance, and foot lock technique",
    lambda w, t: [climb_rope_prep(), climb_core()]
                if t <= 4 else [climb_rope_prep(), climb_core(), climb_antagonist()],
    "sport_specific"))

# ── Misc (3) ──

all_programs.append(("HIV/AIDS Fitness", "Medical Condition Specific", [4, 8, 12], [3, 4], "Med",
    "Safe immune-supportive exercise program for people living with HIV/AIDS focusing on strength preservation and cardiovascular health",
    lambda w, t: [medical_hiv_session(), recovery_light_movement(), medical_hiv_session()]
                if t <= 4 else [medical_hiv_session(), recovery_light_movement(), medical_hiv_session(), recovery_gentle_yoga()],
    "full_body"))

all_programs.append(("Deceleration Training", "Plyometrics & Explosiveness", [4, 8], [2, 3], "Med",
    "Landing and braking mechanics training to prevent ACL injuries and improve change of direction",
    lambda w, t: [plyometric_deceleration(), recovery_foam_rolling()]
                if t <= 4 else [plyometric_deceleration(), recovery_foam_rolling(), plyometric_deceleration()],
    "sport_specific"))

all_programs.append(("LAN Party Recovery", "Gamer & Esports Fitness", [1], [1], "Low",
    "Quick recovery session after extended gaming sessions to relieve stiffness and restore circulation",
    lambda w, t: [gamer_lan_recovery()],
    "single_session"))

# ── Also add if missing (6) ──

all_programs.append(("VO2 Max Builder", "Endurance", [4, 8, 12], [4, 5], "High",
    "Progressive VO2 max training using intervals to push aerobic capacity to new levels",
    lambda w, t: [endurance_vo2max(), recovery_light_movement(), endurance_vo2max(), endurance_for_lifters()]
                if t <= 4 else [endurance_vo2max(), recovery_light_movement(), endurance_vo2max(), endurance_for_lifters(), recovery_foam_rolling()],
    "full_body"))

all_programs.append(("Endurance for Lifters", "Endurance", [2, 4, 8], [2, 3], "Med",
    "Cardiovascular conditioning designed for strength athletes without compromising muscle mass",
    lambda w, t: [endurance_for_lifters(), recovery_foam_rolling()]
                if t <= 2 else [endurance_for_lifters(), recovery_foam_rolling(), endurance_for_lifters()],
    "full_body"))

all_programs.append(("Advanced Calisthenics", "Calisthenics", [8, 12, 16], [5, 6], "High",
    "Advanced bodyweight skills including muscle-ups, handstand push-ups, front levers, and planches",
    lambda w, t: [calisthenics_advanced(), climb_core(), calisthenics_advanced(), calisthenics_movement_flow(), calisthenics_advanced()]
                if t <= 8 else [calisthenics_advanced(), climb_core(), calisthenics_advanced(), calisthenics_movement_flow(), calisthenics_advanced(), recovery_foam_rolling()],
    "full_body"))

all_programs.append(("Calisthenics + Weights Hybrid", "Calisthenics", [4, 8, 12], [4, 5], "High",
    "Combine bodyweight skills with barbell and dumbbell training for maximum strength and control",
    lambda w, t: [calisthenics_weights_hybrid(), calisthenics_advanced(), calisthenics_weights_hybrid(), calisthenics_movement_flow()]
                if t <= 4 else [calisthenics_weights_hybrid(), calisthenics_advanced(), calisthenics_weights_hybrid(), calisthenics_movement_flow(), recovery_foam_rolling()],
    "full_body"))

all_programs.append(("Movement Flow", "Calisthenics", [2, 4, 8], [4, 5], "Med",
    "Fluid movement practice combining animal movements, ground transitions, and dynamic flexibility",
    lambda w, t: [calisthenics_movement_flow(), calisthenics_animal_flow(), calisthenics_movement_flow(), calisthenics_animal_flow()]
                if t <= 2 else [calisthenics_movement_flow(), calisthenics_animal_flow(), calisthenics_movement_flow(), calisthenics_animal_flow(), recovery_light_movement()],
    "flow"))

all_programs.append(("Animal Flow", "Calisthenics", [2, 4, 8], [4, 5], "Med",
    "Quadrupedal and ground-based movement practice for mobility, coordination, and body control",
    lambda w, t: [calisthenics_animal_flow(), calisthenics_movement_flow(), calisthenics_animal_flow(), calisthenics_movement_flow()]
                if t <= 2 else [calisthenics_animal_flow(), calisthenics_movement_flow(), calisthenics_animal_flow(), calisthenics_movement_flow(), recovery_light_movement()],
    "flow"))

# ──────────────────────────────────────────────
# GENERATE ALL PROGRAMS
# ──────────────────────────────────────────────

total = len(all_programs)
inserted = 0
skipped = 0
failed = 0

for idx, entry in enumerate(all_programs, 1):
    prog_name, cat, durs, sessions_list, pri, desc, workout_fn, split = entry
    print(f"[{idx}/{total}] Processing: {prog_name}...")

    if helper.check_program_exists(prog_name):
        print(f"  SKIP: {prog_name} already exists")
        skipped += 1
        continue

    # Map category to DB value
    from program_sql_helper import CATEGORY_MAP
    db_cat = CATEGORY_MAP.get(cat, cat)

    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33:
                focus = f"Week {w} - Foundation"
            elif p <= 0.66:
                focus = f"Week {w} - Build"
            else:
                focus = f"Week {w} - Peak"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks

    mn = helper.get_next_migration_num()
    success = helper.insert_full_program(
        prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn, write_sql=False
    )
    if success:
        inserted += 1
        print(f"  DONE: {prog_name}")
    else:
        failed += 1
        print(f"  FAILED: {prog_name}")

helper.close()
print(f"\n=== BATCH COMPLETE ===")
print(f"Total: {total} | Inserted: {inserted} | Skipped: {skipped} | Failed: {failed}")
