#!/usr/bin/env python3
"""
Batch 6 - Lifestyle Programs (95 total)
========================================
Categories: Travel (14), Night Shift (14), Pet-Friendly (14),
Ninja/Apartment (12), Packed Gym (12), Post-Meal (10), Cruise (11), Gamer (8)
"""

from exercise_lib import *


###############################################################################
# TRAVEL (14 programs) - Hotel gym, room bodyweight, airport
###############################################################################

def _hotel_gym_upper():
    return [workout("Hotel Gym Upper", "strength", 40, [
        DB_BENCH(4, 10, 60, "Hotel dumbbells, moderate"),
        DB_OHP(3, 12, 60, "Seated or standing"),
        DB_ROW(4, 10, 60, "One arm, brace on bench"),
        DB_LATERAL_RAISE(3, 15, 30, "Light, strict form"),
        DB_CURL(3, 12, 45, "Alternate arms"),
        TRICEP_PUSHDOWN(3, 12, 45, "Cable if available, else dumbbell kickback"),
    ])]

def _hotel_gym_lower():
    return [workout("Hotel Gym Lower", "strength", 40, [
        GOBLET_SQUAT(4, 12, 60, "Heavy hotel dumbbell"),
        DB_RDL(3, 12, 60, "Moderate dumbbells"),
        DB_LUNGE(3, 10, 60, "Walking or stationary, per leg"),
        LEG_PRESS(3, 12, 90, "If available, otherwise Bulgarian split squats"),
        CALF_RAISE(4, 15, 30, "Dumbbell in hand, single leg on step"),
        GLUTE_BRIDGE(3, 15, 30, "Dumbbell on hips if possible"),
    ])]

