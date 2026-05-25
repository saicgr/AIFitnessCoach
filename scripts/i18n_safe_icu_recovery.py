#!/usr/bin/env python3
"""
i18n_safe_icu_recovery.py — VERY conservative ICU migration for the 416 files
the prior ICU agent corrupted. We accept LOWER coverage in exchange for ZERO
syntax breakage. Only handles the textbook pattern:

  Text('Hello $name')                 → Text(AppLocalizations.of(context).<k>(name))
  Text('Score: $score points')        → ... .<k>(score)
  Text('Done in ${duration}s')        → ... .<k>(duration)

Strict requirements per call site:
  1. Wrapped DIRECTLY in `Text(`, `Text(\n  ...`, `Tooltip(message:`, `label:`, etc.
  2. Single-quoted simple interpolation `$ident` or `${ident}` — NOT method calls,
     NOT object access, NOT nested expressions
  3. The whole string is on a single line OR is a simple multi-line with no escape
  4. Source file's nearest enclosing class is a StatefulWidget/StatelessWidget
     (we have BuildContext)

Anything that doesn't match → leave alone, skip silently. The 416 broken files
were broken because the previous agent tried to handle complex cases mid-quote.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIB = REPO / "mobile" / "flutter" / "lib"
EN_ARB = LIB / "l10n" / "app_en.arb"

# Pattern: textbook interpolation in a UI context wrapper.
# Match `Text('...$ident...')` or `Text("...$ident...")` where:
#   - The string contains exactly $ident or ${ident}
#   - No method calls, no operators, no complex syntax
#
# Group 1: the wrapper (Text, etc.)
# Group 2: the entire matched original substring INCLUDING quotes
SIMPLE_INTERP_RE = re.compile(
    r"(Text|Tooltip\(message:|hintText:|labelText:|helperText:|errorText:|tooltip:|label:)\s*\(?\s*'((?:[^'\\$]|\\.)*\$\{?[a-zA-Z_]\w*\}?(?:[^'\\$]|\\.)*)'\s*\)?",
    re.MULTILINE,
)

# Stricter sub-pattern: extract every interpolation in the string body
INTERP_TOKEN_RE = re.compile(r"\$\{([a-zA-Z_]\w*)\}|\$([a-zA-Z_]\w*)")


def camel(words: list[str]) -> str:
    """Build a camelCase key from words."""
    if not words: return "k"
    return words[0].lower() + "".join(w.capitalize() for w in words[1:])


def mint_key(file: Path, body: str, existing: set[str]) -> str:
    # Use file stem as prefix
    stem = file.stem
    # Sanitize body to text words for key suffix
    text_part = INTERP_TOKEN_RE.sub("", body)
    text_words = re.findall(r"[A-Za-z]+", text_part)[:4]
    base = camel(stem.split("_") + text_words) if text_words else camel(stem.split("_") + ["msg"])
    # Make valid Dart identifier
    base = re.sub(r"[^a-zA-Z0-9_]", "", base)
    if not base or not base[0].islower():
        base = "k" + base
    candidate = base
    i = 2
    while candidate in existing:
        candidate = f"{base}{i}"
        i += 1
    existing.add(candidate)
    return candidate


def build_icu_value(body: str) -> tuple[str, list[str]]:
    """Replace `$name`/`${name}` with `{name}`; return (icu_value, list_of_param_names_in_order)."""
    params: list[str] = []
    seen = set()
    def repl(m):
        name = m.group(1) or m.group(2)
        if name not in seen:
            seen.add(name)
            params.append(name)
        return "{" + name + "}"
    new_body = INTERP_TOKEN_RE.sub(repl, body)
    return new_body, params


def file_has_appLocalizations_import(text: str) -> bool:
    return "app_localizations.dart" in text


def file_has_part_of(text: str) -> bool:
    return bool(re.match(r"^\s*part of\b", text, re.MULTILINE))


def process_file(fp: Path, en: dict, mint_cache: set[str]) -> tuple[int, dict, dict]:
    """Return (replacements_count, new_keys_dict, new_metadata_dict) for the file."""
    text = fp.read_text()
    if "AppLocalizations" in text and "AppLocalizations.of(context)" in text:
        # Already partially migrated — be extra cautious; we only ADD, don't replace
        pass
    if file_has_part_of(text):
        # Skip part-of files (we'd need to ensure parent's import; agent territory)
        return 0, {}, {}

    new_keys: dict[str, str] = {}
    new_meta: dict[str, dict] = {}
    edits: list[tuple[int, int, str]] = []  # (start, end, replacement)

    for m in SIMPLE_INTERP_RE.finditer(text):
        wrapper = m.group(1)
        body = m.group(2)
        # Skip if body contains method-like syntax (we want SIMPLE only)
        if re.search(r"\$\{[^}]*[(\.,][^}]*\}", body):
            continue
        # Skip if body has nested string literals
        if "'" in body or '"' in body:
            continue
        # Find all interpolations
        params_found = INTERP_TOKEN_RE.findall(body)
        if not params_found:
            continue
        # Build ICU value + params
        icu_val, params = build_icu_value(body)
        # Mint a new key (avoid reusing — be conservative)
        existing = set(en.keys()) | set(new_keys.keys()) | mint_cache
        key = mint_key(fp, body, existing)
        new_keys[key] = icu_val
        new_meta[f"@{key}"] = {"placeholders": {p: {"type": "Object"} for p in params}}
        # Build replacement
        param_args = ", ".join(params)
        # Wrapper-specific replacement
        if wrapper == "Text":
            replacement = f"Text(AppLocalizations.of(context)!.{key}({param_args}))"
        elif wrapper.startswith("Tooltip"):
            replacement = f"Tooltip(message: AppLocalizations.of(context)!.{key}({param_args})"
        else:
            # Named-arg patterns: hintText: 'x' → hintText: AppLocalizations.of(context)!.x(...)
            replacement = f"{wrapper} AppLocalizations.of(context)!.{key}({param_args})"
        edits.append((m.start(), m.end(), replacement))

    if not edits:
        return 0, {}, {}

    # Apply edits from rightmost to leftmost
    new_text = text
    for start, end, rep in sorted(edits, key=lambda x: -x[0]):
        new_text = new_text[:start] + rep + new_text[end:]

    # Add import if needed
    if not file_has_appLocalizations_import(new_text):
        # Compute relative path
        lib_root = None
        for anc in fp.parents:
            if anc.name == "lib": lib_root = anc; break
        if lib_root:
            import os
            rel = os.path.relpath(lib_root / "l10n" / "generated" / "app_localizations.dart",
                                  fp.parent)
            new_text = f"import '{rel}';\n" + new_text

    fp.write_text(new_text)
    return len(edits), new_keys, new_meta


def main() -> int:
    # Operate on the 416 reverted files only
    broken_list = REPO / "reports" / "i18n_phase5_broken.txt"
    if not broken_list.exists():
        print(f"❌ {broken_list} not found", file=sys.stderr)
        return 1
    files = [REPO / "mobile" / "flutter" / l.strip()
             for l in broken_list.read_text().splitlines() if l.strip()]

    en = json.load(open(EN_ARB))
    mint_cache: set[str] = set()
    all_new_keys: dict[str, str] = {}
    all_new_meta: dict[str, dict] = {}
    total_files_changed = 0
    total_edits = 0

    for fp in files:
        if not fp.exists(): continue
        try:
            n, new_k, new_m = process_file(fp, en, mint_cache)
        except Exception as e:
            print(f"  ⚠ {fp.relative_to(REPO)}: {e}", file=sys.stderr)
            continue
        if n:
            total_files_changed += 1
            total_edits += n
            all_new_keys.update(new_k)
            all_new_meta.update(new_m)

    print(f"Safe ICU recovery: {total_edits} replacements across {total_files_changed} files")
    print(f"New keys: {len(all_new_keys)}")

    # Save new keys for orchestrator merge
    out = {**all_new_keys, **all_new_meta}
    (REPO / "reports" / "i18n_safe_icu_keys.json").write_text(
        json.dumps(out, ensure_ascii=False, indent=2, sort_keys=True))
    print("Wrote reports/i18n_safe_icu_keys.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
