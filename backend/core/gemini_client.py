"""
Centralized Gemini client factory.

Provides a single place to switch between Google AI Studio (API key)
and Vertex AI (GCP project auth). When GCP_PROJECT_ID is set, all
clients use Vertex AI; otherwise they fall back to the API key.
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

_credentials_setup_done = False


def _setup_credentials() -> None:
    """
    Decode base64 service account JSON and set GOOGLE_APPLICATION_CREDENTIALS.

    Call once at startup. Safe to call multiple times (no-ops after first).
    """
    global _credentials_setup_done
    if _credentials_setup_done:
        return

    settings = get_settings()

    if not settings.use_vertex_ai:
        logger.info("Vertex AI disabled (no GCP_PROJECT_ID). Using API key auth.")
        _credentials_setup_done = True
        return

    # If GOOGLE_APPLICATION_CREDENTIALS is already set (e.g. local dev), skip
    if os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        logger.info(
            f"Using existing GOOGLE_APPLICATION_CREDENTIALS: "
            f"{os.environ['GOOGLE_APPLICATION_CREDENTIALS']}"
        )
        _credentials_setup_done = True
        return

    # Decode base64 service account JSON from env var (for Render)
    if settings.gcp_credentials_json_b64:
        try:
            creds_json = base64.b64decode(settings.gcp_credentials_json_b64)
            # Validate it's valid JSON
            json.loads(creds_json)

            tmp = tempfile.NamedTemporaryFile(
                mode="wb", suffix=".json", delete=False, prefix="gcp_creds_"
            )
            tmp.write(creds_json)
            tmp.close()
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = tmp.name
            logger.info(f"Wrote GCP credentials to {tmp.name}")
        except Exception as e:
            logger.error(f"Failed to decode GCP_CREDENTIALS_JSON_B64: {e}")
            raise
    else:
        logger.warning(
            "Vertex AI enabled but no credentials found. "
            "Set GOOGLE_APPLICATION_CREDENTIALS or GCP_CREDENTIALS_JSON_B64."
        )

    _credentials_setup_done = True


def get_genai_client() -> genai.Client:
    """
    Return a google.genai Client configured for Vertex AI or API key mode.
    """
    settings = get_settings()

    if settings.use_vertex_ai:
        return genai.Client(
            vertexai=True,
            project=settings.gcp_project_id,
            location=settings.gcp_location,
        )
    else:
        return genai.Client(api_key=settings.gemini_api_key)


def get_langchain_llm(temperature: float = 0.7, timeout: Optional[int] = None, model_kwargs: Optional[dict] = None):
    """
    Return a LangChain chat model configured for Vertex AI or API key mode.

    Args:
        temperature: Sampling temperature (0-1).
        timeout: Request timeout in seconds.
        model_kwargs: Extra model kwargs (e.g. response_mime_type).

    Returns:
        ChatVertexAI or ChatGoogleGenerativeAI instance.
    """
    settings = get_settings()

    if settings.use_vertex_ai:
        from langchain_google_vertexai import ChatVertexAI

        kwargs = {
            "model": settings.gemini_model,
            "project": settings.gcp_project_id,
            "location": settings.gcp_location,
            "temperature": temperature,
        }
        # Note: ChatVertexAI does not accept a timeout constructor param;
        # the default GCP client timeout is used.
        if model_kwargs is not None:
            kwargs["model_kwargs"] = model_kwargs
        return ChatVertexAI(**kwargs)
    else:
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
