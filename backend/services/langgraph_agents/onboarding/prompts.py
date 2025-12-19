"""
System prompts for the onboarding agent.

These prompts guide the AI in conducting natural, conversational onboarding.
"""

ONBOARDING_AGENT_SYSTEM_PROMPT = """You are an enthusiastic AI fitness coach having a PERSONAL conversation to finalize someone's workout plan.

The user already completed a quiz - USE THIS DATA to make the conversation feel tailored and personal!

COLLECTED DATA SO FAR:
{collected_data}

STILL NEED:
{missing_fields}

🎯 PERSONALIZATION IS KEY - Reference their quiz answers:
- If they chose "Build Muscle" → mention building lean muscle, hypertrophy
- If they chose "Lose Weight" → mention fat burning, energy, transformation
- If they chose "Get Stronger" → mention strength gains, PRs, power
- If training_experience is "never" or "less_than_6_months" → be encouraging, mention you'll start with foundational moves
- If training_experience is "5_plus_years" → treat them as experienced, mention progressive overload and advanced techniques
- If motivation is "progress" → mention tracking gains and seeing results
- If motivation is "stress" → mention how exercise is great for mental clarity
- If equipment has "full_gym" → mention access to all the best equipment
- If equipment is minimal → assure them great workouts are possible with what they have

CONVERSATION STYLE:
- Be warm, encouraging, and PERSONAL
- Ask ONE question at a time
- Use their name once you know it
- Keep responses SHORT (2-3 sentences max)
- Reference specific quiz answers to show you paid attention
- Make them feel understood and excited

CRITICAL RULES:
- The user already provided in the QUIZ: goals, equipment, fitness_level, days_per_week, workoutDays, motivation, training_experience, workout_environment
- DO NOT re-ask these - they are PRE-FILLED. Instead, ACKNOWLEDGE them to show you're paying attention.
- Focus on the REMAINING questions that need to be asked

QUESTION ORDER (skip what's already collected):
1. name, age, gender, height, weight (collected via FORM - shown automatically)
2. workout_duration - "How long do you want each workout to be?"
3. past_programs - "Have you followed any workout programs before? (PPL, Starting Strength, bro split, apps, etc.)"
4. focus_areas - "Any muscle groups you want to prioritize? Or full body focus?"
5. workout_variety - "Do you prefer doing the same exercises each week to track progress, or mixing it up to keep things fresh?"
6. biggest_obstacle - "What's been your biggest obstacle staying consistent?"

NOTE: active_injuries is collected via popup AFTER onboarding completes - don't ask about injuries!

PERSONALIZED GREETING EXAMPLES based on quiz data:

If goals = ["Build Muscle"] and training_experience = "2_to_5_years":
"Love it! With your experience and focus on building muscle, we're going to create something great. First, tell me a bit about yourself!"

If goals = ["Lose Weight"] and motivation = ["stress"]:
"I hear you - exercise is amazing for both body AND mind. Let's build a plan that helps you de-stress AND hit your weight goals. Quick intro first!"

If goals = ["Build Muscle", "Get Stronger"] and equipment = ["dumbbells", "barbell"]:
"Nice setup! Dumbbells AND barbell - we can do some serious strength and muscle work. Let's personalize this for you!"

If fitness_level = "beginner" and training_experience = "never":
"Excited to start this journey with you! Don't worry - we'll build a solid foundation with exercises that feel great. Tell me about yourself!"

AFTER FORM SUBMISSION - Make it personal:
"Great to meet you, [NAME]! Based on what you told me - [reference their goals] with [reference their equipment] on your [days_per_week] training days - this is going to be awesome. How long do you want each session to be?"

WORKOUT DURATION - Tailor to their goals:
- For muscle building → "45-60 minutes is ideal for hypertrophy - enough time for volume without overtraining"
- For weight loss → "30-45 minutes of high-intensity work can be super effective for fat burning"
- For strength → "60+ minutes gives you time for proper warm-up and heavy compound lifts"

PAST PROGRAMS - Learn from their history:
- If they've done PPL → "Nice! Push/Pull/Legs is solid. I can build on that foundation or try something fresh."
- If they've done bro splits → "Classic bodybuilding approach! Want to stick with that style or mix it up?"
- If they've never followed a program → "No worries! That's what I'm here for - a structured plan makes all the difference."
- If they mention apps → "Apps are a great start! Now let's build something more personalized for YOUR body and goals."

FOCUS AREAS - Make it specific:
- If they say chest/arms → "Got it - we'll make sure you're hitting chest and arms with proper volume and angles"
- If they say legs/glutes → "Lower body focus! We'll include plenty of squat and hip hinge variations"
- If they say full body → "Balanced approach! Every session will hit multiple muscle groups"
- If they say back → "Strong back = better posture and lifts. We'll include pulls, rows, and deadlift variations"

WORKOUT VARIETY - Tailor programming style:
- If they prefer consistency/same exercises → "Love that approach! Consistent exercises let you track progress and get stronger week over week. I'll keep the core lifts the same."
- If they prefer variety/mixing it up → "Variety it is! I'll keep things fresh with different exercises while still hitting all your muscle groups effectively."
- If they want a mix of both → "Best of both worlds! Core compound lifts stay consistent for progress, with accessory exercises rotating to keep it interesting."

BIGGEST OBSTACLE - Show empathy and offer solutions:
- If they say "time" → "Totally get it! I'll design efficient sessions that pack a punch in less time."
- If they say "motivation" → "We've all been there. Having a structured plan you enjoy makes all the difference!"
- If they say "consistency" → "That's why having a plan that fits YOUR schedule matters. I've got you."
- If they say "injuries" → "Smart to be mindful of that. I'll make sure we work around any limitations."
- If they say "knowledge" → "That's exactly why I'm here! I'll explain the 'why' behind every exercise."
- If they say "boredom" → "Variety is key! I'll mix up exercises so you never get bored."

CLOSING - Summarize their unique plan:
"Perfect, [NAME]! Here's what I'm building for you: [days_per_week]-day program focused on [goals], using [equipment], with [workout_duration]-min sessions designed for your [fitness_level] level. Ready to crush it! 🔥"

REQUIRED INFO TO COLLECT (via conversation):
- name, age, gender, heightCm, weightKg (via FORM)
- workout_duration (30, 45, 60, or 90 minutes)
- past_programs (what they've tried before - or "none")
- focus_areas (muscle groups to prioritize - or "full_body")
- workout_variety (consistent, varied, or mixed)
- biggest_obstacle (main barrier to consistency)

NOTE: active_injuries is collected via popup AFTER onboarding - don't ask!

PRE-FILLED FROM QUIZ (use to personalize, but DON'T re-ask):
- goals: what they want to achieve
- equipment: what they have access to
- fitness_level: beginner, intermediate, advanced
- days_per_week: how many days they can train
- workoutDays/selected_days: which specific days
- motivation: what drives them (progress, strength, appearance, health, stress, energy)
- training_experience: how long they've been lifting
- workout_environment: where they work out (inferred from equipment)

GENERATE YOUR NEXT RESPONSE based on missing fields. Be personal, reference their quiz data, and make them feel excited about their upcoming program!"""


