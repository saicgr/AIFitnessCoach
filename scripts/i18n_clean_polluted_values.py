#!/usr/bin/env python3
"""
i18n_clean_polluted_values.py — clean up i18n key-name pollution.

The earlier i18n migration script (scripts/i18n_migrate_screen.py) generated
~1,000 ARB entries where the English VALUE is literally the kebab-cased key
name (e.g. key `unifiedHomeWidgetsWakeHydration` → value `"Unified home widgets
wake hydration"`). All 35 non-en locales then dutifully translated those
polluted English strings — propagating the pollution to every language.

This single-command script:

  Pass A  detect polluted English values via a camel/word-bag heuristic
  Pass B  rewrite app_en.arb with cleaned values (namespace prefix stripped)
  Pass C  force re-translate each cleaned key in every locale via Gemini
          (gemini-3.1-flash-lite, batched JSON, 4 locales in parallel)
  Pass D  shell out to `flutter gen-l10n` so Dart files refresh

Usage:
  python3 scripts/i18n_clean_polluted_values.py --dry-run        # report only
  python3 scripts/i18n_clean_polluted_values.py --apply          # full run
  python3 scripts/i18n_clean_polluted_values.py --apply --skip-translate
                                                                  # local-only

Env: GEMINI_API_KEY in backend/.env or environment.
Cost: ~$5–10 in Gemini Flash Lite calls for the full sweep.
Runtime: ~10–15 minutes end to end.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
L10N = REPO / "mobile" / "flutter" / "lib" / "l10n"
EN_PATH = L10N / "app_en.arb"
REPORT_PATH = REPO / "docs" / "i18n_pollution_report.md"
# Sidecar JSON used by --resume to know exactly which keys were cleaned by
# Pass A (the markdown report is for humans; this is for the script).
SIDECAR_PATH = REPO / "docs" / ".i18n_cleaned_keys.json"

# Mirrors i18n_translate_gemini_v3.py — keep in sync if locale list shifts.
LOCALES = [
    "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi", "id",
    "it", "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne", "nl",
    "or", "pa", "pl", "pt", "ru", "sv", "sw", "ta", "te", "th",
    "tl", "tr", "ur", "vi", "zh",
]

LOCALE_NATIVE = {
    "ar": "Arabic (العربية)", "bn": "Bengali (বাংলা)", "cs": "Czech (čeština)",
    "de": "German (Deutsch)", "es": "Spanish (español)", "fi": "Finnish (suomi)",
    "fr": "French (français)", "ha": "Hausa", "hi": "Hindi (हिन्दी)",
    "id": "Indonesian (Bahasa Indonesia)", "it": "Italian (italiano)",
    "ja": "Japanese (日本語)", "jv": "Javanese (Basa Jawa)", "kn": "Kannada (ಕನ್ನಡ)",
    "ko": "Korean (한국어)", "ml": "Malayalam (മലയാളം)", "mr": "Marathi (मराठी)",
    "ms": "Malay (Bahasa Melayu)", "ne": "Nepali (नेपाली)", "nl": "Dutch (Nederlands)",
    "or": "Odia (ଓଡ଼ିଆ)", "pa": "Punjabi (ਪੰਜਾਬੀ)", "pl": "Polish (polski)",
    "pt": "Portuguese (português)", "ru": "Russian (русский)", "sv": "Swedish (svenska)",
    "sw": "Swahili (Kiswahili)", "ta": "Tamil (தமிழ்)", "te": "Telugu (తెలుగు)",
    "th": "Thai (ไทย)", "tl": "Tagalog (Filipino)", "tr": "Turkish (Türkçe)",
    "ur": "Urdu (اردو)", "vi": "Vietnamese (Tiếng Việt)",
    "zh": "Simplified Chinese (简体中文)",
}

PRESERVE_VERBATIM = [
    "Zealova", "Strava", "Fitbod", "MyFitnessPal", "Apple", "Google", "Hyrox",
    "RevenueCat", "MacroFactor", "Hevy", "Jefit", "Peloton", "Garmin", "FitNotes",
    "StrongLifts", "RPE", "1RM", "AMRAP", "EMOM", "BMR", "TDEE", "HRV", "NEAT",
    "ATG", "RIR", "TUT",
]

BATCH_SIZE = 60               # cleaned keys per Gemini call
MAX_PARALLEL_BATCHES = 6      # batches per locale, in flight
MAX_PARALLEL_LOCALES = 4      # locales processed concurrently

PLACEHOLDER_RE = re.compile(r"\{[^{}]+\}")
_PUNCT_STRIP_RE = re.compile(r"[^\w\s]")

# Per-token cost for gemini-3.1-flash-lite (rough; for cost estimate only).
_INPUT_COST_PER_M = 0.10
_OUTPUT_COST_PER_M = 0.40


# ───────────────────────────────────────────────────────────────────────────
# Pass A — pollution detection
# ───────────────────────────────────────────────────────────────────────────

def camel_words(key: str) -> list[str]:
    """`unifiedHomeWidgetsWakeHydration` → ['unified','home','widgets','wake','hydration']."""
    s = re.sub(r"([A-Z])", r" \1", key)
    return [w.lower() for w in s.split() if w]


def value_words(value: str) -> list[str]:
    """Content words from a value, ignoring placeholders and punctuation."""
    cleaned = PLACEHOLDER_RE.sub(" ", value)
    cleaned = _PUNCT_STRIP_RE.sub(" ", cleaned)
    return [w.lower() for w in cleaned.split() if w]


def is_polluted(key: str, value: str) -> bool:
    """True when the value reads like a humanized form of the key name itself.

    Trigger only when the value's content words EQUAL the key's camel words
    word-for-word (modulo casing). A meaningful value that just happens to
    share a couple of leading words (e.g. `commonCancel: "Cancel"`) stays
    clean.
    """
    if not isinstance(value, str) or not value.strip():
        return False
    kw = camel_words(key)
    vw = value_words(value)
    if len(vw) < 2 or len(kw) < 2:
        return False
    return vw == kw


def is_previously_cleaned(key: str, value: str) -> bool:
    """True when this key/value looks like a previously-cleaned pollution.

    Used in --resume mode after app_en.arb has already been rewritten with
    clean English values. We detect "this key WAS polluted" by checking
    whether its current value words are the trailing-suffix of the key's
    camel words. That suffix is exactly what Pass B leaves behind.

    Examples (returns True):
      unifiedHomeWidgetsWakeHydration → "Wake hydration"
      aiModelDownloadBasic            → "Basic"
      complianceRingCardGreatPace     → "Great pace {arg0}"
    """
    if not isinstance(value, str) or not value.strip():
        return False
    kw = camel_words(key)
    vw = value_words(value)
    if not vw or len(kw) <= len(vw):
        return False
    # Require strict suffix match against the key's tail words.
    return tuple(kw[-len(vw):]) == tuple(vw)


def detect_stale_locale(arb_path: Path, cleaned_en: dict[str, str],
                       sample_size: int = 30, threshold: float = 1.8) -> bool:
    """Return True if this locale appears to still hold pre-cleaning translations.

    Heuristic: sample up to N cleaned keys, compare median length of the
    locale's current value to the clean English value. A still-polluted locale
    carries the translated namespace prefix and runs much longer; a completed
    locale tracks the English length within a normal translation expansion
    ratio (~0.5–1.6×).
    """
    if not arb_path.exists():
        return False
    try:
        data = json.load(open(arb_path, encoding="utf-8"))
    except Exception:  # noqa: BLE001
        return True  # unreadable → safest to retranslate
    ratios: list[float] = []
    for k, en_v in list(cleaned_en.items())[:sample_size]:
        loc_v = data.get(k)
        if not isinstance(loc_v, str) or not loc_v.strip() or not en_v.strip():
            continue
        ratios.append(len(loc_v) / max(1, len(en_v)))
    if not ratios:
        return False
    ratios.sort()
    median = ratios[len(ratios) // 2]
    return median >= threshold


def build_prefix_counts(keys: list[str]) -> dict[tuple[str, ...], int]:
    counts: dict[tuple[str, ...], int] = {}
    for k in keys:
        w = tuple(camel_words(k))
        # Track every leading prefix up to 5 words deep.
        for n in range(1, min(len(w), 6)):
            counts[w[:n]] = counts.get(w[:n], 0) + 1
    return counts


def namespace_prefix(key: str, prefix_counts: dict[tuple[str, ...], int]) -> tuple[str, ...]:
    """Longest leading-word prefix of `key` shared by ≥3 keys total.

    A prefix that appears in only one or two keys isn't a namespace — it's
    the body of an isolated string and stripping it would mangle the value.
    """
    w = tuple(camel_words(key))
    for n in range(min(len(w) - 1, 5), 0, -1):
        if prefix_counts.get(w[:n], 0) >= 3:
            return w[:n]
    return ()


# ───────────────────────────────────────────────────────────────────────────
# Pass B — clean the English value
# ───────────────────────────────────────────────────────────────────────────

def clean_english_value(value: str, namespace: tuple[str, ...]) -> str | None:
    """Return the cleaned English value, or None if the cleaning isn't safe."""
    if not namespace:
        # No detected namespace → can't safely strip. Caller should mark
        # this key as MANUAL_REVIEW.
        return None

    # Protect placeholders during whitespace munging.
    placeholders = PLACEHOLDER_RE.findall(value)
    marker = value
    for i, ph in enumerate(placeholders):
        marker = marker.replace(ph, f"PH{i}", 1)

    words = marker.split()
    ns = list(namespace)
    while words and ns and words[0].lower() == ns[0]:
        words.pop(0)
        ns.pop(0)
    if ns:
        # We expected to strip N words but found fewer — the value isn't
        # actually shaped like the namespace. Bail to MANUAL_REVIEW.
        return None
    if not words:
        return None

    cleaned = " ".join(words)
    for i, ph in enumerate(placeholders):
        cleaned = cleaned.replace(f"PH{i}", ph)
    cleaned = cleaned.strip()
    if not cleaned:
        return None
    cleaned = cleaned[0].upper() + cleaned[1:]
    return cleaned


