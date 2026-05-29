"""
Coach long-term memory subsystem (migration 2217).

Public entry points:
    pipeline.extract_and_store(...)   write path — runs as a BackgroundTask
    pipeline.consolidate_user(...)    nightly reflection (cron)
    retriever.retrieve_for_chat(...)  ranked recall for a coach turn
    retriever.retrieve_for_briefing() recall for the daily open briefing
    injector.build_memory_block(...)  formats recall into the prompt block
    embeddings.*                      ChromaDB relevance index (best-effort)

Design notes live in the migration header (2217_coach_memory.sql) and in
docs/planning/redesign-2026-05/ (the plan this implements).
"""
