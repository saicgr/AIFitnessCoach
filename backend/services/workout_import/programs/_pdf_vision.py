"""
PDF-to-CanonicalProgramTemplate extraction via Gemini Vision.

Used by creator adapters that deliver their programs as PDFs with image-based
tables (BUFF Dudes 96-page book, Athlean-X Max Size / Max OT, Built With
Science Intermediate, Uplifted). pypdf is tried first — if any pages contain
extractable text we return it and the adapter can parse line-by-line. If
pypdf returns nothing useful (image-only PDF), we dispatch raw bytes to
Gemini with a structured response schema matching CanonicalProgramTemplate.

Why not always Gemini? Vision calls cost ~100× more than local pypdf and add
2-8s of latency. Text extraction works for ~40% of the creator PDFs we've
seen in the wild.

Safety: Gemini's safety filters can block fitness content. We set
safety_settings to BLOCK_NONE for HARM_CATEGORY_DANGEROUS_CONTENT via the
existing gemini_generate_with_retry wrapper (the wrapper already handles
that for workout-generation calls — we reuse the same helper here).
"""
from __future__ import annotations

import io
import json
from typing import Any, List, Optional
from uuid import UUID

from core.logger import get_logger

from ..canonical import (
    CanonicalProgramTemplate,
    PrescribedDay,
    PrescribedExercise,
    PrescribedSet,
    PrescribedWeek,
    RepTarget,
    SetType,
    WeightUnit,
)
from . import _shared as S

logger = get_logger(__name__)


async def extract_program_from_pdf(
    *,
    data: bytes,
    user_id: UUID,
    unit: WeightUnit,
    source_app: str,
    program_name: str,
    program_creator: str,
    default_rounding_kg: float = 2.5,
    training_max_factor: float = 1.0,
    extraction_hint: str = "",
) -> Optional[CanonicalProgramTemplate]:
    """Try pypdf first, fall back to Gemini Vision. Returns None if both fail.

    Callers wrap the returned template in a ParseResult(mode=TEMPLATE).
    """
    # Quick page-count guard — most creator PDFs are <100 pages. We cap at
    # 200 pages hard so a scanned book doesn't blow through our Gemini quota.
    try:
        import pypdf
        reader = pypdf.PdfReader(io.BytesIO(data))
        page_count = len(reader.pages)
    except Exception as e:
        logger.warning(f"[{source_app}] pypdf open failed: {e}")
        page_count = 0
        reader = None

    if page_count > 200:
        logger.warning(
            f"[{source_app}] PDF has {page_count} pages — exceeds 200-page cap; truncating"
        )

    # 1. Try pypdf text extraction (fast, free).
    extracted_text = ""
    if reader is not None:
        try:
            # Cap at 200 pages to keep the prompt under Gemini's input limits.
            for i in range(min(page_count, 200)):
                extracted_text += reader.pages[i].extract_text() or ""
                extracted_text += "\n\n"
        except Exception as e:
            logger.warning(f"[{source_app}] pypdf text extract failed: {e}")

    has_usable_text = len(extracted_text.strip()) > 400  # heuristic — < 400 chars means image-only

    # 2. Dispatch to Gemini Vision (works on both text + image PDFs).
    try:
        response_json = await _call_gemini(
            data=data if not has_usable_text else None,
            text=extracted_text if has_usable_text else None,
            source_app=source_app,
            program_name=program_name,
            extraction_hint=extraction_hint,
        )
    except Exception as e:
        logger.error(f"❌ [{source_app}] Gemini extraction failed: {e}", exc_info=True)
        return None

    if not response_json:
        return None

    return _build_template_from_json(
        response_json=response_json,
        user_id=user_id,
        unit=unit,
        source_app=source_app,
        program_name=program_name,
        program_creator=program_creator,
        default_rounding_kg=default_rounding_kg,
        training_max_factor=training_max_factor,
    )


