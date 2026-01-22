#!/usr/bin/env python3
"""
Fix the Category Summary table in PROGRAMS_CHECKLIST.md

The Category Summary table incorrectly has priority values where the category name should be.
This script fixes the structure back to the correct format:
| # | Category | Programs | Status | Done | JSON | Valid | DB | Supersets |
"""

import re
from pathlib import Path

CHECKLIST_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"


def fix_checklist():
    with open(CHECKLIST_PATH) as f:
        content = f.read()

    lines = content.split('\n')
    updated_lines = []
    in_category_summary = False

    for i, line in enumerate(lines):
        # Detect Category Summary section
        if "## Category Summary" in line:
            in_category_summary = True
            updated_lines.append(line)
            continue

        # Detect end of Category Summary (next section)
        if in_category_summary and line.startswith("## ") and "Category Summary" not in line:
            in_category_summary = False

        # Skip the broken separator rows
        if in_category_summary and line.strip().startswith("| **---"):
            updated_lines.append(line)
            continue

        # Fix Category Summary data rows
        # Current broken format: | 1 | High | Premium | 12 | 🔄 | 1/12 | 0/? | 0/? | 0/? | ✅ Some |
        # Correct format: | 1 | Premium | 12 | 🔄 | 1/12 | 0/? | 0/? | 0/? | ✅ Some |
        if in_category_summary:
            cat_match = re.match(
                r'^\| (\d+) \| (High|Med|Low) \| ([^|]+) \| (\d+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$',
                line.strip()
            )
            if cat_match:
                num = cat_match.group(1)
                # Skip priority (group 2)
                category = cat_match.group(3).strip()
                programs = cat_match.group(4)
                status = cat_match.group(5).strip()
                done = cat_match.group(6).strip()
                json_col = cat_match.group(7).strip()
                valid_col = cat_match.group(8).strip()
                db_col = cat_match.group(9).strip()
                supersets = cat_match.group(10).strip()

                updated_lines.append(f"| {num} | {category} | {programs} | {status} | {done} | {json_col} | {valid_col} | {db_col} | {supersets} |")
                continue

        updated_lines.append(line)

    # Write back
    with open(CHECKLIST_PATH, 'w') as f:
        f.write('\n'.join(updated_lines))

    print(f"✅ Fixed Category Summary table in {CHECKLIST_PATH}")


if __name__ == "__main__":
    fix_checklist()