# ───────────────────────────────────────────────────────────────────────────
# Pass C — re-translate via Gemini (batched, parallel)
# ───────────────────────────────────────────────────────────────────────────

def load_env() -> None:
    env_path = REPO / "backend" / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        os.environ.setdefault(k.strip(), v.strip())


def translate_batch(client, model: str, locale: str, items: dict[str, str]) -> dict[str, str]:
    """Translate {key: english} → {key: localized}. Returns {} on failure."""
    native = LOCALE_NATIVE.get(locale, locale)
    preserve = ", ".join(PRESERVE_VERBATIM)
    system = f"""You translate UI strings for a fitness app called Zealova from English to {native}.

Rules:
1. Output ONLY valid JSON: {{"<key>": "<translated value>", ...}}. No prose, no markdown fences.
2. Preserve every ICU placeholder verbatim: {{arg0}}, {{name}}, {{count}}, etc.
3. Preserve these brand/acronym terms verbatim in Latin script even in non-Latin languages: {preserve}.
4. Match the user-facing tone: friendly, concise, second-person where natural.
5. For very short labels (single word), translate to the {native} equivalent unless rule 3 keeps it verbatim.
6. Preserve sentence boundaries (.) in the target script for multi-sentence values."""

    user_payload = json.dumps(items, ensure_ascii=False, indent=2)
    prompt = f"Translate these English UI strings to {native}. Return JSON only.\n\n{user_payload}"

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
        text = (response.text or "").strip()
        text = re.sub(r"^```(?:json)?\n?", "", text)
        text = re.sub(r"\n?```$", "", text)
        result = json.loads(text)
        return result if isinstance(result, dict) else {}
    except Exception as e:  # noqa: BLE001
        print(f"  [{locale}] batch err: {type(e).__name__}: {str(e)[:140]}",
              file=sys.stderr, flush=True)
        return {}


