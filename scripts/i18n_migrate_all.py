#!/usr/bin/env python3
"""
i18n_migrate_all.py — orchestrator that runs i18n_migrate_screen.py across
every Dart file under mobile/flutter/lib/screens/** + lib/widgets/** and
collects the union of new_keys + ICU + COMPLEX reports.

Modes
-----
  --dry-run (default)   Scan everything, write master report to keys.json
                        + icu_pending.json + complex_pending.json. NO file
                        writes to source.
  --apply               Run --apply on every file in scope. Sequential to
                        avoid vocab-cache races (the per-file tool reads +
                        writes the shared vocab).
  --filter <regex>      Only process files matching the regex (for spot-runs).

Usage:
  python3 scripts/i18n_migrate_all.py --dry-run
  # → reports/i18n_keys.json + reports/i18n_icu_pending.json + reports/i18n_complex.json

  python3 scripts/i18n_migrate_all.py --apply --filter 'lib/screens/auth'
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FLUTTER_ROOT = REPO_ROOT / "mobile" / "flutter"
LIB_ROOT = FLUTTER_ROOT / "lib"
REPORTS_DIR = REPO_ROOT / "reports"
PER_FILE_TOOL = REPO_ROOT / "scripts" / "i18n_migrate_screen.py"

EXCLUDE_DIR_PARTS = {"_backup_pre_redesign", "generated", "l10n"}
EXCLUDE_EXTS = {".g.dart", ".freezed.dart", ".gr.dart"}


def _enumerate_dart_files(filter_regex: str | None = None):
    import re
    pat = re.compile(filter_regex) if filter_regex else None
    for root in (LIB_ROOT / "screens", LIB_ROOT / "widgets"):
        if not root.exists():
            continue
        for f in root.rglob("*.dart"):
            rel = f.relative_to(REPO_ROOT)
            if any(part in str(rel) for part in EXCLUDE_DIR_PARTS):
                continue
            if any(str(f).endswith(ext) for ext in EXCLUDE_EXTS):
                continue
            if pat and not pat.search(str(rel)):
                continue
            yield f


def _run_per_file(path: Path, apply: bool) -> dict | None:
    cmd = ["python3", str(PER_FILE_TOOL), str(path)]
    if apply:
        cmd.append("--apply")
    try:
        result = subprocess.run(
            cmd, cwd=REPO_ROOT, capture_output=True, text=True, timeout=30,
        )
    except subprocess.TimeoutExpired:
        print(f"⚠️  timeout on {path}", file=sys.stderr)
        return None
    if result.returncode != 0:
        print(f"⚠️  per-file tool exited {result.returncode} on {path}",
              file=sys.stderr)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        return None
    if apply:
        return {}
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"⚠️  unparseable JSON from per-file tool on {path}: {e}",
              file=sys.stderr)
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--filter", default=None)
    args = ap.parse_args()

    REPORTS_DIR.mkdir(exist_ok=True)
    files = list(_enumerate_dart_files(args.filter))
    print(f"Found {len(files)} Dart files to process", file=sys.stderr)

    all_new_keys: dict[str, str] = {}
    all_reused_keys: dict[str, str] = {}
    all_icu: list[dict] = []
    all_complex: list[dict] = []
    files_with_changes = 0
    total_replacements = 0
    total_skipped = 0

    for i, f in enumerate(files):
        if i % 50 == 0 and i > 0:
            print(f"  …{i}/{len(files)}", file=sys.stderr)
        report = _run_per_file(f, args.apply)
        if report is None or args.apply:
            continue
        for k, v in report.get("new_keys", {}).items():
            if k in all_new_keys and all_new_keys[k] != v:
                # Same key minted twice with different values — surface as conflict
                all_complex.append({
                    "file": report["file"],
                    "string": v,
                    "reason": f"key_collision_with_other_file:{k}",
                })
                continue
            all_new_keys[k] = v
        for k, v in report.get("reused_keys", {}).items():
            all_reused_keys[k] = v
        for icu in report.get("icu_pending", []):
            icu["file"] = report["file"]
            all_icu.append(icu)
        for cp in report.get("complex_pending", []):
            cp["file"] = report["file"]
            all_complex.append(cp)
        if report.get("replacements"):
            files_with_changes += 1
            total_replacements += len(report["replacements"])
        total_skipped += report.get("skipped_count", 0)

    if args.apply:
        print(f"\n✓ apply complete across {len(files)} files", file=sys.stderr)
        return 0

    # Dry-run — write reports
    (REPORTS_DIR / "i18n_keys.json").write_text(
        json.dumps(all_new_keys, ensure_ascii=False, indent=2, sort_keys=True)
    )
    (REPORTS_DIR / "i18n_reused.json").write_text(
        json.dumps(all_reused_keys, ensure_ascii=False, indent=2, sort_keys=True)
    )
    (REPORTS_DIR / "i18n_icu_pending.json").write_text(
        json.dumps(all_icu, ensure_ascii=False, indent=2)
    )
    (REPORTS_DIR / "i18n_complex.json").write_text(
        json.dumps(all_complex, ensure_ascii=False, indent=2)
    )

    print(f"""
=== i18n migration dry-run summary ===
  files scanned:        {len(files)}
  files with changes:   {files_with_changes}
  total replacements:   {total_replacements}
  new keys:             {len(all_new_keys)}
  reused keys:          {len(all_reused_keys)}
  ICU-pending:          {len(all_icu)}
  COMPLEX-pending:      {len(all_complex)}
  skipped (not text):   {total_skipped}

Reports written:
  reports/i18n_keys.json          (new keys to add to .arb)
  reports/i18n_reused.json        (existing keys touched)
  reports/i18n_icu_pending.json   (interpolated strings — Phase 5)
  reports/i18n_complex.json       (manual review needed)

Next:
  python3 scripts/i18n_add_keys.py --keys-file reports/i18n_keys.json
  python3 scripts/i18n_fill_translations.py
  cd mobile/flutter && flutter gen-l10n
""", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
