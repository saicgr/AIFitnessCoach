"""
Coach-agent PROGRAM tools — let the Coach recommend, start, and build training
programs from inside a chat conversation (Program Library integration).

  - recommend_program(user_id, goal_hint=None): pick a PUBLISHED library program
    that best matches the user's goal + level. Returns a program card + reason
    and action='recommend_program' so the chat renders a "View / Start" card.
  - assign_program(user_id, program_id, assigned_days, slot): START a program
    via the SAME `assign_program_core` the HTTP endpoint uses (clone -> customize
    -> assignment -> expand dated workouts -> clear /today cache). Returns
    action='assign_program'.
  - generate_coach_program(user_id, request, weeks=8): build a CUSTOM multi-week
    program from a chat description, reusing the text-parse generator + injury
    safety, persist it as a user_program_template, and return
    action='create_program' so the chat can open the draft / schedule it.

Conventions (mirror coach_tools.py): NO silent fallbacks — a real failure
raises / returns success=False with a chat-ready error; action_data is set so
build_action_data_node forwards the right card. user_id is supplied by the LLM
(the agent prompt interpolates it), exactly like the injury/nutrition tools.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from core.logger import get_logger

logger = get_logger(__name__)


def _run_coro(coro):
    """Run an async coroutine from a sync context (langchain tool executor)."""
    try:
        from .base import run_async_in_sync  # lazy import
        return run_async_in_sync(coro)
    except Exception:
        import asyncio
        return asyncio.get_event_loop().run_until_complete(coro)


# ---------------------------------------------------------------------------
# recommend_program
# ---------------------------------------------------------------------------
@tool
async def recommend_program(
    user_id: str,
    goal_hint: Optional[str] = None,
) -> Dict[str, Any]:
    """Recommend ONE published training program that matches the user.

    Scores PUBLISHED `programs` against the user's primary_goal + fitness_level
    (goal-keyword overlap, difficulty match, featured weight). Optionally biases
    toward a chat-supplied goal_hint (e.g. "build muscle", "lose fat", "5k").

    Args:
        user_id: The user to recommend for.
        goal_hint: Optional free-text goal from the conversation.

    Returns:
        {success, action='recommend_program', program: {id, name, tagline,
         who_for, difficulty_level, duration_weeks, sessions_per_week}, reason,
         message} — or {success:False, error} when nothing suitable is published.
    """
    logger.info(f"🏋️ [coach_tool.recommend_program] user={user_id} hint={goal_hint!r}")
    from core.supabase_client import get_supabase

    db = get_supabase()
    # Resolve user goal + level.
    primary_goal = None
    fitness_level = None
    try:
        ures = (
            db.client.table("users")
            .select("primary_goal, fitness_level")
            .eq("id", user_id).limit(1).execute()
        )
        if ures.data:
            primary_goal = ures.data[0].get("primary_goal")
            fitness_level = ures.data[0].get("fitness_level")
    except Exception as e:  # noqa: BLE001
        logger.warning(f"recommend_program: user lookup failed: {e}")

    try:
        resp = (
            db.client.table("programs")
            .select("id, program_name, editorial_name, tagline, who_for, "
                    "difficulty_level, duration_weeks, sessions_per_week, goals, "
                    "featured_rank")
            .eq("is_published", True)
            .eq("has_workouts", True)
            .execute()
        )
        programs = resp.data or []
    except Exception as e:  # noqa: BLE001
        logger.error(f"recommend_program: programs query failed: {e}", exc_info=True)
        return {"success": False, "action": "recommend_program",
                "error": "Could not load the program library right now."}

    if not programs:
        return {"success": False, "action": "recommend_program",
                "error": "No published programs are available yet."}

    # Lightweight scorer (mirrors program_templates.library_recommended).
    hint_lc = (goal_hint or "").strip().lower()
    goal_lc = (primary_goal or "").strip().lower()
    level_lc = (fitness_level or "").strip().lower()

    def _score(p: Dict[str, Any]) -> int:
        s = 0
        blob = " ".join(str(g).lower() for g in (p.get("goals") or []))
        blob += " " + (p.get("tagline") or "").lower()
        blob += " " + (p.get("who_for") or "").lower()
        if goal_lc and any(tok in blob for tok in goal_lc.split("_")):
            s += 30
        if hint_lc:
            for tok in hint_lc.split():
                if len(tok) > 3 and tok in blob:
                    s += 8
        if level_lc and level_lc in (p.get("difficulty_level") or "").lower():
            s += 25
        if p.get("featured_rank") is not None:
            s += 10
        return s

    programs.sort(key=_score, reverse=True)
    best = programs[0]
    name = best.get("editorial_name") or best.get("program_name") or "Program"
    reason_bits = []
    if goal_hint:
        reason_bits.append(f"matches your goal ({goal_hint})")
    elif primary_goal:
        reason_bits.append(f"fits your {primary_goal.replace('_', ' ')} goal")
    if fitness_level:
        reason_bits.append(f"is {best.get('difficulty_level') or 'a good'}-level")
    reason = " and ".join(reason_bits) or "is a strong, well-rounded program"

    return {
        "success": True,
        "action": "recommend_program",
        "program": {
            "id": str(best["id"]),
            "name": name,
            "tagline": best.get("tagline"),
            "who_for": best.get("who_for"),
            "difficulty_level": best.get("difficulty_level"),
            "duration_weeks": best.get("duration_weeks"),
            "sessions_per_week": best.get("sessions_per_week"),
        },
        "reason": reason,
        "message": (
            f"I'd recommend **{name}** — it {reason}. "
            f"Want me to start it for you?"
        ),
    }


# ---------------------------------------------------------------------------
# assign_program
# ---------------------------------------------------------------------------
@tool
async def assign_program(
    user_id: str,
    program_id: str,
    assigned_days: Optional[List[int]] = None,
    slot: str = "primary",
    duration_weeks: Optional[int] = None,
) -> Dict[str, Any]:
    """Start (assign) a published program for the user from chat.

    Uses the SAME logic as POST /api/v1/program-templates/assign: clones the
    program, customizes for the user's injuries/equipment/level, creates the
    assignment, expands the dated workouts, and clears the /today cache.

    Args:
        user_id: The user to start the program for.
        program_id: public.programs.id (e.g. from a prior recommend_program).
        assigned_days: Weekdays to train, Mon=0..Sun=6. Omit to start
            sequentially from today off the program's own training days.
        slot: 'primary' (replaces the current primary) or 'addon' (runs
            alongside, e.g. a cardio block).
        duration_weeks: Optional override of the program's default length.

    Returns:
        {success, action='assign_program', program_id, program_name,
         assignment_id, template_id, workouts_created, message}.
    """
    logger.info(
        f"🏋️ [coach_tool.assign_program] user={user_id} program={program_id} "
        f"days={assigned_days} slot={slot}"
    )
    from core.supabase_client import get_supabase
    from api.v1.program_templates import assign_program_core, CustomizeOptions

    db = get_supabase()
    try:
        result = await assign_program_core(
            db,
            user_id=user_id,
            program_id=program_id,
            assigned_days=assigned_days or [],
            slot=(slot or "primary"),
            start_date=None,
            replace=True,
            duration_weeks=duration_weeks,
            customize=CustomizeOptions(),  # default: level + injury + equipment
        )
        return {
            "success": True,
            "action": "assign_program",
            "program_id": result.get("program_id"),
            "program_name": result.get("program_name"),
            "assignment_id": result.get("assignment_id"),
            "template_id": result.get("template_id"),
            "workouts_created": result.get("workouts_created"),
            "message": (
                f"Started **{result.get('program_name')}** — I scheduled "
                f"{result.get('workouts_created')} workouts and fitted them to "
                f"your equipment and any injuries. Check your home screen."
            ),
        }
    except Exception as e:  # noqa: BLE001
        # assign_program_core raises HTTPException for 404/422 — surface a clean
        # chat error rather than a stack trace.
        detail = getattr(e, "detail", None)
        msg = detail if isinstance(detail, str) else "Couldn't start that program."
        logger.error(f"❌ [coach_tool.assign_program] failed: {e}", exc_info=True)
        return {"success": False, "action": "assign_program", "error": msg}


# ---------------------------------------------------------------------------
# generate_coach_program
# ---------------------------------------------------------------------------
@tool
async def generate_coach_program(
    user_id: str,
    request: str,
    weeks: int = 8,
    name: Optional[str] = None,
) -> Dict[str, Any]:
    """Build a CUSTOM multi-week training program from a chat description and
    save it as an editable template (does NOT auto-start it).

    Reuses the same generator + injury-safety as the "paste a program" path:
    the free-text `request` is parsed into structured days, exercises resolved
    against the library, and a terminal injury pass drops/replaces unsafe moves.
    The result is persisted as a user_program_template the user can review and
    then start (assign) with their chosen days.

    Args:
        user_id: Owner of the new template.
        request: What the user wants, e.g. "a 4-day upper/lower hypertrophy
            program with a deadlift focus" or a fully pasted routine.
        weeks: Intended duration in weeks (stored on the template; 1-12).
        name: Optional program name; defaults to the parsed/AI-suggested name.

    Returns:
        {success, action='create_program', template_id, program_name,
         day_count, weeks, message}.
    """
    logger.info(
        f"🤖 [coach_tool.generate_coach_program] user={user_id} weeks={weeks} "
        f"req={request[:80]!r}"
    )
    from core.supabase_client import get_supabase
    from services.program_template_parser import parse_to_template_json
    from services.program_customizer import resolve_user_context
    import uuid as _uuid
    from datetime import datetime as _dt

    if not (request or "").strip():
        return {"success": False, "action": "create_program",
                "error": "Tell me what kind of program you'd like."}

    weeks = max(1, min(int(weeks or 8), 12))

    try:
        uctx = resolve_user_context(user_id)
    except Exception:  # noqa: BLE001
        uctx = None

    try:
        parsed = await parse_to_template_json(
            request, user_id=user_id, weeks=weeks, user_context=uctx,
        )
    except ValueError as ve:
        m = str(ve)
        if m.startswith("not_a_program"):
            return {"success": False, "action": "create_program",
                    "error": "I couldn't turn that into a program — try "
                    "describing the days, exercises, and sets/reps you want."}
        return {"success": False, "action": "create_program",
                "error": "I had trouble building that program. Try rephrasing."}
    except Exception as e:  # noqa: BLE001
        logger.error(f"❌ generate_coach_program parse failed: {e}", exc_info=True)
        return {"success": False, "action": "create_program",
                "error": "Something went wrong building your program."}

    days = parsed.get("days") or []
    if not any(not d.get("is_rest") for d in days):
        return {"success": False, "action": "create_program",
                "error": "That program had no training days."}

    program_name = name or parsed.get("name") or "Coach Program"
    db = get_supabase()
    template_id = str(_uuid.uuid4())
    now = _dt.utcnow().isoformat()
    try:
        created = (
            db.client.table("user_program_templates")
            .insert({
                "id": template_id,
                "user_id": user_id,
                "name": program_name,
                "description": parsed.get("description") or "",
                "week_length": parsed.get("week_length") or 7,
                "days": days,
                "deload_every_n_weeks": parsed.get("deload_every_n_weeks"),
                "progression_strategy": parsed.get("progression_strategy") or "linear",
                "apply_staples": True,
                "source": "coach_generated",
                "category": parsed.get("category"),
                "duration_weeks": weeks,
                "created_at": now,
                "updated_at": now,
            })
            .execute()
        )
        if not created.data:
            raise RuntimeError("insert returned no row")
    except Exception as e:  # noqa: BLE001
        logger.error(f"❌ generate_coach_program persist failed: {e}", exc_info=True)
        return {"success": False, "action": "create_program",
                "error": "I built your program but couldn't save it. Try again."}

    training_days = sum(1 for d in days if not d.get("is_rest"))
    return {
        "success": True,
        "action": "create_program",
        "template_id": template_id,
        "program_name": program_name,
        "day_count": training_days,
        "weeks": weeks,
        "message": (
            f"Built **{program_name}** — {training_days} training days over "
            f"{weeks} weeks, fitted to your profile. Want me to schedule it? "
            f"Just tell me which days you train."
        ),
    }


PROGRAM_TOOLS = [recommend_program, assign_program, generate_coach_program]
