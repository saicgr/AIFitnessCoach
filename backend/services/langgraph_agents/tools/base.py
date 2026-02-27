"""
Base utilities for LangGraph tools.

Contains shared utilities like service accessors and async helpers.
"""

from typing import Optional

from services.vision_service import VisionService
from core.logger import get_logger

logger = get_logger(__name__)

# Singleton vision service
_vision_service: Optional[VisionService] = None

# Singleton form analysis service
_form_analysis_service = None


def get_vision_service() -> VisionService:
    """Get or create the vision service singleton."""
    global _vision_service
    if _vision_service is None:
        _vision_service = VisionService()
    return _vision_service


def get_form_analysis_service():
    """Get or create the form analysis service singleton."""
    global _form_analysis_service
    if _form_analysis_service is None:
        from services.form_analysis_service import FormAnalysisService
        _form_analysis_service = FormAnalysisService()
    return _form_analysis_service


def run_async_in_sync(coro, timeout: int = 30):
    """
    Run an async coroutine in a synchronous context.

    Handles the case where an event loop is already running.

    Args:
        coro: The coroutine to run
        timeout: Timeout in seconds

    Returns:
        The result of the coroutine
    """
    import asyncio
    import concurrent.futures

    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            with concurrent.futures.ThreadPoolExecutor() as executor:
                future = executor.submit(asyncio.run, coro)
                return future.result(timeout=timeout)
        else:
            return asyncio.run(coro)
    except RuntimeError:
        # No running event loop
        return asyncio.run(coro)
