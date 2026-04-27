# Zealova — Interview Prep

Anticipated questions + answers for discussing this app in interviews. Answers are written to be **spoken aloud**, not bullet-point-read. Hard-section answers are first-person conversational; short ones can be quoted verbatim.

## Contents
- §0 — 30-second elevator pitch
- §1-3 — Product, AI overview, tooling stack
- §4 — Agents (which, how orchestrated, tool calling walkthrough)
- §5-6 — System design + data architecture
- §7-8 — Challenges faced, behavioral
- §9 — AI deep dives (RAG, hallucination, multimodal, cost)
- **§10 — AI Accuracy & Evaluation** (honest "didn't do but should have" framing)
- **§11 — Prompting & AI Dev Tooling** (CLAUDE.md, memory files, MCPs, subagents)
- **§12 — More Medium questions** (15 additional)
- **§13 — More Hard questions, first-person voice** (15 additional, scripted for speaking)
- **§14 — User Analytics, Retention & Growth** (retention mechanics built, analytics gap, segmentation, churn, virality)
- §15 — Biggest technical regret
- Cheat-sheet numbers + closing tips

---

## 0. The 30-second elevator pitch

> "Zealova is an AI fitness coach — mobile app on iOS and Android. Users chat with it about workouts, nutrition, injuries, and it also generates personalized workout plans and analyzes food images and exercise-form videos. The AI layer is a multi-agent system built on LangGraph with Google Gemini as the base model. Frontend is Flutter, backend is FastAPI on Render, data is Supabase Postgres plus ChromaDB Cloud for RAG. It also works offline via on-device Gemma."

---

## 1. Product & Overview

### Q: What is the app?
AI-powered fitness coaching app. Five core capabilities:
1. **Onboarding → personalized workout plan generation** (monthly plans with progressive overload)
2. **AI chat coach** — domain-specialized (nutrition, workout, injury, hydration, general)
3. **Food logging via image / text / app-screenshot OCR / nutrition label**
4. **Exercise form analysis via video** (keyframe extraction + Gemini Vision)
5. **Workout tracking, progress, social (challenges, leaderboards, XP, trophies)**

### Q: Who is it for?
Consumer fitness users (gym-goers, home-workouts, beginners through intermediate). Monetized through RevenueCat subscriptions (free tier + pro).

### Q: Platforms?
iOS + Android via Flutter. Single codebase, shared Dart logic, native widgets (iOS Home Screen widget via SwiftUI, Android widget via Kotlin).

### Q: What's the scale?
Indie-stage. Backend on Render free/starter tier, single Supabase project, ChromaDB Cloud, Gemini API. Architected for scale but not yet scale-tested.

---

## 2. Did you use AI? How?

### Q: Did you use AI in this app?
Yes — AI is the core value proposition, not a bolt-on. Seven distinct AI surfaces:

1. **Multi-agent chat** (LangGraph + Gemini) — 9 specialized agents
2. **Workout plan generation** — structured-output Gemini calls with RAG-retrieved exercises
3. **Media classification** — Gemini Vision pre-routes uploads (food vs. form vs. screenshot vs. progress photo)
4. **Form analysis** — video keyframes → Gemini Vision scoring pipeline
5. **Onboarding** — AI-driven question generation (no hardcoded question templates)
6. **Content generators** — habit suggestions, recipe suggestions, hashtags, year-in-review
7. **On-device AI** — `flutter_gemma` running Gemma 270M/1B/4B for offline mode

### Q: Which model?
**Google Gemini** (`gemini-3-flash-preview`) via the `google-genai` SDK, wrapped in LangChain (`langchain-google-genai`) for tool binding. Chose Gemini for: multimodal (image/video) in a single model, fast flash-tier latency, and generous free tier during prototyping.

### Q: Why not OpenAI / Anthropic?
Gemini's native video-frame understanding was the deciding factor for form analysis. Cost-per-token was also cheaper for the image-heavy workload (food photos, form videos). Architecture is provider-agnostic — swapping to Claude or GPT-4 would mean changing one wrapper in `core/gemini_client.py`.

### Q: How do you prompt-engineer?
- **Role-specific system prompts** per agent (`personality.py` + per-agent templates)
- **Response format constraints** — JSON-only for structured outputs, with robust parsing that strips markdown fences
- **Few-shot examples** in prompt for nutrition/workout generation
- **Safety settings configured** — default Gemini safety filters block fitness content ("pain," "heavy," etc.), so we explicitly set `HARM_CATEGORY_*` thresholds
- **Prompt injection sanitization** — 9 regex patterns strip attack attempts (`ignore previous instructions`, fake `SYSTEM:` roles, token-boundary markers)

### Q: How do you handle LLM unreliability?
- **Structured output validation** — every JSON response validated against a Pydantic / TypedDict schema
- **Retry-with-different-binding** on `thought_signature` errors (Gemini quirk)
- **No silent fallbacks** — failures surface as errors, not degraded output
- **Human-readable error messages** to the user
- **Observability** — prefixed logs (`🔍` debug, `❌` error, `🎯` milestone) make LLM pipeline traces scannable

---

## 3. What tools / frameworks / SDKs did you use?

### Q: Give me the full stack.

**Frontend (Flutter)**:
- Flutter 3.38.10 (pinned — see §7 challenges)
- Riverpod (state management), Dio (HTTP), freezed + json_serializable (models)
- Drift (local SQLite for offline), connectivity_plus, workmanager
- flutter_gemma (on-device LLM), system_info_plus (device tier detection)
- go_router (navigation), flutter_secure_storage (refresh tokens only)

**Backend (Python)**:
- FastAPI + Uvicorn (ASGI)
- LangGraph + LangChain + langchain-google-genai
- google-genai SDK (direct Gemini calls)
- Supabase Python client, asyncpg
- slowapi (rate limiting), Redis (caching)
- chromadb-client (ChromaDB Cloud)
- Pydantic v2 (schemas)

**Data & infra**:
- Supabase (Postgres + Auth + RLS) — source of truth
- ChromaDB Cloud — RAG vectors (exercises, workouts, feedback, nutrition)
- AWS S3 — exercise illustrations, user videos, progress photos
- Render — backend hosting
- RevenueCat — subscriptions
- SendGrid — email, FCM/APNs — push

### Q: Why LangGraph over LangChain agents or just raw SDK?
- **Explicit state machine**: each agent is a `StateGraph` with typed state. Easier to reason about than ReAct loops.
- **Conditional edges** give me control over when tools fire vs. when the LLM responds directly — I can skip tool calls on greetings, force `tool_choice="check_exercise_form"` when a video is attached, etc.
- **State as TypedDict** — type-checked inputs/outputs per node
- Pure raw SDK would mean reinventing the tool-calling loop; LangChain agents are too magical for production debugging.

### Q: Why Supabase?
Auth + Postgres + RLS in one service. Saved months of infra work. Foreign-key constraints enforced at the DB layer; RLS isolates user data without custom middleware.

### Q: Why ChromaDB Cloud and not pgvector?
Started with pgvector but Supabase's pgvector is slower than a dedicated vector store at scale. ChromaDB Cloud gave me hosted infrastructure with a thin HTTP client. Downside: cold queries hit 5-13s tail latency, which is why greetings bypass RAG entirely (fast-path).

---

## 4. Did you build agents? Which ones?

### Q: Yes or no — did you build AI agents?
Yes. **Nine LangGraph-based agents** orchestrated through a central router.

### Q: List them.
**Five runtime chat agents** (invoked by the message router):
1. **Coach** — general Q&A, app settings, navigation, greetings (default)
2. **Nutrition** — food image analysis, logging, summaries, recipe suggestions (10 tools)
3. **Workout** — add/remove/replace/modify exercises, quick-workout generation, form analysis (9 tools)
4. **Injury** — report/clear/update injuries, triggers workout invalidation (4 tools)
5. **Hydration** — water logging, hydration advice

**Four auxiliary agents** (invoked outside the chat router):
6. **Onboarding** — AI-driven next-question generation, no hardcoded templates
7. **Exercise Suggestion** — fills gaps when a workout is missing an exercise
8. **Plan Agent** — holistic monthly plan updates
9. **Workout Insights** — post-workout analysis

### Q: What's an "agent" in your system, concretely?
A compiled LangGraph `StateGraph` with: (a) a typed state (`TypedDict`), (b) a set of nodes (Python functions that mutate state), (c) conditional edges, (d) optionally a tool belt (list of `@tool`-decorated Python functions bound to the LLM).

