# Senior Data Engineer — Glossary / Abbreviation Cheat Sheet
## Every acronym across all the prep docs, defined plainly + "what it maps to"

> Universal reference (not interviewer-specific). If you hit a term in any `INTERVIEW_QA*.md` and blank on it, it's here. Grouped by area. **Bold = the one you'll be asked to define out loud.**
>
> **Cross-ref:** for "why Databricks vs a relational DB / Redshift / Snowflake," see `INTERVIEW_QA.md` §12 (Platform positioning).

---

## 0. The ones people blank on most (quick hits)

| Term | Plain meaning |
|---|---|
| **ETL / ELT** | Extract-Transform-Load (transform before load) vs Extract-Load-Transform (load raw, transform in-warehouse). Lakehouse = ELT (raw to bronze, transform in Spark/dbt). |
| **EDW** | Enterprise Data Warehouse — the big central analytics DB (Teradata/Redshift/etc.). |
| **OLTP** | Online Transaction Processing — the operational app DB (orders, inventory). Source of CDC. |
| **OLAP** | Online Analytical Processing — analytics/reporting workloads (the warehouse side). |
| **MPP** | Massively Parallel Processing — splits data + query across many nodes (Teradata, Redshift, Spark). |
| **DAG** | Directed Acyclic Graph — a job dependency graph (task B runs after task A; no cycles). |
| **SLA** | Service Level Agreement — the promised deadline/freshness (e.g. "gold ready by 6 AM"). |
| **P90 / P99** | 90th / 99th percentile latency — "90% of queries finish under X." Better than averages for tails. |
| **TCO** | Total Cost of Ownership — full cost incl. ops/labor/idle, not just sticker price. |
| **CDC** | Change Data Capture — streaming row-level inserts/updates/deletes out of an OLTP DB (e.g. via Debezium). |
| **IaC** | Infrastructure as Code — define cloud resources in code (Terraform), not console clicks. |
| **CI/CD** | Continuous Integration / Continuous Deployment — automated test + deploy pipeline (GitHub Actions). |

---

## 1. Spark / Databricks core

| Term | Meaning | Maps to / note |
|---|---|---|
| **Spark** | Distributed compute engine; splits work into tasks across executors. | The engine under Databricks/EMR/Glue. |
| **Driver** | The coordinator node — plans the job, schedules tasks, collects results. | OOMs on `.collect()`/huge broadcast. |
| **Executor / worker** | Nodes that actually run tasks on data partitions. | OOMs on skew/wide aggregation. |
| **Partition** (compute) | A chunk of the data processed by one task. | ≠ table partition (storage). |
| **Shuffle** | Redistributing data across the cluster by key (for join/groupBy/distinct) — moves data over the network. | The expensive thing you minimize. |
| **Skew** | Uneven key distribution → one task gets most of the data → straggler. | Fix: AQE skew-join, salting, unknown-member. |
| **Spill** | Spark writes intermediate data to disk because it won't fit in memory. | Symptom of too-few shuffle partitions / skew. |
| **OOM** | Out Of Memory — JVM heap exhausted, task/driver dies. | Driver (collect) vs executor (skew) — diagnose which. |
| **GC** | Garbage Collection — JVM reclaiming memory; >10% of task time = pressure. | High GC → OOM incoming. |
| **AQE** | **Adaptive Query Execution** — Spark re-optimizes at runtime using real shuffle stats. | 3 moves: coalesce partitions, switch to broadcast, split skew. |
| **Broadcast (join)** | Send the small table to every executor so the big table isn't shuffled. | Backfires if "small" is actually big (OOM). |
| **Sort-merge join** | Default big-big join: shuffle both sides by key, sort, merge. | AQE can switch it to broadcast if one side is small. |
| **Coalesce** | Reduce partition count WITHOUT a shuffle (cheap, can be uneven). | Use to write fewer files. |
| **Repartition** | Change partition count WITH a full shuffle (even, costly). | Use to grow parallelism / fix skew. |
| **Salting** | Append a random suffix to a hot key so it spreads across tasks. | Last-resort skew fix (code change). |
| **shuffle partitions** | `spark.sql.shuffle.partitions` — how many partitions a shuffle produces. | Rule: `total_shuffle_bytes / 128MB`. Default 200 = too low. |
| **Photon** | Databricks' C++ vectorized query engine — more work per DBU. | Off for Python-UDF-heavy jobs. |
| **DBU** | **Databricks Unit** — the billing unit for Databricks compute (per-second). | Watch via `system.billing.usage`. |
| **RDD** | Resilient Distributed Dataset — Spark's low-level data abstraction (pre-DataFrame). | You rarely touch it now. |
| **CBO** | Cost-Based Optimizer — picks query plans from table stats (`ANALYZE`). | AQE is the runtime complement. |
| **UDF** | User-Defined Function — custom code in a query; slower (esp. Python, breaks vectorization). | Prefer built-ins. |
| **predicate pushdown** | Push `WHERE` filters down to the scan so less data is read. | Verify with `EXPLAIN FORMATTED`. |

