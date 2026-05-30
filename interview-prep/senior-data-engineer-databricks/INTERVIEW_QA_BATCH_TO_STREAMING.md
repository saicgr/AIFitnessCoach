# Senior Data Engineer — Batch → Streaming Migration Prep
## STAR Format · Discovery → Diagnosis → Fix → Result · Structured Streaming on Databricks

> **Companion to `INTERVIEW_QA.md` and the migration docs.** Same house style. Every "how did you" answer is **STAR** (Action = how I *found* it + *approached* it + *fixed* it). Definitional items are **Context → Answer**.
>
> **Cross-ref:** for "why Databricks vs a relational DB / Redshift / Snowflake," see `INTERVIEW_QA.md` §12 (Platform positioning); acronyms (watermark, RocksDB, CDC, foreachBatch…) in `INTERVIEW_QA_GLOSSARY.md`.
>
> **Anchor project:** **Juul Labs' Retail Sales Intelligence Platform** — converted the hot path from **nightly batch → near-real-time streaming**. Same company + domain as every other prep doc. Driver: the business wanted intra-day inventory + sales visibility (depletion signals within minutes, not "tomorrow morning"). Kept the same medallion (bronze→silver→gold); changed the *engine* on the hot path from scheduled batch to **Spark Structured Streaming** + Kafka/Kinesis + Auto Loader.
>
> **Coherence note:** anchor company is **Juul** in every doc. This one is **not a platform migration** — it's an *engine change on the existing Databricks lakehouse* (batch jobs → streaming) for the latency-sensitive feeds. It pairs naturally with any of the migration stories ("after we landed on Databricks, we streamed the hot path").
>
> **Numbers (customize to yours):** hot-path end-to-end latency **~6 h (overnight batch) → ~90 s**; **~12 source feeds** (SFTP files + 3 Kafka topics + CDC from an OLTP DB); throughput **~50k events/s peak**; **99.9% on-time** within the SLA window; **exactly-once** to gold; **streamed ~30% / kept batch ~70%**.
>
> **The senior thesis to repeat:** *"Don't stream what doesn't need to be real-time."* Streaming adds real operational cost (state, watermarks, 24/7 compute, harder debugging). I streamed the **hot path** (sales/inventory events) and **kept batch** for everything tolerant of daily latency. Choosing *what not to stream* is the senior signal.
>
> **For Dmitry** (pragmatism, cost, self-service): lead with the cost/complexity trade-off (streaming isn't free), the reuse of one code path for batch+stream, and the monitoring/alerting that made 24/7 operable.

---

## Contents

1. [Why stream — and what NOT to stream](#1-why-stream--and-what-not-to-stream)
2. [Structured Streaming fundamentals (the model)](#2-structured-streaming-fundamentals)
3. [Sources: files (Auto Loader), Kafka/Kinesis, CDC](#3-sources-files-kafka-kinesis-cdc)
4. [Exactly-once, checkpoints, idempotency](#4-exactly-once-checkpoints-idempotency)
5. [Watermarks, late data, windowing](#5-watermarks-late-data-windowing)
6. [Stateful streaming (aggregations, joins, dedup)](#6-stateful-streaming)
7. [Triggers, micro-batch, and the batch↔stream code reuse](#7-triggers-micro-batch-code-reuse)
8. [Streaming joins (stream-static, stream-stream)](#8-streaming-joins)
9. [foreachBatch, MERGE, sinks, medallion streaming](#9-foreachbatch-merge-sinks)
10. [Performance, state-store, OOM, backpressure](#10-performance-state-store-oom-backpressure)
11. [Operations: monitoring, recovery, schema change, deploy](#11-operations-monitoring-recovery)
12. [DLT / Lakeflow Declarative Pipelines](#12-dlt--lakeflow-declarative-pipelines)
13. [Scenario / war-story questions](#13-scenario--war-story-questions)
14. [Hard rapid-fire + flashcards](#14-hard-rapid-fire--flashcards)

---

## 0. The architecture — before and after (sketch this in 60s)

**BEFORE — nightly batch (Juul lakehouse):**
```
12 feeds (SFTP files, OLTP) ── land in S3 overnight
        |
        v  4 AM Databricks Workflow (scheduled DAG, runs once/day)
  BRONZE (batch read)  ->  SILVER (batch MERGE)  ->  GOLD (batch marts)
        |
        v
  Looker / Databricks SQL   (data is "yesterday" each morning)
```
Pain: business sees yesterday's depletions/inventory at 8 AM; can't react to a stockout or promo spike same-day. ~6 h end-to-end.

**AFTER — streaming hot path + batch cold path (hybrid):**
```
  HOT PATH (latency: minutes)            COLD PATH (latency: daily, unchanged)
  ┌─────────────────────────────┐        ┌──────────────────────────────┐
  Kafka/Kinesis (sales,          │        │  SFTP dims, finance marts,    │
   inventory events) + CDC       │        │  Nielsen, slow dims           │
        |  readStream            │        │       |  nightly batch        │
        v                        │        │       v                        │
  BRONZE stream                  │        │  BRONZE/SILVER/GOLD batch      │
   |  Structured Streaming       │        │  (SCD2 dims, monthly finance)  │
   |  + watermark + RocksDB state│        └──────────────────────────────┘
   v                             │                    |
  SILVER (foreachBatch + MERGE)  │ <── stream-static join ──┘ (dims read per micro-batch)
   |                             │
   v                             │
  GOLD real-time marts (windowed agg)
        |
        v
  Looker / Databricks SQL  (current-day, ~90s fresh)  +  batch finance gold (daily)

  Exactly-once: replayable source (Kafka offsets) + checkpoint + idempotent MERGE
  Late data: watermark (2h, from measured P99) + side-table batch correction
  Triggers: hot path = processingTime/always-on; medium feeds = availableNow on a schedule
```
Key visual: **two lanes.** Stream the hot path (events that drive an intra-day decision); keep the cold path on batch; **join the batch dims into the stream as STATIC tables** (no stream-stream state). The medallion shape is unchanged — only the engine on the hot lane changed.

**The mapping (batch concept → streaming concept):**

| Batch | Streaming | Note |
|---|---|---|
| `spark.read` | `spark.readStream` | Same DataFrame code after |
| Scheduled job (4 AM) | Trigger (processingTime / availableNow) | availableNow = incremental batch |
| Full/partition reload | Checkpoint + incremental offsets | Exactly-once resume |
| Append/overwrite write | `foreachBatch` + Delta MERGE | Upsert, idempotent |
| "Yesterday was complete" | Watermark + late-data handling | Decide how long to wait |
| Reprocess yesterday | Replay from offset / state | Bounded by checkpoint+state |
| Stateless | State store (RocksDB) + watermark eviction | New failure class |
| Batch dim join | Stream-static join | Dim re-read per micro-batch |

---

## 1. Why stream — and what NOT to stream

### Q. Why did you move from batch to streaming? How did you decide what to convert?

**Context:** The mature answer leads with "I didn't stream everything." Streaming has real costs — pick the hot path.

**S:** Nightly batch meant the business saw yesterday's depletions/inventory each morning; ops wanted intra-day so they could react to stockouts + promo spikes same-day. But ~70% of the warehouse (finance month-end, slowly-changing dims, historical marts) was perfectly fine on daily latency.
**T:** Deliver near-real-time where it mattered without 24/7-streaming the whole estate.
**A — how I scoped it:**
- **Mapped each feed to a latency SLA** the business actually needed: sales/inventory events = minutes; dims + finance marts = daily is fine.
- **Streamed only the hot path** (sales + inventory events from Kafka/CDC) end-to-end bronze→silver→gold.
- **Kept batch** for the slow-changing + finance layers — joined them as **static** tables into the stream (stream-static join, §8).
- **Quantified the cost** of streaming (24/7 compute, state management, on-call complexity) so the "only hot path" decision was defensible to finance.
**R:** Hot-path latency 6h→90s; the rest stayed cheap batch. The headline interview point: *"Streaming is a cost, not a default. I streamed the 30% that needed it and left 70% on batch — and could defend the line."*

> 💡 **Remember:** Trap — answering "we streamed everything" signals you don't respect streaming's cost. Say — "I mapped each feed to a latency SLA, streamed the 30% with a real-time decision, and kept 70% on batch."

### Q. What makes streaming genuinely harder than batch?

**Context:** Shows you respect the operational reality, not just the demo.

**Answer:**
- **State:** aggregations/joins/dedup keep state across micro-batches → memory growth, must be bounded by watermarks → a whole failure class batch doesn't have.
- **Late + out-of-order data:** batch sees a complete day; streaming must decide *how long to wait* (watermark) → correctness/latency trade-off.
- **24/7 operations:** it never "finishes" → on-call, restart semantics, checkpoint management, monitoring lag — not "did the 4 AM job pass."
- **Exactly-once is subtle:** requires replayable source + checkpoint + idempotent sink, all aligned.
- **Debugging:** no clean "rerun yesterday"; you reason about offsets, state, and watermarks.
- **Cost:** always-on compute vs scale-to-zero batch.
- **So:** stream only when the latency win exceeds all that. Most "we need streaming" is really "we need a 15-min batch," which is far cheaper (just a frequent trigger).

> 💡 **Remember:** Trap — listing only "lower latency, harder" misses that streaming spawns a new failure class (unbounded state). Say — "Most 'we need streaming' is really 'we need a 15-minute batch' — far cheaper with just a frequent trigger."

---

## 2. Structured Streaming fundamentals

### Q. Explain the Structured Streaming model.

**Context → Answer:**
- **Core idea:** a stream is an **unbounded table** that grows as data arrives; you write (almost) the same DataFrame/SQL code as batch, and Spark incrementalizes it.
- **Execution:** the engine runs a series of **micro-batches** — each trigger processes the new data since the last offset, updates any state, and commits results + progress to the **checkpoint**. (Continuous-processing mode exists for ultra-low latency but micro-batch is the default and what you use 99% of the time.)
- **Guarantees:** **exactly-once** end-to-end when source is replayable + sink is idempotent/transactional + checkpoint is intact.
- **Output modes:** **append** (only new rows — for non-aggregated or watermarked-window results), **update** (changed keys — for running aggregations), **complete** (whole result table — small aggregations only).
- **The win:** one mental model + largely one code path for batch and stream (`spark.read` vs `spark.readStream`).

> 💡 **Remember:** Trap — confusing output modes (append vs update vs complete) or claiming complete mode for big aggregations. Say — "A stream is an unbounded table the engine incrementalizes as micro-batches; exactly-once needs replayable source + idempotent sink + checkpoint."

### Q. Micro-batch vs continuous processing?

**Answer:** **Micro-batch** (default): processes data in small batches (trigger-driven), ~seconds latency, full feature support (stateful ops, joins), exactly-once. **Continuous** (niche): record-at-a-time, ~ms latency, but limited operations + at-least-once historically. I used micro-batch everywhere — 90s latency was the SLA, and micro-batch's feature set (stateful aggs, stream-static joins, foreachBatch MERGE) is what the pipeline needed. Continuous is for sub-second-critical, simple maps.

> 💡 **Remember:** Trap — reaching for continuous mode to sound advanced; it's niche, at-least-once historically, and can't do stateful ops. Say — "Micro-batch everywhere; my SLA was 90 seconds and continuous can't do the stateful aggs and foreachBatch MERGE the pipeline needed."

---

## 3. Sources: files, Kafka/Kinesis, CDC

### Q. What were your streaming sources and how did each work?

**Context:** Three source archetypes, each with different replay/offset semantics.

**Answer:**
- **Files (Auto Loader / `cloudFiles`):** for the SFTP feeds that kept arriving — Auto Loader incrementally picks up new files (directory-listing or SNS/SQS notification mode), checkpoint tracks processed paths. (Covered deeply in `INTERVIEW_QA.md` §11.) Effectively "streaming over a file drop."
- **Kafka:** the true event source (sales/inventory events). `spark.readStream.format("kafka")`, offsets tracked in the checkpoint → replayable → exactly-once. Tuned `maxOffsetsPerTrigger` for backpressure.
- **Kinesis:** same idea, AWS-native; shard-based, `maxRecordsPerFetch`/initial-position config.
- **CDC from OLTP** (Debezium → Kafka, or Delta CDF): captured row-level changes from the operational DB → MERGE into silver. The key for "real-time updates," not just inserts.

> 💡 **Remember:** Trap — treating all sources as interchangeable; each has distinct replay/offset semantics. Say — "Files via Auto Loader, events via Kafka offsets, real-time updates via CDC — all replayable, so the checkpoint can resume exactly-once."

### Q. How did you turn the existing file-batch into streaming with minimal rewrite?

**S:** The SFTP feeds were ingested by a nightly batch read of an S3 prefix.
**T:** Make them near-real-time without rewriting the transforms.
**A:** Swapped `spark.read` → `spark.readStream.format("cloudFiles")` (Auto Loader) on the same prefix; the downstream transform DataFrame code was **unchanged** (same model batch↔stream); changed the trigger from "nightly job" to a short interval / `trigger(availableNow)` on more frequent runs. Added a checkpoint.
**R:** Same transform logic, now incremental + frequent, with exactly-once via checkpoint. The batch↔stream code symmetry is what made this a small diff, not a rewrite.

> 💡 **Remember:** Trap — implying a rewrite was needed; the transform code is identical batch↔stream. Say — "I swapped `spark.read` for `readStream.format('cloudFiles')` and added a checkpoint — the transforms were untouched, a small diff not a rewrite."

---

## 4. Exactly-once, checkpoints, idempotency

> **The #1 streaming interview area** (mirrors the atomicity/idempotency theme in `INTERVIEW_QA.md` §11.10/11.18).

### Q. How do you guarantee exactly-once in a streaming pipeline?

**Context:** Exactly-once is an *end-to-end* property requiring three things aligned: replayable source + checkpointed progress + idempotent/transactional sink.

**S:** Finance-adjacent gold marts fed by streaming — a duplicated or dropped event = wrong numbers.
**T:** Guarantee each event affects gold exactly once, even across failures/restarts.
**A — the three pillars:**
- **Replayable source:** Kafka/Kinesis offsets (or Auto Loader file paths) → on restart, re-read from the last committed offset.
- **Checkpoint:** records committed offsets + state per micro-batch in durable storage; restart resumes from the last *committed* batch (atomic — see below).
- **Idempotent/transactional sink:** writing to **Delta** is atomic; for upserts I used **`foreachBatch` + MERGE on natural keys** so a replayed batch *updates* rather than *appends* → no dupes.
- **Why the combo:** atomic Delta commit = no partial batch; checkpoint = resume from uncommitted, not from zero; MERGE on natural key = re-sends/replays converge. Drop any one → either dupes or loss.
**R:** Exactly-once to gold across real failures (cluster restarts, redeploys). Same principle as the batch idempotency story: **atomic commit + checkpoint + idempotent MERGE = exactly-once.**

> 💡 **Remember:** Trap — naming only the checkpoint; exactly-once is end-to-end and dies if you drop any one pillar. Say — "Exactly-once is three things aligned: replayable source, checkpoint, and idempotent MERGE on the natural key — drop any one and you get dupes or loss."

### Q. A micro-batch fails mid-write. What happens? (the resume question)

**Answer (from the main doc, restated for streaming):** Micro-batches are **atomic + sequential**. Batch N must commit (write `_delta_log` + advance checkpoint offset) before N+1 starts. If N fails, the stream **stops**; on restart the checkpoint shows N uncommitted → it **reprocesses N from its recorded start offset**, then continues. Already-committed batches aren't redone; the failed batch committed nothing → no dupes, no partial. You resume from the failed batch, not from zero and not mid-batch.

> 💡 **Remember:** Trap — saying it "starts over from zero" or "resumes mid-write." Say — "Micro-batches are atomic and sequential; a failed batch committed nothing, so restart reprocesses just that batch from its recorded start offset — no dupes, no partial."

### Q. What exactly is in the checkpoint, and what breaks it?

**Answer:** (1) **offsets/commits** (streaming progress per batch), (2) **source metadata** (Auto Loader: processed files in RocksDB; Kafka: committed offsets), (3) **state store** (for stateful ops). It lives in durable cloud storage, one per stream, never shared, never hand-edited. **Breaks it:** deleting it (forgets everything → reprocess/replay all), or making an **incompatible query change** (changing stateful logic, keys, or output mode can be checkpoint-incompatible → needs a new checkpoint + a reprocessing plan). Treat checkpoint location as part of the stream's identity.

> 💡 **Remember:** Trap — thinking the checkpoint only holds offsets (it also holds source metadata + state store), or that you can hand-edit/share it. Say — "The checkpoint is the stream's identity — offsets, source metadata, and state — never shared, never edited; an incompatible query change needs a new one plus a reprocessing plan."

---

## 5. Watermarks, late data, windowing

### Q. Explain watermarks. Why do you need them?

**Context:** The defining streaming concept. Without a watermark, stateful state grows forever.

**Answer:**
- **Watermark = `max(event_time seen) − allowedLateness`** — a moving threshold that says "I won't wait for events older than this."
- **Two jobs:** (1) lets the engine **finalize** windowed aggregations (close the window, emit the result), and (2) lets it **drop old state** so memory is bounded.
- **The trade-off you must articulate:** **too tight** (e.g. 5 min) → you drop legitimately-late events → undercount; **too loose** (e.g. 24 h) → state grows huge → OOM + latency. You tune it to the source's real lateness distribution.
- Syntax: `df.withWatermark("event_time", "2 hours").groupBy(window("event_time","1 hour"), key).agg(...)`.

> 💡 **Remember:** Trap — describing a watermark as only "dropping late data" and forgetting it's what bounds state. Say — "A watermark does two jobs: finalize windows and evict old state — too tight drops legit events, too loose OOMs."

### Q. How did you choose the watermark value?

**S:** Sales events arrived mostly within minutes, but a tail (store connectivity blips, retries) lagged up to ~90 min.
**T:** Capture ~all real events without unbounded state.
**A — how I found the number:** **profiled the actual lateness distribution** — `event_time` vs `processing_time` over a week → P99 lateness ~75 min. Set the watermark to **2 hours** (P99 + margin). Validated by counting how many events would have been dropped at that threshold (near-zero) vs the state-size cost.
**R:** <0.01% events dropped, state bounded + stable. The senior move: set the watermark from the *measured* lateness distribution, not a guessed round number.

> 💡 **Remember:** Trap — picking a round number ("1 hour, felt safe") instead of measuring. Say — "I profiled event_time vs processing_time for a week, found P99 lateness ~75 min, and set the watermark to 2 hours — measured, not guessed."

### Q. Late event arrives after the watermark — what happens to it?

**Answer:** It's **dropped** from the stateful window (the window already finalized + state evicted). If those late events matter (finance corrections), you handle them **out-of-band**: route late/dropped events to a side table and reconcile via a **batch correction job** (idempotent MERGE), rather than widening the watermark and paying unbounded state. Streaming for the 99.99%, batch correction for the rare tail — a pragmatic split.

> 💡 **Remember:** Trap — widening the watermark to "never drop anything," which trades correctness for unbounded state. Say — "Post-watermark events are dropped from the window; if they matter I route them to a side table and batch-correct, not widen the watermark."

### Q. Tumbling vs sliding vs session windows?

**Answer:** **Tumbling** = fixed, non-overlapping (hourly buckets) — most aggregations. **Sliding** = fixed size, overlapping by a slide interval (1h window every 5 min) — moving averages. **Session** = dynamic, gap-defined (activity bursts separated by inactivity) — user sessions. I used tumbling for the per-hour sales rollups; the gold daily marts came from windowed aggregates + a final batch reconcile.

> 💡 **Remember:** Trap — mixing up sliding (fixed size, overlapping) with session (dynamic, gap-defined). Say — "Tumbling = non-overlapping buckets, sliding = overlapping moving averages, session = gap-defined bursts — I used tumbling for the per-hour sales rollups."

---

## 6. Stateful streaming

### Q. What stateful operations did you run, and how did you keep state from exploding?

**Context:** Stateful = aggregations, stream-stream joins, dedup, `[flat]MapGroupsWithState`. State lives in the state store; unbounded state is the #1 streaming OOM.

**S:** Running per-retailer/per-product hourly aggregates + dedup of replayed events → growing state.
**T:** Keep state bounded + the job stable 24/7.
**A — how I found the problem:** Streaming UI showed **state-store rows + memory climbing** batch over batch; eventually executor OOM.
**A — how I fixed it:**
- **Watermark on every stateful op** so old windows/keys evict (the root fix — no watermark = infinite state).
- **Switched state store to RocksDB** (`spark.sql.streaming.stateStore.providerClass` → RocksDB) — keeps state off-heap on disk, handles far larger state than the default HDFSBackedStateStore without OOM.
- **Bounded dedup state** with a watermark on the dedup key (`dropDuplicatesWithinWatermark`) so the dedup set doesn't grow forever.
- Sized executors for the (now bounded) state + monitored state metrics.
**R:** State plateaued instead of climbing; OOM cleared; job stable 24/7. Lesson: **streaming OOM is usually state growth, not data skew** — watermark + RocksDB state store, before adding memory.

> 💡 **Remember:** Trap — reaching for bigger executors first when state-store rows are climbing batch-over-batch. Say — "Streaming OOM is usually unbounded state, not skew — I put a watermark on every stateful op and moved state to RocksDB before touching memory."

### Q. Default state store vs RocksDB?

**Answer:** Default **HDFSBackedStateStore** keeps state **on-heap** (JVM) → fine for small state, OOMs on large. **RocksDB state store** keeps it **off-heap on local disk** with an in-memory cache → handles orders-of-magnitude larger state, less GC pressure. Rule: any non-trivial stateful stream (big aggregations, stream-stream joins, large dedup) → RocksDB. It's a one-line config and the standard fix for state-driven OOM.

> 💡 **Remember:** Trap — not knowing the default is on-heap (the reason it OOMs on large state). Say — "Default HDFSBackedStateStore is on-heap and OOMs on large state; RocksDB keeps it off-heap on disk — one-line config, standard fix for any real stateful stream."

---

## 7. Triggers, micro-batch, code reuse

### Q. What trigger modes are there and when do you use each?

**Answer:**
- **Default (unspecified):** new micro-batch as soon as the previous finishes — lowest latency, always-on.
- **`processingTime="30 seconds"`:** fixed interval — steady cadence, predictable cost. My hot path used this.
- **`availableNow=True`:** process all available data then **stop** — "batch-style streaming." This is the killer feature for **incremental batch**: run a streaming query on a schedule, it picks up everything new since last run (via checkpoint), exactly-once, then exits. Cheaper than always-on for non-urgent feeds.
- **`once=True`:** deprecated predecessor of availableNow.
- **Continuous:** sub-second, niche.

> 💡 **Remember:** Trap — not knowing `availableNow` exists, so missing the cheap incremental-batch option. Say — "`availableNow` drains all new data exactly-once then stops — streaming code run on a schedule, the middle ground between always-on and nightly."

### Q. "We want it cheaper than always-on but fresher than nightly" — what did you do?

**S:** Some feeds needed ~15-min freshness, not 90s, and 24/7 compute was wasteful for them.
**T:** Get incremental freshness without always-on cost.
**A:** Ran the streaming query with **`trigger(availableNow=True)` on a 15-min schedule** (Databricks Workflow). Each run drained new data exactly-once via the checkpoint, then the cluster terminated → no idle 24/7 compute. Same streaming code, scheduled like a batch.
**R:** 15-min freshness at near-batch cost. `availableNow` on a schedule is the pragmatic middle ground between always-on streaming and nightly batch — a great thing to volunteer in interviews.

> 💡 **Remember:** Trap — assuming "fresher than nightly" forces always-on 24/7 compute. Say — "I ran `availableNow` on a 15-minute Workflow schedule — each run drains new data exactly-once then the cluster terminates, freshness at near-batch cost."

### Q. How much code did you actually share between batch and streaming?

**Answer:** Most of the *transform* logic — the DataFrame/SQL business rules are identical (`spark.read` vs `spark.readStream`, then the same `.select/.join/.groupBy`). The differences are at the **edges**: source (`readStream` + format opts), sink (`writeStream` + checkpoint + trigger + output mode, or `foreachBatch`), and stateful ops need watermarks. I factored transforms into shared functions called by both a batch entrypoint and a streaming entrypoint → one tested code path, two runners. (This is also how you keep a batch fallback for backfills.)

> 💡 **Remember:** Trap — claiming "100% shared" — the edges (source, sink, watermarks) genuinely differ. Say — "Transforms are identical and factored into shared functions; only the edges differ — source readStream, sink foreachBatch, watermarks — one tested code path, two runners."

---

## 8. Streaming joins

### Q. Stream-static vs stream-stream join — when each, and the gotchas?

**Context:** The join type interviewers probe because stream-stream is genuinely hard (state on both sides).

**Answer:**
- **Stream-static:** stream joined to a (slowly-changing) **static/Delta table** — e.g. sales events ⨝ `canonical_product` dim. The static side is re-read per micro-batch (picks up updates), **no state** kept for the join → cheap + simple. **This is what I used for 90% of enrichment** (events enriched with dims). It's also how I joined the *batch* dims into the *stream* (the "stream only the hot path" design).
- **Stream-stream:** two streams joined — requires **state on both sides + watermarks on both** to bound how long to buffer unmatched rows waiting for the other side. Memory-heavy, latency-sensitive. Only used it where two event streams genuinely had to correlate (e.g. order events ⨝ shipment events within a time bound).
- **Gotchas:** stream-stream **needs watermarks + a time-bound join condition** (`eventA.time BETWEEN eventB.time AND eventB.time + interval`) or state grows forever; outer joins emit nulls only after the watermark passes (delayed).

> 💡 **Remember:** Trap — defaulting to a stream-stream join for dim enrichment and paying unnecessary dual-side state. Say — "Most 'join in streaming' is really stream-static — the dim re-read per micro-batch, zero state; I reserve stream-stream for two genuinely-correlated event streams, with watermarks on both."

### Q. You enriched a stream with a dimension that updates. How did you avoid stale dims?

**S:** Sales events needed current product/retailer canonical attributes; the dims (SCD2) updated daily via batch.
**T:** Enrich with *current* dim values without a stateful stream-stream join.
**A:** **Stream-static join** to the Delta dim table — Spark re-reads the static side each micro-batch, so dim updates (the daily batch MERGE) are picked up automatically on the next batch. For point-in-time correctness on SCD2, joined on `is_current` (or the valid-time range for as-of-event enrichment). No join state to manage.
**R:** Events always enriched with fresh dims, zero stream-stream state cost. Stream-static is the unsung workhorse — most "join in streaming" is really stream-static.

> 💡 **Remember:** Trap — worrying a static dim goes stale; Spark re-reads it each micro-batch. Say — "Stream-static re-reads the Delta dim every micro-batch, so the daily SCD2 MERGE is picked up automatically — I joined on is_current, no join state to manage."

---

## 9. foreachBatch, MERGE, sinks

### Q. How do you upsert (MERGE) from a stream? You can't MERGE a stream directly.

**Context:** `writeStream` supports append-y sinks; arbitrary MERGE/upsert needs `foreachBatch`. A core pattern.

**S:** Silver `canonical_sales` needed upserts (late corrections update existing rows), not append-only.
**T:** Run a Delta MERGE per micro-batch from a stream.
**A:** Used **`foreachBatch`** — it hands each micro-batch to you as a *normal batch DataFrame*, where you run any batch operation, including **`MERGE INTO ... USING <batchDF> ON natural_key WHEN MATCHED UPDATE WHEN NOT MATCHED INSERT`**. Made the MERGE idempotent on the natural key so replays converge.
```python
def upsert(batch_df, batch_id):
    (delta_table.alias("t")
       .merge(batch_df.alias("s"), "t.nk = s.nk")
       .whenMatchedUpdateAll().whenNotMatchedInsertAll().execute())
stream.writeStream.foreachBatch(upsert).option("checkpointLocation", ckpt).start()
```
**R:** Streaming upserts with exactly-once (idempotent MERGE + checkpoint). `foreachBatch` is the answer to "how do I do <any batch op> in a stream" — MERGE, multi-sink writes, calling external APIs.

> 💡 **Remember:** Trap — trying to MERGE a streaming DataFrame directly (unsupported). Say — "You can't MERGE a stream; foreachBatch hands you each micro-batch as a normal batch DataFrame where you run MERGE on the natural key — that's the upsert pattern."

### Q. foreachBatch and exactly-once — any catch?

**Answer:** `foreachBatch` gives **at-least-once** by default (a batch can re-run on failure). You make it **exactly-once** by either (a) an **idempotent MERGE** on natural keys (re-run converges — what I did), or (b) using the `batch_id` to dedupe (write batch_id to a tracking table, skip if already processed). If you do *two* writes inside foreachBatch, neither is atomic with the other — design for the replay.

> 💡 **Remember:** Trap — assuming foreachBatch is exactly-once by default (it's at-least-once; a batch can re-run). Say — "foreachBatch is at-least-once — I make it exactly-once with an idempotent MERGE on the natural key, or dedupe on batch_id."

### Q. Medallion streaming — did you stream all three layers?

**Answer:** Bronze + silver streamed (Auto Loader → bronze, stream + foreachBatch MERGE → silver). Gold was **mixed**: real-time gold marts (current-day sales/inventory) streamed via windowed aggregates; finance/historical gold stayed **batch** (daily, with reconciliation) because it tolerated latency and needed the heavy reconcile. So: stream bronze→silver→hot-gold; batch the cold-gold. Don't stream layers that don't need it.

> 💡 **Remember:** Trap — saying "all three layers streamed" when gold is mixed. Say — "Bronze and silver streamed; gold was split — real-time marts streamed via windowed aggregates, finance/historical gold stayed batch because it needed the heavy reconcile."

---

## 10. Performance, state-store, OOM, backpressure

### Q. The stream started falling behind (lag growing). How did you diagnose + fix?

**Context:** "Falling behind" = processing slower than ingestion → lag grows → SLA breach. The streaming analog of a slow batch job.

**S:** The Streaming UI showed **batch duration > trigger interval** and input-rate > processing-rate → lag climbing.
**T:** Get processing rate above ingestion rate, stably.
**A — how I found the cause:**
- **Streaming UI:** input rate vs processing rate, batch duration trend, and **state-store metrics**. Batch duration was climbing → either state growth or a per-batch overload.
- Checked: was it **too much per batch** (no backpressure cap) or **state explosion** (no watermark) or **skew**?
**A — fixes (matched to cause):**
- **Backpressure:** capped intake per batch — `maxOffsetsPerTrigger` (Kafka) / `cloudFiles.maxFilesPerTrigger` (files) so a burst doesn't create a giant batch that blows the trigger interval.
- **State:** watermark + RocksDB state store (§6) to bound state.
- **Parallelism:** raised `shuffle.partitions` for the stateful agg; scaled workers.
- **Skew:** AQE / salt on the hot key (same as batch).
**R:** Processing rate back above ingestion, lag drained, stable within SLA. Lesson: for a falling-behind stream, check **state growth + per-batch size (backpressure)** first — they're the streaming-specific causes; then the usual skew/parallelism levers.

> 💡 **Remember:** Trap — jumping straight to skew/parallelism (the batch reflexes) when batch duration > trigger interval. Say — "When a stream falls behind I check the streaming-specific causes first — unbounded state and oversized batches (cap with maxOffsetsPerTrigger) — then the usual skew and parallelism levers."

### Q. Streaming OOM — how's it different from batch OOM?

**Answer:** Batch OOM is usually **skew or a wide shuffle**. Streaming OOM is usually **unbounded state** (missing/too-loose watermark) or **too-large micro-batches** (no backpressure cap). So the first moves differ: streaming → check watermark + state-store metrics + RocksDB + `maxOffsetsPerTrigger`, *then* the batch-style skew/memory levers. (Said this way it signals you know both worlds.)

> 💡 **Remember:** Trap — diagnosing a streaming OOM with batch instincts (skew/wide shuffle). Say — "Batch OOM is skew or a wide shuffle; streaming OOM is unbounded state or oversized micro-batches — check watermark, state metrics, and maxOffsetsPerTrigger first."

---

## 11. Operations: monitoring, recovery, schema change, deploy

### Q. How do you monitor a 24/7 stream? It never "passes" like a batch job.

**Context:** Batch monitoring = "did the job succeed." Streaming = continuous health signals.

**Answer — what I watched + alerted on:**
- **Lag / freshness:** input rate vs processing rate; consumer-group lag (Kafka); end-to-end latency. Alert if lag grows N batches running or freshness > SLA.
- **Batch duration vs trigger interval:** if batch duration approaches the interval, you're about to fall behind.
- **State-store size/rows:** climbing = watermark/state problem.
- **StreamingQueryListener** → push `QueryProgressEvent` metrics to the observability stack; PagerDuty on breach.
- **Checkpoint health + dropped-late-event counts.**
- Dashboards + alerts, not "did the 4 AM run pass."

> 💡 **Remember:** Trap — describing batch-style "did the job pass" monitoring for a job that never finishes. Say — "A stream never 'passes' — I alert on lag/freshness, batch-duration-vs-trigger-interval, and state-store growth via StreamingQueryListener, not a green checkmark."

### Q. The stream died at 2 AM. How does it recover — and do you lose data?

**Answer:** **No data loss** if checkpoint + replayable source are intact. On restart, the query reads the checkpoint → resumes from the last committed offset → replays uncommitted data from the source → exactly-once. I run streams under **Databricks Workflows with retries + `availableNow` fallbacks**, and for always-on streams, automatic restart. The recovery is "restart the query, it resumes from checkpoint" — which is why checkpoint integrity is sacred.

> 💡 **Remember:** Trap — fearing data loss on a crash; there's none if checkpoint + replayable source are intact. Say — "Restart the query, it resumes from the last committed offset and replays the uncommitted data exactly-once — which is why checkpoint integrity is sacred."

### Q. A source schema changed mid-stream. What happens?

**S:** A Kafka producer added a field (and once, a file feed added a column).
**A:** Auto Loader / schema tracking: with **`schemaEvolutionMode`** the stream stops once on the new column, updates the tracked schema, and resumes ingesting it (old rows null) — or **`rescue` mode** lands unexpected fields in `_rescued_data` (nothing lost). For Kafka (bytes), I deserialized against a **schema registry** so producer changes are versioned/compatible. A **CI schema-diff** caught contract breaks before prod. (Same discipline as `INTERVIEW_QA.md` §11.z.) **R:** schema changes were contained events, not outages.

> 💡 **Remember:** Trap — assuming a new field silently crashes the stream. Say — "Auto Loader's schemaEvolutionMode stops once, tracks the new column, and resumes; rescue mode lands unknowns in _rescued_data; Kafka goes through a schema registry — schema change is a contained event, not an outage."

### Q. How do you deploy a code change to a running stream?

**Answer:** Stop the query gracefully, deploy, restart from the **same checkpoint** — *if* the change is checkpoint-compatible (transform logic, non-stateful changes: fine). **Incompatible changes** (altering stateful aggregation keys/logic, output mode) can't resume the old state → plan a **new checkpoint + reprocessing** (replay from source, or run a batch backfill for the gap). I version checkpoints with the deploy and test compatibility in staging. Treat "is this change checkpoint-compatible?" as a deploy-time checklist item.

> 💡 **Remember:** Trap — assuming every redeploy can just resume the old checkpoint. Say — "Transform-only changes resume from the same checkpoint; changing stateful keys/logic or output mode is checkpoint-incompatible — that needs a new checkpoint plus a reprocessing plan."

---

## 12. DLT / Lakeflow Declarative Pipelines

### Q. Did you consider DLT (Delta Live Tables / Lakeflow Declarative Pipelines)?

**Context:** DLT is Databricks' declarative streaming/ETL framework — you declare tables + expectations, it manages orchestration, retries, checkpoints, autoscaling.

**Answer:**
- **What it gives you:** declarative `@dlt.table` definitions, **streaming tables + materialized views**, built-in **data-quality expectations** (`@dlt.expect` → drop/quarantine/fail on violation), automatic checkpoint + retry + lineage + autoscaling. Less boilerplate than hand-rolled Structured Streaming.
- **When I'd use it:** new medallion pipelines where I want DQ + orchestration handled and the team values declarative simplicity over fine control.
- **When I'd hand-roll Structured Streaming:** when I need precise control over state, custom `foreachBatch` logic, non-standard sinks, or complex stream-stream state tuning — DLT abstracts some of that away.
- **My call on the project:** used hand-rolled Structured Streaming for the complex stateful hot path (needed foreachBatch MERGE + custom state tuning), and would put the simpler bronze→silver DQ-heavy feeds on DLT. Right tool per workload — and DLT's expectations are a clean replacement for scattered Great Expectations checks.

> 💡 **Remember:** Trap — treating DLT as all-or-nothing instead of right-tool-per-workload. Say — "DLT for DQ-heavy simple pipelines where managed checkpoints/expectations win; hand-rolled Structured Streaming where I need custom foreachBatch MERGE and fine state control."

---

## 13. Scenario / war-story questions

### Q. Business says "make the whole warehouse real-time." How do you respond?

**A:** Push back with data, pragmatically. **"Real-time costs money + complexity; let's stream what has a real-time *decision* attached."** Map each consumer to the latency that changes a decision: stockout alerts = minutes (stream); month-end finance = daily is fine (batch). Stream the hot path, leave the rest batch, join batch dims as static. Quantify the cost delta. The senior answer is *scoping*, not "yes, streaming everywhere."

> 💡 **Remember:** Trap — saying "yes" to please the business and signing up for needless 24/7 cost. Say — "Real-time costs money and complexity — let's stream what has a real-time decision attached, map each consumer to that, and quantify the cost delta."

### Q. Duplicate rows showed up in a streaming gold table. Walk me through it.

**S:** A gold mart had dupes after a redeploy.
**A — found it:** reconciliation count-distinct flagged it; traced to the streaming write. **Root cause:** the sink was an **append**, and a redeploy replayed an uncommitted batch → appended again. **Fix:** changed the sink to **`foreachBatch` + idempotent MERGE on natural key** so replays converge; verified checkpoint compatibility. **R:** dupes gone, exactly-once restored. Lesson: append sink + replay = dupes; upsert via MERGE on natural key for exactly-once.

> 💡 **Remember:** Trap — blaming "bad data" when the real cause is an append sink replaying an uncommitted batch. Say — "Append sink plus a replayed batch on redeploy equals dupes — I switched to foreachBatch + idempotent MERGE on the natural key so replays converge."

### Q. The stream is "stuck" — no progress, no error. Diagnose.

**A:** Streaming UI: is it **receiving** (input rate 0 → source/connectivity issue: Kafka offsets, file notifications, SQS backlog) or **receiving-but-not-progressing** (batch running forever → state explosion, skew, a slow stream-stream join, or a downstream sink blocked)? Check batch duration, state metrics, and the active batch's stage in Spark UI. Common culprits: SQS/notification backlog (Auto Loader), an unbounded stream-stream join with no watermark, or a sink (external API in foreachBatch) hanging.

> 💡 **Remember:** Trap — lumping "stuck" into one cause; first split receiving-nothing from receiving-but-not-progressing. Say — "Input rate zero means a source/connectivity issue; input flowing but batch never finishing means state explosion, skew, or a blocked sink — the UI tells you which."

### Q. How do you backfill history into a new streaming pipeline?

**A:** Two-path: **batch backfill** the history (the same shared transform functions, §7, run in batch over the historical files/offsets) writing to the same Delta tables, then **start the stream** from the appropriate offset/timestamp (`startingOffsets`/`startingTimestamp`) so it picks up from where the backfill ended. Checkpoint + idempotent MERGE means a slight overlap between backfill and stream converges instead of duplicating. One code path, two runners — the reason I factored transforms out (§7).

> 💡 **Remember:** Trap — fearing the backfill/stream overlap creates dupes. Say — "Batch-backfill the history with the shared transforms, then start the stream from that offset/timestamp — checkpoint + idempotent MERGE converge the overlap instead of duplicating."

### Q. (Architecture) Walk the end-to-end conversion of ONE batch job to streaming.

**Context:** The full arc on a concrete pipeline, not the abstract process.

**S:** The `silver_canonical_sales` batch job: nightly `spark.read` of an S3 prefix → dedup/join to dims → `MERGE` into the Delta fact → fed gold marts. Business wanted it intra-day.
**T:** Convert to streaming, exactly-once, without rewriting the transform logic or breaking the batch consumers during transition.
**A — the arc:**
1. **Pick the source:** sales events were also flowing to **Kafka** (the OLTP emitted them) → switched the source from the nightly file read to `readStream.format("kafka")` (replayable offsets). The SFTP file feed stayed as an Auto Loader stream for the laggard distributors.
2. **Reuse the transform:** factored the dedup/join/enrich logic into a **shared function** called by both the (existing) batch entrypoint and the new streaming entrypoint — same tested code, two runners (§7). The transform DataFrame code was unchanged.
3. **Dims as stream-static:** the SCD2 dims stayed **batch** (daily) and were joined as **static Delta tables** (re-read per micro-batch) — no stream-stream state.
4. **Sink via foreachBatch + MERGE:** the existing `MERGE` logic moved inside `foreachBatch` so each micro-batch upserts idempotently on the natural key → exactly-once.
5. **State + late data:** added a **watermark** (2h, from measured P99 lateness) on the dedup/agg; switched the state store to **RocksDB**; routed post-watermark stragglers to a side table for batch correction.
6. **Checkpoint + trigger:** new checkpoint location; `processingTime="60s"` for the hot path.
7. **Dual-run + parity:** ran the stream alongside the nightly batch for 2 weeks; reconciled the streamed gold vs the batch gold daily (same reconciliation discipline as a migration) until they matched.
8. **Cutover:** repointed the gold marts to the streamed silver; kept the batch job as a **fallback + backfill** path (shared code makes this free).
**R:** 6h→90s on that fact, exactly-once, transform logic untouched. **The reusable lesson: factor transforms out so batch and stream share one code path; change only the edges (source `readStream`, sink `foreachBatch+MERGE`, add watermark+checkpoint).**

> 💡 **Remember:** Trap — skipping the dual-run parity step and cutting over blind. Say — "Source to Kafka, reuse the transform, dims as stream-static, sink via foreachBatch + MERGE, watermark + RocksDB, then dual-run against the nightly batch for two weeks until gold reconciled before cutover."

### Q. (Architecture) How did you decide the stream/batch boundary — what's the rule, not the vibe?

**Context:** "Stream the hot path" needs a concrete decision rule.

**Answer — the rule I applied per feed/consumer:**
- **Is there a decision that changes if the data is minutes-fresh vs next-morning?** Yes (stockout reaction, promo-spike, intra-day inventory) → **stream.** No (month-end finance, slow dims, historical trend) → **batch.**
- **How late does the data actually arrive?** If the source itself only produces daily (Nielsen, some distributor files), streaming buys nothing → **batch.**
- **Is it a dimension or a fact?** Slowly-changing **dims → batch** (join as static); high-velocity **facts/events → stream.**
- **Cost check:** does the latency win justify 24/7 compute + state + on-call? If marginal → **`availableNow` on a 15-min schedule** (the middle ground), not always-on.
- I encoded this as a column in the feed inventory so the boundary was documented + defensible, not per-engineer taste.
**R:** ~30% streamed (the event hot path), ~70% batch, dims joined static. **Whiteboard line:** "Stream where minutes-vs-morning changes a decision and the source produces fast; batch everything else; dims are static joins. The boundary is a documented rule, not a vibe."

> 💡 **Remember:** Trap — giving a vibe ("stream the important stuff") with no rule. Say — "The rule is a decision test: does minutes-fresh vs next-morning change an action? Plus does the source even produce fast, and is it a fact or a dim — encoded as a column in the feed inventory."

### Q. (Architecture) Lambda vs Kappa — did you run two code paths?

**Context:** Classic streaming-architecture question. Lambda = separate batch + speed layers; Kappa = one streaming path for everything.

**Answer:**
- **I avoided a true Lambda architecture** (two *separate* codebases for batch + speed) — that's the well-known maintenance trap (two implementations of the same logic drifting apart).
- **Closer to Kappa-ish with shared code:** one set of **shared transform functions** run by both a streaming runner (hot path) and a batch runner (backfill/cold path/fallback) — so there's *one* logic implementation, two execution modes, not two codebases.
- **The batch path isn't a separate "batch layer" recomputing the same data** — it's the backfill/correction/cold-feed runner. The streaming path owns the hot truth.
- **Late-data correction** is a small batch job on a side table, not a full Lambda recompute layer.
**R:** No dual-codebase drift; one transform implementation. The senior framing: "I didn't build Lambda's two layers — I shared the transform code and varied the runner, getting Kappa's single-logic benefit with a batch fallback for free."

> 💡 **Remember:** Trap — defending a true Lambda's two separate codebases (the drift trap) or claiming "pure Kappa, no batch at all." Say — "One transform implementation, two runners — Kappa's single-logic benefit with a batch fallback for free, never Lambda's drifting dual codebases."

---

## 14. Hard rapid-fire + flashcards

| Prompt | Crisp answer |
|---|---|
| Structured Streaming model | Stream = unbounded table; engine runs micro-batches; exactly-once via replayable source + checkpoint + idempotent sink. |
| Exactly-once = | Replayable source + checkpoint + idempotent/transactional sink. All three. |
| Micro-batch failure | Atomic + sequential; failed batch stops stream; restart reprocesses that batch from its start offset; no dupes, no partial. |
| Watermark | `max(event_time) − allowedLateness`; finalizes windows + evicts old state. Too tight=drop late; too loose=OOM. |
| Pick watermark by | Measuring the real lateness distribution (P99 + margin), not a guess. |
| Late event after watermark | Dropped from window; route to side table + batch-correct if it matters. |
| Stateful OOM fix | Watermark (bound state) + RocksDB state store; THEN memory. Streaming OOM = state, usually not skew. |
| Default vs RocksDB state store | Default on-heap (small state, OOMs); RocksDB off-heap on disk (large state). Use RocksDB for any real stateful stream. |
| Triggers | default (ASAP), processingTime (interval), **availableNow** (drain+stop = incremental batch), continuous (niche). |
| availableNow on a schedule | Incremental freshness at near-batch cost — the always-on vs nightly middle ground. |
| Stream-static join | Stream ⨝ Delta dim; static re-read per batch; NO state; the workhorse for enrichment. |
| Stream-stream join | State both sides + watermarks both + time-bound condition, or state grows forever. Memory-heavy. |
| Upsert from stream | `foreachBatch` + Delta `MERGE` on natural key (foreachBatch is at-least-once → MERGE makes it exactly-once). |
| foreachBatch use | Any batch op in a stream: MERGE, multi-sink, external calls. Idempotent on natural key / batch_id. |
| Falling behind | Backpressure (`maxOffsetsPerTrigger`/`maxFilesPerTrigger`) + watermark/RocksDB + parallelism + skew fixes. |
| Output modes | append (new/windowed), update (changed keys), complete (whole small agg). |
| Schema change | `schemaEvolutionMode`/rescue (files) or schema registry (Kafka) + CI schema-diff = contained event. |
| Deploy to running stream | Restart from same checkpoint if compatible; incompatible (stateful key/logic change) → new checkpoint + reprocess. |
| DLT / Lakeflow | Declarative tables + expectations + managed checkpoints/retries; use for DQ-heavy simple pipelines; hand-roll for custom state. |
| What NOT to stream | Anything without a real-time *decision*. Stream hot path, batch the rest, join batch dims as static. |
| Backfill new stream | Batch backfill (shared transforms) + start stream from offset/timestamp; MERGE converges the overlap. |

### Pre-interview checklist
- [ ] Lead with **"don't stream what doesn't need to be real-time"** (the senior signal)
- [ ] Exactly-once = replayable source + checkpoint + idempotent MERGE (say all three)
- [ ] Watermark: what it does (finalize + evict) + how you *chose* the value (measured P99)
- [ ] Stateful OOM = state growth → watermark + RocksDB, NOT memory first
- [ ] Stream-static (workhorse) vs stream-stream (hard, dual watermarks)
- [ ] `foreachBatch` + MERGE for upserts; `availableNow` for cheap incremental
- [ ] Memorize: **6h→90s · 50k events/s · exactly-once · 99.9% on-time · stream 30% / batch 70%**
- [ ] For Dmitry: streaming is a cost (pragmatic scoping), one code path batch+stream, 24/7 monitoring/alerting made it operable

---

*Last updated: 2026-05-28*
