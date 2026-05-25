#!/usr/bin/env python3
"""
i18n_translate_multi_provider.py — translate non-en ARB cells using a rotation of
FREE providers to bypass any single one's rate limit.

Providers (in order, each tried until one succeeds):
  1. MyMemoryTranslator with email auth → 50K words/day per email
  2. LingueeTranslator (free, no key)
  3. LibreTranslator (libretranslate.com public instance, no key, slow but unlimited)
  4. GoogleTranslator (deep_translator) — last resort, IP-rate-limited

When all providers fail for a string, we keep English (transparent failure, no silent
degradation).

Usage:
  python3 scripts/i18n_translate_multi_provider.py
  python3 scripts/i18n_translate_multi_provider.py --locales hi,ar,zh
  python3 scripts/i18n_translate_multi_provider.py --email you@example.com --parallel 4

The email arg is required for MyMemory's 50K/day tier; without it MyMemory caps at
1K/day per IP. Recommend the user's own email or a throwaway alias.
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

# MyMemory uses BCP-47-ish codes (en-US, hi-IN). Map ISO 639-1 → BCP-47.
MYMEMORY_REMAP = {
    "ar":"ar-SA","bn":"bn-IN","cs":"cs-CZ","de":"de-DE","es":"es-ES",
    "fi":"fi-FI","fr":"fr-FR","ha":"ha-NG","hi":"hi-IN","id":"id-ID",
    "it":"it-IT","ja":"ja-JP","jv":"jv-ID","kn":"kn-IN","ko":"ko-KR",
    "ml":"ml-IN","mr":"mr-IN","ms":"ms-MY","ne":"ne-NP","nl":"nl-NL",
    "or":"or-IN","pa":"pa-IN","pl":"pl-PL","pt":"pt-PT","ru":"ru-RU",
    "sv":"sv-SE","sw":"sw-KE","ta":"ta-IN","te":"te-IN","th":"th-TH",
    "tl":"tl-PH","tr":"tr-TR","ur":"ur-PK","vi":"vi-VN","zh":"zh-CN",
}

# Google maps for the last-resort provider (jv → jw remap is Google's, not standard).
GOOGLE_REMAP = {"zh": "zh-CN", "jv": "jw"}

# LibreTranslate uses ISO 639-1; some locales aren't supported and we skip them.
LIBRE_SUPPORTED = {
    "ar","cs","de","es","fi","fr","hi","id","it","ja","ko","nl",
    "pl","pt","ru","sv","tr","vi","zh",
}

PRESERVE_TERMS = [
    "Zealova","Strava","Fitbod","MyFitnessPal","Apple","Google",
    "Hyrox","RevenueCat","MacroFactor","Hevy","Jefit","Peloton",
    "Garmin","FitNotes","StrongLifts",
    "RPE","1RM","AMRAP","EMOM","BMR","TDEE","HRV","NEAT","ATG","RIR","TUT",
]

# Don't translate values like '15s', '100kg', '5%', '7-day', acronyms-only, etc.
_SKIP_RE = re.compile(
    r"^("
    r"\s*"
    r"|[\d\s\-_:,./]*"
    r"|[A-Z]{2,5}"
    r"|-?\d+(\.\d+)?[a-z%]{0,3}"
    r")$"
)


def should_skip(s: str) -> bool:
    if not isinstance(s, str): return True
    if len(s.strip()) < 2: return True
    if _SKIP_RE.match(s): return True
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


def translate_via_mymemory(text: str, target: str, email: str | None) -> str | None:
    from deep_translator import MyMemoryTranslator
    bcp = MYMEMORY_REMAP.get(target, target)
    try:
        kwargs = {"source": "en-US", "target": bcp}
        if email:
            kwargs["email"] = email
        tr = MyMemoryTranslator(**kwargs)
        r = tr.translate(text)
        if r and r.strip() and r.strip().lower() != text.strip().lower():
            return r.strip()
    except Exception:
        return None
    return None


def translate_via_libre(text: str, target: str) -> str | None:
    if target not in LIBRE_SUPPORTED:
        return None
    from deep_translator import LibreTranslator
    try:
        tr = LibreTranslator(source="en", target=target,
                             base_url="https://libretranslate.com/")
        r = tr.translate(text)
        if r and r.strip() and r.strip().lower() != text.strip().lower():
            return r.strip()
    except Exception:
        return None
    return None


def translate_via_linguee(text: str, target: str) -> str | None:
    # Linguee only does word-level lookups; skip multi-word strings.
    if " " in text.strip() or len(text.split()) > 1:
        return None
    from deep_translator import LingueeTranslator
    LINGUEE_REMAP = {
        "de":"german","fr":"french","es":"spanish","it":"italian","pt":"portuguese",
        "nl":"dutch","pl":"polish","ru":"russian","ja":"japanese","zh":"chinese",
    }
    if target not in LINGUEE_REMAP:
        return None
    try:
        tr = LingueeTranslator(source="english", target=LINGUEE_REMAP[target])
        r = tr.translate(text)
        if r and r.strip() and r.strip().lower() != text.strip().lower():
            return r.strip()
    except Exception:
        return None
    return None


def translate_via_google(text: str, target: str) -> str | None:
    from deep_translator import GoogleTranslator
    glang = GOOGLE_REMAP.get(target, target)
    try:
        tr = GoogleTranslator(source="en", target=glang)
        r = tr.translate(text)
        if r and r.strip() and r.strip().lower() != text.strip().lower():
            return r.strip()
    except Exception:
        return None
    return None


def translate_one(text: str, target: str, email: str | None) -> tuple[str, str]:
    """Return (translated_text_or_english, provider_used_or_'none')."""
    protected, mapping = protect_terms(text)
    if not protected.strip():
        return text, "none-empty"

    for name, fn in [
        ("mymemory", lambda: translate_via_mymemory(protected, target, email)),
        ("libre",    lambda: translate_via_libre(protected, target)),
        ("linguee",  lambda: translate_via_linguee(protected, target)),
        ("google",   lambda: translate_via_google(protected, target)),
    ]:
        result = fn()
        if result:
            return restore_terms(result, mapping), name
    return text, "none-all-failed"


def process_locale(locale: str, en_data: dict, workers: int, email: str | None) -> dict:
    arb_path = L10N / f"app_{locale}.arb"
    with arb_path.open() as f:
        data = json.load(f)

    todo = []
    for k, en_v in en_data.items():
        if k.startswith("@") or not isinstance(en_v, str): continue
        cur = data.get(k)
        if cur != en_v: continue   # already translated (differs from en)
        if should_skip(en_v): continue
        todo.append(k)

    if not todo:
        return {"locale": locale, "todo": 0, "changed": 0, "skipped": True}

    t0 = time.time()
    print(f"[{locale}] {len(todo)} keys to translate (workers={workers})...", flush=True)

    results: dict[str, tuple[str, str]] = {}
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(translate_one, en_data[k], locale, email): k for k in todo}
        done = 0
        for fut in as_completed(futures):
            k = futures[fut]
            try:
                results[k] = fut.result()
            except Exception:
                results[k] = (en_data[k], "exception")
            done += 1
            if done % 500 == 0:
                rate = done / max(0.1, time.time() - t0)
                eta = (len(todo) - done) / rate
                print(f"[{locale}] {done}/{len(todo)} ({rate:.1f}/s, eta {eta:.0f}s)",
                      flush=True)

    changed = 0
    providers = {}
    for k, (v, prov) in results.items():
        providers[prov] = providers.get(prov, 0) + 1
        if v and v != data.get(k):
            data[k] = v
            changed += 1

    with arb_path.open("w") as f:
        json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")

    dt = time.time() - t0
    breakdown = " ".join(f"{p}={n}" for p, n in sorted(providers.items()))
    print(f"[{locale}] ✓ {changed}/{len(todo)} translated in {dt:.0f}s | {breakdown}",
          flush=True)
    return {"locale": locale, "todo": len(todo), "changed": changed,
            "seconds": dt, "providers": providers}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--locales", default=None)
    ap.add_argument("--parallel", type=int, default=3)
    ap.add_argument("--workers-per-locale", type=int, default=6)
    ap.add_argument("--email", default=os.environ.get("MYMEMORY_EMAIL"),
                    help="Email for MyMemory 50K/day tier (default: $MYMEMORY_EMAIL)")
    args = ap.parse_args()

    locales = LOCALES
    if args.locales:
        locales = [s.strip() for s in args.locales.split(",") if s.strip()]

    en_data = json.load(open(L10N / "app_en.arb"))
    email = args.email
    print(f"Multi-provider translate: {len(locales)} locale(s), "
          f"{args.parallel} parallel, {args.workers_per_locale} workers each, "
          f"email={'set' if email else 'NOT SET (capped at 1K/day)'}",
          flush=True)

    summaries = []
    with ThreadPoolExecutor(max_workers=args.parallel) as pool:
        futures = {pool.submit(process_locale, loc, en_data,
                                args.workers_per_locale, email): loc
                   for loc in locales}
        for fut in as_completed(futures):
            loc = futures[fut]
            try: summaries.append(fut.result())
            except Exception as e:
                print(f"[{loc}] ❌ {e}", file=sys.stderr, flush=True)

    print("\n=== SUMMARY ===", flush=True)
    total_changed = 0
    for s in sorted(summaries, key=lambda x: x["locale"]):
        if s.get("skipped"):
            print(f"  {s['locale']}: nothing to do")
        else:
            total_changed += s["changed"]
            print(f"  {s['locale']}: {s['changed']}/{s['todo']} "
                  f"({s['seconds']:.0f}s) "
                  f"providers={s.get('providers', {})}")
    print(f"\nTotal cells translated: {total_changed}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
