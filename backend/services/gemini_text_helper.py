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
    """Run a plain-text prompt and return the response text."""
    cfg_kwargs = {"temperature": temperature}
    if max_output_tokens is not None:
        cfg_kwargs["max_output_tokens"] = max_output_tokens
    response = await gemini_generate_with_retry(
        model=_settings.gemini_model,
        contents=[prompt],
        config=types.GenerateContentConfig(**cfg_kwargs),
        method_name=method_name,
        user_id=user_id,
    )
    return (response.text or "").strip()
