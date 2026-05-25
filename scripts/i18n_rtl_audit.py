#!/usr/bin/env python3
"""
i18n_rtl_audit.py — find hardcoded LTR-only positioning in Dart source +
optionally migrate to direction-aware variants.

What we look for (Phase 6 of the i18n plan):
  * Alignment.{centerLeft, topLeft, bottomLeft, centerRight, topRight, bottomRight}
      → AlignmentDirectional.{centerStart, topStart, bottomStart, centerEnd, …}
  * EdgeInsets.only(left: X)            → EdgeInsetsDirectional.only(start: X)
  * EdgeInsets.fromLTRB(L, T, R, B)     → EdgeInsetsDirectional.fromSTEB(L, T, R, B)
                                          IF L != R, else fine
  * Positioned(left: X)                 → PositionedDirectional(start: X)
  * Positioned(right: X)                → PositionedDirectional(end: X)
  * TextAlign.left                      → TextAlign.start
  * TextAlign.right                     → TextAlign.end

Modes:
  default      Emit JSON report at reports/i18n_rtl_audit.json with
               {file, line, snippet, suggested_replacement, status: "review"}
  --apply      Auto-apply all candidates EXCEPT files annotated `// rtl-keep`
               on the line.

Some cases legitimately stay LTR (chart axes, brand logos, image-anchored
badges). Annotate the line with `// rtl-keep` to opt out.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LIB_ROOT = REPO_ROOT / "mobile" / "flutter" / "lib"
REPORTS_DIR = REPO_ROOT / "reports"

EXCLUDE_DIR_PARTS = {"_backup_pre_redesign", "generated", "l10n"}
EXCLUDE_EXT_SUFFIXES = {".g.dart", ".freezed.dart", ".gr.dart"}

# (regex, replacement)  — replacement is a function (re.Match)→str or a string
_MIGRATIONS = [
    (re.compile(r"\bAlignment\.centerLeft\b"),     "AlignmentDirectional.centerStart"),
    (re.compile(r"\bAlignment\.topLeft\b"),        "AlignmentDirectional.topStart"),
    (re.compile(r"\bAlignment\.bottomLeft\b"),     "AlignmentDirectional.bottomStart"),
    (re.compile(r"\bAlignment\.centerRight\b"),    "AlignmentDirectional.centerEnd"),
    (re.compile(r"\bAlignment\.topRight\b"),       "AlignmentDirectional.topEnd"),
    (re.compile(r"\bAlignment\.bottomRight\b"),    "AlignmentDirectional.bottomEnd"),
    (re.compile(r"\bTextAlign\.left\b"),           "TextAlign.start"),
    (re.compile(r"\bTextAlign\.right\b"),          "TextAlign.end"),
]

# EdgeInsets.only — special-case because we need to rewrite the named arg too
_EDGE_INSETS_ONLY = re.compile(
    r"\bEdgeInsets\.only\(\s*((?:(?:left|right|top|bottom)\s*:\s*[^,)]+,?\s*)+)\)"
)
_LEFT_ARG = re.compile(r"\bleft\s*:")
_RIGHT_ARG = re.compile(r"\bright\s*:")

# Positioned( ... left|right: ...)
_POSITIONED = re.compile(r"\bPositioned\(\s*(.*?)\s*\)", re.DOTALL)


def _enumerate_dart_files():
    for f in LIB_ROOT.rglob("*.dart"):
        rel = f.relative_to(REPO_ROOT)
        if any(part in str(rel) for part in EXCLUDE_DIR_PARTS):
            continue
        if any(str(f).endswith(ext) for ext in EXCLUDE_EXT_SUFFIXES):
            continue
        yield f


def _scan_file(path: Path) -> list[dict]:
    findings: list[dict] = []
    with path.open(encoding="utf-8") as f:
        text = f.read()

    line_offsets = [0]
    for i, ch in enumerate(text):
        if ch == "\n":
            line_offsets.append(i + 1)

    def pos_to_line(pos: int) -> int:
        lo, hi = 0, len(line_offsets) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if line_offsets[mid] <= pos:
                lo = mid
            else:
                hi = mid - 1
        return lo + 1

    def line_text(line_no: int) -> str:
        start = line_offsets[line_no - 1]
        end = line_offsets[line_no] - 1 if line_no < len(line_offsets) else len(text)
        return text[start:end]

    def has_keep_annotation(line_no: int) -> bool:
        return "rtl-keep" in line_text(line_no)

    # Simple regex migrations
    for pat, replacement in _MIGRATIONS:
        for m in pat.finditer(text):
            line = pos_to_line(m.start())
            if has_keep_annotation(line):
                continue
            findings.append({
                "file": str(path.relative_to(REPO_ROOT)),
                "line": line,
                "old": m.group(0),
                "new": replacement,
                "kind": "simple",
            })

    # EdgeInsets.only with left or right
    for m in _EDGE_INSETS_ONLY.finditer(text):
        args_text = m.group(1)
        has_left = bool(_LEFT_ARG.search(args_text))
        has_right = bool(_RIGHT_ARG.search(args_text))
        if not (has_left or has_right):
            continue
        line = pos_to_line(m.start())
        if has_keep_annotation(line):
            continue
        new_args = args_text
        new_args = _LEFT_ARG.sub("start:", new_args)
        new_args = _RIGHT_ARG.sub("end:", new_args)
        new_call = f"EdgeInsetsDirectional.only({new_args})"
        findings.append({
            "file": str(path.relative_to(REPO_ROOT)),
            "line": line,
            "old": m.group(0),
            "new": new_call,
            "kind": "edgeinsets",
        })

    # EdgeInsets.fromLTRB  → only flag if L != R (different values mean
    # asymmetric layout — RTL-flip-sensitive)
    for m in re.finditer(
        r"\bEdgeInsets\.fromLTRB\(\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)", text
    ):
        left, top, right, bottom = m.group(1), m.group(2), m.group(3), m.group(4)
        if left.strip() == right.strip():
            continue  # symmetric — direction-agnostic
        line = pos_to_line(m.start())
        if has_keep_annotation(line):
            continue
        new_call = f"EdgeInsetsDirectional.fromSTEB({left.strip()}, {top.strip()}, {right.strip()}, {bottom.strip()})"
        findings.append({
            "file": str(path.relative_to(REPO_ROOT)),
            "line": line,
            "old": m.group(0),
            "new": new_call,
            "kind": "edgeinsets_ltrb",
        })

    # Positioned( ... left: / right: ...)
    for m in _POSITIONED.finditer(text):
        args_text = m.group(1)
        if not (_LEFT_ARG.search(args_text) or _RIGHT_ARG.search(args_text)):
            continue
        line = pos_to_line(m.start())
        if has_keep_annotation(line):
            continue
        new_args = _LEFT_ARG.sub("start:", args_text)
        new_args = _RIGHT_ARG.sub("end:", new_args)
        new_call = f"PositionedDirectional({new_args})"
        findings.append({
            "file": str(path.relative_to(REPO_ROOT)),
            "line": line,
            "old": m.group(0)[:150],
            "new": new_call[:150],
            "kind": "positioned",
        })

    return findings


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    REPORTS_DIR.mkdir(exist_ok=True)
    all_findings: list[dict] = []
    files = list(_enumerate_dart_files())
    print(f"Scanning {len(files)} Dart files…", file=sys.stderr)

    for f in files:
        try:
            all_findings.extend(_scan_file(f))
        except Exception as e:
            print(f"⚠️  scan failed on {f}: {e}", file=sys.stderr)

    if not args.apply:
        out = REPORTS_DIR / "i18n_rtl_audit.json"
        out.write_text(json.dumps(all_findings, ensure_ascii=False, indent=2))
        kinds = {}
        for f in all_findings:
            kinds[f["kind"]] = kinds.get(f["kind"], 0) + 1
        print(f"\n=== RTL audit ===")
        print(f"  total candidates: {len(all_findings)}")
        for k, n in sorted(kinds.items(), key=lambda x: -x[1]):
            print(f"    {k:18s} {n}")
        print(f"\nReport: {out}")
        print(f"\nNext: review report, annotate `// rtl-keep` on lines that "
              f"legitimately stay LTR (charts, brand logos), then run "
              f"`python3 scripts/i18n_rtl_audit.py --apply`")
        return 0

    # --apply mode — rewrite files
    # Group findings by file
    by_file: dict[str, list[dict]] = {}
    for f in all_findings:
        by_file.setdefault(f["file"], []).append(f)

    modified = 0
    for rel, findings in by_file.items():
        path = REPO_ROOT / rel
        with path.open(encoding="utf-8") as f:
            text = f.read()
        new_text = text
        for f_d in findings:
            new_text = new_text.replace(f_d["old"], f_d["new"], 1)
        if new_text != text:
            with path.open("w", encoding="utf-8") as f:
                f.write(new_text)
            modified += 1
            print(f"  ✓ {rel}: {len(findings)} migration(s)", file=sys.stderr)
    print(f"\n✓ RTL audit applied across {modified} files.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
