"""
intent_classifier.py — classify a SharedContent blob (text + media + metadata)
into one of the import intents handled by the share-funnel orchestrator.

Used by `/api/v1/share/fetch-url` and `/api/v1/share/import-text` and
`/api/v1/share/import-audio` after fetch+transcribe. The result drives which
extractor (workout / recipe / etc.) is invoked.

Single Gemini Flash call — small input, ~80 tokens output. Cost ~$0.0001 per
call. Returns deterministic enums, never free-text.
"""
from __future__ import annotations

from typing import Any, Literal, Optional
import json

from google.genai import types

from core.config import get_settings
from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry

logger = get_logger(__name__)
settings = get_settings()


Intent = Literal[
    "workout_extract",
    "recipe_extract",
    "meal_plan_extract",
    "food_log_extract",
    "form_check",
    "progress_log",
    "tip_save",
    "nutrition_question",
    "discuss",
]

VALID_INTENTS = {
    "workout_extract",
    "recipe_extract",
    "meal_plan_extract",
    "food_log_extract",
    "form_check",
    "progress_log",
    "tip_save",
    "nutrition_question",
    "discuss",
}

Confidence = Literal["high", "medium", "low"]


def _classify_prompt() -> str:
    try:
        from prompts.share import load
        return load("intent_classifier")
    except Exception:
        # Fallback path used when the prompts directory isn't accessible
        # (e.g. some test harnesses don't add backend/ to sys.path).
        return _CLASSIFY_PROMPT_INLINE


# Inline fallback kept verbatim with prompts/share/intent_classifier.md.
_CLASSIFY_PROMPT_INLINE = """You are a content classifier for a fitness + nutrition app.

Given a piece of text (caption, transcript, pasted AI response, recipe page,
voice memo transcript, etc.), classify the PRIMARY intent into ONE of these:

- workout_extract       a structured exercise routine (sets, reps, exercises)
- recipe_extract        a recipe (ingredients + steps to cook one dish)
- meal_plan_extract     multi-day meal plan ("Day 1: breakfast … Day 2: …")
- food_log_extract      a SINGLE meal already eaten that the user wants logged
                        ("I had 1 cup rice and 200 g chicken")
- form_check            a short clip / description of ONE exercise, asking
                        if form looks right
- progress_log          progress photo(s); body comp before/after
- tip_save              motivational / educational paragraph worth saving but
                        not a structured plan (Perplexity essay, X tip)
- nutrition_question    user is asking a question ("how many carbs in…",
                        "should I eat before lifting")
- discuss               anything else; routes to the AI Coach chat

If the content has multiple legit intents (e.g. ChatGPT response with BOTH
a workout AND a recipe), put the dominant one as `intent` and list the
others in `secondary_intents`.

Also rate confidence:
- high   : the content is clearly one of the above; structured signals match
- medium : best guess but content is mixed or ambiguous
- low    : you genuinely cannot tell; UI will show a chooser

Respond ONLY with compact JSON of the form:
{"intent":"workout_extract","confidence":"high","secondary_intents":[],"why":"numbered list of exercises with sets and reps"}

No commentary, no markdown fences."""


async def classify_intent(
    *,
    text: str,
    source_origin: Optional[str] = None,
    locale: Optional[str] = None,
    extra_signals: Optional[dict[str, Any]] = None,
) -> dict[str, Any]:
    """Classify the given text into an Intent. Returns dict with keys
    `intent`, `confidence`, `secondary_intents`, `why`.

    `source_origin` (e.g. "youtube", "chatgpt", "voicememos") is appended as
    a hint to the prompt — it helps disambiguate but the model can override.
    """
    text = (text or "").strip()
    if not text:
        return {
            "intent": "discuss",
            "confidence": "low",
            "secondary_intents": [],
            "why": "empty input",
        }

    # Truncate to keep cost predictable. The classifier doesn't need an
    # 18k-token transcript — first ~6k chars usually carry the signal.
    snippet = text[:6000]

    hint = ""
    if source_origin:
        hint = f"\n\nSource: {source_origin}"
    if locale:
        hint += f"\nUser locale: {locale}"
    if extra_signals:
        # Keep small — only short, structured hints.
        for k, v in list(extra_signals.items())[:5]:
            hint += f"\n{k}: {str(v)[:80]}"

    full_prompt = f"{_classify_prompt()}{hint}\n\n---\nCONTENT:\n{snippet}\n---"

    model = settings.gemini_model

    try:
        response = await gemini_generate_with_retry(
            model=model,
            contents=[full_prompt],
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=200,
                response_mime_type="application/json",
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
            method_name="share_intent_classify",
        )
        raw = (response.text or "").strip()
        parsed = _safe_parse_json(raw)

        intent = parsed.get("intent", "discuss")
        if intent not in VALID_INTENTS:
            intent = "discuss"

        confidence = parsed.get("confidence", "low")
        if confidence not in ("high", "medium", "low"):
            confidence = "low"

        secondary_raw = parsed.get("secondary_intents", []) or []
        secondary = [s for s in secondary_raw if s in VALID_INTENTS and s != intent]

        return {
            "intent": intent,
            "confidence": confidence,
            "secondary_intents": secondary[:3],
            "why": str(parsed.get("why", ""))[:240],
        }
    except Exception as e:
        logger.warning(f"[IntentClassifier] failed: {e}", exc_info=True)
        return {
            "intent": "discuss",
            "confidence": "low",
            "secondary_intents": [],
            "why": "classifier error — falling back to chat",
        }


def _safe_parse_json(raw: str) -> dict[str, Any]:
    """Tolerant JSON parser — Gemini occasionally emits markdown fences even
    with response_mime_type=application/json set."""
    if not raw:
        return {}
    s = raw.strip()
    if s.startswith("```"):
        # Strip ```json ... ```
        s = s.split("\n", 1)[-1] if "\n" in s else s
        if s.endswith("```"):
            s = s[:-3]
    s = s.strip()
    try:
        return json.loads(s)
    except Exception:
        # Last-ditch — find the first { … } block
        start = s.find("{")
        end = s.rfind("}")
        if start >= 0 and end > start:
            try:
                return json.loads(s[start : end + 1])
            except Exception:
                return {}
        return {}


# Routing hint exported for the orchestrator: each intent maps to one of a
# small set of frontend destinations + the target_entity_kind to persist on
# shared_items.
INTENT_ROUTING: dict[str, dict[str, str]] = {
    "workout_extract": {
        "redirect_screen": "workout_import_review",
        "target_entity_kind": "workout",
    },
    "recipe_extract": {
        "redirect_screen": "recipe_import_paste",
        "target_entity_kind": "recipe",
    },
    "meal_plan_extract": {
        "redirect_screen": "meal_plan_import_review",
        "target_entity_kind": "meal_plan",
    },
    "food_log_extract": {
        "redirect_screen": "food_log_text",
        "target_entity_kind": "food_log",
    },
    "form_check": {
        "redirect_screen": "form_check",
        "target_entity_kind": "form_check_job",
    },
    "progress_log": {
        "redirect_screen": "progress_upload",
        "target_entity_kind": "progress_photo",
    },
    "tip_save": {
        "redirect_screen": "saved_tip",
        "target_entity_kind": "saved_tip",
    },
    "nutrition_question": {
        "redirect_screen": "chat",
        "target_entity_kind": "chat",
    },
    "discuss": {
        "redirect_screen": "chat",
        "target_entity_kind": "chat",
    },
}
