#!/usr/bin/env python3
"""Generate remaining Sports programs (Category 6)."""
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
# VOLLEYBALL JUMP TRAINING
# ========================================================================
def volleyball_lower():
    return wo("Volleyball Lower Body Power", "strength", 50, [
        ex("Box Jump", 4, 6, 90, "24-30 inch box", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Drive arms up, land soft with bent knees", "Squat Jump"),
        ex("Depth Jump", 3, 5, 120, "12-18 inch drop", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "advanced", "Step off box, immediately explode up on contact", "Box Jump"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Moderate DBs", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hip Flexors"], "intermediate", "Rear foot elevated, torso upright, knee tracks toe", "Reverse Lunge"),
        ex("Barbell Back Squat", 4, 6, 120, "75-85% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Break at hips, chest up, full depth", "Goblet Squat"),
        ex("Single-Leg Calf Raise", 3, 15, 45, "Bodyweight + DB", "Dumbbells", "Legs", "Calves", ["Soleus"], "beginner", "Full ROM, pause at top", "Seated Calf Raise"),
        ex("Lateral Bound", 3, 8, 60, "Bodyweight", "Bodyweight", "Legs", "Glutes", ["Hip Abductors", "Quadriceps"], "intermediate", "Stick landing on each side, minimize ground contact", "Lateral Shuffle"),
    ])