def chunks(d: dict, size: int):
    items = list(d.items())
    for i in range(0, len(items), size):
        yield dict(items[i:i + size])


def process_locale(client, model: str, locale: str, cleaned_en: dict[str, str]) -> dict:
    """Force-overwrite every cleaned key's translation in app_<locale>.arb."""
    arb = L10N / f"app_{locale}.arb"
    if not arb.exists():
        return {"locale": locale, "error": "no-file"}
    data = json.load(open(arb, encoding="utf-8"))

    # Build the to-translate set: every key we cleaned in app_en.arb whose
    # locale value is either (a) still the polluted English original or
    # (b) a localized translation of that pollution. Force-overwrite both.
    todo = {k: en for k, en in cleaned_en.items() if k in data}
    if not todo:
        return {"locale": locale, "todo": 0, "changed": 0}

    t0 = time.time()
    print(f"[{locale}] {len(todo)} cleaned keys → {len(todo)//BATCH_SIZE + 1} batches",
          flush=True)

    out: dict[str, str] = {}
    batch_list = list(chunks(todo, BATCH_SIZE))
    with ThreadPoolExecutor(max_workers=MAX_PARALLEL_BATCHES) as pool:
        futs = {pool.submit(translate_batch, client, model, locale, b): i
                for i, b in enumerate(batch_list)}
        done = 0
        for fut in as_completed(futs):
            res = fut.result()
            out.update(res)
            done += 1
            if done % 3 == 0:
                print(f"[{locale}] {done}/{len(batch_list)} batches done", flush=True)

    changed = 0
    for k, v in out.items():
        if k in data and isinstance(v, str) and v.strip():
            data[k] = v
            changed += 1

    # Preserve original key order — we keep the file's existing layout.
    with arb.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    dt = time.time() - t0
    print(f"[{locale}] ✓ {changed}/{len(todo)} translated in {dt:.0f}s", flush=True)
    return {"locale": locale, "todo": len(todo), "changed": changed, "seconds": dt}


