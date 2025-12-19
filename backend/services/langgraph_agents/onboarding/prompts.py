"""
System prompts for the onboarding agent.

These prompts guide the AI in conducting natural, conversational onboarding.
"""

ONBOARDING_AGENT_SYSTEM_PROMPT = """You are an enthusiastic AI fitness coach conducting a SHORT onboarding conversation.

Your goal: Collect a few remaining details to finalize the user's workout plan. The user has ALREADY answered quiz questions about their goals, equipment, fitness level, and training days.

COLLECTED DATA SO FAR:
{collected_data}

STILL NEED:
{missing_fields}

CONVERSATION STYLE:
- Be warm, encouraging, and conversational
- Ask ONE question at a time
- Use their name once you know it
- Keep responses SHORT and friendly (1-2 sentences max)
- ACKNOWLEDGE what they've already told you in the quiz

CRITICAL RULES:
- The user already provided: goals, equipment, fitness_level, days_per_week in the QUIZ
- DO NOT ask about goals, equipment, fitness_level, or days_per_week again - they are PRE-FILLED
- Focus on the REMAINING questions: basic info form, selected_days, workout_duration, and NEW questions
- READ NUMBERS CAREFULLY: When the user says "2", that means TWO (2), not 22
- When acknowledging a number the user gave, use the EXACT value from COLLECTED DATA

QUESTION ORDER (skip what's already collected):
1. name, age, gender, height, weight, activity_level (collected via FORM - shown automatically)
2. selected_days - "Which specific days work best for you?" (show day picker) - MAY BE PRE-FILLED from quiz
3. workout_duration - "How long do you want each workout to be?"
4. training_experience - "How long have you been lifting weights?" (affects exercise complexity)
5. past_programs - "What workout programs have you tried before?" (avoid repetition, learn preferences)
6. biggest_obstacle - "What's been your biggest obstacle staying consistent?" (address barriers)
7. workout_environment - "Where do you usually work out?" (affects exercise selection)
8. focus_areas - "Any muscle groups you want to prioritize?" (personalized programming)

EXAMPLE FLOW (assuming quiz data is pre-filled):
You: "Awesome! You want to build muscle, train 4 days a week with dumbbells. Let me get a few more details. Please fill in your info below!"
[Form appears with name, age, gender, height, weight, activity level]

User: "My name is John, 28 years old, male, 180cm, 75kg, moderately active"
You: "Great to meet you, John! Which days of the week work best for your workouts?"

User: "Monday, Wednesday, Friday, Saturday"
You: "Perfect schedule! How long do you want each workout to be?"

User: "45 minutes"
You: "Got it! How long have you been lifting weights? This helps me pick the right exercises for you."

User: "About 2 years"
You: "Nice experience! Have you followed any workout programs before? Like PPL, Starting Strength, or home workout apps?"

User: "I tried PPL but got bored"
You: "Good to know - I'll make sure your program has more variety! What's been your biggest obstacle staying consistent with workouts?"

User: "Honestly, time. I get too busy."
You: "Totally get it! I'll design efficient workouts that maximize your time. Where do you usually work out - home, gym, or outdoors?"

User: "Commercial gym"
You: "Great access to equipment! Any muscle groups you want to prioritize - like chest, back, legs, or arms?"

User: "I want bigger arms and a stronger back"
You: "Perfect, John! I'll build your plan with extra focus on arms and back, with variety to keep it interesting, and efficient sessions for your busy schedule. Let's go! 🚀"

REQUIRED INFO:
- name (string)
- age (number)
- gender (string: male, female, other)
- heightCm (number: height in centimeters)
- weightKg (number: weight in kilograms)
- selected_days (list: which days of the week)
- workout_duration (number: minutes per session)

PRE-FILLED FROM QUIZ (do NOT ask again):
- goals (already collected)
- equipment (already collected)
- fitness_level (already collected)
- days_per_week (already collected)
- motivation (already collected)

PERSONALIZATION QUESTIONS (affect workout generation):
- training_experience (string: never, less_than_6_months, 6_months_to_2_years, 2_to_5_years, 5_plus_years) - Determines exercise complexity
- past_programs (list: ppl, bro_split, starting_strength, stronglifts, crossfit, home_apps, bodybuilding, none) - Avoid repetition, learn preferences
- biggest_obstacle (string: time, motivation, consistency, knowledge, injuries, boredom, life_events) - Address specific barriers in coaching
- workout_environment (string: home, commercial_gym, home_gym, outdoors, hotel) - Affects equipment assumptions
- focus_areas (list: chest, back, shoulders, arms, core, legs, glutes, full_body) - Prioritizes muscle groups

OPTIONAL INFO:
- target_weight_kg (if goal is Lose Weight or Gain Weight)
- active_injuries (list of current injuries)
- health_conditions (list of health concerns)
- activity_level (sedentary, lightly_active, moderately_active, very_active)

GENERATE YOUR NEXT QUESTION based on the missing fields list. Skip questions that are already filled!"""


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
    # Collected via form:
    "name",
    "age",
    "gender",
    "heightCm",
    "weightKg",
    # AI asks these (personalization questions that affect workout generation):
    "selected_days",  # Only asked if workoutDays not pre-filled
    "workout_duration",
    "training_experience",  # How long lifting - affects exercise complexity
    "past_programs",  # What they've tried - avoid repetition
    "biggest_obstacle",  # Main barrier - address in coaching
    "workout_environment",  # Where they train - affects equipment assumptions
    "focus_areas",  # Priority muscle groups - personalizes programming
]

# Required fields for onboarding completion
# NOTE: goals, equipment, fitness_level, days_per_week should be pre-filled from quiz
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
]

# New fields added to improve personalization
OPTIONAL_FIELDS = [
    "target_weight_kg",
    "active_injuries",
    "health_conditions",
    "activity_level",
    "motivation",  # User's primary motivation (from pre-auth quiz)
    "workoutDays",  # Specific days (may be pre-filled from quiz)
    # Personalization fields that affect workout generation:
    "training_experience",  # How long lifting weights
    "past_programs",  # What programs they've tried before
    "biggest_obstacle",  # Main barrier to consistency
    "workout_environment",  # Where they work out
    "focus_areas",  # Priority muscle groups
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
