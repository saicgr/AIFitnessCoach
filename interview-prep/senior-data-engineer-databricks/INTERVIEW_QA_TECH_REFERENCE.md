# Senior Data Engineer — Ultimate Technical Reference Table
## Every Spark / Delta / Databricks term: what · where it runs · when · why · how

> **Self-contained operational cheat sheet.** Everything is in this one file — what each thing *is*, **where it executes** (S3 / driver / executor / metadata), **when it fires** (write-time / maintenance / query-planning / query-runtime), **why** you reach for it (OOM, skew, small files, late data…), a **tiny code** snippet, the gotcha, plus two scenario question banks (§13 quick, §14 deep diagnostics) with inline answers. No need to open any other file.
>
> **The "When" vocabulary** (used in every table): **Write-time** (as data lands) · **Maintenance** (a separate scheduled/explicit job) · **Query-planning** (driver, before execution) · **Query-runtime** (during execution, e.g. AQE) · **Read-time** (automatic on read) · **Commit-time** (the atomic `_delta_log` append). Big interview point: *OPTIMIZE/VACUUM are **maintenance** jobs (not read- or write-time); partition pruning is **planning**; AQE is **runtime**.*
>
> **Facts current as of 2026-05 (verified):** liquid clustering GA in DBR 15.2+; AQE `skewedPartitionFactor=5`, `skewedPartitionThresholdInBytes=256MB`, `advisoryPartitionSizeInBytes=64MB`; `autoBroadcastJoinThreshold=10MB`; VACUUM retention default 7 days.

---

## 0. First — the "where + when does it run?" mental model (say this in interviews)

Almost nothing in Spark/Delta is "executor only," and timing splits into clear buckets:

- **Driver** = the brain. Plans the query, schedules tasks, decides *which* files to touch, and **commits to `_delta_log`** (atomic step). Reads metadata, not row data. OOMs on `.collect()` / huge broadcast / planning over millions of files.
- **Executors** = the muscle. Read/sort/shuffle/transform/write the actual **Parquet files in parallel**. OOM on skew / wide aggregation / oversized partitions.
- **S3 (object storage)** = where the bytes live (data files + `_delta_log` JSON).
- **Metadata-only** = touches `_delta_log` / catalog stats, not data files (cheap, no shuffle).

**Three timing buckets:** (1) **Write-time** layout (partition, liquid clustering, Auto Optimize). (2) **Maintenance** (OPTIMIZE, Z-ORDER, VACUUM, ANALYZE — separate jobs). (3) **Query-time**, split into **planning** (Catalyst/CBO, pruning, data skipping — *before* execution) and **runtime** (AQE re-planning *during* execution).

**One-liner:** *"Driver plans and commits the `_delta_log`; executors do the parallel file I/O on S3; OPTIMIZE/VACUUM are maintenance jobs, pruning is planning-time, AQE is runtime."*

---

## 1. Table maintenance / file layout

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **OPTIMIZE** | Compacts small files into ~1 GB files | Driver picks+commits; executors rewrite; S3 | **Maintenance** (explicit/scheduled or Predictive Opt) | Small-files → slow scans, task explosion, log bloat | `OPTIMIZE t WHERE date>='2026-01-01'` | A real compute job; off-peak. NOT read- or write-time. |
| **Z-ORDER** | Co-locate rows by chosen high-card cols | Executors (shuffle+sort+rewrite) | **Maintenance** (part of OPTIMIZE) | Slow filters/joins → enable data skipping | `OPTIMIZE t ZORDER BY (retailer_id)` | **Heaviest** op (full sort, can spill). NOT incremental — rewrites all. |
| **Liquid Clustering** | Auto-managed replacement for partition + Z-ORDER | Executors (incremental) | **Write-time (incremental) + maintenance** | Removes hand-tuning; rewrites only what's needed | `CREATE TABLE t CLUSTER BY (k)` / `CLUSTER BY AUTO` | GA 15.2+. Recommended over Z-ORDER for new tables. Keys changeable w/o full rewrite. |
| **VACUUM** | Delete old unreferenced files past retention | Driver lists+diffs; deletion parallel; S3 | **Maintenance** (explicit/scheduled) | Reclaim storage from tombstoned files | `VACUUM t RETAIN 168 HOURS` | **Lightest op** (metadata/IO, no shuffle/sort). Default 7d. `RETAIN 0` breaks time travel + live readers. |
| **PARTITION** (storage) | Split into dirs by low-card col | Executors write (+shuffle if unsorted) | **Write-time** | Partition pruning for `WHERE date=…` | `… PARTITIONED BY (sales_date)` | **Never high-cardinality** (tiny files). Liquid usually beats it. |
| **partition pruning** | Read only matching partition dirs | Driver, metadata | **Query-planning** | Avoid full scan on time filters | `WHERE sales_date='2026-05-27'` | Breaks if you wrap col in a function. Verify `EXPLAIN FORMATTED`→`PartitionFilters`. |
| **data skipping** | Skip files whose min/max can't match | Driver reads file stats | **Query-planning** | Read fewer files w/o partitioning | (automatic) | Effective when clustered on the filtered col. Stats: first 32 cols. |
| **Auto Optimize / Optimized Writes** | Write larger files at write time | Executors at write | **Write-time** | Prevent small files at the source | `delta.autoOptimize.optimizeWrite=true` | Slight write latency for fewer small files. Good for streaming sinks. |
| **Predictive Optimization** | DB auto-runs OPTIMIZE/VACUUM/cluster via ML | DB-managed background jobs | **Maintenance (auto)** | No manual maintenance scheduling | (enable at catalog) | UC managed tables only. Integrates with `CLUSTER BY AUTO`. |
| **deletion vectors** | Mark rows deleted w/o rewriting the file | Executors write tiny DV files | **Write-time** (DELETE/UPDATE/MERGE) | Faster DML (no full-file rewrite) | `delta.enableDeletionVectors=true` | Files "look old" but stay referenced → VACUUM waits until OPTIMIZE materializes. |

---

## 2. Joins + skew handling

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **Sort-merge join (SMJ)** | Default big↔big: shuffle both, sort, merge | Executors (shuffle+sort) | **Query-runtime** | General join when neither side small | (default) | Two shuffles + sort. AQE can switch to broadcast mid-query. |
| **Broadcast hash join (BHJ)** | Ship small table to every executor | Driver collects+broadcasts; executors join | **Query-planning / runtime** | Kill the shuffle when one side small | `df.join(broadcast(dim),"k")` | Backfires if "small" is big → OOM. Auto threshold **10 MB**. |
| **Broadcast hint** | Force a broadcast join | Driver, planning | **Query-planning** | Override wrong size estimate | `/*+ BROADCAST(u) */` | Don't force a secretly-large side. `autoBroadcastJoinThreshold=-1` to disable auto. |
| **Shuffle hash join** | Hash join after shuffle, no sort | Executors (shuffle) | **Query-runtime** | Mid-size without sort | (planner choice) | Less common; SMJ+AQE usually preferred. |
| **AQE** | Re-optimize at runtime from real stats | Driver re-plans between stages | **Query-runtime** | Static estimates wrong on skewed/filtered data | `spark.sql.adaptive.enabled=true` | 3 moves: coalesce, switch-to-broadcast, split skew. On by default. |
| **AQE skew join** | Split oversized partition + replicate other side | Executors; driver detects | **Query-runtime** | Skew → one straggler does 100× | `…skewJoin.enabled=true` | Triggers > **5× median AND > 256 MB**. Lower factor to 3. |
| **Salting** | Random suffix on hot key to spread it | Executors (you add a col) | **Job runtime** (you code it) | Skew AQE doesn't fully fix | `key,(rand()*N)::int AS salt` | **Last resort** (code change). Replicate other side ×N. |
| **Salted MERGE** | Salt inside a MERGE for a skewed merge key | Executors | **Job runtime** | Skewed `MERGE` on a hot key | salt both sides, `ON t.k=s.k AND t.salt=s.salt` | Niche; justify it. |
| **data skew** | Uneven key dist → one task gets most rows | Symptom on executors | **Query-runtime (symptom)** | #1 cause of slow stages + executor OOM | `GROUP BY key ORDER BY count DESC` | Spark UI max≫median. Fix: filter→AQE→broadcast→salt. NULL keys = hidden skew. |
| **shuffle** | Redistribute data by key over network | Executors; driver schedules | **Query-runtime** | Inherent to wide ops; minimize it | (implicit) | Tune `shuffle.partitions`=`bytes/128MB`. |

---

## 3. Partition tuning

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **shuffle partitions** | How many partitions a shuffle makes | Executors; config | **Query-runtime** | Default 200 too low → spill | `spark.conf.set("spark.sql.shuffle.partitions",2000)` | `bytes/128MB`. With AQE set high + let it coalesce. |
| **COALESCE** | Reduce partitions, NO shuffle | Executors (narrow, cheap) | **Job runtime** | Write fewer files; shrink | `df.coalesce(8).write…` | Can be uneven. Use to *shrink*, esp. before write. |
| **REPARTITION** | Change partitions WITH full shuffle (even) | Executors (full shuffle) | **Job runtime** | Grow parallelism / rebalance skew | `df.repartition(200,"key")` | Even but costly. Grow/rebalance; coalesce to shrink. |
| **AQE coalesce partitions** | Auto-merge tiny post-shuffle partitions | Driver decides; executors | **Query-runtime** | Avoid thousands of empty tasks | (automatic with AQE) | Why you can set shuffle.partitions high. `advisoryPartitionSizeInBytes`=64 MB. |

---