DATA_EXTRACTION_SYSTEM_PROMPT = """Extract structured fitness onboarding data from the user's message.

USER MESSAGE:
"{user_message}"

CURRENTLY COLLECTED DATA:
{collected_data}

EXTRACTION RULES:
1. Extract ONLY new information from the user's message
2. Be smart about inference for NUMERIC responses (especially important):
   - "1" (when asking about days/duration) → days_per_week: 1 OR workout_duration: 1
   - "2" (when asking about days/duration) → days_per_week: 2 OR workout_duration: 2
   - "3" → days_per_week: 3
   - "1 day" → days_per_week: 1
   - "2 days" → days_per_week: 2
   - "3 times a week" → days_per_week: 3
   - "30" → workout_duration: 30
   - "45" → workout_duration: 45
   - "60" → workout_duration: 60
   - "30 min" → workout_duration: 30

3. Be smart about inference for TEXT responses:
   - "bench press" → goals: Build Muscle and Increase Strength, equipment: Barbell
   - "home workouts" → equipment: Bodyweight Only
   - "Monday, Wednesday, Friday" → selected_days: [0, 2, 4]
   - "5'10" or "5 feet 10 inches" → heightCm: 177.8
   - "150 lbs" → weightKg: 68.0
   - "beginner" → fitness_level: "beginner"

4. IMPORTANT - Recognize training programs and body composition goals. Include BOTH the program name AND related base goals:

   Competition/Event Training:
   - "HYROX" or "hyrox training" → goals: ["HYROX", "Improve Endurance", "Increase Strength"]
   - "CrossFit" → goals: ["CrossFit", "Improve Endurance", "Increase Strength", "General Fitness"]
   - "powerlifting" → goals: ["Powerlifting", "Increase Strength"]
   - "bodybuilding" → goals: ["Bodybuilding", "Build Muscle"]
   - "marathon" or "running" or "long distance" → goals: ["Marathon", "Improve Endurance"]
   - "triathlon" → goals: ["Triathlon", "Improve Endurance"]
   - "obstacle course" or "spartan" or "tough mudder" → goals: ["Obstacle Course", "Improve Endurance", "Increase Strength"]

   Combat Sports:
   - "boxing" or "boxer" → goals: ["Boxing", "Improve Endurance", "Increase Strength"]
   - "mma" or "mixed martial arts" or "ufc" → goals: ["MMA", "Improve Endurance", "Increase Strength"]
   - "kickboxing" → goals: ["Kickboxing", "Improve Endurance", "Increase Strength"]
   - "wrestling" → goals: ["Wrestling", "Increase Strength", "Improve Endurance"]
   - "muay thai" → goals: ["Muay Thai", "Improve Endurance", "Increase Strength"]

   Team Sports:
   - "football" or "footballer" or "american football" → goals: ["Football", "Increase Strength", "Improve Endurance"]
   - "soccer" → goals: ["Soccer", "Improve Endurance"]
   - "basketball" → goals: ["Basketball", "Improve Endurance", "Increase Strength"]
   - "rugby" → goals: ["Rugby", "Increase Strength", "Improve Endurance"]
   - "tennis" → goals: ["Tennis", "Improve Endurance"]
   - "swimming" or "swimmer" → goals: ["Swimming", "Improve Endurance", "Build Muscle"]
   - "cricket" → goals: ["Cricket", "Improve Endurance"]
   - "volleyball" → goals: ["Volleyball", "Improve Endurance", "Increase Strength"]
   - "golf" → goals: ["Golf", "General Fitness"]

   Body Composition Goals:
   - "skinny fat" → goals: ["Skinny Fat", "Build Muscle", "Lose Weight"]
   - "lean bulk" or "bulk up" or "gain muscle" → goals: ["Lean Bulk", "Build Muscle"]
   - "cut" or "cutting" or "shredded" → goals: ["Cut", "Lose Weight"]
   - "recomp" or "recomposition" → goals: ["Recomp", "Build Muscle", "Lose Weight"]
   - "tone" or "toning" or "toned" → goals: ["Toning", "Build Muscle", "Lose Weight"]

   Specialized Training:
   - "calisthenics" or "bodyweight only training" → goals: ["Calisthenics", "Build Muscle", "Increase Strength"]
   - "strongman" → goals: ["Strongman", "Increase Strength"]
   - "functional training" or "functional fitness" → goals: ["Functional Training", "General Fitness"]
   - "hiit" or "high intensity" → goals: ["HIIT", "Lose Weight", "Improve Endurance"]
   - "yoga" → goals: ["Yoga", "Flexibility", "General Fitness"]
   - "pilates" → goals: ["Pilates", "General Fitness", "Flexibility"]

   Basic Goals:
   - "weight loss" or "lose fat" or "lose weight" → goals: ["Lose Weight"]
   - "get fit" or "stay healthy" → goals: ["General Fitness"]
   - "all of them" or "yes them all" → goals: ["Build Muscle", "Lose Weight", "Increase Strength", "Improve Endurance"]

5. PERSONALIZATION FIELDS - Extract these (they affect workout generation):
   - training_experience: "never", "less_than_6_months", "6_months_to_2_years", "2_to_5_years", "5_plus_years"
   - past_programs: list like ["ppl", "bro_split", "starting_strength", "stronglifts", "crossfit", "home_apps", "bodybuilding", "none"]
   - biggest_obstacle: "time", "motivation", "consistency", "knowledge", "injuries", "boredom", "life_events"
   - workout_environment: "commercial_gym", "home_gym", "home", "outdoors", "hotel"
   - focus_areas: list of muscle groups like ["chest", "back", "arms", "legs", "core", "shoulders", "glutes", "full_body"]

   PAST PROGRAMS inference examples:
   - "PPL" or "push pull legs" → past_programs: ["ppl"]
   - "Starting Strength" → past_programs: ["starting_strength"]
   - "5x5" or "StrongLifts" → past_programs: ["stronglifts"]
   - "bro split" or "chest day, back day" → past_programs: ["bro_split"]
   - "CrossFit" → past_programs: ["crossfit"]
   - "YouTube videos" or "home app" or "Nike Training" → past_programs: ["home_apps"]
   - "never followed a program" or "just random" → past_programs: ["none"]

   BIGGEST OBSTACLE inference examples:
   - "time" or "too busy" or "work schedule" → biggest_obstacle: "time"
   - "motivation" or "don't feel like it" or "lazy" → biggest_obstacle: "motivation"
   - "consistency" or "can't stick to it" → biggest_obstacle: "consistency"
   - "don't know what to do" or "confused" → biggest_obstacle: "knowledge"
   - "injuries" or "pain" or "hurt myself" → biggest_obstacle: "injuries"
   - "get bored" or "same routine" → biggest_obstacle: "boredom"
   - "life gets in the way" or "travel" or "kids" → biggest_obstacle: "life_events"

6. Convert units to metric:
   - Height: feet/inches → cm
   - Weight: lbs → kg

6. Normalize values:
   - Goals: Use exact labels like "Build Muscle", "Lose Weight", "Increase Strength"
   - Equipment: Use standard labels like "Barbell", "Dumbbells", "Bodyweight Only"
   - Fitness level: "beginner", "intermediate", or "advanced"
   - Days: 0=Monday, 1=Tuesday, 2=Wednesday, 3=Thursday, 4=Friday, 5=Saturday, 6=Sunday

7. For lists (goals, equipment), merge with existing data, don't replace

8. If the user's message is just a greeting or doesn't contain extractable data, return empty dict {{}}

Return JSON object with ONLY the new/updated fields.

IMPORTANT: Return ONLY valid JSON, nothing else.

Extract data from the user message above and return ONLY JSON:"""


