"""Batch 8: Remaining categories - hybrid, competition, nervous_system, weighted_accessories,
home_workout, outdoor, longevity, seasonal, social_fitness, fat_loss, face_jaw, strongman, hell_mode"""
from exercise_lib import *

# === HYBRID (11) ===
def _run_lift(): return [
    workout("Run Day", "cardio", 40, [
        cardio_ex("Treadmill Run - Easy Pace", 1200, "Conversational pace, 20 min"),
        cardio_ex("Treadmill Intervals", 600, "1 min fast / 1 min jog x5"),
        BODYWEIGHT_SQUAT(2, 15, 30, "Post-run activation"),
    ]),
    workout("Lift Day - Upper", "strength", 45, [
        BARBELL_BENCH(4, 8, 120, "Progressive overload"),
        BARBELL_ROW(4, 8, 120, "Match bench"),
        DB_OHP(3, 10, 60, "Moderate"),
        DB_CURL(3, 12, 45, "Moderate"),
        TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
    ]),
    workout("Lift Day - Lower", "strength", 45, [
        BARBELL_SQUAT(4, 6, 180, "Heavy"),
        RDL(3, 10, 90, "Moderate"),
        LEG_PRESS(3, 12, 90, "Moderate"),
        CALF_RAISE(4, 15, 30, "Moderate"),
    ]),
]
def _swim_strength(): return [
    workout("Swim Conditioning", "cardio", 40, [
        cardio_ex("Freestyle Swim", 1200, "20 min continuous"),
        cardio_ex("Kickboard Drills", 600, "10 min legs focus"),
        cardio_ex("Pull Buoy Drills", 600, "10 min upper body focus"),
    ]),
    workout("Dryland Strength", "strength", 45, [
        LAT_PULLDOWN(4, 10, 60, "Swim-specific pulling"),
        DB_OHP(3, 10, 60, "Shoulder stability"),
        CABLE_ROW(3, 12, 60, "Back endurance"),
        PLANK(3, 1, 30, "Hold 45 sec"),
        CALF_RAISE(3, 15, 30, "Kick power"),
    ]),
]
def _yoga_strength(): return [
    workout("Yoga Flow", "flexibility", 45, [
        CAT_COW(), DOWNWARD_DOG(), WARRIOR_I(), WARRIOR_II(), TRIANGLE(),
        PIGEON_POSE(), BRIDGE_POSE(), SAVASANA(),
    ]),
    workout("Strength Session", "strength", 45, [
        BARBELL_SQUAT(4, 8, 150, "Moderate-heavy"),
        BARBELL_BENCH(4, 8, 120, "Moderate-heavy"),
        BARBELL_ROW(4, 8, 120, "Moderate"),
        DB_OHP(3, 10, 60, "Moderate"),
        PLANK(3, 1, 30, "Hold 45 sec"),
    ]),
]
def _boxing_strength(): return [
    workout("Boxing Conditioning", "conditioning", 40, [
        cardio_ex("Shadow Boxing", 180, "3 rounds x 3 min"),
        cardio_ex("Heavy Bag Work", 180, "3 rounds x 3 min"),
        BURPEE(3, 10, 30, "Explosive"),
        MOUNTAIN_CLIMBER(3, 30, 15, "30 sec rounds"),
        JUMP_ROPE(3, 1, 30, "60 sec rounds"),
    ]),
    workout("Strength Day", "strength", 45, [
        BARBELL_BENCH(4, 8, 120, "Punching power"),
        BARBELL_ROW(4, 8, 120, "Pulling strength"),
        DB_OHP(3, 10, 60, "Shoulder endurance"),
        RUSSIAN_TWIST(3, 20, 30, "Core rotation"),
        PLANK(3, 1, 30, "Hold 45 sec"),
    ]),
]
def _cycling_weights(): return [
    workout("Cycling Session", "cardio", 45, [
        cardio_ex("Stationary Bike Warm-Up", 300, "Easy spin 5 min"),
        cardio_ex("Cycling Intervals", 1200, "30s sprint / 90s recover x10"),
        cardio_ex("Cool Down Spin", 300, "Easy 5 min"),
    ]),
    workout("Leg Strength", "strength", 40, [
        BARBELL_SQUAT(4, 8, 150, "Cycling power"),
        LEG_PRESS(3, 12, 90, "Single-leg option"),
        LEG_CURL(3, 12, 60, "Hamstring balance"),
        CALF_RAISE(4, 15, 30, "Pedal power"),
        PLANK(3, 1, 30, "Core for cycling posture"),
    ]),
]
def _hiit_strength(): return [
    workout("HIIT Circuit", "hiit", 25, [
        BURPEE(1, 10, 15, "30 sec"), JUMP_SQUAT(1, 15, 15, "30 sec"),
        MOUNTAIN_CLIMBER(1, 30, 15, "30 sec"), PUSHUP(1, 15, 15, "30 sec"),
        HIGH_KNEES(1, 30, 15, "30 sec"), BODYWEIGHT_SQUAT(1, 20, 15, "30 sec"),
    ]),
    workout("Strength Day", "strength", 45, [
        BARBELL_SQUAT(4, 6, 150, "Heavy"), BARBELL_BENCH(4, 6, 150, "Heavy"),
        BARBELL_ROW(4, 6, 120, "Heavy"), RDL(3, 8, 90, "Moderate"),
    ]),
]
def _endurance_power(): return [
    workout("Endurance Session", "cardio", 45, [
        cardio_ex("Steady-State Cardio", 1800, "30 min moderate effort"),
        BODYWEIGHT_SQUAT(2, 20, 30, "Endurance squats"),
        PUSHUP(2, 20, 30, "Endurance push-ups"),
    ]),
    workout("Power Session", "strength", 45, [
        POWER_CLEAN(5, 3, 120, "Explosive"), BARBELL_SQUAT(4, 5, 180, "Heavy"),
        BARBELL_BENCH(4, 5, 180, "Heavy"), BOX_JUMP(3, 8, 60, "Explosive"),
    ]),
]
def _crossfit_hybrid(): return [
    workout("WOD Style", "conditioning", 35, [
        PULLUP(3, 10, 30, "Kipping allowed"), PUSHUP(3, 20, 15, "Fast"),
        BODYWEIGHT_SQUAT(3, 20, 15, "Air squats"), BURPEE(3, 10, 30, "Fast"),
        KETTLEBELL_SWING(3, 15, 30, "Moderate"), BOX_JUMP(3, 10, 30, "24 inch"),
    ]),
    workout("Strength Focus", "strength", 45, [
        BARBELL_SQUAT(5, 5, 180, "Heavy"), DEADLIFT(3, 5, 240, "Heavy"),
        BARBELL_OHP(3, 5, 180, "Heavy"), PULLUP(3, 8, 90, "Strict"),
    ]),
]
def _martial_arts_weights(): return [
    workout("Martial Arts Conditioning", "conditioning", 40, [
        cardio_ex("Shadow Boxing/Kicking", 300, "5 min warm-up"),
        BURPEE(3, 10, 30, "Explosive"), JUMP_SQUAT(3, 10, 30, "Power"),
        MOUNTAIN_CLIMBER(3, 30, 15, "Speed"), RUSSIAN_TWIST(3, 20, 30, "Core rotation"),
    ]),
    workout("Strength Day", "strength", 45, [
        DEADLIFT(3, 5, 180, "Hip power"), BARBELL_BENCH(4, 8, 120, "Push strength"),
        PULLUP(3, 8, 90, "Grappling strength"), BARBELL_ROW(3, 8, 120, "Pull strength"),
    ]),
]
def _calisthenics_weights(): return [
    workout("Calisthenics Day", "strength", 40, [
        PULLUP(4, 8, 90, "Strict"), DIP(4, 10, 90, "Weighted if possible"),
        PIKE_PUSHUP(3, 10, 60, "Handstand prep"), INVERTED_ROW(3, 12, 60, "Bodyweight"),
        PLANK(3, 1, 30, "Hold 60 sec"), HANGING_LEG_RAISE(3, 10, 60, "Core"),
    ]),
    workout("Weights Day", "strength", 45, [
        BARBELL_SQUAT(4, 6, 180, "Heavy"), DEADLIFT(3, 5, 240, "Heavy"),
        BARBELL_OHP(3, 8, 120, "Moderate"), BARBELL_ROW(3, 8, 120, "Moderate"),
    ]),
]
def _sport_gym(): return [
    workout("Sport Skills", "conditioning", 40, [
        cardio_ex("Sport-Specific Drills", 600, "10 min agility"), BOX_JUMP(3, 8, 60, "Power"),
        JUMP_SQUAT(3, 10, 30, "Reactive"), HIGH_KNEES(3, 30, 15, "Speed"),
        PLANK(3, 1, 30, "Core stability"),
    ]),
    workout("Gym Strength", "strength", 45, [
        BARBELL_SQUAT(4, 6, 180, "Leg power"), BARBELL_BENCH(4, 8, 120, "Upper push"),
        PULLUP(3, 8, 90, "Upper pull"), RDL(3, 10, 90, "Posterior chain"),
        FARMER_WALK(3, 1, 60, "Grip and core"),
    ]),
]

