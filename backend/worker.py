#!/usr/bin/env python3
"""
Background Worker for Program Generation

Run on Render as a background worker to generate all workout programs.
Reads configuration from environment variables.

Environment Variables:
    GEMINI_API_KEY - Required for AI generation
    SUPABASE_URL - Required for database
    SUPABASE_KEY - Required for database
    GENERATION_PRIORITY - high|medium|low|all (default: high)
    GENERATION_LIMIT - Max variants to generate (default: unlimited)
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    print("=" * 60)
    print("🚀 PROGRAM GENERATION WORKER")
    print("=" * 60)

    # Get configuration from environment
    priority = os.getenv("GENERATION_PRIORITY", "high")
    limit = os.getenv("GENERATION_LIMIT", "")

    print(f"Priority: {priority}")
    print(f"Limit: {limit if limit else 'unlimited'}")

    # Build command
    script_path = Path(__file__).parent / "scripts" / "generate_programs.py"

    cmd = [
        sys.executable,
        str(script_path),
        "--priority", priority,
        "--no-break",  # Continue on failures
    ]

    if limit:
        cmd.extend(["--limit", limit])

    print(f"\nRunning: {' '.join(cmd)}")
    print("=" * 60 + "\n")

    # Run the generation script
    result = subprocess.run(cmd, cwd=str(Path(__file__).parent))

    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
