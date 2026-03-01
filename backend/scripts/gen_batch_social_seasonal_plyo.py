#!/usr/bin/env python3
"""Generate programs for Categories 43-52: Social, Seasonal, Sleep, Menstrual, Medical, Desk Break, Plyo, Olympic, Swimming, Climbing."""
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
# CAT 43 - SOCIAL/COMMUNITY FITNESS
# ========================================================================

def partner_circuit():
    return wo("Partner Circuit", "circuit", 40, [
        ex("Partner Medicine Ball Pass", 3, 15, 30, "Use 6-10lb ball", "Medicine Ball", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Face partner, twist and pass at chest height", "Solo Medicine Ball Twist"),
        ex("Partner Squat Hold & High Five", 3, 12, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Both squat, high five at top of each rep", "Bodyweight Squat"),
        ex("Wheelbarrow Walk", 3, 30, 45, "Hold partner ankles", "Bodyweight", "Arms", "Shoulders", ["Core", "Triceps", "Chest"], "intermediate", "Tight core, walk on hands while partner holds legs", "Bear Crawl"),
        ex("Partner Plank Clap", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Obliques"], "beginner", "Face each other in plank, alternate hand claps", "Regular Plank"),
        ex("Band Resisted Sprint", 3, 6, 60, "Use resistance band", "Resistance Band", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Calves"], "intermediate", "Partner holds band around waist, sprint against resistance", "Sprint in Place"),
        ex("Partner Leg Throw", 3, 12, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Lie down, partner throws legs down, resist and return", "Lying Leg Raise"),
    ])

def group_hiit():
    return wo("Group HIIT Circuit", "hiit", 35, [
        ex("Burpee", 3, 10, 20, "Bodyweight explosive", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Shoulders", "Core"], "intermediate", "Chest to floor, jump up explosively", "Squat Thrust"),
        ex("Mountain Climber", 3, 30, 20, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Alternate knees to chest rapidly, hips low", "Slow Mountain Climber"),
        ex("Jump Squat", 3, 12, 30, "Bodyweight explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explode up, soft landing", "Bodyweight Squat"),
        ex("Push-Up", 3, 15, 20, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Full range, chest to floor", "Knee Push-Up"),
        ex("High Knees", 3, 30, 20, "Sprint pace", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core", "Calves"], "beginner", "Drive knees above hip height, pump arms", "Marching in Place"),
        ex("Plank to Shoulder Tap", 3, 16, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Obliques"], "beginner", "Minimal hip rotation, alternate taps", "Forearm Plank"),
    ])

def bootcamp_workout():
    return wo("Community Bootcamp", "circuit", 45, [
        ex("Bear Crawl", 3, 30, 30, "Bodyweight", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps", "Triceps"], "intermediate", "Knees 2 inches off ground, opposite hand and foot move", "Crawling"),
        ex("Squat Jump", 3, 15, 30, "Bodyweight explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Full depth squat, max height jump", "Bodyweight Squat"),
        ex("Push-Up Walkout", 3, 8, 30, "Bodyweight", "Bodyweight", "Full Body", "Chest", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Stand, walk hands to plank, push-up, walk back", "Inchworm"),
        ex("Lateral Shuffle", 3, 30, 30, "Quick feet", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves", "Glutes"], "beginner", "Stay low, quick lateral steps, touch ground", "Side Step"),
        ex("V-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Arms and legs meet at top, control descent", "Crunch"),
        ex("Broad Jump", 3, 8, 45, "Max distance", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Calves"], "intermediate", "Swing arms, jump forward, stick landing", "Squat Jump"),
    ])

def family_fitness():
    return wo("Family Fitness Fun", "circuit", 30, [
        ex("Jumping Jack", 3, 20, 15, "Bodyweight", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Quadriceps"], "beginner", "Full arm extension, land softly", "Half Jack"),
        ex("Bodyweight Squat", 3, 12, 20, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Sit back, knees track toes, full depth", "Wall Sit"),
        ex("Crab Walk", 2, 30, 20, "Bodyweight", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core", "Glutes"], "beginner", "Belly up, hands and feet, walk forward and back", "Glute Bridge"),
        ex("Star Jump", 3, 10, 20, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Glutes", "Shoulders", "Calves"], "beginner", "Squat then jump making a star shape", "Jumping Jack"),
        ex("Plank Hold", 2, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "beginner", "Straight line from head to heels", "Knee Plank"),
    ])

def social_run():
    return wo("Social Run Club", "cardio", 40, [
        ex("Dynamic Warm-Up Jog", 1, 1, 0, "Easy pace 5 minutes", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Conversational pace, loosen up", "Walking"),
        ex("Interval Run", 4, 1, 60, "Moderate to hard effort 3 min", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "intermediate", "Push pace for 3 min, recover 1 min", "Brisk Walk"),
        ex("Side Shuffle Drill", 2, 30, 30, "Quick lateral movement", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Stay low, quick steps, arms ready", "Lateral Walk"),
        ex("High Knees Run", 3, 30, 30, "Fast pace", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Calves", "Core"], "beginner", "Drive knees high, pump arms", "Marching"),
        ex("Cool Down Walk", 1, 1, 0, "5 minutes easy", "Bodyweight", "Legs", "Calves", ["Hamstrings", "Quadriceps"], "beginner", "Gradual slow down, deep breathing", "Standing Stretches"),
    ])

cat43_programs = [
    ("Workout Buddy System", "Social/Community Fitness", [2, 4, 8], [3, 4], "Structured partner workouts for mutual motivation and accountability", "High",
     lambda w, t: [partner_circuit(), group_hiit(), partner_circuit()]),
    ("Group Fitness Challenge", "Social/Community Fitness", [2, 4, 8], [3, 4], "Competitive group challenges to push limits together", "High",
     lambda w, t: [group_hiit(), bootcamp_workout(), group_hiit()]),
    ("Partner Workout", "Social/Community Fitness", [2, 4, 8], [3, 4], "Two-person exercises requiring cooperation and teamwork", "High",
     lambda w, t: [partner_circuit(), partner_circuit(), partner_circuit()]),
    ("Family Fitness", "Social/Community Fitness", [2, 4, 8], [3, 4], "Fun, accessible workouts the whole family can do together", "High",
     lambda w, t: [family_fitness(), family_fitness(), family_fitness()]),
    ("Couples Workout", "Social/Community Fitness", [2, 4, 8], [3, 4], "Romantic and fun partner exercises to stay fit together", "High",
     lambda w, t: [partner_circuit(), family_fitness(), partner_circuit()]),
    ("Community Bootcamp", "Social/Community Fitness", [2, 4, 8], [3, 4], "High-energy outdoor bootcamp for groups of all sizes", "High",
     lambda w, t: [bootcamp_workout(), group_hiit(), bootcamp_workout()]),
    ("Team Building Fitness", "Social/Community Fitness", [2, 4, 8], [3, 4], "Corporate and team exercises designed to build camaraderie", "High",
     lambda w, t: [bootcamp_workout(), partner_circuit(), family_fitness()]),
    ("Social Run Club", "Social/Community Fitness", [2, 4, 8], [3, 4], "Group running program with intervals and social pacing", "High",
     lambda w, t: [social_run(), social_run(), social_run()]),
    ("Group HIIT", "Social/Community Fitness", [2, 4, 8], [3, 4], "High-intensity interval training optimized for group settings", "High",
     lambda w, t: [group_hiit(), group_hiit(), group_hiit()]),
    ("Accountability Challenge", "Social/Community Fitness", [2, 4, 8], [3, 4], "30-day structured challenge with daily check-ins and group support", "High",
     lambda w, t: [group_hiit(), bootcamp_workout(), partner_circuit()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat43_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Build community: learn partner exercises, establish group rhythm"
            elif p <= 0.66: focus = f"Week {w} - Challenge together: increase intensity, friendly competition"
            else: focus = f"Week {w} - Peak together: max effort group sessions, celebrate progress"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 43 COMPLETE ===")

# ========================================================================
# CAT 44 - SEASONAL/CLIMATE TRAINING
# ========================================================================

def summer_outdoor():
    return wo("Summer Outdoor Session", "circuit", 40, [
        ex("Sprint Interval", 4, 1, 60, "80% effort 30 sec sprints", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "intermediate", "All-out sprint, full arm drive, 60s rest", "Fast Jog"),
        ex("Bodyweight Squat", 3, 20, 30, "Bodyweight high rep", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, control tempo", "Wall Sit"),
        ex("Push-Up", 3, 15, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Full range of motion", "Knee Push-Up"),
        ex("Burpee", 3, 10, 45, "Bodyweight explosive", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Shoulders", "Core"], "intermediate", "Chest to ground, explosive jump", "Squat Thrust"),
        ex("Mountain Climber", 3, 30, 30, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Drive knees to chest rapidly", "Slow Mountain Climber"),
        ex("Jump Lunge", 3, 16, 30, "Bodyweight explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Calves"], "intermediate", "Alternate legs in air, land softly", "Reverse Lunge"),
    ])

def indoor_winter():
    return wo("Winter Indoor Training", "strength", 45, [
        ex("Goblet Squat", 4, 12, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold dumbbell at chest, elbows inside knees", "Bodyweight Squat"),
        ex("Dumbbell Row", 4, 10, 60, "Moderate dumbbell", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull elbow past torso, squeeze back", "Resistance Band Row"),
        ex("Dumbbell Floor Press", 4, 10, 60, "Moderate dumbbells", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Elbows touch floor at bottom, press up", "Push-Up"),
        ex("Romanian Deadlift", 3, 12, 60, "Moderate dumbbells", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, slight knee bend, feel hamstring stretch", "Good Morning"),
        ex("Dumbbell Shoulder Press", 3, 10, 60, "Moderate dumbbells", "Dumbbell", "Shoulders", "Deltoids", ["Triceps", "Upper Chest"], "beginner", "Press overhead, full lockout", "Pike Push-Up"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, squeeze everything", "Forearm Plank"),
    ])

def rainy_day():
    return wo("Rainy Day Home Workout", "circuit", 30, [
        ex("Bodyweight Squat", 3, 20, 20, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, controlled tempo", "Wall Sit"),
        ex("Push-Up", 3, 15, 20, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Full range", "Knee Push-Up"),
        ex("Glute Bridge", 3, 15, 20, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze glutes at top, hold 2 sec", "Single-Leg Glute Bridge"),
        ex("Superman", 3, 12, 20, "Bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Lift arms and legs, hold 2 seconds", "Bird Dog"),
        ex("Bicycle Crunch", 3, 20, 20, "Bodyweight", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Elbow to opposite knee, slow and controlled", "Crunch"),
        ex("Jumping Jack", 3, 30, 20, "Bodyweight cardio", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Quadriceps"], "beginner", "Full extension, rhythmic pace", "Half Jack"),
    ])

cat44_programs = [
    ("Summer Body Prep", "Seasonal/Climate Training", [4, 8, 12], [3, 4], "Get beach-ready with fat-burning circuits and toning exercises", "High",
     lambda w, t: [summer_outdoor(), group_hiit(), summer_outdoor()]),
    ("Winter Indoor Training", "Seasonal/Climate Training", [4, 8, 12], [3, 4], "Stay strong indoors when it is too cold to train outside", "High",
     lambda w, t: [indoor_winter(), indoor_winter(), indoor_winter()]),
    ("Rainy Day Workout", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Equipment-free home workout for when weather keeps you inside", "High",
     lambda w, t: [rainy_day(), rainy_day(), rainy_day()]),
    ("Hot Weather Training", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Heat-adapted training with shorter bursts and hydration focus", "High",
     lambda w, t: [summer_outdoor(), rainy_day(), summer_outdoor()]),
    ("Cold Weather Training", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Extended warm-ups and indoor alternatives for cold months", "High",
     lambda w, t: [indoor_winter(), rainy_day(), indoor_winter()]),
    ("Spring Reset", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Shake off winter with progressive outdoor fitness", "High",
     lambda w, t: [rainy_day(), summer_outdoor(), rainy_day()]),
    ("Fall Fitness", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Transition from summer to indoor training with hybrid sessions", "High",
     lambda w, t: [indoor_winter(), summer_outdoor(), indoor_winter()]),
    ("Holiday Workout", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Quick effective sessions to stay on track during holidays", "High",
     lambda w, t: [rainy_day(), group_hiit(), rainy_day()]),
    ("Seasonal Transition", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Gradual adaptation between indoor and outdoor training", "High",
     lambda w, t: [indoor_winter(), rainy_day(), summer_outdoor()]),
    ("Beach Season Prep", "Seasonal/Climate Training", [4, 8, 12], [3, 4], "Targeted physique training for beach confidence", "High",
     lambda w, t: [summer_outdoor(), group_hiit(), summer_outdoor()]),
    ("Ski Season Prep", "Seasonal/Climate Training", [4, 8, 12], [3, 4], "Leg strength, balance, and endurance for skiing and snowboarding", "High",
     lambda w, t: [indoor_winter(), bootcamp_workout(), indoor_winter()]),
    ("Festival Season Prep", "Seasonal/Climate Training", [2, 4, 8], [3, 4], "Build stamina for long days on your feet at festivals", "High",
     lambda w, t: [summer_outdoor(), social_run(), summer_outdoor()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat44_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Adapt: acclimate to seasonal demands, build base"
            elif p <= 0.66: focus = f"Week {w} - Build: increase volume and intensity for the season"
            else: focus = f"Week {w} - Peak: season-ready performance and conditioning"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 44 COMPLETE ===")

# ========================================================================
# CAT 45 - SLEEP & RECOVERY OPTIMIZATION
# ========================================================================

def pm_wind_down():
    return wo("PM Wind Down", "recovery", 20, [
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, reach forward, breathe deeply", "Puppy Pose"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Glutes"], "beginner", "Knees to one side, opposite shoulder down", "Seated Twist"),
        ex("Legs Up The Wall", 2, 1, 0, "Hold 3 minutes", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Scoot hips to wall, legs vertical, relax", "Elevated Legs on Chair"),
        ex("Cat-Cow", 2, 10, 0, "Slow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Inhale arch, exhale round, 4-count each", "Seated Cat-Cow"),
        ex("Diaphragmatic Breathing", 2, 10, 0, "4-7-8 pattern", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale 4 counts, hold 7, exhale 8", "Box Breathing"),
    ])

def foam_rolling():
    return wo("Foam Rolling Recovery", "recovery", 25, [
        ex("Foam Roll Thoracic Spine", 2, 10, 0, "Roll mid-back", "Foam Roller", "Back", "Erector Spinae", ["Rhomboids", "Trapezius"], "beginner", "Cross arms, roll mid-back slowly, pause on tight spots", "Tennis Ball Back Roll"),
        ex("Foam Roll Quads", 2, 10, 0, "Roll each quad 60 sec", "Foam Roller", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Face down, roll from hip to knee, pause on knots", "Quad Stretch"),
        ex("Foam Roll IT Band", 2, 10, 0, "Roll each side 60 sec", "Foam Roller", "Legs", "IT Band", ["Quadriceps", "Glutes"], "beginner", "Side-lying, roll outer thigh hip to knee", "Side-Lying Stretch"),
        ex("Foam Roll Glutes", 2, 10, 0, "Roll each side 60 sec", "Foam Roller", "Glutes", "Gluteus Maximus", ["Piriformis"], "beginner", "Sit on roller, cross ankle over knee, roll", "Figure-4 Stretch"),
        ex("Foam Roll Calves", 2, 10, 0, "Roll each calf 60 sec", "Foam Roller", "Legs", "Calves", ["Soleus"], "beginner", "Sit with calf on roller, rotate foot in/out", "Calf Stretch"),
        ex("Foam Roll Lats", 2, 10, 0, "Roll each side 60 sec", "Foam Roller", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Side-lying, arm overhead, roll armpit to mid-torso", "Lat Stretch"),
    ])

def active_recovery():
    return wo("Active Recovery", "recovery", 30, [
        ex("Walking", 1, 1, 0, "10 minutes easy pace", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Hamstrings"], "beginner", "Easy conversational pace, focus on breathing", "Marching in Place"),
        ex("World's Greatest Stretch", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings"], "beginner", "Lunge, rotate, reach up", "Spiderman Stretch"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Slow, breath-driven movement", "Seated Cat-Cow"),
        ex("90/90 Hip Stretch", 2, 1, 0, "Hold 45 sec each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Flexors", "Piriformis"], "beginner", "Both legs at 90 degrees, tall spine, lean forward", "Seated Hip Stretch"),
        ex("Dead Hang", 2, 1, 30, "Hold 20-30 seconds", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Forearms", "Shoulders"], "beginner", "Relax shoulders, let spine decompress", "Doorframe Stretch"),
        ex("Deep Breathing", 2, 10, 0, "Box breathing 4-4-4-4", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Inhale 4, hold 4, exhale 4, hold 4", "Normal Breathing Focus"),
    ])

cat45_programs = [
    ("Sleep Optimization Movement", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Gentle movement patterns designed to improve sleep quality", "High",
     lambda w, t: [pm_wind_down(), active_recovery(), pm_wind_down()]),
    ("PM Wind Down", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Evening routine to calm the nervous system before bed", "High",
     lambda w, t: [pm_wind_down(), pm_wind_down(), pm_wind_down()]),
    ("Recovery Day Protocol", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Structured recovery day to maximize adaptation and repair", "High",
     lambda w, t: [active_recovery(), foam_rolling(), pm_wind_down()]),
    ("Active Recovery", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Low-intensity movement to promote blood flow and recovery", "High",
     lambda w, t: [active_recovery(), active_recovery(), active_recovery()]),
    ("Deep Recovery Week", "Sleep & Recovery Optimization", [1, 2, 4], [3, 4], "Full deload week protocol for complete physical reset", "High",
     lambda w, t: [pm_wind_down(), foam_rolling(), active_recovery()]),
    ("Sleep Yoga", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Yoga Nidra-inspired practice for deep relaxation", "High",
     lambda w, t: [pm_wind_down(), pm_wind_down(), pm_wind_down()]),
    ("Foam Rolling Routine", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Systematic foam rolling for myofascial release and recovery", "High",
     lambda w, t: [foam_rolling(), foam_rolling(), foam_rolling()]),
    ("Massage Gun Protocol", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Percussion therapy routine targeting major muscle groups", "High",
     lambda w, t: [foam_rolling(), active_recovery(), foam_rolling()]),
    ("Epsom Salt Bath Prep", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Pre-bath gentle movement to maximize relaxation benefits", "High",
     lambda w, t: [pm_wind_down(), active_recovery(), pm_wind_down()]),
    ("Recovery Breathing", "Sleep & Recovery Optimization", [2, 4, 8], [3, 4], "Breathwork protocols for parasympathetic activation", "High",
     lambda w, t: [pm_wind_down(), pm_wind_down(), pm_wind_down()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat45_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Awareness: learn recovery techniques and breathing"
            elif p <= 0.66: focus = f"Week {w} - Deepen: longer holds, deeper relaxation"
            else: focus = f"Week {w} - Integrate: full recovery protocols, sleep optimization"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 45 COMPLETE ===")

# ========================================================================
# CAT 46 - MENSTRUAL CYCLE SYNCED
# ========================================================================

def follicular_power():
    return wo("Follicular Phase Power", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 90, "Moderate-heavy, energy is high", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Break at hips, chest up, drive through heels", "Goblet Squat"),
        ex("Barbell Hip Thrust", 4, 10, 60, "Heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Full hip extension, squeeze glutes at top", "Glute Bridge"),
        ex("Dumbbell Shoulder Press", 3, 10, 60, "Moderate dumbbells", "Dumbbell", "Shoulders", "Deltoids", ["Triceps", "Upper Chest"], "beginner", "Press overhead, control descent", "Pike Push-Up"),
        ex("Pull-Up", 3, 8, 60, "Bodyweight or assisted", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full hang to chin over bar", "Lat Pulldown"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Tight core, squeeze glutes", "Forearm Plank"),
    ])

def luteal_recovery():
    return wo("Luteal Phase Recovery", "flexibility", 35, [
        ex("Walking Lunge", 3, 12, 30, "Bodyweight or light", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, knee tracks toe, upright torso", "Reverse Lunge"),
        ex("Cat-Cow", 2, 10, 0, "Slow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Sync with breath, reduce tension", "Seated Cat-Cow"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze at top, controlled movement", "Hip Thrust"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Breathe into lower back", "Puppy Pose"),
        ex("Standing Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Soft knees, let head hang", "Seated Forward Fold"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 sec each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Relax into the twist, breathe", "Seated Twist"),
    ])

def menstrual_gentle():
    return wo("Menstrual Phase Gentle", "recovery", 25, [
        ex("Walking", 1, 1, 0, "10 minutes easy pace", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Hamstrings"], "beginner", "Gentle pace, listen to body", "Marching in Place"),
        ex("Cat-Cow", 2, 10, 0, "Very gentle", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Small range, ease cramping", "Seated Cat-Cow"),
        ex("Supported Child's Pose", 2, 1, 0, "Hold 90 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Hips"], "beginner", "Use pillow under chest for support", "Regular Child's Pose"),
        ex("Supine Hip Circle", 2, 10, 0, "Gentle circles each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Lying down, gentle knee circles", "Seated Hip Circle"),
        ex("Legs Up The Wall", 1, 1, 0, "Hold 5 minutes", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Passive, let gravity drain legs", "Elevated Legs on Chair"),
    ])

def ovulation_peak():
    return wo("Ovulation Peak Performance", "hiit", 40, [
        ex("Jump Squat", 4, 12, 45, "Bodyweight explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Full squat depth, max height jump", "Bodyweight Squat"),
        ex("Push-Up to T-Rotation", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Shoulders"], "intermediate", "Push-up then rotate to side plank, alternate", "Push-Up"),
        ex("Kettlebell Swing", 4, 15, 45, "Moderate kettlebell", "Kettlebell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip hinge, snap hips, float the bell", "Dumbbell Swing"),
        ex("Box Jump", 3, 8, 60, "Step down each rep", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Swing arms, land softly, full hip extension", "Squat Jump"),
        ex("Renegade Row", 3, 10, 45, "Moderate dumbbells", "Dumbbell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row one arm, minimal rotation", "Bent-Over Row"),
        ex("Burpee", 3, 8, 45, "Full speed", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, explosive jump", "Squat Thrust"),
    ])

cat46_programs = [
    ("Follicular Phase Power", "Menstrual Cycle Synced", [2, 4, 8], [3, 4], "Capitalize on rising energy with strength and power training", "High",
     lambda w, t: [follicular_power(), ovulation_peak(), follicular_power()]),
    ("Ovulation Peak Performance", "Menstrual Cycle Synced", [2, 4, 8], [3, 4], "Maximum intensity training during peak hormone levels", "High",
     lambda w, t: [ovulation_peak(), ovulation_peak(), ovulation_peak()]),
    ("Luteal Phase Recovery", "Menstrual Cycle Synced", [2, 4, 8], [3, 4], "Lower intensity training as energy naturally decreases", "High",
     lambda w, t: [luteal_recovery(), luteal_recovery(), luteal_recovery()]),
    ("Menstrual Phase Gentle", "Menstrual Cycle Synced", [2, 4, 8], [3, 4], "Gentle restorative movement to ease menstrual discomfort", "High",
     lambda w, t: [menstrual_gentle(), menstrual_gentle(), menstrual_gentle()]),
    ("Full Cycle Training", "Menstrual Cycle Synced", [4, 8, 12], [3, 4], "Complete 28-day program synced to all four cycle phases", "High",
     lambda w, t: [follicular_power(), ovulation_peak(), luteal_recovery()]),
    ("Hormone Balance Workout", "Menstrual Cycle Synced", [2, 4, 8], [3, 4], "Exercise optimized for hormonal health and balance", "High",
     lambda w, t: [follicular_power(), luteal_recovery(), menstrual_gentle()]),
    ("PMS Relief Movement", "Menstrual Cycle Synced", [2, 4, 8], [3, 4], "Targeted movement to reduce bloating, cramps, and mood swings", "High",
     lambda w, t: [menstrual_gentle(), luteal_recovery(), menstrual_gentle()]),
    ("Endometriosis Safe", "Menstrual Cycle Synced", [2, 4, 8], [3, 4], "Low-impact exercise safe for endometriosis management", "High",
     lambda w, t: [menstrual_gentle(), luteal_recovery(), menstrual_gentle()]),
    ("PCOS Workout Plan", "Menstrual Cycle Synced", [4, 8, 12], [3, 4], "Insulin-sensitizing exercise plan for PCOS management", "High",
     lambda w, t: [follicular_power(), luteal_recovery(), follicular_power()]),
    ("Fertility Support Fitness", "Menstrual Cycle Synced", [4, 8, 12], [3, 4], "Moderate exercise to support reproductive health", "High",
     lambda w, t: [luteal_recovery(), menstrual_gentle(), luteal_recovery()]),
    ("Menopause Transition", "Menstrual Cycle Synced", [4, 8, 12], [3, 4], "Strength and bone-density focused training for menopause", "High",
     lambda w, t: [follicular_power(), luteal_recovery(), follicular_power()]),
    ("Perimenopause Training", "Menstrual Cycle Synced", [4, 8, 12], [3, 4], "Adapted training for hormonal fluctuations during perimenopause", "High",
     lambda w, t: [follicular_power(), luteal_recovery(), menstrual_gentle()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat46_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Learn: understand cycle phases and appropriate intensity"
            elif p <= 0.66: focus = f"Week {w} - Sync: match training intensity to cycle phase"
            else: focus = f"Week {w} - Optimize: fully adapted cycle-synced training"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 46 COMPLETE ===")

# ========================================================================
# CAT 47 - MEDICAL CONDITION SPECIFIC
# ========================================================================

def gentle_cardio_strength():
    return wo("Gentle Cardio & Strength", "strength", 30, [
        ex("Seated March", 3, 20, 20, "Seated in chair", "Chair", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Sit tall, alternate lifting knees, controlled pace", "Standing March"),
        ex("Wall Push-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Hands on wall shoulder width, lean in and push back", "Incline Push-Up"),
        ex("Seated Leg Extension", 3, 12, 30, "Bodyweight or light ankle weight", "Chair", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Extend one leg, hold 2 sec, lower slowly", "Standing Leg Raise"),
        ex("Standing Calf Raise", 3, 15, 20, "Hold wall for balance", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Rise onto toes, hold, lower slowly", "Seated Calf Raise"),
        ex("Arm Circle", 2, 15, 0, "Small to large circles", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, gradually increase", "Shoulder Shrug"),
        ex("Diaphragmatic Breathing", 2, 10, 0, "Focus on exhale", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Hand on belly, belly rises on inhale", "Normal Breathing"),
    ])

def chronic_pain_movement():
    return wo("Chronic Pain Movement", "recovery", 25, [
        ex("Pelvic Tilt", 3, 12, 15, "Gentle activation", "Bodyweight", "Core", "Rectus Abdominis", ["Lower Back", "Glutes"], "beginner", "Lying down, flatten lower back to floor, release", "Seated Pelvic Tilt"),
        ex("Knee to Chest Stretch", 2, 1, 0, "Hold 30 sec each side", "Bodyweight", "Back", "Lower Back", ["Glutes", "Hamstrings"], "beginner", "Gently pull one knee to chest while lying", "Seated Knee Hug"),
        ex("Cat-Cow", 2, 10, 0, "Very gentle pace", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Only move pain-free range", "Seated Cat-Cow"),
        ex("Glute Bridge", 2, 10, 20, "Gentle activation", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Small range, focus on engagement not height", "Pelvic Tilt"),
        ex("Neck Roll", 2, 5, 0, "Slow circles each direction", "Bodyweight", "Neck", "Trapezius", ["Levator Scapulae"], "beginner", "Drop chin, roll ear to shoulder, slow and gentle", "Neck Side Stretch"),
        ex("Walking", 1, 1, 0, "5-10 minutes easy", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Pain-free pace, stop if pain increases", "Standing March"),
    ])

def osteoporosis_prevention():
    return wo("Bone-Strengthening Workout", "strength", 35, [
        ex("Bodyweight Squat", 3, 12, 45, "Controlled tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Weight-bearing, stimulates bone density in hips/spine", "Wall Sit"),
        ex("Standing Heel Raise", 3, 15, 30, "Hold support for balance", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Full range, impact at bottom stimulates bone", "Seated Calf Raise"),
        ex("Step-Up", 3, 10, 45, "Low step, 6-8 inches", "Step Platform", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Drive through heel, full hip extension at top", "Bodyweight Squat"),
        ex("Standing Row", 3, 12, 45, "Light resistance band", "Resistance Band", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Squeeze shoulder blades, upright posture", "Seated Row"),
        ex("Wall Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Weight-bearing for wrist and shoulder bones", "Incline Push-Up"),
        ex("Standing Balance Hold", 3, 1, 20, "Hold 20 sec each leg", "Bodyweight", "Legs", "Gluteus Medius", ["Core", "Calves"], "beginner", "Stand on one leg, hold wall if needed, builds balance", "Tandem Stand"),
    ])

cat47_programs = [
    ("Diabetes Friendly", "Medical Condition Specific", [4, 8, 12], [3, 4], "Blood sugar regulating exercise with moderate intensity", "High",
     lambda w, t: [gentle_cardio_strength(), gentle_cardio_strength(), gentle_cardio_strength()]),
    ("Heart Condition Safe", "Medical Condition Specific", [4, 8, 12], [3, 4], "Low to moderate intensity training safe for cardiac patients", "High",
     lambda w, t: [gentle_cardio_strength(), chronic_pain_movement(), gentle_cardio_strength()]),
    ("Asthma Friendly", "Medical Condition Specific", [4, 8, 12], [3, 4], "Controlled breathing exercises with gradual cardio progression", "High",
     lambda w, t: [gentle_cardio_strength(), chronic_pain_movement(), gentle_cardio_strength()]),
    ("Chronic Pain Movement", "Medical Condition Specific", [4, 8, 12], [3, 4], "Gentle movement to manage and reduce chronic pain", "High",
     lambda w, t: [chronic_pain_movement(), chronic_pain_movement(), chronic_pain_movement()]),
    ("Fibromyalgia Gentle", "Medical Condition Specific", [4, 8, 12], [3, 4], "Ultra-gentle movement for fibromyalgia symptom management", "High",
     lambda w, t: [chronic_pain_movement(), chronic_pain_movement(), chronic_pain_movement()]),
    ("MS Exercise Program", "Medical Condition Specific", [4, 8, 12], [3, 4], "Adapted exercise for multiple sclerosis with fatigue management", "High",
     lambda w, t: [chronic_pain_movement(), gentle_cardio_strength(), chronic_pain_movement()]),
    ("Cancer Recovery", "Medical Condition Specific", [4, 8, 12], [3, 4], "Rebuilding strength and energy during or after cancer treatment", "High",
     lambda w, t: [chronic_pain_movement(), gentle_cardio_strength(), chronic_pain_movement()]),
    ("Autoimmune Support", "Medical Condition Specific", [4, 8, 12], [3, 4], "Anti-inflammatory movement for autoimmune conditions", "High",
     lambda w, t: [chronic_pain_movement(), gentle_cardio_strength(), chronic_pain_movement()]),
    ("Thyroid Support", "Medical Condition Specific", [4, 8, 12], [3, 4], "Metabolism-supporting exercise for thyroid conditions", "High",
     lambda w, t: [gentle_cardio_strength(), gentle_cardio_strength(), gentle_cardio_strength()]),
    ("Chronic Fatigue Movement", "Medical Condition Specific", [4, 8, 12], [3, 4], "Pacing-based exercise for chronic fatigue syndrome", "High",
     lambda w, t: [chronic_pain_movement(), chronic_pain_movement(), chronic_pain_movement()]),
    ("Osteoporosis Prevention", "Medical Condition Specific", [4, 8, 12], [3, 4], "Weight-bearing exercises to maintain and build bone density", "High",
     lambda w, t: [osteoporosis_prevention(), osteoporosis_prevention(), osteoporosis_prevention()]),
    ("High Blood Pressure Safe", "Medical Condition Specific", [4, 8, 12], [3, 4], "Moderate cardio and light resistance for blood pressure management", "High",
     lambda w, t: [gentle_cardio_strength(), chronic_pain_movement(), gentle_cardio_strength()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat47_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Gentle start: establish safe movement patterns"
            elif p <= 0.66: focus = f"Week {w} - Progress: gradually increase duration and intensity"
            else: focus = f"Week {w} - Maintain: sustainable exercise habits for long-term health"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 47 COMPLETE ===")

# ========================================================================
# CAT 48 - DESK BREAK MICRO-WORKOUTS
# ========================================================================

def desk_stretch_2min():
    return wo("2-Min Desk Stretch", "flexibility", 2, [
        ex("Neck Side Stretch", 1, 1, 0, "Hold 15 sec each side", "Bodyweight", "Neck", "Trapezius", ["Levator Scapulae"], "beginner", "Ear toward shoulder, gentle hand pressure", "Neck Roll"),
        ex("Seated Chest Opener", 1, 1, 0, "Hold 15 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Clasp hands behind back, squeeze shoulder blades", "Doorway Stretch"),
        ex("Seated Spinal Twist", 1, 1, 0, "Hold 15 sec each side", "Bodyweight", "Back", "Obliques", ["Erector Spinae"], "beginner", "Sit tall, twist from thoracic spine, breathe", "Standing Twist"),
        ex("Wrist Flexor Stretch", 1, 1, 0, "Hold 15 sec each hand", "Bodyweight", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back gently", "Wrist Circle"),
    ])

def standing_break_3min():
    return wo("3-Min Standing Break", "flexibility", 3, [
        ex("Standing Hip Circle", 1, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Core"], "beginner", "Hands on hips, big circles", "Seated Hip Shift"),
        ex("Calf Raise", 1, 15, 0, "Slow and controlled", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Rise on toes, hold 2 sec, lower", "Seated Calf Raise"),
        ex("Standing Side Bend", 1, 8, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Reach overhead, lean to side, feel lateral stretch", "Seated Side Bend"),
        ex("March in Place", 1, 20, 0, "Moderate pace", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Calves"], "beginner", "Lift knees high, pump arms", "Step Touch"),
        ex("Shoulder Roll", 1, 10, 0, "Forward then backward", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Big circles, release tension", "Shoulder Shrug"),
    ])

def office_hiit_5min():
    return wo("5-Min Office HIIT", "hiit", 5, [
        ex("Squat", 1, 15, 10, "Bodyweight, fast pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Fast but controlled, full depth", "Chair Squat"),
        ex("Desk Push-Up", 1, 12, 10, "Hands on desk edge", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Lean into desk, push back, incline angle", "Wall Push-Up"),
        ex("High Knees", 1, 20, 10, "Fast pace", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Drive knees up fast, light on feet", "Marching"),
        ex("Chair Dip", 1, 10, 10, "Hands on chair edge", "Chair", "Arms", "Triceps", ["Shoulders", "Chest"], "beginner", "Lower until 90 degrees, press up", "Wall Push-Up"),
        ex("Jumping Jack", 1, 20, 10, "Full speed", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Quadriceps"], "beginner", "Full extension, rhythmic", "Step Jack"),
    ])

def chair_yoga():
    return wo("Chair Yoga Break", "yoga", 5, [
        ex("Seated Cat-Cow", 1, 8, 0, "Slow with breath", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Hands on knees, arch and round spine", "Standing Cat-Cow"),
        ex("Seated Forward Fold", 1, 1, 0, "Hold 20 seconds", "Chair", "Back", "Hamstrings", ["Lower Back"], "beginner", "Fold forward from hips, let arms hang", "Standing Forward Fold"),
        ex("Seated Eagle Arms", 1, 1, 0, "Hold 20 sec each side", "Chair", "Shoulders", "Rhomboids", ["Deltoids", "Trapezius"], "beginner", "Cross arms, wrap forearms, lift elbows", "Seated Arm Cross"),
        ex("Seated Pigeon", 1, 1, 0, "Hold 30 sec each side", "Chair", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Ankle on opposite knee, lean forward", "Seated Figure-4"),
        ex("Seated Side Bend", 1, 1, 0, "Hold 15 sec each side", "Chair", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Reach overhead, bend to side", "Standing Side Bend"),
    ])

def posture_reset():
    return wo("Posture Reset Break", "flexibility", 3, [
        ex("Chin Tuck", 1, 10, 0, "Hold 5 seconds each", "Bodyweight", "Neck", "Deep Neck Flexors", ["Trapezius"], "beginner", "Pull chin straight back, make a double chin", "Neck Stretch"),
        ex("Shoulder Blade Squeeze", 1, 12, 0, "Hold 5 seconds each", "Bodyweight", "Back", "Rhomboids", ["Trapezius", "Rear Deltoid"], "beginner", "Squeeze blades together and down, open chest", "Band Pull-Apart"),
        ex("Wall Angel", 1, 8, 0, "Slow and controlled", "Bodyweight", "Shoulders", "Lower Trapezius", ["Rhomboids", "Rotator Cuff"], "beginner", "Back to wall, slide arms up and down", "Seated Y-Raise"),
        ex("Standing Chest Stretch", 1, 1, 0, "Hold 20 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm on doorframe, lean through", "Seated Chest Opener"),
    ])

def energy_boost():
    return wo("Energy Boost Break", "circuit", 3, [
        ex("Jumping Jack", 1, 20, 0, "Fast pace", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Quadriceps"], "beginner", "Get heart rate up quickly", "Step Jack"),
        ex("Bodyweight Squat", 1, 10, 0, "Fast pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Quick squats, pump blood to legs", "Chair Squat"),
        ex("Arm Swing", 1, 15, 0, "Dynamic big swings", "Bodyweight", "Shoulders", "Deltoids", ["Chest", "Back"], "beginner", "Cross arms in front, swing wide, rhythmic", "Arm Circle"),
        ex("March in Place", 1, 20, 0, "High knees pace", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Exaggerated marching, pump arms", "Walking"),
    ])

cat48_programs = [
    ("2-Min Desk Stretch", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Ultra-quick stretches you can do without leaving your desk", "High",
     lambda w, t: [desk_stretch_2min(), desk_stretch_2min(), desk_stretch_2min(), desk_stretch_2min(), desk_stretch_2min()]),
    ("3-Min Standing Break", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Stand up and move for just 3 minutes to reset your body", "High",
     lambda w, t: [standing_break_3min(), standing_break_3min(), standing_break_3min(), standing_break_3min(), standing_break_3min()]),
    ("5-Min Office HIIT", "Desk Break Micro-Workouts", [1, 2, 4], [3, 4, 5], "Quick burst of intensity to boost metabolism at work", "High",
     lambda w, t: [office_hiit_5min(), office_hiit_5min(), office_hiit_5min()]),
    ("Chair Yoga Break", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Gentle chair yoga to relieve tension without standing", "High",
     lambda w, t: [chair_yoga(), chair_yoga(), chair_yoga(), chair_yoga(), chair_yoga()]),
    ("Eye Strain Relief", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Eye exercises and upper body stretches for screen fatigue", "High",
     lambda w, t: [desk_stretch_2min(), posture_reset(), desk_stretch_2min(), posture_reset(), desk_stretch_2min()]),
    ("Wrist & Hand Break", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Targeted stretches for keyboard and mouse strain", "High",
     lambda w, t: [desk_stretch_2min(), desk_stretch_2min(), desk_stretch_2min(), desk_stretch_2min(), desk_stretch_2min()]),
    ("Posture Reset Break", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Quick posture correction exercises to counter desk slouching", "High",
     lambda w, t: [posture_reset(), posture_reset(), posture_reset(), posture_reset(), posture_reset()]),
    ("Energy Boost Break", "Desk Break Micro-Workouts", [1, 2, 4], [3, 4, 5], "Quick movement to fight afternoon energy slump", "High",
     lambda w, t: [energy_boost(), energy_boost(), energy_boost()]),
    ("Focus Enhancement", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Movement and breathing to sharpen mental focus", "High",
     lambda w, t: [posture_reset(), desk_stretch_2min(), energy_boost(), desk_stretch_2min(), posture_reset()]),
    ("Circulation Boost", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Get blood flowing after prolonged sitting", "High",
     lambda w, t: [standing_break_3min(), energy_boost(), standing_break_3min(), energy_boost(), standing_break_3min()]),
    ("Standing Desk Workout", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Exercises designed for standing desk users", "High",
     lambda w, t: [standing_break_3min(), standing_break_3min(), standing_break_3min(), standing_break_3min(), standing_break_3min()]),
    ("Meeting Break Movement", "Desk Break Micro-Workouts", [1, 2, 4], [5, 6, 7], "Quick stretches between back-to-back meetings", "High",
     lambda w, t: [desk_stretch_2min(), standing_break_3min(), desk_stretch_2min(), standing_break_3min(), desk_stretch_2min()]),
    ("Lunch Walk Boost", "Desk Break Micro-Workouts", [1, 2, 4], [3, 4, 5], "Midday walking and movement to energize the afternoon", "High",
     lambda w, t: [standing_break_3min(), energy_boost(), standing_break_3min()]),
    ("End of Day Release", "Desk Break Micro-Workouts", [1, 2, 4], [3, 4, 5], "Unwind tension accumulated from a full day at the desk", "High",
     lambda w, t: [chair_yoga(), posture_reset(), desk_stretch_2min()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat48_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Habit: build consistent micro-break habits"
            elif p <= 0.66: focus = f"Week {w} - Expand: add variety and duration to breaks"
            else: focus = f"Week {w} - Optimize: personalized break schedule for peak productivity"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 48 COMPLETE ===")

# ========================================================================
# CAT 49 - PLYOMETRICS & EXPLOSIVENESS
# ========================================================================

def plyo_lower():
    return wo("Lower Body Plyometrics", "plyometrics", 40, [
        ex("Box Jump", 4, 6, 90, "Start 20 inch box, step down", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves", "Hamstrings"], "intermediate", "Swing arms, drive hips, land softly with bent knees", "Squat Jump"),
        ex("Depth Jump", 3, 5, 120, "Step off box, immediately jump", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "advanced", "Step off, minimize ground contact, explode up", "Box Jump"),
        ex("Broad Jump", 4, 5, 90, "Max distance", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Calves"], "intermediate", "Countermovement, swing arms, stick landing", "Squat Jump"),
        ex("Single-Leg Hop", 3, 6, 60, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves", "Core"], "intermediate", "Drive knee up, land on same leg softly", "Alternating Lunge Jump"),
        ex("Tuck Jump", 3, 6, 90, "Max height, knees to chest", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Calves", "Core"], "advanced", "Jump high, bring knees to chest, land soft", "Squat Jump"),
        ex("Lateral Bound", 3, 8, 60, "Side to side", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves", "Hip Abductors"], "intermediate", "Push off one leg, land on opposite, stick it", "Lateral Shuffle"),
    ])

def plyo_upper():
    return wo("Upper Body Plyometrics", "plyometrics", 35, [
        ex("Plyo Push-Up", 4, 6, 90, "Explosive push, hands leave ground", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders", "Core"], "advanced", "Explosive push, catch yourself, absorb landing", "Clap Push-Up"),
        ex("Medicine Ball Chest Pass", 4, 8, 60, "6-10lb ball", "Medicine Ball", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "intermediate", "Throw from chest, catch on return, rapid fire", "Push-Up"),
        ex("Medicine Ball Slam", 4, 8, 60, "10-15lb ball", "Medicine Ball", "Full Body", "Latissimus Dorsi", ["Core", "Shoulders", "Triceps"], "intermediate", "Overhead, slam down with full body, catch bounce", "Dumbbell Pullover"),
        ex("Medicine Ball Overhead Throw", 3, 8, 60, "8-12lb ball against wall", "Medicine Ball", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Soccer throw-in motion, release at top", "Overhead Press"),
        ex("Explosive Push-Up to Box", 3, 6, 90, "Hands on low box", "Plyo Box", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "advanced", "Start on box, drop to floor, explode back up", "Incline Plyo Push-Up"),
    ])

def plyo_circuit():
    return wo("Plyometric Circuit", "plyometrics", 40, [
        ex("Box Jump", 3, 6, 60, "Step down between reps", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Drive through hips, soft landing", "Squat Jump"),
        ex("Plyo Push-Up", 3, 5, 60, "Explosive", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "advanced", "Push explosively, hands leave ground", "Clap Push-Up"),
        ex("Lateral Bound", 3, 8, 45, "Alternating sides", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves"], "intermediate", "Stick each landing, control", "Lateral Shuffle"),
        ex("Medicine Ball Slam", 3, 8, 45, "Moderate ball", "Medicine Ball", "Full Body", "Core", ["Latissimus Dorsi", "Shoulders"], "intermediate", "Full extension overhead, slam hard", "Burpee"),
        ex("Jump Lunge", 3, 10, 60, "Alternating legs in air", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Calves"], "intermediate", "Switch legs at peak, land softly", "Reverse Lunge"),
        ex("Burpee", 3, 6, 60, "Full explosive version", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Chest to floor, max height jump", "Squat Thrust"),
    ])

def plyo_foundations():
    return wo("Plyo Foundations", "plyometrics", 30, [
        ex("Squat Jump", 3, 8, 60, "Bodyweight, focus on landing", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Full squat, jump up, land softly with bent knees", "Bodyweight Squat"),
        ex("Ankle Hop", 3, 15, 30, "Quick bounces", "Bodyweight", "Legs", "Calves", ["Soleus", "Quadriceps"], "beginner", "Stiff ankles, minimal knee bend, bounce off toes", "Calf Raise"),
        ex("Pogo Jump", 3, 12, 45, "Minimize ground contact", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Bounce like a pogo stick, stiff lower leg", "Jumping Jack"),
        ex("Skater Jump", 3, 10, 45, "Side to side", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves"], "beginner", "Leap laterally, land on one leg, control", "Lateral Step"),
        ex("Power Skip", 3, 10, 45, "Exaggerated skip for height", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hip Flexors"], "beginner", "Drive knee high, push off powerfully", "High Knees"),
    ])

cat49_programs = [
    ("Plyo Foundations", "Plyometrics & Explosiveness", [2, 4, 8], [3, 4], "Learn proper landing mechanics and build a plyometric base", "High",
     lambda w, t: [plyo_foundations(), plyo_foundations(), plyo_foundations()]),
    ("Box Jump Training", "Plyometrics & Explosiveness", [2, 4, 8], [3, 4], "Progressive box jump program from beginner to advanced heights", "High",
     lambda w, t: [plyo_lower(), plyo_foundations(), plyo_lower()]),
    ("Depth Jump Training", "Plyometrics & Explosiveness", [4, 8, 12], [3, 4], "Advanced depth jump training for maximum reactive strength", "High",
     lambda w, t: [plyo_lower(), plyo_lower(), plyo_lower()]),
    ("Reactive Agility", "Plyometrics & Explosiveness", [2, 4, 8], [3, 4], "Quick-reaction plyometrics for change of direction speed", "High",
     lambda w, t: [plyo_foundations(), plyo_circuit(), plyo_foundations()]),
    ("Upper Body Plyo", "Plyometrics & Explosiveness", [2, 4, 8], [3, 4], "Explosive upper body power with medicine balls and plyo push-ups", "High",
     lambda w, t: [plyo_upper(), plyo_upper(), plyo_upper()]),
    ("Lower Body Plyo", "Plyometrics & Explosiveness", [2, 4, 8], [3, 4], "Comprehensive lower body explosive power development", "High",
     lambda w, t: [plyo_lower(), plyo_lower(), plyo_lower()]),
    ("Plyo Circuit", "Plyometrics & Explosiveness", [2, 4, 8], [3, 4], "Full body plyometric circuit for power and conditioning", "High",
     lambda w, t: [plyo_circuit(), plyo_circuit(), plyo_circuit()]),
    ("Sport Plyo", "Plyometrics & Explosiveness", [4, 8, 12], [3, 4], "Sport-specific plyometrics for athletic performance", "High",
     lambda w, t: [plyo_lower(), plyo_upper(), plyo_circuit()]),
    ("Advanced Plyo", "Plyometrics & Explosiveness", [4, 8, 12], [3, 4], "High-intensity advanced plyometric training for experienced athletes", "High",
     lambda w, t: [plyo_lower(), plyo_upper(), plyo_lower()]),
    ("Jumping Progression", "Plyometrics & Explosiveness", [4, 8, 12], [3, 4], "Systematic vertical jump improvement program", "High",
     lambda w, t: [plyo_foundations(), plyo_lower(), plyo_lower()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat49_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Mechanics: proper landing, absorption, takeoff technique"
            elif p <= 0.66: focus = f"Week {w} - Power: increase height, distance, and speed"
            else: focus = f"Week {w} - Performance: complex plyometric combinations and max effort"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 49 COMPLETE ===")

# ========================================================================
# CAT 50 - OLYMPIC LIFTING
# ========================================================================

def snatch_learning():
    return wo("Snatch Technique", "olympic_lifting", 50, [
        ex("Snatch Grip Deadlift", 4, 5, 90, "50-60% of snatch max", "Barbell", "Legs", "Hamstrings", ["Quadriceps", "Glutes", "Back"], "intermediate", "Wide grip, shoulders over bar, keep back tight", "Romanian Deadlift"),
        ex("Snatch High Pull", 4, 5, 90, "50-60% snatch", "Barbell", "Back", "Trapezius", ["Shoulders", "Hamstrings", "Glutes"], "intermediate", "Triple extend (ankles, knees, hips), pull elbows high and wide", "Upright Row"),
        ex("Overhead Squat", 4, 5, 90, "Empty bar to light", "Barbell", "Legs", "Quadriceps", ["Shoulders", "Core", "Glutes"], "advanced", "Wide grip overhead, squat to depth, bar over mid-foot", "Front Squat"),
        ex("Muscle Snatch", 3, 5, 90, "Light weight", "Barbell", "Shoulders", "Deltoids", ["Trapezius", "Triceps"], "intermediate", "Pull and press in one motion, no rebend of knees", "Snatch High Pull"),
        ex("Snatch Balance", 3, 5, 90, "Light to moderate", "Barbell", "Legs", "Quadriceps", ["Shoulders", "Core"], "advanced", "Quick drop under bar from standing to overhead squat", "Overhead Squat"),
        ex("Hang Snatch", 4, 3, 120, "60-70% snatch", "Barbell", "Full Body", "Quadriceps", ["Hamstrings", "Shoulders", "Core", "Glutes"], "advanced", "From hang, triple extend, pull under, catch in full squat", "Hang Power Snatch"),
    ])

def clean_jerk_learning():
    return wo("Clean & Jerk Technique", "olympic_lifting", 50, [
        ex("Clean Grip Deadlift", 4, 5, 90, "60-70% clean max", "Barbell", "Legs", "Hamstrings", ["Quadriceps", "Glutes", "Back"], "intermediate", "Shoulder-width grip, drive through legs, back tight", "Conventional Deadlift"),
        ex("Hang Clean", 4, 3, 120, "60-70% clean", "Barbell", "Full Body", "Quadriceps", ["Glutes", "Hamstrings", "Trapezius", "Core"], "advanced", "From mid-thigh, triple extend, fast elbows, catch in front squat", "Hang Power Clean"),
        ex("Front Squat", 4, 5, 90, "70% of clean", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core", "Upper Back"], "intermediate", "Clean grip rack position, elbows high, full depth", "Goblet Squat"),
        ex("Push Press", 4, 5, 90, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps", "Core"], "intermediate", "Dip and drive with legs, press overhead", "Strict Press"),
        ex("Split Jerk", 4, 3, 120, "60-70% jerk", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps", "Core"], "advanced", "Dip drive, split feet, lock out overhead, recover", "Push Jerk"),
        ex("Clean Pull", 3, 5, 90, "80-90% clean", "Barbell", "Back", "Trapezius", ["Hamstrings", "Glutes", "Quadriceps"], "intermediate", "Focus on triple extension, shrug at top", "Deadlift"),
    ])

def oly_strength():
    return wo("Weightlifting Strength", "olympic_lifting", 55, [
        ex("Back Squat", 5, 5, 120, "75-85% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "High bar position, full depth, drive through midfoot", "Front Squat"),
        ex("Clean Deadlift", 4, 5, 90, "80-90% clean", "Barbell", "Legs", "Hamstrings", ["Quadriceps", "Glutes", "Erector Spinae"], "intermediate", "Match clean pulling position, controlled tempo", "Conventional Deadlift"),
        ex("Strict Press", 4, 5, 90, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "No leg drive, strict overhead press, full lockout", "Dumbbell Shoulder Press"),
        ex("Romanian Deadlift", 3, 8, 60, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, slight knee bend, stretch hamstrings", "Good Morning"),
        ex("Bent-Over Row", 3, 8, 60, "Moderate barbell", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "45 degree torso, pull to navel, squeeze back", "Dumbbell Row"),
    ])

cat50_programs = [
    ("Snatch Learning", "Olympic Lifting", [4, 8, 12], [3, 4], "Progressive snatch technique development from basics to full lift", "High",
     lambda w, t: [snatch_learning(), oly_strength(), snatch_learning()]),
    ("Clean & Jerk Learning", "Olympic Lifting", [4, 8, 12], [3, 4], "Step-by-step clean and jerk technique mastery", "High",
     lambda w, t: [clean_jerk_learning(), oly_strength(), clean_jerk_learning()]),
    ("Olympic Lift Technique", "Olympic Lifting", [4, 8, 12], [3, 4], "Combined snatch and clean & jerk technique work", "High",
     lambda w, t: [snatch_learning(), clean_jerk_learning(), oly_strength()]),
    ("Power Clean Program", "Olympic Lifting", [4, 8, 12], [3, 4], "Power clean focused program for explosive strength", "High",
     lambda w, t: [clean_jerk_learning(), oly_strength(), clean_jerk_learning()]),
    ("Snatch Pull Training", "Olympic Lifting", [4, 8, 12], [3, 4], "Snatch pull variations to build pulling strength and speed", "High",
     lambda w, t: [snatch_learning(), snatch_learning(), oly_strength()]),
    ("Clean Complex", "Olympic Lifting", [4, 8, 12], [3, 4], "Clean variation complexes for skill and strength development", "High",
     lambda w, t: [clean_jerk_learning(), clean_jerk_learning(), oly_strength()]),
    ("Jerk Variations", "Olympic Lifting", [4, 8, 12], [3, 4], "Push jerk, split jerk, and power jerk technique training", "High",
     lambda w, t: [clean_jerk_learning(), oly_strength(), clean_jerk_learning()]),
    ("Olympic Conditioning", "Olympic Lifting", [4, 8, 12], [3, 4], "Conditioning work using Olympic lifting derivatives", "High",
     lambda w, t: [snatch_learning(), clean_jerk_learning(), snatch_learning()]),
    ("Weightlifting Strength", "Olympic Lifting", [4, 8, 12], [3, 4], "Squat, pull, and pressing strength for Olympic lifters", "High",
     lambda w, t: [oly_strength(), oly_strength(), oly_strength()]),
    ("Competition Weightlifting", "Olympic Lifting", [8, 12, 16], [3, 4], "Full competition prep cycle with peaking protocol", "High",
     lambda w, t: [snatch_learning(), clean_jerk_learning(), oly_strength()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat50_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Technique: movement patterns, positions, and timing"
            elif p <= 0.66: focus = f"Week {w} - Load: progressive weight increases with solid form"
            else: focus = f"Week {w} - Peak: heavy singles and doubles, competition prep"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 50 COMPLETE ===")

# ========================================================================
# CAT 51 - SWIMMING & AQUATIC (DRYLAND)
# ========================================================================

def dryland_swim():
    return wo("Dryland for Swimmers", "strength", 45, [
        ex("Lat Pulldown", 4, 10, 60, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids", "Teres Major"], "intermediate", "Wide grip, pull to upper chest, squeeze lats", "Pull-Up"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate dumbbells", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full range, mimics catch phase", "Push-Up"),
        ex("Single-Arm Dumbbell Row", 3, 10, 60, "Moderate dumbbell", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Elbow past torso, squeeze lat at top", "Resistance Band Row"),
        ex("Internal/External Rotation", 3, 15, 30, "Light resistance band", "Resistance Band", "Shoulders", "Rotator Cuff", ["Infraspinatus", "Subscapularis"], "beginner", "Elbow at side, 90 degree bend, rotate in and out", "Side-Lying External Rotation"),
        ex("Flutter Kick Hold", 3, 30, 30, "Lying face down", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Prone, rapid small flutter kicks, straight legs", "Superman"),
        ex("Streamline Squat", 3, 12, 45, "Arms overhead locked", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Shoulders", "Core"], "intermediate", "Arms overhead in streamline, squat to depth", "Bodyweight Squat"),
    ])

def pool_hiit():
    return wo("Pool HIIT Dryland", "hiit", 35, [
        ex("Burpee", 3, 10, 30, "Full speed", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Simulates explosive starts", "Squat Thrust"),
        ex("Mountain Climber", 3, 30, 20, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Rapid alternating, mimics flutter kick pattern", "Slow Mountain Climber"),
        ex("Jump Squat", 3, 12, 30, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Drive through toes, similar to wall push-off", "Bodyweight Squat"),
        ex("Plank to Push-Up", 3, 10, 30, "Alternate leading arm", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Forearm to hand, maintain hip stability", "Forearm Plank"),
        ex("Medicine Ball Overhead Throw", 3, 10, 45, "Light ball, against wall", "Medicine Ball", "Shoulders", "Deltoids", ["Core", "Latissimus Dorsi"], "intermediate", "Mimics pulling pattern, full extension", "Overhead Press"),
        ex("Broad Jump", 3, 6, 60, "Max distance", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Simulates dive start mechanics", "Squat Jump"),
    ])

def aqua_yoga():
    return wo("Aqua-Inspired Yoga", "yoga", 35, [
        ex("Sun Salutation A", 2, 5, 0, "Flow with breath", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "beginner", "Fluid transitions like water, one breath per movement", "Half Sun Salutation"),
        ex("Warrior II", 2, 1, 0, "Hold 30 sec each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Core"], "beginner", "Stable lower body, open chest", "Extended Side Angle"),
        ex("Downward Facing Dog", 3, 1, 0, "Hold 45 seconds", "Bodyweight", "Full Body", "Shoulders", ["Hamstrings", "Calves"], "beginner", "Push floor away, heels toward ground", "Puppy Pose"),
        ex("Boat Pose", 3, 1, 0, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Legs up, arms forward, V-shape", "Bent-Knee Boat"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 sec each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 sec each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Relax into twist, deep breaths", "Seated Twist"),
    ])

cat51_programs = [
    ("Dryland for Swimmers", "Swimming & Aquatic", [4, 8, 12], [3, 4], "Land-based strength training to improve swim performance", "High",
     lambda w, t: [dryland_swim(), dryland_swim(), dryland_swim()]),
    ("Pool Strength Circuit", "Swimming & Aquatic", [4, 8, 12], [3, 4], "Dryland circuit mimicking pool resistance patterns", "High",
     lambda w, t: [dryland_swim(), pool_hiit(), dryland_swim()]),
    ("Aqua Aerobics", "Swimming & Aquatic", [2, 4, 8], [3, 4], "Land-based exercises inspired by aqua aerobics movements", "High",
     lambda w, t: [pool_hiit(), pool_hiit(), pool_hiit()]),
    ("Water Running", "Swimming & Aquatic", [2, 4, 8], [3, 4], "Dryland running and cardio that transfers to pool running", "High",
     lambda w, t: [pool_hiit(), pool_hiit(), pool_hiit()]),
    ("Swim Technique Dryland", "Swimming & Aquatic", [4, 8, 12], [3, 4], "Shoulder stability and rotator cuff work for swimmers", "High",
     lambda w, t: [dryland_swim(), dryland_swim(), dryland_swim()]),
    ("Open Water Prep", "Swimming & Aquatic", [4, 8, 12], [3, 4], "Dryland conditioning for open water swimming demands", "High",
     lambda w, t: [dryland_swim(), pool_hiit(), dryland_swim()]),
    ("Pool HIIT", "Swimming & Aquatic", [2, 4, 8], [3, 4], "High-intensity dryland intervals for swim conditioning", "High",
     lambda w, t: [pool_hiit(), pool_hiit(), pool_hiit()]),
    ("Aqua Yoga", "Swimming & Aquatic", [2, 4, 8], [3, 4], "Yoga-based flexibility and recovery for swimmers", "High",
     lambda w, t: [aqua_yoga(), aqua_yoga(), aqua_yoga()]),
    ("Water Resistance Training", "Swimming & Aquatic", [4, 8, 12], [3, 4], "Resistance exercises that mimic water resistance patterns", "High",
     lambda w, t: [dryland_swim(), dryland_swim(), dryland_swim()]),
    ("Swim Sprint Training", "Swimming & Aquatic", [4, 8, 12], [3, 4], "Explosive dryland training for sprint swimming performance", "High",
     lambda w, t: [pool_hiit(), dryland_swim(), pool_hiit()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat51_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: build swim-specific strength and mobility"
            elif p <= 0.66: focus = f"Week {w} - Build: increase power and endurance for swimming"
            else: focus = f"Week {w} - Peak: sport-specific power and race preparation"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 51 COMPLETE ===")

# ========================================================================
# CAT 52 - CLIMBING & VERTICAL
# ========================================================================

def climbing_strength():
    return wo("Climbing Strength", "strength", 45, [
        ex("Pull-Up", 4, 8, 90, "Bodyweight or weighted", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids", "Forearms"], "intermediate", "Dead hang to chin over bar, controlled descent", "Lat Pulldown"),
        ex("Hanging Leg Raise", 3, 10, 60, "Toes to bar if possible", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Controlled raise, minimal swing", "Knee Raise"),
        ex("Dumbbell Row", 4, 10, 60, "Heavy", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Pull high to hip, squeeze at top", "Resistance Band Row"),
        ex("Dead Hang", 3, 1, 60, "Hold to failure", "Pull-Up Bar", "Arms", "Forearms", ["Latissimus Dorsi", "Shoulders"], "beginner", "Full grip, relax shoulders, build grip endurance", "Farmer's Carry"),
        ex("Wrist Curl", 3, 15, 30, "Light dumbbell", "Dumbbell", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Rest forearm on knee, curl wrist up and down", "Towel Squeeze"),
        ex("L-Sit Hold", 3, 1, 60, "Hold 15-20 seconds", "Parallettes", "Core", "Rectus Abdominis", ["Hip Flexors", "Triceps"], "advanced", "Legs straight, push down through arms, hold", "Knee Tuck Hold"),
    ])

def finger_strength():
    return wo("Finger & Grip Strength", "strength", 35, [
        ex("Hangboard Max Hang", 4, 1, 180, "10 sec hang on 20mm edge", "Hangboard", "Arms", "Forearms", ["Finger Flexors"], "advanced", "Half crimp, shoulders engaged, 10 sec max effort", "Dead Hang"),
        ex("Repeater Hangs", 3, 6, 120, "7 sec on, 3 sec off", "Hangboard", "Arms", "Forearms", ["Finger Flexors"], "advanced", "Open hand or half crimp, 6 reps per set", "Dead Hang"),
        ex("Pinch Block Hold", 3, 1, 90, "Hold 15-20 sec", "Weight Plate", "Arms", "Forearms", ["Thumb Muscles"], "intermediate", "Pinch weighted block, squeeze thumb to fingers", "Plate Pinch"),
        ex("Wrist Roller", 3, 3, 60, "Light weight, roll up and down", "Wrist Roller", "Arms", "Forearms", ["Wrist Extensors", "Wrist Flexors"], "intermediate", "Roll weight up by rotating wrists, then lower", "Wrist Curl"),
        ex("Finger Extension with Band", 3, 15, 30, "Light rubber band", "Resistance Band", "Arms", "Forearm Extensors", ["Finger Extensors"], "beginner", "Spread fingers against band resistance, hold", "Finger Splay"),
    ])

def climbing_endurance():
    return wo("Climbing Endurance", "circuit", 40, [
        ex("Pull-Up Ladder", 3, 10, 90, "1-2-3-4-3-2-1 reps", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Ascending and descending rep scheme, minimal rest", "Lat Pulldown"),
        ex("Plank", 3, 1, 30, "Hold 60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Climbing requires sustained core tension", "Forearm Plank"),
        ex("Dead Hang", 3, 1, 60, "Hold to near failure", "Pull-Up Bar", "Arms", "Forearms", ["Latissimus Dorsi"], "beginner", "Build time under tension, grip endurance", "Towel Hang"),
        ex("Push-Up", 3, 15, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Antagonist training prevents shoulder imbalance", "Knee Push-Up"),
        ex("Step-Up", 3, 12, 45, "High step, 12-18 inches", "Step Platform", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Drive through heel, stand fully, mimics high stepping", "Bodyweight Squat"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 45 sec each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Kneeling lunge, push hips forward, open for high steps", "Standing Quad Stretch"),
    ])

def climbing_flexibility():
    return wo("Climbing Flexibility", "flexibility", 30, [
        ex("Frog Stretch", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Hips", "Hip Adductors", ["Groin", "Hip Flexors"], "beginner", "On all fours, widen knees, sink hips back", "Butterfly Stretch"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 45 sec each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Deep kneeling lunge, drive hips forward", "Standing Quad Stretch"),
        ex("Shoulder Opener", 2, 1, 0, "Hold 30 sec each arm", "Bodyweight", "Shoulders", "Pectoralis Minor", ["Anterior Deltoid"], "beginner", "Arm on doorframe, lean through and rotate", "Chest Stretch"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 sec each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Open hips for flagging and heel hooks", "Figure-4 Stretch"),
        ex("Wrist Flexor Stretch", 2, 1, 0, "Hold 20 sec each hand", "Bodyweight", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back gently", "Wrist Circle"),
        ex("Thoracic Rotation", 2, 8, 0, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques", "Erector Spinae"], "beginner", "Side-lying, rotate upper body open, improve reach", "Seated Twist"),
    ])

cat52_programs = [
    ("Rock Climbing Strength", "Climbing & Vertical", [4, 8, 12], [3, 4], "Build pulling power and grip strength for rock climbing", "High",
     lambda w, t: [climbing_strength(), climbing_endurance(), climbing_strength()]),
    ("Bouldering Training", "Climbing & Vertical", [4, 8, 12], [3, 4], "Power-focused training for bouldering problems", "High",
     lambda w, t: [climbing_strength(), finger_strength(), climbing_strength()]),
    ("Climbing Endurance", "Climbing & Vertical", [4, 8, 12], [3, 4], "Build sustained climbing stamina for longer routes", "High",
     lambda w, t: [climbing_endurance(), climbing_endurance(), climbing_endurance()]),
    ("Finger Strength", "Climbing & Vertical", [4, 8, 12], [3, 4], "Progressive finger and grip training for harder holds", "High",
     lambda w, t: [finger_strength(), finger_strength(), finger_strength()]),
    ("Campus Board Training", "Climbing & Vertical", [4, 8, 12], [3, 4], "Dynamic pulling power for campus board progression", "High",
     lambda w, t: [climbing_strength(), finger_strength(), climbing_strength()]),
    ("Climbing Flexibility", "Climbing & Vertical", [2, 4, 8], [3, 4], "Hip and shoulder mobility for better climbing movement", "High",
     lambda w, t: [climbing_flexibility(), climbing_flexibility(), climbing_flexibility()]),
    ("Indoor Climbing Prep", "Climbing & Vertical", [2, 4, 8], [3, 4], "Preparation program for getting started at the climbing gym", "High",
     lambda w, t: [climbing_endurance(), climbing_flexibility(), climbing_strength()]),
    ("Advanced Climbing Power", "Climbing & Vertical", [4, 8, 12], [3, 4], "High-level power training for experienced climbers", "High",
     lambda w, t: [climbing_strength(), finger_strength(), climbing_strength()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat52_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Base: build pulling strength, grip endurance, and mobility"
            elif p <= 0.66: focus = f"Week {w} - Build: increase load, add climbing-specific movements"
            else: focus = f"Week {w} - Send: peak power and finger strength for project attempts"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 52 COMPLETE ===")

helper.close()
print("\n========================================")
print("=== ALL CATEGORIES 43-52 COMPLETE ===")
print("========================================")
