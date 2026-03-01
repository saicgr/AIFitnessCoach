#!/usr/bin/env python3
"""Generate Yoga, Pilates, Flexibility, and Bodyweight programs."""
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
# YOGA - Vinyasa Flow, Power Yoga, Beginner Yoga
# ========================================================================

def vinyasa_flow():
    return wo("Vinyasa Flow", "yoga", 45, [
        ex("Sun Salutation A", 3, 5, 0, "Flow with breath", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings", "Back"], "beginner", "One breath per movement, smooth transitions", "Half Sun Salutation"),
        ex("Warrior I", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core", "Shoulders"], "beginner", "Back foot 45 degrees, square hips forward", "Crescent Lunge"),
        ex("Warrior II", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Core"], "beginner", "Front knee over ankle, gaze over front hand", "Extended Side Angle"),
        ex("Triangle Pose", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Hamstrings", ["Obliques", "Hip Adductors"], "beginner", "Straight front leg, reach down and up", "Extended Side Angle"),
        ex("Downward Facing Dog", 3, 1, 0, "Hold 45 seconds", "Bodyweight", "Full Body", "Shoulders", ["Hamstrings", "Calves", "Core"], "beginner", "Push floor away, heels toward ground", "Puppy Pose"),
        ex("Chaturanga Dandasana", 3, 5, 0, "Part of vinyasa flow", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Core"], "intermediate", "Elbows hug ribs, lower with control", "Knee Chaturanga"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Hip Flexors", "Piriformis"], "beginner", "Square hips, fold forward for deeper stretch", "Reclining Pigeon"),
        ex("Savasana", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Complete relaxation, conscious breathing", "Seated Meditation"),
    ])

def power_yoga():
    return wo("Power Yoga", "yoga", 55, [
        ex("Sun Salutation B", 3, 5, 0, "Vigorous pace with breath", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders", "Back"], "intermediate", "Chair pose to warrior I, faster flow", "Sun Salutation A"),
        ex("Chair Pose", 3, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core", "Shoulders"], "intermediate", "Sink deep, weight in heels, arms up", "Wall Sit"),
        ex("Warrior III", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core", "Lower Back"], "intermediate", "Hinge forward, extend back leg, T-shape", "Single-Leg Deadlift"),
        ex("Crow Pose", 3, 1, 0, "Hold 10-20 seconds", "Bodyweight", "Arms", "Core", ["Shoulders", "Triceps", "Hip Flexors"], "advanced", "Knees on backs of arms, lean forward, lift feet", "Frog Stand"),
        ex("Side Plank", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Glutes"], "intermediate", "Stack feet, lift hips, reach up", "Forearm Side Plank"),
        ex("Boat Pose", 3, 1, 0, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "intermediate", "Legs up, arms reaching forward, V-shape", "Bent-Knee Boat"),
        ex("Wheel Pose", 2, 1, 0, "Hold 15-20 seconds", "Bodyweight", "Back", "Erector Spinae", ["Shoulders", "Quadriceps", "Glutes"], "advanced", "Push up into backbend, straighten arms", "Bridge Pose"),
    ])

def beginner_yoga():
    return wo("Gentle Beginner Yoga", "yoga", 35, [
        ex("Cat-Cow", 3, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Inhale arch, exhale round, slow rhythm", "Seated Cat-Cow"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, reach arms forward, forehead down", "Puppy Pose"),
        ex("Mountain Pose", 2, 1, 0, "Hold 30 seconds, awareness", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Calves"], "beginner", "Stand tall, engage everything lightly", "Standing"),
        ex("Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Bend knees if needed, let head hang", "Ragdoll"),
        ex("Cobra Pose", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Low cobra, elbows bent, shoulders down", "Baby Cobra"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Glutes"], "beginner", "Knees to one side, look opposite", "Seated Twist"),
    ])

# Generate yoga programs
programs = [
    ("Vinyasa Flow", "Yoga", [2, 4, 8], [3, 4], "Flowing movement synchronized with breath - builds strength, flexibility, and mindfulness", "High",
     lambda w, t: [vinyasa_flow(), power_yoga(), vinyasa_flow()]),
    ("Power Yoga", "Yoga", [2, 4, 8], [3, 4], "Vigorous, fitness-based yoga for strength and endurance", "High",
     lambda w, t: [power_yoga(), vinyasa_flow(), power_yoga()]),
    ("Beginner Yoga", "Yoga", [2, 4, 8], [3, 4], "Gentle introduction to yoga for complete beginners", "High",
     lambda w, t: [beginner_yoga(), beginner_yoga(), beginner_yoga()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in programs:
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: learn poses and breathing"
            elif p <= 0.66: focus = f"Week {w} - Deepening: longer holds, more challenging poses"
            else: focus = f"Week {w} - Flow: link sequences, build endurance"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

# ========================================================================
# PILATES - Mat Pilates, Reformer-Style
# ========================================================================

def mat_pilates():
    return wo("Mat Pilates", "pilates", 45, [
        ex("The Hundred", 1, 100, 0, "100 arm pumps", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "intermediate", "Legs at 45, pump arms, breathe 5 in/5 out", "Modified Hundred"),
        ex("Roll Up", 3, 8, 30, "Slow and controlled", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Articulate spine one vertebra at a time", "Half Roll Up"),
        ex("Single Leg Circle", 2, 8, 0, "Each leg, each direction", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Stable pelvis, circle from hip", "Bent-Knee Circle"),
        ex("Rolling Like a Ball", 3, 8, 0, "Rock back and forth", "Bodyweight", "Core", "Rectus Abdominis", ["Lower Back"], "beginner", "Tight ball, roll on mid-back", "Seated Balance"),
        ex("Single Leg Stretch", 3, 10, 0, "Alternating legs", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "One knee to chest, other extends, switch", "Bent-Knee Version"),
        ex("Swimming", 3, 20, 30, "Alternating arm/leg lifts", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "intermediate", "Prone, flutter arms and legs, breathe", "Superman"),
        ex("Plank", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, engage entire body", "Forearm Plank"),
        ex("Side-Lying Leg Lifts", 3, 15, 0, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Obliques", "Hip Abductors"], "beginner", "Stack hips, lift with control", "Clamshell"),
    ])

for prog_name, durs, desc in [
    ("Mat Pilates", [2, 4, 8], "Classical mat Pilates for core strength, flexibility, and body control"),
    ("Core Pilates", [2, 4, 8], "Pilates-based core strengthening for stability and posture"),
]:
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Learn Pilates principles: breathing, centering, control"
            elif p <= 0.66: focus = f"Week {w} - Build endurance: longer sequences, fewer breaks"
            else: focus = f"Week {w} - Challenge: full sequences, advanced modifications"
            weeks[w] = {"focus": focus, "workouts": [mat_pilates(), mat_pilates(), mat_pilates()]}
        for sess in [3, 4]:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, "Pilates", desc, durs, [3, 4], False, "High", weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

# ========================================================================
# FLEXIBILITY - Dynamic Stretching, Full Body Stretch
# ========================================================================

def dynamic_stretch():
    return wo("Dynamic Stretching", "flexibility", 25, [
        ex("Leg Swing Forward", 2, 15, 0, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings", "Quadriceps"], "beginner", "Hold support, swing leg front to back", "Standing Leg Raise"),
        ex("Arm Circles", 2, 15, 0, "Forward then backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, get bigger", "Shoulder Roll"),
        ex("Walking Knee Hug", 2, 10, 0, "Alternate legs", "Bodyweight", "Hips", "Glutes", ["Hip Flexors"], "beginner", "Hug knee to chest while walking", "Standing Knee Hug"),
        ex("Inchworm", 2, 6, 0, "Walk hands out and back", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Keep legs straight, walk out to plank, walk back", "Standing Forward Fold"),
        ex("World's Greatest Stretch", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings", "Shoulders"], "beginner", "Lunge, rotate, reach - one of each", "Spiderman Stretch"),
        ex("Hip Circle", 2, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Hip Adductors"], "beginner", "Big circles with hips", "Standing Hip Rotation"),
    ])

def full_body_stretch():
    return wo("Full Body Stretch", "flexibility", 30, [
        ex("Standing Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Fold from hips, let head hang heavy", "Seated Forward Fold"),
        ex("Quad Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, stand tall", "Lying Quad Stretch"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Chest Opener Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arms behind, open chest, squeeze back", "Doorway Stretch"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Knees wide, reach forward, breathe", "Puppy Pose"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Knees to side, opposite shoulder down", "Seated Twist"),
    ])

for prog_name, durs, desc in [
    ("Dynamic Stretching", [1, 2, 4], "Pre-workout dynamic stretching routine for mobility and injury prevention"),
    ("Full Body Stretch", [1, 2, 4], "Complete stretching routine for full-body flexibility and recovery"),
    ("Yoga Flexibility", [2, 4, 8], "Yoga-based flexibility program for improved range of motion"),
]:
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Gentle: ease into stretches, don't force"
            elif p <= 0.66: focus = f"Week {w} - Deepen: hold longer, explore end range"
            else: focus = f"Week {w} - Advance: deeper stretches, longer holds"
            if "Dynamic" in prog_name:
                wkts = [dynamic_stretch(), dynamic_stretch(), dynamic_stretch()]
            elif "Yoga" in prog_name:
                wkts = [vinyasa_flow(), beginner_yoga(), vinyasa_flow()]
            else:
                wkts = [full_body_stretch(), full_body_stretch(), full_body_stretch()]
            weeks[w] = {"focus": focus, "workouts": wkts}
        for sess in [3, 4, 5]:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, "Flexibility/Stretches", desc, durs, [3, 4, 5], False,
                                   "High" if "Dynamic" in prog_name or "Full Body" in prog_name else "High",
                                   weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

helper.close()
print("\n=== YOGA + PILATES + FLEXIBILITY COMPLETE ===")
