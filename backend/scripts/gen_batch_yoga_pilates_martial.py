#!/usr/bin/env python3
"""Generate Yoga (17), Pilates (8), and Martial Arts (10) programs."""
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

# ============================================================
# YOGA WORKOUT FUNCTIONS
# ============================================================

def yoga_beginner_flow():
    return wo("Beginner Yoga Flow", "flexibility", 40, [
        ex("Mountain Pose (Tadasana)", 1, 1, 0, "Hold 60 seconds", "Yoga Mat", "Full Body", "Quadriceps", ["Core", "Calves"], "beginner", "Ground all four corners of feet, lengthen spine, relax shoulders", "Standing Tall"),
        ex("Forward Fold (Uttanasana)", 2, 1, 0, "Hold 30 seconds", "Yoga Mat", "Back", "Hamstrings", ["Erector Spinae", "Calves"], "beginner", "Hinge at hips, let head hang heavy, soft knees okay", "Ragdoll Pose"),
        ex("Cat-Cow Stretch", 2, 8, 0, "Flow with breath", "Yoga Mat", "Back", "Erector Spinae", ["Core", "Hip Flexors"], "beginner", "Inhale arch back, exhale round spine, move slowly", "Seated Cat-Cow"),
        ex("Downward Facing Dog (Adho Mukha Svanasana)", 2, 1, 0, "Hold 30 seconds", "Yoga Mat", "Full Body", "Hamstrings", ["Shoulders", "Calves", "Latissimus Dorsi"], "beginner", "Press hands wide, lift hips high, pedal heels", "Puppy Pose"),
        ex("Warrior I (Virabhadrasana I)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Quadriceps", ["Hip Flexors", "Shoulders"], "beginner", "Back foot 45 degrees, square hips forward, arms overhead", "High Lunge"),
        ex("Child's Pose (Balasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Back", "Latissimus Dorsi", ["Hips", "Shoulders"], "beginner", "Knees wide, reach arms forward, forehead to mat", "Puppy Pose"),
        ex("Corpse Pose (Savasana)", 1, 1, 0, "Hold 3 minutes", "Yoga Mat", "Full Body", "Diaphragm", ["Core"], "beginner", "Lie flat, arms at sides, close eyes, deep breathing", "Seated Meditation"),
    ])

def yoga_athlete_flow():
    return wo("Yoga for Athletes", "flexibility", 45, [
        ex("Sun Salutation A (Surya Namaskar A)", 3, 1, 0, "Full sequence", "Yoga Mat", "Full Body", "Core", ["Shoulders", "Hamstrings", "Quadriceps"], "intermediate", "Link breath to movement, 5 breaths in each hold", "Modified Sun Salutation"),
        ex("Warrior II (Virabhadrasana II)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Legs", "Quadriceps", ["Hip Adductors", "Core"], "intermediate", "Front knee over ankle, gaze over front hand", "Modified Warrior"),
        ex("Half Pigeon Pose (Eka Pada Rajakapotasana)", 2, 1, 0, "Hold 60 seconds each side", "Yoga Mat", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "intermediate", "Square hips, fold forward over front shin", "Supine Figure-4 Stretch"),
        ex("Lizard Pose (Utthan Pristhasana)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Hips", "Hip Flexors", ["Hip Adductors", "Hamstrings"], "intermediate", "Both hands inside front foot, option to drop to forearms", "Low Lunge"),
        ex("Revolved Triangle (Parivrtta Trikonasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Full Body", "Hamstrings", ["Obliques", "Shoulders"], "intermediate", "Hinge at hips, rotate torso, extend top arm", "Revolved Half Moon"),
        ex("Bridge Pose (Setu Bandhasana)", 2, 1, 0, "Hold 30 seconds", "Yoga Mat", "Back", "Glutes", ["Hamstrings", "Core"], "beginner", "Press feet down, lift hips, interlace hands beneath", "Supported Bridge"),
        ex("Reclined Spinal Twist (Supta Matsyendrasana)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Back", "Obliques", ["Erector Spinae", "Glutes"], "beginner", "Both shoulders on mat, let knees fall to one side", "Seated Twist"),
    ])

def hatha_yoga_flow():
    return wo("Hatha Yoga Practice", "flexibility", 50, [
        ex("Easy Seated Pose (Sukhasana) with Breath", 1, 1, 0, "Hold 2 minutes", "Yoga Mat", "Core", "Diaphragm", ["Hip Flexors"], "beginner", "Tall spine, close eyes, 4-count inhale, 6-count exhale", "Chair Seated Breathing"),
        ex("Standing Forward Fold (Uttanasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Back", "Hamstrings", ["Erector Spinae", "Calves"], "beginner", "Hinge at hips, relax neck, micro-bend knees", "Ragdoll Pose"),
        ex("Triangle Pose (Trikonasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Hip Adductors", ["Obliques", "Hamstrings"], "beginner", "Wide stance, reach hand to shin, open chest", "Extended Side Angle"),
        ex("Tree Pose (Vrksasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Quadriceps", ["Core", "Calves"], "beginner", "Foot on inner thigh or calf, never the knee, fix gaze", "Toe-Touch Tree"),
        ex("Cobra Pose (Bhujangasana)", 2, 1, 0, "Hold 20 seconds", "Yoga Mat", "Back", "Erector Spinae", ["Shoulders", "Core"], "beginner", "Hands under shoulders, gentle backbend, elbows close", "Sphinx Pose"),
        ex("Seated Forward Fold (Paschimottanasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Sit tall, hinge at hips, reach for feet", "Seated Knee-Bent Forward Fold"),
        ex("Legs Up The Wall (Viparita Karani)", 1, 1, 0, "Hold 3 minutes", "Yoga Mat", "Legs", "Hamstrings", ["Calves", "Core"], "beginner", "Hips close to wall, legs vertical, arms out to sides", "Supine Leg Raise"),
    ])

