"""
Centralized Gemini client factory.

Uses Vertex AI when GCP_PROJECT_ID is set, otherwise falls back to API key auth.
"""
from __future__ import annotations

import base64
import json
import os
import tempfile
from typing import Optional

from google import genai

from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)

_credentials_file: Optional[str] = None


def _setup_credentials() -> None:
    """Decode base64 service account JSON from GCP_CREDENTIALS_JSON_B64 to a temp file."""
    global _credentials_file
    if _credentials_file is not None:
        return

    settings = get_settings()
    creds_b64 = settings.gcp_credentials_json_b64
    if not creds_b64:
        return

    try:
        decoded = base64.b64decode(creds_b64)
        # Validate it's valid JSON
        json.loads(decoded)

        fd, path = tempfile.mkstemp(suffix=".json", prefix="gcp_sa_")
        with os.fdopen(fd, "wb") as f:
            f.write(decoded)
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = path
        _credentials_file = path
        logger.info("Vertex AI credentials written to temp file")
    except Exception as e:
        logger.error(f"Failed to write service account credentials: {e}")


def get_genai_client() -> genai.Client:
    """Return a google.genai Client. Uses Vertex AI if configured, else API key."""
    settings = get_settings()

    if settings.gcp_project_id:
        _setup_credentials()
        logger.info(
            f"Using Vertex AI: project={settings.gcp_project_id}, "
            f"location={settings.gcp_location}"
        )
        return genai.Client(
            vertexai=True,
            project=settings.gcp_project_id,
            location=settings.gcp_location,
        )

    return genai.Client(api_key=settings.gemini_api_key)


def get_langchain_llm(temperature: float = 0.7, timeout: Optional[int] = None, model_kwargs: Optional[dict] = None):
    """
    Return a LangChain ChatGoogleGenerativeAI instance.

    Uses Vertex AI when GCP_PROJECT_ID is set, otherwise API key.
    """
    settings = get_settings()

    if settings.gcp_project_id:
        _setup_credentials()
        from langchain_google_vertexai import ChatVertexAI

        kwargs = {
            "model_name": settings.gemini_model,
            "project": settings.gcp_project_id,
            "location": settings.gcp_location,
            "temperature": temperature,
        }
        if timeout is not None:
            kwargs["request_timeout"] = timeout
        if model_kwargs is not None:
            kwargs["model_kwargs"] = model_kwargs
        return ChatVertexAI(**kwargs)

    from langchain_google_genai import ChatGoogleGenerativeAI

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
