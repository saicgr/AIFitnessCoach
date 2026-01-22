#!/usr/bin/env python3
"""
Update Priority column from emojis to text (High/Med/Low).
"""

import re
from pathlib import Path

CHECKLIST_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"


def update_checklist():
    with open(CHECKLIST_PATH) as f:
        content = f.read()

    # Replace emoji priorities with text
    content = content.replace('| 🔴 |', '| High |')
    content = content.replace('| 🟡 |', '| Med |')
    content = content.replace('| 🟢 |', '| Low |')
    content = content.replace('| ✅ |', '| Done |')  # For already completed

    with open(CHECKLIST_PATH, 'w') as f:
        f.write(content)

    print("✅ Updated priorities to text format:")
    print("   🔴 → High")
    print("   🟡 → Med")
    print("   🟢 → Low")
    print("   ✅ → Done")


if __name__ == "__main__":
    update_checklist()