### Q: How is an agent different from a service or a function?
- A **service** (like `ProgressionService`) is deterministic — plain Python, no LLM.
- A **function** has no state machine.
- An **agent** has an LLM-driven loop: LLM decides whether to call a tool, tool runs, LLM decides what to say about the result. State carries across nodes.

### Q: How are the agents orchestrated?
A central orchestrator — `LangGraphCoachService` — receives every chat message and picks exactly one agent. Priority order:

1. **`@mention` in the message** (`@nutrition`, `@workout`, `@injury`, `@hydration`, `@coach`) — highest priority
2. **Media content type** from `VisionService.classify_media_content()` — Gemini Vision classifies uploads into 10 types (`food_plate`, `exercise_form`, `progress_photo`, etc.), each routed to a specific agent
3. **Intent** inferred by a small Gemini classifier call (`ANALYZE_FOOD`, `ADD_EXERCISE`, `REPORT_INJURY`, ...)
4. **Keyword dictionary** — `DOMAIN_KEYWORDS` per agent (fallback)
5. **Coach agent** — default catch-all

### Q: Why one agent per turn and not multi-agent collaboration?
- Latency — every extra agent hop = extra LLM round-trip.
- Determinism — easier to debug a single graph execution than a multi-agent dialogue.
- The router already handles the routing problem — no need for agents to hand off to each other mid-turn.
- Cross-domain questions are rare in practice; follow-up turns can route to a different agent.

### Q: Walk me through what happens when a user sends "what should I eat after my chest workout?"
1. Message arrives at `POST /chat` → `LangGraphCoachService`
2. Prompt-injection sanitizer strips attack patterns
3. Not trivial (not "hi"/"thanks"), so no fast-path
4. No media → skip vision classifier
5. `_select_agent()` — no `@mention`, intent classifier returns something nutrition-ish, keyword dict hits "eat" and "workout" → **Nutrition agent** wins
6. `_build_agent_state` — fetches user profile, today's workout (for context), recent food logs, RAG context from ChromaDB
7. Nutrition agent graph starts: router node sees no tool-requiring intent → routes to `autonomous` node
8. LLM call with system prompt ("you are a nutritionist, today's context is: …") → returns a meal recommendation
9. `action_data_node` builds a structured payload (could be a "log this meal" button)
10. Final state flows back to orchestrator
11. `_store_chat_history` — writes to `chat_messages` in Postgres + embeds Q/A into ChromaDB for future RAG
12. `ChatResponse` returned to Flutter

Round-trip: typically 2-4 seconds.

### Q: What tools does each agent have?

| Agent | Tools |
|---|---|
| Nutrition (10) | `analyze_food_image`, `analyze_multi_food_images`, `parse_app_screenshot`, `parse_nutrition_label`, `log_food_from_text`, `get_nutrition_summary`, `get_recent_meals`, `get_calorie_remainder`, `get_favorite_foods`, `get_todays_workout_for_meal` |
| Workout (7+2) | `add_exercise_to_workout`, `remove_exercise_from_workout`, `replace_all_exercises`, `modify_workout_intensity`, `reschedule_workout`, `delete_workout`, `generate_quick_workout` + `check_exercise_form`, `compare_exercise_form` |
| Injury (4) | `report_injury`, `clear_injury`, `get_active_injuries`, `update_injury_status` |
| Hydration | No tools — side effects via `action_data` |
| Coach | No tools — side effects via `action_data` |

### Q: How does tool calling work under the hood?
1. Agent node builds `messages = [SystemMessage(prompt), *history, HumanMessage(user_msg)]`
2. `llm = get_langchain_llm().bind_tools(TOOLS)`
3. `response = await llm.ainvoke(messages)` — Gemini decides whether to emit `tool_calls`
4. If `tool_calls` present: `tool_executor` runs each, appends `ToolMessage(tool_call_id=..., content=result)`
5. Re-invoke LLM with appended tool messages → final natural-language response
6. Workout agent also uses **forced `tool_choice`** when media is attached (e.g. `tool_choice="check_exercise_form"`) to prevent the LLM from skipping the tool

### Q: How do tools affect the database?
Tools are the ONLY AI-driven code path that writes to Postgres. Each tool is a Python function with `@tool` decorator that (a) validates input, (b) performs DB operation via Supabase facade, (c) returns a dict the LLM can quote. Examples: `report_injury` writes to `injuries` table AND triggers `invalidate_upcoming_workouts()` to delete future plans so they regenerate without the injured muscle group.

---

## 5. System Design Questions

### Q: Draw the architecture on a whiteboard.
Point them to `SYSTEM_ARCHITECTURE.md` — or sketch:
- Flutter client (Riverpod + Dio + Drift SQLite)
- → FastAPI on Render (middleware: security, body-size, gzip, rate-limit, CORS, JWT auth)
- → Service layer (Gemini service, RAG service, LangGraph service, Vision service)
- → Data plane: Supabase PG (source of truth), S3 (media), ChromaDB Cloud (vectors), Gemini API
- → Auxiliary: RevenueCat (subs), FCM/APNs (push), SendGrid (email)

### Q: How do you handle authentication?
Supabase Auth (JWT). Client stores only the refresh token in `FlutterSecureStorage`; the access token is always read **live** from `Supabase.instance.client.auth.currentSession` because cached tokens expire silently. Backend verifies every request's JWT against Supabase. Proactive refresh on a timer before expiry.

### Q: How do you handle rate limiting?
Two layers:
1. **SlowAPI** on FastAPI — per-endpoint (e.g. `/workouts/generate-stream` = 15/min/user)
2. **App-level caps** — `Semaphore(10)` on vision calls, 50 on workout generation; daily media cap (20 free / 100 pro) tracked in `chat_media_usage` table

### Q: How do you handle long-running operations (workout generation)?
**Streaming via SSE** — `POST /workouts/generate-stream` returns Server-Sent Events with typed event names (`chunk`, `done`, `error`, `already_generating`). Time-to-first-chunk < 500ms vs 3-8s for full generation. Client renders partial results as they arrive.

### Q: How do you prevent duplicate workout generation?
**3-layer dedup**:
1. DB check — query for existing workout for (user_id, date)
2. Insert a placeholder row with `status='generating'` before calling Gemini
3. In-process set `_active_background_generations` tracks in-flight tasks

All three wrapped in `try/finally` so the placeholder/set entry always clears.

### Q: How do you handle background tasks?
FastAPI `BackgroundTasks` for non-critical writes (XP, trophies, cache population, email triggers). Never block the response on these. For workout generation, each upcoming day is scheduled independently.

### Q: How do you handle caching?
Four tiers:
- **L0 RAM**: Riverpod state + `DataCacheService` on the client
- **L1 SQLite**: Drift (offline mode, durable)
- **L2 in-process**: `ResponseCache` TTL dicts on the backend
- **L2.5 Redis**: cross-request cache, rate limiting
- **L3 Postgres**: source of truth

### Q: How do you handle offline mode?
- **Drift (SQLite)** stores workouts, food logs, sync queue locally
- **Three offline generation modes** (strict, no cross-mode fallback):
  1. Pre-cached server workouts (backend pre-generates 14 days ahead)
  2. Rule-based algorithmic generator (templates + exercise selector + progressive overload rules)
  3. On-device Gemma (270M/1B/4B depending on device capability)
- **Sync on reconnect** — `connectivity_plus` detects online, `workmanager` drains the sync queue with priority + exponential backoff
- **Conflict resolution** — client-wins for logs, server-wins for workouts

### Q: How do you handle schema changes / migrations?
Supabase migrations via SQL files. Deployed manually through the Supabase dashboard. Client-side Drift uses generated `.g.dart` files (committed to repo — no build_runner on CI).

### Q: How do you observe / debug the system?
- Structured logging with emoji prefixes (`🎯` milestone, `❌` error, `⚠️` warning) for scannable traces
- `core/logger.py` sets request-context (user_id, request_id) via `set_log_context`
- Dev log dashboard (`api/dev_logs.py`) when `debug=True`
- Discord webhooks for critical alerts
- Render logs for production

