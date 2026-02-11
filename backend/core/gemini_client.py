"""
Centralized Gemini client factory.

Always uses Google AI Studio (API key) auth.
"""
from __future__ import annotations

from typing import Optional

from google import genai

from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)


def get_genai_client() -> genai.Client:
    """Return a google.genai Client using API key auth."""
    settings = get_settings()
    return genai.Client(api_key=settings.gemini_api_key)


def get_langchain_llm(temperature: float = 0.7, timeout: Optional[int] = None, model_kwargs: Optional[dict] = None):
    """
    Return a LangChain ChatGoogleGenerativeAI instance.

    Args:
        temperature: Sampling temperature (0-1).
        timeout: Request timeout in seconds.
        model_kwargs: Extra model kwargs (e.g. response_mime_type).
    """
    from langchain_google_genai import ChatGoogleGenerativeAI

    settings = get_settings()

    kwargs = {
        "model": settings.gemini_model,
        "api_key": settings.gemini_api_key,
        "temperature": temperature,
    }
    if timeout is not None:
        kwargs["timeout"] = timeout
    if model_kwargs is not None:
        kwargs["model_kwargs"] = model_kwargs
    return ChatGoogleGenerativeAI(**kwargs)
