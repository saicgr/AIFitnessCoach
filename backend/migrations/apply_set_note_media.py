"""
Apply the `add_set_note_media.sql` migration to Supabase.

Run from repo root with:
    cd backend && .venv/bin/python migrations/apply_set_note_media.py

Uses `DATABASE_URL` from backend/.env (already exported asyncpg-style).
Non-destructive: both columns use `IF NOT EXISTS`.
"""
import asyncio
import os
import re
from pathlib import Path


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    load_dotenv()
    url = os.environ["DATABASE_URL"]
    # asyncpg doesn't understand the +asyncpg dialect prefix SQLAlchemy uses.
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)

    sql_path = Path(__file__).parent / "add_set_note_media.sql"
    sql = sql_path.read_text()

    conn = await asyncpg.connect(url, ssl="require")
    try:
        print(f"→ Applying {sql_path.name} to {url.split('@', 1)[-1]} …")
        await conn.execute(sql)

        rows = await conn.fetch(
            """
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'set_performances'
              AND column_name IN ('notes_audio_url', 'notes_photo_urls')
            ORDER BY column_name
            """
        )
        print("✅ Columns present on set_performances:")
        for r in rows:
            print("   ", dict(r))
        if len(rows) != 2:
            print("⚠️  Expected both columns but only found:", len(rows))
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
