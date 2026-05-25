#!/usr/bin/env python3
"""
i18n_translate_backend_notifications.py

Translates the _EN_TEMPLATES dict from backend/core/i18n.py into all 35
non-en locales via gemini-3.1-flash-lite, then writes the result as a Python
literal to backend/core/i18n_translations.py.

Strategy:
  - Send all ~30 templates per locale in one Gemini call (well under token limits).
  - Parallelize across locales with 8 workers.
  - Preserve {var} placeholders verbatim.
  - Preserve brand names: Zealova, Strava, Fitbod, MyFitnessPal.
  - Preserve fitness acronyms: RPE, 1RM, AMRAP, EMOM, BMR, TDEE, HRV.
  - Resume-safe: re-running overwrites i18n_translations.py cleanly.

Output shape:
  NON_EN_TEMPLATES: dict[str, dict[str, str]] = {
      'ar': {'morning_recovery_nudge_title': '...', ...},
      ...
  }
"""
from __future__ import annotations

import json
import os
import random
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

LOCALES: list[str] = [
    "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi", "id",
    "it", "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne", "nl",
    "or", "pa", "pl", "pt", "ru", "sv", "sw", "ta", "te", "th",
    "tl", "tr", "ur", "vi", "zh",
]

LOCALE_NATIVE: dict[str, str] = {
    "ar": "Arabic (العربية)",
    "bn": "Bengali (বাংলা)",
    "cs": "Czech (čeština)",
    "de": "German (Deutsch)",
    "es": "Spanish (español)",
    "fi": "Finnish (suomi)",
    "fr": "French (français)",
    "ha": "Hausa",
    "hi": "Hindi (हिन्दी)",
    "id": "Indonesian (Bahasa Indonesia)",
    "it": "Italian (italiano)",
    "ja": "Japanese (日本語)",
    "jv": "Javanese (Basa Jawa)",
    "kn": "Kannada (ಕನ್ನಡ)",
    "ko": "Korean (한국어)",
    "ml": "Malayalam (മലയാളം)",
    "mr": "Marathi (मराठी)",
    "ms": "Malay (Bahasa Melayu)",
    "ne": "Nepali (नेपाली)",
    "nl": "Dutch (Nederlands)",
    "or": "Odia (ଓଡ଼ିଆ)",
    "pa": "Punjabi (ਪੰਜਾਬੀ)",
    "pl": "Polish (polski)",
    "pt": "Portuguese (português)",
    "ru": "Russian (русский)",
    "sv": "Swedish (svenska)",
    "sw": "Swahili (Kiswahili)",
    "ta": "Tamil (தமிழ்)",
    "te": "Telugu (తెలుగు)",
    "th": "Thai (ไทย)",
    "tl": "Tagalog (Filipino)",
    "tr": "Turkish (Türkçe)",
    "ur": "Urdu (اردو)",
    "vi": "Vietnamese (Tiếng Việt)",
    "zh": "Simplified Chinese (简体中文)",
}

PRESERVE_VERBATIM = [
    "Zealova", "Strava", "Fitbod", "MyFitnessPal",
    "RPE", "1RM", "AMRAP", "EMOM", "BMR", "TDEE", "HRV", "NEAT",
]

MODEL = "gemini-3.1-flash-lite"
MAX_PARALLEL_LOCALES = 8


# ── helpers ────────────────────────────────────────────────────────────────────

def load_env() -> None:
    env_path = REPO / "backend" / ".env"
    for line in env_path.read_text().splitlines():
        if not line.strip() or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        v = v.strip().strip('"').strip("'")
        os.environ.setdefault(k.strip(), v)


def load_en_templates() -> dict[str, str]:
    """Import _EN_TEMPLATES from backend/core/i18n.py without side-effects."""
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "i18n_src",
        REPO / "backend" / "core" / "i18n.py",
    )
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return dict(mod._EN_TEMPLATES)


