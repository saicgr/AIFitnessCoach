#!/usr/bin/env python3
"""
i18n_translate_gemini.py — translate non-en ARB cells using gemini-3.1-flash-lite
with batched JSON-mode requests. Operates in place on app_<locale>.arb files.

Strategy:
  - Per locale, find all keys where value == English (untranslated bleed)
  - Skip pure-numeric / acronym / measurement strings
  - Batch ~80 strings per Gemini request; ask for a JSON object back
  - Parse + apply to .arb
  - Preserve ICU placeholders {name} verbatim
  - Preserve brand names + acronyms verbatim
  - Resume-safe: re-running only translates remaining English bleed
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
L10N = REPO / "mobile" / "flutter" / "lib" / "l10n"

LOCALES = [
    "ar","bn","cs","de","es","fi","fr","ha","hi","id",
    "it","ja","jv","kn","ko","ml","mr","ms","ne","nl",
    "or","pa","pl","pt","ru","sv","sw","ta","te","th",
    "tl","tr","ur","vi","zh",
]

LOCALE_NATIVE = {
    "ar":"Arabic (العربية)","bn":"Bengali (বাংলা)","cs":"Czech (čeština)","de":"German (Deutsch)",
    "es":"Spanish (español)","fi":"Finnish (suomi)","fr":"French (français)","ha":"Hausa",
    "hi":"Hindi (हिन्दी)","id":"Indonesian (Bahasa Indonesia)","it":"Italian (italiano)",
    "ja":"Japanese (日本語)","jv":"Javanese (Basa Jawa)","kn":"Kannada (ಕನ್ನಡ)",
    "ko":"Korean (한국어)","ml":"Malayalam (മലയാളം)","mr":"Marathi (मराठी)",
    "ms":"Malay (Bahasa Melayu)","ne":"Nepali (नेपाली)","nl":"Dutch (Nederlands)",
    "or":"Odia (ଓଡ଼ିଆ)","pa":"Punjabi (ਪੰਜਾਬੀ)","pl":"Polish (polski)","pt":"Portuguese (português)",
    "ru":"Russian (русский)","sv":"Swedish (svenska)","sw":"Swahili (Kiswahili)",
    "ta":"Tamil (தமிழ்)","te":"Telugu (తెలుగు)","th":"Thai (ไทย)","tl":"Tagalog (Filipino)",
    "tr":"Turkish (Türkçe)","ur":"Urdu (اردو)","vi":"Vietnamese (Tiếng Việt)",
    "zh":"Simplified Chinese (简体中文)",
}

PRESERVE_VERBATIM = [
    "Zealova","Strava","Fitbod","MyFitnessPal","Apple","Google","Hyrox",
    "RevenueCat","MacroFactor","Hevy","Jefit","Peloton","Garmin","FitNotes",
    "StrongLifts","RPE","1RM","AMRAP","EMOM","BMR","TDEE","HRV","NEAT","ATG",
    "RIR","TUT",
]

_SKIP_RE = re.compile(
    r"^("
    r"\s*"
    r"|[\d\s\-_:,./]*"
    r"|[A-Z]{2,5}"
    r"|-?\d+(\.\d+)?[a-z%]{0,3}"
    r")$"
)

BATCH_SIZE = 80   # ~80 strings per Gemini call — well within token limits
MAX_PARALLEL_BATCHES = 8


def should_skip(s: str) -> bool:
    if not isinstance(s, str): return True
    if len(s.strip()) < 2: return True
    if _SKIP_RE.match(s): return True
    if not re.search(r"[a-zA-Z]", s): return True
    return False


def load_env():
    env_path = REPO / "backend" / ".env"
    for line in env_path.read_text().splitlines():
        if not line.strip() or line.startswith("#") or "=" not in line: continue
        k, _, v = line.partition("=")
        v = v.strip().strip('"').strip("'")
        os.environ.setdefault(k.strip(), v)


def translate_batch(client, model: str, locale: str, items: dict[str, str]) -> dict[str, str]:
    """Send a batch of (key → English) to Gemini, return (key → translation).
    items keys are kept opaque to Gemini; we ask it to return a JSON dict.
    """
    native = LOCALE_NATIVE.get(locale, locale)
    preserve_list = ", ".join(PRESERVE_VERBATIM)

    system = f"""You translate UI strings for a fitness app called Zealova from English to {native}.