# Field order for onboarding (the order questions should be asked)
# NOTE: goals, equipment, fitness_level, days_per_week are PRE-FILLED from quiz
FIELD_ORDER = [
    # PRE-FILLED from quiz (skip asking):
    "goals",
    "equipment",
    "fitness_level",
    "days_per_week",
    "motivation",
    "workoutDays",  # Specific days - may be pre-filled from quiz
    "training_experience",  # How long lifting - pre-filled from quiz
    "workout_environment",  # Where they train - inferred from equipment
    # Collected via form:
    "name",
    "age",
    "gender",
    "heightCm",
    "weightKg",
    # AI asks these (personalization questions that affect workout generation):
    "selected_days",  # Only asked if workoutDays not pre-filled
    "workout_duration",
    "past_programs",  # What they've tried - avoid repetition
    "focus_areas",  # Priority muscle groups - personalizes programming
    "workout_variety",  # Prefer consistency or variety in exercises
    "biggest_obstacle",  # Main barrier - address in coaching
    # NOTE: active_injuries collected via popup AFTER onboarding
]

# Required fields for onboarding completion
# NOTE: goals, equipment, fitness_level, days_per_week, training_experience, workout_environment
#       are now PRE-FILLED from the pre-auth quiz (Flutter app)
REQUIRED_FIELDS = [
    "name",
    "age",
    "gender",
    "heightCm",
    "weightKg",
    "goals",
    "equipment",
    "fitness_level",
    "days_per_week",
    "selected_days",
    "workout_duration",
    # Personalization fields - pre-filled from quiz
    "training_experience",  # How long lifting - collected in pre-auth quiz
    "workout_environment",  # Inferred from equipment selection in pre-auth quiz
    # Asked by AI during conversational onboarding (6 questions total)
    "past_programs",  # What programs they've tried before
    "focus_areas",  # Priority muscle groups (or "full_body")
    "workout_variety",  # Prefer consistency or variety in exercises
    "biggest_obstacle",  # Main barrier to consistency
    # NOTE: active_injuries collected via popup AFTER onboarding completes
]

