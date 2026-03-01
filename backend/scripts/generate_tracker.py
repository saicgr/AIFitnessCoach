#!/usr/bin/env python3
"""Generate PROGRAMS_GENERATION_TRACKER.md from PROGRAMS_CHECKLIST.md."""

import re
from collections import defaultdict
from pathlib import Path

CHECKLIST = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"
TRACKER = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_GENERATION_TRACKER.md"


def main():
    with open(CHECKLIST) as f:
        content = f.read()

    programs = []
    current_category = None
    current_category_num = 0

    category_pattern = r'^## (\d+)\. (.+?) \((\d+) programs?\)'
    program_pattern = r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'

    for line in content.split('\n'):
        cat_match = re.match(category_pattern, line)
        if cat_match:
            current_category_num = int(cat_match.group(1))
            current_category = cat_match.group(2).strip()
            continue

        if '|------' in line or '| Program |' in line:
            continue

        if current_category and line.startswith('|'):
            prog_match = re.match(program_pattern, line)
            if prog_match:
                name = prog_match.group(1).strip()
                priority = prog_match.group(2).strip()
                durations = prog_match.group(3).strip()
                sessions = prog_match.group(4).strip()
                if name and name != 'Program' and '---' not in name:
                    programs.append({
                        'name': name,
                        'priority': priority,
                        'durations': durations,
                        'sessions': sessions,
                        'category': current_category,
                        'category_num': current_category_num,
                    })

    # Group by category
    cats = defaultdict(list)
    for p in programs:
        cats[(p['category_num'], p['category'])].append(p)

    # Count by priority
    high = sum(1 for p in programs if p['priority'] == 'High')
    med = sum(1 for p in programs if p['priority'] == 'Med')
    low = sum(1 for p in programs if p['priority'] == 'Low')

    # Agent assignments
    agent_cats = {
        1: list(range(1, 4)),
        2: list(range(4, 7)),
        3: list(range(7, 10)),
        4: list(range(10, 14)),
        5: list(range(14, 18)),
        6: list(range(18, 21)),
        7: list(range(21, 27)),
        8: list(range(27, 32)),
        9: list(range(32, 38)),
        10: list(range(38, 53)),
        11: list(range(53, 61)),
        12: list(range(61, 81)),
    }

    lines = []
    lines.append('# Program Generation Tracker')
    lines.append('')
    lines.append('## Plan Context')
    lines.append('- **Approach**: Web research -> SQL files -> execute against Supabase')
    lines.append('- **Anchor durations only**: Dynamic algorithm derives other durations')
    lines.append('- **Exercise library linked**: exercise_library_id + in_library fields in JSONB')
    lines.append('- **Resume**: Check this tracker, pick up Pending items')
    lines.append('- **Migration base**: 343+ (342 = constraints)')
    lines.append('')
    lines.append('## Summary')
    lines.append('')
    lines.append('| Priority | Programs | Done | Pending |')
    lines.append('|----------|----------|------|---------|')
    lines.append(f'| High     | {high}      | 0    | {high}     |')
    lines.append(f'| Med      | {med}     | 0    | {med}    |')
    lines.append(f'| Low      | {low}     | 0    | {low}    |')
    lines.append(f'| **Total** | **{len(programs)}** | **0** | **{len(programs)}** |')
    lines.append('')

    lines.append('## Agent Assignments')
    lines.append('')
    lines.append('| Agent | Categories | Programs |')
    lines.append('|-------|-----------|----------|')
    for agent_num, cat_nums in agent_cats.items():
        count = sum(len(progs) for (cn, _), progs in cats.items() if cn in cat_nums)
        cat_names = [cat for (cn, cat) in sorted(cats.keys()) if cn in cat_nums]
        short = ', '.join(cat_names[:3])
        if len(cat_names) > 3:
            short += '...'
        lines.append(f'| {agent_num} | {cat_nums[0]}-{cat_nums[-1]}: {short} | {count} |')
    lines.append('')

    # Per-category tables
    for (cat_num, cat_name) in sorted(cats.keys()):
        progs = cats[(cat_num, cat_name)]
        lines.append(f'## {cat_num}. {cat_name} ({len(progs)} programs)')
        lines.append('')
        lines.append('| Program | Pri | Anchor Durations | Sessions | Status | SQL File | Agent |')
        lines.append('|---------|-----|-----------------|----------|--------|----------|-------|')

        agent = 0
        for a, cnums in agent_cats.items():
            if cat_num in cnums:
                agent = a
                break

        for p in progs:
            lines.append(f'| {p["name"]} | {p["priority"]} | {p["durations"]} | {p["sessions"]} | Pending | | {agent} |')
        lines.append('')

    with open(TRACKER, 'w') as f:
        f.write('\n'.join(lines))

    print(f'Total programs: {len(programs)}')
    print(f'Categories: {len(cats)}')
    print(f'High: {high}, Med: {med}, Low: {low}')
    print(f'Tracker written to {TRACKER}')


if __name__ == '__main__':
    main()
