"""
Base utilities for LangGraph tools.

Contains shared utilities like service accessors and async helpers.
"""
import asyncio

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
    Run an async coroutine from a synchronous context.

    This is called from sync LangGraph tool functions that are offloaded to
    worker threads by LangChain (via asyncio.to_thread) when the graph is
    invoked with ainvoke().

    The coroutine often uses objects (e.g. Gemini client.aio) that are bound
    to the main uvicorn event loop. Creating a new loop with asyncio.run()
    causes "Future attached to a different loop" errors. Instead, we schedule
    the coroutine on the existing main event loop via run_coroutine_threadsafe
    and block the worker thread until the result is ready.

    Falls back to asyncio.run() only when no pre-existing loop is found
    (e.g. standalone scripts, tests).

    Args:
        coro: The coroutine to run
        timeout: Timeout in seconds

    Returns:
        The result of the coroutine
    """
    import asyncio

    # First, check if there is a running loop in THIS thread.
    # This happens if the sync tool is called directly on the event loop
    # thread (unusual but possible).
    try:
        running_loop = asyncio.get_running_loop()
        # We are on the event loop thread. Schedule the coroutine as a task
        # and block-wait. Note: this will deadlock if the loop cannot process
        # tasks concurrently, but this case should not occur in practice since
        # LangChain offloads sync tools to worker threads.
        future = asyncio.run_coroutine_threadsafe(coro, running_loop)
        return future.result(timeout=timeout)
    except RuntimeError:
        pass

    # We are in a worker thread (no running loop here).
    # Try to find the main event loop (uvicorn/FastAPI) to schedule the
    # coroutine there. In Python 3.11, get_event_loop() returns the main
    # thread's default loop even from a worker thread.
    try:
        main_loop = asyncio.get_event_loop()
        if main_loop.is_running():
            future = asyncio.run_coroutine_threadsafe(coro, main_loop)
            return future.result(timeout=timeout)
    except RuntimeError:
        pass

    # No running loop found anywhere — safe to create a new one.
    return asyncio.run(coro)
