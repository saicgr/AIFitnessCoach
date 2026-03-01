#!/usr/bin/env python3
"""Generate Kids & Youth, Seniors, and Mind & Breath programs."""
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
# KIDS & YOUTH workout templates
# ============================================================

def kids_fun_circuit():
    return wo("Kids Fun Circuit", "bodyweight", 30, [
        ex("Jumping Jacks", 3, 15, 15, "Fun pace", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Clap hands overhead, land softly", "Star Jumps"),
        ex("Bear Crawl", 3, 10, 20, "Across the room", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "beginner", "Hands and feet on ground, hips low", "Crab Walk"),
        ex("Frog Jump", 3, 8, 20, "Jump like a frog", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Deep squat, explode forward", "Squat Jump"),
        ex("Crab Walk", 3, 10, 20, "Across and back", "Bodyweight", "Full Body", "Triceps", ["Core", "Shoulders"], "beginner", "Belly up, walk on hands and feet", "Bear Crawl"),
        ex("High Knees", 3, 20, 15, "Fast and fun", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees to chest, pump arms", "Marching"),
        ex("Plank Hold", 2, 1, 15, "Hold 15 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders"], "beginner", "Straight body like a board", "Forearm Plank"),
    ])

def kids_agility():
    return wo("Kids Agility Fun", "bodyweight", 25, [
        ex("Lateral Shuffle", 3, 10, 15, "Side to side", "Bodyweight", "Legs", "Hip Abductors", ["Calves", "Quadriceps"], "beginner", "Stay low, quick feet", "Side Step"),
        ex("Skipping", 3, 20, 15, "Skip across floor", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Drive knee up, swing opposite arm", "Marching"),
        ex("Star Jumps", 3, 10, 15, "Spread out like a star", "Bodyweight", "Full Body", "Quadriceps", ["Shoulders", "Calves"], "beginner", "Jump up, spread arms and legs wide", "Jumping Jacks"),
        ex("Inchworm Walk", 2, 6, 20, "Walk hands out and back", "Bodyweight", "Full Body", "Hamstrings", ["Shoulders", "Core"], "beginner", "Keep legs straight, walk hands to plank", "Standing Toe Touch"),
        ex("Bunny Hops", 3, 10, 15, "Hop with both feet", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Soft landings, hop forward", "Tuck Jumps"),
        ex("Superman Hold", 2, 1, 15, "Hold 10 seconds", "Bodyweight", "Back", "Erector Spinae", ["Glutes"], "beginner", "Lie on belly, lift arms and legs", "Bird Dog"),
    ])

def teen_strength():
    return wo("Teen Strength Foundations", "strength", 35, [
        ex("Bodyweight Squat", 3, 12, 30, "Focus on form", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Chest up, knees track toes, full depth", "Chair Squat"),
        ex("Push-up", 3, 10, 30, "Full range or knees", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Elbows 45 degrees, full range", "Knee Push-up"),
        ex("Inverted Row", 3, 8, 30, "Use bar or table edge", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull chest to bar, squeeze shoulder blades", "Resistance Band Row"),
        ex("Goblet Squat", 3, 10, 30, "Light dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold weight at chest, sit back", "Bodyweight Squat"),
        ex("Dumbbell Row", 3, 10, 30, "Light to moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Flat back, pull to hip", "Resistance Band Row"),
        ex("Plank", 3, 1, 20, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, tight core", "Forearm Plank"),
        ex("Glute Bridge", 3, 12, 20, "Squeeze at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive hips up, squeeze glutes", "Hip Thrust"),
    ])

def teen_hiit():
    return wo("Teen HIIT Session", "hiit", 25, [
        ex("Squat Jump", 3, 10, 20, "Explosive jumps", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Deep squat, jump high, soft landing", "Bodyweight Squat"),
        ex("Mountain Climber", 3, 15, 20, "Quick pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders", "Core"], "beginner", "Alternating knees to chest quickly", "High Knees"),
        ex("Burpee", 3, 6, 30, "Modified if needed", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "beginner", "Squat down, jump back, push-up, jump up", "Squat Thrust"),
        ex("Lateral Bound", 3, 8, 20, "Side to side jumps", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Calves"], "beginner", "Jump sideways, stick landing", "Lateral Shuffle"),
        ex("Plank Jack", 3, 12, 20, "Plank position jack", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Hip Abductors"], "beginner", "Plank position, jump feet in and out", "Jumping Jacks"),
        ex("Tuck Jump", 3, 8, 25, "Bring knees up", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Jump high, pull knees to chest", "Squat Jump"),
    ])

def kids_calisthenics():
    return wo("Kids Calisthenics", "bodyweight", 25, [
        ex("Wall Push-up", 3, 10, 15, "Against a wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Lean into wall, push back", "Knee Push-up"),
        ex("Squat Hold", 3, 1, 15, "Hold 10 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Sit back, hold at bottom", "Chair Squat"),
        ex("Dead Hang", 2, 1, 20, "Hold 10-15 seconds", "Pull-up Bar", "Back", "Forearms", ["Latissimus Dorsi"], "beginner", "Hang with straight arms, relax shoulders", "Towel Hang"),
        ex("L-Sit Tuck Hold", 2, 1, 20, "Hold 5-10 seconds", "Bodyweight", "Core", "Hip Flexors", ["Rectus Abdominis"], "beginner", "Hands on floor, lift tucked knees", "Knee Raise"),
        ex("Broad Jump", 3, 6, 20, "Jump as far as you can", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Swing arms, jump forward", "Squat Jump"),
        ex("Inch Worm", 3, 5, 20, "Walk hands out to plank", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Walk hands out, walk feet to hands", "Standing Toe Touch"),
    ])

def teen_athlete():
    return wo("Teen Athletic Development", "strength", 40, [
        ex("Box Jump", 3, 8, 30, "Low box 12-16 inch", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Swing arms, land softly on box", "Squat Jump"),
        ex("Dumbbell Lunge", 3, 10, 30, "Light dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, upright torso", "Bodyweight Lunge"),
        ex("Medicine Ball Slam", 3, 8, 25, "Light med ball", "Medicine Ball", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi"], "beginner", "Reach overhead, slam to ground", "Bodyweight Squat"),
        ex("Push-up", 3, 12, 25, "Strict form", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range of motion", "Knee Push-up"),
        ex("Resistance Band Pull-Apart", 3, 12, 20, "Light band", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids", "Trapezius"], "beginner", "Pull band apart at chest level", "Face Pull"),
        ex("Side Plank", 2, 1, 15, "Hold 15 seconds each side", "Bodyweight", "Core", "Obliques", ["Hip Abductors"], "beginner", "Stack feet, straight line", "Modified Side Plank"),
        ex("Broad Jump", 3, 6, 30, "Max distance", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Swing arms, explode forward", "Squat Jump"),
    ])

def kids_dance():
    return wo("Kids Dance Fitness", "cardio", 25, [
        ex("Jumping Jacks", 3, 20, 10, "Dance rhythm", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Move to the beat, clap overhead", "Step Jacks"),
        ex("Grapevine Step", 3, 12, 10, "Side to side", "Bodyweight", "Legs", "Hip Abductors", ["Calves", "Core"], "beginner", "Step behind, step together, step out", "Side Step"),
        ex("High Knee March", 3, 20, 10, "March to music", "Bodyweight", "Legs", "Hip Flexors", ["Core"], "beginner", "Drive knees high, swing arms", "Marching"),
        ex("Twist Jump", 3, 10, 10, "Twist hips mid-air", "Bodyweight", "Core", "Obliques", ["Calves", "Quadriceps"], "beginner", "Jump and twist hips left and right", "Standing Twist"),
        ex("Freeze Dance Squat", 3, 8, 15, "Squat when music stops", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Dance freely, squat and hold on cue", "Bodyweight Squat"),
    ])

def preteen_fitness():
    return wo("Preteen Fitness Session", "bodyweight", 30, [
        ex("Bodyweight Squat", 3, 12, 20, "Full depth", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Chest up, sit back and down", "Chair Squat"),
        ex("Push-up", 3, 8, 20, "Knees or full", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Lower chest to floor, push back up", "Knee Push-up"),
        ex("Jumping Jacks", 3, 20, 15, "Steady pace", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full arm extension, land soft", "Step Jacks"),
        ex("Mountain Climber", 3, 12, 20, "Moderate pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders"], "beginner", "Alternating knees to chest", "Plank Knee Tuck"),
        ex("Lunge Walk", 3, 8, 20, "Alternating legs", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, upright torso", "Reverse Lunge"),
        ex("Plank", 3, 1, 15, "Hold 15-20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight body, tight core", "Forearm Plank"),
    ])

def youth_sports_prep():
    return wo("Youth Sports Prep", "strength", 30, [
        ex("A-Skip", 3, 10, 15, "High knee drive", "Bodyweight", "Legs", "Hip Flexors", ["Calves", "Core"], "beginner", "Drive knee up, skip forward", "High Knees"),
        ex("Lateral Shuffle", 3, 10, 15, "Quick feet", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Stay low, quick side to side", "Side Step"),
        ex("Squat Jump", 3, 8, 20, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Deep squat, max height, soft landing", "Bodyweight Squat"),
        ex("Push-up", 3, 10, 20, "Strict form", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range of motion", "Knee Push-up"),
        ex("Single Leg Balance", 2, 1, 10, "Hold 15 seconds each", "Bodyweight", "Legs", "Calves", ["Core", "Hip Stabilizers"], "beginner", "Stand on one foot, stay steady", "Wall-Assisted Balance"),
        ex("Agility Dot Drill", 3, 6, 20, "5-dot pattern", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Quick feet through dot pattern", "Ladder Drill"),
    ])

# ============================================================
# SENIORS workout templates
# ============================================================

def senior_fitness_basic():
    return wo("Senior Fitness Session", "strength", 30, [
        ex("Seated Marching", 3, 15, 15, "Gentle pace", "Chair", "Legs", "Hip Flexors", ["Core"], "beginner", "Lift knees alternately while seated", "Standing March"),
        ex("Wall Push-up", 3, 10, 20, "Against sturdy wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Lean into wall, press back", "Countertop Push-up"),
        ex("Chair Squat", 3, 10, 20, "Sit and stand", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Lower to chair, stand back up", "Wall Sit"),
        ex("Seated Shoulder Press", 3, 10, 20, "Light dumbbells 2-5 lbs", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Press overhead from shoulders", "Arm Raise"),
        ex("Standing Calf Raise", 3, 12, 15, "Hold chair for balance", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Rise onto toes, slow lower", "Seated Calf Raise"),
        ex("Seated Bicep Curl", 3, 10, 15, "Light dumbbells 2-5 lbs", "Dumbbell", "Arms", "Biceps", ["Forearms"], "beginner", "Curl slowly, squeeze at top", "Resistance Band Curl"),
    ])

def chair_exercises():
    return wo("Chair Exercise Session", "flexibility", 20, [
        ex("Seated Marching", 3, 15, 10, "Gentle pace", "Chair", "Legs", "Hip Flexors", ["Core"], "beginner", "Lift knees alternately", "Ankle Pumps"),
        ex("Seated Arm Raise", 3, 10, 10, "Raise arms overhead", "Chair", "Shoulders", "Deltoids", ["Trapezius"], "beginner", "Raise arms slowly overhead", "Shoulder Shrug"),
        ex("Seated Leg Extension", 3, 10, 10, "Extend one leg at a time", "Chair", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Straighten knee, hold 2 seconds", "Seated Knee Lift"),
        ex("Seated Torso Twist", 3, 8, 10, "Twist left and right", "Chair", "Core", "Obliques", ["Erector Spinae"], "beginner", "Rotate upper body gently", "Seated Side Bend"),
        ex("Seated Heel Raise", 3, 15, 10, "Both feet", "Chair", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Lift heels, press through toes", "Ankle Circle"),
        ex("Seated Cat-Cow", 3, 8, 10, "Arch and round", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Spinal Rotation"),
        ex("Seated Wrist Circle", 2, 10, 0, "Both directions", "Chair", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Circle wrists slowly", "Wrist Flexion Extension"),
    ])

def balance_prevention():
    return wo("Balance & Fall Prevention", "balance", 25, [
        ex("Tandem Stand", 3, 1, 15, "Hold 20 seconds", "Bodyweight", "Legs", "Calves", ["Core", "Hip Stabilizers"], "beginner", "Heel to toe, hold balance", "Wall-Assisted Tandem"),
        ex("Single Leg Stand", 3, 1, 15, "Hold 15 seconds each", "Bodyweight", "Legs", "Calves", ["Core", "Glutes"], "beginner", "Stand on one leg near wall", "Chair-Assisted Balance"),
        ex("Heel to Toe Walk", 3, 10, 15, "Steps in a line", "Bodyweight", "Legs", "Calves", ["Core", "Hip Stabilizers"], "beginner", "Walk placing heel to toe", "Side Step Walk"),
        ex("Lateral Weight Shift", 3, 10, 10, "Side to side", "Bodyweight", "Legs", "Hip Abductors", ["Core", "Glutes"], "beginner", "Shift weight left to right", "Side Step"),
        ex("Clock Reach", 3, 6, 15, "Each direction", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Stabilizers"], "beginner", "Stand on one leg, reach like clock hands", "Single Leg Stand"),
        ex("Chair Stand", 3, 8, 20, "Without using hands", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stand up from chair without arms", "Assisted Chair Stand"),
    ])

def senior_flexibility():
    return wo("Senior Flexibility Session", "flexibility", 20, [
        ex("Neck Stretch", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear toward shoulder, gentle pressure", "Neck Roll"),
        ex("Shoulder Stretch", 2, 1, 0, "Hold 20 seconds each", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Cross arm across chest, gentle pull", "Doorway Stretch"),
        ex("Seated Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each", "Chair", "Legs", "Hamstrings", ["Calves"], "beginner", "Extend leg, lean forward gently", "Standing Hamstring Stretch"),
        ex("Seated Spinal Twist", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Back", "Obliques", ["Erector Spinae"], "beginner", "Rotate upper body, look behind", "Standing Twist"),
        ex("Calf Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Step back, press heel down", "Wall Calf Stretch"),
        ex("Chest Opener", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Clasp hands behind back, open chest", "Doorway Stretch"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Half kneeling lunge, push hips forward", "Standing Hip Stretch"),
    ])

def arthritis_movement():
    return wo("Arthritis-Friendly Movement", "flexibility", 20, [
        ex("Finger Squeeze", 3, 10, 5, "Squeeze soft ball", "Stress Ball", "Arms", "Forearms", ["Fingers"], "beginner", "Squeeze gently, hold 3 seconds, release", "Finger Extension"),
        ex("Wrist Circle", 2, 10, 5, "Both directions", "Bodyweight", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Slow gentle circles", "Wrist Flexion Extension"),
        ex("Ankle Circle", 2, 10, 5, "Both directions each foot", "Bodyweight", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Full gentle range of motion", "Ankle Pump"),
        ex("Shoulder Roll", 3, 10, 5, "Forward and backward", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Slow controlled circles", "Arm Circle"),
        ex("Seated Knee Lift", 3, 8, 10, "Gentle lifts", "Chair", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Lift knee gently toward chest", "Seated Marching"),
        ex("Seated Side Bend", 2, 8, 5, "Each side", "Chair", "Core", "Obliques", ["Erector Spinae"], "beginner", "Lean gently to each side", "Seated Torso Twist"),
        ex("Gentle Neck Turn", 2, 6, 5, "Each side", "Bodyweight", "Neck", "Sternocleidomastoid", ["Trapezius"], "beginner", "Turn head slowly left and right", "Neck Stretch"),
    ])

def senior_tai_chi():
    return wo("Senior Tai Chi Session", "flexibility", 25, [
        ex("Tai Chi Opening", 2, 6, 10, "Slow arm raise", "Bodyweight", "Full Body", "Deltoids", ["Core"], "beginner", "Raise arms slowly, breathe in, lower with exhale", "Arm Raise"),
        ex("Wave Hands Like Clouds", 3, 8, 10, "Flowing side to side", "Bodyweight", "Full Body", "Obliques", ["Shoulders", "Core"], "beginner", "Weight shift side to side, arms flow", "Seated Torso Twist"),
        ex("Parting Wild Horses Mane", 3, 6, 10, "Step and separate", "Bodyweight", "Full Body", "Hip Flexors", ["Shoulders", "Core"], "beginner", "Step forward, separate hands", "Walking Lunge"),
        ex("Brush Knee Twist Step", 3, 6, 10, "Forward stepping", "Bodyweight", "Legs", "Quadriceps", ["Obliques", "Hip Flexors"], "beginner", "Step, brush past knee, push forward", "Walking"),
        ex("Single Whip", 3, 6, 10, "Open and close stance", "Bodyweight", "Full Body", "Deltoids", ["Core", "Legs"], "beginner", "Open arms wide, shift weight", "Arm Raise"),
        ex("Closing Form", 2, 6, 10, "Return to center", "Bodyweight", "Full Body", "Core", ["Shoulders"], "beginner", "Bring arms down slowly, deep breath", "Deep Breathing"),
    ])

def senior_aqua():
    return wo("Senior Aqua Fitness", "cardio", 30, [
        ex("Water Walking", 3, 1, 10, "Walk 2 minutes", "Pool", "Full Body", "Quadriceps", ["Core", "Hip Flexors"], "beginner", "Walk through chest-deep water with big steps", "Seated Marching"),
        ex("Water Arm Curl", 3, 12, 10, "Against water resistance", "Pool", "Arms", "Biceps", ["Forearms"], "beginner", "Curl arms through water slowly", "Resistance Band Curl"),
        ex("Water Leg Lift", 3, 10, 10, "Hold pool edge", "Pool", "Legs", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Lift leg forward in water", "Seated Leg Extension"),
        ex("Water Jumping Jack", 3, 12, 10, "In shallow water", "Pool", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Jump feet out and in, push arms", "Step Jacks"),
        ex("Flutter Kick", 3, 15, 10, "Hold pool edge", "Pool", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Rapid small kicks at surface", "Leg Lift"),
        ex("Water Push", 3, 10, 10, "Push water forward and back", "Pool", "Chest", "Pectoralis Major", ["Shoulders", "Core"], "beginner", "Push palms through water", "Wall Push-up"),
    ])

def active_aging():
    return wo("Active Aging Session", "strength", 30, [
        ex("Chair Squat", 3, 10, 20, "Sit and stand", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Lower to chair, stand back up controlled", "Wall Sit"),
        ex("Wall Push-up", 3, 10, 15, "Against wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Lean in, press back", "Countertop Push-up"),
        ex("Standing Leg Curl", 3, 10, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Curl heel toward glute", "Seated Leg Curl"),
        ex("Seated Row with Band", 3, 10, 15, "Light resistance band", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull band toward chest, squeeze", "Seated Arm Pull"),
        ex("Standing Side Leg Raise", 3, 10, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hip Abductors", ["Glutes"], "beginner", "Lift leg to side, keep toe forward", "Seated Leg Lift"),
        ex("Seated Overhead Press", 3, 8, 15, "Light weight 2-3 lbs", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Press straight up from shoulders", "Arm Raise"),
    ])

def senior_yoga():
    return wo("Senior Yoga Session", "flexibility", 25, [
        ex("Mountain Pose", 2, 1, 10, "Hold 30 seconds", "Bodyweight", "Full Body", "Core", ["Calves", "Quadriceps"], "beginner", "Stand tall, feet hip width, arms at sides", "Seated Mountain Pose"),
        ex("Chair Pose Modified", 2, 1, 15, "Hold 15 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Slight squat, arms forward or up", "Wall Sit"),
        ex("Warrior I Modified", 2, 1, 15, "Hold 20 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Shoulders"], "beginner", "Short lunge, arms up, use chair", "Standing Lunge"),
        ex("Tree Pose Modified", 2, 1, 15, "Hold 15 seconds each side", "Bodyweight", "Legs", "Calves", ["Core", "Hip Stabilizers"], "beginner", "Foot on ankle or calf, use wall", "Single Leg Stand"),
        ex("Seated Forward Fold", 2, 1, 10, "Hold 30 seconds", "Chair", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Hinge at hips, reach toward toes", "Standing Forward Fold"),
        ex("Cat-Cow Seated", 3, 8, 5, "Breath with movement", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Standing Cat-Cow"),
        ex("Seated Twist", 2, 1, 10, "Hold 20 seconds each side", "Chair", "Core", "Obliques", ["Erector Spinae"], "beginner", "Rotate gently, use backrest", "Standing Twist"),
    ])

def obese_senior_safe():
    return wo("Obese Senior Safe Start", "flexibility", 25, [
        ex("Seated Marching", 3, 12, 15, "Gentle pace", "Chair", "Legs", "Hip Flexors", ["Core"], "beginner", "Lift knees alternately, stay upright", "Ankle Pump"),
        ex("Seated Arm Raise", 3, 8, 15, "No weight needed", "Chair", "Shoulders", "Deltoids", ["Trapezius"], "beginner", "Raise arms slowly to shoulder height", "Shoulder Shrug"),
        ex("Ankle Pump", 3, 15, 10, "Point and flex", "Chair", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Point toes then pull back", "Ankle Circle"),
        ex("Seated Side Bend", 2, 6, 10, "Each side", "Chair", "Core", "Obliques", ["Erector Spinae"], "beginner", "Lean gently, reach toward floor", "Seated Torso Twist"),
        ex("Deep Breathing", 3, 5, 10, "Diaphragmatic", "Chair", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Breathe in 4 counts, out 6 counts", "Box Breathing"),
        ex("Seated Heel Raise", 3, 12, 10, "Both feet", "Chair", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Press through toes, lift heels", "Ankle Pump"),
    ])

def obese_senior_strength():
    return wo("Obese Senior Strength", "strength", 25, [
        ex("Assisted Chair Squat", 3, 8, 25, "Use armrests", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Use arms to help stand, control descent", "Seated Leg Press"),
        ex("Wall Push-up", 3, 8, 20, "Wide stance for stability", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Stand arm length from wall, push", "Countertop Push-up"),
        ex("Seated Bicep Curl", 3, 8, 15, "Very light weight 1-2 lbs", "Dumbbell", "Arms", "Biceps", ["Forearms"], "beginner", "Curl slowly, full range", "Resistance Band Curl"),
        ex("Seated Leg Extension", 3, 8, 15, "One leg at a time", "Chair", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Straighten knee, hold 2 seconds", "Seated Knee Lift"),
        ex("Seated Row with Band", 3, 8, 15, "Light band", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids"], "beginner", "Pull band to chest", "Seated Arm Pull"),
        ex("Seated Shoulder Press", 3, 8, 15, "Very light weight 1-2 lbs", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Press up from shoulders", "Arm Raise"),
    ])

def obese_senior_mobility():
    return wo("Obese Senior Mobility", "flexibility", 20, [
        ex("Seated Ankle Circle", 2, 10, 5, "Each direction", "Chair", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Gentle circles with each foot", "Ankle Pump"),
        ex("Seated Shoulder Roll", 3, 10, 5, "Forward and back", "Chair", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Roll shoulders slowly", "Arm Circle"),
        ex("Seated Hip Circle", 2, 8, 10, "Small circles", "Chair", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Shift weight in circular motion", "Seated Marching"),
        ex("Seated Neck Stretch", 2, 1, 5, "Hold 15 seconds each side", "Chair", "Neck", "Trapezius", ["Scalenes"], "beginner", "Tilt ear to shoulder gently", "Neck Roll"),
        ex("Seated Chest Opener", 2, 1, 5, "Hold 15 seconds", "Chair", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Squeeze shoulder blades together", "Doorway Stretch"),
        ex("Seated Wrist Stretch", 2, 1, 5, "Hold 15 seconds each", "Chair", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back", "Wrist Circle"),
    ])

def senior_weight_loss():
    return wo("Senior Weight Loss Session", "cardio", 30, [
        ex("Seated Marching", 3, 20, 10, "Brisk pace", "Chair", "Legs", "Hip Flexors", ["Core"], "beginner", "Quick alternating knees", "Standing March"),
        ex("Standing Leg Curl", 3, 12, 15, "Hold chair for balance", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Curl heel toward glute", "Seated Leg Curl"),
        ex("Wall Push-up", 3, 10, 15, "Steady tempo", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Lean in and push back", "Countertop Push-up"),
        ex("Chair Squat", 3, 10, 20, "Controlled", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Sit back, stand up", "Wall Sit"),
        ex("Arm Circle", 3, 15, 10, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, gradually bigger", "Shoulder Roll"),
        ex("Standing Knee Lift", 3, 10, 10, "Alternating", "Bodyweight", "Core", "Hip Flexors", ["Rectus Abdominis"], "beginner", "Lift knee toward chest, stand tall", "Seated Marching"),
    ])

def senior_multicomponent():
    return wo("Senior Multicomponent Session", "strength", 35, [
        ex("Chair Squat", 3, 10, 20, "Controlled pace", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Sit back and stand up", "Wall Sit"),
        ex("Wall Push-up", 3, 10, 15, "Slow tempo", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Lean in, press back", "Countertop Push-up"),
        ex("Tandem Walk", 3, 10, 15, "Heel to toe steps", "Bodyweight", "Legs", "Calves", ["Core", "Hip Stabilizers"], "beginner", "Walk in straight line, heel to toe", "Side Step"),
        ex("Seated Row with Band", 3, 10, 15, "Light band", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull band to chest, squeeze back", "Seated Arm Pull"),
        ex("Standing Calf Raise", 3, 12, 10, "Hold chair", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Rise onto toes, control down", "Seated Calf Raise"),
        ex("Seated Stretch Sequence", 2, 1, 5, "Hold 30 seconds each", "Chair", "Full Body", "Hamstrings", ["Shoulders", "Back"], "beginner", "Stretch major muscle groups seated", "Standing Stretch"),
        ex("Deep Breathing", 2, 5, 0, "Cool down", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Breathe in 4, out 6, relax body", "Box Breathing"),
    ])

# ============================================================
# MIND & BREATH workout templates
# ============================================================

def breathwork_basic():
    return wo("Breathwork Basics", "breathing", 15, [
        ex("Diaphragmatic Breathing", 3, 10, 10, "Deep belly breaths", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Hand on belly, breathe into hand, 4 in 6 out", "Seated Breathing"),
        ex("4-7-8 Breathing", 3, 5, 10, "Inhale-hold-exhale", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Breathe in 4, hold 7, exhale 8 counts", "Box Breathing"),
        ex("Alternate Nostril Breathing", 3, 6, 10, "Block one nostril", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Close right nostril, inhale left, switch, exhale right", "Deep Breathing"),
        ex("Pursed Lip Breathing", 3, 8, 5, "Purse lips on exhale", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale through nose, exhale slowly through pursed lips", "Deep Breathing"),
        ex("Counted Breathing", 3, 8, 5, "Count each breath", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Count to 10 breaths, restart if mind wanders", "Diaphragmatic Breathing"),
    ])

def mindful_movement():
    return wo("Mindful Movement Flow", "flexibility", 20, [
        ex("Standing Body Scan", 2, 1, 10, "Hold 1 minute", "Bodyweight", "Full Body", "Core", ["Calves"], "beginner", "Stand still, scan from head to toe", "Seated Body Scan"),
        ex("Slow Cat-Cow", 3, 8, 5, "Breath-synced", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round, very slow", "Seated Cat-Cow"),
        ex("Mindful Walking", 2, 1, 5, "Walk 2 minutes slowly", "Bodyweight", "Full Body", "Calves", ["Quadriceps", "Core"], "beginner", "Heel-toe, feel each step, breathe", "Standing Balance"),
        ex("Gentle Spinal Twist", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Erector Spinae"], "beginner", "Supine twist, breathe into stretch", "Seated Twist"),
        ex("Child's Pose", 2, 1, 5, "Hold 1 minute", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Knees wide, reach forward, forehead down", "Puppy Pose"),
        ex("Savasana", 2, 1, 0, "Hold 2 minutes", "Bodyweight", "Full Body", "Core", ["Diaphragm"], "beginner", "Lie flat, palms up, release all tension", "Seated Relaxation"),
    ])

def stress_relief():
    return wo("Stress Relief Movement", "flexibility", 20, [
        ex("Shoulder Shrug and Release", 3, 8, 5, "Tense and release", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Shrug up tight, hold 3 seconds, drop", "Shoulder Roll"),
        ex("Neck Roll", 2, 6, 5, "Slow circles", "Bodyweight", "Neck", "Trapezius", ["Sternocleidomastoid"], "beginner", "Gentle half circles, ear to ear", "Neck Stretch"),
        ex("Standing Forward Fold", 2, 1, 10, "Hold 30 seconds", "Bodyweight", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Fold forward, let head hang heavy", "Seated Forward Fold"),
        ex("Chest Opener Stretch", 2, 1, 10, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Clasp hands behind, open chest wide", "Doorway Stretch"),
        ex("Hip Circle", 3, 8, 5, "Both directions", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Core"], "beginner", "Hands on hips, big slow circles", "Standing Hip Stretch"),
        ex("Progressive Muscle Relaxation", 2, 1, 0, "Full body scan", "Bodyweight", "Full Body", "Core", ["Diaphragm"], "beginner", "Tense each muscle group 5 seconds, release", "Deep Breathing"),
    ])

def meditation_stretch():
    return wo("Meditation + Stretch", "flexibility", 20, [
        ex("Seated Meditation", 2, 1, 0, "5 minute sit", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Sit tall, eyes closed, focus on breath", "Lying Meditation"),
        ex("Seated Side Stretch", 2, 1, 5, "Hold 30 seconds each", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Reach one arm over, lean to side", "Standing Side Stretch"),
        ex("Seated Forward Fold", 2, 1, 5, "Hold 30 seconds", "Bodyweight", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Legs extended, fold gently forward", "Standing Forward Fold"),
        ex("Supine Twist", 2, 1, 5, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Erector Spinae"], "beginner", "Knees to one side, look opposite", "Seated Twist"),
        ex("Butterfly Stretch", 2, 1, 5, "Hold 30 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Glutes"], "beginner", "Soles together, knees out, lean forward", "Seated Hip Stretch"),
        ex("Savasana", 2, 1, 0, "3 minutes", "Bodyweight", "Full Body", "Core", ["Diaphragm"], "beginner", "Lie flat, release all tension, breathe naturally", "Seated Relaxation"),
    ])

def qigong_basic():
    return wo("Qigong Basics", "flexibility", 25, [
        ex("Qigong Standing Meditation", 2, 1, 10, "Hold 2 minutes", "Bodyweight", "Full Body", "Core", ["Quadriceps"], "beginner", "Stand with slightly bent knees, arms at sides", "Seated Meditation"),
        ex("Lifting the Sky", 3, 8, 10, "Breath with movement", "Bodyweight", "Full Body", "Deltoids", ["Core", "Latissimus Dorsi"], "beginner", "Interlace fingers, lift palms to sky, lower slowly", "Arm Raise"),
        ex("Carrying the Moon", 3, 8, 10, "Side to side", "Bodyweight", "Core", "Obliques", ["Shoulders"], "beginner", "Bend sideways, arms overhead like carrying moon", "Seated Side Bend"),
        ex("Pushing Mountains", 3, 8, 10, "Push and pull", "Bodyweight", "Chest", "Pectoralis Major", ["Shoulders", "Core"], "beginner", "Push palms forward, pull back slowly", "Wall Push-up"),
        ex("Nourishing Kidneys", 3, 6, 10, "Bend and stretch", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Bend forward, hands to lower back, arch up", "Cat-Cow"),
        ex("Closing Form", 2, 6, 5, "Return to center", "Bodyweight", "Full Body", "Core", ["Diaphragm"], "beginner", "Hands to lower belly, breathe deeply three times", "Deep Breathing"),
    ])

def box_breathing():
    return wo("Box Breathing Training", "breathing", 10, [
        ex("Box Breathing 4-4-4-4", 4, 8, 5, "4 count each phase", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale 4, hold 4, exhale 4, hold 4", "Deep Breathing"),
        ex("Extended Box Breathing 5-5-5-5", 3, 6, 5, "5 count each phase", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale 5, hold 5, exhale 5, hold 5", "Box Breathing 4-4-4-4"),
        ex("Box Breathing with Body Scan", 3, 5, 5, "Scan while breathing", "Bodyweight", "Full Body", "Diaphragm", ["Core"], "beginner", "Box breathe while scanning body head to toe", "Deep Breathing"),
        ex("Tactical Box Breathing", 3, 6, 5, "Eyes open, focused", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Eyes on fixed point, maintain box pattern", "Box Breathing 4-4-4-4"),
        ex("Box Breathing Cool Down", 2, 5, 0, "Slow and relaxed", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Gradually lengthen exhale phase", "4-7-8 Breathing"),
    ])

def wim_hof_style():
    return wo("Wim Hof Style Breathing", "breathing", 15, [
        ex("Power Breathing Rounds", 3, 30, 15, "Deep rapid breaths", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "30 deep breaths: big inhale, passive exhale, rapid", "Deep Breathing"),
        ex("Breath Retention", 3, 1, 10, "Hold after exhale", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "After 30 breaths, exhale fully, hold as long as comfortable", "Breath Hold"),
        ex("Recovery Breath", 3, 1, 15, "Deep inhale and hold", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale deeply, hold 15 seconds, exhale", "Deep Breathing"),
        ex("Body Scan During Hold", 2, 1, 10, "Scan while holding", "Bodyweight", "Full Body", "Diaphragm", ["Core"], "beginner", "During retention, scan body for sensations", "Progressive Muscle Relaxation"),
        ex("Closing Meditation", 2, 1, 0, "2 minute sit", "Bodyweight", "Full Body", "Core", ["Diaphragm"], "beginner", "Sit quietly, notice how body feels after practice", "Seated Meditation"),
    ])

def anxiety_relief():
    return wo("Anxiety Relief Movement", "flexibility", 15, [
        ex("Grounding 5-4-3-2-1", 2, 1, 5, "Sensory awareness", "Bodyweight", "Full Body", "Core", ["Diaphragm"], "beginner", "Name 5 things you see, 4 feel, 3 hear, 2 smell, 1 taste", "Seated Body Scan"),
        ex("4-7-8 Calming Breath", 3, 5, 5, "Slow calming breath", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale 4, hold 7, exhale 8 through mouth", "Deep Breathing"),
        ex("Gentle Neck Release", 2, 6, 5, "Each direction", "Bodyweight", "Neck", "Trapezius", ["Sternocleidomastoid"], "beginner", "Tilt ear to shoulder, hold, breathe into stretch", "Neck Stretch"),
        ex("Shoulder Drop and Roll", 3, 8, 5, "Release tension", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Shrug tight, hold, drop and roll backward", "Shoulder Roll"),
        ex("Standing Sway", 2, 1, 5, "Gentle side to side", "Bodyweight", "Full Body", "Core", ["Calves"], "beginner", "Shift weight slowly side to side, breathe", "Seated Rocking"),
        ex("Extended Exhale Breathing", 3, 8, 5, "Long exhale", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Inhale 3 counts, exhale 6 counts", "4-7-8 Breathing"),
    ])

def morning_mindfulness():
    return wo("Morning Mindfulness Session", "flexibility", 15, [
        ex("Sunrise Breathing", 3, 8, 5, "Greet the day", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Arms rise with inhale, lower with exhale", "Deep Breathing"),
        ex("Standing Side Stretch", 2, 1, 5, "Hold 20 seconds each", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Reach one arm up and over", "Seated Side Stretch"),
        ex("Gentle Spinal Twist", 2, 1, 5, "Hold 20 seconds each side", "Bodyweight", "Core", "Obliques", ["Erector Spinae"], "beginner", "Standing twist, arms follow", "Seated Twist"),
        ex("Forward Fold with Rag Doll", 2, 1, 5, "Hold 30 seconds", "Bodyweight", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Fold forward, grab opposite elbows, sway", "Seated Forward Fold"),
        ex("Morning Intention Setting", 2, 1, 0, "1 minute meditation", "Bodyweight", "Full Body", "Core", ["Diaphragm"], "beginner", "Stand tall, set intention for the day", "Seated Meditation"),
        ex("Sun Salutation Modified", 2, 3, 10, "Slow and mindful", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "beginner", "Reach up, fold, half lift, fold, reach up", "Standing Stretch Sequence"),
    ])

# ============================================================
# PROGRAM DEFINITIONS
# ============================================================

all_programs = []

# --- Kids & Youth (8 programs) ---
all_programs.append(("Kids Fitness Fun", "Kids & Youth", [2, 4, 8], [3, 4], "High",
    "Fun bodyweight games and activities for kids to build fitness habits",
    lambda w, t: [kids_fun_circuit(), kids_agility(), kids_fun_circuit(), kids_agility()]))

all_programs.append(("Teen Strength Basics", "Kids & Youth", [4, 8, 12], [3], "High",
    "Safe strength foundations for teens learning to train properly",
    lambda w, t: [teen_strength()] * 3))

all_programs.append(("Youth Sports Prep", "Kids & Youth", [4, 8], [3, 4], "High",
    "Athletic development for young athletes preparing for sports",
    lambda w, t: [youth_sports_prep(), teen_strength(), youth_sports_prep(), teen_strength()]))

all_programs.append(("Teen HIIT", "Kids & Youth", [2, 4, 8], [3], "Med",
    "Age-appropriate interval training for teens",
    lambda w, t: [teen_hiit()] * 3))

all_programs.append(("Kids Calisthenics", "Kids & Youth", [2, 4, 8], [3, 4], "Med",
    "Bodyweight skills and movement mastery for kids",
    lambda w, t: [kids_calisthenics(), kids_fun_circuit(), kids_calisthenics(), kids_fun_circuit()]))

all_programs.append(("Teen Athlete Development", "Kids & Youth", [4, 8, 12], [4, 5], "Med",
    "Comprehensive athletic training for competitive teen athletes",
    lambda w, t: [teen_athlete(), teen_strength(), teen_hiit(), teen_athlete(), youth_sports_prep()]))

all_programs.append(("Kids Dance Fitness", "Kids & Youth", [2, 4], [2, 3], "Low",
    "Dance-based cardio fun for kids who love to move",
    lambda w, t: [kids_dance(), kids_fun_circuit(), kids_dance()]))

all_programs.append(("Preteen Fitness", "Kids & Youth", [2, 4, 8], [3, 4], "Med",
    "Age-appropriate fitness program for preteens building healthy habits",
    lambda w, t: [preteen_fitness(), kids_calisthenics(), preteen_fitness(), kids_agility()]))

# --- Seniors (14 programs) ---
all_programs.append(("Senior Fitness Fundamentals", "Seniors", [2, 4, 8, 12], [3], "High",
    "Complete fitness foundation program designed for seniors",
    lambda w, t: [senior_fitness_basic()] * 3))

all_programs.append(("Chair Exercises", "Seniors", [1, 2, 4], [4, 5], "High",
    "Seated exercise program for seniors with limited mobility",
    lambda w, t: [chair_exercises()] * 5))

all_programs.append(("Balance & Fall Prevention", "Seniors", [2, 4, 8], [3, 4], "High",
    "Balance training to reduce fall risk in older adults",
    lambda w, t: [balance_prevention(), senior_fitness_basic(), balance_prevention(), senior_fitness_basic()]))

all_programs.append(("Senior Flexibility", "Seniors", [2, 4, 8], [4, 5], "Med",
    "Gentle flexibility and stretching program for seniors",
    lambda w, t: [senior_flexibility()] * 5))

all_programs.append(("Arthritis-Friendly Movement", "Seniors", [2, 4, 8], [3, 4], "Med",
    "Joint-friendly movement program for seniors with arthritis",
    lambda w, t: [arthritis_movement(), senior_flexibility(), arthritis_movement(), senior_flexibility()]))

all_programs.append(("Senior Tai Chi", "Seniors", [2, 4, 8], [3, 4], "Med",
    "Tai Chi program adapted for seniors to improve balance and calm",
    lambda w, t: [senior_tai_chi(), balance_prevention(), senior_tai_chi(), balance_prevention()]))

all_programs.append(("Senior Aqua Fitness", "Seniors", [2, 4, 8], [3], "Med",
    "Water-based exercise program gentle on joints for seniors",
    lambda w, t: [senior_aqua()] * 3))

all_programs.append(("Active Aging", "Seniors", [4, 8, 12], [3, 4], "Med",
    "Comprehensive active aging program to maintain strength and independence",
    lambda w, t: [active_aging(), balance_prevention(), active_aging(), senior_flexibility()]))

all_programs.append(("Senior Yoga", "Seniors", [2, 4, 8], [3, 4], "Med",
    "Modified yoga program adapted for senior flexibility and balance",
    lambda w, t: [senior_yoga(), senior_flexibility(), senior_yoga(), senior_flexibility()]))

all_programs.append(("Obese Senior Safe Start", "Seniors", [4, 8, 12], [2, 3], "High",
    "Safe starting program for obese seniors beginning their fitness journey",
    lambda w, t: [obese_senior_safe(), arthritis_movement(), obese_senior_safe()]))

all_programs.append(("Obese Senior Strength", "Seniors", [4, 8, 12], [2, 3], "Med",
    "Progressive strength building for obese seniors",
    lambda w, t: [obese_senior_strength(), obese_senior_safe(), obese_senior_strength()]))

all_programs.append(("Obese Senior Mobility", "Seniors", [2, 4, 8], [3, 4], "Med",
    "Mobility and flexibility program for obese seniors",
    lambda w, t: [obese_senior_mobility(), arthritis_movement(), obese_senior_mobility(), senior_flexibility()]))

all_programs.append(("Senior Weight Loss", "Seniors", [4, 8, 12], [3, 4], "Med",
    "Safe calorie-burning program for seniors seeking weight loss",
    lambda w, t: [senior_weight_loss(), senior_fitness_basic(), senior_weight_loss(), active_aging()]))

all_programs.append(("Senior Multicomponent Training", "Seniors", [4, 8, 12], [3], "Med",
    "Combined strength, balance, flexibility and cardio for seniors",
    lambda w, t: [senior_multicomponent()] * 3))

# --- Mind & Breath (9 programs) ---
all_programs.append(("Breathwork Basics", "Mind & Breath", [1, 2, 4], [5, 6, 7], "High",
    "Foundation breathing techniques for stress relief and calm",
    lambda w, t: [breathwork_basic()] * 7))

all_programs.append(("Mindful Movement", "Mind & Breath", [1, 2, 4], [4, 5], "High",
    "Slow mindful movement combining breath awareness and gentle motion",
    lambda w, t: [mindful_movement()] * 5))

all_programs.append(("Stress Relief Movement", "Mind & Breath", [1, 2, 4], [4, 5], "High",
    "Movement-based stress relief targeting tension and anxiety",
    lambda w, t: [stress_relief()] * 5))

all_programs.append(("Meditation + Stretch", "Mind & Breath", [1, 2, 4], [5, 6, 7], "Med",
    "Combined meditation and gentle stretching for mind-body connection",
    lambda w, t: [meditation_stretch()] * 7))

all_programs.append(("Qigong Basics", "Mind & Breath", [2, 4, 8], [4, 5], "Med",
    "Introduction to Qigong energy cultivation and flowing movements",
    lambda w, t: [qigong_basic()] * 5))

all_programs.append(("Box Breathing Training", "Mind & Breath", [1, 2], [7], "Med",
    "Structured box breathing protocol for focus and nervous system regulation",
    lambda w, t: [box_breathing()] * 7))

all_programs.append(("Wim Hof Style Breathing", "Mind & Breath", [1, 2, 4], [5, 6, 7], "Med",
    "Intense breathing protocol inspired by Wim Hof method for energy and resilience",
    lambda w, t: [wim_hof_style()] * 7))

all_programs.append(("Anxiety Relief Movement", "Mind & Breath", [1, 2, 4], [5, 6, 7], "High",
    "Gentle grounding movements and breathing to ease anxiety symptoms",
    lambda w, t: [anxiety_relief()] * 7))

all_programs.append(("Morning Mindfulness", "Mind & Breath", [1, 2, 4], [7], "Med",
    "Daily morning mindfulness practice to start the day centered and calm",
    lambda w, t: [morning_mindfulness()] * 7))

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

    # Build weeks_data
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
    # Use correct split type
    if cat == "Mind & Breath":
        split_override = "flow"
    else:
        split_override = "full_body"

    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s:
        print(f"DONE: {prog_name}")
        success_count += 1
    else:
        print(f"FAIL: {prog_name}")
        fail_count += 1

helper.close()
print(f"\n=== KIDS/SENIORS/MIND-BREATH BATCH COMPLETE ===")
print(f"Success: {success_count} | Skipped: {skip_count} | Failed: {fail_count}")
print(f"Total programs attempted: {len(all_programs)}")
