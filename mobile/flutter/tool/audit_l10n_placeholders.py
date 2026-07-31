#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Regression gate for E2E row 22 — literal widget-slot placeholders in l10n.

The i18n migration (commit e8ede3fc) extracted widget copy into ARB keys by
walking the widget tree. For a handful of `Text(...)` children the extractor
emitted the *slot name* it inferred ("Title", "Subtitle") instead of the source
string literal, and those placeholders shipped: the Quick Workout sheet's
header literally read "Title / Subtitle" on device.

This gate fails when an ARB value is a bare widget-slot placeholder AND the key
is used at a heading/subtitle call site. Legitimate one-word field labels
("Notes", "Details", "Name", "Description") are unaffected — they are only
flagged when the value is one of the slot words that no real UI ever displays.

Usage:
    python3 mobile/flutter/tool/audit_l10n_placeholders.py --check
"""
import argparse
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FLUTTER_ROOT = os.path.dirname(HERE)
TEMPLATE_ARB = os.path.join(FLUTTER_ROOT, 'lib', 'l10n', 'app_en.arb')
LIB = os.path.join(FLUTTER_ROOT, 'lib')

# Values no shipping UI ever legitimately renders — they are the *name of the
# slot*, not copy. Deliberately narrow: "Notes"/"Details"/"Name"/"Description"
# are real labels somewhere in this app and are NOT listed.
SLOT_WORDS = {
    'title', 'subtitle', 'sub-title', 'subhead', 'subheading',
    'heading', 'placeholder', 'body text', 'lorem ipsum', 'todo', 'tbd',
    'fixme', 'xxx', 'dummy', 'sample text', 'string',
}
SUBSTRING_MARKERS = ('lorem ipsum', 'todo:', 'fixme', 'placeholder text')


def load_template():
    with io.open(TEMPLATE_ARB, encoding='utf-8') as f:
        return json.load(f)


def dart_sources():
    for root, _dirs, files in os.walk(LIB):
        if os.sep + 'l10n' + os.sep in root + os.sep:
            continue
        for name in files:
            if name.endswith('.dart'):
                yield os.path.join(root, name)


# A one-word slot value IS legitimate copy when it labels a form field —
# `TextField(labelText: l.challengeCreateFieldTitle)` really should read
# "Title". Only headline/subtitle call sites are a defect.
FORM_LABEL_MARKERS = (
    'labeltext:', 'hinttext:', 'helpertext:', 'label:', 'hint:',
    'placeholder:', 'labelstyle', 'inputdecoration',
)


def split_top_level_args(raw):
    """Split a Dart call's argument-list source on top-level commas only
    (ignores commas nested inside parens/brackets/braces or string literals)."""
    args = []
    depth = 0
    current = []
    in_string = None
    i = 0
    while i < len(raw):
        ch = raw[i]
        if in_string:
            current.append(ch)
            if ch == '\\':
                i += 1
                if i < len(raw):
                    current.append(raw[i])
            elif ch == in_string:
                in_string = None
        elif ch in ("'", '"'):
            in_string = ch
            current.append(ch)
        elif ch in '([{':
            depth += 1
            current.append(ch)
        elif ch in ')]}':
            depth -= 1
            current.append(ch)
        elif ch == ',' and depth == 0:
            args.append(''.join(current))
            current = []
        else:
            current.append(ch)
        i += 1
    tail = ''.join(current).strip()
    if tail:
        args.append(tail)
    return [a.strip() for a in args]


# Keys whose `{unit}` placeholder must be fed by
# `WeightUtils.workoutUnitLabel(useKg)` — i.e. the WORKOUT-WEIGHT unit
# ('kg'/'lb'), not some other unit family. `{unit}` alone is not a reliable
# signal: the app has ~15 pre-existing, unrelated `unit` placeholders (body
# measurement units, work-rate units, PR record units — e.g.
# `aiCoachReportCardMin(unit)`, `measurementsTabValue(unit)`,
# `recordAttemptDialogAdd(_capitalize(widget.unit.fullLabel))`) that
# correctly pass a locally-scoped `unit` value with no relation to this bug
# class. Scoping to this explicit registry avoids false-positiving on those.
# Add a key here whenever a NEW ARB message gets a workout-weight `{unit}`
# placeholder (mirrors register row #18 / E2E #18: summaryBestSet,
# summaryEst1RM, workoutSummaryGeneralLbXReps all baked a literal "lb" into
# every locale until fixed).
WEIGHT_UNIT_KEYS = {
    'summaryBestSet',
    'summaryEst1RM',
    'workoutSummaryGeneralLbXReps',
}


def check_unit_placeholder_ordering():
    """Regression gate for register row #100's bug CLASS: `flutter gen_l10n`
    emits positional constructor params in ALPHABETICAL placeholder order,
    not the order they appear in the message text. A `{unit}` placeholder is
    the highest-risk shape — it is usually bolted onto an existing key later
    (see summaryBestSet/summaryEst1RM/workoutSummaryGeneralLbXReps, E2E #18),
    which silently reshuffles every other positional argument at every call
    site. This walks every ARB key in WEIGHT_UNIT_KEYS, reads its REAL
    position out of the generated (alphabetical) method signature, and
    asserts every call site passes `WeightUtils.workoutUnitLabel(...)` in
    that exact slot — not wherever it would fall in message-text order.
    """
    arb = load_template()
    gen_path = os.path.join(FLUTTER_ROOT, 'lib', 'l10n', 'generated', 'app_localizations.dart')
    with io.open(gen_path, encoding='utf-8') as f:
        gen_src = f.read()

    unit_keys = []
    for key, value in arb.items():
        if key.startswith('@') or not isinstance(value, str):
            continue
        if key not in WEIGHT_UNIT_KEYS:
            continue
        meta = arb.get('@' + key, {})
        placeholders = meta.get('placeholders', {}) if isinstance(meta, dict) else {}
        if 'unit' in placeholders:
            unit_keys.append(key)

    missing = WEIGHT_UNIT_KEYS - set(unit_keys)
    findings = [(k, None, 'in WEIGHT_UNIT_KEYS but has no `unit` placeholder in the ARB — '
                 'stale registry entry?') for k in sorted(missing)]
    for key in unit_keys:
        sig_m = re.search(r'String %s\(([^;]*?)\);' % re.escape(key), gen_src, re.DOTALL)
        if not sig_m:
            findings.append((key, None, 'signature not found in generated code'))
            continue
        params = [p.strip() for p in sig_m.group(1).split(',') if p.strip()]
        param_names = [p.split()[-1] for p in params]
        if 'unit' not in param_names:
            findings.append((key, None, 'unit not in generated signature'))
            continue
        unit_index = param_names.index('unit')

        call_pat = re.compile(r'\.%s\(' % re.escape(key))
        for path in dart_sources():
            with io.open(path, encoding='utf-8', errors='replace') as f:
                src = f.read()
            for m in call_pat.finditer(src):
                # Walk forward from the opening '(' to find its matching ')'.
                start = m.end()
                depth = 1
                j = start
                while j < len(src) and depth > 0:
                    if src[j] == '(':
                        depth += 1
                    elif src[j] == ')':
                        depth -= 1
                    j += 1
                args_raw = src[start:j - 1]
                args = split_top_level_args(args_raw)
                if len(args) != len(param_names):
                    continue
                actual = args[unit_index]
                if 'workoutUnitLabel' not in actual:
                    line_no = src.count('\n', 0, start) + 1
                    findings.append((
                        key,
                        '%s:%d' % (os.path.relpath(path, FLUTTER_ROOT), line_no),
                        'positional arg #%d (the "unit" slot) is %r — expected '
                        'WeightUtils.workoutUnitLabel(...)' % (unit_index, actual),
                    ))
    return findings


def key_call_sites():
    """Map every l10n getter referenced from real Dart source to its call-site
    lines (so a form-field label can be told apart from a screen headline)."""
    sites = {}
    pat = re.compile(r'\.([a-z][A-Za-z0-9_]*)\b')
    for path in dart_sources():
        with io.open(path, encoding='utf-8', errors='replace') as f:
            lines = f.read().split('\n')
        text = '\n'.join(lines)
        if 'AppLocalizations' not in text and re.search(r'\bl\.', text) is None:
            continue
        for idx, line in enumerate(lines):
            for m in pat.finditer(line):
                # Include the previous line: the getter is often wrapped onto
                # its own line under `labelText:`.
                ctx = (lines[idx - 1] if idx else '') + ' ' + line
                sites.setdefault(m.group(1), []).append(ctx)
    return sites


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true',
                    help='exit non-zero when a placeholder is found')
    args = ap.parse_args()

    arb = load_template()
    sites = key_call_sites()

    findings = []
    for key, value in sorted(arb.items()):
        if key.startswith('@') or not isinstance(value, str):
            continue
        norm = value.strip().lower()
        hit = norm in SLOT_WORDS or any(s in norm for s in SUBSTRING_MARKERS)
        if not hit:
            continue
        call_sites = sites.get(key)
        if not call_sites:
            # Unused key — still wrong, but it cannot reach a screen.
            findings.append((key, value, 'unused'))
            continue
        if all(any(mk in ctx.lower() for mk in FORM_LABEL_MARKERS)
               for ctx in call_sites):
            # Every call site is a form-field label — "Title" is real copy.
            continue
        findings.append((key, value, 'RENDERED'))

    slot_word_ok = not findings

    if slot_word_ok:
        print('OK — no widget-slot placeholders in %s (%d keys)'
              % (os.path.relpath(TEMPLATE_ARB, FLUTTER_ROOT), len(arb)))
    else:
        print('FAIL — %d placeholder string(s) in the localisation template:'
              % len(findings))
        for key, value, state in findings:
            print('  %-44s = %-14r  [%s]' % (key, value, state))
        print('\nReplace the value with the real copy (recover the pre-i18n literal '
              'with `git show e8ede3fc^:<file>`), then mirror it into every '
              'lib/l10n/app_<locale>.arb and lib/l10n/generated/app_localizations_'
              '<locale>.dart.')

    ordering_findings = check_unit_placeholder_ordering()
    ordering_ok = not ordering_findings

    if ordering_ok:
        print('OK — every `{unit}` placeholder call site matches the generated '
              '(alphabetical) argument order')
    else:
        print('FAIL — %d call site(s) with a `unit` placeholder in the wrong '
              'position (register row #100 class):' % len(ordering_findings))
        for key, loc, detail in ordering_findings:
            print('  %-44s %-60s %s' % (key, loc or '', detail))
        print('\n`flutter gen_l10n` orders positional params ALPHABETICALLY, not '
              'in message-text order. Read the generated signature in '
              'lib/l10n/generated/app_localizations.dart and pass arguments in '
              'THAT order at every call site.')

    if slot_word_ok and ordering_ok:
        return 0
    return 1 if args.check else 0


if __name__ == '__main__':
    sys.exit(main())