async def _call_gemini(
    *,
    data: Optional[bytes],
    text: Optional[str],
    source_app: str,
    program_name: str,
    extraction_hint: str,
) -> Optional[dict]:
    """Invoke Gemini with either the raw PDF bytes OR already-extracted text.
    Returns the parsed JSON dict or None on any error.
    """
    try:
        from google.genai import types  # type: ignore
    except ImportError:
        logger.error("google.genai not installed — cannot extract program from PDF")
        return None

    try:
        from services.gemini.service import gemini_generate_with_retry  # type: ignore
    except Exception:
        # Some builds expose the helper at a different path; fall through.
        try:
            from services.gemini import get_gemini_service  # type: ignore
            svc = get_gemini_service()
            gemini_generate_with_retry = svc.generate_with_retry  # type: ignore
        except Exception as e:
            logger.error(f"[{source_app}] cannot locate gemini helper: {e}")
            return None

    system_instruction = (
        "You are a fitness program extraction tool. Read the provided PDF "
        "or text and return a JSON object describing the training program in "
        "this exact schema:\n\n"
        "{\n"
        '  "weeks": [\n'
        '    {\n'
        '      "week_number": 1,\n'
        '      "label": null,\n'
        '      "days": [\n'
        '        {\n'
        '          "day_number": 1,\n'
        '          "day_label": "Push A",\n'
        '          "exercises": [\n'
        '            {\n'
        '              "name": "Barbell Bench Press",\n'
        '              "sets": 3,\n'
        '              "reps_min": 8,\n'
        '              "reps_max": 10,\n'
        '              "amrap_last": false,\n'
        '              "percent_1rm_min": null,\n'
        '              "percent_1rm_max": null,\n'
        '              "rpe": 8,\n'
        '              "notes": null\n'
        '            }\n'
        '          ]\n'
        '        }\n'
        '      ]\n'
        '    }\n'
        '  ]\n'
        "}\n\n"
        "Rules:\n"
        "- percent_1rm_min/max in [0,1] (0.75 not 75).\n"
        "- If the program uses absolute weight instead of %1RM, omit both.\n"
        "- amrap_last=true if the last set is AMRAP / 'to failure' / '+'.\n"
        "- RPE: if the table says 'RIR 2', convert to RPE = 10 - RIR = 8.\n"
        "- Skip instruction pages, table-of-contents, nutrition chapters.\n"
        "- Warmup sets don't need to appear unless they're explicitly prescribed.\n"
        f"- Extraction hint: {extraction_hint}"
    )

    parts: List[Any] = []
    if data is not None:
        parts.append(types.Part.from_bytes(data=data, mime_type="application/pdf"))
    if text is not None:
        parts.append(types.Part.from_text(text=text[:250_000]))  # cap input size

    from core.config import settings  # type: ignore
    model_name = getattr(settings, "GEMINI_MODEL", None) or "gemini-2.0-flash-exp"

    try:
        response = await gemini_generate_with_retry(
            model=model_name,
            contents=[system_instruction, *parts],
            config=types.GenerateContentConfig(
                temperature=0.1,
                response_mime_type="application/json",
                max_output_tokens=16_000,
            ),
            method_name=f"workout_import_{source_app}",
        )
    except Exception as e:
        logger.error(f"[{source_app}] Gemini call failed: {e}")
        return None

    text_out = (response.text or "").strip() if response else ""
    if not text_out:
        return None
    if text_out.startswith("```"):
        import re as _re
        text_out = _re.sub(r"^```(?:json)?\s*", "", text_out)
        text_out = _re.sub(r"\s*```$", "", text_out)
    try:
        return json.loads(text_out)
    except json.JSONDecodeError as e:
        logger.error(f"[{source_app}] Gemini returned invalid JSON: {e}")
        return None


def _build_template_from_json(
    *,
    response_json: dict,
    user_id: UUID,
    unit: WeightUnit,
    source_app: str,
    program_name: str,
    program_creator: str,
    default_rounding_kg: float,
    training_max_factor: float,
) -> Optional[CanonicalProgramTemplate]:
    raw_weeks = response_json.get("weeks") or []
    if not raw_weeks:
        return None

    weeks: list[PrescribedWeek] = []
    for wk in raw_weeks:
        days: list[PrescribedDay] = []
        for d in wk.get("days") or []:
            exercises: list[PrescribedExercise] = []
            for ei, e in enumerate(d.get("exercises") or []):
                name = str(e.get("name") or "").strip()
                if not name:
                    continue
                sets_count = int(e.get("sets") or 3)
                rmin = int(e.get("reps_min") or 8)
                rmax = int(e.get("reps_max") or rmin)
                amrap = bool(e.get("amrap_last"))
                pmin = e.get("percent_1rm_min")
                pmax = e.get("percent_1rm_max")
                rpe = e.get("rpe")
                notes = e.get("notes")

                if pmin is not None and pmax is not None:
                    load_presc = S.simple_percent_prescription(
                        float(pmin), float(pmax),
                    )
                elif rpe is not None:
                    load_presc = S.rpe_prescription(float(rpe))
                else:
                    load_presc = S.unspecified_prescription()

                prescribed = [
                    PrescribedSet(
                        order=i,
                        set_type=SetType.AMRAP if (amrap and i == sets_count - 1)
                                   else SetType.WORKING,
                        rep_target=RepTarget(
                            min=rmin,
                            max=rmax if not (amrap and i == sets_count - 1) else 99,
                            amrap_last=(amrap and i == sets_count - 1),
                        ),
                        load_prescription=load_presc,
                        notes=notes if isinstance(notes, str) else None,
                    )
                    for i in range(sets_count)
                ]
                exercises.append(PrescribedExercise(
                    order=ei,
                    exercise_name_raw=name,
                    sets=prescribed,
                ))
            if exercises:
                days.append(PrescribedDay(
                    day_number=int(d.get("day_number") or len(days) + 1),
                    day_label=d.get("day_label"),
                    exercises=exercises,
                ))
        if days:
            weeks.append(PrescribedWeek(
                week_number=int(wk.get("week_number") or len(weeks) + 1),
                label=wk.get("label"),
                days=days,
            ))

    if not weeks:
        return None

    days_per_week = max(len(w.days) for w in weeks)

    return S.build_template(
        user_id=user_id,
        source_app=source_app,
        program_name=program_name,
        program_creator=program_creator,
        total_weeks=len(weeks),
        days_per_week=days_per_week,
        unit_hint=unit,
        weeks=weeks,
        rounding_multiple_kg=default_rounding_kg,
        training_max_factor=training_max_factor,
        notes="Extracted via Gemini Vision from PDF source.",
    )
