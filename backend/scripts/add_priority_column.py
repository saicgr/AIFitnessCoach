#!/usr/bin/env python3
"""
Add Priority column to PROGRAMS_CHECKLIST.md

Priority levels:
- 🔴 High - Must have, core programs
- 🟡 Med - Good to have, popular programs
- 🟢 Low - Nice to have, niche programs

Default assignments:
- First 3-4 programs in each category = High
- Next 3-4 = Medium
- Rest = Low
"""

import re
from pathlib import Path

CHECKLIST_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"


def update_checklist():
    with open(CHECKLIST_PATH) as f:
        content = f.read()

    lines = content.split('\n')
    updated_lines = []

    current_category = None
    program_count_in_category = 0

    for line in lines:
        # Detect category header
        cat_match = re.match(r'^## (\d+)\. (.+?) \((\d+) programs?\)', line)
        if cat_match:
            current_category = cat_match.group(2).strip()
            program_count_in_category = 0
            updated_lines.append(line)
            continue

        # Update Category Summary header
        if "| # | Category | Programs | Status | Done | JSON | Valid | DB | Supersets |" in line:
            updated_lines.append("| # | Category | Programs | Status | Done | JSON | Valid | DB | Supersets |")
            continue

        # Update program table header - add Pri column after Program
        if "| Program | Duration | Sessions | Description | SS | Done | JSON | Valid | DB |" in line:
            updated_lines.append("| Program | Pri | Duration | Sessions | Description | SS | Done | JSON | Valid | DB |")
            continue

        # Update program table separator
        if "|---------|----------|:--------:|-------------|:--:|:----:|:----:|:-----:|:--:|" in line:
            updated_lines.append("|---------|:---:|----------|:--------:|-------------|:--:|:----:|:----:|:-----:|:--:|")
            continue

        # Update program data rows - current: 9 columns
        prog_match = re.match(
            r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$',
            line.strip()
        )

        if prog_match and "Program" not in prog_match.group(1) and "---" not in prog_match.group(1):
            name = prog_match.group(1).strip()
            duration = prog_match.group(2).strip()
            sessions = prog_match.group(3).strip()
            description = prog_match.group(4).strip()
            ss = prog_match.group(5).strip()
            done = prog_match.group(6).strip()
            json_col = prog_match.group(7).strip()
            valid_col = prog_match.group(8).strip()
            db_col = prog_match.group(9).strip()

            program_count_in_category += 1

            # Assign priority based on position in category
            # Also boost certain keywords
            name_lower = name.lower()

            # High priority keywords
            high_keywords = ['5x5', 'ppl', 'push pull', 'full body', 'beginner', 'hiit', 'shred',
                           'hyrox', 'classic', 'foundation', 'essential', 'basic']
            # Low priority keywords
            low_keywords = ['specialization', 'advanced', 'elite', 'pro ', 'extreme', 'hell mode',
                          'viral', 'tiktok', 'reddit', 'celebrity']

            if any(kw in name_lower for kw in high_keywords) or program_count_in_category <= 3:
                priority = '🔴'
            elif any(kw in name_lower for kw in low_keywords) or program_count_in_category > 8:
                priority = '🟢'
            else:
                priority = '🟡'

            # Already done = keep original priority marker or use ✅
            if '✅' in done:
                priority = '✅'

            updated_lines.append(f"| {name} | {priority} | {duration} | {sessions} | {description} | {ss} | {done} | {json_col} | {valid_col} | {db_col} |")
        else:
            updated_lines.append(line)

    # Write back
    with open(CHECKLIST_PATH, 'w') as f:
        f.write('\n'.join(updated_lines))

    print(f"✅ Added Priority column to {CHECKLIST_PATH}")
    print("\nPriority Legend:")
    print("  🔴 High - Core programs, generate first")
    print("  🟡 Med  - Popular programs")
    print("  🟢 Low  - Niche programs")
    print("  ✅ Done - Already completed")


if __name__ == "__main__":
    update_checklist()
