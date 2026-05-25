#!/usr/bin/env python3
"""Retry Hausa and Korean translations that failed the first run."""
from __future__ import annotations
import importlib.util, json, os, re, time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

RETRY_LOCALES = {
    "ha": "Hausa",
    "ko": "Korean (한국어)",
}
PRESERVE_VERBATIM = [
    "Zealova", "Strava", "Fitbod", "MyFitnessPal",
    "RPE", "1RM", "AMRAP", "EMOM", "BMR", "TDEE", "HRV", "NEAT",
]
MODEL = "gemini-3.1-flash-lite"


def load_env() -> None:
    for line in (REPO / "backend" / ".env").read_text().splitlines():
        if not line.strip() or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def load_en_templates() -> dict[str, str]:
    spec = importlib.util.spec_from_file_location(
        "i18n_src", REPO / "backend" / "core" / "i18n.py"
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return dict(mod._EN_TEMPLATES)


def translate(client, locale: str, native: str, en_templates: dict) -> dict:
    from google.genai import types

    preserve_list = ", ".join(PRESERVE_VERBATIM)
    system = (
        f"You translate push-notification and email strings for a fitness app called Zealova "
        f"from English to {native}.\n\n"
        "Rules:\n"
        "1. Output ONLY valid JSON: {\"<key>\": \"<translated value>\", ...}. "
        "No prose, no markdown fences, no trailing commas.\n"
        "2. Preserve EVERY Python str.format() placeholder verbatim — e.g. {name}, "
        "{hrv_score}, {streak_count}, {xp_gap}, etc.\n"
        f"3. Preserve these brand/acronym terms verbatim: {preserve_list}.\n"
        "4. Match the tone: friendly, motivational, second-person.\n"
        "5. Return EXACTLY one JSON object — nothing before or after it."
    )
    user_payload = json.dumps(en_templates, ensure_ascii=False, indent=2)
    prompt = (
        f"Translate to {native}. Return a single valid JSON object with the same keys.\n\n"
        + user_payload
    )

    for attempt in range(5):
        try:
            response = client.models.generate_content(
                model=MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system,
                    response_mime_type="application/json",
                    temperature=0.1,
                    max_output_tokens=16000,
                ),
            )
            text = (response.text or "").strip()
            text = re.sub(r"^```(?:json)?\n?", "", text)
            text = re.sub(r"\n?```$", "", text)
            result = json.loads(text)
            if not isinstance(result, dict):
                raise ValueError(f"Expected dict, got {type(result)}")
            print(f"  [{locale}] OK — {len(result)} keys")
            return result
        except Exception as exc:
            wait = 2 ** (attempt + 1)
            print(f"  [{locale}] attempt {attempt+1} error: {exc} — retrying in {wait}s")
            time.sleep(wait)

    print(f"  [{locale}] all retries exhausted")
    return {}


def patch_translations_file(results: dict[str, dict]) -> None:
    trans_path = REPO / "backend" / "core" / "i18n_translations.py"
    text = trans_path.read_text(encoding="utf-8")

    for locale, translations in results.items():
        if not translations:
            print(f"  [{locale}] skipping patch (empty)")
            continue

        # Build the new block
        block_lines = [f"    {locale!r}: {{"]
        for k, v in translations.items():
            block_lines.append(f"        {k!r}: {v!r},")
        block_lines.append("    },")
        new_block = "\n".join(block_lines)

        # Replace the existing locale block (which may contain 0 entries or garbage)
        pattern = re.compile(
            r"    '" + re.escape(locale) + r"'\s*:\s*\{[^}]*\},",
            re.DOTALL,
        )
        if pattern.search(text):
            text = pattern.sub(new_block, text, count=1)
            print(f"  [{locale}] patched in i18n_translations.py")
        else:
            print(f"  [{locale}] WARNING: existing block not found — skipping")

    trans_path.write_text(text, encoding="utf-8")
    print(f"Saved: {trans_path}")


def main() -> None:
    load_env()
    from google import genai
    client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

    en_templates = load_en_templates()
    print(f"Retrying {list(RETRY_LOCALES.keys())} ({len(en_templates)} keys each)")

    results = {}
    for locale, native in RETRY_LOCALES.items():
        results[locale] = translate(client, locale, native, en_templates)

    patch_translations_file(results)


if __name__ == "__main__":
    main()