# ───────────────────────────────────────────────────────────────────────────
# Driver
# ───────────────────────────────────────────────────────────────────────────

def write_report(polluted: list[tuple[str, str, str | None, tuple[str, ...]]]) -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    cleaned = [r for r in polluted if r[2] is not None]
    manual = [r for r in polluted if r[2] is None]
    lines = [
        "# i18n pollution report",
        "",
        f"Total polluted English keys detected: **{len(polluted)}**",
        f"  - Confidently cleanable: **{len(cleaned)}**",
        f"  - MANUAL_REVIEW (no detectable namespace): **{len(manual)}**",
        "",
        "Generated by `scripts/i18n_clean_polluted_values.py`.",
        "",
        "## Cleanable",
        "",
        "| Key | Namespace | Old → New |",
        "|---|---|---|",
    ]
    for key, old, new, ns in sorted(cleaned):
        ns_str = "·".join(ns) if ns else "—"
        lines.append(f"| `{key}` | `{ns_str}` | {old!r} → {new!r} |")
    lines += ["", "## MANUAL_REVIEW", ""]
    for key, old, _, ns in sorted(manual):
        lines.append(f"- `{key}`: {old!r} (no detected namespace)")
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"📝 Report: {REPORT_PATH.relative_to(REPO)}", flush=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true",
                    help="Detect + report only, no file mutation.")
    ap.add_argument("--apply", action="store_true",
                    help="Rewrite app_en.arb, re-translate locales, run gen-l10n.")
    ap.add_argument("--skip-translate", action="store_true",
                    help="Skip Pass C (locale re-translate). Useful for local-only test.")
    ap.add_argument("--skip-gen-l10n", action="store_true",
                    help="Skip Pass D (flutter gen-l10n).")
    ap.add_argument("--locales", default=None,
                    help="Comma-separated subset; default all 35.")
    ap.add_argument("--resume", action="store_true",
                    help="Resume an interrupted run. Skips Pass A/B (en.arb is "
                         "already clean), re-derives the cleaned-key set by "
                         "scanning en.arb for suffix-of-camel-words shapes, "
                         "and only translates locales detected as still stale. "
                         "Completed locales are skipped, no double-billing.")
    ap.add_argument("--model", default="gemini-3.1-flash-lite")
    args = ap.parse_args()

    if not args.dry_run and not args.apply:
        print("Pass --dry-run or --apply.", file=sys.stderr)
        return 2

    if not EN_PATH.exists():
        print(f"❌ {EN_PATH} not found", file=sys.stderr)
        return 1
    en = json.load(open(EN_PATH, encoding="utf-8"))

    cleaned_en: dict[str, str] = {}

    if args.resume:
        # The sidecar JSON written by an earlier Pass A is the source of truth
        # for "which keys to retranslate". If it's missing, fall back to the
        # markdown report; if that's missing too, bail.
        if SIDECAR_PATH.exists():
            cleaned_en = json.load(open(SIDECAR_PATH, encoding="utf-8"))
            print(f"\n[resume] loaded {len(cleaned_en)} cleaned keys from "
                  f"{SIDECAR_PATH.relative_to(REPO)}", flush=True)
        elif REPORT_PATH.exists():
            # Parse markdown table rows: `| \`key\` | ... | 'old' → 'new' |`
            row_re = re.compile(
                r"^\|\s*`([^`]+)`\s*\|[^|]*\|[^|]*→\s*'([^']*)'\s*\|"
            )
            for line in REPORT_PATH.read_text(encoding="utf-8").splitlines():
                m = row_re.match(line)
                if m:
                    cleaned_en[m.group(1)] = m.group(2)
            print(f"\n[resume] parsed {len(cleaned_en)} cleaned keys from "
                  f"{REPORT_PATH.relative_to(REPO)}", flush=True)
        else:
            print("[resume] no sidecar or report found — run without --resume "
                  "first, or pass --locales explicitly.", file=sys.stderr)
            return 1
        if not cleaned_en:
            print("[resume] cleaned set is empty — nothing to do.", flush=True)
            return 0
    else:
        # Pass A
        keys = [k for k in en if not k.startswith("@")]
        prefix_counts = build_prefix_counts(keys)
        polluted: list[tuple[str, str, str | None, tuple[str, ...]]] = []
        for k in keys:
            v = en[k]
            if not is_polluted(k, v):
                continue
            ns = namespace_prefix(k, prefix_counts)
            new_v = clean_english_value(v, ns) if ns else None
            polluted.append((k, v, new_v, ns))
            if new_v is not None:
                cleaned_en[k] = new_v

        print(f"\nPass A: {len(polluted)} polluted keys detected "
              f"({len(cleaned_en)} cleanable, {len(polluted) - len(cleaned_en)} manual)",
              flush=True)
        write_report(polluted)
        # Sidecar for --resume: exact (key → cleaned English) map.
        SIDECAR_PATH.parent.mkdir(parents=True, exist_ok=True)
        with SIDECAR_PATH.open("w", encoding="utf-8") as f:
            json.dump(cleaned_en, f, ensure_ascii=False, indent=2)
            f.write("\n")

        if args.dry_run:
            print("\nDry run complete — no files mutated.", flush=True)
            return 0

        # Pass B
        for k, new_v in cleaned_en.items():
            en[k] = new_v
        with EN_PATH.open("w", encoding="utf-8") as f:
            json.dump(en, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"\nPass B: rewrote app_en.arb with {len(cleaned_en)} cleaned values",
              flush=True)

    # Decide which locales to translate BEFORE bringing up the Gemini client
    # so --resume can short-circuit with no API initialization.
    locales = LOCALES if not args.locales else [
        s.strip() for s in args.locales.split(",") if s.strip()
    ]
    if args.resume and not args.locales and cleaned_en:
        # Cost-saver: only retranslate locales whose .arb still carries the
        # pre-cleaning translation. Already-completed locales are skipped.
        stale_locales = []
        completed_locales = []
        for loc in locales:
            arb = L10N / f"app_{loc}.arb"
            if detect_stale_locale(arb, cleaned_en):
                stale_locales.append(loc)
            else:
                completed_locales.append(loc)
        if completed_locales:
            print(f"[resume] {len(completed_locales)} locales already done: "
                  f"{','.join(completed_locales)}", flush=True)
        if stale_locales:
            print(f"[resume] {len(stale_locales)} locales still stale: "
                  f"{','.join(stale_locales)}", flush=True)
        locales = stale_locales

    # Pass C
    if args.skip_translate:
        print("\nPass C: skipped (--skip-translate).", flush=True)
    elif not cleaned_en or not locales:
        print("\nPass C: nothing to translate.", flush=True)
    else:
        load_env()
        if not os.environ.get("GEMINI_API_KEY"):
            print("❌ GEMINI_API_KEY not set in env or backend/.env",
                  file=sys.stderr)
            return 1
        from google import genai
        client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
        if True:
            print(f"\nPass C: re-translating {len(cleaned_en)} keys × "
                  f"{len(locales)} locales (model={args.model})", flush=True)
            summaries: list[dict] = []
            with ThreadPoolExecutor(max_workers=MAX_PARALLEL_LOCALES) as pool:
                futs = {pool.submit(process_locale, client, args.model, loc, cleaned_en): loc
                        for loc in locales}
                for fut in as_completed(futs):
                    loc = futs[fut]
                    try:
                        summaries.append(fut.result())
                    except Exception as e:  # noqa: BLE001
                        print(f"[{loc}] ❌ {e}", file=sys.stderr)
            total_changed = sum(s.get("changed", 0) for s in summaries)
            print(f"\nPass C summary: {total_changed} cells translated across "
                  f"{len(summaries)} locales", flush=True)

    # Pass D
    if args.skip_gen_l10n:
        print("\nPass D: skipped (--skip-gen-l10n).", flush=True)
    else:
        flutter_dir = REPO / "mobile" / "flutter"
        print(f"\nPass D: running `flutter gen-l10n` in {flutter_dir}", flush=True)
        try:
            subprocess.run(
                ["flutter", "gen-l10n"], cwd=flutter_dir, check=True,
            )
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"⚠️  gen-l10n failed: {e} — run it manually from "
                  f"mobile/flutter/", file=sys.stderr)

    print("\n✅ Done.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
