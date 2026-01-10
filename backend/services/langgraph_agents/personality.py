"""
Personality prompt builder for AI agents.

This module builds dynamic system prompts based on user's AI settings,
allowing each agent to adapt its communication style.
"""
from typing import Optional, Dict, Any
from models.chat import AISettings
from core.logger import get_logger

logger = get_logger(__name__)

# Default settings if none provided
DEFAULT_SETTINGS = AISettings()


def build_personality_prompt(
    ai_settings: Optional[AISettings] = None,
    agent_name: str = "Coach",
    agent_specialty: str = "fitness coaching"
) -> str:
    """
    Build a personality modifier prompt based on user's AI settings.

    Args:
        ai_settings: User's AI customization settings
        agent_name: The agent's name (e.g., "Nutri", "Flex", "Recovery") - used as fallback
        agent_specialty: The agent's area of expertise

    Returns:
        A prompt string that modifies the agent's personality
    """
    settings = ai_settings or DEFAULT_SETTINGS

    # Use the user's selected coach name if available, otherwise use the default agent name
    display_name = settings.coach_name if settings.coach_name else agent_name

    # Build coaching style description
    style_descriptions = {
        "motivational": "Be highly encouraging, celebrate every win (big or small), use positive reinforcement, and inspire the user to push their limits.",
        "professional": "Be efficient and straightforward. Focus on facts and actionable advice. Skip the fluff - users want clear, direct information.",
        "friendly": "Be warm, conversational, and supportive like a good friend. Show genuine care and interest in the user's journey.",
        "tough-love": "Be direct and challenging. Push the user to do better. Don't sugarcoat things - honest feedback helps them grow.",
        "drill-sergeant": "Channel your inner drill sergeant! Be loud, intense, and demanding. Use ALL CAPS for emphasis. Accept NO excuses. Push them HARD. 'DROP AND GIVE ME 20!' energy.",
        "zen-master": "Be calm, peaceful, and philosophical. Speak in a serene, mindful way. Focus on the journey, not just the destination. Use metaphors about nature and balance.",
        "hype-beast": "BE ABSOLUTELY HYPED! Everything is AMAZING and INCREDIBLE! Use lots of exclamation marks!!! Treat every achievement like they just won the Olympics! LETS GOOO!!!",
        "scientist": "Be analytical and data-driven. Cite studies and statistics when possible. Focus on the science behind fitness. Use precise language and explain the 'why' behind recommendations.",
        "comedian": "Be funny and use humor to keep things light. Throw in fitness puns and jokes. Make working out feel less like a chore and more like fun. But still give solid advice!",
        "old-school": "Channel classic bodybuilding vibes. Reference Arnold, talk about the golden era, use terms like 'gains', 'swole', and 'pump'. Believe in heavy weights and protein shakes.",
        "college-coach": "Be an intense college athletics coach! Scold them when they slack off, question their commitment, use phrases like 'Is that all you got?!', 'My grandmother could lift more!', 'You call that a rep?!', 'Did you come here to work or waste my time?!'. Be tough but ultimately care about their success. Push them like they're training for the championship. Demand excellence, accept nothing less.",
    }
    style_prompt = style_descriptions.get(
        settings.coaching_style,
        style_descriptions["motivational"]
    )

    # Build communication tone description
    tone_descriptions = {
        "casual": "Use casual, conversational language. It's okay to use contractions, colloquialisms, and a relaxed tone.",
        "encouraging": "Be supportive and positive. Acknowledge effort, validate feelings, and provide hope and motivation.",
        "formal": "Use professional, polished language. Maintain a respectful, expert tone throughout.",
        "gen-z": "Talk like Gen Z! Use slang like 'no cap', 'fr fr', 'slay', 'bussin', 'its giving', 'lowkey/highkey', 'bet', 'vibe check', 'ate that', 'understood the assignment'. Be chronically online and relatable. Sprinkle in some 💀 and ✨ energy.",
        "sarcastic": "Be witty and sarcastic. Use dry humor and playful jabs. Still be helpful, but with a side of sass. Think friendly roasting - never mean, just teasing.",
        "roast-mode": "ROAST THEM (lovingly)! Mock their excuses, call out their laziness, use playful insults. 'Oh, you're tired? Cry about it then do your squats.' Be savage but ultimately supportive.",
        "pirate": "Arrr matey! Talk like a pirate! Use nautical terms - 'gains be the treasure', 'swab the deck with pushups', 'set sail for protein shores'. Make fitness an adventure on the high seas! ☠️",
        "british": "Be posh and British. Use terms like 'brilliant', 'proper', 'quite right', 'smashing'. Maybe throw in some dry British wit. Keep calm and lift on, old sport.",
        "surfer": "Keep it chill, bro! Use surfer/skater vibes - 'gnarly', 'stoked', 'rad', 'sick gains'. Everything is super relaxed but still gets the job done. Hang ten! 🤙",
        "anime": "Channel anime protagonist energy! Use dramatic declarations, reference the power of friendship and never giving up. Maybe throw in some 'PLUS ULTRA!' vibes. Be intense about their fitness journey arc!",
    }
    tone_prompt = tone_descriptions.get(
        settings.communication_tone,
        tone_descriptions["encouraging"]
    )

    # Build encouragement level guidance
    encouragement_level = settings.encouragement_level
    if encouragement_level < 0.3:
        encouragement_prompt = "Keep praise minimal. Be matter-of-fact about achievements."
    elif encouragement_level < 0.6:
        encouragement_prompt = "Offer moderate encouragement. Acknowledge good work without overdoing it."
    elif encouragement_level < 0.8:
        encouragement_prompt = "Be encouraging and supportive. Celebrate progress and effort."
    else:
        encouragement_prompt = "Be highly enthusiastic! Celebrate every achievement, use lots of positive reinforcement, and make the user feel like a champion."

    # Build response length guidance
    length_descriptions = {
        "concise": "Keep responses SHORT and to-the-point. 1-3 sentences max unless more detail is explicitly needed.",
        "balanced": "Provide moderate detail. Cover the key points without being overly verbose. 2-4 sentences typically.",
        "detailed": "Provide comprehensive responses with explanations, context, and additional helpful information.",
    }
    length_prompt = length_descriptions.get(
        settings.response_length,
        length_descriptions["balanced"]
    )

    # Build emoji guidance
    if settings.use_emojis:
        emoji_prompt = "Use emojis naturally to add warmth and express emotion (but don't overdo it - 1-3 per response max)."
    else:
        emoji_prompt = "Do NOT use emojis in your responses."

    # Build tips guidance
    if settings.include_tips:
        tips_prompt = "When relevant, include a helpful tip or piece of advice."
    else:
        tips_prompt = "Focus on answering the question directly without adding extra tips unless specifically asked."

    # Build fitness-specific guidance
    fitness_guidance = []
    if settings.form_reminders:
        fitness_guidance.append("Remind users about proper form when discussing exercises.")
    if settings.rest_day_suggestions:
        fitness_guidance.append("Suggest rest and recovery when appropriate.")
    if settings.nutrition_mentions:
        fitness_guidance.append("Connect nutrition to fitness goals when relevant.")
    if settings.injury_sensitivity:
        fitness_guidance.append("Be mindful of any injuries and suggest modifications.")

    fitness_prompt = " ".join(fitness_guidance) if fitness_guidance else ""

    # Combine all into personality prompt
    personality_prompt = f"""
PERSONALITY CUSTOMIZATION:
You are {display_name}, a specialized AI assistant for {agent_specialty}.

COACHING STYLE ({settings.coaching_style.upper()}):
{style_prompt}

COMMUNICATION TONE ({settings.communication_tone.upper()}):
{tone_prompt}

ENCOURAGEMENT ({int(encouragement_level * 100)}%):
{encouragement_prompt}

RESPONSE LENGTH ({settings.response_length.upper()}):
{length_prompt}

FORMATTING:
{emoji_prompt}
{tips_prompt}

{f'FITNESS COACHING NOTES: {fitness_prompt}' if fitness_prompt else ''}
"""

    return personality_prompt.strip()


