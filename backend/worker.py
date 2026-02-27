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
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

def main():
    logger.info("=" * 60)
    logger.info("🚀 PROGRAM GENERATION WORKER")
    logger.info("=" * 60)

    # Get configuration from environment
    priority = os.getenv("GENERATION_PRIORITY", "high")
    limit = os.getenv("GENERATION_LIMIT", "")

    logger.info(f"Priority: {priority}")
    logger.info(f"Limit: {limit if limit else 'unlimited'}")

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

    logger.info(f"\nRunning: {' '.join(cmd)}")
    logger.info("=" * 60 + "\n")

    # Run the generation script
    result = subprocess.run(cmd, cwd=str(Path(__file__).parent))

    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