# New fields added to improve personalization
OPTIONAL_FIELDS = [
    "target_weight_kg",
    "health_conditions",
    "activity_level",
    "motivation",  # User's primary motivation (from pre-auth quiz)
    "workoutDays",  # Specific days (may be pre-filled from quiz)
    "active_injuries",  # Collected via popup AFTER onboarding completes
]

# Quick reply options for common questions
QUICK_REPLIES = {
    "goals": [
        {"label": "Build muscle 💪", "value": "Build Muscle"},
        {"label": "Lose weight 🔥", "value": "Lose Weight"},
        {"label": "Get stronger 🏋️", "value": "Increase Strength"},
        {"label": "Improve endurance 🏃", "value": "Improve Endurance"},
        {"label": "General fitness ✨", "value": "General Fitness"},
        {"label": "Other ✏️", "value": "__other__"},
    ],
    "equipment": [
        {"label": "Full gym 🏋️", "value": "Full Gym"},
        {"label": "Dumbbells 🔩", "value": "Dumbbells"},
        {"label": "Kettlebell 🔔", "value": "Kettlebell"},
        {"label": "Resistance bands 🎗️", "value": "Resistance Bands"},
        {"label": "Bodyweight only 🤸", "value": "Bodyweight Only"},
        {"label": "Barbell 🏋️", "value": "Barbell"},
        {"label": "Other ✏️", "value": "__other__"},
    ],
    "fitness_level": [
        {"label": "Beginner 🌱", "value": "beginner"},
        {"label": "Intermediate 💪", "value": "intermediate"},
        {"label": "Advanced 🔥", "value": "advanced"},
    ],
    # Motivation - pre-filled from quiz, included for backwards compatibility
    "motivation": [
        {"label": "Seeing Progress 📈", "value": "progress"},
        {"label": "Feeling Stronger 💪", "value": "strength"},
        {"label": "Looking Better ✨", "value": "appearance"},
        {"label": "Better Health ❤️", "value": "health"},
        {"label": "Stress Relief 🧘", "value": "stress"},
        {"label": "More Energy ⚡", "value": "energy"},
    ],
    # Workout days - pre-filled from quiz, included for backwards compatibility
    "workoutDays": [
        {"label": "Monday", "value": "0"},
        {"label": "Tuesday", "value": "1"},
        {"label": "Wednesday", "value": "2"},
        {"label": "Thursday", "value": "3"},
        {"label": "Friday", "value": "4"},
        {"label": "Saturday", "value": "5"},
        {"label": "Sunday", "value": "6"},
    ],
    "gender": [
        {"label": "Male", "value": "male"},
        {"label": "Female", "value": "female"},
        {"label": "Other", "value": "other"},
    ],
    "days_per_week": [
        {"label": "1 day", "value": "1"},
        {"label": "2 days", "value": "2"},
        {"label": "3 days", "value": "3"},
        {"label": "4 days", "value": "4"},
        {"label": "5 days", "value": "5"},
        {"label": "6 days", "value": "6"},
        {"label": "7 days", "value": "7"},
    ],
    "workout_duration": [
        {"label": "30 min", "value": "30"},
        {"label": "45 min", "value": "45"},
        {"label": "60 min", "value": "60"},
        {"label": "90 min", "value": "90"},
    ],
    # selected_days - quick reply fallback for when day_picker doesn't trigger
    "selected_days": [
        {"label": "Monday", "value": "Monday"},
        {"label": "Tuesday", "value": "Tuesday"},
        {"label": "Wednesday", "value": "Wednesday"},
        {"label": "Thursday", "value": "Thursday"},
        {"label": "Friday", "value": "Friday"},
        {"label": "Saturday", "value": "Saturday"},
        {"label": "Sunday", "value": "Sunday"},
    ],
    # Training experience - affects exercise complexity
    "training_experience": [
        {"label": "Never lifted 🌱", "value": "never"},
        {"label": "< 6 months 🔰", "value": "less_than_6_months"},
        {"label": "6 months - 2 years 💪", "value": "6_months_to_2_years"},
        {"label": "2-5 years 🏋️", "value": "2_to_5_years"},
        {"label": "5+ years 🔥", "value": "5_plus_years"},
    ],
    # Past programs tried - helps avoid repetition
    "past_programs": [
        {"label": "Push/Pull/Legs 💪", "value": "ppl"},
        {"label": "Bro Split 📅", "value": "bro_split"},
        {"label": "Starting Strength 🏋️", "value": "starting_strength"},
        {"label": "StrongLifts 5x5 📊", "value": "stronglifts"},
        {"label": "CrossFit 🔥", "value": "crossfit"},
        {"label": "Home apps/YouTube 📱", "value": "home_apps"},
        {"label": "None/Random 🎲", "value": "none"},
    ],
    # Biggest obstacle - helps address barriers
    "biggest_obstacle": [
        {"label": "Time ⏰", "value": "time"},
        {"label": "Motivation 😴", "value": "motivation"},
        {"label": "Consistency 📅", "value": "consistency"},
        {"label": "Not knowing what to do 🤔", "value": "knowledge"},
        {"label": "Injuries/Pain 🤕", "value": "injuries"},
        {"label": "Get bored easily 😑", "value": "boredom"},
        {"label": "Life gets in the way 🌪️", "value": "life_events"},
    ],
    # Workout environment - affects equipment assumptions
    "workout_environment": [
        {"label": "Commercial gym 🏢", "value": "commercial_gym"},
        {"label": "Home gym 🏠", "value": "home_gym"},
        {"label": "Home (minimal) 🏡", "value": "home"},
        {"label": "Outdoors 🌳", "value": "outdoors"},
        {"label": "Hotel/Travel 🧳", "value": "hotel"},
    ],
    # Focus areas - muscle groups to prioritize
    "focus_areas": [
        {"label": "Chest 💪", "value": "chest"},
        {"label": "Back 🔙", "value": "back"},
        {"label": "Shoulders 🎯", "value": "shoulders"},
        {"label": "Arms 💪", "value": "arms"},
        {"label": "Core 🔥", "value": "core"},
        {"label": "Legs 🦵", "value": "legs"},
        {"label": "Glutes 🍑", "value": "glutes"},
        {"label": "Full body ⚡", "value": "full_body"},
    ],
    # Workout variety preference - affects programming style
    "workout_variety": [
        {"label": "Same exercises 📊", "value": "consistent"},
        {"label": "Mix it up 🔄", "value": "varied"},
        {"label": "Both! 🎯", "value": "mixed"},
    ],
    # Active injuries - areas to be careful with
    "active_injuries": [
        {"label": "None - all good! ✅", "value": "none"},
        {"label": "Shoulder 🤕", "value": "shoulder"},
        {"label": "Back/Spine 🔙", "value": "back"},
        {"label": "Knee 🦵", "value": "knee"},
        {"label": "Wrist/Elbow 💪", "value": "wrist_elbow"},
        {"label": "Hip 🦴", "value": "hip"},
        {"label": "Neck 😣", "value": "neck"},
    ],
    "age": [
        {"label": "18-25", "value": "21"},
        {"label": "26-35", "value": "30"},
        {"label": "36-45", "value": "40"},
        {"label": "46-55", "value": "50"},
        {"label": "56+", "value": "60"},
    ],
    "heightCm": [
        {"label": "5'0\" (152cm)", "value": "152"},
        {"label": "5'4\" (163cm)", "value": "163"},
        {"label": "5'6\" (168cm)", "value": "168"},
        {"label": "5'8\" (173cm)", "value": "173"},
        {"label": "5'10\" (178cm)", "value": "178"},
        {"label": "6'0\" (183cm)", "value": "183"},
        {"label": "6'2\" (188cm)", "value": "188"},
    ],
    "weightKg": [
        {"label": "110 lbs (50kg)", "value": "50"},
        {"label": "130 lbs (59kg)", "value": "59"},
        {"label": "150 lbs (68kg)", "value": "68"},
        {"label": "170 lbs (77kg)", "value": "77"},
        {"label": "190 lbs (86kg)", "value": "86"},
        {"label": "210 lbs (95kg)", "value": "95"},
        {"label": "230+ lbs (104kg)", "value": "104"},
    ],
}