### Q: What about testing?
Honest answer: coverage is patchy. Unit tests on critical parsers (JSON extraction, prompt builders), integration tests for agent graphs with mocked LLM, manual E2E on devices. Philosophy per `CLAUDE.md`: test API integrations + parsing BEFORE deploying to device. No mocked DB in integration tests — uses real Supabase test project.

### Q: How would you scale this to 10K daily active users?
- Move backend off Render free tier → paid tier or GCP Cloud Run with autoscaling
- Redis → managed (Upstash / Elasticache)
- Add read replicas to Supabase
- Batch embeddings to ChromaDB (currently per-message)
- CDN for S3 exercise illustrations (CloudFront)
- Pre-warm Gemini connections (keep-alive)
- Queue workout generation via SQS/Celery instead of in-process BackgroundTasks

### Q: How would you scale to 1M DAU?
Different conversation. Agent routing becomes a bottleneck → move to a dedicated routing service. Vector DB sharded by user cohort. Gemini API cost becomes prohibitive → fine-tune a smaller open model (Llama, Qwen) for the 80% of routine queries, reserve Gemini for hard ones. Multi-region deployment.

---

## 6. Data Architecture Questions

### Q: What's in your Postgres?
~80 tables. Core entities: `users`, `workouts`, `exercises` (library), `workout_exercises` (junction), `food_logs`, `injuries`, `chat_messages`, `xp_events`, `trophies`, `challenges`, `subscriptions`. Plus per-feature tables for habits, fasting, hydration, progress photos, leaderboards.

### Q: How do you handle vector embeddings?
Dedicated **ChromaDB Cloud** collections:
- `exercises` — exercise library (name + description + muscle groups)
- `workouts` — user's past workouts for personalized recall
- `workout_feedback` — RPE, notes, completion signals
- `nutrition` — food database
- `saved_foods` — user's custom foods
- `social`, `custom_inputs` — hashtags, user vocab

Embeddings generated via Gemini embedding API. Queried per chat turn for context injection into the LLM prompt.

### Q: Why split PG + Chroma + S3 instead of one DB?
Different access patterns:
- **PG**: transactional, relational, RLS-enforced
- **Chroma**: similarity search at scale, different index type
- **S3**: binary blobs (videos, images) — wrong shape for PG

Trying to cram all three into Postgres works until you need sub-100ms vector queries or multi-GB blobs.

### Q: How do you keep Chroma and PG consistent?
Honestly — **eventual consistency**. PG is source of truth. Chroma is rebuildable from PG at any time (we have reindex scripts). Drift is tolerable because Chroma is used for RAG retrieval — stale embeddings just mean slightly worse recall, not data loss.

---

## 7. Challenges Faced

### Q: What was the hardest problem?
**Agent routing correctness.** Early versions had two failure modes:
1. User sends a food image, gets routed to the workout agent because message says "after my workout."
2. User `@mention`s an agent but the intent classifier overrides.

Fix: built the **media classifier** as a pre-router stage (Gemini Vision on the image BEFORE agent selection). Added priority ordering: `@mention` > media > intent > keywords > default. That single architectural change fixed ~80% of misroutes.

### Q: What else?
**JWT silent expiry.** Users would get logged out mid-session because the client was using a cached access token from `FlutterSecureStorage`. Fix: always read live from `Supabase.instance.client.auth.currentSession`, never cache.

**Gemini safety filter false positives.** "This workout will hurt tomorrow" triggered the harm filter and blocked responses. Fix: explicit `HARM_CATEGORY_*` threshold configuration.

**ChromaDB cold-start latency.** First query after idle takes 5-13 seconds. Fix: greeting fast-path skips RAG entirely; for non-greetings we just eat the latency on first message.

**Workout generation determinism.** Gemini occasionally skips exercises, duplicates, or invents exercises not in our library. Fix: (a) RAG-retrieve candidate exercises from Chroma and inject them into the prompt, (b) post-validate every exercise against the library, (c) retry up to 2x on validation failure.

**Offline mode mode-selection complexity.** Users got confused by the app silently falling back from on-device AI → rule-based → cached. Fix: strict mode boundaries, no silent fallback, explicit user control in Settings.

**Flutter build_runner curse.** `.g.dart` files either out of sync or CI couldn't regenerate them. Fix: commit generated files, pin Flutter version (3.38.10), never run build_runner.

### Q: A time you made a tradeoff.
**Single-agent-per-turn vs multi-agent collaboration.** Multi-agent is cooler and handles cross-domain questions better, but doubles the LLM cost, adds latency, and makes debugging much harder. Chose single-agent + good routing. Cross-domain cases are rare; users can ask a follow-up.

### Q: What would you do differently if you started over?
1. **Tests first** — retrofitting integration tests onto 9 LangGraph agents is painful
2. **Structured output from day 1** — early code parsed markdown-fenced JSON; should have used Gemini's native JSON mode from the start
3. **Single dev environment** — early on, local vs Render diverged in subtle ways
4. **Feature flags** — shipping AI features without the ability to kill them if Gemini misbehaves is scary
5. **Cost observability** — I under-tracked per-user Gemini costs until one user's food-image spam cost me $20 in a day (now: daily caps)

---

## 8. Behavioral / "Tell me about a time…"

### Q: Tell me about a bug you're proud of fixing.
**The invalidation cascade.** When a user reported an injury, their upcoming workouts still included the injured muscle group for days. Root cause: injuries were written to DB, but workouts were generated ahead of time and cached. Fix: built an `invalidate_upcoming_workouts()` function that deletes non-completed future workouts on injury/preference change; next `/today` call detects missing workouts and regenerates. Five trigger points now cascade correctly (injury, exercise avoidance, muscle avoidance, exercise queue).

### Q: Tell me about a design decision you reversed.
**Mocked data in development.** Early on I had mock Gemini responses so I could develop without API calls. Shipped a bug where the mock path leaked into prod. Now: **no mocks, ever** — documented in CLAUDE.md, enforced by convention.

