#!/usr/bin/env python3
"""Generate programs for Categories 23-31: Mind & Breath, Lift Mobility, Warmup & Cooldown,
Targeted Stretching, Interval/HIIT, Rehab & Recovery, Hell Mode, Dance Fitness, Face & Jaw."""
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
# CAT 23 - MIND & BREATH
# ========================================================================

def breathwork_basics_wo():
    return wo("Breathwork Basics", "mind_body", 20, [
        ex("Diaphragmatic Breathing", 3, 10, 30, "Deep belly breaths", "Bodyweight", "Core", "Diaphragm", ["Intercostals", "Transverse Abdominis"], "beginner", "Hand on belly, expand on inhale, contract on exhale", "Seated Belly Breathing"),
        ex("4-7-8 Breathing", 3, 5, 15, "Inhale 4s, hold 7s, exhale 8s", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Tongue behind upper teeth, exhale through mouth", "Simple Counted Breathing"),
        ex("Box Breathing", 3, 6, 15, "4s inhale, 4s hold, 4s exhale, 4s hold", "Bodyweight", "Core", "Diaphragm", ["Intercostals", "Core"], "beginner", "Equal counts each phase, stay relaxed", "Triangle Breathing"),
        ex("Lion's Breath", 2, 8, 15, "Forceful exhale with tongue out", "Bodyweight", "Face", "Jaw Muscles", ["Throat Muscles", "Core"], "beginner", "Wide mouth, stick tongue out, exhale with force", "Open Mouth Exhale"),
        ex("Alternate Nostril Breathing", 3, 8, 20, "Nadi Shodhana technique", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Ring finger left nostril, thumb right, alternate", "Simple Nostril Breathing"),
        ex("Breath Hold Walk", 2, 4, 30, "Walk while holding breath gently", "Bodyweight", "Full Body", "Diaphragm", ["Legs", "Core"], "beginner", "Gentle hold, walk slowly, resume breathing before strain", "Seated Breath Hold"),
    ])

def mindful_movement_wo():
    return wo("Mindful Movement", "mind_body", 30, [
        ex("Standing Body Scan", 2, 1, 0, "Hold 60 seconds with awareness", "Bodyweight", "Full Body", "Core", ["Legs", "Back"], "beginner", "Scan from feet to head, notice sensations", "Seated Body Scan"),
        ex("Mindful Walking", 2, 1, 0, "3 minutes slow intentional steps", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Feel each step, heel to toe, slow pace", "Standing Weight Shift"),
        ex("Gentle Spinal Wave", 3, 8, 15, "Slow undulation", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Start from pelvis, wave through spine slowly", "Cat-Cow"),
        ex("Shoulder Roll Meditation", 2, 10, 10, "Slow circles with breath", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids", "Rhomboids"], "beginner", "Inhale lift, exhale roll back and down", "Neck Rolls"),
        ex("Hip Circle Flow", 2, 10, 10, "Gentle hip circles each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Core"], "beginner", "Hands on hips, slow circles, feel each position", "Standing Hip Sway"),
        ex("Savasana", 1, 1, 0, "5 minutes total relaxation", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Lie flat, release all tension, breathe naturally", "Seated Meditation"),
    ])

def stress_relief_wo():
    return wo("Stress Relief Movement", "mind_body", 25, [
        ex("Progressive Muscle Relaxation", 2, 1, 0, "Tense and release each group", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Tense 5 seconds, release 10 seconds, notice difference", "Body Scan Relaxation"),
        ex("Tension Release Shake", 2, 1, 0, "30 seconds full body shake", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Shake arms, legs, whole body, let go of tension", "Gentle Bouncing"),
        ex("Child's Pose Breathing", 3, 1, 0, "Hold 60 seconds with deep breath", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, arms forward, breathe into back ribs", "Seated Forward Fold"),
        ex("Neck Release", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes", "Levator Scapulae"], "beginner", "Ear to shoulder, gentle hand pressure, breathe", "Neck Rolls"),
        ex("Legs Up the Wall", 2, 1, 0, "Hold 3 minutes", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Hips close to wall, legs vertical, arms relaxed", "Supine Knees to Chest"),
        ex("Extended Exhale Breathing", 3, 8, 15, "Inhale 4s, exhale 8s", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Double the exhale length, activate parasympathetic", "4-7-8 Breathing"),
    ])

def qigong_basics_wo():
    return wo("Qigong Basics", "mind_body", 35, [
        ex("Standing Meditation (Zhan Zhuang)", 2, 1, 0, "Hold 2 minutes", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Back"], "beginner", "Knees slightly bent, arms as if hugging tree", "Standing Mountain Pose"),
        ex("Lifting the Sky", 3, 8, 10, "Arms rise overhead with breath", "Bodyweight", "Full Body", "Deltoids", ["Core", "Back"], "beginner", "Inhale arms up, exhale float down, gentle movement", "Arm Raises"),
        ex("Carrying the Moon", 3, 8, 10, "Side bend with arm sweep", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi", "Shoulders"], "beginner", "Reach overhead, gentle side bend, return center", "Standing Side Stretch"),
        ex("Pushing Mountains", 3, 8, 10, "Push palms forward with exhale", "Bodyweight", "Arms", "Deltoids", ["Triceps", "Core"], "beginner", "Root feet, push palms away on exhale, draw back on inhale", "Wall Push"),
        ex("Cloud Hands", 3, 8, 0, "Flowing arm circles with weight shift", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hips"], "beginner", "Shift weight side to side, arms circle like clouds", "Arm Circles with Step"),
        ex("Shaking the Tree", 2, 1, 0, "60 seconds gentle bouncing", "Bodyweight", "Full Body", "Calves", ["Quadriceps", "Core"], "beginner", "Gentle bounce on balls of feet, arms loose", "Gentle Bouncing"),
    ])

def body_scan_stretch_wo():
    return wo("Body Scan & Stretch", "mind_body", 25, [
        ex("Seated Body Scan", 1, 1, 0, "3 minutes full scan", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Notice each body part from toes to crown", "Lying Body Scan"),
        ex("Neck Release Sequence", 2, 1, 0, "30 seconds each direction", "Bodyweight", "Neck", "Trapezius", ["Scalenes", "Sternocleidomastoid"], "beginner", "Slow and gentle, breathe into tight spots", "Seated Neck Rolls"),
        ex("Seated Spinal Twist", 2, 1, 0, "30 seconds each side", "Bodyweight", "Back", "Obliques", ["Erector Spinae", "Core"], "beginner", "Sit tall, rotate from mid-back, look over shoulder", "Lying Spinal Twist"),
        ex("Wrist and Hand Stretch", 2, 1, 0, "30 seconds each position", "Bodyweight", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Extend arm, pull fingers back gently", "Prayer Stretch"),
        ex("Seated Figure-4 Stretch", 2, 1, 0, "45 seconds each side", "Bodyweight", "Hips", "Piriformis", ["Gluteus Medius", "Hip Rotators"], "beginner", "Ankle on opposite knee, sit tall, lean forward", "Seated Hip Opener"),
        ex("Closing Meditation", 1, 1, 0, "2 minutes eyes closed", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Notice how body feels after stretching", "Deep Breathing"),
    ])

def meditation_movement_wo():
    return wo("Meditation & Movement", "mind_body", 30, [
        ex("Walking Meditation", 2, 1, 0, "3 minutes slow walking", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Heel-toe, feel the ground, breathe rhythmically", "Standing Meditation"),
        ex("Gentle Sun Salutation", 2, 3, 0, "Slow meditative flow", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "beginner", "One breath per movement, eyes soft", "Half Sun Salutation"),
        ex("Mindful Cat-Cow", 3, 8, 0, "Breath-led movement", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Close eyes, feel each vertebra move", "Seated Cat-Cow"),
        ex("Standing Forward Fold with Breath", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Fold with exhale, micro-bend knees, let gravity work", "Seated Forward Fold"),
        ex("Butterfly Pose Meditation", 2, 1, 0, "Hold 2 minutes", "Bodyweight", "Hips", "Hip Adductors", ["Groin", "Lower Back"], "beginner", "Soles of feet together, breathe into hips", "Seated Wide Leg"),
        ex("Savasana with Body Scan", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Progressive relaxation from toes to head", "Seated Meditation"),
    ])

def box_breathing_workout_wo():
    return wo("Box Breathing Workout", "mind_body", 15, [
        ex("Warm-Up Belly Breathing", 2, 8, 15, "Deep diaphragmatic breaths", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Hand on belly, expand fully on inhale", "Natural Breathing"),
        ex("Box Breathing 4-Count", 4, 6, 10, "4s in, 4s hold, 4s out, 4s hold", "Bodyweight", "Core", "Diaphragm", ["Intercostals", "Core"], "beginner", "Equal counts all four phases", "Triangle Breathing"),
        ex("Box Breathing 6-Count", 3, 5, 10, "6s in, 6s hold, 6s out, 6s hold", "Bodyweight", "Core", "Diaphragm", ["Intercostals", "Core"], "intermediate", "Longer counts for deeper practice", "Box Breathing 4-Count"),
        ex("Breath Retention Walk", 2, 4, 30, "Gentle walk with holds", "Bodyweight", "Full Body", "Diaphragm", ["Legs", "Core"], "beginner", "Walk slowly during hold phase", "Seated Breath Hold"),
        ex("Recovery Breathing", 2, 6, 15, "Natural rhythm restoration", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Let breathing normalize, observe rhythm", "Belly Breathing"),
    ])

def nervous_system_reset_wo():
    return wo("Nervous System Reset", "mind_body", 25, [
        ex("Physiological Sigh", 3, 8, 15, "Double inhale through nose, long exhale mouth", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Two quick nasal inhales, one long mouth exhale", "Extended Exhale"),
        ex("Vagus Nerve Humming", 2, 8, 10, "Hum on exhale", "Bodyweight", "Neck", "Throat Muscles", ["Diaphragm", "Core"], "beginner", "Inhale deeply, hum steadily on exhale, feel vibration", "Bee Breath"),
        ex("Cold Exposure Breathing", 2, 6, 20, "Controlled breathing with cold stimulus", "Bodyweight", "Core", "Diaphragm", ["Full Body"], "intermediate", "Splash cold water on face, control breathing response", "Deep Slow Breathing"),
        ex("Gentle Rocking", 2, 1, 0, "60 seconds rhythmic rocking", "Bodyweight", "Full Body", "Core", ["Back", "Hips"], "beginner", "Lie on back, hug knees, rock gently side to side", "Supine Twist"),
        ex("Legs Up Wall Breathing", 2, 1, 0, "Hold 3 minutes with breath focus", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Legs vertical, breathe into belly, activate rest response", "Supine Knees to Chest"),
        ex("Grounding Body Tap", 2, 1, 0, "60 seconds tapping body", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Tap arms, legs, torso lightly to activate sensory awareness", "Gentle Body Shake"),
    ])

def somatic_release_wo():
    return wo("Somatic Release", "mind_body", 30, [
        ex("Pandiculation Stretch", 3, 6, 15, "Contract, lengthen, release", "Bodyweight", "Full Body", "Core", ["Back", "Shoulders"], "beginner", "Tighten muscle group fully, then slowly release", "Progressive Muscle Relaxation"),
        ex("TRE Tremor Activation", 2, 1, 0, "Hold 90 seconds in wall sit position", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Flexors"], "beginner", "Wall sit until legs tremor, allow shaking", "Standing Shake"),
        ex("Hip Rocking", 3, 10, 10, "Gentle pelvic tilts on back", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Lower Back"], "beginner", "Small movements, explore range, breathe", "Supine Pelvic Tilt"),
        ex("Jaw Release", 2, 8, 10, "Open and release jaw with breath", "Bodyweight", "Face", "Jaw Muscles", ["Neck Muscles"], "beginner", "Open wide with exhale, let jaw hang, massage muscles", "Gentle Jaw Stretch"),
        ex("Psoas Release", 2, 1, 0, "Hold 90 seconds each side", "Bodyweight", "Hips", "Psoas", ["Hip Flexors", "Core"], "beginner", "Constructive rest position, one knee to chest", "Supine Knee to Chest"),
        ex("Full Body Shake-Off", 2, 1, 0, "90 seconds free shaking", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Shake everything, bounce, let sound out if needed", "Gentle Bouncing"),
    ])

def mindful_strength_wo():
    return wo("Mindful Strength", "mind_body", 35, [
        ex("Breath-Synced Squat", 3, 10, 30, "Inhale down, exhale up", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "4 seconds down, 4 seconds up, breath-led", "Wall Sit"),
        ex("Slow Push-Up", 3, 6, 30, "5 seconds down, 5 seconds up", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Ultra slow tempo, breathe continuously", "Knee Push-Up"),
        ex("Single-Leg Balance Hold", 2, 1, 0, "30 seconds each leg with eyes closed", "Bodyweight", "Legs", "Calves", ["Core", "Glutes"], "beginner", "Close eyes, feel micro-adjustments, breathe", "Tree Pose"),
        ex("Plank with Breath Focus", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Breathe smoothly in plank, stay relaxed in face", "Forearm Plank"),
        ex("Mindful Lunge", 3, 8, 20, "Slow step back, slow return", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Feel each phase, breathe with movement", "Step Back"),
        ex("Closing Breath Meditation", 1, 1, 0, "3 minutes seated", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Notice strength in body, observe breath", "Savasana"),
    ])

# Cat 23 generation
cat23_programs = [
    ("Breathwork Basics", "Mind & Breath", [1, 2, 4], [5, 7], "Breath-focused exercises for relaxation, focus, and energy management", "High", lambda w,t: [breathwork_basics_wo(), breathwork_basics_wo(), breathwork_basics_wo()]),
    ("Mindful Movement", "Mind & Breath", [1, 2, 4], [4, 5], "Meditation combined with gentle movement for mind-body connection", "High", lambda w,t: [mindful_movement_wo(), mindful_movement_wo(), mindful_movement_wo()]),
    ("Stress Relief Movement", "Mind & Breath", [1, 2, 4], [4, 5], "Anxiety and stress reduction through targeted movement and breathing", "High", lambda w,t: [stress_relief_wo(), stress_relief_wo(), stress_relief_wo()]),
    ("Qigong Basics", "Mind & Breath", [2, 4, 8], [4, 5], "Chinese energy cultivation through slow mindful movement and breath", "High", lambda w,t: [qigong_basics_wo(), qigong_basics_wo(), qigong_basics_wo()]),
    ("Body Scan & Stretch", "Mind & Breath", [1, 2, 4], [4, 5], "Mindful body scanning combined with targeted stretching", "High", lambda w,t: [body_scan_stretch_wo(), body_scan_stretch_wo(), body_scan_stretch_wo()]),
    ("Meditation & Movement", "Mind & Breath", [1, 2, 4], [5, 7], "Combined meditation and gentle movement practice", "High", lambda w,t: [meditation_movement_wo(), meditation_movement_wo(), meditation_movement_wo()]),
    ("Box Breathing Workout", "Mind & Breath", [1, 2], [7], "Master the 4-4-4-4 box breathing technique used by Navy SEALs", "High", lambda w,t: [box_breathing_workout_wo(), box_breathing_workout_wo(), box_breathing_workout_wo()]),
    ("Nervous System Reset", "Mind & Breath", [1, 2, 4], [5, 7], "Regulate your nervous system through breath and gentle movement", "High", lambda w,t: [nervous_system_reset_wo(), nervous_system_reset_wo(), nervous_system_reset_wo()]),
    ("Somatic Release", "Mind & Breath", [1, 2, 4], [4, 5], "Release stored tension through somatic movement techniques", "High", lambda w,t: [somatic_release_wo(), somatic_release_wo(), somatic_release_wo()]),
    ("Mindful Strength", "Mind & Breath", [1, 2, 4], [4, 5], "Strength training with mindful breath-synced tempo", "High", lambda w,t: [mindful_strength_wo(), mindful_strength_wo(), mindful_strength_wo()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat23_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: learn breathing patterns and gentle movement"
            elif p <= 0.66: focus = f"Week {w} - Build: deepen practice, longer holds"
            else: focus = f"Week {w} - Peak: integrate all techniques, independent practice"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 23 COMPLETE ===\n")

# ========================================================================
# CAT 24 - LIFT MOBILITY
# ========================================================================

def deadlift_mobility_wo():
    return wo("Deadlift Mobility Prep", "mobility", 20, [
        ex("Hip Hinge Pattern Drill", 3, 10, 20, "Dowel on back for feedback", "Bodyweight", "Hips", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Dowel touches head, mid-back, sacrum throughout hinge", "Wall Hip Hinge"),
        ex("Romanian Deadlift Stretch", 2, 8, 20, "Slow eccentric with bodyweight", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Soft knees, push hips back, feel hamstring stretch", "Standing Hamstring Stretch"),
        ex("90/90 Hip Switch", 2, 8, 15, "Alternate hip rotation", "Bodyweight", "Hips", "Hip Rotators", ["Glutes", "Hip Flexors"], "beginner", "Both knees 90 degrees, rotate side to side", "Seated Hip Rotation"),
        ex("Banded Hip Distraction", 2, 1, 0, "Hold 45 seconds each side", "Resistance Band", "Hips", "Hip Flexors", ["Glutes", "Hip Capsule"], "beginner", "Band at hip crease, step away, rock into stretch", "Deep Lunge Hold"),
        ex("Thoracic Extension on Foam Roller", 2, 8, 15, "Roll upper back", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae", "Rhomboids"], "beginner", "Roller at mid-back, arms crossed, extend over roller", "Cat-Cow"),
        ex("Calf and Ankle Mobilization", 2, 10, 15, "Each side", "Bodyweight", "Legs", "Calves", ["Ankle Joint", "Soleus"], "beginner", "Foot on wall, drive knee forward over toes", "Standing Calf Stretch"),
    ])

def squat_mobility_wo():
    return wo("Squat Mobility Prep", "mobility", 20, [
        ex("Ankle Dorsiflexion Mobilization", 3, 10, 15, "Each side, knee over toe", "Bodyweight", "Legs", "Calves", ["Ankle Joint", "Tibialis Anterior"], "beginner", "Foot flat, drive knee forward past toes", "Wall Ankle Stretch"),
        ex("Deep Squat Hold", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Glutes", "Calves"], "beginner", "Elbows push knees out, chest up, heels down", "Goblet Squat Hold"),
        ex("Couch Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Psoas"], "beginner", "Rear knee at wall, front foot flat, squeeze glute", "Half-Kneeling Hip Flexor Stretch"),
        ex("Adductor Rock-Back", 2, 10, 15, "Each side", "Bodyweight", "Hips", "Hip Adductors", ["Groin", "Hamstrings"], "beginner", "Kneel with one leg out, rock back into stretch", "Seated Straddle"),
        ex("Thoracic Rotation", 2, 8, 10, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques", "Rhomboids"], "beginner", "Quadruped position, hand behind head, rotate and open", "Seated Twist"),
        ex("Goblet Squat Prying", 2, 6, 20, "Use light weight to deepen squat", "Dumbbell", "Legs", "Quadriceps", ["Hip Adductors", "Glutes"], "beginner", "Hold dumbbell at chest, sink deep, pry knees open with elbows", "Deep Squat Hold"),
    ])

def bench_press_mobility_wo():
    return wo("Bench Press Mobility", "mobility", 20, [
        ex("Pec Doorway Stretch", 2, 1, 0, "Hold 30 seconds each arm position", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Biceps"], "beginner", "Arm at 90 degrees in doorway, lean through, feel chest open", "Floor Chest Stretch"),
        ex("Shoulder Pass-Through", 3, 10, 15, "Use band or dowel", "Resistance Band", "Shoulders", "Deltoids", ["Rotator Cuff", "Chest"], "beginner", "Wide grip, pass band overhead and behind, keep arms straight", "Wall Slides"),
        ex("Foam Roller Thoracic Extension", 2, 10, 15, "Roll mid-back", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner", "Place roller at mid-back, extend over it, arms overhead", "Cat-Cow"),
        ex("Scapular Wall Slide", 3, 10, 15, "Arms slide up wall", "Bodyweight", "Shoulders", "Serratus Anterior", ["Lower Trapezius", "Rotator Cuff"], "beginner", "Back flat on wall, elbows and wrists on wall, slide up and down", "Floor Y Raise"),
        ex("Band Pull-Apart", 3, 15, 15, "Light resistance", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids", "Middle Trapezius"], "beginner", "Arms straight, pull band apart to chest level, squeeze back", "Prone Y-T-W"),
        ex("Lat Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Latissimus Dorsi", ["Teres Major", "Obliques"], "beginner", "Grab doorframe overhead, lean away, feel lat stretch", "Child's Pose Lat Stretch"),
    ])

def overhead_press_mobility_wo():
    return wo("Overhead Press Mobility", "mobility", 20, [
        ex("Wall Angel", 3, 10, 15, "Slow controlled repetitions", "Bodyweight", "Shoulders", "Lower Trapezius", ["Serratus Anterior", "Rotator Cuff"], "beginner", "Back flat on wall, slide arms up maintaining wall contact", "Floor Angel"),
        ex("Shoulder Flexion Stretch", 2, 1, 0, "Hold 30 seconds each arm", "Bodyweight", "Shoulders", "Latissimus Dorsi", ["Teres Major", "Triceps"], "beginner", "Arm overhead, other hand pulls gently, lean to side", "Doorway Overhead Stretch"),
        ex("Thoracic Foam Roll", 2, 10, 15, "Roll upper to mid back", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae", "Rhomboids"], "beginner", "Arms crossed, roll from shoulder blades to mid-back", "Cat-Cow Extension"),
        ex("Band Dislocate", 3, 10, 15, "Wide grip rotation", "Resistance Band", "Shoulders", "Rotator Cuff", ["Deltoids", "Chest"], "beginner", "Wide grip on band, rotate fully overhead and behind body", "Shoulder Pass-Through"),
        ex("Half-Kneeling Windmill", 2, 6, 15, "Each side, no weight", "Bodyweight", "Shoulders", "Deltoids", ["Obliques", "Core"], "intermediate", "Arm overhead, hinge to side, keep arm vertical", "Standing Side Reach"),
        ex("Prone T-Y-W Raise", 2, 8, 15, "Face down on floor", "Bodyweight", "Shoulders", "Lower Trapezius", ["Rhomboids", "Rear Deltoid"], "beginner", "Lying face down, raise arms in T, Y, W pattern, hold 2 seconds", "Seated Band Pull"),
    ])

def hip_hinge_mobility_wo():
    return wo("Hip Hinge Mobility", "mobility", 20, [
        ex("Wall Hip Hinge", 3, 10, 15, "Butt to wall drill", "Bodyweight", "Hips", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Stand 6 inches from wall, push hips back to touch wall", "Dowel Hip Hinge"),
        ex("Single-Leg RDL Balance", 2, 8, 20, "Each side", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Hinge on one leg, reach hands toward floor", "Kickstand RDL"),
        ex("Hamstring Nerve Floss", 2, 8, 10, "Seated, each leg", "Bodyweight", "Legs", "Hamstrings", ["Sciatic Nerve", "Calves"], "beginner", "Sit on edge of chair, extend one leg, flex and point foot", "Seated Hamstring Stretch"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis", "Hip Rotators"], "beginner", "Front shin angled, back leg straight, square hips", "Figure-4 Stretch"),
        ex("Good Morning Stretch", 3, 10, 15, "Bodyweight only", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings", "Glutes"], "beginner", "Hands behind head, hinge at hips, flat back", "Standing Forward Fold"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Half kneeling, squeeze glute, push hips forward", "Standing Quad Stretch"),
    ])

def ankle_mobility_wo():
    return wo("Ankle Mobility", "mobility", 15, [
        ex("Wall Ankle Stretch", 3, 10, 15, "Each side, knee to wall", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior", "Ankle Joint"], "beginner", "Foot 3-4 inches from wall, drive knee forward over toes", "Standing Calf Stretch"),
        ex("Banded Ankle Distraction", 2, 10, 15, "Each side", "Resistance Band", "Legs", "Ankle Joint", ["Calves", "Tibialis Anterior"], "beginner", "Band around front of ankle, step forward, drive knee over toe", "Wall Ankle Stretch"),
        ex("Calf Foam Roll", 2, 1, 0, "60 seconds each calf", "Foam Roller", "Legs", "Calves", ["Soleus", "Achilles"], "beginner", "Roll slowly, pause on tender spots", "Tennis Ball Calf Roll"),
        ex("Ankle Alphabet", 2, 1, 0, "Full alphabet each foot", "Bodyweight", "Legs", "Ankle Joint", ["Tibialis Anterior", "Peroneals"], "beginner", "Draw letters A to Z with big toe, full range of motion", "Ankle Circles"),
        ex("Single-Leg Calf Raise", 2, 15, 15, "Each side", "Bodyweight", "Legs", "Calves", ["Soleus", "Ankle Stabilizers"], "beginner", "Full range, slow 2 seconds up, 2 seconds down", "Double-Leg Calf Raise"),
    ])

def thoracic_mobility_wo():
    return wo("Thoracic Mobility", "mobility", 20, [
        ex("Foam Roller Thoracic Extension", 3, 8, 15, "Pause at each segment", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner", "Move roller up one vertebra at a time, extend over it", "Cat-Cow Extension"),
        ex("Open Book Rotation", 3, 8, 10, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques", "Rhomboids"], "beginner", "Side-lying, top arm opens like a book, follow with eyes", "Seated Twist"),
        ex("Quadruped T-Spine Rotation", 3, 8, 10, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques", "Shoulders"], "beginner", "Hand behind head, rotate up toward ceiling, return", "Cat-Cow Twist"),
        ex("Thread the Needle", 2, 8, 10, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Rhomboids", "Shoulders"], "beginner", "On all fours, reach one arm under body, rotate", "Seated Twist"),
        ex("Wall Slide with Thoracic Extension", 2, 10, 15, "Keep contact with wall", "Bodyweight", "Shoulders", "Lower Trapezius", ["Thoracic Spine", "Serratus Anterior"], "beginner", "Back to wall, slide arms up maintaining contact", "Floor Angel"),
        ex("Cat-Cow", 2, 10, 0, "Emphasis on thoracic segment", "Bodyweight", "Back", "Erector Spinae", ["Core", "Thoracic Spine"], "beginner", "Focus rounding and extending in upper back", "Seated Cat-Cow"),
    ])

def shoulder_mobility_wo():
    return wo("Shoulder Mobility", "mobility", 20, [
        ex("Shoulder CARs", 3, 5, 10, "Each arm, controlled articular rotations", "Bodyweight", "Shoulders", "Rotator Cuff", ["Deltoids", "Trapezius"], "beginner", "Make largest possible circle, slow and controlled", "Arm Circles"),
        ex("Sleeper Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Shoulders", "Infraspinatus", ["Teres Minor", "Posterior Capsule"], "beginner", "Side-lying, bottom arm at 90, push wrist toward floor", "Cross-Body Shoulder Stretch"),
        ex("Shoulder Pass-Through", 3, 10, 10, "Use dowel or band", "Resistance Band", "Shoulders", "Deltoids", ["Chest", "Rotator Cuff"], "beginner", "Wide grip, pass overhead and behind, keep straight arms", "Wall Slides"),
        ex("Cross-Body Stretch", 2, 1, 0, "Hold 30 seconds each arm", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Infraspinatus", "Rhomboids"], "beginner", "Pull arm across chest, gentle pressure at elbow", "Doorway Stretch"),
        ex("Internal/External Rotation", 2, 10, 10, "Each arm with band", "Resistance Band", "Shoulders", "Rotator Cuff", ["Subscapularis", "Infraspinatus"], "beginner", "Elbow at side, rotate in and out against band", "Towel Internal Rotation"),
        ex("Prone Y-T-W Raise", 2, 8, 15, "Hold each position 2 seconds", "Bodyweight", "Shoulders", "Lower Trapezius", ["Rhomboids", "Rear Deltoid"], "beginner", "Face down, raise arms in Y, T, then W pattern", "Seated Band Pull-Apart"),
    ])

def hip_mobility_flow_wo():
    return wo("Hip Mobility Flow", "mobility", 25, [
        ex("90/90 Hip Switch", 3, 8, 10, "Flow between sides", "Bodyweight", "Hips", "Hip Rotators", ["Glutes", "Hip Flexors"], "beginner", "Sit with both knees at 90, rotate to switch sides", "Seated Hip Rotation"),
        ex("Deep Squat Hold", 2, 1, 30, "Hold 45 seconds", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Glutes", "Adductors"], "beginner", "Elbows push knees out, chest tall, heels down", "Supported Squat"),
        ex("Hip CARs", 2, 5, 10, "Each leg, controlled circles", "Bodyweight", "Hips", "Hip Rotators", ["Glutes", "Hip Flexors"], "beginner", "Stand on one leg, make large slow hip circles", "Hip Circles"),
        ex("Frog Stretch", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Groin", "Hip Flexors"], "beginner", "On all fours, widen knees, rock back gently", "Butterfly Stretch"),
        ex("World's Greatest Stretch", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings"], "beginner", "Lunge, elbow to instep, rotate and reach up", "Spiderman Stretch"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis", "Hip Rotators"], "beginner", "Front shin angled, square hips, fold forward", "Figure-4 Stretch"),
    ])

def wrist_forearm_mobility_wo():
    return wo("Wrist & Forearm Mobility", "mobility", 15, [
        ex("Wrist CARs", 2, 8, 10, "Each wrist, full circles", "Bodyweight", "Arms", "Wrist Flexors", ["Wrist Extensors", "Forearm"], "beginner", "Make slow full circles, maximize range", "Wrist Circles"),
        ex("Prayer Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Arms", "Wrist Flexors", ["Forearm Flexors"], "beginner", "Palms together at chest, press down keeping contact", "Reverse Prayer Stretch"),
        ex("Reverse Prayer Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Arms", "Wrist Extensors", ["Forearm Extensors"], "beginner", "Backs of hands together, push up gently", "Wrist Extensor Stretch"),
        ex("Finger Extension Stretch", 2, 10, 10, "Use rubber band for resistance", "Resistance Band", "Arms", "Finger Extensors", ["Forearm Extensors"], "beginner", "Band around fingers, spread against resistance", "Finger Splay"),
        ex("Forearm Foam Roll", 2, 1, 0, "60 seconds each arm", "Foam Roller", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Roll forearm on foam roller or lacrosse ball", "Self-Massage Forearm"),
    ])

def pre_squat_mobility_wo():
    return wo("Pre-Squat Mobility", "mobility", 15, [
        ex("Ankle Dorsiflexion Drill", 2, 10, 10, "Each side", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Knee to wall drill, track over second toe", "Wall Ankle Stretch"),
        ex("Hip Flexor Stretch", 2, 1, 0, "30 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Half kneeling, squeeze glute, lean forward", "Standing Quad Stretch"),
        ex("Adductor Rock-Back", 2, 8, 10, "Each side", "Bodyweight", "Hips", "Hip Adductors", ["Groin", "Hamstrings"], "beginner", "Side lunge position, rock hips back", "Butterfly Stretch"),
        ex("Goblet Squat Hold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Adductors"], "beginner", "Deep squat, elbows push knees out", "Supported Squat"),
        ex("Glute Activation Bridge", 2, 10, 10, "Squeeze at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive through heels, hold top 2 seconds", "Hip Thrust"),
    ])

def general_lifting_warmup_wo():
    return wo("General Lifting Warmup", "mobility", 15, [
        ex("Jump Rope or Jog in Place", 1, 1, 0, "2 minutes light cardio", "Bodyweight", "Full Body", "Calves", ["Quadriceps", "Core"], "beginner", "Easy pace, get heart rate up slightly", "Jumping Jacks"),
        ex("Arm Circles", 2, 15, 0, "Forward then backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, progressively bigger", "Shoulder Rolls"),
        ex("Leg Swings", 2, 10, 0, "Each leg, front-to-back then side-to-side", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings", "Adductors"], "beginner", "Hold support, controlled swing, increase range", "Walking Knee Hugs"),
        ex("Bodyweight Squat", 2, 10, 15, "Full range warmup", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Controlled tempo, full depth", "Air Squat"),
        ex("Cat-Cow", 2, 8, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round, move spine fully", "Seated Spinal Wave"),
        ex("Inchworm", 2, 5, 15, "Walk hands out to plank and back", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Keep legs straight, walk out, walk back", "Standing Forward Fold"),
    ])

def olympic_lift_mobility_wo():
    return wo("Olympic Lift Mobility", "mobility", 25, [
        ex("Overhead Squat with Dowel", 3, 8, 20, "Wide grip, full depth", "Bodyweight", "Full Body", "Quadriceps", ["Shoulders", "Core", "Thoracic Spine"], "intermediate", "Arms locked overhead, sit deep, chest up", "Deep Squat Hold"),
        ex("Snatch Grip Behind Neck Press", 2, 8, 15, "Very light weight or dowel", "Barbell", "Shoulders", "Deltoids", ["Trapezius", "Triceps"], "intermediate", "Wide grip, press from behind neck, control descent", "Overhead Press"),
        ex("Hip Flexor Mobilization", 2, 1, 0, "45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Half kneeling, reach arm overhead, lean forward", "Couch Stretch"),
        ex("Wrist Warm-Up", 2, 10, 0, "Circles and stretches", "Bodyweight", "Arms", "Wrist Flexors", ["Wrist Extensors"], "beginner", "Circles both directions, then extend and flex on floor", "Prayer Stretch"),
        ex("Thoracic Rotation Drill", 2, 8, 10, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques"], "beginner", "Quadruped rotation with reach through", "Thread the Needle"),
        ex("Ankle Mobilization", 2, 10, 10, "Each side", "Bodyweight", "Legs", "Calves", ["Ankle Joint"], "beginner", "Knee over toe wall drill, track second toe", "Standing Calf Stretch"),
    ])

def powerlifting_mobility_wo():
    return wo("Powerlifting Mobility", "mobility", 25, [
        ex("Hip Hinge Drill", 3, 10, 15, "Dowel on back", "Bodyweight", "Hips", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Maintain 3 points of contact: head, mid-back, sacrum", "Wall Hip Hinge"),
        ex("Couch Stretch", 2, 1, 0, "60 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Psoas"], "beginner", "Rear foot elevated on couch/wall, squeeze glute, stay upright", "Half-Kneeling Hip Flexor Stretch"),
        ex("Banded Shoulder Distraction", 2, 1, 0, "30 seconds each position", "Resistance Band", "Shoulders", "Rotator Cuff", ["Deltoids", "Chest"], "beginner", "Band anchored high, face away, let band pull arm back", "Doorway Stretch"),
        ex("Deep Squat Hold with Rotation", 2, 1, 0, "Hold 45 seconds with twists", "Bodyweight", "Full Body", "Quadriceps", ["Thoracic Spine", "Hips"], "beginner", "Deep squat, reach one arm up rotating, alternate", "Squat to Stand"),
        ex("Lat Foam Roll", 2, 1, 0, "60 seconds each side", "Foam Roller", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Side-lying, roller under armpit, roll slowly", "Child's Pose Lat Stretch"),
        ex("Glute Foam Roll", 2, 1, 0, "60 seconds each side", "Foam Roller", "Glutes", "Gluteus Maximus", ["Piriformis"], "beginner", "Sit on roller, cross ankle over knee, roll glute", "Figure-4 Stretch"),
    ])

# Cat 24 generation
cat24_programs = [
    ("Deadlift Mobility Prep", "Lift Mobility", [1, 2, 4], [3, 4], "Hip hinge and hamstring prep for safer, deeper deadlifts", "High", lambda w,t: [deadlift_mobility_wo(), deadlift_mobility_wo(), deadlift_mobility_wo()]),
    ("Squat Mobility Prep", "Lift Mobility", [1, 2, 4], [3, 4], "Ankle, hip, and thoracic prep for better squat depth and form", "High", lambda w,t: [squat_mobility_wo(), squat_mobility_wo(), squat_mobility_wo()]),
    ("Bench Press Mobility", "Lift Mobility", [1, 2, 4], [3, 4], "Shoulder and chest prep for pain-free pressing", "High", lambda w,t: [bench_press_mobility_wo(), bench_press_mobility_wo(), bench_press_mobility_wo()]),
    ("Overhead Press Mobility", "Lift Mobility", [1, 2, 4], [3, 4], "Shoulder and thoracic prep for overhead pressing", "High", lambda w,t: [overhead_press_mobility_wo(), overhead_press_mobility_wo(), overhead_press_mobility_wo()]),
    ("Hip Hinge Mobility", "Lift Mobility", [2, 4], [4, 5], "Perfect your hinge pattern for deadlifts and RDLs", "High", lambda w,t: [hip_hinge_mobility_wo(), hip_hinge_mobility_wo(), hip_hinge_mobility_wo()]),
    ("Ankle Mobility", "Lift Mobility", [1, 2, 4], [5, 6], "Dorsiflexion and stability for squats and athletic performance", "High", lambda w,t: [ankle_mobility_wo(), ankle_mobility_wo(), ankle_mobility_wo()]),
    ("Thoracic Mobility", "Lift Mobility", [1, 2, 4], [5, 6], "Mid-back mobility for better posture and lifting mechanics", "High", lambda w,t: [thoracic_mobility_wo(), thoracic_mobility_wo(), thoracic_mobility_wo()]),
    ("Shoulder Mobility", "Lift Mobility", [1, 2, 4], [5, 6], "Rotator cuff and shoulder capsule mobility for pressing and pulling", "High", lambda w,t: [shoulder_mobility_wo(), shoulder_mobility_wo(), shoulder_mobility_wo()]),
    ("Hip Mobility Flow", "Lift Mobility", [1, 2, 4], [4, 5], "Flowing hip mobility routine for unrestricted lower body movement", "High", lambda w,t: [hip_mobility_flow_wo(), hip_mobility_flow_wo(), hip_mobility_flow_wo()]),
    ("Wrist & Forearm Mobility", "Lift Mobility", [1, 2], [5, 7], "Wrist and forearm prep for lifters and desk workers", "High", lambda w,t: [wrist_forearm_mobility_wo(), wrist_forearm_mobility_wo(), wrist_forearm_mobility_wo()]),
    ("Pre-Squat Mobility", "Lift Mobility", [1, 2, 4], [3, 4], "Quick targeted prep before squatting sessions", "High", lambda w,t: [pre_squat_mobility_wo(), pre_squat_mobility_wo(), pre_squat_mobility_wo()]),
    ("General Lifting Warmup", "Lift Mobility", [1, 2, 4], [3, 4], "All-purpose warmup routine before any lifting session", "High", lambda w,t: [general_lifting_warmup_wo(), general_lifting_warmup_wo(), general_lifting_warmup_wo()]),
    ("Olympic Lift Mobility", "Lift Mobility", [2, 4, 8], [5, 6], "Snatch and clean mobility for overhead and receiving positions", "High", lambda w,t: [olympic_lift_mobility_wo(), olympic_lift_mobility_wo(), olympic_lift_mobility_wo()]),
    ("Powerlifting Mobility", "Lift Mobility", [2, 4, 8], [4, 5], "SBD-focused mobility for squat, bench, and deadlift", "High", lambda w,t: [powerlifting_mobility_wo(), powerlifting_mobility_wo(), powerlifting_mobility_wo()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat24_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: learn movement patterns and assess limitations"
            elif p <= 0.66: focus = f"Week {w} - Build: deeper ranges, longer holds, address weak links"
            else: focus = f"Week {w} - Peak: full range mobility, integrate with lifting movements"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 24 COMPLETE ===\n")

# ========================================================================
# CAT 25 - WARMUP & COOLDOWN
# ========================================================================

def five_min_warmup_wo():
    return wo("5-Min Dynamic Warmup", "warmup", 5, [
        ex("Jumping Jacks", 1, 20, 0, "Get heart rate up", "Bodyweight", "Full Body", "Calves", ["Deltoids", "Core"], "beginner", "Full range arms, light landing", "March in Place"),
        ex("Arm Circles", 1, 10, 0, "Forward then backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, get bigger", "Shoulder Rolls"),
        ex("Leg Swings", 1, 10, 0, "Each leg, front-to-back", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings"], "beginner", "Hold support, controlled swing", "Walking Knee Hug"),
        ex("Bodyweight Squat", 1, 10, 0, "Full range", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Controlled, full depth", "Half Squat"),
        ex("Inchworm", 1, 5, 0, "Walk out and back", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Straight legs, plank at bottom", "Standing Forward Fold"),
    ])

def ten_min_warmup_wo():
    return wo("10-Min Full Warmup", "warmup", 10, [
        ex("Light Jog in Place", 1, 1, 0, "60 seconds easy pace", "Bodyweight", "Full Body", "Calves", ["Quadriceps", "Core"], "beginner", "Easy pace, get blood flowing", "March in Place"),
        ex("Arm Circles", 2, 10, 0, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Progressive range", "Shoulder Rolls"),
        ex("Leg Swings Front/Back", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings", "Glutes"], "beginner", "Hold support, controlled", "Walking Knee Hug"),
        ex("Leg Swings Side-to-Side", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Adductors", ["Hip Abductors"], "beginner", "Cross midline, open wide", "Lateral Lunge"),
        ex("Inchworm to Push-Up", 1, 5, 0, "Walk out, push-up, walk back", "Bodyweight", "Full Body", "Chest", ["Hamstrings", "Core"], "beginner", "Smooth flow through movement", "Inchworm"),
        ex("World's Greatest Stretch", 1, 4, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings"], "beginner", "Lunge, rotate, reach", "Spiderman Stretch"),
        ex("High Knees", 1, 20, 0, "Quick pace", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees up, pump arms", "March in Place"),
    ])

def strength_warmup_wo():
    return wo("Strength Training Warmup", "warmup", 10, [
        ex("Light Cardio", 1, 1, 0, "2 minutes jumping jacks or jog", "Bodyweight", "Full Body", "Calves", ["Quadriceps", "Core"], "beginner", "Easy pace, elevate heart rate", "March in Place"),
        ex("Band Pull-Apart", 2, 15, 10, "Light band", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids", "Trapezius"], "beginner", "Chest up, squeeze shoulder blades", "Prone Y Raise"),
        ex("Bodyweight Squat", 2, 10, 10, "Full range", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Controlled depth, prep knees and hips", "Goblet Squat"),
        ex("Push-Up", 1, 8, 10, "Controlled tempo", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, activate pressing muscles", "Knee Push-Up"),
        ex("Glute Bridge", 2, 10, 10, "Squeeze at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive through heels, hold 2 seconds at top", "Hip Thrust"),
        ex("Cat-Cow", 2, 8, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Spinal Wave"),
    ])

def cardio_warmup_wo():
    return wo("Cardio Warmup", "warmup", 8, [
        ex("March in Place", 1, 1, 0, "60 seconds", "Bodyweight", "Legs", "Hip Flexors", ["Calves", "Core"], "beginner", "High knees, pump arms", "Walking"),
        ex("Leg Swings", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings"], "beginner", "Front-to-back controlled swing", "Walking Knee Hug"),
        ex("Calf Raises", 1, 15, 0, "Warm up calves", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Full range, slow and controlled", "Ankle Circles"),
        ex("Butt Kicks", 1, 20, 0, "Light jogging with heel to glute", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Calves"], "beginner", "Heel touches glute each step", "March in Place"),
        ex("Arm Swings", 1, 10, 0, "Cross body and open wide", "Bodyweight", "Chest", "Pectoralis Major", ["Deltoids"], "beginner", "Hug self then open wide, alternate arm on top", "Arm Circles"),
    ])

def sports_warmup_wo():
    return wo("Sports Warmup", "warmup", 10, [
        ex("Light Jog", 1, 1, 0, "2 minutes", "Bodyweight", "Full Body", "Calves", ["Quadriceps"], "beginner", "Easy pace to elevate temperature", "March in Place"),
        ex("High Knees", 1, 20, 0, "Drive knees up", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Quick feet, pump arms", "March in Place"),
        ex("Butt Kicks", 1, 20, 0, "Quick pace", "Bodyweight", "Legs", "Hamstrings", ["Calves", "Glutes"], "beginner", "Heel to glute each rep", "Jogging"),
        ex("Lateral Shuffle", 1, 10, 0, "Each direction", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Low stance, quick feet, push off", "Side Steps"),
        ex("Carioca", 1, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Rotators", ["Core", "Calves"], "intermediate", "Cross behind, cross in front, quick rhythm", "Lateral Shuffle"),
        ex("Dynamic Lunge with Twist", 1, 5, 0, "Each side", "Bodyweight", "Legs", "Quadriceps", ["Core", "Obliques"], "beginner", "Step into lunge, rotate torso over front knee", "Walking Lunge"),
    ])

def dynamic_warmup_series_wo():
    return wo("Dynamic Warmup Series", "warmup", 10, [
        ex("Jumping Jacks", 1, 25, 0, "Moderate pace", "Bodyweight", "Full Body", "Calves", ["Deltoids"], "beginner", "Full arm range, light landing", "Step Jacks"),
        ex("Walking Knee Hugs", 1, 10, 0, "Alternate legs walking", "Bodyweight", "Hips", "Glutes", ["Hip Flexors", "Core"], "beginner", "Hug knee to chest, stand tall", "Standing Knee Hug"),
        ex("Walking Quad Pull", 1, 10, 0, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute while walking, stand tall", "Standing Quad Stretch"),
        ex("Inchworm", 1, 5, 0, "Walk out and back", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Legs straight, walk hands to plank", "Forward Fold"),
        ex("A-Skip", 1, 10, 0, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Calves", "Core"], "beginner", "Drive knee up with skip, opposite arm", "High Knees"),
        ex("Lateral Lunge", 1, 8, 0, "Alternate sides", "Bodyweight", "Legs", "Hip Adductors", ["Quadriceps", "Glutes"], "beginner", "Step wide, sit back on one leg, push back", "Side Step"),
    ])

def post_workout_cooldown_wo():
    return wo("Post-Workout Cool Down", "cooldown", 10, [
        ex("Easy Walk", 1, 1, 0, "2 minutes easy walking", "Bodyweight", "Full Body", "Calves", ["Quadriceps"], "beginner", "Slow pace, bring heart rate down", "Standing in Place"),
        ex("Standing Quad Stretch", 1, 1, 0, "30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, stand tall", "Lying Quad Stretch"),
        ex("Standing Hamstring Stretch", 1, 1, 0, "30 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Foot on low surface, lean forward from hips", "Seated Forward Fold"),
        ex("Chest Doorway Stretch", 1, 1, 0, "30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm in doorway, lean through, feel chest open", "Floor Chest Stretch"),
        ex("Cross-Body Shoulder Stretch", 1, 1, 0, "30 seconds each arm", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Rhomboids"], "beginner", "Pull arm across chest", "Behind Back Stretch"),
        ex("Child's Pose", 1, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, reach forward, breathe deeply", "Puppy Pose"),
    ])

def active_recovery_wo():
    return wo("Active Recovery", "recovery", 30, [
        ex("Easy Walk", 1, 1, 0, "5 minutes light walking", "Bodyweight", "Full Body", "Calves", ["Quadriceps"], "beginner", "Very easy pace, enjoy the movement", "Standing Gentle Sway"),
        ex("Foam Roll Full Body", 1, 1, 0, "5 minutes targeting tight areas", "Foam Roller", "Full Body", "Full Body", [], "beginner", "Slow rolling, pause on tight spots, breathe", "Self-Massage"),
        ex("Cat-Cow", 2, 10, 0, "Gentle spinal flow", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Slow and controlled, breathe deeply", "Seated Cat-Cow"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Knees to side, look opposite, relax into it", "Seated Twist"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis"], "beginner", "Square hips, fold forward gently", "Figure-4 Stretch"),
        ex("Deep Breathing", 2, 8, 0, "Belly breathing to finish", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "4 seconds in, 6 seconds out, total relaxation", "Natural Breathing"),
    ])

def office_break_warmup_wo():
    return wo("Office Break Warmup", "warmup", 5, [
        ex("Seated Neck Rolls", 1, 8, 0, "Each direction", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Slow circles, ear to shoulder, chin to chest", "Neck Side Stretch"),
        ex("Shoulder Shrugs", 1, 15, 0, "Up and release", "Bodyweight", "Shoulders", "Trapezius", ["Levator Scapulae"], "beginner", "Shrug to ears, hold 2 seconds, drop", "Shoulder Rolls"),
        ex("Seated Spinal Twist", 1, 1, 0, "15 seconds each side", "Bodyweight", "Back", "Obliques", ["Erector Spinae"], "beginner", "Sit tall, rotate from mid-back", "Standing Twist"),
        ex("Standing Chest Opener", 1, 1, 0, "Hold 20 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Clasp hands behind back, open chest", "Doorway Stretch"),
        ex("Standing Calf Raise", 1, 15, 0, "Quick pump", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Full range up on toes, quick tempo", "Heel Walks"),
    ])

def morning_mobility_wo():
    return wo("Morning Mobility", "mobility", 10, [
        ex("Cat-Cow", 2, 8, 0, "Wake up the spine", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Slow, feel each vertebra", "Seated Cat-Cow"),
        ex("World's Greatest Stretch", 1, 4, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings"], "beginner", "Lunge, rotate, reach to sky", "Spiderman Stretch"),
        ex("Standing Forward Fold", 1, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Ragdoll, nod head yes and no", "Seated Forward Fold"),
        ex("Hip Circle", 1, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Big circles, lubricate joints", "Hip Rotation"),
        ex("Shoulder Roll", 1, 10, 0, "Forward then backward", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Big circles, squeeze at back", "Arm Circles"),
        ex("Deep Breath Stretch", 2, 5, 0, "Arms overhead with breath", "Bodyweight", "Full Body", "Core", ["Shoulders"], "beginner", "Inhale reach up, exhale fold forward", "Standing Side Stretch"),
    ])

def pre_run_warmup_wo():
    return wo("Pre-Run Warmup", "warmup", 8, [
        ex("Brisk Walk", 1, 1, 0, "90 seconds", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Quick walk to start warming up", "March in Place"),
        ex("Leg Swings Front-Back", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings"], "beginner", "Hold wall, swing freely", "Walking Knee Hug"),
        ex("Leg Swings Side-Side", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Adductors", ["Hip Abductors"], "beginner", "Cross midline, open wide", "Lateral Step"),
        ex("Calf Raise", 1, 15, 0, "Both legs", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Full range, prep achilles", "Ankle Circles"),
        ex("A-Skip", 1, 10, 0, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Calves"], "beginner", "Drive knee up, skip rhythm", "High Knees"),
        ex("Strides", 1, 4, 0, "Build to 80% effort over 50 meters", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Gradually build speed, relax at top end", "Light Jog"),
    ])

def pre_swim_warmup_wo():
    return wo("Pre-Swim Warmup", "warmup", 8, [
        ex("Arm Circles", 2, 15, 0, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Progressive range, warm up shoulder joint", "Shoulder Rolls"),
        ex("Shoulder Pass-Through", 2, 10, 0, "With band or towel", "Resistance Band", "Shoulders", "Deltoids", ["Chest", "Rotator Cuff"], "beginner", "Wide grip, full overhead rotation", "Arm Circles"),
        ex("Trunk Rotation", 1, 10, 0, "Each direction", "Bodyweight", "Core", "Obliques", ["Erector Spinae"], "beginner", "Feet planted, rotate upper body", "Seated Twist"),
        ex("Lat Stretch", 1, 1, 0, "30 seconds each side", "Bodyweight", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Reach overhead, lean to side, feel lat", "Child's Pose Stretch"),
        ex("Ankle Circles", 1, 10, 0, "Each direction, each foot", "Bodyweight", "Legs", "Ankle Joint", ["Calves"], "beginner", "Full circles for kick preparation", "Calf Raises"),
        ex("Streamline Stretch", 2, 1, 0, "Hold 15 seconds", "Bodyweight", "Full Body", "Shoulders", ["Core", "Lats"], "beginner", "Arms overhead, biceps by ears, elongate body", "Overhead Reach"),
    ])

# Cat 25 generation
cat25_programs = [
    ("5-Min Dynamic Warmup", "Warmup & Cooldown", [1, 2], [7], "Quick pre-workout activation to prep for any training session", "High", lambda w,t: [five_min_warmup_wo(), five_min_warmup_wo(), five_min_warmup_wo()]),
    ("10-Min Full Warmup", "Warmup & Cooldown", [1, 2, 4], [7], "Complete warmup routine covering all major movement patterns", "High", lambda w,t: [ten_min_warmup_wo(), ten_min_warmup_wo(), ten_min_warmup_wo()]),
    ("Strength Training Warmup", "Warmup & Cooldown", [1, 2, 4], [7], "Pre-lifting warmup to activate muscles and prep joints", "High", lambda w,t: [strength_warmup_wo(), strength_warmup_wo(), strength_warmup_wo()]),
    ("Cardio Warmup", "Warmup & Cooldown", [1, 2], [7], "Pre-run, bike, or HIIT warmup for cardiovascular readiness", "High", lambda w,t: [cardio_warmup_wo(), cardio_warmup_wo(), cardio_warmup_wo()]),
    ("Sports Warmup", "Warmup & Cooldown", [1, 2, 4], [7], "Athletic activation routine for sport performance prep", "High", lambda w,t: [sports_warmup_wo(), sports_warmup_wo(), sports_warmup_wo()]),
    ("Dynamic Warmup Series", "Warmup & Cooldown", [1, 2, 4], [7], "Progressive dynamic stretching series for any workout", "High", lambda w,t: [dynamic_warmup_series_wo(), dynamic_warmup_series_wo(), dynamic_warmup_series_wo()]),
    ("Post-Workout Cool Down", "Warmup & Cooldown", [1, 2, 4], [7], "Essential cooldown stretches after any workout", "High", lambda w,t: [post_workout_cooldown_wo(), post_workout_cooldown_wo(), post_workout_cooldown_wo()]),
    ("Active Recovery", "Warmup & Cooldown", [1, 2, 4], [1, 2], "Light movement days for recovery between hard sessions", "High", lambda w,t: [active_recovery_wo(), active_recovery_wo(), active_recovery_wo()]),
    ("Office Break Warmup", "Warmup & Cooldown", [1, 2], [7], "Quick desk-break mobility to fight sitting stiffness", "High", lambda w,t: [office_break_warmup_wo(), office_break_warmup_wo(), office_break_warmup_wo()]),
    ("Morning Mobility", "Warmup & Cooldown", [1, 2, 4], [7], "Start your day with gentle mobility and blood flow", "High", lambda w,t: [morning_mobility_wo(), morning_mobility_wo(), morning_mobility_wo()]),
    ("Pre-Run Warmup", "Warmup & Cooldown", [1, 2], [7], "Targeted warmup for running and jogging sessions", "High", lambda w,t: [pre_run_warmup_wo(), pre_run_warmup_wo(), pre_run_warmup_wo()]),
    ("Pre-Swim Warmup", "Warmup & Cooldown", [1, 2], [7], "Shoulder and full body warmup before swimming", "High", lambda w,t: [pre_swim_warmup_wo(), pre_swim_warmup_wo(), pre_swim_warmup_wo()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat25_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: learn the warmup/cooldown sequence"
            elif p <= 0.66: focus = f"Week {w} - Build: refine technique and increase range"
            else: focus = f"Week {w} - Peak: full routine mastery, self-directed"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 25 COMPLETE ===\n")

# ========================================================================
# CAT 26 - TARGETED STRETCHING
# ========================================================================

def upper_body_stretch_wo():
    return wo("Upper Body Stretch", "stretching", 20, [
        ex("Neck Side Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes", "Levator Scapulae"], "beginner", "Ear to shoulder, gentle hand pressure", "Neck Rolls"),
        ex("Chest Doorway Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm at 90 in doorway, step through", "Floor Chest Stretch"),
        ex("Cross-Body Shoulder Stretch", 2, 1, 0, "Hold 30 seconds each arm", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Rhomboids"], "beginner", "Pull arm across chest at elbow", "Behind Back Stretch"),
        ex("Triceps Overhead Stretch", 2, 1, 0, "Hold 30 seconds each arm", "Bodyweight", "Arms", "Triceps", ["Latissimus Dorsi"], "beginner", "Reach behind head, pull elbow with other hand", "Towel Shoulder Stretch"),
        ex("Biceps Wall Stretch", 2, 1, 0, "Hold 30 seconds each arm", "Bodyweight", "Arms", "Biceps", ["Anterior Deltoid", "Forearm"], "beginner", "Hand on wall behind, rotate body away", "Doorway Biceps Stretch"),
        ex("Cat-Cow", 2, 8, 0, "Spinal flow", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Inhale arch, exhale round, full range", "Seated Cat-Cow"),
    ])

def lower_body_stretch_wo():
    return wo("Lower Body Stretch", "stretching", 25, [
        ex("Standing Quad Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, keep knees together", "Lying Quad Stretch"),
        ex("Standing Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Foot on low surface, lean forward from hips", "Seated Forward Fold"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Half kneeling, squeeze glute, lean forward", "Standing Hip Flexor Stretch"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis", "Hip Rotators"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Calf Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Calves", ["Soleus", "Achilles"], "beginner", "Wall stretch, straight back leg, heel down", "Step Calf Stretch"),
        ex("Butterfly Stretch", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Groin"], "beginner", "Soles together, elbows push knees gently", "Seated Straddle"),
        ex("Supine Figure-4 Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "Ankle on opposite knee, pull standing leg to chest", "Seated Figure-4"),
    ])

def hip_opener_wo():
    return wo("Hip Opener Series", "stretching", 25, [
        ex("90/90 Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Rotators", ["Glutes", "Hip Flexors"], "beginner", "Front leg 90, back leg 90, sit tall", "Seated Hip Rotation"),
        ex("Frog Stretch", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Groin"], "beginner", "On all fours, wide knees, sink hips back", "Butterfly Stretch"),
        ex("Low Lunge Hold", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Deep lunge, back knee down, sink hips", "Standing Hip Flexor Stretch"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis"], "beginner", "Front shin at angle, back leg long, fold forward", "Figure-4 Stretch"),
        ex("Happy Baby", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Hamstrings", "Lower Back"], "beginner", "On back, grab outer feet, pull knees toward armpits", "Supine Butterfly"),
        ex("Lizard Pose", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Adductors", "Hamstrings"], "intermediate", "Low lunge, both hands inside front foot", "Low Lunge Hold"),
    ])

def shoulder_stretch_wo():
    return wo("Shoulder Stretch Routine", "stretching", 20, [
        ex("Shoulder CARs", 2, 5, 10, "Each arm", "Bodyweight", "Shoulders", "Rotator Cuff", ["Deltoids"], "beginner", "Slow controlled circles, largest range possible", "Arm Circles"),
        ex("Cross-Body Stretch", 2, 1, 0, "Hold 30 seconds each arm", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Infraspinatus"], "beginner", "Pull arm across chest, gentle pressure at elbow", "Thread the Needle"),
        ex("Sleeper Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner", "Side-lying, push wrist toward floor", "Cross-Body Stretch"),
        ex("Doorway Pec Stretch", 2, 1, 0, "Hold 30 seconds each angle", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Try 45, 90, and 135 degree arm positions", "Floor Chest Stretch"),
        ex("Behind Back Clasp", 2, 1, 0, "Hold 30 seconds each way", "Bodyweight", "Shoulders", "Deltoids", ["Chest", "Biceps"], "beginner", "Clasp hands behind back, open chest, switch top hand", "Towel Stretch"),
        ex("Child's Pose with Side Reach", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Latissimus Dorsi", ["Teres Major", "Obliques"], "beginner", "Walk hands to one side, feel lat and side stretch", "Lat Stretch"),
    ])

def hamstring_flexibility_wo():
    return wo("Hamstring Flexibility", "stretching", 20, [
        ex("Standing Forward Fold", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Micro-bend knees, fold from hips, let gravity work", "Seated Forward Fold"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Legs straight, reach for feet, breathe into stretch", "Standing Forward Fold"),
        ex("Supine Hamstring Stretch", 2, 1, 0, "Hold 45 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "On back, pull one leg up straight, use strap if needed", "Seated Single-Leg Stretch"),
        ex("Standing Single-Leg Forward Fold", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves", "Lower Back"], "beginner", "Foot on low surface, hinge forward from hips", "Chair Hamstring Stretch"),
        ex("Downward Dog", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Full Body", "Hamstrings", ["Calves", "Shoulders"], "beginner", "Push floor away, pedal feet, heels toward ground", "Puppy Pose"),
        ex("Lying Leg Cradle", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Hips", "Hamstrings", ["Glutes", "Hip Rotators"], "beginner", "On back, cradle shin to chest, gentle rock", "Supine Knee Hug"),
    ])

def quad_hip_flexor_stretch_wo():
    return wo("Quad & Hip Flexor Stretch", "stretching", 20, [
        ex("Standing Quad Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, knees together, stand tall", "Lying Quad Stretch"),
        ex("Couch Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Psoas"], "intermediate", "Rear foot on couch/wall, squeeze glute, stay upright", "Half-Kneeling Hip Flexor Stretch"),
        ex("Low Lunge Hip Flexor", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Deep lunge, back knee down, squeeze back glute", "Standing Hip Flexor Stretch"),
        ex("Lying Quad Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "On side, pull top heel to glute", "Standing Quad Stretch"),
        ex("Half-Kneeling Quad Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Psoas"], "intermediate", "Back foot on bench, half kneel, lean back", "Couch Stretch"),
        ex("Reclined Hero Pose", 1, 1, 0, "Hold 60 seconds", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Ankles"], "intermediate", "Kneel, lean back on elbows or floor, feel front thigh", "Seated Quad Stretch"),
    ])

def back_flexibility_wo():
    return wo("Back Flexibility", "stretching", 20, [
        ex("Cat-Cow", 3, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Full range, feel each vertebra", "Seated Cat-Cow"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, reach forward, breathe into back", "Puppy Pose"),
        ex("Cobra Stretch", 2, 1, 0, "Hold 20 seconds, repeat", "Bodyweight", "Back", "Erector Spinae", ["Core", "Chest"], "beginner", "Press up gently, shoulders down from ears", "Baby Cobra"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Glutes"], "beginner", "Knees to side, opposite shoulder down, relax", "Seated Twist"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Round forward, let spine hang, breathe", "Standing Forward Fold"),
        ex("Thread the Needle", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Thoracic Spine", ["Shoulders", "Obliques"], "beginner", "On all fours, reach arm under body, rotate", "Open Book"),
    ])

def neck_trap_release_wo():
    return wo("Neck & Trap Release", "stretching", 15, [
        ex("Neck Side Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear to shoulder, gentle hand pressure, breathe", "Neck Rolls"),
        ex("Chin Tuck", 2, 10, 10, "Hold 5 seconds each", "Bodyweight", "Neck", "Deep Neck Flexors", ["Sternocleidomastoid"], "beginner", "Pull chin straight back, double chin position", "Wall Chin Tuck"),
        ex("Levator Scapulae Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Neck", "Levator Scapulae", ["Trapezius"], "beginner", "Look toward armpit, pull gently with hand", "Neck Side Stretch"),
        ex("Trap Squeeze and Release", 2, 8, 10, "Squeeze then release", "Bodyweight", "Shoulders", "Trapezius", ["Rhomboids"], "beginner", "Shrug to ears hard 5 seconds, drop and relax", "Shoulder Shrugs"),
        ex("Suboccipital Release", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Neck", "Suboccipitals", ["Upper Trapezius"], "beginner", "Two fingers at base of skull, gentle pressure upward, nod yes", "Tennis Ball Neck Release"),
    ])

def splits_training_wo():
    return wo("Splits Training", "stretching", 30, [
        ex("Low Lunge Hold", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Sink deep, keep back knee down", "Standing Hip Flexor Stretch"),
        ex("Half Split (Runner's Stretch)", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "From low lunge, straighten front leg, fold forward", "Seated Forward Fold"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis"], "beginner", "Front shin at angle, sink hips evenly", "Figure-4 Stretch"),
        ex("Wide-Leg Forward Fold", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Adductors", "Lower Back"], "beginner", "Legs wide, fold forward from hips", "Seated Straddle"),
        ex("Frog Stretch", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Groin"], "intermediate", "On all fours, knees wide, rock back", "Butterfly Stretch"),
        ex("Supported Front Split", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Legs", "Hamstrings", ["Hip Flexors", "Quadriceps"], "intermediate", "Use blocks for support, slide into split gradually", "Half Split"),
    ])

def it_band_glute_stretch_wo():
    return wo("IT Band & Glute Stretch", "stretching", 20, [
        ex("IT Band Foam Roll", 2, 1, 0, "60 seconds each side", "Foam Roller", "Legs", "IT Band", ["Vastus Lateralis"], "beginner", "Side-lying, roll from hip to knee, pause on tender spots", "Tennis Ball IT Band"),
        ex("Cross-Leg Forward Fold", 2, 1, 0, "Hold 30 seconds each cross", "Bodyweight", "Legs", "IT Band", ["Hamstrings", "Glutes"], "beginner", "Stand, cross one leg behind, fold forward toward back foot", "Standing TFL Stretch"),
        ex("Figure-4 Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "On back, ankle on opposite knee, pull toward chest", "Seated Figure-4"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis", "Hip Rotators"], "beginner", "Square hips, fold forward gently", "Figure-4 Stretch"),
        ex("Seated Glute Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Sit, cross one ankle over knee, lean forward", "Supine Glute Stretch"),
        ex("Standing IT Band Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "IT Band", ["TFL", "Gluteus Medius"], "beginner", "Cross back leg behind, lean away from back leg", "Side-Lying IT Band Stretch"),
    ])

def ankle_flexibility_wo():
    return wo("Ankle Flexibility", "stretching", 15, [
        ex("Wall Ankle Stretch", 3, 10, 10, "Each side", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Knee to wall, track over second toe", "Standing Calf Stretch"),
        ex("Ankle Circles", 2, 10, 0, "Each direction, each foot", "Bodyweight", "Legs", "Ankle Joint", ["Calves", "Peroneals"], "beginner", "Full circles, maximize range", "Ankle Alphabet"),
        ex("Calf Stretch on Step", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Calves", ["Soleus", "Achilles"], "beginner", "Ball of foot on step, drop heel below", "Wall Calf Stretch"),
        ex("Seated Ankle Dorsiflexion", 2, 10, 10, "Pull toes toward shin", "Bodyweight", "Legs", "Tibialis Anterior", ["Ankle Joint"], "beginner", "Use hand or band to pull foot up", "Standing Toe Raise"),
        ex("Toe Yoga", 2, 10, 10, "Lift big toe, then other toes separately", "Bodyweight", "Feet", "Foot Intrinsics", ["Toe Flexors", "Toe Extensors"], "beginner", "Work on independent toe control", "Towel Scrunches"),
    ])

def full_body_flexibility_wo():
    return wo("Full Body Flexibility", "stretching", 30, [
        ex("Neck Stretch", 1, 1, 0, "30 seconds each direction", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Side, forward, and rotation stretches", "Neck Rolls"),
        ex("Chest Opener", 1, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Hands behind back, open chest wide", "Doorway Stretch"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Full spinal range", "Seated Cat-Cow"),
        ex("Standing Forward Fold", 1, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Fold from hips, soft knees if needed", "Seated Forward Fold"),
        ex("Low Lunge Hip Stretch", 1, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas"], "beginner", "Deep lunge, sink hips", "Standing Hip Flexor Stretch"),
        ex("Pigeon Pose", 1, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Piriformis"], "beginner", "Front shin angled, fold forward", "Figure-4 Stretch"),
        ex("Supine Twist", 1, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Knees to side, opposite shoulder down", "Seated Twist"),
    ])

def flexibility_beginners_wo():
    return wo("Flexibility for Beginners", "stretching", 20, [
        ex("Standing Side Stretch", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Reach arm overhead, lean to side gently", "Seated Side Stretch"),
        ex("Standing Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Bend knees as needed, fold forward, relax", "Seated Forward Fold"),
        ex("Seated Butterfly", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Groin"], "beginner", "Soles together, gentle elbow pressure on knees", "Seated Wide Leg"),
        ex("Standing Quad Stretch", 2, 1, 0, "Hold 20 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Hold wall for balance, pull heel to glute", "Lying Quad Stretch"),
        ex("Child's Pose", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Knees wide, arms forward, breathe", "Puppy Pose"),
        ex("Supine Knee to Chest", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Hips", "Glutes", ["Lower Back"], "beginner", "On back, hug one knee to chest, keep other leg flat", "Lying Glute Stretch"),
    ])

def chest_bicep_stretch_wo():
    return wo("Chest & Bicep Stretch", "stretching", 15, [
        ex("Doorway Pec Stretch", 2, 1, 0, "Hold 30 seconds each angle", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Try 45, 90, and 135 degree arm positions in doorway", "Floor Chest Stretch"),
        ex("Floor Chest Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Biceps"], "beginner", "Prone, arm out to side, roll toward opposite side", "Doorway Stretch"),
        ex("Biceps Wall Stretch", 2, 1, 0, "Hold 30 seconds each arm", "Bodyweight", "Arms", "Biceps", ["Anterior Deltoid", "Forearm"], "beginner", "Hand on wall behind, rotate body away", "Doorway Biceps Stretch"),
        ex("Behind Back Clasp", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Biceps"], "beginner", "Hands behind back, lift arms, open chest", "Towel Behind Back Stretch"),
        ex("Supine Chest Opener", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Lie on foam roller lengthwise, arms out to sides, relax", "Floor Angel"),
    ])

# Cat 26 generation
cat26_programs = [
    ("Upper Body Stretch", "Targeted Stretching", [1, 2, 4], [4, 5], "Comprehensive upper body stretching for shoulders, chest, and arms", "High", lambda w,t: [upper_body_stretch_wo()]*3),
    ("Lower Body Stretch", "Targeted Stretching", [1, 2, 4], [4, 5], "Complete lower body stretching for hips, legs, and ankles", "High", lambda w,t: [lower_body_stretch_wo()]*3),
    ("Hip Opener Series", "Targeted Stretching", [1, 2, 4], [4, 5], "Deep hip opening sequence for improved range of motion", "High", lambda w,t: [hip_opener_wo()]*3),
    ("Shoulder Stretch Routine", "Targeted Stretching", [1, 2, 4], [5, 6], "Rotator cuff and shoulder mobility for pain-free movement", "High", lambda w,t: [shoulder_stretch_wo()]*3),
    ("Hamstring Flexibility", "Targeted Stretching", [1, 2, 4], [5, 6], "Targeted hamstring stretching for improved flexibility", "High", lambda w,t: [hamstring_flexibility_wo()]*3),
    ("Quad & Hip Flexor Stretch", "Targeted Stretching", [1, 2, 4], [5, 6], "Quad and hip flexor stretching to counteract sitting", "High", lambda w,t: [quad_hip_flexor_stretch_wo()]*3),
    ("Back Flexibility", "Targeted Stretching", [1, 2, 4], [4, 5], "Spinal mobility and back flexibility for pain relief", "High", lambda w,t: [back_flexibility_wo()]*3),
    ("Neck & Trap Release", "Targeted Stretching", [1, 2, 4], [5, 7], "Neck and upper trapezius tension relief stretches", "High", lambda w,t: [neck_trap_release_wo()]*3),
    ("Splits Training", "Targeted Stretching", [2, 4, 8], [5, 6], "Progressive flexibility program toward front and side splits", "High", lambda w,t: [splits_training_wo()]*3),
    ("IT Band & Glute Stretch", "Targeted Stretching", [1, 2, 4], [4, 5], "IT band and deep glute release for lateral leg tightness", "High", lambda w,t: [it_band_glute_stretch_wo()]*3),
    ("Ankle Flexibility", "Targeted Stretching", [1, 2, 4], [5, 6], "Dorsiflexion and ankle flexibility for squats and movement", "High", lambda w,t: [ankle_flexibility_wo()]*3),
    ("Full Body Flexibility", "Targeted Stretching", [1, 2, 4], [4, 5], "Head-to-toe flexibility routine for overall range of motion", "High", lambda w,t: [full_body_flexibility_wo()]*3),
    ("Flexibility for Beginners", "Targeted Stretching", [1, 2, 4], [4, 5], "Gentle intro to stretching for complete beginners", "High", lambda w,t: [flexibility_beginners_wo()]*3),
    ("Chest & Bicep Stretch", "Targeted Stretching", [1, 2, 4], [4, 5], "Open up tight chest and biceps from pressing and sitting", "High", lambda w,t: [chest_bicep_stretch_wo()]*3),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat26_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: gentle stretches, learn positions"
            elif p <= 0.66: focus = f"Week {w} - Deepen: longer holds, increased range"
            else: focus = f"Week {w} - Advance: deeper stretches, PNF techniques"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 26 COMPLETE ===\n")

helper.close()
print("\n=== PART 1 (CATS 23-26) COMPLETE ===")