---

## 2. Delta Lake / storage / file layout

| Term | Meaning | Note |
|---|---|---|
| **Delta / Delta Lake** | The table format: Parquet files + a transaction log (`_delta_log`) giving ACID. | The "lake" that acts like a warehouse. |
| **ACID** | Atomicity, Consistency, Isolation, Durability — transactional guarantees. | Why a mid-write crash leaves no partial data. |
| **`_delta_log`** | The transaction log — ordered record of every commit (which files added/removed). | Atomic commit = appending to this. |
| **Time travel** | Query a table as-of an old version/timestamp (`VERSION AS OF`). | Delta keeps old file versions. |
| **OPTIMIZE** | Compacts many small files into ~1 GB files (bin-packing). | Fixes small-files problem. |
| **Z-ORDER** | Multi-dimensional clustering — co-locates rows with similar values in chosen columns into the same files. | Better data skipping; pick high-card filtered cols. |
| **data skipping** | Delta skips files whose min/max stats can't match the filter. | Z-ORDER/clustering makes it effective. |
| **Liquid Clustering** | Modern auto-managed replacement for partitioning + Z-ORDER (`CLUSTER BY`). | No manual key tuning. |
| **partition** (storage) | Physically split a table into directories by a low-card column (date). | Enables partition pruning. |
| **partition pruning** | Query reads only the partition dirs matching the `WHERE`. | Breaks if you wrap the col in a function. |
| **VACUUM** (Delta) | Deletes old unreferenced files past the retention window. | ONLY reclaims space — does NOT re-sort (unlike Redshift VACUUM). |
| **CDF** | **Change Data Feed** — Delta emits row-level changes (insert/update/delete) for downstream consumption. | Delta's own CDC. |
| **MERGE** | `MERGE INTO ... WHEN MATCHED UPDATE WHEN NOT MATCHED INSERT` — upsert. | The idempotent-load + SCD2 workhorse. |
| **small-files problem** | Too many tiny files → per-file overhead, task explosion, `_delta_log` bloat, slow reads. | Fix: OPTIMIZE / Auto Optimize / liquid clustering. |
| **medallion** | The bronze → silver → gold layering pattern. | Raw → cleaned/canonical → business marts. |

---

## 3. Auto Loader / Structured Streaming