## 4. Ingestion

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **Auto Loader (`cloudFiles`)** | Incremental file ingest, only new files | Executors read S3; driver tracks checkpoint; SNS/SQS | **Ingest / write-time (streaming)** | Incrementally ingest a growing drop, exactly-once | `spark.readStream.format("cloudFiles")…` | Checkpoint tracks files. Notification mode for high volume. N files = ONE run. |
| **COPY INTO** | Idempotent batch SQL file load | Executors load; driver commits | **Ingest (batch run)** | One-shot/scheduled load | `COPY INTO t FROM 's3://…' FILEFORMAT=CSV` | Skips already-loaded files. Bounded loads; Auto Loader for continuous. |
| **schema evolution** | Auto-adapt schema when source adds cols | Executors; schema in checkpoint/log | **Ingest / read-time** | Producer adds a column → don't break | `.option("cloudFiles.schemaEvolutionMode","addNewColumns")` | Modes: addNewColumns / rescue / failOnNewColumns / none. Pair w/ CI diff. |
| **rescue mode / `_rescued_data`** | Unexpected cols → JSON catch-all | Executors | **Ingest-time** | Never lose data | `…schemaEvolutionMode","rescue"` | Alert on non-empty `_rescued_data`. Safest bronze default. |
| **mergeSchema** | Let a write add new columns | Driver updates log; executors write | **Write-time** | Append a DF with extra cols | `df.write.option("mergeSchema","true")…` | Write-time (≠ read-time Auto Loader evolution). `overwriteSchema` for type changes. |
| **schema inference** | Detect schema from sample files | Driver/executors sample S3 | **Ingest-time (first read)** | Avoid hand-writing DDL | `.option("cloudFiles.inferColumnTypes","true")` | Sampled → can guess wrong. Pin schema for prod-critical feeds. |

---

## 5. Caching

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **`cache()` / `persist()`** | Keep a DF in executor memory/disk | Executors (RAM/disk) | **Job runtime (on action)** | Reused DF recomputed each action | `df.cache(); df.count()` | Lazy — needs an action. Unpersist when done; over-cache → OOM. |
| **Delta cache / disk cache** | Auto-cache remote Parquet on local NVMe | Executors (local SSD) | **Read-time (automatic)** | Repeated reads of same S3 files | (automatic on cache instances) | File-level, automatic, cluster-wide (≠ `cache()`). |
| **result cache (SQL warehouse)** | Cache identical query results | SQL warehouse | **Query-time** | Repeated identical BI queries | (automatic) | Invalidated on data change. |
| **broadcast variable** | Read-only value shipped once to executors | Driver → executors | **Job runtime** | Avoid re-sending a lookup per task | `sc.broadcast(my_dict)` | ≠ broadcast *join*. For small lookups in UDFs. |

---

## 6. Stats, inspection, query plans

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **ANALYZE TABLE** | Compute stats for the CBO | Executors scan; stats in catalog | **Maintenance (on-demand)** | Better join/plan decisions | `ANALYZE TABLE t COMPUTE STATISTICS FOR ALL COLUMNS` | Delta auto-collects basics on write. Needed for CBO reordering. |
| **DESCRIBE DETAIL** | Metadata: numFiles, sizeInBytes, location | Driver (metadata) | **On-demand (instant)** | Diagnose small files / layout | `DESCRIBE DETAIL t` | First check for small-files. Metadata-only. |
| **DESCRIBE HISTORY** | Audit log of every table version | Driver (metadata) | **On-demand** | "What changed?" find bad OPTIMIZE/overwrite | `DESCRIBE HISTORY t` | Step 4 of slow-job triage. Powers time travel. |
| **EXPLAIN / FORMATTED** | Show the physical plan | Driver (planning only) | **Query-planning (no exec)** | Verify pruning, join type, broadcast | `EXPLAIN FORMATTED SELECT …` | Look for PartitionFilters, BroadcastHashJoin vs SMJ, PushedFilters. |
| **time travel** | Query an old version/timestamp | Driver reads old log; executors read files | **Query-time** | Audit, rollback, reproduce report | `SELECT * FROM t VERSION AS OF 42` | Bounded by VACUUM retention. |
| **Spark UI** | Runtime job/stage/task inspector (~8 tabs) | Driver-hosted UI | **Runtime (observability)** | Diagnose skew, spill, slow stage | (UI) | **Stages tab → stage → Summary Metrics** (Max≫Median = skew); **Executors tab** (Spill/GC/OOM); **SQL tab** (join type/pruning). Full guide in §15. |

---

## 7. Transactions / write semantics

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **MERGE** | Upsert: match key → UPDATE/INSERT/DELETE | Executors (join+write); driver commits | **Write + commit-time** | Idempotent loads, SCD2, CDC, dedup | `MERGE INTO t USING s ON t.k=s.k …` | Idempotency + SCD2 workhorse. Skewed merge key → slow. Broadcast small source. |
| **ACID commit** | Write all-or-nothing via log append | Driver | **Commit-time** | Crash mid-write → no partial data | (every Delta write) | Atomic step is driver-side. Foundation of exactly-once. |
| **idempotent** | Run twice = same as once | Design property | **Design** | Retries/replays must not duplicate | MERGE on natural key | Append+retry = dupes; MERGE converges. |
| **checkpoint** (streaming) | Durable stream progress (offsets+state) | Driver writes; executors state; S3 | **Stream runtime** | Exactly-once resume | `.option("checkpointLocation",path)` | One per stream. Delete = reprocess all. |
| **foreachBatch** | Hand each micro-batch to batch code | Executors per batch; driver orchestrates | **Stream runtime (per batch)** | Upsert/multi-sink from a stream | `…writeStream.foreachBatch(fn)` | At-least-once → idempotent MERGE / batchId dedup. |
| **OPTIMISTIC concurrency** | Detect conflicting commits, retry/fail | Driver at commit | **Commit-time** | Concurrent writers to one table | (automatic) | Two writers same files → one retries/fails. Partition to reduce. |

---

## 8. Streaming-specific

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **watermark** | `max(event_time)−lateness`; finalize+evict state | Executors (state); driver tracks | **Stream runtime** | Bound state + handle late data | `.withWatermark("ts","2 hours")` | Too tight=drop late; too loose=OOM. Set from P99. |
| **state store** | Where stateful streaming keeps state | Executors (on-heap, or RocksDB) | **Stream runtime** | Stateful ops across batches | `…stateStore…RocksDB…` | Streaming OOM = state growth. Fix: watermark + RocksDB. |
| **trigger** | When the next micro-batch fires | Driver schedules | **Stream scheduling** | Latency vs cost | `.trigger(availableNow=True)` | `availableNow`=drain+stop (cheap). `processingTime`=interval. |
| **backpressure** | Cap how much one batch ingests | Executors; config | **Stream runtime** | Burst → giant batch → blow SLA | `.option("maxFilesPerTrigger",1000)` | Kafka: maxOffsetsPerTrigger. |
| **stream-static join** | Stream ⨝ static Delta dim, NO state | Executors | **Stream runtime (per batch)** | Enrich events with dims | `events.join(dimDF,"k")` | Workhorse. Dim updates picked up next batch. |
| **stream-stream join** | Two streams, state both sides + watermarks | Executors (state-heavy) | **Stream runtime** | Correlate two event streams | both `withWatermark` + time-bound ON | Needs watermarks + time bound or state grows forever. |

---

## 9. Compute / cluster

| Term | What it is | Where | When | Why (problem) | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **Photon** | C++ vectorized query engine | Executors | **Query-runtime** | More work per DBU on SQL/scan | (toggle on cluster) | Off for Python-UDF-heavy (breaks vectorization). |
| **autoscaling** | Add/remove workers with load | Cluster manager | **Cluster runtime** | Pay for window, scale to zero | (min/max workers) | The elastic cost lever. |
| **cluster policy** | Guardrails (size, types, terminate, tags) | Account/admin | **Cluster create-time** | Self-service w/o runaway cost | (policy JSON) | Tags + auto-terminate = cost controlled. |
| **job cluster (ephemeral)** | Spins up per job, terminates after | Cluster manager | **Job runtime** | No idle compute for batch | (job config) | Cheaper than all-purpose left running. |
| **pools** | Pre-warmed idle instances | Cluster manager | **Cluster start-time** | Reduce startup latency | (pool config) | A little idle cost for fast starts. |
| **DBU** | Databricks billing unit (per-second) | Billing | **Continuous** | The cost metric you optimize | `system.billing.usage` | Photon does more per DBU. |

---

## 10. Governance / catalog

| Term | What it is | Where | When | Why | Tiny code | Gotcha |
|---|---|---|---|---|---|---|
| **Unity Catalog (UC)** | Governance: grants, lineage, audit | Metastore + engine | **Query-time (enforced)** | One governance model across SQL/Spark/ML | `GRANT SELECT ON t TO group` | 3-level `catalog.schema.table`. Lineage built in. |
| **row filter / column mask** | Restrict rows / mask cols per group | Engine (executors apply) | **Query-time** | Fine-grained access, no scattered views | `ALTER TABLE t SET ROW FILTER f ON (region)` | The Lake Formation / RLS replacement. |
| **managed vs external table** | UC manages storage vs you point at S3 | Metadata | **Create-time** | Managed → Predictive Opt eligible | `CREATE TABLE …` vs `… LOCATION 's3://…'` | Managed gets auto-maintenance. |

---

## 11. Quick decision rules ("which do I reach for")

| Symptom / goal | Reach for | Not |
|---|---|---|
| Slow scans, thousands of tiny files | `OPTIMIZE` (+ Auto Optimize at write) | partitioning harder |
| Slow filters/joins on high-card col | Z-ORDER / **liquid clustering** | partitioning on that col |
| New table, don't want to hand-tune | **liquid clustering `CLUSTER BY AUTO`** | partition + Z-ORDER |
| Reclaim storage after deletes/OPTIMIZE | `VACUUM` (retain ≥7d) | `RETAIN 0 HOURS` |
| Time-filtered queries scan whole table | partition by date | partition by id |
| One task 100× slower (skew) | AQE skew join → broadcast → **salt** | bumping memory first |
| Small dim join causing a shuffle | broadcast (auto/hint) | broadcasting a 500 MB "dim" |
| Too many tiny output files | `coalesce(n)` before write | `repartition` (full shuffle) |
| Need even partitions / grow parallelism | `repartition(n, col)` | `coalesce` (uneven) |
| Spill on a big shuffle | raise `shuffle.partitions` + AQE | more memory first |
| Continuous file ingest, exactly-once | **Auto Loader** + checkpoint | re-reading the whole prefix |
| Bounded/periodic file load | `COPY INTO` | a hand-rolled dedup |
| Source added a column | schema evolution / `rescue` | failing the pipeline |
| Upsert / SCD2 / CDC apply | `MERGE` on natural key | append (dupes) |
| Streaming OOM, state climbing | watermark + **RocksDB** | bigger executors first |
| "What changed / why slow today?" | `DESCRIBE HISTORY` + Spark UI + `EXPLAIN` | guessing |

