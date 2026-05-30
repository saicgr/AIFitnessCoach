# Senior Data Engineer — Round 1 Interview Prep
## STAR + Context-First Format · Short Answers · Easy to Scan

> **Two formats below** (use whichever the question fits):
>
> 1. **Story-style** (behavioral, scenario, "tell me about a project"): **STAR** — Situation, Task, Action (3-4 bullets), Result with numbers.
> 2. **Technical "how does X work"**: **Context → Answer → Anchor** — one-line technical primer, the technique bullets, then a real example I've used it on.
>
> Either way: 30-60 seconds spoken. Drop technical terms — Databricks Workflows, MERGE, watermark, Photon, AQE, broadcast, skew, spill, reconciliation, SCD2, idempotent, predicate pushdown, OPTIMIZE / Z-ORDER, liquid clustering, transformation, CDF, foreachBatch, Auto Loader — wherever they fit naturally. Sounds senior.
>
> **Anchor project:** Retail Sales Intelligence Platform at Juul Labs — Q1 2025 → Q1 2026. Address normalization + master retailer + product master + promo analysis.
>
> **No ML.** All entity resolution = deterministic rules + fuzzy string scoring. No learned models.

---

## Contents

0. [Interviewer profile (Dmitry)](#0-interviewer-profile-dmitry)
1. [Project portfolio + architecture](#1-project-portfolio--architecture)
2. [Warm-up](#2-warm-up)
3. [Anchor project deep-dive](#3-anchor-project-deep-dive)
4. [Core technical Q&A](#4-core-technical-qa)
5. [Deep-dive technical Q&A by area](#5-deep-dive-technical-qa-by-area)
   - 5.1 [Performance & debugging (OOM, skew, spill, AQE...)](#51-performance--debugging)
   - 5.2 [Databricks deep-dive](#52-databricks-deep-dive)
   - 5.3 [AWS deep-dive](#53-aws-deep-dive)
   - 5.4 [Streaming + late data](#54-streaming--late-data)
   - 5.5 [Schema evolution + drift](#55-schema-evolution--drift)
   - 5.6 [Orchestration deep-dive](#56-orchestration-deep-dive)
   - 5.7 [Testing & data quality](#57-testing--data-quality)
   - 5.8 [Terraform / CI-CD](#58-terraform--ci-cd)
   - 5.9 [SCDs + master data](#59-scds--master-data)
6. [Scenario questions](#6-scenario-questions)
7. [Dmitry-specific questions](#7-dmitry-specific-questions)
8. [Behavioral](#8-behavioral)
9. [Code snippets cheat sheet](#9-code-snippets-cheat-sheet)
10. [Closing + flashcards](#10-closing--flashcards)
11. [Architecture walkthrough + extended Q&A (ingest → bronze → silver → gold)](#11-architecture-walkthrough--extended-qa-ingest--bronze--silver--gold)
    - 11.0 [Example file end-to-end](#110-the-example-file--follow-one-feed-end-to-end) · 11.1 [Terraform providers + SFTP→S3](#111-terraform-resource-types--the-sftps3-to-and-fro) · 11.2 [Manifest vs checkpoint](#112-data-arrival-log--manifest--does-auto-loader-use-it) · 11.3 [Auto Loader modes / N files](#113-auto-loader-discovery-modes--does-n-files-trigger-n-cluster-starts) · 11.4 [Lambda validation gate](#114-if-lambda-didnt-validate-the-file-does-auto-loader-still-run) · 11.5 [Checkpoint storage](#115-where-is-auto-loaders-checkpoint-stored) · 11.6 [SGWS](#116-what-is-sgws) · 11.7 [Small-files](#117-small-files-problem--detail) · 11.8/11.9 [Micro-batch commit failure](#118--119-commit-failure-in-a-micro-batch--does-it-stop-the-next-ones-how-is-the-file-split-into-micro-batches) · 11.10/11.18 [Atomicity + idempotency](#1110--1118-why-atomic-commit--checkpoint-the-1-hardest-area-atomicity--idempotency) · 11.11 [Late-arriving data](#1111-late-arriving-data--separate-pipeline) · 11.12 [Concept primers](#1112-concept-primers--watermark-checkpoint-bucketing-salting-aqe-shuffle-partitions-partitioningpruning) · 11.13 [Cluster sizing](#1113-how-do-you-decide-cluster--memory-size--the-actual-numbers) · 11.14 [Finding skew](#1114-how-do-you-actually-find-skew-in-the-data) · 11.15 [4-hour job](#1115-a-job-that-should-be-fast-takes-4-hours--what-does-a-senior-do) · 11.16 [Driver vs worker OOM](#1116-driver-vs-worker-oom--which-one-can-you-move-work-off-a-bad-worker) · 11.17 [AQE + coalesce](#1117-more-aqe--coalesce) · 11.x [Bitemporal + MERGE](#11x-what-is-bitemporal-the-scd2-hardest-area--whiteboard-the-merge) · 11.y [Two orchestrators](#11y-why-two-orchestrators-the-hardest-area--reason-about-the-right-tool) · 11.z [Hard curveballs (schema drift, wrong number, SLA miss, exactly-once, federation)](#11z-more-hard-questions-star--the-curveballs)

**Migration interview?** See the companion file **`INTERVIEW_QA_MIGRATION.md`** (Teradata→Databricks, all STAR — strategy, reconciliation, cutover, cost, plus Redshift/Oracle adaptation notes).

12. [Platform positioning — why Databricks vs X](#12-platform-positioning--why-databricks-vs-x) — vs relational DB · vs Redshift · vs Snowflake · when NOT to pick it

---

## 0. Interviewer profile (Dmitry)

**Dmitry Stepanov — Director, Platform Engineering & AI at MUFG Investor Services** ($1T+ financial institution). 5 yrs at MUFG, prior Scotiabank + Personify. 12+ yrs experience.

### His values (direct quotes)
- "Pragmatic over perfect — ship good, not perfect delayed."
- "Honesty matters — say hard things directly."
- "Culture is infrastructure — psychological safety drives good decisions."
- "Impact over ego."

### His proudest wins (use as anchors)
- $5M/year AWS cost savings at MUFG
- Terraform standardization across 50+ teams
- Self-service infra: −75% manual provisioning, −60% deploy cycles
- Hybrid AWS/on-prem at Scotiabank
- Grew team 1 → 15+ at Personify

### What he'll ask about
Pragmatism · Terraform · Self-service · Hybrid · Cost · Mentorship · Trade-offs

### What he'll dislike
Hero stories · Over-engineering · Vague answers · Dodging risk · Buzzword salad

### Framing pivot (Juul → financial parallel)
| Juul | Financial parallel |
|---|---|
| FDA audit trail | SOX / FFIEC audit trail |
| State AG settlements | OCC consent orders |
| Trade-spend reconciliation | Trade-reporting reconciliation |
| Distributor data fragmentation | Counterparty reference data |

---

## 1. Project portfolio + architecture

### Anchor project — Retail Sales Intelligence Platform

```
TERRAFORM CLOUD (all infra-as-code) ────────────────────────┐
  AWS: VPC, SFTP, S3 (KMS + object lock), Lambda,           │
       Step Functions, CloudWatch, IAM, KMS, Secrets        │
  Databricks: workspaces, UC catalogs, cluster policies,    │
              service principals, secret scopes, Workflows  │
└──────────────────────────────────────────────────────────┘

12 distributor SFTP feeds + CRM + Nielsen TDLinx
         │
         ▼
┌─ INGEST (AWS) ──────────────────────────────────────────┐
│  Transfer Family → S3 → Step Functions → Lambda hop     │
│  CloudWatch alarms: file lateness, size anomaly         │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─ LAKEHOUSE (Databricks) ────────────────────────────────┐
│  BRONZE (raw, 7y object lock)                           │
│      ↓ Auto Loader                                      │
│  SILVER (typed, canonical, bitemporal)                  │
│   • normalized_address (libpostal + USPS via Lambda)    │
│   • candidate_retailer                                  │
│   • canonical_retailer (SCD2, deterministic ER)         │
│   • canonical_product (hierarchical taxonomy, SCD2)     │
│   • canonical_sales (joined to canonical IDs)           │
│      ↓ dbt-on-Databricks                                │
│  GOLD (precomputed marts)                               │
│   • sales_by_retailer_daily / sales_by_product_daily    │
│   • promo_performance_daily (DiD lift)                  │
│   • trade_spend_reconciliation                          │
└─────────────────────────────────────────────────────────┘
         │
         ▼
Looker · Databricks SQL · Alation (lineage)

ORCHESTRATION: Databricks Workflows (daily DAG, 4 AM UTC)
              + Step Functions (per-file ingest)
              + Lambda (event-driven triggers)
CI/CD:        GitHub Actions → Terraform Cloud + Asset Bundles
TESTING:      pytest · dbt test · Great Expectations · schema diff
MONITORING:   CloudWatch (AWS) + Databricks SQL dashboards + PagerDuty
```

### Quick reference — where each tool lives

| Layer | Tools |
|---|---|
| Infra-as-code | Terraform Cloud, OPA/conftest |
| AWS | Transfer Family, S3 (KMS + object lock), Lambda, Step Functions, CloudWatch, EventBridge, Secrets Manager, KMS, VPC + PrivateLink, DynamoDB |
| Lakehouse | Databricks Premium, Unity Catalog, Delta Lake medallion, Photon, Auto Loader, Liquid Clustering, Delta CDF |
| Transformations | PySpark (bronze→silver), dbt-core (silver→gold) |
| Orchestration | Databricks Workflows, Step Functions, Lambda |
| CI/CD | GitHub Actions, Asset Bundles, Terraform Cloud |
| Testing | pytest, dbt test, Great Expectations |
| Monitoring | CloudWatch + Databricks SQL dashboards + PagerDuty + Alation |

---

## 2. Warm-up

### Q. Tell me about yourself.

**S:** Senior DE at Juul Labs, 3 years in.
**T:** Lead the Databricks Lakehouse — architecture, governance, biggest active initiative.
**A:** Half code review for a team of 8, half hands-on coding. Most recent: Retail Sales Intelligence Platform with PySpark transformations, dbt gold marts, Databricks Workflows orchestration. Before: Unity Catalog rollout, 3,400 tables.
**R:** Day-to-day mix is ~50% review, 25% coding, 15% incidents, 10% stakeholder.

> 💡 **Remember:** Trap — rambling a chronological resume instead of leading with scope + impact. Say — "Senior DE leading Juul's Databricks Lakehouse for a team of 8 — half review, half hands-on, most recent build is the Retail Sales Intelligence Platform."

### Q. What does your day look like?

**S:** Async-first, remote, CST.
**T:** Balance platform health, project work, team support.
**A:** Morning: triage Slack + Terraform drift report + PRs. Mid: deep work block (design or coding). Office hours twice/week. 1:1 with manager weekly. Aim 1 PR shipped per day.
**R:** Roughly 50/25/15/10. Write code 2-3 days a week.

> 💡 **Remember:** Trap — making it sound like all meetings and no engineering for a hands-on senior role. Say — "Async-first day: morning triage of PRs and Terraform drift, a protected deep-work block, office hours twice a week — I aim to ship a PR a day."

### Q. How is the team structured?

**S:** Data org under CTO, ~25 people total, my group is 8 engineers.
**T:** Serve Trade Marketing, Sales Ops, Finance, Compliance.
**A:** Hub-and-spoke. We own platform (bronze ingest + silver canonical entities + governance). Analytics engineers embedded in domains own their gold marts via dbt.
**R:** Ticket queue dropped 60% in two quarters after the hub-spoke shift.

> 💡 **Remember:** Trap — describing structure without showing your team owns a clear boundary. Say — "Hub-and-spoke: my platform team owns bronze ingest, silver canonical entities, and governance; embedded analytics engineers own their gold marts in dbt — ticket queue dropped 60%."

---

## 3. Anchor project deep-dive

### Q. Tell me about a recent project.

**S:** Q1 2025. Juul sells through 12 distributors into ~120k retailers. Same Stop-N-Shop appeared as 3 different retailers across 3 feeds. Promo lift was ±15-20% off.

**T:** Build unified canonical retailer + product + promo platform on a Databricks Lakehouse. Replace 12 fragmented per-distributor reports.

**Stack:** Databricks Premium on AWS · Unity Catalog · Delta Lake medallion (bronze/silver/gold) · Terraform Cloud for infra · Databricks Workflows + AWS Step Functions for orchestration · Lambda for USPS API · dbt-core for gold marts · Great Expectations for DQ · Alation for catalog · Looker for BI · GitHub Actions + Asset Bundles for CI/CD · CloudWatch + PagerDuty for monitoring.

**A:**
- Address normalization first — libpostal Pandas UDF + USPS API wrapped in Lambda, responses cached in DynamoDB
- Deterministic rule-based entity resolution in PySpark — Jaro-Winkler on name/address, exact match on phone/banner, weighted-sum scoring, connected-components clustering (no ML)
- Hierarchical product master in Delta with SCD2 — GTIN-first → manufacturer code → fuzzy attribute fallback
- Promo analysis mart via dbt incremental models with MERGE — difference-in-differences lift vs control cohort
- Strangler rollout: ship each canonical layer to prod before starting the next; dual-write with legacy reports for one quarter

**R:** 247k retailer dupes → 124k true unique. Promo lift accuracy ±15-20% → within 2%. $1.2M trade-spend recovery in H2 2025. Strangler approach got Trade Marketing value in week 6, not month 6.

> 💡 **Remember:** Trap — drowning the listener in stack names before the business problem lands. Say — "Same Stop-N-Shop showed up as 3 retailers across 3 feeds, so promo lift was off ±15-20%; I built a canonical retailer/product/promo platform that took 247k dupes to 124k and recovered $1.2M in trade spend."

### Q. Why Databricks for this?

**Context:** Standard "why this stack" justification.

**Answer:**
- Single platform for SQL + PySpark + streaming + governance — one runtime, one identity model, one billing surface
- Delta Lake MERGE for SCD2 + bitemporal master data — idiomatic SQL, ACID semantics
- Unity Catalog for automatic column-level lineage + masks + row filters
- Snowflake considered but Snowpark was immature for our PySpark-heavy entity resolution; would have meant external services

**Anchor:** Got sign-off in week 2 of the project. Two-week PoC validated the Delta MERGE + GraphFrames clustering performance.

> 💡 **Remember:** Trap — sounding like a Databricks fanboy with no alternative considered. Say — "One platform for SQL, PySpark, streaming and governance, with Delta MERGE for SCD2 — I did weigh Snowflake but Snowpark was too immature for our PySpark-heavy entity resolution."

### Q. Address normalization — how did it work?

**S:** 12 distributor feeds with garbage address formatting, ~8% unmatchable to USPS without cleaning.
**T:** Take any input address and produce a canonical joinable representation.
**A:**
- Parse with libpostal inside a Pandas UDF (vectorized via Arrow)
- Standardize via USPS Publication 28 lookup table
- Validate via USPS Web Tools API wrapped in a Lambda with DynamoDB cache
- SHA-256 hash the final canonical address for cheap join keys
**R:** 99.7% normalized. USPS API cache hit rate 85%, cost $510/mo vs $3.4k projected.

> 💡 **Remember:** Trap — calling the USPS API row-by-row from Spark and ignoring rate limits/cost. Say — "libpostal in a vectorized Pandas UDF, then USPS validation through a rate-limited Lambda with a DynamoDB cache — 85% cache hit dropped the bill from $3.4k to $510/mo."

### Q. Entity resolution — walk me through it.

**S:** ~250k candidate retailers across 12 feeds, same physical location across up to 12 sources.
**T:** Cluster candidates into canonical retailers with stable IDs.
**A:** Five-stage deterministic pipeline — no ML:
1. **Standardize** — normalize address hash, E.164 phone, banner names
2. **Block** by zip5 + first token of business name (cuts 31B pairs → ~50M)
3. **Score pairwise** with rules: exact address-hash match = 1.0, Jaro-Winkler on name, exact phone match, exact banner match → weighted sum, hand-tuned weights
4. **Cluster** via Spark GraphFrames `connectedComponents` on pairs above 0.85 threshold
5. **Master record selection** by data-quality priority (Nielsen > Juul CRM > distributor)

`canonical_retailer_id = sha256(master_address_hash || normalized_banner)` for re-run stability.

**R:** 247k → 124k canonical. Precision 98.4%, recall 96.1%. ~45 min on 16 Photon workers.

> 💡 **Remember:** Trap — reaching for ML when the interviewer expects you to defend deterministic rules. Say — "Five deterministic stages — standardize, block by zip+name token to cut 31B pairs to 50M, rule-score with Jaro-Winkler plus exact matches, cluster with connected components, pick a master by data-quality priority — no ML, fully explainable at 98.4% precision."

### Q. Product master mapping?

**S:** Same product had 4-5 different SKU codes across feeds.
**T:** Single canonical product table with hierarchical taxonomy.
**A:** Three-tier matching: GTIN exact → manufacturer code + flavor + size pattern → fuzzy attribute match. Hierarchical taxonomy: device family → pod family → pack size → SKU.
**R:** 100% mapped. "Unknown SKU" sales: 8% → 0.4%.

> 💡 **Remember:** Trap — implying one magic match key when codes are inconsistent across feeds. Say — "Three-tier fallback — GTIN exact, then manufacturer code plus flavor/size pattern, then fuzzy attribute match — into a hierarchical taxonomy; unknown-SKU sales went 8% to 0.4%."

### Q. Promo analysis — how does the lift calc work?

**S:** Trade Marketing wanted promo lift on a monthly cadence.
**T:** Join canonical sales × canonical retailer × canonical product × promo calendar. Compute lift + cannibalization.
**A:**
- Identify promo cohort (retailers + products in promo) and control group (similar retailers not in promo)
- Compute promo-period sales vs 28-day baseline for both cohorts
- **Difference-in-differences**: subtract control's change from promo cohort's change to isolate the promo effect
- Materialized via dbt incremental MERGE into `gold.promo_performance_daily`
**R:** Lift accuracy ±15-20% off → within 2%. $1.2M in retailer-funded promo recoveries identified.

> 💡 **Remember:** Trap — calling raw promo-period sales the "lift" without a control group. Say — "Difference-in-differences — subtract a matched control cohort's change from the promo cohort's change to isolate the true effect — materialized via dbt incremental MERGE, accuracy tightened to within 2%."

---

## 4. Core technical Q&A

### Q. Why Delta over Parquet/Iceberg?

**Context:** Data lake table format choice.

**Answer:**
- ACID transactions + MERGE — non-negotiable for upsert workloads
- Time travel for audit + rollback
- Iceberg has feature parity now but Delta has tighter Databricks integration (UC, liquid clustering, CDF)
- Multi-cloud requirement → would reevaluate Iceberg

**Anchor:** Use Delta everywhere at Juul; never hit a feature wall in 3 years.

> 💡 **Remember:** Trap — claiming Delta is strictly superior when Iceberg has near parity now. Say — "ACID MERGE and time travel are non-negotiable for upserts; Delta wins on tighter Databricks integration today, but I'd reevaluate Iceberg the moment we went seriously multi-cloud."

### Q. Photon — on or off?

**Context:** Vectorized C++ execution engine; DBU premium applies.

**Answer:**
- On by default for SQL + Delta scans + Parquet reads — wins easily
- Off for Python-UDF-heavy stages — Photon falls back to JVM per row, you pay the premium for nothing
- Always measure with `system.billing.usage` cost-per-row, not wall-clock

**Anchor:** Had a Pandas-UDF-heavy job running 1.4× cost with Photon on. Vectorized the UDF via Arrow → Photon then won by 30%.

> 💡 **Remember:** Trap — saying "always on" — Photon falls back to JVM per row on Python UDFs and you pay the premium for nothing. Say — "On by default for SQL and Delta scans, but I measure cost-per-row in `system.billing.usage` — a Python-UDF-heavy stage ran 1.4× cost until I vectorized it via Arrow."

### Q. What transformations do you use most?

**Context:** Bread-and-butter Spark vocabulary.

**Answer:**
- Window functions for lag/lead, running totals, top-N per group, dedup
- `groupBy().agg()` for aggregations + `pivot()` for wide marts
- `withWatermark` + `dropDuplicates` for streaming dedup
- `MERGE INTO` for upserts + SCD2
- `broadcast()` hint for small-side joins
- `applyInPandas` for procedural per-group logic when set-based won't work

**Anchor:** Built the `silver.canonical_sales` MERGE with window-based dedup + Delta MERGE — runs in 90s on 50M rows because of `WHEN MATCHED AND attributes_hash differ` skip logic.

> 💡 **Remember:** Trap — listing transformations as trivia instead of tying them to a real pattern. Say — "Windows for dedup and top-N, MERGE for SCD2 upserts, broadcast for small dims — my canonical_sales MERGE runs 90s on 50M rows because a `WHEN MATCHED AND attributes_hash differ` skips no-op rewrites."

### Q. Schema evolution in Delta?

**Context:** Upstream sources change shape; pipeline shouldn't fall over.

**Answer:**
- `mergeSchema=true` on bronze for additive changes (new columns auto-added)
- Column mapping mode (`'name'`) for renames/drops without rewriting Parquet
- Strict enforcement on gold — `ALTER TABLE ADD COLUMN` only via PR with reviewer
- `MERGE WITH SCHEMA EVOLUTION` clause (DBR 12.2+) for inline merges that pick up new columns

**Anchor:** Distributor added 4 columns silently. Auto Loader `schemaEvolutionMode=addNewColumns` caught them in bronze with Slack alert; silver kept its strict shape until I explicitly mapped them.

> 💡 **Remember:** Trap — turning on `mergeSchema` everywhere so gold silently absorbs garbage. Say — "Permissive on bronze with `addNewColumns` plus an alert, strict on gold behind a PR — when a distributor added 4 columns, bronze caught them while silver held its shape until I explicitly mapped them."

### Q. Exactly-once in Spark Structured Streaming?

**Context:** Kinesis source is at-least-once; sink needs exactly-once semantics.

**Answer:**
- Spark Structured Streaming tracks Kinesis sequence numbers in checkpoint
- `foreachBatch` + Delta MERGE on stable `event_id` makes the sink idempotent
- `withWatermark` + `dropDuplicates` for in-batch dedup
- Replay-safe: same `batch_id` reprocessed produces same end state

**Anchor:** Zero duplicate event_ids in silver over 4 months of production streaming.

> 💡 **Remember:** Trap — claiming Spark gives exactly-once for free without an idempotent sink. Say — "Spark tracks source offsets in the checkpoint, but the sink is exactly-once only because `foreachBatch` does a Delta MERGE on a stable event_id — same batch_id replayed lands the same end state."

### Q. Window functions vs groupBy?

**Context:** Spark transformation choice.

**Answer:**
- Window if order matters within a group (lag/lead, top-N, running totals)
- GroupBy if you only need aggregates
- Windows shuffle more — expensive at scale

**Anchor:** Default to groupBy when possible; window when the question requires ordering (latest-record dedup, ranking).

> 💡 **Remember:** Trap — defaulting to window functions when a plain groupBy is cheaper. Say — "GroupBy when I only need aggregates, window when order matters within the group — windows shuffle more, so I reach for them only for lag/lead, top-N, or latest-record dedup."

### Q. Z-ORDER vs Liquid clustering?

**Context:** Multi-dimensional file layout for filter performance.

**Answer:**
- Z-ORDER: space-filling curve, great for filters, expensive rewrite, locks you into one query pattern
- Liquid clustering: adapts as data writes evolve, no rewrite, can change keys later
- Both improve data skipping via min/max stats in Parquet footers

**Anchor:** Migrated `silver.canonical_sales` from Z-ORDER to liquid clustering when the join pattern changed. Liquid handled the re-clustering in-place — no migration window.

> 💡 **Remember:** Trap — treating them as interchangeable; Z-ORDER locks you into one query pattern and needs a full rewrite. Say — "Z-ORDER is a one-shot expensive rewrite tied to one filter pattern; liquid clustering adapts in-place and lets me change keys later — I migrated canonical_sales with no migration window when the join pattern shifted."

### Q. CDC patterns?

**Context:** Source-system change tracking.

**Answer:**
- Sources with native CDC (Postgres logical replication, MySQL binlog) → land with change-type column → MERGE silver
- Snapshot-only sources → full snapshot to bronze → diff against silver's prior snapshot
- Delta Change Data Feed for downstream of silver — propagates row-level changes

**Anchor:** Enabled Delta CDF on `silver.canonical_retailer`. dbt incremental models read from `table_changes(...)` — gold rebuilds dropped ~60%.

> 💡 **Remember:** Trap — conflating source CDC with Delta's own Change Data Feed. Say — "Native CDC sources land with a change-type column and MERGE into silver; snapshot-only sources I diff against the prior snapshot; then Delta CDF propagates row-level changes downstream — gold rebuilds dropped ~60%."

---

## 5. Deep-dive technical Q&A by area

### 5.1 Performance & debugging

#### Q. How do you handle Out-of-Memory errors?

**Context:** OOM in Spark splits two ways — driver OOM (`.collect()`, broadcast estimate too small) vs executor OOM (skew, wide aggregation, join blowup). Fix depends on which.

**S:** Hit executor OOM on the `silver.canonical_sales` MERGE in November 2025 — 4 hours in, multiple executors died.
**T:** Diagnose, recover the day, harden against recurrence.
**A:**
- Spark UI showed one task in the join stage running 100× longer holding heap — classic skew, not memory misconfig
- Salted the skewed join key (hash mod 20 both sides) to spread heavy keys across more tasks
- Lowered `spark.sql.adaptive.skewJoin.skewedPartitionFactor` from 5 → 3 so AQE intervenes sooner
- Raised `spark.executor.memoryOverhead` for off-heap (Photon + Arrow buffers eat overhead)
**R:** Runtime 4h+ → 9 min. Cluster cost down ~80%. Lesson: OOM is almost always a skew problem in disguise — fix data layout before bumping memory.

> 💡 **Remember:** Trap — reflexively bumping executor memory before diagnosing. Say — "First I separate driver from executor OOM, then I check the Spark UI for an outlier task — OOM is almost always skew in disguise, so I salt the key before I ever touch memory."

#### Q. Walk me through diagnosing a slow Spark job.

**Context:** "Got slower" can mean data growth, schema change, layout drift, executor pressure, or a misbehaving UDF. Diagnose in order.

**S:** `gold.compliance_state_monthly` job started taking 4× longer in October 2025.
**T:** Root cause within an hour to avoid SLA breach.
**A:**
- **Spark UI stage view** — look for outlier task (3.4h on one task, rest done = skew)
- **DAG view** — confirm which logical op is the bottleneck (join? aggregation? UDF?)
- **`system.workflow.job_runs`** — compare to 30-day baseline; input volume same → not data growth
- **Delta `DESCRIBE HISTORY`** — recent OPTIMIZE Z-ORDER with bad keys 2 weeks back co-located records, killed join performance
**R:** Reclustering + AQE tuning got runtime back to 9 min from 4h+.

> 💡 **Remember:** Trap — guessing at the cause instead of diagnosing in order. Say — "I diagnose in order — Spark UI stage view for an outlier task, `job_runs` baseline to rule out data growth, then `DESCRIBE HISTORY` — which is how I found a bad Z-ORDER from two weeks back had killed the join."

#### Q. What's spill, when does it happen, how do you avoid it?

**Context:** Spill = Spark writes intermediate shuffle data to local disk because it doesn't fit in executor memory. Shows up in Spark UI as "Spill (Memory)" and "Spill (Disk)" metrics.

**Answer:**
- Causes: too-coarse partitioning, big aggregations holding many groups in memory, OOM-avoidance kicking in
- Symptoms: disk I/O spike, long task durations, GC pressure
- Fixes:
  - Bump `spark.sql.shuffle.partitions` (default 200; 800-2000 for big shuffles)
  - Enable AQE — dynamically coalesces small partitions, splits large
  - Avoid `groupBy().collect_list()` on high-cardinality keys — use windows
  - Re-cluster underlying Delta so partition reads pull less per task

**Anchor:** Caught 4TB spill on a daily reconciliation job — 200 shuffle partitions on 1B rows = 5M rows/partition. Bumped to 2000, AQE on. Spill → ~60GB, runtime 38 min → 14 min.

> 💡 **Remember:** Trap — treating spill as a memory problem and upsizing the cluster. Say — "Spill is shuffle data overflowing to disk, almost always too-coarse partitioning — 200 partitions on 1B rows is 5M rows each; I bumped shuffle partitions to 2000 with AQE on and 4TB spill dropped to 60GB."

#### Q. AQE — what does it actually do?

**Context:** Adaptive Query Execution = Spark 3+ runtime optimization that re-plans stages based on actual shuffle statistics, not static estimates.

**Answer:** Three things, all post-shuffle:
- **Coalesce post-shuffle partitions** — merges tiny partitions, avoids "tons of empty tasks" overhead
- **Switch join strategy** — converts sort-merge to broadcast mid-query if one side ends up small after filter
- **Skew join split** — if one partition is >`skewedPartitionFactor` × median, splits it + replicates the other side

**Anchor:** Default on for every job. Skew-split was the only setting I had to tune — default 5× threshold wasn't catching California's 4.7× skew. Lowered to 3× via `spark.sql.adaptive.skewJoin.skewedPartitionFactor=3` for that job; handled automatically after.

> 💡 **Remember:** Trap — assuming AQE catches all skew at defaults. Say — "AQE re-plans post-shuffle — coalesce, switch to broadcast, split skew — but its 5× default missed California's 4.7× skew until I lowered `skewedPartitionFactor` to 3."

#### Q. When does a broadcast join backfire?

**Context:** Broadcast hash join sends the small side to every executor. Fast for small dims, disastrous when "small" turns out to be 500MB.

**Answer:**
- Wrong size estimate — Spark estimates the broadcast side; complex expressions or post-filter sizes can be wildly off → OOM
- Skew on the small side — broadcast doesn't help; same heavy key replicated everywhere
- Threshold trap — `spark.sql.autoBroadcastJoinThreshold` default 10MB; teams bump to 200MB, then OOM

**Anchor:** `canonical_product` dim grew from 8k to 80k SKUs over a year. Spark still auto-broadcast; queries OOM'd at peak. Disabled auto-broadcast (`spark.sql.autoBroadcastJoinThreshold=-1`), switched to sort-merge with explicit hint where validated.

> 💡 **Remember:** Trap — assuming "small dim = always broadcast" forever. Say — "Broadcast OOMs when the size estimate is wrong or the dim quietly grows — my product dim went 8k to 80k SKUs and started OOMing, so I disabled auto-broadcast and forced sort-merge."

#### Q. Partition pruning — how do you verify it works?

**Context:** Pruning means Spark only reads partitions matching your filter. Easy to break by wrapping the partition column in a function.

**Answer:**
- `EXPLAIN FORMATTED` shows `PartitionFilters: [...]` — empty or function-wrapped means pruning broke
- Common break: `WHERE cast(date_col as string) = '2026-01-01'` — the cast prevents pruning
- Use native types: `WHERE date_col = date'2026-01-01'`
- Generated columns: `PARTITIONED BY (year GENERATED ALWAYS AS (year(event_ts)))` so filters on `event_ts` prune on `year`

**Anchor:** Discovered a 200GB scan on a quarterly aggregation that should have been 6GB. Filter wrapped `event_ts` in `BETWEEN` against a `event_date`-partitioned table. Rewrote to filter on the partition column directly — 30× speedup.

> 💡 **Remember:** Trap — wrapping the partition column in a `cast` or function and silently killing pruning. Say — "I verify with `EXPLAIN FORMATTED` that `PartitionFilters` is non-empty and filter on native types — a `cast(date as string)` once turned a 6GB scan into 200GB."

#### Q. The small-files problem in Delta — how do you handle?

**Context:** Streaming + frequent micro-batches produce thousands of tiny Parquet files. Reads suffer because file-open overhead dominates.

**Answer:**
- `OPTIMIZE` compacts small files into target-size files (default 1GB) — run weekly or after big writes
- `delta.autoOptimize.optimizeWrite=true` writes larger files at the cost of slight write latency; great default for streaming sinks
- `spark.databricks.delta.optimizeWrite.binSize` tunes target file size
- Liquid clustering is the modern answer — self-organizes on writes
- `VACUUM` afterward to delete the files OPTIMIZE replaced

**Anchor:** Bronze ingest from 12 distributors had ~2M files after 6 months. Year-of-data queries took 40 min just opening files. Nightly OPTIMIZE + VACUUM with 30-day retention. Scan time → 5 min, storage cost up only ~5%.

> 💡 **Remember:** Trap — forgetting VACUUM after OPTIMIZE so storage balloons with replaced files. Say — "OPTIMIZE compacts and VACUUM cleans up — 2M tiny files made year queries take 40 min; nightly OPTIMIZE plus VACUUM took scans to 5 min, or just use liquid clustering to self-organize on write."

#### Q. How do you debug a slow MERGE?

**Context:** Delta MERGE is the standard upsert pattern but rewrites every file containing an updated row. Slow on big tables without help.

**Answer:**
- Predicate pushdown inside MERGE's `ON` condition — force partition pruning so MERGE only touches relevant partitions
- Cluster on the merge key — Z-ORDER or liquid clustering reduces files touched
- Broadcast the source side if small; otherwise it shuffles to match target partitioning
- `WHEN MATCHED AND condition` to skip no-op updates

**Anchor:** `silver.canonical_retailer` MERGE rewriting 30% of files daily because ER pipeline emitted all records, even unchanged. Added `WHEN MATCHED AND src.attributes_hash != tgt.attributes_hash THEN UPDATE` — rewrites dropped to ~3%, runtime 12 min → 90s.

> 💡 **Remember:** Trap — letting MERGE rewrite every file because no-op updates aren't skipped. Say — "Force partition pruning in the `ON` clause, cluster on the merge key, and add `WHEN MATCHED AND attributes_hash differ` — that alone took canonical_retailer from rewriting 30% of files to 3%, 12 min to 90s."

#### Q. Stream state store growing unbounded — how to fix?

**Context:** Structured Streaming state stores (aggregations, joins, sessionization) grow until watermark allows cleanup. Without watermark, they grow forever.

**Answer:**
- `withWatermark("event_ts", "1 hour")` lets state drop keys past watermark
- Switch to RocksDB state store for big state — pages to disk; in-memory state store doesn't
- Reduce key cardinality — group on coarser keys if business permits
- Monitor via `query.lastProgress().stateOperators` for size, eviction count

**Anchor:** Stream-stream join held 8M rows in state at peak. In-memory state OOM'd executors. Switched to RocksDB (`spark.sql.streaming.stateStore.providerClass=...RocksDBStateStoreProvider`) + dropped slow-side watermark from 1h to 30 min. State stabilized at ~1M rows.

> 💡 **Remember:** Trap — running a stateful stream with no watermark so state grows forever. Say — "A watermark lets state drop old keys, and RocksDB pages big state to disk — my stream-stream join held 8M rows until I added both and it stabilized at ~1M."

#### Q. Reconciliation — how do you design the checks?

**Context:** Reconciliation = your pipeline's numbers must match an authoritative source within tolerance.

**Answer:** Three rules:
- Reconcile early and often — daily, not quarterly. Longer gap = harder root-cause
- Reconcile at the right grain — total daily revenue is too coarse (a $10k positive and $10k negative cancel). Reconcile by distributor, state, product category
- Capture the gap, don't just alert — write diff rows to `audit.reconciliation_log` with timestamp + source rows + target rows

**Anchor:** Daily POS revenue vs NetSuite ERP reconciliation via Great Expectations checkpoints, tolerance 0.5%. Caught a McLane double-counting issue in October 2025 — promo units appeared in both regular + promo feeds. Investigation took 4 hours because the audit log had row-level diff. $340k overstated revenue prevented.

> 💡 **Remember:** Trap — reconciling only on a coarse grain where a positive and negative error cancel out. Say — "Reconcile early, at the right grain, and capture the gap — daily by distributor/state/category with row-level diffs in an audit log is how I caught McLane double-counting and stopped a $340k overstatement."

---

### 5.1b OOM / Skew / Spill extended (Databricks-specific)

#### Q. Driver OOM vs Executor OOM — how do you tell them apart?

**Context:** Same symptom (job dies), totally different fixes. Driver runs your `main` + collects results + plans queries; executors do the actual data work.

**Answer:**
- **Driver OOM signs:** "Driver is temporarily unavailable" in cluster log, `RpcTimeoutException`, `OutOfMemoryError: Java heap space` in driver stderr, cluster restart loop
- **Executor OOM signs:** `ExecutorLostFailure (Container killed by YARN for exceeding memory limits)`, exit code 137 (cgroup OOMKiller), tasks retrying on different executors
- **Driver causes:** `.collect()`, `.toPandas()` on big DF, broadcast hint on something not-small, heavy Python on driver
- **Executor causes:** skew, too-coarse partitions, wide aggregations, GC pressure from object churn

**Anchor:** Inherited a notebook running `df.toPandas()` on a 30GB DataFrame to "preview" — driver OOM'd every run. Replaced with `df.limit(1000).toPandas()`, problem gone. Driver crash 99% of the time = somebody collecting too much.

> 💡 **Remember:** Trap — applying executor fixes (salting, partitions) to a driver OOM. Say — "I read the error first: `RpcTimeoutException` or 'Driver temporarily unavailable' means somebody collected too much; `ExecutorLostFailure` with exit 137 means skew or coarse partitions — totally different fixes."

#### Q. `spark.driver.maxResultSize` — when do you tune it?

**Context:** Cap on serialized data returned to driver via `collect()`. Defaults to 1GB. Bumping it just delays the inevitable.

**Answer:**
- Raise only if you legitimately need the result on driver (e.g., generating a small report from final aggregates)
- Driver heap often OOMs well before `maxResultSize` if your driver is small — raising the limit doesn't help
- Better: write the result to a Delta table, read back if needed
- Lower it (e.g., `512m`) as a guardrail — fail fast when someone tries to collect too much

**Anchor:** Set `spark.driver.maxResultSize=512m` as a cluster-policy default at Juul. Forces engineers to write to a table instead of collecting. Caught 3 collect-bombs in code review the first month.

> 💡 **Remember:** Trap — raising `maxResultSize` to "fix" a driver OOM, which just delays the crash. Say — "I actually lower it to 512m as a guardrail so collect-bombs fail fast — the real fix is writing the result to a Delta table, not collecting to the driver at all."

#### Q. Photon + OOM — does the memory model change?

**Context:** Photon is a C++ vectorized engine using off-heap memory. The JVM heap shrinks ~25-50% when Photon is enabled because some memory reserves for the C++ side.

**Answer:**
- Photon-handled stages use off-heap; JVM stages (Python UDFs, etc.) still use on-heap
- Mixed workloads can OOM the JVM side while Photon side is fine — `executor.memoryOverhead` is the lever
- `spark.memory.offHeap.size` is auto-configured by Photon; you usually don't touch it directly
- Photon spills to disk too — same memory-pressure rules apply, just faster spill (no Java serialization overhead)

**Anchor:** Enabled Photon on a Python-UDF-heavy job, executors OOM'd at half the volume they used to handle. Root cause: smaller JVM heap, UDF rows piling up. Fixed by raising `spark.executor.memoryOverhead` from 10% to 25%.

> 💡 **Remember:** Trap — forgetting Photon shrinks the JVM heap, so Python-UDF stages OOM sooner. Say — "Photon reserves off-heap, so a mixed Python-UDF job can OOM the smaller JVM heap even when Photon is fine — the lever is `executor.memoryOverhead`, which I bumped 10% to 25%."

#### Q. GC pressure as an OOM precursor — how do you detect it?

**Context:** OOM rarely comes out of nowhere. GC pressure (long pauses, frequent full GCs) is the warning sign hours before crash.

**Answer:**
- Spark UI executor tab shows "GC Time" column — if >10% of task time, you're under GC pressure
- Ganglia / cluster metrics show heap utilization; >85% sustained = trouble
- Log signal: `OutOfMemoryError: GC overhead limit exceeded` means GC is spending 98%+ of time and reclaiming <2%
- Fixes: reduce object churn (avoid millions of small Java objects), prefer Datasets over RDDs, native Spark over UDFs

**Anchor:** Caught GC time at 18% of task time on a job before it OOM'd via the dashboard. Root cause: `groupBy().collect_list()` on a 1B-row table accumulating millions of small arrays. Switched to a window-based top-N, GC time dropped to 2%.

> 💡 **Remember:** Trap — waiting for the OOM crash instead of watching GC as the early warning. Say — "GC Time over 10% of task time is the canary — I caught 18% from a `collect_list` on a 1B-row table before it crashed and switched to a window-based top-N, dropping GC to 2%."

#### Q. `ExecutorLostFailure` — what's the diagnostic flow?

**Context:** Most common visible OOM symptom. The reason string in the error matters.

**Answer:**
- **Exit code 137** = killed by Linux OOMKiller (cgroup memory limit hit) — bump `spark.executor.memoryOverhead`
- **"Container killed by YARN for exceeding memory limits"** = JVM heap fine but total container exceeded — same fix
- **"exited unexpectedly"** without a kill reason = often a Python crash or Photon crash
- Always check task duration on the failing executor — long-running outlier = skew, not memory misconfig

**Anchor:** Got ExecutorLostFailure with exit code 137. Doubled `memoryOverhead` reflexively — wrong move. Real cause was a skewed join. Fixed via salting, kept the original memory budget. **Don't bump memory before checking skew.**

> 💡 **Remember:** Trap — bumping `memoryOverhead` on exit 137 without checking the failing executor's task duration. Say — "Exit 137 is the OOMKiller and YARN-killed is the same fix, but I always check task duration first — a long-running outlier means skew, and I once doubled memory for nothing when salting was the real fix."

#### Q. How do you actually detect skew in Spark UI?

**Context:** Skew detection is visual in the Stages tab. Look for outliers in task statistics.

**Answer:**
- Failing stage → "Summary Metrics for Completed Tasks" → compare Min / 25th / Median / 75th / Max for Duration + Shuffle Read Size
- If **Max is 10× the Median = strong skew**
- If Max task is still running while others done = skew in flight
- "Tasks" view sortable by duration — outlier's input size tells you which key
- Stage's input/output records bar shows skew visually too

**Anchor:** December 2025 incident — median task 4s, max task 3h42m. That ratio is the textbook signal. Found the bad key (California `state_code`) in 2 minutes by sorting tasks by input size.

> 💡 **Remember:** Trap — eyeballing the DAG instead of reading the task summary metrics. Say — "Stages tab, Summary Metrics — if Max is 10× the Median, that's skew; I found California in 2 minutes by sorting tasks by input size when median was 4s and max was 3h42m."

#### Q. AQE skew join — when does it NOT trigger?

**Context:** AQE skew handling is gated by TWO thresholds: `skewedPartitionFactor` (relative to median) AND `skewedPartitionThresholdInBytes` (absolute size). Both must be exceeded.

**Answer:**
- Default `skewedPartitionFactor=5` (5× the median partition size)
- Default `skewedPartitionThresholdInBytes=256MB`
- Skew has to exceed BOTH to trigger the split — common gotcha
- If your skew is 4× median, AQE won't fire even though there's clearly a problem
- Lower factor (3×) for known-skewed workloads, or lower bytes threshold

**Anchor:** This was the literal cause of my December 2025 4-hour skew incident. AQE was enabled, just not aggressive enough. `SET spark.sql.adaptive.skewJoin.skewedPartitionFactor=3` fixed it in one config change.

> 💡 **Remember:** Trap — assuming AQE skew handling fires on the factor alone. Say — "It needs BOTH `skewedPartitionFactor` (5×) AND `skewedPartitionThresholdInBytes` (256MB) exceeded — a 4× skew slips through, which is exactly why my December incident sat unfixed until I lowered the factor to 3."

#### Q. Salting vs broadcast vs filter-then-rejoin — when do you use which?

**Context:** Three families of skew fixes, each with a sweet spot.

**Answer:**
- **Salting** — both sides large, skewed key unavoidable. Add `salt` column, replicate the smaller side, join on `(key, salt)`
- **Broadcast** — smaller side genuinely small (<200MB after filters). Skips the shuffle entirely
- **Filter-then-rejoin** — one skewed key dominates; isolate it. Union the skewed-key join (broadcast) with the rest (sort-merge)
- AQE skew split = the lazy version. Let it try first, fall back to manual

**Anchor:** Used salting on `state_code` (CA/TX always hot). Broadcast on `dim.product` (80k rows). Filter-then-rejoin once on a NYC-vs-rest split where NYC was 60% of volume.

> 💡 **Remember:** Trap — reaching for salting first when it's the most invasive (a code change). Say — "Salt when both sides are large and the key's unavoidable, broadcast when the small side fits under 200MB, filter-then-rejoin when one mega-key dominates — and let AQE skew-split try before any of them."

#### Q. Skewed aggregation (not join) — different fix?

**Context:** Aggregation skew = one key has way more rows than others. Same family as join skew but AQE doesn't auto-fix it.

**Answer:**
- Two-stage aggregation pattern: pre-aggregate with salt, then aggregate the partial results un-salted
- `df.withColumn("salt", F.rand()*100).groupBy("hot_key","salt").agg(partial_sum).groupBy("hot_key").agg(F.sum("partial_sum"))`
- Approximate aggregations: `approx_count_distinct`, `approx_percentile` — way cheaper at scale
- AQE doesn't help here the way it does join skew

**Anchor:** Used two-stage aggregation on a daily POS rollup where California alone produced 30% of rows. Pre-aggregate with 100-way salt, final aggregation collapsed back. Job time 45 min → 11 min.

> 💡 **Remember:** Trap — assuming AQE skew-join handling fixes aggregation skew (it doesn't). Say — "For aggregation skew I do a two-stage pattern — salt then pre-aggregate, then re-aggregate un-salted — California was 30% of rows and it took the job 45 min to 11."

#### Q. Multi-key skew — composite keys?

**Context:** Skew can hide in composites (e.g., `state_code + product_category`). Single-column salting won't help if both columns contribute to skew.

**Answer:**
- Hash the composite into a single key first, then salt that
- Or salt the combined key: `salt = hash(concat(state, category)) % N`
- Watch for nested skew — fixing state-skew can reveal product-skew underneath
- Re-check tail percentiles after the first fix to confirm

**Anchor:** Had skew on `(state_code, distributor_id)`. CA-McLane was 8% of rows. Single-column salt on state cut it from 8% to 4% — still skewed on distributor. Salted both into one composite hash, problem resolved.

> 💡 **Remember:** Trap — salting one column when the skew lives in the composite, and missing nested skew underneath. Say — "Hash the composite into one key then salt that, and re-check tail percentiles — salting just state on CA-McLane only took it 8% to 4% until I salted the combined hash."

#### Q. Skew on the small side of a broadcast — what happens?

**Context:** Broadcast doesn't help if the small side itself has a heavy key — every executor gets the heavy key replicated.

**Answer:**
- Broadcast replicates the small side everywhere; skew on it just propagates
- 100k rows total but 50k for one key → every executor holds 50k for that key → fine in isolation
- Problem appears in the JOIN output: 50k × 1M big-side rows = 50B output rows per executor → OOM
- Fix: split the join — broadcast the non-skewed keys, salted join for the skewed key

**Anchor:** Saw this once on a dim with one mega-customer. Broadcast worked, the join itself exploded. Filter-then-rejoin pattern fixed it cleanly.

> 💡 **Remember:** Trap — thinking broadcast immunizes you from skew on the small side. Say — "Broadcast just replicates the small side everywhere, so a heavy key blows up the join output, not the broadcast — I split it, broadcasting the normal keys and salting the mega-key."

#### Q. Spill (Memory) vs Spill (Disk) — what's the difference?

**Context:** Spark UI shows two spill metrics. Confusing names — they measure the same event from different angles.

**Answer:**
- **Spill (Memory)** = bytes of in-memory data that got serialized before spilling — accounts for object overhead
- **Spill (Disk)** = bytes written to local disk after serialization — usually smaller due to compression
- Both nonzero = your job exceeded in-memory budget for shuffle/sort
- High ratio (Spill Memory >> Spill Disk) = good compression; close ratio = data was already compact

**Anchor:** Saw 4TB Spill (Memory) → 700GB Spill (Disk) on the reconciliation job. ~6× compression. After bumping shuffle partitions to 2000, spill went to zero.

> 💡 **Remember:** Trap — double-counting the two spill metrics or thinking they're different events. Say — "Same event, two angles — Spill (Memory) is the in-memory bytes before serialization, Spill (Disk) is what actually hit disk; my 4TB-to-700GB ratio just meant good compression, and bumping partitions zeroed it."

#### Q. How do you choose `spark.sql.shuffle.partitions`?

**Context:** Default 200 is from a different era. Modern workloads almost always need more. Math, not vibes.

**Answer:**
- Aim for partition size of 100-200MB after shuffle
- Math: `total_shuffle_bytes / 128MB = optimal partitions`
- AQE coalesce handles overshoot — set high, let AQE merge down
- ~1TB shuffle → 8,000 partitions. ~100GB → 800. ~10GB → 80.
- Don't exceed ~10,000 — task overhead dominates

**Anchor:** Set per-job based on expected shuffle from `EXPLAIN COST`. The 200 default cost us 2-3× runtime on the bigger jobs before tuning.

> 💡 **Remember:** Trap — leaving the 200 default in place for big shuffles. Say — "It's math, not vibes — `total_shuffle_bytes / 128MB`, so ~1TB shuffle wants ~8000 partitions; set it high and let AQE coalesce down, the 200 default cost us 2-3× runtime."

#### Q. AutoOptimizeShuffle — when do you trust it?

**Context:** Databricks AQE feature (`spark.sql.adaptive.autoOptimizeShuffle.enabled=true`) auto-tunes shuffle partition count from runtime statistics.

**Answer:**
- Good for jobs where shuffle size is variable run-to-run
- Less good for jobs you've already hand-tuned — AOS sometimes overshoots
- Tweakable via `spark.sql.adaptive.autoOptimizeShuffle.partitionSizeInBytes` (default 128MB)
- Always measure before/after; rare regression cases exist

**Anchor:** Enabled AOS on the daily reconciliation job — saved manual tuning. Kept it off on the `canonical_sales` MERGE where my hand-tuned count was already optimal.

> 💡 **Remember:** Trap — turning AOS on over an already hand-tuned job where it can overshoot. Say — "I trust it for variable-shuffle workloads to save manual tuning, but I leave it off where I've already hand-tuned the partition count — and I always measure before/after."

#### Q. When is spill acceptable vs disaster?

**Context:** Not all spill is bad. Tiny spills don't matter; massive spill kills performance and can crash the job.

**Answer:**
- Spill < 10% of shuffle data = acceptable, often unavoidable
- Spill 10-50% = job is 1.5-2× slower than it should be, worth fixing
- Spill > 50% of shuffle data = job is 5-10× slower, fix now
- Catastrophic spill (>2× shuffle volume) = OOM is imminent, disk thrashing

**Anchor:** Reconciliation job spilling 4TB on 800GB of shuffle (5× catastrophic). Bumped shuffle partitions to 2000 + AQE on. Spill → ~50GB (acceptable). Runtime 38 → 14 min.

> 💡 **Remember:** Trap — chasing zero spill when small spill is normal and harmless. Say — "Spill under 10% of shuffle is fine, over 50% means 5-10× slowdown, and over 2× shuffle volume means OOM is imminent — my 4TB on 800GB was catastrophic, partition tuning took it to acceptable 50GB."

#### Q. `spark.executor.cores` — when do you tune it?

**Context:** Cores per executor. Default is 4-5 on most Databricks runtimes. More cores = more parallelism per node, less memory per core.

**Answer:**
- Lower cores (2-3) when individual tasks need more memory — fewer competing for the same executor heap
- Higher cores (8+) for CPU-bound workloads with small per-task memory
- Tradeoff: more cores = more concurrent tasks but more GC contention
- Photon mostly negates the need to tune cores; off-heap means tasks don't fight for JVM heap

**Anchor:** Pre-Photon, had a memory-hungry UDF stage that was OOMing with default 4 cores. Lowered to 2 cores, doubled memory per task, problem gone. Post-Photon, default cores work fine because the heavy data is off-heap.

> 💡 **Remember:** Trap — adding cores to a memory-hungry stage, which shrinks heap per task. Say — "Fewer cores gives each task more heap for memory-hungry UDFs, more cores helps CPU-bound work — I dropped to 2 cores to fix a UDF OOM, though Photon mostly makes this moot by going off-heap."

#### Q. Streaming OOM — different from batch?

**Context:** Structured Streaming has a state store that grows; OOM in streaming is usually state-related, not batch-style data skew.

**Answer:**
- State store growth is the #1 streaming OOM cause — watermark too generous, key cardinality too high
- Switch to RocksDB state store (`spark.sql.streaming.stateStore.providerClass=...RocksDBStateStoreProvider`) — pages to disk, doesn't hold everything in heap
- Bound the watermark — `withWatermark("event_ts", "1 hour")` not `"7 days"` unless you really need 7
- Monitor `stateOperators.numRowsTotal` in `query.lastProgress` — alert at growth rate, not just absolute size

**Anchor:** Stream-stream join state hit 8M rows in heap, executors started OOMing. Switched to RocksDB state store + dropped watermark from 1h to 30 min. State stabilized at 1M rows, OOMs gone.

> 💡 **Remember:** Trap — debugging streaming OOM like batch data skew. Say — "Streaming OOM is state-store growth, not data skew — tighten the watermark and switch to RocksDB so it pages to disk; my stream-stream join went from 8M rows in heap to a stable 1M."

---

### 5.1c OOM / Skew / Spill — step-by-step playbooks

> The "what do you actually do, in what order" workflow questions. Run through these answers with the steps numbered so you sound like you've done it 50 times. Because you have.

#### Q. Walk me through your step-by-step process for fixing an OOM.

**Context:** Triage-first playbook I run for any production OOM. Six steps, in order. Order matters — bumping memory before fixing skew wastes money.

**Answer:**
1. **Identify type** — read the error first. Driver OOM (`OutOfMemoryError: Java heap space` in driver stderr, `RpcTimeoutException`, "Driver is temporarily unavailable") vs Executor OOM (`ExecutorLostFailure`, exit code 137, "Container killed by YARN")
2. **Spark UI → Stages → Failed stage** — click the failed stage, look at the task summary metrics table. Compare Max task duration / Max shuffle read vs Median
3. **If Max ≥ 10× Median = skew**, not memory pressure. Jump to the skew playbook below
4. **If task sizes uniform = true memory pressure.** First lever: bump `spark.sql.shuffle.partitions` (more, smaller tasks). Re-run
5. **Still OOM?** Bump `spark.executor.memoryOverhead` from 10% to 20-25% (especially for PySpark / Pandas UDFs)
6. **Last resort** — bigger instance type (more memory per core) OR lower `spark.executor.cores` so each task gets more heap

**Anchor:** This playbook fixed 9 of 10 OOM pages on my team in 2025. The 10th was a memory leak (different diagnostic). Skipping step 2 and bumping memory directly is the most common junior mistake — it hides skew, costs money, and the problem comes back next month.

> 💡 **Remember:** Trap — jumping straight to a bigger instance and skipping the diagnosis steps. Say — "Six steps in order — identify driver vs executor, read the failed stage's task metrics, skew if Max is 10× Median, then shuffle partitions, then `memoryOverhead`, bigger instance last — this fixed 9 of 10 OOM pages on my team."

#### Q. Pager fires at 2 AM with OOM. What's your first move?

**Context:** Compressed version of the above for the panic moment.

**Answer:**
- **First move: do NOT bump memory.** Tempting at 2 AM; almost always wrong
- Open Spark UI → Failed stages → look at task duration distribution
- Outlier task = skew → quick fix is `SET spark.sql.adaptive.skewJoin.skewedPartitionFactor=3` + restart from checkpoint
- Uniform task sizes = real memory pressure → bump shuffle partitions, restart
- If genuinely catastrophic and need data flowing now: temporary cluster upsize, but file the real-fix ticket in the morning

**Anchor:** December 2025 — pager fires, my first move was opening Spark UI not the cluster config. Outlier task at 3h42m, others done in 4s. AQE tweak + salt → ran in 9 min. Bumping memory would have wasted 30 min and not fixed it.

> 💡 **Remember:** Trap — bumping memory at 2 AM because it feels like the fast fix. Say — "First move is NOT touching memory — I open Spark UI and read the task duration distribution; outlier means skew (an AQE tweak from checkpoint), uniform means real memory pressure."

#### Q. What's the order of operations for fixing skew?

**Context:** Databricks docs recommend simplest-cheapest first. Salting is the last resort — it's a code change.

**Answer:** Five steps in order:
1. **Filter skewed values** if business permits (e.g., the skew is from a test account or junk key) — rare but easiest when it works
2. **Skew hints** — `SELECT /*+ SKEW('orders', 'cust_id', 'mega_customer_id') */` tells Spark explicitly which key is hot
3. **AQE skew optimization** — `spark.sql.adaptive.skewJoin.skewedPartitionFactor=3` (drop from default 5). One config line, zero code change
4. **Broadcast** if one side fits after filter (<200MB) — skips the shuffle entirely
5. **Salting** — last because it's a code change. Hash-mod-N suffix on both sides

**Anchor:** I try AQE config first — it's one line and easy to roll back. Salting was my December 2025 fix only because AQE alone got me from 4h to 1h45 but not below. Salt + AQE got it to 9 min.

> 💡 **Remember:** Trap — salting first when cheaper config-only fixes exist. Say — "Cheapest first — filter the junk key, skew hints, AQE `skewedPartitionFactor=3` (one line, no code), broadcast if it fits, salt LAST because it's a code change."

#### Q. You see massive spill in Spark UI — what's the systematic fix?

**Context:** Spark UI shows Spill (Memory) and Spill (Disk) in GB-to-TB range.

**Answer:** Four steps in order:
1. **Check for skew FIRST.** If skew exists, fixing it eliminates most spill. Summary Metrics → Max vs Median
2. **No skew → bump `spark.sql.shuffle.partitions`.** Default 200 is way too low for big shuffles. Math: `total_shuffle_bytes / 128MB`. 1TB shuffle → 8,000 partitions
3. **Verify AQE coalesce is on** (`spark.sql.adaptive.enabled=true`, default true on DBR 11+) — lets Spark merge small partitions post-shuffle
4. **Still spilling? Bump executor memory** — but usually steps 1-3 have fixed it. Big shuffles on small executors will always spill

**Anchor:** Daily reconciliation spilling 4TB. Step 1: no skew. Step 2: partitions 200 → 2000. AQE already on. Spill dropped to 60GB. Runtime 38 → 14 min. Never touched memory.

> 💡 **Remember:** Trap — bumping executor memory before ruling out skew and partition count. Say — "Check skew first, then bump shuffle partitions by `shuffle_bytes/128MB`, then verify AQE coalesce, memory last — my 4TB spill dropped to 60GB without ever touching memory."

#### Q. How do you decide between adding memory vs fixing data layout?

**Context:** The shortcut is "bigger cluster." The right move usually isn't.

**Answer:** Decision rule:
- **Layout problem (fix this first):** task duration outliers in Spark UI (skew), spill on a uniform workload, bad partition count, recent OPTIMIZE / Z-ORDER / clustering change
- **Memory problem (rare in practice):** task durations uniform, no outlier, spill proportional to data, executor heap > 85% sustained even after partition tuning, Photon enabled with heavy Python UDF
- **Both:** fix layout first — more memory hides layout problems and you'll pay again next month

**Anchor:** Out of 12 OOM pages in 2025, 10 were layout problems disguised as memory. The 2 that were really memory: a Photon job with heavy Python UDFs (needed `memoryOverhead` bump), and a stream-stream join with state growth (needed RocksDB).

> 💡 **Remember:** Trap — defaulting to "bigger cluster" when it's almost always a layout problem. Say — "Outlier tasks, spill on a uniform workload, or a recent OPTIMIZE change all mean fix layout first — 10 of my 12 OOM pages last year were layout disguised as memory."

#### Q. Production job suddenly slow — what's your triage workflow?

**Context:** No code change, just got slower. Could be data, layout, infra, or external dependency.

**Answer:** Five steps:
1. **Compare to baseline.** Query `system.workflow.job_runs` for last 30 days. Same input volume? Same duration trend?
2. **Spark UI Stages.** Find the slowest stage; was it slow last week too?
3. **Spark UI task summary.** Min/median/max — if max >> median, skew. If uniform slow, infra (spot reclaims, cluster downsize)
4. **Delta table history.** Recent OPTIMIZE / Z-ORDER / clustering changes can fight new query patterns. `DESCRIBE HISTORY`
5. **Input data shape.** New distributor onboarded? New SKU mix? POS feed double-counting?

**Anchor:** October 2025 — `compliance_state_monthly` 22 min → 4h overnight. Steps above pinpointed: Z-ORDER 2 weeks back reclustered for filter perf, fought our join pattern. Re-clustered, problem fixed.

> 💡 **Remember:** Trap — assuming "slower" means data growth and missing a layout change. Say — "Five steps — `job_runs` baseline, slowest stage, task metrics, `DESCRIBE HISTORY`, input shape — a `compliance_state_monthly` job 22 min to 4h turned out to be a two-week-old Z-ORDER fighting the join pattern."

#### Q. How do you reproduce a prod OOM in dev?

**Context:** Hard to debug what you can't reproduce. Sample data on a tiny cluster usually won't OOM.

**Answer:** Four-step reproduction:
1. **Pull the exact partition that failed** — Spark UI's failed-task input partition pointer tells you which
2. **Run on 10% sample sized to match memory pressure per core** — same memory-per-core ratio as prod, not same cluster size
3. **Enable heap dumps:** `spark.executor.extraJavaOptions=-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dbfs/heapDumps`
4. **`EXPLAIN FORMATTED`** to verify plan in dev matches prod — AQE rules sometimes differ across runtimes

**Anchor:** Reproduced the December incident in dev by reading just the November 2025 California partitions on a cluster sized 1:10 of prod. OOM'd the same way. Salt fix verified locally before pushing.

> 💡 **Remember:** Trap — running a tiny sample on a tiny cluster that never reproduces the OOM. Say — "Pull the exact failed partition and match the memory-per-core ratio, not the cluster size — I reproduced December by reading just the California partitions at 1:10 scale and it OOM'd identically."

#### Q. How do you PREVENT OOM in the first place?

**Context:** Proactive vs reactive. Stops the 2 AM page from happening.

**Answer:** Five preventive practices:
1. **Cluster policies** enforce sane defaults — max workers cap, mandatory tags, no `i3.16xlarge` ad-hoc
2. **Code review lints** flag `.collect()`, `.toPandas()`, broadcast hints on unbounded sides
3. **`spark.driver.maxResultSize=512m`** as guardrail — fail fast when collecting too much
4. **Pre-prod sample runs in CI** on representative data shape (not just toy fixtures)
5. **Liquid clustering on hot tables** — avoids the Z-ORDER-vs-different-query-pattern trap

**Anchor:** OOM pages dropped from ~12/year to ~3/year after I shipped the cluster policies + lint rules + sample-run CI step in 2024.

> 💡 **Remember:** Trap — treating OOM as purely reactive firefighting. Say — "Prevent it with cluster policies, lint rules flagging `collect`/`toPandas`, `maxResultSize=512m`, CI sample runs, and liquid clustering on hot tables — that took my OOM pages from 12 a year to 3."

#### Q. Cluster autoscale isn't helping — why and what do you do?

**Context:** Autoscale adds executors when memory is tight. Doesn't always help.

**Answer:**
- Autoscale adds executors but **doesn't redistribute existing skewed partitions**
- A 50GB skewed partition won't fit on a new executor any better than the old one
- Autoscale also has 30-60s latency — too slow for in-flight OOM
- Fix the layout (salt, partition), don't rely on autoscale to save you

**Anchor:** Configured min workers conservatively, let autoscale ramp on heavy stages. Caught one job where autoscale was masking a real partition problem — disabled autoscale for that job, forced the issue to surface, fixed it properly.

> 💡 **Remember:** Trap — expecting autoscale to rescue an in-flight OOM. Say — "Autoscale adds executors but can't redistribute a 50GB skewed partition, and it's 30-60s too slow for an in-flight OOM — I fix the layout and once disabled autoscale to force a masked partition problem to surface."

#### Q. What's your runbook for diagnosing a slow MERGE?

**Context:** Delta MERGE is the upsert pattern; slow MERGE is one of the most common production complaints.

**Answer:** Four-step diagnostic:
1. **`EXPLAIN FORMATTED` the MERGE** — verify partition pruning fires on the `ON` clause (`PartitionFilters:` should be non-empty)
2. **Check for `WHEN MATCHED AND condition`** — skip no-op updates by hashing attributes; massive win on SCD2 tables
3. **Source size** — if source > 10MB, MERGE shuffles to match target. Consider `broadcast()` hint on source if small
4. **Clustering** — Z-ORDER or liquid clustering on the join key reduces files touched by the MERGE rewrite

**Anchor:** `canonical_retailer` MERGE 12 min → 90 sec after adding `WHEN MATCHED AND src.attributes_hash != tgt.attributes_hash`. Single line of SQL.

> 💡 **Remember:** Trap — diagnosing a slow MERGE without checking whether partition pruning even fires on the `ON` clause. Say — "`EXPLAIN FORMATTED` to confirm `PartitionFilters` is non-empty, then skip no-op updates with a hash compare, broadcast a small source, cluster on the join key — the hash compare alone took canonical_retailer 12 min to 90 sec."

#### Q. What's your runbook for diagnosing slow streaming?

**Context:** Streaming-specific perf issues differ from batch — state store dynamics matter.

**Answer:** Four checks:
1. **Latency dashboard** — `query.lastProgress` exposes processedRowsPerSecond + durationMs per phase
2. **State store size growth** — growing = watermark too generous OR RocksDB needed
3. **Photon on streaming?** — Photon helps streaming too; verify it's on for SQL-heavy streaming
4. **foreachBatch latency** — if MERGE inside batch is slow, see slow-MERGE runbook above

**Anchor:** Streaming silver lagging — checked progress events, foreachBatch MERGE was 18s of the 30s trigger. Tuned MERGE clustering, batch dropped to 4s.

> 💡 **Remember:** Trap — debugging streaming latency like a batch job and ignoring the `foreachBatch` MERGE. Say — "Read `lastProgress` for per-phase timing and state growth first — my streaming silver was lagging because the foreachBatch MERGE ate 18 of 30s, so it routed back to the slow-MERGE runbook."

#### Q. How do you size a cluster for a new workload?

**Context:** Sizing from scratch — the alternative to "guess and hope."

**Answer:** Four-step sizing approach:
1. **Run on 10% sample** with a small cluster (2 workers). Note: total shuffle bytes from `EXPLAIN COST`, peak heap usage from Ganglia, spill metrics
2. **Math the partition count:** `total_shuffle_bytes / 128MB = optimal shuffle partitions`
3. **Math the worker count:** `(total_shuffle_bytes / partitions_per_worker) / (memory_per_worker × 0.5)` — leaves 50% headroom
4. **Scale linearly to full data** — if 10% ran clean on 4 workers, full data needs ~40

**Anchor:** Sized the canonical_sales daily job this way — 10% test on 4 workers, predicted 40 workers for full volume, actual sweet spot was 32. Same approach for every new pipeline now.

> 💡 **Remember:** Trap — guessing "let's just grab a big cluster" instead of sampling and doing the math. Say — "Sample → measure → math → scale linearly — 10% on a small cluster, partition count from `shuffle_bytes/128MB`, workers with 50% headroom; predicted 40 for canonical_sales, landed at 32."

---

### 5.2 Databricks deep-dive

#### Q. Walk me through how you configured Auto Loader for the distributor feeds.

**S:** 12 distributor SFTP feeds dropping CSV/JSON into S3 bronze prefixes, ~50M transactions/month combined.
**T:** Ingest reliably with schema inference + drift handling.
**A:**
- Auto Loader in `cloudFiles` mode with `schemaLocation` per feed, `schemaEvolutionMode=addNewColumns`
- File notification mode (SNS → SQS) instead of directory listing — cheaper at scale
- `cloudFiles.maxFilesPerTrigger=200` to bound batch size
- `rescuedDataColumn` captures malformed rows for the DQ queue
**R:** Bronze ingest p95 = 4 minutes per feed; missed-file alerts under 10 minutes.

> 💡 **Remember:** Trap — defaulting to directory listing at scale where it gets expensive. Say — "Auto Loader with per-feed schema location, `addNewColumns` evolution, `rescuedDataColumn` for bad rows, and file-notification mode (SNS/SQS) instead of listing because listing gets pricey at scale."

#### Q. When would you use Delta Live Tables vs hand-rolled Workflows?

**S:** Choosing the orchestration pattern for new pipelines at Juul.
**T:** Decide DLT vs PySpark + Workflows.
**A:**
- DLT for simple medallion flows where teams want declarative DQ expectations
- Hand-rolled Workflows for the Retail platform — needed custom MERGE logic, GraphFrames connected-components, Lambda callbacks DLT can't model cleanly
- DLT's serverless mode is great but obscures cost attribution at our scale
**R:** Stuck with Workflows + dbt for the anchor project; piloted DLT on a low-stakes reference-data feed.

> 💡 **Remember:** Trap — picking DLT because it's the newer/shinier option. Say — "DLT for simple declarative medallion flows, but the Retail platform needed custom MERGE, GraphFrames connected-components, and Lambda callbacks DLT can't model — so Workflows plus dbt, with a DLT pilot on a low-stakes feed."

#### Q. Liquid clustering — how did you pick the keys?

**S:** `silver.canonical_sales` was 18 TB, queries filtered by retailer + date + product.
**T:** Avoid the Z-ORDER rewrite cycle.
**A:**
- Clustered on `(sale_date, canonical_retailer_id, canonical_product_id)` — order matches actual filter selectivity
- `OPTIMIZE` runs nightly with `auto_optimize.optimizeWrite=true`
- Re-ran `ANALYZE TABLE ... COMPUTE STATISTICS` after backfills
**R:** Looker dashboard p95 dropped from 14s to 3s; no migration window because liquid clustering is in-place.

> 💡 **Remember:** Trap — picking cluster keys by gut instead of actual filter selectivity. Say — "I ordered the keys by real filter selectivity — `(sale_date, retailer_id, product_id)` matching how queries actually filter — and Looker p95 dropped 14s to 3s with no migration window."

#### Q. How do you use Delta Change Data Feed in production?

**S:** Multiple gold marts consume `silver.canonical_retailer` — full re-reads were wasteful.
**T:** Propagate only changed rows downstream.
**A:**
- Enabled `delta.enableChangeDataFeed=true` on silver canonicals
- dbt incremental models read from `table_changes(...)` with a watermark in a state table
- Audit log of CDF reads stored in a UC system table for compliance
**R:** Gold rebuild time dropped ~60% on retailer-fanout marts; saved ~$8k/mo on a single mart.

> 💡 **Remember:** Trap — full-re-reading silver downstream when only a few rows changed. Say — "Enable `enableChangeDataFeed` on the silver canonicals, have dbt incrementals read `table_changes(...)` with a watermark — gold rebuilds dropped ~60% and saved $8k/mo on one mart."

### 5.3 AWS deep-dive

#### Q. How is your S3 bucket layout structured and why?

**S:** 7-year FDA retention requirement on raw distributor data.
**T:** Layout that supports retention, lifecycle, least-privilege access.
**A:**
- One bucket per environment, prefix-per-feed (`bronze/distributor=mclane/dt=2026-05-27/`)
- Object Lock in compliance mode on bronze raw for 7 years; governance mode on silver
- Lifecycle: bronze raw → Glacier IR after 90 days, expire silver/gold intermediates at 30
- KMS CMK per environment, key policy grants only the workspace's instance profile
**R:** Storage cost down ~35% after lifecycle rollout; passed internal SOC2 audit on first pass.

> 💡 **Remember:** Trap — designing layout for access alone and forgetting retention/lifecycle economics. Say — "Bucket per env, prefix per feed, Object Lock compliance-mode 7 years on bronze raw for FDA, lifecycle to Glacier IR after 90 days, KMS CMK per env — cut storage 35% and passed SOC2 first pass."

#### Q. Walk me through your IAM trust pattern between Databricks and AWS.

**S:** Unity Catalog needs to read/write S3 from a Databricks workspace without long-lived keys.
**T:** Set up trust safely.
**A:**
- UC storage credential = IAM role with trust policy scoped to Databricks' AWS account + the external ID UC assigns
- Role grants only the prefixes UC needs (no `s3:*`)
- Separate IAM role for workspace instance profile, never reused for UC
- All roles managed in Terraform with OPA gating on `s3:*` wildcards
**R:** Zero long-lived keys in the platform; external-ID rotation drill ran clean.

> 💡 **Remember:** Trap — using long-lived access keys or a wildcard `s3:*` role. Say — "UC storage credential is an IAM role with a trust policy scoped to Databricks' account plus the external ID, granted only the prefixes it needs, separate from the instance-profile role — zero long-lived keys, OPA blocks `s3:*`."

#### Q. How did you design the Lambda that wraps the USPS API?

**S:** USPS Web Tools API rate-limited and occasionally flaky; calling from PySpark via Pandas UDF was a bad idea.
**T:** Build a stable, cached, rate-limited bridge.
**A:**
- Lambda with reserved concurrency = 10 to respect USPS quotas
- DynamoDB cache keyed on `address_hash` — checked first; 85% hit rate
- Exponential backoff with jitter on 429/5xx, dead-letter to SQS after 3 retries
- Pandas UDF batches 500 addresses per Lambda invoke via boto3
**R:** Address normalization cost $510/mo vs $3.4k projected; zero USPS quota breaches.

> 💡 **Remember:** Trap — hammering a rate-limited external API with no cache, concurrency cap, or backoff. Say — "Reserved concurrency 10 to respect the quota, DynamoDB cache for an 85% hit rate, exponential backoff with a DLQ, and 500-address batches per invoke — $510/mo vs $3.4k projected, zero quota breaches."

#### Q. Step Functions vs Lambda chaining — when do you reach for which?

**S:** Per-file ingest had 5+ steps (decrypt → validate → land → register → notify).
**T:** Pick the orchestration shape.
**A:**
- Step Functions when there's branching, retries with different policies per step, or human-visible state
- Pure Lambda chains (via EventBridge) when it's a stateless 2-step hop
- Step Functions Express for high-volume short flows — cheaper than Standard
- Always emit a custom CloudWatch metric per terminal state for alarming
**R:** Per-file ingest visible in one Step Functions UI; on-call MTTR dropped because state is obvious.

> 💡 **Remember:** Trap — chaining Lambdas for a multi-step flow that needs branching and visible state. Say — "Step Functions when there's branching, per-step retries, or human-visible state; plain Lambda/EventBridge chains for a stateless two-step hop — and every terminal state emits a CloudWatch metric for alarming."

### 5.4 Streaming + late data

#### Q. How do you size watermarks without over-buffering state?

**S:** Stream of POS events; some retailers batch-upload nightly, others stream live.
**T:** Pick a watermark that doesn't blow up state.
**A:**
- Measured actual lateness distribution from 30 days of bronze data: p99 = 22 minutes
- Set watermark to 30 minutes — covers p99 plus headroom
- Bucketed truly-late uploads (>30 min) into a separate batch path
- Monitored state-store size via Spark UI; alert at 50 GB
**R:** State store stable at ~12 GB; <0.1% of events drop as truly-late.

> 💡 **Remember:** Trap — picking a watermark by gut, then either dropping legit data or blowing up state. Say — "I measured 30 days of actual lateness — p99 was 22 min, so I set the watermark to 30 with headroom and routed truly-late uploads to a separate batch path; state stayed at 12GB."

#### Q. RocksDB state store vs default — what triggers the switch?

**S:** A streaming join started OOM-ing on the driver after we widened a watermark.
**T:** Decide whether to scale or change state backend.
**A:**
- Default in-memory state store keeps everything in heap — fine for <2GB state
- Switched to RocksDB when state exceeded ~8GB sustained
- Tuned `spark.sql.streaming.stateStore.rocksdb.compactOnCommit=true` to bound disk
- Kept checkpoints on S3, state on local NVMe
**R:** OOM gone, query throughput +20%, memory pressure dropped to 60% utilization.

> 💡 **Remember:** Trap — scaling the cluster to fix state-store OOM instead of changing the backend. Say — "In-memory state is fine under ~2GB, but past ~8GB sustained I switch to RocksDB so it pages to disk — that killed the OOM and bumped throughput 20% without a bigger cluster."

#### Q. Exactly-once edge case — what happens if `foreachBatch` partially succeeds?

**S:** Asked about exactly-once guarantees beyond the textbook answer.
**T:** Be honest about the edge.
**A:**
- `foreachBatch` is exactly-once IF the function is idempotent — Spark replays the same `batch_id`
- If the function writes to Delta then calls an external webhook, the webhook can fire twice
- Pattern: write a Delta `_batch_id` marker first, no-op if marker exists on replay
- External side effects always go through an idempotency-token table
**R:** Caught one real case where a Slack notifier was double-firing; marker pattern fixed it.

> 💡 **Remember:** Trap — claiming `foreachBatch` is exactly-once even when it fires external side effects. Say — "It's exactly-once only if idempotent — a Delta write replays cleanly, but an external webhook can fire twice, so I write a `_batch_id` marker first and route side effects through an idempotency-token table."

#### Q. How do you handle out-of-order events that must affect a daily aggregate?

**S:** Sales adjustments arrive up to 14 days after the original sale.
**T:** Daily aggregate must reflect adjustments without rewriting all history.
**A:**
- Partition gold by `sale_date`; reprocess trailing 14 days every night
- Use Delta MERGE keyed on `(sale_date, retailer_id, product_id)` — overwrites only touched partitions
- Track `last_adjustment_ts` per day in a metadata table; trigger spot-recomputes if it changes
- Cost: ~14× a single day's compute, capped and predictable
**R:** Aggregates always match source of truth within 24h; finance reconciliation breaks dropped to near-zero.

> 💡 **Remember:** Trap — rewriting all history to absorb a late adjustment. Say — "Partition gold by `sale_date` and reprocess a trailing 14-day window with a MERGE keyed on the natural keys — it only touches affected partitions, ~14× one day's compute, capped and predictable."

### 5.5 Schema evolution + drift

#### Q. Distributor renamed a column from `store_id` to `retailer_store_id`. How did you handle it?

**S:** McLane silently renamed a column in their nightly CSV.
**T:** Don't lose the column, don't break silver.
**A:**
- Auto Loader rescued-data column caught it in bronze; Slack alert fired
- Enabled Delta column mapping mode (`'name'`) on the silver target so we could rename without rewrite
- Added an explicit alias in the bronze→silver PySpark code mapping both old and new names
- Documented the rename in the data-contract doc
**R:** Zero data loss; ingest resumed in 90 minutes after the alert.

> 💡 **Remember:** Trap — a rename silently dropping the column or forcing a full Parquet rewrite. Say — "The rescued-data column caught it in bronze with an alert; I enabled column-mapping name mode on silver to rename without rewriting Parquet and aliased both names in code — zero data loss, ingest back in 90 min."

#### Q. How do you enforce schema contracts between bronze and silver?

**S:** Silver is the canonical layer; downstream marts can't tolerate surprises.
**T:** Make contracts enforceable, not aspirational.
**A:**
- JSON schema contract per silver table in repo (`contracts/silver/*.json`)
- CI step diffs proposed silver schema against the contract — PR blocked on mismatch
- Great Expectations suite enforces nullable + type + cardinality at runtime
- Contract changes require sign-off from the consuming mart owner
**R:** One mart-breaking change in 12 months, caught in CI before merge.

> 💡 **Remember:** Trap — relying on docs/convention so contracts stay aspirational, not enforced. Say — "A JSON schema contract per silver table in the repo, a CI step that diffs the proposed schema and blocks the PR on mismatch, plus Great Expectations at runtime — one mart-breaking change in 12 months, caught before merge."

#### Q. Column mapping mode gotchas you've hit?

**S:** Turned on column mapping mode on a heavy silver table.
**T:** Avoid the foot-guns.
**A:**
- Once enabled, downgrade is one-way painful — pin Delta reader/writer versions
- Some Spark connectors (older JDBC) don't read column-mapped tables — broke a Tableau extract
- `CHANGE COLUMN` only renames in metadata, not in Parquet — `OPTIMIZE` doesn't rewrite physical names
- CDF read pattern needs care because `_change_type` survives renames but column refs may not
**R:** Now enable column mapping only on tables we expect to evolve; default off elsewhere.

> 💡 **Remember:** Trap — enabling column mapping everywhere and getting bitten by the one-way downgrade and connector breakage. Say — "It broke an older JDBC Tableau extract and the downgrade is one-way painful, so I pin reader/writer versions and turn column mapping on only for tables I expect to evolve, off elsewhere."

#### Q. How do you communicate schema changes to downstream consumers?

**S:** Eight teams consume the gold layer via Looker + Databricks SQL + direct Delta reads.
**T:** No "surprise migration" emails on Monday morning.
**A:**
- Alation catalog has automatic lineage; consumers subscribe to dataset notifications
- Schema-change PRs trigger a comment listing all downstream tables + dashboards touched
- Two-week deprecation window for column drops; old column aliased + a `_deprecated_at` tag
- Monthly data-platform office hours to walk through upcoming changes
**R:** Last 4 schema changes shipped with zero broken dashboards.

> 💡 **Remember:** Trap — shipping a schema change and surprising eight teams with a Monday-morning migration. Say — "Alation lineage tells consumers what's affected, schema-change PRs auto-comment every downstream table and dashboard, and column drops get a two-week deprecation window with the old column aliased — last 4 changes broke zero dashboards."

### 5.6 Orchestration deep-dive

#### Q. Databricks Workflows task retry policy — what's your default?

**S:** Setting defaults across ~600 jobs.
**T:** Retry without masking real failures.
**A:**
- Max retries = 2, min retry interval = 5 minutes (exponential)
- `retry_on_timeout = false` — timeouts often mean state, not transience
- Idempotency is a precondition: no retries on tasks that aren't idempotent
- Per-task overrides only for known-flaky external dependencies (e.g. USPS API)
**R:** Retry-masked bugs dropped sharply; pages now mean something.

> 💡 **Remember:** Trap — generous retries that mask real bugs and retry non-idempotent tasks. Say — "Max 2 retries, 5-min exponential backoff, `retry_on_timeout=false` because timeouts usually mean state, and idempotency is a precondition — retry-masked bugs dropped sharply and pages mean something again."

#### Q. CloudWatch alarm strategy for the AWS side?

**S:** Need to page on real problems, not noise.
**T:** Layer alarms thoughtfully.
**A:**
- Tier 1 (page): SFTP feed missing >2h past expected, S3 PutObject failures sustained, Step Functions failed terminal state
- Tier 2 (Slack only): file size anomaly (>3σ from 30-day avg), latency p95 breaches
- Composite alarms to suppress noise during planned maintenance
- All alarms defined in Terraform, reviewed quarterly for false-positive rate
**R:** Page volume ~3-5/week; >80% are real issues.

> 💡 **Remember:** Trap — paging on everything until on-call ignores the pager. Say — "Two tiers — page on missing feeds, sustained PutObject failures, and Step Functions terminal failures; Slack-only for size anomalies and latency — plus composite alarms to suppress maintenance noise; >80% of pages are real."

#### Q. How do you handle backfills without disrupting the live pipeline?

**S:** Need to backfill 6 months of `canonical_sales` after a logic fix.
**T:** Don't compete with production for resources.
**A:**
- Dedicated backfill job cluster with `spot_bid_price_percent=50`, off-hours schedule
- Backfill writes to a shadow table; cutover via `ALTER TABLE ... RENAME` after validation
- Per-day partitions processed in parallel with a Semaphore to cap concurrency at 10
- Live pipeline keeps running on a separate cluster pool with reserved on-demand capacity
**R:** 6 months backfilled in ~8 days; zero live SLA breaches during the window.

> 💡 **Remember:** Trap — backfilling on the production cluster and starving live SLAs. Say — "Dedicated spot backfill cluster off-hours writing to a shadow table, cut over with `ALTER TABLE RENAME` after validation, live pipeline on reserved capacity — 6 months in 8 days, zero live SLA breaches."

#### Q. Step Functions error handling pattern?

**S:** Per-file ingest has 5 stages; any can fail transiently or terminally.
**T:** Distinguish and route correctly.
**A:**
- `Retry` blocks for transient errors (`Lambda.ServiceException`, `TooManyRequestsException`) with backoff
- `Catch` blocks route terminal errors to a `QuarantineFile` Lambda + PagerDuty
- Custom error names thrown by Lambdas (`ChecksumMismatchError` etc.) get specific Catch routes
- Every terminal state emits a CloudWatch metric for the alarming layer
**R:** ~98% of transient failures self-heal; quarantine queue averages 1-2 files/week with clear root causes.

> 💡 **Remember:** Trap — treating transient and terminal failures the same way. Say — "`Retry` blocks with backoff for transient errors, `Catch` blocks routing terminal ones to quarantine plus PagerDuty, custom error names for specific routes — ~98% of transient failures self-heal."

### 5.7 Testing & data quality

#### Q. What does your dbt test suite cover?

**S:** ~80 gold-layer dbt models.
**T:** Catch contract violations before they hit Looker.
**A:**
- Generic tests on every model: `unique` + `not_null` on PK, `relationships` on FK columns
- Custom singular tests for business rules (e.g. `promo_lift_pct between -100 and 500`)
- `dbt-expectations` for distributional checks (mean/stddev tolerance vs 30-day baseline)
- Tests run in PR CI on a sampled dev schema, full-volume in nightly job
**R:** Test failures catch ~3-4 issues/month before merge; gold-layer post-deploy incidents <1/quarter.

> 💡 **Remember:** Trap — only doing `unique`/`not_null` and skipping business-rule and distributional checks. Say — "Generic `unique`/`not_null`/`relationships` on keys, plus singular tests for business rules like `promo_lift between -100 and 500` and dbt-expectations for distributional drift vs a 30-day baseline — catches 3-4 issues/month before merge."

#### Q. Great Expectations vs dbt tests — how do you split?

**S:** Both tools in the stack.
**T:** Avoid overlap and confusion.
**A:**
- dbt tests own gold layer (logic + business rules)
- Great Expectations owns silver and bronze (statistical + DQ profile checks)
- GE suites version-controlled, run as Workflows tasks, not from notebooks
- Alation surfaces GE pass/fail as catalog badges so consumers see DQ health
**R:** Clear ownership; no debates about where a check belongs.

> 💡 **Remember:** Trap — running both tools with overlapping checks and constant "where does this belong" debates. Say — "Clean split — dbt owns gold logic and business rules, Great Expectations owns silver/bronze statistical and DQ-profile checks, GE suites version-controlled and run as Workflows tasks, surfaced as Alation badges."

#### Q. How do you integration-test a pipeline that depends on Lambda + Step Functions + Databricks?

**S:** Hard to test end-to-end without a staging environment.
**T:** Make integration tests fast and trustworthy.
**A:**
- Dedicated `stg` environment, Terraform-managed, identical shape to prod
- Synthetic distributor fixtures dropped into staging SFTP via a CI job
- Assertion runner reads gold tables after pipeline completes, compares to expected
- Runs nightly + on every infrastructure PR
**R:** Caught two Step Functions IAM regressions before they hit prod; ~25 min full run.

> 💡 **Remember:** Trap — only unit-testing pieces and never exercising the cross-service flow end-to-end. Say — "A Terraform-managed staging env identical to prod, synthetic fixtures dropped into staging SFTP by CI, an assertion runner that reads gold and compares to expected — caught two Step Functions IAM regressions before prod."

#### Q. Contract testing between producer teams and your platform?

**S:** Distributor data formats drift; producer teams don't always tell us.
**T:** Make the contract executable.
**A:**
- JSON Schema contract committed in repo, agreed with each producer
- A "contract test" Lambda runs on every new file in bronze, validates structure
- Violations alert the producing team's Slack channel directly, not just us
- Quarterly contract review meeting with each distributor's tech lead
**R:** Contract breakages now caught and fixed by the source team; we stopped being the bug-tracker for their changes.

> 💡 **Remember:** Trap — being the team that absorbs and debugs every upstream format change. Say — "An agreed JSON Schema contract, a contract-test Lambda on every new bronze file, and violations that alert the producing team's Slack directly — they fix their own breakages instead of us being their bug tracker."

### 5.8 Terraform / CI-CD

#### Q. How is your Terraform state organized?

**S:** Multiple environments + AWS + Databricks providers.
**T:** State strategy that scales without becoming a blast-radius hazard.
**A:**
- Terraform Cloud workspaces per (environment, domain): `prd-aws-network`, `prd-dbx-workspaces`, etc.
- Remote state references via `tfe_outputs` data source, never direct state file reads
- Module versions pinned to git tags; minor bumps via Dependabot PRs
- Drift detection runs nightly; auto-creates issues for unresolved drift
**R:** State corruption incidents: zero in 2 years. Drift PR turnaround averages 2 days.

> 💡 **Remember:** Trap — one giant monolithic state file with a huge blast radius. Say — "Terraform Cloud workspaces split per environment and domain, cross-references via `tfe_outputs` never raw state reads, modules pinned to git tags — zero state-corruption incidents in 2 years."

#### Q. OPA policy-as-code examples you actually enforce?

**S:** Standardization across the team without becoming a bottleneck.
**T:** Policies that block real risk, not nits.
**A:**
- No `s3:*` or `iam:*` wildcards on production roles
- All S3 buckets must have encryption + versioning + public access block
- Databricks cluster policies must set `max_workers` and require cost tags
- Conftest runs in PR CI; bypass requires a documented exception PR with director approval
**R:** Caught two over-permissive IAM PRs in the last quarter; ~5 min added to CI for the safety.

> 💡 **Remember:** Trap — policies that nitpick style instead of blocking real risk, so people route around them. Say — "Policies that block real risk only — no `s3:*`/`iam:*` wildcards, mandatory bucket encryption/versioning, cluster policies requiring `max_workers` and cost tags — caught two over-permissive IAM PRs last quarter for 5 min of CI."

#### Q. Asset Bundles — what's the pattern you settled on?

**S:** Deploying Databricks jobs + notebooks + dbt across dev/stg/prd.
**T:** One source of truth for job definitions.
**A:**
- One bundle per domain (retail-platform, finance, compliance), targets for each env
- Bundle YAML references the dbt project as a subfolder; `tasks` block includes `dbt_task`
- GitHub Actions runs `databricks bundle deploy --target prd` on merge to main
- Secrets resolved via UC service principals, never hardcoded
**R:** Job deploys went from ~30 min manual to <3 min on merge; rollback is `git revert`.

> 💡 **Remember:** Trap — hand-deploying jobs/notebooks so prod and repo drift apart. Say — "One bundle per domain with per-env targets, the dbt project referenced as a subfolder, `databricks bundle deploy` on merge via GitHub Actions — deploys went 30 min manual to under 3, rollback is `git revert`."

#### Q. Drift between Terraform and reality — how do you handle it?

**S:** Ops team makes a console change at 2 AM during an incident.
**T:** Don't punish the fix, but don't let drift persist.
**A:**
- Nightly `terraform plan` across all workspaces; non-zero drift creates a Jira ticket
- Drift SLA: reconciled within 5 business days (either codify or revert)
- Quarterly review: which resources drift most? Often signals a module needs refactor
- "Break-glass" tag on resources allows temporary manual change with auto-expiry
**R:** Drift-tickets-aged-over-30-days went from ~15 to 0 over two quarters.

> 💡 **Remember:** Trap — punishing the 2 AM console fix or letting drift quietly persist. Say — "Nightly `terraform plan` files a ticket on drift with a 5-day reconcile SLA, and a break-glass tag allows a temporary manual change with auto-expiry — don't punish the fix, but don't let drift persist; aged drift tickets went 15 to 0."

### 5.9 SCDs + master data

#### Q. Why deterministic IDs for `canonical_retailer_id`?

**S:** Needed stable IDs that survive re-clustering.
**T:** Avoid the "ID shuffles on every run" anti-pattern.
**A:**
- Master record selected by data-quality priority within each cluster
- `canonical_retailer_id = sha256(master_address_hash || normalized_banner)`
- Stable across re-runs as long as the master record's address + banner don't change
- When they do change, old ID retired with `valid_to`, new ID created — SCD2 captures it
**R:** ID churn rate <0.5% across re-runs; downstream FK joins stay stable.

> 💡 **Remember:** Trap — surrogate keys that reshuffle every run and break downstream FKs. Say — "Deterministic `sha256(master_address_hash || normalized_banner)` so the ID is stable across re-runs; when the master attributes genuinely change, SCD2 retires the old ID rather than reshuffling — ID churn under 0.5%."

#### Q. Late-arriving dimensions — what's your pattern?

**S:** Sales facts often land before the retailer's canonical record is resolved.
**T:** Don't drop the fact, don't fudge attribution.
**A:**
- Facts with unresolved FK land in `staging.sales_unresolved` with the raw retailer fields
- Daily reprocessing job re-attempts ER on the raw fields; resolved facts move to silver
- After 30 days unresolved, route to manual review queue (rare — <0.5%)
- Bitemporal columns let us correct attribution retroactively without losing the "as-known-at" view
**R:** ~99% of unresolved facts close within 24h; ~99.7% within 7 days.

> 💡 **Remember:** Trap — dropping facts whose dimension hasn't resolved yet, or fudging the attribution. Say — "Facts with an unresolved FK land in `staging.sales_unresolved`, a daily job re-attempts ER, and bitemporal columns let me correct attribution retroactively — ~99% close within 24h, never dropped."

#### Q. Bitemporal model — when is it worth the cost?

**S:** Asked when full bitemporal modeling pays off.
**T:** Be specific, not dogmatic.
**A:**
- Worth it when stakeholders ask "what did we know at time T" — audit + regulator questions
- Worth it when corrections backdate (e.g. fixed retailer banner attribution retroactively)
- NOT worth it for transactional facts that don't get corrected — SCD2 on dimensions is enough
- Cost is mostly query complexity, not storage — train consumers on the two timelines
**R:** Applied bitemporal only to `canonical_retailer` and `canonical_product`; sales stays SCD0/append.

> 💡 **Remember:** Trap — applying full bitemporal everywhere as dogma when it just adds query complexity. Say — "Worth it only where stakeholders ask 'what did we know at time T' or corrections backdate — I applied it to canonical_retailer and canonical_product, but sales stays append-only because facts don't get corrected."

#### Q. SCD2 with `attributes_hash` — what's the trick?

**S:** Detecting which attributes changed on a retailer without column-by-column comparison.
**T:** Make change detection cheap and consistent.
**A:**
- `attributes_hash = sha256(concat_ws('|', sorted SCD2-tracked columns))` computed in silver
- MERGE compares hash only: `WHEN MATCHED AND tgt.attributes_hash != src.attributes_hash THEN`
- Hash computation pinned in a single PySpark helper so it's identical on both sides of MERGE
- Excluded columns documented per-table (e.g. `last_seen_ts` shouldn't trigger a new version)
**R:** SCD2 MERGE is 4× faster than column-list comparison; zero false-positive new versions.

> 💡 **Remember:** Trap — hashing volatile columns like `last_seen_ts` so every run spawns a false new version. Say — "`sha256(concat_ws('|', sorted tracked columns))` computed in one shared helper on both sides, comparing the hash only and excluding volatile columns — 4× faster than column-by-column, zero false-positive versions."

---

## 6. Scenario questions

### Scenario 1: Late-arriving data — events up to 7 days late

**S:** Daily feature table keyed by user_id, events can arrive 7 days late.
**T:** Design correct pipeline.
**A:**
- Partition by `event_date` (not ingest_date)
- Daily job reprocesses last 8 days, MERGEs into feature table
- Events > 8 days late → quarantine + alert
- Cost: 7× the daily compute
**R:** Late events land in correct partition. Re-runs idempotent.

> 💡 **Remember:** Trap — partitioning by ingest_date so late events land in the wrong bucket. Say — "Partition by `event_date`, reprocess a trailing 8-day window with a MERGE, quarantine anything later — late events land in the correct partition and re-runs stay idempotent."

### Scenario 2: Schema drift — upstream silently adds columns

**S:** Distributor CSV gains 4 columns this week.
**T:** Handle without breaking, don't silently lose data.
**A:**
- Bronze: Auto Loader `schemaEvolutionMode=addNewColumns` + alert
- Silver: requires explicit column mapping — new columns logged, not auto-promoted
- Gold: strict, PR-required
- Renames/drops: enable column mapping mode (`'name'`)
**R:** Schema drift is a Slack alert, not a P1.

> 💡 **Remember:** Trap — letting bronze auto-promote new columns all the way into strict gold. Say — "Bronze absorbs new columns with `addNewColumns` plus an alert, silver requires explicit mapping, gold stays strict and PR-required — drift is a Slack alert, not a P1."

### Scenario 3: Stream-stream join with different lateness

**S:** Two Kinesis streams, payments lag verifications by up to 1 hour.
**T:** Join safely.
**A:**
- Watermark on both sides (5 min on fast side, 1 hour on slow)
- Time-range condition in the join (`p.ts BETWEEN v.ts AND v.ts + 1 hour`)
- RocksDB state store if memory bound
- Output mode: append (update not supported)
**R:** Joins clear state correctly; no OOM.

> 💡 **Remember:** Trap — one watermark for both streams and no time-range bound, so state grows forever. Say — "Watermark each side independently (5 min fast, 1 hour slow), bound the join with a time-range condition, RocksDB if memory-bound — state clears and no OOM."

### Scenario 4: Idempotency — daily job ran twice

**S:** On-call accidentally re-runs today's ETL.
**T:** Don't double-count.
**A:**
- MERGE with deterministic key everywhere
- `INSERT OVERWRITE PARTITION` for partition-overwrite cases
- Run-ID token on side-effect tasks (webhooks, refresh triggers)
- No `INSERT INTO` in production code (CI lint blocks it)
**R:** Re-runs always produce same end state.

> 💡 **Remember:** Trap — `INSERT INTO` in production code that double-counts on a re-run. Say — "MERGE on a deterministic key everywhere, `INSERT OVERWRITE PARTITION` for overwrites, run-ID tokens on side effects, and a CI lint that blocks `INSERT INTO` — a double-run produces the same end state."

### Scenario 5: Backfilling a new column over 6 months

**S:** Added `promo_flag` to `silver.canonical_sales`. Need to backfill.
**T:** Populate historical rows without rewriting the world.
**A:**
- Small tables: `ALTER TABLE ADD COLUMN` + `UPDATE WHERE date BETWEEN ...`
- Large tables: partitioned MERGE loop, one day at a time, parallel clusters
- Or: recompute silver from bronze for the window (most idempotent)
**R:** 6 months backfilled in ~8 days running 10 days in parallel.

> 💡 **Remember:** Trap — a single `UPDATE` rewriting the whole giant table at once. Say — "Small tables, `ALTER ADD COLUMN` plus targeted `UPDATE`; large tables, a partitioned MERGE loop one day at a time in parallel, or just recompute silver from bronze for the window since that's most idempotent."

### Scenario 6: SLA breach at 3 AM

**S:** Pager fires, daily Workflow DAG missed 8 AM SLA.
**T:** Recover the day's pipeline.
**A:**
- Triage: Workflow UI — which task failed/slow?
- Spark UI: stage outlier? skew?
- Compare to baseline (input volume, schema changes, recent deploys)
- Quick fix → root cause later → blameless post-mortem
**R:** Make the SLA first. Investigate properly in the morning.

> 💡 **Remember:** Trap — root-causing at 3 AM while the SLA keeps slipping. Say — "Make the SLA first with a quick fix — triage in the Workflow UI, check Spark UI for skew, compare to baseline — then do the real root-cause and a blameless post-mortem in the morning."

### Scenario 7: Reconciliation gap with ERP

**S:** Daily POS revenue ≠ ERP revenue by 0.8%.
**T:** Find the source of the gap.
**A:**
- Verify timezone + cutoff alignment first
- Drill down by source / product / transaction type
- Sample 5 transactions, trace POS → bronze → silver → gold
- Common causes: tax, currency timing, returns netting, promo discount
**R:** Caught a McLane double-counting issue, $340k revenue overstatement prevented.

> 💡 **Remember:** Trap — assuming a code bug before ruling out timezone/cutoff misalignment. Say — "Check timezone and cutoff alignment first, then drill by source/product/type and trace 5 sample transactions end-to-end — that's how I caught McLane double-counting and a $340k overstatement."

### Scenario 8: Adding a column to a streaming table

**S:** Streaming job writes to silver Delta. Need to add a column.
**T:** Don't break the stream.
**A:**
1. `query.stop()` — graceful stop
2. `ALTER TABLE ADD COLUMN`
3. Update streaming code to populate new column
4. Restart from existing checkpoint (with `mergeSchema=true`)
**R:** Zero data loss across the change.

> 💡 **Remember:** Trap — killing the stream hard or restarting with a fresh checkpoint and losing position. Say — "Graceful `query.stop()`, `ALTER ADD COLUMN`, update the code, restart from the existing checkpoint with `mergeSchema=true` — zero data loss across the change."

### Scenario 9: Cost spike investigation

**S:** Databricks bill jumped 40% last month.
**T:** Find what changed.
**A:** Three queries on `system.billing.usage`:
1. Top jobs by DBU consumption last 30 days
2. Per-job recent vs prior delta
3. Idle warehouse time

Common culprits: warehouse without auto-stop, Photon downgrade from a UDF, shuffle blowup from a new join, failed jobs retrying in a loop.

**R:** Found a SQL warehouse running 24/7 — $30k/mo saved.

> 💡 **Remember:** Trap — guessing at the cause instead of querying the billing tables. Say — "Three queries on `system.billing.usage` — top jobs by DBU, per-job recent-vs-prior delta, idle warehouse time — usual culprits are a warehouse with no auto-stop or a Photon downgrade; I found a 24/7 warehouse worth $30k/mo."

### Scenario 10: Late-arriving dimension

**S:** Sales arrive but matching canonical_retailer record lands a day later.
**T:** Don't drop the fact, don't lose attribution.
**A:**
- Hold facts with unresolved FK in `staging.sales_unresolved`
- Reprocess daily — FK-resolved facts move to `silver.canonical_sales`
- Long-tail unresolved → manual review queue
**R:** ~99% of gaps close within 24h.

> 💡 **Remember:** Trap — dropping the fact or guessing the attribution when the dimension is late. Say — "Hold the fact in `staging.sales_unresolved`, reprocess daily so FK-resolved facts flow into silver, long-tail unresolved to a manual review queue — ~99% of gaps close within 24h."

### Scenario 11: Dedup at scale

**S:** Bronze is at-least-once. Need exactly-once in silver.
**T:** Pick the dedup pattern.
**A:**
- Streaming: `withWatermark + dropDuplicates(["event_id"])`
- Batch / MERGE: `WHEN NOT MATCHED THEN INSERT` on stable key
- Window-based "keep latest": `row_number().over(...).where(rn = 1)`
**R:** MERGE pattern is canonical at silver.

> 💡 **Remember:** Trap — picking a dedup pattern that doesn't fit the workload (streaming vs batch vs keep-latest). Say — "Streaming, `withWatermark + dropDuplicates(event_id)`; batch, `WHEN NOT MATCHED THEN INSERT` on a stable key; keep-latest, `row_number().over(...).where(rn=1)` — MERGE is the canonical one at silver."

---

## 7. Dmitry-specific questions

### Q1. Hard trade-off you made on platform architecture?

**S:** Building the Retail Sales Intelligence Platform.
**T:** Decide: ship canonical entities incrementally or wait for the full platform.
**A:** Picked incremental — address normalization first, then ER, then sales, then gold. Dual-wrote with legacy reports for a quarter.
**R:** Trade Marketing got value in week 6, not month 6. The 5× time-to-value won.

> 💡 **Remember:** Trap — describing a trade-off with no clear cost on the other side. Say — "I chose incremental over a big-bang platform and dual-wrote with legacy for a quarter — Trade Marketing got value in week 6, not month 6, a 5× time-to-value win."

### Q2. Your approach to Terraform standardization?

**S:** Provisioning across multiple environments and teams.
**T:** Avoid divergence and toil.
**A:** Module-per-concern (not per-team). OPA policy gates in CI. Nightly drift detection. Weekly office hours to get adoption.
**R:** EU expansion took 4 hours of new Terraform because 80% was module reuse.

> 💡 **Remember:** Trap — organizing modules per team, which guarantees divergence. Say — "Module-per-concern not per-team, OPA gates in CI, nightly drift detection, office hours for adoption — EU expansion took 4 hours of new Terraform because 80% was module reuse."

### Q3. Self-service infra engineers actually use?

**S:** Engineers were filing tickets for routine infra.
**T:** Make self-service easier than ticket-filing.
**A:** Happy path is one command (`databricks bundle init`). Escape hatches to direct Terraform when templates don't fit. Platform team uses the platform.
**R:** Routine-infra tickets dropped 70% in two quarters.

> 💡 **Remember:** Trap — building a self-service platform with no escape hatch, so people route around it. Say — "Make the happy path one command and easier than filing a ticket, but keep an escape hatch to raw Terraform — and the platform team uses the platform; routine tickets dropped 70%."

### Q4. Hybrid cloud — when does it make sense?

**S:** Common architecture question.
**T:** Honest answer.
**A:** Three cases: regulatory residency, data gravity from PB legacy, cost arbitrage on steady-state. Trap is treating hybrid as permanent.
**R:** Honest: Juul is cloud-native; I haven't operated a primary hybrid. I'd want 30 days to understand yours before proposing changes.

> 💡 **Remember:** Trap — overclaiming hybrid experience you don't have. Say — "Hybrid makes sense for regulatory residency, data gravity from PB legacy, or steady-state cost arbitrage — but Juul is cloud-native, so I'd be honest I haven't run a primary hybrid and want 30 days to learn yours first."

### Q5. Biggest cost optimization?

**S:** Databricks bill hit $190k/mo, no one could explain why.
**T:** Make cost visible and actionable.
**A:** Mandatory cluster tags via cluster policies. Daily ETL from `system.billing.usage` into Looker dashboard. Reviewed monthly with engineering leads.
**R:** ~$60k/mo savings in 4 months. ~$720k annualized. Same mechanism as your $5M — make cost visible to people who can change behavior.

> 💡 **Remember:** Trap — describing cost wins as a one-off cleanup instead of a repeatable mechanism. Say — "Mandatory cluster tags, a daily `system.billing.usage` dashboard reviewed monthly with engineering leads — make cost visible to people who can change behavior; that was ~$720k annualized."

### Q6. How do you build psychological safety?

**S:** Mentoring engineers across a team.
**T:** Create an environment where juniors flag concerns.
**A:** Public credit, private feedback. Stretch projects with real ownership. I'm wrong publicly — own my mistakes in post-mortems.
**R:** Juniors ask "dumb" questions in public Slack now, not DM. That's the signal.

> 💡 **Remember:** Trap — describing safety as a vibe with no observable signal. Say — "Public credit, private feedback, owning my own mistakes in post-mortems — and the signal it worked is juniors now ask 'dumb' questions in public Slack instead of DMs."

### Q7. Pushed back on a senior stakeholder?

**S:** Trade Marketing director wanted real-time PII access.
**T:** Push back without breaking the relationship.
**A:** Booked a 30-min meeting (not email). Walked through consent terms + state AG settlement language. Offered two paths that WOULD meet her need legally.
**R:** She picked aggregate option, sponsored consent-flow change 6 months later. Came with options, not "no."

> 💡 **Remember:** Trap — pushing back with a flat "no" over email. Say — "I booked a 30-min meeting, walked through the consent and settlement language, and offered two paths that WOULD meet her need legally — came with options, not 'no'; she picked the aggregate one."

### Q8. Reliability — your incident-response practice?

**S:** Need to keep production reliable with a small team.
**T:** Layer pre-, during-, and post-incident discipline.
**A:** SLOs + dashboard catch ~70% before breach. Runbook-first culture (top 20 incidents documented). Blameless post-mortems within 5 business days.
**R:** Incident recurrence rate 22% → 8% YoY. Recurrence is the real failure metric.

> 💡 **Remember:** Trap — bragging about MTTR while the same incidents keep recurring. Say — "SLOs catch ~70% before breach, runbooks for the top 20 incidents, blameless post-mortems within 5 days — and I track recurrence as the real failure metric, which went 22% to 8% YoY."

### Q9. Shipped good rather than waited for perfect?

**S:** Same Retail Sales Intelligence rollout.
**T:** Decide ship-cadence.
**A:** Strangler approach — incremental cutover by layer. Each layer in prod for weeks before the next started. Dual-write with legacy for a quarter.
**R:** Trade Marketing got value 3-4 months earlier than the big-bang plan. I'll ship 95% with monitoring on the gap, not wait for 99%.

> 💡 **Remember:** Trap — sounding like "ship fast" means cutting corners with no guardrail. Say — "Strangler approach, each layer in prod for weeks before the next, dual-write with legacy for a quarter — I'll ship 95% with monitoring on the gap, not wait for 99%."

### Q10. How would you onboard into a regulated banking environment?

**S:** Coming from CPG to banking.
**T:** Be useful fast without faking expertise.
**A:**
- 30 days: read, listen, pair. Read consent orders, sit with compliance, shadow audits
- 60 days: write a "what's different here" doc for myself, get it red-penned by a peer
- 90 days: first architecture doc I sign my name to
**R:** Expect rookie mistakes early on banking-specific stuff. Rather make them in front of a team that says "here's the right way" than fake it. Bring the discipline that carried at Juul (audit trail, object lock, OPA gates) — substrate transfers even if the regs don't.

> 💡 **Remember:** Trap — faking domain expertise you don't have yet in a regulated space. Say — "30 days read and pair, 60 days a 'what's different here' doc red-penned by a peer, 90 days my first signed architecture doc — I'll bring the Juul discipline (audit trail, object lock, OPA) even while learning the regs."

### Q11. Time you chose the boring solution?

**S:** Team wanted to introduce a graph database for retailer-distributor relationships.
**T:** Decide: shiny tool or boring option.
**A:** Mapped the actual queries — all were 2-3 hop joins, not deep traversals. Stayed with Delta tables + recursive CTEs. Saved the operational cost of a new system. Set a tripwire to reopen if traversals exceeded 5 hops.
**R:** Queries hit p95 = 1.2s on Delta; never reopened.

> 💡 **Remember:** Trap — adopting a shiny tool before mapping the actual query patterns. Say — "I mapped the queries — all 2-3 hop joins, not deep traversals — so I stayed on Delta with recursive CTEs and set a tripwire to reopen past 5 hops; p95 hit 1.2s and it never reopened."

### Q12. How do you make trade-offs explicit when stakeholders push back?

**S:** Finance wanted real-time trade-spend dashboards; the source data lands once a day.
**T:** Push back without sounding defensive.
**A:**
- Wrote a one-pager: "real-time" options cost $X/mo for Y minutes saved; daily is $Z and matches source cadence
- Showed three concrete designs (intraday micro-batch, streaming, daily with hourly delta refresh)
- Recommended the hourly delta — 90% of value at 10% of cost
- Made the cost-vs-latency curve visible so the call was theirs, not mine
**R:** Finance picked hourly delta; we shipped in 6 weeks instead of 6 months. They cited the framing in a leadership readout.

> 💡 **Remember:** Trap — arguing your preferred option instead of making the cost-vs-latency curve theirs to decide. Say — "I wrote a one-pager with three concrete designs and the cost-vs-latency curve, recommended hourly delta at 90% of value for 10% of cost — made the call theirs, and they shipped in 6 weeks instead of 6 months."

---

## 8. Behavioral

### Q. Disagreement with a stakeholder?

**S:** Trade Marketing director wanted 99% ER precision target (saw a vendor pitch).
**T:** Push back honestly.
**A:** Walked through the math: 99% means 1,240 wrong merges among 124k retailers — worse than the system we replaced. Committed to 98% with documented measurement.
**R:** Shipped at 98.4%. He used the number on his board readout.

> 💡 **Remember:** Trap — caving to an arbitrary vanity metric a vendor pitched. Say — "I walked through the math — 99% precision means 1,240 wrong merges among 124k retailers, worse than what we replaced — and committed to 98% with documented measurement; shipped 98.4% and he used it on his board deck."

### Q. Mentoring story?

**S:** L3 engineer on my team, hadn't owned a sub-module end-to-end.
**T:** Real stretch project without risking the timeline.
**A:** Owned the ER validation harness — known-pair management, precision/recall reporting. I paired weekly for month 1, code review only after.
**R:** Presented at engineering all-hands. Promoted to L4 next cycle.

> 💡 **Remember:** Trap — telling a mentoring story where you actually did the work yourself. Say — "I gave the L3 real ownership of the ER validation harness, paired weekly for month 1 then dropped to code review only — they presented it at all-hands and got promoted to L4."

### Q. Let a junior take a risk?

**S:** L3 engineer wanted to own the streaming join refactor — high-visibility piece.
**T:** Give real ownership without setting them up to fail.
**A:** Paired on the design doc; let them present it to the team. Code review with explicit "what could go wrong in prod" prompts. Shadow deploy — their job ran alongside the existing one for two weeks.
**R:** Ship was clean; engineer promoted to L4 the next cycle.

> 💡 **Remember:** Trap — "letting them take a risk" with no safety net, setting them up to fail. Say — "Real ownership of the streaming-join refactor but de-risked — paired on the design, had them present it, code review with 'what breaks in prod' prompts, and a two-week shadow deploy; the ship was clean."

### Q. Hardest decision?

**S:** Q3 2025 — ER precision plateaued at ~92% on initial rule weights.
**T:** Invest more in tuning or ship at 92%?
**A:** Spent 2 weeks tuning weights + adding a second blocking pass. Manual review of 500 borderline pairs to calibrate thresholds.
**R:** Hit 98.4% precision. Right call but only because we invested in the eval harness alongside.

> 💡 **Remember:** Trap — framing it as "I just tuned harder" without the measurement that made it safe. Say — "Precision plateaued at 92%, so I spent 2 weeks on weights and a second blocking pass, calibrating against 500 manually-reviewed borderline pairs — hit 98.4%, but only because the eval harness made it measurable."

### Q. Time you handled a blocker?

**S:** Source team hadn't started on Kinesis publishing — blocked on their own roadmap.
**T:** Unblock without political escalation.
**A:** 1:1 with their tech lead first. Wrote a 1-pager (cost of delay, narrowed scope, offered to embed an engineer). Took to both directors.
**R:** Picked it up next sprint. I embedded one engineer for a week. Pipeline launched on time.

> 💡 **Remember:** Trap — escalating to directors before trying to unblock peer-to-peer. Say — "1:1 with their tech lead first, then a one-pager on cost-of-delay with a narrowed scope and an offer to embed an engineer — I embedded one for a week and the pipeline launched on time, no political escalation."

---

## 9. Code snippets cheat sheet

### SCD2 MERGE

```python
target = DeltaTable.forName(spark, "silver.canonical_retailer")

# Close out changed current rows
(target.alias("tgt")
    .merge(incoming.alias("src"),
           "tgt.canonical_retailer_id = src.canonical_retailer_id AND tgt.is_current = true")
    .whenMatchedUpdate(
        condition = "tgt.attributes_hash != src.attributes_hash",
        set = {"valid_to": "current_timestamp()", "is_current": "false"})
    .execute())

# Insert new versions for changed + brand-new
(spark.read.table("silver.canonical_retailer").alias("current")
    .join(incoming.alias("src"), "canonical_retailer_id", "right")
    .where("current.is_current IS NULL OR current.attributes_hash != src.attributes_hash")
    .select("src.*",
            F.current_timestamp().alias("valid_from"),
            F.lit("9999-12-31").cast("timestamp").alias("valid_to"),
            F.lit(True).alias("is_current"))
    .write.mode("append").saveAsTable("silver.canonical_retailer"))
```

### Streaming foreachBatch idempotent MERGE

```python
def upsert(batch_df, batch_id):
    target = DeltaTable.forName(spark, "silver.pos_events")
    (target.alias("tgt")
        .merge(batch_df.alias("src"), "tgt.event_id = src.event_id")
        .whenMatchedUpdate(
            condition = "src._ingest_ts > tgt._ingest_ts",
            set = {c: f"src.{c}" for c in batch_df.columns})
        .whenNotMatchedInsertAll()
        .execute())

(stream_df
    .withWatermark("event_ts", "5 minutes")
    .dropDuplicates(["event_id"])
    .writeStream
    .foreachBatch(upsert)
    .option("checkpointLocation", "s3://.../checkpoints/")
    .trigger(processingTime="30 seconds")
    .start())
```

### Skew fix — salting

```python
N = 20
salted_big = big.withColumn("salt", (F.hash("state_code") % F.lit(N)).cast("int"))
salted_small = (small
    .withColumn("salt_arr", F.array([F.lit(i) for i in range(N)]))
    .withColumn("salt", F.explode("salt_arr"))
    .drop("salt_arr"))
joined = salted_big.join(salted_small, ["state_code", "salt"]).drop("salt")
```

### Late-data reprocessing window

```python
from datetime import date, timedelta

for offset in range(8):  # 7-day late budget + buffer
    d = date.today() - timedelta(days=offset)
    features = (events.where(F.col("event_date") == d)
                      .groupBy("user_id", "event_date").agg(...))
    (DeltaTable.forName(spark, "gold.user_features_daily").alias("tgt")
        .merge(features.alias("src"),
               "tgt.user_id = src.user_id AND tgt.event_date = src.event_date")
        .whenMatchedUpdateAll().whenNotMatchedInsertAll().execute())
```

### Window dedup — keep latest

```python
w = Window.partitionBy("event_id").orderBy(F.col("_ingest_ts").desc())
deduped = (df.withColumn("rn", F.row_number().over(w))
             .where("rn = 1").drop("rn"))
```

### dbt incremental model (gold layer)

```sql
{{ config(
    materialized='incremental',
    unique_key=['promo_id', 'product_id', 'date'],
    incremental_strategy='merge'
) }}

select ...
from {{ ref('canonical_sales') }} s
join {{ ref('promo_calendar') }} p on ...
{% if is_incremental() %}
  where s.sale_date >= (select max(date) - interval 7 day from {{ this }})
{% endif %}
```

### Time-travel rollback

```sql
DESCRIBE HISTORY silver.canonical_retailer;
RESTORE TABLE silver.canonical_retailer TO VERSION AS OF 2034;
```

### MERGE WITH SCHEMA EVOLUTION

```sql
MERGE WITH SCHEMA EVOLUTION
INTO silver.canonical_retailer tgt
USING staged src ON tgt.canonical_retailer_id = src.canonical_retailer_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
```

---

## 10. Closing + flashcards

### Q. First 30/60/90 days?

**S:** Joining as Senior DE leading new Lakehouse.
**T:** Be useful fast without overstepping.
**A:**
- 30 — understand: read docs + Terraform + source overviews
- 60 — propose: architecture doc, circulate
- 90 — execute: ship Terraform-managed dev infra + one reference pipeline
**R:** By day 90, infrastructure exists + one pipeline runs + migration plan committed.

> 💡 **Remember:** Trap — promising to ship big in week 1, which signals you'll overstep before understanding the system. Say — "30 days understand (docs, Terraform, sources), 60 days propose a circulated architecture doc, 90 days execute — Terraform-managed dev infra plus one reference pipeline running."

### Q. Your questions for us?

1. "Biggest blocker the existing team has hit?"
2. "How does data engineering interact with security and compliance?"
3. "What does success at 6 and 12 months look like?"
4. "Why is this role open — backfill or new?"
5. "First project I'd own?"
6. "On-call expectations?"

> 💡 **Remember:** Trap — asking only logistics (PTO, hours) or nothing at all, which reads as low engagement. Say — "What's the biggest blocker the existing team has hit, and what does success at 6 and 12 months look like for whoever owns this role?"

### Quick-reference table

One-breath answers for the highest-leverage questions.

| Q | One-breath answer |
|---|---|
| Tell me about a project | Retail Sales Intelligence at Juul. Q1 2025–Q1 2026. Address norm + deterministic ER + product master + promo lift mart. **247k → 124k retailers, ±15-20% → 2%, $1.2M recovery, 98.4% ER precision.** |
| Why Databricks | Single platform for SQL/Python/streaming. UC for governance + lineage. Delta MERGE for SCD2/bitemporal. |
| Architecture | SFTP → S3 → Step Function → Workflows DAG → bronze → silver canonicals → gold dbt marts → Looker. CloudWatch + PagerDuty. |
| Orchestration | Workflows for DBX-internal DAG. Step Functions for per-file AWS ingest. Lambda for stateless hops. CloudWatch for AWS alarms. |
| Auto Loader config | `cloudFiles` + file notification mode + `schemaEvolutionMode=addNewColumns` + `rescuedDataColumn`. p95 = 4 min per feed. |
| DLT vs Workflows | DLT for declarative medallion; hand-rolled for custom MERGE + GraphFrames + Lambda callbacks. |
| Liquid clustering keys | Match filter selectivity: `(sale_date, retailer_id, product_id)`. Looker p95: 14s → 3s. |
| Delta CDF | `enableChangeDataFeed=true` on silver; dbt incrementals read `table_changes(...)`. ~60% rebuild reduction. |
| S3 layout | One bucket per env, prefix-per-feed, Object Lock 7y on bronze, KMS CMK per env. ~35% cost cut. |
| UC trust pattern | Storage credential = IAM role + external ID; no `s3:*`, separate from instance profile. |
| USPS Lambda | Reserved concurrency=10, DynamoDB cache (85% hit), exp backoff + DLQ. $510/mo vs $3.4k. |
| Step Fn vs Lambda chain | SF for branching/retries/visible state; Lambda chain for stateless 2-step hops. |
| Watermark sizing | Measure p99 lateness, set watermark to p99 + buffer. Route truly-late to separate batch. |
| RocksDB switch | When state exceeds ~8GB sustained; checkpoints on S3, state on local NVMe. |
| OOM handling | Almost always skew in disguise. Spark UI → identify outlier task → salt join key + drop AQE skew threshold. |
| Driver OOM | `.collect()`, `.toPandas()`, big broadcast hint. Fix at source — write to Delta. Cap `spark.driver.maxResultSize=512m`. |
| Executor OOM exit codes | 137 = cgroup OOMKiller; "Container killed by YARN" = container exceeded. Don't bump memory before checking skew. |
| Skew detection | Spark UI Stage → Summary Metrics → if Max is 10× Median = strong skew. Sort tasks by input size to find hot key. |
| Skew fix recipe | AQE threshold → salt → re-cluster. 4h → 9 min after full recipe. |
| AQE skew threshold gotcha | Default `skewedPartitionFactor=5` AND `skewedPartitionThresholdInBytes=256MB` — BOTH required. Lower factor to 3 for known-skewed workloads. |
| Salt vs broadcast vs filter-rejoin | Salt = both sides large + skewed key. Broadcast = small side <200MB. Filter-rejoin = one mega-key, isolate + union. |
| Multi-key skew | Hash composite first, then salt. Re-check tails after first fix. |
| Skewed aggregation | Two-stage: pre-aggregate with salt → final aggregation un-salted. AQE doesn't auto-fix aggregation skew. |
| Spill | Bump shuffle partitions, AQE on, avoid `collect_list` on high-cardinality. 4TB → 60GB. |
| Spill metrics | Spill (Memory) = serialized bytes before disk. Spill (Disk) = actually written. High ratio = good compression. |
| Shuffle partitions math | `total_shuffle_bytes / 128MB = optimal`. ~1TB → 8000 partitions. Default 200 way too low for modern workloads. |
| AutoOptimizeShuffle | Variable-size shuffle workloads. Skip for hand-tuned jobs — AOS sometimes overshoots. |
| AQE | Post-shuffle: coalesce partitions, switch to broadcast, split skewed partitions. |
| Photon memory | Shrinks on-heap by 25-50%; bump `spark.executor.memoryOverhead` if mixing Python UDFs. |
| Streaming OOM | State store growth, not data skew. Switch to RocksDB, tighten watermark. |
| GC pressure | "GC Time" >10% of task time = trouble. >85% heap utilization sustained = OOM incoming. |
| **OOM 6-step playbook** | (1) Driver vs executor (2) Spark UI failed stage (3) Skew? jump to skew playbook (4) Bump shuffle partitions (5) Bump `memoryOverhead` 10→25% (6) Bigger instance / fewer cores. **Order matters — bumping memory before fixing layout wastes money.** |
| **Skew order of operations** | (1) Filter skewed values if possible (2) Skew hints (3) AQE `skewedPartitionFactor=3` — ONE LINE (4) Broadcast if small side fits (5) Salt — LAST because code change. |
| **Spill 4-step playbook** | (1) Check skew FIRST (2) Bump `spark.sql.shuffle.partitions` to `total_shuffle_bytes/128MB` (3) Verify AQE coalesce on (4) Then memory. 4TB spill → 60GB without touching memory. |
| **First move on OOM page** | Do NOT bump memory. Open Spark UI, find outlier task. Outlier = skew. Uniform = real memory pressure. |
| **Slow job triage 5-step** | (1) `system.workflow.job_runs` baseline (2) Spark UI slowest stage (3) Task summary metrics (4) `DESCRIBE HISTORY` for recent layout changes (5) Input data shape (new feed?). |
| **Sizing new cluster** | 10% sample on 2 workers → math partitions (`shuffle_bytes/128MB`) → math workers (`headroom 50%`) → scale linearly. |
| **Slow MERGE playbook** | (1) `EXPLAIN FORMATTED` — verify partition pruning (2) `WHEN MATCHED AND attributes_hash differ` (3) Broadcast source if small (4) Cluster on join key. 12 min → 90 sec. |
| **Reproduce prod OOM in dev** | Pull exact failed partition + match memory-per-core ratio + heap dumps on + `EXPLAIN FORMATTED` to verify same plan. |
| **Prevent OOM proactively** | Cluster policies + lint rules (`collect`, `toPandas`) + `maxResultSize=512m` + CI sample runs + liquid clustering on hot tables. |
| Photon | On by default. Off for Python-UDF-heavy. Always measure with `system.billing.usage`. |
| Cost win | Mandatory tags + `system.billing.usage` Looker dashboard. $190k → $130k/mo (~$720k/yr). |
| Retry default | Max 2, 5 min exp backoff, no retry on timeout, idempotency required. |
| dbt vs GE split | dbt owns gold (logic), GE owns silver+bronze (DQ profile). |
| Deterministic IDs | `sha256(master_address_hash || normalized_banner)`. <0.5% ID churn across re-runs. |
| Reconciliation | Daily + at right grain + capture the gap in audit log. Caught $340k overstatement. |
| ER approach | Deterministic only — block, rule-score (Jaro-Winkler + exact), threshold, connected components. No ML. |

### Pre-interview checklist

- [ ] Memorize four numbers: **247k → 124k, ±15-20% → 2%, $1.2M, 98.4%**
- [ ] Sketch the architecture diagram (5 boxes) in 30 seconds
- [ ] Be ready to talk about hybrid even though Juul is cloud-native — be honest
- [ ] One sentence for Dmitry: "Pragmatic over perfect. I make trade-offs explicit, ship 95% with monitoring on the gap, mentor by being wrong publicly."
- [ ] Camera/lighting/water/phone silent

### Post-interview

- [ ] Thank-you email within 4 hours
- [ ] Reference one specific topic discussed
- [ ] Log every question asked (next round is likely SAS deep-dive)

---

## 11. Architecture walkthrough + extended Q&A (ingest → bronze → silver → gold)

> Added 2026-05-28. Same anchor (Juul Retail Sales Intelligence Platform). Follows one file end-to-end, then answers the deep follow-ups. **The three areas interviewers push hardest: (11.10/11.18 atomicity/idempotency), (ER + SCD2 — be ready to whiteboard the MERGE, see 11.x), (why two orchestrators — reason about the right tool, don't just name tools, see 11.y).**

### 11.0 The example file — follow one feed end to end

A distributor (Southern Glazer's = **SGWS**, the largest US alcohol/beverage distributor) drops a daily **depletion** feed via SFTP at ~2 AM:

```
sftp://transfer.juul.com/southern_glazers/incoming/SGWS_depletions_2026-05-27.csv
```

```csv
account_name,account_addr,city,st,zip,product_desc,upc,cases,unit_price,invoice_dt
"JOE'S WINE & SPIRITS","123 main st ste 4","austin","tx","78701","TITO'S 750ML",619947000014,12,8.50,2026-05-26
"Joes Wine and Spirits","123 Main Street #4","Austin","TX","78701-2204","Titos Vodka 750",619947000014,3,8.50,2026-05-26
```

Two rows = **same physical store, different spelling**; product name non-standard. That messiness is the entire reason SILVER (entity resolution) exists. The journey:

1. **INGEST (AWS)** — Transfer Family SFTP → S3 → S3 event → Step Functions → Lambda hop (validate) → land.
2. **BRONZE (Databricks)** — Auto Loader incrementally ingests raw, all-string, + provenance. 7-year object lock, never altered.
3. **SILVER** — normalize address (libpostal + USPS), deterministic ER → `canonical_retailer` (one ID for both rows), `canonical_product` (UPC → Tito's > Vodka > 750ml), `canonical_sales` (15 cases, $127.50, one fact from two dirty rows). SCD2 + bitemporal.
4. **GOLD** — dbt marts: `sales_by_retailer_daily`, `promo_performance_daily` (DiD lift), `trade_spend_reconciliation` ("did our $2M promo spend drive sales?").

**One-sentence model:** Raw distributor files land event-by-event in AWS (bronze, locked 7y), a daily 4 AM Databricks DAG resolves the same store/product across 12 inconsistent sources into canonical time-versioned facts (silver), then rolls them into business-ready marts (gold).

---

### 11.1 Terraform resource types + the SFTP→S3 to-and-fro

#### Q. Are `aws_s3_bucket_object_lock_configuration`, `aws_cloudwatch_metric_alarm`, `aws_transfer_server` etc. built into Terraform by default?

**Context:** Terraform core knows *nothing* about AWS. Those resource types come from the **AWS provider** — a plugin you declare and Terraform downloads. "Built in" = built into the provider, not Terraform itself.

**Answer:**
- You declare the provider once; `terraform init` downloads it:
  ```hcl
  terraform { required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } } }
  provider "aws" { region = "us-east-1" }
  ```
- Every `aws_*` resource type (`aws_transfer_server`, `aws_s3_bucket`, `aws_cloudwatch_metric_alarm`, ...) is defined by that provider — it maps the HCL block to the underlying AWS API calls. ~1,400 resource types in the AWS provider.
- Databricks has its own provider (`databricks/databricks`) for workspaces, UC catalogs, jobs, etc. So one Terraform repo, two providers.
- They are **not** invented per-project — you use the canonical resource types; you only write the config values.

> 💡 **Remember:** Trap — saying those resource types are "built into Terraform" — they're built into the provider. Say — "Terraform core knows nothing about AWS; every `aws_*` type comes from the AWS provider plugin you declare and `terraform init` downloads — one repo, two providers, AWS and Databricks."

#### Q. Where is the SFTP feed coming from and where does it land — the full to-and-fro?

**Context:** AWS Transfer Family is a *managed SFTP front door* that writes straight to S3. No EC2/SFTP server to patch.

**Answer — the flow:**
```
Distributor's system (SGWS)
   |  opens SFTP connection, key-auth
   v
aws_transfer_server "sftp"   <- the managed endpoint (transfer.juul.com)
   - identity_provider_type = SERVICE_MANAGED  -> AWS stores the user + SSH public key (no LDAP/AD)
   - domain = "S3"                              -> writes land DIRECTLY in S3 (not EFS)
   - protocols = ["SFTP"]                       -> SFTP only
   - logging_role = aws_iam_role...arn          -> IAM role letting it write CloudWatch logs
   |
   v  each SFTP user is mapped to a home dir = an S3 prefix
s3://juul-ingest-bronze/raw/southern_glazers/2026/05/27/SGWS_depletions_*.csv
   |
   v  S3 object-created (PutObject) event
Step Functions (per-file) -> Lambda hop (validate) -> manifest row + alarms
```

- **To:** the distributor pushes (writes) the file *to* the Transfer Family endpoint. We don't pull.
- **From → landing:** Transfer Family routes that write *into* the mapped S3 prefix. The SFTP user's "home directory" is literally an S3 path, so an upload to `incoming/` becomes an S3 object under `raw/southern_glazers/`.
- **logging_role** is the to-and-fro for *observability*: Transfer Family assumes that IAM role to emit connection/transfer logs to CloudWatch (who connected, bytes transferred, success/fail).
- 12 distributors = 12 SFTP users, each mapped to its own prefix → clean per-source isolation.

**Anchor:** 12 distributor feeds + CRM + Nielsen TDLinx, all landing under one bronze bucket, partitioned by source + date. No SFTP server to manage = one less thing to patch (the kind of pragmatism Dmitry likes).

> 💡 **Remember:** Trap — thinking we pull files or run an SFTP server we patch. Say — "The distributor pushes to a managed Transfer Family endpoint whose home directory IS an S3 prefix, so the upload lands directly in `raw/<source>/` — no EC2 SFTP box to patch, 12 users mapped to 12 prefixes."

---

### 11.2 Data-arrival log / manifest — does Auto Loader use it?

#### Q. Are we keeping a data-arrival / file log / manifest anywhere? Does Auto Loader use it?

**Context:** Two *separate* tracking systems exist and people conflate them: (a) **our** business manifest, (b) **Auto Loader's** internal checkpoint. They do not share state.

**Answer:**
- **Our manifest** (a Delta table, e.g. `ops.ingest_manifest`): the Lambda hop writes one row per file — `source, filename, s3_path, arrival_ts, row_estimate, schema_ok, status (landed/quarantined)`. This drives the `FileArrivalGap` metric, the "did SGWS arrive?" check, SLA dashboards, and reprocessing. It is **our** operational record.
- **Auto Loader's checkpoint** (separate, in cloud storage): an internal RocksDB/log that records exactly which file paths it has already ingested, so it never reprocesses. **Auto Loader does NOT read our manifest** — it tracks files independently via its checkpoint (and, in notification mode, an SQS queue).
- So: two independent skip mechanisms. Our manifest answers "did the business get the file + is it valid"; the checkpoint answers "has the ingestion engine already consumed this path."

**Why both:** the manifest gives auditable, queryable lineage ("prove SGWS sent this on this date" — pairs with the 7y object lock); the checkpoint gives exactly-once mechanics. Don't try to make Auto Loader depend on your manifest — keep them decoupled.

> 💡 **Remember:** Trap — conflating our business manifest with Auto Loader's internal checkpoint, or trying to wire one into the other. Say — "Two independent skip mechanisms — our Delta manifest answers 'did the business get a valid file' for audit, the checkpoint answers 'has the engine consumed this path' for exactly-once; keep them decoupled."

---

### 11.3 Auto Loader discovery modes + does N files trigger N cluster starts?

#### Q. Explain directory-listing vs file-notification mode. If many files land, does it start the Databricks cluster multiple times?

**Context:** Auto Loader (`cloudFiles`) finds new files two ways; the choice is about scale, not correctness.

**Answer — two modes:**
- **Directory listing (default):** each run, lists the S3 prefix, diffs against the checkpoint → new files. Simple, no extra infra. Slows down at very high file counts (listing millions of objects is expensive).
- **File notification mode (`cloudFiles.useNotifications=true`):** Auto Loader provisions its *own* SNS topic + SQS queue; S3 pushes new-object events to SQS; Auto Loader drains the queue. No listing. Scales to millions of files. Use at high volume.

> 💡 **Remember:** Trap — using directory listing at high file counts where listing millions of objects gets slow and expensive. Say — "Directory listing is simple and fine at low volume; notification mode provisions its own SNS+SQS so S3 pushes events instead of listing — that's what scales to millions of files."

#### Q. Does multiple files = multiple cluster triggers?

**No — and this is the key point.** Auto Loader does not start a cluster per file. The cluster is started by **the job/DAG** (the 4 AM Databricks Workflow, or a continuous stream). Once running, Auto Loader picks up *all* new files in **one** run and processes them in parallel across the cluster:
- 50 files land → next scheduled run ingests all 50 in one batch (`trigger(availableNow=True)` = "process everything new, then stop").
- 1 file or 50 files → **same single cluster start.** File count drives task parallelism, not cluster count.
- This is why Auto Loader handling "50 files at once" is the *normal* case, not an edge case.

**Caveat (small-files problem):** 50 tiny files → 50 tiny Delta files → slow downstream reads. Fix with `OPTIMIZE` compaction (see 11.7).

**Anchor:** Juul's 12 feeds + CRM + Nielsen all arrive overnight; the single 4 AM DAG run sweeps the lot in one cluster lifecycle. We used notification mode once file counts crossed ~10k/day on a high-frequency feed.

> 💡 **Remember:** Trap — thinking N files spin up N clusters. Say — "The job/DAG starts the cluster, not Auto Loader — one run ingests all 50 new files in parallel across the one cluster; file count drives task parallelism, not cluster count."

---

### 11.4 If Lambda didn't validate the file, does Auto Loader still run?

#### Q. If the Lambda hop fails validation, would Auto Loader run on it?

**Context:** This is a design decision about coupling. The clean architecture **decouples** validation from ingestion using **separate S3 prefixes**.

**Answer:**
- The Lambda hop validates, then **routes**: valid → `raw/<source>/...` (the path Auto Loader watches); invalid → `quarantine/<source>/...` (a path Auto Loader does **not** watch).
- So an invalid file **never reaches Auto Loader's watched prefix** → it won't be ingested. It sits in quarantine with a `status=quarantined` manifest row + a PagerDuty alarm.
- If instead you (wrongly) let everything land in one prefix and relied on Auto Loader to filter, a malformed file *would* be picked up and you'd be cleaning bad rows out of bronze — worse.
- The raw file is preserved (object lock), so after the distributor resends or you fix the contract, you move/reprocess it.

**Senior framing:** "fail fast, fail cheap, fail isolated" — reject at the Lambda (200ms, sub-cent) before a cluster ever spins, and keep bad data physically out of the ingestion path via prefix separation.

> 💡 **Remember:** Trap — landing everything in one prefix and relying on Auto Loader to filter bad files, so garbage gets into bronze. Say — "The Lambda routes valid files to the watched `raw/` prefix and invalid ones to an unwatched `quarantine/` prefix — fail fast, fail cheap, fail isolated, before a cluster ever spins."

---

### 11.5 Where is Auto Loader's checkpoint stored?

#### Q. Where does the checkpoint live?

**Answer:**
- Wherever you point `checkpointLocation` — **cloud object storage** (S3 / DBFS / a Unity Catalog volume), e.g. `s3://juul-checkpoints/bronze_sgws/`. It is durable and external to the cluster, so it survives cluster termination.
- Contents: (1) the **source** sub-dir — which input files have been processed (RocksDB), (2) the **offsets/commits** — streaming progress, (3) **schema** location if set.
- One checkpoint **per stream/table**. Never share a checkpoint across two streams, and never hand-edit it.
- Delete the checkpoint = Auto Loader forgets everything → reprocesses all files (dangerous; only do intentionally for a full rebuild).

**Gotcha:** if you change the query in incompatible ways, you may need a new checkpoint. Treat checkpoint location as part of the table's identity.

> 💡 **Remember:** Trap — sharing a checkpoint across streams, hand-editing it, or casually deleting it and reprocessing everything. Say — "It lives in durable cloud storage at `checkpointLocation` so it survives cluster death — one per stream, never shared or hand-edited; deleting it makes Auto Loader forget and reprocess all files."

---

### 11.6 What is SGWS?

**Southern Glazer's Wine & Spirits** — the largest alcohol/beverage **distributor** in the US (three-tier system: supplier → distributor → retailer). In the anchor story it's one of the 12 distributor depletion feeds. "Depletion" = cases sold *out* of the distributor to retail accounts (the signal a supplier like Juul actually cares about, vs shipments *into* the distributor).

---

### 11.7 Small-files problem — detail (STAR)

#### Q. Tell me about a small-files problem you hit and fixed.

**Context:** Delta/Parquet tables are made of immutable data files. Performance depends on having *few, large* files (~128 MB–1 GB), not *many, tiny* ones. Tiny files hurt four ways: per-file open/read overhead, ~1 task per file (task explosion), `_delta_log` metadata bloat → slow planning, and driver pressure during listing/planning.

**S:** Silver builds on the bronze SGWS-style feeds started creeping slower over a few weeks; nothing in the logic had changed.
**T:** Find why a stable transform was degrading and stop the bleed.
**A — how I found it:**
- **Spark UI** showed thousands of tiny tasks on the read stage and a long planning phase before any work started — the signature of too many small files.
- **`DESCRIBE DETAIL bronze.sgws`** confirmed it: `numFiles` had ballooned into the tens of thousands at sub-MB each, from per-file streaming ingest (50 distributor files/night, short triggers).
- Root cause: every micro-batch wrote its own small file; nobody was compacting.
**A — how I fixed it:**
- Scheduled nightly **`OPTIMIZE`** (bin-packing into ~1 GB files), with **`ZORDER BY (retailer_id, product_id)`** on the hot tables so it compacted *and* co-located.
- Turned on **Optimized Writes / Auto Optimize** so new writes land larger.
- Moved the hottest tables to **liquid clustering** so I stopped hand-tuning.
**R:** Silver build time dropped materially and `_delta_log` planning shrank; the regression stopped recurring because compaction was now scheduled, not manual. Lesson: small-files is a *layout* problem — fix it with OPTIMIZE/clustering, not by adding compute.

> 💡 **Remember:** Trap — throwing compute at a slowdown that's actually too many tiny files. Say — "Thousands of tiny tasks and a long planning phase is the small-files signature — confirm with `DESCRIBE DETAIL` numFiles, fix with scheduled OPTIMIZE plus optimized writes or liquid clustering; it's a layout problem, not a compute one."

---

### 11.8 / 11.9 Commit failure in a micro-batch — does it stop the next ones? How is the file split into micro-batches?

#### Q. If a micro-batch commit fails, does it stop the next micro-batch or all of them? And how do we split into micro-batches — is it like dbt's microbatch where you assign an event-time?

**Context:** Critical to separate **Spark Structured Streaming micro-batches** (mechanical, size-based) from **dbt's `microbatch` incremental strategy** (logical, event-time-based). They are unrelated despite the shared word.

**Answer — Spark Structured Streaming (what Auto Loader uses):**
- A **micro-batch** = the chunk of new input processed in one trigger. Splitting is controlled by **`cloudFiles.maxBytesPerTrigger`** / **`maxFilesPerTrigger`** — e.g. "≤10 GB or ≤1000 files per batch." This is **size/count-based**, not event-time-based.
- Each micro-batch is **atomic and sequential**: batch N must commit (write to `_delta_log` + advance the checkpoint offset) before batch N+1 starts.
- **If batch N's commit fails → the stream stops.** Subsequent batches do **not** run (it's sequential). On restart, the checkpoint shows batch N did **not** commit → it **reprocesses batch N from its recorded start offset**, then continues to N+1. So you resume from the failed batch, not from zero, and not mid-batch.
- Within a micro-batch, *task* failures retry automatically (4×); only an unrecoverable batch failure stops the stream.

**So for "100 GB file fails at 50%":** if it's processed as one batch, the failed batch reprocesses the whole batch (atomic — nothing committed). If you set `maxBytesPerTrigger=10GB`, it's ~10 batches; batches 1–5 already committed, batch 6 fails → restart reprocesses batch 6 onward. **Already-committed batches are not redone** (checkpoint advanced past them), and because the failed batch committed nothing, **no duplicates.**

**dbt microbatch (different thing):** dbt's `microbatch` strategy splits a model by an **`event_time` column** into time slices (e.g. per-day) and processes/backfills each slice independently/idempotently. That's a *logical* batching of a transform for incremental builds and backfills — used in the gold dbt layer — not the streaming ingest mechanism. Don't conflate them in the interview; calling that out explicitly is a senior signal.

> 💡 **Remember:** Trap — conflating Spark size-based micro-batches with dbt's event-time `microbatch`, or thinking a failed batch reprocesses from zero or leaves dupes. Say — "Spark batches are atomic and sequential by `maxBytesPerTrigger` — a failed batch stops the stream and reprocesses only that batch from its start offset; committed batches aren't redone and the failed one committed nothing, so no dupes."

---

### 11.10 / 11.18 Why atomic commit + checkpoint? (the #1 hardest area: atomicity / idempotency)

#### Q. Why do we need atomic commit + checkpoint — reprocess the file, no partial state, no dupes?

**Context:** This is the idempotency story. "Idempotent" = running the same load twice produces the same result as running it once. Without it, every retry risks partial or duplicated data — fatal for trade-spend numbers.

**Answer — the two guarantees and why each is needed:**
- **Atomic commit (Delta ACID):** a write either fully commits to the `_delta_log` or it's as if it never happened. Readers never see half a file. So a crash at 50% leaves **zero** committed rows from that batch → **no partial state.**
- **Checkpoint:** records exactly which files/offsets are already committed. On rerun, already-done work is skipped → **no reprocessing** of committed data; the failed unit reprocesses cleanly.
- **Together → no dupes:** because the failed attempt committed nothing (atomic) *and* the checkpoint knows what's done, the rerun reprocesses only the uncommitted unit exactly once. Atomic alone could still double-write on retry without the checkpoint; checkpoint alone can't prevent partial writes without atomicity. You need **both.**

**The anti-pattern to name:** a naive `df.write.append()` inside a Python loop that writes as it iterates — a crash leaves 50% of rows committed, and the retry appends them *again* → both partial *and* duplicated. Delta + Auto Loader checkpoints exist precisely to avoid this.

**Whiteboard line:** "Unit of work = the file/batch. Atomic commit makes the unit all-or-nothing; the checkpoint makes the pipeline resume-from-uncommitted; the combination is exactly-once. That's why a mid-file failure is a non-event — reprocess the unit, no partial, no dupes."

**Anchor:** daily reconciliation MERGE that died 4h in — because writes were atomic and the checkpoint tracked completed batches, the rerun produced byte-identical output, no manual dedupe. Reconciliation caught $340k overstatement *because* the numbers were trustworthy, which depends on this idempotency.

> 💡 **Remember:** Trap — thinking atomicity alone (or the checkpoint alone) gives exactly-once. Say — "You need both — atomic commit makes the unit all-or-nothing so there's no partial state, the checkpoint makes the pipeline resume from uncommitted; together a mid-file failure is a non-event, reprocess the unit, no partial, no dupes."

---

### 11.11 Late-arriving data — separate pipeline?

#### Q. Is there a separate pipeline for late-arriving data?

**Context:** "Late" has two distinct meanings; neither usually needs a *separate* pipeline — the same pipeline is built to absorb it.

**Answer:**
- **Late facts** (SGWS sends Tuesday's depletions on Thursday): the daily silver build does a **MERGE** keyed on natural keys into the correct date partition, not a blind append. Re-running affected gold marts picks up the correction. **Bitemporal** transaction-time captures *when we learned it*, so a restatement is auditable, not a silent overwrite. Same pipeline, idempotent MERGE.
- **Late/early-arriving dimensions** (a sale references a retailer not yet in `canonical_retailer`): route the fact to an **inferred/unknown member** (`RTL_UNKNOWN`) with the raw attributes stashed, then **backfill the FK** when the dimension arrives. Never drop the fact.
- **Streaming late events:** **watermarks** (see 11.12) bound how long to keep window state before finalizing.
- A genuinely separate **backfill/reprocessing** job exists for *bulk* historical restatements (a distributor resends 6 months) — that uses dbt microbatch by `event_time` to rebuild affected slices idempotently. But routine lateness is handled inline.

**Senior framing:** design the *normal* pipeline to be correct under lateness (MERGE + bitemporal + unknown-member) rather than bolting on a fragile side-pipeline.

> 💡 **Remember:** Trap — bolting on a fragile separate side-pipeline for every kind of lateness. Say — "Build the normal pipeline correct under lateness — idempotent MERGE into the right date partition with bitemporal for auditable restatements, route to an unknown-member when a dimension is late; only bulk historical restatements get a dedicated backfill."

---

### 11.12 Concept primers — watermark, checkpoint, bucketing, salting, AQE, shuffle partitions, partitioning/pruning

Tight definitions to drop verbatim:

- **Checkpoint:** durable record (cloud storage) of a stream's progress — which files/offsets are committed + state — enabling exactly-once resume after failure. One per stream.
- **Watermark:** in streaming, a moving threshold = `max(event_time) − allowedLateness`. Tells Spark "events older than this won't arrive" so it can finalize windows and **drop old state** (bounds memory). E.g. `withWatermark("event_time", "2 hours")` = wait up to 2h for late events, then close the window. Too tight → drop legit late data; too loose → state grows → OOM.
- **Shuffle:** redistributing data across the cluster by key (for joins/groupBy/distinct) — data moves over the network between stages. Expensive; the thing you minimize.
- **Shuffle partitions** (`spark.sql.shuffle.partitions`): how many partitions the shuffle produces. Default 200 is too low for big data. Rule: `total_shuffle_bytes / 128MB`. ~1 TB shuffle → ~8000.
- **AQE (Adaptive Query Execution):** Spark 3+ re-plans *after* seeing real shuffle stats. Three moves: (1) **coalesce** tiny post-shuffle partitions, (2) **switch** sort-merge → broadcast if a side turns out small, (3) **skew-join split** a giant partition. Mostly "on and forget"; the one knob is `skewedPartitionFactor`.
- **Coalesce vs repartition:** `coalesce(n)` reduces partitions **without a shuffle** (cheap, can cause uneven sizes); `repartition(n)` does a **full shuffle** to n even partitions (costly, even). Use coalesce to shrink, repartition to rebalance/grow.
- **Partitioning (storage):** physically split a table into directories by a **low-cardinality** column, usually date → `…/sales_date=2026-05-27/`.
- **Partition pruning:** a `WHERE sales_date='2026-05-27'` reads only that directory, skipping the rest. Verify with `EXPLAIN FORMATTED` (look for `PartitionFilters`). Breaks if you wrap the partition column in a function (`WHERE year(sales_date)=...` → no pruning).
- **Bucketing:** pre-hash rows into a fixed number of buckets by a column at write time so repeated joins on that column avoid re-shuffling. Less used on Databricks now — **Liquid Clustering / Z-ORDER** generally preferred.
- **Z-ORDER:** multi-dimensional clustering — co-locates rows with similar values in high-cardinality, frequently-filtered columns (`retailer_id`, `product_id`) into the same files → better data skipping.
- **Salting:** fix for skew — append a random/hashed suffix to a hot join key (`key || '_' || (rand()*N)::int`) so one heavy key spreads across N tasks instead of crushing one. Replicate the other side ×N. Last resort (code change) after AQE skew-join.
- **Liquid Clustering:** modern replacement for partitioning + Z-ORDER; you declare `CLUSTER BY` and Databricks auto-manages file layout/sizing as data and query patterns change.

---

### 11.13 How do you decide cluster / memory size — the actual numbers? (STAR)

#### Q. A new heavy job needs a cluster — how did you size it instead of guessing?

**Context:** Sizing by vibes either wastes money (too big) or OOMs/spills (too small). The senior method is sample → measure → math → verify. Pragmatic + measurable — Dmitry's lane.

**S:** Standing up the silver `canonical_sales` MERGE; no prior runtime data to size against.
**T:** Pick worker count + instance type defensibly, not "let's try a big cluster."
**A — how I approached it:**
1. **Sample run:** ran on ~10% of data on a small 2-worker cluster; read **Spark UI** for total shuffle bytes + input size + spill.
2. **Partition math:** `shuffle_partitions = total_shuffle_bytes / 128MB` → ~2000 for the full set.
3. **Worker math:** target ~128 MB per core-task; `cores ≈ shuffle_partitions` processed in waves; `workers = cores / cores_per_worker` + ~50% headroom.
4. **Memory ratio:** checked "Spill (Disk)" — heavy spill but *not* skewed → bumped shuffle partitions before touching memory.
5. **Scaled linearly + verified:** 10% on 2 workers → ~8 workers for full; ran, re-checked the UI, adjusted.
6. **Autoscaling** (min/max) so off-peak it scales down.
**R:** 8 workers + AQE held the full MERGE at ~9 min with minimal spill, autoscaled down off-peak. **Order of levers (memorize):** layout → shuffle partitions → AQE → `memoryOverhead` 10%→25% → bigger instance. *Bumping memory before fixing layout wastes money* — say this to Dmitry. If pushed on the exact arithmetic, fall back to "sample-then-measure," which is the defensible part.

> 💡 **Remember:** Trap — sizing by vibes and grabbing a big cluster instead of sampling and measuring. Say — "Sample on 10%, read shuffle bytes from the UI, partition math `shuffle_bytes/128MB`, worker math with 50% headroom, scale linearly — and the order of levers is layout before memory, because bumping memory first wastes money."

---

### 11.14 How do you actually *find* skew in the data? (STAR)

#### Q. "One retailer has 90% of rows → one task gets it all" — how did you detect and fix skew?

**Context:** Skew = uneven key distribution → one task does most of the work while others idle. You find it in the Spark UI (symptom) *and* by profiling the data (root cause).

**S:** A silver join stage had one task running ~100× longer than the rest; the job dragged and occasionally OOM'd on that task.
**T:** Confirm it was skew (not memory misconfig) and spread the hot key.
**A — how I found it:**
- **Spark UI → Task summary metrics** on the slow stage: **max** task duration/shuffle-read was wildly above the **median/75th pct** (one task 100× longer). Outlier task = skew; uniform-but-slow would have meant real memory pressure.
- **Profiled the key to confirm root cause:**
  ```sql
  SELECT join_key, COUNT(*) c FROM table GROUP BY join_key ORDER BY c DESC LIMIT 20;
  ```
  A handful of keys held a huge share. Also checked `approx_count_distinct` + **null counts** — NULL join keys all hash to one partition (classic *hidden* skew). Rule of thumb: top key > ~5–10% of rows, or max/median task ratio > 5×.
**A — how I fixed it (in order):**
- California retailers were ~4.7× the median partition; AQE's default 5× threshold didn't trigger → lowered **`spark.sql.adaptive.skewJoin.skewedPartitionFactor=3`** (one line) so AQE split it.
- A second hidden skew was NULL `upc` rows → routed them to an **unknown-product member** before the join.
- (Escalation ladder if those hadn't worked: filter the skewed value → skew hints → broadcast the small side → **salt** the key, last, since it's a code change.)
**R:** Stage went from one 100×-outlier task to balanced; runtime and the OOMs cleared. Lesson: prove skew in the UI first, fix data layout (AQE/unknown-member/salt) before ever bumping memory.

> 💡 **Remember:** Trap — missing hidden skew from NULL join keys, which all hash to one partition. Say — "Prove it in the UI (Max task 100× the median) AND profile the key with a `GROUP BY COUNT(*)` plus null counts — California was 4.7× so I lowered AQE to 3, and NULL upc rows went to an unknown-product member before the join."

---

### 11.15 A job that *should* be fast takes 4 hours — what does a senior do?

#### Q. A job that runs in minutes suddenly takes 4 hours — your move?

**Context:** Triage in order; don't randomly bump memory. (This is a real anchor — `gold.compliance_state_monthly` went 4× slower.)

**Answer — 5-step triage:**
1. **Baseline:** `system.workflow.job_runs` — when did it regress, by how much, did input volume change? (Rules out organic data growth.)
2. **Spark UI slowest stage:** find the bottleneck stage; is one task an outlier (skew) or all slow (resource/plan)?
3. **Task summary metrics:** max vs median → skew vs uniform.
4. **`DESCRIBE HISTORY <table>`:** recent layout change? (A bad `OPTIMIZE ZORDER` on wrong keys, a dropped partition, a vacuum.)
5. **Input shape:** new feed, schema change, a distributor 10×'d their file, broadcast side grew past threshold and started OOM-retrying.

**Then act** on the specific cause (recluster, fix Z-order keys, disable bad auto-broadcast, fix skew, bump shuffle partitions). **Senior part:** after the fix, **prevent recurrence** — add a runtime SLA alert (`system.workflow.job_runs` regression), a cluster policy, a CI sample run, and write the postmortem. "Fix the day, then harden against the class of failure."

**Anchor:** the 4× regression was a 2-week-old `OPTIMIZE ZORDER` on a low-value key that de-co-located the join. Reclustered on `(retailer_id, product_id)` + AQE tune → back to 9 min from 4h+. Added a job-runtime regression alarm so it can't silently creep again.

> 💡 **Remember:** Trap — fixing the day and walking away without hardening against the class of failure. Say — "5-step triage — baseline, slowest stage, task metrics, `DESCRIBE HISTORY`, input shape — found a 2-week-old bad Z-ORDER; reclustered to 9 min, then added a runtime-regression alarm so it can't silently creep again."

---

### 11.16 Driver vs worker OOM — which one? Can you move work off a bad worker?

#### Q. How do you tell if the driver or a worker is OOMing? Can you stop one worker and reassign its work?

**Context:** Two different OOMs, different fixes. And Spark already does the "reassign" for you — you don't manually move tasks.

**Answer — which is which:**
- **Driver OOM:** error in the **driver log**; triggered by `.collect()`, `.toPandas()`, huge broadcast estimate, or planning over millions of files. Symptom: job dies at result-collection or planning, not mid-stage. Fix: don't collect to driver, cap `spark.driver.maxResultSize`, disable bad auto-broadcast, bigger driver.
- **Executor/worker OOM:** error in an **executor log** / Spark UI shows **failed tasks on a stage**; triggered by skew, wide aggregation, oversized partitions. Fix: skew handling, more shuffle partitions, `memoryOverhead`, bigger workers.
- **First move on an OOM page:** open Spark UI, find the outlier task. Outlier = skew (worker). Driver log clean + executor failures = executor OOM.

**Can you stop one worker and reassign?**
- You don't do it manually — **Spark's fault tolerance does it.** If an executor dies, the driver **reschedules its tasks onto other live executors** automatically (lineage lets it recompute lost partitions). With autoscaling, a replacement node may spin up.
- What you *can* do: kill a pathological executor (it'll reschedule), enable **speculative execution** (`spark.speculation=true`) so a straggler task is **re-launched on another executor** and whichever finishes first wins — useful for a slow/bad node. But speculation can waste resources on genuine skew (re-running the same heavy task elsewhere doesn't help), so it's not a skew fix.
- You **cannot** "move half of one task's data" to another worker mid-flight — the unit is the partition. To spread a heavy partition you must **repartition/salt** so the *next* stage splits it.

**Anchor:** the November MERGE OOM was executor-side (Spark UI outlier task, driver clean) → skew, fixed by salting; not a memory misconfig. Speculation was off because the slowness was skew, not a bad node.

> 💡 **Remember:** Trap — claiming you'll manually move a task's data off a bad worker. Say — "Driver OOM is in the driver log from collecting/planning, executor OOM shows failed tasks on a stage; Spark already reschedules a dead executor's tasks and speculation re-launches a straggler — but you can't split a heavy partition mid-flight, you repartition or salt for the next stage."

---

### 11.17 More AQE + Coalesce

**Context primer (definitional — no STAR needed):**

**AQE (Adaptive Query Execution)** — re-optimizes at runtime using *actual* shuffle statistics (static cost estimates are often wrong on skewed/filtered real data). Default on (`spark.sql.adaptive.enabled=true`). Three runtime moves:
- **Coalesce post-shuffle partitions:** set `shuffle.partitions` high (say 2000) for safety; AQE merges the tiny ones back down so you don't pay for thousands of near-empty tasks.
- **Switch join strategy:** a planned sort-merge becomes a broadcast if, after filters, one side is actually small. Saves a shuffle.
- **Split skew joins:** a partition > `skewedPartitionFactor × median` (default 5) is split + the other side replicated. Tune down to 3 to trigger sooner.

**Coalesce vs repartition:** `coalesce(n)` reduces partitions **without a shuffle** (merges on same executors; cheap; can be uneven) — use to *shrink* (fewer output files). `repartition(n)` does a **full shuffle** to n **even** partitions (costly; balanced) — use to *grow parallelism* or *rebalance skew*. Rule: **coalesce to write fewer files; repartition to fix skew or grow parallelism.**

#### Q. (STAR) Where did AQE / coalesce actually save you?

**S:** A shuffle-heavy job was tuned to 2000 shuffle partitions for month-end volume, but on light days it left thousands of near-empty tasks (scheduling overhead dominated), and the gold marts were writing hundreds of small files.
**T:** Keep the high parallelism for big days without the overhead on small days, and stop the small-file output.
**A:** Left `shuffle.partitions=2000` but **relied on AQE coalesce** to merge tiny post-shuffle partitions automatically per run — high parallelism when the data's big, low overhead when it's small, no per-day retuning. Added **`coalesce(8)`** right before the final gold writes so each mart wrote a few large files, not hundreds of tiny ones.
**R:** Light-day overhead disappeared (AQE adapted the partition count to actual bytes) and the gold small-files problem cleared without a separate OPTIMIZE pass. Lesson: set partitions high + let AQE coalesce down; use plain `coalesce` only at the write boundary.

> 💡 **Remember:** Trap — confusing `coalesce` (no shuffle, to shrink/write fewer files) with `repartition` (full shuffle, to rebalance skew). Say — "Set shuffle partitions high and let AQE coalesce tiny ones down per run so I never retune by day, then a plain `coalesce(8)` only at the gold write boundary to stop hundreds of small files."

---

### 11.x What is bitemporal? (the SCD2 hardest area — whiteboard the MERGE)

#### Q. Explain bitemporal modeling.

**Context:** "Bitemporal" = tracking **two independent time axes** on every record. Required in regulated CPG finance for auditable restatements.

**Answer — the two axes:**
- **Valid time (business / effective time):** *when the fact was true in the real world.* "Joe's was at the old address Jan 2020 → Mar 2026." This is what plain **SCD2** captures (`valid_from` / `valid_to` / `is_current`).
- **Transaction time (system / knowledge time):** *when we recorded/learned it.* "We loaded these depletions on 2026-05-27; the corrected version on 2026-06-10."

**Bitemporal = both.** Each row carries `valid_from/valid_to` **and** `system_from/system_to`. This lets you answer two different questions:
- "What was true as-of date X?" (valid time) — historical accuracy for joins.
- "What did **we believe** as-of date X?" (transaction time) — reproduce a past report exactly, even after later corrections.

**Why it matters at Juul:** **trade-spend reconciliation + restatements.** A distributor restates last quarter's depletions in May. Bitemporality keeps **both** the original numbers (what the Q1 board deck showed) **and** the corrected numbers (what we know now) — neither overwrites the other. If finance paid a promo allowance on the original figures, you can prove exactly what was known at decision time *and* show the truth now. A plain overwrite (SCD1) destroys that audit trail = compliance failure.

**Whiteboard one-liner:** "SCD2 answers *when was it true*; bitemporal adds *when did we know it*. Restatements are the reason — you must reproduce 'what we believed then' and 'what's correct now' simultaneously."

**Relationship to SCD2 + ER (the merge whiteboard):**
1. **ER first** decides *what is one entity* — deterministic: normalize (libpostal+USPS address, banner name) → blocking key (zip) → rule-score (Jaro-Winkler + exact UPC) → threshold → connected components → one `canonical_*_id`. **No ML.**
2. **SCD2 then** versions that entity over time (close old row, insert new on attribute change) — dbt snapshot (`strategy='check'`, `check_cols=[...]`).
3. **Bitemporal** layers transaction-time on top for restatement auditability.

The MERGE: match on the deterministic `canonical_id`; `WHEN MATCHED AND attributes_hash differs` → expire old version (set `valid_to`, `is_current=false`) + insert new version; `WHEN NOT MATCHED` → insert. Deterministic IDs (`sha256(master_address_hash || normalized_banner)`) keep ID churn <0.5% across re-runs.

```sql
MERGE INTO canonical_retailer tgt
USING staged_retailer src
  ON tgt.retailer_id = src.retailer_id AND tgt.is_current
WHEN MATCHED AND tgt.attributes_hash <> src.attributes_hash THEN
  UPDATE SET tgt.valid_to = current_date(), tgt.is_current = false
WHEN NOT MATCHED THEN
  INSERT (retailer_id, name, normalized_address, attributes_hash,
          valid_from, valid_to, is_current)
  VALUES (src.retailer_id, src.name, src.normalized_address, src.attributes_hash,
          current_date(), DATE'9999-12-31', true);
-- a second pass inserts the NEW version row for the keys just expired
```

> 💡 **Remember:** Trap — describing bitemporal as just SCD2 with extra columns, or overwriting on a restatement and destroying the audit trail. Say — "Two axes — valid time is when it was true, transaction time is when we learned it; for restatements you must reproduce both 'what the Q1 board saw' and 'what's correct now,' which a plain SCD1 overwrite would destroy."

---

### 11.y Why two orchestrators? (the hardest area — reason about the right tool)

#### Q. Why Step Functions + Lambda AND Databricks Workflows — why not one?

**Context:** They solve two fundamentally different timing problems. Naming both tools isn't the answer; explaining *why each fits its job* is.

**Answer:**

| | Step Functions + Lambda | Databricks Workflows |
|---|---|---|
| Trigger | Event-driven (file lands) | Schedule (4 AM UTC daily) |
| Granularity | Per-file | Whole bronze→silver→gold DAG |
| Job | Ingest, validate, fail-fast | Transform, model, aggregate (Spark) |
| Latency | Seconds (reacts instantly) | Minutes–hours (batch) |
| Lives in | AWS | Databricks |

- You **can't** cleanly do per-file event reaction in a daily DAG (you'd be polling S3) — Step Functions reacts the instant a file lands, cheaply, per file.
- You **can't** cleanly do heavy Spark transformation in Step Functions — it's an orchestrator, not a compute engine.
- So: **AWS-native event layer** handles "a file arrived, is it valid, land it"; **Databricks** handles "now transform everything that landed." The handoff point is the **bronze table**.
- **Why not unify on Airflow?** You could, but you'd lose the native, cheap, instant S3-event reaction, and you'd run both file-shaped and Spark-shaped work through one scheduler ideal for neither. Right tool per job > one tool for all.

**Anchor:** at Juul, per-file ingest SLAs (a late distributor delays the whole 4 AM DAG + the morning Looker refresh) need event-driven reaction → Step Functions + the `FileArrivalGap` alarm; the transform DAG is a scheduled Databricks Workflow. Two orchestrators, each doing what it's best at.

> 💡 **Remember:** Trap — just naming both tools, or proposing to unify on Airflow without the cost. Say — "Two different timing problems — Step Functions reacts per-file the instant data lands, Databricks Workflows runs the heavy scheduled Spark DAG; the handoff is the bronze table, and unifying on Airflow would lose cheap instant S3-event reaction."

---

### 11.z More hard questions (STAR) — the curveballs

#### Q. A distributor silently changed their schema (added a column) and reconciliation broke. Walk me through it.

**Context:** Schema drift is the most common real-world ingest break. The answer shows detection → containment → fix → prevention.

**S:** One morning the SGWS silver build failed; the gold marts would have been wrong if it hadn't.
**T:** Restore the pipeline without losing data or shipping bad numbers.
**A — how I found it:** the **schema-diff CI test** (header vs registered contract) flagged a new `promo_code` column before Auto Loader even ran; the manifest row showed `schema_ok=false` → file routed to quarantine, PagerDuty paged.
**A — how I fixed it:** Auto Loader bronze runs in **`rescue` mode**, so even when one slips past CI, unexpected columns land in `_rescued_data` (nothing lost). I updated the converted schema to add `promo_code` (nullable, old rows null), re-ran from the preserved raw file (object lock = it was still there), reconciled, released.
**A — prevention:** added the column to the contract + told the distributor-onboarding runbook to expect drift; alert on non-empty `_rescued_data`.
**R:** Zero data loss, no bad gold numbers shipped, back in <1 hour. The combination — CI schema-diff (catch early) + rescue mode (never lose data) + object-locked raw (always replayable) — is why drift is a contained event, not an outage.

> 💡 **Remember:** Trap — only detecting drift, with no way to recover the lost columns or replay the file. Say — "Three layers — CI schema-diff catches it before Auto Loader even runs, rescue mode means nothing is lost if it slips through, object-locked raw means I can replay; updated the contract, re-ran, reconciled, back in under an hour."

#### Q. Finance says yesterday's revenue number is wrong. Production. Go.

**S:** A gold `sales_by_retailer_daily` total didn't match finance's expectation.
**T:** Determine fast whether it's a pipeline bug or a legitimate data change, with evidence.
**A:**
- **First, is the input complete?** Checked the **ingest manifest** — did all 12 feeds + CRM + Nielsen arrive? Found SGWS was flagged *late/partial* (the `FileArrivalGap` alarm had fired) → yesterday's gold ran missing one distributor.
- **Confirmed** by diffing the affected partition's per-source control totals against the prior day.
- **Fixed forward:** ingested the now-complete SGWS file, re-ran the affected silver+gold partitions (idempotent MERGE → no dupes), reconciled, notified finance with the corrected number + the cause.
- **Prevention:** made the gold build **fail (or visibly flag stale)** when a required source is missing, instead of silently producing a partial total.
**R:** Corrected within the morning, with a clear "missing-source, not a logic bug" explanation. The manifest + reconciliation audit trail is what let me answer "us vs real change" with evidence, not a guess.

> 💡 **Remember:** Trap — diving into pipeline logic before checking whether the input was even complete. Say — "First question is 'is the input complete' — checked the ingest manifest, SGWS was late/partial so gold ran missing a distributor; fixed forward with an idempotent re-run and made gold fail-loud on a missing required source."

#### Q. The 4 AM DAG missed its SLA and BI was empty at 8 AM. Triage.

**S:** Morning Looker dashboards were stale; the overnight DAG hadn't finished.
**T:** Restore freshness + prevent recurrence.
**A:**
- **`system.workflow.job_runs`** → which task hung and since when. It was the silver MERGE, running 4× normal.
- **Spark UI** → one outlier task (skew) on a day a single retailer had a data spike.
- **Immediate:** re-ran the stage with AQE skew-split threshold lowered; backfilled the marts so BI refreshed.
- **Root cause + prevent:** that retailer's spike was a recurring month-end pattern → added the skew handling permanently + a **runtime-regression alert** on the job so it pages before 8 AM, not after.
**R:** BI restored mid-morning; the SLA miss didn't recur because the skew was handled and alerting moved left. "Fix the morning, then harden the class of failure."

> 💡 **Remember:** Trap — just rerunning to restore BI and not moving the alert left so it can't recur. Say — "`job_runs` to find the hung task, Spark UI showed a month-end retailer spike causing skew — re-ran with the AQE skew-split, then added permanent skew handling and a runtime-regression alert that pages before 8 AM, not after."

#### Q. How do you guarantee exactly-once when the *source* might send the same file twice?

**Context:** Auto Loader dedups *file paths*, but a distributor re-sending the same data under a *new filename* defeats that. Idempotency must also live at the data layer.

**S:** A distributor occasionally re-sent a day's depletions under a new filename after a "correction."
**T:** Make sure a re-send corrects, never double-counts.
**A:** Two layers — (1) **Auto Loader checkpoint** dedups identical paths; (2) the silver load is an **idempotent MERGE on the natural key** (`retailer_id, product_id, sales_date, source`), so a re-send *updates* the existing fact rather than appending a duplicate. The bronze keeps both raw files (audit), but silver converges to one correct row.
**R:** Re-sends became self-correcting. The principle: file-level dedup (checkpoint) handles retries; **data-level MERGE on natural keys** handles re-sends — you need both for true exactly-once at the business grain.

> 💡 **Remember:** Trap — relying on Auto Loader's path-dedup alone, which a re-send under a new filename defeats. Say — "Two layers — the checkpoint dedups identical paths for retries, but an idempotent MERGE on the natural key handles a re-send under a new filename so it updates the fact instead of double-counting; you need both."

#### Q. When would you choose Lakehouse Federation (query in place) over ingesting a source?

**Context:** Not everything needs to be copied. Senior = knows when *not* to build a pipeline.

**Answer (Context→Answer):** Federate (query the source in place) when the data is **low-volume, infrequently used, or you need it temporarily** (e.g. a CRM table joined occasionally, or a source mid-migration) — it avoids building + maintaining an ingest path. **Ingest** when it's **hot, joined heavily, needs Delta performance/history, or the source can't take query load.** At Juul I federated a couple of reference tables that changed rarely and were queried weekly — not worth a pipeline — while the daily depletion facts were fully ingested. Right tool: don't build a pipeline for data you can cheaply read in place.

> 💡 **Remember:** Trap — building an ingest pipeline for everything, even rarely-queried reference data. Say — "Federate low-volume, infrequently-used, or mid-migration sources to skip an ingest path; ingest what's hot, joined heavily, or needs Delta history — I federated weekly reference tables while fully ingesting the daily depletion facts."

---

## 12. Platform positioning — "why Databricks vs X"

> Added 2026-05-28. The top-of-funnel "do you understand the platform, not just the syntax" questions. Asked in nearly every Databricks interview. Lead with **workload fit + the lakehouse thesis**, stay honest about where the other tool wins (honesty reads as senior, not disloyal).

### The one-paragraph thesis (say this first, then specialize)

> "A traditional **relational database / EDW** couples storage and compute, is built for one engine (SQL) on structured data, and you scale it as a fixed box. **Databricks is a lakehouse**: open data (Delta/Parquet) in your own object storage, decoupled elastic compute, and *one* copy of the data served to SQL, Python/Spark, streaming, and ML. So the real question is workload: if it's pure structured SQL BI on modest data, a warehouse is fine; once you have big/semi-structured data, Spark transforms, streaming, ML, or you want to avoid storage lock-in, the lakehouse wins. I don't pick by brand — I pick by workload."

### Q. Databricks vs a traditional relational database (Postgres/Oracle/SQL Server/MySQL)?

**Context:** This compares two different *categories*, not two products. The trap is treating them as interchangeable. Frame it as OLTP-vs-analytics + scale + workload breadth.

**Answer — the axes that matter:**
- **Workload:** an RDBMS is **OLTP-first** — row-store, indexes, single-row reads/writes, ACID transactions for an *application* (orders, inventory). Databricks is **OLAP/analytics** — columnar, scan-and-aggregate over billions of rows. You would not run a checkout flow on Databricks, and you would not run a 10 TB scan-aggregate on Postgres.
- **Scale + architecture:** RDBMS is one server (vertical scale; read replicas) with storage+compute coupled. Databricks is **distributed (MPP) + decoupled storage/compute** on object storage → scales horizontally + elastically to zero.
- **Data shape:** RDBMS = structured, schema-on-write. Databricks = structured **+ semi-structured + unstructured**, schema-on-read or evolve.
- **Engines:** RDBMS = SQL only. Databricks = SQL **+ Python/Scala/Spark + streaming + ML** on the *same* data.
- **Transactions:** RDBMS = rich multi-row OLTP transactions, enforced constraints/FKs. Delta = ACID at the **table/batch** grain (great for analytics writes), not row-level OLTP concurrency.
- **The relationship is complementary:** in our stack the **OLTP DB is a *source*** (we CDC out of it into the lakehouse). They sit at different ends of the pipeline, not in competition.
- **When the RDBMS wins:** transactional apps, single-row lookups, strict referential integrity, small data, sub-ms point queries. **When Databricks wins:** large-scale analytics, semi-structured data, Spark transforms, streaming, ML, avoiding storage lock-in.

**Anchor:** Juul's operational systems are the OLTP sources; the lakehouse is where their data is unified + analyzed. Databricks didn't replace a transactional DB — it replaced the *analytics* layer (the EDW) and reads *from* the OLTP via CDC.

> 💡 **Remember:** Trap — comparing them as rivals; they're different categories (OLTP app DB vs OLAP analytics platform). Say — "An RDBMS is OLTP — row-store, single-row ACID for the app; Databricks is OLAP — columnar, distributed, multi-engine on one copy. They're complementary: the OLTP DB is a *source* I CDC into the lakehouse, not a competitor."

### Q. Databricks vs Redshift?

**Context:** Now two *analytics* platforms (apples to apples-ish). Differentiate on architecture (lakehouse vs warehouse), openness, workload breadth, and the operational model — while crediting where Redshift is genuinely strong.

**Answer — the axes:**
- **Architecture:** Redshift is a **data warehouse** — you load data *into* Redshift's managed storage (proprietary format), historically provisioned nodes (storage+compute more coupled; RA3 + Spectrum decouple somewhat). Databricks is a **lakehouse** — data stays in **open Delta/Parquet in your own S3**, compute fully decoupled and elastic.
- **Openness / lock-in:** Redshift data lives in Redshift's format (Spectrum reads external, but the warehouse tables are proprietary). Delta is **open** — other engines (Spark, Trino, even Snowflake/Athena via connectors) can read the same files. No re-ingest to switch engines.
- **Workload breadth:** Redshift is **SQL-centric** (great BI warehouse). Databricks runs **SQL + Spark + streaming + ML** on one copy — you don't move data to a separate system to do data science.
- **Concurrency model:** Redshift = **WLM** rationing slots on a cluster (+ Concurrency Scaling). Databricks = **separate SQL warehouses + multi-cluster autoscale + serverless** → isolate workloads, scale out, scale to zero.
- **Data shape:** Redshift handles JSON via `SUPER`/PARTIQL but is structured-first; Databricks is natively comfortable with semi/unstructured.
- **Where Redshift genuinely wins:** if you're **all-in on AWS, pure SQL BI, structured data, want the tightest AWS-native integration (QuickSight, IAM, zero-ETL from Aurora)**, Redshift is simpler and excellent. Serverless Redshift is a strong low-ops BI warehouse.
- **Where Databricks wins:** mixed workloads (ETL + ML + streaming), large/semi-structured data, open-format / multi-cloud / no-lock-in, Spark-heavy transforms, unified governance (Unity Catalog) across all of it.

**Anchor:** the AWS-native migration doc (`INTERVIEW_QA_MIGRATION_REDSHIFT_GLUE_EMR.md`) is exactly this — we left Redshift+Glue+EMR for one lakehouse to unify SQL+Spark+ML, kill the WLM month-end queuing, and get open Delta on the same S3.

> 💡 **Remember:** Trap — bashing Redshift; credit where it wins (pure AWS SQL BI) to sound senior. Say — "Redshift is a warehouse — proprietary storage, SQL-centric, WLM rationing; Databricks is a lakehouse — open Delta in your S3, decoupled elastic compute, SQL+Spark+ML+streaming on one copy. Pick Redshift for pure AWS SQL BI; Databricks for mixed workloads + open format."

### Q. Databricks vs Snowflake?

**Context:** *The* most-asked competitive question right now — they've converged a lot, so a nuanced answer beats a fanboy one. Differentiate on origin/strength, architecture, openness, and workload, and be honest that they overlap heavily in 2025.

**Answer — the axes:**
- **Origin / center of gravity:** Snowflake grew from the **SQL data warehouse** (best-in-class SQL, near-zero-admin, fantastic BI/analyst UX). Databricks grew from **Spark / data engineering + ML** (the lakehouse, big-data transforms, data science). Each has raced into the other's territory (Snowflake added Snowpark/Python + Iceberg; Databricks added serverless SQL warehouses + a strong SQL UX).
- **Architecture:** both decouple storage/compute. Snowflake historically stored data in its **own managed (proprietary) format** (now embracing **Apache Iceberg** for openness). Databricks is **open Delta/Parquet in your own object storage** from the start.
- **Openness / control:** Databricks = your data in your cloud account, open format. Snowflake = data managed *by* Snowflake (more of a SaaS appliance feel) — simpler ops, less control. Iceberg tables narrow this gap.
- **Ops / simplicity:** Snowflake is famously **low-admin** (it "just works," auto-everything) — analysts love it. Databricks gives **more knobs** (cluster configs, Spark tuning) → more power, more to manage (cluster policies + serverless close the gap).
- **Workload:** for **pure SQL BI + analyst self-service**, Snowflake is hard to beat on simplicity. For **heavy data engineering, Spark, streaming, and ML on the same platform**, Databricks is stronger (one platform, no separate ML stack). Both now do "both," but their *defaults* reflect their roots.
- **ML / AI:** Databricks has the deeper native ML / MLflow / feature-store + (with Mosaic) LLM story; Snowflake's is newer (Cortex / Snowpark ML).
- **Honest take:** for a CPG analytics platform with **heavy Spark ETL + entity resolution + streaming + a roadmap toward ML**, Databricks fits the *whole* workload on one platform. If it were **purely SQL marts + BI with analyst self-service and minimal eng**, Snowflake's simplicity would be very compelling. I'd choose by workload mix + team skills + existing cloud, not religion.

**Anchor:** our workload (Spark-based ER, bitemporal SILVER, streaming hot path, ML on the roadmap) is squarely Databricks' strength — it's not a pure-SQL BI shop, so unifying ETL+streaming+ML on one lakehouse beat running a warehouse + a separate Spark/ML stack.

> 💡 **Remember:** Trap — picking a "winner"; they've converged, so a nuanced workload-based answer sounds senior. Say — "Snowflake's roots are best-in-class SQL warehouse + low-admin analyst UX; Databricks' are Spark + ML + the open lakehouse. Both do both now, but I pick by workload — heavy ETL/streaming/ML on one platform → Databricks; pure SQL BI with minimal eng → Snowflake."

### Q. So when would you NOT pick Databricks?

**Context:** Senior credibility = knowing your tool's anti-fit. Refusing to name one reads as a zealot.

**Answer:**
- **Pure OLTP / transactional app** → a relational DB (Postgres/Aurora). Databricks isn't for single-row, high-concurrency app writes.
- **Small, purely-structured SQL BI with a non-engineering team** → Snowflake or serverless Redshift (less to manage, analyst-friendly).
- **Sub-millisecond point lookups / a serving layer** → a key-value/OLTP store (DynamoDB, Redis), not a lakehouse.
- **Tiny data** (a few GB, simple reporting) → a lakehouse is overkill; a managed Postgres is cheaper + simpler.
- **Deep single-cloud-native lock-in is acceptable + you want zero data-eng** → the native warehouse may be simpler.
- **Where Databricks is right:** large/growing data, mixed SQL+Spark+streaming+ML, open format / multi-cloud, real data-engineering team. That's the Juul platform.

> 💡 **Remember:** Trap — claiming Databricks is best for everything (reads as a zealot). Say — "I wouldn't use it for OLTP, sub-ms serving, tiny data, or a pure-SQL BI shop with no engineers — it shines on large mixed SQL+Spark+streaming+ML workloads with open format, which is exactly the platform I built."

---

*Last updated: 2026-05-28*
