"""
Nightly coach-memory consolidation (reflection) cron.

Runs the deterministic reflection pass over every user with active memory:
dedupe/decay/archive, open-loop expiry, episodic->semantic promotion, and a
conservative derived-insight pass. No LLM calls — cheap to run nightly.

Wired in render.yaml as the `fitwiz-memory-consolidate` cron:
    python -m scripts.consolidate_memory

Also reachable as an HTTP trigger: POST /api/v1/coach/memory/consolidate
(X-Cron-Secret).
"""
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("consolidate_memory")


def main() -> None:
    from services.coach.memory.pipeline import consolidate_all_active
    totals = consolidate_all_active()
    logger.info(f"[consolidate_memory] done: {totals}")
    print(f"[consolidate_memory] {totals}")


if __name__ == "__main__":
    main()