def translate_locale(client, locale: str, en_templates: dict[str, str]) -> dict[str, str]:
    """Translate all EN templates into `locale` in a single Gemini call."""
    from google import genai
    from google.genai import types

    native = LOCALE_NATIVE.get(locale, locale)
    preserve_list = ", ".join(PRESERVE_VERBATIM)

    system = (
        f"You translate push-notification and email strings for a fitness app called Zealova "
        f"from English to {native}.\n\n"
        "Rules:\n"
        "1. Output ONLY valid JSON: {\"<key>\": \"<translated value>\", ...}. "
        "No prose, no markdown fences.\n"
        "2. Preserve EVERY Python str.format() placeholder verbatim — e.g. {name}, "
        "{hrv_score}, {streak_count}, {xp_gap}, etc. Do NOT translate or alter them.\n"
        f"3. Preserve these brand/acronym terms verbatim in Latin script: {preserve_list}.\n"
        "4. Match the tone: friendly, motivational, second-person where natural.\n"
        "5. Preserve sentence structure and {var} placement exactly as in the English source."
    )

    user_payload = json.dumps(en_templates, ensure_ascii=False, indent=2)
    prompt = (
        f"Translate the following English notification strings to {native}. "
        "Return a JSON object with the same keys and translated values.\n\n"
        + user_payload
    )

    for attempt in range(3):
        try:
            response = client.models.generate_content(
                model=MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system,
                    response_mime_type="application/json",
                    temperature=0.2,
                    max_output_tokens=16000,
                ),
            )
            text = response.text.strip()
            # Strip markdown fences if model returned them despite mime type
            text = re.sub(r"^```(?:json)?\n?", "", text)
            text = re.sub(r"\n?```$", "", text)
            result = json.loads(text)
            if not isinstance(result, dict):
                raise ValueError(f"Expected JSON object, got {type(result).__name__}")
            return result
        except Exception as e:
            wait = 2 ** attempt
            print(
                f"  [{locale}] attempt {attempt+1} error: {type(e).__name__}: "
                f"{str(e)[:120]} — retrying in {wait}s",
                file=sys.stderr,
                flush=True,
            )
            time.sleep(wait)

    print(f"  [{locale}] all retries exhausted, returning empty dict", file=sys.stderr, flush=True)
    return {}


def dict_to_python_literal(data: dict[str, dict[str, str]]) -> str:
    """Serialize the translations dict as a readable Python literal."""
    lines = [
        "# AUTO-GENERATED by scripts/i18n_translate_backend_notifications.py",
        "# DO NOT EDIT BY HAND — re-run the script to refresh translations.",
        "# Preserve all {var} placeholders verbatim.",
        "",
        'NON_EN_TEMPLATES: dict[str, dict[str, str]] = {',
    ]
    for locale in LOCALES:
        tmpl = data.get(locale, {})
        lines.append(f"    {locale!r}: {{")
        for key, value in tmpl.items():
            # Escape backslashes and single quotes; use repr for the value.
            lines.append(f"        {key!r}: {value!r},")
        lines.append("    },")
    lines.append("}")
    lines.append("")  # trailing newline
    return "\n".join(lines)


# ── main ───────────────────────────────────────────────────────────────────────

def main() -> int:
    load_env()
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("❌ GEMINI_API_KEY not set in backend/.env", file=sys.stderr)
        return 1

    from google import genai

    client = genai.Client(api_key=api_key)

    print(f"Loading _EN_TEMPLATES from backend/core/i18n.py …", flush=True)
    en_templates = load_en_templates()
    n_templates = len(en_templates)
    print(f"  {n_templates} template keys found.", flush=True)

    print(
        f"\nTranslating {n_templates} templates × {len(LOCALES)} locales "
        f"via {MODEL} ({MAX_PARALLEL_LOCALES} workers in parallel) …\n",
        flush=True,
    )

    results: dict[str, dict[str, str]] = {}
    t_start = time.time()

    with ThreadPoolExecutor(max_workers=MAX_PARALLEL_LOCALES) as pool:
        future_to_locale = {
            pool.submit(translate_locale, client, loc, en_templates): loc
            for loc in LOCALES
        }
        done = 0
        for fut in as_completed(future_to_locale):
            loc = future_to_locale[fut]
            try:
                translated = fut.result()
                results[loc] = translated
                done += 1
                print(
                    f"  [{loc}] ✓ {len(translated)}/{n_templates} keys translated "
                    f"({done}/{len(LOCALES)} locales done)",
                    flush=True,
                )
            except Exception as e:
                print(f"  [{loc}] ❌ {e}", file=sys.stderr, flush=True)
                results[loc] = {}
                done += 1

    elapsed = time.time() - t_start
    total_translated = sum(len(v) for v in results.values())
    print(
        f"\nTranslated {n_templates} templates × {len(LOCALES)} locales "
        f"= {total_translated} total strings in {elapsed:.0f}s",
        flush=True,
    )

    # ── spot-check 3 random translations ──────────────────────────────────────
    print("\n── Spot checks ──────────────────────────────────────────────────────")
    sample_locales = random.sample(LOCALES, min(3, len(LOCALES)))
    sample_keys = random.sample(list(en_templates.keys()), min(3, n_templates))
    for loc, key in zip(sample_locales, sample_keys):
        en_val = en_templates[key]
        tr_val = results.get(loc, {}).get(key, "<MISSING>")
        print(f"  [{loc}] {key!r}")
        print(f"    EN: {en_val}")
        print(f"    {loc.upper()}: {tr_val}")
    print("─────────────────────────────────────────────────────────────────────\n")

    # ── write output file ──────────────────────────────────────────────────────
    out_path = REPO / "backend" / "core" / "i18n_translations.py"
    py_literal = dict_to_python_literal(results)
    out_path.write_text(py_literal, encoding="utf-8")
    print(f"Wrote: {out_path}", flush=True)

    print("\nFiles created/modified:")
    print(f"  CREATED/OVERWRITTEN: {out_path}")
    print(f"  (i18n.py will be updated separately by the orchestrator)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
