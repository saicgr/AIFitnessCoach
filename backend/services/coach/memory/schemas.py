"""
Constants + structured-output contracts for the coach memory pipeline.

Categories are an OPEN vocabulary (the extractor may coin a new tag); the list
below is guidance for the model, not a hard whitelist enforced anywhere — per
feedback_no_hardcoded_enumerations. The DB CHECK constraints are only on
memory_type and status (closed sets with real lifecycle meaning).
"""
from __future__ import annotations

# --- closed sets (mirror the DB CHECK constraints) -------------------------
MEMORY_TYPES = ("semantic", "episodic", "state", "derived")
STATUSES = ("provisional", "active", "open", "resolved", "superseded", "dismissed")

# --- open-vocabulary category guidance -------------------------------------
SUGGESTED_CATEGORIES = (
    "preference",     # likes/dislikes, training style, coach tone
    "goal",           # what they're working toward
    "constraint",     # schedule/time/space limits, "only mornings"
    "equipment",      # what they have access to
    "dietary",        # vegetarian, allergies, intolerances
    "injury",         # pain / limitation (dual-written to injury_history)
    "life_event",     # travel, new baby, exam season
    "nutrition",      # eating habits/patterns (qualitative)
    "schedule",       # recurring routine
    "motivation",     # what drives or discourages them
    "observation",    # derived coach insight (memory_type=derived)
    "other",
)

# --- conflict-resolution operations the extractor proposes -----------------
OP_ADD = "ADD"            # genuinely new fact
OP_UPDATE = "UPDATE"      # refines/replaces an existing fact (keep history)
OP_RESOLVE = "RESOLVE"    # closes an open loop ("back feels better")
OP_REINFORCE = "REINFORCE"  # restated known fact — bump salience+recency
OP_CONTRADICT = "CONTRADICT"  # supersede an old fact with a conflicting new one
OP_NOOP = "NOOP"          # nothing worth remembering
OPS = (OP_ADD, OP_UPDATE, OP_RESOLVE, OP_REINFORCE, OP_CONTRADICT, OP_NOOP)

# Confidence below this is stored as 'provisional' and NOT injected until
# reinforced or user-confirmed (trust gating).
PROVISIONAL_CONFIDENCE_THRESHOLD = 0.55

# Memories with salience below this are never injected (noise floor).
MIN_INJECTABLE_SALIENCE = 0.2

# Per-user per-day cost cap for memory extraction (mirrors daily_insight).
MAX_MEMORY_USD_PER_USER_PER_DAY = 0.02

# Recency half-lives (days) by memory_type — drive the retrieval decay term.
# Semantic facts effectively never decay; episodics fade over ~3 weeks; open
# loops don't decay (they decay by follow_up_count instead); derived ~2 weeks.
RECENCY_HALF_LIFE_DAYS = {
    "semantic": 3650.0,   # ~10y => negligible decay
    "episodic": 21.0,
    "state": 3650.0,
    "derived": 14.0,
}

# Retrieval ranking weights (deterministic composite — local algo, no LLM).
RANK_WEIGHTS = {
    "salience": 0.30,
    "recency": 0.20,
    "relevance": 0.30,   # embedding cosine to current message (0 when unused)
    "type_priority": 0.10,
    "open_loop": 0.10,   # flat boost for open loops so they're never dropped
}

# Type priority for ranking (open loops + durable identity rank highest).
TYPE_PRIORITY = {
    "state": 1.0,
    "semantic": 0.8,
    "derived": 0.5,
    "episodic": 0.4,
}

# Token budget for the injected memory block (rough char proxy ~4 chars/token).
MEMORY_BLOCK_CHAR_BUDGET = 1400

# ChromaDB collection that mirrors memory embeddings for relevance retrieval.
MEMORY_COLLECTION = "coach_memory"

# Default open-loop follow-up delay (hours) when the extractor proposes a state
# memory without an explicit follow-up time. ~next morning.
DEFAULT_FOLLOW_UP_HOURS = 14


# --- Gemini structured-output JSON schema for extraction -------------------
# Used as response_schema so the model returns a clean ops list (no parsing of
# free text). One object per proposed operation.
EXTRACTION_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "operations": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "op": {"type": "string", "enum": list(OPS)},
                    # For UPDATE/RESOLVE/REINFORCE/CONTRADICT: which existing
                    # memory this targets (the id we showed the model). Null for ADD.
                    "target_id": {"type": "string"},
                    "memory_type": {"type": "string", "enum": list(MEMORY_TYPES)},
                    "category": {"type": "string"},
                    "content": {"type": "string"},
                    "salience": {"type": "number"},
                    "confidence": {"type": "number"},
                    "sensitive": {"type": "boolean"},
                    "is_injury": {"type": "boolean"},
                    # state memories only:
                    "resolution_prompt": {"type": "string"},
                    "source_quote": {"type": "string"},
                },
                "required": ["op"],
            },
        }
    },
    "required": ["operations"],
}