---

## 12. The 12 one-liners to deliver (memorize)

1. **Driver plans + commits `_delta_log`; executors do parallel file I/O on S3; the commit is the atomic step → ACID.**
2. **OPTIMIZE = compaction; it's a maintenance job, not read/write-time.**
3. **VACUUM = delete dead files (lightest op, metadata); default 7-day retention; `RETAIN 0` breaks time travel.**
4. **Z-ORDER = co-locate by high-card filtered cols (heaviest, full sort, not incremental); liquid clustering is the incremental modern replacement, GA 15.2+.**
5. **Partition by low-card date; cluster by high-card join key; never partition a high-card col.**
6. **Sort-merge = default big↔big (two shuffles); broadcast = ship small side, no shuffle (backfires if big, default 10 MB).**
7. **AQE re-plans at runtime: coalesce, switch-to-broadcast, split skew (5× median AND >256 MB).**
8. **Skew fix order: filter → AQE skew join → broadcast → salt (last). Find via Spark UI max≫median.**
9. **coalesce = shrink no-shuffle (uneven); repartition = full shuffle (even).**
10. **Auto Loader = incremental file stream + checkpoint (exactly-once); COPY INTO = idempotent batch load.**
11. **Schema evolution: `rescue` never loses data; `addNewColumns` stops-adds-resumes; pair with CI schema-diff.**
12. **MERGE on natural key = idempotent upsert / SCD2 / CDC; makes retries safe.**

---

## 13. Interview question bank — quick scenarios (self-contained, explained)

> Cover the answer, read the scenario, respond out loud in 30-60s. Each answer explains the *mechanism*, not just the keyword — so it teaches, not just reminds.

### Table maintenance / file layout

**"Nightly read got slow over weeks, no logic changed. Why?"**
Small-files creep. Each write (especially frequent micro-batches/streaming) drops new small Parquet files, and nobody compacts them — so over weeks the table goes from hundreds of files to tens of thousands of tiny ones. Every file is a separate open/read + a metadata entry in `_delta_log`, so the *planning* alone gets slow before any data is read. Diagnose: `DESCRIBE DETAIL t` → `numFiles` is huge vs `sizeInBytes`. Fix: run `OPTIMIZE` to bin-pack them into ~1 GB files, and turn on Auto Optimize so future writes land larger. It's a file-layout problem, not a compute one — adding workers won't help.

**"Queries filtering/joining on `retailer_id` are slow. What do you do?"**
The rows you need are scattered across many files, so Spark reads almost every file (no skipping). Fix: **cluster** the table on `retailer_id` — `OPTIMIZE t ZORDER BY (retailer_id)` or liquid clustering — which physically co-locates rows with the same `retailer_id` into the same files. Then Delta's min/max file stats let it **skip** files that can't contain your value (data skipping). Do NOT *partition* by `retailer_id`: it's high-cardinality, so you'd get thousands of tiny single-retailer directories (the small-files disaster). Rule: partition by low-card date, cluster by high-card keys.

**"Liquid clustering vs partitioning + Z-ORDER — when do you pick each?"**
Use **liquid clustering for new tables.** The reason: Z-ORDER is a *full, non-incremental* rewrite — every `OPTIMIZE ZORDER` re-sorts the whole table (huge write amplification, long jobs). Liquid clustering is **incremental** — it only rewrites the new/unclustered data, you can *change the clustering keys later* without rewriting everything, and `CLUSTER BY AUTO` + Predictive Optimization picks and maintains the keys for you. GA in DBR 15.2+; Databricks now recommends it over Z-ORDER for all new tables. I'd only stay on partition+Z-ORDER for an older runtime or an existing well-tuned table not worth migrating.

