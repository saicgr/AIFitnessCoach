"""Recent form-analysis verdicts as prompt-injectable coach context (closed loop).

PURPOSE
-------
The user records exercise-form videos that are analyzed by
``FormAnalysisService`` and persisted to ``media_analysis_jobs`` (job_type=
``form_analysis``). On a READ, the coach is currently blind to those verdicts:
it can score a single uploaded clip yet can't *see* that the user's squat depth
regressed across their last three clips when programming tomorrow's session.

This module closes the loop. It assembles a compact, deterministic summary of
the user's RECENT form verdicts (form_score + the standout issue per clip, plus
a per-exercise trend when ≥2 clips exist for the same movement) so the coach can
SEE and CITE them ("your squat depth regressed — here's a cue") instead of
giving generic advice.

Mirrors ``services.coach.self_tracking_context`` deliberately: same hot-path
fail-soft contract, same "empty string == no data" signal, same off-event-loop
Supabase read via ``asyncio.to_thread`` (the Supabase client is synchronous).

CONTRACT
--------
``build_form_verdict_context(user_id) -> str``

- Returns a short multi-line string when there is form data, e.g.::

      RECENT FORM VERDICTS (video-analyzed, newest first):
      - Barbell Back Squat (today): 6/10 — depth shallow (moderate); cue: hit parallel
      - Bench Press (3d ago): 8/10 — solid; minor bar-path drift
      - Barbell Back Squat (8d ago): 8/10 — solid
      Trend: Barbell Back Squat depth/score regressed (8 -> 6 over 2 clips) — address before adding load.

- Returns "" (empty string) when there is NO completed form analysis. The empty
  string is the explicit no-data signal — the coach must NEVER invent a verdict,
  so "no data" is communicated by the ABSENCE of the block.

- NEVER raises. Any error (missing table, malformed result JSON, query failure)
  degrades to "" so it can never block or crash the coach turn. Fail open.

GROUNDING
---------
Table/columns/result-shape are taken verbatim from the write + read paths, NOT
guessed:
- ``media_analysis_jobs`` (user_id, job_type='form_analysis', status='completed',
  result JSONB, params JSONB, completed_at) — see
  ``api/v1/media_jobs.py::list_form_analyses`` (the reused query) and the
  ``FORM_ANALYSIS_SCHEMA`` in ``services/form_analysis_service.py`` for the
  ``result`` shape (form_score, subscores{form,tempo,range_of_motion},
  exercise_identified, issues[]{body_part,severity,description,correction},
  positives[]).
"""
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from core.logger import get_logger

logger = get_logger(__name__)

# Keep this a cheap hot-path call + a compact injected block.
_MAX_CLIPS = 4          # most-recent form clips to summarize
_FETCH_LIMIT = 8        # rows scanned (covers trend detection across exercises)
_LOOKBACK_DAYS = 45     # ignore stale verdicts — only recent form is actionable


def _parse_ts(value: Any) -> Optional[datetime]:
    if not value:
        return None
    try:
        s = str(value).replace("Z", "+00:00")
        dt = datetime.fromisoformat(s)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None


def _ago_label(dt: Optional[datetime], now: datetime) -> str:
    if dt is None:
        return "recently"
    days = (now.date() - dt.date()).days
    if days <= 0:
        return "today"
    if days == 1:
        return "yesterday"
    return f"{days}d ago"


def _exercise_name(result: Dict[str, Any], params: Dict[str, Any]) -> str:
    name = (
        result.get("exercise_identified")
        or params.get("exercise_name")
        or ""
    )
    name = str(name).strip()
    if not name or name.upper() == "N/A":
        return "Exercise"
    return name


def _top_issue(result: Dict[str, Any]) -> Optional[str]:
    """The single most-severe issue, rendered as 'description (severity)'."""
    issues = result.get("issues")
    if not isinstance(issues, list) or not issues:
        return None
    order = {"critical": 0, "moderate": 1, "minor": 2}
    ranked = sorted(
        (i for i in issues if isinstance(i, dict)),
        key=lambda i: order.get(str(i.get("severity", "")).lower(), 3),
    )
    if not ranked:
        return None
    top = ranked[0]
    desc = str(top.get("description") or "").strip()
    if not desc:
        return None
    sev = str(top.get("severity") or "").strip().lower()
    # Compact the description to a short clause.
    if len(desc) > 70:
        desc = desc[:67].rstrip() + "..."
    return f"{desc} ({sev})" if sev else desc


def _correction(result: Dict[str, Any]) -> Optional[str]:
    issues = result.get("issues")
    if isinstance(issues, list):
        for i in issues:
            if isinstance(i, dict):
                c = str(i.get("correction") or "").strip()
                if c:
                    if len(c) > 60:
                        c = c[:57].rstrip() + "..."
                    return c
    return None