def volleyball_upper():
    return wo("Volleyball Upper Body & Core", "strength", 45, [
        ex("Medicine Ball Overhead Throw", 3, 10, 60, "4-6 kg ball", "Medicine Ball", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Full extension overhead, slam with core engagement", "Overhead Press"),
        ex("Face Pull", 3, 15, 45, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rotator Cuff", "Rhomboids"], "beginner", "Pull to face level, squeeze shoulder blades", "Band Pull-Apart"),
        ex("Dumbbell Shoulder Press", 3, 10, 60, "Moderate weight", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Chest"], "intermediate", "Press straight up, don't arch excessively", "Pike Push-up"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Straight line from head to heels", "Forearm Plank"),
        ex("Russian Twist", 3, 20, 30, "5-10 kg plate", "Weight Plate", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Rotate from thoracic spine, feet elevated", "Bicycle Crunch"),
        ex("Rotator Cuff External Rotation", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rotator Cuff", ["Rear Deltoid"], "beginner", "Elbow pinned to side, rotate out slowly", "Cable External Rotation"),
    ])

def volleyball_agility():
    return wo("Volleyball Agility & Reactivity", "conditioning", 40, [
        ex("Approach Jump", 4, 8, 60, "Full approach", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "3-step approach, plant and explode vertically", "Standing Vertical Jump"),
        ex("Lateral Shuffle", 3, 30, 45, "10 yards each way", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Low athletic stance, quick feet, don't cross over", "Side Step"),
        ex("Block Jump Drill", 4, 8, 60, "At the net height", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Shoulders"], "intermediate", "Quick double-foot take off, hands high, repeat", "Tuck Jump"),
        ex("Sprint to Dive", 3, 6, 90, "10-yard sprint", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Sprint, then pancake or sprawl dive", "Sprint to Burpee"),
        ex("Broad Jump", 3, 8, 60, "Maximum distance", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Hamstrings"], "intermediate", "Swing arms, extend hips fully, stick landing", "Squat Jump"),
    ])

# ========================================================================
# SPRINT TRAINING
# ========================================================================
def sprint_speed():
    return wo("Sprint Speed Development", "conditioning", 50, [
        ex("A-Skip", 3, 20, 30, "Warm-up drill", "Bodyweight", "Legs", "Hip Flexors", ["Calves", "Quadriceps"], "beginner", "Drive knee high, quick ground contact", "High Knees"),
        ex("10m Sprint", 6, 1, 120, "100% effort", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Explosive start, forward lean, drive arms", "20m Sprint"),
        ex("30m Sprint", 4, 1, 180, "100% effort", "Bodyweight", "Legs", "Hamstrings", ["Quadriceps", "Glutes"], "intermediate", "Transition from drive to upright mechanics", "40m Sprint"),
        ex("Sled Sprint", 4, 30, 120, "Light sled 10-20% BW", "Sled", "Legs", "Glutes", ["Quadriceps", "Calves"], "intermediate", "Forward lean, powerful leg drive", "Hill Sprint"),
        ex("Wall Drive", 3, 10, 45, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Glutes", "Core"], "beginner", "Hands on wall, drive knee up explosively", "Marching"),
    ])

def sprint_strength():
    return wo("Sprint Strength & Power", "strength", 55, [
        ex("Trap Bar Deadlift", 4, 5, 120, "80-90% 1RM", "Trap Bar", "Legs", "Glutes", ["Hamstrings", "Quadriceps"], "intermediate", "Drive through floor, lockout hips", "Barbell Deadlift"),
        ex("Front Squat", 4, 5, 120, "75-85% 1RM", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows high, upright torso, full depth", "Goblet Squat"),
        ex("Romanian Deadlift", 3, 8, 90, "60-70% 1RM", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, slight knee bend, feel hamstring stretch", "Single-Leg RDL"),
        ex("Hip Thrust", 3, 10, 60, "Heavy", "Barbell", "Legs", "Glutes", ["Hamstrings"], "intermediate", "Bench at mid-back, drive through heels, full hip extension", "Glute Bridge"),
        ex("Nordic Hamstring Curl", 3, 5, 90, "Bodyweight", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "advanced", "Control eccentric descent, use arms to push back", "Hamstring Curl"),
        ex("Hanging Leg Raise", 3, 12, 45, "Bodyweight", "Pull-up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Controlled movement, avoid swinging", "Lying Leg Raise"),
    ])

# ========================================================================
# CAPTAIN'S COMPLETE CRICKET
# ========================================================================
def cricket_batting():
    return wo("Cricket Batting Power & Endurance", "sport_specific", 50, [
        ex("Rotational Medicine Ball Throw", 4, 10, 60, "4-6 kg ball", "Medicine Ball", "Core", "Obliques", ["Shoulders", "Hips"], "intermediate", "Rotate from hips, release at chest height", "Cable Woodchop"),
        ex("Single-Leg Romanian Deadlift", 3, 10, 60, "Moderate DB", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Balance on one leg, hinge forward, back flat", "Romanian Deadlift"),
        ex("Goblet Squat", 3, 12, 60, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold at chest, elbows inside knees, full depth", "Bodyweight Squat"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy DBs, 40m", "Dumbbells", "Full Body", "Forearms", ["Traps", "Core"], "intermediate", "Tight core, shoulders back, quick short steps", "Suitcase Carry"),
        ex("Plank with Rotation", 3, 12, 45, "Alternate sides", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis", "Shoulders"], "intermediate", "From plank, rotate to side plank, alternate", "Side Plank"),
        ex("Shuttle Run", 4, 6, 90, "20m shuttles", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Touch line, change direction explosively", "Lateral Shuffle"),
    ])

def cricket_bowling():
    return wo("Cricket Bowling Strength", "sport_specific", 55, [
        ex("Overhead Press", 3, 8, 90, "Moderate barbell", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, no leg drive, full lockout", "Dumbbell Press"),
        ex("Pull-up", 3, 8, 90, "Bodyweight or weighted", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Full hang to chin over bar, controlled descent", "Lat Pulldown"),
        ex("Back Squat", 4, 6, 120, "75-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, drive through heels", "Leg Press"),
        ex("Internal/External Rotation", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rotator Cuff", ["Rear Deltoid"], "beginner", "Elbow at 90, rotate slowly", "Cable Rotation"),
        ex("Box Jump", 3, 6, 60, "24 inch box", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Full extension, soft landing", "Squat Jump"),
        ex("Anti-Rotation Press", 3, 12, 45, "Light cable", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Press cable straight out, resist rotation", "Pallof Press"),
    ])

def cricket_fielding():
    return wo("Cricket Fielding Agility", "conditioning", 40, [
        ex("Lateral Bound", 3, 10, 60, "Bodyweight", "Bodyweight", "Legs", "Glutes", ["Hip Abductors", "Quadriceps"], "intermediate", "Explode laterally, stick landing", "Lateral Shuffle"),
        ex("Sprint to Ground Pick-up", 4, 6, 90, "10-yard sprint", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Hamstrings"], "intermediate", "Sprint, bend to pick up ball, throw", "Sprint to Burpee"),
        ex("Reactive Agility Drill", 3, 8, 60, "Cone drill", "Cones", "Legs", "Quadriceps", ["Calves", "Hip Abductors"], "intermediate", "React to stimulus, change direction quickly", "T-Drill"),
        ex("Overhead Throw", 3, 10, 45, "2-4 kg ball", "Medicine Ball", "Shoulders", "Deltoids", ["Core", "Triceps"], "beginner", "Full overhead arc, release at peak", "Chest Pass"),
        ex("Bear Crawl", 3, 1, 45, "20m distance", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "intermediate", "Hands and feet, hips low, opposite hand/foot", "Inchworm"),
    ])

# ========================================================================
# WICKETKEEPER AGILITY
# ========================================================================
def wicketkeeper_lower():
    return wo("Wicketkeeper Lower Body", "strength", 50, [
        ex("Wall Sit", 3, 1, 60, "Hold 60 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Back flat on wall, thighs parallel, hold", "Chair Pose"),
        ex("Lateral Lunge", 3, 10, 60, "Light DBs", "Dumbbells", "Legs", "Hip Adductors", ["Quadriceps", "Glutes"], "intermediate", "Step wide, push hips back, keep chest up", "Cossack Squat"),
        ex("Squat Jump", 4, 8, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, explode up, soft landing", "Box Jump"),
        ex("Single-Leg Box Squat", 3, 8, 60, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Control descent to box on one leg, stand", "Pistol Squat"),
        ex("Ankle Hops", 3, 20, 45, "Quick ground contact", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Stiff ankles, minimal ground time", "Jump Rope"),
        ex("Glute Bridge March", 3, 16, 45, "Alternating legs", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "beginner", "Hold bridge, march legs alternately", "Glute Bridge"),
    ])

def wicketkeeper_reaction():
    return wo("Wicketkeeper Reaction & Agility", "conditioning", 40, [
        ex("Lateral Shuffle Drop", 4, 8, 60, "3-5m each way", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Core"], "intermediate", "Shuffle, drop to low catch position, reset", "Lateral Shuffle"),
        ex("Tennis Ball Reaction Catch", 3, 20, 45, "Partner throws", "Tennis Ball", "Full Body", "Forearms", ["Shoulders", "Core"], "beginner", "React to bounce, catch with soft hands", "Wall Ball Catch"),
        ex("Depth Drop to Sprint", 3, 6, 90, "6-inch box", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Drop, absorb, immediately sprint 5m", "Broad Jump to Sprint"),
        ex("Lateral Plyo Step-up", 3, 10, 60, "Low box", "Plyo Box", "Legs", "Glutes", ["Quadriceps", "Calves"], "intermediate", "Lateral onto box, drive up explosively", "Step-up"),
        ex("Prone Ball Pick-up", 3, 10, 45, "From lying position", "Tennis Ball", "Full Body", "Core", ["Hip Flexors", "Quadriceps"], "intermediate", "Lie flat, react, get up and grab ball", "Burpee"),
    ])

# ========================================================================
# FAST BOWLER POWER
# ========================================================================
def fast_bowler_upper():
    return wo("Fast Bowler Upper Body Power", "strength", 55, [
        ex("Landmine Press", 3, 10, 60, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Single arm, drive through, rotational element", "Dumbbell Press"),
        ex("Bent-Over Row", 4, 8, 90, "Heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge at hips, pull to lower chest", "Dumbbell Row"),
        ex("Face Pull", 3, 15, 45, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rotator Cuff"], "beginner", "Pull to face, external rotate at end", "Band Pull-Apart"),
        ex("Dumbbell Pullover", 3, 12, 60, "Moderate DB", "Dumbbells", "Chest", "Latissimus Dorsi", ["Pectoralis Major", "Triceps"], "intermediate", "Arc over head, feel lats stretch", "Straight-Arm Pulldown"),
        ex("Medicine Ball Slam", 3, 10, 45, "6-8 kg ball", "Medicine Ball", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Reach high, slam hard, hinge at hips", "Cable Crunch"),
        ex("Prone Y-T-W", 3, 10, 30, "Light dumbbells", "Dumbbells", "Shoulders", "Rotator Cuff", ["Rear Deltoid", "Rhomboids"], "beginner", "Lie face down, make Y, T, W shapes", "Band Pull-Apart"),
    ])

def fast_bowler_lower():
    return wo("Fast Bowler Lower Body & Trunk", "strength", 55, [
        ex("Front Squat", 4, 6, 120, "75-85% 1RM", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows high, upright torso", "Goblet Squat"),
        ex("Single-Leg Hip Thrust", 3, 10, 60, "Bodyweight or bar", "Bench", "Legs", "Glutes", ["Hamstrings"], "intermediate", "One leg extended, drive through planted heel", "Glute Bridge"),
        ex("Walking Lunge", 3, 12, 60, "Moderate DBs", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso, knee tracks toe", "Reverse Lunge"),
        ex("Cable Woodchop", 3, 12, 45, "Moderate cable", "Cable Machine", "Core", "Obliques", ["Shoulders", "Hips"], "intermediate", "High to low rotation, pivot back foot", "Medicine Ball Rotation"),
        ex("Pallof Press", 3, 12, 45, "Light cable", "Cable Machine", "Core", "Transverse Abdominis", ["Obliques"], "intermediate", "Press out against rotation, hold 2 seconds", "Anti-Rotation Press"),
        ex("Box Jump", 3, 6, 90, "24-30 inch", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Full hip extension, soft landing", "Squat Jump"),
    ])

# ========================================================================
# BATSMAN ENDURANCE
# ========================================================================
def batsman_endurance_a():
    return wo("Batsman Endurance & Power", "sport_specific", 50, [
        ex("Rotational Cable Press", 3, 12, 45, "Moderate cable", "Cable Machine", "Core", "Obliques", ["Pectoralis Major", "Shoulders"], "intermediate", "Press across body with rotation", "Landmine Press"),
        ex("Step-up", 3, 10, 60, "Moderate DBs", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Drive through top foot, full extension", "Reverse Lunge"),
        ex("Single-Arm Dumbbell Row", 3, 10, 60, "Moderate-heavy", "Dumbbells", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Support on bench, pull to hip, squeeze", "Cable Row"),
        ex("Goblet Squat", 3, 12, 60, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold at chest, full depth, elbows between knees", "Front Squat"),
        ex("Plank", 3, 1, 30, "Hold 60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Straight line, engage everything", "Dead Bug"),
        ex("Sled Push", 3, 1, 90, "Moderate load, 30m", "Sled", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Low grip, drive through legs, lean forward", "Farmer's Walk"),
    ])

def batsman_endurance_b():
    return wo("Batsman Running Between Wickets", "conditioning", 40, [
        ex("Shuttle Run", 5, 6, 60, "22-yard shuttles", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Sprint, decelerate, turn, sprint back", "Sprint"),
        ex("Tempo Run", 3, 1, 120, "400m at 70% effort", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Controlled pace, maintain form throughout", "Jog"),
        ex("Lateral Bound", 3, 10, 60, "Maximum distance", "Bodyweight", "Legs", "Glutes", ["Hip Abductors", "Quadriceps"], "intermediate", "Stick each landing, minimize ground contact", "Lateral Shuffle"),
        ex("High Knees", 3, 30, 30, "Rapid pace", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees above hip height, quick arms", "Marching"),
        ex("Bodyweight Squat", 3, 20, 30, "Quick tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, controlled rhythm", "Air Squat"),
    ])

# ========================================================================
# KABADDI WARRIOR
# ========================================================================
def kabaddi_strength():
    return wo("Kabaddi Strength & Grappling", "strength", 55, [
        ex("Deadlift", 4, 5, 120, "80-90% 1RM", "Barbell", "Legs", "Glutes", ["Hamstrings", "Lower Back"], "intermediate", "Flat back, hinge at hips, lock out", "Trap Bar Deadlift"),
        ex("Bench Press", 3, 8, 90, "70-80% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Arch back slightly, drive feet, bar to chest", "Dumbbell Press"),
        ex("Barbell Row", 3, 8, 90, "Heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, row to lower chest", "Cable Row"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy DBs, 40m", "Dumbbells", "Full Body", "Forearms", ["Traps", "Core"], "intermediate", "Tight grip, short quick steps, shoulders back", "Suitcase Carry"),
        ex("Turkish Get-up", 3, 3, 90, "Moderate KB", "Kettlebell", "Full Body", "Core", ["Shoulders", "Hips", "Glutes"], "advanced", "Keep eye on KB, controlled transitions", "Floor Press to Sit-up"),
        ex("Rope Climb", 3, 2, 120, "15-foot rope", "Rope", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "advanced", "Pinch with feet, pull with arms", "Towel Pull-up"),
    ])

def kabaddi_agility():
    return wo("Kabaddi Raiding Agility", "conditioning", 45, [
        ex("Bear Crawl", 3, 1, 45, "20m distance", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "intermediate", "Low hips, opposite hand/foot, quick movement", "Army Crawl"),
        ex("Lateral Shuffle", 4, 30, 45, "10m each way", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Low stance, quick feet, stay low", "Carioca"),
        ex("Sprawl", 4, 8, 60, "Quick ground contact", "Bodyweight", "Full Body", "Core", ["Hip Flexors", "Quadriceps"], "intermediate", "Drop hips to ground, immediately get up", "Burpee"),
        ex("Sprint to Backpedal", 3, 8, 60, "10m forward, 10m back", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Sprint forward, transition to backpedal", "Shuttle Run"),
        ex("Medicine Ball Chest Pass", 3, 12, 45, "4-6 kg ball", "Medicine Ball", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Explosive pass from chest, catch on return", "Push-up"),
        ex("Plank to Push-up", 3, 10, 45, "Alternate lead arm", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Forearm plank to push-up position, alternate", "Push-up"),
    ])

# ========================================================================
# FIELD HOCKEY CONDITIONING
# ========================================================================
def hockey_lower():
    return wo("Field Hockey Lower Body Power", "strength", 50, [
        ex("Trap Bar Deadlift", 4, 6, 120, "80% 1RM", "Trap Bar", "Legs", "Glutes", ["Hamstrings", "Quadriceps"], "intermediate", "Drive through floor, neutral spine", "Barbell Deadlift"),
        ex("Front Squat", 3, 8, 90, "70-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows high, upright torso", "Goblet Squat"),
        ex("Lateral Lunge", 3, 10, 60, "Moderate DBs", "Dumbbells", "Legs", "Hip Adductors", ["Quadriceps", "Glutes"], "intermediate", "Wide step, push hips back, chest up", "Cossack Squat"),
        ex("Nordic Hamstring Curl", 3, 5, 90, "Bodyweight", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "advanced", "Control eccentric, push back up with hands", "Hamstring Curl"),
        ex("Single-Leg Hip Thrust", 3, 10, 60, "Bodyweight", "Bench", "Legs", "Glutes", ["Hamstrings"], "intermediate", "One leg elevated, drive through planted heel", "Glute Bridge"),
        ex("Calf Raise", 3, 15, 30, "Moderate weight", "Smith Machine", "Legs", "Calves", ["Soleus"], "beginner", "Full range, pause at top", "Seated Calf Raise"),
    ])

def hockey_agility():
    return wo("Field Hockey Agility & Stick Skills Conditioning", "conditioning", 45, [
        ex("T-Drill", 4, 4, 90, "Sprint/shuffle/backpedal", "Cones", "Legs", "Quadriceps", ["Hip Abductors", "Calves"], "intermediate", "Sprint forward, shuffle left/right, backpedal", "Shuttle Run"),
        ex("5-10-5 Shuttle", 4, 4, 90, "Pro agility drill", "Cones", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Quick direction change, low center of gravity", "Shuttle Run"),
        ex("Low Stance Hold", 3, 1, 45, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Core", "Lower Back"], "beginner", "Athletic crouch like holding a hockey stick", "Wall Sit"),
        ex("Sprint with Direction Change", 4, 6, 60, "Cone drill", "Cones", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Sprint to cone, cut 90 degrees, repeat", "Shuttle Run"),
        ex("Medicine Ball Rotational Throw", 3, 10, 45, "4-6 kg ball", "Medicine Ball", "Core", "Obliques", ["Shoulders", "Hips"], "intermediate", "Simulate hitting motion, rotate from hips", "Cable Woodchop"),
    ])

def hockey_upper():
    return wo("Field Hockey Upper Body & Core", "strength", 45, [
        ex("Single-Arm Cable Row", 3, 10, 60, "Moderate cable", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "One arm at a time, squeeze at contraction", "Dumbbell Row"),
        ex("Push-up", 3, 15, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, elbows at 45 degrees", "Bench Press"),
        ex("Pallof Press", 3, 12, 45, "Light cable", "Cable Machine", "Core", "Transverse Abdominis", ["Obliques"], "intermediate", "Press out, resist rotation, hold 2 seconds", "Plank with Rotation"),
        ex("Cable Woodchop", 3, 12, 45, "High to low", "Cable Machine", "Core", "Obliques", ["Shoulders"], "intermediate", "Rotate from thoracic spine, pivot back foot", "Medicine Ball Rotation"),
        ex("Face Pull", 3, 15, 30, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rotator Cuff", "Rhomboids"], "beginner", "Pull to face, external rotate, squeeze", "Band Pull-Apart"),
    ])


# ========================================================================
# GENERATE ALL PROGRAMS
# ========================================================================

programs = [
    ("Volleyball Jump Training", "Sports", "Vertical jump training and agility for volleyball players",
     [4, 8], [3, 4], "Low",
     lambda w, t: [volleyball_lower(), volleyball_upper(), volleyball_agility(), volleyball_lower()]),

    ("Sprint Training", "Sports", "Speed development for sprinters and athletes needing acceleration",
     [2, 4, 8], [3, 4], "Low",
     lambda w, t: [sprint_speed(), sprint_strength(), sprint_speed(), sprint_strength()]),

    ("Captain's Complete Cricket", "Sports", "All-round cricketer fitness covering batting, bowling, and fielding",
     [4, 8, 12], [5, 6], "Low",
     lambda w, t: [cricket_batting(), cricket_bowling(), cricket_fielding(), cricket_batting(), cricket_bowling(), cricket_fielding()]),

    ("Wicketkeeper Agility", "Sports", "Quick reflexes, squat endurance, and diving agility for wicketkeepers",
     [4, 8], [4, 5], "Low",
     lambda w, t: [wicketkeeper_lower(), wicketkeeper_reaction(), wicketkeeper_lower(), wicketkeeper_reaction(), wicketkeeper_lower()]),

    ("Fast Bowler Power", "Sports", "Shoulder strength, trunk rotation power, and run-up stamina for fast bowlers",
     [4, 8, 12], [4, 5], "Low",
     lambda w, t: [fast_bowler_upper(), fast_bowler_lower(), fast_bowler_upper(), fast_bowler_lower(), fast_bowler_upper()]),

    ("Batsman Endurance", "Sports", "Long innings conditioning with focus on running between wickets and shot power",
     [4, 8], [4, 5], "Low",
     lambda w, t: [batsman_endurance_a(), batsman_endurance_b(), batsman_endurance_a(), batsman_endurance_b(), batsman_endurance_a()]),

    ("Kabaddi Warrior", "Sports", "Raiding agility, grappling strength, and defensive fitness for kabaddi",
     [4, 8, 12], [5, 6], "Low",
     lambda w, t: [kabaddi_strength(), kabaddi_agility(), kabaddi_strength(), kabaddi_agility(), kabaddi_strength(), kabaddi_agility()]),

    ("Field Hockey Conditioning", "Sports", "Low stance endurance, sprint speed, and stick work conditioning",
     [4, 8, 12], [4, 5], "Low",
     lambda w, t: [hockey_lower(), hockey_agility(), hockey_upper(), hockey_lower(), hockey_agility()]),
]

for prog_name, cat, desc, durs, sessions_list, pri, workout_fn in programs:
    if helper.check_program_exists(prog_name):
        print(f"{prog_name} - ALREADY EXISTS, skipping")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: build base fitness and technique"
            elif p <= 0.66: focus = f"Week {w} - Development: increase intensity and complexity"
            else: focus = f"Week {w} - Peak: maximum performance and sport-specific work"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

helper.close()
print("\n=== REMAINING SPORTS PROGRAMS COMPLETE ===")
