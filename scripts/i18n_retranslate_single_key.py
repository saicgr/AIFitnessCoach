#!/usr/bin/env python3
"""
i18n_retranslate_single_key.py — re-translate ONE ARB key across all 34 non-en
locales when the English source has changed (the regular retranslate scripts
only touch keys whose value still equals English, so they would skip a stale
translation).

Usage:
  python3 scripts/i18n_retranslate_single_key.py founderNoteSoIBuiltThe
  python3 scripts/i18n_retranslate_single_key.py founderNoteSoIBuiltThe --locales te,hi

Uses MyMemory free translator (same provider as i18n_retranslate_arb.py).
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
L10N = REPO / "mobile" / "flutter" / "lib" / "l10n"

# Mirrors the locale list from i18n_retranslate_arb.py
LOCALES = [
    "ar","bn","cs","de","es","fi","fr","ha","hi","id",
    "it","ja","jv","kn","ko","ml","mr","ms","ne","nl",
    "or","pa","pl","pt","ru","sv","sw","ta","te","th",
    "tl","tr","ur","vi","zh",
]

MYMEMORY_REMAP = {
    "ar":"ar-SA","bn":"bn-IN","cs":"cs-CZ","de":"de-DE","es":"es-ES",
    "fi":"fi-FI","fr":"fr-FR","ha":"ha-NG","hi":"hi-IN","id":"id-ID",
    "it":"it-IT","ja":"ja-JP","jv":"jv-ID","kn":"kn-IN","ko":"ko-KR",
    "ml":"ml-IN","mr":"mr-IN","ms":"ms-MY","ne":"ne-NP","nl":"nl-NL",
    "or":"or-IN","pa":"pa-IN","pl":"pl-PL","pt":"pt-PT","ru":"ru-RU",
    "sv":"sv-SE","sw":"sw-KE","ta":"ta-IN","te":"te-IN","th":"th-TH",
    "tl":"tl-PH","tr":"tr-TR","ur":"ur-PK","vi":"vi-VN","zh":"zh-CN",
}


GOOGLE_REMAP = {"zh": "zh-CN", "jv": "jw"}


def translate_one(text: str, target: str) -> str:
    from deep_translator import GoogleTranslator
    code = GOOGLE_REMAP.get(target, target)
    return GoogleTranslator(source="en", target=code).translate(text)


def process(locale: str, key: str, en_value: str) -> dict:
    path = L10N / f"app_{locale}.arb"
    if not path.exists():
        return {"locale": locale, "skipped": "no-file"}
    with path.open() as f:
        data = json.load(f)
    if key not in data:
        return {"locale": locale, "skipped": "no-key"}
    try:
        translated = translate_one(en_value, locale)
        if not translated or not translated.strip():
            return {"locale": locale, "skipped": "empty-translation"}
        if translated.strip() == data[key]:
            return {"locale": locale, "skipped": "unchanged"}
        data[key] = translated.strip()
    except Exception as e:
        return {"locale": locale, "skipped": f"err:{e}"}
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")
    return {"locale": locale, "changed": True}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("key", help="ARB key to retranslate (must exist in app_en.arb)")
    ap.add_argument("--locales", default=None,
                    help="Comma-separated locales (default: all 34 non-en)")
    args = ap.parse_args()

    en_path = L10N / "app_en.arb"
    with en_path.open() as f:
        en_data = json.load(f)
    en_value = en_data.get(args.key)
    if not isinstance(en_value, str):
        print(f"[err] {args.key} missing or non-string in app_en.arb", file=sys.stderr)
        return 1

    targets = args.locales.split(",") if args.locales else LOCALES
    targets = [t.strip() for t in targets if t.strip()]
    print(f"Re-translating '{args.key}' across {len(targets)} locales", flush=True)
    print(f"EN source: {en_value[:140]}...", flush=True)

    t0 = time.time()
    results = []
    with ThreadPoolExecutor(max_workers=6) as pool:
        futures = {pool.submit(process, lc, args.key, en_value): lc for lc in targets}
        for fut in as_completed(futures):
            r = fut.result()
            results.append(r)
            print(f"  [{r['locale']}] {'changed' if r.get('changed') else r.get('skipped')}", flush=True)
    dt = time.time() - t0
    changed = sum(1 for r in results if r.get("changed"))
    print(f"\nDone. {changed}/{len(results)} locales updated in {dt:.0f}s.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
