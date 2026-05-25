#!/usr/bin/env python3
"""
i18n_translate_batches.py — translate all scripts/translations/batch_v2_*.json
files into 35 non-English locales using the FREE Google Translate web endpoint
via deep_translator (no API key, no billing, no Gemini).

Operates on the batch files in-place:
  Input shape:  {"key": "English value", ...}
  Output shape: {"key": {"en": "...", "ar": "...", ...all 36 codes}, ...}

Strategy: batch-translate per locale (one HTTP request per ~5000 chars chunk),
serial across locales but parallel chunking via threading to keep wall-clock low.
Skips already-translated batches (resumable).

Brand names + fitness acronyms preserved Latin (no translation) via placeholder
substitution before translation and restoration after.
"""
from __future__ import annotations

import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS_DIR = REPO_ROOT / "scripts" / "translations"

# Sorted ISO codes for stable iteration / deterministic output.
LOCALES_NON_EN = [
    "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi", "id",
    "it", "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne", "nl",
    "or", "pa", "pl", "pt", "ru", "sv", "sw", "ta", "te", "th",
    "tl", "tr", "ur", "vi", "zh",
]

# Google Translate doesn't recognize some codes — remap before sending.
GOOGLE_REMAP = {
    "zh": "zh-CN",    # Simplified Chinese
    "jv": "jw",       # Javanese — Google uses 'jw' not 'jv'
}

# Brand names + fitness acronyms — preserve verbatim (replace with placeholder,
# translate around them, restore after).
PRESERVE_TERMS = [
    "Zealova", "Strava", "Fitbod", "MyFitnessPal", "Apple", "Google",
    "Hyrox", "RevenueCat", "MacroFactor", "Hevy", "Jefit", "Peloton",
    "Garmin", "FitNotes", "StrongLifts",
    "RPE", "1RM", "AMRAP", "EMOM", "PR", "BMR", "TDEE", "HRV", "NEAT",
    "ATG", "RIR", "TUT",
]

# Per Google Translate web endpoint — max 5000 chars per request safely.
MAX_CHUNK_CHARS = 4500
# Delimiter Google preserves (uncommon string the source values won't contain).
DELIM = "\n##ZSEP##\n"


def _protect_terms(s: str) -> tuple[str, dict[str, str]]:
    """Replace PRESERVE_TERMS with stable tokens so Google doesn't translate them."""
    mapping: dict[str, str] = {}
    out = s
    for i, term in enumerate(PRESERVE_TERMS):
        if term in out:
            placeholder = f"§{i:03d}§"
            mapping[placeholder] = term
            out = out.replace(term, placeholder)
    return out, mapping


def _restore_terms(s: str, mapping: dict[str, str]) -> str:
    for placeholder, term in mapping.items():
        s = s.replace(placeholder, term)
    return s


def _translate_one(text: str, target: str, translator_cls) -> str:
    """Translate one string. Preserves brand/acronym terms via placeholder swap."""
    glang = GOOGLE_REMAP.get(target, target)
    tr = translator_cls(source="en", target=glang)
    protected, mapping = _protect_terms(text)
    if not protected.strip():
        return text
    try:
        translated = tr.translate(protected)
    except Exception as e:
        # Per-string fallback — keep English on this string only.
        return text
    return _restore_terms((translated or text).strip(), mapping)


def _translate_chunk(texts: list[str], target: str, translator_cls) -> list[str]:
    """Translate a list of strings concurrently for one target locale.
    20-way thread pool keeps wall-clock low without tripping rate limits.
    """
    out: list[str] = [""] * len(texts)
    with ThreadPoolExecutor(max_workers=20) as pool:
        futures = {
            pool.submit(_translate_one, t, target, translator_cls): i
            for i, t in enumerate(texts)
        }
        for fut in as_completed(futures):
            i = futures[fut]
            try:
                out[i] = fut.result()
            except Exception:
                out[i] = texts[i]  # English fallback per string
    return out


def _chunkify(texts: list[str], max_chars: int) -> list[list[str]]:
    """Split a list into chunks where each chunk's total joined length ≤ max_chars."""
    chunks: list[list[str]] = []
    cur: list[str] = []
    cur_len = 0
    for t in texts:
        added = len(t) + len(DELIM)
        if cur and cur_len + added > max_chars:
            chunks.append(cur)
            cur = []
            cur_len = 0
        cur.append(t)
        cur_len += added
    if cur:
        chunks.append(cur)
    return chunks


def _translate_to_locale(texts: list[str], target: str) -> list[str]:
    """Translate all `texts` to `target` locale via concurrent per-string calls."""
    from deep_translator import GoogleTranslator
    return _translate_chunk(texts, target, GoogleTranslator)


def _process_batch(batch_path: Path, locales: list[str]) -> bool:
    """Translate one batch file. Returns True if work was done, False if skipped."""
    with batch_path.open() as f:
        data = json.load(f)
    if not data:
        return False
    first_value = next(iter(data.values()))
    if isinstance(first_value, dict):
        # Already translated — skip (resumable)
        print(f"  ↻ {batch_path.name} already translated, skipping")
        return False

    keys = list(data.keys())
    english_values = [data[k] for k in keys]
    print(f"  → {batch_path.name}: {len(keys)} keys × {len(locales)} locales...")

    # Build per-key result: start with English in place
    result: dict[str, dict[str, str]] = {k: {"en": data[k]} for k in keys}

    # Translate to each locale serially (to keep rate limiting predictable)
    for loc in locales:
        t0 = time.time()
        translated = _translate_to_locale(english_values, loc)
        for k, v in zip(keys, translated):
            result[k][loc] = v
        dt = time.time() - t0
        print(f"    {loc}: {dt:.1f}s ({len(translated)} strings)")

    # Write back
    with batch_path.open("w") as f:
        json.dump(result, f, ensure_ascii=False, indent=2, sort_keys=True)
    return True


def main() -> int:
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", type=str, default=None,
                    help="Substring filter: only process batches whose filename contains this")
    ap.add_argument("--locales", type=str, default=None,
                    help="Comma-separated locales to limit to (default: all 35)")
    ap.add_argument("--parallel-batches", type=int, default=4,
                    help="How many batches to process in parallel (each uses its own thread)")
    args = ap.parse_args()

    locales = LOCALES_NON_EN
    if args.locales:
        locales = [s.strip() for s in args.locales.split(",") if s.strip()]

    batches = sorted(TRANSLATIONS_DIR.glob("batch_v2_*.json"))
    if args.only:
        batches = [b for b in batches if args.only in b.name]
    print(f"Processing {len(batches)} batch file(s) × {len(locales)} locale(s)…")
    print(f"Parallel batches: {args.parallel_batches}")
    print()

    done_count = 0
    skip_count = 0
    if args.parallel_batches > 1:
        with ThreadPoolExecutor(max_workers=args.parallel_batches) as pool:
            futures = {pool.submit(_process_batch, b, locales): b for b in batches}
            for fut in as_completed(futures):
                try:
                    if fut.result():
                        done_count += 1
                    else:
                        skip_count += 1
                except Exception as e:
                    print(f"  ❌ {futures[fut].name}: {e}", file=sys.stderr)
    else:
        for b in batches:
            try:
                if _process_batch(b, locales):
                    done_count += 1
                else:
                    skip_count += 1
            except Exception as e:
                print(f"  ❌ {b.name}: {e}", file=sys.stderr)

    print()
    print(f"✓ Translated: {done_count}")
    print(f"  Skipped (already done): {skip_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