def _line_for(result: Dict[str, Any], params: Dict[str, Any], ago: str) -> Optional[str]:
    """Render one clip as a deterministic verdict line."""
    if not isinstance(result, dict):
        return None
    if str(result.get("content_type") or "exercise").lower() == "not_exercise":
        return None
    score = result.get("form_score")
    try:
        score = int(score)
    except (TypeError, ValueError):
        score = None

    name = _exercise_name(result, params)
    issue = _top_issue(result)
    correction = _correction(result)

    score_part = f"{score}/10" if score is not None else "n/a"
    if issue:
        tail = f"{issue}"
        if correction:
            tail += f"; cue: {correction}"
    elif score is not None and score >= 8:
        tail = "solid"
    else:
        tail = "see notes"
    return f"- {name} ({ago}): {score_part} — {tail}"


def _trend_lines(rows: List[Dict[str, Any]]) -> List[str]:
    """Per-exercise score trend when ≥2 verdicts exist for the same movement.

    Compares the newest two clips of each exercise. Surfaces a regression or an
    improvement deterministically (newest score vs the prior one), so the coach
    can act on direction, not just a snapshot.
    """
    by_ex: Dict[str, List[int]] = {}
    for r in rows:
        result = r.get("result") or {}
        if not isinstance(result, dict):
            continue
        score = result.get("form_score")
        try:
            score = int(score)
        except (TypeError, ValueError):
            continue
        name = _exercise_name(result, r.get("params") or {})
        by_ex.setdefault(name.lower() + "|" + name, []).append(score)

    out: List[str] = []
    for key, scores in by_ex.items():
        if len(scores) < 2:
            continue
        name = key.split("|", 1)[1]
        newest, prior = scores[0], scores[1]
        if newest < prior:
            out.append(
                f"Trend: {name} score regressed ({prior} -> {newest} over "
                f"{len(scores)} clips) — address technique before adding load."
            )
        elif newest > prior:
            out.append(
                f"Trend: {name} score improved ({prior} -> {newest}) — "
                f"technique is heading the right way."
            )
    return out[:2]  # at most 2 trend callouts to keep the block compact


def _fetch_rows(user_id: str) -> List[Dict[str, Any]]:
    """Synchronous Supabase read — mirrors api/v1/media_jobs.list_form_analyses."""
    from core.db import get_supabase_db

    db = get_supabase_db()
    rows = (
        db.client.table("media_analysis_jobs")
        .select("id, result, params, created_at, completed_at")
        .eq("user_id", user_id)
        .eq("job_type", "form_analysis")
        .eq("status", "completed")
        .order("completed_at", desc=True)
        .limit(_FETCH_LIMIT)
        .execute()
    ).data or []
    return rows


def build_form_verdict_context_sync(user_id: str) -> str:
    """Synchronous core. Call ``build_form_verdict_context`` from async code."""
    if not user_id:
        return ""
    try:
        rows = _fetch_rows(user_id)
    except Exception as e:  # never break the coach turn
        logger.debug(f"[form_verdict] fetch failed for {user_id}: {e}")
        return ""

    if not rows:
        return ""

    now = datetime.now(timezone.utc)
    cutoff_days = _LOOKBACK_DAYS

    # Keep only recent, exercise-typed rows (preserve newest-first order).
    fresh: List[Dict[str, Any]] = []
    for r in rows:
        ts = _parse_ts(r.get("completed_at") or r.get("created_at"))
        if ts is not None and (now.date() - ts.date()).days > cutoff_days:
            continue
        result = r.get("result") or {}
        if isinstance(result, dict) and str(
            result.get("content_type") or "exercise"
        ).lower() == "not_exercise":
            continue
        fresh.append(r)

    if not fresh:
        return ""

    lines: List[str] = []
    for r in fresh[:_MAX_CLIPS]:
        ago = _ago_label(_parse_ts(r.get("completed_at") or r.get("created_at")), now)
        line = _line_for(r.get("result") or {}, r.get("params") or {}, ago)
        if line:
            lines.append(line)

    if not lines:
        return ""

    block = ["RECENT FORM VERDICTS (video-analyzed, newest first):"]
    block.extend(lines)
    block.extend(_trend_lines(fresh))
    return "\n".join(block)


async def build_form_verdict_context(user_id: str) -> str:
    """Async wrapper: runs the synchronous Supabase read off the event loop.

    Returns "" on ANY failure (fail open). Mirrors
    ``build_self_tracking_context`` so it can sit in the same coach-state
    ``asyncio.gather``.
    """
    import asyncio

    try:
        return await asyncio.to_thread(build_form_verdict_context_sync, user_id)
    except Exception as e:
        logger.debug(f"[form_verdict] async build failed for {user_id}: {e}")
        return ""