**"Storage cost is climbing but row count isn't. Fix?"**
Every UPDATE/DELETE/MERGE/OPTIMIZE writes *new* files and tombstones (logically removes, but doesn't physically delete) the old ones — so old file versions pile up on S3, plus time-travel history. Diagnose: `DESCRIBE DETAIL` size vs logical rows, `DESCRIBE HISTORY` for write volume. Fix: `VACUUM t RETAIN 168 HOURS` deletes the tombstoned files older than the retention window. VACUUM is the *lightest* maintenance op — it's just listing + deleting files (metadata/IO), no shuffle or sort, no data rewrite.

**"Someone ran `VACUUM RETAIN 0 HOURS`. What breaks?"**
`RETAIN 0` deletes *all* unreferenced files immediately. That breaks two things: (1) **time travel** — you can no longer query older versions because their files are gone; (2) **any in-flight reader or streaming job** still pointing at those older files mid-query suddenly finds them deleted → it fails or returns corrupt results. The 7-day default exists to give running jobs + time travel a safety window. Keep retention ≥7 days.

**"Is OPTIMIZE/VACUUM done on the executor or the driver?"**
Both, split by role. The **driver** plans the operation (decides which files to compact or delete) and **commits** the result to `_delta_log` (the atomic step). The **executors** do the actual parallel file I/O — reading small files and writing big ones for OPTIMIZE. VACUUM is the exception: it's mostly driver-coordinated file listing + deletion (metadata/IO), so it's the lightest, with no shuffle or sort.

**"Why not just partition by `user_id` to speed up user-level queries?"**
`user_id` is high-cardinality — millions of distinct values. Partitioning creates one directory per value, so you'd get millions of directories each holding one tiny file. That's the small-files disaster: massive `_delta_log`, slow planning, terrible reads — worse than no partitioning. Partition only by *low-cardinality* columns you filter on (date/month), and handle high-card keys with clustering (Z-ORDER/liquid) instead.

### Joins / skew / broadcast

**"Your Spark job fails with OutOfMemoryError on the executor. Walk me through it."**
First, confirm it's the **executor** not the driver — check the **Spark UI → Executors tab** (see which executor shows failed tasks / high memory) vs the driver log; they have different causes. Then go to the **Spark UI → Stages tab → click the failed/slow stage → the "Summary Metrics for … Tasks" table** at the top of that stage page. If **Max** duration/Shuffle-Read-Size is far above the **Median** row, it's **data skew** — one partition holds most of the rows so that one task can't fit its slice in memory (uniform-but-slow across all percentiles would mean genuine under-provisioning instead). Fix the *data layout* first: enable AQE skew-join, route NULL/dominant keys to an "unknown" member, or salt the hot key — before adding memory. Bumping executor memory to mask a skewed partition just costs money without fixing the root cause. *(See §15 for the exact Spark UI navigation.)*

**"One task runs 100× longer than the other 199. What is it and how do you fix it?"**
Data skew — one key (or NULL) dominates a single partition, so 199 tasks finish fast and one chews through most of the data. Fix in cost order: (1) **filter** the skewed value if it's junk you can drop; (2) **AQE skew-join** — it auto-splits an oversized partition into sub-partitions (lower `skewedPartitionFactor` to 3 so it triggers sooner); (3) **broadcast** the other side if it's small (removes the shuffle entirely); (4) **salt** the hot key as a last resort (add a random suffix so it spreads across tasks — it's a code change, so justify it).

**"A star join on a small dimension is doing a big shuffle. How do you fix it?"**
Force a **broadcast join**: ship the small dim to every executor so the big fact table never has to be shuffled across the network. Spark auto-broadcasts tables under `autoBroadcastJoinThreshold` (default 10 MB), or you hint it: `SELECT /*+ BROADCAST(dim) */ …`. Each executor then joins its slice of the fact table against its local copy of the dim — no shuffle, much faster. Only do this when the dim is genuinely small (see the next question for the failure mode).

**"You added a BROADCAST hint and the job OOMed. Why?"**
Because a broadcast join works by **pulling the entire "small" table up to the driver, then shipping a full copy into every executor's memory** so each can join locally. That's only safe when the table is truly small. If the side you broadcast is actually large (you forced a hint on a 2 GB table, or a dim grew, or it only *looked* small before a filter), two things blow up: (1) the **driver** can't hold the whole table while collecting it → driver OOM; (2) even if the driver survives, **every executor** now holds a full giant copy *on top of* its working data → executor OOM. Fix: check the *real* (post-filter) size before broadcasting — only broadcast genuinely small tables (under ~100 MB, default auto-threshold 10 MB). If Spark keeps auto-broadcasting something too big, set `spark.sql.autoBroadcastJoinThreshold=-1` to **disable automatic broadcasting**, forcing it back to a (slower but safe) sort-merge join.

**"What's the default join for two billion-row tables, and what does it cost?"**
**Sort-merge join (SMJ).** Spark shuffles *both* tables across the network so all rows with the same key land on the same executor, sorts each side by the key, then merges them. The cost is two big shuffles + a sort — expensive, but it's the only general approach when neither side is small enough to broadcast. With AQE on, if one side turns out small after filtering, Spark can switch it to a broadcast join mid-query and skip the second shuffle.

**"How do you detect skew before you try to fix it?"**
Two ways. (1) **Spark UI → Stages tab → click the slow stage → "Summary Metrics for … Tasks" table**: if the **Max** task time / Shuffle-Read-Size row is far above the **Median / 75th percentile** row, that's skew (a single straggler). (2) **Profile the key** directly: `SELECT key, count(*) c FROM t GROUP BY key ORDER BY c DESC LIMIT 20` — a few keys holding most rows = skewed. Always check **NULL keys** too: all NULLs hash to the same partition, so a column full of NULLs creates hidden skew even when no business key is huge. *(§15 has the exact navigation.)*

**"AQE is on — what three things does it actually do at runtime?"**
After a shuffle finishes, AQE has the *real* data statistics (not the planner's guesses), so it re-optimizes: (1) **coalesces** tiny post-shuffle partitions together so you don't run thousands of near-empty tasks; (2) **switches** a planned sort-merge join to a broadcast join if a side turns out small after filtering (saves a shuffle); (3) **splits a skewed partition** into sub-partitions and replicates the other side — but only when a partition is > 5× the median AND > 256 MB. It's on by default and mostly "set and forget."

**"When is salting justified versus overkill?"**
Salting (adding a random suffix to a hot key so it spreads across N tasks, then replicating the other side ×N) is a **last resort** — only after AQE skew-join and broadcasting have failed and you have one extremely dominant key. It's overkill otherwise because the ×N replication adds real work: if the key isn't badly skewed, that overhead outweighs the benefit, and it's a code change you have to maintain. Reach for the automatic fixes (AQE, broadcast) first; salt only when they can't handle the hot key.

### Partitions / shuffle

**"A big shuffle is spilling 4 TB to disk. What's your first move?"**
Spill = the shuffle data doesn't fit in executor memory so Spark writes it to local disk (slow). The first move is **not** more memory — it's more partitions. With only 200 shuffle partitions on a huge dataset, each partition is enormous and can't fit, so it spills. Raise `spark.sql.shuffle.partitions` to roughly `total_shuffle_bytes / 128MB` (often thousands), keep AQE on to coalesce them back down on small days, and check for skew. Re-partitioning typically drops multi-TB spill to tens of GB; memory is the last lever, not the first.

**"coalesce vs repartition — when do you use each?"**
`coalesce(n)` **reduces** partition count *without a shuffle* — it just merges existing partitions on the same executors. Cheap, but can produce uneven partition sizes. Use it to **shrink**, especially right before a write to produce fewer output files. `repartition(n, col)` does a **full shuffle** to produce `n` *evenly-sized* partitions — costly, but balanced. Use it to **grow parallelism** or **rebalance skew**. Rule: coalesce to write fewer files; repartition to grow or rebalance.

**"Your job writes 5,000 tiny output files. Fix without a full shuffle?"**
`df.coalesce(n).write…` right before the write. Coalesce merges the existing partitions down to `n` *without shuffling* (it just combines them on the same executors), so you write a handful of large files instead of 5,000 tiny ones. Using `repartition` would also work but triggers a full, expensive shuffle — unnecessary here since you only need to *reduce* file count, not rebalance.

**"`shuffle.partitions` is 200 (default) and your data is 2 TB. What's the problem?"**
200 partitions on 2 TB = ~10 GB per partition — far too big to fit in memory, so every task spills to disk and may OOM. The default of 200 was set for small data years ago. Set it to ~`bytes/128MB` (thousands of partitions) so each task handles a manageable ~128 MB. With AQE on, you can safely set it high because AQE coalesces the excess back down on days when the data is smaller — so you get high parallelism when needed and low overhead when not.

### Ingestion / schema

**"50 files land at once — does it start the cluster 50 times?"**
No. The **job/DAG** starts the cluster once. Auto Loader then picks up all 50 new files in a single run and processes them in parallel across the executors — the file count drives *task parallelism*, not the number of cluster starts. 1 file or 50 files = the same single cluster lifecycle. (50 tiny files do create a downstream small-files concern → OPTIMIZE; and for very high file counts use notification mode (SNS/SQS) so Auto Loader doesn't have to list the whole directory.)

**"Auto Loader vs COPY INTO — when do you use each?"**
**Auto Loader** for *continuous/incremental* ingestion of a growing file drop: it's a streaming source with a checkpoint (tracks processed files for exactly-once), scales to high file volumes, and supports notification mode. **COPY INTO** for *bounded/periodic* batch loads: it's an idempotent SQL command that skips files it already loaded — simpler, no streaming infrastructure, good for a scheduled "load whatever's in this folder." Both give exactly-once; pick by continuous-vs-bounded.

**"A distributor silently added a column overnight. What happens?"**
With schema evolution it's a contained event, not an outage. `schemaEvolutionMode=addNewColumns` makes the stream stop once, add the new column to the schema, and resume (old rows get null for it). `rescue` mode lands any unexpected fields in a `_rescued_data` JSON column so **nothing is ever lost** — you alert on that column being non-empty. Back it with a **CI schema-diff** that compares the incoming header to the registered contract so you catch the change *before* prod. For Kafka, a schema registry with compatibility rules does the same job.

**"Where does Auto Loader track which files it's already processed?"**
In its **checkpoint** — a RocksDB store of processed file paths + offsets, kept in cloud storage (S3/DBFS/UC volume), separate from your cluster so it survives restarts. This is the engine's own exactly-once mechanism; it does *not* read your business manifest. (Your manifest table is the separate operational/audit record — "did the file arrive, is it valid, SLA.") Deleting the checkpoint makes Auto Loader forget everything and reprocess all files.

**"mergeSchema vs Auto Loader schema evolution — what's the difference?"**
Different stages. `mergeSchema` is **write-time**: when you `df.write.option("mergeSchema","true")`, you let a write add new columns to the *target* table. Auto Loader schema evolution is **read/ingest-time**: it adapts as the *source files* add columns during ingestion. One is about the table accepting a wider DataFrame on write; the other is about the reader handling a changing source. Don't conflate them.

### Transactions / streaming / platform

**"A 100 GB load fails at 50%. Is there partial data? Dupes on retry?"**
Neither. The Delta write is **atomic** — the batch only "appears" when its commit is appended to `_delta_log`, so a crash at 50% leaves *zero* committed rows (no partial data; readers never see half a load). And the **checkpoint** records exactly what committed, so the rerun reprocesses only the uncommitted unit — no duplicates. Atomic commit (no partial) + checkpoint (resume from uncommitted) = exactly-once. The anti-pattern that breaks this is a naive `append` in a Python loop that writes as it goes — that *would* leave 50% committed and re-append on retry.

**"The source re-sends the same data under a new filename. Dupes?"**
You need two layers. The **checkpoint** dedups identical *file paths*, which handles plain retries — but a re-send under a *new* filename is a new path, so the checkpoint won't catch it. The second layer is an **idempotent MERGE on the natural key**: instead of appending, you `MERGE` on (e.g.) `retailer_id + product_id + date`, so a re-send *updates* the existing row rather than inserting a duplicate. File-level dedup handles retries; data-level MERGE handles re-sends — you need both for true exactly-once at the business grain.

**"How do you upsert from a stream? You can't MERGE a stream directly."**
Use `foreachBatch`. Streaming writers only support append-style sinks, but `foreachBatch` hands you each micro-batch as an ordinary **batch DataFrame**, where you can run any batch operation — including a Delta `MERGE`. Make the MERGE idempotent on the natural key, because `foreachBatch` is at-least-once by default (a batch can re-run on failure), so the MERGE must converge rather than duplicate on a replay.

**"A streaming job runs fine for hours then OOMs. Why?"**
Almost always **unbounded state**, not skew. A stateful operation (aggregation, join, dedup) without a watermark (or with one set too loose) keeps accumulating state every micro-batch — running totals, join buffers — until the executor heap is exhausted. Diagnose: the Streaming UI shows state-store rows/memory climbing batch over batch. Fix: add a `withWatermark` so old windows/keys get evicted, and switch the state store to **RocksDB** (keeps state off-heap on local disk instead of in the JVM heap, so it scales far larger). Memory is the last lever.

**"A late event arrives after the watermark. What happens to it?"**
It gets **dropped** from the stateful window — the watermark already told Spark "nothing older than this will arrive," so it finalized that window and evicted its state. If those late events matter (e.g. finance corrections), don't widen the watermark (that grows state unboundedly); instead route late/dropped events to a **side table** and reconcile them with a **batch correction job** (idempotent MERGE). Stream the 99.99% on time, batch-correct the rare tail.

**"You need 15-min freshness but 24/7 streaming compute is wasteful. What do you do?"**
Run the streaming query with `trigger(availableNow=True)` on a 15-minute schedule (a Workflow). Each run drains all new data since the last run — exactly-once via the checkpoint — then the query *stops* and the cluster terminates. So you get streaming semantics (incremental, exactly-once, checkpoint-based) at near-batch cost, because there's no always-on cluster sitting idle between runs. It's the middle ground between always-on streaming and nightly batch.

**"Databricks vs Redshift vs Snowflake — when each?"**
Pick by workload, not brand. **Databricks** (lakehouse: open Delta in your own S3, runs SQL + Spark + streaming + ML on one copy) → mixed/engineering-heavy workloads, large or semi-structured data, ML on the roadmap. **Redshift** (AWS-native SQL warehouse) → you're all-in on AWS and it's pure SQL BI on structured data. **Snowflake** (low-admin SQL warehouse, best-in-class analyst UX) → SQL-heavy analytics with minimal engineering and a non-eng team. Credit where each wins — that nuance reads as senior; declaring one universal winner reads as a zealot.

**"Photon — when do you turn it OFF?"**
Photon is Databricks' C++ vectorized engine — it does more work per DBU on SQL/scan/aggregate-heavy queries. Turn it off (or expect no benefit) on **Python-UDF-heavy jobs**: a Python UDF can't run in the vectorized engine, so execution falls back and Photon's advantage evaporates while you may still pay for it. Always measure the actual win with `system.billing.usage` rather than assuming.

---

## 14. DEEP diagnostic scenarios (the "walk me through it" set — 50)

> Longer, multi-part answers: **symptom → how you diagnose → root cause(s) → fix → prevent.** This is what senior interviews actually drill. Answer each in 60-90s.

### A. Skew, stragglers, single slow tasks (1-9)

**1. "One task in your stage takes 45 min while the other 199 finish in 2 min. What's happening and how do you fix it?"**

**Symptom:** Classic data skew — one partition holds most of the rows.

**Diagnose:**
1. **Spark UI → Stages tab → click that stage → "Summary Metrics for … Tasks" table**.
2. If **Max** duration/Shuffle-Read ≫ the **75th-pct/Median** row → skew (uniform-but-slow = resource pressure instead).
3. Find the hot key: `SELECT key, count(*) c FROM t GROUP BY key ORDER BY c DESC`.

**Fix:**
1. Filter the skewed value if droppable.
2. AQE skew join — `spark.sql.adaptive.skewJoin.enabled=true`, lower `skewedPartitionFactor` to 3.
3. Broadcast the other side if small.
4. Salt the hot key — add `(rand()*N)` suffix, replicate other side ×N — last resort.
5. ✗ Don't add memory — it won't help one fat partition. *(§15 = UI path; §17 = flowchart.)*

**2. "Your Spark job fails with OutOfMemoryError on the executor — walk through your diagnosis and the three most common root causes."**

**Symptom:** Executor OOM — confirm location, then work the three usual causes.

**Diagnose:**
1. Confirm it's **executor** not driver — **Spark UI → Executors tab** shows which executor has failed tasks / high memory / spill (vs the driver log).
2. Then **Stages tab → stage → Summary Metrics**: Max ≫ Median tells you it's skew.

**Fix (by root cause, lever order):**
1. **Skew** (one task's partition too big) → AQE skew / salt.
2. **Too few shuffle partitions** (each huge → spill → OOM) → raise `shuffle.partitions` to `bytes/128MB`.
3. **Blown broadcast** (auto-broadcast a side bigger than estimated) → tune/disable `autoBroadcastJoinThreshold`.
4. Lever order: layout/skew → shuffle partitions → `spark.executor.memoryOverhead` 10%→25% → bigger instance.
5. ✗ Bumping memory first wastes money.

**3. "Driver OOM, not executor — how is your diagnosis different?"**

**Symptom:** Driver OOM — shows in driver log, dies at collection/planning not mid-stage.

**Diagnose:**
1. Look in the **driver log**; job dies at result collection or planning, not mid-stage.
2. Triggers: `.collect()`/`.toPandas()` pulling a big result; broadcasting too large; planning over millions of files; `maxResultSize` exceeded.

**Fix:**
1. Never collect big data to the driver.
2. Cap `spark.driver.maxResultSize`.
3. Disable bad auto-broadcast.
4. Reduce file count (`OPTIMIZE`).
5. Bigger driver only if truly needed.

**4. "All 200 tasks are slow and uniform — not one outlier. What does that tell you?"**

**Symptom:** Not skew — real resource pressure or a bad plan.

**Diagnose:**
1. **Spark UI → Executors tab**: Spill + GC Time.
2. **Stages tab → Summary Metrics**: confirm all percentiles are similarly slow (uniform = capacity/plan; outlier = skew).

**Fix:**
1. Raise parallelism (`shuffle.partitions`).
2. Enable AQE.
3. Fix the join strategy (missing broadcast? wide UDF?).
4. Scale workers if genuinely under-provisioned.

**5. "NULL join keys are tanking performance even though no single business key is huge. Why?"**

**Symptom:** Hidden skew — all NULL keys hash to the same partition → one giant task.

**Diagnose:**
1. Count NULLs in the join key.
2. Check the outlier partition's key (often NULL or a sentinel like `-1`/`'UNKNOWN'`).

**Fix:**
1. Route NULL-key rows to an "unknown"/inferred member before the join.
2. Or filter them if invalid.
3. Same treatment for a dominant sentinel value.

**6. "After enabling AQE, skew is still there. Why didn't it auto-fix?"**

**Symptom:** AQE skew-join thresholds weren't tripped.

**Diagnose:**
1. AQE skew-join only triggers when a partition is **> `skewedPartitionFactor` (5) × median AND > 256 MB**.
2. A skew that's 4× median, or below 256 MB absolute, won't trip it.
3. AQE skew-split also needs the skew in a *shuffle/join* stage — not a non-shuffle path.

**Fix:**
1. Lower `skewedPartitionFactor` to 3 (and/or `skewedPartitionThresholdInBytes`).
2. If still bad, salt.

**7. "Salting fixed the skew but now the job is slower overall. Trade-off?"**

**Symptom:** Salting adds replication + a shuffle column → more total work.

**Diagnose:**
1. Salting multiplies the other side ×N and adds a shuffle column → more total work.
2. It only pays off when the skew straggler dominated wall-clock; otherwise overhead > benefit.

**Fix:**
1. Reserve salting as last resort, after AQE + broadcast.
2. Tune N to the smallest that balances the hot partition.

**8. "A GROUP BY on a high-cardinality key is OOMing/spilling. Fix?"**

**Symptom:** Wide aggregation holding too many groups per partition.

**Diagnose:**
1. High-card grouping key → too many groups held in memory per partition → spill/OOM.

**Fix:**
1. Raise `shuffle.partitions` so groups spread.
2. Ensure AQE on.
3. Avoid `collect_list`/`collect_set` on high-card keys (unbounded state per group) — use windowed/incremental aggregation.
4. Pre-aggregate if possible.
5. If it's a streaming agg, add a watermark + RocksDB.

**9. "How do you reproduce a prod skew/OOM in a dev cluster?"**

**Symptom:** Reproduce the plan + skewed slice, not the full data volume.

**Diagnose:**
1. The goal is to recreate the *plan* and the *skewed slice*, which matters more than full volume.

**Fix:**
1. Pull the exact failing partition/key range.
2. Match the **memory-per-core ratio** (not just total memory).
3. Enable heap dumps.
4. Run `EXPLAIN FORMATTED` to confirm the same physical plan (same join strategy/broadcast).

### B. Slow jobs, regressions, spill (10-16)

**10. "A job that ran in 9 min now takes 4 hours. Triage it step by step."**

**Symptom:** A previously-fast job regressed ~27× — isolate data vs layout vs plan.

**Diagnose:**
1. **Baseline** `system.workflow.job_runs` — when did it regress, by how much, did input volume change?
2. **Spark UI → Jobs tab → slowest job → Stages tab → slowest stage** — outlier task (skew) or all slow (capacity/plan)?
3. That stage's **"Summary Metrics" table** — Max vs Median.
4. `DESCRIBE HISTORY` — recent layout change (bad `OPTIMIZE ZORDER`, vacuum, overwrite)?
5. **Input shape** — new feed, a source 10×'d its file, broadcast side grew past threshold.

**Fix:**
1. Fix the specific cause (recluster / fix skew / raise partitions / fix broadcast).
2. Add a runtime-regression alert so it can't silently creep again.

**11. "Spark UI shows 4 TB of disk spill. What is spill and how do you cut it?"**

**Symptom:** Shuffle/aggregation data won't fit in executor memory → spills to local disk → slow.

**Diagnose:**
1. Causes: too-coarse partitioning (huge partitions), skew, or big aggregations.
2. Check skew first (Stages → Summary Metrics).

**Fix:**
1. Raise `shuffle.partitions` to `bytes/128MB`.
2. Ensure AQE coalesce is on.
3. Avoid high-card `collect_list`.
4. ✗ Bump memory last — re-partitioning usually drops 4 TB spill to tens of GB.

**12. "GC time is >10% of task time. What does that mean and what do you do?"**

**Symptom:** Heavy garbage collection = memory pressure (too much in heap, too-large partitions, over-caching). Sustained >85% heap = OOM incoming.

**Diagnose:**
1. **Spark UI → Executors tab → GC Time** column; >10% of task time = trouble.

**Fix:**
1. More / smaller partitions.
2. Unpersist unused caches.
3. Raise `memoryOverhead` for off-heap (Photon/Arrow) — bump if mixing Python UDFs.
4. Or switch to memory-optimized instances.

**13. "Queries got slow after someone ran OPTIMIZE. How is that possible?"**

**Symptom:** An `OPTIMIZE ... ZORDER BY` on the **wrong (low-value) columns** re-co-located data away from the hot predicates, killing data skipping.

**Diagnose:**
1. `DESCRIBE HISTORY` — confirm a recent OPTIMIZE.
2. `EXPLAIN` — files scanned jumped; ZORDER cols ≠ hot query predicates.

**Fix:**
1. Re-cluster on the columns the hot queries actually filter/join on.
2. Or move to liquid clustering.

**14. "Partition pruning isn't happening — full table scan on a date filter. Why?"**

**Symptom:** A date filter triggers a full scan because pruning is disabled.

**Diagnose:**
1. `EXPLAIN FORMATTED` → no `PartitionFilters`.
2. Usual cause: the filter **wraps the partition column in a function** (`WHERE year(sales_date)=2026`). Or it's not the partition column, or a string-vs-date mismatch.

**Fix:**
1. Filter the raw partition column directly (`sales_date >= '2026-01-01'`).

**15. "The same query is fast on the 2nd run, slow on the 1st. Why?"**

**Symptom:** Caching warms between runs — run 1 cold, run 2 hot.

**Diagnose:**
1. Delta/disk cache warmed the local-SSD file cache on run 1; result cache (SQL warehouse) may serve run 2; OS page cache too.

**Fix:**
1. For benchmarking, measure cold.
2. For production, this is expected (it's why repeated BI queries are fast) — don't "optimize" away a one-time cold-start.

**16. "Your job's wall-clock is dominated by the last 1% of tasks. Diagnose."**

**Symptom:** A long tail of stragglers dominates wall-clock — skew or a bad node.

**Diagnose:**
1. Task summary (Stages tab) — is it skew (one fat task) or one slow/bad node?

**Fix:**
1. If skew → see §A.
2. If a bad node (disk/network) → enable speculative execution (`spark.speculation=true`) to relaunch the straggler elsewhere.
3. ✗ Speculation won't help genuine skew — re-running the same fat task elsewhere is still fat.

### C. Small files, layout, storage (17-22)

**17. "Bronze has 2 million sub-MB files and planning takes forever. What happened and fix?"**

**Symptom:** Per-file streaming/micro-batch writes with no compaction → file + `_delta_log` explosion → driver spends ages listing/planning (can even OOM).

**Diagnose:**
1. `DESCRIBE DETAIL` → `numFiles` huge, files tiny.

**Fix:**
1. Scheduled `OPTIMIZE` to compact.
2. Turn on Optimized Writes / Auto Optimize at the source.
3. Consider liquid clustering.
4. Prevent: don't write tiny files (tune trigger interval / `maxFilesPerTrigger`).

**18. "Storage cost doubled but row count didn't. Why?"**

**Symptom:** Tombstoned files from frequent UPDATE/DELETE/MERGE/OPTIMIZE not yet vacuumed, plus time-travel history.

**Diagnose:**
1. `DESCRIBE DETAIL` size vs logical rows.
2. `DESCRIBE HISTORY` for write volume.

**Fix:**
1. `VACUUM` (≥7d retention) to remove tombstoned files.
2. Shorten `logRetentionDuration` / `deletedFileRetentionDuration` if appropriate.
3. Enable deletion vectors to reduce rewrite churn.

**19. "When does partitioning HURT instead of help?"**

**Symptom:** Partitioning backfires in three cases.

**Diagnose:**
1. High-cardinality columns → thousands of partitions → tiny files.
2. Small tables → overhead > benefit.
3. Queries don't filter on the partition column → you pay layout cost for no pruning.

**Fix:**
1. Partition only large tables on a low-card column that's actually filtered (date); else cluster.

**20. "Z-ORDER vs liquid clustering — defend your choice for a new hot table."**

**Symptom:** For a new hot table, choose liquid clustering over Z-ORDER.

**Diagnose:**
1. Z-ORDER is a full, non-incremental rewrite (write amplification, long jobs).
2. Liquid clustering is incremental, keys changeable without full rewrite, `CLUSTER BY AUTO` self-tunes, GA 15.2+.

**Fix:**
1. Use liquid clustering for new tables (Databricks recommends it over Z-ORDER).
2. Only stay on Z-ORDER for an older runtime or an existing well-tuned table not worth migrating.

**21. "DELETE/UPDATE/MERGE got faster after you enabled something. What?"**

**Symptom:** Selective DML sped up after enabling **deletion vectors**.

**Diagnose:**
1. Deletion vectors mark rows deleted/updated without rewriting the whole file (tiny DV file, merge on read).

**Fix:**
1. Enable `delta.enableDeletionVectors=true` for selective-DML-heavy tables.
2. Caveat: files "look old" but stay referenced — VACUUM won't reclaim them until a later OPTIMIZE materializes the change.

**22. "How do you pick partition vs cluster keys for a brand-new fact table?"**

**Symptom:** Pick keys by query predicates, then validate.

**Diagnose:**
1. Identify the low-card time column queries filter on, and the high-card join/filter keys.

**Fix:**
1. Partition by the **low-cardinality, time-based** column (date/month) — only if the table is big.
2. Cluster (liquid / Z-ORDER) on the **high-cardinality join/filter keys**.
3. ✗ Never partition the high-card key.
4. Validate with `EXPLAIN FORMATTED` (pruning + skipping) on the real hot queries.

### D. Joins, broadcast, shuffle (23-29)

**23. "A broadcast join worked for months, then started OOMing. What changed?"**

**Symptom:** The broadcast side grew past the threshold but Spark kept auto-broadcasting it (stale estimate) — e.g. a dim went 8k→80k+ rows.

**Diagnose:**
1. Check the dim's real (post-filter) size vs `autoBroadcastJoinThreshold` (10 MB default).

**Fix:**
1. Disable auto-broadcast (`autoBroadcastJoinThreshold=-1`) and use explicit hints only where validated, or switch that join to sort-merge.
2. Monitor dim sizes so growth is caught before it OOMs.

**24. "Two large tables join with a huge shuffle. Options to make it cheaper?"**

**Symptom:** Big↔big join generates a huge, expensive shuffle.

**Diagnose:**
1. No free lunch for big↔big — the goal is to minimize bytes shuffled.

**Fix:**
1. Pre-cluster/bucket both on the join key so the shuffle is cheaper/avoided.
2. Filter early (predicate pushdown) to shrink sides.
3. If one side becomes small after filtering, let AQE switch to broadcast.
4. Ensure enough shuffle partitions to avoid spill.
5. Co-locate via liquid clustering on the join key.

**25. "How does AQE decide to switch a sort-merge join to a broadcast mid-query?"**

**Symptom:** AQE re-plans a join at runtime using actual stage sizes, not static estimates.

**Diagnose:**
1. After a shuffle stage completes, AQE has the **actual** size of each side.

**Fix:**
1. If one side's real size is under `spark.sql.adaptive.autoBroadcastJoinThreshold`, AQE converts the remaining join to a broadcast hash join — saving the second shuffle.
2. This is why post-filter joins that *look* big-big often run as broadcasts.

**26. "Explain shuffle to me like I'm junior, then tell me how to minimize it."**

**Symptom:** Shuffle moves rows across the network so same-key rows land on one executor (join/groupBy/distinct) — the expensive part (network + disk + serialization).

**Diagnose:**
1. Identify the wide ops causing it.

**Fix:**
1. Broadcast small sides (no shuffle).
2. Filter before the shuffle.
3. Pre-cluster/bucket on the key.
4. Reduce the number of wide ops.
5. Right-size `shuffle.partitions` so you don't spill.

**27. "A MERGE is slow. Diagnose and fix."**

**Symptom:** A Delta MERGE runs slowly.

**Diagnose:**
1. Is the merge join key skewed (one natural key dominates → straggler)?
2. Is the source large and not broadcast?
3. Is the target unclustered on the merge key (full scan to find matches)?

**Fix:**
1. Broadcast a small source.
2. Cluster/Z-ORDER the target on the merge key so the match scan prunes.
3. `EXPLAIN FORMATTED` to confirm pruning + join type.
4. Salt the merge if the key is extreme.
5. `WHEN MATCHED AND hash differs` to skip no-op updates.

**28. "When is shuffle-hash join chosen over sort-merge, and do you ever force it?"**

**Symptom:** Shuffle-hash join (hash table after shuffle, no sort) can beat sort-merge for mid-size sides where sorting is the cost.

**Diagnose:**
1. Spark/AQE usually picks the join type; most tuning is broadcast-vs-SMJ, not SHJ.

**Fix:**
1. Let AQE pick; you rarely force SHJ.
2. Mention it to show depth, but SMJ + AQE is the default story.

**29. "Your join silently dropped rows. No error. What happened?"**

**Symptom:** Rows vanished from a join with no error.

**Diagnose:**
1. INNER JOIN on a nullable key (NULL keys never match → rows vanish).
2. Or a case/collation/whitespace mismatch on string keys.
3. Or a type mismatch coercing keys differently.
4. Check: row counts before/after; NULL keys; trim/case differences.

**Fix:**
1. LEFT JOIN + handle unmatched explicitly.
2. Normalize keys (trim/case); route NULLs to an unknown member.
3. Reconcile counts — never trust "it ran."

### E. Streaming (30-38)

**30. "A streaming job ran fine for 12 hours then OOMed. Walk through it."**

**Symptom:** Long-running stateful stream slowly exhausts heap — almost always unbounded state, not skew.

**Diagnose:**
1. **Structured Streaming tab** → state-store rows/memory climbing batch over batch.

**Fix:**
1. Add a `withWatermark` to evict old state.
2. Switch to the RocksDB state store (off-heap/disk).
3. Then size for the now-bounded state.
4. ✗ Bigger executors is the last lever.

**31. "How do you pick the watermark delay? Give me a number and justify it."**

**Symptom:** Choosing a defensible watermark from measured lateness, not a guess.

**Diagnose:**
1. Measure real lateness: `event_time` vs `processing_time` over a representative window → ~P99 + margin (e.g. P99 75 min → set 2 hours).

**Fix:**
1. Set the watermark to that value; justify by drop-rate (near-zero) vs state-size cost.
2. Too tight drops legit late data; too loose grows state unbounded.

**32. "Events arrive after the watermark and finance needs them. Now what?"**

**Symptom:** Late events past the watermark are dropped from streaming, but finance still needs them.

**Diagnose:**
1. The window already finalized + evicted state → those events are gone from the stream.

**Fix:**
1. ✗ Don't widen the watermark (unbounded state).
2. Route late/dropped events to a side table.
3. Run a batch correction job (idempotent MERGE) to restate; bitemporal modeling makes it auditable.

**33. "Your stream is falling behind — lag grows every batch. Diagnose + fix."**

**Symptom:** Processing rate < ingestion rate, so lag grows every batch.

**Diagnose:**
1. **Structured Streaming tab**: batch duration > trigger interval, input rate > processing rate.

**Fix:**
1. Batches too big → backpressure (`maxOffsetsPerTrigger`/`maxFilesPerTrigger`).
2. State explosion → watermark + RocksDB.
3. Skew → AQE/salt.
4. Under-parallelized → more shuffle partitions/workers.

**34. "Exactly-once in streaming — what are the three things that must all be true?"**

**Symptom:** Exactly-once requires all three; miss one → dupes or loss.

**Diagnose:**
1. Atomic commit alone isn't enough — you could re-append on retry without the checkpoint.

**Fix:**
1. **Replayable source** (Kafka offsets / Auto Loader file paths) — re-read from last committed point.
2. **Checkpoint** — records committed offsets + state.
3. **Idempotent/transactional sink** (Delta atomic write, or `foreachBatch` + MERGE on natural key).

**35. "You can't MERGE a stream directly. How do you upsert from a stream?"**

**Symptom:** Streaming sinks can't run MERGE directly — need per-micro-batch upsert.

**Diagnose:**
1. `foreachBatch` is at-least-once by default (a batch can re-run).

**Fix:**
1. Use `foreachBatch` — it hands each micro-batch to you as a batch DataFrame.
2. Run a Delta `MERGE` inside it (or any batch op: multi-sink, external call).
3. Make the MERGE idempotent on the natural key (or dedupe by `batchId`) so replays converge.

**36. "Stream-static vs stream-stream join — when, and the gotcha?"**

**Symptom:** Choosing the join type, and the state gotcha for each.

**Diagnose:**
1. Stream-static (stream ⨝ static Delta dim): no join state, dim re-read per batch, picks up updates next batch.
2. Stream-stream (two streams): state on both sides.

**Fix:**
1. Use stream-static as the enrichment workhorse (~90% of joins).
2. For stream-stream, require watermarks on both sides + a time-bound join condition, or state grows forever — only when two event streams must correlate within a window.

**37. "You need 15-min freshness but 24/7 streaming compute is wasteful. Solution?"**

**Symptom:** Want 15-min freshness without paying for always-on streaming compute.

**Diagnose:**
1. Always-on streaming idles between bursts → wasted compute.

**Fix:**
1. `trigger(availableNow=True)` on a 15-min schedule (Databricks Workflow).
2. Each run drains all new data exactly-once via the checkpoint, then the cluster terminates.
3. Streaming semantics at near-batch cost — the middle ground between always-on and nightly batch.

**38. "How do you deploy a code change to a running stream without losing data?"**

**Symptom:** Deploying a code change to a running stream depends on checkpoint compatibility.

**Diagnose:**
1. Is the change checkpoint-compatible? (transform logic / non-stateful = yes; altering stateful keys/logic/output mode = no).

**Fix:**
1. Compatible → stop gracefully, deploy, restart from the **same checkpoint**.
2. Incompatible → new checkpoint + reprocessing (replay from source or batch-backfill the gap).
3. Treat "is this checkpoint-compatible?" as a deploy checklist item.

### F. Ingestion / schema (39-43)

**39. "A producer added a column overnight and the pipeline broke. Diagnose + harden."**

**Symptom:** Pipeline broke because the incoming schema no longer matched the registered contract (schema drift).

**Diagnose:**
1. Schema mismatch vs the registered contract; check `_rescued_data` if rescue mode was on.

**Fix:**
1. **CI schema-diff** to catch drift before prod.
2. Auto Loader `schemaEvolutionMode=rescue` (unknown fields → `_rescued_data`, nothing lost) or `addNewColumns` (stop-add-resume).
3. For Kafka, a schema registry with compatibility rules.
4. Alert on non-empty `_rescued_data` — make drift a contained event, not an outage.

**40. "50 files vs 1 file — does Auto Loader start the cluster more times?"**

**Symptom:** Misconception that file count drives cluster starts — it doesn't.

**Diagnose:**
1. The job/DAG starts the cluster once; file count = task parallelism, not cluster count.

**Fix:**
1. Auto Loader picks up all new files in one run and parallelizes across the cluster.
2. 50 tiny files create a downstream small-files concern → OPTIMIZE.
3. For very high file counts, use notification mode (SNS/SQS) instead of directory listing.

**41. "A file failed to ingest at 50% (cluster died). Partial rows? Dupes on rerun?"**

**Symptom:** Cluster died mid-file — question is partial rows or dupes.

**Diagnose:**
1. The unit of work is the file/batch; the Delta write per batch is atomic; the checkpoint tracks what committed.

**Fix:**
1. No partial: a half-written batch never commits.
2. No dupes: the rerun reprocesses only the uncommitted unit.
3. ✗ A naive `append` in a Python loop is what breaks this.

**42. "Auto Loader checkpoint vs your business manifest — what's the difference?"**

**Symptom:** Two independent skip mechanisms that get confused.

**Diagnose:**
1. Checkpoint (RocksDB of processed paths + offsets) = the **engine's** exactly-once mechanism; it never reads your manifest.
2. Manifest (a Delta table the validation step writes) = the **operational/audit** record (arrival, validity, SLA).

**Fix:**
1. Keep them decoupled — engine exactly-once vs business audit are separate concerns.

**43. "When do you use COPY INTO instead of Auto Loader?"**

**Symptom:** Choosing the right ingestion command.

**Diagnose:**
1. Both are exactly-once; the axis is continuous-vs-bounded.

**Fix:**
1. COPY INTO for **bounded/periodic, idempotent batch loads** (scheduled SQL, skips already-loaded files) — simpler, no streaming infra.
2. Auto Loader for **continuous/incremental** ingestion with a checkpoint, high file volumes, notification mode.

### G. Correctness, cost, concurrency, sizing (44-50)

**44. "Two jobs write the same Delta table concurrently and one fails with a conflict. Why + fix?"**

**Symptom:** Concurrent Delta writers collide; one fails with `ConcurrentModificationException`.

**Diagnose:**
1. Delta uses optimistic concurrency — at commit each writer checks if its read files were changed by a concurrent commit; conflict → retry or fail.

**Fix:**
1. Have writers touch **disjoint partitions/files** (partition by date so different jobs hit different days).
2. Or serialize conflicting writers, or retry with backoff.
3. ✗ Don't have two jobs blind-overwrite the same partition.

**45. "Finance says a number is wrong in prod. Walk your diagnosis."**

**Symptom:** A prod number is reported wrong; isolate "us vs real change" with evidence.

**Diagnose:**
1. **Input complete?** Ingest manifest — did all sources arrive (or one late/partial)?
2. **Reconciliation audit** for that table/date — was it green at load?
3. If newly diverged → source change or a job double-writing?
4. Row-checksum to isolate the exact rows; find the semantic cause (rounding, NULL, cast).

**Fix:**
1. Fix forward (idempotent re-run).
2. Notify with the cause.
3. Add the missed check to the reconciliation suite.

**46. "How do you size a cluster for a new heavy job without guessing?"**

**Symptom:** Size a heavy job's cluster empirically, not by guessing.

**Diagnose:**
1. Run on ~10% of data on 2 workers; read Spark UI for total shuffle bytes; check spill.

**Fix:**
1. `shuffle_partitions = bytes/128MB`.
2. `workers ≈ cores_needed/cores_per_worker` + ~50% headroom.
3. Scale linearly to full and re-verify; autoscale for variable load.
4. Levers in order: layout → shuffle partitions → AQE → memoryOverhead → bigger instance.

**47. "Your DBU bill spiked. How do you find and fix it?"**

**Symptom:** DBU bill spiked; attribute and fix.

**Diagnose:**
1. `system.billing.usage` (+ mandatory cost tags) to attribute spend by job/team.
2. Common causes: all-purpose clusters left running, no autoscale-to-zero, oversized clusters, Photon off on SQL-heavy jobs, runaway retries.

**Fix:**
1. Job clusters + auto-terminate + autoscale-to-zero off-peak.
2. Enable Photon on SQL-heavy jobs.
3. Cluster policies (max size, mandatory terminate, instance allowlist) + a chargeback dashboard.

**48. "EMR-on-spot was cheaper per-hour. Justify Databricks cost."**

**Symptom:** Defend Databricks cost vs cheaper-per-hour EMR-on-spot.

**Diagnose:**
1. Per-hour ≠ TCO: add idle-cluster waste, eng-hours babysitting/right-sizing, spot-interruption reruns, version-upgrade toil.

**Fix:**
1. Databricks autoscale-to-zero + job clusters + Photon (more per DBU) + spot worker fleets close most of the gap.
2. Be honest: for a pure, steady, well-tuned spot Spark batch, EMR can be marginally cheaper per-unit — the win is unification + ops toil + governance, and say that explicitly.

**49. "How do you verify a query does what you think BEFORE running it on 10 TB?"**

**Symptom:** Validate a query's plan before spending on a 10 TB run.

**Diagnose:**
1. `EXPLAIN FORMATTED` — confirm partition pruning (`PartitionFilters`), join strategy (BroadcastHashJoin vs SortMergeJoin), pushed filters (`PushedFilters`), no accidental cartesian.

**Fix:**
1. Fix the plan if any of those are wrong.
2. Run on a sampled/filtered subset first — cheaper than discovering a missing broadcast or full scan after an hour.

**50. "Walk me through your general methodology for ANY slow/failing Spark job."**

**Symptom:** General methodology — diagnose before tuning, fix the class not the instance.

**Diagnose:**
1. **Classify**: failing (OOM/error) vs slow.
2. **Driver vs executor** — Spark UI **Executors tab** vs driver log.
3. **Stages tab → slowest stage → "Summary Metrics"**: Max vs Median (skew vs uniform).
4. **Plan**: `EXPLAIN FORMATTED` or the **SQL/DataFrame tab** (pruning, join type, broadcast).
5. **History/baseline**: `DESCRIBE HISTORY` + `system.workflow.job_runs` (what changed?).
6. **Input shape** (volume/skew/new feed).

**Fix:**
1. Fix the *specific* cause, in lever order (layout → partitions → AQE → memory → instance).
2. **Harden** (alert/policy/test) so the class can't silently recur.
3. The senior signal: *diagnose before you tune, fix the class not the instance.* *(§15 = where each signal lives in the UI.)*

---

## 15. Reading the Spark UI — where every signal lives

> The diagnostic answers above keep saying "Spark UI → Stages → Summary Metrics." This section is the actual map: how to open it, what the tabs are, and the exact click-path to each signal. Memorize the bold path for skew — it's the single most-asked "how would you find that."

### How to open it
- **Databricks:** cluster page → **Spark UI** tab; or in a notebook, click **"View"/"Spark Jobs"** under a running cell. Each job run also has a Spark UI link.
- **Open-source / EMR:** `http://<driver-node>:4040` (4041, 4042… if multiple apps).

### The tabs (top nav bar — ~8)
| Tab | What's in it | Use it for |
|---|---|---|
| **Jobs** | Every Spark *job* (one per action: `.write`, `.count`, `.collect`), duration + status | **Entry point** — find the slow/failed job |
| **Stages** | Every *stage* (a job splits into stages at each shuffle boundary) + per-task metrics | **★ SKEW** — the Summary Metrics table lives here |
| **Storage** | Cached/persisted DataFrames + their memory/disk footprint | Did `cache()` materialize? cache pressure |
| **Environment** | All effective Spark configs (`shuffle.partitions`, AQE, broadcast threshold…) | **Confirm a config you set is actually applied** |
| **Executors** | Per-executor: memory, **disk Spill**, **GC Time**, failed tasks, cores, logs | **★ OOM / spill / GC**; driver-vs-executor |
| **SQL / DataFrame** | Per-query: the **plan diagram** + per-operator rows/bytes/time/files | **★ Join type, partition pruning, files read** |
| **Structured Streaming** | (streaming) input vs processing rate, batch duration, **state rows** | **★ Streaming lag + state-growth OOM** |
| **JDBC/ODBC** | (SQL warehouse) external client connections | Rare |

The three you live in: **Stages** (skew), **Executors** (OOM/spill/GC), **SQL/DataFrame** (plan/joins/pruning).

### ★ The exact path to find SKEW (memorize this)
1. **Jobs** tab → click the slow/failed **job**.
2. Its list of **stages** appears → click the slowest (longest duration) or failed **stage**.
3. On the stage page, scroll to the section titled **"Summary Metrics for N Completed Tasks."**
4. It's a percentile table — rows **Min · 25th · Median · 75th · Max** × columns **Duration · Shuffle Read Size · Spill · …**
5. **Read it:** **Max ≫ Median** (e.g. median 2 min, max 45 min) = **skew** (one fat task). All percentiles similar but slow = not skew, it's under-provisioning / bad plan.
6. Below that table, the **per-task list** shows the exact straggler task + which executor ran it.

### Where each OTHER signal lives
| Signal you're hunting | Tab → path | What you're reading |
|---|---|---|
| **Skew** (one slow task) | **Stages** → stage → Summary Metrics | Max ≫ Median on Duration/Shuffle-Read |
| **Spill to disk** | **Stages** → stage → Summary Metrics (Spill cols) **+ Executors** tab | Non-zero "Spill (Memory/Disk)" = under-partitioned/under-memory |
| **GC pressure** | **Executors** tab → "GC Time" column | >10% of task time = memory pressure; >85% heap sustained = OOM coming |
| **Driver vs executor OOM** | **Executors** tab (executor failed tasks) vs the **driver log** | Executor failures = skew/partition; driver = collect/broadcast/planning |
| **Join type** (broadcast vs sort-merge) | **SQL/DataFrame** tab → click query → plan diagram | `BroadcastHashJoin` vs `SortMergeJoin` node |
| **Partition pruning** | **SQL/DataFrame** tab → scan node (or `EXPLAIN FORMATTED`) | "files read" / `PartitionFilters` — small = pruning works |
| **Shuffle size** | **Stages** → stage → "Shuffle Read/Write" | How many bytes crossed the network |
| **A config's real value** | **Environment** tab | Confirms `shuffle.partitions`, AQE, threshold actually applied |
| **Cache materialized?** | **Storage** tab | Cached DF size in memory/disk (empty = `cache()` never triggered) |
| **Streaming lag** | **Structured Streaming** tab → query | Input Rate vs Processing Rate; batch duration vs trigger interval |
| **Streaming state growth** | **Structured Streaming** tab → query | "Aggregated Number Of Total State Rows" climbing = OOM risk |

### The mental model (say this)
**Job** (one action) → splits into **Stages** at every shuffle → each stage runs many **Tasks** (one per partition). So: **skew = task-level imbalance → Stages tab**; **OOM/spill/GC = executor-level → Executors tab**; **join/pruning = query-level → SQL/DataFrame tab**; **streaming lag/state = Structured Streaming tab**. Match the *level of the problem* to the *tab*.

---

## 16. Decision flowcharts (glance → answer)

> The multi-step "fix ladders" as diagrams. Find the symptom, follow the arrows top-to-bottom (each step only if the one above didn't solve it), stop when fixed. Cheaper on the eyes than numbered prose.

### Skew — one task ≫ the rest (the fix ladder)
```
SYMPTOM: Stages tab → stage → Summary Metrics → Max ≫ Median
                         │
            ┌────────────┴────────────┐
            │ Is the hot value junk    │── yes ──▶ (1) FILTER it out (cheapest)
            │ you can drop? (NULLs,    │
            │ a sentinel, bad data)    │
            └────────────┬────────────┘
                         │ no / still skewed
                         ▼
            (2) AQE SKEW JOIN  (one config, no code change)
                spark.sql.adaptive.skewJoin.enabled=true
                lower skewedPartitionFactor 5 → 3
                         │ still skewed
                         ▼
            ┌────────────┴────────────┐
            │ Is the OTHER side small? │── yes ──▶ (3) BROADCAST it (kills the shuffle)
            └────────────┬────────────┘
                         │ no (both big)
                         ▼
            (4) SALT the hot key  ── LAST RESORT (code change)
                add (rand()*N) suffix; replicate other side ×N
                         │
                         ▼
            ✗ NEVER just add executor memory — it can't fix one fat partition
```

### Executor OutOfMemoryError (diagnose → fix)
```
OOM error
   │
   ▼
Driver or executor?  ── Executors tab (failed tasks / high mem)  vs  driver log
   │                                      │
 EXECUTOR                               DRIVER
   │                                      │
   ▼                                      ▼
Stages tab → Summary Metrics       Caused by: .collect()/.toPandas(),
   │                                huge broadcast, planning over millions of files
 Max ≫ Median?                         │
   ├── YES → SKEW → run the skew ladder ▲     ▼ Fix: don't collect big to driver;
   │                                      cap maxResultSize; disable bad broadcast;
   └── NO (all slow) →                    OPTIMIZE to cut file count; bigger driver
        3 common executor causes:
        (1) too few shuffle partitions → raise to bytes/128MB
        (2) blown broadcast (side bigger than estimated) → autoBroadcastJoinThreshold=-1
        (3) huge wide aggregation → more partitions / windowed agg
   │
   ▼
Lever ORDER (cheapest first):
 layout/skew → shuffle partitions → AQE → memoryOverhead 10%→25% → bigger instance
 (memory is LAST, not first)
```

### Slow job / regression triage (was fast, now slow)
```
(1) BASELINE   system.workflow.job_runs → when did it regress? input volume up?
       │
(2) FIND STAGE Spark UI → Jobs tab → slowest job → Stages tab → slowest stage
       │
(3) SKEW?      that stage → Summary Metrics → Max vs Median
       ├── Max ≫ Median → skew → skew ladder
       └── all slow → capacity/plan → more partitions / AQE / scale / fix join
       │
(4) CHANGED?   DESCRIBE HISTORY → recent bad OPTIMIZE ZORDER / vacuum / overwrite?
       │
(5) INPUT      new feed? a source 10×'d its file? broadcast side grew?
       │
       ▼
Fix the SPECIFIC cause → then add a runtime-regression ALERT (harden the class)
```

### Join strategy — which join + broadcast decision
```
Joining two tables
   │
   ▼
Is one side SMALL?  (real / post-filter size < ~100 MB; auto threshold 10 MB)
   ├── YES → BROADCAST JOIN  (ship small side to every executor, no shuffle)
   │            │
   │            ▼  ⚠ but if "small" is actually big →
   │            driver OOM (collecting it) + executor OOM (every node holds a copy)
   │            → check real size; autoBroadcastJoinThreshold=-1 to force sort-merge
   │
   └── NO (both big) → SORT-MERGE JOIN (default: shuffle both, sort, merge)
                │
                ▼  to make it cheaper:
                filter early · cluster/bucket both on join key · enough shuffle partitions
                (AQE may auto-switch to broadcast if a side is small after filtering)
```

### Small files / storage bloat
```
Symptom: reads slow over time / planning slow / storage cost up
   │
   ▼
DESCRIBE DETAIL t → look at numFiles vs sizeInBytes
   │
   ├── numFiles huge, files tiny  → SMALL-FILES problem
   │        → OPTIMIZE (compact to ~1GB)  +  turn on Auto Optimize (prevent at write)
   │        → for new tables: liquid clustering (incremental, self-maintaining)
   │
   └── size ≫ logical data, many old versions → STORAGE BLOAT (tombstones/history)
            → VACUUM RETAIN 168 HOURS (≥7d)   [lightest op: just deletes dead files]
            → enable deletion vectors to cut future rewrite churn
            ✗ never VACUUM RETAIN 0 HOURS (breaks time travel + live readers)
```

### Partition vs cluster vs nothing (layout decision for a new table)
```
For each column you query on:
   │
   ▼
Low-cardinality + time-based + table is big?  (e.g. sales_date)
   ├── YES → PARTITION by it (enables partition pruning)
   │
High-cardinality + filtered/joined a lot?  (e.g. retailer_id, product_id)
   ├── YES → CLUSTER on it (Z-ORDER, or liquid clustering for new tables)
   │
Small dimension table?
   ├── YES → do NOTHING → let Spark BROADCAST it at join time
   │
✗ NEVER partition a high-cardinality column → millions of tiny files
```

### Streaming OOM (ran fine for hours, then died)
```
Streaming job OOMs after running a while
   │
   ▼
Structured Streaming tab → "Total State Rows" climbing every batch?
   ├── YES → UNBOUNDED STATE (not skew)
   │         (1) add withWatermark("ts","2h")  → evicts old windows/state
   │         (2) switch state store to ROCKSDB → off-heap/disk, scales huge
   │
   └── NO, but lag growing (input rate > processing rate)?
             → backpressure: maxOffsetsPerTrigger / maxFilesPerTrigger
             → + more shuffle partitions / fix skew
   │
   ▼
✗ bigger executors is the LAST lever, not the first
```

### Exactly-once — what must all be true
```
Goal: each record affects output exactly once, across failures
   │
   ├── (1) REPLAYABLE SOURCE   Kafka offsets / Auto Loader file paths
   │            └─ on restart, re-read from last committed point
   │
   ├── (2) CHECKPOINT          records committed offsets + state
   │            └─ resume from uncommitted, not from zero
   │
   └── (3) IDEMPOTENT SINK     Delta atomic commit + MERGE on natural key
                └─ a replay UPDATES, never double-inserts

   Need ALL THREE.  Miss one →
     no source replay   = data loss
     no checkpoint      = reprocess everything / dupes
     no idempotent sink = dupes on retry
   (Atomic commit alone is NOT exactly-once.)
```

## Sources (verified 2026-05)
- [Liquid clustering (Databricks docs)](https://docs.databricks.com/aws/en/delta/clustering) · [Liquid clustering GA announcement](https://www.databricks.com/blog/announcing-general-availability-liquid-clustering)
- [VACUUM (Databricks docs)](https://docs.databricks.com/aws/en/sql/language-manual/delta-vacuum) · [Deletion vectors](https://docs.databricks.com/aws/en/delta/deletion-vectors)
- [AQE (Databricks docs)](https://docs.databricks.com/aws/en/optimizations/aqe) · [Spark performance tuning](https://spark.apache.org/docs/latest/sql-performance-tuning.html)
- [Spark Web UI (Apache docs)](https://spark.apache.org/docs/latest/web-ui.html)

---

*Last updated: 2026-05-29*
