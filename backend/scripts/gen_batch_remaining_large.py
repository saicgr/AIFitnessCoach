#!/usr/bin/env python3
"""Generate remaining programs across multiple categories - large batch."""
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

# Generic workout templates by type
def strength_full():
    return wo("Full Body Strength", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 90, "70-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, chest up, drive through heels", "Goblet Squat"),
        ex("Barbell Bench Press", 4, 8, 90, "70-80% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch chest, drive up, arch back slightly", "Dumbbell Press"),
        ex("Barbell Row", 3, 10, 60, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull to lower chest", "Dumbbell Row"),
        ex("Overhead Press", 3, 8, 60, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Strict press, full lockout", "Dumbbell Press"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, feel hamstring stretch", "Single-Leg RDL"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line, tight core", "Forearm Plank"),
    ])

def hiit_circuit():
    return wo("HIIT Circuit", "hiit", 25, [
        ex("Burpee", 3, 10, 30, "Maximum effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, explosive jump", "Squat Thrust"),
        ex("Kettlebell Swing", 3, 15, 30, "Moderate KB", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap, float KB to eye level", "Dumbbell Swing"),
        ex("Box Jump", 3, 8, 30, "20-24 inch", "Plyo Box", "Legs", "Quadriceps", ["Calves"], "intermediate", "Explosive jump, soft landing", "Squat Jump"),
        ex("Battle Rope Slam", 3, 20, 30, "Alternating arms", "Battle Ropes", "Full Body", "Shoulders", ["Core"], "intermediate", "Alternate arms rapidly", "Medicine Ball Slam"),
        ex("Mountain Climber", 3, 20, 30, "Quick pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders"], "beginner", "Rapid alternating knees", "High Knees"),
    ])

