#!/usr/bin/env python3
"""
Update PROGRAMS_CHECKLIST.md to have proper pipeline tracking columns.

Columns needed:
| Program | Duration | Sessions | Description | SS | Done | JSON | Valid | DB |

Where:
- Done = Overall completion status
- JSON = JSON file generated
- Valid = JSON validated (passes quality checks)
- DB = Ingested to Supabase
"""

import re
from pathlib import Path

CHECKLIST_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"


def update_checklist():
    with open(CHECKLIST_PATH) as f:
        content = f.read()

    lines = content.split('\n')
    updated_lines = []

    for i, line in enumerate(lines):
        # Update Category Summary header
        if "| # | Category | Programs | Status | Done |" in line and "JSON" in line:
            updated_lines.append("| # | Category | Programs | Status | Done | JSON | Valid | DB | Supersets |")
            continue

        # Update Category Summary separator
        if "|---|----------|----------|--------|------|:----:|:--:|-----------|" in line:
            updated_lines.append("|---|----------|----------|--------|------|:----:|:-----:|:--:|-----------|")
            continue

        # Update Category Summary data rows
        cat_match = re.match(r'^\| (\d+) \| ([^|]+) \| (\d+) \| ([^|]+) \| (\d+/\d+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', line.strip())
        if cat_match:
            num = cat_match.group(1)
            category = cat_match.group(2)
            programs = cat_match.group(3)
            status = cat_match.group(4)
            done = cat_match.group(5)
            # groups 6,7,8 are JSON, DB, Supersets - we need to add Valid between JSON and DB
            json_col = cat_match.group(6).strip()
            db_col = cat_match.group(7).strip()
            supersets = cat_match.group(8)
            updated_lines.append(f"| {num} | {category} | {programs} | {status} | {done} | {json_col} | 0/? | {db_col} | {supersets} |")
            continue

        # Update program table header - current format has JSON | DB, need JSON | Valid | DB
        if "| Program | Duration | Sessions | Description | SS | Done | JSON | DB |" in line:
            updated_lines.append("| Program | Duration | Sessions | Description | SS | Done | JSON | Valid | DB |")
            continue

        # Update program table separator
        if "|---------|----------|:--------:|-------------|:--:|:----:|:----:|:--:|" in line:
            updated_lines.append("|---------|----------|:--------:|-------------|:--:|:----:|:----:|:-----:|:--:|")
            continue

        # Update program data rows - current format: | name | dur | sess | desc | ss | done | json | db |
        prog_match = re.match(r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', line.strip())
        if prog_match and "Program" not in prog_match.group(1) and "---" not in prog_match.group(1):
            name = prog_match.group(1)
            duration = prog_match.group(2)
            sessions = prog_match.group(3)
            description = prog_match.group(4)
            ss = prog_match.group(5)
            done = prog_match.group(6)
            json_col = prog_match.group(7)
            db_col = prog_match.group(8)

            # Add Valid column - same as JSON for completed, ⬜ otherwise
            if '✅' in json_col:
                valid_col = '✅'
            else:
                valid_col = '⬜'

            updated_lines.append(f"| {name} | {duration} | {sessions} | {description} | {ss} | {done} | {json_col} | {valid_col} | {db_col} |")
            continue

        # Keep line as-is
        updated_lines.append(line)

    # Write back
    with open(CHECKLIST_PATH, 'w') as f:
        f.write('\n'.join(updated_lines))

    print(f"✅ Updated {CHECKLIST_PATH}")
    print("   Added 'Valid' column between JSON and DB")


if __name__ == "__main__":
    update_checklist()
