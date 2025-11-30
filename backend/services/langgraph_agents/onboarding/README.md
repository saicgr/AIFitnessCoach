# LangGraph Onboarding Agent

**AI-driven conversational onboarding with NO hardcoded questions!**

## Why This Exists

The previous onboarding system used hardcoded question templates, which:
- ❌ Felt robotic and templated
- ❌ Created duplicate messages when users were vague
- ❌ Couldn't adapt to user context
- ❌ Bypassed the beautiful LangGraph agent system

This LangGraph agent fixes all of that by letting the AI decide what to ask.

## How It Works

### Agent Flow

```
START
  ↓
extract_data (GPT-4 extracts structured data from user message)
  ↓
check_completion (validate what's missing)
  ↓
router
  ├─→ ask_question (AI generates next question) → END
  └─→ complete (onboarding finished) → END
```

### Key Features

1. **AI-Generated Questions**
   - No templates! The AI decides what to ask based on:
     - What data is already collected
     - What's still missing
     - The user's last message
     - Conversation history

2. **Smart Clarifying Questions**
   - User: "bench press"
   - AI: "Nice! So you're interested in strength training. Are you looking to build muscle, increase strength, or both?"
   - Extracts: goals: [Build Muscle, Increase Strength], equipment: [Barbell]

3. **Intelligent Data Extraction**
   - Uses GPT-4 to extract structured data from natural language
   - Handles unit conversion: "5'10, 150 lbs" → heightCm: 177.8, weightKg: 68.0
   - Infers context: "kettlebell home workouts" → equipment: [Kettlebell], context: home

4. **No Duplicate Messages**
   - If extraction returns empty, AI asks a different clarifying question
   - Not stuck in loops!

## Files

```
onboarding/
├── __init__.py        # Public exports
├── state.py           # OnboardingState TypedDict
├── nodes.py           # Graph nodes (extract, check, agent)
├── prompts.py         # System prompts for AI
└── README.md          # This file
```

## Usage

```python
from services.langgraph_onboarding_service import LangGraphOnboardingService

service = LangGraphOnboardingService()

result = await service.process_message(
    user_id="user_123",
    message="I want to get stronger",
    collected_data={},
    conversation_history=[],
)

# result contains:
# - next_question: AI-generated question
# - extracted_data: Structured data from message
# - is_complete: Whether onboarding is finished
# - quick_replies: Optional quick reply buttons
```

## Testing

Run the test suite:
```bash
python3 test_langgraph_onboarding.py
```

Tests verify:
- ✅ Natural, AI-generated questions
- ✅ Clarifying questions for vague inputs
- ✅ Smart data extraction
- ✅ No duplicate messages

## Integration

The API endpoint automatically uses this agent:
- `POST /api/v1/onboarding/parse-response`

Frontend passes `conversation_history` and gets back AI-generated questions.

## Required Data

The agent collects:
- name
- goals (list)
- equipment (list)
- days_per_week (int)
- selected_days (list of day indices)
- workout_duration (int, minutes)
- fitness_level (beginner/intermediate/advanced)
- age (int)
- gender (string)
- heightCm (float)
- weightKg (float)

Optional:
- target_weight_kg
- active_injuries
- health_conditions
- activity_level
- preferred_time

## Comparison: Old vs New

### Old System (DEPRECATED)
```python
# Hardcoded question templates
questions = {
    "goals": {
        "question": f"Nice to meet you, {name}! What are your main fitness goals?",
        "type": "multi_select",
        "quick_replies": [...],
    }
}
```

**Problems:**
- Same question every time
- Can't adapt to user context
- Duplicate messages on vague inputs

### New System (This Agent)
```python
# AI generates question based on context
system_prompt = f"""
You are an AI fitness coach.

COLLECTED DATA: {collected_data}
STILL NEED: {missing_fields}

Ask ONE natural question to continue the conversation.
"""

response = await llm.ainvoke(messages)
```

**Benefits:**
- Different question every time
- Adapts to what user said
- Asks clarifying questions when needed

## Architecture

This agent uses the same LangGraph patterns as the main fitness coach agent:
- StateGraph with TypedDict state
- Async nodes
- Conditional routing
- Compiled graph

This makes the codebase consistent and easier to maintain!
