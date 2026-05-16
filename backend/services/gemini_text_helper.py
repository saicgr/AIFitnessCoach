"""Tiny helper: simple text-prompt Gemini call returning the response text.

The richer `services.gemini.constants.gemini_generate_with_retry` requires
`model=`, `contents=[]`, and a `GenerateContentConfig`. Several Recipes-tab
services only need a basic text completion — wrap the verbose call here.
"""
from typing import Optional

from google.genai import types

from core.config import get_settings
from services.gemini.constants import gemini_generate_with_retry


_settings = get_settings()


async def gemini_text(
    prompt: str,
    *,
    temperature: float = 0.2,
    max_output_tokens: Optional[int] = None,
    method_name: str = "recipes_helper",
    user_id: Optional[str] = None,
) -> str:
    """Run a plain-text prompt and return the response text.

    Uses Flash Lite + thinking disabled — these are Recipes-tab extraction
    tasks (parse a recipe, analyze an ingredient), not reasoning. On the
    full thinking model these calls were slow (thinking ate the budget) and
    recipe import dragged to ~25s. See core/config.py::gemini_vision_model.
    """
    cfg_kwargs = {
        "temperature": temperature,
        "thinking_config": types.ThinkingConfig(thinking_budget=0),
    }
    cfg_kwargs["max_output_tokens"] = max_output_tokens if max_output_tokens is not None else 4000
    response = await gemini_generate_with_retry(
        model=_settings.gemini_vision_model,
        contents=[prompt],
        config=types.GenerateContentConfig(**cfg_kwargs),
        method_name=method_name,
        user_id=user_id,
    )
    return (response.text or "").strip()
