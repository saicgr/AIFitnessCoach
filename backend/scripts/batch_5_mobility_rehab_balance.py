#!/usr/bin/env python3
"""
Batch 5: Mobility, Warmup, Stretching, Rehab, Posture, Balance programs.
59 total programs across 6 categories.
"""

from exercise_lib import *


###############################################################################
# MOBILITY (20 programs) - Lift-specific and general mobility
###############################################################################

def _deadlift_mobility_prep():
    return [workout("Deadlift Mobility Prep", "mobility", 20, [
        FOAM_ROLL_BACK(),
        ex("Foam Roll Glutes", 1, 1, 10, "60 seconds each side", "Foam Roller", "Glutes",
           "Gluteus Maximus", ["Piriformis"], "beginner",
           "Sit on roller, cross ankle over knee, roll", "Pigeon Pose"),
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll from glutes to knee", "Hamstring Stretch"),
        HIP_90_90(),
        WORLD_GREATEST_STRETCH(),
        HIP_FLEXOR_STRETCH(),
        ex("Cat-Cow", 2, 10, 15, "Flow with breath", "Bodyweight", "Back",
           "Erector Spinae", ["Core", "Thoracic Spine"], "beginner",
           "Inhale arch, exhale round, slow rhythm", "Seated Spinal Flex"),
        ex("Banded Hip Distraction", 2, 1, 10, "Hold 30-60 seconds each side", "Resistance Band",
           "Hips", "Hip Joint", ["Surrounding Muscles"], "beginner",
           "Band around hip, step away for distraction", "Hip Flexor Stretch"),
        ex("Inchworm Walkout", 2, 6, 15, "Slow and controlled", "Bodyweight", "Full Body",
           "Hamstrings", ["Core", "Shoulders"], "beginner",
           "Hinge at hips, walk hands out to plank, walk back", "Standing Forward Fold"),
    ])]

def _squat_mobility_prep():
    return [workout("Squat Mobility Prep", "mobility", 20, [
        FOAM_ROLL_QUAD(),
        ex("Foam Roll Adductors", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Adductors", ["Inner Thigh"], "beginner",
           "Face down, leg out to side on roller, roll inner thigh", "Adductor Stretch"),
        ex("Ankle Dorsiflexion Mobilization", 2, 10, 15, "Per ankle", "Bodyweight", "Ankles",
           "Ankle Joint", ["Calves", "Tibialis Anterior"], "beginner",
           "Knee over toe in lunge position, drive knee forward", "Calf Stretch"),
        HIP_90_90(),
        WORLD_GREATEST_STRETCH(),
        ex("Deep Squat Hold", 2, 1, 15, "Hold 30 seconds", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Adductors", "Ankles"], "beginner",
           "Sit in deep squat, elbows push knees out, chest up", "Goblet Squat Hold"),
        HIP_FLEXOR_STRETCH(),
        BANDED_DISTRACTION("Hip"),
        ex("Goblet Squat Prying", 2, 8, 15, "Light weight, hold at bottom", "Dumbbell", "Legs",
           "Quadriceps", ["Glutes", "Adductors"], "beginner",
           "Sit in deep squat, use elbows to pry knees open", "Deep Squat Hold"),
    ])]

def _bench_press_mobility():
    return [workout("Bench Press Mobility", "mobility", 15, [
        FOAM_ROLL_BACK(),
        ex("Foam Roll Lats", 1, 1, 10, "60 seconds each side", "Foam Roller", "Back",
           "Latissimus Dorsi", ["Teres Major"], "beginner",
           "Side lying, roller under armpit, roll slowly", "Lat Stretch"),
        ex("Foam Roll Pecs", 1, 1, 10, "60 seconds each side", "Lacrosse Ball", "Chest",
           "Pectoralis Major", ["Pectoralis Minor"], "beginner",
           "Ball against wall or floor, roll chest muscles", "Doorway Chest Stretch"),
        THORACIC_EXTENSION(),
        WALL_ANGEL(),
        ex("Band Dislocates", 2, 10, 15, "Light band or PVC pipe", "Resistance Band", "Shoulders",
           "Rotator Cuff", ["Rear Deltoid", "Pectoralis Minor"], "beginner",
           "Wide grip, rotate band overhead and behind back", "Band Pull-Apart"),
        ex("Doorway Pec Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Chest",
           "Pectoralis Major", ["Anterior Deltoid"], "beginner",
           "Forearm on door frame, lean through, feel chest stretch", "Floor Chest Stretch"),
        BAND_PULL_APART(),
    ])]

def _overhead_press_mobility():
    return [workout("Overhead Press Mobility", "mobility", 15, [
        FOAM_ROLL_BACK(),
        ex("Foam Roll Lats", 1, 1, 10, "60 seconds each side", "Foam Roller", "Back",
           "Latissimus Dorsi", ["Teres Major"], "beginner",
           "Side lying, roller under armpit, roll slowly", "Lat Stretch"),
        THORACIC_EXTENSION(),
        WALL_ANGEL(),
        ex("Band Dislocates", 2, 12, 15, "Wide grip band or PVC pipe", "Resistance Band", "Shoulders",
           "Rotator Cuff", ["Rear Deltoid"], "beginner",
           "Rotate band overhead and behind back, keep arms straight", "Band Pull-Apart"),
        ex("Lat Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Back",
           "Latissimus Dorsi", ["Teres Major"], "beginner",
           "Grab door frame or rig, lean away, feel lat stretch", "Child's Pose"),
        ex("Banded Shoulder Distraction", 2, 1, 10, "Hold 30 seconds each arm", "Resistance Band",
           "Shoulders", "Shoulder Joint", ["Rotator Cuff"], "beginner",
           "Band around wrist, arm overhead, step away for traction", "Band Dislocates"),
        BAND_PULL_APART(),
    ])]

def _post_deadlift_recovery():
    return [workout("Post-Deadlift Recovery", "flexibility", 20, [
        FOAM_ROLL_BACK(),
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll from glutes to knee", "Hamstring Stretch"),
        ex("Foam Roll Glutes", 1, 1, 10, "60 seconds each side", "Foam Roller", "Glutes",
           "Gluteus Maximus", ["Piriformis"], "beginner",
           "Cross ankle over knee, roll glute on foam roller", "Pigeon Pose"),
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot on bench, hinge forward, straight back", "Seated Forward Fold"),
        HIP_FLEXOR_STRETCH(),
        PIRIFOMIS_STRETCH(),
        stretch("Seated Spinal Twist", 30, "Back", "Erector Spinae",
                "Sit, cross one leg, twist toward raised knee, hold", "Supine Twist"),
        CHILDS_POSE(),
    ])]

def _post_squat_recovery():
    return [workout("Post-Squat Recovery", "flexibility", 20, [
        FOAM_ROLL_QUAD(),
        FOAM_ROLL_IT_BAND(),
        ex("Foam Roll Adductors", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Adductors", ["Inner Thigh"], "beginner",
           "Face down, leg out to side on roller, roll inner thigh", "Adductor Stretch"),
        stretch("Standing Quad Stretch", 30, "Legs", "Quadriceps",
                "Pull heel to glute, keep knees together, stand tall", "Couch Stretch"),
        HIP_FLEXOR_STRETCH(),
        stretch("Adductor Stretch", 30, "Legs", "Adductors",
                "Wide stance, shift weight to one side, feel inner thigh stretch", "Butterfly Stretch"),
        ex("Calf Stretch", 2, 1, 10, "Hold 30 seconds each leg", "Bodyweight", "Legs",
           "Calves", ["Soleus"], "beginner",
           "Foot against wall, lean forward, feel calf stretch", "Seated Calf Stretch"),
        CHILDS_POSE(),
    ])]

def _post_leg_day_recovery():
    return [workout("Post-Leg Day Recovery", "flexibility", 25, [
        FOAM_ROLL_QUAD(),
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll from glutes to knee", "Hamstring Stretch"),
        FOAM_ROLL_IT_BAND(),
        ex("Foam Roll Calves", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Calves", ["Soleus"], "beginner",
           "Cross one leg over for pressure, roll calf", "Calf Stretch"),
        stretch("Standing Quad Stretch", 30, "Legs", "Quadriceps",
                "Pull heel to glute, keep knees together", "Couch Stretch"),
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot elevated on bench, hinge forward", "Seated Forward Fold"),
        HIP_FLEXOR_STRETCH(),
        PIRIFOMIS_STRETCH(),
        stretch("Butterfly Stretch", 30, "Hips", "Adductors",
                "Soles together, press knees toward floor gently", "Adductor Stretch"),
        CHILDS_POSE(),
    ])]

def _post_pull_day_recovery():
    return [workout("Post-Pull Day Recovery", "flexibility", 20, [
        FOAM_ROLL_BACK(),
        ex("Foam Roll Lats", 1, 1, 10, "60 seconds each side", "Foam Roller", "Back",
           "Latissimus Dorsi", ["Teres Major"], "beginner",
           "Side lying, roller under armpit area, roll slowly", "Lat Stretch"),
        ex("Lat Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Back",
           "Latissimus Dorsi", ["Teres Major"], "beginner",
           "Grab overhead bar, lean away, feel lat stretch", "Child's Pose"),
        stretch("Bicep Wall Stretch", 30, "Arms", "Biceps",
                "Hand on wall behind you, rotate body away", "Doorway Bicep Stretch"),
        stretch("Forearm Stretch", 30, "Arms", "Forearms",
                "Arm extended, pull fingers back gently", "Wrist Flexion Stretch"),
        THORACIC_EXTENSION(),
        stretch("Seated Spinal Twist", 30, "Back", "Erector Spinae",
                "Sit, cross leg, twist toward raised knee", "Supine Twist"),
        CHILDS_POSE(),
    ])]

def _post_push_day_recovery():
    return [workout("Post-Push Day Recovery", "flexibility", 20, [
        ex("Foam Roll Pecs", 1, 1, 10, "60 seconds each side", "Lacrosse Ball", "Chest",
           "Pectoralis Major", ["Pectoralis Minor"], "beginner",
           "Ball against wall, roll chest area slowly", "Doorway Chest Stretch"),
        ex("Foam Roll Triceps", 1, 1, 10, "60 seconds each arm", "Foam Roller", "Arms",
           "Triceps", ["Long Head"], "beginner",
           "Arm out to side on roller, roll tricep area", "Tricep Stretch"),
        FOAM_ROLL_BACK(),
        ex("Doorway Pec Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Chest",
           "Pectoralis Major", ["Anterior Deltoid"], "beginner",
           "Forearm on door frame, lean through gently", "Floor Chest Stretch"),
        stretch("Overhead Tricep Stretch", 30, "Arms", "Triceps",
                "Arm overhead, pull elbow behind head", "Tricep Rope Stretch"),
        stretch("Cross-Body Shoulder Stretch", 30, "Shoulders", "Posterior Deltoid",
                "Pull arm across chest, hold at elbow", "Doorway Shoulder Stretch"),
        WALL_ANGEL(),
        CHILDS_POSE(),
    ])]

