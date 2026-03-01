#!/usr/bin/env python3
"""Generate programs for categories 32-42: Posture, Sedentary, Occupation, Cardio,
Strongman, Outdoor, Longevity, GLP-1, Balance, Hybrid, Competition."""
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
# CAT 32 - POSTURE CORRECTION (12 programs)
# ========================================================================

def posture_fix_fundamentals():
    return wo("Posture Fix Fundamentals", "corrective", 30, [
        ex("Chin Tuck", 3, 15, 30, "Hold 5 seconds each", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Sternocleidomastoid", "Scalenes"], "beginner", "Draw chin straight back, make double chin, hold", "Supine Chin Tuck"),
        ex("Wall Angel", 3, 12, 30, "Slow controlled movement", "Bodyweight", "Shoulders", "Lower Trapezius", ["Rhomboids", "Serratus Anterior"], "beginner", "Back flat on wall, slide arms up and down", "Floor Angel"),
        ex("Thoracic Extension on Foam Roller", 2, 10, 30, "Hold 3 seconds at top", "Foam Roller", "Back", "Thoracic Erectors", ["Rhomboids"], "beginner", "Roller at mid-back, extend over it gently", "Towel Roll Extension"),
        ex("Band Pull-Apart", 3, 15, 30, "Light resistance band", "Resistance Band", "Shoulders", "Rear Deltoids", ["Rhomboids", "Middle Trapezius"], "beginner", "Arms straight, pull band to chest level", "Reverse Fly"),
        ex("Cat-Cow", 2, 12, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Inhale arch, exhale round, slow rhythm", "Seated Cat-Cow"),
        ex("Dead Bug", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Low back pressed to floor, extend opposite arm and leg", "Bent-Knee Dead Bug"),
        ex("Prone Y-T-W Raise", 2, 8, 30, "Each position", "Bodyweight", "Back", "Lower Trapezius", ["Rhomboids", "Rotator Cuff"], "beginner", "Face down, raise arms in Y then T then W shape", "Standing Y-T-W with Band"),
    ])

def text_neck_reversal():
    return wo("Text Neck Reversal", "corrective", 20, [
        ex("Chin Tuck", 3, 15, 30, "Hold 5 seconds", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Scalenes"], "beginner", "Retract chin, lengthen back of neck", "Supine Chin Tuck"),
        ex("Neck Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Sternocleidomastoid", ["Scalenes", "Upper Trapezius"], "beginner", "Gently tilt head to side, slight rotation", "Seated Neck Stretch"),
        ex("Upper Trapezius Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Upper Trapezius", ["Levator Scapulae"], "beginner", "Tilt ear to shoulder, gently press with hand", "Levator Scapulae Stretch"),
        ex("Thoracic Foam Roll Extension", 2, 10, 30, "Pause at tight spots", "Foam Roller", "Back", "Thoracic Erectors", ["Rhomboids"], "beginner", "Roll mid-back, extend over roller", "Towel Roll"),
        ex("Scapular Retraction", 3, 15, 30, "Squeeze and hold 3 sec", "Bodyweight", "Back", "Rhomboids", ["Middle Trapezius"], "beginner", "Pull shoulder blades together and down", "Band Retraction"),
        ex("Doorway Chest Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arms on doorframe at 90 degrees, lean forward", "Floor Chest Opener"),
    ])

def rounded_shoulders_fix():
    return wo("Rounded Shoulders Fix", "corrective", 30, [
        ex("Pec Minor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Chest", "Pectoralis Minor", ["Anterior Deltoid"], "beginner", "Arm on wall at 120 degrees, rotate body away", "Doorway Stretch"),
        ex("Band Pull-Apart", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rear Deltoids", ["Rhomboids", "Middle Trapezius"], "beginner", "Pull band apart at chest height, squeeze back", "Reverse Fly"),
        ex("Face Pull", 3, 15, 45, "Cable or band at face height", "Cable Machine", "Shoulders", "Rear Deltoids", ["External Rotators", "Middle Trapezius"], "beginner", "Pull to face, rotate hands outward at end", "Band Face Pull"),
        ex("Wall Slide", 3, 12, 30, "Slow and controlled", "Bodyweight", "Shoulders", "Serratus Anterior", ["Lower Trapezius", "Rotator Cuff"], "beginner", "Back to wall, slide arms up maintaining contact", "Floor Slide"),
        ex("Prone I-Y-T Raise", 3, 8, 30, "Light or no weight", "Bodyweight", "Back", "Lower Trapezius", ["Rhomboids", "Rear Deltoids"], "beginner", "Face down on bench, raise arms in each position", "Standing Band I-Y-T"),
        ex("Seated Row", 3, 12, 45, "Focus on retraction", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Squeeze shoulder blades at end, pause 2 sec", "Band Row"),
    ])

def full_body_alignment():
    return wo("Full Body Alignment", "corrective", 40, [
        ex("Chin Tuck", 3, 12, 30, "Hold 5 seconds", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Scalenes"], "beginner", "Retract chin straight back", "Supine Chin Tuck"),
        ex("Wall Angel", 3, 12, 30, "Full range of motion", "Bodyweight", "Shoulders", "Lower Trapezius", ["Serratus Anterior", "Rhomboids"], "beginner", "Back flat on wall, arms slide up", "Floor Angel"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Psoas"], "beginner", "Half-kneeling, push hips forward, squeeze glute", "Standing Hip Flexor Stretch"),
        ex("Glute Bridge", 3, 15, 30, "Squeeze at top 3 seconds", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive through heels, full hip extension", "Single-Leg Bridge"),
        ex("Bird Dog", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Erector Spinae", ["Gluteus Maximus", "Core"], "beginner", "Extend opposite arm and leg, keep hips level", "Quadruped Arm Lift"),
        ex("Side-Lying Clamshell", 3, 15, 30, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip External Rotators"], "beginner", "Feet together, open knees like clamshell", "Banded Clamshell"),
        ex("Plank", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Obliques"], "beginner", "Straight line head to heels, engage everything", "Forearm Plank"),
        ex("Thoracic Rotation", 2, 10, 0, "Each side", "Bodyweight", "Back", "Obliques", ["Thoracic Erectors", "Rhomboids"], "beginner", "Side-lying, open top arm and rotate", "Seated Thoracic Rotation"),
    ])

def forward_head_fix():
    return wo("Forward Head Fix", "corrective", 20, [
        ex("Deep Neck Flexor Activation", 3, 12, 30, "Hold 5 seconds each", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Longus Colli"], "beginner", "Lie on back, gently nod chin without lifting head", "Chin Tuck"),
        ex("Suboccipital Release", 2, 1, 0, "Hold 60 seconds", "Tennis Ball", "Neck", "Suboccipitals", ["Upper Trapezius"], "beginner", "Two balls at base of skull, gently rest head on them", "Manual Neck Massage"),
        ex("Levator Scapulae Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Levator Scapulae", ["Upper Trapezius"], "beginner", "Look into armpit, gently pull head down", "Upper Trap Stretch"),
        ex("Prone Cobra", 3, 10, 30, "Hold 5 seconds each rep", "Bodyweight", "Back", "Lower Trapezius", ["Rhomboids", "Rear Deltoids"], "beginner", "Face down, lift chest, externally rotate arms, squeeze back", "Superman"),
        ex("Band Retraction", 3, 15, 30, "Light resistance", "Resistance Band", "Back", "Rhomboids", ["Middle Trapezius"], "beginner", "Pull band apart, squeeze shoulder blades together", "Cable Face Pull"),
    ])

def apt_fix():
    return wo("APT Fix", "corrective", 30, [
        ex("Hip Flexor Stretch", 3, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris", "Iliacus"], "beginner", "Half-kneeling lunge, squeeze glute, tilt pelvis under", "Standing Hip Flexor Stretch"),
        ex("Glute Bridge", 3, 15, 30, "Posterior tilt at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Tuck tailbone under, squeeze glutes hard at top", "Single-Leg Bridge"),
        ex("Dead Bug", 3, 10, 30, "Slow and controlled", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Press low back into floor throughout", "Bent-Knee Dead Bug"),
        ex("Posterior Pelvic Tilt", 3, 15, 30, "Hold 5 seconds each", "Bodyweight", "Core", "Rectus Abdominis", ["Glutes"], "beginner", "Lying on back, flatten low back to floor by tucking pelvis", "Standing Pelvic Tilt"),
        ex("Plank with Posterior Tilt", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Glutes"], "intermediate", "In plank, tuck tailbone to flatten low back", "Forearm Plank"),
        ex("Quadriceps Foam Roll", 2, 1, 0, "60 seconds each leg", "Foam Roller", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Roll front of thigh, pause on tight spots", "Quad Stretch"),
    ])

def desk_worker_posture():
    return wo("Desk Worker Posture", "corrective", 25, [
        ex("Chin Tuck", 3, 12, 30, "Can do seated at desk", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Scalenes"], "beginner", "Pull chin back, hold 5 seconds", "Supine Chin Tuck"),
        ex("Chest Doorway Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Pectoralis Minor"], "beginner", "Arms on doorframe, lean through gently", "Floor Chest Opener"),
        ex("Seated Thoracic Rotation", 2, 10, 0, "Each side", "Bodyweight", "Back", "Thoracic Erectors", ["Obliques"], "beginner", "Sit tall, rotate to each side with arms crossed", "Standing Rotation"),
        ex("Band Pull-Apart", 3, 15, 30, "Light resistance", "Resistance Band", "Shoulders", "Rear Deltoids", ["Rhomboids", "Middle Trapezius"], "beginner", "Chest height, pull apart and squeeze", "Reverse Fly"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Half-kneeling, lean forward gently", "Standing Hip Flexor Stretch"),
        ex("Glute Bridge", 3, 15, 30, "Squeeze at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Reactivate glutes after sitting all day", "Single-Leg Bridge"),
    ])

def scoliosis_support():
    return wo("Scoliosis Support", "corrective", 30, [
        ex("Side Plank", 2, 1, 30, "Hold 20-30 seconds each side", "Bodyweight", "Core", "Obliques", ["Quadratus Lumborum", "Gluteus Medius"], "beginner", "Focus on weaker side, keep hips stacked", "Modified Side Plank"),
        ex("Cat-Cow", 2, 12, 0, "Slow and deliberate", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Focus on symmetrical movement", "Seated Cat-Cow"),
        ex("Bird Dog", 3, 10, 30, "Each side", "Bodyweight", "Core", "Erector Spinae", ["Gluteus Maximus", "Shoulders"], "beginner", "Keep hips and shoulders level", "Quadruped Arm Lift"),
        ex("Latissimus Dorsi Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Latissimus Dorsi", ["Obliques", "Teres Major"], "beginner", "Side bend with arm overhead, lean away from tight side", "Child's Pose Side Reach"),
        ex("Pallof Press", 3, 10, 30, "Each side", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis", "Rectus Abdominis"], "beginner", "Press out and resist rotation, hold 2 seconds", "Band Pallof Press"),
        ex("Swimming", 3, 15, 30, "Alternating", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Prone, alternate lifting opposite arm and leg", "Superman Hold"),
    ])

def kyphosis_correction():
    return wo("Kyphosis Correction", "corrective", 35, [
        ex("Thoracic Extension on Foam Roller", 3, 10, 30, "Hold extension 3 seconds", "Foam Roller", "Back", "Thoracic Erectors", ["Rhomboids"], "beginner", "Roller at upper back, extend backward over it", "Towel Roll Extension"),
        ex("Face Pull", 3, 15, 45, "External rotate at end", "Cable Machine", "Shoulders", "Rear Deltoids", ["External Rotators", "Lower Trapezius"], "beginner", "Pull high, rotate hands outward", "Band Face Pull"),
        ex("Prone Y Raise", 3, 10, 30, "Light or no weight", "Bodyweight", "Back", "Lower Trapezius", ["Rhomboids"], "beginner", "Face down, raise arms in Y overhead", "Standing Y Raise"),
        ex("Chest Stretch on Foam Roller", 2, 1, 0, "Hold 60 seconds", "Foam Roller", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Lie lengthwise on roller, arms out to sides", "Doorway Stretch"),
        ex("Seated Row", 3, 12, 45, "Squeeze at end 2 seconds", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Middle Trapezius"], "beginner", "Drive elbows back, retract shoulder blades", "Band Row"),
        ex("Prone Cobra Hold", 3, 1, 30, "Hold 15-20 seconds", "Bodyweight", "Back", "Erector Spinae", ["Rear Deltoids", "Rhomboids"], "beginner", "Face down, lift chest, thumbs out, squeeze back", "Superman"),
    ])

def lordosis_fix():
    return wo("Lordosis Fix", "corrective", 30, [
        ex("Hip Flexor Stretch", 3, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Half-kneeling, posterior pelvic tilt, lean forward", "Standing Hip Flexor Stretch"),
        ex("Glute Bridge with Pelvic Tilt", 3, 15, 30, "Tuck pelvis at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze glutes and flatten low back at top", "Single-Leg Bridge"),
        ex("Dead Bug", 3, 10, 30, "Slow alternating", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Maintain low back contact with floor", "Bent-Knee Dead Bug"),
        ex("Reverse Crunch", 3, 12, 30, "Controlled movement", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Curl hips off floor using lower abs", "Knee Tuck"),
        ex("Quadriceps Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Standing or lying, pull heel to glute", "Couch Stretch"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds with posterior tilt", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Glutes"], "beginner", "Tuck pelvis under in plank position", "Forearm Plank"),
    ])

def tech_posture_reset():
    return wo("Tech Posture Reset", "corrective", 20, [
        ex("Chin Tuck", 3, 15, 30, "Hold 5 seconds", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Scalenes"], "beginner", "Pull chin straight back, lengthen neck", "Supine Chin Tuck"),
        ex("Wrist Extensor Stretch", 2, 1, 0, "Hold 30 seconds each hand", "Bodyweight", "Arms", "Wrist Extensors", ["Forearms"], "beginner", "Extend arm, pull fingers down gently", "Wrist Circles"),
        ex("Thoracic Opener", 2, 10, 30, "Each side", "Bodyweight", "Back", "Thoracic Erectors", ["Obliques", "Pectoralis Major"], "beginner", "Side-lying, rotate upper body to open chest", "Seated Rotation"),
        ex("Scapular Wall Slide", 3, 12, 30, "Slow controlled", "Bodyweight", "Shoulders", "Serratus Anterior", ["Lower Trapezius"], "beginner", "Back to wall, slide arms up maintaining wall contact", "Floor Slide"),
        ex("Wrist Flexor Stretch", 2, 1, 0, "Hold 30 seconds each hand", "Bodyweight", "Arms", "Wrist Flexors", ["Forearms"], "beginner", "Extend arm palm up, pull fingers back gently", "Wrist Circles"),
        ex("Upper Trap Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Upper Trapezius", ["Levator Scapulae"], "beginner", "Tilt head to side, gentle pressure with hand", "Neck Rolls"),
    ])

def standing_posture_training():
    return wo("Standing Posture Training", "corrective", 25, [
        ex("Single-Leg Balance", 3, 1, 30, "Hold 30 seconds each side", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "beginner", "Stand tall, lift one foot, maintain alignment", "Balance on Foam Pad"),
        ex("Wall Stand", 3, 1, 30, "Hold 60 seconds", "Bodyweight", "Full Body", "Postural Muscles", ["Core", "Back"], "beginner", "Head, shoulders, butt, heels touch wall", "Standing Posture Check"),
        ex("Calf Raise", 3, 15, 30, "Slow and controlled", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Rise up tall, pause at top, maintain posture", "Seated Calf Raise"),
        ex("Glute Squeeze Drill", 3, 15, 30, "Hold 5 seconds each", "Bodyweight", "Glutes", "Gluteus Maximus", ["Core"], "beginner", "Standing, squeeze glutes hard, maintain tall posture", "Glute Bridge"),
        ex("Toe Yoga", 2, 10, 0, "Each foot", "Bodyweight", "Feet", "Intrinsic Foot Muscles", ["Tibialis Anterior"], "beginner", "Lift big toe while pressing others down, then reverse", "Towel Scrunches"),
        ex("Standing Thoracic Extension", 2, 10, 30, "Arms overhead", "Bodyweight", "Back", "Thoracic Erectors", ["Shoulders"], "beginner", "Reach arms up and slightly back, open chest", "Wall Extension"),
    ])

# Generate Cat 32 programs
cat32_programs = [
    ("Posture Fix Fundamentals", "Posture Correction", [2, 4, 8], [5, 6], "Basic posture correction program for common postural imbalances", "High", False,
     lambda w, t: [posture_fix_fundamentals(), posture_fix_fundamentals(), posture_fix_fundamentals()]),
    ("Text Neck Reversal", "Posture Correction", [1, 2, 4, 8], [7], "Fix forward head posture caused by phone and computer use", "High", False,
     lambda w, t: [text_neck_reversal(), text_neck_reversal(), text_neck_reversal()]),
    ("Rounded Shoulders Fix", "Posture Correction", [2, 4, 8], [5, 6], "Correct upper cross syndrome and rounded shoulders", "High", False,
     lambda w, t: [rounded_shoulders_fix(), rounded_shoulders_fix(), rounded_shoulders_fix()]),
    ("Full Body Alignment", "Posture Correction", [4, 8, 12], [5, 6], "Comprehensive posture correction from head to toe", "High", False,
     lambda w, t: [full_body_alignment(), full_body_alignment(), full_body_alignment()]),
    ("Forward Head Fix", "Posture Correction", [2, 4, 8], [5, 6], "Correct forward head posture with targeted exercises", "Med", False,
     lambda w, t: [forward_head_fix(), forward_head_fix(), forward_head_fix()]),
    ("APT Fix", "Posture Correction", [2, 4, 8], [5, 6], "Fix anterior pelvic tilt with hip flexor and core work", "Med", False,
     lambda w, t: [apt_fix(), apt_fix(), apt_fix()]),
    ("Desk Worker Posture", "Posture Correction", [2, 4, 8], [7], "Daily posture correction for desk and computer workers", "Med", False,
     lambda w, t: [desk_worker_posture(), desk_worker_posture(), desk_worker_posture()]),
    ("Scoliosis Support", "Posture Correction", [4, 8, 12], [4, 5], "Safe exercises for managing scoliosis asymmetry", "Med", False,
     lambda w, t: [scoliosis_support(), scoliosis_support(), scoliosis_support()]),
    ("Kyphosis Correction", "Posture Correction", [4, 8, 12], [5, 6], "Reduce excessive thoracic kyphosis with strengthening and stretching", "Med", False,
     lambda w, t: [kyphosis_correction(), kyphosis_correction(), kyphosis_correction()]),
    ("Lordosis Fix", "Posture Correction", [4, 8, 12], [5, 6], "Correct excessive lumbar lordosis with core and glute activation", "Med", False,
     lambda w, t: [lordosis_fix(), lordosis_fix(), lordosis_fix()]),
    ("Tech Posture Reset", "Posture Correction", [2, 4, 8], [5, 6], "Reset posture damage from technology use including wrists", "Med", False,
     lambda w, t: [tech_posture_reset(), tech_posture_reset(), tech_posture_reset()]),
    ("Standing Posture Training", "Posture Correction", [2, 4, 8], [5, 6], "Improve standing alignment, balance, and proprioception", "Low", False,
     lambda w, t: [standing_posture_training(), standing_posture_training(), standing_posture_training()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat32_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Assessment: identify imbalances and learn corrective positions"
            elif p <= 0.66: focus = f"Week {w} - Correction: strengthen weak muscles, stretch tight ones"
            else: focus = f"Week {w} - Integration: build endurance in corrected positions"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 32 POSTURE CORRECTION COMPLETE ===")

# ========================================================================
# CAT 33 - SEDENTARY/COUCH TO FIT (11 programs)
# ========================================================================

def couch_to_fitness():
    return wo("Couch to Fitness", "general", 25, [
        ex("March in Place", 2, 30, 30, "30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Calves"], "beginner", "Lift knees to hip height, pump arms", "Seated March"),
        ex("Wall Push-Up", 2, 10, 30, "Hands on wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Lean into wall, push back, keep body straight", "Incline Push-Up"),
        ex("Bodyweight Squat to Chair", 2, 10, 30, "Sit and stand", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Lower to chair, stand up using legs not momentum", "Wall Sit"),
        ex("Standing Calf Raise", 2, 12, 30, "Hold support if needed", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Rise on toes, lower slowly", "Seated Calf Raise"),
        ex("Standing Side Leg Raise", 2, 10, 30, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Hold support, lift leg to side, keep trunk still", "Seated Leg Raise"),
        ex("Wall Plank Hold", 2, 1, 30, "Hold 15-20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Hands on wall at angle, hold straight body", "Knee Plank"),
    ])

def sedentary_to_active():
    return wo("Sedentary to Active", "general", 30, [
        ex("Walking in Place", 2, 1, 30, "2 minutes", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Hip Flexors"], "beginner", "Walk in place, gradually increase pace", "Marching"),
        ex("Seated Leg Extension", 2, 12, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Sit tall, extend one leg straight, hold 2 seconds", "Standing Leg Extension"),
        ex("Wall Push-Up", 2, 10, 30, "Slow and controlled", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Hands on wall, lower chest to wall", "Incline Push-Up"),
        ex("Standing Hip Hinge", 2, 10, 30, "Hands on thighs", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "beginner", "Push hips back, slight knee bend, flat back", "Chair Deadlift"),
        ex("Arm Circle", 2, 15, 0, "Forward then backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small circles, gradually increase size", "Shoulder Roll"),
        ex("Standing Crunch", 2, 10, 30, "Each side", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Bring elbow toward opposite knee while standing", "Seated Crunch"),
    ])

def tv_time_workout():
    return wo("TV Time Workout", "general", 20, [
        ex("Seated March", 3, 20, 30, "During commercials", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Sit on edge of couch, march knees up alternating", "Standing March"),
        ex("Couch Tricep Dip", 2, 8, 30, "Hands on couch edge", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid"], "beginner", "Lower body by bending elbows, push back up", "Wall Push-Up"),
        ex("Couch Squat", 2, 10, 30, "Sit to stand", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stand up from couch without using hands, sit back down", "Wall Sit"),
        ex("Seated Leg Raise", 3, 12, 30, "Alternate legs", "Bodyweight", "Core", "Hip Flexors", ["Rectus Abdominis"], "beginner", "Sit on edge, extend one leg straight out, hold", "Knee Raise"),
        ex("Standing Calf Raise", 2, 15, 30, "Behind couch for balance", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Rise up on toes, slow lower", "Seated Calf Raise"),
    ])

def zero_to_hero():
    return wo("Zero to Hero Beginner", "general", 30, [
        ex("Bodyweight Squat", 3, 10, 45, "Full depth if possible", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Push hips back, knees over toes, chest up", "Chair Squat"),
        ex("Incline Push-Up", 3, 8, 45, "Hands on elevated surface", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Lower chest to surface, push back up", "Wall Push-Up"),
        ex("Glute Bridge", 3, 12, 30, "Squeeze at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Drive through heels, lift hips, squeeze glutes", "Hip Thrust"),
        ex("Dead Bug", 2, 8, 30, "Alternate sides", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Back pressed to floor, extend opposite limbs", "Bent-Knee Dead Bug"),
        ex("Band Row", 3, 10, 30, "Light resistance", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull band to ribs, squeeze back muscles", "Doorway Row"),
        ex("Standing Calf Raise", 2, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Rise up on toes, control the lowering", "Seated Calf Raise"),
    ])

def obese_beginner_safe():
    return wo("Obese Beginner Safe Start", "general", 20, [
        ex("Seated March", 2, 20, 30, "Alternate legs", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Sit in sturdy chair, lift knees alternating", "Standing March"),
        ex("Wall Push-Up", 2, 8, 45, "Take your time", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Hands on wall, lean in and push away", "Counter Push-Up"),
        ex("Chair Squat", 2, 8, 45, "Sit to stand", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stand from sturdy chair, sit back slowly", "Wall Sit"),
        ex("Seated Arm Raise", 2, 10, 30, "Alternate arms", "Bodyweight", "Shoulders", "Deltoids", ["Trapezius"], "beginner", "Sit tall, raise one arm at a time overhead", "Standing Arm Raise"),
        ex("Ankle Pump", 2, 15, 0, "Both feet", "Bodyweight", "Legs", "Tibialis Anterior", ["Gastrocnemius"], "beginner", "Seated, point and flex feet to improve circulation", "Calf Raise"),
    ])

def plus_size_beginner():
    return wo("Plus Size Beginner", "general", 25, [
        ex("Supported Squat", 3, 10, 45, "Hold onto something stable", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Hold support, lower as far as comfortable, stand up", "Chair Squat"),
        ex("Wall Push-Up", 3, 10, 30, "Shoulder width apart", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Hands on wall, lower chest toward wall", "Incline Push-Up"),
        ex("Seated Row with Band", 3, 10, 30, "Light resistance", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Sit on floor, band around feet, pull to ribs", "Doorway Row"),
        ex("Standing Side Step", 2, 12, 30, "Each direction", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Step to side, keep low, return to center", "Seated Leg Raise"),
        ex("Modified Plank", 2, 1, 30, "Hold 15-20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "On knees, straight line from head to knees", "Wall Plank"),
    ])

def plus_size_hiit():
    return wo("Plus Size HIIT", "hiit", 25, [
        ex("March in Place", 3, 1, 30, "30 seconds fast", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Calves"], "beginner", "High knees marching, pump arms", "Seated March"),
        ex("Modified Jumping Jack", 3, 12, 30, "Step out instead of jump", "Bodyweight", "Full Body", "Deltoids", ["Quadriceps", "Calves"], "beginner", "Step right, arms up, step back, arms down", "Arm Raise with Step"),
        ex("Chair Squat", 3, 10, 30, "Sit to stand quickly", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Fast sit to stand, control descent", "Wall Sit"),
        ex("Standing Knee Drive", 3, 10, 30, "Each side", "Bodyweight", "Core", "Hip Flexors", ["Obliques", "Quadriceps"], "beginner", "Drive knee up toward chest, arms down to meet", "Seated Knee Raise"),
        ex("Wall Push-Up Tempo", 3, 10, 30, "Fast pace", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Quick push-ups against wall", "Incline Push-Up"),
    ])

def plus_size_cardio():
    return wo("Plus Size Cardio", "cardio", 25, [
        ex("Walking in Place", 3, 1, 30, "2 minutes each bout", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hip Flexors"], "beginner", "Walk in place, swing arms naturally", "Seated March"),
        ex("Step Touch", 3, 1, 30, "1 minute each bout", "Bodyweight", "Legs", "Hip Abductors", ["Calves", "Quadriceps"], "beginner", "Step to side, tap other foot, alternate", "Side Step"),
        ex("Arm Swing March", 2, 1, 30, "1 minute", "Bodyweight", "Full Body", "Deltoids", ["Core", "Hip Flexors"], "beginner", "March with exaggerated arm swings", "Standing March"),
        ex("Low-Impact Toe Tap", 3, 15, 30, "Alternating feet", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves", "Quadriceps"], "beginner", "Tap toes forward alternating, keep moving", "Heel Taps"),
        ex("Standing Bicycle", 2, 10, 30, "Each side", "Bodyweight", "Core", "Obliques", ["Hip Flexors"], "beginner", "Bring elbow to opposite knee while standing", "Seated Bicycle"),
    ])

def plus_size_strength():
    return wo("Plus Size Strength", "strength", 30, [
        ex("Goblet Squat", 3, 10, 45, "Light dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold dumbbell at chest, squat to depth", "Chair Squat"),
        ex("Dumbbell Chest Press", 3, 10, 45, "Lying on bench", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Press dumbbells up from chest, lower slowly", "Incline Push-Up"),
        ex("Dumbbell Row", 3, 10, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "One hand on bench, pull dumbbell to hip", "Band Row"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Seated for support", "Dumbbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Press dumbbells overhead, lower to ears", "Lateral Raise"),
        ex("Glute Bridge", 3, 12, 30, "Can add dumbbell on hips", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Drive through heels, squeeze glutes at top", "Hip Thrust"),
        ex("Plank", 2, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line from head to knees or toes", "Wall Plank"),
    ])

def beginners_journey():
    return wo("Beginner Journey", "general", 30, [
        ex("Bodyweight Squat", 3, 12, 30, "Full range", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Sit back, chest up, knees track toes", "Chair Squat"),
        ex("Push-Up", 3, 8, 30, "Modified if needed", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Lower chest to floor, push back up", "Incline Push-Up"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm, light weight", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to hip, squeeze back", "Band Row"),
        ex("Glute Bridge", 3, 15, 30, "Squeeze at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive hips up, squeeze 2 seconds", "Hip Thrust"),
        ex("Plank", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line, engage core", "Knee Plank"),
        ex("Reverse Lunge", 3, 8, 30, "Alternate legs", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, lower knee toward floor", "Step Back"),
    ])

def couch_potato_recovery():
    return wo("Couch Potato Recovery", "general", 20, [
        ex("Gentle March in Place", 2, 20, 30, "Easy pace", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Calves"], "beginner", "Slow easy march, focus on movement", "Seated March"),
        ex("Arm Reach Overhead", 2, 10, 30, "Alternate arms", "Bodyweight", "Shoulders", "Deltoids", ["Trapezius"], "beginner", "Reach up high, stretch through side body", "Seated Arm Raise"),
        ex("Standing Hip Circle", 2, 8, 0, "Each direction, each leg", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Hip Adductors"], "beginner", "Hold support, make circles with knee", "Seated Hip Circle"),
        ex("Wall Push-Up", 2, 8, 30, "Easy angle", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Light push-up against wall", "Counter Push-Up"),
        ex("Toe Touch Reach", 2, 8, 30, "Alternate sides", "Bodyweight", "Core", "Obliques", ["Hamstrings"], "beginner", "Standing, reach toward opposite toe", "Standing Side Bend"),
    ])

# Generate Cat 33 programs
cat33_programs = [
    ("Couch to Fitness", "Sedentary/Couch to Fit", [2, 4, 8], [3, 4], "Complete beginner program to go from sedentary to active", "High", False,
     lambda w, t: [couch_to_fitness(), couch_to_fitness(), couch_to_fitness()]),
    ("Sedentary to Active", "Sedentary/Couch to Fit", [4, 8, 12], [3, 4], "Progressive activity building for long-term inactive individuals", "High", False,
     lambda w, t: [sedentary_to_active(), sedentary_to_active(), sedentary_to_active()]),
    ("TV Time Workout", "Sedentary/Couch to Fit", [1, 2, 4], [7], "Exercise during TV commercial breaks", "High", False,
     lambda w, t: [tv_time_workout(), tv_time_workout(), tv_time_workout()]),
    ("Zero to Hero Beginner", "Sedentary/Couch to Fit", [4, 8, 12], [3, 4], "Complete transformation from zero fitness to functional strength", "High", False,
     lambda w, t: [zero_to_hero(), zero_to_hero(), zero_to_hero()]),
    ("Obese Beginner Safe Start", "Sedentary/Couch to Fit", [4, 8, 12], [2, 3], "Very low-impact entry point for obese beginners", "High", False,
     lambda w, t: [obese_beginner_safe(), obese_beginner_safe(), obese_beginner_safe()]),
    ("Plus Size Beginner", "Sedentary/Couch to Fit", [2, 4, 8], [3, 4], "Joint-safe starting point for plus size individuals", "High", False,
     lambda w, t: [plus_size_beginner(), plus_size_beginner(), plus_size_beginner()]),
    ("Plus Size HIIT", "Sedentary/Couch to Fit", [2, 4, 8], [3], "Modified high intensity intervals for plus size bodies", "High", False,
     lambda w, t: [plus_size_hiit(), plus_size_hiit(), plus_size_hiit()]),
    ("Plus Size Cardio", "Sedentary/Couch to Fit", [2, 4, 8], [3, 4], "Low-impact cardiovascular conditioning for larger bodies", "High", False,
     lambda w, t: [plus_size_cardio(), plus_size_cardio(), plus_size_cardio()]),
    ("Plus Size Strength", "Sedentary/Couch to Fit", [4, 8, 12], [3, 4], "Progressive strength building for plus size individuals", "High", False,
     lambda w, t: [plus_size_strength(), plus_size_strength(), plus_size_strength()]),
    ("Beginner's Journey", "Sedentary/Couch to Fit", [4, 8, 12], [3, 4], "Structured beginner path from first workout to confident gym-goer", "High", False,
     lambda w, t: [beginners_journey(), beginners_journey(), beginners_journey()]),
    ("Couch Potato Recovery", "Sedentary/Couch to Fit", [2, 4, 8], [3, 4], "Gentle movement recovery for the extremely sedentary", "Med", False,
     lambda w, t: [couch_potato_recovery(), couch_potato_recovery(), couch_potato_recovery()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat33_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Start moving: gentle introduction to exercise"
            elif p <= 0.66: focus = f"Week {w} - Build habit: increase duration and intensity slightly"
            else: focus = f"Week {w} - Progress: add exercises and challenge yourself"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 33 SEDENTARY/COUCH TO FIT COMPLETE ===")

# ========================================================================
# CAT 34 - OCCUPATION-BASED (11 programs)
# ========================================================================

def manual_labor_fitness():
    return wo("Manual Labor Fitness", "strength", 35, [
        ex("Trap Bar Deadlift", 3, 8, 90, "Moderate weight", "Trap Bar", "Legs", "Glutes", ["Hamstrings", "Quadriceps", "Erector Spinae"], "intermediate", "Hips back, chest up, drive through floor", "Dumbbell Deadlift"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy dumbbells, 40 meters", "Dumbbell", "Full Body", "Forearms", ["Trapezius", "Core", "Glutes"], "intermediate", "Tall posture, tight core, brisk walk", "Suitcase Carry"),
        ex("Overhead Press", 3, 8, 60, "Barbell or dumbbells", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Press overhead, lock out, lower controlled", "Dumbbell Press"),
        ex("Pull-Up", 3, 6, 60, "Assisted if needed", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full hang, pull chin over bar", "Lat Pulldown"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Half-kneeling, push hips forward", "Standing Hip Flexor Stretch"),
        ex("Thoracic Foam Roll", 2, 1, 0, "60 seconds", "Foam Roller", "Back", "Thoracic Erectors", ["Rhomboids"], "beginner", "Roll upper back, pause on tight spots", "Thoracic Extension"),
    ])

def hay_bale_conditioning():
    return wo("Hay Bale Conditioning", "functional", 35, [
        ex("Sandbag Clean and Press", 3, 8, 60, "Moderate sandbag", "Sandbag", "Full Body", "Shoulders", ["Glutes", "Core", "Trapezius"], "intermediate", "Pick from ground, lap, clean to shoulders, press overhead", "Dumbbell Clean and Press"),
        ex("Sandbag Carry", 3, 1, 60, "Bear hug carry 40m", "Sandbag", "Full Body", "Core", ["Biceps", "Forearms", "Quadriceps"], "intermediate", "Hug sandbag tight to chest, walk with purpose", "Farmer's Walk"),
        ex("Sandbag Shouldering", 3, 6, 60, "Alternate shoulders", "Sandbag", "Full Body", "Glutes", ["Core", "Shoulders", "Biceps"], "intermediate", "Pick up from ground, heave onto shoulder", "Dumbbell Hang Clean"),
        ex("Sled Push", 3, 1, 60, "40 meters moderate weight", "Sled", "Legs", "Quadriceps", ["Calves", "Core", "Shoulders"], "intermediate", "Low position, drive through legs", "Prowler Push"),
        ex("Tire Flip", 3, 6, 90, "Medium tire", "Tire", "Full Body", "Glutes", ["Hamstrings", "Chest", "Triceps"], "intermediate", "Deadlift position start, drive hips, push over", "Trap Bar Deadlift"),
        ex("Grip Hang", 3, 1, 30, "Hold 30 seconds", "Pull-Up Bar", "Arms", "Forearms", ["Shoulders", "Latissimus Dorsi"], "beginner", "Dead hang, squeeze bar tight, shoulders engaged", "Towel Hang"),
    ])

def trucker_fitness():
    return wo("Trucker Fitness", "general", 30, [
        ex("Bodyweight Squat", 3, 12, 30, "Full depth", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Counter long sitting with squats, full range", "Chair Squat"),
        ex("Push-Up", 3, 10, 30, "On truck step if needed", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Lower chest down, push up, full extension", "Incline Push-Up"),
        ex("Hip Flexor Stretch", 3, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Critical after long drives, lunge position", "Standing Hip Stretch"),
        ex("Band Row", 3, 12, 30, "Attach to door or post", "Resistance Band", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Pull to ribcage, squeeze shoulder blades", "Doorway Row"),
        ex("Calf Raise", 3, 15, 30, "On curb or step", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Important for circulation after sitting", "Seated Calf Raise"),
        ex("Glute Bridge", 3, 12, 30, "Reactivate glutes", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze glutes hard to counter sitting", "Single-Leg Bridge"),
    ])

def office_worker_recovery():
    return wo("Office Worker Recovery", "corrective", 25, [
        ex("Chin Tuck", 3, 12, 30, "Hold 5 seconds each", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Scalenes"], "beginner", "Pull chin back to counter forward head", "Supine Chin Tuck"),
        ex("Doorway Chest Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arms on frame, lean forward gently", "Floor Chest Stretch"),
        ex("Band Pull-Apart", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rear Deltoids", ["Rhomboids"], "beginner", "Pull band apart at chest level", "Reverse Fly"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Half-kneeling, lean forward to open hip", "Standing Hip Flexor Stretch"),
        ex("Glute Bridge", 3, 12, 30, "Reactivate after sitting", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze glutes hard at top", "Single-Leg Bridge"),
        ex("Thoracic Rotation", 2, 10, 0, "Each side", "Bodyweight", "Back", "Thoracic Erectors", ["Obliques"], "beginner", "Open chest by rotating upper body", "Seated Twist"),
    ])

def busy_professional_fitness():
    return wo("Busy Professional Fitness", "strength", 30, [
        ex("Goblet Squat", 3, 10, 45, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Hold dumbbell at chest, squat deep", "Bodyweight Squat"),
        ex("Push-Up", 3, 12, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Chest to floor, full lockout", "Incline Push-Up"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, 2-second squeeze", "Band Row"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Standing or seated", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Press overhead, lower to ears", "Push-Up"),
        ex("Plank", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Tight body, straight line", "Dead Bug"),
    ])

def healthcare_worker_fitness():
    return wo("Healthcare Worker Fitness", "general", 30, [
        ex("Romanian Deadlift", 3, 10, 45, "Dumbbells, moderate", "Dumbbell", "Back", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips, flat back, feel hamstring stretch", "Good Morning"),
        ex("Band Face Pull", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rear Deltoids", ["External Rotators", "Middle Trapezius"], "beginner", "Pull to face, rotate hands out", "Band Pull-Apart"),
        ex("Goblet Squat", 3, 10, 45, "Light to moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Full depth squat, chest up", "Bodyweight Squat"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Counter long shift standing", "Standing Hip Stretch"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Obliques"], "beginner", "Brace core as if lifting a patient", "Dead Bug"),
        ex("Calf Raise", 3, 15, 30, "Slow tempo", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Counter long shifts on feet", "Seated Calf Raise"),
    ])

def construction_worker_recovery():
    return wo("Construction Worker Recovery", "recovery", 25, [
        ex("Thoracic Foam Roll", 2, 1, 0, "60 seconds", "Foam Roller", "Back", "Thoracic Erectors", ["Rhomboids"], "beginner", "Roll upper back to relieve construction strain", "Thoracic Extension"),
        ex("Shoulder Dislocate", 2, 15, 30, "Light band or dowel", "Resistance Band", "Shoulders", "Rotator Cuff", ["Deltoids", "Pectoralis Major"], "beginner", "Wide grip, pass over head and behind back", "Arm Circle"),
        ex("Hip 90/90 Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Glutes", ["Hip Rotators"], "beginner", "Sit with both legs at 90 degrees, rotate between", "Pigeon Stretch"),
        ex("Cat-Cow", 2, 12, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Relieve compression from heavy lifting", "Seated Cat-Cow"),
        ex("Wrist Extensor Stretch", 2, 1, 0, "Hold 30 seconds each hand", "Bodyweight", "Arms", "Wrist Extensors", ["Forearms"], "beginner", "Extend arm, pull fingers down", "Wrist Circles"),
        ex("Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Standing, heel on step, lean forward with flat back", "Seated Hamstring Stretch"),
    ])

def teacher_energy_boost():
    return wo("Teacher Energy Boost", "general", 25, [
        ex("Bodyweight Squat", 3, 12, 30, "Quick pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Counter standing fatigue with squats", "Chair Squat"),
        ex("Push-Up", 3, 10, 30, "Any variation", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range of motion, energize upper body", "Incline Push-Up"),
        ex("Band Row", 3, 12, 30, "Light resistance", "Resistance Band", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Pull to ribs, counter hunching over desk", "Doorway Row"),
        ex("Calf Raise", 3, 15, 30, "Slow and controlled", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Relieve lower leg fatigue from standing", "Seated Calf Raise"),
        ex("Plank", 2, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Build core for better standing posture", "Dead Bug"),
    ])

def chef_body_maintenance():
    return wo("Chef Body Maintenance", "recovery", 25, [
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Open hips after standing at station all day", "Standing Hip Stretch"),
        ex("Calf Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Wall stretch for calves after long shift", "Downward Dog"),
        ex("Shoulder Roll", 2, 15, 0, "Forward and backward", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids", "Rhomboids"], "beginner", "Big circles to release tension from chopping and stirring", "Arm Circle"),
        ex("Wrist Flexor Stretch", 2, 1, 0, "Hold 30 seconds each hand", "Bodyweight", "Arms", "Wrist Flexors", ["Forearms"], "beginner", "Extend arm palm up, pull fingers back", "Wrist Circles"),
        ex("Glute Bridge", 3, 12, 30, "Activate dormant glutes", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top, counter flat floor standing", "Single-Leg Bridge"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Mobilize spine after hunching over prep table", "Seated Cat-Cow"),
    ])

def musician_body_care():
    return wo("Musician Body Care", "corrective", 25, [
        ex("Wrist Extensor Stretch", 2, 1, 0, "Hold 30 seconds each hand", "Bodyweight", "Arms", "Wrist Extensors", ["Forearms"], "beginner", "Crucial for instrumentalists, extend and gently pull", "Wrist Circles"),
        ex("Wrist Flexor Stretch", 2, 1, 0, "Hold 30 seconds each hand", "Bodyweight", "Arms", "Wrist Flexors", ["Forearms"], "beginner", "Palm up, pull fingers back gently", "Wrist Circles"),
        ex("Chin Tuck", 3, 12, 30, "Hold 5 seconds each", "Bodyweight", "Neck", "Deep Cervical Flexors", ["Scalenes"], "beginner", "Counter forward head from reading music", "Supine Chin Tuck"),
        ex("Thoracic Extension", 2, 10, 30, "Seated or standing", "Bodyweight", "Back", "Thoracic Erectors", ["Rhomboids"], "beginner", "Open chest, extend upper back", "Foam Roller Extension"),
        ex("Finger Extensor Exercise", 3, 15, 30, "Spread fingers against band", "Rubber Band", "Arms", "Finger Extensors", ["Forearms"], "beginner", "Place band around fingers, spread apart", "Finger Stretches"),
        ex("Scapular Retraction", 3, 15, 30, "Squeeze and hold", "Bodyweight", "Back", "Rhomboids", ["Middle Trapezius"], "beginner", "Pull shoulder blades together, hold 3 seconds", "Band Pull-Apart"),
    ])

def night_shift_recovery():
    return wo("Night Shift Recovery", "general", 25, [
        ex("Bodyweight Squat", 3, 12, 30, "Energize after night shift", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, chest up, wake up the body", "Chair Squat"),
        ex("Push-Up", 3, 8, 30, "Any variation", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Get blood flowing to upper body", "Incline Push-Up"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Mobilize stiff spine from night shift", "Seated Cat-Cow"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Open hips, counter sitting or standing fatigue", "Standing Hip Stretch"),
        ex("Band Pull-Apart", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rear Deltoids", ["Rhomboids"], "beginner", "Improve posture after slumped night shift", "Reverse Fly"),
        ex("Walking Lunge", 2, 8, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Dynamic movement to boost energy", "Reverse Lunge"),
    ])

# Generate Cat 34 programs
cat34_programs = [
    ("Manual Labor Fitness", "Occupation-Based", [4, 8, 12], [3, 4], "Conditioning program for construction and trades workers", "High", True,
     lambda w, t: [manual_labor_fitness(), manual_labor_fitness(), manual_labor_fitness()]),
    ("Hay Bale Conditioning", "Occupation-Based", [2, 4, 8], [3, 4], "Odd object lifting and carrying for farm and manual work", "High", False,
     lambda w, t: [hay_bale_conditioning(), hay_bale_conditioning(), hay_bale_conditioning()]),
    ("Trucker Fitness", "Occupation-Based", [2, 4, 8], [4, 5], "Health program for long-haul truck drivers", "High", True,
     lambda w, t: [trucker_fitness(), trucker_fitness(), trucker_fitness()]),
    ("Office Worker Recovery", "Occupation-Based", [2, 4, 8], [5, 6], "Reverse the damage of desk work", "Med", False,
     lambda w, t: [office_worker_recovery(), office_worker_recovery(), office_worker_recovery()]),
    ("Busy Professional Fitness", "Occupation-Based", [2, 4, 8], [3, 4], "Time-efficient workouts for busy schedules", "Med", True,
     lambda w, t: [busy_professional_fitness(), busy_professional_fitness(), busy_professional_fitness()]),
    ("Healthcare Worker Fitness", "Occupation-Based", [2, 4, 8], [3, 4], "Fitness program for nurses and healthcare shift workers", "Med", True,
     lambda w, t: [healthcare_worker_fitness(), healthcare_worker_fitness(), healthcare_worker_fitness()]),
    ("Construction Worker Recovery", "Occupation-Based", [2, 4, 8], [3, 4], "Recovery and mobility for construction workers", "Med", False,
     lambda w, t: [construction_worker_recovery(), construction_worker_recovery(), construction_worker_recovery()]),
    ("Teacher Energy Boost", "Occupation-Based", [2, 4, 8], [4, 5], "Energy-boosting workouts for teachers who stand all day", "Med", False,
     lambda w, t: [teacher_energy_boost(), teacher_energy_boost(), teacher_energy_boost()]),
    ("Chef Body Maintenance", "Occupation-Based", [2, 4], [3, 4], "Body maintenance for chefs and kitchen workers", "Med", False,
     lambda w, t: [chef_body_maintenance(), chef_body_maintenance(), chef_body_maintenance()]),
    ("Musician Body Care", "Occupation-Based", [2, 4, 8], [4, 5], "Prevent repetitive strain and posture issues for musicians", "Med", False,
     lambda w, t: [musician_body_care(), musician_body_care(), musician_body_care()]),
    ("Night Shift Recovery", "Occupation-Based", [2, 4, 8], [3, 4], "Fitness program designed for irregular schedule workers", "Low", False,
     lambda w, t: [night_shift_recovery(), night_shift_recovery(), night_shift_recovery()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat34_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: learn movements and build work capacity"
            elif p <= 0.66: focus = f"Week {w} - Build: increase intensity and add job-specific exercises"
            else: focus = f"Week {w} - Perform: peak job readiness and injury prevention"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 34 OCCUPATION-BASED COMPLETE ===")

helper.close()
print("\n=== PART 1 (CATS 32-34) COMPLETE ===")