Rules:
1. Output ONLY valid JSON: {{"<key>": "<translated value>", ...}}. No prose, no markdown fences.
2. Preserve every ICU placeholder verbatim: {{name}}, {{count}}, {{xp}}, etc.
3. Preserve these brand/acronym terms verbatim in Latin script even in non-Latin languages: {preserve_list}.
4. Match the user-facing tone: friendly, concise, second-person where natural.
5. For very short labels (single word), use the standard {native} equivalent — do NOT add extra punctuation.
6. If a key has multiple sentences, preserve sentence boundaries (.) in the target script."""

    user_payload = json.dumps(items, ensure_ascii=False, indent=2)
    prompt = f"Translate these English UI strings to {native}. Return JSON only.\n\n{user_payload}"

    from google import genai
    from google.genai import types

    try:
        response = client.models.generate_content(
            model=model,
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=system,
                response_mime_type="application/json",
                temperature=0.2,
                max_output_tokens=8000,
            ),
        )
        text = response.text.strip()
        # Strip markdown fences if model returned them
        text = re.sub(r"^```(?:json)?\n?", "", text)
        text = re.sub(r"\n?```$", "", text)
        result = json.loads(text)
        if not isinstance(result, dict):
            return {}
        return result
    except Exception as e:
        print(f"  [{locale}] batch error: {type(e).__name__}: {str(e)[:120]}",
              file=sys.stderr, flush=True)
        return {}


def chunks(d: dict, size: int):
    items = list(d.items())
    for i in range(0, len(items), size):
        yield dict(items[i:i+size])


def process_locale(client, model: str, locale: str, en_data: dict) -> dict:
    arb = L10N / f"app_{locale}.arb"
    data = json.load(open(arb))

    todo: dict[str, str] = {}
    for k, en_v in en_data.items():
        if k.startswith("@") or not isinstance(en_v, str): continue
        cur = data.get(k)
        if cur != en_v: continue
        if should_skip(en_v): continue
        todo[k] = en_v

    if not todo:
        return {"locale": locale, "todo": 0, "changed": 0, "skipped": True}

    t0 = time.time()
    print(f"[{locale}] {len(todo)} keys → batching {BATCH_SIZE}/call "
          f"({len(todo)//BATCH_SIZE + 1} batches)", flush=True)

    # Process batches in parallel within the locale
    all_results: dict[str, str] = {}
    batch_list = list(chunks(todo, BATCH_SIZE))
    with ThreadPoolExecutor(max_workers=MAX_PARALLEL_BATCHES) as pool:
        futures = {
            pool.submit(translate_batch, client, model, locale, batch): i
            for i, batch in enumerate(batch_list)
        }
        done_batches = 0
        for fut in as_completed(futures):
            try:
                result = fut.result()
                all_results.update(result)
            except Exception as e:
                print(f"  [{locale}] batch fail: {e}", file=sys.stderr)
            done_batches += 1
            if done_batches % 5 == 0:
                elapsed = time.time() - t0
                rate = len(all_results) / max(0.1, elapsed)
                print(f"[{locale}] {done_batches}/{len(batch_list)} batches | "
                      f"{len(all_results)} translated ({rate:.1f}/s)", flush=True)

    # Apply to .arb
    changed = 0
    for k, v in all_results.items():
        if k in data and isinstance(v, str) and v.strip() and v != data[k]:
            data[k] = v
            changed += 1

    with arb.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")

    dt = time.time() - t0
    print(f"[{locale}] ✓ {changed}/{len(todo)} translated in {dt:.0f}s", flush=True)
    return {"locale": locale, "todo": len(todo), "changed": changed, "seconds": dt}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--locales", default=None,
                    help="Comma-separated; default all 35")
    ap.add_argument("--parallel", type=int, default=4,
                    help="Locales processed concurrently (default 4)")
    ap.add_argument("--model", default="gemini-3.1-flash-lite")
    args = ap.parse_args()

    load_env()
    if not os.environ.get("GEMINI_API_KEY"):
        print("❌ GEMINI_API_KEY not set in backend/.env", file=sys.stderr)
        return 1

    from google import genai
    client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

    locales = LOCALES
    if args.locales:
        locales = [s.strip() for s in args.locales.split(",") if s.strip()]

    en_data = json.load(open(L10N / "app_en.arb"))
    print(f"Gemini translate: {len(locales)} locale(s), model={args.model}, "
          f"{args.parallel} locales in parallel, {MAX_PARALLEL_BATCHES} batches/locale",
          flush=True)
    print(f"app_en.arb keys: {len([k for k in en_data if not k.startswith('@')])}",
          flush=True)

    summaries = []
    with ThreadPoolExecutor(max_workers=args.parallel) as pool:
        futures = {pool.submit(process_locale, client, args.model, loc, en_data): loc
                   for loc in locales}
        for fut in as_completed(futures):
            loc = futures[fut]
            try: summaries.append(fut.result())
            except Exception as e:
                print(f"[{loc}] ❌ {e}", file=sys.stderr, flush=True)

    print("\n=== SUMMARY ===", flush=True)
    total = 0
    for s in sorted(summaries, key=lambda x: x["locale"]):
        if s.get("skipped"):
            print(f"  {s['locale']}: nothing to do")
        else:
            total += s["changed"]
            print(f"  {s['locale']}: {s['changed']}/{s['todo']} in {s['seconds']:.0f}s")
    print(f"\nTotal cells translated: {total}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