| Term | Meaning | Note |
|---|---|---|
| **Auto Loader / `cloudFiles`** | Databricks incremental file ingestion — processes only new files, tracked by checkpoint. | Directory-listing or notification mode. |
| **notification mode** | Auto Loader provisions SNS+SQS so S3 pushes new-file events (no listing). | For high file volume. |
| **checkpoint** | Durable record of stream progress (offsets + state + processed files). | Enables exactly-once resume. One per stream. |
| **micro-batch** | The chunk of new data processed per trigger; atomic + sequential. | Size-controlled by maxBytes/maxFilesPerTrigger. |
| **watermark** | `max(event_time) − allowedLateness` — threshold to finalize windows + drop old state. | Too tight = drop late; too loose = OOM. |
| **state store** | Where stateful streaming keeps state (aggregations/joins/dedup). | Default on-heap; **RocksDB** for large state. |
| **RocksDB** | Off-heap, on-disk state store — handles huge state without OOM. | The fix for state-driven streaming OOM. |
| **trigger** | When the next micro-batch fires: default(ASAP), `processingTime`, **`availableNow`**, continuous. | `availableNow` = drain all + stop (incremental batch). |
| **`foreachBatch`** | Hands each micro-batch to you as a batch DataFrame → run any batch op (MERGE, multi-sink). | How you upsert from a stream. |
| **output mode** | append (new/windowed), update (changed keys), complete (whole small agg). | — |
| **stream-static join** | Stream ⨝ a static Delta table (dim); re-read per batch; NO state. | The enrichment workhorse. |
| **stream-stream join** | Two streams joined; needs watermarks + time-bound on both sides. | State-heavy. |
| **maxOffsetsPerTrigger / maxFilesPerTrigger / maxBytesPerTrigger** | Backpressure caps — limit how much one micro-batch ingests. | Stops a burst creating a giant batch. |
| **exactly-once** | Each record affects output once despite failures. | = replayable source + checkpoint + idempotent sink. |
| **idempotent** | Running it twice = same result as once. | MERGE on natural key gives this. |
| **DLT / Lakeflow Declarative Pipelines** | Databricks' declarative ETL framework — declare tables + expectations, it manages orchestration/checkpoints/retries. | vs hand-rolled Structured Streaming. |
| **Lambda architecture** | Separate batch layer + speed layer (two codebases). | The maintenance trap — avoid. |
| **Kappa architecture** | One streaming path for everything (one logic). | Shared transform code + 2 runners ≈ this. |

---

## 4. Teradata (the EDW source)

| Term | Meaning | Maps to in Databricks |
|---|---|---|
| **BTEQ** | Basic Teradata Query — Teradata's SQL script/CLI tool (the load + transform scripts). | dbt models + Spark notebooks. |
| **PI (Primary Index)** | Teradata's row-distribution key — hashes rows across AMPs; same-PI joins are local. | Z-ORDER / liquid clustering (co-location). |
| **PPI** | Partitioned Primary Index — adds range partitioning (often by date) on top of the PI. | Delta partitioning (date). |
| **AMP** | Access Module Processor — a Teradata worker unit; data is hashed across AMPs. | Spark executor (loosely). |
| **TASM** | **Teradata Active System Management** — workload mgmt: priorities, throttles, query queues on the fixed appliance. | Cluster policies + separate SQL warehouses + serverless. |
| **SET table** | Table that silently rejects duplicate rows (auto-dedup). | No equivalent → explicit MERGE dedup on natural key. |
| **MULTISET table** | Table that allows duplicate rows. | Default Delta behavior. |
| **FastLoad / MultiLoad / TPump** | Teradata bulk-load utilities (empty-table load / update load / streaming load). | Auto Loader / COPY INTO / MERGE. |
| **TPT** | **Teradata Parallel Transporter** — the parallel bulk export/import tool. | The history-export path (→ Parquet/S3). |
| **DBC** | The Teradata system database — `DBC.Tables`, `DBC.Columns`, `DBC.AllRights` (the data dictionary). | `information_schema` / Unity Catalog metadata. |
| **DBQL** | **DataBase Query Log** — Teradata's query history (who ran what, how often, how slow). | The usage-mining source for the decommission/tier decision. |
| **QUALIFY** | Teradata clause to filter on a window function result. | Spark SQL supports `QUALIFY` directly now. |
| **MERGE / UPSERT** | Insert-or-update. | Delta `MERGE`. |
| **collation** | String comparison rules; Teradata default LATIN = case-INsensitive. | Spark is case-SENSITIVE → normalize case on load. |

---

## 5. Redshift (the AWS warehouse source) — incl. WLM in detail