# === COMPETITION (11) ===
def _marathon(): return [
    workout("Long Run", "cardio", 90, [
        cardio_ex("Easy Run", 5400, "90 min at conversational pace"),
    ]),
    workout("Tempo Run + Strength", "conditioning", 60, [
        cardio_ex("Tempo Run", 2400, "40 min at threshold pace"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Runner strength"),
        GLUTE_BRIDGE(3, 15, 30, "Hip activation"),
        PLANK(3, 1, 30, "Core stability"),
    ]),
    workout("Interval Training", "hiit", 45, [
        cardio_ex("800m Repeats", 1800, "6x800m with 400m jog recovery"),
        CALF_RAISE(3, 15, 30, "Foot strength"),
        SINGLE_LEG_RDL(2, 10, 45, "Balance and hamstrings"),
    ]),
]
def _half_marathon(): return [
    workout("Long Run", "cardio", 75, [
        cardio_ex("Steady Run", 4500, "75 min easy pace"),
    ]),
    workout("Tempo + Strength", "conditioning", 50, [
        cardio_ex("Tempo Run", 1800, "30 min moderate-hard"),
        BODYWEIGHT_SQUAT(3, 15, 30, "Leg endurance"),
        GLUTE_BRIDGE(3, 15, 30, "Hip strength"),
    ]),
]
def _triathlon(): return [
    workout("Swim", "cardio", 45, [cardio_ex("Freestyle Swim", 2700, "45 min continuous")]),
    workout("Bike", "cardio", 60, [cardio_ex("Cycling", 3600, "60 min moderate")]),
    workout("Run + Brick", "cardio", 45, [
        cardio_ex("Bike to Run Transition", 1200, "20 min bike then 25 min run"),
    ]),
    workout("Strength", "strength", 40, [
        BARBELL_SQUAT(3, 8, 120, "Leg power"), PULLUP(3, 8, 90, "Swim strength"),
        PLANK(3, 1, 30, "Core"), CALF_RAISE(3, 15, 30, "Run power"),
    ]),
]
def _tough_mudder(): return [
    workout("OCR Conditioning", "conditioning", 50, [
        PULLUP(3, 8, 60, "Obstacle prep"), BURPEE(3, 10, 30, "Full body"),
        FARMER_WALK(3, 1, 60, "Grip endurance"), BODYWEIGHT_SQUAT(3, 20, 30, "Leg endurance"),
        MOUNTAIN_CLIMBER(3, 30, 15, "Cardio"), DEAD_BUG(3, 10, 30, "Core"),
    ]),
    workout("Run + Strength", "conditioning", 45, [
        cardio_ex("Trail Run Intervals", 1200, "Run 2 min, walk 1 min x6"),
        PUSHUP(3, 20, 30, "Wall climbs"), INVERTED_ROW(3, 12, 60, "Rope prep"),
        JUMP_SQUAT(3, 10, 30, "Explosive"), PLANK(3, 1, 30, "Mud crawl core"),
    ]),
]
def _crossfit_games(): return [
    workout("WOD A", "conditioning", 45, [
        BARBELL_SQUAT(5, 5, 120, "Heavy"), PULLUP(5, 10, 30, "Kipping"),
        BURPEE(3, 15, 20, "Fast"), KETTLEBELL_SWING(3, 20, 30, "Russian"),
        BOX_JUMP(3, 12, 30, "24 inch"),
    ]),
    workout("WOD B", "conditioning", 45, [
        DEADLIFT(5, 5, 150, "Heavy"), BARBELL_OHP(3, 8, 90, "Push press"),
        ROWING(3, 1, 60, "500m sprints"), PUSHUP(3, 20, 15, "Fast"),
        HANGING_LEG_RAISE(3, 15, 30, "Toes to bar"),
    ]),
]
def _boxing_match(): return [
    workout("Boxing Conditioning", "conditioning", 50, [
        JUMP_ROPE(5, 1, 30, "3 min rounds"), cardio_ex("Shadow Boxing", 540, "3x3 min rounds"),
        cardio_ex("Heavy Bag", 540, "3x3 min rounds"), BURPEE(3, 10, 30, "Explosive"),
        RUSSIAN_TWIST(3, 20, 30, "Core rotation"),
    ]),
    workout("Strength", "strength", 40, [
        BARBELL_BENCH(4, 8, 120, "Punch power"), PULLUP(3, 8, 90, "Clinch strength"),
        BARBELL_ROW(3, 8, 120, "Pull strength"), PLANK(3, 1, 30, "Core stability"),
    ]),
]
def _mma_fight(): return [
    workout("MMA Conditioning", "conditioning", 50, [
        cardio_ex("Striking Combos", 300, "5 min"), cardio_ex("Grappling Drills", 300, "5 min"),
        BURPEE(3, 10, 30, "Scrambles"), MOUNTAIN_CLIMBER(3, 30, 15, "Ground work"),
        RUSSIAN_TWIST(3, 20, 30, "Guard passing"), PULLUP(3, 8, 60, "Clinch"),
    ]),
    workout("Strength", "strength", 45, [
        DEADLIFT(4, 5, 180, "Takedown power"), BARBELL_SQUAT(4, 6, 150, "Level changes"),
        BARBELL_ROW(3, 8, 120, "Grip fighting"), FARMER_WALK(3, 1, 60, "Grip endurance"),
    ]),
]
def _wrestling(): return [
    workout("Wrestling Conditioning", "conditioning", 45, [
        BURPEE(3, 10, 30, "Scrambles"), MOUNTAIN_CLIMBER(3, 30, 15, "Mat work"),
        PULLUP(3, 8, 60, "Grip strength"), BODYWEIGHT_SQUAT(3, 20, 30, "Level changes"),
        PLANK(3, 1, 30, "Core stability"),
    ]),
    workout("Strength", "strength", 45, [
        DEADLIFT(4, 5, 180, "Lifting power"), BARBELL_ROW(4, 8, 120, "Pulling"),
        BARBELL_SQUAT(4, 6, 150, "Leg drive"), FARMER_WALK(3, 1, 60, "Grip"),
    ]),
]
def _track_field(): return [
    workout("Sprint Training", "conditioning", 40, [
        cardio_ex("Sprint Intervals", 1200, "8x100m with full recovery"),
        JUMP_SQUAT(3, 8, 60, "Explosive power"), BOX_JUMP(3, 8, 60, "Plyometrics"),
        HIGH_KNEES(3, 30, 15, "Sprint mechanics"),
    ]),
    workout("Strength", "strength", 45, [
        BARBELL_SQUAT(4, 5, 180, "Leg power"), POWER_CLEAN(4, 3, 120, "Explosive"),
        RDL(3, 8, 90, "Hamstring strength"), CALF_RAISE(4, 10, 30, "Sprint power"),
    ]),
]
def _swim_meet(): return [
    workout("Pool Training", "cardio", 50, [
        cardio_ex("Warm-Up Swim", 600, "10 min easy"), cardio_ex("Interval Sets", 1200, "8x50m sprints"),
        cardio_ex("Kick Sets", 600, "Kickboard work"), cardio_ex("Cool Down", 300, "Easy 5 min"),
    ]),
    workout("Dryland", "strength", 40, [
        LAT_PULLDOWN(4, 10, 60, "Pulling power"), DB_OHP(3, 10, 60, "Overhead recovery"),
        PLANK(3, 1, 30, "Streamline core"), CALF_RAISE(3, 15, 30, "Kick power"),
    ]),
]
def _cycling_race(): return [
    workout("Interval Ride", "cardio", 60, [
        cardio_ex("Warm-Up Spin", 600, "10 min easy"),
        cardio_ex("VO2 Max Intervals", 1800, "5x3 min hard, 3 min easy"),
        cardio_ex("Cool Down", 600, "10 min easy"),
    ]),
    workout("Leg Strength", "strength", 40, [
        BARBELL_SQUAT(4, 6, 150, "Pedal power"), LEG_PRESS(3, 10, 90, "Single-leg"),
        LEG_CURL(3, 12, 60, "Hamstring balance"), CALF_RAISE(4, 15, 30, "Ankle power"),
    ]),
]

# === NERVOUS SYSTEM (11) ===
def _vagus_nerve(): return [workout("Vagus Nerve Activation", "flexibility", 20, [
    ex("Deep Diaphragmatic Breathing", 3, 10, 15, "Inhale 4s, hold 4s, exhale 8s", "Bodyweight", "Core",
       "Diaphragm", ["Nervous System"], "beginner", "Belly expands on inhale, slow exhale through mouth", "Box Breathing"),
    ex("Cold Exposure Breathing", 2, 5, 15, "Splash cold water on face or hold ice", "Bodyweight", "Full Body",
       "Vagus Nerve", ["Nervous System"], "beginner", "Cold stimulus activates vagus nerve", "Deep Breathing"),
    ex("Humming/Chanting", 3, 5, 15, "Hum deeply for 5 breaths", "Bodyweight", "Full Body",
       "Vagus Nerve", ["Throat"], "beginner", "Feel vibration in chest and throat", "Singing"),
    CAT_COW(), CHILDS_POSE(), LEGS_UP_WALL(), SAVASANA(),
])]
def _somatic_movement(): return [workout("Somatic Movement", "flexibility", 25, [
    ex("Body Scan", 1, 1, 15, "Lie still, scan from toes to head", "Bodyweight", "Full Body",
       "Awareness", ["Nervous System"], "beginner", "Notice sensations without judgment", "Meditation"),
    CAT_COW(), ex("Pelvic Tilts", 3, 10, 15, "Slow, mindful", "Bodyweight", "Core",
       "Pelvic Floor", ["Core"], "beginner", "Tilt pelvis forward and back, feel each vertebra", "Glute Bridge"),
    HAPPY_BABY(), RECLINED_TWIST(), SAVASANA(),
])]
def _trauma_release(): return [workout("TRE Session", "flexibility", 25, [
    ex("Wall Sit Tremor", 1, 1, 15, "Hold until legs shake, then lie down", "Bodyweight", "Legs",
       "Quadriceps", ["Nervous System"], "beginner", "Allow natural tremoring to occur", "Wall Sit"),
    ex("Standing Shake", 3, 1, 15, "60 seconds shaking entire body", "Bodyweight", "Full Body",
       "Full Body", ["Nervous System"], "beginner", "Let body shake freely, release tension", "Jumping Jacks"),
    BUTTERFLY_STRETCH(), CHILDS_POSE(), SAVASANA(),
])]
def _polyvagal(): return [workout("Polyvagal Exercises", "flexibility", 20, [
    ex("Orienting Exercise", 3, 5, 15, "Slowly look around room", "Bodyweight", "Full Body",
       "Visual System", ["Nervous System"], "beginner", "Turn head slowly, notice 5 things you see", "Body Scan"),
    ex("Social Engagement", 2, 5, 15, "Smile, hum, sing", "Bodyweight", "Full Body",
       "Facial Muscles", ["Vagus Nerve"], "beginner", "Activate social nervous system", "Humming"),
    CAT_COW(), CHILDS_POSE(), LEGS_UP_WALL(), SAVASANA(),
])]
def _body_awareness(): return [workout("Body Awareness", "flexibility", 25, [
    ex("Standing Body Scan", 1, 1, 10, "Stand still, feel feet on ground", "Bodyweight", "Full Body",
       "Proprioception", ["Balance"], "beginner", "Notice weight distribution, posture alignment", "Meditation"),
    TREE_POSE(), WARRIOR_II(), CAT_COW(), PIGEON_POSE(), SAVASANA(),
])]
def _tension_release(): return [workout("Tension Release", "flexibility", 25, [
    ex("Jaw Release", 3, 10, 10, "Open mouth wide, stretch jaw", "Bodyweight", "Face",
       "Masseter", ["TMJ"], "beginner", "Open and close jaw slowly, feel release", "Neck Stretch"),
    ex("Shoulder Drops", 3, 10, 10, "Shrug up, hold 5s, drop", "Bodyweight", "Shoulders",
       "Trapezius", ["Neck"], "beginner", "Let shoulders fall completely relaxed", "Neck Rolls"),
    CAT_COW(), CHILDS_POSE(), HAPPY_BABY(), RECLINED_TWIST(), SAVASANA(),
])]
def _grounding(): return [workout("Grounding Movement", "flexibility", 20, [
    ex("5-4-3-2-1 Grounding", 1, 1, 10, "Name 5 things you see, 4 touch, 3 hear, 2 smell, 1 taste",
       "Bodyweight", "Full Body", "Awareness", ["Nervous System"], "beginner",
       "Engages all senses to return to present", "Body Scan"),
    ex("Barefoot Standing", 1, 1, 10, "Stand barefoot, feel ground", "Bodyweight", "Feet",
       "Proprioception", ["Balance"], "beginner", "Notice texture, temperature, weight distribution", "Tree Pose"),
    DOWNWARD_DOG(), WARRIOR_I(), TREE_POSE(), CHILDS_POSE(),
])]
def _shake_release(): return [workout("Shake & Release", "flexibility", 20, [
    ex("Full Body Shake", 3, 1, 15, "60 seconds per round", "Bodyweight", "Full Body",
       "Full Body", ["Nervous System"], "beginner", "Shake arms, legs, torso - let everything go", "Jumping Jacks"),
    ex("Arm Swings", 2, 20, 10, "Swing arms freely", "Bodyweight", "Shoulders",
       "Deltoids", ["Spine"], "beginner", "Twist torso, let arms swing loosely", "Shoulder Circles"),
    CHILDS_POSE(), HAPPY_BABY(), SAVASANA(),
])]
def _nervous_recovery(): return [workout("Nervous System Recovery", "flexibility", 25, [
    ex("Physiological Sigh", 5, 5, 10, "Double inhale through nose, long exhale", "Bodyweight", "Full Body",
       "Diaphragm", ["Nervous System"], "beginner", "Two quick inhales then one long exhale", "Deep Breathing"),
    LEGS_UP_WALL(), RECLINED_TWIST(), HAPPY_BABY(), SAVASANA(),
])]
def _interoception(): return [workout("Interoception Training", "flexibility", 20, [
    ex("Heart Rate Awareness", 1, 1, 10, "Place hand on chest, count heartbeats", "Bodyweight", "Full Body",
       "Cardiovascular", ["Awareness"], "beginner", "Feel your heartbeat for 60 seconds", "Body Scan"),
    ex("Breath Counting", 3, 10, 10, "Count natural breaths", "Bodyweight", "Full Body",
       "Respiratory", ["Awareness"], "beginner", "Don't change breath, just observe", "Meditation"),
    CAT_COW(), BRIDGE_POSE(), CHILDS_POSE(), SAVASANA(),
])]
def _embodiment(): return [workout("Embodiment Practice", "flexibility", 25, [
    ex("Mindful Walking", 1, 1, 10, "Walk slowly for 3 minutes", "Bodyweight", "Full Body",
       "Proprioception", ["Balance", "Awareness"], "beginner", "Feel each step: heel, arch, toes", "Standing Balance"),
    CAT_COW(), WARRIOR_I(), WARRIOR_II(), TREE_POSE(), PIGEON_POSE(), SAVASANA(),
])]

# helper for trauma release
BUTTERFLY_STRETCH = lambda: stretch("Butterfly Stretch", 30, "Hips", "Adductors",
    "Soles together, let knees fall, gentle bounce", "Seated Forward Fold")

# === WEIGHTED ACCESSORIES (16) ===
def _vest_walk(): return [workout("Weighted Vest Walking", "cardio", 35, [
    ex("Weighted Walk", 1, 1, 30, "30 min at brisk pace with 10-20lb vest", "Weighted Vest",
       "Full Body", "Cardiovascular", ["Core", "Legs"], "beginner",
       "Upright posture, normal stride, start with lighter vest", "Brisk Walk", duration_seconds=1800),
    BODYWEIGHT_SQUAT(2, 15, 30, "Vest on, bodyweight squats"),
])]
def _vest_hiit(): return [workout("Weighted Vest HIIT", "hiit", 30, [
    ex("Vest Burpee", 3, 8, 30, "With vest", "Weighted Vest", "Full Body", "Full Body",
       ["Chest", "Legs", "Core"], "advanced", "Chest to floor, explosive jump", "Burpee"),
    PUSHUP(3, 12, 30, "With vest"), BODYWEIGHT_SQUAT(3, 15, 30, "With vest"),
    MOUNTAIN_CLIMBER(3, 20, 15, "With vest"),
])]
def _vest_strength(): return [workout("Weighted Vest Strength", "strength", 40, [
    PULLUP(4, 6, 90, "With vest"), DIP(4, 8, 90, "With vest"),
    PUSHUP(3, 15, 45, "With vest"), BODYWEIGHT_SQUAT(3, 15, 45, "With vest, deep"),
    STEP_UP(3, 10, 60, "With vest, per leg"), PLANK(3, 1, 30, "With vest, hold 30s"),
])]
def _ankle_sculpt(): return [workout("Ankle Weight Sculpt", "strength", 30, [
    DONKEY_KICK(3, 15, 30, "With ankle weights"), FIRE_HYDRANT(3, 15, 30, "With ankle weights"),
    ex("Standing Leg Lift - Front", 3, 15, 30, "Per leg", "Ankle Weights", "Legs",
       "Hip Flexors", ["Quadriceps"], "beginner", "Stand tall, lift leg forward controlled", "Lying Leg Raise"),
    ex("Standing Leg Lift - Side", 3, 15, 30, "Per leg", "Ankle Weights", "Legs",
       "Hip Abductors", ["Glutes"], "beginner", "Lift leg to side, control descent", "Fire Hydrant"),
    ex("Lying Leg Raise", 3, 12, 30, "With ankle weights", "Ankle Weights", "Core",
       "Lower Abs", ["Hip Flexors"], "beginner", "Lie back, raise legs to 90 degrees", "Knee Raise"),
    GLUTE_BRIDGE(3, 15, 30, "With ankle weights above knees"),
])]
def _wrist_cardio(): return [workout("Wrist Weight Cardio", "cardio", 25, [
    ex("Arm Circles", 3, 20, 15, "Forward and backward", "Wrist Weights", "Shoulders",
       "Deltoids", ["Trapezius"], "beginner", "Keep arms extended, circle slowly", "Lateral Raise"),
    ex("Shadow Boxing", 3, 1, 30, "60 seconds per round", "Wrist Weights", "Full Body",
       "Shoulders", ["Arms", "Core"], "beginner", "Jab, cross, hooks with wrist weights", "Arm Punches"),
    JUMPING_JACK(3, 30, 15, "With wrist weights"), HIGH_KNEES(3, 30, 15, "With wrist weights"),
    MOUNTAIN_CLIMBER(3, 20, 15, "With wrist weights"),
])]
def _hula_hoop(): return [workout("Weighted Hula Hoop", "cardio", 25, [
    ex("Hula Hoop Waist", 3, 1, 30, "3 min per direction", "Weighted Hula Hoop", "Core",
       "Obliques", ["Rectus Abdominis", "Hip Flexors"], "beginner",
       "Keep feet shoulder-width, push hips in circle", "Standing Twist", duration_seconds=180),
    ex("Hula Hoop Arms", 2, 1, 15, "30 sec per arm", "Weighted Hula Hoop", "Arms",
       "Biceps", ["Shoulders"], "beginner", "Spin hoop on each arm", "Arm Circles"),
    BODYWEIGHT_SQUAT(3, 15, 30, "Between sets"),
])]
def _mini_stepper(): return [workout("Mini Stepper Cardio", "cardio", 30, [
    ex("Stepper Warm-Up", 1, 1, 15, "5 min easy pace", "Mini Stepper", "Legs",
       "Quadriceps", ["Calves", "Glutes"], "beginner", "Steady rhythm, upright posture", "Stair Walk"),
    ex("Stepper Intervals", 5, 1, 30, "2 min fast / 1 min easy", "Mini Stepper", "Legs",
       "Quadriceps", ["Calves", "Cardiovascular"], "beginner", "Alternate speed", "Step-Up"),
    BODYWEIGHT_SQUAT(2, 15, 30, "Between intervals"),
])]
def _vibration_plate(): return [workout("Vibration Plate", "strength", 25, [
    ex("Vibration Squat", 3, 15, 30, "On plate", "Vibration Plate", "Legs",
       "Quadriceps", ["Glutes"], "beginner", "Stand on plate, squat with vibration", "Bodyweight Squat"),
    ex("Vibration Plank", 3, 1, 30, "Hold 30 sec", "Vibration Plate", "Core",
       "Core", ["Shoulders"], "beginner", "Hands on plate in plank position", "Plank"),
    CALF_RAISE(3, 15, 30, "On plate"), GLUTE_BRIDGE(3, 15, 30, "Feet on plate"),
])]
def _rucking(): return [workout("Rucking for Beginners", "cardio", 40, [
    ex("Ruck Walk", 1, 1, 30, "30-40 min with 10-20lb pack", "Backpack/Rucksack", "Full Body",
       "Legs", ["Core", "Back", "Cardiovascular"], "beginner",
       "Start with 10lb, upright posture, normal pace", "Brisk Walk", duration_seconds=2400),
    BODYWEIGHT_SQUAT(2, 15, 30, "With pack on"),
])]
def _vest_training(): return [workout("Weighted Vest Training", "strength", 40, [
    PULLUP(3, 6, 90, "With vest"), PUSHUP(3, 15, 45, "With vest"),
    BODYWEIGHT_SQUAT(3, 20, 45, "With vest"), DB_LUNGE(3, 10, 60, "With vest"),
    PLANK(3, 1, 30, "With vest, 30s"), BURPEE(2, 8, 30, "With vest"),
])]
def _ankle_weight_workout(): return [workout("Ankle Weight Workout", "strength", 30, [
    DONKEY_KICK(3, 15, 30, "With ankle weights"), FIRE_HYDRANT(3, 15, 30, "Ankle weights"),
    CLAMSHELL(3, 15, 30, "Ankle weights"), GLUTE_BRIDGE(3, 15, 30, "Ankle weights"),
    ex("Seated Leg Extension", 3, 12, 30, "With ankle weights", "Ankle Weights", "Legs",
       "Quadriceps", ["Hip Flexors"], "beginner", "Sit tall, extend one leg at a time", "Leg Extension"),
])]
def _wrist_weight_workout(): return [workout("Wrist Weight Workout", "strength", 25, [
    ex("Arm Punches", 3, 20, 15, "Per arm", "Wrist Weights", "Arms",
       "Shoulders", ["Triceps", "Core"], "beginner", "Alternate punches, engage core", "Shadow Boxing"),
    PUSHUP(3, 12, 30, "Wrist weights on"), PLANK(3, 1, 30, "With wrist weights, 30s"),
    ex("Standing Arm Circles", 3, 15, 15, "Forward and back", "Wrist Weights", "Shoulders",
       "Deltoids", ["Rotator Cuff"], "beginner", "Keep arms straight, controlled circles", "Lateral Raise"),
])]
def _weighted_walking(): return [workout("Weighted Walking", "cardio", 35, [
    ex("Farmer's Walk", 4, 1, 60, "50 yards each set", "Dumbbell", "Full Body",
       "Grip", ["Traps", "Core"], "beginner", "Heavy dumbbells, upright posture, quick steps", "Weighted Walk"),
    ex("Weighted Walk", 1, 1, 30, "20 min with dumbbells or vest", "Dumbbell", "Full Body",
       "Cardiovascular", ["Core", "Legs"], "beginner", "Moderate pace, alternate hands", "Brisk Walk"),
])]
def _hip_circle_band(): return [workout("Hip Circle Band", "strength", 25, [
    LATERAL_BAND_WALK(3, 15, 30, "Band around ankles"),
    BANDED_SQUAT(3, 15, 30, "Push knees out"),
    GLUTE_BRIDGE(3, 15, 30, "Band above knees"),
    CLAMSHELL(3, 15, 30, "Band above knees"),
    ex("Banded Monster Walk", 3, 12, 30, "Per direction", "Resistance Band", "Glutes",
       "Gluteus Medius", ["TFL"], "beginner", "Band around ankles, walk forward diagonally", "Lateral Band Walk"),
])]
def _mini_band(): return [workout("Mini Band Workout", "strength", 25, [
    LATERAL_BAND_WALK(3, 15, 30, "Mini band above knees"),
    BANDED_SQUAT(3, 15, 30, "Mini band above knees"),
    GLUTE_BRIDGE(3, 15, 30, "Mini band above knees"),
    DONKEY_KICK(3, 12, 30, "Mini band around foot and knee"),
    CLAMSHELL(3, 15, 30, "Mini band above knees"),
])]
def _slam_ball(): return [workout("Slam Ball Training", "conditioning", 30, [
    ex("Ball Slam", 4, 10, 30, "Overhead slam", "Slam Ball", "Full Body",
       "Core", ["Shoulders", "Lats"], "intermediate", "Lift overhead, slam down hard, squat to pick up", "Medicine Ball Slam"),
    ex("Rotational Slam", 3, 8, 30, "Per side", "Slam Ball", "Core",
       "Obliques", ["Shoulders"], "intermediate", "Twist and slam to each side", "Russian Twist"),
    ex("Chest Pass", 3, 10, 30, "Explosive", "Slam Ball", "Chest",
       "Pectoralis Major", ["Triceps"], "beginner", "Push ball from chest explosively", "Push-Up"),
    BODYWEIGHT_SQUAT(3, 15, 30, "Hold ball at chest"),
])]

# === HOME WORKOUT (16) ===
def _epic_strength(): return [
    workout("Full Body A", "strength", 50, [
        GOBLET_SQUAT(4, 12, 60, "Heavy dumbbell"), DB_BENCH(4, 10, 60, "Heavy dumbbells"),
        DB_ROW(4, 10, 60, "Heavy"), DB_OHP(3, 10, 60, "Moderate"),
        DB_RDL(3, 12, 60, "Moderate"), DB_CURL(3, 12, 45, "Moderate"),
    ]),
    workout("Full Body B", "strength", 50, [
        DB_LUNGE(3, 10, 60, "Heavy, per leg"), DB_INCLINE_PRESS(4, 10, 60, "Moderate"),
        DB_ROW(4, 10, 60, "Heavy"), ARNOLD_PRESS(3, 10, 60, "Moderate"),
        DB_RDL(3, 12, 60, "Moderate"), TRICEP_OVERHEAD(3, 12, 45, "Dumbbell"),
    ]),
]
def _quick_shred(): return [workout("Full Body Shred", "hiit", 30, [
    JUMP_SQUAT(3, 15, 15, "Explosive"), PUSHUP(3, 15, 15, "Fast"),
    MOUNTAIN_CLIMBER(3, 30, 15, "30 sec"), BURPEE(3, 10, 15, "Full"),
    BODYWEIGHT_SQUAT(3, 20, 15, "Deep"), PLANK(3, 1, 15, "30 sec"),
])]
def _daily_variety(): return [
    workout("Upper Focus", "strength", 35, [
        PUSHUP(3, 15, 30, "Bodyweight"), INVERTED_ROW(3, 10, 60, "Bodyweight or DB row"),
        PIKE_PUSHUP(3, 10, 45, "Shoulder focus"), DB_CURL(3, 12, 30, "Light"),
    ]),
    workout("Lower Focus", "strength", 35, [
        BODYWEIGHT_SQUAT(3, 20, 30, "Deep"), GLUTE_BRIDGE(3, 15, 30, "Banded"),
        DB_LUNGE(3, 10, 45, "Per leg"), CALF_RAISE(3, 20, 20, "Bodyweight"),
    ]),
    workout("Full Body", "hiit", 30, [
        BURPEE(3, 8, 20, "Full"), MOUNTAIN_CLIMBER(3, 20, 15, "Fast"),
        JUMP_SQUAT(3, 12, 15, "Explosive"), PUSHUP(3, 12, 15, "Fast"),
    ]),
]
def _skills_calisthenics(): return [workout("Skills Training", "strength", 45, [
    PULLUP(4, 8, 90, "Strict"), DIP(4, 10, 90, "Strict"), PIKE_PUSHUP(3, 10, 60, "Handstand prep"),
    INVERTED_ROW(3, 12, 60, "Feet elevated"), PLANK(3, 1, 30, "Hold 60 sec"),
    HANGING_LEG_RAISE(3, 10, 60, "L-sit prep"),
])]
def _balanced_home(): return [
    workout("Strength", "strength", 35, [
        GOBLET_SQUAT(3, 12, 60, "Moderate"), PUSHUP(3, 15, 30, "Bodyweight"),
        DB_ROW(3, 10, 60, "Moderate"), GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
    ]),
    workout("Flexibility", "flexibility", 25, [
        CAT_COW(), DOWNWARD_DOG(), PIGEON_POSE(), CHILDS_POSE(), SAVASANA(),
    ]),
]
def _yoga_journey(): return [workout("Accessible Yoga", "flexibility", 30, [
    CAT_COW(), DOWNWARD_DOG(), WARRIOR_I(), WARRIOR_II(), TREE_POSE(),
    BRIDGE_POSE(), CHILDS_POSE(), SAVASANA(),
])]
def _celeb_trainer(): return [
    workout("Upper Body", "strength", 35, [
        DB_BENCH(3, 12, 60, "Moderate"), DB_ROW(3, 12, 60, "Moderate"),
        DB_OHP(3, 10, 60, "Moderate"), DB_CURL(3, 12, 30, "Light"),
        TRICEP_OVERHEAD(3, 12, 30, "Light"),
    ]),
    workout("Lower Body", "strength", 35, [
        GOBLET_SQUAT(3, 12, 60, "Moderate"), DB_LUNGE(3, 10, 60, "Per leg"),
        DB_RDL(3, 12, 60, "Moderate"), GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
    ]),
]
def _no_nonsense(): return [workout("No-Nonsense Full Body", "strength", 30, [
    PUSHUP(3, 15, 30, "Bodyweight"), BODYWEIGHT_SQUAT(3, 20, 30, "Deep"),
    DB_ROW(3, 10, 60, "Moderate"), GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
    PLANK(3, 1, 30, "Hold 30 sec"),
])]
def _beginner_home_yt(): return [workout("Beginner Home Workout", "strength", 25, [
    BODYWEIGHT_SQUAT(3, 12, 30, "Bodyweight"), PUSHUP(3, 8, 30, "Knee push-ups OK"),
    GLUTE_BRIDGE(3, 12, 30, "Bodyweight"), PLANK(3, 1, 30, "Hold 20 sec"),
    BIRD_DOG(2, 10, 20, "Per side"),
])]
def _thirty_day_challenge(): return [workout("30-Day Challenge", "strength", 25, [
    BODYWEIGHT_SQUAT(3, 15, 30, "Add reps weekly"), PUSHUP(3, 10, 30, "Add reps weekly"),
    PLANK(3, 1, 30, "Add 5 sec weekly"), GLUTE_BRIDGE(3, 15, 30, "Add reps weekly"),
    BURPEE(2, 5, 30, "Add reps weekly"),
])]
def _no_equip(): return [workout("No Equipment", "strength", 25, [
    BODYWEIGHT_SQUAT(3, 20, 30, "Deep"), PUSHUP(3, 15, 30, "Full ROM"),
    GLUTE_BRIDGE(3, 15, 30, "Single-leg option"), MOUNTAIN_CLIMBER(3, 20, 15, "Fast"),
    PLANK(3, 1, 30, "Hold 30 sec"),
])]
def _apartment_friendly(): return [workout("Apartment Friendly", "strength", 30, [
    BODYWEIGHT_SQUAT(3, 20, 30, "No jumping"), PUSHUP(3, 15, 30, "Controlled"),
    GLUTE_BRIDGE(3, 15, 30, "Slow tempo"), PLANK(3, 1, 30, "Hold 30 sec"),
    DEAD_BUG(3, 10, 20, "Slow and controlled"), BIRD_DOG(3, 10, 20, "Per side"),
])]
def _small_space(): return [workout("Small Space Workout", "strength", 25, [
    BODYWEIGHT_SQUAT(3, 15, 30, "In place"), PUSHUP(3, 12, 30, "Minimal space"),
    GLUTE_BRIDGE(3, 15, 30, "Lying down"), PLANK(3, 1, 30, "Hold 30 sec"),
    CRUNCHES(3, 15, 20, "Minimal space"),
])]
def _minimal_noise(): return [workout("Minimal Noise", "strength", 30, [
    BODYWEIGHT_SQUAT(3, 15, 30, "Slow, controlled"), PUSHUP(3, 12, 30, "Slow tempo"),
    GLUTE_BRIDGE(3, 15, 30, "Squeeze at top"), PLANK(3, 1, 30, "Hold 30 sec"),
    DEAD_BUG(3, 10, 20, "Super controlled"),
])]
def _follow_strength(): return [workout("Follow Along Strength", "strength", 35, [
    GOBLET_SQUAT(3, 12, 60, "Moderate"), DB_BENCH(3, 10, 60, "Moderate"),
    DB_ROW(3, 10, 60, "Moderate"), DB_OHP(3, 10, 60, "Moderate"),
    GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
])]
def _follow_cardio(): return [workout("Follow Along Cardio", "cardio", 25, [
    JUMPING_JACK(3, 30, 15, "30 sec"), HIGH_KNEES(3, 30, 15, "30 sec"),
    MOUNTAIN_CLIMBER(3, 20, 15, "20 sec"), BURPEE(2, 8, 20, "Full"),
    BODYWEIGHT_SQUAT(3, 20, 15, "Fast pace"),
])]

# === OUTDOOR (8) ===
def _hiking(): return [workout("Hiking Prep", "conditioning", 45, [
    cardio_ex("Incline Walk", 1200, "20 min treadmill at steep incline"),
    STEP_UP(3, 12, 60, "Weighted, high step"), BODYWEIGHT_SQUAT(3, 20, 30, "Endurance"),
    CALF_RAISE(3, 15, 30, "Single-leg"), PLANK(3, 1, 30, "Hold 45 sec"),
])]
def _urban_explore(): return [workout("Urban Fitness", "conditioning", 40, [
    cardio_ex("Brisk Walk/Jog", 900, "15 min"), BODYWEIGHT_SQUAT(3, 20, 30, "Park bench squats"),
    PUSHUP(3, 15, 30, "Incline on bench"), STEP_UP(3, 10, 60, "Stairs or bench"),
    PLANK(3, 1, 30, "Hold 30 sec"),
])]
def _trail_run(): return [workout("Trail Running Prep", "conditioning", 45, [
    cardio_ex("Interval Run", 1200, "Hills: run up, walk down x8"),
    SINGLE_LEG_RDL(3, 10, 45, "Balance work"), BODYWEIGHT_SQUAT(3, 20, 30, "Endurance"),
    CALF_RAISE(3, 15, 30, "Trail ankle strength"), PLANK(3, 1, 30, "Core stability"),
])]
def _outdoor_boot(): return [workout("Outdoor Bootcamp", "conditioning", 40, [
    BURPEE(3, 10, 15, "Full"), JUMP_SQUAT(3, 12, 15, "Explosive"),
    PUSHUP(3, 15, 15, "Fast"), MOUNTAIN_CLIMBER(3, 30, 15, "30 sec"),
    HIGH_KNEES(3, 30, 15, "30 sec"), PLANK(3, 1, 15, "Hold 30 sec"),
])]
def _kayak_dry(): return [workout("Kayaking Dryland", "strength", 40, [
    LAT_PULLDOWN(4, 10, 60, "Pulling power"), CABLE_ROW(3, 12, 60, "Endurance pulls"),
    DB_OHP(3, 10, 60, "Shoulder stability"), RUSSIAN_TWIST(3, 20, 30, "Rotational core"),
    PLANK(3, 1, 30, "Hold 45 sec"),
])]
def _surfing(): return [workout("Surfing Prep", "conditioning", 40, [
    PUSHUP(3, 15, 30, "Pop-up practice"), PULLUP(3, 8, 60, "Paddle strength"),
    BODYWEIGHT_SQUAT(3, 15, 30, "Stance stability"), PLANK(3, 1, 30, "Paddle endurance"),
    ex("Turkish Get-Up", 2, 5, 60, "Per side", "Dumbbell", "Full Body", "Full Body",
       ["Core", "Shoulders"], "intermediate", "Stand up from ground smoothly", "Windmill"),
])]
def _snow_sport(): return [workout("Snow Sport Prep", "conditioning", 40, [
    BODYWEIGHT_SQUAT(3, 20, 30, "Ski stance"), WALL_SIT(3, 1, 30, "Hold 45 sec"),
    JUMP_SQUAT(3, 10, 30, "Explosive"), SINGLE_LEG_RDL(3, 10, 45, "Balance"),
    PLANK(3, 1, 30, "Core stability"), SIDE_PLANK(2, 1, 30, "Hold 20 sec per side"),
])]
def _adventure_race(): return [workout("Adventure Race Prep", "conditioning", 50, [
    BURPEE(3, 10, 20, "Full"), PULLUP(3, 8, 60, "Obstacle prep"),
    FARMER_WALK(3, 1, 60, "Carry strength"), BODYWEIGHT_SQUAT(3, 20, 30, "Endurance"),
    MOUNTAIN_CLIMBER(3, 30, 15, "Cardio"), PLANK(3, 1, 30, "Core"),
])]

# === LONGEVITY (9) ===
def _heat_exposure(): return [workout("Heat Exposure Training", "conditioning", 30, [
    cardio_ex("Warm-Up Walk", 600, "10 min brisk walk"),
    BODYWEIGHT_SQUAT(3, 20, 30, "Moderate pace"), PUSHUP(3, 12, 30, "Controlled"),
    GLUTE_BRIDGE(3, 15, 30, "Hold at top"), PLANK(3, 1, 30, "Hold 30 sec"),
])]
def _vo2_max(): return [workout("VO2 Max Training", "hiit", 30, [
    cardio_ex("Warm-Up", 300, "5 min easy jog"),
    cardio_ex("VO2 Max Intervals", 1200, "4x4 min at 90-95% max HR, 3 min active rest"),
    cardio_ex("Cool Down", 300, "5 min easy jog"),
])]
def _joint_longevity(): return [workout("Joint Longevity", "flexibility", 25, [
    ANKLE_CIRCLES(), WRIST_CIRCLES(), HIP_90_90(),
    WORLD_GREATEST_STRETCH(), CAT_COW(), THORACIC_EXTENSION(),
    WALL_ANGEL(), BODYWEIGHT_SQUAT(2, 10, 30, "Slow, full ROM"),
])]
def _spine_health(): return [workout("Spine Health", "flexibility", 25, [
    CAT_COW(), BIRD_DOG(3, 10, 20, "Per side"), DEAD_BUG(3, 10, 20, "Slow"),
    SUPERMAN(3, 10, 20, "Hold 3 sec at top"), CHILDS_POSE(),
    ex("Pelvic Tilts", 3, 10, 15, "Slow, controlled", "Bodyweight", "Core",
       "Pelvic Floor", ["Core"], "beginner", "Tilt pelvis forward and back gently", "Glute Bridge"),
])]
def _brain_body(): return [workout("Brain-Body Connection", "flexibility", 30, [
    ex("Cross-Body March", 3, 20, 15, "Opposite hand to knee", "Bodyweight", "Full Body",
       "Coordination", ["Core", "Balance"], "beginner", "Touch right hand to left knee alternating", "High Knees"),
    BIRD_DOG(3, 10, 20, "Per side"), TREE_POSE(),
    ex("Dual-Task Balance", 2, 10, 15, "Count backward while balancing", "Bodyweight", "Full Body",
       "Cognitive", ["Balance"], "beginner", "Stand on one foot, count backwards from 100 by 7s", "Tree Pose"),
    CAT_COW(), SAVASANA(),
])]
def _anti_aging_move(): return [workout("Anti-Aging Movement", "strength", 35, [
    BODYWEIGHT_SQUAT(3, 15, 30, "Full depth"), PUSHUP(3, 10, 30, "Full ROM"),
    GLUTE_BRIDGE(3, 15, 30, "Squeeze at top"), BIRD_DOG(3, 10, 20, "Per side"),
    PLANK(3, 1, 30, "Hold 20 sec"),
    ex("Get-Up from Floor", 3, 5, 30, "Practice getting up without using hands", "Bodyweight", "Full Body",
       "Functional", ["Legs", "Core"], "beginner", "Sit down and stand up using minimal hand support", "Bodyweight Squat"),
])]
def _hormesis(): return [workout("Hormesis Training", "conditioning", 30, [
    cardio_ex("Cold Exposure Breathing", 120, "2 min controlled breathing before cold shower"),
    BODYWEIGHT_SQUAT(3, 20, 30, "Moderate pace"), PUSHUP(3, 15, 30, "Controlled"),
    PLANK(3, 1, 30, "Hold 30 sec"), BURPEE(2, 5, 30, "Moderate"),
])]
def _fascia(): return [workout("Fascia Training", "flexibility", 30, [
    FOAM_ROLL_QUAD(), FOAM_ROLL_IT_BAND(), FOAM_ROLL_BACK(),
    ex("Fascial Stretch - Whole Body", 2, 1, 15, "Full body stretch, 30 sec each", "Bodyweight", "Full Body",
       "Fascia", ["Flexibility"], "beginner", "Reach arms overhead, lean side to side, rotate", "Standing Stretch"),
    DOWNWARD_DOG(), CAT_COW(), PIGEON_POSE(),
])]
def _autophagy(): return [workout("Autophagy Workout", "conditioning", 25, [
    cardio_ex("Brisk Walk", 600, "10 min moderate"), BODYWEIGHT_SQUAT(3, 15, 30, "Moderate"),
    PUSHUP(3, 10, 30, "Controlled"), PLANK(3, 1, 30, "Hold 20 sec"),
    GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
])]

# === SEASONAL (9) ===
def _cold_weather(): return [workout("Cold Weather Fitness", "strength", 35, [
    cardio_ex("Dynamic Warm-Up", 300, "5 min jumping jacks + high knees"),
    BODYWEIGHT_SQUAT(3, 20, 30, "Get blood flowing"), PUSHUP(3, 15, 30, "Controlled"),
    BURPEE(3, 8, 30, "Full body warm"), DB_ROW(3, 10, 60, "Moderate"),
])]
def _monsoon(): return [workout("Monsoon Indoor", "strength", 35, [
    BODYWEIGHT_SQUAT(3, 20, 30, "No equipment needed"), PUSHUP(3, 15, 30, "Controlled"),
    GLUTE_BRIDGE(3, 15, 30, "Bodyweight"), PLANK(3, 1, 30, "Hold 30 sec"),
    MOUNTAIN_CLIMBER(3, 20, 15, "Cardio indoors"),
])]
def _winter_maint(): return [workout("Winter Maintenance", "strength", 35, [
    GOBLET_SQUAT(3, 12, 60, "Moderate"), DB_BENCH(3, 10, 60, "Moderate"),
    DB_ROW(3, 10, 60, "Moderate"), PLANK(3, 1, 30, "Hold 30 sec"),
    GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
])]
def _spring_kick(): return [workout("Spring Kickoff", "strength", 40, [
    BARBELL_SQUAT(4, 8, 120, "Progressive"), BARBELL_BENCH(4, 8, 120, "Progressive"),
    BARBELL_ROW(4, 8, 120, "Progressive"), DB_OHP(3, 10, 60, "Moderate"),
    cardio_ex("Outdoor Jog", 600, "10 min easy pace"),
])]
def _fall_peak(): return [workout("Fall Training Peak", "strength", 50, [
    BARBELL_SQUAT(5, 5, 180, "Heavy"), BARBELL_BENCH(5, 5, 180, "Heavy"),
    DEADLIFT(3, 5, 240, "Heavy"), BARBELL_OHP(3, 5, 180, "Heavy"),
])]
def _humidity(): return [workout("Humidity Adaptation", "conditioning", 30, [
    cardio_ex("Light Cardio", 600, "10 min easy, hydrate well"),
    BODYWEIGHT_SQUAT(3, 15, 30, "Moderate"), PUSHUP(3, 12, 30, "Controlled"),
    PLANK(3, 1, 30, "Hold 20 sec"),
])]
def _altitude(): return [workout("Altitude Training Prep", "conditioning", 35, [
    cardio_ex("Breathwork", 300, "5 min controlled breathing"),
    cardio_ex("Steady Cardio", 900, "15 min moderate effort, monitor breathing"),
    BODYWEIGHT_SQUAT(3, 15, 30, "Moderate"), PLANK(3, 1, 30, "Core stability"),
])]
def _indoor_winter(): return [workout("Indoor Winter Alternative", "strength", 35, [
    BODYWEIGHT_SQUAT(3, 20, 30, "Deep"), PUSHUP(3, 15, 30, "Full ROM"),
    GLUTE_BRIDGE(3, 15, 30, "Bodyweight"), MOUNTAIN_CLIMBER(3, 20, 15, "Cardio"),
    PLANK(3, 1, 30, "Hold 30 sec"),
])]
def _year_round(): return [
    workout("Outdoor Session A", "conditioning", 40, [
        cardio_ex("Jog", 900, "15 min easy"), BODYWEIGHT_SQUAT(3, 20, 30, "Park"),
        PUSHUP(3, 15, 30, "Park bench"), STEP_UP(3, 10, 60, "Bench or stairs"),
    ]),
    workout("Outdoor Session B", "conditioning", 40, [
        cardio_ex("Hill Sprints", 900, "10x30 sec uphill, walk down"),
        BURPEE(3, 8, 30, "Park"), PLANK(3, 1, 30, "Hold 30 sec"),
    ]),
]

# === SOCIAL FITNESS (8) ===
def _run_club(): return [workout("Run Club Ready", "cardio", 40, [
    cardio_ex("Group Run", 1800, "30 min easy pace, conversational"),
    BODYWEIGHT_SQUAT(2, 15, 30, "Post-run"), GLUTE_BRIDGE(2, 15, 30, "Activation"),
    CALF_RAISE(2, 15, 20, "Recovery"),
])]
def _couples(): return [workout("Couples Fitness", "strength", 35, [
    BODYWEIGHT_SQUAT(3, 15, 30, "Side by side"), PUSHUP(3, 12, 30, "Facing each other"),
    PLANK(3, 1, 30, "Hold together 30 sec"), GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
    BURPEE(2, 8, 30, "Race each other"),
])]
def _group_class(): return [workout("Group Class Ready", "hiit", 35, [
    JUMPING_JACK(3, 30, 15, "30 sec"), BURPEE(3, 8, 15, "Full"),
    BODYWEIGHT_SQUAT(3, 20, 15, "Fast"), PUSHUP(3, 12, 15, "Controlled"),
    MOUNTAIN_CLIMBER(3, 20, 15, "Fast"), PLANK(3, 1, 15, "Hold 30 sec"),
])]
def _accountability(): return [
    workout("Day A - Full Body", "strength", 35, [
        BODYWEIGHT_SQUAT(3, 15, 30, "Share with partner"), PUSHUP(3, 12, 30, "Accountability"),
        DB_ROW(3, 10, 60, "Moderate"), GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
    ]),
    workout("Day B - Cardio", "cardio", 25, [
        cardio_ex("Walk/Jog Together", 1200, "20 min"), BURPEE(2, 8, 30, "Challenge"),
    ]),
]
def _social_walk(): return [workout("Social Walking Group", "cardio", 35, [
    cardio_ex("Group Walk", 1800, "30 min brisk pace"),
    BODYWEIGHT_SQUAT(2, 12, 30, "Park stop"), CALF_RAISE(2, 15, 20, "Standing"),
])]
def _gym_buddy(): return [
    workout("Push Day Together", "strength", 45, [
        BARBELL_BENCH(4, 8, 120, "Spot each other"), DB_OHP(3, 10, 60, "Moderate"),
        DB_INCLINE_PRESS(3, 12, 60, "Moderate"), TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
    ]),
    workout("Pull Day Together", "strength", 45, [
        BARBELL_ROW(4, 8, 120, "Spot each other"), PULLUP(3, 8, 90, "Or lat pulldown"),
        CABLE_ROW(3, 12, 60, "Moderate"), DB_CURL(3, 12, 45, "Moderate"),
    ]),
]
def _virtual_group(): return [workout("Virtual Group Training", "strength", 30, [
    BODYWEIGHT_SQUAT(3, 20, 30, "Sync with group"), PUSHUP(3, 15, 30, "Together"),
    PLANK(3, 1, 30, "Hold 30 sec challenge"), BURPEE(2, 8, 30, "Race"),
    MOUNTAIN_CLIMBER(3, 20, 15, "Cardio burst"),
])]
def _team_sport(): return [workout("Team Sport Fitness", "conditioning", 40, [
    cardio_ex("Agility Drills", 600, "10 min ladder/cones"),
    JUMP_SQUAT(3, 10, 30, "Explosive"), BOX_JUMP(3, 8, 60, "Reactive"),
    BODYWEIGHT_SQUAT(3, 15, 30, "Endurance"), PLANK(3, 1, 30, "Core"),
    cardio_ex("Sprint Intervals", 600, "6x50m sprints"),
])]

# === FAT LOSS / GLP-1 (8) ===
def _ozempic_recomp(): return [workout("Body Recomp", "strength", 40, [
    BARBELL_SQUAT(3, 8, 120, "Muscle preservation"), BARBELL_BENCH(3, 8, 120, "Compound focus"),
    BARBELL_ROW(3, 8, 120, "Back strength"), DB_OHP(3, 10, 60, "Moderate"),
    PLANK(3, 1, 30, "Core stability"),
])]
def _med_safe_cardio(): return [workout("Medication-Safe Cardio", "cardio", 30, [
    cardio_ex("Walking", 1200, "20 min moderate pace"),
    BODYWEIGHT_SQUAT(2, 12, 30, "Light"), GLUTE_BRIDGE(2, 12, 30, "Gentle"),
    PLANK(2, 1, 30, "Hold 20 sec"),
])]
def _muscle_recovery(): return [workout("Muscle Recovery Protocol", "strength", 35, [
    GOBLET_SQUAT(3, 10, 60, "Moderate"), DB_BENCH(3, 10, 60, "Moderate"),
    DB_ROW(3, 10, 60, "Moderate"), DB_OHP(3, 10, 60, "Light"),
    GLUTE_BRIDGE(3, 12, 30, "Bodyweight"),
])]
def _bone_density(): return [workout("Bone Density on GLP-1", "strength", 35, [
    BARBELL_SQUAT(3, 8, 120, "Weight-bearing"), STEP_UP(3, 10, 60, "Per leg"),
    BARBELL_OHP(3, 8, 90, "Overhead loading"), CALF_RAISE(3, 15, 30, "Impact loading"),
    PLANK(3, 1, 30, "Core"),
])]
def _post_med(): return [workout("Post-Medication Transition", "strength", 35, [
    BARBELL_SQUAT(3, 8, 120, "Rebuild strength"), BARBELL_BENCH(3, 8, 120, "Progressive"),
    BARBELL_ROW(3, 8, 120, "Compound"), RDL(3, 10, 90, "Posterior chain"),
])]
def _lean_mass(): return [workout("Lean Mass Building", "strength", 45, [
    BARBELL_SQUAT(4, 8, 150, "Hypertrophy"), BARBELL_BENCH(4, 8, 120, "Hypertrophy"),
    BARBELL_ROW(4, 8, 120, "Hypertrophy"), DB_OHP(3, 10, 60, "Volume"),
    DB_CURL(3, 12, 45, "Volume"), TRICEP_PUSHDOWN(3, 12, 45, "Volume"),
])]
def _metabolism_rebuild(): return [workout("Metabolism Rebuild", "strength", 35, [
    GOBLET_SQUAT(3, 12, 60, "Moderate"), PUSHUP(3, 12, 30, "Bodyweight"),
    DB_ROW(3, 10, 60, "Moderate"), GLUTE_BRIDGE(3, 15, 30, "Bodyweight"),
    cardio_ex("Brisk Walk", 600, "10 min"),
])]
def _sustainable_move(): return [workout("Sustainable Movement", "strength", 30, [
    BODYWEIGHT_SQUAT(3, 15, 30, "Daily habit"), PUSHUP(3, 10, 30, "Consistent"),
    GLUTE_BRIDGE(3, 12, 30, "Bodyweight"), PLANK(3, 1, 30, "Hold 20 sec"),
    cardio_ex("Walking", 600, "10 min"),
])]

# === FACE/JAW (8) ===
def _under_eye(): return [workout("Under Eye Exercises", "flexibility", 10, [
    face_ex("Under Eye Squeeze", 15, "Gently squeeze eyes shut, hold 3 sec, release", "Eye Circles"),
    face_ex("Eye Circles", 10, "Roll eyes clockwise then counterclockwise slowly", "Under Eye Squeeze"),
    face_ex("Brow Lift", 10, "Raise eyebrows high, hold 5 sec, release", "Forehead Smoothing"),
    face_ex("Temple Massage", 10, "Circular pressure on temples with fingertips", "Eye Circles"),
])]
def _forehead(): return [workout("Forehead Smoothing", "flexibility", 10, [
    face_ex("Forehead Resistance", 15, "Place fingers on forehead, try to raise brows against resistance", "Brow Lift"),
    face_ex("Brow Furrow Release", 10, "Pinch and smooth between brows outward", "Forehead Massage"),
    face_ex("Surprise Hold", 10, "Wide eyes, raised brows, hold 10 sec", "Brow Lift"),
])]
def _cheek_lift(): return [workout("Cheek Lifting", "flexibility", 10, [
    face_ex("Cheek Puff", 15, "Puff air side to side, hold each 5 sec", "Fish Face"),
    face_ex("Smile Lift", 15, "Smile wide, press fingers on cheeks, push up", "Cheek Puff"),
    face_ex("Fish Face", 15, "Suck cheeks in, try to smile, hold 5 sec", "Smile Lift"),
])]
def _neck_firm(): return [workout("Neck Firming", "flexibility", 12, [
    face_ex("Neck Tilt Stretch", 10, "Tilt head back, push tongue to roof of mouth, swallow", "Chin Tuck"),
    face_ex("Jaw Jut", 10, "Push lower jaw forward, hold, feel neck stretch", "Neck Tilt"),
    face_ex("Platysma Tone", 15, "Open mouth wide, pull corners down, feel neck bands tense", "Neck Stretch"),
    CHIN_TUCK(),
])]
def _facial_sym(): return [workout("Facial Symmetry", "flexibility", 12, [
    face_ex("One-Sided Smile", 10, "Smile on one side only, alternate, per side", "Smile Lift"),
    face_ex("Eye Wink Hold", 10, "Wink and hold each side 5 sec, per side", "Eye Squeeze"),
    face_ex("Cheek Push", 10, "Push tongue into each cheek alternately", "Cheek Puff"),
    face_ex("Jaw Shift", 10, "Shift jaw left and right slowly", "Jaw Jut"),
])]
def _mewing(): return [workout("Mewing & Posture", "flexibility", 15, [
    face_ex("Mewing Hold", 5, "Press entire tongue to roof of mouth, hold 60 sec", "Tongue Press"),
    face_ex("Chin Tuck", 10, "Pull chin straight back, hold 5 sec", "Neck Retraction"),
    WALL_ANGEL(), CHIN_TUCK(),
    ex("Posture Reset", 3, 10, 15, "Stand against wall, all contact points", "Bodyweight", "Back",
       "Posture", ["Core"], "beginner", "Head, shoulders, hips, heels touch wall", "Wall Stand"),
])]
def _gua_sha(): return [workout("Facial Gua Sha Flow", "flexibility", 15, [
    face_ex("Jaw Line Sweep", 10, "Sweep gua sha tool from chin to ear", "Jaw Massage"),
    face_ex("Cheek Sculpt", 10, "Sweep from nose to ear along cheekbone", "Cheek Massage"),
    face_ex("Forehead Sweep", 10, "Sweep from center of forehead outward", "Forehead Massage"),
    face_ex("Under Eye Sweep", 8, "Gentle sweeps from inner to outer corner", "Eye Massage"),
    face_ex("Neck Drainage", 10, "Sweep down sides of neck to collarbone", "Neck Massage"),
])]
def _complete_face(): return [workout("Complete Face Workout", "flexibility", 15, [
    face_ex("Forehead Lift", 15, "Raise brows against finger resistance"),
    face_ex("Eye Squeeze", 15, "Squeeze eyes shut tight, hold 5 sec"),
    face_ex("Cheek Puff", 15, "Puff air side to side"),
    face_ex("Smile Lift", 15, "Wide smile with finger resistance"),
    face_ex("Jaw Opener", 10, "Open mouth wide, hold, close slowly"),
    face_ex("Neck Tilt", 10, "Tilt head back, push tongue up"),
    face_ex("Platysma Flex", 10, "Open mouth, pull corners down"),
])]

# === STRONGMAN (5) ===
def _atlas_stone(): return [workout("Atlas Stone Training", "strength", 50, [
    DEADLIFT(5, 3, 240, "Heavy conventional"),
    ex("Atlas Stone Lift", 5, 3, 180, "Work up to heavy", "Atlas Stone", "Full Body",
       "Posterior Chain", ["Biceps", "Core", "Chest"], "advanced",
       "Scoop stone, chest wrap, stand with extension", "Trap Bar Deadlift"),
    BARBELL_SQUAT(3, 5, 180, "Front squat option"), BARBELL_ROW(3, 8, 120, "Upper back"),
    FARMER_WALK(3, 1, 60, "Heavy, 50 yards"),
])]
def _log_press(): return [workout("Log Press Training", "strength", 50, [
    BARBELL_OHP(5, 3, 180, "Heavy strict press"),
    ex("Log Clean & Press", 5, 3, 180, "Technique focus", "Log", "Full Body",
       "Shoulders", ["Triceps", "Core", "Legs"], "advanced",
       "Clean to chest, neutral grip, drive with legs and press", "Push Press"),
    INCLINE_BENCH(3, 8, 90, "Lockout strength"), DB_OHP(3, 10, 60, "Volume"),
    TRICEP_PUSHDOWN(3, 12, 45, "Lockout assistance"),
])]
def _functional_athlete(): return [workout("Functional Athlete", "conditioning", 50, [
    DEADLIFT(4, 5, 180, "Moderate-heavy"), BARBELL_SQUAT(4, 5, 180, "Moderate-heavy"),
    FARMER_WALK(3, 1, 60, "Heavy"), SLED_PUSH(3, 1, 90, "Moderate"),
    PULLUP(3, 8, 60, "Strict"), KETTLEBELL_SWING(3, 15, 45, "Conditioning"),
])]
def _power_builder(): return [
    workout("Power Day", "strength", 55, [
        BARBELL_SQUAT(5, 3, 240, "Heavy singles/triples"),
        BARBELL_BENCH(5, 3, 240, "Heavy"), DEADLIFT(3, 3, 300, "Heavy"),
    ]),
    workout("Hypertrophy Day", "hypertrophy", 55, [
        BARBELL_SQUAT(3, 10, 90, "60-70% of max"), BARBELL_BENCH(3, 10, 90, "Moderate"),
        BARBELL_ROW(3, 10, 90, "Moderate"), DB_OHP(3, 12, 60, "Volume"),
        DB_CURL(3, 12, 45, "Volume"), TRICEP_PUSHDOWN(3, 12, 45, "Volume"),
    ]),
]
def _grip_strength(): return [workout("Grip Strength", "strength", 35, [
    FARMER_WALK(4, 1, 60, "Heavy, 40 yards"),
    ex("Plate Pinch Hold", 3, 1, 60, "Hold 30 seconds", "Barbell Plate", "Forearms",
       "Grip", ["Forearms"], "intermediate", "Pinch two plates together, hold", "Towel Hang"),
    DEADLIFT(3, 5, 180, "Double overhand, no straps"),
    ex("Towel Pull-Up", 3, 5, 120, "Drape towel over bar", "Bodyweight", "Back",
       "Grip", ["Latissimus Dorsi", "Biceps"], "advanced", "Grip towel instead of bar", "Pull-Up"),
    ex("Wrist Curl", 3, 15, 30, "Light barbell", "Barbell", "Forearms",
       "Wrist Flexors", ["Forearms"], "beginner", "Forearms on bench, curl wrist up", "Reverse Wrist Curl"),
])]

# === HELL MODE (5) ===
def _exhaust_core(): return [workout("EXHAUST ME - Core", "conditioning", 45, [
    HANGING_LEG_RAISE(4, 15, 30, "No rest between sets"),
    PLANK(3, 1, 15, "Hold 60 sec"), RUSSIAN_TWIST(3, 30, 15, "Weighted"),
    BICYCLE_CRUNCH(3, 30, 15, "Non-stop"), MOUNTAIN_CLIMBER(3, 40, 10, "Sprint pace"),
    SIDE_PLANK(2, 1, 15, "Hold 45 sec per side"),
    ex("Ab Wheel Rollout", 3, 12, 30, "Full extension", "Ab Wheel", "Core",
       "Rectus Abdominis", ["Obliques", "Shoulders"], "advanced",
       "Full extension, control the eccentric", "Plank"),
])]
def _spartan(): return [workout("Spartan Challenge", "conditioning", 60, [
    BURPEE(5, 20, 30, "Non-negotiable"), PULLUP(5, 10, 30, "Strict"),
    PUSHUP(5, 20, 15, "No rest"), BODYWEIGHT_SQUAT(5, 30, 15, "Deep"),
    MOUNTAIN_CLIMBER(5, 30, 10, "Sprint"), FARMER_WALK(3, 1, 60, "Heavy, 100 yards"),
])]
def _navy_seal(): return [workout("Navy SEAL Inspired", "conditioning", 60, [
    cardio_ex("Run", 1200, "20 min steady"), PUSHUP(5, 20, 15, "No break"),
    PULLUP(5, 10, 30, "Strict"), BODYWEIGHT_SQUAT(5, 25, 15, "Fast"),
    BURPEE(3, 15, 20, "Full"), PLANK(3, 1, 15, "Hold 60 sec"),
    FLUTTER_KICK(), SUPERMAN(3, 20, 15, "Fast"),
])]
def _prison_yard(): return [workout("Prison Yard", "conditioning", 45, [
    PUSHUP(10, 10, 15, "Descending ladder: 10,9,8...1"),
    BODYWEIGHT_SQUAT(5, 30, 20, "Deep, fast"),
    BURPEE(5, 10, 20, "Full"), DIP(5, 15, 20, "On bench or parallel bars"),
    PLANK(3, 1, 15, "Hold 60 sec"),
])]
def _murph(): return [workout("Murph Prep", "conditioning", 60, [
    cardio_ex("Run", 600, "Half-mile run"),
    PULLUP(10, 10, 20, "Partition: 10 rounds of 10"),
    PUSHUP(10, 20, 10, "10 rounds of 20"),
    BODYWEIGHT_SQUAT(10, 30, 10, "10 rounds of 30"),
    cardio_ex("Run", 600, "Half-mile run"),
])]

FLUTTER_KICK = lambda: ex("Flutter Kicks", 3, 30, 15, "Per side", "Bodyweight", "Core",
    "Lower Abs", ["Hip Flexors"], "beginner",
    "Lie back, legs 6 inches off floor, alternate kicks", "Lying Leg Raise")


###############################################################################
# BATCH_WORKOUTS - Maps program names to workout generators
###############################################################################

BATCH_WORKOUTS = {
    # Hybrid (11)
    "Run + Lift Hybrid": _run_lift, "Swim + Strength": _swim_strength,
    "Yoga + Strength": _yoga_strength, "Boxing + Strength": _boxing_strength,
    "Cycling + Weights": _cycling_weights, "HIIT + Strength": _hiit_strength,
    "Endurance + Power": _endurance_power, "CrossFit Hybrid": _crossfit_hybrid,
    "Martial Arts + Weights": _martial_arts_weights, "Calisthenics + Weights": _calisthenics_weights,
    "Sport + Gym": _sport_gym,
    # Competition (11)
    "Marathon Prep": _marathon, "Half Marathon Prep": _half_marathon,
    "Triathlon Prep": _triathlon, "Tough Mudder Prep": _tough_mudder,
    "CrossFit Games Prep": _crossfit_games, "Boxing Match Prep": _boxing_match,
    "MMA Fight Prep": _mma_fight, "Wrestling Prep": _wrestling,
    "Track & Field Prep": _track_field, "Swimming Meet Prep": _swim_meet,
    "Cycling Race Prep": _cycling_race,
    # Nervous System (11)
    "Vagus Nerve Activation": _vagus_nerve, "Somatic Movement": _somatic_movement,
    "Trauma Release Exercises": _trauma_release, "Polyvagal Exercises": _polyvagal,
    "Body Awareness Practice": _body_awareness, "Tension Release": _tension_release,
    "Grounding Movement": _grounding, "Shake & Release": _shake_release,
    "Nervous System Recovery": _nervous_recovery, "Interoception Training": _interoception,
    "Embodiment Practice": _embodiment,
    # Weighted Accessories (16)
    "Weighted Vest Walking": _vest_walk, "Weighted Vest HIIT": _vest_hiit,
    "Weighted Vest Strength": _vest_strength, "Ankle Weight Sculpt": _ankle_sculpt,
    "Wrist Weight Cardio": _wrist_cardio, "Weighted Hula Hoop": _hula_hoop,
    "Mini Stepper Cardio": _mini_stepper, "Vibration Plate Training": _vibration_plate,
    "Rucking for Beginners": _rucking, "Weighted Vest Training": _vest_training,
    "Ankle Weight Workout": _ankle_weight_workout, "Wrist Weight Workout": _wrist_weight_workout,
    "Weighted Walking": _weighted_walking, "Hip Circle Band": _hip_circle_band,
    "Mini Band Workout": _mini_band, "Slam Ball Training": _slam_ball,
    # Home Workout (16)
    "EPIC Progressive Strength": _epic_strength, "Quick Results Shred": _quick_shred,
    "Daily Variety Training": _daily_variety, "Skills-Based Calisthenics": _skills_calisthenics,
    "Balanced Home Training": _balanced_home, "Accessible Yoga Journey": _yoga_journey,
    "Celebrity Trainer Variety": _celeb_trainer, "No-Nonsense Home Workouts": _no_nonsense,
    "Beginner Home YouTube": _beginner_home_yt, "30-Day Home Challenge": _thirty_day_challenge,
    "No Equipment YouTube": _no_equip, "Apartment Friendly": _apartment_friendly,
    "Small Space Workout": _small_space, "Minimal Noise Workout": _minimal_noise,
    "Follow Along Strength": _follow_strength, "Follow Along Cardio": _follow_cardio,
    # Outdoor (8)
    "Mountain Hiking Training": _hiking, "Urban Exploration Fitness": _urban_explore,
    "Trail Running Prep": _trail_run, "Outdoor Bootcamp": _outdoor_boot,
    "Kayaking Dryland": _kayak_dry, "Surfing Prep": _surfing,
    "Snow Sport Prep": _snow_sport, "Adventure Race Prep": _adventure_race,
    # Longevity (9)
    "Heat Exposure Training": _heat_exposure, "VO2 Max Training": _vo2_max,
    "Joint Longevity": _joint_longevity, "Spine Health": _spine_health,
    "Brain-Body Connection": _brain_body, "Anti-Aging Movement": _anti_aging_move,
    "Hormesis Training": _hormesis, "Fascia Training": _fascia,
    "Autophagy Workout": _autophagy,
    # Seasonal (9)
    "Cold Weather Fitness": _cold_weather, "Monsoon Indoor Training": _monsoon,
    "Winter Maintenance": _winter_maint, "Spring Fitness Kickoff": _spring_kick,
    "Fall Training Peak": _fall_peak, "Humidity Adaptation": _humidity,
    "Altitude Training Prep": _altitude, "Indoor Winter Alternative": _indoor_winter,
    "Year-Round Outdoor": _year_round,
    # Social Fitness (8)
    "Run Club Ready": _run_club, "Couples Fitness": _couples,
    "Group Class Ready": _group_class, "Accountability Partner Plan": _accountability,
    "Social Walking Group": _social_walk, "Gym Buddy Workouts": _gym_buddy,
    "Virtual Group Training": _virtual_group, "Team Sport Fitness": _team_sport,
    # Fat Loss / GLP-1 (8)
    "Ozempic Body Recomp": _ozempic_recomp, "Medication-Safe Cardio": _med_safe_cardio,
    "Muscle Recovery Protocol": _muscle_recovery, "Bone Density on GLP-1": _bone_density,
    "Post-Medication Transition": _post_med, "Lean Mass Building": _lean_mass,
    "Metabolism Rebuild": _metabolism_rebuild, "Sustainable Movement": _sustainable_move,
    # Face/Jaw (8)
    "Under Eye Exercises": _under_eye, "Forehead Smoothing": _forehead,
    "Cheek Lifting": _cheek_lift, "Neck Firming": _neck_firm,
    "Facial Symmetry": _facial_sym, "Mewing & Posture": _mewing,
    "Facial Gua Sha Flow": _gua_sha, "Complete Face Workout": _complete_face,
    # Strongman (5)
    "Atlas Stone Training": _atlas_stone, "Log Press Training": _log_press,
    "Functional Athlete": _functional_athlete, "Power Builder": _power_builder,
    "Grip Strength": _grip_strength,
    # Hell Mode (5)
    "EXHAUST ME - Core": _exhaust_core, "Spartan Challenge": _spartan,
    "Navy SEAL Inspired": _navy_seal, "Prison Yard": _prison_yard,
    "Murph Prep": _murph,
}