def _hip_hinge_mastery():
    return [workout("Hip Hinge Mastery", "mobility", 20, [
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll from glutes to knee", "Hamstring Stretch"),
        ex("Foam Roll Glutes", 1, 1, 10, "60 seconds each side", "Foam Roller", "Glutes",
           "Gluteus Maximus", ["Piriformis"], "beginner",
           "Cross ankle over knee, roll glute", "Pigeon Pose"),
        HIP_FLEXOR_STRETCH(),
        WORLD_GREATEST_STRETCH(),
        ex("Wall Hip Hinge Drill", 3, 10, 15, "Bodyweight only", "Bodyweight", "Hips",
           "Hamstrings", ["Glutes", "Erector Spinae"], "beginner",
           "Stand 6 inches from wall, push hips back to touch wall", "Good Morning"),
        ex("Dowel Hip Hinge", 3, 10, 15, "PVC pipe or broomstick", "Bodyweight", "Hips",
           "Hamstrings", ["Glutes", "Erector Spinae"], "beginner",
           "Dowel along spine, maintain 3 points of contact while hinging", "Wall Hip Hinge"),
        ex("Band Pull-Through", 3, 12, 30, "Light band", "Resistance Band", "Hips",
           "Glutes", ["Hamstrings"], "beginner",
           "Band anchored low behind, hip hinge, snap hips forward", "Cable Pull-Through"),
        HIP_90_90(),
    ])]

def _powerlifter_mobility():
    return [workout("Powerlifter Mobility", "mobility", 25, [
        FOAM_ROLL_BACK(),
        FOAM_ROLL_QUAD(),
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll from glutes to knee", "Hamstring Stretch"),
        THORACIC_EXTENSION(),
        WORLD_GREATEST_STRETCH(),
        HIP_90_90(),
        HIP_FLEXOR_STRETCH(),
        ex("Banded Shoulder Distraction", 2, 1, 10, "Hold 30 seconds each arm", "Resistance Band",
           "Shoulders", "Shoulder Joint", ["Rotator Cuff"], "beginner",
           "Band around wrist, arm overhead, step away", "Band Dislocates"),
        WALL_ANGEL(),
        ex("Deep Squat Hold", 2, 1, 15, "Hold 30-45 seconds", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Adductors", "Ankles"], "beginner",
           "Sit deep, elbows push knees out, chest up", "Goblet Squat Hold"),
    ])]

def _olympic_lift_mobility():
    return [workout("Olympic Lift Mobility", "mobility", 25, [
        FOAM_ROLL_BACK(),
        ex("Foam Roll Lats", 1, 1, 10, "60 seconds each side", "Foam Roller", "Back",
           "Latissimus Dorsi", ["Teres Major"], "beginner",
           "Side lying, roller under armpit, roll slowly", "Lat Stretch"),
        THORACIC_EXTENSION(),
        WALL_ANGEL(),
        ex("Band Dislocates", 2, 15, 15, "Light band or PVC pipe", "Resistance Band", "Shoulders",
           "Rotator Cuff", ["Rear Deltoid"], "beginner",
           "Rotate band overhead and behind, keep arms straight", "Band Pull-Apart"),
        ex("Overhead Squat Hold", 2, 1, 15, "Hold 30 seconds, PVC pipe", "Bodyweight", "Full Body",
           "Shoulders", ["Thoracic Spine", "Hips", "Ankles"], "intermediate",
           "Arms locked overhead, sit deep, chest up", "Deep Squat Hold"),
        ex("Ankle Dorsiflexion Mobilization", 2, 10, 15, "Per ankle", "Bodyweight", "Ankles",
           "Ankle Joint", ["Calves", "Tibialis Anterior"], "beginner",
           "Knee over toe in lunge, drive knee forward over toes", "Calf Stretch"),
        WORLD_GREATEST_STRETCH(),
        HIP_90_90(),
        BANDED_DISTRACTION("Hip"),
    ])]

def _tight_hamstring_fix():
    return [workout("Tight Hamstring Fix", "flexibility", 20, [
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, cross one leg for pressure", "Hamstring Stretch"),
        ex("Foam Roll Glutes", 1, 1, 10, "60 seconds each side", "Foam Roller", "Glutes",
           "Gluteus Maximus", ["Piriformis"], "beginner",
           "Cross ankle over knee, roll glute", "Pigeon Pose"),
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot on bench, hinge forward from hips, flat back", "Seated Forward Fold"),
        stretch("Seated Hamstring Stretch", 45, "Legs", "Hamstrings",
                "Legs extended, reach for toes, fold from hips", "Standing Forward Fold"),
        stretch("Lying Hamstring Stretch", 30, "Legs", "Hamstrings",
                "On back, pull straight leg toward chest with strap or hands", "Seated Hamstring Stretch"),
        PIRIFOMIS_STRETCH(),
        ex("Active Hamstring Stretch", 2, 8, 15, "Per leg, slow", "Bodyweight", "Legs",
           "Hamstrings", ["Hip Flexors"], "beginner",
           "On back, actively raise straight leg using hip flexors", "Lying Hamstring Stretch"),
        stretch("Downward Dog Hold", 45, "Legs", "Hamstrings",
                "Push hips up and back, pedal heels, straighten legs gradually", "Standing Forward Fold"),
    ])]

def _lower_back_relief_for_lifters():
    return [workout("Lower Back Relief for Lifters", "flexibility", 20, [
        FOAM_ROLL_BACK(),
        ex("Foam Roll Glutes", 1, 1, 10, "60 seconds each side", "Foam Roller", "Glutes",
           "Gluteus Maximus", ["Piriformis"], "beginner",
           "Cross ankle over knee, roll glute", "Pigeon Pose"),
        ex("Cat-Cow", 2, 10, 15, "Flow with breath", "Bodyweight", "Back",
           "Erector Spinae", ["Core", "Thoracic Spine"], "beginner",
           "Inhale arch, exhale round, slow rhythm", "Seated Spinal Flex"),
        CHILDS_POSE(),
        HIP_FLEXOR_STRETCH(),
        PIRIFOMIS_STRETCH(),
        DEAD_BUG(3, 8, 20, "Slow and controlled"),
        stretch("Knee-to-Chest Stretch", 30, "Back", "Erector Spinae",
                "Lie on back, pull both knees to chest, round lower back", "Child's Pose"),
        stretch("Supine Spinal Twist", 30, "Back", "Erector Spinae",
                "Lie back, knees to one side, arms out, look opposite", "Seated Spinal Twist"),
    ])]

def _hip_hinge_mobility():
    return [workout("Hip Hinge Mobility", "mobility", 20, [
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll from glutes to knee", "Hamstring Stretch"),
        ex("Foam Roll Glutes", 1, 1, 10, "60 seconds each side", "Foam Roller", "Glutes",
           "Gluteus Maximus", ["Piriformis"], "beginner",
           "Cross ankle over knee, roll glute", "Pigeon Pose"),
        HIP_90_90(),
        WORLD_GREATEST_STRETCH(),
        HIP_FLEXOR_STRETCH(),
        ex("Banded Good Morning", 2, 10, 20, "Light band around neck and under feet", "Resistance Band",
           "Hips", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner",
           "Hip hinge with band resistance, keep back flat", "Bodyweight Good Morning"),
        ex("Single-Leg Hip Hinge", 2, 8, 15, "Per leg, bodyweight", "Bodyweight", "Hips",
           "Hamstrings", ["Glutes", "Balance"], "intermediate",
           "One foot behind, hinge to touch floor, return", "Romanian Deadlift"),
        PIRIFOMIS_STRETCH(),
    ])]

def _thoracic_mobility():
    return [workout("Thoracic Mobility", "mobility", 20, [
        FOAM_ROLL_BACK(),
        THORACIC_EXTENSION(),
        ex("Side-Lying Thoracic Rotation", 2, 8, 15, "Per side", "Bodyweight", "Back",
           "Thoracic Spine", ["Obliques", "Chest"], "beginner",
           "Side lying, knees bent, rotate top arm open, follow with eyes", "Open Book Stretch"),
        ex("Cat-Cow", 2, 10, 15, "Flow with breath", "Bodyweight", "Back",
           "Erector Spinae", ["Core", "Thoracic Spine"], "beginner",
           "Inhale arch, exhale round", "Seated Spinal Flex"),
        WALL_ANGEL(),
        ex("Thread the Needle", 2, 8, 15, "Per side", "Bodyweight", "Back",
           "Thoracic Spine", ["Rhomboids", "Obliques"], "beginner",
           "On all fours, thread one arm under, rotate chest", "Seated Spinal Twist"),
        ex("Prone Y-T-W Raise", 2, 8, 15, "No weight, slow", "Bodyweight", "Back",
           "Scapular Stabilizers", ["Rear Deltoid", "Rhomboids"], "beginner",
           "Lie face down, raise arms in Y, T, then W shapes", "Band Pull-Apart"),
        stretch("Cross-Body Shoulder Stretch", 30, "Shoulders", "Posterior Deltoid",
                "Pull arm across chest, hold at elbow", "Doorway Shoulder Stretch"),
    ])]

def _hip_mobility_flow():
    return [workout("Hip Mobility Flow", "mobility", 20, [
        HIP_90_90(),
        WORLD_GREATEST_STRETCH(),
        HIP_FLEXOR_STRETCH(),
        PIRIFOMIS_STRETCH(),
        ex("Leg Swings (Front-Back)", 2, 15, 10, "Per leg", "Bodyweight", "Hips",
           "Hip Flexors", ["Hamstrings", "Glutes"], "beginner",
           "Hold wall, swing leg forward and back, controlled", "Walking Knee Hugs"),
        ex("Leg Swings (Side-Side)", 2, 15, 10, "Per leg", "Bodyweight", "Hips",
           "Adductors", ["Hip Abductors"], "beginner",
           "Hold wall, swing leg across body and out", "Lateral Leg Raise"),
        ex("Deep Squat Hold with Rotation", 2, 1, 15, "Hold 30 seconds", "Bodyweight", "Hips",
           "Quadriceps", ["Glutes", "Thoracic Spine"], "beginner",
           "In deep squat, rotate chest open each side", "Deep Squat Hold"),
        stretch("Butterfly Stretch", 45, "Hips", "Adductors",
                "Soles together, press knees toward floor, sit tall", "Adductor Stretch"),
        BANDED_DISTRACTION("Hip"),
    ])]

def _pre_squat_mobility():
    return [workout("Pre-Squat Mobility", "mobility", 15, [
        FOAM_ROLL_QUAD(),
        ex("Foam Roll Adductors", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Adductors", ["Inner Thigh"], "beginner",
           "Face down, leg out to side on roller, roll inner thigh", "Adductor Stretch"),
        ex("Ankle Dorsiflexion Mobilization", 2, 10, 15, "Per ankle", "Bodyweight", "Ankles",
           "Ankle Joint", ["Calves", "Tibialis Anterior"], "beginner",
           "Knee over toe in lunge, drive knee forward", "Calf Stretch"),
        HIP_90_90(),
        WORLD_GREATEST_STRETCH(),
        HIP_FLEXOR_STRETCH(),
        ex("Deep Squat Hold", 2, 1, 15, "Hold 30 seconds", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Adductors", "Ankles"], "beginner",
           "Sit deep, elbows push knees out, chest up", "Goblet Squat Hold"),
        BANDED_DISTRACTION("Hip"),
    ])]

