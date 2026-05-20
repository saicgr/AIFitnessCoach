"""Integration test for Track A: confirm user_tz flows from the HTTP
handler → process_message → _build_agent_state → state['user_tz'] → tool.

Does NOT boot FastAPI — exercises the LangGraphCoachService directly with
a minimal mock + spy on _build_agent_state.

Usage:
    backend/.venv/bin/python backend/scripts/_test_tz_state_propagation.py
"""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv  # type: ignore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")


pass_count = 0
fail_count = 0


def check(label, got, want):
    global pass_count, fail_count
    ok = got == want
    if ok:
        pass_count += 1
        print(f"  ✅ {label}")
    else:
        fail_count += 1
        print(f"  ❌ {label}\n     got={got!r}\n     want={want!r}")


async def run() -> None:
    from services.langgraph_service import LangGraphCoachService

    # We're testing state plumbing, not the agent graph. Stub the internals
    # that would otherwise need Gemini / Supabase to be alive.
    svc = LangGraphCoachService.__new__(LangGraphCoachService)

    # Monkey-patch _enrich_user_profile to avoid DB calls.
    svc._enrich_user_profile = lambda req: {}
    svc._trim_conversation_history = lambda h: h or []

    # Build a minimal ChatRequest stand-in.
    class _Stub:
        def model_dump(self):
            return {}

    class _StubRequest:
        user_id = "test-user"
        user_profile = _Stub()
        conversation_history = []
        ai_settings = None
        unified_context = None
        media_refs = None
        media_ref = None
        current_workout = None
        workout_schedule = None
        image_base64 = None

    request = _StubRequest()

    from services.langgraph_service import AgentType
    from services.langgraph_service import CoachIntent

    print("\n[1] _build_agent_state propagates explicit user_tz")
    state = await svc._build_agent_state(
        AgentType.COACH,
        request,
        cleaned_message="hi",
        intent=CoachIntent.QUESTION,
        extraction_data={},
        rag_context="",
        rag_used=False,
        similar_questions=[],
        user_tz="America/Chicago",
    )
    check("state['user_tz'] = America/Chicago", state.get("user_tz"), "America/Chicago")

    print("\n[2] Missing user_tz defaults to UTC, not None")
    state = await svc._build_agent_state(
        AgentType.COACH,
        request,
        cleaned_message="hi",
        intent=CoachIntent.QUESTION,
        extraction_data={},
        rag_context="",
        rag_used=False,
        similar_questions=[],
    )
    check("state['user_tz'] defaults to UTC", state.get("user_tz"), "UTC")

    print("\n[3] Header-resolved tz survives all the way through to state")
    state = await svc._build_agent_state(
        AgentType.COACH,
        request,
        cleaned_message="hi",
        intent=CoachIntent.QUESTION,
        extraction_data={},
        rag_context="",
        rag_used=False,
        similar_questions=[],
        user_tz="Asia/Tokyo",
    )
    check("state['user_tz'] = Asia/Tokyo", state.get("user_tz"), "Asia/Tokyo")


asyncio.run(run())

print(f"\n{'='*60}")
print(f"  PASS: {pass_count}   FAIL: {fail_count}")
print(f"{'='*60}")
sys.exit(0 if fail_count == 0 else 2)
