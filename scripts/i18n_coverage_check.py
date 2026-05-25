#!/usr/bin/env python3
"""
i18n_coverage_check.py — refuses to pass if any (key, locale) cell is missing
or contains the `[en] ` placeholder marker. Per `feedback_i18n_no_english_fallback`,
the migration's 100%-coverage rule is enforced by this gate.

Usage
-----
  python3 scripts/i18n_coverage_check.py
      Full check across all 36 locales × all keys. Exit 0 = pass, 1 = fail.

  python3 scripts/i18n_coverage_check.py --keys-file <path>
      Only check the keys in <path>.json (subset check for per-batch verification).

  python3 scripts/i18n_coverage_check.py --report
      Print detailed per-locale + per-key matrix of gaps.

Exit codes:
  0 = clean
  1 = missing keys or [en] markers found
  2 = .arb file shape error
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = REPO_ROOT / "mobile" / "flutter" / "lib" / "l10n"
PLACEHOLDER = "[en] "


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--keys-file", type=Path, default=None,
                    help="Subset of keys to check (default: all keys in app_en.arb)")
    ap.add_argument("--report", action="store_true",
                    help="Print detailed per-locale gap report on failure")
    args = ap.parse_args()

    en_path = L10N_DIR / "app_en.arb"
    if not en_path.exists():
        print(f"❌ {en_path} not found", file=sys.stderr)
        return 2
    with en_path.open() as f:
        en_data = json.load(f)

    if args.keys_file:
        with args.keys_file.open() as f:
            keys_to_check = set(json.load(f).keys())
    else:
        keys_to_check = {k for k in en_data if not k.startswith("@")}

    arb_files = sorted(L10N_DIR.glob("app_*.arb"))
    failures: dict[str, list[str]] = {}  # locale -> list[key]
    placeholder_failures: dict[str, list[str]] = {}

    for arb in arb_files:
        locale = arb.stem.removeprefix("app_")
        with arb.open() as f:
            data = json.load(f)
        for key in keys_to_check:
            v = data.get(key)
            if v is None or (isinstance(v, str) and v == ""):
                failures.setdefault(locale, []).append(key)
            elif isinstance(v, str) and v.startswith(PLACEHOLDER):
                placeholder_failures.setdefault(locale, []).append(key)

    total_missing = sum(len(v) for v in failures.values())
    total_placeholder = sum(len(v) for v in placeholder_failures.values())

    if total_missing == 0 and total_placeholder == 0:
        print(f"✓ {len(keys_to_check)} keys × {len(arb_files)} locales — "
              f"all {len(keys_to_check) * len(arb_files)} cells populated, "
              f"zero [en] markers.")
        return 0

    print(f"❌ coverage failure:", file=sys.stderr)
    print(f"   missing cells:   {total_missing}", file=sys.stderr)
    print(f"   [en] markers:    {total_placeholder}", file=sys.stderr)
    print(f"   affected locales: "
          f"{sorted(set(failures) | set(placeholder_failures))}",
          file=sys.stderr)

    if args.report:
        for locale in sorted(failures):
            print(f"\n  [{locale}] missing {len(failures[locale])} keys:",
                  file=sys.stderr)
            for k in sorted(failures[locale])[:20]:
                print(f"    - {k}", file=sys.stderr)
            if len(failures[locale]) > 20:
                print(f"    … and {len(failures[locale]) - 20} more",
                      file=sys.stderr)
        for locale in sorted(placeholder_failures):
            print(f"\n  [{locale}] {len(placeholder_failures[locale])} keys "
                  f"still have [en] marker:", file=sys.stderr)
            for k in sorted(placeholder_failures[locale])[:20]:
                print(f"    - {k}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
