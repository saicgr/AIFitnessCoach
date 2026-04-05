from typing import Any
#!/usr/bin/env python3
"""
Batch 7: Age/Life Stage & Miscellaneous Programs (68 total)
- Seniors (14)
- Kids & Youth (8)
- Anti-Aging (12)
- Life Events (16)
- Motivational (12)
- Occupation (4)
- Sedentary (2)
"""
from exercise_lib import *


###############################################################################
# SENIORS (14 programs) - Gentle, safe, chair/standing exercises
###############################################################################

def _senior_fitness_fundamentals():
    return [
        workout("Senior Fitness Session A", "strength", 30, [
            ex("Seated Marching", 3, 15, 15, "Gentle pace", "Chair", "Legs", "Hip Flexors",
               ["Core"], "beginner", "Lift knees alternately while seated", "Standing March"),
            ex("Wall Push-Up", 3, 10, 20, "Against sturdy wall", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps", "Shoulders"], "beginner", "Lean into wall, press back", "Countertop Push-Up"),
            ex("Chair Squat", 3, 10, 20, "Sit and stand", "Chair", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Lower to chair, stand back up controlled", "Wall Sit"),
            ex("Seated Shoulder Press", 3, 10, 20, "Light dumbbells 2-5 lbs", "Dumbbell", "Shoulders", "Deltoids",
               ["Triceps"], "beginner", "Press overhead from shoulders", "Arm Raise"),
            ex("Standing Calf Raise", 3, 12, 15, "Hold chair for balance", "Bodyweight", "Legs", "Calves",
               ["Tibialis Anterior"], "beginner", "Rise onto toes, slow lower", "Seated Calf Raise"),
            ex("Seated Bicep Curl", 3, 10, 15, "Light dumbbells 2-5 lbs", "Dumbbell", "Arms", "Biceps",
               ["Forearms"], "beginner", "Curl slowly, squeeze at top", "Resistance Band Curl"),
        ]),
        workout("Senior Fitness Session B", "strength", 30, [
            ex("Standing Knee Lift", 3, 10, 15, "Hold chair for balance", "Bodyweight", "Core", "Hip Flexors",
               ["Rectus Abdominis"], "beginner", "Lift knee toward chest, stand tall", "Seated Marching"),
            ex("Countertop Push-Up", 3, 10, 20, "Against kitchen counter", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean in and press back", "Wall Push-Up"),
            ex("Standing Leg Curl", 3, 10, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hamstrings",
               ["Calves"], "beginner", "Curl heel toward glute", "Seated Leg Curl"),
            ex("Seated Row with Band", 3, 10, 15, "Light resistance band", "Resistance Band", "Back", "Latissimus Dorsi",
               ["Rhomboids", "Biceps"], "beginner", "Pull band toward chest, squeeze", "Seated Arm Pull"),
            ex("Standing Side Leg Raise", 3, 10, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hip Abductors",
               ["Glutes"], "beginner", "Lift leg to side, keep toe forward", "Seated Leg Lift"),
            GLUTE_BRIDGE(3, 12, 20, "Bodyweight, squeeze at top"),
        ]),
    ]


def _chair_exercises():
    return [
        workout("Chair Exercise Session", "flexibility", 20, [
            ex("Seated Marching", 3, 15, 10, "Gentle pace", "Chair", "Legs", "Hip Flexors",
               ["Core"], "beginner", "Lift knees alternately", "Ankle Pumps"),
            ex("Seated Arm Raise", 3, 10, 10, "Raise arms overhead", "Chair", "Shoulders", "Deltoids",
               ["Trapezius"], "beginner", "Raise arms slowly overhead", "Shoulder Shrug"),
            ex("Seated Leg Extension", 3, 10, 10, "Extend one leg at a time", "Chair", "Legs", "Quadriceps",
               ["Hip Flexors"], "beginner", "Straighten knee, hold 2 seconds", "Seated Knee Lift"),
            ex("Seated Torso Twist", 3, 8, 10, "Twist left and right", "Chair", "Core", "Obliques",
               ["Erector Spinae"], "beginner", "Rotate upper body gently", "Seated Side Bend"),
            ex("Seated Heel Raise", 3, 15, 10, "Both feet", "Chair", "Legs", "Calves",
               ["Tibialis Anterior"], "beginner", "Lift heels, press through toes", "Ankle Circle"),
            ex("Seated Cat-Cow", 3, 8, 10, "Arch and round", "Chair", "Back", "Erector Spinae",
               ["Core"], "beginner", "Inhale arch, exhale round", "Seated Spinal Rotation"),
            ex("Seated Wrist Circle", 2, 10, 0, "Both directions", "Chair", "Arms", "Forearms",
               ["Wrist Flexors"], "beginner", "Circle wrists slowly", "Wrist Flexion Extension"),
        ]),
    ]


def _balance_fall_prevention():
    return [
        workout("Balance & Fall Prevention", "strength", 25, [
            ex("Tandem Stand", 3, 1, 15, "Hold 20 seconds", "Bodyweight", "Legs", "Calves",
               ["Core", "Hip Stabilizers"], "beginner", "Heel to toe, hold balance", "Wall-Assisted Tandem"),
            ex("Single Leg Stand", 3, 1, 15, "Hold 15 seconds each", "Bodyweight", "Legs", "Calves",
               ["Core", "Glutes"], "beginner", "Stand on one leg near wall", "Chair-Assisted Balance"),
            ex("Heel to Toe Walk", 3, 10, 15, "Steps in a line", "Bodyweight", "Legs", "Calves",
               ["Core", "Hip Stabilizers"], "beginner", "Walk placing heel to toe", "Side Step Walk"),
            ex("Lateral Weight Shift", 3, 10, 10, "Side to side", "Bodyweight", "Legs", "Hip Abductors",
               ["Core", "Glutes"], "beginner", "Shift weight left to right", "Side Step"),
            ex("Clock Reach", 3, 6, 15, "Each direction", "Bodyweight", "Legs", "Quadriceps",
               ["Core", "Hip Stabilizers"], "beginner", "Stand on one leg, reach like clock hands", "Single Leg Stand"),
            ex("Chair Stand", 3, 8, 20, "Without using hands", "Chair", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Stand up from chair without arms", "Assisted Chair Stand"),
        ]),
    ]


def _senior_flexibility():
    return [
        workout("Senior Flexibility Session", "flexibility", 20, [
            ex("Neck Stretch", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Neck", "Trapezius",
               ["Scalenes"], "beginner", "Ear toward shoulder, gentle pressure", "Neck Roll"),
            ex("Shoulder Stretch", 2, 1, 0, "Hold 20 seconds each", "Bodyweight", "Shoulders", "Deltoids",
               ["Rotator Cuff"], "beginner", "Cross arm across chest, gentle pull", "Doorway Stretch"),
            ex("Seated Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each", "Chair", "Legs", "Hamstrings",
               ["Calves"], "beginner", "Extend leg, lean forward gently", "Standing Hamstring Stretch"),
            ex("Seated Spinal Twist", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Back", "Obliques",
               ["Erector Spinae"], "beginner", "Rotate upper body, look behind", "Standing Twist"),
            ex("Calf Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Legs", "Calves",
               ["Soleus"], "beginner", "Step back, press heel down", "Wall Calf Stretch"),
            ex("Chest Opener", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Chest", "Pectoralis Major",
               ["Anterior Deltoid"], "beginner", "Clasp hands behind back, open chest", "Doorway Stretch"),
            ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Hips", "Hip Flexors",
               ["Quadriceps"], "beginner", "Half kneeling lunge, push hips forward", "Standing Hip Stretch"),
        ]),
    ]


def _arthritis_friendly_movement():
    return [
        workout("Arthritis-Friendly Movement", "flexibility", 20, [
            ex("Finger Squeeze", 3, 10, 5, "Squeeze soft ball", "Stress Ball", "Arms", "Forearms",
               ["Fingers"], "beginner", "Squeeze gently, hold 3 seconds, release", "Finger Extension"),
            ex("Wrist Circle", 2, 10, 5, "Both directions", "Bodyweight", "Arms", "Forearms",
               ["Wrist Flexors"], "beginner", "Slow gentle circles", "Wrist Flexion Extension"),
            ex("Ankle Circle", 2, 10, 5, "Both directions each foot", "Bodyweight", "Legs", "Tibialis Anterior",
               ["Calves"], "beginner", "Full gentle range of motion", "Ankle Pump"),
            ex("Shoulder Roll", 3, 10, 5, "Forward and backward", "Bodyweight", "Shoulders", "Trapezius",
               ["Deltoids"], "beginner", "Slow controlled circles", "Arm Circle"),
            ex("Seated Knee Lift", 3, 8, 10, "Gentle lifts", "Chair", "Legs", "Hip Flexors",
               ["Quadriceps"], "beginner", "Lift knee gently toward chest", "Seated Marching"),
            ex("Seated Side Bend", 2, 8, 5, "Each side", "Chair", "Core", "Obliques",
               ["Erector Spinae"], "beginner", "Lean gently to each side", "Seated Torso Twist"),
            ex("Gentle Neck Turn", 2, 6, 5, "Each side", "Bodyweight", "Neck", "Sternocleidomastoid",
               ["Trapezius"], "beginner", "Turn head slowly left and right", "Neck Stretch"),
        ]),
    ]


def _senior_tai_chi():
    return [
        workout("Senior Tai Chi Session", "flexibility", 25, [
            ex("Tai Chi Opening", 2, 6, 10, "Slow arm raise", "Bodyweight", "Full Body", "Deltoids",
               ["Core"], "beginner", "Raise arms slowly, breathe in, lower with exhale", "Arm Raise"),
            ex("Wave Hands Like Clouds", 3, 8, 10, "Flowing side to side", "Bodyweight", "Full Body", "Obliques",
               ["Shoulders", "Core"], "beginner", "Weight shift side to side, arms flow", "Seated Torso Twist"),
            ex("Parting Wild Horses Mane", 3, 6, 10, "Step and separate", "Bodyweight", "Full Body", "Hip Flexors",
               ["Shoulders", "Core"], "beginner", "Step forward, separate hands", "Walking Lunge"),
            ex("Brush Knee Twist Step", 3, 6, 10, "Forward stepping", "Bodyweight", "Legs", "Quadriceps",
               ["Obliques", "Hip Flexors"], "beginner", "Step, brush past knee, push forward", "Walking"),
            ex("Single Whip", 3, 6, 10, "Open and close stance", "Bodyweight", "Full Body", "Deltoids",
               ["Core", "Legs"], "beginner", "Open arms wide, shift weight", "Arm Raise"),
            ex("Closing Form", 2, 6, 10, "Return to center", "Bodyweight", "Full Body", "Core",
               ["Shoulders"], "beginner", "Bring arms down slowly, deep breath", "Deep Breathing"),
        ]),
    ]


def _senior_aqua_fitness():
    return [
        workout("Senior Aqua Fitness", "cardio", 30, [
            ex("Water Walking", 3, 1, 10, "Walk 2 minutes", "Pool", "Full Body", "Quadriceps",
               ["Core", "Hip Flexors"], "beginner", "Walk through chest-deep water with big steps", "Seated Marching"),
            ex("Water Arm Curl", 3, 12, 10, "Against water resistance", "Pool", "Arms", "Biceps",
               ["Forearms"], "beginner", "Curl arms through water slowly", "Resistance Band Curl"),
            ex("Water Leg Lift", 3, 10, 10, "Hold pool edge", "Pool", "Legs", "Hip Flexors",
               ["Core", "Quadriceps"], "beginner", "Lift leg forward in water", "Seated Leg Extension"),
            ex("Water Jumping Jack", 3, 12, 10, "In shallow water", "Pool", "Full Body", "Calves",
               ["Shoulders", "Core"], "beginner", "Jump feet out and in, push arms", "Step Jacks"),
            ex("Flutter Kick", 3, 15, 10, "Hold pool edge", "Pool", "Legs", "Hip Flexors",
               ["Quadriceps", "Core"], "beginner", "Rapid small kicks at surface", "Leg Lift"),
            ex("Water Push", 3, 10, 10, "Push water forward and back", "Pool", "Chest", "Pectoralis Major",
               ["Shoulders", "Core"], "beginner", "Push palms through water", "Wall Push-Up"),
        ]),
    ]


def _active_aging():
    return [
        workout("Active Aging Session", "strength", 30, [
            ex("Chair Squat", 3, 10, 20, "Sit and stand", "Chair", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Lower to chair, stand back up controlled", "Wall Sit"),
            ex("Wall Push-Up", 3, 10, 15, "Against wall", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean in, press back", "Countertop Push-Up"),
            ex("Standing Leg Curl", 3, 10, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hamstrings",
               ["Calves"], "beginner", "Curl heel toward glute", "Seated Leg Curl"),
            ex("Seated Row with Band", 3, 10, 15, "Light resistance band", "Resistance Band", "Back", "Latissimus Dorsi",
               ["Rhomboids", "Biceps"], "beginner", "Pull band toward chest, squeeze", "Seated Arm Pull"),
            ex("Standing Side Leg Raise", 3, 10, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hip Abductors",
               ["Glutes"], "beginner", "Lift leg to side, keep toe forward", "Seated Leg Lift"),
            ex("Seated Overhead Press", 3, 8, 15, "Light weight 2-3 lbs", "Dumbbell", "Shoulders", "Deltoids",
               ["Triceps"], "beginner", "Press straight up from shoulders", "Arm Raise"),
        ]),
    ]


def _senior_yoga():
    return [
        workout("Senior Yoga Session", "flexibility", 25, [
            ex("Mountain Pose", 2, 1, 10, "Hold 30 seconds", "Bodyweight", "Full Body", "Core",
               ["Calves", "Quadriceps"], "beginner", "Stand tall, feet hip width, arms at sides", "Seated Mountain Pose"),
            ex("Chair Pose Modified", 2, 1, 15, "Hold 15 seconds", "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Core"], "beginner", "Slight squat, arms forward or up", "Wall Sit"),
            ex("Warrior I Modified", 2, 1, 15, "Hold 20 seconds each side", "Bodyweight", "Legs", "Quadriceps",
               ["Hip Flexors", "Shoulders"], "beginner", "Short lunge, arms up, use chair if needed", "Standing Lunge"),
            ex("Tree Pose Modified", 2, 1, 15, "Hold 15 seconds each side", "Bodyweight", "Legs", "Calves",
               ["Core", "Hip Stabilizers"], "beginner", "Foot on ankle or calf, use wall", "Single Leg Stand"),
            ex("Seated Forward Fold", 2, 1, 10, "Hold 30 seconds", "Chair", "Back", "Hamstrings",
               ["Erector Spinae"], "beginner", "Hinge at hips, reach toward toes", "Standing Forward Fold"),
            ex("Cat-Cow Seated", 3, 8, 5, "Breath with movement", "Chair", "Back", "Erector Spinae",
               ["Core"], "beginner", "Inhale arch, exhale round", "Standing Cat-Cow"),
            ex("Seated Twist", 2, 1, 10, "Hold 20 seconds each side", "Chair", "Core", "Obliques",
               ["Erector Spinae"], "beginner", "Rotate gently, use backrest", "Standing Twist"),
        ]),
    ]


def _obese_senior_safe_start():
    return [
        workout("Obese Senior Safe Start", "flexibility", 25, [
            ex("Seated Marching", 3, 12, 15, "Gentle pace", "Chair", "Legs", "Hip Flexors",
               ["Core"], "beginner", "Lift knees alternately, stay upright", "Ankle Pump"),
            ex("Seated Arm Raise", 3, 8, 15, "No weight needed", "Chair", "Shoulders", "Deltoids",
               ["Trapezius"], "beginner", "Raise arms slowly to shoulder height", "Shoulder Shrug"),
            ex("Ankle Pump", 3, 15, 10, "Point and flex", "Chair", "Legs", "Calves",
               ["Tibialis Anterior"], "beginner", "Point toes then pull back", "Ankle Circle"),
            ex("Seated Side Bend", 2, 6, 10, "Each side", "Chair", "Core", "Obliques",
               ["Erector Spinae"], "beginner", "Lean gently, reach toward floor", "Seated Torso Twist"),
            ex("Deep Breathing", 3, 5, 10, "Diaphragmatic", "Chair", "Core", "Diaphragm",
               ["Transverse Abdominis"], "beginner", "Breathe in 4 counts, out 6 counts", "Box Breathing"),
            ex("Seated Heel Raise", 3, 12, 10, "Both feet", "Chair", "Legs", "Calves",
               ["Tibialis Anterior"], "beginner", "Press through toes, lift heels", "Ankle Pump"),
        ]),
    ]


def _obese_senior_strength():
    return [
        workout("Obese Senior Strength", "strength", 25, [
            ex("Assisted Chair Squat", 3, 8, 25, "Use armrests", "Chair", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Use arms to help stand, control descent", "Seated Leg Press"),
            ex("Wall Push-Up", 3, 8, 20, "Wide stance for stability", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Stand arm length from wall, push", "Countertop Push-Up"),
            ex("Seated Bicep Curl", 3, 8, 15, "Very light weight 1-2 lbs", "Dumbbell", "Arms", "Biceps",
               ["Forearms"], "beginner", "Curl slowly, full range", "Resistance Band Curl"),
            ex("Seated Leg Extension", 3, 8, 15, "One leg at a time", "Chair", "Legs", "Quadriceps",
               ["Hip Flexors"], "beginner", "Straighten knee, hold 2 seconds", "Seated Knee Lift"),
            ex("Seated Row with Band", 3, 8, 15, "Light band", "Resistance Band", "Back", "Latissimus Dorsi",
               ["Rhomboids"], "beginner", "Pull band to chest", "Seated Arm Pull"),
            ex("Seated Shoulder Press", 3, 8, 15, "Very light weight 1-2 lbs", "Dumbbell", "Shoulders", "Deltoids",
               ["Triceps"], "beginner", "Press up from shoulders", "Arm Raise"),
        ]),
    ]


def _obese_senior_mobility():
    return [
        workout("Obese Senior Mobility", "flexibility", 20, [
            ex("Seated Ankle Circle", 2, 10, 5, "Each direction", "Chair", "Legs", "Tibialis Anterior",
               ["Calves"], "beginner", "Gentle circles with each foot", "Ankle Pump"),
            ex("Seated Shoulder Roll", 3, 10, 5, "Forward and back", "Chair", "Shoulders", "Trapezius",
               ["Deltoids"], "beginner", "Roll shoulders slowly", "Arm Circle"),
            ex("Seated Hip Circle", 2, 8, 10, "Small circles", "Chair", "Hips", "Hip Flexors",
               ["Glutes"], "beginner", "Shift weight in circular motion", "Seated Marching"),
            ex("Seated Neck Stretch", 2, 1, 5, "Hold 15 seconds each side", "Chair", "Neck", "Trapezius",
               ["Scalenes"], "beginner", "Tilt ear to shoulder gently", "Neck Roll"),
            ex("Seated Chest Opener", 2, 1, 5, "Hold 15 seconds", "Chair", "Chest", "Pectoralis Major",
               ["Anterior Deltoid"], "beginner", "Squeeze shoulder blades together", "Doorway Stretch"),
            ex("Seated Wrist Stretch", 2, 1, 5, "Hold 15 seconds each", "Chair", "Arms", "Forearms",
               ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back", "Wrist Circle"),
        ]),
    ]


def _senior_weight_loss():
    return [
        workout("Senior Weight Loss Session", "cardio", 30, [
            ex("Seated Marching", 3, 20, 10, "Brisk pace", "Chair", "Legs", "Hip Flexors",
               ["Core"], "beginner", "Quick alternating knees", "Standing March"),
            ex("Standing Leg Curl", 3, 12, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hamstrings",
               ["Calves"], "beginner", "Curl heel toward glute", "Seated Leg Curl"),
            ex("Wall Push-Up", 3, 10, 15, "Steady tempo", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean in and push back", "Countertop Push-Up"),
            ex("Chair Squat", 3, 10, 20, "Controlled", "Chair", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Sit back, stand up", "Wall Sit"),
            ex("Arm Circle", 3, 15, 10, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids",
               ["Rotator Cuff"], "beginner", "Start small, gradually bigger", "Shoulder Roll"),
            ex("Standing Knee Lift", 3, 10, 10, "Alternating", "Bodyweight", "Core", "Hip Flexors",
               ["Rectus Abdominis"], "beginner", "Lift knee toward chest, stand tall", "Seated Marching"),
        ]),
    ]


def _senior_multicomponent_training():
    return [
        workout("Senior Multicomponent Session", "strength", 35, [
            ex("Chair Squat", 3, 10, 20, "Controlled pace", "Chair", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Sit back and stand up", "Wall Sit"),
            ex("Wall Push-Up", 3, 10, 15, "Slow tempo", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean in, press back", "Countertop Push-Up"),
            ex("Tandem Walk", 3, 10, 15, "Heel to toe steps", "Bodyweight", "Legs", "Calves",
               ["Core", "Hip Stabilizers"], "beginner", "Walk in straight line, heel to toe", "Side Step"),
            ex("Seated Row with Band", 3, 10, 15, "Light band", "Resistance Band", "Back", "Latissimus Dorsi",
               ["Rhomboids", "Biceps"], "beginner", "Pull band to chest, squeeze back", "Seated Arm Pull"),
            ex("Standing Calf Raise", 3, 12, 10, "Hold chair", "Bodyweight", "Legs", "Calves",
               ["Tibialis Anterior"], "beginner", "Rise onto toes, control down", "Seated Calf Raise"),
            ex("Seated Stretch Sequence", 2, 1, 5, "Hold 30 seconds each", "Chair", "Full Body", "Hamstrings",
               ["Shoulders", "Back"], "beginner", "Stretch major muscle groups seated", "Standing Stretch"),
            ex("Deep Breathing", 2, 5, 0, "Cool down", "Bodyweight", "Core", "Diaphragm",
               ["Transverse Abdominis"], "beginner", "Breathe in 4, out 6, relax body", "Box Breathing"),
        ]),
    ]


###############################################################################
# KIDS & YOUTH (8 programs) - Fun, bodyweight-focused
###############################################################################

def _kids_fitness_fun():
    return [
        workout("Kids Fun Circuit", "bodyweight", 25, [
            ex("Jumping Jacks", 3, 15, 15, "Fun pace", "Bodyweight", "Full Body", "Calves",
               ["Shoulders", "Core"], "beginner", "Clap hands overhead, land softly", "Star Jumps"),
            ex("Bear Crawl", 3, 10, 20, "Across the room", "Bodyweight", "Full Body", "Shoulders",
               ["Core", "Quadriceps"], "beginner", "Hands and feet on ground, hips low", "Crab Walk"),
            ex("Frog Jump", 3, 8, 20, "Jump like a frog", "Bodyweight", "Legs", "Quadriceps",
               ["Calves", "Glutes"], "beginner", "Deep squat, explode forward", "Squat Jump"),
            ex("Crab Walk", 3, 10, 20, "Across and back", "Bodyweight", "Full Body", "Triceps",
               ["Core", "Shoulders"], "beginner", "Belly up, walk on hands and feet", "Bear Crawl"),
            HIGH_KNEES(1, 20, 15, "Fast and fun"),
            PLANK(2, 1, 15, "Hold 15 seconds"),
        ]),
        workout("Kids Agility Fun", "bodyweight", 25, [
            ex("Lateral Shuffle", 3, 10, 15, "Side to side", "Bodyweight", "Legs", "Hip Abductors",
               ["Calves", "Quadriceps"], "beginner", "Stay low, quick feet", "Side Step"),
            ex("Skipping", 3, 20, 15, "Skip across floor", "Bodyweight", "Legs", "Calves",
               ["Quadriceps", "Core"], "beginner", "Drive knee up, swing opposite arm", "Marching"),
            ex("Star Jumps", 3, 10, 15, "Spread like a star", "Bodyweight", "Full Body", "Quadriceps",
               ["Shoulders", "Calves"], "beginner", "Jump up, spread arms and legs wide", "Jumping Jacks"),
            ex("Inchworm Walk", 2, 6, 20, "Walk hands out and back", "Bodyweight", "Full Body", "Hamstrings",
               ["Shoulders", "Core"], "beginner", "Keep legs straight, walk hands to plank", "Standing Toe Touch"),
            ex("Bunny Hops", 3, 10, 15, "Hop with both feet", "Bodyweight", "Legs", "Calves",
               ["Quadriceps"], "beginner", "Soft landings, hop forward", "Tuck Jumps"),
            SUPERMAN(2, 8, 15, "Hold 5 seconds at top"),
        ]),
    ]


def _teen_strength_basics():
    return [
        workout("Teen Strength Foundations", "strength", 30, [
            BODYWEIGHT_SQUAT(3, 12, 30, "Focus on form"),
            PUSHUP(3, 10, 30, "Full range or from knees"),
            INVERTED_ROW(3, 8, 30, "Use bar or table edge"),
            GOBLET_SQUAT(3, 10, 30, "Light dumbbell"),
            DB_ROW(3, 10, 30, "Light to moderate"),
            PLANK(3, 1, 20, "Hold 20-30 seconds"),
            GLUTE_BRIDGE(3, 12, 20, "Squeeze at top"),
        ]),
    ]


def _youth_sports_prep():
    return [
        workout("Youth Sports Prep", "strength", 30, [
            ex("A-Skip", 3, 10, 15, "High knee drive", "Bodyweight", "Legs", "Hip Flexors",
               ["Calves", "Core"], "beginner", "Drive knee up, skip forward", "High Knees"),
            ex("Lateral Shuffle", 3, 10, 15, "Quick feet", "Bodyweight", "Legs", "Hip Abductors",
               ["Quadriceps", "Calves"], "beginner", "Stay low, quick side to side", "Side Step"),
            JUMP_SQUAT(3, 8, 20, "Explosive"),
            PUSHUP(3, 10, 20, "Strict form"),
            ex("Single Leg Balance", 2, 1, 10, "Hold 15 seconds each", "Bodyweight", "Legs", "Calves",
               ["Core", "Hip Stabilizers"], "beginner", "Stand on one foot, stay steady", "Wall-Assisted Balance"),
            ex("Agility Dot Drill", 3, 6, 20, "5-dot pattern", "Bodyweight", "Legs", "Calves",
               ["Quadriceps", "Core"], "beginner", "Quick feet through dot pattern", "Ladder Drill"),
        ]),
    ]


def _teen_hiit():
    return [
        workout("Teen HIIT Session", "hiit", 25, [
            JUMP_SQUAT(3, 10, 20, "Explosive jumps"),
            MOUNTAIN_CLIMBER(3, 15, 20, "Quick pace"),
            BURPEE(3, 6, 30, "Modified if needed"),
            ex("Lateral Bound", 3, 8, 20, "Side to side jumps", "Bodyweight", "Legs", "Glutes",
               ["Quadriceps", "Calves"], "beginner", "Jump sideways, stick landing", "Lateral Shuffle"),
            ex("Plank Jack", 3, 12, 20, "Plank position jack", "Bodyweight", "Core", "Rectus Abdominis",
               ["Shoulders", "Hip Abductors"], "beginner", "Plank position, jump feet in and out", "Jumping Jacks"),
            ex("Tuck Jump", 3, 8, 25, "Bring knees up", "Bodyweight", "Legs", "Quadriceps",
               ["Core", "Calves"], "intermediate", "Jump high, pull knees to chest", "Squat Jump"),
        ]),
    ]


def _kids_calisthenics():
    return [
        workout("Kids Calisthenics", "bodyweight", 25, [
            ex("Wall Push-Up", 3, 10, 15, "Against a wall", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean into wall, push back", "Knee Push-Up"),
            ex("Squat Hold", 3, 1, 15, "Hold 10 seconds", "Bodyweight", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Sit back, hold at bottom", "Chair Squat"),
            ex("Dead Hang", 2, 1, 20, "Hold 10-15 seconds", "Pull-Up Bar", "Back", "Forearms",
               ["Latissimus Dorsi"], "beginner", "Hang with straight arms, relax shoulders", "Towel Hang"),
            ex("L-Sit Tuck Hold", 2, 1, 20, "Hold 5-10 seconds", "Bodyweight", "Core", "Hip Flexors",
               ["Rectus Abdominis"], "beginner", "Hands on floor, lift tucked knees", "Knee Raise"),
            ex("Broad Jump", 3, 6, 20, "Jump as far as you can", "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Calves"], "beginner", "Swing arms, jump forward", "Squat Jump"),
            ex("Inchworm Walk", 3, 5, 20, "Walk hands out to plank", "Bodyweight", "Full Body", "Hamstrings",
               ["Core", "Shoulders"], "beginner", "Walk hands out, walk feet to hands", "Standing Toe Touch"),
        ]),
    ]


def _teen_athlete_development():
    return [
        workout("Teen Athletic Development", "strength", 35, [
            BOX_JUMP(3, 8, 30, "Low box 12-16 inch"),
            DB_LUNGE(3, 10, 30, "Light dumbbells"),
            ex("Medicine Ball Slam", 3, 8, 25, "Light med ball", "Medicine Ball", "Full Body", "Core",
               ["Shoulders", "Latissimus Dorsi"], "beginner", "Reach overhead, slam to ground", "Bodyweight Squat"),
            PUSHUP(3, 12, 25, "Strict form"),
            BAND_PULL_APART(3, 12, 20, "Light band"),
            SIDE_PLANK(2, 1, 15, "Hold 15 seconds each side"),
        ]),
    ]


def _kids_dance_fitness():
    return [
        workout("Kids Dance Fitness", "cardio", 20, [
            JUMPING_JACK(3, 20, 10, "Dance rhythm"),
            ex("Grapevine Step", 3, 12, 10, "Side to side", "Bodyweight", "Legs", "Hip Abductors",
               ["Calves", "Core"], "beginner", "Step behind, step together, step out", "Side Step"),
            ex("High Knee March", 3, 20, 10, "March to music", "Bodyweight", "Legs", "Hip Flexors",
               ["Core"], "beginner", "Drive knees high, swing arms", "Marching"),
            ex("Twist Jump", 3, 10, 10, "Twist hips mid-air", "Bodyweight", "Core", "Obliques",
               ["Calves", "Quadriceps"], "beginner", "Jump and twist hips left and right", "Standing Twist"),
            ex("Freeze Dance Squat", 3, 8, 15, "Squat when music stops", "Bodyweight", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Dance freely, squat and hold on cue", "Bodyweight Squat"),
        ]),
    ]


def _preteen_fitness():
    return [
        workout("Preteen Fitness Session", "bodyweight", 25, [
            BODYWEIGHT_SQUAT(3, 12, 20, "Full depth"),
            PUSHUP(3, 8, 20, "Knees or full"),
            JUMPING_JACK(3, 20, 15, "Steady pace"),
            MOUNTAIN_CLIMBER(3, 12, 20, "Moderate pace"),
            ex("Lunge Walk", 3, 8, 20, "Alternating legs", "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Hamstrings"], "beginner", "Long stride, upright torso", "Reverse Lunge"),
            PLANK(3, 1, 15, "Hold 15-20 seconds"),
        ]),
    ]


###############################################################################
# ANTI-AGING (12 programs) - Longevity, functional movement, joint health
###############################################################################

def _time_machine_body():
    return [
        workout("Time Machine Full Body", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60, "Moderate, control tempo"),
            DB_ROW(3, 10, 60, "Moderate weight"),
            PUSHUP(3, 12, 45, "Full range of motion"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze glutes 2 sec"),
            DEAD_BUG(3, 10, 30, "Slow and controlled"),
            BIRD_DOG(3, 10, 30, "Per side"),
        ]),
        workout("Time Machine Mobility", "flexibility", 30, [
            WORLD_GREATEST_STRETCH(),
            HIP_90_90(),
            CAT_COW(),
            DOWNWARD_DOG(),
            HIP_FLEXOR_STRETCH(),
            WALL_ANGEL(),
        ]),
    ]


def _look_10_years_younger():
    return [
        workout("Youth Restore Strength", "strength", 35, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Deep, controlled"),
            PUSHUP(3, 12, 45, "Full ROM"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Light to moderate"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
            STEP_UP(3, 10, 45, "Per leg, no weight"),
        ]),
        workout("Youth Restore Flexibility", "flexibility", 30, [
            CAT_COW(),
            DOWNWARD_DOG(),
            PIGEON_POSE(),
            SEATED_FORWARD_FOLD(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
        ]),
    ]


def _aging_in_reverse():
    return [
        workout("Reverse Aging Circuit", "strength", 40, [
            GOBLET_SQUAT(3, 12, 45, "Moderate"),
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            DEAD_BUG(3, 10, 30, "Controlled"),
            FARMER_WALK(3, 1, 45, "30 seconds, moderate weight"),
        ]),
    ]


def _fountain_of_youth():
    return [
        workout("Fountain of Youth Flow", "strength", 35, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Deep, full ROM"),
            PUSHUP(3, 12, 45, "Controlled tempo"),
            INVERTED_ROW(3, 10, 45, "Body straight"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze at top"),
            BIRD_DOG(3, 10, 30, "Per side, slow"),
            WALL_SIT(3, 1, 30, "Hold 30 seconds"),
        ]),
        workout("Fountain of Youth Stretch", "flexibility", 30, [
            DOWNWARD_DOG(),
            WARRIOR_I(),
            WARRIOR_II(),
            TRIANGLE(),
            CHILDS_POSE(),
            SAVASANA(),
        ]),
    ]


def _age_is_just_a_number():
    return [
        workout("Age-Defying Strength", "strength", 40, [
            DB_BENCH(3, 10, 60, "Moderate"),
            LAT_PULLDOWN(3, 10, 60, "Moderate"),
            LEG_PRESS(3, 12, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Light to moderate"),
            CABLE_ROW(3, 12, 60, "Moderate, squeeze back"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
        ]),
    ]


def _move_like_youre_20():
    return [
        workout("Move Like 20 - Mobility", "flexibility", 35, [
            WORLD_GREATEST_STRETCH(),
            HIP_90_90(),
            THORACIC_EXTENSION(),
            DOWNWARD_DOG(),
            PIGEON_POSE(),
            LOW_LUNGE(),
        ]),
        workout("Move Like 20 - Strength", "strength", 35, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Full depth"),
            PUSHUP(3, 12, 45, "Full ROM"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            SUPERMAN(3, 12, 30, "Squeeze at top"),
            SIDE_PLANK(2, 1, 30, "Hold 20 seconds each side"),
        ]),
    ]


def _defy_gravity():
    return [
        workout("Defy Gravity Workout", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Light to moderate"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze at top"),
            DEAD_BUG(3, 10, 30, "Controlled"),
            CALF_RAISE(3, 15, 30, "Bodyweight, slow"),
        ]),
    ]


def _glow_up_at_any_age():
    return [
        workout("Glow Up Full Body", "strength", 35, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Deep and controlled"),
            PUSHUP(3, 12, 45, "Full ROM"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_LATERAL_RAISE(3, 12, 30, "Light, strict"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze top"),
        ]),
    ]


def _second_wind():
    return [
        workout("Second Wind Cardio-Strength", "strength", 40, [
            GOBLET_SQUAT(3, 12, 45, "Moderate"),
            PUSHUP(3, 12, 45, "Full ROM"),
            DB_ROW(3, 10, 60, "Moderate"),
            STEP_UP(3, 10, 45, "Per leg"),
            MOUNTAIN_CLIMBER(3, 20, 20, "Moderate pace"),
            BIRD_DOG(3, 10, 30, "Per side"),
        ]),
    ]


def _better_with_age():
    return [
        workout("Better With Age A", "strength", 35, [
            DB_BENCH(3, 10, 60, "Moderate"),
            LAT_PULLDOWN(3, 10, 60, "Moderate"),
            GOBLET_SQUAT(3, 12, 45, "Moderate"),
            FACE_PULL(3, 15, 30, "Light, shoulder health"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
        ]),
        workout("Better With Age B", "flexibility", 30, [
            CAT_COW(),
            DOWNWARD_DOG(),
            WARRIOR_I(),
            PIGEON_POSE(),
            SEATED_FORWARD_FOLD(),
            SAVASANA(),
        ]),
    ]


def _reverse_the_clock():
    return [
        workout("Reverse the Clock", "strength", 40, [
            BARBELL_SQUAT(3, 10, 90, "Moderate, 60-70% 1RM"),
            BARBELL_BENCH(3, 10, 90, "Moderate"),
            BARBELL_ROW(3, 10, 90, "Moderate"),
            RDL(3, 10, 60, "Moderate, stretch hamstrings"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


def _forever_young():
    return [
        workout("Forever Young Full Body", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_RDL(3, 10, 60, "Moderate, feel stretch"),
            DB_OHP(3, 10, 60, "Light to moderate"),
            DEAD_BUG(3, 10, 30, "Controlled"),
        ]),
        workout("Forever Young Mobility", "flexibility", 30, [
            WORLD_GREATEST_STRETCH(),
            HIP_90_90(),
            THORACIC_EXTENSION(),
            CAT_COW(),
            PIGEON_POSE(),
            LEGS_UP_WALL(),
        ]),
    ]


###############################################################################
# LIFE EVENTS (16 programs) - Wedding, parenthood, vacation
###############################################################################

def _pre_wedding_fitness():
    return [
        workout("Wedding Sculpt Upper", "strength", 40, [
            DB_OHP(3, 12, 60, "Moderate, sculpt shoulders"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            DB_BENCH(3, 10, 60, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Tone arms"),
            DB_CURL(3, 12, 45, "Moderate"),
            FACE_PULL(3, 15, 30, "Posture"),
        ]),
        workout("Wedding Sculpt Lower", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            DB_RDL(3, 12, 60, "Feel stretch"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze top"),
            CALF_RAISE(3, 15, 30, "Controlled"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


def _wedding_day_ready():
    return [
        workout("Wedding Day Arms & Shoulders", "strength", 35, [
            DB_OHP(3, 12, 60, "Sculpt those shoulders"),
            ARNOLD_PRESS(3, 10, 60, "Full rotation"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, high reps"),
            DB_CURL(3, 12, 45, "Tone biceps"),
            TRICEP_PUSHDOWN(3, 12, 45, "Tone triceps"),
            BAND_PULL_APART(3, 15, 20, "Posture"),
        ]),
        workout("Wedding Day Core & Glutes", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            HIP_THRUST(3, 12, 60, "Heavy, squeeze"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            CRUNCHES(3, 20, 30, "Controlled"),
            BICYCLE_CRUNCH(3, 20, 30, "Per side"),
            PLANK(3, 1, 30, "Hold 45-60 seconds"),
        ]),
    ]


def _last_minute_wedding_shred():
    return [
        workout("Wedding Shred HIIT", "hiit", 30, [
            JUMP_SQUAT(4, 12, 20, "Explosive"),
            PUSHUP(4, 15, 20, "Fast tempo"),
            MOUNTAIN_CLIMBER(4, 20, 20, "Sprint pace"),
            BURPEE(4, 8, 30, "Full effort"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
            PLANK(3, 1, 20, "Hold 30 seconds"),
        ]),
    ]


def _engaged_and_fit():
    return [
        workout("Engaged & Fit Full Body", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Light to moderate"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
        ]),
    ]


def _honeymoon_body():
    return [
        workout("Honeymoon Upper", "strength", 35, [
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            DB_CURL(3, 12, 45, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
        ]),
        workout("Honeymoon Lower & Core", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            DB_RDL(3, 12, 60, "Feel stretch"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze"),
            RUSSIAN_TWIST(3, 20, 30, "Per side"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


def _pre_parent_fitness():
    return [
        workout("Pre-Parent Functional Strength", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Build leg strength"),
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Build back strength for carrying"),
            FARMER_WALK(3, 1, 60, "30 seconds, build grip and core"),
            DEAD_BUG(3, 10, 30, "Core stability"),
            GLUTE_BRIDGE(3, 15, 30, "Hip strength"),
        ]),
    ]


def _couples_pre_baby():
    return [
        workout("Couples Pre-Baby Workout", "strength", 35, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Full depth"),
            PUSHUP(3, 12, 45, "Full ROM"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            PLANK(3, 1, 30, "Hold 30 seconds"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze"),
        ]),
    ]


def _new_dad_fitness():
    return [
        workout("New Dad Quick Strength", "strength", 25, [
            GOBLET_SQUAT(3, 12, 45, "Moderate, build for carrying baby"),
            DB_ROW(3, 10, 45, "Build back for lifting"),
            PUSHUP(3, 12, 30, "Quick tempo"),
            FARMER_WALK(3, 1, 45, "30 seconds, grip and core"),
            PLANK(3, 1, 20, "Hold 30 seconds"),
        ]),
    ]


def _new_mom_post_baby():
    return [
        workout("New Mom Recovery", "strength", 25, [
            GLUTE_BRIDGE(3, 12, 30, "Rebuild pelvic floor connection"),
            DEAD_BUG(3, 8, 30, "Gentle core reactivation"),
            BIRD_DOG(3, 8, 30, "Per side, slow"),
            WALL_SIT(2, 1, 30, "Hold 20 seconds"),
            ex("Wall Push-Up", 3, 10, 20, "Gentle start", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean into wall, press back", "Countertop Push-Up"),
            ex("Pelvic Tilt", 3, 10, 15, "Engage deep core", "Bodyweight", "Core", "Transverse Abdominis",
               ["Pelvic Floor"], "beginner", "Lie on back, flatten lower back to floor", "Dead Bug"),
        ]),
    ]


def _first_year_parent():
    return [
        workout("First Year Parent Quick Hit", "strength", 25, [
            GOBLET_SQUAT(3, 12, 45, "Moderate"),
            PUSHUP(3, 12, 30, "Full ROM"),
            DB_ROW(3, 10, 45, "Moderate"),
            GLUTE_BRIDGE(3, 15, 20, "Quick squeeze"),
            PLANK(3, 1, 20, "Hold 30 seconds"),
        ]),
    ]


def _baby_and_me_workout():
    return [
        workout("Baby & Me Session", "strength", 20, [
            BODYWEIGHT_SQUAT(3, 15, 20, "Hold baby close to chest"),
            GLUTE_BRIDGE(3, 15, 20, "Baby sits on hips"),
            ex("Baby Overhead Press", 3, 10, 20, "Hold baby securely", "Bodyweight", "Shoulders", "Deltoids",
               ["Triceps", "Core"], "beginner", "Press baby gently overhead, smile", "Seated Arm Raise"),
            BIRD_DOG(3, 8, 20, "Baby on mat beside you"),
            ex("Baby Bench Press", 3, 10, 20, "Lie on back, press baby up", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Press baby up from chest, interact", "Floor Press"),
        ]),
    ]


def _sleep_deprived_parent():
    return [
        workout("Sleep-Deprived Quick Burn", "strength", 15, [
            BODYWEIGHT_SQUAT(3, 12, 20, "Wake up those legs"),
            PUSHUP(3, 10, 20, "Get blood flowing"),
            GLUTE_BRIDGE(3, 12, 15, "Quick squeeze"),
            PLANK(2, 1, 15, "Hold 20 seconds"),
            MOUNTAIN_CLIMBER(2, 15, 15, "Light pace to energize"),
        ]),
    ]


def _grandparent_fitness():
    return [
        workout("Grandparent Fitness Session", "strength", 25, [
            ex("Chair Squat", 3, 10, 20, "Sit and stand", "Chair", "Legs", "Quadriceps",
               ["Glutes"], "beginner", "Lower to chair, stand up", "Wall Sit"),
            ex("Wall Push-Up", 3, 10, 15, "Against wall", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean in, press back", "Countertop Push-Up"),
            ex("Standing Calf Raise", 3, 12, 15, "Hold chair", "Bodyweight", "Legs", "Calves",
               ["Tibialis Anterior"], "beginner", "Rise onto toes", "Seated Calf Raise"),
            GLUTE_BRIDGE(3, 12, 20, "Gentle squeeze"),
            ex("Seated Row with Band", 3, 10, 15, "Light band", "Resistance Band", "Back", "Latissimus Dorsi",
               ["Rhomboids", "Biceps"], "beginner", "Pull band to chest", "Seated Arm Pull"),
            ex("Tandem Walk", 3, 10, 10, "Heel to toe for balance", "Bodyweight", "Legs", "Calves",
               ["Core", "Hip Stabilizers"], "beginner", "Walk heel to toe in a line", "Side Step"),
        ]),
    ]


def _beach_vacation_ready():
    return [
        workout("Beach Body Upper", "strength", 40, [
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            DB_CURL(3, 12, 45, "Pump"),
            TRICEP_PUSHDOWN(3, 12, 45, "Pump"),
        ]),
        workout("Beach Body Lower & Core", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            DB_RDL(3, 12, 60, "Feel the stretch"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze"),
            CRUNCHES(3, 20, 30, "Controlled"),
            PLANK(3, 1, 30, "Hold 45-60 seconds"),
        ]),
    ]


def _reunion_shred():
    return [
        workout("Reunion Shred HIIT", "hiit", 35, [
            JUMP_SQUAT(4, 12, 20, "Explosive"),
            PUSHUP(4, 15, 20, "Fast tempo"),
            MOUNTAIN_CLIMBER(4, 20, 20, "Sprint pace"),
            DB_ROW(3, 10, 45, "Moderate"),
            BURPEE(3, 8, 30, "Full effort"),
            PLANK(3, 1, 20, "Hold 30-45 seconds"),
        ]),
    ]


def _summer_body_countdown():
    return [
        workout("Summer Body Push", "strength", 40, [
            DB_BENCH(4, 10, 60, "Moderate-heavy"),
            DB_OHP(3, 10, 60, "Moderate"),
            DB_INCLINE_PRESS(3, 12, 60, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
        workout("Summer Body Pull & Legs", "strength", 40, [
            LAT_PULLDOWN(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            GOBLET_SQUAT(3, 12, 60, "Moderate"),
            DB_RDL(3, 12, 60, "Moderate"),
            DB_CURL(3, 12, 45, "Moderate"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze"),
        ]),
    ]


###############################################################################
# MOTIVATIONAL (12 programs) - Tough-love themed, real workouts
###############################################################################

def _get_to_gym_upper():
    return [
        workout("Get to the Gym - Upper", "strength", 40, [
            BARBELL_BENCH(4, 8, 120, "Moderate-heavy"),
            BARBELL_ROW(4, 8, 120, "Match bench effort"),
            BARBELL_OHP(3, 8, 90, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            BARBELL_CURL(3, 10, 60, "Moderate"),
            SKULL_CRUSHER(3, 10, 60, "Moderate"),
        ]),
    ]


def _get_to_gym_lower():
    return [
        workout("Get to the Gym - Lower", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120, "Moderate-heavy"),
            RDL(3, 10, 90, "Moderate, stretch hamstrings"),
            LEG_PRESS(3, 10, 90, "Heavy"),
            LEG_CURL(3, 12, 60, "Moderate"),
            LEG_EXT(3, 12, 60, "Moderate"),
            CALF_RAISE(4, 15, 30, "Full ROM"),
        ]),
    ]


def _get_to_gym_cardio():
    return [
        workout("Get to the Gym - Cardio", "hiit", 35, [
            JUMP_SQUAT(4, 12, 20, "Explosive"),
            BURPEE(4, 10, 25, "Full effort"),
            MOUNTAIN_CLIMBER(4, 20, 15, "Sprint pace"),
            HIGH_KNEES(4, 30, 15, "30 seconds all out"),
            JUMPING_JACK(4, 30, 15, "30 seconds"),
            BATTLE_ROPES(3, 1, 30, "30 seconds all out"),
        ]),
    ]


def _get_to_gym_full_body():
    return [
        workout("Get to the Gym - Full Body", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120, "Moderate-heavy"),
            BARBELL_BENCH(4, 8, 120, "Moderate-heavy"),
            BARBELL_ROW(4, 8, 90, "Moderate"),
            BARBELL_OHP(3, 8, 90, "Moderate"),
            DEADLIFT(1, 5, 180, "Heavy top set"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


def _stop_making_excuses():
    return [
        workout("Stop Making Excuses", "strength", 40, [
            GOBLET_SQUAT(4, 12, 60, "Moderate"),
            DB_BENCH(4, 10, 60, "Moderate"),
            DB_ROW(4, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Moderate"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


def _just_show_up():
    return [
        workout("Just Show Up", "strength", 30, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Just do them"),
            PUSHUP(3, 12, 30, "Full ROM"),
            DB_ROW(3, 10, 45, "Moderate"),
            GLUTE_BRIDGE(3, 15, 20, "Squeeze"),
            PLANK(3, 1, 20, "Hold 30 seconds"),
        ]),
    ]


def _no_more_bs():
    return [
        workout("No More BS Full Body", "strength", 40, [
            BARBELL_SQUAT(3, 8, 120, "Moderate"),
            BARBELL_BENCH(3, 8, 120, "Moderate"),
            BARBELL_ROW(3, 8, 90, "Moderate"),
            RDL(3, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Moderate"),
            DEAD_BUG(3, 10, 30, "Core work"),
        ]),
    ]


def _shut_up_and_lift():
    return [
        workout("Shut Up and Lift - Push", "strength", 45, [
            BARBELL_BENCH(4, 6, 150, "Heavy"),
            INCLINE_BENCH(3, 8, 90, "Moderate-heavy"),
            BARBELL_OHP(3, 8, 90, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            CLOSE_GRIP_BENCH(3, 8, 90, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
        ]),
        workout("Shut Up and Lift - Pull", "strength", 45, [
            DEADLIFT(1, 5, 240, "Heavy top set"),
            BARBELL_ROW(4, 6, 120, "Heavy"),
            PULLUP(3, 8, 90, "Add weight if needed"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
            BARBELL_CURL(3, 10, 60, "Moderate"),
            HAMMER_CURL(3, 10, 45, "Moderate"),
        ]),
        workout("Shut Up and Lift - Legs", "strength", 45, [
            BARBELL_SQUAT(4, 6, 150, "Heavy"),
            RDL(3, 8, 90, "Moderate-heavy"),
            LEG_PRESS(3, 10, 90, "Heavy"),
            LEG_CURL(3, 12, 60, "Moderate"),
            CALF_RAISE(4, 15, 30, "Full ROM"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


def _zero_excuses_zone():
    return [
        workout("Zero Excuses Full Body", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60, "No excuses"),
            DB_BENCH(3, 10, 60, "Just do it"),
            DB_ROW(3, 10, 60, "Pull hard"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            PUSHUP(3, 15, 30, "Drop and give me 15"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


def _get_off_the_couch():
    return [
        workout("Get Off the Couch", "strength", 30, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Start moving"),
            PUSHUP(3, 10, 30, "From knees if needed"),
            GLUTE_BRIDGE(3, 15, 20, "Wake up those glutes"),
            HIGH_KNEES(3, 20, 15, "Get the heart rate up"),
            PLANK(3, 1, 20, "Hold 20-30 seconds"),
            MOUNTAIN_CLIMBER(3, 15, 20, "Keep going"),
        ]),
    ]


def _youve_got_this():
    return [
        workout("You've Got This", "strength", 35, [
            GOBLET_SQUAT(3, 12, 45, "Moderate"),
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_ROW(3, 10, 60, "Moderate"),
            DB_OHP(3, 10, 60, "Moderate"),
            GLUTE_BRIDGE(3, 15, 30, "Squeeze"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
        ]),
    ]


def _make_yourself_proud():
    return [
        workout("Make Yourself Proud", "strength", 40, [
            BARBELL_SQUAT(3, 8, 120, "Moderate"),
            BARBELL_BENCH(3, 8, 120, "Moderate"),
            BARBELL_ROW(3, 8, 90, "Moderate"),
            DB_OHP(3, 10, 60, "Moderate"),
            DB_LUNGE(3, 10, 60, "Per leg"),
            DEAD_BUG(3, 10, 30, "Core work"),
            PLANK(3, 1, 30, "Finish strong, hold 45 seconds"),
        ]),
    ]


###############################################################################
# OCCUPATION (4 programs) - Address occupation-specific issues
###############################################################################

def _construction_worker_recovery():
    return [
        workout("Construction Recovery Session", "flexibility", 25, [
            FOAM_ROLL_BACK(),
            FOAM_ROLL_QUAD(),
            HIP_FLEXOR_STRETCH(),
            PIRIFOMIS_STRETCH(),
            CAT_COW(),
            CHILDS_POSE(),
            ex("Forearm Stretch", 2, 1, 10, "Hold 20 seconds each", "Bodyweight", "Arms", "Forearms",
               ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back gently", "Wrist Circle"),
        ]),
    ]


def _teacher_energy_boost():
    return [
        workout("Teacher Energy Boost", "strength", 25, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Get blood flowing"),
            PUSHUP(3, 12, 30, "Wake up upper body"),
            HIGH_KNEES(3, 20, 15, "Boost energy"),
            MOUNTAIN_CLIMBER(3, 15, 20, "Core and cardio"),
            WALL_ANGEL(),
            ex("Standing Desk Stretch", 2, 1, 10, "Hold 20 seconds", "Bodyweight", "Back", "Erector Spinae",
               ["Shoulders"], "beginner", "Clasp hands overhead, lean side to side", "Seated Side Stretch"),
        ]),
    ]


def _chef_body_maintenance():
    return [
        workout("Chef Body Maintenance", "flexibility", 25, [
            FOAM_ROLL_BACK(),
            ex("Calf Stretch", 2, 1, 10, "Hold 30 seconds each", "Bodyweight", "Legs", "Calves",
               ["Soleus"], "beginner", "Step back, press heel down, relief for standing", "Wall Calf Stretch"),
            HIP_FLEXOR_STRETCH(),
            WALL_ANGEL(),
            CAT_COW(),
            ex("Wrist Stretch", 2, 1, 10, "Hold 20 seconds each", "Bodyweight", "Arms", "Forearms",
               ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back", "Wrist Circle"),
            GLUTE_BRIDGE(3, 12, 20, "Counteract standing all day"),
        ]),
    ]


def _musician_body_care():
    return [
        workout("Musician Body Care", "flexibility", 20, [
            WRIST_CIRCLES(),
            ex("Finger Stretch", 2, 10, 5, "Spread and close", "Bodyweight", "Arms", "Forearms",
               ["Fingers"], "beginner", "Spread fingers wide, hold, make fist", "Finger Squeeze"),
            CHIN_TUCK(),
            WALL_ANGEL(),
            THORACIC_EXTENSION(),
            ex("Neck Stretch", 2, 1, 10, "Hold 20 seconds each side", "Bodyweight", "Neck", "Trapezius",
               ["Scalenes"], "beginner", "Ear to shoulder, gentle stretch", "Neck Roll"),
            ex("Shoulder Roll", 3, 10, 5, "Forward and backward", "Bodyweight", "Shoulders", "Trapezius",
               ["Deltoids"], "beginner", "Slow controlled circles, release tension", "Arm Circle"),
        ]),
    ]


###############################################################################
# SEDENTARY (2 programs) - Very beginner-friendly
###############################################################################

def _beginners_journey():
    return [
        workout("Beginner's Journey A", "strength", 20, [
            BODYWEIGHT_SQUAT(2, 10, 30, "Gentle start, use chair if needed"),
            ex("Wall Push-Up", 2, 10, 20, "Against wall", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean into wall, press back", "Countertop Push-Up"),
            GLUTE_BRIDGE(2, 10, 20, "Gentle squeeze"),
            BIRD_DOG(2, 8, 20, "Per side, slow"),
            ex("Standing March", 2, 1, 15, "March for 1 minute", "Bodyweight", "Full Body", "Hip Flexors",
               ["Core", "Calves"], "beginner", "Lift knees gently, swing arms", "Seated Marching"),
        ]),
        workout("Beginner's Journey B", "flexibility", 15, [
            CAT_COW(),
            ex("Neck Stretch", 2, 1, 5, "Hold 15 seconds each side", "Bodyweight", "Neck", "Trapezius",
               ["Scalenes"], "beginner", "Ear to shoulder, gentle", "Neck Roll"),
            ex("Chest Opener", 2, 1, 5, "Hold 15 seconds", "Bodyweight", "Chest", "Pectoralis Major",
               ["Anterior Deltoid"], "beginner", "Clasp hands behind, open chest", "Doorway Stretch"),
            ex("Seated Hamstring Stretch", 2, 1, 5, "Hold 20 seconds each", "Chair", "Legs", "Hamstrings",
               ["Calves"], "beginner", "Extend leg, lean forward gently", "Standing Hamstring Stretch"),
            ex("Hip Circle", 2, 8, 5, "Both directions", "Bodyweight", "Hips", "Hip Flexors",
               ["Glutes"], "beginner", "Hands on hips, slow circles", "Standing Hip Stretch"),
        ]),
    ]


def _couch_potato_recovery():
    return [
        workout("Couch Potato Recovery", "strength", 15, [
            ex("Standing March", 3, 1, 15, "March for 1 minute", "Bodyweight", "Full Body", "Hip Flexors",
               ["Core", "Calves"], "beginner", "Lift knees gently, swing arms", "Seated Marching"),
            BODYWEIGHT_SQUAT(2, 8, 30, "Use chair if needed"),
            ex("Wall Push-Up", 2, 8, 20, "Against wall", "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps"], "beginner", "Lean in and push back", "Countertop Push-Up"),
            GLUTE_BRIDGE(2, 10, 20, "Gentle squeeze"),
            ex("Shoulder Roll", 3, 10, 5, "Release tension", "Bodyweight", "Shoulders", "Trapezius",
               ["Deltoids"], "beginner", "Slow circles forward and back", "Arm Circle"),
        ]),
    ]


###############################################################################
# BATCH_WORKOUTS - maps program name to callable returning list of workouts
###############################################################################

BATCH_WORKOUTS = {
    # --- Seniors (14) ---
    "Senior Fitness Fundamentals": _senior_fitness_fundamentals,
    "Chair Exercises": _chair_exercises,
    "Balance & Fall Prevention": _balance_fall_prevention,
    "Senior Flexibility": _senior_flexibility,
    "Arthritis-Friendly Movement": _arthritis_friendly_movement,
    "Senior Tai Chi": _senior_tai_chi,
    "Senior Aqua Fitness": _senior_aqua_fitness,
    "Active Aging": _active_aging,
    "Senior Yoga": _senior_yoga,
    "Obese Senior Safe Start": _obese_senior_safe_start,
    "Obese Senior Strength": _obese_senior_strength,
    "Obese Senior Mobility": _obese_senior_mobility,
    "Senior Weight Loss": _senior_weight_loss,
    "Senior Multicomponent Training": _senior_multicomponent_training,

    # --- Kids & Youth (8) ---
    "Kids Fitness Fun": _kids_fitness_fun,
    "Teen Strength Basics": _teen_strength_basics,
    "Youth Sports Prep": _youth_sports_prep,
    "Teen HIIT": _teen_hiit,
    "Kids Calisthenics": _kids_calisthenics,
    "Teen Athlete Development": _teen_athlete_development,
    "Kids Dance Fitness": _kids_dance_fitness,
    "Preteen Fitness": _preteen_fitness,

    # --- Anti-Aging (12) ---
    "Time Machine Body": _time_machine_body,
    "Look 10 Years Younger": _look_10_years_younger,
    "Aging in Reverse": _aging_in_reverse,
    "Fountain of Youth": _fountain_of_youth,
    "Age Is Just a Number": _age_is_just_a_number,
    "Move Like You're 20": _move_like_youre_20,
    "Defy Gravity": _defy_gravity,
    "Glow Up at Any Age": _glow_up_at_any_age,
    "Second Wind": _second_wind,
    "Better With Age": _better_with_age,
    "Reverse the Clock": _reverse_the_clock,
    "Forever Young": _forever_young,

    # --- Life Events (16) ---
    "Pre-Wedding Fitness": _pre_wedding_fitness,
    "Wedding Day Ready": _wedding_day_ready,
    "Last-Minute Wedding Shred": _last_minute_wedding_shred,
    "Engaged & Fit": _engaged_and_fit,
    "Honeymoon Body": _honeymoon_body,
    "Pre-Parent Fitness": _pre_parent_fitness,
    "Couples Pre-Baby": _couples_pre_baby,
    "New Dad Fitness": _new_dad_fitness,
    "New Mom Post-Baby": _new_mom_post_baby,
    "First Year Parent": _first_year_parent,
    "Baby & Me Workout": _baby_and_me_workout,
    "Sleep-Deprived Parent": _sleep_deprived_parent,
    "Grandparent Fitness": _grandparent_fitness,
    "Beach Vacation Ready": _beach_vacation_ready,
    "Reunion Shred": _reunion_shred,
    "Summer Body Countdown": _summer_body_countdown,

    # --- Motivational (12) ---
    "Get to the F***in Gym - Upper": _get_to_gym_upper,
    "Get to the F***in Gym - Lower": _get_to_gym_lower,
    "Get to the F***in Gym - Cardio": _get_to_gym_cardio,
    "Get to the F***in Gym - Full Body": _get_to_gym_full_body,
    "Stop Making Excuses Already": _stop_making_excuses,
    "Just Show Up": _just_show_up,
    "No More BS": _no_more_bs,
    "Shut Up and Lift": _shut_up_and_lift,
    "Zero Excuses Zone": _zero_excuses_zone,
    "Get Off the Couch NOW": _get_off_the_couch,
    "You've Got This": _youve_got_this,
    "Make Yourself Proud": _make_yourself_proud,

    # --- Occupation (4) ---
    "Construction Worker Recovery": _construction_worker_recovery,
    "Teacher Energy Boost": _teacher_energy_boost,
    "Chef Body Maintenance": _chef_body_maintenance,
    "Musician Body Care": _musician_body_care,

    # --- Sedentary (2) ---
    "Beginner's Journey": _beginners_journey,
    "Couch Potato Recovery": _couch_potato_recovery,
}
