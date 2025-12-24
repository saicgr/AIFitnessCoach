"""
Tests for base tool utilities.
"""

import pytest
import asyncio
from unittest.mock import patch, MagicMock


class TestGetVisionService:
    """Tests for get_vision_service function."""

    def test_creates_singleton(self):
        """Test that vision service is created as singleton."""
        from services.langgraph_agents.tools.base import get_vision_service, _vision_service

        # Reset singleton
        import services.langgraph_agents.tools.base as base_module
        base_module._vision_service = None

        with patch('services.langgraph_agents.tools.base.VisionService') as mock_vision:
            mock_instance = MagicMock()
            mock_vision.return_value = mock_instance

            # First call creates instance
            service1 = get_vision_service()
            assert mock_vision.called

            # Second call returns same instance
            mock_vision.reset_mock()
            service2 = get_vision_service()
            assert not mock_vision.called
            assert service1 is service2


class TestRunAsyncInSync:
    """Tests for run_async_in_sync function."""

    def test_runs_coroutine(self):
        """Test running a simple coroutine."""
        from services.langgraph_agents.tools.base import run_async_in_sync

        async def simple_coro():
            return "hello"

        result = run_async_in_sync(simple_coro())
        assert result == "hello"

    def test_handles_async_value(self):
        """Test running coroutine that returns computed value."""
        from services.langgraph_agents.tools.base import run_async_in_sync

        async def compute_coro():
            await asyncio.sleep(0.01)
            return 42

        result = run_async_in_sync(compute_coro())
        assert result == 42

    def test_respects_timeout(self):
        """Test that timeout is passed correctly."""
        from services.langgraph_agents.tools.base import run_async_in_sync

        async def fast_coro():
            return "fast"

        result = run_async_in_sync(fast_coro(), timeout=1)
        assert result == "fast"

    def test_handles_exception(self):
        """Test that exceptions are propagated."""
        from services.langgraph_agents.tools.base import run_async_in_sync

        async def error_coro():
            raise ValueError("test error")

        with pytest.raises(ValueError, match="test error"):
            run_async_in_sync(error_coro())