def _general_lifting_warmup():
    return [workout("General Lifting Warmup", "warmup", 15, [
        ex("Light Jog or March in Place", 1, 1, 10, "2 minutes", "Bodyweight", "Full Body",
           "Cardiovascular", ["Legs"], "beginner",
           "Gradually increase pace, pump arms", "Jumping Jacks"),
        ex("Arm Circles", 2, 15, 10, "Forward and backward", "Bodyweight", "Shoulders",
           "Deltoids", ["Rotator Cuff"], "beginner",
           "Small circles to large, both directions", "Band Dislocates"),
        ex("Cat-Cow", 2, 8, 10, "Flow with breath", "Bodyweight", "Back",
           "Erector Spinae", ["Core"], "beginner",
           "Inhale arch, exhale round", "Seated Spinal Flex"),
        WORLD_GREATEST_STRETCH(),
        BAND_PULL_APART(),
        ex("Bodyweight Good Morning", 2, 10, 15, "Hip hinge, bodyweight only", "Bodyweight", "Hips",
           "Hamstrings", ["Glutes", "Erector Spinae"], "beginner",
           "Hands behind head, hinge at hips, flat back", "Wall Hip Hinge"),
        BODYWEIGHT_SQUAT(2, 10, 15, "Controlled, warm up joints"),
        ex("Glute Bridge March", 2, 10, 15, "Per side", "Bodyweight", "Glutes",
           "Gluteus Maximus", ["Core", "Hip Flexors"], "beginner",
           "In bridge position, alternate lifting feet", "Glute Bridge"),
    ])]

def _powerlifting_mobility():
    return [workout("Powerlifting Mobility", "mobility", 25, [
        FOAM_ROLL_BACK(),
        FOAM_ROLL_QUAD(),
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll slowly", "Hamstring Stretch"),
        THORACIC_EXTENSION(),
        WORLD_GREATEST_STRETCH(),
        HIP_90_90(),
        HIP_FLEXOR_STRETCH(),
        WALL_ANGEL(),
        ex("Band Dislocates", 2, 12, 15, "Light band", "Resistance Band", "Shoulders",
           "Rotator Cuff", ["Rear Deltoid"], "beginner",
           "Rotate band overhead and behind back", "Band Pull-Apart"),
        ex("Deep Squat Hold", 2, 1, 15, "Hold 30-45 seconds", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Adductors", "Ankles"], "beginner",
           "Sit deep, elbows push knees out", "Goblet Squat Hold"),
    ])]


###############################################################################
# WARMUP & COOLDOWN (5 programs)
###############################################################################

def _sports_warmup():
    return [workout("Sports Warmup", "warmup", 12, [
        ex("Light Jog", 1, 1, 10, "2 minutes", "Bodyweight", "Full Body",
           "Cardiovascular", ["Legs"], "beginner",
           "Easy pace, get blood flowing", "March in Place"),
        HIGH_KNEES(1, 20, 15, "30 seconds"),
        ex("Butt Kicks", 1, 20, 15, "30 seconds", "Bodyweight", "Legs",
           "Hamstrings", ["Calves", "Quadriceps"], "beginner",
           "Jog kicking heels to glutes, quick tempo", "High Knees"),
        ex("Lateral Shuffle", 1, 10, 15, "5 each direction", "Bodyweight", "Legs",
           "Adductors", ["Glutes", "Calves"], "beginner",
           "Athletic stance, shuffle side to side", "Lateral Band Walk"),
        ex("Leg Swings (Front-Back)", 1, 10, 10, "Per leg", "Bodyweight", "Hips",
           "Hip Flexors", ["Hamstrings"], "beginner",
           "Hold wall, swing leg forward and back", "Walking Knee Hugs"),
        WORLD_GREATEST_STRETCH(),
        ex("A-Skips", 1, 10, 15, "Per leg", "Bodyweight", "Full Body",
           "Hip Flexors", ["Calves", "Core"], "beginner",
           "Skip with high knee drive, opposite arm", "High Knees"),
        ex("Arm Circles", 2, 10, 10, "Forward and backward", "Bodyweight", "Shoulders",
           "Deltoids", ["Rotator Cuff"], "beginner",
           "Small to large circles, both directions", "Band Dislocates"),
    ])]

def _post_workout_cool_down():
    return [workout("Post-Workout Cool Down", "flexibility", 10, [
        ex("Light Walk", 1, 1, 10, "2 minutes, easy pace", "Bodyweight", "Full Body",
           "Cardiovascular", ["Legs"], "beginner",
           "Slow walk, let heart rate come down", "March in Place"),
        stretch("Standing Quad Stretch", 30, "Legs", "Quadriceps",
                "Pull heel to glute, stand tall", "Lying Quad Stretch"),
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot on low surface, hinge forward", "Seated Forward Fold"),
        stretch("Cross-Body Shoulder Stretch", 30, "Shoulders", "Posterior Deltoid",
                "Pull arm across chest, hold at elbow", "Doorway Shoulder Stretch"),
        stretch("Overhead Tricep Stretch", 30, "Arms", "Triceps",
                "Arm overhead, pull elbow behind head gently", "Tricep Rope Stretch"),
        stretch("Chest Doorway Stretch", 30, "Chest", "Pectoralis Major",
                "Forearm on door frame, lean through", "Floor Chest Stretch"),
        CHILDS_POSE(),
    ])]

def _office_break_warmup():
    return [workout("Office Break Warmup", "warmup", 10, [
        ex("Seated March", 1, 20, 10, "30 seconds", "Bodyweight", "Legs",
           "Hip Flexors", ["Quadriceps", "Core"], "beginner",
           "Sit tall, alternately lift knees, pump arms", "Standing March"),
        ex("Neck Circles", 1, 5, 10, "Each direction, slow", "Bodyweight", "Neck",
           "Neck Muscles", ["Trapezius"], "beginner",
           "Slow half circles, front to each side", "Chin Tuck"),
        ex("Shoulder Rolls", 1, 10, 10, "Forward and backward", "Bodyweight", "Shoulders",
           "Trapezius", ["Deltoids"], "beginner",
           "Large circles, slow and controlled", "Arm Circles"),
        CHIN_TUCK(),
        WALL_ANGEL(),
        stretch("Standing Hip Flexor Stretch", 30, "Hips", "Hip Flexors",
                "Step forward into lunge, squeeze rear glute", "Seated Hip Flexor Stretch"),
        stretch("Standing Hamstring Stretch", 20, "Legs", "Hamstrings",
                "Foot on desk or chair, hinge forward", "Seated Forward Fold"),
        ex("Wrist Flexion/Extension Stretch", 1, 1, 10, "Hold 20 seconds each way", "Bodyweight", "Wrists",
           "Forearms", ["Wrist Flexors", "Wrist Extensors"], "beginner",
           "Extend arm, pull fingers back then down", "Wrist Circles"),
    ])]