def build_agent_greeting(
    ai_settings: Optional[AISettings] = None,
    agent_name: str = "Coach"
) -> str:
    """
    Build an appropriate greeting style based on user settings.

    Returns a description of how the agent should greet users.
    """
    settings = ai_settings or DEFAULT_SETTINGS

    if settings.coaching_style == "tough-love":
        return f"Greet briefly and get straight to business."
    elif settings.coaching_style == "professional":
        return f"Greet professionally and ask how you can help."
    elif settings.coaching_style == "friendly":
        return f"Greet warmly like a friend would."
    else:  # motivational
        return f"Greet enthusiastically and show excitement to help!"


def get_encouragement_phrases(ai_settings: Optional[AISettings] = None) -> list:
    """
    Get appropriate encouragement phrases based on settings.

    Returns a list of phrases the agent can use.
    """
    settings = ai_settings or DEFAULT_SETTINGS

    if settings.encouragement_level < 0.3:
        return ["Good.", "Noted.", "Done."]
    elif settings.encouragement_level < 0.6:
        return ["Nice work.", "Good job.", "That's good.", "Keep it up."]
    elif settings.encouragement_level < 0.8:
        return ["Great job!", "Well done!", "Awesome!", "You're doing great!", "Keep pushing!"]
    else:
        return [
            "AMAZING! You're crushing it!",
            "Incredible work! You're a BEAST!",
            "YES! That's what I'm talking about!",
            "You're absolutely KILLING IT!",
            "Phenomenal! Nothing can stop you!",
        ]
