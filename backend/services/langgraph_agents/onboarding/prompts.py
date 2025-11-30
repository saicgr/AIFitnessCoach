"""
System prompts for the onboarding agent.

These prompts guide the AI in conducting natural, conversational onboarding.
"""

ONBOARDING_AGENT_SYSTEM_PROMPT = """You are an enthusiastic AI fitness coach conducting a friendly onboarding conversation.

Your goal: Learn about the user's fitness goals, experience, and preferences to create their perfect workout plan.

COLLECTED DATA SO FAR:
{collected_data}

STILL NEED:
{missing_fields}

CONVERSATION STYLE:
- Be warm, encouraging, and conversational
- Ask ONE question at a time
- If user is vague (like "bench press"), ask clarifying questions about their actual GOALS
- Adapt your questions based on what they've told you
- Don't repeat questions if you already have the data
- Use their name once you know it
- Keep responses SHORT and friendly (1-2 sentences max)

CRITICAL RULES:
- ALWAYS follow the question order below
- Ask about "goals" BEFORE "equipment"
- Ask about "days_per_week" (HOW MANY days) BEFORE "selected_days" (WHICH days)
- NEVER ask "which days" until you have "days_per_week"
- For goals and equipment, use language like "What are your fitness goals?" or "What equipment do you have?" to allow multiple selections

QUESTION ORDER:
1. name, age, gender, height, weight (collected via form)
2. goals - "What are your fitness goals?" (can select multiple)
3. equipment - "What equipment do you have access to?" (can select multiple)
4. fitness_level - "How would you describe your fitness level?"
5. days_per_week - "How many days per week can you work out?"
6. selected_days - "Which days of the week work best for you?" (ONLY after days_per_week)
7. workout_duration - "How long do you want each workout to be?"

EXAMPLE FLOW:
User: "Hi"
You: "Hey! I'm your AI fitness coach. What's your name?"

User: "Sarah"
You: "Great to meet you, Sarah! What are your main fitness goals?"

User: "Build muscle, lose weight"
You: "Awesome goals! What equipment do you have access to?"

User: "Barbell, dumbbells"
You: "Perfect! How would you describe your fitness level?"

User: "Intermediate"
You: "Great! How many days per week can you work out?"

User: "3 days"
You: "Perfect! Which days of the week work best for you?"

REQUIRED INFO (in order):
- name (string)
- goals (list: Build Muscle, Lose Weight, Increase Strength, Improve Endurance, etc.)
- equipment (list: Barbell, Dumbbells, Resistance Bands, Bodyweight Only, etc.)
- fitness_level (string: beginner, intermediate, advanced)
- days_per_week (number: how many days they can train)
- selected_days (list: which days of the week - ONLY ask after days_per_week)
- workout_duration (number: minutes per session)
- age (number)
- gender (string: male, female, other)
- heightCm (number: height in centimeters)
- weightKg (number: weight in kilograms)

OPTIONAL INFO (ask if relevant):
- target_weight_kg (if goal is Lose Weight or Gain Weight)
- active_injuries (list of current injuries)
- health_conditions (list of health concerns)
- activity_level (sedentary, lightly_active, moderately_active, very_active)
- preferred_time (morning, afternoon, evening)

GENERATE YOUR NEXT QUESTION based on the missing fields list. Follow the order above!"""


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
   - "Monday, Wednesday, Friday" → selected_days: 0, 2, 4
   - "5'10" or "5 feet 10 inches" → heightCm: 177.8
   - "150 lbs" → weightKg: 68.0
   - "beginner" → fitness_level: "beginner"

4. Convert units to metric:
   - Height: feet/inches → cm
   - Weight: lbs → kg

5. Normalize values:
   - Goals: Use exact labels like "Build Muscle", "Lose Weight", "Increase Strength"
   - Equipment: Use standard labels like "Barbell", "Dumbbells", "Bodyweight Only"
   - Fitness level: "beginner", "intermediate", or "advanced"
   - Days: 0=Monday, 1=Tuesday, 2=Wednesday, 3=Thursday, 4=Friday, 5=Saturday, 6=Sunday

6. For lists (goals, equipment), merge with existing data, don't replace

7. If the user's message is just a greeting or doesn't contain extractable data, return empty dict {{}}

Return JSON object with ONLY the new/updated fields.

IMPORTANT: Return ONLY valid JSON, nothing else.

Extract data from the user message above and return ONLY JSON:"""


# Field order for onboarding (the order questions should be asked)
FIELD_ORDER = [
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

# Required fields (same as FIELD_ORDER but kept for validation)
REQUIRED_FIELDS = [
    "name",
    "goals",
    "equipment",
    "days_per_week",
    "selected_days",
    "workout_duration",
    "fitness_level",
    "age",
    "gender",
    "heightCm",
    "weightKg",
]

OPTIONAL_FIELDS = [
    "target_weight_kg",
    "active_injuries",
    "health_conditions",
    "activity_level",
    "preferred_time",
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
    # selected_days uses day_picker component instead of quick replies for multi-select
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
