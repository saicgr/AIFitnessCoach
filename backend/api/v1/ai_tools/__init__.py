"""AI Tools — public unauthenticated marketing-funnel endpoints.

Distinct from the existing `free_tools` package because these endpoints expose
multi-step AI workflows (vision + classifier + deterministic synth) rather
than a single LLM round-trip. Each has its own per-IP rate limit.
"""