def cardio_session():
    return wo("Cardio Session", "conditioning", 30, [
        ex("Jumping Jacks", 3, 30, 20, "Moderate pace", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full arm extension, land soft", "Step Jacks"),
        ex("High Knees", 3, 30, 20, "Fast pace", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees high, quick arms", "Marching"),
        ex("Squat Jump", 3, 12, 30, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, max height", "Bodyweight Squat"),
        ex("Mountain Climber", 3, 20, 20, "Sprint pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders"], "beginner", "Quick alternating", "Plank Knee Tuck"),
        ex("Butt Kicks", 3, 30, 20, "Quick pace", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Kick heels to glutes", "Jog in Place"),
        ex("Burpee", 3, 8, 30, "Full burpee", "Bodyweight", "Full Body", "Quadriceps", ["Chest"], "intermediate", "Chest to floor, jump up", "Squat Thrust"),
    ])

def mobility_session():
    return wo("Mobility Session", "flexibility", 20, [
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("World's Greatest Stretch", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine"], "beginner", "Lunge, rotate, reach", "Spiderman Stretch"),
        ex("Hip Circle", 2, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Big circles", "Standing Hip Rotation"),
        ex("Shoulder Circle", 2, 10, 0, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Progressive range", "Arm Circle"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 45 seconds each", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Child's Pose", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Knees wide, reach forward", "Puppy Pose"),
    ])

def bodyweight_session():
    return wo("Bodyweight Session", "strength", 30, [
        ex("Push-up", 3, 12, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Elbows 45 degrees, full range", "Knee Push-up"),
        ex("Bodyweight Squat", 3, 15, 30, "Full depth", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Chest up, full depth", "Chair Squat"),
        ex("Pull-up", 3, 8, 45, "Or inverted row", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full dead hang to chin over", "Inverted Row"),
        ex("Lunge", 3, 10, 30, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, upright torso", "Step-up"),
        ex("Dip", 3, 8, 30, "Parallel bars or bench", "Dip Station", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Full depth, lean forward slightly", "Bench Dip"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line head to heels", "Forearm Plank"),
    ])

def gentle_session():
    return wo("Gentle Movement", "flexibility", 20, [
        ex("Seated Marching", 2, 20, 15, "Gentle pace", "Chair", "Legs", "Hip Flexors", ["Core"], "beginner", "Lift knees alternately while seated", "Standing March"),
        ex("Shoulder Roll", 2, 10, 0, "Forward and backward", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Slow controlled circles", "Arm Circle"),
        ex("Seated Cat-Cow", 2, 8, 0, "Seated version", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Arch and round while seated", "Cat-Cow"),
        ex("Ankle Circle", 2, 10, 0, "Each direction each foot", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Full range of motion", "Ankle Pump"),
        ex("Neck Stretch", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear to shoulder, gentle", "Neck Roll"),
        ex("Deep Breathing", 2, 5, 0, "Diaphragmatic breathing", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "4 count in, 6 count out", "Box Breathing"),
    ])

def quick_pump():
    return wo("Quick Pump", "strength", 15, [
        ex("Push-up", 3, 12, 15, "Quick tempo", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range, fast", "Knee Push-up"),
        ex("Bodyweight Squat", 3, 15, 15, "Quick tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, fast", "Chair Squat"),
        ex("Plank", 2, 1, 15, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core", "Forearm Plank"),
        ex("Reverse Lunge", 3, 10, 15, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Step back, knee hovers", "Step Back"),
    ])

# Massive program list - using templates with appropriate categories
all_programs = []

# Cat 27 - HIIT (18 programs)
for name, pri in [("Tabata Protocol", "High"), ("EMOM Training", "High"), ("AMRAP Workouts", "High"),
                  ("Interval Running", "Med"), ("Cycling Intervals", "Med"), ("Boxing Intervals", "Med"),
                  ("Rowing Intervals", "Med"), ("Mixed Modal Intervals", "Med"),
                  ("Sprint Interval Training", "Low"), ("Norwegian 4x4", "Low"), ("Death By... Protocol", "Low"),
                  ("Ladder Workouts", "Low"), ("Metcon Madness", "Low"), ("AQAP Training", "Low"),
                  ("Alternating EMOM", "Low"), ("Cardio HIIT Fusion", "High"), ("Strength HIIT", "High"),
                  ("EPOC Maximizer", "Low")]:
    all_programs.append((name, "Interval/HIIT", [2, 4, 8], [3, 4, 5], pri, f"{name} - high intensity interval training program",
                         lambda w, t: [hiit_circuit()] * 5))

# Cat 28 - Rehab (11 programs)
for name, pri in [("Lower Back Rehab", "High"), ("Shoulder Rehab", "High"), ("Knee Rehab", "High"),
                  ("Hip Rehab", "Med"), ("Ankle Stability", "Med"), ("Post-Surgery Return", "Med"),
                  ("Injury Prevention", "Med"), ("Chronic Pain Management", "Med"),
                  ("Desk Worker Rehab", "Low"), ("Foam Rolling & Release", "Low"), ("Neck Pain Relief", "Low")]:
    all_programs.append((name, "Rehab & Recovery", [2, 4, 8], [3, 4], pri, f"{name} - rehabilitation and recovery program",
                         lambda w, t: [gentle_session()] * 4))

# Cat 35 - Cardio (12 programs)
for name, pri in [("Pure Cardio Burn", "High"), ("Cardio Endurance Builder", "High"), ("Low Impact Cardio", "High"),
                  ("High Impact Cardio", "Med"), ("Steady State Cardio", "Med"), ("Jump Rope Cardio", "Med"),
                  ("Elliptical Training", "Med"), ("Treadmill Variety", "Med"),
                  ("Cardio Kickboxing", "Low"), ("Step Aerobics", "Low"), ("Cardio Circuit", "Low"), ("Power Walking", "Low")]:
    all_programs.append((name, "Cardio & Conditioning", [2, 4, 8], [3, 4, 5], pri, f"{name} - cardiovascular conditioning program",
                         lambda w, t: [cardio_session()] * 5))

# Cat 36 - Strongman (9 programs)
for name, pri in [("Strongman Basics", "High"), ("Farmer's Walk Mastery", "High"), ("Odd Object Training", "High"),
                  ("Atlas Stone Prep", "Med"), ("Yoke Walk Training", "Med"), ("Tire Flip Conditioning", "Med"),
                  ("Sled Push/Pull", "Med"), ("Grip Strength Specialist", "Med"), ("Functional Farm Fitness", "Low")]:
    all_programs.append((name, "Strongman/Functional", [4, 8, 12], [3, 4], pri, f"{name} - strongman and functional strength program",
                         lambda w, t: [strength_full()] * 4))

# Cat 37 - Lifestyle/Outdoor (15 programs)
for name, pri in [("Dog Walking Fitness", "High"), ("Running with Dogs", "High"), ("Dog Park Workout", "High"),
                  ("Hiking Fitness Prep", "Med"), ("Trail Running", "Med"), ("Mountain Hiking", "Med"),
                  ("Nature Walk Cardio", "Med"), ("Beach Workout", "Med"),
                  ("Outdoor Adventure Fitness", "Low"), ("Nordic Walking", "Low"), ("Sunrise/Sunset Cardio", "Low"),
                  ("Urban Explorer Fitness", "Low"), ("Outdoor Calisthenics", "Low"), ("Cycling Commuter Fitness", "Low"),
                  ("Kayak/Paddle Prep", "Low")]:
    all_programs.append((name, "Lifestyle/Outdoor Cardio", [2, 4, 8], [3, 4, 5], pri, f"{name} - outdoor lifestyle fitness program",
                         lambda w, t: [cardio_session()] * 5))

# Cat 38 - Longevity (13 programs)
for name, pri in [("Zone 2 Training Protocol", "High"), ("Longevity Fitness", "High"), ("Cold Exposure Prep", "High"),
                  ("Heat Adaptation Training", "Med"), ("Anti-Aging Fitness", "Med"), ("Mitochondrial Health", "Med"),
                  ("Autophagy-Promoting Exercise", "Med"), ("Circadian Rhythm Training", "Med"),
                  ("VO2 Max Longevity", "Low"), ("Grip-to-Lifespan Training", "Low"), ("Brain Health Fitness", "Low"),
                  ("Blue Zone Inspired", "Low"), ("Telomere-Friendly Fitness", "Low")]:
    all_programs.append((name, "Longevity & Biohacking", [4, 8, 12], [3, 4, 5], pri, f"{name} - longevity and biohacking fitness program",
                         lambda w, t: [cardio_session(), mobility_session(), strength_full(), cardio_session(), mobility_session()]))

# Cat 39 - GLP-1 (10 programs)
for name, pri in [("GLP-1 Muscle Preservation", "High"), ("Ozempic-Safe Strength", "High"), ("Post-GLP-1 Maintenance", "High"),
                  ("Medication + Movement", "Med"), ("GLP-1 Energy Builder", "Med"), ("Protein-Priority Training", "Med"),
                  ("Metabolic Reset After Meds", "Med"), ("Tirzepatide Fitness Plan", "Med"),
                  ("Semaglutide Strength", "Low"), ("Weight Loss Drug Transition", "Low")]:
    all_programs.append((name, "GLP-1/Weight Loss Medication", [4, 8, 12], [3, 4], pri, f"{name} - fitness program supporting weight loss medication users",
                         lambda w, t: [strength_full(), cardio_session(), strength_full(), cardio_session()]))

# Cat 40 - Balance (12 programs)
for name, pri in [("Balance Foundations", "High"), ("Single Leg Mastery", "High"), ("Proprioception Training", "High"),
                  ("Vestibular System Training", "Med"), ("Bosu Ball Mastery", "Med"), ("Balance for Athletes", "Med"),
                  ("Fall Prevention Advanced", "Low"), ("Stability Challenge", "Med"),
                  ("Eyes Closed Training", "Low"), ("Reactive Balance", "Low"), ("Balance Board Progression", "Low"),
                  ("Core + Balance Integration", "Low")]:
    all_programs.append((name, "Balance & Proprioception", [2, 4, 8], [3, 4], pri, f"{name} - balance and proprioception training program",
                         lambda w, t: [mobility_session()] * 4))

# Cat 41 - Hybrid (11 programs)
for name, pri in [("Strength + Cardio Hybrid", "High"), ("Concurrent Training", "High"), ("CrossTraining Essentials", "High"),
                  ("Strength-Endurance Blend", "Med"), ("Metabolic Strength", "Med"), ("Cardio Lifting", "Med"),
                  ("Powerbuilding", "Med"), ("Tactical Hybrid", "Med"),
                  ("Sport Hybrid Training", "Low"), ("Strength-Yoga Fusion", "Low"), ("HIIT + Strength Combo", "High")]:
    all_programs.append((name, "Hybrid Training", [4, 8, 12], [4, 5], pri, f"{name} - hybrid training combining multiple modalities",
                         lambda w, t: [strength_full(), hiit_circuit(), strength_full(), hiit_circuit(), cardio_session()]))

# Cat 42 - Competition (14 programs)
for name, pri in [("Spartan Race Prep", "High"), ("Tough Mudder Ready", "High"), ("Ragnar Relay Prep", "High"),
                  ("Color Run Training", "Med"), ("Warrior Dash Prep", "Med"), ("GoRuck Challenge Prep", "Med"),
                  ("Deka Fit Training", "Med"), ("CrossFit Open Prep", "Med"),
                  ("Powerlifting Meet Prep", "Low"), ("Bodybuilding Show Prep", "Low"), ("Physique Competition Prep", "Low"),
                  ("Bikini Competition Prep", "Low"), ("Strongman Competition Prep", "Low"), ("Local 5K Race Prep", "Low")]:
    all_programs.append((name, "Competition/Race Prep", [4, 8, 12], [4, 5, 6], pri, f"{name} - competition and race preparation program",
                         lambda w, t: [strength_full(), hiit_circuit(), cardio_session(), strength_full(), hiit_circuit(), cardio_session()]))

# Cat 47 - Medical (11 programs)
for name, pri in [("Diabetes-Friendly Fitness", "High"), ("Heart Condition Safe", "High"), ("Hypertension Management", "High"),
                  ("Asthma-Safe Exercise", "Med"), ("Autoimmune Gentle", "Med"), ("Thyroid Support Training", "Med"),
                  ("Fibromyalgia Movement", "Med"), ("Chronic Fatigue Gentle", "Med"),
                  ("Lymphedema Exercise", "Low"), ("Cancer Survivor Fitness", "Low"), ("Dialysis Patient Fitness", "Low")]:
    all_programs.append((name, "Medical Condition Specific", [4, 8, 12], [3, 4], pri, f"{name} - safe exercise program for specific medical conditions",
                         lambda w, t: [gentle_session()] * 4))

# Cat 48 - Desk Break (14 programs)
for name, pri in [("2-Minute Desk Breaks", "High"), ("Standing Desk Micro-Moves", "High"), ("Meeting Recovery", "High"),
                  ("Eye Strain Relief Exercises", "Med"), ("Hourly Movement Habit", "Med"), ("Wrist & Hand Desk Breaks", "Med"),
                  ("Neck & Shoulder Desk Relief", "Med"), ("Lower Body Desk Activation", "Med"),
                  ("Brain Break Movement", "Low"), ("Pomodoro Fitness", "Low"), ("Desk Warrior", "Low"),
                  ("Seated & Shredded", "High"), ("Cardio at Your Desk", "Low"), ("5-Minute Office Escape", "Low")]:
    all_programs.append((name, "Desk Break Micro-Workouts", [1, 2, 4], [5, 7], pri, f"{name} - micro-workout for desk workers",
                         lambda w, t: [gentle_session()] * 7))

# Cat 49 - Plyometrics (8 programs)
for name, pri in [("Plyometric Foundations", "High"), ("Box Jump Mastery", "High"), ("Explosive Power", "High"),
                  ("Depth Jump Training", "Med"), ("Reactive Strength", "Med"), ("Broad Jump Training", "Med"),
                  ("Medicine Ball Power", "Med"), ("Athletic Explosiveness", "Med")]:
    all_programs.append((name, "Plyometrics & Explosiveness", [2, 4, 8], [3, 4], pri, f"{name} - plyometric and explosive power training",
                         lambda w, t: [hiit_circuit()] * 4))

# Cat 50 - Olympic Lifting (10 programs)
for name, pri in [("Snatch Foundations", "High"), ("Clean & Jerk Basics", "High"), ("Olympic Lifting Beginner", "High"),
                  ("Olympic Lifting Intermediate", "Med"), ("Power Clean Focus", "Med"), ("Overhead Squat Mobility", "Med"),
                  ("Front Rack Mobility", "Med"), ("Olympic Lift Accessory", "Med"),
                  ("Weightlifting for Athletes", "Low"), ("Olympic Lifting Technique", "Low")]:
    all_programs.append((name, "Olympic Lifting", [4, 8, 12], [3, 4], pri, f"{name} - Olympic weightlifting program",
                         lambda w, t: [strength_full()] * 4))

# Cat 53 - Viral TikTok (17 programs)
for name, pri in [("6-6-6 Walking Challenge", "High"), ("Hot Girl Walk", "High"), ("Cozy Cardio", "High"),
                  ("Dead Hang Challenge", "Med"), ("Morning Jump 50", "Med"), ("Core 300 Challenge", "Med"),
                  ("Wall Sit Challenge", "Med"), ("Plank Challenge Viral", "Low"),
                  ("Two Week Shred Challenge", "High"), ("Progressive Home Strength", "Low"),
                  ("Music-Driven Silent Workout", "Low"), ("Gym Etiquette & Form Focus", "Low"),
                  ('"That Girl" Morning Routine', "Low"), ("Lazy Girl Workout", "Low"), ("Clean Girl Fitness", "Low"),
                  ("Soft Life Fitness", "Low"), ("Main Character Energy", "Low")]:
    all_programs.append((name, "Viral TikTok Programs", [1, 2, 4], [4, 5, 7], pri, f"{name} - viral fitness challenge",
                         lambda w, t: [bodyweight_session(), cardio_session(), bodyweight_session(), cardio_session(), bodyweight_session(), bodyweight_session(), cardio_session()]))

# Cat 54 - Nervous System (12 programs)
for name, pri in [("Somatic Release", "High"), ("Vagus Nerve Reset", "High"), ("Nervous System Regulation", "High"),
                  ("Somatic Shaking", "Med"), ("Polyvagal Exercise", "Med"), ("Anxiety Relief Somatic", "Med"),
                  ("Trauma-Informed Movement", "Med"), ("Cortisol Lowering Workout", "Med"),
                  ("Parasympathetic Activation", "Low"), ("Body Scan Movement", "Low"), ("Grounding Exercises", "Low"),
                  ("Emotional Release Fitness", "Low")]:
    all_programs.append((name, "Nervous System & Somatic", [2, 4, 8], [3, 4, 5], pri, f"{name} - nervous system regulation and somatic movement",
                         lambda w, t: [gentle_session(), mobility_session(), gentle_session(), mobility_session(), gentle_session()]))

# Cat 55 - Weighted Accessories (9 programs)
for name, pri in [("Weighted Vest Walking", "High"), ("Weighted Vest HIIT", "High"), ("Weighted Vest Strength", "High"),
                  ("Ankle Weight Sculpt", "Med"), ("Wrist Weight Cardio", "Med"), ("Weighted Hula Hoop", "Med"),
                  ("Mini Stepper Cardio", "Med"), ("Vibration Plate Training", "Med"), ("Rucking for Beginners", "High")]:
    all_programs.append((name, "Weighted Accessories", [2, 4, 8], [3, 4, 5], pri, f"{name} - weighted accessories fitness program",
                         lambda w, t: [cardio_session(), strength_full(), cardio_session(), strength_full(), cardio_session()]))

# Cat 56 - YouTube Home (8 programs)
for name, pri in [("EPIC Progressive Strength", "High"), ("Quick Results Shred", "High"), ("Daily Variety Training", "High"),
                  ("Skills-Based Calisthenics", "Med"), ("Balanced Home Training", "Med"), ("Accessible Yoga Journey", "Med"),
                  ("Celebrity Trainer Variety", "Low"), ("No-Nonsense Home Workouts", "Med")]:
    all_programs.append((name, "YouTube-Style Home Programs", [4, 8, 12], [4, 5, 6], pri, f"{name} - YouTube-style home workout program",
                         lambda w, t: [bodyweight_session(), hiit_circuit(), bodyweight_session(), hiit_circuit(), bodyweight_session(), cardio_session()]))

# Cat 57 - Influencer (12 programs)
for name, pri in [("Influencer Body Blueprint", "High"), ("Creator Aesthetic Training", "High"), ("Ring Light Ready", "High"),
                  ("Camera Confidence Workout", "Med"), ("Content Creator Energy", "Med"), ("Fitness Influencer Journey", "Med"),
                  ("Posing & Flexing Mastery", "Med"), ("Live Stream Workout Host", "Med"),
                  ("Social Media Body", "Low"), ("Side Hustle Fitness", "Low"), ("Before & After Transformation", "Low"),
                  ("Viral Physique Challenge", "Low")]:
    all_programs.append((name, "Content Creator/Influencer Fitness", [4, 8, 12], [4, 5], pri, f"{name} - content creator and influencer fitness program",
                         lambda w, t: [strength_full(), hiit_circuit(), strength_full(), hiit_circuit(), cardio_session()]))

# Cat 58 - Life Events (13 programs)
for name, pri in [("Pre-Wedding Fitness", "High"), ("Wedding Day Ready", "High"), ("Last-Minute Wedding Shred", "High"),
                  ("Engaged & Fit", "Med"), ("Honeymoon Body", "Med"), ("Pre-Parent Fitness", "Med"),
                  ("Couples Pre-Baby", "Med"),
                  ("New Dad Fitness", "Low"), ("New Mom Post-Baby", "Low"), ("First Year Parent", "Low"),
                  ("Baby & Me Workout", "Low"), ("Sleep-Deprived Parent", "Low"), ("Grandparent Fitness", "Low")]:
    all_programs.append((name, "Life Events & Milestones", [2, 4, 8, 12], [3, 4, 5], pri, f"{name} - milestone-specific fitness program",
                         lambda w, t: [strength_full(), cardio_session(), hiit_circuit(), strength_full(), cardio_session()]))

# Cat 59 - Community-Famous Lifting (18 programs)
for name, pri in [("Basic Barbell Beginner", "High"), ("Tiered Linear Progression", "High"),
                  ("AMRAP Linear Progression", "High"), ("Classic 5x5 Beginner", "High"), ("6-Day PPL Split", "High"),
                  ("High Volume 5/3/1 Variant", "Med"), ("Tier System Hypertrophy", "Med"), ("Tier System Peaking", "Med"),
                  ("Ultra High Frequency Training", "Low"), ("6-Week Powerlifting Peak", "Low"),
                  ("Upper Lower Linear", "Low"), ("Full Body Bodyweight Routine", "High"),
                  ("Bodyweight Primer", "Low"), ("Advanced Movement Skills", "Low"),
                  ("Power Hypertrophy Upper Lower", "Low"), ("Power Hypertrophy Adaptive", "Low"),
                  ("Mix & Match Strength", "Low"), ("Comprehensive Hypertrophy", "Low")]:
    all_programs.append((name, "Reddit-Famous Programs", [4, 8, 12], [3, 4, 5, 6], pri, f"{name} - community-famous lifting program",
                         lambda w, t: [strength_full(), strength_full(), strength_full(), strength_full(), strength_full(), strength_full()]))

# Cat 60 - Glute Building (14 programs)
for name, pri in [("Booty Basics", "High"), ("Glute Building Foundations", "High"), ("At-Home Booty Builder", "High"),
                  ("Resistance Band Glutes", "Med"), ("Advanced Glute Builder", "Low"),
                  ("Science-Based Glute Training", "Med"), ("Hip Thrust Specialization", "Low"), ("Peach Builder", "Med"),
                  ("Glutes & Abs Combo", "Low"), ("Lower Body Sculpt", "Low"), ("High Volume Glute Workout", "Low"),
                  ("Glute Activation Series", "Low"), ("Upper Glute Shelf Builder", "Low"), ("Glute-Ham Developer", "Low")]:
    all_programs.append((name, "Glute & Booty Building", [4, 8, 12], [3, 4, 5], pri, f"{name} - glute building and lower body sculpting",
                         lambda w, t: [strength_full()] * 5))

# Cat 61 - Turn Back Time (12 programs)
for name, pri in [("Time Machine Body", "High"), ("Look 10 Years Younger", "High"), ("Aging in Reverse", "High"),
                  ("Fountain of Youth", "Med"), ("Age Is Just a Number", "Med"), ("Move Like You're 20", "Med"),
                  ("Defy Gravity", "Med"), ("Glow Up at Any Age", "Med"),
                  ("Second Wind", "Low"), ("Better With Age", "Low"), ("Reverse the Clock", "Low"), ("Forever Young", "Low")]:
    all_programs.append((name, "Turn Back Time (Anti-Aging)", [4, 8, 12], [3, 4, 5], pri, f"{name} - anti-aging fitness program",
                         lambda w, t: [strength_full(), mobility_session(), cardio_session(), strength_full(), mobility_session()]))

# Cat 62 - Get to the Gym (12 programs)
for name, pri in [("Get to the F***in Gym - Upper", "High"), ("Get to the F***in Gym - Lower", "High"),
                  ("Get to the F***in Gym - Cardio", "High"), ("Get to the F***in Gym - Full Body", "High"),
                  ("Stop Making Excuses Already", "Med"), ("Just Show Up", "Med"), ("No More BS", "Med"),
                  ("Shut Up and Lift", "Med"),
                  ("Zero Excuses Zone", "Low"), ("Get Off the Couch NOW", "Low"), ("You've Got This", "Low"),
                  ("Make Yourself Proud", "Low")]:
    all_programs.append((name, "Get to the F***in Gym", [1, 2, 4], [3, 4, 5], pri, f"{name} - motivational no-excuses fitness program",
                         lambda w, t: [strength_full(), hiit_circuit(), strength_full(), hiit_circuit(), cardio_session()]))

# Cat 63 - Fur Baby (14 programs)
for name, pri in [("Puppy Parent Workout", "High"), ("Walk the Dog Gains", "High"), ("Cat Got Your Mat", "High"),
                  ("Small Pet Safe Zone", "Med"), ("Pet Parent Power Hour", "Med"), ("While They Nap", "Med"),
                  ("Chaos Coordinator Fitness", "Med"), ("Pet Playtime Gains", "Med"),
                  ("Fur & Fitness", "Low"), ("Cozy Pet Parent", "Low"), ("Pet Underfoot Training", "Low"),
                  ("Animal House Workout", "Low"), ("Paws & Planks", "Low"), ("Fit Pet Parent Life", "Low")]:
    all_programs.append((name, "Fur Baby Friendly Fitness", [2, 4, 8], [3, 4, 5], pri, f"{name} - pet-friendly fitness program",
                         lambda w, t: [bodyweight_session(), cardio_session(), bodyweight_session(), cardio_session(), bodyweight_session()]))

# Cat 64 - Ninja Mode (12 programs)
for name, pri in [("Ninja Mode", "High"), ("Zero Jump Cardio", "High"), ("Stealth Shred", "High"),
                  ("Apartment After Dark", "Med"), ("Don't Wake the Neighbors", "Med"), ("Whisper Workout", "Med"),
                  ("Floor-Friendly Fitness", "Med"), ("Library Mode", "Med"),
                  ("2AM Workout Club", "Low"), ("Tippy-Toe Gains", "Low"), ("Silent But Deadly", "Low"),
                  ("Stealth Mode Strength", "Low")]:
    all_programs.append((name, "Ninja Mode Home Workouts", [2, 4, 8], [3, 4, 5], pri, f"{name} - silent, apartment-friendly workout program",
                         lambda w, t: [bodyweight_session()] * 5))

# Cat 67 - Gym is Packed (12 programs)
for name, pri in [("Packed Gym Push", "High"), ("Packed Gym Pull", "High"), ("Shoulder Express", "High"),
                  ("Arm Blaster Express", "Med"), ("Packed Gym Legs", "Med"), ("Glute & Go", "Med"),
                  ("Leg Press Lightning", "Med"), ("Circuit Crusher", "Med"),
                  ("Dumbbell-Only Day", "Low"), ("Cable Corner Conquest", "Low"), ("Machine Medley", "Low"),
                  ("Bench & Beyond", "Low")]:
    all_programs.append((name, "Gym is Packed (Quick Sessions)", [1, 2, 4], [3, 4, 5], pri, f"{name} - quick gym workout when it's packed",
                         lambda w, t: [quick_pump(), strength_full(), quick_pump(), strength_full(), quick_pump()]))

# Cat 68 - Post-Meal (10 programs)
for name, pri in [("Digestive Walk", "High"), ("After-Meal Stretch", "High"), ("Food Coma Fighter", "High"),
                  ("Full Stomach Friendly", "Med"), ("Post-Feast Flow", "Med"), ("Thanksgiving Recovery", "Med"),
                  ("30-Min Post-Meal", "Med"), ("Upper Only (Post-Meal)", "Med"),
                  ("Standing Only Workout", "Low"), ("Gentle Gains", "Low")]:
    all_programs.append((name, "Post-Meal Movement", [1, 2, 4], [5, 7], pri, f"{name} - gentle post-meal movement program",
                         lambda w, t: [gentle_session()] * 7))

# Cat 69 - Fasted Workouts (15 programs)
for name, pri in [("16:8 Fasted Cardio", "High"), ("16:8 Fasted Strength", "High"), ("18:6 Fat Burner", "High"),
                  ("20:4 Warrior Workout", "Med"), ("OMAD Morning Burn", "Med"), ("OMAD Evening Session", "Med"),
                  ("OMAD Strength Protocol", "Med"), ("24-Hour Fast Workout", "Med"),
                  ("36-Hour Fast Movement", "Low"), ("48-Hour Fast Protocol", "Low"), ("72-Hour Fast Gentle", "Low"),
                  ("5-Day Fast Light Movement", "Low"), ("7-Day Fast Maintenance", "Low"), ("Extended Fast Yoga", "Low"),
                  ("Refeed Day Workout", "Low")]:
    all_programs.append((name, "Fasted Workouts", [2, 4, 8], [3, 4, 5], pri, f"{name} - fasted workout program",
                         lambda w, t: [cardio_session(), strength_full(), cardio_session(), strength_full(), cardio_session()]))

# Cat 70 - Quick Hit Sessions (20 programs)
for name, pri in [("Quick Upper Pump", "High"), ("Express Chest & Tris", "High"), ("Rapid Back & Bis", "High"),
                  ("Shoulder Blaster Quick", "Med"), ("Arm Day Express", "Med"), ("Quick Leg Day", "Med"),
                  ("Glute Express", "Med"), ("Quad Killer Quick", "Med"),
                  ("Hamstring & Glute Rapid", "Low"), ("Calf & Core Combo", "Low"), ("20-Minute Full Body", "High"),
                  ("30-Minute Total Body", "Low"), ("Express Compound Only", "Low"), ("Metabolic Quick Hit", "Low"),
                  ("Dumbbell Only Express", "Low"), ("15-Minute HIIT Blast", "High"), ("20-Minute Steady State", "Low"),
                  ("Tabata Express", "Low"), ("Jump Rope Quick Burn", "Low"), ("Stair Climber Sprint", "Low")]:
    all_programs.append((name, "Quick Hit Sessions", [1, 2, 4], [4, 5, 6], pri, f"{name} - quick hit session workout",
                         lambda w, t: [quick_pump()] * 6))

# Cat 71 - Mood Quick Hits (12 programs)
for name, pri in [("Anxious? Do This", "High"), ("Stressed? Do This", "High"), ("Angry? Do This", "High"),
                  ("Sad? Do This", "Med"), ("Low Energy? Do This", "Med"), ("Can't Sleep? Do This", "Med"),
                  ("Bad Day Burner Express", "Med"), ("Confidence Boost Quick", "Med"),
                  ("Overwhelmed Reset", "Low"), ("Breakup Burn Session", "Low"), ("Monday Motivation Hit", "Low"),
                  ("Sunday Scaries Soother", "Low")]:
    all_programs.append((name, "Mood Quick Hits", [1, 2, 4], [5, 7], pri, f"{name} - mood-based quick workout",
                         lambda w, t: [bodyweight_session(), gentle_session(), bodyweight_session(), gentle_session(), bodyweight_session(), gentle_session(), bodyweight_session()]))

# Cat 72 - Travel & Hotel (14 programs)
for name, pri in [("Hotel Gym Upper", "High"), ("Hotel Gym Lower", "High"), ("Hotel Gym Full Body", "High"),
                  ("Hotel Cardio Crusher", "Med"), ("Hotel Dumbbell Monster", "Med"), ("Airport Layover Workout", "Med"),
                  ("Hotel Room Bodyweight", "Med"), ("Resistance Band Travel", "Med"),
                  ("Jet Lag Recovery", "Low"), ("Airplane Seat Stretches", "Low"), ("Road Warrior Fitness", "Low"),
                  ("Conference Break Workout", "Low"), ("Red Eye Recovery", "Low"), ("Weekend Warrior Travel", "Low")]:
    all_programs.append((name, "Travel & Hotel Fitness", [1, 2, 4], [3, 4, 5], pri, f"{name} - travel and hotel workout program",
                         lambda w, t: [bodyweight_session(), cardio_session(), bodyweight_session(), cardio_session(), bodyweight_session()]))

# Cat 73 - Night Shift (14 programs)
for name, pri in [("Pre-Night Shift Activation", "High"), ("Pre-12 Hour Shift", "High"), ("Shift Worker Morning Routine", "High"),
                  ("Pre-Shift Energy Boost", "Med"), ("Post-Night Shift Wind Down", "Med"), ("Post-12 Hour Recovery", "Med"),
                  ("Day Sleep Prep", "Med"), ("Shift Worker Decompression", "Med"),
                  ("Rotating Shift Fitness", "Low"), ("Healthcare Worker Fitness", "Low"), ("First Responder Maintenance", "Low"),
                  ("Factory Shift Training", "Low"), ("3-Day On 4-Day Off Training", "Low"), ("Night Owl Gains", "Low")]:
    all_programs.append((name, "Night Shift & Shift Worker", [2, 4, 8], [3, 4, 5], pri, f"{name} - shift worker fitness program",
                         lambda w, t: [strength_full(), cardio_session(), bodyweight_session(), strength_full(), cardio_session()]))

# Cat 74 - Gamer (9 programs)
for name, pri in [("Esports Athlete Training", "High"), ("Pro Gamer Conditioning", "High"), ("Reaction Time Training", "High"),
                  ("Gamer Wrist & Hand Health", "Med"), ("Screen Break Stretches", "Med"),
                  ("Eye Strain Relief", "Med"), ("Couch to Controller Fit", "Med"),
                  ("Between Match Movement", "Low"), ("Streaming Setup Fitness", "Low")]:
    all_programs.append((name, "Gamer & Esports Fitness", [2, 4, 8], [4, 5], pri, f"{name} - gamer and esports fitness program",
                         lambda w, t: [gentle_session(), bodyweight_session(), gentle_session(), bodyweight_session(), gentle_session()]))

# Cat 75 - Cruise Ship (11 programs)
for name, pri in [("Cruise Gym Full Body", "High"), ("Cruise Gym Upper", "High"), ("Cruise Gym Lower", "High"),
                  ("Cruise Cardio Circuit", "Med"), ("Cabin Bodyweight", "Med"), ("Pool Aqua Fitness", "Med"),
                  ("Sunrise Deck Yoga", "Med"), ("Port Day Explorer", "Med"),
                  ("Shore Excursion Fitness", "Low"), ("Buffet Damage Control", "Low"), ("Sea Day Full Workout", "Low")]:
    all_programs.append((name, "Cruise Ship Fitness", [1, 2], [4, 5, 7], pri, f"{name} - cruise ship workout program",
                         lambda w, t: [strength_full(), cardio_session(), bodyweight_session(), mobility_session(), strength_full(), cardio_session(), bodyweight_session()]))

# Generate all
for prog_name, cat, durs, sessions_list, pri, desc, workout_fn in all_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP: {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation"
            elif p <= 0.66: focus = f"Week {w} - Build"
            else: focus = f"Week {w} - Peak"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: print(f"DONE: {prog_name}")

helper.close()
print("\n=== REMAINING LARGE BATCH COMPLETE ===")
