#!/usr/bin/env python3
"""Generate Lift Mobility (14), Social/Community (8), and Seasonal/Climate (9) programs."""
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

# ========== LIFT MOBILITY WORKOUT FUNCTIONS ==========

def deadlift_mobility_prep(w, t):
    return [wo("Deadlift Mobility Prep", "flexibility", 20, [
        ex("Foam Roll Thoracic Spine", 2, 10, 0, "Slow passes", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner", "Roll from mid-back to upper back, pause on tight spots", "Lacrosse Ball T-Spine"),
        ex("Banded Hip Distraction", 2, 1, 0, "Hold 45s each side", "Resistance Band", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Anchor band at hip crease, rock forward and back", "Hip Flexor Stretch"),
        ex("90/90 Hip Switch", 2, 8, 0, "Controlled tempo", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Flexors", "Adductors"], "beginner", "Keep tall spine, switch smoothly", "Seated Hip Rotation"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Kettlebell Prying Goblet Squat", 2, 8, 0, "Light weight", "Kettlebell", "Hips", "Adductors", ["Hip Flexors"], "intermediate", "Hold bottom position, use elbows to push knees out", "Bodyweight Deep Squat Hold"),
        ex("Single-Leg Romanian Deadlift Hold", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Maintain neutral spine, slight knee bend", "Standing Hamstring Stretch"),
    ])] * max(t, 1)

def squat_mobility_prep(w, t):
    return [wo("Squat Mobility Prep", "flexibility", 20, [
        ex("Foam Roll Quads", 2, 10, 0, "Slow passes", "Foam Roller", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Roll from hip to just above knee, pause on knots", "Lacrosse Ball Quad"),
        ex("Ankle Dorsiflexion Mobilization", 2, 10, 0, "Each side", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Knee over toe, heel stays down", "Wall Ankle Stretch"),
        ex("Deep Squat Hold", 2, 1, 0, "Hold 45s", "Bodyweight", "Hips", "Hip Flexors", ["Adductors", "Glutes"], "beginner", "Elbows push knees out, chest up", "Assisted Squat Hold"),
        ex("Banded Ankle Distraction", 2, 10, 0, "Each side", "Resistance Band", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Band pulls ankle back, drive knee forward", "Wall Ankle Mobilization"),
        ex("Cossack Squat", 2, 6, 0, "Alternating", "Bodyweight", "Legs", "Adductors", ["Quadriceps", "Glutes"], "intermediate", "Sit deep to one side, straight opposite leg", "Lateral Lunge"),
        ex("World's Greatest Stretch", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine"], "beginner", "Lunge, rotate, reach to ceiling", "Spiderman Stretch"),
    ])] * max(t, 1)

def bench_press_mobility(w, t):
    return [wo("Bench Press Mobility", "flexibility", 20, [
        ex("Foam Roll Lats", 2, 10, 0, "Each side", "Foam Roller", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Roll from armpit to mid-rib, arm overhead", "Lacrosse Ball Lat"),
        ex("Pec Doorway Stretch", 2, 1, 0, "Hold 45s each side", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Elbow at 90 degrees, lean through doorway", "Floor Pec Stretch"),
        ex("Thoracic Extension on Roller", 2, 10, 0, "Controlled", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner", "Hands behind head, extend over roller", "Chair Thoracic Extension"),
        ex("Banded Pull-Apart", 2, 15, 0, "Light band", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rhomboids", "Rotator Cuff"], "beginner", "Arms straight, squeeze shoulder blades", "Reverse Fly"),
        ex("Banded External Rotation", 2, 12, 0, "Each arm", "Resistance Band", "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner", "Elbow pinned to side, rotate outward", "Cable External Rotation"),
        ex("Scapular Push-up", 2, 10, 0, "Slow tempo", "Bodyweight", "Back", "Serratus Anterior", ["Trapezius"], "beginner", "Plank position, protract and retract scapulae", "Wall Scapular Slide"),
    ])] * max(t, 1)

def overhead_press_mobility(w, t):
    return [wo("Overhead Press Mobility", "flexibility", 20, [
        ex("Lacrosse Ball Pec Minor Release", 2, 1, 0, "60s each side", "Lacrosse Ball", "Chest", "Pectoralis Minor", ["Anterior Deltoid"], "beginner", "Pin ball below collarbone, apply pressure", "Foam Roll Chest"),
        ex("Wall Slide", 2, 10, 0, "Slow tempo", "Bodyweight", "Shoulders", "Serratus Anterior", ["Lower Trapezius"], "beginner", "Back flat on wall, slide arms up maintaining contact", "Floor Slide"),
        ex("Banded Shoulder Flexion", 2, 10, 0, "Light band", "Resistance Band", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Band anchored low, raise arms overhead with control", "Dowel Overhead Press"),
        ex("Thread the Needle", 2, 8, 0, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques"], "beginner", "Reach under and through, then open up to ceiling", "Seated Thoracic Rotation"),
        ex("PNF Overhead Stretch", 2, 3, 0, "Contract-relax each side", "Bodyweight", "Shoulders", "Latissimus Dorsi", ["Teres Major"], "intermediate", "Contract 5s, relax and stretch deeper", "Passive Overhead Stretch"),
        ex("Bottoms-Up Kettlebell Hold", 2, 1, 0, "Hold 20s each side", "Kettlebell", "Shoulders", "Rotator Cuff", ["Deltoids", "Forearms"], "intermediate", "Light KB, maintain vertical alignment", "Banded Overhead Hold"),
    ])] * max(t, 1)

def post_deadlift_recovery(w, t):
    return [wo("Post-Deadlift Recovery", "flexibility", 20, [
        ex("Foam Roll Lower Back", 2, 10, 0, "Gentle pressure", "Foam Roller", "Back", "Erector Spinae", ["Quadratus Lumborum"], "beginner", "Roll around lower back, avoid direct spine pressure", "Lacrosse Ball Glute Release"),
        ex("Child's Pose", 2, 1, 0, "Hold 60s", "Bodyweight", "Back", "Latissimus Dorsi", ["Erector Spinae"], "beginner", "Knees wide, reach arms forward, sink hips back", "Puppy Pose"),
        ex("Supine Figure-4 Stretch", 2, 1, 0, "Hold 45s each side", "Bodyweight", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "Cross ankle over knee, pull bottom knee to chest", "Seated Piriformis Stretch"),
        ex("Lying Hamstring Stretch with Band", 2, 1, 0, "Hold 45s each side", "Resistance Band", "Legs", "Hamstrings", ["Calves"], "beginner", "Leg straight up, use band to pull gently", "Standing Hamstring Stretch"),
        ex("Crocodile Breathing", 2, 5, 0, "Deep breaths", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Prone position, breathe into belly against floor", "Supine Diaphragmatic Breathing"),
        ex("Spinal Twist", 2, 1, 0, "Hold 45s each side", "Bodyweight", "Back", "Obliques", ["Erector Spinae"], "beginner", "Supine, knees to one side, arms opposite", "Seated Spinal Twist"),
    ])] * max(t, 1)

def post_squat_recovery(w, t):
    return [wo("Post-Squat Recovery", "flexibility", 20, [
        ex("Foam Roll IT Band", 2, 10, 0, "Each side", "Foam Roller", "Legs", "IT Band", ["Vastus Lateralis"], "beginner", "Roll from hip to just above knee", "Lacrosse Ball TFL"),
        ex("Couch Stretch", 2, 1, 0, "Hold 60s each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Rectus Femoris"], "beginner", "Rear knee against wall, squeeze glute of back leg", "Half Kneeling Hip Flexor Stretch"),
        ex("Seated Adductor Stretch", 2, 1, 0, "Hold 45s", "Bodyweight", "Legs", "Adductors", ["Hamstrings"], "beginner", "Sit tall, soles together, press knees toward floor", "Standing Adductor Stretch"),
        ex("Quad Foam Roll", 2, 10, 0, "Each side", "Foam Roller", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Slow rolls, pause on tight spots", "Lacrosse Ball Quad"),
        ex("Standing Calf Stretch", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Heel pressed down, lean into wall", "Step Calf Stretch"),
        ex("Supine Knee to Chest", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Back", "Erector Spinae", ["Glutes"], "beginner", "Pull one knee to chest, keep other leg flat", "Double Knee to Chest"),
    ])] * max(t, 1)

def post_leg_day_recovery(w, t):
    return [wo("Post-Leg Day Recovery", "flexibility", 20, [
        ex("Foam Roll Glutes", 2, 10, 0, "Each side", "Foam Roller", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Sit on roller, cross ankle over knee, roll glute", "Lacrosse Ball Glute"),
        ex("Standing Quad Stretch", 2, 1, 0, "Hold 45s each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, keep knees together", "Prone Quad Stretch"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60s each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Front shin across, fold forward", "Figure-4 Stretch"),
        ex("Hamstring PNF Stretch", 2, 3, 0, "Contract-relax each side", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "intermediate", "Contract 5s against resistance, relax and deepen", "Passive Hamstring Stretch"),
        ex("Ankle Circle", 2, 10, 0, "Each direction each foot", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Full range of motion circles", "Ankle Pump"),
        ex("Legs Up the Wall", 2, 1, 0, "Hold 2 minutes", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Scoot close to wall, legs vertical, relax", "Elevated Leg Rest"),
    ])] * max(t, 1)

def post_pull_day_recovery(w, t):
    return [wo("Post-Pull Day Recovery", "flexibility", 20, [
        ex("Foam Roll Lats", 2, 10, 0, "Each side", "Foam Roller", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Lie on side, arm overhead, roll lat area", "Lacrosse Ball Lat"),
        ex("Cross-Body Shoulder Stretch", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Rhomboids"], "beginner", "Pull arm across chest, feel back of shoulder stretch", "Doorway Rear Delt Stretch"),
        ex("Bicep Wall Stretch", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Arms", "Biceps", ["Forearms"], "beginner", "Place palm on wall behind you, turn body away", "Doorway Bicep Stretch"),
        ex("Foam Roll Upper Back", 2, 10, 0, "Slow rolls", "Foam Roller", "Back", "Rhomboids", ["Trapezius"], "beginner", "Arms crossed, roll upper back area", "Lacrosse Ball Upper Back"),
        ex("Wrist Flexor Stretch", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Arms", "Forearm Flexors", ["Wrist"], "beginner", "Extend arm, pull fingers back gently", "Prayer Stretch"),
        ex("Child's Pose with Side Reach", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Back", "Latissimus Dorsi", ["Obliques"], "beginner", "Walk hands to each side for lateral lat stretch", "Lat Stretch on Rack"),
    ])] * max(t, 1)

def post_push_day_recovery(w, t):
    return [wo("Post-Push Day Recovery", "flexibility", 20, [
        ex("Foam Roll Pecs", 2, 10, 0, "Each side", "Foam Roller", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Lie face down on roller angled under pec", "Lacrosse Ball Pec Release"),
        ex("Doorway Pec Stretch", 2, 1, 0, "Hold 45s each side", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm at 90 degrees in doorframe, step through", "Floor Pec Stretch"),
        ex("Overhead Tricep Stretch", 2, 1, 0, "Hold 30s each side", "Bodyweight", "Arms", "Triceps", ["Shoulders"], "beginner", "Reach behind head, use other hand to press elbow", "Tricep Wall Stretch"),
        ex("Foam Roll Triceps", 2, 10, 0, "Each side", "Foam Roller", "Arms", "Triceps", ["Shoulders"], "beginner", "Arm extended, roll from elbow to armpit area", "Lacrosse Ball Tricep"),
        ex("Prone Y-T-W Raises", 2, 8, 0, "Light or no weight", "Bodyweight", "Shoulders", "Lower Trapezius", ["Rear Deltoid", "Rotator Cuff"], "beginner", "Lie face down, arms in Y then T then W shapes", "Band Pull-Apart"),
        ex("Thoracic Rotation", 2, 8, 0, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques"], "beginner", "Side-lying, rotate top arm open to the floor", "Seated Thoracic Rotation"),
    ])] * max(t, 1)

def hip_hinge_mastery(w, t):
    return [wo("Hip Hinge Mastery", "flexibility", 25, [
        ex("Dowel Hip Hinge", 3, 10, 30, "Dowel on spine", "Dowel", "Back", "Erector Spinae", ["Hamstrings", "Glutes"], "beginner", "Maintain 3 points of contact: head, upper back, tailbone", "Broomstick Hip Hinge"),
        ex("Romanian Deadlift with Pause", 3, 8, 45, "Light weight", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Pause 2s at bottom, feel hamstring stretch", "Bodyweight RDL"),
        ex("Pull-Through", 3, 12, 30, "Cable or band", "Cable Machine", "Hips", "Glutes", ["Hamstrings"], "beginner", "Hinge back, snap hips forward with squeeze", "Banded Pull-Through"),
        ex("Good Morning", 3, 10, 45, "Light to moderate", "Barbell", "Back", "Hamstrings", ["Erector Spinae", "Glutes"], "intermediate", "Bar on back, hinge forward maintaining flat back", "Banded Good Morning"),
        ex("Kettlebell Swing", 3, 12, 30, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap, not a squat, KB to eye level", "Dumbbell Swing"),
        ex("Single-Leg RDL", 3, 8, 30, "Light weight each side", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Reach back leg and torso in one line", "B-Stance RDL"),
    ])] * max(t, 1)

def powerlifter_mobility(w, t):
    return [wo("Powerlifter Mobility", "flexibility", 30, [
        ex("Foam Roll Full Body", 2, 15, 0, "All major areas", "Foam Roller", "Full Body", "Various", ["Various"], "beginner", "Quads, IT band, lats, thoracic, calves - 2 min each", "Lacrosse Ball Release"),
        ex("Banded Hip Distraction", 2, 1, 0, "Hold 60s each side", "Resistance Band", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Band at hip crease, stretch in multiple directions", "Hip Flexor Stretch"),
        ex("Banded Shoulder Distraction", 2, 1, 0, "Hold 45s each side", "Resistance Band", "Shoulders", "Rotator Cuff", ["Deltoids"], "beginner", "Band pulls arm across, open chest", "PNF Shoulder Stretch"),
        ex("Loaded Goblet Squat Hold", 2, 1, 0, "Hold 45s", "Kettlebell", "Hips", "Hip Flexors", ["Adductors", "Quadriceps"], "intermediate", "Sit deep, elbows push knees out", "Deep Squat Hold"),
        ex("Jefferson Curl", 2, 6, 0, "Very light or bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings"], "intermediate", "Slowly round down vertebra by vertebra", "Standing Toe Touch"),
        ex("PNF Hamstring Stretch", 2, 3, 0, "Contract-relax each side", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "intermediate", "Contract 6s, relax 10s deeper stretch", "Passive Hamstring Stretch"),
        ex("Thoracic Spine Extension on Roller", 2, 10, 0, "Controlled", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner", "Hands behind head, extend over roller segment by segment", "Chair Thoracic Extension"),
    ])] * max(t, 1)

def olympic_lift_mobility(w, t):
    return [wo("Olympic Lift Mobility", "flexibility", 30, [
        ex("Overhead Squat with Dowel", 3, 8, 30, "Dowel or PVC", "Dowel", "Full Body", "Shoulders", ["Quadriceps", "Core"], "intermediate", "Wide grip, sit deep, arms locked overhead", "Wall Overhead Squat"),
        ex("Banded Lat Stretch", 2, 1, 0, "Hold 60s each side", "Resistance Band", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Band high, hinge and let band stretch lat", "Hanging Lat Stretch"),
        ex("Ankle Dorsiflexion with Band", 2, 10, 0, "Each side", "Resistance Band", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Band pulls ankle back, drive knee over toe", "Wall Ankle Mobilization"),
        ex("Sotts Press", 3, 6, 30, "Empty bar or dowel", "Barbell", "Shoulders", "Deltoids", ["Trapezius", "Core"], "advanced", "Press overhead while in deep squat position", "Dowel Sotts Press"),
        ex("Wrist Flexibility Circles", 2, 10, 0, "All directions", "Bodyweight", "Arms", "Forearm Extensors", ["Forearm Flexors"], "beginner", "On all fours, rotate wrists in circles", "Wrist Flexion/Extension"),
        ex("Front Rack Stretch", 2, 1, 0, "Hold 45s", "Barbell", "Shoulders", "Latissimus Dorsi", ["Triceps", "Wrist"], "intermediate", "Bar in rack position, push elbows up high", "Banded Front Rack Stretch"),
        ex("Hip Flexor PAILs/RAILs", 2, 3, 0, "Contract-relax each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas"], "intermediate", "Isometric contraction into stretch, then deepen", "Half-Kneeling Hip Flexor Stretch"),
    ])] * max(t, 1)

def tight_hamstring_fix(w, t):
    return [wo("Tight Hamstring Fix", "flexibility", 25, [
        ex("Foam Roll Hamstrings", 2, 10, 0, "Each side", "Foam Roller", "Legs", "Hamstrings", ["Calves"], "beginner", "Roll from glute to just above knee, cross other leg on top for pressure", "Lacrosse Ball Hamstring"),
        ex("Active Straight Leg Raise", 3, 8, 0, "Each side", "Bodyweight", "Legs", "Hamstrings", ["Hip Flexors"], "beginner", "Lie supine, raise straight leg as high as possible under control", "Banded Leg Raise"),
        ex("Romanian Deadlift Stretch", 3, 8, 30, "Light weight", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Slow eccentric, feel deep hamstring stretch at bottom", "Bodyweight RDL Stretch"),
        ex("PNF Hamstring Contract-Relax", 2, 4, 0, "Each side", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "intermediate", "Contract 6s pushing leg into hand, relax 10s deeper", "Passive Hamstring Stretch"),
        ex("Sciatic Nerve Floss", 2, 8, 0, "Each side", "Bodyweight", "Legs", "Hamstrings", ["Sciatic Nerve"], "beginner", "Seated, extend knee while looking up, flex while looking down", "Seated Hamstring Stretch"),
        ex("Forward Fold with Bent Knees", 2, 1, 0, "Hold 60s", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Slight knee bend, hang and relax, gradually straighten legs", "Ragdoll Hang"),
        ex("Elevated Hamstring Stretch", 2, 1, 0, "Hold 45s each side", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Foot on bench, hinge forward from hips", "Standing Hamstring Stretch"),
    ])] * max(t, 1)

def lower_back_relief(w, t):
    return [wo("Lower Back Relief for Lifters", "flexibility", 25, [
        ex("Foam Roll Glutes & Piriformis", 2, 10, 0, "Each side", "Foam Roller", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "Sit on roller, cross one leg over, roll deep into glute", "Lacrosse Ball Piriformis"),
        ex("McGill Big 3 - Curl-Up", 3, 8, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Hands under low back, curl only shoulders off floor", "Dead Bug"),
        ex("McGill Big 3 - Side Plank", 3, 1, 30, "Hold 20s each side", "Bodyweight", "Core", "Obliques", ["Quadratus Lumborum"], "beginner", "Elbow and knees, straight line, brief holds", "Modified Side Plank"),
        ex("McGill Big 3 - Bird Dog", 3, 8, 30, "Alternating", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Core"], "beginner", "Opposite arm and leg extend, maintain neutral spine", "Dead Bug"),
        ex("Supine Spinal Twist", 2, 1, 0, "Hold 45s each side", "Bodyweight", "Back", "Obliques", ["Erector Spinae"], "beginner", "Knees to one side, arms out, relax into twist", "Seated Spinal Twist"),
        ex("Cat-Cow", 2, 10, 0, "Slow flow", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Exaggerate each position, breathe fully", "Seated Cat-Cow"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 60s each side", "Bodyweight", "Hips", "Psoas", ["Rectus Femoris"], "beginner", "Half kneeling, squeeze back glute, shift forward", "Couch Stretch"),
    ])] * max(t, 1)


# ========== SOCIAL/COMMUNITY WORKOUT FUNCTIONS ==========

def run_club_ready(w, t):
    return [wo("Run Club Ready", "conditioning", 40, [
        ex("Tempo Run Intervals", 4, 1, 60, "Moderate pace 3-5 min", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Maintain conversational pace, consistent stride", "Brisk Walk Intervals"),
        ex("Walking Lunge", 3, 12, 30, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, knee hovers above ground", "Reverse Lunge"),
        ex("A-Skip Drill", 3, 20, 30, "Moderate pace", "Bodyweight", "Legs", "Hip Flexors", ["Calves"], "beginner", "Drive knee high, quick foot strike", "High Knees"),
        ex("Single-Leg Calf Raise", 3, 12, 30, "Each side", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full range, pause at top", "Double Calf Raise"),
        ex("Glute Bridge", 3, 15, 30, "Squeeze at top", "Bodyweight", "Hips", "Glutes", ["Hamstrings"], "beginner", "Drive through heels, full hip extension", "Hip Thrust"),
        ex("Plank", 3, 1, 30, "Hold 30s", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line head to heels", "Forearm Plank"),
    ])] * max(t, 1)

def couples_fitness(w, t):
    return [wo("Couples Fitness", "strength", 40, [
        ex("Partner Wall Sit Hold", 3, 1, 45, "Hold 30s, switch roles", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "One partner wall sits while other does push-ups, swap", "Bodyweight Squat Hold"),
        ex("Partner Plank High-Five", 3, 10, 30, "Alternating hands", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Obliques"], "beginner", "Face each other in plank, alternate high fives", "Standard Plank"),
        ex("Dumbbell Goblet Squat", 3, 12, 45, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold DB at chest, full depth squat", "Bodyweight Squat"),
        ex("Push-up", 3, 12, 30, "Sync pace with partner", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, chest to floor", "Knee Push-up"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Hinge forward, pull to hip", "Bodyweight Row"),
        ex("Partner Russian Twist Pass", 3, 15, 30, "With medicine ball", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Sit back-to-back, rotate and pass ball", "Solo Russian Twist"),
        ex("Bodyweight Squat Jump", 3, 8, 45, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, jump together", "Bodyweight Squat"),
    ])] * max(t, 1)

def group_class_ready(w, t):
    return [wo("Group Class Ready", "conditioning", 35, [
        ex("Burpee", 3, 8, 30, "Full burpee", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, explosive jump up", "Squat Thrust"),
        ex("Bodyweight Squat", 3, 15, 20, "Quick tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, chest up", "Chair Squat"),
        ex("Mountain Climber", 3, 20, 20, "Fast pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders", "Core"], "beginner", "Rapid alternating knee drives", "Plank Knee Tuck"),
        ex("Jump Squat", 3, 10, 30, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, max height jump", "Bodyweight Squat"),
        ex("Push-up to T-Rotation", 3, 8, 30, "Alternating", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Shoulders"], "intermediate", "Push-up then rotate to side plank, alternate", "Standard Push-up"),
        ex("Jumping Lunge", 3, 10, 30, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Switch legs in air, soft landing", "Reverse Lunge"),
    ])] * max(t, 1)

def accountability_partner(w, t):
    return [wo("Accountability Partner Plan", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 90, "70-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Partner spots, full depth, chest up", "Goblet Squat"),
        ex("Barbell Bench Press", 4, 8, 90, "70-80% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Partner spots, touch chest, drive up", "Dumbbell Bench Press"),
        ex("Barbell Row", 3, 10, 60, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge 45 degrees, pull to lower chest", "Dumbbell Row"),
        ex("Overhead Press", 3, 10, 60, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Strict press, full lockout overhead", "Dumbbell Shoulder Press"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, bar close to legs", "Dumbbell RDL"),
        ex("Plank with Shoulder Tap", 3, 12, 30, "Alternating", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Minimize hip rotation, tap opposite shoulder", "Standard Plank"),
    ])] * max(t, 1)

def social_walking(w, t):
    return [wo("Social Walking Group", "conditioning", 35, [
        ex("Brisk Walking Intervals", 4, 1, 30, "3 min brisk, 1 min easy", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Glutes"], "beginner", "Maintain upright posture, arms swinging", "Steady Walk"),
        ex("Walking Lunge", 3, 10, 30, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, knee hovers above ground", "Step-up"),
        ex("Standing Calf Raise on Curb", 3, 15, 20, "Use curb edge", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Hang heels off edge, rise fully", "Flat Calf Raise"),
        ex("Park Bench Step-up", 3, 10, 30, "Each side", "Bench", "Legs", "Quadriceps", ["Glutes"], "beginner", "Drive through top foot, full stand at top", "Reverse Lunge"),
        ex("Park Bench Incline Push-up", 3, 10, 30, "Hands on bench", "Bench", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Body straight, lower chest to bench", "Knee Push-up"),
        ex("Standing Side Leg Raise", 3, 12, 20, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Flexors"], "beginner", "Controlled lift, don't lean excessively", "Banded Side Walk"),
    ])] * max(t, 1)

def gym_buddy_workouts(w, t):
    return [wo("Gym Buddy Workouts", "strength", 45, [
        ex("Dumbbell Bench Press", 4, 10, 60, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full range, partner counts reps", "Push-up"),
        ex("Lat Pulldown", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull to upper chest, squeeze lats", "Pull-up"),
        ex("Leg Press", 3, 12, 60, "Moderate weight", "Leg Press", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full range, don't lock knees at top", "Goblet Squat"),
        ex("Dumbbell Lateral Raise", 3, 12, 30, "Light to moderate", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Trapezius"], "beginner", "Slight elbow bend, raise to shoulder height", "Cable Lateral Raise"),
        ex("Cable Tricep Pushdown", 3, 12, 30, "Moderate weight", "Cable Machine", "Arms", "Triceps", ["Forearms"], "beginner", "Elbows pinned, full extension", "Dumbbell Kickback"),
        ex("Dumbbell Bicep Curl", 3, 12, 30, "Moderate weight", "Dumbbell", "Arms", "Biceps", ["Forearms"], "beginner", "Full range, no swinging", "Hammer Curl"),
        ex("Ab Wheel Rollout", 3, 8, 30, "Controlled", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Extend as far as controlled, roll back", "Plank"),
    ])] * max(t, 1)

def virtual_group_training(w, t):
    return [wo("Virtual Group Training", "strength", 40, [
        ex("Bodyweight Squat", 3, 15, 20, "Tempo 3-1-1", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, count tempo together on screen", "Chair Squat"),
        ex("Push-up", 3, 12, 20, "Standard", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range of motion, elbows 45 degrees", "Knee Push-up"),
        ex("Reverse Lunge", 3, 10, 20, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, knee hovers above floor", "Step Back"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Hinge forward, pull to hip", "Bodyweight Row"),
        ex("Glute Bridge March", 3, 12, 20, "Alternating", "Bodyweight", "Hips", "Glutes", ["Hamstrings", "Core"], "beginner", "Hold bridge, lift one foot at a time", "Glute Bridge"),
        ex("Dead Bug", 3, 10, 20, "Alternating", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Low back pressed to floor, opposite arm and leg extend", "Bird Dog"),
        ex("Jumping Jack", 3, 20, 20, "Moderate pace", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full arm extension, land soft", "Step Jack"),
    ])] * max(t, 1)

def team_sport_fitness(w, t):
    return [wo("Team Sport Fitness", "conditioning", 45, [
        ex("Lateral Shuffle", 3, 10, 30, "Each direction", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves"], "beginner", "Low athletic stance, quick feet, stay low", "Side Step"),
        ex("Box Jump", 3, 8, 45, "20-24 inch", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Explosive jump, soft landing, step down", "Squat Jump"),
        ex("Medicine Ball Rotational Throw", 3, 8, 30, "Each side", "Medicine Ball", "Core", "Obliques", ["Hip Rotators"], "intermediate", "Rotate from hips, release at chest height", "Russian Twist"),
        ex("Sprint Intervals", 4, 1, 60, "30s sprint, 60s rest", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "90% effort sprints with full recovery", "High Knees"),
        ex("Agility Ladder Drill", 3, 6, 30, "Various patterns", "Agility Ladder", "Legs", "Calves", ["Hip Flexors", "Quadriceps"], "intermediate", "Quick feet, stay on balls of feet", "Cone Drill"),
        ex("Broad Jump", 3, 6, 45, "Max distance", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Swing arms, explode forward, stick landing", "Squat Jump"),
    ])] * max(t, 1)


# ========== SEASONAL/CLIMATE WORKOUT FUNCTIONS ==========

def cold_weather_fitness(w, t):
    return [wo("Cold Weather Fitness", "strength", 40, [
        ex("Dynamic Warm-up March", 3, 20, 15, "Moderate pace", "Bodyweight", "Full Body", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "High knees with arm swings, extended warm-up for cold muscles", "Jog in Place"),
        ex("Dumbbell Goblet Squat", 4, 10, 45, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold DB at chest, full depth, extra warm-up sets", "Bodyweight Squat"),
        ex("Push-up", 3, 12, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Elbows 45 degrees, chest to floor", "Knee Push-up"),
        ex("Dumbbell Romanian Deadlift", 3, 10, 45, "Moderate weight", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Slow eccentric, feel stretch", "Bodyweight RDL"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Hinge forward, pull to hip", "Bodyweight Row"),
        ex("Mountain Climber", 3, 15, 20, "Moderate pace to stay warm", "Bodyweight", "Core", "Hip Flexors", ["Shoulders", "Core"], "beginner", "Keep continuous movement to maintain warmth", "High Knees"),
    ])] * max(t, 1)

def monsoon_indoor(w, t):
    return [wo("Monsoon Indoor Training", "strength", 40, [
        ex("Bodyweight Squat", 3, 15, 20, "Full depth", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Chest up, full range of motion", "Chair Squat"),
        ex("Push-up", 3, 12, 20, "Standard", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range, elbows 45 degrees", "Knee Push-up"),
        ex("Dumbbell Lunge", 3, 10, 30, "Alternating", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, upright torso", "Bodyweight Lunge"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Moderate weight", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full lockout, control the descent", "Pike Push-up"),
        ex("Glute Bridge", 3, 15, 20, "Squeeze at top", "Bodyweight", "Hips", "Glutes", ["Hamstrings"], "beginner", "Drive through heels, full hip extension", "Hip Thrust"),
        ex("Plank", 3, 1, 20, "Hold 30s", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core, straight line", "Forearm Plank"),
        ex("Burpee", 3, 8, 30, "Full burpee", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump up", "Squat Thrust"),
    ])] * max(t, 1)

def winter_maintenance(w, t):
    return [wo("Winter Maintenance", "strength", 40, [
        ex("Barbell Back Squat", 4, 8, 90, "70% 1RM maintenance", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Maintain strength, focus on form, extended warm-up", "Goblet Squat"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full range, controlled tempo", "Push-up"),
        ex("Cable Row", 3, 12, 45, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Squeeze shoulder blades, controlled return", "Dumbbell Row"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Moderate weight", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full lockout, slow negative", "Barbell Press"),
        ex("Leg Curl", 3, 12, 30, "Moderate weight", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Controlled tempo, squeeze at peak", "Nordic Curl"),
        ex("Plank", 3, 1, 30, "Hold 30s", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core, no sagging", "Forearm Plank"),
    ])] * max(t, 1)

def spring_fitness_kickoff(w, t):
    return [wo("Spring Fitness Kickoff", "conditioning", 40, [
        ex("Bodyweight Squat", 3, 15, 20, "Build back up", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, re-establish movement patterns", "Chair Squat"),
        ex("Push-up", 3, 12, 20, "Standard", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, rebuild pushing endurance", "Knee Push-up"),
        ex("Dumbbell Lunge", 3, 10, 30, "Light to moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, upright posture", "Bodyweight Lunge"),
        ex("Dumbbell Row", 3, 10, 30, "Light to moderate each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Hinge forward, pull to hip", "Bodyweight Row"),
        ex("High Knees", 3, 20, 20, "Outdoor if possible", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees high, pump arms", "Marching"),
        ex("Jumping Jack", 3, 25, 20, "Moderate pace", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full extension, enjoy the fresh air", "Step Jack"),
        ex("Glute Bridge", 3, 15, 20, "Bodyweight", "Bodyweight", "Hips", "Glutes", ["Hamstrings"], "beginner", "Reactivate glutes after winter", "Hip Thrust"),
    ])] * max(t, 1)

def fall_training_peak(w, t):
    return [wo("Fall Training Peak", "strength", 45, [
        ex("Barbell Back Squat", 4, 6, 120, "80-85% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Peak strength phase, push intensity", "Goblet Squat"),
        ex("Barbell Bench Press", 4, 6, 120, "80-85% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Peak pressing strength", "Dumbbell Bench Press"),
        ex("Barbell Deadlift", 4, 5, 120, "80-85% 1RM", "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "intermediate", "Strong hip drive, lockout at top", "Trap Bar Deadlift"),
        ex("Weighted Pull-up", 3, 6, 90, "Add weight via belt", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Full dead hang to chin over bar", "Lat Pulldown"),
        ex("Overhead Press", 3, 8, 60, "Moderate to heavy", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Strict press, full lockout", "Dumbbell Press"),
        ex("Barbell Row", 3, 8, 60, "Moderate to heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull to lower chest", "Dumbbell Row"),
    ])] * max(t, 1)

def humidity_adaptation(w, t):
    return [wo("Humidity Adaptation", "conditioning", 35, [
        ex("Bodyweight Squat", 3, 12, 30, "Moderate tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stay hydrated, rest as needed in humidity", "Chair Squat"),
        ex("Push-up", 3, 10, 30, "Standard", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Wipe hands between sets for grip in humidity", "Knee Push-up"),
        ex("Walking Lunge", 3, 8, 30, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Shorter session to manage heat stress", "Reverse Lunge"),
        ex("Dumbbell Row", 3, 10, 30, "Light to moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Chalk or towel for grip", "Bodyweight Row"),
        ex("Glute Bridge", 3, 12, 20, "Bodyweight", "Bodyweight", "Hips", "Glutes", ["Hamstrings"], "beginner", "Towel under shoulders for sweat management", "Hip Thrust"),
        ex("Plank", 3, 1, 30, "Hold 20s", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Shorter holds, focus on breathing in humidity", "Forearm Plank"),
    ])] * max(t, 1)

def altitude_training_prep(w, t):
    return [wo("Altitude Training Prep", "conditioning", 40, [
        ex("Nasal Breathing Walk", 3, 1, 30, "3 min walk, nose only", "Bodyweight", "Full Body", "Diaphragm", ["Calves", "Quadriceps"], "beginner", "Breathe exclusively through nose, build CO2 tolerance", "Steady Walk"),
        ex("Bodyweight Squat", 3, 12, 45, "Moderate pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Extended rest periods to simulate altitude recovery", "Chair Squat"),
        ex("Box Step-up", 3, 10, 45, "Each side", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Drive through top foot, full stand", "Step-up"),
        ex("Push-up", 3, 10, 45, "Standard", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Focus on breathing rhythm during reps", "Knee Push-up"),
        ex("Farmer's Walk", 3, 1, 45, "Walk 30s moderate weight", "Dumbbell", "Full Body", "Forearms", ["Trapezius", "Core"], "beginner", "Upright posture, steady breathing", "Bodyweight Walk"),
        ex("Diaphragmatic Breathing", 3, 5, 0, "Deep belly breaths", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "4 count in, 6 count out, belly expands", "Box Breathing"),
    ])] * max(t, 1)

def indoor_winter_alt(w, t):
    return [wo("Indoor Winter Alternative", "strength", 40, [
        ex("Dumbbell Goblet Squat", 4, 10, 45, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold DB at chest, full depth", "Bodyweight Squat"),
        ex("Dumbbell Bench Press", 3, 10, 45, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full range, controlled tempo", "Push-up"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Hinge forward, pull to hip", "Inverted Row"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Moderate weight", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full lockout, controlled descent", "Pike Push-up"),
        ex("Dumbbell Romanian Deadlift", 3, 10, 45, "Moderate weight", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Hinge at hips, feel hamstring stretch", "Single-Leg RDL"),
        ex("Jumping Jack", 3, 25, 20, "Quick pace for indoor cardio", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full arm extension, keep moving for warmth", "Step Jack"),
        ex("Plank", 3, 1, 30, "Hold 30s", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core, straight line", "Forearm Plank"),
    ])] * max(t, 1)

def year_round_outdoor(w, t):
    return [wo("Year-Round Outdoor", "conditioning", 45, [
        ex("Outdoor Jog", 3, 1, 60, "3-5 min intervals", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Adjust pace for weather, maintain steady rhythm", "Brisk Walk"),
        ex("Park Bench Step-up", 3, 10, 30, "Each side", "Bench", "Legs", "Quadriceps", ["Glutes"], "beginner", "Drive through top foot, full stand at top", "Walking Lunge"),
        ex("Park Bench Incline Push-up", 3, 12, 30, "Hands on bench", "Bench", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Body straight, chest to bench", "Standard Push-up"),
        ex("Inverted Row on Bar", 3, 10, 45, "Outdoor bar", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Body straight, pull chest to bar", "Dumbbell Row"),
        ex("Hill Sprint", 3, 6, 60, "Sprint up, walk down", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Short hill, 80-90% effort, walk recovery", "Flat Sprint"),
        ex("Squat Jump", 3, 8, 30, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, max height", "Bodyweight Squat"),
        ex("Outdoor Plank", 3, 1, 30, "Hold 30s", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Hands on flat ground, straight line", "Forearm Plank"),
    ])] * max(t, 1)


# ========== PROGRAM DEFINITIONS ==========

all_programs = []

# --- LIFT MOBILITY (14) ---
all_programs.append(("Deadlift Mobility Prep", "Lift Mobility", [1, 2, 4], [3, 4], "High",
    "Pre-deadlift mobility drills targeting hip hinge, thoracic spine, and hamstring flexibility",
    deadlift_mobility_prep, "flow"))

all_programs.append(("Squat Mobility Prep", "Lift Mobility", [1, 2, 4], [3, 4], "High",
    "Pre-squat mobility drills for ankle, hip, and thoracic spine mobility",
    squat_mobility_prep, "flow"))

all_programs.append(("Bench Press Mobility", "Lift Mobility", [1, 2, 4], [3, 4], "High",
    "Shoulder and thoracic preparation for bench pressing with pec and rotator cuff work",
    bench_press_mobility, "flow"))

all_programs.append(("Overhead Press Mobility", "Lift Mobility", [1, 2, 4], [3, 4], "High",
    "Shoulder mobility for overhead pressing including lat, thoracic, and rotator cuff drills",
    overhead_press_mobility, "flow"))

all_programs.append(("Post-Deadlift Recovery", "Lift Mobility", [1, 2], [3], "Med",
    "Recovery work after deadlifts targeting lower back, glutes, and hamstrings",
    post_deadlift_recovery, "flow"))

all_programs.append(("Post-Squat Recovery", "Lift Mobility", [1, 2], [3], "Med",
    "Recovery mobility work after squats for quads, hips, and IT band",
    post_squat_recovery, "flow"))

all_programs.append(("Post-Leg Day Recovery", "Lift Mobility", [1, 2], [3], "Med",
    "Comprehensive leg day recovery with foam rolling, stretching, and PNF",
    post_leg_day_recovery, "flow"))

all_programs.append(("Post-Pull Day Recovery", "Lift Mobility", [1, 2], [3], "Med",
    "Recovery work after back and bicep sessions targeting lats, biceps, and forearms",
    post_pull_day_recovery, "flow"))

all_programs.append(("Post-Push Day Recovery", "Lift Mobility", [1, 2], [3], "Med",
    "Recovery work after chest and shoulder sessions targeting pecs, triceps, and thoracic spine",
    post_push_day_recovery, "flow"))

all_programs.append(("Hip Hinge Mastery", "Lift Mobility", [2, 4], [4, 5], "High",
    "Master the hip hinge movement pattern through progressive drills and loaded stretches",
    hip_hinge_mastery, "flow"))

all_programs.append(("Powerlifter Mobility", "Lift Mobility", [2, 4, 8], [4, 5], "High",
    "Comprehensive mobility program for powerlifters addressing squat, bench, and deadlift restrictions",
    powerlifter_mobility, "flow"))

all_programs.append(("Olympic Lift Mobility", "Lift Mobility", [2, 4, 8], [5, 6], "High",
    "Olympic weightlifting mobility for overhead squat, front rack, and deep catch positions",
    olympic_lift_mobility, "flow"))

all_programs.append(("Tight Hamstring Fix", "Lift Mobility", [2, 4, 8], [5, 6], "Med",
    "Progressive hamstring flexibility program using foam rolling, PNF, and loaded stretching",
    tight_hamstring_fix, "flow"))

all_programs.append(("Lower Back Relief for Lifters", "Lift Mobility", [2, 4, 8], [4, 5], "High",
    "Back pain prevention for lifters using McGill Big 3, foam rolling, and hip mobility",
    lower_back_relief, "flow"))

# --- SOCIAL/COMMUNITY (8) ---
all_programs.append(("Run Club Ready", "Social/Community Fitness", [4, 8, 12], [3, 4], "High",
    "Preparation program for group running with tempo runs, drills, and lower body strength",
    run_club_ready, "full_body"))

all_programs.append(("Couples Fitness", "Social/Community Fitness", [4, 8, 12], [3, 4], "High",
    "Partner workout program with shared exercises, synchronized movements, and mutual spotting",
    couples_fitness, "full_body"))

all_programs.append(("Group Class Ready", "Social/Community Fitness", [2, 4], [3, 4], "Med",
    "Fitness class preparation building endurance and movement quality for group exercise",
    group_class_ready, "full_body"))

all_programs.append(("Accountability Partner Plan", "Social/Community Fitness", [4, 8, 12], [4, 5], "High",
    "Structured partner accountability program with complementary exercises and mutual spotting",
    accountability_partner, "full_body"))

all_programs.append(("Social Walking Group", "Social/Community Fitness", [4, 8], [3, 4, 5], "Med",
    "Walking-based fitness program combining brisk walks with bodyweight exercises in parks",
    social_walking, "full_body"))

all_programs.append(("Gym Buddy Workouts", "Social/Community Fitness", [4, 8], [3, 4], "Med",
    "Partner gym workout program with shared equipment and alternating sets",
    gym_buddy_workouts, "full_body"))

all_programs.append(("Virtual Group Training", "Social/Community Fitness", [4, 8], [4, 5], "Med",
    "Online group fitness program with synchronized bodyweight and dumbbell exercises",
    virtual_group_training, "full_body"))

all_programs.append(("Team Sport Fitness", "Social/Community Fitness", [4, 8], [3, 4], "Med",
    "Team sport conditioning with agility, explosiveness, and sport-specific movements",
    team_sport_fitness, "full_body"))

# --- SEASONAL/CLIMATE (9) ---
all_programs.append(("Cold Weather Fitness", "Seasonal/Climate Training", [2, 4, 8], [4, 5], "High",
    "Training adapted for cold weather with extended warm-ups and indoor-friendly exercises",
    cold_weather_fitness, "full_body"))

all_programs.append(("Monsoon Indoor Training", "Seasonal/Climate Training", [2, 4, 8], [4, 5], "High",
    "Indoor workout program for rainy seasons using bodyweight and dumbbells",
    monsoon_indoor, "full_body"))

all_programs.append(("Winter Maintenance", "Seasonal/Climate Training", [4, 8, 12], [3, 4], "High",
    "Maintain fitness levels during winter with gym-based strength and conditioning",
    winter_maintenance, "full_body"))

all_programs.append(("Spring Fitness Kickoff", "Seasonal/Climate Training", [4, 8], [4, 5], "Med",
    "Spring fitness restart program rebuilding base fitness after winter with outdoor elements",
    spring_fitness_kickoff, "full_body"))

all_programs.append(("Fall Training Peak", "Seasonal/Climate Training", [4, 8, 12], [4, 5], "High",
    "Peak training block during fall weather for maximum strength and performance gains",
    fall_training_peak, "full_body"))

all_programs.append(("Humidity Adaptation", "Seasonal/Climate Training", [2, 4], [3, 4], "Med",
    "Training adaptations for humid conditions with shorter sessions and hydration focus",
    humidity_adaptation, "full_body"))

all_programs.append(("Altitude Training Prep", "Seasonal/Climate Training", [4, 8], [4, 5], "Med",
    "Altitude acclimatization prep with breathing drills and aerobic capacity building",
    altitude_training_prep, "full_body"))

all_programs.append(("Indoor Winter Alternative", "Seasonal/Climate Training", [4, 8, 12], [4, 5], "High",
    "Complete indoor training alternative for harsh winter conditions using dumbbells and bodyweight",
    indoor_winter_alt, "full_body"))

all_programs.append(("Year-Round Outdoor", "Seasonal/Climate Training", [8, 12, 16], [4, 5], "Med",
    "All-season outdoor training program using parks, trails, and outdoor equipment",
    year_round_outdoor, "full_body"))


# ========== EXECUTE ALL ==========

print("=== Starting Lift Mobility + Social/Community + Seasonal/Climate batch ===\n")

success = 0
skipped = 0
failed = 0

for entry in all_programs:
    prog_name, cat, durs, sessions_list, pri, desc = entry[0], entry[1], entry[2], entry[3], entry[4], entry[5]
    workout_fn = entry[6]
    split_override = entry[7] if len(entry) > 7 else None

    if helper.check_program_exists(prog_name):
        print(f"SKIP: {prog_name}")
        skipped += 1
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
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks

    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s:
        print(f"DONE: {prog_name}")
        success += 1
    else:
        print(f"FAIL: {prog_name}")
        failed += 1

helper.close()
print(f"\n=== BATCH COMPLETE: {success} done, {skipped} skipped, {failed} failed ===")