| Term | Meaning | Maps to in Databricks |
|---|---|---|
| **Redshift** | AWS's MPP columnar data warehouse (provisioned nodes, or serverless). | Databricks SQL warehouses + Delta on S3. |
| **DISTKEY** | Distribution key — which column decides how rows spread across nodes; same-DISTKEY joins are local (co-located). | Z-ORDER / liquid clustering on the join key. |
| **SORTKEY** | The on-disk sort order of a table — enables range restriction (skip blocks). | Partition (date) + Z-ORDER for compound. |
| **DISTSTYLE** | How rows distribute: `KEY` (by DISTKEY), `ALL` (full copy on every node — for small dims), `EVEN` (round-robin), `AUTO`. | `ALL` → small Delta table that auto-broadcasts. |
| **VACUUM** (Redshift) | Reclaims space from deleted rows AND **re-sorts** the table to the SORTKEY. | Re-sort → `OPTIMIZE ZORDER`; reclaim → Delta `VACUUM`. **Two different VACUUMs — don't conflate.** |
| **ANALYZE** | Refreshes table statistics for the query planner. | Delta auto-collects stats on write. |
| **UNLOAD** | Bulk export of a query result to S3 (`UNLOAD ... TO 's3://' FORMAT PARQUET`). | The history-export path (Redshift's TPT). |
| **COPY** | Bulk load from S3 into Redshift. | Auto Loader / `COPY INTO`. |
| **SUPER** | Redshift's semi-structured (JSON-ish) column type. | Spark `STRUCT`/`MAP`/`VARIANT`. |
| **PARTIQL** | The SQL dialect extension to navigate `SUPER`/nested data. | Spark JSON functions. |
| **Spectrum** | Redshift querying external tables in S3 (without loading them). | Unity Catalog external tables. |
| **Concurrency Scaling** | Redshift temporarily adds clusters to handle query bursts. | SQL warehouse multi-cluster load balancing. |

### Redshift WLM — the full picture (you asked for detail)

**WLM = Workload Management.** It's how Redshift decides *which query runs when* on a **fixed-size** cluster — because the cluster has limited memory + query slots, WLM is the rationing system. Two modes:

- **Manual WLM:** you define **query queues**, each with: a **memory %** of the cluster, a **concurrency level** (number of **slots** = how many queries run at once in that queue), and rules for which queries land in which queue (by user group / query group). Example: a "BI" queue with 40% memory + 5 slots, an "ETL" queue with 60% + 3 slots. A query waits in its queue until a slot frees.
- **Automatic WLM (default now):** Redshift manages memory + concurrency dynamically per query based on its predicted resource need, instead of fixed slot counts. You just set relative **priorities** (highest/high/normal/low).

Supporting pieces:
- **Slots:** a queue's concurrency unit. 5 slots = 5 concurrent queries; the 6th queues. A query can be given multiple slots (more memory) via `wlm_query_slot_count`.
- **QMR (Query Monitoring Rules):** "if a query runs > N seconds or scans > X rows, abort it / log it / hop it to another queue" — guardrails against runaway queries.
- **SQA (Short Query Acceleration):** a fast lane so quick queries don't get stuck behind big ones.
- **Concurrency Scaling:** when queues back up, Redshift spins up *transient* clusters to drain the queue (extra cost).

**Why it's the pain that drives migration:** on a fixed appliance, at month-end everyone queries at once → queues fill → slots are exhausted → analysts' ad-hoc queries **wait** (the throttling). You're rationing a fixed resource.

**What it maps to in Databricks (the conceptual shift):** there is no single fixed box to ration. Instead you **isolate + autoscale**: give each workload its **own SQL warehouse / cluster** (BI ≠ ETL ≠ data science → no contention), let each **autoscale** out under load (multi-cluster load balancing — the Concurrency-Scaling analog) and to zero when idle, governed by **cluster policies** (max size, instance types). **Serverless SQL** removes the month-end queue entirely because it scales on demand. So: *TASM/WLM = ration a fixed box; Databricks = isolate workloads + autoscale elastic compute.* That one sentence is the whole answer.

---

## 6. Glue / EMR (the AWS ETL sources)

| Term | Meaning | Maps to in Databricks |
|---|---|---|
| **Glue** | AWS's serverless managed-Spark ETL service. | Databricks jobs/notebooks. |
| **DynamicFrame** | Glue's schema-flexible DataFrame variant (handles messy schemas). | Native Spark DataFrame. |
| **GlueContext** | Glue's wrapper around SparkContext. | SparkSession. |
| **Glue job bookmark** | Glue's incremental-state tracker (what's been processed). | Auto Loader checkpoint (file) + idempotent MERGE (data). **Missing this = double-processing bug.** |
| **Glue Data Catalog** | AWS's Hive-compatible metastore (table definitions for Athena/EMR/Spectrum). | Unity Catalog (or bridge during transition). |
| **Glue crawler** | Auto-infers schemas + registers tables in the Catalog. | Auto Loader schema inference/evolution. |
| **DPU** | **Data Processing Unit** — Glue's billing unit (compute capacity per job). | DBU (loosely). |
| **EMR** | **Elastic MapReduce** — AWS managed clusters running open-source Spark/Hadoop. | Databricks job clusters + cluster policies. |
| **EMRFS** | EMR's S3 filesystem layer (historically added read-after-write consistency). | Delta transactional consistency (native). |
| **bootstrap action** | A script EMR runs on each node at cluster start (installs/config). | Cluster init scripts / policies (mostly unneeded). |
| **EMR Serverless** | EMR without managing clusters. | Databricks serverless. |
| **Athena** | AWS serverless SQL over S3 (Presto/Trino). | Databricks SQL. |
| **Step** (EMR) | A unit of work submitted to an EMR cluster. | A Workflows task. |
| **Oozie** | Hadoop's workflow scheduler (sometimes on EMR). | Databricks Workflows. |

