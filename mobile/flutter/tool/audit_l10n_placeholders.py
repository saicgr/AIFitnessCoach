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

    if not findings:
        print('OK — no widget-slot placeholders in %s (%d keys)'
              % (os.path.relpath(TEMPLATE_ARB, FLUTTER_ROOT), len(arb)))
        return 0

    print('FAIL — %d placeholder string(s) in the localisation template:'
          % len(findings))
    for key, value, state in findings:
        print('  %-44s = %-14r  [%s]' % (key, value, state))
    print('\nReplace the value with the real copy (recover the pre-i18n literal '
          'with `git show e8ede3fc^:<file>`), then mirror it into every '
          'lib/l10n/app_<locale>.arb and lib/l10n/generated/app_localizations_'
          '<locale>.dart.')
    return 1 if args.check else 0


if __name__ == '__main__':
    sys.exit(main())
