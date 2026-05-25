#!/usr/bin/env python3
"""
i18n_retranslate_arb.py — operate directly on app_<locale>.arb files. For every
key whose value still equals the English source (i.e. untranslated bleed),
translate via FREE Google Translate web endpoint (deep_translator). Writes
in place. Resumable: re-running only touches keys still showing English bleed.

NO paid APIs. NO Gemini. Just deep_translator → free Google Translate.

Usage:
  python3 scripts/i18n_retranslate_arb.py                    # all 35 locales
  python3 scripts/i18n_retranslate_arb.py --locales hi,ar    # subset
  python3 scripts/i18n_retranslate_arb.py --parallel 6       # N locales at once
"""
from __future__ import annotations

import argparse
import json
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
GOOGLE_REMAP = {"zh": "zh-CN", "jv": "jw"}

PRESERVE_TERMS = [
    "Zealova","Strava","Fitbod","MyFitnessPal","Apple","Google",
    "Hyrox","RevenueCat","MacroFactor","Hevy","Jefit","Peloton",
    "Garmin","FitNotes","StrongLifts",
    "RPE","1RM","AMRAP","EMOM","BMR","TDEE","HRV","NEAT","ATG","RIR","TUT",
]

# Skip values that aren't worth translating
_SKIP_RE = re.compile(
    r"^("
    r"\s*"                              # whitespace only
    r"|[\d\s\-_:,./]*"                  # only digits/symbols (no letters)
    r"|[A-Z]{2,5}"                      # short acronym like 'IP', 'URL', 'CSV'
    r"|-?\d+(\.\d+)?[a-z%]{0,3}"        # measurements like '15s', '-100kg', '5%'
    r"|[☀-➿-\U0001F300-\U0001FAFF\s]+"  # emoji-only
    r")$"
)

def should_skip(s: str) -> bool:
    if not isinstance(s, str): return True
    if len(s.strip()) < 2: return True
    if _SKIP_RE.match(s): return True
    # No Latin letter at all (already non-English) → skip
    if not re.search(r"[a-zA-Z]", s): return True
    return False

def protect_terms(s: str):
    mapping = {}
    out = s
    for i, term in enumerate(PRESERVE_TERMS):
        if term in out:
            ph = f"§{i:03d}§"
            mapping[ph] = term
            out = out.replace(term, ph)
    return out, mapping

def restore_terms(s: str, mapping):
    for ph, term in mapping.items():
        s = s.replace(ph, term)
    return s

# MyMemory uses BCP-47-ish codes (en-US, hi-IN). Map our ISO-639 → BCP-47.
MYMEMORY_REMAP = {
    "ar":"ar-SA","bn":"bn-IN","cs":"cs-CZ","de":"de-DE","es":"es-ES",
    "fi":"fi-FI","fr":"fr-FR","ha":"ha-NG","hi":"hi-IN","id":"id-ID",
    "it":"it-IT","ja":"ja-JP","jv":"jv-ID","kn":"kn-IN","ko":"ko-KR",
    "ml":"ml-IN","mr":"mr-IN","ms":"ms-MY","ne":"ne-NP","nl":"nl-NL",
    "or":"or-IN","pa":"pa-IN","pl":"pl-PL","pt":"pt-PT","ru":"ru-RU",
    "sv":"sv-SE","sw":"sw-KE","ta":"ta-IN","te":"te-IN","th":"th-TH",
    "tl":"tl-PH","tr":"tr-TR","ur":"ur-PK","vi":"vi-VN","zh":"zh-CN",
}

def translate_one(text: str, target: str, _unused=None) -> str:
    """Translate via MyMemory (free, no API key). Falls back to English on
    any error — caller decides whether to retry."""
    from deep_translator import MyMemoryTranslator
    protected, mapping = protect_terms(text)
    if not protected.strip():
        return text
    bcp = MYMEMORY_REMAP.get(target, target)
    try:
        tr = MyMemoryTranslator(source="en-US", target=bcp)
        result = tr.translate(protected)
        if not result or not result.strip():
            return text
        return restore_terms(result.strip(), mapping)
    except Exception:
        return text

def process_locale(locale: str, en_data: dict, workers: int = 20) -> dict:
    arb_path = L10N / f"app_{locale}.arb"
    with arb_path.open() as f:
        data = json.load(f)

    # Find keys needing translation: value == English AND should not skip
    todo = []
    for k, en_v in en_data.items():
        if k.startswith("@"): continue
        if not isinstance(en_v, str): continue
        cur = data.get(k)
        if cur != en_v: continue  # already translated (different from en)
        if should_skip(en_v): continue
        todo.append(k)

    if not todo:
        return {"locale": locale, "skipped": True, "todo": 0}

    t0 = time.time()
    print(f"[{locale}] translating {len(todo)} keys (workers={workers})...", flush=True)

    results: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {
            pool.submit(translate_one, en_data[k], locale): k
            for k in todo
        }
        done = 0
        for fut in as_completed(futures):
            k = futures[fut]
            try:
                results[k] = fut.result()
            except Exception:
                results[k] = en_data[k]
            done += 1
            if done % 500 == 0:
                elapsed = time.time() - t0
                rate = done / max(0.1, elapsed)
                eta = (len(todo) - done) / rate
                print(f"[{locale}] {done}/{len(todo)} done ({rate:.1f}/s, eta {eta:.0f}s)",
                      flush=True)

    # Apply results to data + write back
    changed = 0
    for k, v in results.items():
        if v and v != data.get(k):
            data[k] = v
            changed += 1

    with arb_path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")

    dt = time.time() - t0
    print(f"[{locale}] ✓ {changed}/{len(todo)} changed in {dt:.0f}s", flush=True)
    return {"locale": locale, "todo": len(todo), "changed": changed, "seconds": dt}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--locales", default=None,
                    help="Comma-separated locales (default: all 35)")
    ap.add_argument("--parallel", type=int, default=4,
                    help="Number of locales to process concurrently (default 4)")
    ap.add_argument("--workers-per-locale", type=int, default=20,
                    help="Threadpool size within each locale (default 20)")
    args = ap.parse_args()

    locales = LOCALES
    if args.locales:
        locales = [s.strip() for s in args.locales.split(",") if s.strip()]

    en_data = json.load(open(L10N / "app_en.arb"))

    print(f"Re-translating {len(locales)} locale(s), {args.parallel} in parallel, "
          f"{args.workers_per_locale} workers each", flush=True)

    summaries = []
    with ThreadPoolExecutor(max_workers=args.parallel) as pool:
        futures = {
            pool.submit(process_locale, loc, en_data, args.workers_per_locale): loc
            for loc in locales
        }
        for fut in as_completed(futures):
            loc = futures[fut]
            try:
                summaries.append(fut.result())
            except Exception as e:
                print(f"[{loc}] ❌ failed: {e}", file=sys.stderr, flush=True)

    print("\n=== SUMMARY ===", flush=True)
    total_changed = 0
    for s in sorted(summaries, key=lambda x: x["locale"]):
        if s.get("skipped"):
            print(f"  {s['locale']}: nothing to do")
        else:
            total_changed += s["changed"]
            print(f"  {s['locale']}: {s['changed']}/{s['todo']} changed "
                  f"({s['seconds']:.0f}s)")
    print(f"\nTotal cells changed: {total_changed}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