def _hotel_gym_full_body():
    return [workout("Hotel Gym Full Body", "strength", 45, [
        GOBLET_SQUAT(4, 12, 60, "Heaviest dumbbell available"),
        DB_BENCH(3, 10, 60, "Moderate dumbbells"),
        DB_ROW(3, 10, 60, "Each arm"),
        DB_OHP(3, 10, 60, "Standing preferred"),
        DB_RDL(3, 12, 60, "Moderate weight"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
    ])]

def _hotel_cardio_crusher():
    return [workout("Hotel Cardio Crusher", "cardio", 30, [
        cardio_ex("Treadmill Intervals", 300, "30s sprint / 60s jog, repeat 5-6 times", "Treadmill", "intermediate"),
        cardio_ex("Rowing Machine Intervals", 300, "1 min hard / 1 min easy, repeat 5 rounds", "Rowing Machine", "intermediate"),
        MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds fast"),
        BODYWEIGHT_SQUAT(3, 20, 30, "Fast tempo"),
        PUSHUP(3, 15, 30, "Moderate pace"),
        PLANK(2, 1, 30, "Hold 30 seconds"),
    ])]

def _hotel_dumbbell_monster():
    return [workout("Hotel Dumbbell Monster", "strength", 45, [
        DB_BENCH(4, 10, 60, "Heavy dumbbells, controlled tempo"),
        DB_ROW(4, 10, 60, "Heavy, pull to hip"),
        GOBLET_SQUAT(4, 12, 60, "Slow tempo, pause at bottom"),
        ARNOLD_PRESS(3, 10, 60, "Full rotation"),
        DB_RDL(3, 12, 60, "Slow eccentric 3 seconds"),
        HAMMER_CURL(3, 12, 45, "Superset with overhead tricep extension"),
        ex("Dumbbell Overhead Tricep Extension", 3, 12, 45, "One heavy dumbbell",
           "Dumbbell", "Arms", "Triceps Long Head", ["Triceps"], "beginner",
           "Full stretch behind head, press up", "Bench Dip"),
    ])]

def _airport_layover():
    return [workout("Airport Layover Workout", "flexibility", 20, [
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot on seat edge, lean forward gently", "Seated Forward Fold"),
        stretch("Standing Quad Stretch", 30, "Legs", "Quadriceps",
                "Hold ankle, pull heel to glute, stand tall", "Kneeling Quad Stretch"),
        stretch("Neck Side Stretch", 20, "Neck", "Trapezius",
                "Ear to shoulder, hold gently", "Chin Tuck"),
        WALL_ANGEL(),
        CHIN_TUCK(),
        stretch("Standing Chest Opener", 30, "Chest", "Pectoralis Major",
                "Clasp hands behind back, squeeze shoulder blades, lift chest",
                "Doorway Chest Stretch"),
        ex("Seated Leg Raise", 3, 15, 20, "Seated in chair", "Bodyweight", "Legs",
           "Quadriceps", ["Hip Flexors", "Core"], "beginner",
           "Straighten one leg at a time, hold 3 seconds", "Standing Knee Raise"),
        ex("Standing Calf Raise", 3, 20, 15, "Hold chair for balance", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Rise on balls of feet, slow negative", "Seated Calf Raise"),
    ])]

def _hotel_room_bodyweight():
    return [workout("Hotel Room Bodyweight", "strength", 30, [
        PUSHUP(4, 15, 45, "Chest to floor"),
        BODYWEIGHT_SQUAT(4, 20, 30, "Full depth, slow tempo"),
        ex("Inverted Row (Desk/Table)", 3, 10, 60, "Grip table edge, body under",
           "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"],
           "intermediate", "Straight body, pull chest to table", "Dumbbell Row"),
        GLUTE_BRIDGE(3, 20, 30, "Squeeze at top 2 seconds"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        DIAMOND_PUSHUP(3, 10, 45, "Hands close together"),
        REVERSE_LUNGE(3, 12, 45, "Per leg, bodyweight"),
    ])]

def _resistance_band_travel():
    return [workout("Resistance Band Travel", "strength", 35, [
        BAND_PULL_APART(3, 15, 20, "Light band, slow squeeze"),
        BANDED_SQUAT(3, 15, 30, "Band above knees, push out"),
        LATERAL_BAND_WALK(3, 15, 30, "Stay low, per direction"),
        ex("Band Chest Press", 3, 12, 45, "Anchor band behind, press forward",
           "Resistance Band", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"],
           "beginner", "Step forward for more tension, controlled press", "Push-Up"),
        ex("Band Row", 3, 12, 45, "Anchor band at chest height, pull to torso",
           "Resistance Band", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"],
           "beginner", "Squeeze shoulder blades, slow negative", "Inverted Row"),
        ex("Band Shoulder Press", 3, 12, 45, "Stand on band, press overhead",
           "Resistance Band", "Shoulders", "Deltoids", ["Triceps"],
           "beginner", "Full lockout, controlled descent", "Pike Push-Up"),
        ex("Band Bicep Curl", 3, 15, 30, "Stand on band, curl up",
           "Resistance Band", "Arms", "Biceps", ["Forearms"],
           "beginner", "Strict form, squeeze at top", "Dumbbell Curl"),
    ])]

def _jet_lag_recovery():
    return [workout("Jet Lag Recovery", "flexibility", 25, [
        CAT_COW(),
        CHILDS_POSE(),
        DOWNWARD_DOG(),
        stretch("Supine Spinal Twist", 45, "Back", "Obliques",
                "Knees to one side, arms out, look opposite", "Seated Twist"),
        HAPPY_BABY(),
        HIP_FLEXOR_STRETCH(),
        PIRIFOMIS_STRETCH(),
        LEGS_UP_WALL(),
    ])]

def _airplane_seat_stretches():
    return [workout("Airplane Seat Stretches", "flexibility", 15, [
        ANKLE_CIRCLES(),
        WRIST_CIRCLES(),
        stretch("Seated Neck Rolls", 20, "Neck", "Trapezius",
                "Slow circles, drop chin, ear to shoulder, back, other side", "Neck Side Stretch"),
        ex("Seated Knee Lift", 2, 10, 10, "Per leg", "Bodyweight", "Legs",
           "Hip Flexors", ["Core"], "beginner",
           "Lift knee toward chest, hold 3 seconds, alternate", "Standing Knee Raise"),
        stretch("Seated Figure Four", 30, "Hips", "Piriformis",
                "Ankle on opposite knee, lean forward gently", "Piriformis Stretch"),
        stretch("Seated Chest Opener", 20, "Chest", "Pectoralis Major",
                "Clasp hands behind headrest, open chest", "Standing Chest Opener"),
        CHIN_TUCK(),
        ex("Seated Calf Pump", 2, 20, 10, "Both feet", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Press toes down then pull up, pump to improve circulation", "Ankle Circles"),
    ])]

def _road_warrior_fitness():
    return [workout("Road Warrior Fitness", "strength", 35, [
        PUSHUP(4, 15, 45, "Standard push-ups, full ROM"),
        BODYWEIGHT_SQUAT(4, 20, 30, "Deep, controlled"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        DB_ROW(3, 12, 60, "If dumbbells available, else inverted row on desk"),
        GLUTE_BRIDGE(3, 20, 30, "Single leg if bodyweight too easy"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Moderate pace"),
        DEAD_BUG(3, 10, 20, "Per side, slow and controlled"),
    ])]

def _conference_break_workout():
    return [workout("Conference Break Workout", "strength", 15, [
        WALL_SIT(3, 1, 30, "Hold 30 seconds"),
        PUSHUP(3, 10, 30, "Against wall or floor"),
        BODYWEIGHT_SQUAT(3, 15, 20, "Quick tempo"),
        stretch("Standing Forward Fold", 30, "Legs", "Hamstrings",
                "Let head hang, bend knees slightly", "Ragdoll"),
        CHIN_TUCK(),
        ex("Standing Calf Raise", 3, 20, 15, "Bodyweight", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Rise on balls of feet, pause at top", "Seated Calf Raise"),
    ])]

def _red_eye_recovery():
    return [workout("Red Eye Recovery", "flexibility", 20, [
        CAT_COW(),
        CHILDS_POSE(),
        stretch("Neck Side Stretch", 20, "Neck", "Trapezius",
                "Ear to shoulder, gentle pressure", "Chin Tuck"),
        HIP_FLEXOR_STRETCH(),
        stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                "Foot elevated, hinge at hips", "Seated Forward Fold"),
        DOWNWARD_DOG(),
        SPHINX_POSE(),
        LEGS_UP_WALL(),
    ])]

def _weekend_warrior_travel():
    return [workout("Weekend Warrior Travel", "strength", 30, [
        PUSHUP(3, 15, 45, "Chest to floor"),
        BODYWEIGHT_SQUAT(3, 20, 30, "Full depth"),
        GLUTE_BRIDGE(3, 15, 30, "Single leg option"),
        PIKE_PUSHUP(3, 8, 60, "Hips high"),
        REVERSE_LUNGE(3, 10, 45, "Per leg"),
        PLANK(3, 1, 30, "Hold 40 seconds"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Controlled pace"),
    ])]


###############################################################################
# NIGHT SHIFT (14 programs) - Pre/post shift, recovery
###############################################################################

def _pre_night_shift_activation():
    return [workout("Pre-Night Shift Activation", "strength", 25, [
        JUMPING_JACK(3, 30, 15, "30 seconds, wake up the body"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Moderate tempo, pump blood"),
        PUSHUP(3, 12, 30, "Controlled pace"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Moderate speed"),
        GLUTE_BRIDGE(3, 15, 20, "Activate glutes"),
        PLANK(2, 1, 30, "Hold 30 seconds"),
    ])]

def _pre_12_hour_shift():
    return [workout("Pre-12 Hour Shift", "strength", 20, [
        HIGH_KNEES(3, 30, 15, "30 seconds to energize"),
        BODYWEIGHT_SQUAT(3, 15, 20, "Moderate pace"),
        PUSHUP(3, 10, 30, "Standard"),
        DEAD_BUG(3, 10, 20, "Per side"),
        GLUTE_BRIDGE(3, 15, 20, "Squeeze at top"),
        stretch("Standing Calf Stretch", 20, "Legs", "Calves",
                "Wall push, back leg straight", "Downward Dog"),
    ])]

def _shift_worker_morning():
    return [workout("Shift Worker Morning Routine", "strength", 20, [
        CAT_COW(),
        BODYWEIGHT_SQUAT(3, 15, 30, "Ease into movement"),
        PUSHUP(3, 10, 30, "Knees ok if tired"),
        BIRD_DOG(3, 10, 20, "Per side, wake up core"),
        GLUTE_BRIDGE(3, 15, 20, "Activate posterior chain"),
        stretch("Standing Hamstring Stretch", 20, "Legs", "Hamstrings",
                "Gentle, ease into it", "Seated Forward Fold"),
    ])]

def _pre_shift_energy_boost():
    return [workout("Pre-Shift Energy Boost", "cardio", 20, [
        JUMPING_JACK(3, 30, 15, "30 seconds, fast pace"),
        HIGH_KNEES(3, 20, 15, "20 seconds, drive up"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Fast hands"),
        BODYWEIGHT_SQUAT(3, 15, 20, "Explosive tempo"),
        PUSHUP(3, 10, 20, "Quick reps"),
        BURPEE(2, 8, 30, "Full extension at top"),
    ])]

def _post_night_shift_wind_down():
    return [workout("Post-Night Shift Wind Down", "flexibility", 25, [
        CAT_COW(),
        CHILDS_POSE(),
        stretch("Supine Spinal Twist", 45, "Back", "Obliques",
                "Knees to each side, hold and breathe", "Seated Twist"),
        HIP_FLEXOR_STRETCH(),
        stretch("Neck Side Stretch", 30, "Neck", "Trapezius",
                "Ear to shoulder, breathe deeply", "Chin Tuck"),
        PIRIFOMIS_STRETCH(),
        HAPPY_BABY(),
        LEGS_UP_WALL(),
    ])]

def _post_12_hour_recovery():
    return [workout("Post-12 Hour Recovery", "flexibility", 25, [
        FOAM_ROLL_BACK(),
        FOAM_ROLL_QUAD(),
        CAT_COW(),
        CHILDS_POSE(),
        HIP_FLEXOR_STRETCH(),
        stretch("Chest Doorway Stretch", 30, "Chest", "Pectoralis Major",
                "Arm on doorframe, lean through gently", "Standing Chest Opener"),
        PIRIFOMIS_STRETCH(),
        LEGS_UP_WALL(),
    ])]

def _day_sleep_prep():
    return [workout("Day Sleep Prep", "flexibility", 20, [
        stretch("Neck Rolls", 20, "Neck", "Trapezius",
                "Slow circles, release tension", "Neck Side Stretch"),
        CAT_COW(),
        CHILDS_POSE(),
        stretch("Supine Spinal Twist", 45, "Back", "Obliques",
                "Relax fully, breathe deep", "Seated Twist"),
        HAPPY_BABY(),
        LEGS_UP_WALL(),
    ])]

def _shift_worker_decompression():
    return [workout("Shift Worker Decompression", "flexibility", 25, [
        FOAM_ROLL_BACK(),
        CAT_COW(),
        CHILDS_POSE(),
        DOWNWARD_DOG(),
        PIGEON_POSE(),
        stretch("Seated Forward Fold", 45, "Legs", "Hamstrings",
                "Let gravity pull you forward, breathe", "Standing Forward Fold"),
        RECLINED_TWIST(),
        SAVASANA(),
    ])]

def _rotating_shift_fitness():
    return [workout("Rotating Shift Fitness", "strength", 30, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Moderate pace"),
        PUSHUP(3, 12, 30, "Controlled"),
        GLUTE_BRIDGE(3, 15, 30, "Squeeze at top"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
        REVERSE_LUNGE(3, 10, 30, "Per leg"),
        DEAD_BUG(3, 10, 20, "Per side"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Moderate speed"),
    ])]

def _healthcare_worker_fitness():
    return [workout("Healthcare Worker Fitness", "strength", 30, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Functional for patient lifting"),
        PUSHUP(3, 12, 30, "Core tight"),
        GLUTE_BRIDGE(3, 15, 30, "Protect lower back"),
        BIRD_DOG(3, 10, 20, "Per side, spinal stability"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
        stretch("Standing Calf Stretch", 20, "Legs", "Calves",
                "Wall push, relieve standing fatigue", "Downward Dog"),
        WALL_ANGEL(),
    ])]

def _first_responder_maintenance():
    return [workout("First Responder Maintenance", "strength", 35, [
        BODYWEIGHT_SQUAT(4, 15, 30, "Functional base"),
        PUSHUP(4, 15, 45, "Tactical standard"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        REVERSE_LUNGE(3, 10, 45, "Per leg"),
        GLUTE_BRIDGE(3, 15, 30, "Single-leg option"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Conditioning"),
        DEAD_BUG(3, 10, 20, "Core stability"),
    ])]

def _factory_shift_training():
    return [workout("Factory Shift Training", "strength", 25, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Functional leg strength"),
        PUSHUP(3, 10, 30, "Upper body maintenance"),
        GLUTE_BRIDGE(3, 15, 20, "Protect lower back"),
        BIRD_DOG(3, 10, 20, "Per side, spinal health"),
        stretch("Standing Quad Stretch", 20, "Legs", "Quadriceps",
                "Hold chair for balance", "Kneeling Quad Stretch"),
        WALL_ANGEL(),
    ])]

def _3_day_on_4_off():
    return [workout("3-Day On 4-Day Off Training", "strength", 40, [
        PUSHUP(4, 15, 45, "Full ROM"),
        BODYWEIGHT_SQUAT(4, 20, 30, "Full depth"),
        DB_ROW(3, 12, 60, "If available, else inverted row"),
        GLUTE_BRIDGE(3, 15, 30, "Loaded if possible"),
        PIKE_PUSHUP(3, 8, 60, "Shoulder work"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        REVERSE_LUNGE(3, 10, 45, "Per leg"),
    ])]

def _night_owl_gains():
    return [workout("Night Owl Gains", "strength", 35, [
        PUSHUP(4, 15, 45, "Slow tempo, 3 second negatives"),
        BODYWEIGHT_SQUAT(4, 20, 30, "Deep, controlled"),
        GLUTE_BRIDGE(3, 20, 30, "Pause at top"),
        DIAMOND_PUSHUP(3, 10, 45, "Tricep focus"),
        WALL_SIT(3, 1, 30, "Hold 40 seconds"),
        DEAD_BUG(3, 10, 20, "Controlled, per side"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
    ])]


###############################################################################
# PET-FRIENDLY (14 programs) - Small space, minimal jumping, bodyweight
###############################################################################

def _puppy_parent():
    return [workout("Puppy Parent Workout", "strength", 25, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Steady, no sudden movements"),
        PUSHUP(3, 12, 30, "Watch your puppy from the floor"),
        GLUTE_BRIDGE(3, 15, 30, "Great floor position for pet time"),
        DEAD_BUG(3, 10, 20, "Per side, careful of curious pup"),
        PLANK(3, 1, 30, "Hold 30 seconds, pup may join"),
        DONKEY_KICK(3, 12, 20, "Per leg, on all fours"),
    ])]

def _walk_the_dog_gains():
    return [workout("Walk the Dog Gains", "strength", 30, [
        ex("Walking Lunge", 3, 12, 45, "Per leg, during walk break",
           "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"],
           "beginner", "Long stride, upright torso, alternate legs", "Reverse Lunge"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Park bench squats"),
        PUSHUP(3, 12, 30, "Incline on park bench"),
        STEP_UP(3, 10, 45, "Per leg, park bench or curb"),
        PLANK(3, 1, 30, "Hold 30 seconds on grass"),
        ex("Standing Calf Raise", 3, 20, 15, "On curb edge", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Rise up, slow descent", "Seated Calf Raise"),
    ])]

def _cat_got_your_mat():
    return [workout("Cat Got Your Mat", "strength", 25, [
        PLANK(3, 1, 30, "Hold 30 seconds, cat may sit on you"),
        GLUTE_BRIDGE(3, 15, 30, "Slow, steady hip lifts"),
        DEAD_BUG(3, 10, 20, "Per side, entertain your cat"),
        DONKEY_KICK(3, 12, 20, "Per leg"),
        BIRD_DOG(3, 10, 20, "Per side, stay balanced"),
        CLAMSHELL(3, 15, 20, "Per side, floor work"),
    ])]

def _small_pet_safe_zone():
    return [workout("Small Pet Safe Zone", "strength", 20, [
        WALL_SIT(3, 1, 30, "Hold 30 seconds, pet safe below"),
        PUSHUP(3, 10, 30, "Watch for small pets underfoot"),
        ex("Standing Knee Raise", 3, 12, 20, "Per leg, controlled",
           "Bodyweight", "Core", "Hip Flexors", ["Core", "Quadriceps"],
           "beginner", "Lift knee to hip height, hold 2 seconds", "Dead Bug"),
        ex("Standing Calf Raise", 3, 20, 15, "Bodyweight", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Rise on toes, slow descent", "Seated Calf Raise"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
        CHIN_TUCK(),
    ])]

def _pet_parent_power_hour():
    return [workout("Pet Parent Power Hour", "strength", 35, [
        BODYWEIGHT_SQUAT(4, 20, 30, "Deep and controlled"),
        PUSHUP(4, 15, 45, "Full ROM"),
        GLUTE_BRIDGE(3, 20, 30, "Squeeze at top"),
        REVERSE_LUNGE(3, 12, 45, "Per leg"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        DEAD_BUG(3, 10, 20, "Per side"),
        SUPERMAN(3, 12, 20, "Lift and hold 2 seconds"),
    ])]

def _while_they_nap():
    return [workout("While They Nap", "strength", 20, [
        BODYWEIGHT_SQUAT(3, 15, 20, "Quiet, controlled"),
        PUSHUP(3, 10, 20, "Slow tempo"),
        GLUTE_BRIDGE(3, 15, 20, "No noise"),
        PLANK(3, 1, 20, "Hold 30 seconds"),
        DEAD_BUG(3, 10, 15, "Per side, silent"),
        CLAMSHELL(3, 12, 15, "Per side"),
    ])]

def _chaos_coordinator_fitness():
    return [workout("Chaos Coordinator Fitness", "strength", 25, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Quick between pet duties"),
        PUSHUP(3, 12, 30, "Standard or knees"),
        REVERSE_LUNGE(3, 10, 30, "Per leg, controlled"),
        GLUTE_BRIDGE(3, 15, 20, "Floor work"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
        MOUNTAIN_CLIMBER(3, 15, 20, "Controlled pace, no sudden jumps"),
    ])]

def _pet_playtime_gains():
    return [workout("Pet Playtime Gains", "strength", 25, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Toss toy at bottom of squat"),
        ex("Walking Lunge", 3, 10, 45, "Walk across room with pet",
           "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"],
           "beginner", "Long stride, upright torso", "Reverse Lunge"),
        PUSHUP(3, 10, 30, "Pet may walk under you"),
        GLUTE_BRIDGE(3, 15, 30, "Floor level fun"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
        DONKEY_KICK(3, 12, 20, "Per leg"),
    ])]

def _fur_and_fitness():
    return [workout("Fur & Fitness", "strength", 30, [
        BODYWEIGHT_SQUAT(4, 15, 30, "Steady controlled squats"),
        PUSHUP(3, 12, 30, "Full ROM"),
        GLUTE_BRIDGE(3, 15, 30, "Hip drive"),
        REVERSE_LUNGE(3, 10, 30, "Per leg"),
        BIRD_DOG(3, 10, 20, "Per side"),
        SIDE_PLANK(2, 1, 30, "Hold 20 seconds per side"),
        DEAD_BUG(3, 10, 20, "Per side"),
    ])]

def _cozy_pet_parent():
    return [workout("Cozy Pet Parent", "flexibility", 20, [
        CAT_COW(),
        CHILDS_POSE(),
        GLUTE_BRIDGE(3, 12, 20, "Gentle hip work"),
        DEAD_BUG(3, 8, 20, "Per side, slow"),
        stretch("Supine Spinal Twist", 30, "Back", "Obliques",
                "Relax, your pet may cuddle up", "Seated Twist"),
        HAPPY_BABY(),
    ])]

def _pet_underfoot_training():
    return [workout("Pet Underfoot Training", "strength", 25, [
        WALL_SIT(3, 1, 30, "Hold 30 seconds, pet safe"),
        PUSHUP(3, 12, 30, "Elevated on couch if pet is underneath"),
        ex("Standing Knee Raise", 3, 12, 20, "Per leg, watch your pet",
           "Bodyweight", "Core", "Hip Flexors", ["Core", "Quadriceps"],
           "beginner", "Lift knee to hip height, controlled", "Dead Bug"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
        ex("Standing Calf Raise", 3, 20, 15, "Bodyweight", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Slow controlled raises", "Seated Calf Raise"),
        GLUTE_BRIDGE(3, 15, 20, "Careful of pet nearby"),
    ])]

def _animal_house():
    return [workout("Animal House Workout", "strength", 30, [
        BODYWEIGHT_SQUAT(4, 15, 30, "Deep and controlled"),
        PUSHUP(4, 12, 30, "Standard form"),
        REVERSE_LUNGE(3, 10, 30, "Per leg"),
        GLUTE_BRIDGE(3, 15, 30, "Hip drive"),
        PLANK(3, 1, 30, "Hold 40 seconds"),
        SUPERMAN(3, 10, 20, "Hold 2 seconds at top"),
        DEAD_BUG(3, 10, 20, "Per side"),
    ])]

def _paws_and_planks():
    return [workout("Paws & Planks", "strength", 25, [
        PLANK(3, 1, 30, "Hold 40 seconds, pet may join"),
        SIDE_PLANK(2, 1, 30, "Hold 20 seconds per side"),
        GLUTE_BRIDGE(3, 15, 30, "Floor work"),
        DEAD_BUG(3, 10, 20, "Per side"),
        DONKEY_KICK(3, 12, 20, "Per leg"),
        FIRE_HYDRANT(3, 12, 20, "Per leg, on all fours"),
        BIRD_DOG(3, 10, 20, "Per side"),
    ])]

def _fit_pet_parent_life():
    return [workout("Fit Pet Parent Life", "strength", 30, [
        BODYWEIGHT_SQUAT(3, 20, 30, "Controlled depth"),
        PUSHUP(3, 15, 30, "Full ROM"),
        REVERSE_LUNGE(3, 10, 30, "Per leg"),
        GLUTE_BRIDGE(3, 15, 30, "Single leg option"),
        PLANK(3, 1, 30, "Hold 40 seconds"),
        MOUNTAIN_CLIMBER(3, 15, 20, "Slow controlled, no jumping"),
        CRUNCHES(3, 15, 20, "Gentle, pet may sit on your lap"),
    ])]


###############################################################################
# NINJA MODE (12 programs) - Silent/apartment-friendly, NO jumping
###############################################################################

def _ninja_mode():
    return [workout("Ninja Mode", "strength", 30, [
        BODYWEIGHT_SQUAT(4, 15, 30, "Slow 3-second descent, no bounce"),
        PUSHUP(4, 15, 45, "Controlled tempo, chest to floor"),
        REVERSE_LUNGE(3, 12, 45, "Per leg, slow and silent"),
        GLUTE_BRIDGE(3, 20, 30, "Pause at top 2 seconds"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        DEAD_BUG(3, 10, 20, "Per side, controlled"),
    ])]

def _zero_jump_cardio():
    return [workout("Zero Jump Cardio", "strength", 35, [
        BODYWEIGHT_SQUAT(4, 20, 20, "Fast tempo, no jumping"),
        MOUNTAIN_CLIMBER(4, 20, 20, "Controlled pace, feet silent"),
        REVERSE_LUNGE(3, 12, 30, "Alternating legs, quick"),
        GLUTE_BRIDGE(3, 20, 20, "Fast pumps"),
        PUSHUP(3, 15, 30, "Quick reps"),
        ex("March in Place", 3, 30, 15, "30 seconds, high knees without jumping",
           "Bodyweight", "Full Body", "Hip Flexors", ["Core", "Quadriceps"],
           "beginner", "Drive knees high, stay on balls of feet, silent", "Standing Knee Raise"),
    ])]

def _stealth_shred():
    return [workout("Stealth Shred", "strength", 35, [
        BODYWEIGHT_SQUAT(4, 20, 30, "Slow eccentric, fast concentric"),
        PUSHUP(4, 15, 30, "3 second negative"),
        REVERSE_LUNGE(3, 12, 30, "Per leg, controlled"),
        GLUTE_BRIDGE(3, 20, 20, "Squeeze top 3 seconds"),
        WALL_SIT(3, 1, 30, "Hold 45 seconds"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        BICYCLE_CRUNCH(3, 20, 20, "Slow and controlled, no momentum"),
    ])]

def _apartment_after_dark():
    return [workout("Apartment After Dark", "strength", 30, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Slow, silent squats"),
        PUSHUP(3, 12, 30, "Quiet, controlled"),
        GLUTE_BRIDGE(3, 20, 30, "Squeeze and hold at top"),
        DEAD_BUG(3, 10, 20, "Per side, slow"),
        DONKEY_KICK(3, 15, 20, "Per leg, controlled"),
        PLANK(3, 1, 30, "Hold 40 seconds"),
    ])]

def _dont_wake_neighbors():
    return [workout("Don't Wake the Neighbors", "strength", 30, [
        WALL_SIT(3, 1, 30, "Hold 40 seconds, silent burn"),
        PUSHUP(3, 15, 45, "Slow tempo"),
        GLUTE_BRIDGE(3, 20, 30, "Pause at top"),
        REVERSE_LUNGE(3, 10, 45, "Per leg, step softly"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        SIDE_PLANK(2, 1, 30, "Hold 25 seconds per side"),
    ])]

def _whisper_workout():
    return [workout("Whisper Workout", "strength", 25, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Controlled tempo, no bounce"),
        PUSHUP(3, 12, 30, "Slow descent"),
        GLUTE_BRIDGE(3, 15, 20, "Squeeze glutes"),
        DEAD_BUG(3, 10, 20, "Per side"),
        BIRD_DOG(3, 10, 20, "Per side"),
        CLAMSHELL(3, 15, 20, "Per side"),
    ])]

def _floor_friendly_fitness():
    return [workout("Floor-Friendly Fitness", "strength", 30, [
        GLUTE_BRIDGE(4, 20, 30, "Single leg option"),
        DEAD_BUG(3, 10, 20, "Per side, press back to floor"),
        DONKEY_KICK(3, 15, 20, "Per leg"),
        FIRE_HYDRANT(3, 15, 20, "Per leg"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        SIDE_PLANK(2, 1, 30, "Hold 25 seconds per side"),
        SUPERMAN(3, 12, 20, "Hold 2 seconds at top"),
    ])]

def _library_mode():
    return [workout("Library Mode", "strength", 30, [
        WALL_SIT(3, 1, 30, "Hold 40 seconds"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Slow, silent"),
        PUSHUP(3, 12, 30, "Controlled"),
        GLUTE_BRIDGE(3, 15, 20, "Quiet hip work"),
        PLANK(3, 1, 30, "Hold 40 seconds"),
        DEAD_BUG(3, 10, 20, "Per side, zero noise"),
    ])]

def _2am_workout_club():
    return [workout("2AM Workout Club", "strength", 30, [
        BODYWEIGHT_SQUAT(4, 15, 30, "Slow, controlled, silent"),
        PUSHUP(4, 12, 30, "3-second negative"),
        REVERSE_LUNGE(3, 10, 30, "Per leg, soft steps"),
        GLUTE_BRIDGE(3, 20, 20, "Hip drive, pause at top"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        DEAD_BUG(3, 10, 20, "Per side"),
    ])]

def _tippy_toe_gains():
    return [workout("Tippy-Toe Gains", "strength", 30, [
        ex("Standing Calf Raise", 4, 20, 30, "Slow 3-second raise and lower",
           "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"],
           "beginner", "Rise on toes, pause at top, slow descent", "Seated Calf Raise"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Rise on toes at top"),
        REVERSE_LUNGE(3, 10, 30, "Per leg, controlled"),
        WALL_SIT(3, 1, 30, "Hold 40 seconds"),
        PUSHUP(3, 12, 30, "Standard"),
        GLUTE_BRIDGE(3, 15, 20, "Pause at top"),
    ])]

def _silent_but_deadly():
    return [workout("Silent But Deadly", "strength", 35, [
        BODYWEIGHT_SQUAT(4, 20, 30, "Slow tempo, deep burn"),
        PUSHUP(4, 15, 45, "Controlled pace"),
        REVERSE_LUNGE(3, 12, 30, "Per leg, step softly"),
        GLUTE_BRIDGE(3, 20, 30, "Single-leg option for intensity"),
        WALL_SIT(3, 1, 30, "Hold 45 seconds"),
        PLANK(3, 1, 30, "Hold 50 seconds"),
        RUSSIAN_TWIST(3, 20, 20, "No weight, controlled twist"),
    ])]

def _stealth_mode_strength():
    return [workout("Stealth Mode Strength", "strength", 40, [
        BODYWEIGHT_SQUAT(4, 20, 30, "Slow 4-second descent"),
        PUSHUP(4, 15, 45, "3-second negative, pause at bottom"),
        REVERSE_LUNGE(4, 10, 45, "Per leg, deep step"),
        GLUTE_BRIDGE(3, 20, 30, "Weighted if available"),
        DIAMOND_PUSHUP(3, 10, 45, "Tricep emphasis"),
        WALL_SIT(3, 1, 30, "Hold 50 seconds"),
        PLANK(3, 1, 30, "Hold 60 seconds"),
    ])]


###############################################################################
# PACKED GYM (12 programs) - Limited equipment, specific station focus
###############################################################################

def _packed_gym_push():
    return [workout("Packed Gym Push", "strength", 35, [
        DB_BENCH(4, 10, 60, "Grab a pair of dumbbells"),
        DB_INCLINE_PRESS(3, 12, 60, "Adjustable bench if free"),
        DB_OHP(3, 12, 60, "Standing to avoid bench wait"),
        DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
        DIAMOND_PUSHUP(3, 12, 45, "Floor space always available"),
        DB_FLY(3, 12, 45, "Floor fly if no bench"),
    ])]

def _packed_gym_pull():
    return [workout("Packed Gym Pull", "strength", 35, [
        DB_ROW(4, 10, 60, "One arm, brace on any bench"),
        LAT_PULLDOWN(3, 12, 60, "If machine free"),
        FACE_PULL(3, 15, 30, "Light cable"),
        DB_CURL(3, 12, 45, "Standing, out of the way"),
        HAMMER_CURL(3, 12, 45, "Standing"),
        BAND_PULL_APART(3, 15, 20, "Bring your own band"),
    ])]

def _shoulder_express():
    return [workout("Shoulder Express", "strength", 30, [
        DB_OHP(4, 10, 60, "Standing, no bench needed"),
        DB_LATERAL_RAISE(4, 15, 30, "Light and strict"),
        ARNOLD_PRESS(3, 10, 60, "Standing or seated"),
        ex("Dumbbell Front Raise", 3, 12, 30, "Light, alternate arms",
           "Dumbbell", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid"],
           "beginner", "Lift to eye level, controlled descent", "Cable Front Raise"),
        ex("Dumbbell Rear Delt Fly", 3, 15, 30, "Light, bent over",
           "Dumbbell", "Shoulders", "Rear Deltoid", ["Rhomboids"],
           "beginner", "Bent at hips, squeeze shoulder blades", "Face Pull"),
        DB_SHRUG(3, 15, 30, "Heavy dumbbells"),
    ])]

def _arm_blaster_express():
    return [workout("Arm Blaster Express", "strength", 30, [
        DB_CURL(4, 10, 45, "Standing, alternate"),
        HAMMER_CURL(3, 12, 45, "Neutral grip"),
        CONCENTRATION_CURL(3, 12, 30, "Per arm, any bench"),
        ex("Dumbbell Overhead Tricep Extension", 3, 12, 45, "One heavy dumbbell",
           "Dumbbell", "Arms", "Triceps Long Head", ["Triceps"], "beginner",
           "Full stretch behind head, press up", "Bench Dip"),
        BENCH_DIP(3, 12, 45, "Any bench"),
        ex("Dumbbell Kickback", 3, 15, 30, "Light, per arm",
           "Dumbbell", "Arms", "Triceps", ["Anconeus"], "beginner",
           "Lock upper arm, extend fully, squeeze", "Tricep Pushdown"),
    ])]

def _packed_gym_legs():
    return [workout("Packed Gym Legs", "strength", 40, [
        GOBLET_SQUAT(4, 12, 60, "Heavy dumbbell"),
        DB_RDL(4, 10, 60, "Moderate to heavy"),
        DB_LUNGE(3, 10, 60, "Walking or stationary"),
        BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Per leg, any bench"),
        ex("Dumbbell Calf Raise", 4, 15, 30, "Heavy, single leg on plate",
           "Dumbbell", "Legs", "Calves", ["Tibialis Anterior"], "beginner",
           "Full stretch, pause at top", "Bodyweight Calf Raise"),
        GOBLET_SQUAT(3, 15, 45, "Lighter, slow tempo burnout"),
    ])]

def _glute_and_go():
    return [workout("Glute & Go", "strength", 30, [
        GOBLET_SQUAT(4, 12, 60, "Heavy, deep squat"),
        DB_RDL(3, 12, 60, "Feel the stretch"),
        GLUTE_BRIDGE(3, 20, 30, "Dumbbell on hips"),
        REVERSE_LUNGE(3, 10, 45, "Per leg, step back deep"),
        SUMO_SQUAT(3, 15, 45, "Wide stance, dumbbell between legs"),
        CURTSY_LUNGE(3, 10, 30, "Per leg"),
    ])]

def _leg_press_lightning():
    return [workout("Leg Press Lightning", "strength", 35, [
        LEG_PRESS(5, 10, 90, "Progressive sets, heavy"),
        LEG_EXT(4, 12, 45, "Squeeze at top"),
        LEG_CURL(4, 12, 45, "Full ROM"),
        CALF_RAISE(4, 15, 30, "On leg press if available"),
        LEG_PRESS(3, 20, 60, "Drop set to finish"),
    ])]

def _circuit_crusher():
    return [workout("Circuit Crusher", "strength", 35, [
        GOBLET_SQUAT(3, 12, 30, "Quick transitions"),
        PUSHUP(3, 15, 30, "Floor space"),
        DB_ROW(3, 10, 30, "Each arm"),
        DB_OHP(3, 10, 30, "Standing"),
        REVERSE_LUNGE(3, 10, 30, "Alternating"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
    ])]

def _dumbbell_only_day():
    return [workout("Dumbbell-Only Day", "strength", 40, [
        DB_BENCH(4, 10, 60, "Floor press if no bench"),
        DB_ROW(4, 10, 60, "Heavy, per arm"),
        GOBLET_SQUAT(4, 12, 60, "Deep"),
        DB_OHP(3, 10, 60, "Standing"),
        DB_RDL(3, 12, 60, "Moderate"),
        DB_CURL(3, 12, 45, "Alternate arms"),
        ex("Dumbbell Overhead Tricep Extension", 3, 12, 45, "One heavy dumbbell",
           "Dumbbell", "Arms", "Triceps Long Head", ["Triceps"], "beginner",
           "Full stretch, press up", "Bench Dip"),
    ])]

def _cable_corner_conquest():
    return [workout("Cable Corner Conquest", "strength", 40, [
        CABLE_ROW(4, 12, 60, "Moderate, squeeze back"),
        LAT_PULLDOWN(3, 12, 60, "Wide grip"),
        CABLE_FLY(3, 12, 45, "Various angles"),
        FACE_PULL(3, 15, 30, "Light, external rotation"),
        TRICEP_PUSHDOWN(3, 12, 45, "Rope attachment"),
        CABLE_CURL(3, 12, 45, "Constant tension"),
        CABLE_LATERAL_RAISE(3, 15, 30, "One arm at a time"),
    ])]

def _machine_medley():
    return [workout("Machine Medley", "strength", 40, [
        CHEST_PRESS_MACHINE(4, 10, 60, "Moderate weight"),
        LAT_PULLDOWN(4, 10, 60, "Pull to upper chest"),
        SHOULDER_PRESS_MACHINE(3, 10, 60, "Full ROM"),
        LEG_PRESS(4, 12, 90, "Feet shoulder width"),
        LEG_EXT(3, 12, 45, "Squeeze at top"),
        LEG_CURL(3, 12, 45, "Full ROM"),
        PEC_DECK(3, 12, 45, "Squeeze at center"),
    ])]

def _bench_and_beyond():
    return [workout("Bench & Beyond", "strength", 35, [
        DB_BENCH(4, 10, 60, "Heavy dumbbells"),
        DB_INCLINE_PRESS(3, 12, 60, "30-degree angle"),
        DB_FLY(3, 12, 45, "Light, stretch at bottom"),
        PUSHUP(3, 15, 45, "Feet elevated on bench"),
        DB_PULLOVER(3, 12, 60, "Across the bench"),
        DIAMOND_PUSHUP(3, 10, 45, "Finish with tricep burn"),
    ])]


###############################################################################
# POST-MEAL (10 programs) - Gentle, no intense core, no inversions
###############################################################################

def _digestive_walk():
    return [workout("Digestive Walk", "cardio", 20, [
        cardio_ex("Walking", 600, "Easy pace, 10 minutes outdoors or treadmill", "Bodyweight", "beginner"),
        stretch("Standing Quad Stretch", 20, "Legs", "Quadriceps",
                "Hold wall for balance, gentle pull", "Kneeling Quad Stretch"),
        stretch("Standing Hamstring Stretch", 20, "Legs", "Hamstrings",
                "Foot on low surface, gentle hinge", "Seated Forward Fold"),
        stretch("Standing Side Bend", 20, "Core", "Obliques",
                "Reach arm overhead, gentle lean to side", "Seated Side Bend"),
        ex("Standing Calf Raise", 3, 15, 15, "Gentle", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Slow rise and lower", "Ankle Circles"),
    ])]

def _after_meal_stretch():
    return [workout("After-Meal Stretch", "flexibility", 15, [
        stretch("Standing Side Bend", 20, "Core", "Obliques",
                "Gentle, reach overhead and lean", "Seated Side Bend"),
        stretch("Standing Quad Stretch", 20, "Legs", "Quadriceps",
                "Hold for balance, gentle", "Kneeling Quad Stretch"),
        stretch("Standing Chest Opener", 20, "Chest", "Pectoralis Major",
                "Clasp hands behind back, open chest", "Doorway Stretch"),
        stretch("Neck Side Stretch", 20, "Neck", "Trapezius",
                "Ear to shoulder, gentle hold", "Chin Tuck"),
        WALL_ANGEL(),
        stretch("Standing Hamstring Stretch", 20, "Legs", "Hamstrings",
                "Foot on low surface, gentle lean", "Ragdoll"),
    ])]

def _food_coma_fighter():
    return [workout("Food Coma Fighter", "cardio", 20, [
        cardio_ex("Walking", 300, "5 minutes brisk walk to start", "Bodyweight", "beginner"),
        BODYWEIGHT_SQUAT(3, 12, 30, "Light, wake up the body"),
        WALL_SIT(2, 1, 30, "Hold 20 seconds"),
        ex("Standing Knee Raise", 3, 10, 20, "Per leg, gentle",
           "Bodyweight", "Core", "Hip Flexors", ["Core", "Quadriceps"],
           "beginner", "Controlled knee lift, no rush", "March in Place"),
        ex("Standing Calf Raise", 3, 15, 15, "Gentle pump", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Rise on toes, slow descent", "Ankle Circles"),
        stretch("Standing Side Bend", 20, "Core", "Obliques",
                "Gentle reach and lean", "Seated Side Bend"),
    ])]

def _full_stomach_friendly():
    return [workout("Full Stomach Friendly", "strength", 20, [
        WALL_SIT(3, 1, 30, "Hold 25 seconds, no core compression"),
        PUSHUP(3, 10, 30, "Incline on wall or counter"),
        ex("Standing Calf Raise", 3, 20, 15, "Gentle", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Slow controlled raises", "Ankle Circles"),
        stretch("Standing Chest Opener", 20, "Chest", "Pectoralis Major",
                "Open chest, breathe deep", "Doorway Stretch"),
        WALL_ANGEL(),
        stretch("Standing Quad Stretch", 20, "Legs", "Quadriceps",
                "Gentle hold", "Kneeling Quad Stretch"),
    ])]

def _post_feast_flow():
    return [workout("Post-Feast Flow", "flexibility", 20, [
        cardio_ex("Walking", 300, "5 minute gentle walk", "Bodyweight", "beginner"),
        stretch("Standing Side Bend", 20, "Core", "Obliques",
                "Gentle lateral stretch", "Seated Side Bend"),
        stretch("Standing Forward Fold", 20, "Legs", "Hamstrings",
                "Gentle, bend knees freely", "Ragdoll"),
        stretch("Standing Chest Opener", 20, "Chest", "Pectoralis Major",
                "Open chest, deep breaths", "Doorway Stretch"),
        CHIN_TUCK(),
        stretch("Neck Side Stretch", 20, "Neck", "Trapezius",
                "Gentle, each side", "Chin Tuck"),
    ])]

def _thanksgiving_recovery():
    return [workout("Thanksgiving Recovery", "cardio", 25, [
        cardio_ex("Walking", 600, "10 minutes easy walking", "Bodyweight", "beginner"),
        BODYWEIGHT_SQUAT(3, 12, 30, "Gentle, get moving"),
        WALL_SIT(2, 1, 30, "Hold 20 seconds"),
        stretch("Standing Side Bend", 20, "Core", "Obliques",
                "Gentle stretch each side", "Seated Side Bend"),
        stretch("Standing Quad Stretch", 20, "Legs", "Quadriceps",
                "Hold for balance", "Kneeling Quad Stretch"),
        WALL_ANGEL(),
    ])]

def _30_min_post_meal():
    return [workout("30-Min Post-Meal", "cardio", 30, [
        cardio_ex("Walking", 600, "10 minute moderate walk", "Bodyweight", "beginner"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Easy tempo"),
        WALL_SIT(3, 1, 30, "Hold 25 seconds"),
        PUSHUP(3, 10, 30, "Incline option"),
        stretch("Standing Hamstring Stretch", 20, "Legs", "Hamstrings",
                "Gentle forward fold", "Ragdoll"),
        stretch("Standing Side Bend", 20, "Core", "Obliques",
                "Each side, breathe through it", "Seated Side Bend"),
        WALL_ANGEL(),
    ])]

def _upper_only_post_meal():
    return [workout("Upper Only (Post-Meal)", "strength", 20, [
        PUSHUP(3, 10, 30, "Incline on counter or wall"),
        DB_LATERAL_RAISE(3, 12, 30, "Light, seated if preferred"),
        DB_CURL(3, 10, 30, "Standing, light weight"),
        BENCH_DIP(3, 10, 30, "On chair edge"),
        WALL_ANGEL(),
        BAND_PULL_APART(3, 15, 20, "Light band, posture work"),
    ])]

def _standing_only_workout():
    return [workout("Standing Only Workout", "strength", 25, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Controlled depth"),
        WALL_SIT(3, 1, 30, "Hold 30 seconds"),
        REVERSE_LUNGE(3, 10, 30, "Per leg, gentle"),
        ex("Standing Calf Raise", 3, 20, 15, "Slow and controlled", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Full range of motion", "Ankle Circles"),
        ex("Standing Knee Raise", 3, 10, 20, "Per leg",
           "Bodyweight", "Core", "Hip Flexors", ["Core", "Quadriceps"],
           "beginner", "Lift knee to hip height, hold 2 seconds", "March in Place"),
        WALL_ANGEL(),
    ])]

def _gentle_gains():
    return [workout("Gentle Gains", "strength", 20, [
        BODYWEIGHT_SQUAT(3, 12, 30, "Easy, controlled"),
        PUSHUP(3, 8, 30, "Wall push-ups ok"),
        WALL_SIT(2, 1, 30, "Hold 20 seconds"),
        ex("Standing Calf Raise", 3, 15, 15, "Gentle", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Slow, controlled", "Ankle Circles"),
        WALL_ANGEL(),
        stretch("Standing Side Bend", 20, "Core", "Obliques",
                "Gentle reach each side", "Seated Side Bend"),
    ])]


###############################################################################
# CRUISE (11 programs) - Mix of gym, bodyweight, pool, deck
###############################################################################

def _cruise_gym_full_body():
    return [workout("Cruise Gym Full Body", "strength", 40, [
        DB_BENCH(3, 10, 60, "Moderate dumbbells"),
        DB_ROW(3, 10, 60, "Per arm"),
        GOBLET_SQUAT(3, 12, 60, "Heavy"),
        DB_OHP(3, 10, 60, "Standing"),
        DB_RDL(3, 12, 60, "Moderate"),
        PLANK(3, 1, 30, "Hold 40 seconds"),
    ])]

def _cruise_gym_upper():
    return [workout("Cruise Gym Upper", "strength", 35, [
        DB_BENCH(4, 10, 60, "Moderate"),
        DB_ROW(4, 10, 60, "Per arm, heavy"),
        DB_OHP(3, 10, 60, "Standing"),
        DB_LATERAL_RAISE(3, 15, 30, "Light"),
        DB_CURL(3, 12, 45, "Alternate"),
        ex("Dumbbell Overhead Tricep Extension", 3, 12, 45, "One heavy dumbbell",
           "Dumbbell", "Arms", "Triceps Long Head", ["Triceps"], "beginner",
           "Full stretch, press up", "Bench Dip"),
    ])]

def _cruise_gym_lower():
    return [workout("Cruise Gym Lower", "strength", 35, [
        GOBLET_SQUAT(4, 12, 60, "Heavy"),
        DB_RDL(3, 12, 60, "Moderate to heavy"),
        DB_LUNGE(3, 10, 60, "Per leg"),
        LEG_PRESS(3, 12, 90, "If available"),
        ex("Dumbbell Calf Raise", 4, 15, 30, "Single leg, heavy",
           "Dumbbell", "Legs", "Calves", ["Tibialis Anterior"], "beginner",
           "Full ROM on step", "Bodyweight Calf Raise"),
        GLUTE_BRIDGE(3, 15, 30, "Dumbbell on hips"),
    ])]

def _cruise_cardio_circuit():
    return [workout("Cruise Cardio Circuit", "cardio", 30, [
        cardio_ex("Treadmill Walk/Jog", 300, "5 min warmup, easy pace", "Treadmill", "beginner"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Quick tempo"),
        PUSHUP(3, 12, 30, "Fast reps"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Fast pace"),
        REVERSE_LUNGE(3, 10, 30, "Alternating"),
        cardio_ex("Rowing Machine", 300, "5 min moderate effort", "Rowing Machine", "beginner"),
    ])]

def _cabin_bodyweight():
    return [workout("Cabin Bodyweight", "strength", 25, [
        PUSHUP(4, 15, 45, "Full ROM"),
        BODYWEIGHT_SQUAT(4, 20, 30, "Deep"),
        GLUTE_BRIDGE(3, 15, 30, "Floor work"),
        PLANK(3, 1, 30, "Hold 40 seconds"),
        REVERSE_LUNGE(3, 10, 30, "Per leg"),
        DEAD_BUG(3, 10, 20, "Per side"),
    ])]

def _pool_aqua_fitness():
    return [workout("Pool Aqua Fitness", "cardio", 30, [
        ex("Water Walking", 1, 1, 30, "5 minutes", "Pool", "Full Body",
           "Cardiovascular", ["Legs", "Core"], "beginner",
           "Walk across pool, resist water, arms pumping", "Walking",
           duration_seconds=300),
        ex("Pool Squat", 3, 15, 30, "Chest-deep water", "Pool", "Legs",
           "Quadriceps", ["Glutes", "Core"], "beginner",
           "Squat in water, press back up, water provides resistance", "Bodyweight Squat"),
        ex("Water Arm Circles", 3, 20, 20, "Submerge arms", "Pool", "Shoulders",
           "Deltoids", ["Chest", "Back"], "beginner",
           "Arms out to sides underwater, circle forward and back", "Arm Circles"),
        ex("Pool Leg Kick", 3, 20, 20, "Hold pool edge", "Pool", "Legs",
           "Quadriceps", ["Hamstrings", "Core"], "beginner",
           "Hold edge, kick legs behind you alternating", "Lying Leg Raise"),
        ex("Water Treading", 1, 1, 30, "3 minutes", "Pool", "Full Body",
           "Cardiovascular", ["Core", "Legs", "Arms"], "beginner",
           "Stay afloat using arms and legs, steady effort", "Jumping Jacks",
           duration_seconds=180),
        ex("Pool Cool Down Walk", 1, 1, 0, "3 minutes easy", "Pool", "Full Body",
           "Cardiovascular", ["Recovery"], "beginner",
           "Gentle walk in shallow end", "Walking", duration_seconds=180),
    ])]

def _sunrise_deck_yoga():
    return [workout("Sunrise Deck Yoga", "yoga", 30, [
        CAT_COW(),
        DOWNWARD_DOG(),
        WARRIOR_I(),
        WARRIOR_II(),
        TRIANGLE(),
        TREE_POSE(),
        PIGEON_POSE(),
        SAVASANA(),
    ])]

def _port_day_explorer():
    return [workout("Port Day Explorer", "cardio", 30, [
        cardio_ex("Walking/Exploring", 600, "10 minutes brisk walk exploring port town",
                  "Bodyweight", "beginner"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Find a bench or ledge"),
        PUSHUP(3, 10, 30, "Incline on bench or wall"),
        STEP_UP(3, 10, 45, "Per leg, use stairs or curb"),
        REVERSE_LUNGE(3, 10, 30, "Per leg"),
        stretch("Standing Hamstring Stretch", 20, "Legs", "Hamstrings",
                "Foot on bench, hinge forward", "Seated Forward Fold"),
    ])]

def _shore_excursion_fitness():
    return [workout("Shore Excursion Fitness", "strength", 30, [
        BODYWEIGHT_SQUAT(4, 15, 30, "Beach squats"),
        PUSHUP(4, 12, 30, "Sand adds instability"),
        REVERSE_LUNGE(3, 10, 30, "Per leg, on sand"),
        PLANK(3, 1, 30, "Hold 30 seconds on sand"),
        GLUTE_BRIDGE(3, 15, 30, "Beach towel for comfort"),
        MOUNTAIN_CLIMBER(3, 15, 20, "Controlled on sand"),
    ])]

def _buffet_damage_control():
    return [workout("Buffet Damage Control", "strength", 35, [
        BODYWEIGHT_SQUAT(4, 20, 30, "High reps for calorie burn"),
        PUSHUP(4, 15, 30, "Full ROM"),
        MOUNTAIN_CLIMBER(4, 20, 20, "Fast pace"),
        REVERSE_LUNGE(3, 12, 30, "Alternating"),
        PLANK(3, 1, 30, "Hold 45 seconds"),
        GLUTE_BRIDGE(3, 20, 30, "Single leg option"),
        BURPEE(3, 8, 30, "Full extension"),
    ])]

def _sea_day_full_workout():
    return [workout("Sea Day Full Workout", "strength", 45, [
        DB_BENCH(4, 10, 60, "Ship gym dumbbells"),
        DB_ROW(4, 10, 60, "Per arm"),
        GOBLET_SQUAT(4, 12, 60, "Heavy"),
        DB_OHP(3, 10, 60, "Standing, brace core for ship movement"),
        DB_RDL(3, 12, 60, "Moderate"),
        DB_CURL(3, 12, 45, "Alternate"),
        PLANK(3, 1, 30, "Extra core challenge with ship movement"),
    ])]


###############################################################################
# GAMER (8 programs) - Wrist health, posture, quick breaks, conditioning
###############################################################################

def _esports_athlete_training():
    return [workout("Esports Athlete Training", "strength", 30, [
        WRIST_CIRCLES(),
        WALL_ANGEL(),
        CHIN_TUCK(),
        PUSHUP(3, 12, 30, "Posture and upper body strength"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Get blood flowing"),
        PLANK(3, 1, 30, "Hold 30 seconds, core for posture"),
        BAND_PULL_APART(3, 15, 20, "Light band, open chest"),
        stretch("Chest Doorway Stretch", 30, "Chest", "Pectoralis Major",
                "Arm on doorframe, lean through", "Standing Chest Opener"),
    ])]

def _pro_gamer_conditioning():
    return [workout("Pro Gamer Conditioning", "strength", 30, [
        WRIST_CIRCLES(),
        CHIN_TUCK(),
        BODYWEIGHT_SQUAT(3, 15, 30, "Counteract sitting"),
        PUSHUP(3, 12, 30, "Upper body strength"),
        GLUTE_BRIDGE(3, 15, 30, "Activate glutes after sitting"),
        PLANK(3, 1, 30, "Hold 30 seconds"),
        WALL_ANGEL(),
        DEAD_BUG(3, 10, 20, "Core stability for posture"),
    ])]

def _reaction_time_training():
    return [workout("Reaction Time Training", "strength", 25, [
        WRIST_CIRCLES(),
        ex("Finger Taps", 3, 30, 15, "Tap each finger to thumb rapidly",
           "Bodyweight", "Hands", "Hand Muscles", ["Forearms", "Finger Flexors"],
           "beginner", "Tap each finger to thumb fast, both hands", "Wrist Circles"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Quick tempo, explosive stand"),
        PUSHUP(3, 10, 30, "Clap push-ups if able, else fast reps"),
        MOUNTAIN_CLIMBER(3, 20, 20, "Fast hands, reaction drill"),
        HIGH_KNEES(3, 20, 15, "Quick feet"),
    ])]

def _gamer_wrist_hand_health():
    return [workout("Gamer Wrist & Hand Health", "flexibility", 15, [
        WRIST_CIRCLES(),
        ex("Wrist Flexion Stretch", 2, 1, 10, "Hold 20 seconds each hand",
           "Bodyweight", "Wrists", "Wrist Flexors", ["Forearms"],
           "beginner", "Extend arm, pull fingers back gently with other hand", "Wrist Circles"),
        ex("Wrist Extension Stretch", 2, 1, 10, "Hold 20 seconds each hand",
           "Bodyweight", "Wrists", "Wrist Extensors", ["Forearms"],
           "beginner", "Extend arm, push back of hand down gently", "Wrist Circles"),
        ex("Finger Spread", 3, 10, 10, "Spread and squeeze",
           "Bodyweight", "Hands", "Hand Muscles", ["Forearms"],
           "beginner", "Spread fingers wide, hold 3 seconds, make fist, repeat", "Wrist Circles"),
        ex("Prayer Stretch", 2, 1, 10, "Hold 20 seconds",
           "Bodyweight", "Wrists", "Wrist Flexors", ["Forearms"],
           "beginner", "Palms together at chest, press down keeping palms together", "Wrist Flexion Stretch"),
        ex("Thumb Stretch", 2, 1, 10, "Hold 15 seconds each thumb",
           "Bodyweight", "Hands", "Thumb Muscles", ["Forearms"],
           "beginner", "Pull thumb gently across palm, feel stretch at base", "Wrist Circles"),
        CHIN_TUCK(),
    ])]

def _screen_break_stretches():
    return [workout("Screen Break Stretches", "flexibility", 10, [
        WRIST_CIRCLES(),
        CHIN_TUCK(),
        stretch("Neck Side Stretch", 20, "Neck", "Trapezius",
                "Ear to shoulder, hold gently", "Chin Tuck"),
        WALL_ANGEL(),
        stretch("Standing Chest Opener", 20, "Chest", "Pectoralis Major",
                "Clasp hands behind back, open chest", "Doorway Stretch"),
        stretch("Standing Hamstring Stretch", 20, "Legs", "Hamstrings",
                "Foot on chair, gentle lean", "Seated Forward Fold"),
    ])]

def _couch_to_controller_fit():
    return [workout("Couch to Controller Fit", "strength", 25, [
        WRIST_CIRCLES(),
        CHIN_TUCK(),
        BODYWEIGHT_SQUAT(3, 12, 30, "Start easy, build up"),
        PUSHUP(3, 8, 30, "Knees ok to start"),
        GLUTE_BRIDGE(3, 12, 30, "Counter all that sitting"),
        PLANK(3, 1, 30, "Hold 20 seconds, build up"),
        WALL_ANGEL(),
    ])]

def _between_match_movement():
    return [workout("Between Match Movement", "flexibility", 10, [
        WRIST_CIRCLES(),
        CHIN_TUCK(),
        BODYWEIGHT_SQUAT(2, 10, 15, "Quick set, get blood flowing"),
        stretch("Standing Chest Opener", 15, "Chest", "Pectoralis Major",
                "Open up after hunching over controller", "Doorway Stretch"),
        stretch("Neck Side Stretch", 15, "Neck", "Trapezius",
                "Quick stretch each side", "Chin Tuck"),
        ex("Standing Calf Raise", 2, 15, 10, "Pump blood to legs", "Bodyweight", "Legs",
           "Calves", ["Tibialis Anterior"], "beginner",
           "Rise on toes, quick reps", "Ankle Circles"),
    ])]

def _streaming_setup_fitness():
    return [workout("Streaming Setup Fitness", "strength", 20, [
        WRIST_CIRCLES(),
        CHIN_TUCK(),
        WALL_ANGEL(),
        PUSHUP(3, 10, 30, "Off camera, quick set"),
        BODYWEIGHT_SQUAT(3, 12, 30, "Between streams"),
        PLANK(2, 1, 30, "Hold 25 seconds"),
        BAND_PULL_APART(3, 12, 20, "Keep at desk, quick posture reset"),
    ])]


###############################################################################
# BATCH_WORKOUTS dictionary
###############################################################################

BATCH_WORKOUTS = {
    # ---- Travel (14) ----
    "Hotel Gym Upper": _hotel_gym_upper,
    "Hotel Gym Lower": _hotel_gym_lower,
    "Hotel Gym Full Body": _hotel_gym_full_body,
    "Hotel Cardio Crusher": _hotel_cardio_crusher,
    "Hotel Dumbbell Monster": _hotel_dumbbell_monster,
    "Airport Layover Workout": _airport_layover,
    "Hotel Room Bodyweight": _hotel_room_bodyweight,
    "Resistance Band Travel": _resistance_band_travel,
    "Jet Lag Recovery": _jet_lag_recovery,
    "Airplane Seat Stretches": _airplane_seat_stretches,
    "Road Warrior Fitness": _road_warrior_fitness,
    "Conference Break Workout": _conference_break_workout,
    "Red Eye Recovery": _red_eye_recovery,
    "Weekend Warrior Travel": _weekend_warrior_travel,

    # ---- Night Shift (14) ----
    "Pre-Night Shift Activation": _pre_night_shift_activation,
    "Pre-12 Hour Shift": _pre_12_hour_shift,
    "Shift Worker Morning Routine": _shift_worker_morning,
    "Pre-Shift Energy Boost": _pre_shift_energy_boost,
    "Post-Night Shift Wind Down": _post_night_shift_wind_down,
    "Post-12 Hour Recovery": _post_12_hour_recovery,
    "Day Sleep Prep": _day_sleep_prep,
    "Shift Worker Decompression": _shift_worker_decompression,
    "Rotating Shift Fitness": _rotating_shift_fitness,
    "Healthcare Worker Fitness": _healthcare_worker_fitness,
    "First Responder Maintenance": _first_responder_maintenance,
    "Factory Shift Training": _factory_shift_training,
    "3-Day On 4-Day Off Training": _3_day_on_4_off,
    "Night Owl Gains": _night_owl_gains,

    # ---- Pet-Friendly (14) ----
    "Puppy Parent Workout": _puppy_parent,
    "Walk the Dog Gains": _walk_the_dog_gains,
    "Cat Got Your Mat": _cat_got_your_mat,
    "Small Pet Safe Zone": _small_pet_safe_zone,
    "Pet Parent Power Hour": _pet_parent_power_hour,
    "While They Nap": _while_they_nap,
    "Chaos Coordinator Fitness": _chaos_coordinator_fitness,
    "Pet Playtime Gains": _pet_playtime_gains,
    "Fur & Fitness": _fur_and_fitness,
    "Cozy Pet Parent": _cozy_pet_parent,
    "Pet Underfoot Training": _pet_underfoot_training,
    "Animal House Workout": _animal_house,
    "Paws & Planks": _paws_and_planks,
    "Fit Pet Parent Life": _fit_pet_parent_life,

    # ---- Ninja Mode (12) ----
    "Ninja Mode": _ninja_mode,
    "Zero Jump Cardio": _zero_jump_cardio,
    "Stealth Shred": _stealth_shred,
    "Apartment After Dark": _apartment_after_dark,
    "Don't Wake the Neighbors": _dont_wake_neighbors,
    "Whisper Workout": _whisper_workout,
    "Floor-Friendly Fitness": _floor_friendly_fitness,
    "Library Mode": _library_mode,
    "2AM Workout Club": _2am_workout_club,
    "Tippy-Toe Gains": _tippy_toe_gains,
    "Silent But Deadly": _silent_but_deadly,
    "Stealth Mode Strength": _stealth_mode_strength,

    # ---- Packed Gym (12) ----
    "Packed Gym Push": _packed_gym_push,
    "Packed Gym Pull": _packed_gym_pull,
    "Shoulder Express": _shoulder_express,
    "Arm Blaster Express": _arm_blaster_express,
    "Packed Gym Legs": _packed_gym_legs,
    "Glute & Go": _glute_and_go,
    "Leg Press Lightning": _leg_press_lightning,
    "Circuit Crusher": _circuit_crusher,
    "Dumbbell-Only Day": _dumbbell_only_day,
    "Cable Corner Conquest": _cable_corner_conquest,
    "Machine Medley": _machine_medley,
    "Bench & Beyond": _bench_and_beyond,

    # ---- Post-Meal (10) ----
    "Digestive Walk": _digestive_walk,
    "After-Meal Stretch": _after_meal_stretch,
    "Food Coma Fighter": _food_coma_fighter,
    "Full Stomach Friendly": _full_stomach_friendly,
    "Post-Feast Flow": _post_feast_flow,
    "Thanksgiving Recovery": _thanksgiving_recovery,
    "30-Min Post-Meal": _30_min_post_meal,
    "Upper Only (Post-Meal)": _upper_only_post_meal,
    "Standing Only Workout": _standing_only_workout,
    "Gentle Gains": _gentle_gains,

    # ---- Cruise (11) ----
    "Cruise Gym Full Body": _cruise_gym_full_body,
    "Cruise Gym Upper": _cruise_gym_upper,
    "Cruise Gym Lower": _cruise_gym_lower,
    "Cruise Cardio Circuit": _cruise_cardio_circuit,
    "Cabin Bodyweight": _cabin_bodyweight,
    "Pool Aqua Fitness": _pool_aqua_fitness,
    "Sunrise Deck Yoga": _sunrise_deck_yoga,
    "Port Day Explorer": _port_day_explorer,
    "Shore Excursion Fitness": _shore_excursion_fitness,
    "Buffet Damage Control": _buffet_damage_control,
    "Sea Day Full Workout": _sea_day_full_workout,

    # ---- Gamer (8) ----
    "Esports Athlete Training": _esports_athlete_training,
    "Pro Gamer Conditioning": _pro_gamer_conditioning,
    "Reaction Time Training": _reaction_time_training,
    "Gamer Wrist & Hand Health": _gamer_wrist_hand_health,
    "Screen Break Stretches": _screen_break_stretches,
    "Couch to Controller Fit": _couch_to_controller_fit,
    "Between Match Movement": _between_match_movement,
    "Streaming Setup Fitness": _streaming_setup_fitness,
}
