#!/usr/bin/env python3
"""
Script to rename "FitWiz" to "FitWiz" throughout the codebase
"""

import os
import re

BASE_DIR = '/Users/saichetangrandhe/AIFitnessCoach'

# File extensions to process
EXTENSIONS = {'.md', '.py', '.dart', '.yaml', '.json', '.xml', '.plist', '.txt', '.html', '.sql'}

# Directories to skip
SKIP_DIRS = {'.git', 'build', '.dart_tool', '.idea', 'node_modules', '__pycache__', 'venv', '.venv'}

# Replacements to make (order matters - more specific first)
REPLACEMENTS = [
    ('FitWiz', 'FitWiz'),
    ('fitwiz', 'fitwiz'),
    ('FITWIZ', 'FITWIZ'),
    ('fitwiz', 'fitwiz'),
    ('FitWiz', 'FitWiz'),
    ('fitwiz', 'fitwiz'),
]

def should_process_file(filepath):
    """Check if file should be processed based on extension."""
    _, ext = os.path.splitext(filepath)
    return ext.lower() in EXTENSIONS

def process_file(filepath):
    """Process a single file, making replacements."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"  Error reading {filepath}: {e}")
        return False

    original_content = content

    for old, new in REPLACEMENTS:
        content = content.replace(old, new)

    if content != original_content:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            print(f"  Error writing {filepath}: {e}")
            return False

    return False

def main():
    print(f"Renaming 'FitWiz' to 'FitWiz' in {BASE_DIR}")
    print("=" * 60)

    files_processed = 0
    files_modified = 0

    for root, dirs, files in os.walk(BASE_DIR):
        # Skip certain directories
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

        for filename in files:
            filepath = os.path.join(root, filename)

            if should_process_file(filepath):
                files_processed += 1
                if process_file(filepath):
                    rel_path = os.path.relpath(filepath, BASE_DIR)
                    print(f"  ✅ Updated: {rel_path}")
                    files_modified += 1

    print("=" * 60)
    print(f"Files processed: {files_processed}")
    print(f"Files modified: {files_modified}")
    print("Done!")

if __name__ == '__main__':
    main()
