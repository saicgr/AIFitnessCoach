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
    """Set up Vertex AI credentials and environment variables.

    Decodes base64 service account JSON to a temp file and sets env vars
    that the google-genai SDK and langchain-google-genai auto-detect:
    - GOOGLE_APPLICATION_CREDENTIALS (service account file)
    - GOOGLE_GENAI_USE_VERTEXAI=true
    - GOOGLE_CLOUD_PROJECT
    - GOOGLE_CLOUD_LOCATION
    """
    global _credentials_file
    if _credentials_file is not None:
        return

    settings = get_settings()

    # Set Vertex AI env vars for google-genai SDK auto-detection
    os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "true"
    os.environ["GOOGLE_CLOUD_PROJECT"] = settings.gcp_project_id
    os.environ["GOOGLE_CLOUD_LOCATION"] = settings.gcp_location

    creds_b64 = settings.gcp_credentials_json_b64
    if not creds_b64:
        _credentials_file = "env_only"  # Mark as set up (no file needed)
        logger.info("Vertex AI configured via env vars (no credentials file)")
        return

    try:
        decoded = base64.b64decode(creds_b64)
        json.loads(decoded)  # Validate it's valid JSON

        fd, path = tempfile.mkstemp(suffix=".json", prefix="gcp_sa_")
        with os.fdopen(fd, "wb") as f:
            f.write(decoded)
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = path
        _credentials_file = path
        logger.info("Vertex AI credentials written to temp file")
    except Exception as e:
        _credentials_file = "env_only"
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

    When GCP_PROJECT_ID is set, _setup_credentials() configures env vars
    (GOOGLE_GENAI_USE_VERTEXAI, GOOGLE_CLOUD_PROJECT, GOOGLE_CLOUD_LOCATION)
    that the google-genai SDK auto-detects. This avoids needing the heavy
    langchain-google-vertexai / google-cloud-aiplatform dependency.
    """
    from langchain_google_genai import ChatGoogleGenerativeAI

    settings = get_settings()

    # Ensure Vertex AI env vars are set if GCP is configured
    if settings.gcp_project_id:
        _setup_credentials()

    kwargs = {
        "model": settings.gemini_model,
        "temperature": temperature,
    }
    # Only pass api_key when NOT using Vertex AI (env vars handle auth)
    if not settings.gcp_project_id:
        kwargs["api_key"] = settings.gemini_api_key

    if timeout is not None:
        kwargs["timeout"] = timeout
    if model_kwargs is not None:
        kwargs["model_kwargs"] = model_kwargs
    return ChatGoogleGenerativeAI(**kwargs)