### Q: How do you approach ambiguous requirements?
Look at what users actually do. When designing the chat agent routing, I analyzed my own chat logs (and friends' beta logs) to see which domains were most requested. Built routing to optimize for the common cases first.

### Q: How do you stay productive as a solo dev?
- **Claude Code as a pair programmer** — agent swarms for parallel file-owning tasks
- **Strict memory files** (`MEMORY.md`, `CLAUDE.md`) so I don't re-debug the same issue
- **Feedback files** — when I correct a Claude behavior, it's saved as a rule
- **No backwards-compat hacks** — solo codebase means I can refactor freely

---

## 9. AI-Specific Deep Dives

### Q: Explain prompt caching and whether you use it.
Gemini doesn't have Anthropic-style explicit prompt caching, but has implicit caching for repeated prompt prefixes. System prompts are stable per-agent, so prefix caching kicks in automatically. On Anthropic API I would use explicit `cache_control` breakpoints.

### Q: RAG — how do you chunk, embed, retrieve?
- **Chunk**: exercises aren't chunked — each exercise is a unit. Workouts chunked by workout. Food items are already atomic.
- **Embed**: Gemini's text-embedding-004 at ingest time
- **Retrieve**: top-k=5 per query with similarity threshold
- **Inject**: retrieved docs formatted as a compact prompt block ("Relevant past workouts: …")

### Q: How do you handle LLM hallucination in workout generation?
Post-validation. Every generated exercise is checked against the exercise library (exact name match + fuzzy fallback). Unknown exercises trigger a retry with a correction prompt: "Exercise X not in library. Pick from this list: …"

### Q: How do you evaluate agent quality?
Weakest part of the system, honestly. Currently: manual testing + user bug reports + chat log review. Would add: golden eval set (100 canonical queries with expected agents / tool calls), automated scoring on PRs, cost + latency P50/P95/P99 dashboards.

### Q: How do you handle multi-turn conversations?
`conversation_history` is a `List[Dict]` in state. Trimmed to 50K chars (~12.5K tokens) by dropping oldest first. Passed into every LLM call as `history` messages. Each turn is a fresh graph execution — no persistent agent state across turns (stateless agents, stateful conversation).

### Q: How do you handle images / multi-modal?
Base64-encoded images go into the `HumanMessage` content as a list: `[{"type": "text", ...}, {"type": "image_url", ...}]`. Videos → S3 → keyframe extraction (1-3 frames via `keyframe_extractor.py`) → frames sent to Gemini Vision same as images.

### Q: What's your cost per request?
Rough numbers:
- **Chat turn (text only)**: ~$0.0005 (Gemini Flash pricing, ~2K input / ~500 output tokens)
- **Food image analysis**: ~$0.003
- **Form video (3 keyframes)**: ~$0.01
- **Workout generation**: ~$0.005 (RAG + long output)
- **Media classifier**: ~$0.0001 (tiny prompt, 15 output tokens)

Daily media caps: 20 free / 100 pro, so worst-case free user is ~$0.06/day.

### Q: How would you add a new agent?
1. Create `langgraph_agents/new_agent/{state.py, nodes.py, graph.py, __init__.py}`
2. Define `NewAgentState(TypedDict)` extending `FitnessCoachState`
3. Write tool functions in `tools/new_tools.py` with `@tool` decorator
4. Build graph with nodes + edges
5. Register in `LangGraphCoachService.__init__`: `self.agents[AgentType.NEW] = build_new_agent_graph()`
6. Add routing rules: `AGENT_MENTION_PATTERNS`, `INTENT_TO_AGENT`, `DOMAIN_KEYWORDS`
7. Add `AgentType.NEW` to the enum

~2-3 hours end-to-end if tools are straightforward.

---

## 10. AI Accuracy & Evaluation

Honest upfront: **this is the weakest part of the system** and I'll tell the interviewer that. But I know exactly what I'd build.

### Q: How do you measure AI accuracy?
> "Honestly, today I don't — not systematically. I rely on manual testing, user bug reports, and reading chat logs. That's fine for a solo project at this scale, but it's not a defensible answer for production AI. If you asked me to fix it, here's what I'd build…"

Then describe:

**1. Golden eval set** — 100-200 canonical queries with expected outcomes:
- Expected agent selected
- Expected tool(s) called with expected args
- Expected action_data shape
- Expected response semantic category (e.g. "recommends a meal," "logs food," "refuses dangerously")

**2. Automated scoring on every prompt change**:
- Agent routing accuracy (exact match on agent selected)
- Tool-call accuracy (F1 on which tools were called, argument fuzzy match)
- Response quality via LLM-as-judge (GPT-4 or Claude scores on a rubric)
- Cost per query (token counts)
- Latency P50 / P95 / P99

**3. Hallucination tracking specifically for workout generation**:
- % of generated exercises that exist in the library (should be 100%)
- % of generated workouts that respect user constraints (injuries, equipment, duration)
- Drift detection: flag when these numbers drop week-over-week

**4. Production observability**:
- Log every LLM call with inputs/outputs/tokens/latency
- Dashboard for cost-per-user, cost-per-agent, cost-per-tool
- Alert when P99 latency or error rate spikes

**5. A/B testing prompts** — split traffic between prompt versions, measure user-facing metrics (workout completion rate, chat satisfaction).

**6. Human-in-the-loop** — a sample of 1-2% of responses flagged for human review, feedback loops back into the golden set.

### Q: Why didn't you build this?
> "Speed. I was optimizing for shipping features over measuring them. It's a bet — a bad one long-term. If this app gets real users I'd build evals before the next prompt change, not after. It's also the first thing I'd ask for budget on in a real team."

### Q: How would you know if a prompt change made things worse?
> "Today? Probably from a user complaint. That's the honest answer. With the eval harness above, I'd run the full golden set on every prompt PR, fail CI if accuracy drops more than 2% on any metric, and require an explicit waiver to merge."

### Q: What does "accuracy" even mean for an LLM?
Depends on the surface:
- **Agent routing** — binary correct/wrong. Measurable.
- **Tool calling** — F1 on tool names, fuzzy match on args. Measurable.
- **Workout generation** — constraint satisfaction (exercises in library, muscles not injured, duration fits). Measurable.
- **Chat responses** — fuzzier. LLM-as-judge on rubrics (helpful / safe / on-topic / correct). Correlates imperfectly with human judgment.

You measure what you can and acknowledge the gap for the rest.

---

## 11. Prompting & AI Dev Tooling

### Q: How did you approach prompting?
Five principles I landed on:

**1. Role-first system prompts.** Every agent starts with "You are [Coach Name], an expert [nutritionist/trainer/...]. You specialize in [list]. You MUST [constraints]. You MUST NEVER [anti-constraints]." Adding the role before the task gave me much more consistent tone.

**2. Response format as a first-class constraint.** If I need JSON, I say "Respond with ONLY valid JSON, no markdown, no prose." If I need a specific schema, I paste the schema in the prompt and give an example. Gemini's JSON mode helps but isn't perfect — belt-and-suspenders with parsing that strips markdown fences anyway.

**3. Tool docstrings are prompts.** LangChain turns every `@tool` function's docstring + type signature into the tool schema sent to the LLM. So a docstring like "Analyzes a food image and logs it." is way worse than "Analyzes a food image to identify foods, estimate calories and macros, and optionally log to the user's food diary. USE WHEN: user uploads a photo of food. DO NOT USE WHEN: user asks for nutrition advice without an image." The quality of tool selection lives in docstrings.

**4. Context comes last, instructions come first.** I build prompts as `[role] → [instructions] → [constraints] → [user context like today's workout, recent meals] → [user message]`. This survives context truncation better because the last thing in the prompt has the strongest effect on the output.

**5. Test prompts against real distributions, not hypotheticals.** I'd write a prompt, try one query, think "this works," then ship it. Then user messages would hit cases I never tested. Now I keep a list of real user messages from chat logs and run prompt changes against that set before shipping.

### Q: You worked with Claude Code / AI dev tools. How?
Heavily. This is where the "vibe coding" bit comes from — but it's structured vibe coding.

**CLAUDE.md** — project-level instructions Claude Code reads on every session. Mine has:
- Testing principles ("no mock data," "test parsing before deploy")
- Error-handling standards (try-catch template, user-friendly messages)
- UI standards (Material 3, 8px grid, 14sp min)
- Logging prefixes (🎯 milestone, ❌ error)
- Gemini integration gotchas (safety filters, JSON extraction, robust parsing)
- Known issues list

The effect: Claude arrives at every session already knowing the codebase conventions. No re-explaining.

**Memory files** — per-topic memory in `~/.claude/projects/.../memory/`:
- `feedback_*.md` — rules I've given Claude that it saved ("always use lbs not kg," "never silently fall back," "always test locally first")
- `project_*.md` — tribal knowledge about the codebase (Flutter pinned to 3.38.10, don't run build_runner, S3 prefix is `ILLUSTRATIONS ALL/`)
- `user_*.md` — my preferences, timezone

Over ~6 months of use this has compounded into a system that understands my codebase better than most human contractors would after a week.

**Subagents / agent swarms** — when I have parallel work (e.g. refactoring 5 unrelated files), I spawn multiple Claude Code subagents with exclusive file ownership. Prevents edit conflicts, 3-5× faster than sequential.

**MCP servers** — Model Context Protocol servers give Claude direct tool access:
- **Supabase MCP** — Claude can query my DB, apply migrations, check RLS policies directly. Huge for "check if this foreign key exists" type questions.
- **Playwright MCP** — browser automation for testing flows.
- **Gmail / Google Calendar MCPs** — scheduled tasks.

MCPs turned Claude from "code generator" into "teammate that can actually execute."

### Q: So how much of this app did you write vs. Claude wrote?
Honest split:
- **Architecture decisions** — me. Which agents, which DB, which pattern.
- **First drafts of code** — ~70% Claude-generated with detailed spec from me.
- **Debugging** — ~50/50. Claude catches obvious stuff fast; hard bugs need human intuition about what's actually wrong.
- **Prompts** — mostly me, iterated. Prompting well requires understanding the domain, which Claude doesn't.
- **Review & integration** — me.

The lesson: Claude is phenomenal leverage IF you understand what you're building. It's a force-multiplier on clarity, not a replacement for it. Give it a muddy spec, you get muddy code fast.

### Q: What's the workflow for a new feature with Claude Code?
Roughly:
1. **Research phase** — dispatch an `Explore` subagent to map the relevant code
2. **Plan phase** — write a Plan in the session, iterate until it's right
3. **Build phase** — Claude implements, I review each diff
4. **Test phase** — manual + whatever automated tests exist
5. **Memory update phase** — if I corrected Claude or learned something non-obvious, save it as a memory file

The memory step is what makes subsequent sessions compound.

---

## 12. More Medium Questions

### Q: What's RLS and why does it matter?
Row-Level Security — Postgres feature Supabase exposes. You write SQL policies like "users can only SELECT rows where user_id = auth.uid()". Enforced at the DB layer, not application code. Means even if my backend had a bug that forgot to filter by user_id, the DB would still refuse. Defense in depth.

### Q: What's the difference between Redis and an in-process TTL cache?
In-process is faster (no network hop) but doesn't survive restart and isn't shared between instances. Redis is shared + durable but adds latency. I use both: in-process for hot per-request data, Redis for cross-request cache (user profile, rate-limit counters, deduplication keys).

### Q: Why Server-Sent Events for streaming instead of WebSockets?
SSE is one-way (server → client), which is all I need for streaming a workout generation. WebSockets would be overkill and need more infra (connection upgrade, heartbeat, reconnect logic). SSE works over plain HTTP, survives most proxies, has built-in reconnect on browsers. Simpler problem, simpler tool.

### Q: Why Flutter not React Native?
Mostly: Dart + Flutter gave me hot reload and consistent rendering across iOS/Android. React Native would have been fine too. Secondary: I'd done a Flutter project before, none in RN. In a team setting with React devs I'd pick RN.

### Q: Why Riverpod over Bloc or Provider?
Riverpod's `.family` and `.autoDispose` are incredible for a feature-heavy app. I can write `workoutProvider.family((workoutId) => ...)` and get per-workout state for free. Bloc is more ceremonious. Provider was the v1 — Riverpod fixes its context-dependency issues.

### Q: What does freezed do?
Generates immutable data classes with `copyWith`, equality, and JSON serialization from a single source of truth. Stops whole categories of bugs — accidental mutation, forgetting to update `==`, forgetting to update fromJson.

### Q: What's Drift and why use it over sqflite?
Drift (formerly Moor) is a type-safe SQLite ORM for Dart. You write schemas, it generates CRUD code. Migrations are explicit. The alternative (sqflite) is raw SQL strings with no type safety. Picked Drift for the offline mode because I didn't want 7 tables of stringly-typed bugs.

### Q: What does `asyncio.gather()` do in your backend?
Runs multiple awaitables in parallel. In `workouts/today.py`, three independent Supabase queries run concurrently instead of sequentially — takes the slowest one instead of sum. For 3 queries at 150ms each: 450ms sequential → 150ms parallel.

### Q: What's a semaphore and when did you need one?
A semaphore is a counter with acquire/release — limits how many coroutines can hold it at once. I use `asyncio.Semaphore(10)` on vision calls to stop the backend from spawning 50 concurrent Gemini requests if 50 users upload images at the same moment. Without it I'd blow rate limits or OOM.

### Q: How does FastAPI's `BackgroundTasks` differ from Celery?
`BackgroundTasks` runs *after the response is sent, in the same process*. Fine for quick fire-and-forget writes. Celery runs in a separate worker process/machine, survives crashes, has retries. BackgroundTasks is right for "increment a counter"; Celery is right for "process this video." I use BackgroundTasks today; would add Celery if background workloads grew.

### Q: What's a JWT and how does your backend validate one?
JWT = JSON Web Token — a signed string with three parts (header.payload.signature). Client sends it in `Authorization: Bearer …`. Backend verifies the signature against Supabase's public key, extracts `user_id`, uses it for all DB operations. Stateless — no server-side session storage.

### Q: How does the Flutter client decide what to do with `action_data`?
Every chat response has an optional `action_data: {action: "log_food" | "update_setting" | "navigate" | ..., payload: {...}}`. In `chat_screen.dart`, a switch on `action` dispatches to handlers: `_handleFoodLog`, `_handleSettingChange`, `_handleNavigate`. This keeps the agent's NLG response separate from the side-effect — the text is what the user reads, the action_data is what the app does.

### Q: What does the media classifier actually return?
A JSON like `{"content_type": "food_plate", "confidence": 0.9}`. 10 possible types. Routes into the agent selector as one signal among several. If confidence is low or type is `unknown`, fall through to the next priority layer (intent classifier).

### Q: What's a webhook and where do you use them?
HTTP callback from another service into yours. I use them for:
- **SendGrid email events** — bounces, unsubscribes (`email_webhooks.py`)
- **RevenueCat subscription events** — new sub, cancellation, refund
- **Supabase auth events** — new user signup triggers welcome email

### Q: Why do you read the Supabase session live instead of caching the access token?
Access tokens expire (~1 hour). Refresh tokens outlive them. Supabase's client auto-refreshes in the background, but if I cached the access token in `FlutterSecureStorage`, I'd use stale tokens after refresh and get 401s. Reading live from `Supabase.instance.client.auth.currentSession` guarantees I always have the current one.

---

## 13. More Hard Questions

Answers are written in first-person, conversational — how I'd actually say them out loud. Each opens with the short version and then earns the deeper answer if the interviewer keeps digging.

### Q: Walk me through how tool calling actually works under the hood.
> "OK, so tool calling isn't magic — it's just structured output. When I call `llm.bind_tools(TOOLS)`, LangChain takes each tool function's name, docstring, and type signature, turns that into a JSON schema, and pushes it into the Gemini request as available functions. Gemini's response either has a `tool_calls` field with the function name and arguments it picked, or it doesn't and just returns text. My code checks for `tool_calls`, and if present, I run each function with the provided args, wrap the result in a `ToolMessage`, append it to the message history, and re-invoke the LLM. On the second call, Gemini sees the tool result and generates a natural-language response about it. So two LLM calls per tool-using turn. Workout agent sometimes forces `tool_choice='check_exercise_form'` to stop the LLM from skipping the tool when I know it needs to run — that's a deterministic override."

### Q: What if the LLM calls the wrong tool, or hallucinates a tool that doesn't exist?
> "The hallucination case is rare because LangChain only sends valid tools in the schema — Gemini physically can't pick something outside that list without producing invalid JSON, which LangChain rejects. Wrong tool is more common. My defense is tight docstrings — I say when to use the tool AND when not to. I also use `tool_choice` to force the right one when I know from context what should run. For Workout specifically, if a video is attached, I force `check_exercise_form` because there's no valid interpretation where the user uploaded a video and didn't want form analysis."

### Q: How do you handle an LLM call that times out or fails?
> "Gemini calls have a 30-second timeout. On failure there's exactly one retry with different binding — specifically, I strip the `tool_choice` because thought-signature errors can loop otherwise. After that, I raise. The error propagates to the orchestrator, gets stored in `state['error']`, and returned to the client as a user-facing message. I don't silently fall back to a degraded response because that hides bugs — if Gemini is broken, I want to know immediately, not six weeks later when I realize my responses are worse. That's a design stance, not universally correct — some apps would rather degrade gracefully."

### Q: How do you handle concurrent workout generation for the same user?
> "Three layers of dedup, all necessary. One: before starting, I check the DB for an existing workout with that user_id and date. If it exists and isn't cancelled, return it. Two: if not, I insert a placeholder row with `status='generating'` — this is atomic and racy, but that's the point. Any second request hitting this code path will see the placeholder and bail. Three: there's an in-process set `_active_background_generations` keyed on `user_id:date` that catches requests arriving on the same backend instance within milliseconds of each other. All three are wrapped in `try/finally` so the placeholder and set entry always clear, even on exception. The reason all three exist is they protect against different races — layer one protects against ordinary re-requests, layer two protects against concurrent requests to the same DB, layer three protects against concurrent in-process calls. Miss any one and I've had bugs."

### Q: Your agent orchestrator picks one agent per turn. What if the user asks a multi-domain question?
> "Yeah, this is a real tradeoff. If someone says 'my knee hurts, what should I eat to recover?' I'll pick either Injury or Nutrition but not both. The router will currently prioritize the injury keyword and route to Injury, which then gives a hand-wavy nutrition answer. Bad UX. The right fix is a multi-agent collaboration pattern — something like a supervisor that decomposes the query and delegates to both agents, then synthesizes. I haven't built that because it doubles the LLM cost and latency for a case I see maybe 2% of the time. What I tell users to do is ask follow-up questions. What I'd build if I had more traffic is: a lightweight classifier that detects multi-domain queries, and if confident, runs two agents in parallel and merges the outputs. Not cheap, but the right call at scale."

### Q: Explain your RAG pipeline in detail. Chunking, embedding, retrieval, reranking.
> "Sure. First, I don't chunk aggressively because my documents are already atomic — each exercise in the library is one document, each user workout is one document. That keeps retrieval clean. At ingest time I embed with Gemini's text-embedding-004, store in ChromaDB Cloud with metadata like muscle_group, equipment, difficulty. Retrieval is top-k=5 with a similarity threshold to filter noise. I don't rerank today — the domain is narrow enough that top-5 from similarity gets me the right exercises most of the time. Where it breaks down is when a user says 'something like squats but easier' — semantic similarity puts barbell squats first because the literal word matches. A cross-encoder reranker would catch that 'easier' should push lunges or wall sits up. That's on the to-build list. For injection, the retrieved docs get formatted into a compact prompt block with metadata — not raw text — and inserted before the user message."

### Q: How do you prevent a runaway cost scenario from the LLM?
> "Four layers. One: daily media caps per user, 20 for free and 100 for pro, tracked in a `chat_media_usage` table. Two: a backend-wide `asyncio.Semaphore(10)` on vision calls so even under a traffic spike I can't have more than 10 concurrent vision requests. Three: conversation history trimmed to 50K chars before every LLM call — stops runaway context growth. Four: rate limiting at the endpoint level. What I'm missing is per-user cost tracking in real time — right now I'd see an abuse pattern in a daily Gemini invoice, not immediately. If I had one afternoon to improve this, I'd pipe per-request token counts into a metric and alert when any user crosses a threshold."

### Q: Why LangGraph and not CrewAI, AutoGen, or rolling your own?
> "I looked at all of them. CrewAI and AutoGen are higher-level — they hide the graph and give you roles, delegation, conversation patterns. That's nice for a demo, frustrating for production because you've got less control over the execution path. Rolling my own is feasible but I'd end up rebuilding 80% of LangGraph in six months. LangGraph is the middle ground: it gives me a typed state machine with explicit nodes and edges, and the conditional-edge pattern fits my 'one agent per turn' decision perfectly. Also, LangGraph is built by the LangChain team so I get the tool-calling integration for free. The downside is LangGraph moves fast and breaks APIs — I've had to pin versions more than I'd like."

### Q: How do you observe an LLM pipeline? What does 'monitoring' mean here?
> "Different from traditional monitoring. Obvious stuff: latency, error rate, throughput — standard. Specific to LLMs: token usage per request, per user, per agent, per tool. Tool-call success rate. Tool-call selection accuracy — when I have an eval set, this becomes a first-class metric. Response length distribution — sudden drop can signal the model got more conservative. Safety filter block rate — went up once when I changed a prompt in a way that inadvertently tripped safety. Cost per request rolling P50/P95. And the qualitative one: a random 1% sample of real responses logged for human review. Without that, you can have all the dashboards green and still be producing garbage output."

### Q: Tell me about a race condition you fought.
> "Workout generation, early on. User finishes onboarding, the sign-in screen fires off an early-generation request, and the loading screen ALSO fires a request on mount. Two requests, same user, same date, arriving within 200 milliseconds. Both would go to Gemini, both would write to Postgres, user ends up with two workouts for the same day. Fix was the three-layer dedup I mentioned — but finding it took me a week because it was intermittent. What taught me the lesson: log-first debugging. I added a log line with a request-ID to every path that could generate a workout, then grep'd for users with multiple workouts and traced back. Once I could see the two request IDs hitting within 200ms, the root cause was obvious."

### Q: Your backend is on Render. What happens during a cold start?
> "Render's free tier sleeps instances after 15 minutes of inactivity. Cold start is 10-30 seconds because it rebuilds the container, downloads dependencies, boots Uvicorn, loads all the service singletons. That's unacceptable for a user waiting on a chat response. Two mitigations: first, a three-phase startup in `main.py` — critical path boots fast, background warmup loads heavier services, non-critical services lazy-init on first use. Second, I have a cron that pings the backend every 14 minutes to keep it warm. Would I do this in production? No. In production I'd be on a paid tier with no sleep, or on Cloud Run with min-instances set to 1. But for a side project at $0/month, it works."

### Q: What's the hardest tradeoff you made on this project?
> "Evaluation vs shipping. I knew — and know — that running LLM features without a proper eval harness is technically irresponsible. I did it anyway because I needed to ship to see if users would care. The bet was: gather enough usage to know which agents matter, then build evals for those. So far the bet is OK — I know which agents are used most, which prompts need work, which edge cases recur. But it's a bet I could lose. If I shipped a prompt change tomorrow that silently regressed the nutrition agent's accuracy by 20%, I'd learn about it from user complaints, not a dashboard. That's technical debt with a teeth."

### Q: How do you handle long conversations that exceed the context window?
> "Today, naively — trim to 50K characters by dropping oldest messages first, keep the most recent. That loses context. In a better world I'd build a summarization step: when history exceeds N turns, summarize the older half into a compact 'user context' block and prepend that as a system message, then pass only recent turns verbatim. That way you preserve the signal (what the user cares about, their goals, past decisions) without the full history bloat. Hasn't been a pressing issue because most conversations are short, but for a power user chatting for a week, the current approach degrades."

### Q: How would you test an agent end-to-end?
> "Integration test with a mocked LLM that returns canned responses. You can't reliably test against a real LLM because the outputs aren't deterministic. So: stub `llm.ainvoke` to return a scripted `AIMessage` with a specific `tool_calls` field, run the graph, assert on the final state. For each agent I'd have a handful of tests: tool-call path, no-tool path, error path, forced tool_choice path. Then above that, a separate integration layer with the real LLM but against the golden eval set, checking that the graph's output distribution matches expected distribution. Two different kinds of tests answering two different questions — the unit tests check that my graph's logic is correct, the eval tests check that the LLM is behaving."

### Q: What happens if two tools need to run but depend on each other?
> "Today, the LLM decides the order. It'll emit one tool_call, I run it, return the result, LLM decides whether to call another. Sequential. That works because most of my tools are independent — `get_nutrition_summary` doesn't depend on `log_food_from_text`. Where it would break is something like 'log this meal and then show me remaining calories' — LLM might call both in parallel, second one reads stale DB state. I haven't hit this bug because LangChain typically emits tool calls one at a time in conversation mode. If I needed strict ordering I'd either (a) force it in the prompt, (b) compose the two tools into one higher-level tool, or (c) add a post-tool-call step that re-queries state."

### Q: How do you think about privacy for user health data going to Gemini?
> "Two layers. One: what goes in — I send user profile data (age, weight, goals), recent logged data (today's food, today's workout), and the user's message. I do NOT send anything identifying like email, full name, or DB user IDs. Gemini sees a de-identified profile. Two: Gemini's data policy. On the paid Gemini tier, data isn't used for training. That's the legal protection. For truly sensitive health data — things like diagnosed conditions, medications — I'd want explicit user consent before sending to any third-party LLM. This is a consumer fitness app, not a medical device. If I were building a medical app I'd need HIPAA, BAA with Google, audited data flows. Different product, different bar."

### Q: If you had to cut costs by 50%, what would you do?
> "Two moves. First, batch and cache — right now every chat request hits Gemini fresh. A lot of those are repetitive ('what should I eat before a workout?'). If I added semantic caching — hash the prompt signature, check if a similar response was generated in the last hour — I could serve maybe 20% of requests without an LLM call. Second, route by cost — easy queries to a cheaper model (Gemini Flash 3 → Flash 3 Lite or an open model), hard ones to the expensive one. Today everything goes to the same tier. A routing layer that picked the cheapest capable model for each query would cut the remaining bill by maybe 40%. Combined: ~50%+ reduction. Downside: added latency from the cache check, added complexity from the routing layer, more places for bugs to hide."

### Q: You mentioned no silent fallbacks — defend that design.
> "Sure. The argument *for* silent fallback is user experience: when Gemini is flaky, show something degraded rather than an error. The argument *against* — the one I took — is that silent fallback hides bugs. If the Nutrition agent is broken and I silently fall back to a canned response, users get worse answers and I don't know. A week later I've lost trust and still haven't found the bug. Explicit errors surface fast. The tradeoff is: occasional visible failures instead of constant invisible degradation. For a solo-dev app where I can't afford invisible bugs, it's the right call. For a team with SLA obligations to enterprise customers, the opposite call might be right — you'd want graceful degradation with alerts to ops."

### Q: Walk me through how you'd add streaming to the chat response (token-by-token).
> "Right now chat responses are non-streaming — client waits for the full response, then renders. Workout generation is SSE-streamed, chat isn't. To add: change the LangGraph agent's final response node to use `llm.astream()` instead of `ainvoke()`. Wrap that in a FastAPI `StreamingResponse` that yields SSE chunks. Client side, switch from `dio.post` to an SSE reader, append tokens to the rendered message as they arrive. Three gotchas: one, tool-calling agents can't stream — the LLM has to emit the full `tool_calls` object before I can run tools. So streaming only works for the autonomous path (Coach responding without tools) and the `response_after_tools` phase. Two, action_data has to be extracted at the end, not mid-stream, so I need a terminator event. Three, error handling across a stream is more awkward — what if the stream fails at token 400 of 500? Need a cleanup path on both ends."

---

## 14. User Analytics, Retention & Growth

The honest framing up front, since this is another "built half, didn't build the other half" story:

> "I built a lot of retention *mechanics* — lifecycle emails, push nudges, streaks, XP, trophies, challenges, year-in-review, comeback detection. But I didn't build retention *measurement* — no PostHog, no Amplitude, no cohort dashboards. So I have the levers but not the numbers. That's a gap I'd close immediately if this had real traffic."

### What I built (retention mechanics)

**Email lifecycle system** (`backend/services/email_lifecycle.py` + `email_cron.py`):
- Onboarding drip (welcome → day 1 → day 3 → day 7 check-ins)
- Re-engagement sequences for users who go quiet
- Subscription cancellation "ladder" (`email_cancel_ladder.py`) — progressively better offers as churn risk rises
- Transactional emails (workout ready, milestone hit)
- Hourly cron, branches on user-local time (morning/midday/evening/quiet), name-personalized subject + body, per-category unsubscribe, vacation mode

**Push notification system** (`push_nudge_cron.py` + `notification_service.py`):
- Workout reminders based on user's scheduled days + preferred time
- Streak-protection nudges ("you'll lose your 12-day streak if you don't train today")
- Meal-logging reminders if no food logged by X PM user-local
- Hourly cron, same user-local time branching as email

**Gamification** (XP / trophies / achievements):
- `xp_endpoints.py` — XP earned per workout, food log, streak day
- `trophy_triggers.py` — milestone trophies (first workout, 10-day streak, 100 workouts, etc.)
- `achievements.py` — badge system for longer-horizon goals
- Leaderboards (`leaderboard.py`) for social comparison

**Comeback mode** (`services/comeback_service.py`):
- Detects users absent 14+ days, OR explicit `comeback_mode` flag
- Auto-reduces workout volume (`volume_multiplier`), intensity, exercise count on return
- Prompt-injects "comeback context" into Gemini workout generation so plans are age-appropriate
- Safeguards: accounts <14 days old skipped, users with no history treated as new

**Wrapped / year-in-review** (`services/wrapped_service.py`):
- Spotify-Wrapped-style end-of-year recap
- Total workouts, favorite exercise, longest streak, top muscle group, PR milestones
- Shareable card UI in Flutter — built-in viral loop

**Challenges** (`api/v1/challenges.py`):
- Time-boxed community challenges ("30-day squat challenge")
- Social accountability — other participants visible

**Habits & streaks**:
- `habits.py` — habit tracking with streak counting
- Streak display prominent in UI — core engagement mechanic

### What I DIDN'T build (analytics measurement)

Grep the codebase for PostHog / Amplitude / Mixpanel / Firebase Analytics — **zero results**. No product analytics SDK on the client. No funnel tracking. No cohort analysis. No A/B testing framework.

What I do have:
- Supabase Postgres (can query for anything retrospectively)
- Structured logging on the backend (latency, errors)
- Render logs (request-level)

What I don't have:
- DAU/WAU/MAU dashboards
- Funnel conversion visibility (signup → onboarding complete → first workout → 7-day retained)
- Cohort retention curves
- Feature adoption metrics
- User session recordings
- Event-level behavior tracking
- A/B test infrastructure

**Why this is bad**: I'm shipping retention features without knowing if they work. My email lifecycle could be driving +15% D7 retention or -5% — I can't tell. I'm running on product intuition, which is fine at solo-scale, broken at any real scale.

---

### Interview Q&A — medium

### Q: How do you measure retention today?
> "Honestly, I don't — not in a product-analytics sense. I can query Postgres for 'how many users active in the last 7 days' if I write the SQL, but I don't have dashboards. For a real product I'd wire up PostHog or Amplitude day one. My excuse is solo-dev prioritization; my honest answer is I should have done it earlier."

### Q: What analytics stack would you add?
> "PostHog is my default pick — open-source, self-hostable, covers product analytics + session replay + feature flags + A/B tests in one tool. If I'm OK with SaaS, Amplitude for product analytics + LaunchDarkly for flags. The key is one source of truth for events — I don't want analytics in one tool, flags in another, session replay in a third."

### Q: What events would you track?
Core event taxonomy, in priority order:
1. **Lifecycle**: `sign_up`, `onboarding_started`, `onboarding_completed`, `first_workout_generated`, `first_workout_completed`
2. **Activation**: `workout_completed`, `food_logged`, `chat_message_sent`, `form_video_analyzed`
3. **Retention**: `app_opened`, `session_started`, `streak_day_added`, `streak_broken`
4. **Monetization**: `paywall_viewed`, `subscription_started`, `subscription_cancelled`, `subscription_renewed`
5. **Feature adoption**: `@nutrition_agent_used`, `offline_mode_activated`, `wrapped_viewed`, `challenge_joined`

Each event tagged with user_id, session_id, timestamp, platform, subscription_tier.

### Q: What's your North Star metric?
> "If I had to pick one, **Weekly Active Users who completed ≥1 workout**. Workouts are the core activity — food logging and chat are secondary. A user who chats every day but never works out isn't getting the product's value. DAU would be too noisy, MAU too lagging. WAU with a completion filter captures intent."

### Q: What's your engagement hierarchy?
Roughly (in terms of what I'd bet predicts retention):
1. **Completed workout in first 48 hours** — best predictor of D30 retention
2. **Onboarding completion rate** — biggest funnel leak
3. **7-day streak achieved** — users who hit this rarely churn in the next 30 days
4. **First paywall view timing** — too early kills retention, too late leaves money

### Q: How do you think about D1 / D7 / D30?
Haven't measured, but target benchmarks for a consumer fitness app:
- **D1**: 40-50% (industry good is 40%+)
- **D7**: 20-25%
- **D30**: 10-15%
- **D90**: 5-8%

Below these numbers at scale = product-market fit problem, not a retention-tactics problem. Above = scale the acquisition loop.

### Q: How do you reduce onboarding drop-off?
What I built:
- **Early workout pre-generation** — fires during onboarding so first workout is ready when user finishes (reduces "I'm done onboarding, now what?" dead time)
- **AI-driven onboarding** — no hardcoded question templates, agent decides what to ask next based on what's missing. Feels more natural than a 20-question form.
- **Quiz-style UI** — single-question screens, not long forms
- **Skip-ability** — most onboarding fields have smart defaults, user can skip and return later

What I'd add if I could measure it:
- Step-by-step funnel analytics to find the exact drop-off points
- A/B test onboarding length (shorter vs fuller)
- Contextual nudges for users who pause mid-onboarding

---

### Interview Q&A — hard

### Q: Walk me through your retention strategy.
> "Three layers, and I'll own the gap at the end. Layer one is habit formation — streaks, workout reminders at the user's scheduled time, in-app XP and trophies for consistency. Habit mechanics do the heavy lifting because fitness is fundamentally a habit product. Layer two is re-engagement — users who go quiet get lifecycle emails, push nudges, and when they come back, comeback mode auto-reduces workout intensity so they don't quit again on day one. The 14-day absence threshold came from my intuition, not data — would tune with real numbers. Layer three is social and narrative — challenges give time-boxed goals, leaderboards give comparison, wrapped gives a reflective moment at year-end that drives sharing. So the strategy is: build the habit, catch the drop-outs, create narrative moments. The gap is I'm not measuring any of it — I built the mechanics from principles, not from cohort data showing what moves the needle. That's the first thing I'd fix."

### Q: How would you run an A/B test on a retention feature?
> "Today I can't — no infrastructure. Here's what I'd build. First, a feature flag service — PostHog has one built in, or LaunchDarkly. Every user gets a stable hash-based assignment to a variant. Client reads the flag, server logs the variant on every event. Second, an experiment schema — experiment ID, variants, assignment algorithm, start/end date, success metric, guardrail metrics. Third, a readout dashboard — for the current experiment, show variant A vs B on the success metric with a p-value. The trap I'd avoid: running 20 experiments in parallel with no multi-test correction, declaring winners on noise. One experiment at a time, pre-registered success metric, run to sufficient power. For a retention test specifically — say, 'does a 3-day onboarding drip email improve D7?' — I'd need two weeks of data and maybe 2000 users per arm to see a 5% lift with confidence. That's the honest timeline."

### Q: How do you prevent churn?
> "Three mechanisms, in order of impact I'd guess. One: the cancel ladder — when a user hits the cancel button in-app, they go through a flow that offers progressively better saves. Pause for a month, 50% off for three months, free month. This isn't manipulative, it's meeting users who churn for 'life got busy' reasons with the right friction. Two: comeback mode — for users who lapse without cancelling, lower the barrier to re-engagement. The worst churn is silent — user stops opening the app, subscription auto-renews, they eventually cancel without engaging. Push and email re-engagement before it's too late. Three: the streak mechanic — the single strongest reason users say they open the app is 'I don't want to lose my streak.' Loss aversion is a more powerful driver than reward in a habit product. What I haven't built: predictive churn modeling — train a model on behavioral signals (session frequency, workout completion rate, engagement with chat) to predict 14-day churn probability, and target the top-decile-risk users with a save flow. Would pay for itself at scale."

### Q: How do you segment users?
> "Today I don't, beyond subscription tier (free / pro) and the explicit user-provided data (goals, fitness level, equipment). At scale I'd segment by behavior: new user (under 14 days), engaged (3+ workouts/week), casual (1-2/week), at-risk (was engaged, now quiet), dormant (14+ days absent). Each segment gets different messaging and different feature prioritization. The at-risk segment is the highest-leverage — by the time someone is dormant, you've mostly lost them, but at-risk users are still reachable."

### Q: What's your notification strategy? How do you avoid notification fatigue?
> "The core principle is **every notification type has a user-facing toggle, a per-category unsubscribe, quiet hours, and vacation mode**. No notification ships without user control — I documented this as an explicit rule after shipping a couple of noisy features. Beyond that, the frequency cap is implicit: I send workout reminders on scheduled workout days only, streak-protection pushes only when a streak is at risk, lifecycle emails only on meaningful day boundaries. The branching logic checks the user's local time — no 6 AM nudges. And importantly, I branch on user state — if a user worked out at 10 AM, I don't send them a 'don't forget to work out!' push at 5 PM. That coordination between 'what the user has done today' and 'what to say to them' is the hardest part of getting notifications right, and it's where most apps fail."

### Q: How do you think about the free-to-paid conversion funnel?
> "Haven't built formal analytics but here's the loose model. New user signs up, completes onboarding, gets their first AI-generated workout — that's the activation moment. Paywall placement is: don't paywall the first workout, don't paywall chat for the first week, but paywall advanced features like multiple gym profiles, form video analysis, offline on-device AI. So the user sees value first, hits a wall for value later. Conversion rate I'd guess is 3-5% of activated users, industry-standard for consumer fitness. Things I'd test: paywall timing (day 3 vs day 7 vs hitting a premium feature), price points (monthly vs annual vs lifetime), trial length (7 day vs 14 day). Things I'd measure first: where in the funnel users drop — activation, paywall view, paywall conversion, second-month renewal. Each has a different fix."

### Q: What would you measure to know if the AI features are working?
> "Two levels — immediate quality and long-term retention impact. Immediate quality: did the user take the action the AI suggested? For food logging, did they confirm the logged meal or edit it heavily (edit rate is a quality signal). For workout generation, did they complete the generated workout or regenerate it (regeneration rate = dissatisfaction signal). For chat, did the user follow up positively or re-ask the question. Long-term: cohort users into 'heavy AI feature users' vs 'light users' and compare D30 retention. If the AI features aren't moving retention, they're expensive cost without a moat. The hypothesis I'd want to confirm is that chat users (especially those who use multiple agents) retain 2-3x better than non-chat users — because it implies investment and personalization in the relationship. If that hypothesis doesn't hold up, chat isn't the moat I think it is."

### Q: How does personalization drive retention?
> "Four personalization signals in the app: user's explicit preferences from onboarding (goals, equipment, injuries), behavioral history (past workouts, food logs, feedback), derived preferences (inferred intensity tolerance from RPE, inferred food preferences from recent meals), and real-time context (today's workout when asking about meals, recent injuries when generating workouts). The more of these signals the app has, the less the user can get the same experience elsewhere. That's the retention moat — switching costs. A new fitness app starts me at zero; Zealova knows my injuries, my PRs, my preferences, my patterns. The risk is that personalization quality decays if signals are stale — I haven't built a feedback loop to refresh preferences when behavior shifts. If a user injures their knee and shifts to upper-body-only, the app should detect that and update the inferred profile. Today it doesn't; that's a bug masquerading as a missing feature."

### Q: How do you think about virality?
> "Three loops in the app. One: wrapped / year-in-review — Spotify-style shareable cards. Built-in viral moment one time a year. Two: challenges — users invite friends to join a challenge, becomes social proof for the invited user to try the app. Three: form video analysis — people share AI-analyzed form videos on social media, functions as a product demo. What I haven't built: explicit referral rewards, social feeds, workout-sharing URLs. The conventional viral mechanics are on the roadmap but they're lower priority than fixing retention because viral without retention is a leaky bucket. Growth per dollar of engineering is higher from fixing a 20% D7 to a 25% D7 than from adding a referral program to an app that churns users after two weeks."

### Q: What metric would you pay the most attention to in the first 6 months?
> "Onboarding-to-first-workout-completed conversion rate. Every other metric is downstream. If users aren't completing a first workout, nothing else matters — retention is zero, monetization is zero, word-of-mouth is negative. My sub-goal for this would be: 60%+ of users who start onboarding complete their first workout within 48 hours. That's aggressive but achievable with good onboarding UX and early workout pre-generation. Below 40% is a product problem that can't be fixed with marketing spend — fix the product first. Between 40-60% is a tactical UX optimization problem — A/B test onboarding length, first-workout difficulty, reminder timing. Above 60% is 'stop optimizing, focus on retention and monetization.' The beauty of this metric is it forces me to confront the 'is the product actually good' question early, before I've invested in acquisition that won't pay back."

---

## 15. Biggest Technical Regret

> "Not building an eval framework for the agents early. I iterate on prompts by hand and eyeball the output. Scaling that past 9 agents and 23 tools is unsustainable, and I know it. The excuse is that I prioritized shipping — which is defensible — but the honest answer is I knew evals would slow me down and I didn't want to pay that cost. If I restarted, I'd build a 50-query golden set on week one and refuse to merge prompt changes that regressed it. That's probably the single highest-leverage thing I could add today."

---

## Cheat-sheet numbers (memorize these)

| Metric | Number |
|---|---|
| Backend LOC (roughly) | ~80K Python |
| Frontend LOC | ~100K Dart |
| API endpoints | 80+ routers |
| LangGraph agents | 5 chat + 4 auxiliary = 9 |
| Total @tool functions | 23 |
| Postgres tables | ~80 |
| ChromaDB collections | 7 |
| Media classifier types | 10 |
| Prompt-injection patterns sanitized | 9 |
| Daily media cap (free/pro) | 20 / 100 |
| Workout gen dedup layers | 3 |
| Invalidation triggers | 5 |
| Offline generation tiers | 3 (pre-cache / rule-based / on-device Gemma) |
| On-device Gemma sizes | 270M / 1B / 4B |
| Conversation history trim | 50K chars (~12.5K tokens) |
| Exponential backoff sequence | 2s → 4s → 8s → 16s → 30s |

---

## Closing tips

- **Speak in terms of trade-offs**, not just decisions. Every choice had an alternative you rejected.
- **Lead with the problem**, not the tech. "Users were getting logged out silently → JWT cache bug → fixed by reading live session."
- **Show you know what you don't know**. Evals are weak. Testing is patchy. Scaling is unproven. Owning gaps beats hiding them.
- **Have one detail ready per layer** — DB schema quirk, a specific Flutter gotcha, a specific prompt trick. Interviewers poke to see if you built it or bought it.
