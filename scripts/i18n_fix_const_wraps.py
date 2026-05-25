#!/usr/bin/env python3
"""
i18n_fix_const_wraps.py — strip `const ` from any constructor call whose
argument list contains an AppLocalizations.of(context) reference.

Reason: `const Foo(...)` requires ALL args to be const expressions. The
migration tool replaced literal strings with `AppLocalizations.of(context).key`
calls (not const), but didn't always strip the outer `const`. This fixer
walks every dart file, finds `const <Ident>(...)` constructs by balanced
parens, checks if the body contains AppLocalizations.of(, and drops `const`.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIB = REPO / "mobile" / "flutter" / "lib"

CONST_CTOR_RE = re.compile(r"\bconst\s+([A-Z][A-Za-z0-9_]*)\s*\(")


def find_balanced(text: str, open_idx: int) -> int:
    """Given index of '(', return index of matching ')'. Returns -1 if unbalanced.
    Tracks string literals (single, double, triple, raw, dollar-interpolation curly
    counts) so parens inside strings don't confuse balance.
    """
    i = open_idx
    n = len(text)
    depth = 0
    in_str = None  # None | "'" | '"' | "'''" | '"""'
    i = open_idx
    while i < n:
        c = text[i]
        if in_str is None:
            # Check for triple-quote opener
            if i + 2 < n and (text[i:i+3] == "'''" or text[i:i+3] == '"""'):
                in_str = text[i:i+3]
                i += 3
                continue
            if c == '"' or c == "'":
                in_str = c
                i += 1
                continue
            if c == '/' and i + 1 < n and text[i+1] == '/':
                # line comment — skip to end of line
                nl = text.find('\n', i)
                i = n if nl == -1 else nl
                continue
            if c == '/' and i + 1 < n and text[i+1] == '*':
                # block comment
                end = text.find('*/', i+2)
                i = n if end == -1 else end + 2
                continue
            if c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0:
                    return i
            i += 1
        else:
            # Inside string
            if c == '\\' and i + 1 < n:
                i += 2  # skip escaped char
                continue
            # Closing
            if len(in_str) == 3 and text[i:i+3] == in_str:
                i += 3
                in_str = None
                continue
            if len(in_str) == 1 and c == in_str:
                i += 1
                in_str = None
                continue
            # Dollar-curly interpolation — track nested parens? we don't go that deep,
            # we just skip { ... } matched braces inside string.
            if c == '$' and i + 1 < n and text[i+1] == '{':
                # find matching } accounting for nesting
                bdepth = 1
                j = i + 2
                while j < n and bdepth > 0:
                    if text[j] == '{': bdepth += 1
                    elif text[j] == '}': bdepth -= 1
                    j += 1
                i = j
                continue
            i += 1
    return -1


def fix_file(path: Path) -> int:
    text = path.read_text()
    # Iterate from rightmost match leftward so indices stay valid as we edit.
    matches = list(CONST_CTOR_RE.finditer(text))
    if not matches:
        return 0
    edits = []  # list of (start_of_const, end_of_const_keyword)
    for m in matches:
        const_start = m.start()
        open_paren = m.end() - 1  # index of '('
        close_paren = find_balanced(text, open_paren)
        if close_paren == -1:
            continue
        body = text[open_paren+1:close_paren]
        if "AppLocalizations.of(" not in body:
            continue
        # Compute the slice to delete: "const " (including trailing whitespace
        # up to the type name). m.group(0) starts with "const " optionally
        # followed by extra whitespace. We want to drop "const" + the single
        # space/whitespace following it.
        # m.start() = position of 'c' in 'const'
        # We need to keep everything from the type identifier onward.
        type_pos = m.start(1)
        edits.append((const_start, type_pos))

    if not edits:
        return 0

    # Apply edits from rightmost to leftmost
    new_text = text
    for start, end in sorted(edits, key=lambda x: -x[0]):
        new_text = new_text[:start] + new_text[end:]

    path.write_text(new_text)
    return len(edits)


def main() -> int:
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    files = []
    for sub in ("screens", "widgets"):
        files.extend((LIB / sub).rglob("*.dart"))

    total_files_changed = 0
    total_edits = 0
    for f in files:
        if "/generated/" in str(f) or "/l10n/" in str(f): continue
        if str(f).endswith((".g.dart", ".freezed.dart", ".gr.dart")): continue
        if args.dry_run:
            # count without writing
            text = f.read_text()
            matches = list(CONST_CTOR_RE.finditer(text))
            count = 0
            for m in matches:
                close = find_balanced(text, m.end() - 1)
                if close == -1: continue
                if "AppLocalizations.of(" in text[m.end():close]:
                    count += 1
            if count:
                total_files_changed += 1
                total_edits += count
        else:
            n = fix_file(f)
            if n:
                total_files_changed += 1
                total_edits += n

    print(f"{'WOULD FIX' if args.dry_run else 'FIXED'}: {total_edits} const-wraps in {total_files_changed} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