---

## 7. Governance / security / catalog

| Term | Meaning | Note |
|---|---|---|
| **UC (Unity Catalog)** | Databricks' governance layer: catalog→schema→table grants, lineage, audit, row/column security. | The target for all source grants. |
| **Lake Formation** | AWS's fine-grained data-lake permissions (row/column) over Glue Catalog. | → UC row filters + column masks. |
| **IAM** | AWS Identity and Access Management — roles/policies controlling who can do what. | → UC grants + cloud creds. |
| **SCIM** | System for Cross-domain Identity Management — auto-syncs users/groups from the IdP. | Group-based access in UC. |
| **IdP** | Identity Provider (Okta/AzureAD) — the source of truth for identities. | Feeds SCIM. |
| **row filter / column mask** | UC features: restrict rows / mask column values per user/group. | Centralized vs scattered view logic. |
| **ARN** | Amazon Resource Name — the unique ID of an AWS resource (used in IAM/Terraform refs). | — |
| **KMS** | Key Management Service — AWS encryption-key management. | S3/Delta encryption. |
| **object lock** | S3 feature making objects immutable for a retention period (COMPLIANCE/GOVERNANCE mode). | The 7-year audit retention on bronze. |

---

## 8. Data modeling / quality / ER

| Term | Meaning | Note |
|---|---|---|
| **ER (Entity Resolution)** | Deciding which records refer to the same real-world entity (same store, same product). | Deterministic here (rules + fuzzy), no ML. |
| **canonical** | The single authoritative version of an entity after resolving duplicates. | `canonical_retailer` etc. |
| **SCD** | Slowly Changing Dimension — how you track dimension changes over time. | — |
| **SCD2** | Keep history: on change, close the old row (`valid_to`) + insert a new version row. | vs SCD1 (overwrite, no history). |
| **bitemporal** | Track TWO time axes: **valid time** (when true in reality) + **transaction time** (when we learned it). | Restatement auditability. |
| **valid time** | When a fact was true in the real world. | SCD2 captures this. |
| **transaction time** | When we recorded/learned it. | Bitemporal adds this. |
| **3NF** | Third Normal Form — heavily normalized schema (minimize redundancy). | Teradata core; lakehouse silver denormalizes more. |
| **PK / FK** | Primary Key (unique row id) / Foreign Key (reference to another table's PK). | Natural keys drive MERGE/dedup. |
| **natural key** | The business identifier (e.g. retailer_id+product_id+date) vs a surrogate. | What idempotent MERGE matches on. |
| **surrogate key** | A system-generated id (IDENTITY/sequence). | Verify nothing depends on exact old values. |
| **DiD** | **Difference-in-Differences** — causal-inference method: did the treated group change more than the control? | The promo-lift gold mart. |
| **reconciliation** | Proving migrated/target data matches source — structural→count→aggregate→row-checksum (L1-L4). | The cutover gate. |
| **GE (Great Expectations)** | A data-quality testing framework (assert not-null, ranges, etc.). | DLT expectations replace it. |
| **HLL (HyperLogLog)** | Probabilistic distinct-count algorithm (`approx_count_distinct`). | Fast, approximate. |
| **Jaro-Winkler** | A string-similarity score (0-1) for fuzzy name matching. | Used in deterministic ER scoring. |
| **3σ (3-sigma)** | 3 standard deviations from the mean — an outlier threshold. | Outlier guardrails. |

---

## 9. Source systems / tools / consumers

| Term | Meaning |
|---|---|
| **SFTP** | SSH File Transfer Protocol — secure file drop (distributors push feeds). |
| **Transfer Family** | AWS's managed SFTP service that writes straight to S3. |
| **TDLinx** | Nielsen's retail-outlet reference database (store master data). |
| **Kafka** | Distributed event-streaming platform (durable, replayable topics + offsets). |
| **Kinesis** | AWS's managed streaming service (shards instead of partitions). |
| **Debezium** | Open-source CDC tool — turns DB change logs into Kafka events. |
| **schema registry** | Central store of Kafka message schemas + compatibility rules. |
| **Step Functions** | AWS's serverless workflow/state-machine orchestrator (per-file ingest here). |
| **Lambda** | AWS's serverless functions (the validation "hop"). |
| **SNS / SQS** | Simple Notification Service (pub/sub) / Simple Queue Service (message queue) — Auto Loader notification mode + alarms. |
| **CloudWatch** | AWS monitoring/metrics/alarms. |
| **PagerDuty** | On-call alerting/paging. |
| **Control-M** | Enterprise job scheduler (often fronts Teradata BTEQ). |
| **Informatica** | Enterprise ETL tool. |
| **Looker / Tableau** | BI/dashboarding tools (consumers). |
| **Alation** | Data catalog / lineage tool. |
| **Terraform** | HashiCorp's IaC tool; **HCL** = its config language; **provider** = the plugin for a platform (aws, databricks). |
| **Asset Bundles** | Databricks' IaC for jobs/notebooks/pipelines (deploys the Databricks side). |
| **terraform plan / apply** | Dry-run diff (what would change) / execute the change. |
| **state file** | Terraform's record of what it manages (source of truth; drift = console changes vs this). |

---

## 10. Migration / program terms

| Term | Meaning |
|---|---|
| **lift-and-shift** | Move 1:1 with minimal change (fast, carries forward anti-patterns). |
| **re-architect / re-platform** | Redesign for the target platform (slower, captures the real wins). |
| **strangler fig** | Migrate incrementally behind a stable interface (views) until the old system is fully replaced. |
| **dual-run / parallel run** | Run old + new simultaneously, reconcile nightly, cut over only when green. |
| **cutover** | The moment consumers switch from old to new. |
| **rollback** | Revert to the source (kept live) if cutover fails. |
| **soak** | Keep the old system available/read-only for a stability window before decommissioning. |
| **wave** | A phased batch of the migration (a domain/dependency cluster). |
| **moving-train problem** | Source keeps changing during a long migration → CDC + narrow freeze keep target in sync. |
| **decommission** | Shut down + delete the old system after soak. |
| **backfill** | Load historical data into the new system. |
| **high-water mark** | The last-processed timestamp/offset, so incrementals resume correctly. |
| **RPO / RTO** | Recovery Point Objective (max acceptable data loss) / Recovery Time Objective (max downtime). |

---

*Last updated: 2026-05-28*
