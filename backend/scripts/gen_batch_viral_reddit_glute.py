#!/usr/bin/env python3
"""Generate programs for Categories 53-60: Viral TikTok, Nervous System, Weighted Accessories,
YouTube Home, Influencer, Life Events, Reddit-Famous, Glute & Booty."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

def ex(name, sets, reps, rest, weight, equip, body, muscle, secondary, diff, cue, sub):
    return {"name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": weight, "equipment": equip, "body_part": body,
            "primary_muscle": muscle, "secondary_muscles": secondary,
            "difficulty": diff, "form_cue": cue, "substitution": sub}

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# ========================================================================
# CAT 53 - VIRAL TIKTOK PROGRAMS (18)
# ========================================================================

def treadmill_12_3_30():
    return wo("12-3-30 Treadmill Walk", "cardio", 35, [
        ex("Incline Treadmill Walk", 1, 30, 0, "12% incline, 3.0 mph, 30 min", "Treadmill", "Legs", "Glutes", ["Hamstrings", "Calves", "Quadriceps"], "beginner", "Stand upright, no holding rails, engage core", "Stairmaster 30 min"),
        ex("Walking Lunge Cooldown", 2, 10, 0, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step forward, knee to 90 degrees", "Stationary Lunge"),
        ex("Standing Calf Raise", 2, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range, pause at top", "Seated Calf Raise"),
    ])

def seventy_five_hard_modified():
    return wo("75 Hard Modified Session", "conditioning", 45, [
        ex("Outdoor Walk or Jog", 1, 1, 0, "20 min at moderate pace", "Bodyweight", "Full Body", "Quadriceps", ["Glutes", "Calves", "Core"], "beginner", "Maintain conversational pace", "Indoor Treadmill Walk"),
        ex("Bodyweight Squat", 3, 15, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Chest up, knees track toes", "Wall Sit"),
        ex("Push-Up", 3, 10, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full range of motion, elbows 45 degrees", "Knee Push-Up"),
        ex("Plank Hold", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line head to heels", "Forearm Plank"),
        ex("Jumping Jacks", 3, 20, 30, "Bodyweight", "Bodyweight", "Full Body", "Deltoids", ["Calves", "Core"], "beginner", "Land softly, full arm extension", "Step Jacks"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze at top, controlled lower", "Single-Leg Glute Bridge"),
    ])

def wall_pilates_viral():
    return wo("Wall Pilates", "pilates", 30, [
        ex("Wall Sit", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Back flat against wall, thighs parallel", "Shallow Wall Sit"),
        ex("Wall Push-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Hands shoulder width on wall, full range", "Incline Push-Up"),
        ex("Wall Leg Raise", 3, 10, 30, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Back against wall, lift leg to 90 degrees", "Standing Knee Raise"),
        ex("Wall Glute Kickback", 3, 12, 30, "Each leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Face wall, kick back with control", "Standing Glute Squeeze"),
        ex("Wall Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Hands on wall at angle, straight body", "Forearm Wall Plank"),
        ex("Wall Calf Raise", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Hands on wall for balance, full ROM", "Standing Calf Raise"),
    ])

def cozy_cardio():
    return wo("Cozy Cardio", "cardio", 30, [
        ex("Slow Walking Pad Walk", 1, 1, 0, "2.0-2.5 mph, 15 min", "Treadmill", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Comfortable pace, enjoy music or show", "Outdoor Gentle Walk"),
        ex("Gentle Arm Circles", 2, 15, 0, "Small to large circles", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Relaxed shoulders, smooth circles", "Shoulder Rolls"),
        ex("Side Step Touch", 2, 1, 0, "2 min each set", "Bodyweight", "Legs", "Hip Abductors", ["Glutes", "Calves"], "beginner", "Step side to side, gentle rhythm", "Marching in Place"),
        ex("Standing Knee Raise", 2, 10, 0, "Alternating", "Bodyweight", "Core", "Hip Flexors", ["Rectus Abdominis"], "beginner", "Gentle lift, no rushing", "Seated Knee Raise"),
        ex("Gentle Torso Twist", 2, 10, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Erector Spinae"], "beginner", "Relaxed arms swing with twist", "Seated Twist"),
    ])

def hot_girl_walk():
    return wo("Hot Girl Walk", "cardio", 45, [
        ex("Brisk Outdoor Walk", 1, 1, 0, "3.5-4.0 mph, 30-40 min, focus on gratitude goals and confidence", "Bodyweight", "Full Body", "Quadriceps", ["Glutes", "Calves", "Hamstrings"], "beginner", "Tall posture, pump arms, engage core", "Treadmill Brisk Walk"),
        ex("Walking Lunge", 2, 10, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, knee tracks toe", "Reverse Lunge"),
        ex("Calf Raise Walk", 2, 15, 0, "On toes for 15 steps", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Stay on toes, short steps", "Standing Calf Raise"),
    ])

def lazy_girl_workout():
    return wo("Lazy Girl Workout", "strength", 20, [
        ex("Lying Leg Raise", 3, 10, 30, "On bed or floor", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Slow lower, press lower back down", "Bent-Knee Leg Raise"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze at top 2 seconds", "Single-Leg Glute Bridge"),
        ex("Dead Bug", 3, 10, 30, "Alternating sides", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Lower back stays flat on floor", "Bird Dog"),
        ex("Clamshell", 3, 15, 30, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Keep feet together, open knees", "Side-Lying Leg Lift"),
        ex("Wall Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full range against wall", "Incline Push-Up"),
    ])

def that_girl_routine():
    return wo("That Girl Morning Routine", "conditioning", 35, [
        ex("Morning Stretch Flow", 1, 1, 0, "5 min gentle full body stretch", "Bodyweight", "Full Body", "Hamstrings", ["Quadriceps", "Shoulders", "Back"], "beginner", "Breathe deeply, hold each 20 seconds", "Cat-Cow"),
        ex("Bodyweight Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Chest up, full depth", "Wall Sit"),
        ex("Mountain Climber", 3, 20, 30, "Alternating", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Hips level, drive knees to chest", "Plank Knee Tuck"),
        ex("Reverse Lunge", 3, 10, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, both knees 90 degrees", "Stationary Lunge"),
        ex("Push-Up", 3, 8, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Elbows 45 degrees, full range", "Knee Push-Up"),
        ex("Bicycle Crunch", 3, 15, 30, "Alternating", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Opposite elbow to knee, slow tempo", "Dead Bug"),
    ])

def chloe_ting_style():
    return wo("HIIT Abs & Full Body", "hiit", 30, [
        ex("Jumping Jack", 3, 20, 15, "Bodyweight", "Bodyweight", "Full Body", "Deltoids", ["Calves", "Core"], "beginner", "Land softly, full range", "Step Jack"),
        ex("Bicycle Crunch", 3, 20, 15, "Alternating", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Touch elbow to opposite knee", "Dead Bug"),
        ex("Squat Jump", 3, 12, 20, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Soft landing, full squat depth", "Bodyweight Squat"),
        ex("Plank to Shoulder Tap", 3, 10, 15, "Alternating", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Minimize hip rotation", "Plank Hold"),
        ex("Burpee", 3, 8, 20, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Chest to floor, explosive jump", "Squat Thrust"),
        ex("Leg Raise", 3, 15, 15, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Lower slowly, don't arch back", "Bent-Knee Leg Raise"),
        ex("High Knees", 3, 20, 15, "Bodyweight", "Bodyweight", "Full Body", "Hip Flexors", ["Quadriceps", "Calves", "Core"], "beginner", "Drive knees high, pump arms", "Marching in Place"),
    ])

def pamela_reif_style():
    return wo("No Talking Full Body HIIT", "hiit", 25, [
        ex("Squat Pulse", 3, 15, 10, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stay low, small pulses at bottom", "Wall Sit"),
        ex("Push-Up", 3, 10, 10, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Full range, controlled tempo", "Knee Push-Up"),
        ex("Curtsy Lunge", 3, 12, 10, "Each side", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hip Adductors"], "beginner", "Cross behind, knee to 90", "Reverse Lunge"),
        ex("Plank Up-Down", 3, 8, 10, "Alternating lead arm", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Minimize rocking, steady hips", "Plank Hold"),
        ex("Sumo Squat", 3, 15, 10, "Bodyweight", "Bodyweight", "Legs", "Hip Adductors", ["Glutes", "Quadriceps"], "beginner", "Wide stance, toes out, chest up", "Goblet Squat"),
        ex("Crunch", 3, 20, 10, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Shoulder blades off floor, exhale up", "Dead Bug"),
    ])

def blogilates_inspired():
    return wo("Pop Pilates Sculpt", "pilates", 30, [
        ex("The Hundred", 1, 100, 0, "100 arm pumps, legs at 45", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "intermediate", "5 pumps inhale, 5 pumps exhale", "Modified Hundred"),
        ex("Single Leg Stretch", 3, 12, 0, "Alternating", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "beginner", "One knee in, other extends, switch", "Bent-Knee Version"),
        ex("Pilates Side-Lying Leg Lift", 3, 15, 0, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors", "Obliques"], "beginner", "Stack hips, lift with control", "Clamshell"),
        ex("Pilates Swimming", 3, 20, 20, "Flutter arms and legs", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "intermediate", "Prone, alternate flutter, breathe", "Superman Hold"),
        ex("Pilates Teaser", 3, 8, 20, "Full V-up position", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Roll up to V, balance on sit bones", "Half Roll Up"),
        ex("Inner Thigh Lift", 3, 15, 0, "Each side", "Bodyweight", "Legs", "Hip Adductors", ["Core"], "beginner", "Bottom leg lifts, top leg in front", "Sumo Squat Pulse"),
    ])

def daisy_keech_ab():
    return wo("10-Min Ab Shred", "strength", 15, [
        ex("Bicycle Crunch", 3, 20, 10, "Alternating", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Slow, controlled, elbow to knee", "Dead Bug"),
        ex("Reverse Crunch", 3, 15, 10, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Lift hips off floor, curl pelvis", "Knee Tuck"),
        ex("Scissor Kick", 3, 20, 10, "Alternating", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Lower back pressed to floor", "Flutter Kick"),
        ex("Toe Touch Crunch", 3, 15, 10, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Legs vertical, reach for toes", "Standard Crunch"),
        ex("Plank Hold", 3, 1, 15, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Squeeze everything, straight line", "Forearm Plank"),
    ])

def sami_clarke_booty():
    return wo("Sculpted Booty Burn", "strength", 35, [
        ex("Sumo Squat", 3, 15, 45, "Light to moderate dumbbell", "Dumbbell", "Legs", "Glutes", ["Hip Adductors", "Quadriceps"], "beginner", "Wide stance, toes out, squeeze glutes", "Bodyweight Sumo Squat"),
        ex("Hip Thrust", 4, 12, 60, "Moderate to heavy barbell or dumbbell", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Drive through heels, full hip extension", "Glute Bridge"),
        ex("Romanian Deadlift", 3, 12, 60, "Moderate dumbbells", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips, soft knees, flat back", "Single-Leg RDL"),
        ex("Cable Kickback", 3, 12, 30, "Each leg, light to moderate", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top, controlled return", "Donkey Kick"),
        ex("Curtsy Lunge", 3, 10, 30, "Each leg, dumbbells", "Dumbbell", "Legs", "Glutes", ["Quadriceps", "Hip Adductors"], "intermediate", "Cross behind, keep torso upright", "Reverse Lunge"),
        ex("Fire Hydrant", 3, 15, 30, "Each side, bodyweight", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lift knee to side, hip height", "Banded Fire Hydrant"),
    ])

def madfit_quick_hiit():
    return wo("Quick No-Equipment HIIT", "hiit", 20, [
        ex("High Knees", 3, 20, 15, "Bodyweight", "Bodyweight", "Full Body", "Hip Flexors", ["Quadriceps", "Calves"], "beginner", "Drive knees up fast, pump arms", "Marching in Place"),
        ex("Squat Jump", 3, 10, 15, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explosive jump, soft land", "Bodyweight Squat"),
        ex("Plank Shoulder Tap", 3, 12, 15, "Alternating", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Minimize hip sway", "Plank Hold"),
        ex("Reverse Lunge to Knee Drive", 3, 8, 15, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Lunge back then drive knee up", "Reverse Lunge"),
        ex("Burpee", 3, 8, 20, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest down, explosive up", "Squat Thrust"),
    ])

def caroline_girvan_epic():
    return wo("Epic Full Body Dumbbell", "strength", 50, [
        ex("Goblet Squat", 4, 10, 60, "Heavy dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Elbows between knees, full depth", "Bodyweight Squat"),
        ex("Dumbbell Romanian Deadlift", 4, 10, 60, "Heavy dumbbells", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips, dumbbells close to legs", "Single-Leg RDL"),
        ex("Dumbbell Bench Press", 4, 10, 60, "Moderate to heavy", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full ROM, squeeze at top", "Push-Up"),
        ex("Bent Over Dumbbell Row", 4, 10, 60, "Moderate to heavy", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, squeeze back", "Inverted Row"),
        ex("Dumbbell Shoulder Press", 3, 10, 60, "Moderate", "Dumbbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Press overhead, full lockout", "Pike Push-Up"),
        ex("Dumbbell Lunges", 3, 10, 45, "Each leg, moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Bodyweight Lunge"),
        ex("Renegade Row", 3, 8, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, pull to hip, no rotation", "Single-Arm Row"),
    ])

def sydney_cummings_full():
    return wo("Full Body Strength & Cardio", "conditioning", 45, [
        ex("Dumbbell Squat to Press", 3, 12, 45, "Moderate dumbbells", "Dumbbell", "Full Body", "Quadriceps", ["Deltoids", "Glutes", "Core"], "intermediate", "Squat deep, press at top", "Bodyweight Squat + Overhead Reach"),
        ex("Alternating Dumbbell Lunge", 3, 10, 45, "Each leg", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Alternate forward lunges with dumbbells", "Bodyweight Lunge"),
        ex("Dumbbell Chest Press", 3, 12, 45, "Moderate", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Squeeze at top, slow lower", "Push-Up"),
        ex("Dumbbell Bent Over Row", 3, 12, 45, "Moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Flat back, pull to navel", "Inverted Row"),
        ex("Dumbbell Deadlift", 3, 12, 45, "Moderate to heavy", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hip hinge, flat back", "Bodyweight Good Morning"),
        ex("Plank to Row", 3, 8, 30, "Each arm", "Dumbbell", "Core", "Rectus Abdominis", ["Latissimus Dorsi", "Obliques"], "intermediate", "Stable plank, row to hip", "Plank Hold"),
    ])

def jeff_nippard_science():
    return wo("Science-Based Full Body", "strength", 60, [
        ex("Barbell Back Squat", 4, 8, 120, "75-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Break at hips and knees, below parallel", "Leg Press"),
        ex("Barbell Bench Press", 4, 8, 120, "75-80% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, arch, touch chest", "Dumbbell Bench Press"),
        ex("Barbell Row", 4, 8, 90, "70-75% 1RM", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate", "45-degree torso, pull to navel", "Cable Row"),
        ex("Overhead Press", 3, 8, 90, "70% 1RM", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, no leg drive", "Dumbbell Shoulder Press"),
        ex("Romanian Deadlift", 3, 10, 90, "65-70% DL 1RM", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hip hinge, bar close to body", "Dumbbell RDL"),
        ex("Lateral Raise", 3, 15, 45, "Light dumbbells, controlled", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Supraspinatus"], "beginner", "Slight elbow bend, raise to shoulder height", "Cable Lateral Raise"),
        ex("Face Pull", 3, 15, 45, "Light cable, rope attachment", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids", "External Rotators"], "beginner", "Pull to face, externally rotate at top", "Band Pull-Apart"),
    ])

def athlean_x_style():
    return wo("Athlean-X Science Push", "strength", 55, [
        ex("Barbell Bench Press", 4, 8, 120, "Progressive overload, track weight", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, controlled eccentric", "Dumbbell Bench Press"),
        ex("Incline Dumbbell Press", 3, 10, 90, "Moderate to heavy", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps", "Anterior Deltoid"], "intermediate", "30-degree bench, full stretch at bottom", "Incline Push-Up"),
        ex("Dumbbell Lateral Raise", 3, 12, 45, "Light, strict form", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Supraspinatus"], "beginner", "Lead with pinkies, no momentum", "Cable Lateral Raise"),
        ex("Overhead Tricep Extension", 3, 12, 45, "Moderate dumbbell", "Dumbbell", "Arms", "Triceps", ["Anconeus"], "intermediate", "Full stretch behind head, lock out", "Skull Crusher"),
        ex("Cable Fly", 3, 12, 45, "Moderate, constant tension", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "Slight elbow bend, squeeze at center", "Dumbbell Fly"),
        ex("Face Pull", 3, 15, 45, "Light, external rotation at top", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids", "External Rotators"], "beginner", "High pull, rotate thumbs back", "Band Pull-Apart"),
    ])

def bret_contreras_glute():
    return wo("Glute Lab Session", "strength", 50, [
        ex("Barbell Hip Thrust", 4, 10, 90, "Heavy, progressive overload", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Bench at mid-back, drive through heels, full extension", "Glute Bridge"),
        ex("Barbell Back Squat", 4, 8, 120, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Below parallel, push knees out", "Goblet Squat"),
        ex("Romanian Deadlift", 3, 10, 90, "Moderate barbell", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hip hinge, feel hamstring stretch", "Dumbbell RDL"),
        ex("Cable Pull-Through", 3, 12, 60, "Moderate cable", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hip hinge, squeeze glutes at top", "Kettlebell Swing"),
        ex("Banded Lateral Walk", 3, 15, 30, "Each direction", "Resistance Band", "Hips", "Gluteus Medius", ["Gluteus Minimus", "Hip Abductors"], "beginner", "Stay low, tension on band", "Side-Lying Leg Lift"),
        ex("Frog Pump", 3, 20, 30, "Bodyweight or light plate", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hip Adductors"], "beginner", "Soles together, knees out, squeeze glutes", "Glute Bridge"),
    ])

# Cat 53 programs list
cat53_programs = [
    ("12-3-30 Treadmill", "Viral TikTok Programs", [2, 4, 8], [3, 4, 5], "The viral 12-3-30 treadmill workout: 12% incline, 3.0 mph, 30 minutes for fat burning and glute sculpting", "High",
     lambda w, t: [treadmill_12_3_30(), treadmill_12_3_30(), treadmill_12_3_30()]),
    ("75 Hard Modified", "Viral TikTok Programs", [4, 8, 12], [5, 6, 7], "Modified version of the viral 75 Hard challenge with two daily workouts and habit building", "High",
     lambda w, t: [seventy_five_hard_modified(), seventy_five_hard_modified(), seventy_five_hard_modified()]),
    ("Wall Pilates Viral", "Viral TikTok Programs", [2, 4, 8], [3, 4, 5], "The TikTok-viral wall pilates workout using just a wall for full body toning", "High",
     lambda w, t: [wall_pilates_viral(), wall_pilates_viral(), wall_pilates_viral()]),
    ("Cozy Cardio", "Viral TikTok Programs", [2, 4, 8], [3, 4, 5], "Low-intensity cozy cardio with walking pad and gentle movement - the anti-hustle workout trend", "High",
     lambda w, t: [cozy_cardio(), cozy_cardio(), cozy_cardio()]),
    ("Hot Girl Walk", "Viral TikTok Programs", [2, 4, 8], [3, 4, 5], "The viral Hot Girl Walk: 4 miles outdoors while manifesting goals and building confidence", "High",
     lambda w, t: [hot_girl_walk(), hot_girl_walk(), hot_girl_walk()]),
    ("Lazy Girl Workout", "Viral TikTok Programs", [2, 4, 8], [3, 4], "Minimal effort maximum results workout from bed or floor - the viral lazy girl trend", "High",
     lambda w, t: [lazy_girl_workout(), lazy_girl_workout(), lazy_girl_workout()]),
    ("That Girl Routine", "Viral TikTok Programs", [2, 4, 8], [4, 5, 6], "The That Girl morning routine workout combining fitness, mindfulness, and aesthetic wellness", "High",
     lambda w, t: [that_girl_routine(), that_girl_routine(), that_girl_routine()]),
    ("Chloe Ting Style", "Viral TikTok Programs", [2, 4, 8], [4, 5, 6], "High-intensity abs and full body HIIT inspired by viral YouTube fitness challenges", "High",
     lambda w, t: [chloe_ting_style(), chloe_ting_style(), chloe_ting_style()]),
    ("Pamela Reif Style", "Viral TikTok Programs", [2, 4, 8], [4, 5, 6], "No-talking follow-along HIIT and toning workouts inspired by viral silent workout format", "High",
     lambda w, t: [pamela_reif_style(), pamela_reif_style(), pamela_reif_style()]),
    ("Blogilates Inspired", "Viral TikTok Programs", [2, 4, 8], [4, 5], "Pop pilates sculpting workout with fun music-driven Pilates moves for lean muscle", "High",
     lambda w, t: [blogilates_inspired(), blogilates_inspired(), blogilates_inspired()]),
    ("Daisy Keech Ab Program", "Viral TikTok Programs", [2, 4, 8], [5, 6, 7], "The viral 10-minute ab workout targeting all core muscles for a toned midsection", "High",
     lambda w, t: [daisy_keech_ab(), daisy_keech_ab(), daisy_keech_ab()]),
    ("Sami Clarke Booty", "Viral TikTok Programs", [4, 8, 12], [3, 4, 5], "Sculpted booty-focused training with compound and isolation glute exercises", "High",
     lambda w, t: [sami_clarke_booty(), sami_clarke_booty(), sami_clarke_booty()]),
    ("Madfit Quick HIIT", "Viral TikTok Programs", [2, 4, 8], [4, 5, 6], "Quick no-equipment HIIT workouts you can do anywhere in under 20 minutes", "High",
     lambda w, t: [madfit_quick_hiit(), madfit_quick_hiit(), madfit_quick_hiit()]),
    ("Caroline Girvan Epic Style", "Viral TikTok Programs", [4, 8, 12], [4, 5, 6], "Epic-style dumbbell strength training with high volume and progressive overload", "High",
     lambda w, t: [caroline_girvan_epic(), caroline_girvan_epic(), caroline_girvan_epic()]),
    ("Sydney Cummings Full Body", "Viral TikTok Programs", [4, 8, 12], [4, 5, 6], "Full body strength and cardio combination workouts with positive coaching energy", "High",
     lambda w, t: [sydney_cummings_full(), sydney_cummings_full(), sydney_cummings_full()]),
    ("Jeff Nippard Science", "Viral TikTok Programs", [4, 8, 12], [3, 4, 5], "Science-based training with optimal exercise selection and evidence-backed programming", "High",
     lambda w, t: [jeff_nippard_science(), jeff_nippard_science(), jeff_nippard_science()]),
    ("Athlean-X Style", "Viral TikTok Programs", [4, 8, 12], [4, 5, 6], "Science-meets-strength training focusing on muscle mechanics and joint health", "High",
     lambda w, t: [athlean_x_style(), athlean_x_style(), athlean_x_style()]),
    ("Bret Contreras Glute", "Viral TikTok Programs", [4, 8, 12], [3, 4, 5], "Glute Lab style hip thrust-focused training from the Glute Guy methodology", "High",
     lambda w, t: [bret_contreras_glute(), bret_contreras_glute(), bret_contreras_glute()]),
]

print("=== CAT 53: VIRAL TIKTOK PROGRAMS ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat53_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: learn the movements and build consistency"
            elif p <= 0.66: focus = f"Week {w} - Build: increase intensity and duration"
            else: focus = f"Week {w} - Push: maximize effort and track progress"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

# ========================================================================
# CAT 54 - NERVOUS SYSTEM & SOMATIC (12)
# ========================================================================

def vagus_nerve_activation():
    return wo("Vagus Nerve Activation", "recovery", 20, [
        ex("Diaphragmatic Breathing", 3, 10, 0, "5-second inhale, 7-second exhale", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Belly rises on inhale, ribs expand laterally", "Box Breathing"),
        ex("Cold Water Face Immersion", 1, 3, 0, "Splash cold water on face 30 seconds", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Triggers dive reflex, activates vagus nerve", "Cold Cloth on Neck"),
        ex("Humming Bee Breath", 3, 5, 0, "Inhale deeply, hum on exhale", "Bodyweight", "Core", "Diaphragm", ["Throat Muscles"], "beginner", "Long exhale with vibration stimulates vagus", "Om Chanting"),
        ex("Gentle Neck Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Sternocleidomastoid", ["Upper Trapezius"], "beginner", "Ear to shoulder, breathe into stretch", "Neck Roll"),
        ex("Eye Movement Exercise", 2, 5, 0, "Look far right, hold 30s, then left", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Move eyes only, head still, triggers relaxation", "Figure-8 Eye Movement"),
        ex("Gargling", 1, 3, 0, "Gargle water vigorously 30 seconds", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Activates vagus nerve through throat muscles", "Humming"),
    ])

def somatic_movement():
    return wo("Somatic Movement Flow", "recovery", 25, [
        ex("Body Scan Breathing", 1, 1, 0, "3 minutes mindful body scan", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Notice sensations without judging, breathe into tension", "Seated Meditation"),
        ex("Somatic Arch and Flatten", 3, 8, 0, "Slow pelvic tilts on back", "Bodyweight", "Core", "Erector Spinae", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Tiny movements, maximum awareness", "Cat-Cow"),
        ex("Slow Shoulder Roll", 2, 8, 0, "Each direction, very slow", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids", "Rhomboids"], "beginner", "Feel every degree of rotation", "Arm Circles"),
        ex("Somatic Side Bend", 2, 6, 0, "Each side, lying down", "Bodyweight", "Core", "Obliques", ["Quadratus Lumborum"], "beginner", "Contract gently then release fully", "Standing Side Bend"),
        ex("Pandiculation", 3, 5, 0, "Yawning full body stretch", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Contract muscles, then slowly release with awareness", "Cat Stretch"),
        ex("Constructive Rest Position", 1, 1, 0, "5 minutes, knees bent, feet flat", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Back flat, let gravity release tension", "Savasana"),
    ])

def nervous_system_regulation():
    return wo("Nervous System Reset", "recovery", 20, [
        ex("4-7-8 Breathing", 3, 4, 0, "Inhale 4s, hold 7s, exhale 8s", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Activates parasympathetic nervous system", "Box Breathing"),
        ex("Bilateral Stimulation Tap", 2, 1, 0, "Alternate tapping knees 2 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Cross-body tapping, like butterfly hug", "Self-Hug Squeeze"),
        ex("Orienting Exercise", 1, 1, 0, "Slowly look around room, name 5 things", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Engages visual system for safety signals", "5-4-3-2-1 Grounding"),
        ex("Physiological Sigh", 3, 5, 0, "Double inhale through nose, long exhale mouth", "Bodyweight", "Core", "Diaphragm", [], "beginner", "Most efficient single breath for calm", "Extended Exhale"),
        ex("Supported Child Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Erector Spinae", ["Shoulders"], "beginner", "Forehead on floor, arms extended, breathe", "Fetal Position Rest"),
    ])

def trauma_release_exercises():
    return wo("TRE Shake & Release", "recovery", 25, [
        ex("Standing Quad Tremor", 2, 1, 0, "Hold wall squat until legs shake, 2 min", "Bodyweight", "Legs", "Quadriceps", ["Core"], "beginner", "Slightly past fatigue, allow natural tremor", "Wall Sit"),
        ex("Butterfly Stretch with Tremor", 2, 1, 0, "Hold 90 seconds, allow shaking", "Bodyweight", "Hips", "Hip Adductors", ["Glutes"], "beginner", "Soles together, let knees fall, breathe", "Supine Butterfly"),
        ex("Psoas Release", 2, 1, 0, "Hold each side 60 seconds", "Bodyweight", "Hips", "Hip Flexors", ["Psoas"], "beginner", "One knee up, other leg straight, breathe into hip", "Supine Knee-to-Chest"),
        ex("Supine Tremoring", 1, 1, 0, "5 minutes, feet flat, knees together/apart", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Allow natural shaking, do not force or stop", "Constructive Rest"),
        ex("Grounding Breath", 2, 5, 0, "Extended exhale with feet on floor", "Bodyweight", "Core", "Diaphragm", [], "beginner", "Feel feet on ground, exhale twice as long as inhale", "4-7-8 Breathing"),
    ])

def polyvagal_exercises():
    return wo("Polyvagal Tone Session", "recovery", 20, [
        ex("Social Engagement Smile", 1, 5, 0, "Gentle smile hold 10 seconds", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Activates ventral vagal through facial muscles", "Eye Contact Practice"),
        ex("Voo Breath", 3, 5, 0, "Deep inhale, exhale with 'voo' sound", "Bodyweight", "Core", "Diaphragm", [], "beginner", "Low vibration in chest activates vagus", "Humming Breath"),
        ex("Safe Space Visualization", 1, 1, 0, "3 minutes eyes closed, imagine safe place", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Engage all senses in the visualization", "Body Scan"),
        ex("Gentle Rocking", 2, 1, 0, "2 minutes seated or standing gentle rock", "Bodyweight", "Full Body", "Core", [], "beginner", "Rhythmic movement soothes nervous system", "Swaying"),
        ex("Half Salamander Exercise", 2, 5, 0, "Turn eyes right, tilt head, hold 30s each", "Bodyweight", "Neck", "Sternocleidomastoid", ["Suboccipitals"], "beginner", "Eyes and head move opposite, vagal stimulation", "Neck Rotation"),
    ])

def body_awareness_practice():
    return wo("Body Awareness Practice", "recovery", 25, [
        ex("Progressive Body Scan", 1, 1, 0, "5 minutes, scan toes to head", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Notice without changing, just observe", "Seated Meditation"),
        ex("Slow Walking Meditation", 1, 1, 0, "5 minutes, feel each step fully", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Heel-toe contact, feel weight shift", "Standing Balance"),
        ex("Joint Circles", 2, 5, 0, "Ankles, knees, hips, shoulders, wrists", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Slow circles, feel joint space", "Arm Circles"),
        ex("Somatic Reach and Pull", 2, 6, 0, "Reach overhead, pull back slowly", "Bodyweight", "Full Body", "Latissimus Dorsi", ["Shoulders", "Core"], "beginner", "Maximum awareness of muscle engagement", "Lat Pulldown Motion"),
        ex("Floor Rolling", 2, 3, 0, "Log roll side to side", "Bodyweight", "Core", "Obliques", ["Erector Spinae"], "beginner", "Initiate from different body parts", "Supine Twist"),
    ])

def tension_release():
    return wo("Tension Release Sequence", "recovery", 20, [
        ex("Jaw Release", 2, 5, 0, "Open wide, side to side, massage", "Bodyweight", "Full Body", "Masseter", ["Temporalis"], "beginner", "Release clenching, tongue on roof of mouth", "Jaw Stretch"),
        ex("Shoulder Shrug and Drop", 3, 8, 0, "Shrug high, hold 5s, drop completely", "Bodyweight", "Shoulders", "Upper Trapezius", ["Levator Scapulae"], "beginner", "Exaggerate the drop, feel the release", "Neck Rolls"),
        ex("Wrist and Hand Release", 2, 10, 0, "Flex, extend, circle, shake", "Bodyweight", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Especially for screen users", "Prayer Stretch"),
        ex("Hip Flexor Release", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Rectus Femoris"], "beginner", "Half-kneeling, tuck pelvis, breathe", "Standing Hip Flexor Stretch"),
        ex("Legs Up Wall", 1, 1, 0, "5 minutes, legs vertical on wall", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Promotes venous return and calm", "Supine Leg Raise"),
    ])

def grounding_movement():
    return wo("Grounding Movement Flow", "recovery", 20, [
        ex("Barefoot Standing", 1, 1, 0, "2 minutes, feel all 4 corners of feet", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Root into ground, feel earth beneath", "Standing Meditation"),
        ex("Toe Grip and Spread", 2, 10, 0, "Grip floor then spread wide", "Bodyweight", "Legs", "Foot Intrinsics", ["Calves"], "beginner", "Builds foot-to-brain connection", "Towel Scrunch"),
        ex("Grounded Squat Hold", 2, 1, 0, "Hold deep squat 30-60 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hip Flexors"], "beginner", "Flat feet, arms forward for balance", "Wall Sit"),
        ex("Earth Touch Flow", 2, 5, 0, "Reach up then fold to touch ground", "Bodyweight", "Full Body", "Hamstrings", ["Erector Spinae", "Shoulders"], "beginner", "Slow, feel the connection up and down", "Forward Fold"),
        ex("Seated Spinal Wave", 2, 8, 0, "Sequential spine roll from tailbone to head", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "One vertebra at a time, fluid wave", "Cat-Cow"),
    ])

def shake_and_release():
    return wo("Shake & Release", "recovery", 15, [
        ex("Full Body Shake", 1, 1, 0, "3 minutes shaking all limbs", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Start gentle, increase intensity, let go", "Jumping Jacks"),
        ex("Arm Shake Out", 2, 1, 0, "1 minute each arm", "Bodyweight", "Arms", "Deltoids", ["Biceps", "Triceps"], "beginner", "Floppy, loose, no tension", "Arm Circles"),
        ex("Leg Shake Out", 2, 1, 0, "1 minute each leg", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Hold support, shake each leg loose", "Leg Swing"),
        ex("Spinal Shake", 1, 1, 0, "2 minutes gentle bounce through spine", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Soft knees, let spine ripple", "Cat-Cow"),
        ex("Stillness Integration", 1, 1, 0, "3 minutes standing still, eyes closed", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Feel the tingling, observe internal state", "Savasana"),
    ])

def nervous_system_recovery():
    return wo("Nervous System Recovery", "recovery", 20, [
        ex("Restorative Breathing", 3, 6, 0, "Inhale 4, hold 4, exhale 6, hold 2", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Box breathing variation for deep rest", "4-7-8 Breathing"),
        ex("Supported Fish Pose", 1, 1, 0, "Hold 3 minutes with pillow under back", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Intercostals"], "beginner", "Opens chest, stimulates heart area", "Chest Opener Stretch"),
        ex("Happy Baby Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Hamstrings", "Lower Back"], "beginner", "Grab feet, pull knees down, rock gently", "Supine Butterfly"),
        ex("Crocodile Breathing", 3, 8, 0, "Prone, breathe into belly against floor", "Bodyweight", "Core", "Diaphragm", [], "beginner", "Feel belly push into floor on inhale", "Diaphragmatic Breathing"),
        ex("Legs Up Wall", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Promotes parasympathetic activation", "Supine Rest"),
    ])

def interoception_training():
    return wo("Interoception Training", "recovery", 20, [
        ex("Heartbeat Awareness", 1, 1, 0, "2 minutes, find pulse, count beats", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Internal body awareness training", "Hand on Heart Breathing"),
        ex("Hunger and Fullness Check", 1, 1, 0, "1 minute mindful stomach scan", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Rate hunger 1-10, notice gut signals", "Body Scan"),
        ex("Temperature Awareness Walk", 1, 1, 0, "3 minutes slow walk noticing temperature", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Feel warmth/cool on skin as you move", "Slow Walking Meditation"),
        ex("Breath Counting", 3, 10, 0, "Count each breath cycle", "Bodyweight", "Core", "Diaphragm", [], "beginner", "Notice depth and rhythm without changing", "Mindful Breathing"),
        ex("Muscle Tension Scan", 1, 1, 0, "3 minutes, find and release held tension", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Contract then release each area", "Progressive Muscle Relaxation"),
    ])

def embodiment_practice():
    return wo("Embodiment Practice", "recovery", 25, [
        ex("Free Movement Dance", 1, 1, 0, "5 minutes intuitive movement to music", "Bodyweight", "Full Body", "Full Body", [], "beginner", "No rules, follow body impulses", "Gentle Swaying"),
        ex("Somatic Push Exercise", 2, 5, 0, "Push against wall, feel whole body engage", "Bodyweight", "Full Body", "Pectoralis Major", ["Core", "Legs"], "beginner", "Creates sense of agency and power", "Wall Push-Up"),
        ex("Grounding Stamp", 2, 10, 0, "Stomp feet firmly into floor", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Feel the impact, claim your space", "Heel Drops"),
        ex("Expansive Reach", 2, 8, 0, "Reach arms wide and overhead, take up space", "Bodyweight", "Full Body", "Deltoids", ["Latissimus Dorsi", "Core"], "beginner", "Star shape, breathe fully expanded", "Overhead Stretch"),
        ex("Resting Pose", 1, 1, 0, "5 minutes comfortable position", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Allow body to find its natural rest", "Savasana"),
    ])

# Cat 54 programs list
cat54_programs = [
    ("Vagus Nerve Activation", "Nervous System & Somatic", [1, 2, 4], [5, 6, 7], "Exercises to stimulate vagal tone for stress relief and nervous system regulation", "High",
     lambda w, t: [vagus_nerve_activation(), vagus_nerve_activation(), vagus_nerve_activation()]),
    ("Somatic Movement", "Nervous System & Somatic", [2, 4, 8], [4, 5], "Body-led somatic movement for releasing chronic tension and improving body awareness", "High",
     lambda w, t: [somatic_movement(), somatic_movement(), somatic_movement()]),
    ("Nervous System Regulation", "Nervous System & Somatic", [2, 4, 8], [5, 6, 7], "Down-regulate the stress response with evidence-based nervous system exercises", "High",
     lambda w, t: [nervous_system_regulation(), nervous_system_regulation(), nervous_system_regulation()]),
    ("Trauma Release Exercises", "Nervous System & Somatic", [1, 2, 4], [4, 5], "TRE-style tremor and shaking exercises for releasing stored tension and trauma", "Med",
     lambda w, t: [trauma_release_exercises(), trauma_release_exercises(), trauma_release_exercises()]),
    ("Polyvagal Exercises", "Nervous System & Somatic", [2, 4, 8], [4, 5], "Exercises based on polyvagal theory for feeling safe and socially connected", "Med",
     lambda w, t: [polyvagal_exercises(), polyvagal_exercises(), polyvagal_exercises()]),
    ("Body Awareness Practice", "Nervous System & Somatic", [2, 4, 8], [3, 4, 5], "Mindful body awareness training to reconnect with physical sensations", "Med",
     lambda w, t: [body_awareness_practice(), body_awareness_practice(), body_awareness_practice()]),
    ("Tension Release", "Nervous System & Somatic", [1, 2, 4], [4, 5], "Targeted tension release sequences for desk workers and stress holders", "Med",
     lambda w, t: [tension_release(), tension_release(), tension_release()]),
    ("Grounding Movement", "Nervous System & Somatic", [1, 2, 4], [4, 5, 6], "Grounding and earthing movement practices for stability and calm", "Med",
     lambda w, t: [grounding_movement(), grounding_movement(), grounding_movement()]),
    ("Shake & Release", "Nervous System & Somatic", [1, 2, 4], [4, 5], "Full body shaking therapy for releasing tension and resetting the nervous system", "Med",
     lambda w, t: [shake_and_release(), shake_and_release(), shake_and_release()]),
    ("Nervous System Recovery", "Nervous System & Somatic", [1, 2, 4], [4, 5], "Restorative practices for nervous system recovery after burnout or chronic stress", "Med",
     lambda w, t: [nervous_system_recovery(), nervous_system_recovery(), nervous_system_recovery()]),
    ("Interoception Training", "Nervous System & Somatic", [2, 4, 8], [4, 5], "Build awareness of internal body signals for better self-regulation", "Med",
     lambda w, t: [interoception_training(), interoception_training(), interoception_training()]),
    ("Embodiment Practice", "Nervous System & Somatic", [2, 4, 8], [3, 4, 5], "Reconnect with your body through expressive and intuitive movement", "Med",
     lambda w, t: [embodiment_practice(), embodiment_practice(), embodiment_practice()]),
]

print("\n=== CAT 54: NERVOUS SYSTEM & SOMATIC ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat54_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Awareness: gentle introduction to nervous system practices"
            elif p <= 0.66: focus = f"Week {w} - Deepen: longer holds, deeper awareness"
            else: focus = f"Week {w} - Integration: combine practices into daily routine"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

print("\n=== CATS 53-54 COMPLETE, continuing to 55-56... ===")

# ========================================================================
# CAT 55 - WEIGHTED ACCESSORIES (10)
# ========================================================================

def weighted_vest_training():
    return wo("Weighted Vest Workout", "strength", 40, [
        ex("Weighted Vest Walk", 1, 1, 0, "20 min brisk walk with 10-20lb vest", "Weighted Vest", "Full Body", "Quadriceps", ["Glutes", "Calves", "Core"], "intermediate", "Upright posture, engage core throughout", "Brisk Walk"),
        ex("Weighted Vest Push-Up", 3, 10, 60, "Vest adds 10-20lbs", "Weighted Vest", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid", "Core"], "intermediate", "Full range, elbows 45 degrees", "Push-Up"),
        ex("Weighted Vest Squat", 3, 15, 60, "Bodyweight + vest load", "Weighted Vest", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, chest up, core braced", "Bodyweight Squat"),
        ex("Weighted Vest Pull-Up", 3, 6, 90, "Vest adds resistance to pull-up", "Weighted Vest", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Full dead hang to chin over bar", "Pull-Up"),
        ex("Weighted Vest Dip", 3, 8, 90, "Vest adds load", "Weighted Vest", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Lean forward slightly for chest emphasis", "Bench Dip"),
        ex("Weighted Vest Lunge", 3, 10, 60, "Each leg", "Weighted Vest", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Bodyweight Lunge"),
    ])

def ankle_weight_workout():
    return wo("Ankle Weight Sculpt", "strength", 30, [
        ex("Ankle Weight Leg Raise", 3, 12, 30, "Each leg, 2-5lb ankle weights", "Ankle Weights", "Core", "Hip Flexors", ["Rectus Abdominis"], "beginner", "Slow controlled lift, press lower back down", "Lying Leg Raise"),
        ex("Ankle Weight Side Leg Lift", 3, 15, 30, "Each side", "Ankle Weights", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lying on side, lift with control", "Side-Lying Leg Lift"),
        ex("Ankle Weight Donkey Kick", 3, 12, 30, "Each leg", "Ankle Weights", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "On all fours, kick back to hip height", "Bodyweight Donkey Kick"),
        ex("Ankle Weight Fire Hydrant", 3, 12, 30, "Each side", "Ankle Weights", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lift knee to side, hip height", "Bodyweight Fire Hydrant"),
        ex("Ankle Weight Flutter Kick", 3, 20, 30, "Alternating", "Ankle Weights", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Small range of motion, lower back flat", "Flutter Kick"),
        ex("Ankle Weight Standing Kickback", 3, 12, 30, "Each leg", "Ankle Weights", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hold support, kick back with control", "Standing Glute Squeeze"),
    ])

def wrist_weight_workout():
    return wo("Wrist Weight Toning", "strength", 25, [
        ex("Wrist Weight Arm Circle", 3, 15, 30, "Each direction, 1-3lb wrist weights", "Wrist Weights", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Controlled circles, no momentum", "Arm Circles"),
        ex("Wrist Weight Jab Cross", 3, 20, 30, "Alternating punches", "Wrist Weights", "Shoulders", "Deltoids", ["Triceps", "Core"], "beginner", "Rotate hips with each punch", "Shadow Boxing"),
        ex("Wrist Weight Lateral Raise", 3, 12, 30, "Light wrist weights", "Wrist Weights", "Shoulders", "Lateral Deltoid", ["Supraspinatus"], "beginner", "Raise to shoulder height, slow lower", "Lateral Raise"),
        ex("Wrist Weight Front Raise", 3, 12, 30, "Alternating arms", "Wrist Weights", "Shoulders", "Anterior Deltoid", ["Core"], "beginner", "Arms straight, raise to eye level", "Front Raise"),
        ex("Wrist Weight Overhead Punch", 3, 15, 30, "Alternating arms overhead", "Wrist Weights", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Drive fist to ceiling, full extension", "Overhead Press"),
    ])

def weighted_walking():
    return wo("Weighted Walking Session", "cardio", 40, [
        ex("Weighted Walk", 1, 1, 0, "30 min walk with 10-20lb vest or weighted backpack", "Weighted Vest", "Full Body", "Quadriceps", ["Glutes", "Calves", "Core"], "beginner", "Upright posture, natural arm swing", "Brisk Walk"),
        ex("Farmer Walk", 3, 1, 60, "30 seconds each set with heavy dumbbells", "Dumbbell", "Full Body", "Forearms", ["Trapezius", "Core", "Glutes"], "intermediate", "Tall posture, grip tight, shoulders down", "Suitcase Carry"),
        ex("Overhead Carry", 2, 1, 60, "30 seconds, one arm at a time", "Dumbbell", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Lock arm out, brace core, walk steady", "Farmer Walk"),
        ex("Weighted Step-Up", 3, 10, 45, "Each leg, with vest or dumbbells", "Weighted Vest", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Drive through heel, full step up", "Bodyweight Step-Up"),
    ])

def hip_circle_band():
    return wo("Hip Circle Band Workout", "strength", 25, [
        ex("Banded Squat", 3, 15, 45, "Band above knees", "Resistance Band", "Legs", "Quadriceps", ["Glutes", "Hip Abductors"], "beginner", "Push knees out against band, full depth", "Bodyweight Squat"),
        ex("Banded Lateral Walk", 3, 15, 30, "Each direction", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors", "Glutes"], "beginner", "Stay low, constant tension on band", "Side Step"),
        ex("Banded Clamshell", 3, 15, 30, "Each side", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Feet together, open knees against band", "Clamshell"),
        ex("Banded Glute Bridge", 3, 15, 30, "Band above knees", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hamstrings", "Hip Abductors"], "beginner", "Push knees apart at top, squeeze glutes", "Glute Bridge"),
        ex("Banded Fire Hydrant", 3, 12, 30, "Each side", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "On all fours, lift knee against band", "Fire Hydrant"),
        ex("Banded Kickback", 3, 12, 30, "Each leg", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Extend leg back against band tension", "Donkey Kick"),
    ])

def mini_band_workout():
    return wo("Mini Band Full Body", "strength", 25, [
        ex("Mini Band Squat Walk", 3, 10, 30, "Each direction", "Resistance Band", "Legs", "Quadriceps", ["Glutes", "Hip Abductors"], "beginner", "Stay low, step wide against band", "Lateral Walk"),
        ex("Mini Band Pull-Apart", 3, 15, 30, "Band at wrist level", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Arms straight, pull band apart at chest", "Band Pull-Apart"),
        ex("Mini Band Bicycle", 3, 15, 30, "Band around feet", "Resistance Band", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Pedal against band resistance", "Bicycle Crunch"),
        ex("Mini Band Push-Up", 3, 10, 45, "Band across back and hands", "Resistance Band", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Band adds resistance at top", "Push-Up"),
        ex("Mini Band Glute Kickback", 3, 12, 30, "Each leg, band around ankles", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Standing, kick back against band", "Donkey Kick"),
    ])

def slam_ball_training():
    return wo("Slam Ball Power Session", "conditioning", 30, [
        ex("Ball Slam", 4, 10, 45, "15-30lb slam ball", "Slam Ball", "Full Body", "Latissimus Dorsi", ["Core", "Shoulders", "Quadriceps"], "intermediate", "Overhead, slam hard, squat to pick up", "Medicine Ball Slam"),
        ex("Slam Ball Squat Throw", 3, 10, 45, "Moderate slam ball", "Slam Ball", "Legs", "Quadriceps", ["Glutes", "Shoulders", "Core"], "intermediate", "Squat deep, explosive toss overhead", "Wall Ball"),
        ex("Slam Ball Rotational Throw", 3, 8, 45, "Each side", "Slam Ball", "Core", "Obliques", ["Hip Rotators", "Shoulders"], "intermediate", "Rotate and throw ball against wall", "Medicine Ball Rotation"),
        ex("Slam Ball Burpee", 3, 8, 60, "With slam ball", "Slam Ball", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "advanced", "Slam, drop to ball, push-up, jump", "Burpee"),
        ex("Slam Ball Russian Twist", 3, 15, 30, "Holding slam ball", "Slam Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Feet elevated, rotate side to side", "Russian Twist"),
    ])

def weighted_hula_hoop():
    return wo("Weighted Hula Hoop Session", "cardio", 25, [
        ex("Weighted Hula Hoop", 3, 1, 30, "5 min continuous hooping per set", "Weighted Hula Hoop", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Rhythmic hip motion, core engaged", "Standing Torso Rotation"),
        ex("Hula Hoop Squat", 2, 12, 30, "Squat while hooping", "Weighted Hula Hoop", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Maintain hoop while squatting", "Bodyweight Squat"),
        ex("Arm Hula Hoop", 2, 1, 30, "2 min each arm", "Weighted Hula Hoop", "Arms", "Biceps", ["Shoulders", "Forearms"], "beginner", "Spin hoop on arm, build coordination", "Arm Circles"),
        ex("Hula Hoop Walking", 2, 1, 30, "3 min walking and hooping", "Weighted Hula Hoop", "Full Body", "Core", ["Quadriceps", "Glutes"], "intermediate", "Walk forward while maintaining hoop", "Marching in Place"),
    ])

def steel_mace_training():
    return wo("Steel Mace Flow", "strength", 35, [
        ex("Mace 360", 3, 8, 45, "Each direction, 10-15lb mace", "Steel Mace", "Shoulders", "Deltoids", ["Core", "Forearms", "Latissimus Dorsi"], "intermediate", "Full rotation behind head, control the swing", "Kettlebell Halo"),
        ex("Mace 10-to-2", 3, 10, 45, "Pendulum swing", "Steel Mace", "Core", "Obliques", ["Shoulders", "Forearms"], "intermediate", "Controlled side to side, pivot at hips", "Cable Woodchop"),
        ex("Mace Squat Press", 3, 10, 60, "Squat holding mace, press at top", "Steel Mace", "Full Body", "Quadriceps", ["Deltoids", "Core", "Glutes"], "intermediate", "Full squat, press mace overhead at top", "Dumbbell Squat to Press"),
        ex("Mace Lunge Pull", 3, 8, 45, "Each leg", "Steel Mace", "Full Body", "Quadriceps", ["Latissimus Dorsi", "Core"], "intermediate", "Reverse lunge while pulling mace to chest", "Lunge with Row"),
        ex("Mace Grave Digger", 3, 10, 45, "Each side", "Steel Mace", "Core", "Obliques", ["Shoulders", "Hip Rotators"], "intermediate", "Rotational dig motion, full body engagement", "Woodchop"),
    ])

def indian_club_flow():
    return wo("Indian Club Flow", "strength", 30, [
        ex("Indian Club Circle", 3, 10, 30, "Each arm, each direction", "Indian Clubs", "Shoulders", "Rotator Cuff", ["Deltoids", "Forearms"], "beginner", "Smooth circles, let momentum flow", "Arm Circles"),
        ex("Indian Club Figure-8", 3, 8, 30, "Each arm", "Indian Clubs", "Shoulders", "Deltoids", ["Core", "Forearms"], "intermediate", "Continuous figure-8 pattern, wrist leads", "Kettlebell Figure-8"),
        ex("Double Club Swing", 3, 10, 45, "Both clubs simultaneously", "Indian Clubs", "Shoulders", "Deltoids", ["Core", "Back"], "intermediate", "Mirror pattern, maintain rhythm", "Dumbbell Front Raise"),
        ex("Club Shield Cast", 3, 8, 45, "Each arm", "Indian Clubs", "Shoulders", "Rotator Cuff", ["Forearms", "Core"], "intermediate", "Arc behind head, external rotation emphasis", "Band External Rotation"),
        ex("Club Mill", 3, 8, 30, "Each arm", "Indian Clubs", "Shoulders", "Deltoids", ["Rotator Cuff", "Forearms"], "intermediate", "Windmill pattern, full shoulder ROM", "Windmill"),
    ])

# Cat 55 programs list
cat55_programs = [
    ("Weighted Vest Training", "Weighted Accessories", [2, 4, 8], [3, 4, 5], "Progressive weighted vest training for added resistance to bodyweight exercises", "High",
     lambda w, t: [weighted_vest_training(), weighted_vest_training(), weighted_vest_training()]),
    ("Ankle Weight Workout", "Weighted Accessories", [2, 4, 8], [3, 4, 5], "Targeted lower body toning with ankle weights for glutes, hips, and core", "High",
     lambda w, t: [ankle_weight_workout(), ankle_weight_workout(), ankle_weight_workout()]),
    ("Wrist Weight Workout", "Weighted Accessories", [2, 4, 8], [3, 4], "Upper body sculpting with lightweight wrist weights for toned arms and shoulders", "High",
     lambda w, t: [wrist_weight_workout(), wrist_weight_workout(), wrist_weight_workout()]),
    ("Weighted Walking", "Weighted Accessories", [2, 4, 8], [3, 4, 5], "Walking with weighted vest or pack for enhanced calorie burn and bone density", "High",
     lambda w, t: [weighted_walking(), weighted_walking(), weighted_walking()]),
    ("Hip Circle Band", "Weighted Accessories", [2, 4, 8], [3, 4, 5], "Hip circle resistance band workouts for glute activation and hip strength", "High",
     lambda w, t: [hip_circle_band(), hip_circle_band(), hip_circle_band()]),
    ("Mini Band Workout", "Weighted Accessories", [2, 4, 8], [3, 4, 5], "Full body mini band workout using loop bands for resistance everywhere", "Med",
     lambda w, t: [mini_band_workout(), mini_band_workout(), mini_band_workout()]),
    ("Slam Ball Training", "Weighted Accessories", [2, 4, 8], [3, 4], "Explosive slam ball conditioning for power, cardio, and stress relief", "Med",
     lambda w, t: [slam_ball_training(), slam_ball_training(), slam_ball_training()]),
    ("Weighted Hula Hoop", "Weighted Accessories", [2, 4, 8], [3, 4, 5], "Fun weighted hula hoop cardio for core strength and coordination", "Med",
     lambda w, t: [weighted_hula_hoop(), weighted_hula_hoop(), weighted_hula_hoop()]),
    ("Steel Mace Training", "Weighted Accessories", [2, 4, 8], [3, 4], "Ancient steel mace training for rotational strength and shoulder mobility", "Med",
     lambda w, t: [steel_mace_training(), steel_mace_training(), steel_mace_training()]),
    ("Indian Club Flow", "Weighted Accessories", [2, 4, 8], [3, 4], "Traditional Indian club swinging for shoulder rehabilitation and mobility", "Med",
     lambda w, t: [indian_club_flow(), indian_club_flow(), indian_club_flow()]),
]

print("\n=== CAT 55: WEIGHTED ACCESSORIES ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat55_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Learn: master equipment handling and basic movements"
            elif p <= 0.66: focus = f"Week {w} - Build: increase weight or resistance progressively"
            else: focus = f"Week {w} - Perform: complex movements and higher intensity"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

# ========================================================================
# CAT 56 - YOUTUBE HOME PROGRAMS (8)
# ========================================================================

def beginner_home_youtube():
    return wo("Beginner Home Full Body", "strength", 30, [
        ex("Bodyweight Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Chest up, sit back, full depth", "Wall Sit"),
        ex("Knee Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full range from knees, elbows 45 degrees", "Wall Push-Up"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive through heels, squeeze at top", "Hip Raise"),
        ex("Bird Dog", 3, 8, 30, "Each side", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Deltoids"], "beginner", "Opposite arm and leg, hold 3 seconds", "Dead Bug"),
        ex("Standing Calf Raise", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range, pause at top", "Seated Calf Raise"),
        ex("Plank Hold", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, engage everything", "Forearm Plank"),
    ])

def thirty_day_home_challenge():
    return wo("30-Day Home Challenge", "conditioning", 30, [
        ex("Squat", 3, 15, 30, "Add 2 reps every 5 days", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Track daily reps, progressive increase", "Wall Sit"),
        ex("Push-Up", 3, 10, 30, "Add 1 rep every 3 days", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, build up gradually", "Knee Push-Up"),
        ex("Lunge", 3, 10, 30, "Each leg, add reps weekly", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Alternate legs, upright torso", "Step Back Lunge"),
        ex("Plank", 3, 1, 30, "Add 5 seconds daily", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Start 20s, build to 60s+", "Forearm Plank"),
        ex("Burpee", 3, 5, 45, "Add 1 rep every 5 days", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump at top", "Squat Thrust"),
        ex("Mountain Climber", 3, 15, 30, "Alternating, increase speed over time", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Drive knees to chest, hips level", "Plank Knee Tuck"),
    ])

def no_equipment_youtube():
    return wo("No Equipment Strength", "strength", 35, [
        ex("Pistol Squat Progression", 3, 6, 60, "Each leg, use support as needed", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Single leg, full depth, control the descent", "Bulgarian Split Squat"),
        ex("Diamond Push-Up", 3, 10, 45, "Hands close together", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Core"], "intermediate", "Hands form diamond, elbows track back", "Close-Grip Push-Up"),
        ex("Nordic Curl Progression", 3, 5, 60, "Slow eccentric, kneel on pad", "Bodyweight", "Legs", "Hamstrings", ["Glutes"], "advanced", "Control the lowering phase, use hands to assist", "Lying Leg Curl"),
        ex("Pike Push-Up", 3, 8, 45, "Hips high, head toward floor", "Bodyweight", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "V-shape body, press head to floor", "Handstand Push-Up Progression"),
        ex("Single-Leg Glute Bridge", 3, 12, 30, "Each leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "One leg extended, drive through planted heel", "Glute Bridge"),
        ex("Hanging Knee Raise", 3, 10, 45, "If bar available, or lying version", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Controlled raise, no swinging", "Lying Leg Raise"),
    ])

def apartment_friendly():
    return wo("Apartment Friendly Low-Impact", "strength", 30, [
        ex("Slow Squat", 3, 12, 30, "4 seconds down, 4 seconds up", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Ultra slow tempo, no impact", "Wall Sit"),
        ex("Push-Up", 3, 10, 30, "Slow and controlled", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "3 seconds down, push up, no noise", "Knee Push-Up"),
        ex("Reverse Lunge", 3, 10, 30, "Each leg, step back softly", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Soft step back, no stomping", "Stationary Lunge"),
        ex("Glute Bridge March", 3, 10, 30, "Alternating legs, hold bridge", "Bodyweight", "Glutes", "Gluteus Maximus", ["Core", "Hamstrings"], "beginner", "Lift one foot, keep hips level", "Glute Bridge"),
        ex("Dead Bug", 3, 10, 30, "Alternating, slow", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Lower back stays flat, opposite arm and leg", "Bird Dog"),
        ex("Isometric Wall Push", 2, 1, 30, "Hold 20 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Shoulders", "Core"], "beginner", "Push against wall as hard as possible, silent", "Wall Push-Up"),
    ])

def small_space_workout():
    return wo("Small Space Full Body", "strength", 25, [
        ex("Squat in Place", 3, 15, 30, "Bodyweight, stay on one tile", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Feet shoulder width, no movement needed", "Wall Sit"),
        ex("Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Just body length of space needed", "Knee Push-Up"),
        ex("Standing Calf Raise", 3, 20, 20, "Bodyweight", "Bodyweight", "Legs", "Calves", [], "beginner", "Minimal space, maximum burn", "Toe Raise"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Body length only", "Forearm Plank"),
        ex("Standing Knee Raise", 3, 12, 20, "Each leg", "Bodyweight", "Core", "Hip Flexors", ["Core"], "beginner", "Stand in place, drive knee up", "Marching in Place"),
    ])

def minimal_noise_workout():
    return wo("Minimal Noise Strength", "strength", 30, [
        ex("Slow Tempo Squat", 3, 12, 30, "5s down, 5s up", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Ultra slow, zero impact, maximum tension", "Wall Sit"),
        ex("Slow Push-Up", 3, 8, 30, "5s down, 5s up", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Slow tempo, silent, controlled", "Knee Push-Up"),
        ex("Isometric Lunge Hold", 3, 1, 30, "Hold 30s each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Static hold, burn without noise", "Wall Sit"),
        ex("Slow Glute Bridge", 3, 15, 30, "3s up, 3s hold, 3s down", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Silent hip raises with long holds", "Hip Raise"),
        ex("Slow Mountain Climber", 3, 10, 30, "Each leg, 3 seconds per rep", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Controlled, no foot slapping", "Dead Bug"),
        ex("Prone Y-T-W Raise", 3, 8, 30, "Each position", "Bodyweight", "Back", "Rear Deltoid", ["Rhomboids", "Lower Trapezius"], "beginner", "Face down, arms in Y then T then W shape", "Band Pull-Apart"),
    ])

def follow_along_strength():
    return wo("Follow Along Strength", "strength", 40, [
        ex("Goblet Squat", 3, 12, 45, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold dumbbell at chest, full depth", "Bodyweight Squat"),
        ex("Dumbbell Row", 3, 10, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to hip, squeeze shoulder blade", "Inverted Row"),
        ex("Dumbbell Floor Press", 3, 12, 45, "Moderate dumbbells", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Elbows touch floor, press up", "Push-Up"),
        ex("Dumbbell Deadlift", 3, 12, 45, "Moderate dumbbells", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Hip hinge, flat back, stand tall", "Good Morning"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Light to moderate", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Press overhead, full lockout", "Pike Push-Up"),
        ex("Dumbbell Curl", 3, 12, 30, "Alternating", "Dumbbell", "Arms", "Biceps", ["Brachialis"], "beginner", "No swinging, full contraction", "Hammer Curl"),
    ])

def follow_along_cardio():
    return wo("Follow Along Cardio", "cardio", 30, [
        ex("Marching in Place", 1, 1, 0, "3 min warm-up", "Bodyweight", "Full Body", "Quadriceps", ["Calves"], "beginner", "High knees, pump arms", "Step Touch"),
        ex("Squat Jack", 3, 15, 20, "Jump feet wide to squat", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Land soft, squat deep", "Squat"),
        ex("Cross Body Punch", 3, 20, 15, "Alternating", "Bodyweight", "Core", "Obliques", ["Shoulders", "Core"], "beginner", "Rotate torso, extend fully", "Torso Twist"),
        ex("Step Back Lunge to Knee", 3, 10, 20, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Lunge back, drive knee up", "Reverse Lunge"),
        ex("Lateral Shuffle", 3, 1, 20, "30 seconds each set", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Stay low, quick feet", "Side Step"),
        ex("Cool Down March", 1, 1, 0, "3 min easy walk in place", "Bodyweight", "Full Body", "Quadriceps", [], "beginner", "Gradually slow down, deep breaths", "Standing Stretch"),
    ])

# Cat 56 programs list
cat56_programs = [
    ("Beginner Home YouTube", "YouTube-Style Home Programs", [2, 4, 8], [3, 4], "Complete beginner home workout program requiring zero equipment", "High",
     lambda w, t: [beginner_home_youtube(), beginner_home_youtube(), beginner_home_youtube()]),
    ("30-Day Home Challenge", "YouTube-Style Home Programs", [4], [5, 6], "Progressive 30-day challenge that builds daily with increasing reps and difficulty", "High",
     lambda w, t: [thirty_day_home_challenge(), thirty_day_home_challenge(), thirty_day_home_challenge()]),
    ("No Equipment YouTube", "YouTube-Style Home Programs", [2, 4, 8], [3, 4, 5], "Advanced bodyweight-only strength training with zero equipment needed", "High",
     lambda w, t: [no_equipment_youtube(), no_equipment_youtube(), no_equipment_youtube()]),
    ("Apartment Friendly", "YouTube-Style Home Programs", [2, 4, 8], [3, 4, 5], "Low-impact no-noise workout perfect for apartments with neighbors below", "High",
     lambda w, t: [apartment_friendly(), apartment_friendly(), apartment_friendly()]),
    ("Small Space Workout", "YouTube-Style Home Programs", [2, 4, 8], [3, 4], "Full body workout in a tiny space - dorm room, office, or closet-sized area", "Med",
     lambda w, t: [small_space_workout(), small_space_workout(), small_space_workout()]),
    ("Minimal Noise Workout", "YouTube-Style Home Programs", [2, 4, 8], [3, 4], "Silent strength training with slow tempo and isometric holds - no jumping", "Med",
     lambda w, t: [minimal_noise_workout(), minimal_noise_workout(), minimal_noise_workout()]),
    ("Follow Along Strength", "YouTube-Style Home Programs", [4, 8, 12], [3, 4], "Guided strength workout with dumbbells following a YouTube-style format", "Med",
     lambda w, t: [follow_along_strength(), follow_along_strength(), follow_along_strength()]),
    ("Follow Along Cardio", "YouTube-Style Home Programs", [2, 4, 8], [3, 4, 5], "Follow along cardio workout with cues and transitions for home training", "Med",
     lambda w, t: [follow_along_cardio(), follow_along_cardio(), follow_along_cardio()]),
]

print("\n=== CAT 56: YOUTUBE HOME PROGRAMS ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat56_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Start: learn movements, build habit"
            elif p <= 0.66: focus = f"Week {w} - Progress: add reps, improve form"
            else: focus = f"Week {w} - Level Up: harder variations, more volume"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

print("\n=== CATS 55-56 COMPLETE ===")

# ========================================================================
# CAT 57 - CONTENT CREATOR / INFLUENCER FITNESS (12)
# ========================================================================

def fitness_influencer_challenge():
    return wo("Influencer Body Blueprint", "strength", 50, [
        ex("Barbell Hip Thrust", 4, 12, 60, "Heavy, progressive overload", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Full extension, squeeze at top for photos", "Glute Bridge"),
        ex("Incline Dumbbell Press", 4, 10, 60, "Moderate to heavy", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps", "Anterior Deltoid"], "intermediate", "30 degree angle, full stretch", "Push-Up"),
        ex("Lateral Raise", 4, 15, 30, "Light, high reps for cap delts", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Supraspinatus"], "beginner", "Slight lean forward, pinky up", "Cable Lateral Raise"),
        ex("Cable Row", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Wide grip for back width", "Dumbbell Row"),
        ex("Leg Press", 3, 12, 60, "Feet high and wide for glutes", "Leg Press", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Deep range, drive through heels", "Goblet Squat"),
        ex("Tricep Pushdown", 3, 15, 30, "Rope attachment", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Split rope at bottom, squeeze", "Diamond Push-Up"),
    ])

def thirty_day_transformation():
    return wo("30-Day Transformation", "conditioning", 45, [
        ex("Barbell Squat", 4, 10, 90, "Progressive overload weekly", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Below parallel, track weekly weight", "Goblet Squat"),
        ex("Dumbbell Bench Press", 4, 10, 60, "Increase by 2.5lb weekly", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full ROM, squeeze at top", "Push-Up"),
        ex("Pull-Up", 3, 8, 60, "Add reps weekly", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full dead hang to chin over", "Lat Pulldown"),
        ex("Overhead Press", 3, 10, 60, "Barbell or dumbbells", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, no leg drive", "Dumbbell Shoulder Press"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hip hinge, feel the stretch", "Dumbbell RDL"),
        ex("Plank to Push-Up", 3, 8, 30, "Alternating lead arm", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Stable hips, controlled transitions", "Plank Hold"),
    ])

def before_after_program():
    return wo("Before & After Shred", "conditioning", 45, [
        ex("Dumbbell Thruster", 4, 12, 45, "Moderate dumbbells", "Dumbbell", "Full Body", "Quadriceps", ["Deltoids", "Glutes", "Core"], "intermediate", "Deep squat, press overhead in one movement", "Bodyweight Squat to Press"),
        ex("Kettlebell Swing", 4, 15, 30, "Moderate kettlebell", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip snap, arms are pendulum", "Dumbbell Swing"),
        ex("Mountain Climber", 3, 20, 20, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Drive knees, keep hips down", "Plank Knee Tuck"),
        ex("Dumbbell Snatch", 3, 8, 45, "Each arm", "Dumbbell", "Full Body", "Deltoids", ["Core", "Quadriceps", "Glutes"], "intermediate", "Pull from floor to overhead in one motion", "Dumbbell Clean and Press"),
        ex("Burpee", 3, 10, 30, "Full burpee with push-up", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump at top", "Squat Thrust"),
        ex("Battle Rope", 3, 1, 30, "30 seconds alternating waves", "Battle Rope", "Full Body", "Shoulders", ["Core", "Biceps", "Forearms"], "intermediate", "Alternate arms, create waves to end", "Jumping Jacks"),
    ])

def social_media_shred():
    return wo("Social Media Shred", "strength", 50, [
        ex("Dumbbell Lateral Raise", 4, 15, 30, "Light, pump for shoulder caps", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Supraspinatus"], "beginner", "Visible shoulder development for photos", "Cable Lateral Raise"),
        ex("Incline Dumbbell Curl", 3, 12, 45, "Stretch emphasis", "Dumbbell", "Arms", "Biceps", ["Brachialis"], "intermediate", "Full stretch at bottom, peak contraction", "Standing Curl"),
        ex("Cable Fly", 3, 12, 45, "High to low for chest definition", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "Squeeze at center, constant tension", "Dumbbell Fly"),
        ex("Lat Pulldown", 3, 12, 45, "Wide grip for V-taper", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Pull to upper chest, squeeze lats", "Pull-Up"),
        ex("Leg Extension", 3, 15, 30, "Hold at top for quad definition", "Machine", "Legs", "Quadriceps", ["Rectus Femoris"], "beginner", "Full extension, 2-second hold at top", "Sissy Squat"),
        ex("Tricep Overhead Extension", 3, 12, 30, "Dumbbell or cable", "Dumbbell", "Arms", "Triceps", ["Anconeus"], "beginner", "Full stretch behind head", "Skull Crusher"),
    ])

def instagram_worthy_body():
    return wo("Camera-Ready Physique", "strength", 50, [
        ex("Hip Thrust", 4, 12, 60, "Heavy barbell", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full hip extension, pause at top", "Glute Bridge"),
        ex("Dumbbell Shoulder Press", 4, 10, 60, "Moderate weight", "Dumbbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Full lockout, controlled negative", "Pike Push-Up"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate barbell", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Build posterior chain for side profile", "Dumbbell RDL"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids", "External Rotators"], "beginner", "Posture improvement for photos", "Band Pull-Apart"),
        ex("Dumbbell Chest Fly", 3, 12, 45, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "Wide arc, deep stretch, squeeze center", "Cable Fly"),
        ex("Hanging Leg Raise", 3, 10, 45, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Legs straight, no swinging", "Lying Leg Raise"),
    ])

def youtube_trainer_program():
    return wo("YouTube Trainer Full Body", "strength", 45, [
        ex("Barbell Squat", 4, 8, 120, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, brace core", "Goblet Squat"),
        ex("Barbell Bench Press", 4, 8, 120, "Moderate to heavy", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch chest, explosive press", "Dumbbell Bench Press"),
        ex("Barbell Row", 3, 10, 60, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Flat back, pull to navel", "Dumbbell Row"),
        ex("Dumbbell Lunge", 3, 10, 45, "Each leg", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Alternating, upright torso", "Bodyweight Lunge"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Seated or standing", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Full lockout, controlled lower", "Pike Push-Up"),
    ])

def podcast_workout():
    return wo("Podcast Zone-2 Session", "cardio", 45, [
        ex("Incline Treadmill Walk", 1, 1, 0, "30 min at 3.0-3.5mph, 5-8% incline", "Treadmill", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Zone 2 heart rate, can hold conversation", "Outdoor Walk"),
        ex("Stairmaster Climb", 1, 1, 0, "10 min moderate pace", "Stairmaster", "Legs", "Glutes", ["Quadriceps", "Calves"], "beginner", "Steady pace, don't lean on rails", "Step-Up"),
        ex("Standing Calf Raise", 2, 20, 30, "Bodyweight between cardio", "Bodyweight", "Legs", "Calves", [], "beginner", "Full range during rest break", "Seated Calf Raise"),
    ])

def gym_bro_split():
    return wo("Gym Bro Chest Day", "strength", 55, [
        ex("Barbell Bench Press", 5, 5, 120, "Heavy, progressive overload", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, leg drive, touch chest", "Dumbbell Bench Press"),
        ex("Incline Dumbbell Press", 4, 10, 60, "Moderate to heavy", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps", "Anterior Deltoid"], "intermediate", "30 degree bench, full ROM", "Incline Barbell Press"),
        ex("Cable Crossover", 3, 12, 45, "Moderate, squeeze at center", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "High to low, cross hands", "Dumbbell Fly"),
        ex("Dumbbell Fly", 3, 12, 45, "Moderate, deep stretch", "Dumbbell", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "Arms wide, slight bend, squeeze center", "Cable Fly"),
        ex("Dip", 3, 10, 60, "Bodyweight or weighted", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Lean forward for chest emphasis", "Bench Dip"),
        ex("Skull Crusher", 3, 12, 45, "EZ bar or dumbbells", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lower to forehead, extend fully", "Tricep Pushdown"),
    ])

def gym_girl_aesthetic():
    return wo("Gym Girl Lower Body", "strength", 50, [
        ex("Barbell Hip Thrust", 4, 12, 60, "Heavy, use pad", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Drive through heels, full extension", "Smith Machine Hip Thrust"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Each leg, dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot elevated, deep lunge", "Reverse Lunge"),
        ex("Cable Kickback", 3, 12, 30, "Each leg, ankle strap", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Full extension, squeeze at back", "Donkey Kick"),
        ex("Leg Press", 3, 15, 60, "Feet high for glutes", "Leg Press", "Legs", "Glutes", ["Quadriceps", "Hamstrings"], "intermediate", "Full depth, drive through heels", "Goblet Squat"),
        ex("Sumo Deadlift", 3, 10, 60, "Wide stance barbell", "Barbell", "Legs", "Glutes", ["Hip Adductors", "Hamstrings", "Quadriceps"], "intermediate", "Wide stance, toes out, chest up", "Sumo Squat"),
        ex("Abduction Machine", 3, 15, 30, "Moderate weight", "Machine", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Full open, control the close", "Banded Lateral Walk"),
    ])

def tiktok_gym_routine():
    return wo("TikTok Gym Routine", "strength", 40, [
        ex("Smith Machine Hip Thrust", 4, 12, 60, "Heavy", "Smith Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Pad the bar, full hip extension", "Barbell Hip Thrust"),
        ex("Stairmaster", 1, 1, 0, "15 min moderate pace", "Stairmaster", "Legs", "Glutes", ["Quadriceps", "Calves"], "beginner", "Hands off rails, upright posture", "Step-Up"),
        ex("Cable Kickback", 3, 12, 30, "Each leg", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top, control return", "Donkey Kick"),
        ex("Lat Pulldown", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Wide grip, pull to upper chest", "Pull-Up"),
        ex("Lateral Raise", 3, 15, 30, "Light dumbbells", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "Controlled raise, no momentum", "Cable Lateral Raise"),
    ])

def fitness_vlogger_program():
    return wo("Fitness Vlogger Push Pull", "strength", 50, [
        ex("Barbell Bench Press", 4, 8, 90, "Track weight for content", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Film PR attempts, full ROM", "Dumbbell Bench Press"),
        ex("Overhead Press", 3, 10, 60, "Standing barbell", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, document progress", "Dumbbell Shoulder Press"),
        ex("Weighted Pull-Up", 3, 8, 90, "Add weight progressively", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Full ROM, track added weight", "Pull-Up"),
        ex("Barbell Row", 3, 10, 60, "Moderate to heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Flat back, explosive pull", "Dumbbell Row"),
        ex("Dumbbell Lateral Raise", 3, 15, 30, "Light weight, high reps", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "Pump set for camera-ready delts", "Cable Lateral Raise"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "High pull, external rotation", "Band Pull-Apart"),
    ])

def content_creator_body():
    return wo("Content Creator Aesthetics", "strength", 45, [
        ex("Incline Dumbbell Press", 4, 10, 60, "Upper chest focus", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps", "Anterior Deltoid"], "intermediate", "30 degrees, full stretch at bottom", "Incline Push-Up"),
        ex("Dumbbell Lateral Raise", 4, 15, 30, "Light, strict form", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "Build visible shoulder caps", "Cable Lateral Raise"),
        ex("Cable Row", 3, 12, 45, "Moderate, V-taper focus", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Wide grip, pull to chest", "Dumbbell Row"),
        ex("Barbell Curl", 3, 12, 45, "Moderate weight", "Barbell", "Arms", "Biceps", ["Brachialis"], "beginner", "No swinging, peak contraction", "Dumbbell Curl"),
        ex("Tricep Rope Pushdown", 3, 15, 30, "Moderate cable", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Split rope at bottom, full extension", "Diamond Push-Up"),
        ex("Hanging Leg Raise", 3, 10, 45, "Core definition", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Straight legs, no swinging", "Lying Leg Raise"),
    ])

# Cat 57 programs list
cat57_programs = [
    ("Fitness Influencer Challenge", "Content Creator/Influencer Fitness", [4, 8, 12], [5, 6], "Camera-ready physique blueprint focusing on the most photogenic muscle groups", "High",
     lambda w, t: [fitness_influencer_challenge(), fitness_influencer_challenge(), fitness_influencer_challenge()]),
    ("30-Day Transformation", "Content Creator/Influencer Fitness", [4, 8, 12], [5, 6], "Document your transformation with progressive overload and measurable gains", "High",
     lambda w, t: [thirty_day_transformation(), thirty_day_transformation(), thirty_day_transformation()]),
    ("Before & After Program", "Content Creator/Influencer Fitness", [4, 8, 12], [5, 6], "Structured shred program designed for dramatic before and after results", "High",
     lambda w, t: [before_after_program(), before_after_program(), before_after_program()]),
    ("Social Media Shred", "Content Creator/Influencer Fitness", [4, 8, 12], [5, 6], "Aesthetic-focused training for a social-media-worthy lean physique", "High",
     lambda w, t: [social_media_shred(), social_media_shred(), social_media_shred()]),
    ("Instagram Worthy Body", "Content Creator/Influencer Fitness", [4, 8, 12], [5, 6], "Build the photogenic physique with emphasis on shoulders, glutes, and posture", "High",
     lambda w, t: [instagram_worthy_body(), instagram_worthy_body(), instagram_worthy_body()]),
    ("YouTube Trainer Program", "Content Creator/Influencer Fitness", [4, 8, 12], [4, 5], "Full body strength program in the style of popular YouTube fitness trainers", "Med",
     lambda w, t: [youtube_trainer_program(), youtube_trainer_program(), youtube_trainer_program()]),
    ("Podcast Workout", "Content Creator/Influencer Fitness", [2, 4, 8], [3, 4, 5], "Zone 2 cardio sessions designed for multitasking with podcasts or audiobooks", "Med",
     lambda w, t: [podcast_workout(), podcast_workout(), podcast_workout()]),
    ("Gym Bro Split", "Content Creator/Influencer Fitness", [4, 8, 12], [5, 6], "Classic bro split with chest day emphasis - the gym culture classic", "Med",
     lambda w, t: [gym_bro_split(), gym_bro_split(), gym_bro_split()]),
    ("Gym Girl Aesthetic", "Content Creator/Influencer Fitness", [4, 8, 12], [4, 5], "Lower body and glute focused aesthetic training for the gym girl lifestyle", "Med",
     lambda w, t: [gym_girl_aesthetic(), gym_girl_aesthetic(), gym_girl_aesthetic()]),
    ("TikTok Gym Routine", "Content Creator/Influencer Fitness", [2, 4, 8], [4, 5], "The typical TikTok gym routine with hip thrusts, stairmaster, and aesthetic work", "Med",
     lambda w, t: [tiktok_gym_routine(), tiktok_gym_routine(), tiktok_gym_routine()]),
    ("Fitness Vlogger Program", "Content Creator/Influencer Fitness", [4, 8, 12], [4, 5, 6], "Push-pull training designed for documenting strength progress on camera", "Med",
     lambda w, t: [fitness_vlogger_program(), fitness_vlogger_program(), fitness_vlogger_program()]),
    ("Content Creator Body", "Content Creator/Influencer Fitness", [4, 8, 12], [4, 5, 6], "Aesthetic training focusing on upper body and core for on-camera presence", "Med",
     lambda w, t: [content_creator_body(), content_creator_body(), content_creator_body()]),
]

print("\n=== CAT 57: INFLUENCER FITNESS ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat57_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Build Base: establish form and starting weights"
            elif p <= 0.66: focus = f"Week {w} - Intensify: progressive overload, track all lifts"
            else: focus = f"Week {w} - Peak Aesthetics: pump training and definition work"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

# ========================================================================
# CAT 58 - LIFE EVENTS & MILESTONES (14)
# ========================================================================

def wedding_ready_shred():
    return wo("Wedding Ready Workout", "conditioning", 45, [
        ex("Dumbbell Squat to Press", 3, 12, 45, "Moderate dumbbells", "Dumbbell", "Full Body", "Quadriceps", ["Deltoids", "Glutes", "Core"], "intermediate", "Full body calorie burn, deep squat to press", "Bodyweight Squat"),
        ex("Dumbbell Chest Press", 3, 12, 45, "Moderate dumbbells", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Upper body definition for strapless dress/suit", "Push-Up"),
        ex("Dumbbell Romanian Deadlift", 3, 12, 45, "Moderate dumbbells", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Posterior chain for posture in photos", "Good Morning"),
        ex("Lateral Raise", 3, 15, 30, "Light dumbbells", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "Shoulder definition visible in all outfits", "Cable Lateral Raise"),
        ex("Treadmill Intervals", 1, 1, 0, "10 min: 30s sprint / 60s walk x 6-8", "Treadmill", "Full Body", "Quadriceps", ["Glutes", "Calves"], "intermediate", "High intensity for maximum calorie burn", "Jumping Jacks"),
        ex("Plank Hold", 3, 1, 30, "Hold 45-60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Strong core for posture on the big day", "Forearm Plank"),
    ])

def prom_formal_ready():
    return wo("Prom Ready Toning", "strength", 35, [
        ex("Goblet Squat", 3, 12, 30, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Full depth, chest up", "Bodyweight Squat"),
        ex("Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range for arm definition", "Knee Push-Up"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm, moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Back definition for backless dress", "Inverted Row"),
        ex("Dumbbell Curl", 3, 12, 30, "Light to moderate", "Dumbbell", "Arms", "Biceps", ["Brachialis"], "beginner", "Toned arms for sleeveless", "Hammer Curl"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top, shape the back view", "Hip Raise"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Flat midsection for form-fitting", "Forearm Plank"),
    ])

def beach_vacation_ready():
    return wo("Beach Body Shred", "conditioning", 45, [
        ex("Dumbbell Thruster", 4, 12, 45, "Moderate weight", "Dumbbell", "Full Body", "Quadriceps", ["Deltoids", "Glutes"], "intermediate", "Max calorie burn compound movement", "Bodyweight Squat to Press"),
        ex("Pull-Up", 3, 8, 60, "Bodyweight", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "V-taper for beach look", "Lat Pulldown"),
        ex("Dumbbell Walking Lunge", 3, 10, 45, "Each leg", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, leg definition", "Bodyweight Lunge"),
        ex("Cable Crunch", 3, 15, 30, "Moderate cable", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Crunch down, exhale at bottom", "Crunch"),
        ex("Dumbbell Lateral Raise", 3, 15, 30, "Light, strict form", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "Capped shoulders for beach", "Cable Lateral Raise"),
        ex("Sprint Intervals", 1, 1, 0, "8 x 30s sprint / 60s rest", "Bodyweight", "Full Body", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Maximum fat burn for reveal", "High Knees"),
    ])

def reunion_shred():
    return wo("Reunion Ready Shred", "conditioning", 40, [
        ex("Barbell Squat", 4, 8, 90, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Build lower body foundation", "Goblet Squat"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Chest definition", "Push-Up"),
        ex("Cable Row", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Back width and posture", "Dumbbell Row"),
        ex("Overhead Press", 3, 10, 60, "Moderate", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Shoulder presence", "Pike Push-Up"),
        ex("Bicycle Crunch", 3, 20, 30, "Alternating", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Core definition", "Dead Bug"),
        ex("Treadmill Incline Walk", 1, 1, 0, "15 min at 10% incline, 3.5 mph", "Treadmill", "Legs", "Glutes", ["Calves", "Quadriceps"], "beginner", "Steady state fat burn", "Outdoor Walk"),
    ])

def birthday_shred():
    return wo("Birthday Shred Session", "conditioning", 40, [
        ex("Kettlebell Swing", 4, 15, 30, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip drive, fat burning", "Dumbbell Swing"),
        ex("Push-Up", 3, 15, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "High reps for pump", "Knee Push-Up"),
        ex("Goblet Squat", 3, 15, 45, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Deep squat, hold at bottom", "Bodyweight Squat"),
        ex("Dumbbell Row", 3, 12, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull to hip, squeeze", "Inverted Row"),
        ex("Mountain Climber", 3, 20, 30, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Drive knees, heart rate up", "Plank Knee Tuck"),
    ])

def new_year_new_you():
    return wo("New Year Full Body Reset", "conditioning", 40, [
        ex("Dumbbell Squat", 3, 12, 45, "Moderate dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Fresh start, build from here", "Bodyweight Squat"),
        ex("Dumbbell Bench Press", 3, 12, 45, "Moderate", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full ROM, establish baseline", "Push-Up"),
        ex("Dumbbell Row", 3, 12, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull to hip, track weight", "Inverted Row"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Light to moderate", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full lockout", "Pike Push-Up"),
        ex("Plank Hold", 3, 1, 30, "Hold 30 seconds, add 5s weekly", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Build core strength progressively", "Forearm Plank"),
        ex("Treadmill Walk", 1, 1, 0, "15 min brisk walk to finish", "Treadmill", "Full Body", "Quadriceps", ["Calves"], "beginner", "Easy cardio to build habit", "Outdoor Walk"),
    ])

def summer_body_countdown():
    return wo("Summer Body Circuit", "conditioning", 45, [
        ex("Dumbbell Clean and Press", 4, 10, 45, "Moderate dumbbells", "Dumbbell", "Full Body", "Deltoids", ["Quadriceps", "Glutes", "Core"], "intermediate", "One fluid motion, explosive", "Dumbbell Squat to Press"),
        ex("Dumbbell Renegade Row", 3, 8, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row to hip", "Dumbbell Row"),
        ex("Jump Squat", 3, 12, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explosive jump", "Bodyweight Squat"),
        ex("Push-Up to Rotation", 3, 8, 30, "Each side", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Shoulders"], "intermediate", "Push-up then rotate to side plank", "Push-Up"),
        ex("Dumbbell Reverse Lunge", 3, 10, 45, "Each leg", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Step back, both knees 90", "Bodyweight Lunge"),
        ex("Hanging Leg Raise", 3, 10, 45, "Straight legs", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Six-pack for summer", "Lying Leg Raise"),
    ])

def spring_break_ready():
    return wo("Spring Break HIIT", "hiit", 35, [
        ex("Burpee", 4, 10, 30, "Full burpee", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump high", "Squat Thrust"),
        ex("Dumbbell Squat Jump", 3, 10, 30, "Light dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explosive jump", "Jump Squat"),
        ex("Mountain Climber", 3, 20, 20, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Sprint the knees, 20 seconds", "Plank Knee Tuck"),
        ex("Dumbbell Snatch", 3, 8, 45, "Each arm", "Dumbbell", "Full Body", "Deltoids", ["Core", "Quadriceps"], "intermediate", "Floor to overhead, one motion", "Dumbbell Clean and Press"),
        ex("Box Jump", 3, 10, 45, "18-24 inch box", "Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Soft landing, step down", "Jump Squat"),
    ])

def festival_ready():
    return wo("Festival Ready Pump", "strength", 40, [
        ex("Dumbbell Shoulder Press", 4, 10, 45, "Moderate weight", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Capped shoulders for tank tops", "Pike Push-Up"),
        ex("Dumbbell Lateral Raise", 3, 15, 30, "Light weight", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "High reps for shoulder pump", "Cable Lateral Raise"),
        ex("Incline Dumbbell Curl", 3, 12, 30, "Light to moderate", "Dumbbell", "Arms", "Biceps", ["Brachialis"], "beginner", "Full stretch, peak contraction", "Standing Curl"),
        ex("Tricep Dip", 3, 12, 45, "Bodyweight", "Bodyweight", "Arms", "Triceps", ["Pectoralis Major"], "intermediate", "Lean back for tricep focus", "Bench Dip"),
        ex("Cable Fly", 3, 12, 30, "Moderate weight", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "Pump chest for crop tops", "Dumbbell Fly"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Flat stomach for festival outfits", "Forearm Plank"),
    ])

def photoshoot_ready():
    return wo("Photoshoot Pump Session", "strength", 45, [
        ex("Dumbbell Lateral Raise", 4, 20, 20, "Light, extreme pump", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "High reps to fill out shoulders", "Cable Lateral Raise"),
        ex("Incline Dumbbell Press", 3, 15, 30, "Moderate, pump focus", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Pump blood into upper chest", "Incline Push-Up"),
        ex("Cable Curl", 3, 15, 20, "Light to moderate", "Cable Machine", "Arms", "Biceps", ["Brachialis"], "beginner", "Constant tension for vein pop", "Dumbbell Curl"),
        ex("Tricep Pushdown", 3, 15, 20, "Moderate cable", "Cable Machine", "Arms", "Triceps", [], "beginner", "Full extension, squeeze hard", "Diamond Push-Up"),
        ex("Cable Row", 3, 15, 30, "Moderate, squeeze each rep", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids"], "intermediate", "Rear detail for back shots", "Dumbbell Row"),
        ex("Cable Crunch", 3, 15, 20, "Moderate cable", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Definition for shirtless shots", "Crunch"),
    ])

def red_carpet_ready():
    return wo("Red Carpet Full Body", "conditioning", 45, [
        ex("Barbell Squat", 4, 10, 90, "Moderate weight", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Lower body shape for gown/suit", "Goblet Squat"),
        ex("Dumbbell Bench Press", 3, 12, 60, "Moderate", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Upper body fill for tailored fit", "Push-Up"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Posture perfection for photos", "Band Pull-Apart"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate", "Barbell", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Posterior chain for side view", "Dumbbell RDL"),
        ex("Lateral Raise", 3, 15, 30, "Light, controlled", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "Shoulder line for silhouette", "Cable Lateral Raise"),
        ex("Plank Hold", 3, 1, 30, "Hold 60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Flat midsection under fitted clothes", "Forearm Plank"),
    ])

def post_holiday_reset():
    return wo("Post-Holiday Reset", "conditioning", 35, [
        ex("Bodyweight Squat", 3, 15, 30, "Ease back in", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Gentle start, build back up", "Wall Sit"),
        ex("Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Rebuild upper body strength", "Knee Push-Up"),
        ex("Dumbbell Row", 3, 10, 30, "Light to moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Ease back into pulling", "Inverted Row"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Reactivate glutes", "Hip Raise"),
        ex("Walking", 1, 1, 0, "15 min brisk walk", "Bodyweight", "Full Body", "Quadriceps", ["Calves"], "beginner", "Get moving again", "Outdoor Walk"),
        ex("Plank", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Rebuild core engagement", "Forearm Plank"),
    ])

def new_job_confidence():
    return wo("New Job Confidence Builder", "strength", 40, [
        ex("Barbell Squat", 3, 10, 60, "Moderate weight", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Build physical and mental strength", "Goblet Squat"),
        ex("Overhead Press", 3, 10, 60, "Moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Shoulder confidence, powerful presence", "Dumbbell Shoulder Press"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Chest up, confident posture", "Push-Up"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Perfect posture for presentations", "Band Pull-Apart"),
        ex("Dumbbell Row", 3, 10, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Strong back, upright presence", "Inverted Row"),
        ex("Deadlift", 3, 8, 90, "Moderate to heavy", "Barbell", "Full Body", "Hamstrings", ["Glutes", "Erector Spinae", "Core"], "intermediate", "Total body power and confidence", "Dumbbell Deadlift"),
    ])

def divorce_recovery_fitness():
    return wo("Recovery Strength Session", "strength", 40, [
        ex("Dumbbell Goblet Squat", 3, 12, 45, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Build yourself back up, strong foundation", "Bodyweight Squat"),
        ex("Push-Up", 3, 10, 30, "Bodyweight, build up reps", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Push through resistance, literal and figurative", "Knee Push-Up"),
        ex("Kettlebell Swing", 3, 15, 45, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Release stress, explosive power", "Dumbbell Swing"),
        ex("Dumbbell Row", 3, 10, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull yourself together, literally", "Inverted Row"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Light to moderate", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Stand tall, shoulders back", "Pike Push-Up"),
        ex("Plank Hold", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core stability for life stability", "Forearm Plank"),
    ])

# Cat 58 programs list
cat58_programs = [
    ("Wedding Ready Shred", "Life Events & Milestones", [4, 8, 12], [4, 5, 6], "Get wedding-day ready with a shred program for looking amazing in photos", "High",
     lambda w, t: [wedding_ready_shred(), wedding_ready_shred(), wedding_ready_shred()]),
    ("Prom/Formal Ready", "Life Events & Milestones", [2, 4, 8], [3, 4, 5], "Look your best for prom or formal events with targeted toning", "Med",
     lambda w, t: [prom_formal_ready(), prom_formal_ready(), prom_formal_ready()]),
    ("Beach Vacation Ready", "Life Events & Milestones", [2, 4, 8], [4, 5, 6], "Countdown to your beach vacation with full body shred training", "High",
     lambda w, t: [beach_vacation_ready(), beach_vacation_ready(), beach_vacation_ready()]),
    ("Reunion Shred", "Life Events & Milestones", [4, 8, 12], [4, 5], "Show up to your reunion in the best shape of your life", "Med",
     lambda w, t: [reunion_shred(), reunion_shred(), reunion_shred()]),
    ("Birthday Shred", "Life Events & Milestones", [2, 4, 8], [4, 5], "Celebrate your birthday with your best body yet", "Med",
     lambda w, t: [birthday_shred(), birthday_shred(), birthday_shred()]),
    ("New Year New You", "Life Events & Milestones", [4, 8, 12], [3, 4, 5], "Start the new year with a structured full body reset program", "High",
     lambda w, t: [new_year_new_you(), new_year_new_you(), new_year_new_you()]),
    ("Summer Body Countdown", "Life Events & Milestones", [4, 8, 12], [4, 5, 6], "Countdown to summer with high-intensity circuits for lean muscle", "High",
     lambda w, t: [summer_body_countdown(), summer_body_countdown(), summer_body_countdown()]),
    ("Spring Break Ready", "Life Events & Milestones", [2, 4, 8], [4, 5, 6], "Quick HIIT-focused shred for spring break preparation", "Med",
     lambda w, t: [spring_break_ready(), spring_break_ready(), spring_break_ready()]),
    ("Festival Ready", "Life Events & Milestones", [2, 4, 8], [4, 5], "Pump-style training for looking great in festival outfits", "Med",
     lambda w, t: [festival_ready(), festival_ready(), festival_ready()]),
    ("Photoshoot Ready", "Life Events & Milestones", [2, 4, 8], [4, 5, 6], "Peak pump sessions for looking your absolute best on camera", "Med",
     lambda w, t: [photoshoot_ready(), photoshoot_ready(), photoshoot_ready()]),
    ("Red Carpet Ready", "Life Events & Milestones", [4, 8, 12], [4, 5], "Full body training for looking flawless in formal wear and red carpet moments", "Med",
     lambda w, t: [red_carpet_ready(), red_carpet_ready(), red_carpet_ready()]),
    ("Post-Holiday Reset", "Life Events & Milestones", [2, 4, 8], [3, 4], "Ease back into fitness after holiday indulgence with gentle progressive training", "Med",
     lambda w, t: [post_holiday_reset(), post_holiday_reset(), post_holiday_reset()]),
    ("New Job Confidence", "Life Events & Milestones", [4, 8, 12], [3, 4, 5], "Build physical and mental confidence for a new career chapter", "Med",
     lambda w, t: [new_job_confidence(), new_job_confidence(), new_job_confidence()]),
    ("Divorce Recovery Fitness", "Life Events & Milestones", [4, 8, 12], [3, 4, 5], "Rebuild yourself physically and mentally with empowering strength training", "Med",
     lambda w, t: [divorce_recovery_fitness(), divorce_recovery_fitness(), divorce_recovery_fitness()]),
]

print("\n=== CAT 58: LIFE EVENTS & MILESTONES ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat58_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: establish routine and baseline fitness"
            elif p <= 0.66: focus = f"Week {w} - Build: ramp up intensity and volume"
            else: focus = f"Week {w} - Peak: maximize results for the big day"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

print("\n=== CATS 57-58 COMPLETE ===")

# ========================================================================
# CAT 59 - REDDIT-FAMOUS PROGRAMS (18)
# ========================================================================

def reddit_ppl_push():
    return wo("PPL Push Day", "strength", 60, [
        ex("Barbell Bench Press", 4, 5, 180, "Start 70% 1RM, add 2.5lb/session", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, touch chest, leg drive", "Dumbbell Bench Press"),
        ex("Overhead Press", 3, 8, 120, "Start moderate, linear progression", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, no leg drive", "Dumbbell Shoulder Press"),
        ex("Incline Dumbbell Press", 3, 10, 60, "Moderate dumbbells", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps", "Anterior Deltoid"], "intermediate", "30 degrees, full ROM", "Incline Barbell Press"),
        ex("Dumbbell Lateral Raise", 3, 15, 30, "Light, strict form", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Supraspinatus"], "beginner", "No momentum, controlled", "Cable Lateral Raise"),
        ex("Tricep Pushdown", 3, 12, 30, "Rope or bar", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full extension, squeeze", "Diamond Push-Up"),
        ex("Overhead Tricep Extension", 3, 12, 30, "Cable or dumbbell", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full stretch behind head", "Skull Crusher"),
    ])

def reddit_ppl_pull():
    return wo("PPL Pull Day", "strength", 60, [
        ex("Barbell Deadlift", 1, 5, 180, "Start 70% 1RM, add 2.5lb/session", "Barbell", "Full Body", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "intermediate", "Hip hinge, flat back, drive through floor", "Trap Bar Deadlift"),
        ex("Barbell Row", 3, 8, 90, "Linear progression", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate", "45 degree torso, pull to navel", "Dumbbell Row"),
        ex("Pull-Up", 3, 8, 90, "Add weight when hitting 3x8", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full dead hang, chin over bar", "Lat Pulldown"),
        ex("Face Pull", 3, 15, 30, "Light cable, external rotation", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids", "External Rotators"], "beginner", "Pull to face, rotate thumbs back", "Band Pull-Apart"),
        ex("Barbell Curl", 3, 10, 30, "Moderate weight", "Barbell", "Arms", "Biceps", ["Brachialis"], "beginner", "No swinging, full ROM", "Dumbbell Curl"),
        ex("Hammer Curl", 3, 10, 30, "Moderate dumbbells", "Dumbbell", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "Neutral grip, controlled", "Reverse Curl"),
    ])

def reddit_ppl_legs():
    return wo("PPL Leg Day", "strength", 60, [
        ex("Barbell Back Squat", 4, 5, 180, "Start 70% 1RM, add 2.5lb/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Below parallel, brace core, knees track toes", "Leg Press"),
        ex("Romanian Deadlift", 3, 10, 90, "60-70% DL 1RM", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hip hinge, feel hamstring stretch", "Dumbbell RDL"),
        ex("Leg Press", 3, 10, 90, "Heavy", "Leg Press", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, feet shoulder width", "Hack Squat"),
        ex("Leg Curl", 3, 10, 45, "Moderate weight", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Full ROM, squeeze at top", "Nordic Curl"),
        ex("Calf Raise", 4, 15, 30, "Standing machine or smith", "Machine", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full stretch at bottom, pause at top", "Seated Calf Raise"),
    ])

def gzclp_t1_squat():
    return wo("GZCLP Squat Day (T1/T2/T3)", "strength", 55, [
        ex("Barbell Back Squat", 5, 3, 180, "T1: Heavy, 85%+ 1RM, last set AMRAP", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "T1 main lift: 5x3, add 5lb/session, AMRAP last set", "Front Squat"),
        ex("Barbell Bench Press", 3, 10, 90, "T2: Moderate, 65-75% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "T2 supplemental: 3x10, lighter volume work", "Dumbbell Bench Press"),
        ex("Lat Pulldown", 3, 15, 45, "T3: Light, isolation work", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "T3 assistance: 3x15+, last set max reps", "Pull-Up"),
    ])

def gzclp_t1_bench():
    return wo("GZCLP Bench Day (T1/T2/T3)", "strength", 55, [
        ex("Barbell Bench Press", 5, 3, 180, "T1: Heavy, 85%+ 1RM, last set AMRAP", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "T1 main lift: 5x3, add 2.5lb/session, AMRAP last set", "Dumbbell Bench Press"),
        ex("Barbell Back Squat", 3, 10, 90, "T2: Moderate, 65-75% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "T2 supplemental: 3x10, lighter volume", "Front Squat"),
        ex("Dumbbell Row", 3, 15, 45, "T3: Light, each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "T3 assistance: 3x15+, last set max reps", "Cable Row"),
    ])

def nsuns_531_day():
    return wo("nSuns 5/3/1 Bench + OHP", "strength", 70, [
        ex("Barbell Bench Press", 9, 3, 120, "Sets of 8,6,4,4,4,5,6,7,8+ AMRAP at varying %", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "9 sets ramping weight: 65-95% 1RM, last set AMRAP", "Dumbbell Bench Press"),
        ex("Overhead Press", 8, 3, 90, "T2: Sets of 6,5,3,5,7,4,6,8", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "8 sets at 50-70% OHP 1RM", "Dumbbell Shoulder Press"),
        ex("Dumbbell Incline Press", 3, 10, 45, "Moderate, assistance work", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Accessory: hypertrophy rep range", "Incline Push-Up"),
        ex("Lat Pulldown", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Accessory for back balance", "Pull-Up"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Shoulder health accessory", "Band Pull-Apart"),
    ])

def nsuns_531_squat():
    return wo("nSuns 5/3/1 Squat + Sumo DL", "strength", 70, [
        ex("Barbell Back Squat", 9, 3, 120, "Sets of 5,3,1,3,3,3,5,3,5+ AMRAP at varying %", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "advanced", "9 sets ramping: 75-95% 1RM, last set AMRAP", "Front Squat"),
        ex("Sumo Deadlift", 8, 3, 90, "T2: Sets of 5,5,3,5,7,4,6,8", "Barbell", "Legs", "Glutes", ["Hip Adductors", "Hamstrings", "Quadriceps"], "intermediate", "T2 at 50-70% DL 1RM", "Conventional Deadlift"),
        ex("Leg Press", 3, 12, 60, "Moderate, accessory work", "Leg Press", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Accessory volume", "Hack Squat"),
        ex("Leg Curl", 3, 12, 45, "Moderate weight", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Hamstring balance", "Nordic Curl"),
        ex("Calf Raise", 4, 15, 30, "Standing or seated", "Machine", "Legs", "Calves", [], "beginner", "Full ROM, daily calf work", "Seated Calf Raise"),
    ])

def ivysaur_448():
    return wo("Ivysaur 4-4-8 Day A", "strength", 45, [
        ex("Barbell Bench Press", 4, 4, 120, "Heavy, 80-85% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "4x4 heavy bench day, linear progression", "Dumbbell Bench Press"),
        ex("Barbell Back Squat", 4, 8, 120, "Moderate, 65-70% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "4x8 volume squat, alternates with 4x4", "Goblet Squat"),
        ex("Barbell Row", 4, 8, 90, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "4x8, alternates with chin-ups", "Dumbbell Row"),
    ])

def greyskull_lp():
    return wo("Greyskull LP Day A", "strength", 40, [
        ex("Overhead Press", 3, 5, 120, "Last set AMRAP, add 2.5lb/session", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "2x5 + 1x5+ AMRAP, deload if fail", "Dumbbell Shoulder Press"),
        ex("Barbell Row", 3, 5, 120, "Last set AMRAP", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "2x5 + 1x5+ AMRAP", "Dumbbell Row"),
        ex("Barbell Back Squat", 3, 5, 180, "Last set AMRAP, add 2.5lb/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "2x5 + 1x5+ AMRAP, every session", "Goblet Squat"),
    ])

def reddit_beginner_routine():
    return wo("Reddit Beginner Routine A", "strength", 45, [
        ex("Barbell Back Squat", 3, 5, 180, "Start with bar, add 5lb/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "beginner", "Learn form first, linear progression", "Goblet Squat"),
        ex("Barbell Bench Press", 3, 5, 120, "Start light, add 2.5lb/session", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Touch chest, press up, linear progress", "Dumbbell Bench Press"),
        ex("Barbell Row", 3, 5, 120, "Start light, add 2.5lb/session", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "45 degree torso, pull to belly", "Dumbbell Row"),
    ])

def fierce_5():
    return wo("Fierce 5 Day A", "strength", 45, [
        ex("Barbell Back Squat", 3, 5, 180, "Linear progression", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, add weight each session", "Leg Press"),
        ex("Barbell Bench Press", 3, 5, 120, "Linear progression", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full ROM, linear progression", "Dumbbell Bench Press"),
        ex("Barbell Row", 3, 5, 90, "Linear progression", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Overhand grip, pull to navel", "Dumbbell Row"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Shoulder health, prehab", "Band Pull-Apart"),
        ex("Cable Crunch", 3, 15, 30, "Moderate cable", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core accessory", "Crunch"),
    ])

def icf_5x5():
    return wo("ICF 5x5 Day A", "strength", 65, [
        ex("Barbell Back Squat", 5, 5, 180, "Add 5lb/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "5x5, every workout, linear progression", "Goblet Squat"),
        ex("Barbell Bench Press", 5, 5, 120, "Add 2.5lb/session", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "5x5, alternates with OHP", "Dumbbell Bench Press"),
        ex("Barbell Row", 5, 5, 90, "Add 2.5lb/session", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "5x5, overhand grip", "Dumbbell Row"),
        ex("Barbell Curl", 3, 8, 60, "Accessory work", "Barbell", "Arms", "Biceps", ["Brachialis"], "beginner", "3x8, direct arm work", "Dumbbell Curl"),
        ex("Tricep Extension", 3, 8, 60, "Cable or dumbbell", "Cable Machine", "Arms", "Triceps", [], "beginner", "3x8, balanced arm work", "Skull Crusher"),
        ex("Cable Crunch", 3, 10, 30, "Moderate cable", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "3x10, core accessory", "Crunch"),
    ])

def candito_lp():
    return wo("Candito LP Upper", "strength", 50, [
        ex("Barbell Bench Press", 4, 6, 120, "Linear progression, moderate load", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Control eccentric, pause at chest", "Dumbbell Bench Press"),
        ex("Barbell Row", 4, 6, 90, "Match bench progression", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Strict form, no kipping", "Dumbbell Row"),
        ex("Overhead Press", 3, 8, 90, "Secondary pressing", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict, no leg drive", "Dumbbell Shoulder Press"),
        ex("Pull-Up", 3, 8, 60, "Bodyweight or weighted", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full ROM, dead hang", "Lat Pulldown"),
        ex("Dumbbell Curl", 3, 10, 30, "Accessory", "Dumbbell", "Arms", "Biceps", [], "beginner", "Controlled, no swinging", "Hammer Curl"),
    ])

def reddit_bwf_rr():
    return wo("Bodyweight Fitness RR", "strength", 50, [
        ex("Pull-Up", 3, 8, 90, "Progress: negatives to full to weighted", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Dead hang, chin over bar, progress with weight", "Lat Pulldown"),
        ex("Dip", 3, 8, 90, "Progress: bench dip to parallel bars", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full ROM, lean forward for chest", "Bench Dip"),
        ex("Bodyweight Squat", 3, 8, 60, "Progress: squat to pistol squat", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, progress to single leg", "Pistol Squat Progression"),
        ex("Inverted Row", 3, 8, 60, "Progress: high angle to horizontal to front lever", "Bodyweight", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Ring or bar, progress angle", "Barbell Row"),
        ex("Push-Up", 3, 8, 60, "Progress: incline to diamond to pseudo planche", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Progress difficulty, never sacrifice form", "Knee Push-Up"),
        ex("Copenhagen Plank", 3, 1, 60, "Hold 15-30 seconds each side", "Bodyweight", "Core", "Hip Adductors", ["Obliques", "Core"], "intermediate", "Side plank with top leg on bench", "Side Plank"),
    ])

def gslp_variant():
    return wo("GSLP Phrak Variant A", "strength", 40, [
        ex("Overhead Press", 3, 5, 120, "2x5 + 1x5+ AMRAP, add 2.5lb/session", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "beginner", "Alternates with bench, last set max reps", "Dumbbell Shoulder Press"),
        ex("Chin-Up", 3, 5, 120, "2x5 + 1x5+ AMRAP, add weight when 3x8", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Alternates with barbell row, AMRAP last set", "Lat Pulldown"),
        ex("Barbell Back Squat", 3, 5, 180, "2x5 + 1x5+ AMRAP, add 5lb/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "beginner", "Every session, AMRAP last set, 10% deload on fail", "Goblet Squat"),
    ])

def coolcicada_ppl_push():
    return wo("Coolcicada PPL Push", "strength", 55, [
        ex("Barbell Bench Press", 4, 5, 120, "Linear progression", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Heavy compound, track weekly progress", "Dumbbell Bench Press"),
        ex("Overhead Press", 3, 8, 90, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, secondary compound", "Dumbbell Shoulder Press"),
        ex("Incline Dumbbell Press", 3, 10, 60, "Moderate", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "30 degrees, full stretch", "Incline Push-Up"),
        ex("Dumbbell Lateral Raise", 3, 12, 30, "Light weight", "Dumbbell", "Shoulders", "Lateral Deltoid", [], "beginner", "Strict form, no momentum", "Cable Lateral Raise"),
        ex("Tricep Pushdown", 3, 12, 30, "Rope attachment", "Cable Machine", "Arms", "Triceps", [], "beginner", "Full extension, squeeze", "Diamond Push-Up"),
        ex("Overhead Tricep Extension", 3, 12, 30, "Cable or dumbbell", "Cable Machine", "Arms", "Triceps", [], "beginner", "Full stretch, full lock", "Skull Crusher"),
    ])

def lyle_mcdonald_gbr():
    return wo("Lyle McDonald GBR Upper", "strength", 55, [
        ex("Barbell Bench Press", 3, 8, 120, "Moderate, RPE 7-8", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Generic bulking: 3x6-8, controlled tempo", "Dumbbell Bench Press"),
        ex("Barbell Row", 3, 8, 90, "Match bench sets", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "3x6-8, flat back, explosive pull", "Dumbbell Row"),
        ex("Overhead Press", 2, 10, 90, "Lighter, higher reps", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "2x10-12, secondary pressing", "Dumbbell Shoulder Press"),
        ex("Lat Pulldown", 2, 10, 60, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "2x10-12, wide grip", "Pull-Up"),
        ex("Barbell Curl", 2, 12, 30, "Moderate weight", "Barbell", "Arms", "Biceps", [], "beginner", "2x12-15, direct arm work", "Dumbbell Curl"),
        ex("Skull Crusher", 2, 12, 30, "EZ bar", "EZ Bar", "Arms", "Triceps", [], "beginner", "2x12-15, balanced arm work", "Tricep Pushdown"),
    ])

def alpha_destiny_novice():
    return wo("AlphaDestiny Novice Upper", "strength", 50, [
        ex("Overhead Press", 4, 6, 120, "Heavy, linear progression", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "4x6, add weight when all sets hit", "Dumbbell Shoulder Press"),
        ex("Weighted Chin-Up", 3, 6, 90, "Add weight progressively", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "3x6, full ROM, belt or chain", "Lat Pulldown"),
        ex("Barbell Curl", 3, 10, 45, "Moderate weight, strict", "Barbell", "Arms", "Biceps", ["Brachialis"], "beginner", "No cheating, controlled", "Dumbbell Curl"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Shoulder health and rear delts", "Band Pull-Apart"),
        ex("Neck Curl", 3, 15, 30, "Light plate", "Weight Plate", "Neck", "Sternocleidomastoid", ["Neck Flexors"], "beginner", "Builds neck mass, signature of this program", "Neck Harness"),
    ])

def phraks_gslp():
    return wo("Phraks GSLP Day B", "strength", 40, [
        ex("Barbell Bench Press", 3, 5, 120, "2x5 + 1x5+ AMRAP, add 2.5lb/session", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Alternates with OHP, AMRAP last set", "Dumbbell Bench Press"),
        ex("Barbell Row", 3, 5, 120, "2x5 + 1x5+ AMRAP", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Alternates with chin-ups, AMRAP last", "Dumbbell Row"),
        ex("Barbell Back Squat", 3, 5, 180, "2x5 + 1x5+ AMRAP, add 5lb/session", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Every session, never skip, AMRAP last", "Goblet Squat"),
    ])

# Helper: make reddit PPL 3-workout array
def make_ppl_workouts(w, dur):
    return [reddit_ppl_push(), reddit_ppl_pull(), reddit_ppl_legs()]

def make_gzclp_workouts(w, dur):
    return [gzclp_t1_squat(), gzclp_t1_bench(), gzclp_t1_squat()]

def make_nsuns_workouts(w, dur):
    return [nsuns_531_day(), nsuns_531_squat(), nsuns_531_day()]

# Cat 59 programs list
cat59_programs = [
    ("Reddit PPL", "Reddit-Famous Programs", [4, 8, 12, 16], [6], "The legendary Metallicadpa PPL: 6-day push/pull/legs twice weekly with linear progression", "High",
     lambda w, t: make_ppl_workouts(w, t)),
    ("GZCLP", "Reddit-Famous Programs", [4, 8, 12, 16], [3, 4], "Tiered GZCLP method with T1 heavy/T2 moderate/T3 light work each session", "High",
     lambda w, t: make_gzclp_workouts(w, t)),
    ("nSuns 5/3/1", "Reddit-Famous Programs", [4, 8, 12, 16], [4, 5, 6], "High volume 5/3/1 variant with 9 working sets per main lift and AMRAP sets", "High",
     lambda w, t: make_nsuns_workouts(w, t)),
    ("Metallicadpa PPL", "Reddit-Famous Programs", [4, 8, 12, 16], [6], "The original Reddit PPL by Metallicadpa - the most recommended beginner PPL", "High",
     lambda w, t: make_ppl_workouts(w, t)),
    ("PHUL", "Reddit-Famous Programs", [4, 8, 12], [4], "Power Hypertrophy Upper Lower: 4-day split mixing heavy and volume work", "Med",
     lambda w, t: [reddit_ppl_push(), reddit_ppl_pull(), reddit_ppl_push(), reddit_ppl_legs()]),
    ("PHAT", "Reddit-Famous Programs", [4, 8, 12], [5], "Power Hypertrophy Adaptive Training: Layne Norton style 5-day power plus hypertrophy", "Med",
     lambda w, t: [reddit_ppl_push(), reddit_ppl_pull(), reddit_ppl_legs(), reddit_ppl_push(), reddit_ppl_pull()]),
    ("Ivysaur 4-4-8", "Reddit-Famous Programs", [4, 8, 12], [3], "Alternating 4x4 heavy and 4x8 volume on compound lifts for balanced progression", "Med",
     lambda w, t: [ivysaur_448(), ivysaur_448(), ivysaur_448()]),
    ("Greyskull LP", "Reddit-Famous Programs", [4, 8, 12], [3], "Greyskull LP with AMRAP last sets and 10% deload protocol for smart progression", "High",
     lambda w, t: [greyskull_lp(), greyskull_lp(), greyskull_lp()]),
    ("Reddit Beginner Routine", "Reddit-Famous Programs", [4, 8, 12], [3], "The r/Fitness basic beginner routine: simple 3x5 linear progression for novices", "High",
     lambda w, t: [reddit_beginner_routine(), reddit_beginner_routine(), reddit_beginner_routine()]),
    ("Fierce 5", "Reddit-Famous Programs", [4, 8, 12], [3], "Fierce 5 beginner program with 5 compound lifts and smart accessory selection", "Med",
     lambda w, t: [fierce_5(), fierce_5(), fierce_5()]),
    ("ICF 5x5", "Reddit-Famous Programs", [4, 8, 12], [3], "Ice Cream Fitness 5x5: StrongLifts with added accessories for balanced development", "Med",
     lambda w, t: [icf_5x5(), icf_5x5(), icf_5x5()]),
    ("Candito LP", "Reddit-Famous Programs", [4, 8, 12], [4], "Candito Linear Program with smart periodization and auto-regulation", "Med",
     lambda w, t: [candito_lp(), candito_lp(), candito_lp(), candito_lp()]),
    ("Reddit bodyweightfitness RR", "Reddit-Famous Programs", [4, 8, 12, 16], [3], "The r/bodyweightfitness Recommended Routine with paired exercises and progressions", "High",
     lambda w, t: [reddit_bwf_rr(), reddit_bwf_rr(), reddit_bwf_rr()]),
    ("GSLP", "Reddit-Famous Programs", [4, 8, 12], [3], "Greyskull LP original: simple A/B alternating with AMRAP finishers", "Med",
     lambda w, t: [greyskull_lp(), greyskull_lp(), greyskull_lp()]),
    ("Coolcicada PPL", "Reddit-Famous Programs", [4, 8, 12, 16], [6], "Coolcicada version of PPL with emphasis on progressive overload and volume", "Med",
     lambda w, t: [coolcicada_ppl_push(), reddit_ppl_pull(), reddit_ppl_legs()]),
    ("Lyle McDonald GBR", "Reddit-Famous Programs", [4, 8, 12], [4], "Lyle McDonald Generic Bulking Routine: upper/lower split optimized for mass gain", "Med",
     lambda w, t: [lyle_mcdonald_gbr(), reddit_ppl_legs(), lyle_mcdonald_gbr(), reddit_ppl_legs()]),
    ("AlphaDestiny Novice", "Reddit-Famous Programs", [4, 8, 12], [4], "AlphaDestiny novice program with overhead press focus and neck training", "Med",
     lambda w, t: [alpha_destiny_novice(), reddit_ppl_legs(), alpha_destiny_novice(), reddit_ppl_legs()]),
    ("Phraks GSLP", "Reddit-Famous Programs", [4, 8, 12], [3], "Phraks variant of Greyskull LP: minimalist 3-exercise A/B split with AMRAP", "High",
     lambda w, t: [phraks_gslp(), gslp_variant(), phraks_gslp()]),
]

print("\n=== CAT 59: REDDIT-FAMOUS PROGRAMS ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat59_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.25: focus = f"Week {w} - Learn: establish lifts, practice form, start light"
            elif p <= 0.50: focus = f"Week {w} - Progress: linear progression, add weight each session"
            elif p <= 0.75: focus = f"Week {w} - Push: handle heavier loads, test AMRAP sets"
            else: focus = f"Week {w} - Peak: test maxes, deload if needed, maintain gains"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

print("\n=== CAT 59 COMPLETE ===")

# ========================================================================
# CAT 60 - GLUTE & BOOTY BUILDING (16)
# ========================================================================

def glute_lab():
    return wo("Glute Lab Session", "strength", 50, [
        ex("Barbell Hip Thrust", 4, 10, 90, "Heavy, use pad, progressive overload", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Back on bench, drive through heels, full extension, squeeze 2s", "Glute Bridge"),
        ex("Barbell Back Squat", 4, 8, 120, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Below parallel, push knees out", "Goblet Squat"),
        ex("Romanian Deadlift", 3, 10, 90, "Moderate barbell", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hip hinge, feel hamstring stretch, glute squeeze at top", "Dumbbell RDL"),
        ex("Cable Pull-Through", 3, 12, 60, "Moderate cable", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hip hinge, squeeze glutes hard at top", "Kettlebell Swing"),
        ex("Banded Lateral Walk", 3, 15, 30, "Each direction, band above knees", "Resistance Band", "Hips", "Gluteus Medius", ["Gluteus Minimus", "Hip Abductors"], "beginner", "Stay low, constant band tension", "Side-Lying Leg Lift"),
        ex("Frog Pump", 3, 20, 30, "Bodyweight or light plate on hips", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hip Adductors"], "beginner", "Soles together, knees out, drive hips up", "Glute Bridge"),
    ])

def strong_curves_advanced():
    return wo("Gluteal Goddess Session", "strength", 55, [
        ex("Barbell Hip Thrust", 4, 8, 90, "Heavy, work to 1.5x bodyweight", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "advanced", "Full hip extension, 2s pause at top", "Glute Bridge"),
        ex("Front Squat", 4, 8, 120, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Upright torso, elbows high, deep squat", "Goblet Squat"),
        ex("Single-Leg Romanian Deadlift", 3, 10, 60, "Each leg, moderate dumbbell", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Core"], "advanced", "Balance, hinge deep, squeeze glute to stand", "Romanian Deadlift"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Each leg, dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Rear foot elevated, deep lunge, glute drive", "Reverse Lunge"),
        ex("Cable Hip Abduction", 3, 15, 30, "Each leg, ankle strap", "Cable Machine", "Hips", "Gluteus Medius", ["Hip Abductors"], "intermediate", "Stand sideways, lift leg to side", "Banded Lateral Walk"),
        ex("Back Extension", 3, 12, 45, "Hold plate or bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "intermediate", "Round up focused on glute contraction", "Reverse Hyperextension"),
    ])

def peach_plan():
    return wo("Peach Plan Lower Body", "strength", 45, [
        ex("Sumo Deadlift", 4, 8, 90, "Wide stance, toes out", "Barbell", "Legs", "Glutes", ["Hip Adductors", "Hamstrings", "Quadriceps"], "intermediate", "Wide stance, drive hips forward, squeeze glutes", "Sumo Squat"),
        ex("Hip Thrust", 4, 12, 60, "Moderate to heavy barbell", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full extension, pause squeeze at top", "Glute Bridge"),
        ex("Walking Lunge", 3, 10, 45, "Each leg, dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, lean slightly forward for glute emphasis", "Reverse Lunge"),
        ex("Cable Kickback", 3, 12, 30, "Each leg, ankle strap", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Full extension, squeeze at top", "Donkey Kick"),
        ex("Abduction Machine", 3, 15, 30, "Moderate weight", "Machine", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Full open, slow close", "Banded Clamshell"),
    ])

def brazilian_butt_lift():
    return wo("Brazilian Booty Workout", "strength", 45, [
        ex("Barbell Hip Thrust", 4, 12, 60, "Moderate to heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Maximum glute squeeze, full extension", "Glute Bridge"),
        ex("Sumo Squat", 3, 15, 45, "Dumbbell held at center", "Dumbbell", "Legs", "Glutes", ["Hip Adductors", "Quadriceps"], "beginner", "Wide stance, deep squat, squeeze at top", "Bodyweight Sumo Squat"),
        ex("Donkey Kick", 3, 15, 30, "Each leg, ankle weight or cable", "Ankle Weights", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "On all fours, kick back to hip height", "Cable Kickback"),
        ex("Fire Hydrant", 3, 15, 30, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lift knee to side, squeeze at top", "Banded Fire Hydrant"),
        ex("Curtsy Lunge", 3, 12, 30, "Each leg, dumbbells", "Dumbbell", "Legs", "Glutes", ["Quadriceps", "Hip Adductors"], "intermediate", "Cross behind, deep lunge, upright torso", "Reverse Lunge"),
        ex("Standing Kickback", 3, 15, 30, "Each leg, cable", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hold support, kick back with control", "Donkey Kick"),
    ])

def glute_bridge_mastery():
    return wo("Glute Bridge Mastery", "strength", 30, [
        ex("Glute Bridge", 3, 20, 30, "Bodyweight, perfect form", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive through heels, 2s squeeze at top", "Hip Raise"),
        ex("Single-Leg Glute Bridge", 3, 12, 30, "Each leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "One leg extended, drive through planted heel", "Glute Bridge"),
        ex("Banded Glute Bridge", 3, 15, 30, "Band above knees", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hip Abductors", "Hamstrings"], "beginner", "Push knees apart against band at top", "Glute Bridge"),
        ex("Elevated Glute Bridge", 3, 15, 30, "Feet on bench or step", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Greater range of motion, deeper stretch", "Glute Bridge"),
        ex("Pulse Glute Bridge", 3, 20, 30, "Small pulses at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Stay at top, small pulses, constant tension", "Glute Bridge Hold"),
    ])

def hip_thrust_specialization():
    return wo("Hip Thrust Specialist", "strength", 45, [
        ex("Barbell Hip Thrust", 5, 8, 120, "Heavy, progressive overload weekly", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "5x8, add 5lb/week, full extension each rep", "Smith Machine Hip Thrust"),
        ex("Single-Leg Hip Thrust", 3, 10, 60, "Each leg, bodyweight or light", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Unilateral work for balance", "Single-Leg Glute Bridge"),
        ex("Banded Hip Thrust", 3, 15, 45, "Band above knees + barbell", "Resistance Band", "Glutes", "Gluteus Maximus", ["Gluteus Medius", "Hamstrings"], "intermediate", "Band forces abduction at top for full glute activation", "Barbell Hip Thrust"),
        ex("Pause Hip Thrust", 3, 8, 60, "3-second pause at top", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Maximal contraction with isometric hold", "Hip Thrust"),
        ex("Feet-Elevated Hip Thrust", 3, 12, 45, "Feet on box, back on bench", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Greater ROM for deeper glute stretch", "Hip Thrust"),
    ])

def booty_band_workout():
    return wo("Booty Band Burn", "strength", 25, [
        ex("Banded Squat", 3, 15, 30, "Band above knees", "Resistance Band", "Legs", "Quadriceps", ["Glutes", "Hip Abductors"], "beginner", "Push knees out against band throughout", "Bodyweight Squat"),
        ex("Banded Glute Bridge", 3, 15, 30, "Band above knees", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hamstrings", "Hip Abductors"], "beginner", "Push knees apart at top", "Glute Bridge"),
        ex("Banded Kickback", 3, 12, 30, "Each leg, band around ankles", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Kick back against band tension", "Donkey Kick"),
        ex("Banded Lateral Walk", 3, 15, 30, "Each direction", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Stay low, wide steps against band", "Side Step"),
        ex("Banded Clamshell", 3, 15, 30, "Each side", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Feet together, open knees against band", "Clamshell"),
        ex("Banded Fire Hydrant", 3, 12, 30, "Each side", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "On all fours, lift knee against resistance", "Fire Hydrant"),
    ])

def glute_sculpt():
    return wo("Glute Sculpt Session", "strength", 40, [
        ex("Hip Thrust", 4, 10, 60, "Moderate to heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full extension, controlled lower", "Glute Bridge"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Each leg, dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot elevated, lean slightly forward", "Reverse Lunge"),
        ex("Cable Pull-Through", 3, 12, 45, "Moderate cable", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hip hinge, squeeze at top", "Kettlebell Swing"),
        ex("Step-Up", 3, 10, 45, "Each leg, moderate box", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Drive through top foot, no push off back", "Walking Lunge"),
        ex("Abduction Machine", 3, 15, 30, "Moderate weight", "Machine", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Full range, slow negative", "Banded Lateral Walk"),
    ])

def squat_booty_builder():
    return wo("Squat Booty Builder", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 120, "Moderate to heavy, ATG if possible", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Ass to grass for maximum glute recruitment", "Goblet Squat"),
        ex("Goblet Squat", 3, 12, 45, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat, elbows between knees", "Bodyweight Squat"),
        ex("Sumo Squat", 3, 15, 45, "Wide stance, dumbbell", "Dumbbell", "Legs", "Glutes", ["Hip Adductors", "Quadriceps"], "beginner", "Wide stance, toes out 45 degrees", "Bodyweight Sumo Squat"),
        ex("Pause Squat", 3, 8, 60, "2-second pause at bottom", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Pause eliminates stretch reflex, pure muscle", "Tempo Squat"),
        ex("Hip Thrust", 3, 12, 60, "Moderate barbell", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Supplement squats with direct glute work", "Glute Bridge"),
    ])

def glute_hamstring_focus():
    return wo("Glute & Hamstring Focus", "strength", 45, [
        ex("Romanian Deadlift", 4, 10, 90, "Moderate to heavy barbell", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Feel the stretch, squeeze glutes at top", "Dumbbell RDL"),
        ex("Hip Thrust", 4, 10, 60, "Heavy barbell", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full hip extension each rep", "Glute Bridge"),
        ex("Lying Leg Curl", 3, 12, 45, "Moderate weight", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Full ROM, squeeze at top", "Nordic Curl"),
        ex("Good Morning", 3, 10, 60, "Light to moderate barbell", "Barbell", "Back", "Erector Spinae", ["Hamstrings", "Glutes"], "intermediate", "Hinge at hips, slight knee bend", "Romanian Deadlift"),
        ex("Reverse Hyperextension", 3, 12, 45, "Bodyweight or light plate", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Erector Spinae"], "intermediate", "Lift legs behind, squeeze at top", "Back Extension"),
    ])

def bubble_butt_challenge():
    return wo("Bubble Butt Challenge", "strength", 35, [
        ex("Glute Bridge", 3, 20, 30, "Bodyweight, add reps daily", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Progressive daily challenge, track reps", "Hip Raise"),
        ex("Sumo Squat", 3, 15, 30, "Bodyweight to dumbbell", "Bodyweight", "Legs", "Glutes", ["Hip Adductors", "Quadriceps"], "beginner", "Wide and deep for maximum glute", "Bodyweight Squat"),
        ex("Donkey Kick", 3, 15, 30, "Each leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "On all fours, kick to hip height", "Cable Kickback"),
        ex("Fire Hydrant", 3, 15, 30, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lift knee to side", "Banded Fire Hydrant"),
        ex("Squat Pulse", 3, 20, 30, "Hold squat, pulse at bottom", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stay in squat, small pulses for burn", "Wall Sit"),
    ])

def thirty_day_glute_challenge():
    return wo("30-Day Glute Challenge", "strength", 30, [
        ex("Hip Thrust", 3, 15, 30, "Start bodyweight, add load weekly", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Add 5 reps every 5 days or add weight", "Glute Bridge"),
        ex("Squat", 3, 15, 30, "Progressive daily increase", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Deep squat, daily rep increase", "Wall Sit"),
        ex("Lunge", 3, 10, 30, "Each leg, increase weekly", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride for glute emphasis", "Reverse Lunge"),
        ex("Donkey Kick", 3, 15, 30, "Each leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Build up reps daily", "Cable Kickback"),
        ex("Clamshell", 3, 15, 30, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Feet together, open knees wide", "Side-Lying Leg Lift"),
    ])

def glute_activation_series():
    return wo("Glute Activation Warm-Up", "strength", 15, [
        ex("Glute Bridge", 2, 15, 20, "Bodyweight, wake up glutes", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze hard at top, feel the glutes fire", "Hip Raise"),
        ex("Clamshell", 2, 15, 20, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Open knees, feel outer glute", "Banded Clamshell"),
        ex("Fire Hydrant", 2, 12, 20, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lift knee, pause at top", "Banded Fire Hydrant"),
        ex("Banded Lateral Walk", 2, 10, 20, "Each direction", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Stay low, constant tension", "Side Step"),
        ex("Bird Dog", 2, 8, 20, "Each side", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Deltoids"], "beginner", "Extend arm and leg, feel glute engage", "Dead Bug"),
    ])

def stairmaster_glute():
    return wo("Stairmaster Glute Session", "cardio", 35, [
        ex("Stairmaster Climb", 1, 1, 0, "20 min moderate pace, level 6-8", "Stairmaster", "Legs", "Glutes", ["Quadriceps", "Calves"], "beginner", "No holding rails, push through heels, squeeze each step", "Step-Up"),
        ex("Stairmaster Skip Step", 1, 1, 0, "5 min skipping every other step", "Stairmaster", "Legs", "Glutes", ["Quadriceps", "Hamstrings"], "intermediate", "Two steps at a time, deep step for glutes", "Stairmaster Climb"),
        ex("Stairmaster Side Step", 1, 1, 0, "3 min each side, lateral stepping", "Stairmaster", "Hips", "Gluteus Medius", ["Hip Abductors", "Quadriceps"], "intermediate", "Turn sideways, step up sideways for outer glute", "Lateral Step-Up"),
        ex("Bodyweight Squat", 2, 15, 30, "Post-stairmaster burnout", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Deep squat finisher after stairmaster", "Wall Sit"),
    ])

def cable_glute_workout():
    return wo("Cable Glute Isolation", "strength", 35, [
        ex("Cable Kickback", 4, 12, 30, "Each leg, ankle strap", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Full extension back, squeeze at top 2s", "Donkey Kick"),
        ex("Cable Hip Abduction", 3, 15, 30, "Each leg, ankle strap, side stance", "Cable Machine", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lift leg to side against cable resistance", "Banded Lateral Walk"),
        ex("Cable Pull-Through", 3, 12, 45, "Moderate weight, rope", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hip hinge, explosive hip drive forward", "Kettlebell Swing"),
        ex("Cable Romanian Deadlift", 3, 10, 45, "Moderate weight", "Cable Machine", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Constant tension throughout ROM", "Dumbbell RDL"),
        ex("Cable Squat", 3, 12, 45, "Face cable, hold handle at chest", "Cable Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Sit back, upright torso, cable counterbalance", "Goblet Squat"),
    ])

def at_home_glute_builder():
    return wo("At-Home Glute Builder", "strength", 30, [
        ex("Glute Bridge", 3, 20, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze 2s at top each rep", "Hip Raise"),
        ex("Single-Leg Glute Bridge", 3, 12, 30, "Each leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Advanced variation, one leg extended", "Glute Bridge"),
        ex("Sumo Squat", 3, 15, 30, "Bodyweight or water jug", "Bodyweight", "Legs", "Glutes", ["Hip Adductors", "Quadriceps"], "beginner", "Wide stance, deep squat", "Bodyweight Squat"),
        ex("Donkey Kick", 3, 15, 30, "Each leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Control the movement", "Fire Hydrant"),
        ex("Clamshell", 3, 15, 30, "Each side, use book as weight", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Feet together, open wide", "Side-Lying Leg Lift"),
        ex("Curtsy Lunge", 3, 10, 30, "Each leg", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Hip Adductors"], "beginner", "Cross behind, deep lunge", "Reverse Lunge"),
    ])

# Cat 60 programs list
cat60_programs = [
    ("Glute Lab", "Glute & Booty Building", [4, 8, 12], [3, 4, 5], "Science-based glute training from Bret Contreras Glute Lab methodology", "High",
     lambda w, t: [glute_lab(), glute_lab(), glute_lab()]),
    ("Strong Curves Advanced", "Glute & Booty Building", [4, 8, 12], [3, 4], "Advanced Gluteal Goddess program from Strong Curves with heavy compound lifts", "High",
     lambda w, t: [strong_curves_advanced(), strong_curves_advanced(), strong_curves_advanced()]),
    ("Peach Plan", "Glute & Booty Building", [4, 8, 12], [3, 4, 5], "Complete peach-building plan with sumo deadlifts, hip thrusts, and cable work", "High",
     lambda w, t: [peach_plan(), peach_plan(), peach_plan()]),
    ("Brazilian Butt Lift", "Glute & Booty Building", [4, 8, 12], [4, 5], "Brazilian-style booty workout with high volume glute isolation and compounds", "High",
     lambda w, t: [brazilian_butt_lift(), brazilian_butt_lift(), brazilian_butt_lift()]),
    ("Glute Bridge Mastery", "Glute & Booty Building", [2, 4, 8], [4, 5, 6], "Master every glute bridge variation from basic to single-leg to banded", "Med",
     lambda w, t: [glute_bridge_mastery(), glute_bridge_mastery(), glute_bridge_mastery()]),
    ("Hip Thrust Specialization", "Glute & Booty Building", [4, 8], [3, 4], "Heavy hip thrust specialization program for maximum glute development", "Med",
     lambda w, t: [hip_thrust_specialization(), hip_thrust_specialization(), hip_thrust_specialization()]),
    ("Booty Band Workout", "Glute & Booty Building", [2, 4, 8], [4, 5], "Complete booty workout using only resistance bands - travel and home friendly", "High",
     lambda w, t: [booty_band_workout(), booty_band_workout(), booty_band_workout()]),
    ("Glute Sculpt", "Glute & Booty Building", [4, 8, 12], [3, 4], "Balanced glute sculpting with compound and isolation movements", "Med",
     lambda w, t: [glute_sculpt(), glute_sculpt(), glute_sculpt()]),
    ("Squat Booty Builder", "Glute & Booty Building", [4, 8, 12], [3, 4], "Squat-centric glute building with multiple squat variations and accessories", "Med",
     lambda w, t: [squat_booty_builder(), squat_booty_builder(), squat_booty_builder()]),
    ("Glute & Hamstring Focus", "Glute & Booty Building", [4, 8, 12], [3, 4], "Posterior chain specialization targeting both glutes and hamstrings", "Med",
     lambda w, t: [glute_hamstring_focus(), glute_hamstring_focus(), glute_hamstring_focus()]),
    ("Bubble Butt Challenge", "Glute & Booty Building", [2, 4, 8], [4, 5, 6], "Daily progressive challenge for building a round, lifted booty from home", "Med",
     lambda w, t: [bubble_butt_challenge(), bubble_butt_challenge(), bubble_butt_challenge()]),
    ("30-Day Glute Challenge", "Glute & Booty Building", [4], [5, 6], "Progressive 30-day challenge with increasing reps and difficulty for glutes", "Med",
     lambda w, t: [thirty_day_glute_challenge(), thirty_day_glute_challenge(), thirty_day_glute_challenge()]),
    ("Glute Activation Series", "Glute & Booty Building", [2, 4], [5, 6, 7], "Wake up dormant glutes with daily activation exercises as warm-up or standalone", "Med",
     lambda w, t: [glute_activation_series(), glute_activation_series(), glute_activation_series()]),
    ("Stairmaster Glute", "Glute & Booty Building", [2, 4, 8], [3, 4, 5], "Stairmaster-focused glute cardio with varied step patterns for shape and burn", "Med",
     lambda w, t: [stairmaster_glute(), stairmaster_glute(), stairmaster_glute()]),
    ("Cable Glute Workout", "Glute & Booty Building", [4, 8, 12], [3, 4], "Gym cable machine isolation workout targeting all three glute muscles", "Med",
     lambda w, t: [cable_glute_workout(), cable_glute_workout(), cable_glute_workout()]),
    ("At-Home Glute Builder", "Glute & Booty Building", [4, 8, 12], [4, 5], "Complete at-home glute program requiring zero equipment", "High",
     lambda w, t: [at_home_glute_builder(), at_home_glute_builder(), at_home_glute_builder()]),
]

print("\n=== CAT 60: GLUTE & BOOTY BUILDING ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat60_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Activate: build mind-muscle connection, learn glute exercises"
            elif p <= 0.66: focus = f"Week {w} - Grow: progressive overload, increase volume and load"
            else: focus = f"Week {w} - Shape: peak volume, advanced variations, sculpt details"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, True, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")
    else: print(f"  FAIL: {prog_name}")

helper.close()
print("\n========================================")
print("=== ALL CATS 53-60 COMPLETE ===")
print("========================================")