def _pre_run_warmup():
    return [workout("Pre-Run Warmup", "warmup", 10, [
        ex("Brisk Walk", 1, 1, 10, "2 minutes", "Bodyweight", "Full Body",
           "Cardiovascular", ["Legs"], "beginner",
           "Gradually increase pace", "March in Place"),
        ex("Leg Swings (Front-Back)", 1, 10, 10, "Per leg", "Bodyweight", "Hips",
           "Hip Flexors", ["Hamstrings"], "beginner",
           "Hold wall, swing leg forward and back", "Walking Knee Hugs"),
        ex("Leg Swings (Side-Side)", 1, 10, 10, "Per leg", "Bodyweight", "Hips",
           "Adductors", ["Hip Abductors"], "beginner",
           "Swing leg across body and out", "Lateral Leg Raise"),
        HIGH_KNEES(1, 15, 10, "20 seconds"),
        ex("Butt Kicks", 1, 15, 10, "20 seconds", "Bodyweight", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Jog kicking heels to glutes", "High Knees"),
        ex("Walking Lunge with Twist", 1, 5, 15, "Per side", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Obliques", "Hip Flexors"], "beginner",
           "Lunge forward, twist torso over front leg", "World's Greatest Stretch"),
        ANKLE_CIRCLES(),
        ex("Calf Raises", 1, 15, 10, "Both legs", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Rise up on toes, slow descent", "Ankle Circles"),
    ])]

def _pre_swim_warmup():
    return [workout("Pre-Swim Warmup", "warmup", 10, [
        ex("Arm Circles", 2, 15, 10, "Forward and backward", "Bodyweight", "Shoulders",
           "Deltoids", ["Rotator Cuff"], "beginner",
           "Small to large, both directions", "Band Dislocates"),
        ex("Trunk Rotations", 1, 10, 10, "Alternating sides", "Bodyweight", "Core",
           "Obliques", ["Erector Spinae"], "beginner",
           "Feet planted, rotate torso side to side", "Standing Twist"),
        WALL_ANGEL(),
        stretch("Lat Stretch", 30, "Back", "Latissimus Dorsi",
                "Grab overhead bar or doorframe, lean away", "Child's Pose"),
        stretch("Chest Stretch", 30, "Chest", "Pectoralis Major",
                "Hands behind back, squeeze shoulder blades, lift chest", "Doorway Stretch"),
        ex("Leg Swings (Front-Back)", 1, 10, 10, "Per leg", "Bodyweight", "Hips",
           "Hip Flexors", ["Hamstrings"], "beginner",
           "Hold wall, swing leg forward and back", "Walking Knee Hugs"),
        ANKLE_CIRCLES(),
        WRIST_CIRCLES(),
    ])]


###############################################################################
# STRETCHING (8 programs)
###############################################################################

def _hip_opener_series():
    return [workout("Hip Opener Series", "flexibility", 20, [
        HIP_90_90(),
        HIP_FLEXOR_STRETCH(),
        PIRIFOMIS_STRETCH(),
        stretch("Butterfly Stretch", 45, "Hips", "Adductors",
                "Soles together, press knees down gently, sit tall", "Frog Stretch"),
        stretch("Frog Stretch", 45, "Hips", "Adductors",
                "On all fours, widen knees, sink hips back", "Butterfly Stretch"),
        stretch("Lizard Pose", 30, "Hips", "Hip Flexors",
                "Deep lunge, both hands inside front foot, sink hips", "Low Lunge"),
        PIGEON_POSE(),
        HAPPY_BABY(),
    ])]

def _shoulder_stretch_routine():
    return [workout("Shoulder Stretch Routine", "flexibility", 15, [
        stretch("Cross-Body Shoulder Stretch", 30, "Shoulders", "Posterior Deltoid",
                "Pull arm across chest, hold at elbow", "Doorway Shoulder Stretch"),
        stretch("Overhead Tricep/Shoulder Stretch", 30, "Shoulders", "Triceps",
                "Arm overhead, pull elbow behind head", "Cross-Body Stretch"),
        ex("Doorway Pec Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Chest",
           "Pectoralis Major", ["Anterior Deltoid"], "beginner",
           "Forearm on door frame, lean through", "Floor Chest Stretch"),
        WALL_ANGEL(),
        stretch("Lat Stretch", 30, "Back", "Latissimus Dorsi",
                "Grab overhead bar, lean away, feel lat open up", "Child's Pose"),
        ex("Thread the Needle", 2, 5, 15, "Per side", "Bodyweight", "Shoulders",
           "Rotator Cuff", ["Thoracic Spine", "Rhomboids"], "beginner",
           "On all fours, thread arm under, rotate chest", "Seated Spinal Twist"),
        stretch("Eagle Arms Stretch", 30, "Shoulders", "Rhomboids",
                "Wrap arms, elbows stacked, lift elbows, feel upper back stretch", "Cross-Body Stretch"),
    ])]

def _hamstring_flexibility():
    return [workout("Hamstring Flexibility", "flexibility", 20, [
        ex("Foam Roll Hamstrings", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
           "Hamstrings", ["Calves"], "beginner",
           "Sit on roller, roll from glutes to knee", "Hamstring Stretch"),
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot on bench, hinge forward, flat back", "Seated Forward Fold"),
        stretch("Seated Hamstring Stretch", 45, "Legs", "Hamstrings",
                "Legs extended, fold from hips, reach for toes", "Standing Hamstring Stretch"),
        stretch("Lying Hamstring Stretch", 30, "Legs", "Hamstrings",
                "On back, pull straight leg toward chest with strap", "Seated Hamstring Stretch"),
        STANDING_FORWARD_FOLD(),
        DOWNWARD_DOG(),
        stretch("Single-Leg Forward Fold", 30, "Legs", "Hamstrings",
                "One foot crossed over other, fold forward", "Standing Hamstring Stretch"),
    ])]

def _quad_hip_flexor_stretch():
    return [workout("Quad & Hip Flexor Stretch", "flexibility", 15, [
        FOAM_ROLL_QUAD(),
        stretch("Standing Quad Stretch", 30, "Legs", "Quadriceps",
                "Pull heel to glute, keep knees together, stand tall", "Lying Quad Stretch"),
        stretch("Lying Quad Stretch", 30, "Legs", "Quadriceps",
                "Side lying, pull top ankle behind, feel quad stretch", "Standing Quad Stretch"),
        HIP_FLEXOR_STRETCH(),
        stretch("Couch Stretch", 45, "Hips", "Hip Flexors",
                "Rear foot on couch/wall, front foot forward, sink hips", "Half-Kneeling Hip Flexor Stretch"),
        LOW_LUNGE(),
        stretch("Pigeon Pose (Quad Emphasis)", 30, "Legs", "Quadriceps",
                "In pigeon, reach back and grab rear foot, pull toward glute", "Lying Quad Stretch"),
    ])]

def _back_flexibility():
    return [workout("Back Flexibility", "flexibility", 20, [
        FOAM_ROLL_BACK(),
        ex("Cat-Cow", 2, 10, 15, "Flow with breath", "Bodyweight", "Back",
           "Erector Spinae", ["Core"], "beginner",
           "Inhale arch, exhale round, slow rhythm", "Seated Spinal Flex"),
        CHILDS_POSE(),
        COBRA(),
        stretch("Seated Spinal Twist", 30, "Back", "Erector Spinae",
                "Sit tall, cross one leg, twist toward knee, hold", "Supine Twist"),
        RECLINED_TWIST(),
        stretch("Knee-to-Chest Stretch", 30, "Back", "Erector Spinae",
                "Lie on back, pull both knees to chest", "Child's Pose"),
        SEATED_FORWARD_FOLD(),
    ])]

def _it_band_glute_stretch():
    return [workout("IT Band & Glute Stretch", "flexibility", 20, [
        FOAM_ROLL_IT_BAND(),
        ex("Foam Roll Glutes", 1, 1, 10, "60 seconds each side", "Foam Roller", "Glutes",
           "Gluteus Maximus", ["Piriformis"], "beginner",
           "Cross ankle over knee, roll glute area", "Pigeon Pose"),
        ex("Foam Roll TFL", 1, 1, 10, "60 seconds each side", "Foam Roller", "Hips",
           "TFL", ["IT Band"], "beginner",
           "Front of hip, roll slowly over TFL", "IT Band Foam Roll"),
        PIRIFOMIS_STRETCH(),
        stretch("Crossed-Leg Forward Fold", 30, "Hips", "IT Band",
                "Cross one foot in front, fold forward, feel outer hip", "Standing IT Band Stretch"),
        stretch("Supine IT Band Stretch", 30, "Legs", "IT Band",
                "On back, cross leg over, pull gently across body", "Foam Roll IT Band"),
        PIGEON_POSE(),
        stretch("Figure Four Stretch", 30, "Hips", "Piriformis",
                "On back, ankle on opposite knee, pull bottom knee in", "Piriformis Stretch"),
    ])]

def _ankle_flexibility():
    return [workout("Ankle Flexibility", "flexibility", 15, [
        ANKLE_CIRCLES(),
        ex("Ankle Dorsiflexion Mobilization", 2, 10, 15, "Per ankle", "Bodyweight", "Ankles",
           "Ankle Joint", ["Calves", "Tibialis Anterior"], "beginner",
           "Knee over toe in lunge position, drive knee forward", "Calf Stretch"),
        ex("Calf Stretch (Gastrocnemius)", 2, 1, 10, "Hold 30 seconds each leg", "Bodyweight", "Legs",
           "Gastrocnemius", ["Soleus"], "beginner",
           "Foot against wall, straight leg, lean forward", "Seated Calf Stretch"),
        ex("Calf Stretch (Soleus)", 2, 1, 10, "Hold 30 seconds each leg", "Bodyweight", "Legs",
           "Soleus", ["Gastrocnemius"], "beginner",
           "Same wall stretch but bent knee for soleus", "Gastrocnemius Stretch"),
        ex("Banded Ankle Distraction", 2, 1, 10, "Hold 30 seconds each ankle", "Resistance Band",
           "Ankles", "Ankle Joint", ["Calves"], "beginner",
           "Band around ankle front, step away, drive knee forward", "Ankle Dorsiflexion Mobilization"),
        ex("Alphabet Ankles", 1, 1, 10, "Each foot, trace A-Z", "Bodyweight", "Ankles",
           "Ankle Joint", ["Calves", "Tibialis"], "beginner",
           "Trace the alphabet with your toes to work full ROM", "Ankle Circles"),
    ])]

def _chest_bicep_stretch():
    return [workout("Chest & Bicep Stretch", "flexibility", 15, [
        ex("Foam Roll Pecs", 1, 1, 10, "60 seconds each side", "Lacrosse Ball", "Chest",
           "Pectoralis Major", ["Pectoralis Minor"], "beginner",
           "Ball against wall, roll chest area slowly", "Doorway Pec Stretch"),
        ex("Doorway Pec Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Chest",
           "Pectoralis Major", ["Anterior Deltoid"], "beginner",
           "Forearm on door frame, lean through", "Floor Chest Stretch"),
        stretch("Floor Chest Stretch", 30, "Chest", "Pectoralis Major",
                "Lie face down, arm out to side, roll body away from arm", "Doorway Pec Stretch"),
        stretch("Bicep Wall Stretch", 30, "Arms", "Biceps",
                "Hand on wall behind you, arm straight, rotate body away", "Doorway Bicep Stretch"),
        stretch("Behind-Back Clasp Stretch", 30, "Chest", "Pectoralis Major",
                "Hands clasped behind back, squeeze shoulder blades, lift arms", "Doorway Stretch"),
        stretch("Corner Chest Stretch", 30, "Chest", "Pectoralis Major",
                "Hands on walls in corner, lean in, feel deep chest stretch", "Doorway Pec Stretch"),
    ])]


###############################################################################
# REHAB (7 programs)
###############################################################################

def _ankle_rehab():
    return [workout("Ankle Rehab", "rehab", 20, [
        ANKLE_CIRCLES(),
        ex("Alphabet Ankles", 1, 1, 10, "Each foot, trace A-Z", "Bodyweight", "Ankles",
           "Ankle Joint", ["Calves", "Tibialis"], "beginner",
           "Trace letters with toes for full ROM", "Ankle Circles"),
        ex("Towel Curl", 3, 15, 15, "Seated, per foot", "Bodyweight", "Feet",
           "Intrinsic Foot Muscles", ["Calves"], "beginner",
           "Seated, scrunch towel toward you with toes", "Marble Pickup"),
        ex("Calf Raise (Bilateral)", 3, 12, 20, "Slow, hold at top", "Bodyweight", "Legs",
           "Calves", ["Soleus"], "beginner",
           "Rise on both feet, 2-second hold, slow lower", "Seated Calf Raise"),
        ex("Single-Leg Calf Raise", 2, 8, 20, "Per leg, gentle", "Bodyweight", "Legs",
           "Calves", ["Soleus", "Balance"], "beginner",
           "Hold wall for balance, rise on one foot, controlled", "Bilateral Calf Raise"),
        ex("Ankle Dorsiflexion Stretch", 2, 1, 10, "Hold 30 seconds each", "Bodyweight", "Ankles",
           "Ankle Joint", ["Calves"], "beginner",
           "Knee over toe in half-kneel, gentle push", "Ankle Mobilization"),
        ex("Resistance Band Ankle Inversion", 2, 12, 15, "Light band, per foot", "Resistance Band",
           "Ankles", "Tibialis Posterior", ["Ankle Stabilizers"], "beginner",
           "Band around foot, turn sole inward against resistance", "Towel Curl"),
        ex("Resistance Band Ankle Eversion", 2, 12, 15, "Light band, per foot", "Resistance Band",
           "Ankles", "Peroneals", ["Ankle Stabilizers"], "beginner",
           "Band around foot, turn sole outward against resistance", "Ankle Inversion"),
        ex("Single-Leg Balance Hold", 3, 1, 15, "Hold 30 seconds per leg", "Bodyweight", "Ankles",
           "Ankle Stabilizers", ["Core", "Balance"], "beginner",
           "Stand on one foot, slight knee bend, stay steady", "Tandem Stance"),
    ])]

def _wrist_elbow_rehab():
    return [workout("Wrist & Elbow Rehab", "rehab", 20, [
        WRIST_CIRCLES(),
        ex("Wrist Flexion Stretch", 2, 1, 10, "Hold 20 seconds each hand", "Bodyweight", "Wrists",
           "Wrist Flexors", ["Forearms"], "beginner",
           "Arm extended, palm up, pull fingers back gently", "Wrist Extension Stretch"),
        ex("Wrist Extension Stretch", 2, 1, 10, "Hold 20 seconds each hand", "Bodyweight", "Wrists",
           "Wrist Extensors", ["Forearms"], "beginner",
           "Arm extended, palm down, pull fingers toward you", "Wrist Flexion Stretch"),
        ex("Forearm Pronation/Supination", 2, 12, 15, "Per arm, light weight or no weight",
           "Dumbbell", "Arms", "Forearms", ["Wrist Stabilizers"], "beginner",
           "Elbow at side, rotate forearm palm up and palm down", "Wrist Circles"),
        ex("Wrist Curl", 2, 12, 15, "Very light weight, per hand", "Dumbbell", "Arms",
           "Wrist Flexors", ["Forearms"], "beginner",
           "Rest forearm on thigh, curl wrist up, slow", "Wrist Flexion Stretch"),
        ex("Reverse Wrist Curl", 2, 12, 15, "Very light weight, per hand", "Dumbbell", "Arms",
           "Wrist Extensors", ["Forearms"], "beginner",
           "Rest forearm on thigh palm down, extend wrist up", "Wrist Extension Stretch"),
        ex("Eccentric Wrist Extension", 2, 10, 15, "Light weight, slow lower", "Dumbbell", "Arms",
           "Wrist Extensors", ["Forearms"], "beginner",
           "Use other hand to lift, slowly lower under control", "Reverse Wrist Curl"),
        ex("Ball Squeeze", 3, 15, 15, "Stress ball or tennis ball", "Ball", "Hands",
           "Grip", ["Forearms", "Wrist Flexors"], "beginner",
           "Squeeze firmly, hold 3 seconds, release", "Towel Squeeze"),
        ex("Finger Extension with Band", 2, 12, 15, "Rubber band around fingers", "Resistance Band",
           "Hands", "Finger Extensors", ["Forearms"], "beginner",
           "Spread fingers against band resistance", "Ball Squeeze"),
    ])]

def _post_surgery_general():
    return [workout("Post-Surgery General Recovery", "rehab", 25, [
        ex("Diaphragmatic Breathing", 3, 10, 15, "Slow, deep breaths", "Bodyweight", "Core",
           "Diaphragm", ["Intercostals", "Transverse Abdominis"], "beginner",
           "Hand on belly, inhale into belly 4 sec, exhale 6 sec", "Seated Breathing"),
        ANKLE_CIRCLES(),
        WRIST_CIRCLES(),
        ex("Gentle Neck Turns", 2, 5, 10, "Each direction, slow", "Bodyweight", "Neck",
           "Neck Muscles", ["Trapezius"], "beginner",
           "Turn head slowly side to side, hold each side 5 sec", "Neck Stretches"),
        ex("Shoulder Shrugs", 2, 10, 15, "Very gentle", "Bodyweight", "Shoulders",
           "Trapezius", ["Deltoids"], "beginner",
           "Lift shoulders to ears, hold 2 sec, release", "Shoulder Rolls"),
        ex("Seated March", 2, 10, 15, "Gentle knee lifts", "Bodyweight", "Legs",
           "Hip Flexors", ["Quadriceps"], "beginner",
           "Sit upright, alternate lifting knees gently", "Standing March"),
        GLUTE_BRIDGE(2, 8, 20, "Gentle, hold at top 3 seconds"),
        DEAD_BUG(2, 6, 20, "Very slow and controlled"),
        stretch("Gentle Full-Body Stretch", 30, "Full Body", "Multiple",
                "Lie down, reach arms overhead, extend fully, breathe", "Child's Pose"),
    ])]

def _acl_recovery():
    return [workout("ACL Recovery", "rehab", 30, [
        ex("Quad Set", 3, 15, 15, "Isometric, hold 5 sec each", "Bodyweight", "Legs",
           "Quadriceps", ["VMO"], "beginner",
           "Seated, push knee down into floor, tighten quad", "Straight Leg Raise"),
        ex("Straight Leg Raise", 3, 12, 15, "Per leg, slow", "Bodyweight", "Legs",
           "Quadriceps", ["Hip Flexors"], "beginner",
           "Lie back, one knee bent, raise straight leg to 45 degrees", "Quad Set"),
        ex("Heel Slides", 3, 12, 15, "Per leg, gentle", "Bodyweight", "Legs",
           "Quadriceps", ["Hamstrings"], "beginner",
           "Lie back, slide heel toward glute bending knee, slide back", "Wall Slides"),
        ex("Prone Knee Flexion", 2, 12, 15, "Face down, per leg", "Bodyweight", "Legs",
           "Hamstrings", ["Quadriceps"], "beginner",
           "Lie face down, bend knee bringing heel toward glute", "Heel Slides"),
        ex("Mini Wall Squat", 3, 10, 20, "Partial range, pain-free", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes"], "beginner",
           "Back against wall, slide down to 45 degrees only", "Wall Sit"),
        GLUTE_BRIDGE(3, 10, 20, "Gentle, hold at top"),
        ex("Standing Calf Raise", 3, 15, 15, "Hold wall for balance", "Bodyweight", "Legs",
           "Calves", ["Soleus"], "beginner",
           "Rise on both feet, slow descent", "Seated Calf Raise"),
        CLAMSHELL(3, 12, 15, "Light band optional"),
        ex("Step-Up (Low Step)", 2, 10, 20, "Per leg, 4-inch step", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Balance"], "beginner",
           "Low step, drive through lead leg, controlled", "Mini Wall Squat"),
    ])]

def _rotator_cuff_rehab():
    return [workout("Rotator Cuff Rehab", "rehab", 25, [
        ex("Pendulum Swing", 2, 15, 10, "Per arm, relaxed", "Bodyweight", "Shoulders",
           "Rotator Cuff", ["Deltoids"], "beginner",
           "Lean forward, let arm hang, make small circles", "Shoulder Rolls"),
        ex("External Rotation (Sidelying)", 3, 12, 15, "Very light weight, per arm", "Dumbbell",
           "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner",
           "Lie on side, elbow at side 90 degrees, rotate forearm up", "Band External Rotation"),
        ex("Internal Rotation (Sidelying)", 3, 12, 15, "Very light weight, per arm", "Dumbbell",
           "Shoulders", "Subscapularis", ["Pectoralis Major"], "beginner",
           "Lie on side, bottom arm rotates up toward ceiling", "Band Internal Rotation"),
        ex("Band External Rotation", 3, 12, 15, "Light band, per arm", "Resistance Band",
           "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner",
           "Elbow at side, rotate forearm outward against band", "Sidelying External Rotation"),
        BAND_PULL_APART(3, 15, 15, "Very light band"),
        FACE_PULL(3, 15, 20, "Very light, focus on external rotation"),
        ex("Prone Y Raise", 3, 10, 15, "No weight, face down", "Bodyweight", "Shoulders",
           "Lower Trapezius", ["Rotator Cuff", "Scapular Stabilizers"], "beginner",
           "Lie face down, raise arms in Y shape, thumbs up", "Band Pull-Apart"),
        ex("Prone T Raise", 3, 10, 15, "No weight, face down", "Bodyweight", "Shoulders",
           "Middle Trapezius", ["Rhomboids", "Rotator Cuff"], "beginner",
           "Lie face down, raise arms out to sides, squeeze back", "Prone Y Raise"),
        WALL_ANGEL(),
    ])]

def _sciatica_relief():
    return [workout("Sciatica Relief", "rehab", 25, [
        stretch("Knee-to-Chest Stretch", 30, "Back", "Erector Spinae",
                "On back, pull one knee to chest, hold gently", "Both Knees to Chest"),
        PIRIFOMIS_STRETCH(),
        stretch("Figure Four Stretch", 30, "Hips", "Piriformis",
                "On back, ankle on opposite knee, pull thigh toward chest", "Piriformis Stretch"),
        ex("Cat-Cow", 2, 8, 15, "Gentle, flow with breath", "Bodyweight", "Back",
           "Erector Spinae", ["Core"], "beginner",
           "Inhale arch gently, exhale round, avoid pain", "Seated Spinal Flex"),
        CHILDS_POSE(),
        ex("Prone Press-Up", 2, 8, 15, "Gentle, McKenzie extension", "Bodyweight", "Back",
           "Erector Spinae", ["Abdominals"], "beginner",
           "Lie face down, press up on hands, keep hips down, relax back", "Cobra Pose"),
        BIRD_DOG(2, 8, 20, "Very slow, controlled"),
        DEAD_BUG(2, 8, 20, "Slow and controlled"),
        stretch("Supine Spinal Twist", 30, "Back", "Erector Spinae",
                "On back, knees to one side, arms out, gentle rotation", "Seated Twist"),
        GLUTE_BRIDGE(2, 10, 20, "Gentle, hold at top"),
    ])]

def _plantar_fasciitis_relief():
    return [workout("Plantar Fasciitis Relief", "rehab", 20, [
        ex("Plantar Fascia Massage", 1, 1, 10, "2 minutes per foot", "Lacrosse Ball", "Feet",
           "Plantar Fascia", ["Intrinsic Foot Muscles"], "beginner",
           "Roll ball under foot, pause on tender spots", "Frozen Water Bottle Roll"),
        ex("Towel Curl", 3, 15, 15, "Per foot", "Bodyweight", "Feet",
           "Intrinsic Foot Muscles", ["Calves"], "beginner",
           "Seated, scrunch towel toward you with toes", "Marble Pickup"),
        ex("Calf Stretch (Gastrocnemius)", 2, 1, 10, "Hold 30 seconds each leg", "Bodyweight", "Legs",
           "Gastrocnemius", ["Plantar Fascia"], "beginner",
           "Foot against wall, straight leg, lean forward gently", "Seated Calf Stretch"),
        ex("Calf Stretch (Soleus)", 2, 1, 10, "Hold 30 seconds each leg", "Bodyweight", "Legs",
           "Soleus", ["Plantar Fascia"], "beginner",
           "Wall stretch with bent knee to target soleus", "Gastrocnemius Stretch"),
        ex("Toe Yoga", 3, 10, 15, "Per foot", "Bodyweight", "Feet",
           "Intrinsic Foot Muscles", ["Toe Flexors"], "beginner",
           "Lift big toe only, then 4 small toes only, alternate", "Towel Curl"),
        ex("Eccentric Calf Raise", 3, 10, 20, "Slow 5-second lower", "Bodyweight", "Legs",
           "Calves", ["Soleus", "Plantar Fascia"], "beginner",
           "Rise on both feet, shift to one foot, lower slowly", "Bilateral Calf Raise"),
        ANKLE_CIRCLES(),
        ex("Short Foot Exercise", 3, 10, 15, "Per foot, seated", "Bodyweight", "Feet",
           "Intrinsic Foot Muscles", ["Arch Muscles"], "beginner",
           "Seated, shorten foot by lifting arch without curling toes", "Towel Curl"),
    ])]


###############################################################################
# POSTURE (7 programs)
###############################################################################

def _forward_head_fix():
    return [workout("Forward Head Fix", "corrective", 15, [
        CHIN_TUCK(),
        ex("Neck Flexor Strengthening", 3, 10, 15, "Gentle, isometric", "Bodyweight", "Neck",
           "Deep Neck Flexors", ["SCM"], "beginner",
           "Lie on back, tuck chin, lift head 1 inch, hold 5 sec", "Chin Tuck"),
        THORACIC_EXTENSION(),
        WALL_ANGEL(),
        ex("Suboccipital Release", 2, 1, 10, "Hold 60 seconds", "Lacrosse Ball", "Neck",
           "Suboccipitals", ["Upper Trapezius"], "beginner",
           "Lie on back, two balls at base of skull, relax into them", "Chin Tuck"),
        stretch("Upper Trapezius Stretch", 30, "Neck", "Upper Trapezius",
                "Tilt head to side, gentle pull with hand, relax shoulder", "Levator Scapulae Stretch"),
        stretch("Levator Scapulae Stretch", 30, "Neck", "Levator Scapulae",
                "Turn head 45 degrees, look down, pull gently with hand", "Upper Trapezius Stretch"),
        BAND_PULL_APART(3, 15, 15, "Light band, squeeze at end"),
    ])]

def _apt_fix():
    return [workout("Anterior Pelvic Tilt Fix", "corrective", 20, [
        FOAM_ROLL_QUAD(),
        HIP_FLEXOR_STRETCH(),
        stretch("Couch Stretch", 45, "Hips", "Hip Flexors",
                "Rear shin on wall, front foot forward, squeeze glute, sink", "Half-Kneeling Hip Flexor Stretch"),
        ex("Posterior Pelvic Tilt Drill", 3, 10, 15, "On back", "Bodyweight", "Core",
           "Transverse Abdominis", ["Glutes", "Rectus Abdominis"], "beginner",
           "Lie on back, flatten lower back into floor, hold 5 sec", "Dead Bug"),
        DEAD_BUG(3, 10, 20, "Slow, press lower back into floor"),
        GLUTE_BRIDGE(3, 12, 20, "Squeeze glutes hard at top, posterior tilt"),
        PLANK(3, 1, 30, "Hold 20-30 seconds, focus on posterior tilt"),
        ex("Standing Pelvic Tilt Practice", 3, 10, 15, "Standing against wall", "Bodyweight", "Core",
           "Transverse Abdominis", ["Glutes"], "beginner",
           "Stand against wall, flatten lower back, squeeze glutes", "Posterior Pelvic Tilt Drill"),
    ])]

def _desk_worker_posture():
    return [workout("Desk Worker Posture Correction", "corrective", 20, [
        CHIN_TUCK(),
        THORACIC_EXTENSION(),
        WALL_ANGEL(),
        ex("Doorway Pec Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Chest",
           "Pectoralis Major", ["Anterior Deltoid"], "beginner",
           "Forearm on door frame, lean through, open chest", "Floor Chest Stretch"),
        HIP_FLEXOR_STRETCH(),
        BAND_PULL_APART(3, 15, 15, "Light band"),
        ex("Prone Y-T-W Raise", 2, 8, 15, "No weight", "Bodyweight", "Back",
           "Scapular Stabilizers", ["Rear Deltoid", "Rhomboids"], "beginner",
           "Face down, raise arms in Y, T, W shapes, squeeze back", "Band Pull-Apart"),
        DEAD_BUG(3, 8, 20, "Core engagement for spinal support"),
        stretch("Upper Trapezius Stretch", 30, "Neck", "Upper Trapezius",
                "Tilt head to side, gently pull, relax opposite shoulder", "Levator Scapulae Stretch"),
    ])]

def _scoliosis_support():
    return [workout("Scoliosis Support", "corrective", 20, [
        ex("Cat-Cow", 2, 8, 15, "Slow, even movement", "Bodyweight", "Back",
           "Erector Spinae", ["Core"], "beginner",
           "Inhale arch evenly, exhale round evenly", "Seated Spinal Flex"),
        CHILDS_POSE(),
        BIRD_DOG(3, 8, 20, "Focus on symmetrical movement"),
        DEAD_BUG(3, 8, 20, "Focus on keeping pelvis level"),
        SIDE_PLANK(2, 1, 30, "Hold 15-20 seconds, both sides"),
        stretch("Side Stretch", 30, "Back", "Quadratus Lumborum",
                "Stand, reach one arm overhead, lean to opposite side", "Seated Side Bend"),
        PLANK(2, 1, 30, "Hold 20-30 seconds, focus on even engagement"),
        ex("Prone Y Raise", 2, 8, 15, "No weight", "Bodyweight", "Back",
           "Lower Trapezius", ["Scapular Stabilizers"], "beginner",
           "Face down, raise arms in Y shape, even both sides", "Superman"),
        THORACIC_EXTENSION(),
    ])]

def _lordosis_fix():
    return [workout("Lordosis Fix", "corrective", 20, [
        FOAM_ROLL_QUAD(),
        HIP_FLEXOR_STRETCH(),
        ex("Posterior Pelvic Tilt Drill", 3, 10, 15, "On back", "Bodyweight", "Core",
           "Transverse Abdominis", ["Glutes", "Rectus Abdominis"], "beginner",
           "Lie on back, flatten lower back into floor, hold 5 sec", "Dead Bug"),
        DEAD_BUG(3, 10, 20, "Press lower back into floor throughout"),
        GLUTE_BRIDGE(3, 12, 20, "Squeeze glutes, posterior tilt at top"),
        PLANK(3, 1, 30, "Hold 20-30 seconds, tuck pelvis under"),
        ex("Reverse Crunch", 3, 12, 20, "Controlled, lift hips off floor", "Bodyweight", "Core",
           "Lower Abs", ["Rectus Abdominis"], "beginner",
           "Knees to chest, lift hips off floor, slow return", "Dead Bug"),
        stretch("Knee-to-Chest Stretch", 30, "Back", "Erector Spinae",
                "Lie on back, pull both knees to chest, round lower back", "Child's Pose"),
    ])]

def _tech_posture_reset():
    return [workout("Tech Posture Reset", "corrective", 15, [
        CHIN_TUCK(),
        stretch("Upper Trapezius Stretch", 30, "Neck", "Upper Trapezius",
                "Tilt head, gentle pull, relax shoulder down", "Levator Scapulae Stretch"),
        THORACIC_EXTENSION(),
        WALL_ANGEL(),
        ex("Doorway Pec Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Chest",
           "Pectoralis Major", ["Anterior Deltoid"], "beginner",
           "Forearm on frame, lean through", "Floor Chest Stretch"),
        BAND_PULL_APART(3, 15, 15, "Light band"),
        WRIST_CIRCLES(),
        ex("Wrist Flexion/Extension Stretch", 1, 1, 10, "Hold 20 seconds each way", "Bodyweight", "Wrists",
           "Forearms", ["Wrist Flexors", "Wrist Extensors"], "beginner",
           "Extend arm, pull fingers back then down", "Wrist Circles"),
    ])]

def _standing_posture_training():
    return [workout("Standing Posture Training", "corrective", 20, [
        ex("Wall Posture Check", 3, 1, 15, "Hold 30 seconds", "Bodyweight", "Full Body",
           "Postural Muscles", ["Core", "Back"], "beginner",
           "Head, shoulders, glutes, heels touch wall, flatten lower back", "Chin Tuck"),
        CHIN_TUCK(),
        WALL_ANGEL(),
        GLUTE_BRIDGE(3, 12, 20, "Activate glutes for standing support"),
        ex("Single-Leg Balance", 3, 1, 15, "Hold 30 seconds per leg", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Stand tall on one foot, maintain posture alignment", "Tandem Stance"),
        CALF_RAISE(3, 15, 15, "Standing, improve foot/ankle posture"),
        PLANK(2, 1, 30, "Hold 20-30 seconds, practice neutral spine"),
        BAND_PULL_APART(3, 15, 15, "Retract scapulae, improve upper back strength"),
        ex("Farmer's Walk (Light)", 2, 1, 15, "30-second walks, focus on posture", "Dumbbell", "Full Body",
           "Core", ["Trapezius", "Grip", "Postural Muscles"], "beginner",
           "Light weights, shoulders back, chin tucked, tall posture", "Wall Posture Check"),
    ])]


###############################################################################
# BALANCE (12 programs)
###############################################################################

def _balance_foundation():
    return [workout("Balance Foundation", "balance", 20, [
        ex("Tandem Stance", 3, 1, 15, "Hold 30 seconds, switch lead foot", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Heel to toe, arms at sides, stand tall", "Bilateral Stance on Foam"),
        ex("Single-Leg Stance", 3, 1, 15, "Hold 30 seconds per leg", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Hip Stabilizers"], "beginner",
           "Slight knee bend, stay tall, focus on a point ahead", "Tandem Stance"),
        ex("Weight Shifts", 2, 10, 15, "Side to side", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Hip Stabilizers"], "beginner",
           "Stand feet hip-width, shift weight fully side to side", "Single-Leg Stance"),
        ex("Heel-to-Toe Walk", 2, 10, 15, "10 steps forward and back", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Walk in straight line, heel touching toe each step", "Tandem Stance"),
        ex("Marching in Place", 2, 20, 15, "Lift knees high, controlled", "Bodyweight", "Full Body",
           "Hip Flexors", ["Core", "Balance"], "beginner",
           "High knee march, pause briefly at top of each lift", "Standing March"),
        ex("Sit-to-Stand", 3, 10, 20, "From chair, no hands", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Core", "Balance"], "beginner",
           "Sit on chair, stand without using hands, sit controlled", "Wall Sit"),
        CALF_RAISE(3, 12, 15, "Slow and controlled, improve ankle stability"),
    ])]

def _single_leg_stability():
    return [workout("Single-Leg Stability", "balance", 25, [
        ex("Single-Leg Stance", 3, 1, 15, "Hold 30 seconds per leg", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Hip Stabilizers"], "beginner",
           "Slight knee bend, stay tall, focus ahead", "Tandem Stance"),
        ex("Single-Leg Reach", 3, 8, 15, "Per leg, reach in 3 directions", "Bodyweight", "Full Body",
           "Core", ["Hip Stabilizers", "Ankle Stabilizers"], "intermediate",
           "Stand on one leg, reach other foot forward/side/back", "Single-Leg Stance"),
        SINGLE_LEG_RDL(2, 8, 30, "Light or bodyweight, focus on balance"),
        ex("Single-Leg Calf Raise", 3, 10, 15, "Per leg, hold wall if needed", "Bodyweight", "Legs",
           "Calves", ["Ankle Stabilizers", "Balance"], "beginner",
           "Rise on one foot, slow lower, repeat", "Bilateral Calf Raise"),
        ex("Single-Leg Mini Squat", 3, 8, 20, "Per leg, partial range", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Balance"], "intermediate",
           "Stand on one leg, slight squat to 30-40 degrees, return", "Bodyweight Squat"),
        ex("Single-Leg Hip Hinge", 2, 8, 20, "Per leg", "Bodyweight", "Hips",
           "Hamstrings", ["Glutes", "Balance"], "intermediate",
           "Hinge on one leg, other leg extends behind", "Single-Leg RDL"),
        CLAMSHELL(3, 12, 15, "Banded for hip stability"),
        ex("Lateral Step-Down", 2, 8, 20, "Per leg, from low step", "Bodyweight", "Legs",
           "Quadriceps", ["Gluteus Medius", "Balance"], "intermediate",
           "Stand on step, slowly lower other foot, tap and return", "Step-Up"),
    ])]

def _bosu_ball_training():
    return [workout("Bosu Ball Training", "balance", 25, [
        ex("Bosu Bilateral Stance", 2, 1, 15, "Hold 30 seconds", "Bosu Ball", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Stand on dome side, feet hip-width, find balance", "Foam Pad Stance"),
        ex("Bosu Single-Leg Stance", 3, 1, 15, "Hold 20 seconds per leg", "Bosu Ball", "Full Body",
           "Core", ["Ankle Stabilizers", "Hip Stabilizers"], "intermediate",
           "Stand on one leg on dome, slight knee bend", "Single-Leg Stance"),
        ex("Bosu Squat", 3, 10, 20, "Dome side up", "Bosu Ball", "Legs",
           "Quadriceps", ["Glutes", "Core", "Balance"], "intermediate",
           "Stand on dome, squat to parallel, return", "Bodyweight Squat"),
        ex("Bosu Lunge (Front Foot)", 2, 8, 20, "Per leg", "Bosu Ball", "Legs",
           "Quadriceps", ["Glutes", "Balance"], "intermediate",
           "Front foot on dome, lunge down, maintain balance", "Reverse Lunge"),
        ex("Bosu Push-Up", 3, 10, 20, "Hands on dome or flat side", "Bosu Ball", "Chest",
           "Pectoralis Major", ["Triceps", "Core", "Balance"], "intermediate",
           "Hands on dome, push up, stabilize throughout", "Push-Up"),
        ex("Bosu Plank", 3, 1, 15, "Hold 20-30 seconds", "Bosu Ball", "Core",
           "Rectus Abdominis", ["Obliques", "Balance"], "intermediate",
           "Hands on dome in plank, keep body straight", "Plank"),
        ex("Bosu Mountain Climber", 2, 12, 20, "Hands on dome", "Bosu Ball", "Core",
           "Core", ["Hip Flexors", "Shoulders", "Balance"], "intermediate",
           "Plank on dome, drive knees alternately, stable upper body", "Mountain Climber"),
        ex("Bosu Bridge", 3, 10, 15, "Feet on dome", "Bosu Ball", "Glutes",
           "Gluteus Maximus", ["Hamstrings", "Core", "Balance"], "intermediate",
           "Lie back, feet on dome, bridge up, stabilize", "Glute Bridge"),
    ])]

def _balance_board_workout():
    return [workout("Balance Board Workout", "balance", 25, [
        ex("Balance Board Bilateral Stance", 3, 1, 15, "Hold 30 seconds", "Balance Board", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Stand centered, feet hip-width, keep board level", "Foam Pad Stance"),
        ex("Balance Board Tilts (Front-Back)", 2, 10, 15, "Controlled rocks", "Balance Board", "Full Body",
           "Ankle Stabilizers", ["Calves", "Core"], "beginner",
           "Rock board forward and back slowly, control range", "Balance Board Stance"),
        ex("Balance Board Tilts (Side-Side)", 2, 10, 15, "Controlled rocks", "Balance Board", "Full Body",
           "Ankle Stabilizers", ["Hip Stabilizers", "Core"], "beginner",
           "Rock board side to side slowly, keep upper body stable", "Balance Board Stance"),
        ex("Balance Board Squat", 3, 8, 20, "Partial squat on board", "Balance Board", "Legs",
           "Quadriceps", ["Glutes", "Core", "Balance"], "intermediate",
           "Squat while maintaining board level", "Bodyweight Squat"),
        ex("Balance Board Single-Leg", 3, 1, 15, "Hold 15-20 seconds per leg", "Balance Board", "Full Body",
           "Core", ["Ankle Stabilizers", "Hip Stabilizers"], "intermediate",
           "Stand on one leg, maintain board level", "Single-Leg Stance"),
        ex("Balance Board Clock Reach", 2, 6, 20, "Per leg", "Balance Board", "Full Body",
           "Core", ["Hip Stabilizers", "Balance"], "intermediate",
           "Stand on one leg, reach other foot to clock positions", "Single-Leg Reach"),
        ex("Balance Board Push-Up", 2, 8, 20, "Hands on board", "Balance Board", "Chest",
           "Pectoralis Major", ["Triceps", "Core", "Balance"], "intermediate",
           "Push-up with hands on board, stabilize throughout", "Push-Up"),
    ])]

def _proprioception_drills():
    return [workout("Proprioception Drills", "balance", 25, [
        ex("Single-Leg Stance (Firm Surface)", 2, 1, 10, "30 seconds per leg", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers"], "beginner",
           "Stand on one leg, eyes open, stable surface", "Tandem Stance"),
        ex("Single-Leg Stance (Soft Surface)", 2, 1, 15, "20 seconds per leg", "Foam Pad", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "intermediate",
           "Stand on one leg on foam pad or pillow", "Single-Leg Stance"),
        ex("Perturbation Training", 2, 8, 15, "Per leg, partner or self", "Bodyweight", "Full Body",
           "Core", ["Hip Stabilizers", "Ankle Stabilizers"], "intermediate",
           "Stand on one leg, tap opposite hip or shoulder to challenge balance", "Single-Leg Stance"),
        ex("Ball Toss on One Leg", 2, 10, 15, "Per leg, light ball", "Medicine Ball", "Full Body",
           "Core", ["Shoulders", "Balance"], "intermediate",
           "Stand on one leg, toss and catch ball, maintain balance", "Single-Leg Reach"),
        ex("Heel-to-Toe Walk", 2, 10, 15, "10 steps forward, 10 back", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers"], "beginner",
           "Heel touching toe, straight line, arms out if needed", "Tandem Stance"),
        ex("Star Excursion", 2, 5, 20, "Per leg, reach all directions", "Bodyweight", "Full Body",
           "Core", ["Hip Stabilizers", "Ankle Stabilizers"], "intermediate",
           "Stand on one leg, reach other foot in 8 directions", "Single-Leg Reach"),
        ex("Step-Up with Pause", 2, 8, 20, "Per leg, pause on one foot at top", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Balance"], "intermediate",
           "Step up, balance on lead leg 3 seconds, step down", "Single-Leg Mini Squat"),
        ex("Lateral Hop and Stick", 2, 6, 20, "Per leg", "Bodyweight", "Legs",
           "Glutes", ["Calves", "Ankle Stabilizers", "Balance"], "intermediate",
           "Small lateral hop, land on one foot, hold 3 seconds", "Single-Leg Stance"),
    ])]

def _vestibular_training():
    return [workout("Vestibular Training", "balance", 25, [
        ex("Gaze Stabilization (Horizontal)", 3, 20, 15, "Head turns with fixed gaze", "Bodyweight",
           "Full Body", "Vestibular System", ["Neck", "Eye Muscles"], "beginner",
           "Focus on thumb, turn head side to side, keep eyes on thumb", "Seated Head Turns"),
        ex("Gaze Stabilization (Vertical)", 3, 20, 15, "Head nods with fixed gaze", "Bodyweight",
           "Full Body", "Vestibular System", ["Neck", "Eye Muscles"], "beginner",
           "Focus on thumb, nod head up and down, keep eyes on thumb", "Gaze Horizontal"),
        ex("Tandem Walk with Head Turns", 2, 10, 15, "10 steps", "Bodyweight", "Full Body",
           "Vestibular System", ["Core", "Balance"], "intermediate",
           "Heel-to-toe walk while turning head side to side", "Heel-to-Toe Walk"),
        ex("Seated Head Rotations", 2, 10, 15, "Slow circles", "Bodyweight", "Full Body",
           "Vestibular System", ["Neck"], "beginner",
           "Seated, slowly rotate head, follow with eyes", "Gaze Stabilization"),
        ex("Standing Marches with Head Turns", 2, 20, 15, "March while turning head", "Bodyweight",
           "Full Body", "Vestibular System", ["Hip Flexors", "Balance"], "intermediate",
           "March in place, turn head left and right with each step", "Marching in Place"),
        ex("Single-Leg Stand with Head Movement", 2, 1, 15, "15 seconds per leg", "Bodyweight",
           "Full Body", "Vestibular System", ["Core", "Balance"], "intermediate",
           "Stand on one leg, slowly turn head side to side", "Single-Leg Stance"),
        ex("Walking Figure 8", 2, 3, 20, "3 full figure 8s", "Bodyweight", "Full Body",
           "Vestibular System", ["Core", "Balance"], "intermediate",
           "Walk in figure 8 pattern, focus on smooth turning", "Tandem Walk"),
        ex("Weight Shift with Eyes Closed", 2, 10, 15, "Feet hip-width", "Bodyweight", "Full Body",
           "Vestibular System", ["Ankle Stabilizers", "Balance"], "intermediate",
           "Close eyes, shift weight side to side, stay centered", "Weight Shifts"),
    ])]

def _wobble_board_workout():
    return [workout("Wobble Board Workout", "balance", 25, [
        ex("Wobble Board Bilateral Stance", 3, 1, 15, "Hold 30 seconds", "Wobble Board", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Stand centered, feet hip-width, keep rim from touching floor", "Balance Board Stance"),
        ex("Wobble Board Circles", 2, 10, 15, "Each direction", "Wobble Board", "Full Body",
           "Ankle Stabilizers", ["Core", "Calves"], "beginner",
           "Rotate board in circle, controlled, both directions", "Wobble Board Stance"),
        ex("Wobble Board Tilts", 2, 10, 15, "Front-back and side-side", "Wobble Board", "Full Body",
           "Ankle Stabilizers", ["Calves", "Core"], "beginner",
           "Rock board in each direction, control range", "Wobble Board Circles"),
        ex("Wobble Board Squat", 3, 8, 20, "Partial to full range", "Wobble Board", "Legs",
           "Quadriceps", ["Glutes", "Core", "Balance"], "intermediate",
           "Squat while keeping board stable", "Bodyweight Squat"),
        ex("Wobble Board Single-Leg", 2, 1, 15, "Hold 15 seconds per leg", "Wobble Board", "Full Body",
           "Core", ["Ankle Stabilizers", "Hip Stabilizers"], "intermediate",
           "One foot centered on board, maintain level", "Single-Leg Stance"),
        ex("Wobble Board Clock Reach", 2, 5, 20, "Per leg", "Wobble Board", "Full Body",
           "Core", ["Hip Stabilizers", "Ankle Stabilizers"], "intermediate",
           "Stand on one leg, reach other foot to clock positions", "Star Excursion"),
        ex("Wobble Board Calf Raise", 3, 10, 15, "Both feet on board", "Wobble Board", "Legs",
           "Calves", ["Ankle Stabilizers", "Balance"], "intermediate",
           "Rise on toes while maintaining board stability", "Calf Raise"),
    ])]

def _eyes_closed_training():
    return [workout("Eyes-Closed Training", "balance", 20, [
        ex("Bilateral Stance Eyes Closed", 3, 1, 15, "Hold 30 seconds", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance", "Proprioception"], "beginner",
           "Feet hip-width, close eyes, stay balanced", "Bilateral Stance"),
        ex("Tandem Stance Eyes Closed", 3, 1, 15, "Hold 20 seconds, switch lead", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "intermediate",
           "Heel to toe, close eyes, maintain balance", "Tandem Stance Eyes Open"),
        ex("Single-Leg Stance Eyes Closed", 3, 1, 15, "Hold 10-15 seconds per leg", "Bodyweight",
           "Full Body", "Core", ["Ankle Stabilizers", "Hip Stabilizers"], "intermediate",
           "Stand on one leg, close eyes, hold wall nearby for safety", "Single-Leg Eyes Open"),
        ex("Weight Shifts Eyes Closed", 2, 10, 15, "Side to side", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Proprioception"], "intermediate",
           "Close eyes, shift weight left and right slowly", "Weight Shifts"),
        ex("Marching Eyes Closed", 2, 20, 15, "In place", "Bodyweight", "Full Body",
           "Hip Flexors", ["Core", "Balance"], "intermediate",
           "Close eyes, march in place, try to stay centered", "Marching in Place"),
        ex("Heel-to-Toe Walk Eyes Closed", 2, 8, 20, "8 steps, near wall for safety", "Bodyweight",
           "Full Body", "Core", ["Ankle Stabilizers", "Balance"], "intermediate",
           "Close eyes, walk heel to toe, near wall for support", "Heel-to-Toe Walk"),
        ex("Soft Surface Stance Eyes Closed", 2, 1, 15, "Hold 20 seconds", "Foam Pad", "Full Body",
           "Core", ["Ankle Stabilizers", "Proprioception"], "intermediate",
           "Stand on foam pad, close eyes, maintain balance", "Bilateral Stance Eyes Closed"),
    ])]

def _dynamic_balance():
    return [workout("Dynamic Balance", "balance", 25, [
        ex("Walking Lunge", 3, 10, 20, "Per leg, controlled pace", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Balance", "Core"], "intermediate",
           "Step forward, deep lunge, push off, maintain stability", "Reverse Lunge"),
        ex("Lateral Lunge", 2, 8, 20, "Per leg", "Bodyweight", "Legs",
           "Adductors", ["Quadriceps", "Glutes", "Balance"], "intermediate",
           "Wide step to side, sit into hip, push back", "Lateral Band Walk"),
        ex("Single-Leg Hop and Stick", 2, 6, 20, "Per leg", "Bodyweight", "Legs",
           "Calves", ["Glutes", "Ankle Stabilizers", "Balance"], "intermediate",
           "Small hop forward on one leg, land and hold 3 seconds", "Single-Leg Stance"),
        ex("Crossover Step", 2, 10, 15, "10 steps each direction", "Bodyweight", "Full Body",
           "Hip Stabilizers", ["Core", "Adductors", "Balance"], "intermediate",
           "Step across body, open, across, open, smooth pattern", "Lateral Shuffle"),
        ex("Skater Hops", 2, 10, 20, "Side to side", "Bodyweight", "Legs",
           "Glutes", ["Quadriceps", "Calves", "Balance"], "intermediate",
           "Lateral hop, land on outside foot, stabilize", "Lateral Lunge"),
        SINGLE_LEG_RDL(2, 8, 20, "Bodyweight, focus on control"),
        ex("Agility Ladder Single-Leg Hops", 2, 1, 20, "Through ladder", "Agility Ladder", "Full Body",
           "Calves", ["Core", "Balance", "Coordination"], "intermediate",
           "Hop through ladder squares on one foot", "Single-Leg Hop"),
        ex("Multi-Directional Reach", 2, 6, 20, "Per leg", "Bodyweight", "Full Body",
           "Core", ["Hip Stabilizers", "Ankle Stabilizers"], "intermediate",
           "Stand on one leg, reach opposite foot forward, side, behind", "Star Excursion"),
    ])]

def _sport_balance():
    return [workout("Sport Balance", "balance", 25, [
        ex("Single-Leg Medicine Ball Pass", 2, 10, 15, "Per leg, light ball", "Medicine Ball", "Full Body",
           "Core", ["Shoulders", "Balance"], "intermediate",
           "Stand on one leg, pass ball around body", "Ball Toss Single-Leg"),
        ex("Reactive Step-Up", 3, 8, 20, "Per leg, quick movements", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Calves", "Balance"], "intermediate",
           "Quick step up and back down, change direction on cue", "Step-Up"),
        ex("Lateral Bound", 2, 6, 20, "Per side, stick landing", "Bodyweight", "Legs",
           "Glutes", ["Quadriceps", "Calves", "Balance"], "intermediate",
           "Bound laterally, land on outside foot, hold 2 seconds", "Skater Hops"),
        ex("Single-Leg Box Jump", 2, 5, 30, "Per leg, low box", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Calves", "Balance"], "advanced",
           "Jump onto low box from one foot, land stable", "Box Jump"),
        ex("Rotational Medicine Ball Toss", 2, 8, 20, "Per side, on one leg", "Medicine Ball", "Core",
           "Obliques", ["Core", "Balance", "Power"], "intermediate",
           "Stand on one leg, rotate and toss ball to wall", "Russian Twist"),
        ex("Agility T-Drill", 2, 3, 30, "Full speed", "Bodyweight", "Full Body",
           "Calves", ["Quadriceps", "Core", "Balance"], "intermediate",
           "Sprint forward, shuffle left, shuffle right, backpedal", "Lateral Shuffle"),
        ex("Deceleration Drill", 2, 6, 20, "Sprint and stop", "Bodyweight", "Legs",
           "Quadriceps", ["Hamstrings", "Balance"], "intermediate",
           "Sprint 10 yards, decelerate and stop on one leg", "Single-Leg Hop"),
        ex("Depth Jump to Single-Leg Land", 2, 5, 30, "Low box", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Calves", "Balance"], "advanced",
           "Step off low box, land on one foot, absorb and stabilize", "Box Jump"),
    ])]

def _senior_balance():
    return [workout("Senior Balance", "balance", 20, [
        ex("Seated Weight Shifts", 2, 10, 15, "Side to side", "Bodyweight", "Full Body",
           "Core", ["Balance"], "beginner",
           "Sit on chair edge, shift weight left and right", "Standing Weight Shifts"),
        ex("Sit-to-Stand", 3, 8, 20, "Use armrest if needed", "Bodyweight", "Legs",
           "Quadriceps", ["Glutes", "Core", "Balance"], "beginner",
           "Stand from chair slowly, sit down controlled", "Wall Sit"),
        ex("Tandem Stance (Wall Support)", 3, 1, 15, "Hold 20 seconds, hand on wall", "Bodyweight",
           "Full Body", "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Heel to toe stance, fingertips on wall for safety", "Bilateral Stance"),
        ex("Heel-to-Toe Walk (Wall Support)", 2, 8, 15, "Near wall", "Bodyweight", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "beginner",
           "Walk heel to toe along wall, light hand contact", "Tandem Stance"),
        ex("Single-Leg Stance (Wall Support)", 2, 1, 15, "Hold 15 seconds per leg", "Bodyweight",
           "Full Body", "Core", ["Hip Stabilizers", "Balance"], "beginner",
           "Stand on one leg, fingertips on wall, maintain posture", "Tandem Stance"),
        ex("Lateral Step", 2, 8, 15, "Step side to side", "Bodyweight", "Legs",
           "Hip Abductors", ["Glutes", "Balance"], "beginner",
           "Step to one side, bring feet together, repeat", "Lateral Band Walk"),
        ex("Seated Calf Raise", 3, 12, 15, "Seated on chair", "Bodyweight", "Legs",
           "Calves", ["Soleus"], "beginner",
           "Seated, lift heels off floor, hold 2 seconds, lower", "Standing Calf Raise"),
        ex("Standing March", 2, 10, 15, "Hold chair if needed", "Bodyweight", "Legs",
           "Hip Flexors", ["Core", "Balance"], "beginner",
           "March in place, lift knees to comfortable height", "Seated March"),
    ])]

def _surf_balance_training():
    return [workout("Surf Balance Training", "balance", 30, [
        ex("Indo Board Stance", 3, 1, 15, "Hold 30 seconds", "Balance Board", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "intermediate",
           "Stand on balance board, find center, maintain level", "Bosu Ball Stance"),
        ex("Indo Board Squat", 3, 8, 20, "Partial to full range", "Balance Board", "Legs",
           "Quadriceps", ["Glutes", "Core", "Balance"], "intermediate",
           "Squat on balance board, stay centered", "Bodyweight Squat"),
        ex("Pop-Up Drill", 3, 8, 20, "On floor, explosive", "Bodyweight", "Full Body",
           "Full Body", ["Core", "Arms", "Legs"], "intermediate",
           "Lie prone, pop to standing surf stance explosively", "Burpee"),
        ex("Single-Leg Stance on Foam", 3, 1, 15, "20 seconds per leg", "Foam Pad", "Full Body",
           "Core", ["Ankle Stabilizers", "Balance"], "intermediate",
           "Stand on one leg on foam pad, maintain stability", "Single-Leg Stance"),
        ex("Rotational Lunge", 2, 8, 20, "Per side, add torso rotation", "Bodyweight", "Legs",
           "Quadriceps", ["Obliques", "Glutes", "Balance"], "intermediate",
           "Lunge forward, rotate torso over front leg, return", "Walking Lunge"),
        SINGLE_LEG_RDL(2, 8, 20, "Bodyweight, mimic paddle reach"),
        ex("Lateral Hop and Hold", 2, 8, 20, "Per side", "Bodyweight", "Legs",
           "Glutes", ["Calves", "Balance", "Ankle Stabilizers"], "intermediate",
           "Hop laterally, land on outside foot, hold 3 seconds", "Skater Hops"),
        ex("Bosu Ball Stance with Perturbation", 2, 1, 15, "20 seconds, partner pushes lightly",
           "Bosu Ball", "Full Body", "Core", ["Balance", "Ankle Stabilizers"], "intermediate",
           "Stand on bosu, have partner gently push shoulders", "Bosu Ball Stance"),
        ex("Plank with Hip Rotation", 3, 8, 20, "Alternate sides", "Bodyweight", "Core",
           "Obliques", ["Rectus Abdominis", "Balance"], "intermediate",
           "Plank position, rotate hips side to side controlled", "Side Plank"),
    ])]


###############################################################################
# BATCH_WORKOUTS dict - maps program name to callable returning workout list
###############################################################################

BATCH_WORKOUTS = {
    # Mobility (20)
    "Deadlift Mobility Prep": _deadlift_mobility_prep,
    "Squat Mobility Prep": _squat_mobility_prep,
    "Bench Press Mobility": _bench_press_mobility,
    "Overhead Press Mobility": _overhead_press_mobility,
    "Post-Deadlift Recovery": _post_deadlift_recovery,
    "Post-Squat Recovery": _post_squat_recovery,
    "Post-Leg Day Recovery": _post_leg_day_recovery,
    "Post-Pull Day Recovery": _post_pull_day_recovery,
    "Post-Push Day Recovery": _post_push_day_recovery,
    "Hip Hinge Mastery": _hip_hinge_mastery,
    "Powerlifter Mobility": _powerlifter_mobility,
    "Olympic Lift Mobility": _olympic_lift_mobility,
    "Tight Hamstring Fix": _tight_hamstring_fix,
    "Lower Back Relief for Lifters": _lower_back_relief_for_lifters,
    "Hip Hinge Mobility": _hip_hinge_mobility,
    "Thoracic Mobility": _thoracic_mobility,
    "Hip Mobility Flow": _hip_mobility_flow,
    "Pre-Squat Mobility": _pre_squat_mobility,
    "General Lifting Warmup": _general_lifting_warmup,
    "Powerlifting Mobility": _powerlifting_mobility,

    # Warmup & Cooldown (5)
    "Sports Warmup": _sports_warmup,
    "Post-Workout Cool Down": _post_workout_cool_down,
    "Office Break Warmup": _office_break_warmup,
    "Pre-Run Warmup": _pre_run_warmup,
    "Pre-Swim Warmup": _pre_swim_warmup,

    # Stretching (8)
    "Hip Opener Series": _hip_opener_series,
    "Shoulder Stretch Routine": _shoulder_stretch_routine,
    "Hamstring Flexibility": _hamstring_flexibility,
    "Quad & Hip Flexor Stretch": _quad_hip_flexor_stretch,
    "Back Flexibility": _back_flexibility,
    "IT Band & Glute Stretch": _it_band_glute_stretch,
    "Ankle Flexibility": _ankle_flexibility,
    "Chest & Bicep Stretch": _chest_bicep_stretch,

    # Rehab (7)
    "Ankle Rehab": _ankle_rehab,
    "Wrist & Elbow Rehab": _wrist_elbow_rehab,
    "Post-Surgery General": _post_surgery_general,
    "ACL Recovery": _acl_recovery,
    "Rotator Cuff Rehab": _rotator_cuff_rehab,
    "Sciatica Relief": _sciatica_relief,
    "Plantar Fasciitis Relief": _plantar_fasciitis_relief,

    # Posture (7)
    "Forward Head Fix": _forward_head_fix,
    "APT Fix": _apt_fix,
    "Desk Worker Posture": _desk_worker_posture,
    "Scoliosis Support": _scoliosis_support,
    "Lordosis Fix": _lordosis_fix,
    "Tech Posture Reset": _tech_posture_reset,
    "Standing Posture Training": _standing_posture_training,

    # Balance (12)
    "Balance Foundation": _balance_foundation,
    "Single-Leg Stability": _single_leg_stability,
    "Bosu Ball Training": _bosu_ball_training,
    "Balance Board Workout": _balance_board_workout,
    "Proprioception Drills": _proprioception_drills,
    "Vestibular Training": _vestibular_training,
    "Wobble Board Workout": _wobble_board_workout,
    "Eyes-Closed Training": _eyes_closed_training,
    "Dynamic Balance": _dynamic_balance,
    "Sport Balance": _sport_balance,
    "Senior Balance": _senior_balance,
    "Surf Balance Training": _surf_balance_training,
}