def ashtanga_basics_flow():
    return wo("Ashtanga Primary Series Basics", "flexibility", 60, [
        ex("Sun Salutation A (Surya Namaskar A)", 5, 1, 0, "Full vinyasa", "Yoga Mat", "Full Body", "Core", ["Shoulders", "Hamstrings", "Quadriceps"], "intermediate", "Ujjayi breath throughout, gaze points (drishti) at each pose", "Modified Sun Salutation"),
        ex("Sun Salutation B (Surya Namaskar B)", 3, 1, 0, "Full vinyasa with Warrior I", "Yoga Mat", "Full Body", "Quadriceps", ["Shoulders", "Core", "Hamstrings"], "intermediate", "Chair pose on inhale, Warrior I both sides, vinyasa between", "Sun Salutation A"),
        ex("Standing Forward Fold (Padangusthasana)", 2, 1, 0, "Hold 5 breaths", "Yoga Mat", "Back", "Hamstrings", ["Calves", "Erector Spinae"], "intermediate", "Grab big toes, pull torso down, straighten legs", "Bent-Knee Forward Fold"),
        ex("Extended Triangle (Utthita Trikonasana)", 2, 1, 0, "Hold 5 breaths each side", "Yoga Mat", "Legs", "Hip Adductors", ["Obliques", "Hamstrings"], "intermediate", "Wide stance, reach to ankle, stack shoulders", "Supported Triangle"),
        ex("Seated Forward Bend (Paschimottanasana)", 2, 1, 0, "Hold 5 breaths", "Yoga Mat", "Back", "Hamstrings", ["Erector Spinae"], "intermediate", "Bandhas engaged, fold from hips, reach past feet", "Bent-Knee Forward Fold"),
        ex("Boat Pose (Navasana)", 3, 1, 0, "Hold 5 breaths", "Yoga Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "intermediate", "Lift legs 45 degrees, arms parallel to floor, straight spine", "Bent-Knee Boat"),
    ])

def hot_yoga_flow():
    return wo("Hot Yoga Style Flow", "flexibility", 50, [
        ex("Half Moon Pose (Ardha Chandrasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Glutes", ["Core", "Hip Adductors"], "intermediate", "Standing leg strong, top hip stacked, reach for sky", "Supported Half Moon"),
        ex("Eagle Pose (Garudasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Wrap arms and legs, sink into standing leg, lift elbows", "Modified Eagle Arms Only"),
        ex("Standing Head to Knee (Dandayamana Janushirasana)", 2, 1, 0, "Hold 20 seconds each side", "Yoga Mat", "Legs", "Hamstrings", ["Core", "Quadriceps"], "intermediate", "Lock standing knee, extend leg, round spine to knee", "Standing Knee Hold"),
        ex("Camel Pose (Ustrasana)", 2, 1, 0, "Hold 20 seconds", "Yoga Mat", "Back", "Erector Spinae", ["Hip Flexors", "Rectus Abdominis"], "intermediate", "Kneel, hands to heels, push hips forward, open chest", "Supported Camel with Hands on Low Back"),
        ex("Rabbit Pose (Sasangasana)", 2, 1, 0, "Hold 20 seconds", "Yoga Mat", "Back", "Erector Spinae", ["Shoulders", "Neck"], "intermediate", "Grip heels, round spine fully, top of head to mat", "Child's Pose"),
        ex("Fixed Firm Pose (Supta Vajrasana)", 2, 1, 0, "Hold 30 seconds", "Yoga Mat", "Legs", "Quadriceps", ["Hip Flexors", "Ankles"], "intermediate", "Sit between heels, lean back to elbows or floor", "Reclined Hero Modified"),
        ex("Spine Twist (Ardha Matsyendrasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Back", "Obliques", ["Erector Spinae", "Glutes"], "beginner", "Seated twist, hook elbow outside knee, lengthen spine on inhale", "Supine Twist"),
    ])

def yoga_flexibility_flow():
    return wo("Deep Flexibility Flow", "flexibility", 45, [
        ex("Butterfly Pose (Baddha Konasana)", 2, 1, 0, "Hold 60 seconds", "Yoga Mat", "Hips", "Hip Adductors", ["Glutes"], "beginner", "Soles of feet together, press knees toward floor, fold forward", "Reclined Butterfly"),
        ex("Wide-Legged Forward Fold (Prasarita Padottanasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Legs", "Hamstrings", ["Hip Adductors", "Erector Spinae"], "beginner", "Wide stance, fold at hips, hands to floor", "Chair Wide-Leg Forward Fold"),
        ex("Frog Pose (Mandukasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Hips", "Hip Adductors", ["Hip Flexors"], "intermediate", "Knees wide, hips in line with knees, forearms on floor", "Butterfly Pose"),
        ex("King Pigeon Prep (Eka Pada Rajakapotasana)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "intermediate", "Front shin parallel to mat, reach back for foot", "Half Pigeon"),
        ex("Splits Prep (Hanumanasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Hamstrings", ["Hip Flexors", "Quadriceps"], "intermediate", "Use blocks for support, slide front heel forward gradually", "Half Split"),
        ex("Wheel Pose (Urdhva Dhanurasana)", 2, 1, 0, "Hold 15 seconds", "Yoga Mat", "Back", "Erector Spinae", ["Shoulders", "Glutes", "Quadriceps"], "intermediate", "Hands and feet on floor, press up, straighten arms", "Bridge Pose"),
        ex("Reclined Spinal Twist (Supta Matsyendrasana)", 2, 1, 0, "Hold 60 seconds each side", "Yoga Mat", "Back", "Obliques", ["Erector Spinae"], "beginner", "Both shoulders down, let gravity pull knees to side", "Seated Twist"),
    ])

def kundalini_flow():
    return wo("Kundalini Practice", "flexibility", 45, [
        ex("Breath of Fire (Kapalabhati)", 3, 1, 0, "1 minute each round", "Yoga Mat", "Core", "Diaphragm", ["Transverse Abdominis", "Intercostals"], "intermediate", "Rapid rhythmic breathing through nose, pump navel point", "Deep Belly Breathing"),
        ex("Spinal Flex (Seated Cat-Cow)", 2, 26, 0, "Rhythmic with breath", "Yoga Mat", "Back", "Erector Spinae", ["Core"], "beginner", "Seated cross-legged, flex spine forward and back with breath", "Standing Cat-Cow"),
        ex("Ego Eradicator", 2, 1, 0, "Hold 1 minute", "Yoga Mat", "Shoulders", "Deltoids", ["Core", "Diaphragm"], "beginner", "Arms at 60 degrees, thumbs up, Breath of Fire", "Arm Raises with Breath"),
        ex("Archer Pose", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Wide lunge, pull back arm like drawing a bow, gaze forward", "Warrior II"),
        ex("Sat Kriya", 2, 1, 0, "Hold 1 minute", "Yoga Mat", "Core", "Transverse Abdominis", ["Pelvic Floor", "Shoulders"], "intermediate", "Kneel, arms overhead interlaced, chant Sat on navel pump", "Seated Breath Work"),
        ex("Frog Pose Jumps", 2, 26, 0, "Rhythmic movement", "Yoga Mat", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Squat with heels touching, straighten legs on inhale, squat on exhale", "Bodyweight Squat"),
        ex("Deep Relaxation (Savasana)", 1, 1, 0, "Hold 5 minutes", "Yoga Mat", "Full Body", "Diaphragm", ["Core"], "beginner", "Complete stillness, long slow deep breathing", "Seated Meditation"),
    ])

def aerial_yoga_prep_flow():
    return wo("Aerial Yoga Prep", "flexibility", 40, [
        ex("Plank Pose (Phalakasana)", 3, 1, 0, "Hold 30 seconds", "Yoga Mat", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "beginner", "Straight line head to heels, wrists under shoulders", "Forearm Plank"),
        ex("Dolphin Pose", 2, 1, 0, "Hold 30 seconds", "Yoga Mat", "Shoulders", "Deltoids", ["Core", "Hamstrings"], "intermediate", "Forearms on mat, lift hips, walk feet in", "Downward Dog"),
        ex("Forearm Stand Prep (Pincha Mayurasana Prep)", 2, 1, 0, "Hold 15 seconds", "Yoga Mat", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Forearms on floor, kick up gently against wall", "Dolphin Pose"),
        ex("Hanging Grip Holds", 3, 1, 0, "Hold 20 seconds", "Pull-up Bar", "Arms", "Forearm Flexors", ["Latissimus Dorsi", "Biceps"], "intermediate", "Dead hang from bar, engage shoulders, breathe", "Towel Squeeze"),
        ex("Inverted Row Hold", 2, 1, 0, "Hold 15 seconds at top", "Yoga Mat", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull chest to bar/rings, hold at top, squeeze shoulder blades", "Resistance Band Row"),
        ex("Shoulder Opener with Strap", 2, 8, 0, "Slow and controlled", "Yoga Strap", "Shoulders", "Deltoids", ["Rotator Cuff", "Pectoralis Major"], "beginner", "Hold strap wide, lift arms overhead and behind, open chest", "Doorway Chest Stretch"),
    ])

def yoga_nidra_flow():
    return wo("Yoga Nidra Session", "flexibility", 30, [
        ex("Supported Reclined Butterfly (Supta Baddha Konasana)", 1, 1, 0, "Hold 3 minutes", "Yoga Mat", "Hips", "Hip Adductors", ["Core"], "beginner", "Bolster under spine, soles of feet together, arms open", "Reclined Butterfly"),
        ex("Body Scan Relaxation", 1, 1, 0, "Hold 5 minutes", "Yoga Mat", "Full Body", "Diaphragm", ["Core"], "beginner", "Lie flat, systematically relax each body part from toes to crown", "Seated Body Scan"),
        ex("Alternate Nostril Breathing (Nadi Shodhana)", 1, 1, 0, "Hold 3 minutes", "Yoga Mat", "Core", "Diaphragm", ["Intercostals"], "beginner", "Block right nostril inhale left, switch, exhale right, repeat", "Deep Breathing"),
        ex("Supported Legs Up The Wall (Viparita Karani)", 1, 1, 0, "Hold 5 minutes", "Yoga Mat", "Legs", "Hamstrings", ["Calves"], "beginner", "Hips near wall, legs up, bolster under sacrum", "Supine Leg Raise"),
        ex("Guided Visualization Savasana", 1, 1, 0, "Hold 10 minutes", "Yoga Mat", "Full Body", "Diaphragm", ["Core"], "beginner", "Complete stillness, focus on guided imagery, stay awake but relaxed", "Basic Savasana"),
    ])

def chair_yoga_flow():
    return wo("Chair Yoga Session", "flexibility", 30, [
        ex("Seated Mountain Pose", 1, 1, 0, "Hold 60 seconds", "Chair", "Core", "Erector Spinae", ["Core"], "beginner", "Sit tall, feet flat, shoulders back and down, crown reaching up", "Standing Mountain Pose"),
        ex("Seated Cat-Cow", 2, 8, 0, "Flow with breath", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Hands on knees, arch and round spine with breath", "Standing Cat-Cow"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 30 seconds", "Chair", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Hinge at hips, fold over thighs, let head hang", "Standing Forward Fold"),
        ex("Seated Eagle Arms", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Shoulders", "Rhomboids", ["Deltoids", "Trapezius"], "beginner", "Cross elbows, wrap forearms, lift elbows to shoulder height", "Seated Shoulder Stretch"),
        ex("Seated Pigeon", 2, 1, 0, "Hold 30 seconds each side", "Chair", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Ankle on opposite knee, sit tall, gentle fold forward", "Figure-4 Stretch"),
        ex("Seated Twist (Ardha Matsyendrasana)", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Back", "Obliques", ["Erector Spinae"], "beginner", "Hand on opposite knee, twist from waist, look over shoulder", "Standing Twist"),
        ex("Seated Side Bend", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "One arm overhead, lean to opposite side, keep both hips grounded", "Standing Side Bend"),
    ])

def wall_yoga_flow():
    return wo("Wall Yoga Session", "flexibility", 35, [
        ex("Wall Downward Dog", 2, 1, 0, "Hold 30 seconds", "Wall", "Shoulders", "Deltoids", ["Hamstrings", "Latissimus Dorsi"], "beginner", "Hands on wall at hip height, walk back, flatten torso parallel to floor", "Traditional Downward Dog"),
        ex("Wall Supported Warrior III", 2, 1, 0, "Hold 20 seconds each side", "Wall", "Legs", "Glutes", ["Hamstrings", "Core"], "beginner", "Hands on wall, hinge forward, extend back leg parallel to floor", "Modified Warrior III"),
        ex("Wall Chest Opener", 2, 1, 0, "Hold 30 seconds each side", "Wall", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Biceps"], "beginner", "Arm on wall at 90 degrees, turn body away, open chest", "Doorway Stretch"),
        ex("Wall Supported Tree Pose", 2, 1, 0, "Hold 30 seconds each side", "Wall", "Legs", "Quadriceps", ["Core", "Calves"], "beginner", "One hand lightly on wall, foot on inner thigh, find balance", "Toe-Touch Tree"),
        ex("Wall Supported Half Moon", 2, 1, 0, "Hold 20 seconds each side", "Wall", "Legs", "Glutes", ["Core", "Hip Adductors"], "beginner", "Back against wall for support, open hips and stack", "Modified Half Moon"),
        ex("Wall Legs Up (L-Shape)", 2, 1, 0, "Hold 2 minutes", "Wall", "Legs", "Hamstrings", ["Calves", "Core"], "beginner", "Hips at wall, legs vertical, arms by sides, breathe deeply", "Supine Leg Raise"),
    ])

def somatic_yoga_flow():
    return wo("Somatic Yoga Flow", "flexibility", 40, [
        ex("Pandiculation (Full Body Yawn Stretch)", 2, 5, 0, "Slow contractions", "Yoga Mat", "Full Body", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Contract muscles fully, then slowly release with awareness", "Cat-Cow"),
        ex("Somatic Arch and Flatten", 2, 8, 0, "Very slow movement", "Yoga Mat", "Core", "Erector Spinae", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Lying down, slowly arch lower back, then flatten to floor", "Pelvic Tilt"),
        ex("Somatic Side Bend", 2, 6, 0, "Each side slowly", "Yoga Mat", "Core", "Obliques", ["Latissimus Dorsi", "Quadratus Lumborum"], "beginner", "Lying on side, slowly contract and lengthen waist muscles", "Standing Side Bend"),
        ex("Somatic Hip Release", 2, 8, 0, "Very slow circles", "Yoga Mat", "Hips", "Hip Flexors", ["Glutes", "Piriformis"], "beginner", "Lying down, tiny slow hip circles with awareness of sensation", "Supine Hip Circle"),
        ex("Somatic Neck Release", 2, 6, 0, "Micro-movements", "Yoga Mat", "Neck", "Sternocleidomastoid", ["Trapezius", "Scalenes"], "beginner", "Lying down, tiny slow head turns, sense full range of motion", "Neck Rolls"),
        ex("Constructive Rest Position", 1, 1, 0, "Hold 3 minutes", "Yoga Mat", "Back", "Psoas", ["Erector Spinae", "Core"], "beginner", "Knees bent, feet wide, knees together, arms on belly, breathe", "Savasana"),
    ])

def yoga_back_pain_flow():
    return wo("Yoga for Back Pain", "flexibility", 35, [
        ex("Cat-Cow Stretch", 2, 10, 0, "Slow with breath", "Yoga Mat", "Back", "Erector Spinae", ["Core", "Hip Flexors"], "beginner", "Inhale arch, exhale round, move from pelvis through whole spine", "Seated Cat-Cow"),
        ex("Sphinx Pose", 2, 1, 0, "Hold 30 seconds", "Yoga Mat", "Back", "Erector Spinae", ["Core"], "beginner", "Forearms on mat, elbows under shoulders, gentle backbend", "Prone Press-Up"),
        ex("Knees to Chest (Apanasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Back", "Erector Spinae", ["Glutes", "Hip Flexors"], "beginner", "Hug both knees to chest, rock gently side to side", "Single Knee to Chest"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Back", "Obliques", ["Erector Spinae", "Glutes"], "beginner", "Both shoulders on mat, knees to one side, arms in T-shape", "Seated Twist"),
        ex("Thread the Needle", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Back", "Rhomboids", ["Obliques", "Shoulders"], "beginner", "All fours, slide one arm under body, rest shoulder on mat", "Seated Twist"),
        ex("Supported Fish Pose", 2, 1, 0, "Hold 60 seconds", "Yoga Mat", "Back", "Pectoralis Major", ["Erector Spinae", "Shoulders"], "beginner", "Bolster or block under upper back, arms open, gentle chest opener", "Bridge Pose"),
        ex("Reclined Bound Angle (Supta Baddha Konasana)", 1, 1, 0, "Hold 2 minutes", "Yoga Mat", "Hips", "Hip Adductors", ["Core", "Erector Spinae"], "beginner", "Bolster under spine, soles of feet together, knees fall open", "Supine Butterfly"),
    ])

def yoga_neck_shoulders_flow():
    return wo("Yoga for Neck and Shoulders", "flexibility", 30, [
        ex("Neck Rolls", 2, 5, 0, "Slow circles each direction", "Yoga Mat", "Neck", "Sternocleidomastoid", ["Trapezius", "Scalenes"], "beginner", "Half circles chin to chest, ear to shoulder, slow and gentle", "Neck Tilts"),
        ex("Shoulder Rolls", 2, 10, 0, "Forward and backward", "Yoga Mat", "Shoulders", "Trapezius", ["Deltoids", "Rhomboids"], "beginner", "Big slow circles, squeeze shoulder blades at back", "Arm Circles"),
        ex("Eagle Arms (Garudasana Arms)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Shoulders", "Rhomboids", ["Deltoids", "Trapezius"], "beginner", "Cross elbows, wrap forearms, lift elbows, breathe into upper back", "Cross-Body Shoulder Stretch"),
        ex("Thread the Needle", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Shoulders", "Rhomboids", ["Obliques", "Deltoids"], "beginner", "From all fours, slide arm under body, melt shoulder to mat", "Cross-Body Stretch"),
        ex("Cow Face Arms (Gomukhasana Arms)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Shoulders", "Rotator Cuff", ["Triceps", "Deltoids"], "beginner", "One arm overhead, one behind back, clasp fingers or use strap", "Strap Shoulder Stretch"),
        ex("Supported Fish Pose", 2, 1, 0, "Hold 60 seconds", "Yoga Mat", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Neck"], "beginner", "Block under upper back, head supported, arms open wide", "Chest Opener on Wall"),
        ex("Ear to Shoulder Stretch with Hand", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Neck", "Trapezius", ["Scalenes", "Sternocleidomastoid"], "beginner", "Tilt ear to shoulder, gentle hand pressure, opposite arm reaches down", "Simple Neck Tilt"),
    ])

def yoga_hips_flow():
    return wo("Yoga for Hips", "flexibility", 40, [
        ex("Low Lunge (Anjaneyasana)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Hips", "Hip Flexors", ["Quadriceps", "Psoas"], "beginner", "Back knee down, sink hips forward, arms overhead", "Standing Lunge"),
        ex("Lizard Pose (Utthan Pristhasana)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Hips", "Hip Adductors", ["Hip Flexors", "Hamstrings"], "intermediate", "Both hands inside front foot, option for forearms on floor", "Low Lunge"),
        ex("Half Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Yoga Mat", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "beginner", "Square hips, fold forward, breathe into hip", "Supine Figure-4"),
        ex("Frog Pose (Mandukasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Hips", "Hip Adductors", ["Hip Flexors"], "intermediate", "Knees wide, hips between knees, forearms on floor", "Butterfly Pose"),
        ex("Happy Baby (Ananda Balasana)", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Hips", "Hip Adductors", ["Glutes", "Hamstrings"], "beginner", "Grab outer feet, pull knees toward armpits, rock gently", "Supine Knee to Chest"),
        ex("Fire Log Pose (Agnistambhasana)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Hips", "Piriformis", ["Gluteus Medius", "Hip Adductors"], "intermediate", "Stack shins, flex feet, fold forward, deep outer hip stretch", "Seated Pigeon"),
        ex("Butterfly Pose (Baddha Konasana)", 2, 1, 0, "Hold 60 seconds", "Yoga Mat", "Hips", "Hip Adductors", ["Glutes"], "beginner", "Soles of feet together, press knees down, fold forward", "Reclined Butterfly"),
    ])

def yoga_runners_flow():
    return wo("Yoga for Runners", "flexibility", 40, [
        ex("Downward Facing Dog", 2, 1, 0, "Hold 30 seconds, pedal heels", "Yoga Mat", "Full Body", "Hamstrings", ["Calves", "Shoulders"], "beginner", "Press hands wide, lift hips high, alternate bending knees", "Wall Downward Dog"),
        ex("Low Lunge with Quad Stretch", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Hip Flexors", ["Quadriceps"], "intermediate", "Low lunge, reach back, grab back foot, pull heel to glute", "Low Lunge"),
        ex("Pyramid Pose (Parsvottanasana)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "Hamstrings", ["Calves", "Erector Spinae"], "beginner", "Staggered stance, fold over front leg, hands on blocks", "Standing Hamstring Stretch"),
        ex("Reclined Hand to Big Toe (Supta Padangusthasana)", 2, 1, 0, "Hold 45 seconds each side", "Yoga Mat", "Legs", "Hamstrings", ["Calves", "Hip Flexors"], "beginner", "Lying down, strap around foot, extend leg up, keep hips level", "Supine Hamstring Stretch"),
        ex("Standing Calf Stretch", 2, 1, 0, "Hold 30 seconds each side", "Wall", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Hands on wall, step back, press heel down, lean in", "Step Edge Calf Stretch"),
        ex("IT Band Stretch (Revolved Triangle)", 2, 1, 0, "Hold 30 seconds each side", "Yoga Mat", "Legs", "IT Band", ["Hamstrings", "Obliques"], "intermediate", "Narrow stance, twist torso, hand to outside of front foot", "Standing IT Band Stretch"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Yoga Mat", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "beginner", "Front shin on floor, back leg extended, fold forward", "Supine Figure-4"),
    ])

def prenatal_yoga_flow():
    return wo("Prenatal Yoga Flow", "flexibility", 35, [
        ex("Cat-Cow Stretch", 2, 8, 0, "Gentle with breath", "Yoga Mat", "Back", "Erector Spinae", ["Core", "Hip Flexors"], "beginner", "All fours, gentle arch and round, relieve lower back tension", "Seated Cat-Cow"),
        ex("Wide-Legged Child's Pose", 2, 1, 0, "Hold 45 seconds", "Yoga Mat", "Back", "Latissimus Dorsi", ["Hips", "Shoulders"], "beginner", "Knees wide to accommodate belly, reach arms forward, rest", "Supported Child's Pose"),
        ex("Goddess Pose (Utkata Konasana)", 2, 1, 0, "Hold 20 seconds", "Yoga Mat", "Legs", "Quadriceps", ["Hip Adductors", "Glutes"], "beginner", "Wide stance, toes out, bend knees over toes, arms cactus", "Wide Squat Hold"),
        ex("Side-Lying Savasana", 1, 1, 0, "Hold 3 minutes", "Yoga Mat", "Full Body", "Diaphragm", ["Core"], "beginner", "Left side, pillow between knees, support belly if needed", "Reclined on Back"),
        ex("Pelvic Floor Engagement (Mula Bandha)", 2, 10, 0, "Contract and release", "Yoga Mat", "Core", "Pelvic Floor", ["Transverse Abdominis"], "beginner", "Gently engage pelvic floor on exhale, release on inhale", "Kegel Exercise"),
        ex("Supported Squat (Malasana)", 2, 1, 0, "Hold 30 seconds", "Yoga Mat", "Hips", "Hip Adductors", ["Glutes", "Pelvic Floor"], "beginner", "Deep squat with block under sit bones, hands in prayer", "Wall Squat"),
    ])

# ============================================================
# PILATES WORKOUT FUNCTIONS
# ============================================================

def pilates_beginner_flow():
    return wo("Pilates Beginner Mat", "flexibility", 40, [
        ex("The Hundred", 2, 1, 0, "100 arm pumps", "Pilates Mat", "Core", "Rectus Abdominis", ["Transverse Abdominis", "Hip Flexors"], "beginner", "Legs tabletop, curl head and shoulders up, pump arms 5 in 5 out", "Modified Hundred with Feet Down"),
        ex("Roll Up", 2, 6, 0, "Slow and controlled", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Erector Spinae"], "beginner", "Arms overhead, curl up one vertebra at a time, reach past toes", "Half Roll Back"),
        ex("Single Leg Circle", 2, 5, 0, "Each direction each leg", "Pilates Mat", "Hips", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Stabilize pelvis, circle one leg, keep circles small and controlled", "Bent-Knee Leg Circle"),
        ex("Rolling Like a Ball", 2, 8, 0, "Controlled momentum", "Pilates Mat", "Core", "Rectus Abdominis", ["Erector Spinae"], "beginner", "Tuck chin, round spine, roll back to shoulders not neck, roll up to balance", "Seated Balance Hold"),
        ex("Single Leg Stretch", 2, 10, 0, "Alternating legs", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "beginner", "Curl up, one knee to chest, other leg extends, switch rhythmically", "Bent-Knee March"),
        ex("Spine Stretch Forward", 2, 5, 0, "Articulate through spine", "Pilates Mat", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Seated legs wide, round forward stacking one vertebra at a time", "Seated Forward Fold"),
        ex("Swimming", 2, 10, 0, "Alternating arms and legs", "Pilates Mat", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Prone, lift opposite arm and leg alternately, flutter quickly", "Bird Dog"),
    ])

def pilates_core_intensive():
    return wo("Pilates Core Intensive", "flexibility", 40, [
        ex("The Hundred (Advanced)", 2, 1, 0, "100 arm pumps, legs at 45", "Pilates Mat", "Core", "Rectus Abdominis", ["Transverse Abdominis", "Hip Flexors"], "intermediate", "Legs extended 45 degrees, vigorous arm pumps, deep breathing", "Modified Hundred"),
        ex("Double Leg Stretch", 2, 8, 0, "Full extension and return", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Curl up, extend arms and legs simultaneously, circle arms back, hug knees", "Single Leg Stretch"),
        ex("Criss-Cross", 2, 10, 0, "Alternating with rotation", "Pilates Mat", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "intermediate", "Curl up, rotate elbow to opposite knee, extend other leg, hold each twist", "Bicycle Crunch"),
        ex("Teaser", 2, 5, 0, "Full V-shape", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "intermediate", "Roll up to V-sit, arms parallel to legs, balance on sit bones", "Half Teaser"),
        ex("Plank to Pike", 2, 8, 0, "Controlled movement", "Pilates Mat", "Core", "Rectus Abdominis", ["Shoulders", "Hip Flexors"], "intermediate", "From plank, pike hips up, pull navel to spine, return to plank", "Plank Hold"),
        ex("Side Plank with Leg Lift", 2, 1, 0, "Hold 20 seconds each side", "Pilates Mat", "Core", "Obliques", ["Gluteus Medius", "Shoulders"], "intermediate", "Side plank on hand, lift top leg, keep hips stacked and lifted", "Side Plank"),
        ex("Corkscrew", 2, 5, 0, "Each direction", "Pilates Mat", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "intermediate", "Legs to ceiling, circle legs together, keep pelvis stable", "Leg Circle"),
    ])

def pilates_reformer_style():
    return wo("Pilates Reformer Style Mat", "flexibility", 45, [
        ex("Footwork Series (Pilates Squats)", 3, 10, 15, "Controlled tempo", "Pilates Mat", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Lie supine, press through feet as if on reformer carriage, varied foot positions", "Wall Sit Slides"),
        ex("Long Stretch (Plank Push-Up)", 2, 8, 15, "Full range", "Pilates Mat", "Core", "Pectoralis Major", ["Core", "Triceps"], "intermediate", "Plank position, shift body forward and back, mimicking carriage movement", "Push-Up"),
        ex("Elephant Walk", 2, 8, 0, "Articulate through spine", "Pilates Mat", "Core", "Rectus Abdominis", ["Hamstrings", "Shoulders"], "intermediate", "Inverted V position, walk feet toward hands keeping legs straight", "Downward Dog Walk"),
        ex("Short Box Series - Round Back", 2, 8, 0, "Controlled lean back", "Pilates Mat", "Core", "Rectus Abdominis", ["Erector Spinae", "Hip Flexors"], "beginner", "Seated, round spine and lean back, curl back up, maintain C-curve", "Half Roll Back"),
        ex("Mermaid Stretch", 2, 1, 0, "Hold 30 seconds each side", "Pilates Mat", "Core", "Obliques", ["Latissimus Dorsi", "Intercostals"], "beginner", "Z-sit, reach arm overhead to side, open ribs, deep lateral stretch", "Seated Side Bend"),
        ex("Leg Pull Front (Plank Leg Lift)", 2, 8, 0, "Alternating legs", "Pilates Mat", "Core", "Glutes", ["Core", "Shoulders"], "intermediate", "Plank position, lift one leg at a time, maintain stable pelvis", "Plank Hold"),
        ex("Swan on Mat", 2, 6, 0, "Controlled extension", "Pilates Mat", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "intermediate", "Prone, press up into extension, rock forward and back", "Cobra Pose"),
    ])

def classical_pilates_flow():
    return wo("Classical Pilates Mat Order", "flexibility", 50, [
        ex("The Hundred", 1, 1, 0, "100 pumps", "Pilates Mat", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Legs at 45, pump arms vigorously, 5 counts in, 5 counts out", "Modified Hundred"),
        ex("Roll Up", 2, 8, 0, "Sequential spinal articulation", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Use opposition, peel off mat one vertebra at a time", "Half Roll Back"),
        ex("Single Leg Circle", 2, 5, 0, "Each direction each leg", "Pilates Mat", "Hips", "Hip Flexors", ["Core"], "intermediate", "Anchor pelvis, circle from hip joint, moderate circles", "Bent-Knee Circle"),
        ex("Rolling Like a Ball", 2, 8, 0, "Stay in tight ball", "Pilates Mat", "Core", "Rectus Abdominis", ["Erector Spinae"], "intermediate", "Tight tucked shape, roll to shoulder blades only, balance at top", "Seated Balance"),
        ex("Spine Stretch Forward", 2, 6, 0, "Exhale as you round", "Pilates Mat", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Sit tall, exhale round forward, stack spine back up on inhale", "Seated Forward Fold"),
        ex("Saw", 2, 5, 0, "Each side", "Pilates Mat", "Core", "Obliques", ["Hamstrings", "Erector Spinae"], "intermediate", "Seated wide legs, twist and reach pinky past opposite pinky toe", "Seated Twist"),
        ex("Swan Dive", 2, 5, 0, "Rocking motion", "Pilates Mat", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "intermediate", "Prone, lift chest and legs, rock forward and back on torso", "Cobra Pose"),
        ex("Seal", 2, 8, 0, "Clap feet at each end", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Adductors"], "beginner", "Balanced on sit bones, hold ankles from inside, roll and clap", "Rolling Like a Ball"),
    ])

def wall_pilates_flow():
    return wo("Wall Pilates Session", "flexibility", 30, [
        ex("Wall Roll Down", 2, 8, 0, "Articulate through spine", "Wall", "Core", "Rectus Abdominis", ["Erector Spinae"], "beginner", "Stand against wall, roll down one vertebra at a time, roll back up", "Standing Roll Down"),
        ex("Wall Sit with Arm Press", 2, 1, 0, "Hold 30 seconds", "Wall", "Legs", "Quadriceps", ["Glutes", "Shoulders"], "beginner", "Slide down wall to 90 degrees, press arms into wall behind you", "Chair Squat Hold"),
        ex("Wall Push-Up with Pilates Breath", 2, 10, 0, "Exhale on push", "Wall", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Hands on wall, scoop abs, exhale press away, inhale lower", "Incline Push-Up"),
        ex("Wall Leg Slide", 2, 10, 0, "Each leg", "Wall", "Core", "Transverse Abdominis", ["Hip Flexors", "Quadriceps"], "beginner", "Back on wall, slide one foot up wall keeping pelvis stable", "Supine Leg Slide"),
        ex("Wall Side Leg Lift", 2, 10, 0, "Each side", "Wall", "Hips", "Gluteus Medius", ["Core", "Hip Adductors"], "beginner", "Side against wall, lift outer leg up wall, control descent", "Standing Side Leg Lift"),
        ex("Wall Plank", 2, 1, 0, "Hold 30 seconds", "Wall", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "beginner", "Hands on wall, body in plank angle, engage core throughout", "Incline Plank"),
    ])

def pilates_seniors_flow():
    return wo("Pilates for Seniors", "flexibility", 35, [
        ex("Seated Spine Twist", 2, 5, 0, "Gentle rotation each side", "Chair", "Core", "Obliques", ["Erector Spinae"], "beginner", "Sit tall, arms wide, twist from waist, keep hips facing forward", "Standing Twist"),
        ex("Seated Leg Extension", 2, 8, 0, "Each leg", "Chair", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Sit tall, extend one leg straight, hold 2 seconds, lower slowly", "Seated Marching"),
        ex("Modified Hundred (Feet on Floor)", 2, 1, 0, "50 arm pumps", "Pilates Mat", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "beginner", "Feet flat on floor, curl head and shoulders, gentle arm pumps", "Seated Arm Pumps"),
        ex("Bridging", 2, 8, 0, "Slow peel up and down", "Pilates Mat", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "beginner", "Peel spine off mat one vertebra at a time, squeeze glutes at top", "Hip Lift"),
        ex("Side-Lying Leg Lift", 2, 10, 0, "Each side", "Pilates Mat", "Hips", "Gluteus Medius", ["Core"], "beginner", "Lie on side, lift top leg hip height, lower with control", "Standing Side Leg Lift"),
        ex("Supine Arm Circles", 2, 8, 0, "Small controlled circles", "Pilates Mat", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Lying on back, arms to ceiling, small circles maintaining shoulder stability", "Seated Arm Circles"),
    ])

def power_pilates_flow():
    return wo("Power Pilates", "flexibility", 45, [
        ex("The Hundred (Legs Extended)", 1, 1, 0, "100 pumps, legs low", "Pilates Mat", "Core", "Rectus Abdominis", ["Transverse Abdominis", "Hip Flexors"], "intermediate", "Legs at 30 degrees, vigorous pumps, powerhouse engaged", "Modified Hundred"),
        ex("Teaser III", 2, 5, 0, "Arms and legs together", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "advanced", "Roll up to V, lower and lift legs with arms, maintain balance", "Teaser I"),
        ex("Control Balance", 2, 5, 0, "Scissor switch at top", "Pilates Mat", "Core", "Rectus Abdominis", ["Hamstrings", "Erector Spinae"], "advanced", "Roll over, grab one ankle, scissor legs overhead, strong core", "Scissors Supine"),
        ex("Push-Up with Pike", 2, 8, 0, "Walk out and push up", "Pilates Mat", "Full Body", "Pectoralis Major", ["Core", "Shoulders", "Triceps"], "intermediate", "Roll down, walk out to plank, 3 push-ups, pike walk back, roll up", "Standard Push-Up"),
        ex("Star Side Plank", 2, 1, 0, "Hold 15 seconds each side", "Pilates Mat", "Core", "Obliques", ["Gluteus Medius", "Shoulders"], "advanced", "Side plank, lift top arm and leg to star shape, hold and breathe", "Side Plank"),
        ex("Jackknife", 2, 6, 0, "Roll up to vertical", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Erector Spinae"], "advanced", "Legs overhead, press hips up to vertical, roll down with control", "Roll Over"),
        ex("Boomerang", 2, 5, 0, "Full sequence", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "advanced", "Roll over, switch legs, roll up to teaser, clasp hands behind back, fold", "Teaser"),
    ])

def pilates_stretch_fusion():
    return wo("Pilates and Stretch Fusion", "flexibility", 40, [
        ex("Roll Down to Forward Fold", 2, 6, 0, "Flow between", "Pilates Mat", "Back", "Erector Spinae", ["Hamstrings", "Rectus Abdominis"], "beginner", "Standing roll down through spine, pause in fold, roll back up", "Standing Forward Fold"),
        ex("Spine Stretch Forward", 2, 6, 0, "Deep reach past toes", "Pilates Mat", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Sit tall, exhale round forward, reach past toes, stack back up", "Seated Forward Fold"),
        ex("Mermaid Stretch", 2, 1, 0, "Hold 30 seconds each side", "Pilates Mat", "Core", "Obliques", ["Latissimus Dorsi", "Intercostals"], "beginner", "Z-sit position, reach arm overhead, deep side stretch, switch sides", "Seated Side Bend"),
        ex("Single Leg Stretch with Hold", 2, 8, 0, "Pause and stretch each leg", "Pilates Mat", "Core", "Rectus Abdominis", ["Hip Flexors", "Hamstrings"], "beginner", "Pull knee in, extend other leg, hold extended leg stretch 3 seconds", "Supine Knee Pull"),
        ex("Swan Stretch", 2, 5, 0, "Gentle back extension", "Pilates Mat", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Prone, gentle press up, open chest, hold at top and breathe", "Cobra Pose"),
        ex("Hip Flexor Stretch in Kneeling", 2, 1, 0, "Hold 45 seconds each side", "Pilates Mat", "Hips", "Hip Flexors", ["Psoas", "Quadriceps"], "beginner", "Half kneeling, tuck pelvis, shift weight forward, feel front hip stretch", "Standing Hip Flexor Stretch"),
        ex("Pilates Rest Position", 2, 1, 0, "Hold 60 seconds", "Pilates Mat", "Back", "Latissimus Dorsi", ["Erector Spinae", "Shoulders"], "beginner", "Similar to Child's Pose, arms by sides, round back, deep breathing", "Child's Pose"),
    ])

# ============================================================
# MARTIAL ARTS WORKOUT FUNCTIONS
# ============================================================

def tai_chi_basics_flow():
    return wo("Tai Chi Basics", "flexibility", 40, [
        ex("Tai Chi Opening Form (Commencement)", 2, 8, 0, "Slow deliberate movement", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Feet shoulder width, slowly raise arms to shoulder height, lower with breath", "Standing Arm Raises"),
        ex("Grasp the Sparrow's Tail", 2, 6, 0, "Each side", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Ward off, roll back, press, push - four connected movements, shift weight", "Slow Push Hands Drill"),
        ex("Wave Hands Like Clouds", 2, 8, 0, "Continuous flowing movement", "Bodyweight", "Full Body", "Obliques", ["Core", "Shoulders", "Hip Flexors"], "beginner", "Side-step while arms circle horizontally, weight shifts side to side", "Standing Arm Circles with Steps"),
        ex("Brush Knee and Push", 2, 6, 0, "Alternating sides", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Step forward, brush hand past knee, push forward with other hand", "Walking Lunge with Arm Extension"),
        ex("Single Whip", 2, 6, 0, "Each side", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Hook hand back, open palm forward, deep stance, weight on back leg", "Wide Stance with Arm Extension"),
        ex("Golden Rooster Stands on One Leg", 2, 6, 0, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Flexors"], "beginner", "Lift one knee high, opposite hand rises, standing leg slightly bent", "Single Leg Balance"),
        ex("Closing Form", 2, 5, 0, "Return to center", "Bodyweight", "Full Body", "Diaphragm", ["Core"], "beginner", "Slowly lower arms, bring feet together, stand in stillness, breathe", "Standing Meditation"),
    ])

def tai_chi_seniors_flow():
    return wo("Tai Chi for Seniors", "flexibility", 35, [
        ex("Standing Meditation (Wuji)", 1, 1, 0, "Hold 2 minutes", "Bodyweight", "Full Body", "Quadriceps", ["Core"], "beginner", "Feet shoulder width, knees slightly bent, arms relaxed, deep breathing", "Seated Meditation"),
        ex("Tai Chi Walking (Weight Shifting)", 2, 8, 0, "Slow deliberate steps", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "beginner", "Step heel first, slowly shift weight, maintain balance throughout", "Marching in Place"),
        ex("Parting Wild Horse's Mane", 2, 5, 0, "Alternating sides", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Step and separate hands diagonally, weight shifts forward", "Slow Lunge with Arm Reach"),
        ex("Repulse Monkey", 2, 5, 0, "Stepping backward", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Step backward, push forward with palm, other hand pulls back to hip", "Backward Walk with Arm Motion"),
        ex("Wave Hands Like Clouds (Modified)", 2, 6, 0, "Small steps", "Bodyweight", "Full Body", "Obliques", ["Core", "Shoulders"], "beginner", "Small side steps, gentle arm circles at waist height, shift weight", "Standing Arm Circles"),
        ex("Tai Chi Cool Down Qigong", 1, 1, 0, "Hold 2 minutes", "Bodyweight", "Full Body", "Diaphragm", ["Core"], "beginner", "Arms gather energy up, press down, 3 deep belly breaths", "Deep Breathing"),
    ])

def karate_conditioning_flow():
    return wo("Karate Conditioning", "strength", 50, [
        ex("Front Punch (Oi-Zuki) Drill", 3, 20, 15, "Fast with kiai", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core"], "intermediate", "Full hip rotation, snap punch from chamber, pull back fast", "Shadow Boxing Jab"),
        ex("Front Kick (Mae-Geri) Drill", 3, 12, 15, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Knee lift high, snap kick forward, retract quickly, chamber leg back", "Front Snap Kick"),
        ex("Horse Stance (Kiba-Dachi) Hold", 3, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Glutes"], "intermediate", "Wide stance, thighs parallel, back straight, fists at hips", "Wall Sit"),
        ex("Roundhouse Kick (Mawashi-Geri) Drill", 3, 10, 15, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Glutes", "Quadriceps", "Obliques"], "intermediate", "Pivot on support foot, chamber knee, extend kick with hip rotation", "Side Knee Raise"),
        ex("Kata Empi Strikes (Elbow Strikes)", 3, 15, 15, "Various angles", "Bodyweight", "Arms", "Triceps", ["Core", "Shoulders"], "intermediate", "Drive elbow forward, upward, and downward, rotate hips with each strike", "Elbow Strike Drill"),
        ex("Burpee with Punch", 3, 8, 30, "Explosive", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Triceps"], "intermediate", "Full burpee, at top throw two fast punches before dropping again", "Burpee"),
        ex("Shiko-Dachi (Sumo Stance) Squats", 3, 12, 15, "Wide stance deep squat", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Glutes"], "intermediate", "Wide sumo stance, toes out, deep squat, punch at bottom", "Sumo Squat"),
    ])

def taekwondo_basics_flow():
    return wo("Taekwondo Basics Conditioning", "strength", 50, [
        ex("Front Snap Kick (Ap Chagi)", 3, 12, 15, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Fast knee chamber, snap kick forward, retract fast, re-chamber", "Front Kick"),
        ex("Roundhouse Kick (Dollyo Chagi)", 3, 10, 15, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Glutes", "Obliques", "Quadriceps"], "intermediate", "Pivot on ball of support foot, chamber knee, extend with hip turn", "Knee Drive"),
        ex("Side Kick (Yop Chagi)", 3, 8, 15, "Each leg", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Core"], "intermediate", "Chamber knee high, push kick sideways with heel, lean torso away", "Lateral Leg Press"),
        ex("Speed Punching Drill", 3, 20, 15, "Maximum speed", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core"], "beginner", "Rapid alternating punches from guard, snap from hip, retract fast", "Shadow Boxing"),
        ex("Jump Squats for Kicking Power", 3, 12, 30, "Explosive height", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explode upward, land softly, repeat immediately", "Squat Jump"),
        ex("High Knee Chamber Drill", 3, 15, 15, "Alternating legs fast", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Drive knee up to chest rapidly, simulate kick chamber, alternate", "High Knees"),
        ex("Plank to Kick Through", 3, 8, 20, "Each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Hip Flexors"], "intermediate", "From plank, thread one leg through under body, kick out to side, return", "Plank Hip Tap"),
    ])

def capoeira_fundamentals_flow():
    return wo("Capoeira Fundamentals", "strength", 45, [
        ex("Ginga (Base Movement)", 3, 1, 0, "2 minutes continuous", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Alternating back lunge with arm swing, continuous rocking rhythm", "Alternating Reverse Lunge"),
        ex("Meia Lua de Frente (Front Crescent Kick)", 3, 8, 15, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Hip Adductors", "Core"], "intermediate", "Straight leg crescent kick across body, lean back for balance", "Leg Swing"),
        ex("Queixada (Outside Crescent Kick)", 3, 8, 15, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Glutes", "Core"], "intermediate", "Swing straight leg outward in arc, pivot on support foot, lean away", "Lateral Leg Swing"),
        ex("Esquiva (Dodge/Escape)", 3, 8, 0, "Alternating sides", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Adductors"], "beginner", "Side lunge dodge, drop weight low, hand on floor for support", "Side Lunge"),
        ex("Au (Cartwheel)", 3, 5, 15, "Alternating sides", "Bodyweight", "Full Body", "Shoulders", ["Core", "Obliques"], "intermediate", "Hands down one at a time, kick legs over, land one foot at a time", "Lateral Bear Crawl"),
        ex("Negativa (Low Ground Position)", 3, 1, 0, "Hold 15 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Deep side lunge with one arm supporting, other arm protects face", "Deep Side Lunge"),
        ex("Macaco (Back Handspring Prep)", 3, 5, 20, "Controlled", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "intermediate", "From low squat, reach back with one hand, kick legs over, land", "Backward Roll"),
    ])

def aikido_movement_flow():
    return wo("Aikido Movement Drill", "flexibility", 40, [
        ex("Tai Sabaki (Body Turning)", 3, 10, 0, "Each direction", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Calves"], "beginner", "Pivot 180 degrees on balls of feet, maintain center, smooth turn", "Pivot Drill"),
        ex("Tenkan (Turning Movement)", 3, 8, 0, "Each side", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Obliques"], "beginner", "Step forward, pivot 180, blend with partner energy direction", "Turning Lunge"),
        ex("Shikko (Knee Walking)", 2, 10, 0, "Forward and backward", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Walk on knees using hip rotation, maintain upright posture", "Kneeling Walk"),
        ex("Ukemi (Forward Roll)", 3, 6, 0, "Alternating sides", "Bodyweight", "Full Body", "Core", ["Shoulders", "Back"], "beginner", "Lead with one arm, tuck chin, roll diagonally across back, stand up", "Forward Roll"),
        ex("Ukemi (Backward Roll)", 3, 6, 0, "Controlled backward", "Bodyweight", "Full Body", "Core", ["Shoulders", "Erector Spinae"], "intermediate", "Sit back, tuck chin, roll over one shoulder, come to kneeling", "Backward Roll"),
        ex("Irimi (Entering Step with Extension)", 3, 8, 0, "Each side", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Step diagonally forward off center line, extend arm, maintain balance", "Forward Lunge with Reach"),
        ex("Seiza to Standing Transition", 3, 6, 0, "Smooth transitions", "Bodyweight", "Legs", "Quadriceps", ["Core", "Glutes"], "beginner", "From kneeling, rise to standing without using hands, controlled", "Kneeling to Standing"),
    ])

def muay_thai_conditioning_flow():
    return wo("Muay Thai Conditioning", "strength", 50, [
        ex("Jab-Cross-Hook Combo", 3, 12, 15, "Full combinations", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core", "Obliques"], "intermediate", "Jab with lead, cross with rear, hook with lead, rotate hips fully", "Shadow Boxing"),
        ex("Teep (Push Kick)", 3, 10, 15, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Chamber knee, push foot forward targeting solar plexus, snap back", "Front Kick"),
        ex("Thai Roundhouse Kick", 3, 8, 15, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Glutes", "Obliques", "Calves"], "intermediate", "Turn hip over, swing shin through target, pivot on ball of foot", "Lateral Knee Raise"),
        ex("Knee Strike Drill", 3, 12, 15, "Alternating", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Quadriceps"], "intermediate", "Pull imaginary clinch, drive knee up through center, squeeze core", "High Knee Drive"),
        ex("Elbow Strike Combo", 3, 10, 15, "Various angles", "Bodyweight", "Arms", "Triceps", ["Core", "Shoulders"], "intermediate", "Horizontal slash, upward cut, downward strike - rotate hips each time", "Elbow Strike Drill"),
        ex("Clinch Knee Drill", 3, 10, 15, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Core", "Shoulders", "Quadriceps"], "intermediate", "Simulate clinch grip, alternate driving knees up, pull down on clinch", "Knee Drive from Stance"),
        ex("Conditioning Sprawl", 3, 8, 30, "Explosive", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Explosive hip drop to sprawl position, pop back up to fighting stance", "Burpee"),
    ])

def wing_chun_basics_flow():
    return wo("Wing Chun Basics Drill", "strength", 40, [
        ex("Siu Nim Tao First Form Drill", 3, 5, 0, "Full form slowly", "Bodyweight", "Arms", "Forearm Flexors", ["Triceps", "Shoulders"], "beginner", "Stand in IRAS stance, perform tan sau, wu sau, fook sau slowly with structure", "Standing Arm Drill"),
        ex("Chain Punch Drill (Lin Wan Kuen)", 3, 20, 10, "Rapid alternating", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core"], "intermediate", "Rapid alternating vertical fist punches along centerline, relax shoulders", "Speed Punching"),
        ex("Pak Sau (Slapping Block) Drill", 3, 12, 10, "Each hand", "Bodyweight", "Arms", "Forearm Flexors", ["Core", "Shoulders"], "beginner", "Quick slapping deflection to inside or outside gate, followed by punch", "Parry Drill"),
        ex("IRAS Stance (Yee Ji Kim Yeung Ma) Hold", 3, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hip Adductors", ["Quadriceps", "Core"], "beginner", "Toes pigeon-toed, knees driving inward, spine erect, shoulders relaxed", "Narrow Squat Hold"),
        ex("Bong Sau / Tan Sau Alternating Drill", 3, 10, 0, "Each arm", "Bodyweight", "Arms", "Shoulders", ["Forearm Flexors", "Core"], "intermediate", "Alternate between bong sau (wing arm) and tan sau (palm up block)", "Arm Circle Drill"),
        ex("Pivoting (Chum Kiu Turn)", 3, 8, 0, "180 degree pivots", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Calves"], "intermediate", "Pivot on heels 180 degrees while maintaining structure, add bong sau", "Pivot Squat"),
        ex("Wall Bag Punching (Shadow)", 3, 15, 15, "Controlled impact", "Bodyweight", "Arms", "Forearm Flexors", ["Triceps", "Core"], "intermediate", "Punch with proper vertical fist structure, focus on wrist alignment", "Heavy Bag Punching"),
    ])

def kushti_wrestling_flow():
    return wo("Kushti Wrestling Fitness", "strength", 50, [
        ex("Hindu Squats (Baithak)", 3, 20, 30, "Continuous rhythm", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Heels lift at bottom, swing arms for momentum, deep squat, rapid pace", "Bodyweight Squat"),
        ex("Hindu Push-Ups (Dand)", 3, 12, 30, "Flowing movement", "Bodyweight", "Full Body", "Pectoralis Major", ["Shoulders", "Triceps", "Core"], "intermediate", "Dive forward from pike, swoop chest through, press up to cobra, reverse", "Dive Bomber Push-Up"),
        ex("Bridge Hold (Phalwani Bridge)", 3, 1, 0, "Hold 30 seconds", "Bodyweight", "Back", "Erector Spinae", ["Neck", "Glutes", "Shoulders"], "intermediate", "Wrestler's bridge on head and feet, strengthen neck and back", "Glute Bridge"),
        ex("Rope Climbing Drill", 3, 5, 30, "Full ascent", "Climbing Rope", "Back", "Latissimus Dorsi", ["Biceps", "Forearm Flexors", "Core"], "intermediate", "Grip rope overhead, pull body up, use legs to lock, repeat", "Pull-Up"),
        ex("Mace Swing (Gada) / Sledgehammer Tire", 3, 10, 20, "Each direction", "Mace/Sledgehammer", "Full Body", "Shoulders", ["Core", "Forearm Flexors", "Obliques"], "intermediate", "Swing mace behind head and around, full shoulder rotation, grip tight", "Medicine Ball Slam"),
        ex("Mud Pit Conditioning (Bear Crawl)", 3, 1, 0, "30 seconds forward and back", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps", "Hip Flexors"], "intermediate", "Low bear crawl position, crawl forward and backward, stay close to ground", "Bear Crawl"),
        ex("Neck Harness / Manual Neck Resistance", 3, 10, 15, "All directions", "Bodyweight", "Neck", "Sternocleidomastoid", ["Trapezius", "Scalenes"], "intermediate", "Resist neck flexion, extension, and lateral flexion with hand pressure", "Neck Isometric Hold"),
    ])

def mallakhamb_training_flow():
    return wo("Mallakhamb Training", "strength", 50, [
        ex("Pole Climbing Drill", 3, 5, 30, "Controlled ascent/descent", "Pole/Pull-up Bar", "Full Body", "Latissimus Dorsi", ["Biceps", "Forearm Flexors", "Core"], "intermediate", "Grip pole, use legs and arms to climb, control descent, build grip", "Rope Climb"),
        ex("Hanging Leg Raise on Pole", 3, 8, 20, "Full range", "Pull-up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Forearm Flexors"], "intermediate", "Hang from bar/pole, raise legs to horizontal or higher, lower slowly", "Hanging Knee Raise"),
        ex("Flag Hold Prep (Side Lever)", 3, 1, 0, "Hold 10 seconds each side", "Pull-up Bar", "Core", "Obliques", ["Latissimus Dorsi", "Shoulders"], "advanced", "Grip pole/bar, extend body sideways, build toward full flag", "Side Plank"),
        ex("Inverted Hang (Pole/Bar)", 2, 1, 0, "Hold 15 seconds", "Pull-up Bar", "Core", "Core", ["Shoulders", "Forearm Flexors"], "intermediate", "Hook legs on bar, hang inverted, engage core, build confidence", "Inverted Row"),
        ex("Deep Hindu Squats (Baithak)", 3, 20, 30, "Rhythmic", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Heels lift at bottom, arms swing, deep squat, continuous rhythm", "Bodyweight Squat"),
        ex("L-Sit Hold (Floor or Bar)", 3, 1, 0, "Hold 15 seconds", "Pull-up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Triceps"], "intermediate", "Support body on hands, lift legs to horizontal, compress core", "Tuck L-Sit"),
        ex("Bridge Push-Up", 3, 5, 20, "Lower and press", "Bodyweight", "Back", "Erector Spinae", ["Shoulders", "Glutes", "Triceps"], "advanced", "Full bridge position, lower head toward floor, press back up", "Glute Bridge"),
    ])


# ============================================================
# PROGRAM DEFINITIONS
# ============================================================

all_programs = []

# --- YOGA (17 programs) ---
all_programs.append(("Yoga for Beginners", "Yoga", [2, 4, 8], [3, 4], "High",
    "A gentle introduction to fundamental yoga poses, breathing, and mindfulness for complete beginners",
    lambda w, t: [yoga_beginner_flow()] * max(3, min(t, 4))))

all_programs.append(("Yoga for Athletes", "Yoga", [2, 4, 8], [3, 4], "High",
    "Sport-specific yoga flows targeting tight hips, hamstrings, and shoulders common in athletes",
    lambda w, t: [yoga_athlete_flow()] * max(3, min(t, 4))))

all_programs.append(("Hatha Yoga", "Yoga", [2, 4, 8], [3, 4], "High",
    "Traditional Hatha yoga with sustained holds, alignment focus, and pranayama breathing",
    lambda w, t: [hatha_yoga_flow()] * max(3, min(t, 4))))

all_programs.append(("Ashtanga Basics", "Yoga", [4, 8, 12], [5, 6], "Med",
    "Introduction to the Ashtanga Primary Series with sun salutations, standing, and seated sequences",
    lambda w, t: [ashtanga_basics_flow()] * max(5, min(t, 6))))

all_programs.append(("Hot Yoga Style", "Yoga", [2, 4, 8], [3, 4], "Med",
    "Bikram-inspired 26-posture series adapted for home practice with deep holds and backbends",
    lambda w, t: [hot_yoga_flow()] * max(3, min(t, 4))))

all_programs.append(("Yoga for Flexibility", "Yoga", [2, 4, 8], [4, 5], "High",
    "Progressive flexibility training through deep stretching yoga poses with long holds",
    lambda w, t: [yoga_flexibility_flow()] * max(4, min(t, 5))))

all_programs.append(("Kundalini Awakening", "Yoga", [2, 4, 8], [4, 5], "Med",
    "Kundalini yoga combining breath work, chanting, dynamic movements, and meditation kriyas",
    lambda w, t: [kundalini_flow()] * max(4, min(t, 5))))

all_programs.append(("Aerial Yoga Prep", "Yoga", [2, 4], [3], "Low",
    "Build the upper body and core strength needed for aerial yoga with grip, inversions, and shoulder prep",
    lambda w, t: [aerial_yoga_prep_flow()] * 3))

all_programs.append(("Yoga Nidra", "Yoga", [1, 2, 4], [5, 6, 7], "Med",
    "Deep yogic sleep practice combining body scanning, breathwork, and guided relaxation",
    lambda w, t: [yoga_nidra_flow()] * max(5, min(t, 7))))

all_programs.append(("Chair Yoga", "Yoga", [1, 2, 4], [4, 5], "High",
    "Accessible yoga using a chair for support, ideal for limited mobility or office environments",
    lambda w, t: [chair_yoga_flow()] * max(4, min(t, 5))))

all_programs.append(("Wall Yoga", "Yoga", [1, 2, 4], [4, 5], "Med",
    "Wall-supported yoga for alignment feedback, balance assistance, and deeper stretching",
    lambda w, t: [wall_yoga_flow()] * max(4, min(t, 5))))

all_programs.append(("Somatic Yoga", "Yoga", [2, 4, 8], [3, 4], "Med",
    "Slow somatic movement combined with yoga to release chronic tension and improve body awareness",
    lambda w, t: [somatic_yoga_flow()] * max(3, min(t, 4))))

all_programs.append(("Yoga for Back Pain", "Yoga", [1, 2, 4, 8], [4, 5], "High",
    "Therapeutic yoga targeting lower and upper back pain relief through gentle poses and stretches",
    lambda w, t: [yoga_back_pain_flow()] * max(4, min(t, 5))))

all_programs.append(("Yoga for Neck & Shoulders", "Yoga", [1, 2, 4], [5, 6], "High",
    "Targeted yoga for neck tension and shoulder tightness from desk work and poor posture",
    lambda w, t: [yoga_neck_shoulders_flow()] * max(5, min(t, 6))))

all_programs.append(("Yoga for Hips", "Yoga", [1, 2, 4, 8], [4, 5], "High",
    "Deep hip-opening yoga sequence targeting all hip muscles for greater range of motion",
    lambda w, t: [yoga_hips_flow()] * max(4, min(t, 5))))

all_programs.append(("Yoga for Runners", "Yoga", [2, 4, 8], [3, 4], "Med",
    "Runner-specific yoga addressing tight calves, hamstrings, hip flexors, and IT band",
    lambda w, t: [yoga_runners_flow()] * max(3, min(t, 4))))

all_programs.append(("Prenatal Yoga", "Yoga", [4, 8, 12], [3, 4], "High",
    "Safe pregnancy yoga with modified poses, pelvic floor work, and relaxation for each trimester",
    lambda w, t: [prenatal_yoga_flow()] * max(3, min(t, 4))))

# --- PILATES (8 programs) ---
all_programs.append(("Pilates for Beginners", "Pilates", [2, 4, 8], [3, 4], "High",
    "Introduction to Pilates fundamentals including the Hundred, Roll Up, and core engagement basics",
    lambda w, t: [pilates_beginner_flow()] * max(3, min(t, 4))))

all_programs.append(("Pilates Core Intensive", "Pilates", [2, 4, 8], [4, 5], "High",
    "Advanced core training using classical Pilates exercises for deep abdominal strength and control",
    lambda w, t: [pilates_core_intensive()] * max(4, min(t, 5))))

all_programs.append(("Pilates Reformer Style", "Pilates", [2, 4, 8], [3, 4], "Med",
    "Reformer-inspired exercises adapted for mat practice with similar movement patterns and resistance concepts",
    lambda w, t: [pilates_reformer_style()] * max(3, min(t, 4))))

all_programs.append(("Classical Pilates", "Pilates", [4, 8], [4, 5], "Med",
    "Full classical Pilates mat order following Joseph Pilates original 34-exercise sequence",
    lambda w, t: [classical_pilates_flow()] * max(4, min(t, 5))))

all_programs.append(("Wall Pilates", "Pilates", [1, 2, 4], [4, 5], "High",
    "Pilates exercises using the wall for resistance, alignment, and support in standing and lying positions",
    lambda w, t: [wall_pilates_flow()] * max(4, min(t, 5))))

all_programs.append(("Pilates for Seniors", "Pilates", [2, 4, 8], [3], "Med",
    "Gentle Pilates for older adults focusing on core stability, balance, and joint mobility with chair and mat work",
    lambda w, t: [pilates_seniors_flow()] * 3))

all_programs.append(("Power Pilates", "Pilates", [2, 4, 8], [4, 5], "Med",
    "High-intensity Pilates with advanced exercises including Teaser III, Control Balance, and Star Side Plank",
    lambda w, t: [power_pilates_flow()] * max(4, min(t, 5))))

all_programs.append(("Pilates & Stretch Fusion", "Pilates", [2, 4, 8], [3, 4], "Low",
    "Fusion of Pilates core work with deep stretching for flexibility, combining strength and suppleness",
    lambda w, t: [pilates_stretch_fusion()] * max(3, min(t, 4))))

# --- MARTIAL ARTS (10 programs) ---
all_programs.append(("Tai Chi Basics", "Martial Arts", [2, 4, 8], [4, 5], "High",
    "Fundamental Tai Chi movements including Grasp Sparrow's Tail, Cloud Hands, and Single Whip forms",
    lambda w, t: [tai_chi_basics_flow()] * max(4, min(t, 5))))

all_programs.append(("Tai Chi for Seniors", "Martial Arts", [2, 4, 8], [3, 4], "High",
    "Gentle Tai Chi for balance, fall prevention, and joint health with simplified forms and weight shifting",
    lambda w, t: [tai_chi_seniors_flow()] * max(3, min(t, 4))))

all_programs.append(("Karate Conditioning", "Martial Arts", [4, 8, 12], [4, 5], "Med",
    "Karate-inspired conditioning with punching drills, kicks, stances, and full-body functional strength",
    lambda w, t: [karate_conditioning_flow()] * max(4, min(t, 5))))

all_programs.append(("Taekwondo Basics", "Martial Arts", [4, 8, 12], [4, 5], "Med",
    "Fundamental Taekwondo kicking techniques, stances, and conditioning drills for explosive power",
    lambda w, t: [taekwondo_basics_flow()] * max(4, min(t, 5))))

all_programs.append(("Capoeira Fundamentals", "Martial Arts", [4, 8], [3, 4], "Low",
    "Brazilian martial art combining dance, acrobatics, and music with ginga, kicks, and ground movements",
    lambda w, t: [capoeira_fundamentals_flow()] * max(3, min(t, 4))))

all_programs.append(("Aikido Movement", "Martial Arts", [4, 8], [3, 4], "Low",
    "Aikido movement practice with body turning, rolling falls, entering steps, and blending drills",
    lambda w, t: [aikido_movement_flow()] * max(3, min(t, 4))))

all_programs.append(("Muay Thai Conditioning", "Martial Arts", [4, 8, 12], [4, 5], "High",
    "Thai boxing conditioning with punch-kick combos, knee strikes, elbow work, and clinch drills",
    lambda w, t: [muay_thai_conditioning_flow()] * max(4, min(t, 5))))

all_programs.append(("Wing Chun Basics", "Martial Arts", [4, 8], [4, 5], "Low",
    "Wing Chun kung fu basics including chain punches, centerline theory, Siu Nim Tao form, and chi sau concepts",
    lambda w, t: [wing_chun_basics_flow()] * max(4, min(t, 5))))

all_programs.append(("Kushti Wrestling Fitness", "Martial Arts", [4, 8, 12], [5, 6], "Low",
    "Traditional Indian wrestling fitness with Hindu squats, Hindu push-ups, bridges, mace swings, and rope climbing",
    lambda w, t: [kushti_wrestling_flow()] * max(5, min(t, 6))))

all_programs.append(("Mallakhamb Training", "Martial Arts", [4, 8, 12], [4, 5], "Low",
    "Indian pole gymnastics training building grip, core, and upper body strength with climbing and holds",
    lambda w, t: [mallakhamb_training_flow()] * max(4, min(t, 5))))


# ============================================================
# GENERATE ALL PROGRAMS
# ============================================================

success_count = 0
skip_count = 0
fail_count = 0

for prog_name, cat, durs, sessions_list, pri, desc, workout_fn in all_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP: {prog_name}")
        skip_count += 1
        continue

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
            workouts = workout_fn(w, max(sessions_list))
            weeks[w] = {"focus": focus, "workouts": workouts}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks

    # Determine split type
    if cat in ("Yoga", "Pilates"):
        split_override = "flow"
    else:
        split_override = "sport_specific"

    mn = helper.get_next_migration_num()
    ok = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if ok:
        print(f"DONE: {prog_name}")
        success_count += 1
    else:
        print(f"FAIL: {prog_name}")
        fail_count += 1

helper.close()
print(f"\n=== YOGA/PILATES/MARTIAL ARTS BATCH COMPLETE ===")
print(f"Success: {success_count} | Skipped: {skip_count} | Failed: {fail_count}")
print(f"Total: {success_count + skip_count + fail_count} / {len(all_programs)}")
