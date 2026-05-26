#!/usr/bin/env python3
"""
i18n_migrate_screen.py — per-file Dart literal extractor + applier.

Handles the 60+ edge cases catalogued in the plan
(~/.claude/plans/there-is-a-post-dazzling-giraffe.md). Conservative by
default: anything ambiguous falls into COMPLEX (manual review) rather than
auto-migrate. False positives at this scale corrupt files; false negatives
just defer work.

Modes
-----
  --out keys  (default)   Emit JSON change-set to stdout. No file writes.
  --apply                 Apply replacements in-place + add AppLocalizations
                          import if missing. Idempotent — already-migrated
                          callsites left untouched.
  --vocab <path>          Use shared vocabulary (default scripts/i18n_vocab.json)
                          to collapse duplicate values onto existing keys.

Output JSON shape (--out keys):
  {
    "file": "lib/screens/foo.dart",
    "new_keys": {"fooBar": "Bar text", ...},
    "reused_keys": {"buttonCancel": "Cancel", ...},
    "icu_pending": [{"line": N, "col": M, "string": "Hello $name"}, ...],
    "complex_pending": [{"line": N, "col": M, "string": "...", "reason": "..."},
                        ...],
    "replacements": [{"line": N, "col": M, "old": "Text('foo')",
                      "new": "Text(AppLocalizations.of(context).fooBar)"}, ...],
    "needs_import": true,
    "skipped_count": 142
  }

Usage (per plan Phase 4):
  python3 scripts/i18n_migrate_screen.py lib/screens/foo.dart > /tmp/foo.json
  python3 scripts/i18n_migrate_screen.py --apply lib/screens/foo.dart
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parent.parent
FLUTTER_ROOT = REPO_ROOT / "mobile" / "flutter"
L10N_DIR = FLUTTER_ROOT / "lib" / "l10n"
EN_ARB = L10N_DIR / "app_en.arb"
DEFAULT_VOCAB = REPO_ROOT / "scripts" / "i18n_vocab.json"

# ─── Patterns ────────────────────────────────────────────────────────────────

# Match a Dart string literal in either ' or " quotes, single-line, with escape
# support. Not concerned with multi-line raw triple-quoted here; those go to
# COMPLEX.
_STRING_LITERAL = re.compile(
    r"""
    (?P<full>
      (?P<quote>['"])
      (?P<body>(?:\\.|(?!(?P=quote)).)*?)
      (?P=quote)
    )
    """,
    re.VERBOSE,
)

# Triple-quoted multi-line — flag as COMPLEX (needs manual ICU translation
# decision per-case).
_TRIPLE_QUOTED = re.compile(r"""(?:r?'''[\s\S]*?'''|r?\"\"\"[\s\S]*?\"\"\")""")

# Raw string `r'...'` — usually a regex pattern, always SKIP.
_RAW_STRING_RE = re.compile(r"""r(?P<quote>['"])(?P<body>.*?)(?P=quote)""")

# Migratable contexts: `Text(`, `title:`, `hint:`, `label:`, `hintText:`,
# `labelText:`, `helperText:`, `errorText:`, `tooltip:`, `semanticLabel:`.
# The pattern matches the context name + a literal that follows (possibly
# with `const` interposed).
_CONTEXT_PATTERNS = [
    # Text(...)
    (re.compile(r"\bText\s*\(\s*(?:const\s+)?"), "Text"),
    # AlertDialog.title: Text('...'), SnackBar.content: Text('...')
    (re.compile(r"\b(title|content|subtitle)\s*:\s*(?:const\s+)?Text\s*\(\s*(?:const\s+)?"), "TextNamedArg"),
    # title: 'string' (no Text() wrapper — direct String value on a named arg)
    (re.compile(r"\b(title|hint|label|hintText|labelText|helperText|errorText|tooltip|semanticLabel)\s*:\s*"), "DirectStringArg"),
    # IconButton(tooltip: '...')
    (re.compile(r"\btooltip\s*:\s*"), "Tooltip"),
    # Semantics(label: '...')
    (re.compile(r"\bSemantics\s*\([^)]*\blabel\s*:\s*"), "Semantics"),
]

# SKIP contexts (literal appears immediately AFTER one of these):
_SKIP_CONTEXTS = re.compile(
    r"""\b(
        print|debugPrint|logger\.\w+|assert|throw|Sentry\.\w+|
        Key|ValueKey|GlobalKey|UniqueKey|PageStorageKey|
        Hero|Image\.asset|AssetImage|FileImage|NetworkImage|
        Lottie\.asset|SvgPicture\.asset|Lottie\.network|
        RegExp|DateFormat|NumberFormat|Locale|
        Color|Colors|TextStyle|FontFamily|
        Uri|Uri\.parse|context\.push|context\.go|context\.replace|
        Navigator\.pushNamed|Navigator\.pushReplacementNamed|
        \.toJson|\.fromJson|jsonDecode|jsonEncode|
        prefs\.\w+|SharedPreferences\.|
        analytics\.\w+|Analytics\.\w+|track|trackEvent|
        capture|posthog\.\w+|
        Intl\.message|
        Platform\.is\w+
    )\s*\(""",
    re.VERBOSE,
)

# Heuristics for SKIP non-user-text strings.
_ASSET_PATH_RE = re.compile(r"^assets/")
_ROUTE_PATH_RE = re.compile(r"^/[a-z0-9_\-/$\{\}]*$")
_FILE_EXT_RE = re.compile(r"^\.(png|jpg|jpeg|svg|webp|json|mp3|mp4|m4a|webm|gif|pdf|lottie)$")
_MIME_RE = re.compile(r"^[a-z]+/[a-z0-9+.-]+$")
_LOCALE_RE = re.compile(r"^[a-z]{2,3}(_[A-Z]{2}|-[A-Z][a-z]{3})?$")
_DATE_FORMAT_RE = re.compile(r"^[yMdHmsaEZ\-:/. ]+$")
_SHORT_IDENT_RE = re.compile(r"^[A-Z][A-Z0-9_]{0,4}$")  # IP, URL, ID, HRV — but allow AI override below
_PURE_NUMBER_RE = re.compile(r"^-?\d+(\.\d+)?$")
_DEEP_LINK_RE = re.compile(r"^[a-z][a-z0-9]+://")
_SNAKE_CASE_IDENT_RE = re.compile(r"^[a-z][a-z0-9_]*$")  # likely a key/identifier
_HEX_COLOR_RE = re.compile(r"^#[0-9A-Fa-f]{3,8}$")

# Strings allowed even though they match SHORT_IDENT regex (visible to user).
_SHORT_IDENT_ALLOWLIST = {"AI", "PR", "OK", "GO"}

# Interpolation markers — emit ICU instead of MIGRATE.
# Matches: `$identifier`, `${anything}`, or trailing `${` (which signals the
# regex caught a truncated literal because of nested quotes inside interpolation).
_INTERPOLATION_RE = re.compile(r"\$\{|\$[a-zA-Z_][a-zA-Z0-9_.]*")

# Operator-trail detector — if the captured body ends with one of these, the
# closing quote was probably inside an interpolation expression (`${a ?? '...'}`)
# and the lexer captured a partial. Mark COMPLEX.
_TRUNCATION_TAIL = re.compile(r"(?:\?\?|\|\||&&|[+\-*/<>=])\s*$")

# Excluded files / dirs.
_EXCLUDE_PATH_PARTS = {"_backup_pre_redesign", ".g.dart", ".freezed.dart", ".gr.dart", "generated"}


@dataclass
class Finding:
    line: int
    col: int
    full_match: str       # the entire literal text incl. quotes
    body: str             # the contents (no quotes)
    context_kind: str     # MIGRATE | ICU | SKIP | COMPLEX
    reason: str = ""      # human-readable explanation
    suggested_key: str = ""
    suggested_replacement: str = ""


@dataclass
class FileReport:
    file: str
    new_keys: dict[str, str] = field(default_factory=dict)
    reused_keys: dict[str, str] = field(default_factory=dict)
    icu_pending: list[dict] = field(default_factory=list)
    complex_pending: list[dict] = field(default_factory=list)
    replacements: list[dict] = field(default_factory=list)
    needs_import: bool = False
    skipped_count: int = 0


def _load_vocab(vocab_path: Path) -> dict[str, str]:
    """Load {english_value_normalized: key_name} map. Built from app_en.arb +
    any prior vocab cache."""
    out: dict[str, str] = {}
    if EN_ARB.exists():
        try:
            with EN_ARB.open() as f:
                data = json.load(f)
            for k, v in data.items():
                if k.startswith("@") or not isinstance(v, str):
                    continue
                out[_normalize_value(v)] = k
        except Exception:
            pass
    if vocab_path.exists():
        try:
            with vocab_path.open() as f:
                cache = json.load(f)
            out.update({_normalize_value(k): v for k, v in cache.items()})
        except Exception:
            pass
    return out


def _normalize_value(s: str) -> str:
    """Normalize for vocab lookup — strip leading/trailing whitespace, collapse
    inner whitespace, no case folding (case carries meaning in labels)."""
    return re.sub(r"\s+", " ", s.strip())


def _camelize(text: str, prefix: str = "") -> str:
    """Build a camelCase key from a text snippet."""
    words = re.findall(r"[a-zA-Z0-9]+", text)
    if not words:
        return prefix or "key"
    if prefix:
        return prefix + "".join(w.capitalize() for w in words[:4])
    head, *tail = words[:4]
    return head.lower() + "".join(w.capitalize() for w in tail)


def _file_scope_prefix(path: Path) -> str:
    """Derive a camelCase prefix from the file name."""
    stem = path.stem
    # Strip common Dart suffixes
    stem = re.sub(r"_(screen|page|widget|sheet|dialog|tab|view|section)$", "", stem)
    parts = stem.split("_")
    if not parts:
        return "key"
    head, *tail = parts[:3]
    return head + "".join(p.capitalize() for p in tail if p)


_PLACEHOLDER_RE = re.compile(r"\{[^{}]+\}")


def _camel_words(name: str) -> list[str]:
    """`unifiedHomeWidgets` → ['unified','home','widgets']. Lowercase, no separators."""
    s = re.sub(r"([A-Z])", r" \1", name)
    return [w.lower() for w in s.split() if w]


def _strip_namespace_pollution(body: str, prefix: str) -> str:
    """Return `body` with a duplicated namespace prefix stripped, if shape matches.

    Detects the failure mode where ``body`` is the kebab-cased humanization of
    the camelCase namespace prefix + the meaningful suffix (e.g. body=
    ``"Unified home widgets wake hydration"`` with prefix=``"unifiedHomeWidgets"``
    leaves only ``"Wake hydration"``).

    Non-polluted bodies are returned unchanged. Bodies whose leading words
    only partially match the prefix are returned unchanged — we strip
    conservatively only when the full prefix is present at the start.
    """
    if not body or not prefix:
        return body
    prefix_words = _camel_words(prefix)
    if len(prefix_words) < 2:
        return body
    # Walk through body words checking prefix overlap; placeholders/punct
    # don't move the cursor. Keep the trailing remainder intact.
    parts = body.split()
    if len(parts) < len(prefix_words):
        return body
    leading_lower = [_PLACEHOLDER_RE.sub("", p).strip(",.;:!?'\"()").lower()
                     for p in parts[:len(prefix_words)]]
    if leading_lower != prefix_words:
        return body
    remainder = parts[len(prefix_words):]
    if not remainder:
        return body  # nothing left after stripping — don't blank the value
    cleaned = " ".join(remainder).strip()
    if not cleaned:
        return body
    return cleaned[0].upper() + cleaned[1:]


def _is_skippable_value(body: str) -> tuple[bool, str]:
    """Return (skip, reason)."""
    if len(body) < 2:
        return True, "too_short"
    if body.strip() == "":
        return True, "whitespace_only"
    if _ASSET_PATH_RE.match(body):
        return True, "asset_path"
    if _ROUTE_PATH_RE.match(body) and "/" in body:
        return True, "route_path"
    if _FILE_EXT_RE.match(body):
        return True, "file_ext"
    if _MIME_RE.match(body):
        return True, "mime_type"
    if _LOCALE_RE.match(body) and len(body) <= 7:
        return True, "locale_code"
    if _DATE_FORMAT_RE.match(body) and any(c in body for c in "yMdHms"):
        return True, "date_format"
    if _DEEP_LINK_RE.match(body):
        return True, "deep_link"
    if _HEX_COLOR_RE.match(body):
        return True, "hex_color"
    if _PURE_NUMBER_RE.match(body):
        return True, "pure_number"
    if _SHORT_IDENT_RE.match(body) and body not in _SHORT_IDENT_ALLOWLIST:
        return True, "short_identifier"
    if _SNAKE_CASE_IDENT_RE.match(body) and len(body) <= 30 and " " not in body:
        # Likely a programmatic key (snake_case_ident). User-facing strings
        # almost always contain spaces or proper capitalization.
        return True, "snake_case_identifier"
    # Pure punctuation / symbols
    if not re.search(r"[A-Za-zÀ-￿]", body):
        return True, "no_letters"
    return False, ""


def _line_is_comment_or_debug(line: str) -> bool:
    """Return True if the line starts (post-indent) with `//`, `///`, or is
    inside a known debug context."""
    stripped = line.lstrip()
    if stripped.startswith("//") or stripped.startswith("///"):
        return True
    # The full-line check for debug context — finer-grained by-position done elsewhere
    return False


def _within_debug_context(source: str, pos: int) -> bool:
    """Walk back from `pos` looking for `print(`, `debugPrint(`, `logger.X(`,
    `assert(`, `Sentry.X(` that opens an unclosed paren containing `pos`."""
    # Quick check: find the nearest unmatched `(` going backwards
    paren_depth = 0
    i = pos - 1
    while i >= 0:
        ch = source[i]
        if ch == ")":
            paren_depth += 1
        elif ch == "(":
            if paren_depth == 0:
                # Found enclosing `(` — check what precedes it
                before = source[max(0, i - 40):i]
                if _SKIP_CONTEXTS.search(before + "("):
                    return True
                return False
            paren_depth -= 1
        i -= 1
    return False


def _within_dart_comment_block(source: str, pos: int) -> bool:
    """Return True if `pos` lies inside a `/* ... */` block."""
    # Find last `/*` and `*/` before pos
    last_open = source.rfind("/*", 0, pos)
    last_close = source.rfind("*/", 0, pos)
    return last_open > last_close


def _detect_context_kind(source: str, match: re.Match) -> tuple[str, str]:
    """Look at what immediately precedes the literal to classify the context."""
    pos = match.start()
    body = match.group("body")

    # Check ICU first — interpolation in the body itself.
    # `${` always wins, even truncated, since real ICU/manual handling is required.
    if _INTERPOLATION_RE.search(body):
        return "ICU", "interpolation"

    # Detect truncated capture from nested-quote interpolation (lexer limitation).
    # E.g. body `Remove ${c.label ?? c.category ?? ` — regex stopped at the `'`
    # inside `'equipment'`. Mark COMPLEX so a human handles it.
    if _TRUNCATION_TAIL.search(body):
        return "COMPLEX", "lexer_truncation_likely"

    # Detect adjacent-string concatenation (Dart `'A' 'B'` → `'AB'`).
    # If body ends in whitespace AND the next non-whitespace char in source is
    # a quote, this is half of a multi-string literal — flag COMPLEX.
    if body.endswith(" ") or body.endswith("\\n"):
        after_pos = match.end()
        rest = source[after_pos:after_pos + 50].lstrip()
        if rest.startswith(("'", '"')):
            return "COMPLEX", "adjacent_string_concat"

    # Triple-quoted handled separately by caller — assume here it's single-line

    # Check line-level comment
    line_start = source.rfind("\n", 0, pos) + 1
    line_text = source[line_start:source.find("\n", pos) if source.find("\n", pos) != -1 else len(source)]
    line_before_match = source[line_start:pos]
    if "//" in line_before_match:
        # Literal is inside a `// ...` line comment
        return "SKIP", "line_comment"

    if _within_dart_comment_block(source, pos):
        return "SKIP", "block_comment"

    if _within_debug_context(source, pos):
        return "SKIP", "debug_context"

    # SKIP value-only checks (asset paths etc.)
    skip, reason = _is_skippable_value(body)
    if skip:
        return "SKIP", reason

    # Look at 40 chars before the match for context patterns
    before = source[max(0, pos - 80):pos]

    # SKIP if the literal is a function arg to a known SKIP function
    if _SKIP_CONTEXTS.search(before + "("):
        return "SKIP", "skip_context"

    # Check MIGRATE contexts
    for pat, kind in _CONTEXT_PATTERNS:
        if pat.search(before):
            return "MIGRATE", kind

    # If the literal is in a list or const constructor without a recognized
    # named arg, mark COMPLEX (e.g. `final tabs = ['Daily', 'Weekly']`).
    # Heuristic: if preceded by `[` or `,` directly (after whitespace), treat
    # as list element — COMPLEX, not auto-migrate.
    last_non_ws = before.rstrip()
    if last_non_ws and last_non_ws[-1] in "[,(":
        # Could still be a Text() arg (covered above) — if we're here, the
        # context wasn't a known Text-like arg. Surface for manual.
        return "COMPLEX", "list_or_arg_no_context"

    return "SKIP", "no_recognized_context"


def _build_replacement(orig: str, key: str, kind: str) -> str:
    """Build the AppLocalizations replacement based on the context kind."""
    expr = f"AppLocalizations.of(context).{key}"
    if kind == "Text":
        # `Text('foo')` or `Text("foo")` — strip `const` if present
        # The regex captured starting at `Text(`; the original `orig` is
        # just the string literal. The replacement here is just the literal
        # expression; the surrounding `Text(...)` stays.
        return expr
    if kind in {"TextNamedArg", "DirectStringArg", "Tooltip", "Semantics"}:
        return expr
    return expr


def analyze_file(path: Path, vocab: dict[str, str]) -> Optional[FileReport]:
    """Analyze a single Dart file. Returns None if the file is excluded."""
    if any(part in str(path) for part in _EXCLUDE_PATH_PARTS):
        return None
    if not path.suffix == ".dart":
        return None
    if not path.exists():
        return None

    try:
        with path.open(encoding="utf-8") as f:
            source = f.read()
    except Exception:
        return None

    report = FileReport(file=str(path.relative_to(REPO_ROOT)))

    # Track existing AppLocalizations import
    has_import = "AppLocalizations" in source

    # First, blank out triple-quoted strings to keep the single-line lexer sane
    # (we still record their positions for COMPLEX flagging).
    triple_quoted_spans: list[tuple[int, int, str]] = []
    for m in _TRIPLE_QUOTED.finditer(source):
        body = m.group(0)
        triple_quoted_spans.append((m.start(), m.end(), body))
    masked = source
    for start, end, _body in triple_quoted_spans:
        masked = masked[:start] + (" " * (end - start)) + masked[end:]
    # Also mask raw strings
    for m in _RAW_STRING_RE.finditer(source):
        s, e = m.start(), m.end()
        masked = masked[:s] + (" " * (e - s)) + masked[e:]

    # Track line numbers
    line_offsets = [0]
    for i, ch in enumerate(source):
        if ch == "\n":
            line_offsets.append(i + 1)

    def pos_to_line_col(pos: int) -> tuple[int, int]:
        # Binary search line
        lo, hi = 0, len(line_offsets) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if line_offsets[mid] <= pos:
                lo = mid
            else:
                hi = mid - 1
        return lo + 1, pos - line_offsets[lo] + 1

    # Surface triple-quoted as COMPLEX (translator needs to preserve newlines
    # + maybe ICU placeholders).
    for start, _end, body_raw in triple_quoted_spans:
        line, col = pos_to_line_col(start)
        report.complex_pending.append({
            "line": line, "col": col,
            "string": body_raw[:200] + ("..." if len(body_raw) > 200 else ""),
            "reason": "triple_quoted_multiline",
        })

    prefix = _file_scope_prefix(path)
    used_keys_this_file: set[str] = set()

    for m in _STRING_LITERAL.finditer(masked):
        body = m.group("body")
        # Resolve escapes for display
        kind, reason = _detect_context_kind(source, m)
        line, col = pos_to_line_col(m.start())

        if kind == "SKIP":
            report.skipped_count += 1
            continue

        if kind == "ICU":
            report.icu_pending.append({
                "line": line, "col": col,
                "string": body,
            })
            continue

        if kind == "COMPLEX":
            report.complex_pending.append({
                "line": line, "col": col,
                "string": body, "reason": reason,
            })
            continue

        # MIGRATE — check vocab first
        normalized = _normalize_value(body)
        existing_key = vocab.get(normalized)
        if existing_key:
            # Reuse — already in app_en.arb (or vocab cache)
            report.reused_keys[existing_key] = body
            key = existing_key
        else:
            # Mint new key. Avoid collisions within the same file by appending
            # an integer suffix.
            base_key = _camelize(body[:30], prefix=prefix)
            key = base_key
            n = 2
            while key in used_keys_this_file or key in report.new_keys:
                key = f"{base_key}{n}"
                n += 1
            # Guard against value-equals-key-name pollution. Earlier migrations
            # landed ~430 entries where the human body string was literally the
            # kebab-cased version of the namespaced key (e.g. body was
            # "Unified home widgets wake hydration" with prefix
            # "unifiedHomeWidgets" → value duplicated the namespace). When we
            # detect that shape, strip the namespace prefix from the stored
            # value so the .arb keeps a clean English string and downstream
            # locale translators don't re-translate the redundant prefix.
            # See: scripts/i18n_clean_polluted_values.py + docs/i18n_pollution_report.md.
            stored_value = _strip_namespace_pollution(body, prefix)
            if stored_value != body:
                print(
                    f"  ⚠ namespace-pollution stripped — key={key!r} "
                    f"old={body!r} new={stored_value!r}",
                    file=sys.stderr,
                )
            report.new_keys[key] = stored_value
            vocab[normalized] = key
            used_keys_this_file.add(key)

        replacement = _build_replacement(m.group("full"), key, reason)
        report.replacements.append({
            "line": line, "col": col,
            "old": m.group("full"),
            "new": replacement,
        })

    if (report.new_keys or report.reused_keys) and not has_import:
        report.needs_import = True

    return report


def _apply_report(path: Path, report: FileReport) -> bool:
    """Apply replacements + import in-place. Returns True if file modified."""
    if not report.replacements and not report.needs_import:
        return False

    with path.open(encoding="utf-8") as f:
        source = f.read()

    # Apply replacements from end to start so positions don't shift.
    sorted_reps = sorted(
        report.replacements,
        key=lambda r: (r["line"], r["col"]),
        reverse=True,
    )
    # Convert (line, col) back to offset
    line_offsets = [0]
    for i, ch in enumerate(source):
        if ch == "\n":
            line_offsets.append(i + 1)

    def line_col_to_pos(line: int, col: int) -> int:
        return line_offsets[line - 1] + (col - 1)

    for rep in sorted_reps:
        pos = line_col_to_pos(rep["line"], rep["col"])
        old = rep["old"]
        new = rep["new"]
        # Safety: verify the source at pos matches `old`
        if source[pos:pos + len(old)] != old:
            # Source drifted (perhaps from triple-quoted masking inconsistency)
            # — skip rather than corrupt.
            continue
        source = source[:pos] + new + source[pos + len(old):]

    if report.needs_import:
        # Compute import path relative to the file
        rel_to_lib = path.parent.relative_to(FLUTTER_ROOT / "lib")
        depth = len(rel_to_lib.parts)
        rel_import = "../" * depth + "l10n/generated/app_localizations.dart"
        import_line = f"import '{rel_import}';"
        # Insert after the last existing `import` statement
        import_re = re.compile(r"^import\s+.+;\s*$", re.MULTILINE)
        matches = list(import_re.finditer(source))
        if matches:
            last = matches[-1]
            source = source[:last.end()] + "\n" + import_line + source[last.end():]
        else:
            # No imports — prepend at top (after any leading comments)
            source = import_line + "\n" + source

    with path.open("w", encoding="utf-8") as f:
        f.write(source)
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("file", help="Dart file path (relative to repo root)")
    ap.add_argument("--apply", action="store_true",
                    help="Write replacements in-place + add import")
    ap.add_argument("--vocab", type=Path, default=DEFAULT_VOCAB,
                    help="Vocabulary cache path")
    args = ap.parse_args()

    path = Path(args.file).resolve()
    if not str(path).startswith(str(REPO_ROOT)):
        print(f"❌ {path} not inside repo {REPO_ROOT}", file=sys.stderr)
        return 1

    vocab = _load_vocab(args.vocab)
    report = analyze_file(path, vocab)
    if report is None:
        print(f"⚠️  {path} excluded (generated / backup / wrong ext)", file=sys.stderr)
        return 0

    if args.apply:
        modified = _apply_report(path, report)
        print(f"{'✓' if modified else ' '} {report.file}: "
              f"{len(report.replacements)} replacements, "
              f"{len(report.new_keys)} new keys, "
              f"{len(report.reused_keys)} reused, "
              f"{len(report.icu_pending)} ICU, "
              f"{len(report.complex_pending)} complex, "
              f"{report.skipped_count} skipped",
              file=sys.stderr)
        # Persist updated vocab so other files reuse keys we just minted
        try:
            args.vocab.parent.mkdir(parents=True, exist_ok=True)
            with args.vocab.open("w") as f:
                json.dump(
                    {v: k for k, v in vocab.items()},  # value: key
                    f, ensure_ascii=False, indent=2, sort_keys=True,
                )
        except Exception:
            pass
        return 0

    # --out keys mode — emit JSON
    out = {
        "file": report.file,
        "new_keys": report.new_keys,
        "reused_keys": report.reused_keys,
        "icu_pending": report.icu_pending,
        "complex_pending": report.complex_pending,
        "replacements": report.replacements,
        "needs_import": report.needs_import,
        "skipped_count": report.skipped_count,
    }
    json.dump(out, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
