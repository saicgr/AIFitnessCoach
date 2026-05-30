# Senior Data Engineer — Migration Prep (Redshift + Glue/EMR → Databricks)
## STAR Format · Discovery → Diagnosis → Fix → Result · AWS-native sources

> **Companion to `INTERVIEW_QA.md` and `INTERVIEW_QA_MIGRATION.md`.** Same house style. Every "how did you" answer is **STAR** (Action = how I *found* it + *approached* it + *fixed* it). This file covers the **AWS-native** migration paths interviewers ask about most: **Redshift → Databricks** and **Glue/EMR → Databricks**. The Teradata doc covers the EDW path; this covers the AWS-data-platform path.
>
> **Cross-ref:** for "why Databricks vs Redshift / Snowflake / a relational DB," see `INTERVIEW_QA.md` §12 (Platform positioning); acronyms (DISTKEY, WLM, DPU, EMRFS…) in `INTERVIEW_QA_GLOSSARY.md`.
>
> **Anchor project:** **Juul Labs' Retail Sales Intelligence Platform** on an **AWS-native stack → Databricks Lakehouse**. Same company + domain as every other prep doc (12 distributor depletion feeds + CRM + Nielsen TDLinx → finance/supply-chain/category reporting). Here the source stack was **Redshift** (warehouse) + **Glue jobs / EMR Spark** (ETL) + **Glue Data Catalog** (metastore) + Athena consumers. 12-month, wave-based, dual-run, strangler-fig.
>
> **Coherence note:** anchor company is **Juul** in every doc; the **source system** is the only variable (Redshift/Glue/EMR here; Teradata in `INTERVIEW_QA_MIGRATION.md`). In one interview, tell **one** source-system story — pick whichever matches the JD. Don't mix them in the same conversation.
>
> **Numbers (customize to yours):** ~900 Redshift tables · ~25 TB · ~120 Glue jobs + ~40 EMR Spark apps · **$3.1M/yr → $1.3M/yr** (~58%) · **99.98% reconciliation parity** · batch window **5h → 1.4h** · **zero unplanned rollback**.
>
> **Why this is its own story (vs the EDW path):** the source is already AWS + already Spark (EMR/Glue *run* Spark). So this migration is less SQL-dialect translation, more: **DISTKEY/SORTKEY → clustering**, **Glue Catalog → Unity Catalog**, **Glue/EMR Spark → Databricks Spark + Workflows**, and killing operational pain (Glue cold starts, EMR cluster babysitting, Redshift concurrency limits). Lead with *that*.
>
> **For Dmitry** (Terraform 50+ teams, $5M savings, self-service): emphasize you replaced hand-managed EMR clusters + Glue job sprawl with **IaC + cluster policies + serverless**, cut cost, and made it self-service.

---

## Contents

1. [Why migrate off Redshift / Glue / EMR — the business case](#1-why-migrate-off-redshift--glue--emr)
2. [Redshift specifics: DISTKEY/SORTKEY, VACUUM, Spectrum, types](#2-redshift-specifics)
3. [Redshift data movement (UNLOAD) + reconciliation](#3-redshift-data-movement--reconciliation)
4. [Glue → Databricks (jobs, Data Catalog, crawlers, DynamicFrames)](#4-glue--databricks)
5. [EMR → Databricks (Spark apps, cluster ops, cost)](#5-emr--databricks)
6. [Performance parity (concurrency, WLM → warehouses)](#6-performance-parity)
7. [Governance: Glue Catalog + Lake Formation → Unity Catalog](#7-governance-glue-catalog--lake-formation--unity-catalog)
8. [Cutover, dual-run, rollback (AWS-native flavor)](#8-cutover-dual-run-rollback)
9. [Cost — the AWS-native savings story](#9-cost--the-aws-native-savings-story)
10. [Scenario / war-story questions](#10-scenario--war-story-questions)
11. [Hard rapid-fire + flashcards](#11-hard-rapid-fire--flashcards)

---

## 0. The architecture — before and after (sketch this in 60s)

**BEFORE — Juul AWS-native stack:**
```
12 distributor SFTP feeds + CRM + Nielsen TDLinx + OLTP
        |
        v
  ┌─ INGEST + ETL (AWS-native) ───────────────────┐
  │  S3 raw                                         │
  │   |-- GLUE jobs (~120, DynamicFrames,           │
  │   |     job bookmarks for incremental)          │
  │   |-- EMR Spark apps (~40, managed clusters,    │
  │   |     bootstrap actions, spot fleets)         │
  │  Glue Data Catalog (Hive metastore)             │
  │  Lake Formation (row/col grants) + IAM          │
  └──────────────────────────────────────────────────┘
        |                              |
        v                              v
  REDSHIFT (provisioned,         S3 data lake (Parquet)
   DISTKEY/SORTKEY, WLM,          + Athena / Spectrum
   concurrency-capped)
        |
        v
  Tableau · Looker · Athena · BI/SQL
```
Pain: Redshift WLM queuing at month-end, Glue cold starts + opaque DPU billing, EMR cluster babysitting + idle cost, 3 separate systems + 2 governance models.

**AFTER — Databricks Lakehouse (still on AWS, same S3):**
```
12 distributor feeds + CRM + Nielsen + OLTP (CDC)
        |  Auto Loader / COPY INTO (incremental, checkpointed)
        v
  ┌─ LAKEHOUSE (Databricks, Delta on the SAME S3) ─┐
  │  BRONZE raw  ->  SILVER canonical (SCD2)        │
  │              ->  GOLD marts                      │
  │  Transforms: ported EMR/Glue Spark + dbt        │
  │  Orchestration: Databricks Workflows            │
  │  Governance: Unity Catalog (was Glue Catalog +  │
  │              Lake Formation)                     │
  │  Compute: job clusters + SQL warehouses         │
  │           (multi-cluster), policies, autoscale  │
  └──────────────────────────────────────────────────┘
        |
        v
  Tableau · Looker · Databricks SQL  (via views/semantic layer)

  IaC: Terraform (aws + databricks providers) + Asset Bundles
  Parity: dual-run reconciliation (L1-L4) gates cutover
```
Key visual: **the S3 layer barely changes** — the data already lives in S3. You're swapping the *compute + warehouse + catalog + ops model* on top of it, which is why this cutover is smoother than an EDW lift (read-in-place via Glue-Catalog bridge during transition).

**The mapping table (the "how does X become Y" interviewers love):**

| AWS-native | Databricks | Why |
|---|---|---|
| Redshift (provisioned) | SQL warehouses + Delta on S3 | Elastic; no provision-for-peak-24/7 |
| DISTKEY | Z-ORDER / liquid clustering | Co-location = file layout, not partitioning |
| SORTKEY | Partition (date) + Z-ORDER | Range pruning |
| DISTSTYLE ALL | Small Delta table (auto-broadcast) | — |
| Redshift WLM | Separate SQL warehouses + multi-cluster + serverless | Isolate+autoscale, don't ration |
| Redshift VACUUM (re-sort) | OPTIMIZE ... ZORDER | Re-cluster; Delta VACUUM only reclaims files |
| Glue DynamicFrame | Spark DataFrame | Native |
| Glue job bookmark | Auto Loader checkpoint + idempotent MERGE | File-level + data-level |
| Glue Data Catalog | Unity Catalog (or bridge during transition) | Governance + lineage |
| Glue crawlers | Auto Loader schema inference/evolution | Kills crawler cost + wrong-guess |
| EMR managed clusters | Cluster policies + pools + autoscale | Kills babysitting |
| EMRFS consistency | Delta transactional consistency | Native ACID |
| Lake Formation row/col | UC row filters + column masks | Centralized, as-code |
| UNLOAD to S3 | (data already in S3 / COPY INTO) | Shorter move |

---

## 1. Why migrate off Redshift / Glue / EMR

### Q. You were already all-in on AWS. Why move to Databricks?

**Context:** When the source is AWS-native, "why leave AWS tooling" is the first question. Answer with operational pain + unification, not "Databricks is trendy."

**S:** We ran Redshift (warehouse) + ~120 Glue jobs + ~40 EMR Spark apps + Glue Catalog + Athena. Three pain points: Redshift hit **concurrency limits** at month-end (queries queued behind WLM); **Glue jobs had cold-start latency + opaque DPU billing**; **EMR clusters needed constant babysitting** (right-sizing, spot interruptions, version drift) and were either idle-expensive or under-provisioned.
**T:** Build the case for consolidating onto one lakehouse.
**A:**
- **Quantified the three pains:** Redshift WLM queue time at peak, Glue DPU spend + cold starts, EMR ops toil (eng-hours/week babysitting clusters) + idle cost.
- **Unification argument:** three systems (Redshift SQL + Glue ETL + EMR Spark) → one platform (Spark + SQL + Delta + Workflows + Unity Catalog). One governance model, one compute model, one lineage.
- **Open format:** Delta/Parquet in our own S3 → no warehouse lock-in, ML on the same data.
- **Cost model:** elastic autoscaling + serverless SQL + scale-to-zero vs always-on Redshift + idle EMR.
**R:** Approved on operational-toil reduction + ~58% cost + unification, not cost alone. The EMR-babysitting toil was the emotional sell to engineering; cost was the sell to finance.

> 💡 **Remember:** Trap — saying "Databricks is better/trendier" instead of naming concrete AWS-native pain. Say — "Three systems and two governance models collapsed into one lakehouse; the EMR babysitting toil sold engineering, the 58% sold finance."

### Q. Isn't Glue/EMR already Spark — so isn't this just a config change?

**Context:** A sharp interviewer probes whether you understand it's *not* trivial. Show the real gaps.

**Answer:**
- **Partly true, and that's an advantage** — EMR/Glue already run Spark, so the PySpark/Scala *transform logic* ports far more cleanly than a from-scratch rewrite would. Much of it is reusable as-is.
- **But the gaps are real:** (1) **Glue DynamicFrames** (Glue's DataFrame variant) aren't native Spark → rewrite to DataFrames. (2) **Glue Data Catalog** as metastore → **Unity Catalog** migration. (3) **EMR cluster config / bootstrap actions / spot management** → Databricks cluster policies + pools. (4) **Redshift SQL dialect** (the warehouse half) → Spark SQL. (5) orchestration (Step Functions/Glue Workflows/Airflow) → Databricks Workflows. (6) **file layout** — Redshift DISTKEY/SORTKEY co-location must be reproduced via clustering.
- So it's "Spark to Spark" for the EMR transform code (easy), but "warehouse + catalog + ops model" migration for everything around it (the real work).

> 💡 **Remember:** Trap — agreeing it's "just a config change" and sounding naive about the gaps. Say — "The transform code ports Spark-to-Spark, but DynamicFrames, the Glue Catalog, EMR cluster ops, and DISTKEY co-location are all real rewrites around it."

---

## 2. Redshift specifics

### Q. How do you translate Redshift DISTKEY / SORTKEY to Databricks?

**Context:** This is the Redshift analog of Teradata's Primary Index — *the* schema question. DISTKEY controls node distribution (co-location for joins); SORTKEY controls on-disk order (range pruning). Neither has a 1:1 Delta equivalent.

**S:** Every hot Redshift fact had a DISTKEY (join key) + SORTKEY (usually date), tuned over years.
**T:** Reproduce that join/scan performance on Delta, which has no DISTKEY/SORTKEY.
**A — how I mapped it:**
- **DISTKEY (join co-location)** → **Z-ORDER / liquid clustering** on the same join key. DISTKEY's whole job is "rows that join sit together" — that's data co-location = clustering, NOT partitioning (high-card join key partitioned = small-files disaster).
- **SORTKEY (range pruning, usually date)** → **Delta partitioning** on the date column (compound/interleaved SORTKEY → multi-column Z-ORDER).
- **`DISTSTYLE ALL`** (small dim replicated to every node) → just a small Delta table that Spark will **broadcast** automatically.
- **`DISTSTYLE EVEN`** (no co-location) → no clustering needed, default.
- **Verified with `EXPLAIN FORMATTED`** that hot queries got partition pruning + data skipping, compared to the Redshift `EXPLAIN`.
**R:** Hot-path parity-or-better without DISTKEY/SORTKEY. The reusable rule: **DISTKEY→cluster, SORTKEY(date)→partition, DISTSTYLE ALL→let it broadcast.** Same as the Teradata PI story, different keywords.

> 💡 **Remember:** Trap — mapping DISTKEY to partitioning (a high-card join key partitioned = small-files disaster). Say — "DISTKEY is co-location, so it becomes clustering not partitioning; SORTKEY(date) becomes the partition; DISTSTYLE ALL just broadcasts."

### Q. Redshift needs VACUUM and ANALYZE. What's the Databricks equivalent?

**Context:** Redshift requires manual `VACUUM` (reclaim space + re-sort after deletes/updates) and `ANALYZE` (refresh stats). Shows you know the operational rhythm difference.

**Answer:**
- **`VACUUM` (re-sort + reclaim)** → on Delta, **`OPTIMIZE`** (compaction + Z-ORDER re-clustering) handles the "keep data well-ordered" job; Delta's `VACUUM` exists but only **removes old unreferenced files** (tombstone cleanup after the retention window) — it does *not* re-sort. So Redshift VACUUM's *re-sort* role → Delta `OPTIMIZE ... ZORDER`; its *space reclaim* role → Delta `VACUUM`.
- **`ANALYZE` (stats)** → Delta collects stats automatically on write (`dataSkippingNumIndexedCols`); `ANALYZE TABLE ... COMPUTE STATISTICS` exists for CBO but you rarely hand-run it.
- **The shift:** Redshift = scheduled manual maintenance windows; Databricks = mostly automatic (Auto Optimize, predictive optimization / liquid clustering auto-manages). Less ops toil — part of the migration sell.
- **Gotcha:** don't confuse the two `VACUUM`s in the interview — Redshift VACUUM re-sorts; Delta VACUUM only deletes old files. Saying that precisely signals you actually know both.

> 💡 **Remember:** Trap — assuming Delta VACUUM is the equivalent of Redshift VACUUM (it isn't — it only reclaims files). Say — "Redshift VACUUM's re-sort role maps to OPTIMIZE ZORDER; only its space-reclaim role maps to Delta VACUUM. Two different VACUUMs."

### Q. What Redshift types / SQL features bit you?

**Context:** Quick dialect-gap knowledge.

**Answer — the ones I hit:**
- **`SUPER` type** (Redshift's semi-structured/JSON) → Spark `STRUCT`/`MAP`/`VARIANT` or parse to columns; `PARTIQL` navigation → Spark JSON functions.
- **`VARCHAR(n)` is byte-length** in Redshift, char-length semantics differ → multibyte data could overflow; widened on convert.
- **`IDENTITY` / `GENERATED`** → Delta `GENERATED ALWAYS AS IDENTITY`; verified no downstream dependence on exact surrogate values.
- **`GETDATE()`, `DATEADD`, `DATEDIFF`** → Spark `current_timestamp()`, `date_add`, `datediff` (arg order differs — bit me once).
- **`DISTINCT` + `APPROXIMATE COUNT(DISTINCT)`** (HyperLogLog) → Spark `approx_count_distinct`.
- **Spectrum external tables** → Unity Catalog external tables (see §4).
- **Serializable isolation** assumptions in some jobs → Delta is snapshot isolation; checked nothing relied on Redshift's stricter serialization for correctness.
- **Identity of `NULL` in sorts / `NULLS FIRST`** → made explicit (same trap as Teradata).

> 💡 **Remember:** Trap — assuming SUPER/VARCHAR/date-function semantics port cleanly (VARCHAR is byte-length, DATEADD/DATEDIFF arg order differs). Say — "The dialect gaps that bit me were SUPER, byte-vs-char VARCHAR, and DATEDIFF argument order; I caught them in conversion, not in prod."

---

## 3. Redshift data movement + reconciliation

### Q. How did you move the data out of Redshift?

**Context:** Redshift's native bulk export is **`UNLOAD`** to S3 — the analog of Teradata's TPT. Use it, not JDBC row-by-row.

**S:** ~25 TB across ~900 tables, largest fact ~5 TB, on a cluster already concurrency-constrained.
**T:** Export without starving production queries, prove it landed intact.
**A:**
- **`UNLOAD ('SELECT ...') TO 's3://...' FORMAT PARQUET PARTITION BY (dt)`** — parallel, columnar, partitioned export straight to S3. Parquet (not CSV) preserves types + compresses.
- **Throttled to off-peak** + its own WLM queue so production wasn't starved.
- **Big tables UNLOAD'd by date range** → resumable per partition, failures cheap.
- **Auto Loader / COPY INTO** to land bronze → transform to silver/gold.
- **Reconciliation ladder** (same L1–L4 as the Teradata doc): structural → count/count-distinct → aggregate sums → row-checksum at the cent for finance.
**R:** Full history in off-peak windows, every partition checksum-verified, zero production SLA breach. `UNLOAD ... FORMAT PARQUET PARTITION BY` is the one-liner to know.

> 💡 **Remember:** Trap — proposing JDBC row-by-row extraction that starves the already-concurrency-capped cluster. Say — "Parallel UNLOAD to Parquet partitioned by date, on its own off-peak WLM queue, resumable per partition and checksum-verified."

### Q. Incremental catch-up from Redshift during dual-run?

**Answer (STAR-lite):** **S:** tables stayed live during their dual-run window. **A:** incremental `UNLOAD` filtered on an `updated_at`/load-batch watermark (or full-partition refresh where no reliable timestamp) → idempotent MERGE into Delta keyed on natural keys → tracked a high-water mark per table. **R:** target tracked source within a day until cutover; final tiny delta at cutover. (Redshift uses UNLOAD; the catch-up pattern is the same idempotent-MERGE-on-watermark every migration uses.)

> 💡 **Remember:** Trap — appending incremental UNLOADs (re-runs duplicate). Say — "Incremental UNLOAD on an updated_at watermark, then idempotent MERGE on natural keys with a per-table high-water mark, so re-runs converge instead of duplicating."

### Q. How did you prove parity Redshift↔Databricks? Build the framework.

**Context:** Same reconciliation discipline as any finance migration, but with Redshift-specific extraction (UNLOAD/JDBC) and Redshift-specific diff traps.

**S:** Finance marts on Redshift; cutover needed cent-level proof, ~900 tables.
**T:** A config-driven, nightly, auditable parity engine — not one-off compare scripts.
**A — how I built it:**
- **Config per table** (`source, target, pk_cols, numeric_cols, partition_col, level, tolerance`) → the engine generated comparison queries; onboarding a table = a config row.
- **Both-sides at same grain:** ran identical aggregation SQL on Redshift (JDBC, or read the UNLOAD'd Parquet) and Delta, grouped by partition.
- **Ladder L1→L4** (structural → count/count-distinct → aggregate sums → normalized row-checksum), cheap-to-expensive with short-circuit.
- **Redshift-specific normalization before hashing:** `SUPER`/JSON serialization differs, `VARCHAR` byte vs char, NULL rendering, decimal formatting — normalized identically both sides before `SHA2` or the hashes diverge on formatting, not data (the classic false-mismatch).
- **Audit Delta table** `recon_run(...)` = pass/fail history; cutover gated on N green nights from it.
**R:** Auditable nightly parity at 99.98%; finance signed off the audit table, not faith. Same config-driven framework that made wave-N setup trivial.

> 💡 **Remember:** Trap — hashing without normalizing first, so SUPER/JSON serialization, VARCHAR byte-vs-char, and decimal formatting cause false mismatches. Say — "Config-driven L1-L4 ladder, normalized identically both sides before SHA2, gated on N green nights in an audit Delta table finance signed off."

### Q. Walk migrating ONE Glue job end-to-end (the concrete arc).

**Context:** They want the full lifecycle on a real object, Glue flavor.

**S:** The `silver_canonical_sales` Glue job — DynamicFrames, a **job bookmark** for incremental, GlueContext, writing Parquet to S3, cataloged in Glue.
**T:** Move it to Databricks with identical output + exactly-once, no double-processing.
**A — the lifecycle:**
1. **Assess:** mapped its sources (12 distributor prefixes), the bookmark's incremental key, downstream consumers (finance marts via Athena/Glue Catalog).
2. **Code port:** DynamicFrame → Spark DataFrame; stripped GlueContext → SparkSession; the actual join/dedup/aggregate logic carried over ~unchanged (Spark→Spark).
3. **Incremental swap (the key step):** **Glue job bookmark → Auto Loader checkpoint** (file-level, "what have I read") **+ idempotent MERGE on natural key** (data-level, "don't double-count") — because a naive port without this double-processes (see §10 war story).
4. **Sink:** Parquet append → **Delta MERGE** (ACID, exactly-once, small-files tooling).
5. **Catalog:** registered the Delta table in **Unity Catalog**; bridged Glue Catalog during transition so Athena consumers kept working.
6. **Orchestrate:** Glue trigger → **Databricks Workflows** task in the DAG.
7. **Reconcile:** L1-L4 vs the Redshift/Glue output on the same input; gate on green.
8. **Cutover + rollback:** repoint consumers via views; rollback = flip back (old Glue job paused, not deleted, during soak).
**R:** Same output, exactly-once, no bookmark double-processing, no idle Glue DPU. **The one Glue-specific landmine — bookmark → checkpoint + idempotent MERGE — is the whole story of "Spark ports easy but the incremental semantics don't."**

> 💡 **Remember:** Trap — porting the transform but dropping the bookmark's incremental semantics, so the new job double-processes. Say — "The join logic carried over unchanged; the real step was turning the Glue bookmark into an Auto Loader checkpoint plus idempotent MERGE, then gating cutover on reconciliation."

---

## 4. Glue → Databricks

### Q. How did you migrate Glue ETL jobs?

**Context:** Glue jobs are managed Spark (PySpark/Scala) but with Glue-specific abstractions (DynamicFrame, GlueContext, job bookmarks). The Spark logic ports; the Glue wrappers don't.

**S:** ~120 Glue jobs, most using **DynamicFrames**, GlueContext, and **job bookmarks** for incremental.
**T:** Move them to Databricks notebooks/jobs with equivalent behavior.
**A — how I approached it:**
- **DynamicFrame → DataFrame:** Glue's DynamicFrame (schema-flexible, Glue-only) → native Spark DataFrame. Where DynamicFrame's `ResolveChoice`/schema-flexibility was doing real work (messy schemas), replaced with explicit schema handling / Auto Loader schema evolution.
- **GlueContext → SparkSession:** stripped the Glue wrapper; the core transform logic (the actual joins/aggs) carried over largely unchanged — this is the easy, reusable part.
- **Job bookmarks (Glue's incremental-state) → Auto Loader checkpoints / Delta MERGE watermarks.** This is the key conceptual swap: Glue bookmarks tracked "what I've processed"; Databricks does it via checkpoint (file-level) + idempotent MERGE (data-level).
- **Glue triggers/Workflows → Databricks Workflows** (lifted the dependency DAG).
- **Validated each by reconciliation**, not "it ran."
**R:** Transform logic ~80% reusable (Spark→Spark); the work was replacing Glue-specific bookmarks + DynamicFrames + GlueContext. Naming "job bookmark → checkpoint/watermark" is the signal you actually ran Glue.

> 💡 **Remember:** Trap — treating DynamicFrame, GlueContext, and bookmarks as portable Spark (they're Glue-only wrappers). Say — "DynamicFrame to DataFrame, GlueContext to SparkSession, bookmark to checkpoint plus MERGE watermark; the transform logic was the easy 80%."

### Q. What about the Glue Data Catalog?

**Context:** Glue Catalog is the Hive-compatible metastore for Athena/EMR/Spectrum. Databricks uses **Unity Catalog**. Two migration options.

**Answer:**
- **Option A (bridge):** Databricks can *read* the Glue Data Catalog directly (configure it as the external metastore / via federation) — useful during transition so both stacks see the same tables. Pragmatic stepping stone.
- **Option B (target):** migrate definitions into **Unity Catalog** (catalog→schema→table), repoint to Delta. End state.
- **My approach:** bridged early (Databricks reading Glue Catalog for the lift-and-shift external tables) so consumers weren't blocked, then migrated table-by-table into UC as each wave cut over. Strangler fig at the metastore layer.
- **Crawlers** (Glue's schema-inference) → replaced by Auto Loader schema inference/evolution + explicit DDL; killed the crawler cost + the "crawler guessed wrong" failure mode.

> 💡 **Remember:** Trap — proposing a big-bang Glue Catalog migration that blocks Athena/Spectrum consumers. Say — "Bridge by reading the Glue Catalog directly during transition, then migrate table-by-table into Unity Catalog wave-by-wave; strangler fig at the metastore layer."

### Q. Glue cold starts / DPU billing — did that motivate anything?

**Answer:** Yes — Glue jobs had startup latency (provisioning) and opaque **DPU-hour** billing that was hard to attribute. Databricks job clusters (or serverless) + mandatory cost tags + `system.billing.usage` gave per-job cost visibility Glue didn't. Part of the cost + observability sell.

> 💡 **Remember:** Trap — framing it as only a cost issue and missing the attribution/observability gap. Say — "Glue's DPU-hour billing was opaque and unattributable; mandatory tags plus system.billing.usage gave us per-job cost visibility Glue never did."

---

## 5. EMR → Databricks

### Q. How did you migrate EMR Spark applications?

**Context:** EMR runs open-source Spark on clusters you manage (or EMR Serverless). The Spark *code* is the most portable of any source; the *operational model* is what you're really leaving.

**S:** ~40 EMR Spark apps (PySpark/Scala) on long-running + transient clusters, with bootstrap actions, spot-instance fleets, and manual version pinning.
**T:** Move the apps + retire the cluster-babysitting.
**A — code:**
- **Spark app code ported largely as-is** — same Spark APIs. Main edits: replace EMR-specific paths (`s3://` configs, EMRFS quirks), Hadoop/Spark version differences, and any reliance on EMR's filesystem consistency layer (EMRFS) → Delta gives consistency natively.
- **Hardcoded cluster configs / `spark-submit` args** → Databricks job cluster definitions (as code via Asset Bundles).
- **Wrote outputs to Delta** instead of raw Parquet → got ACID + time travel + the small-files tooling for free.
**A — operations (the real win):**
- **EMR cluster management → Databricks cluster policies + pools.** No more bootstrap actions, AMI management, manual spot fleets, version drift. Autoscaling + auto-terminate replaced "did someone leave the cluster running."
- **EMR Steps / Oozie / Airflow → Databricks Workflows.**
- **EMRFS consistency hacks → gone** (Delta is consistent).
**R:** Apps ported fast (Spark→Spark); the measurable win was ops toil — eliminated the eng-hours/week babysitting clusters + the idle-cluster cost. For Dmitry: "replaced hand-managed compute with IaC cluster policies = self-service + cost control."

> 💡 **Remember:** Trap — selling the EMR migration on code effort when the code is the easy part. Say — "The Spark apps ported nearly as-is; the real win was retiring bootstrap actions, spot-fleet management, and version drift for cluster policies plus autoscale-to-zero."

### Q. EMR was cheaper per-hour (esp. spot). How did you justify the cost?

**Context:** A real pushback — EMR on spot can look cheap. Answer with TCO, not sticker price.

**Answer:**
- **Per-hour EMR-on-spot ≠ TCO.** Add: idle-cluster waste (clusters left running), the eng-hours babysitting/right-sizing, spot-interruption reruns, and version-upgrade toil. Databricks autoscale-to-zero + job clusters + Photon (more work per hour) close most of the raw-rate gap.
- **Databricks also runs on spot** (you can configure spot for worker fleets) — so it's not giving up spot economics.
- **Honest framing:** for a *pure, steady, well-tuned* Spark batch on spot, EMR can be marginally cheaper per-DBU-equivalent. The migration wins on **unification + ops toil + governance + the warehouse/ML consolidation**, and I said that explicitly rather than overclaiming pure compute savings. (Pragmatism + honesty = Dmitry's values.)

> 💡 **Remember:** Trap — claiming Databricks beats EMR-on-spot on raw per-hour rate (it often doesn't). Say — "Per-hour spot isn't TCO once you add idle waste, babysitting, spot reruns, and version toil; Databricks runs spot too, and the win is unification plus ops, said honestly."

---

## 6. Performance parity

### Q. Redshift handled our BI concurrency. Does Databricks?

**Context:** Redshift WLM + concurrency scaling vs Databricks SQL warehouses. The concurrency story is a real concern for BI-heavy shops.

**S:** Month-end, dozens of analysts + dashboards hammered Redshift; WLM queued them (the pain that drove the migration).
**T:** Match-or-beat BI concurrency without the queuing.
**A:**
- **Databricks SQL warehouses with multi-cluster load balancing** — adds clusters as concurrency rises (Redshift's "concurrency scaling" analog, but more elastic), scales back down after.
- **Serverless SQL** for instant-on + autoscale → no month-end queue.
- **Result caching + Photon** for repeated BI queries.
- **Separated workloads** onto their own warehouses (BI vs ad-hoc vs ETL) so they don't contend — the WLM-queue → isolate-and-autoscale shift.
**R:** Month-end queuing disappeared (warehouses scaled out); P90 BI latency improved. The conceptual swap: Redshift *rations* fixed nodes via WLM; Databricks *isolates + autoscales* compute per workload.

> 💡 **Remember:** Trap — equating WLM tuning with the Databricks model and missing the philosophy shift. Say — "Redshift rations fixed nodes via WLM queues; Databricks isolates BI, ad-hoc, and ETL onto separate multi-cluster warehouses that autoscale, so month-end queuing just disappears."

### Q. A query was slower post-migration. Diagnose.

**Context:** Same shape as the Teradata answer — lost co-location.

**S:** A heavy analyst star-join ran slower on Databricks than Redshift right after a lift-and-shift wave.
**T:** Parity fast, before "the new thing is worse" spread.
**A:** **Spark UI** → big shuffle + full scan where Redshift had used DISTKEY co-location. Root cause: lift-and-shift tables had no clustering. **Fix:** `OPTIMIZE ... ZORDER BY (join_key)` (→ liquid clustering) to restore co-location; date partition for pruning; Photon on; ensured small dims broadcast. Verified via `EXPLAIN FORMATTED`.
**R:** Past Redshift on latency. Reproducing DISTKEY's *co-location* role via clustering — which a 1:1 port dropped — was the fix. Made "cluster the hot join key" a standard post-migration step.

> 💡 **Remember:** Trap — blaming Spark/Photon when the real cause is a lift-and-shift that dropped DISTKEY co-location. Say — "Spark UI showed a giant shuffle where Redshift had DISTKEY co-location; ZORDER/cluster the join key plus a date partition, and it beat Redshift."

---

## 7. Governance: Glue Catalog + Lake Formation → Unity Catalog

### Q. You had Glue Catalog + Lake Formation permissions. How did that map?

**Context:** AWS-native governance is Glue Catalog (metadata) + Lake Formation (fine-grained access) + IAM. Target is Unity Catalog. Don't 1:1 port — modernize.

**S:** Lake Formation row/column grants + IAM roles + Glue Catalog databases.
**T:** Reproduce least-privilege in UC, auditable.
**A:**
- **Glue databases/tables → UC catalogs/schemas/tables** (modeled to UC's 3-level hierarchy: catalog per domain, schema per layer — not a flat port).
- **Lake Formation row/column permissions → UC row filters + column masks** (centralized, not scattered).
- **IAM-role-based access → UC grants on SCIM-synced groups** (group-managed, not per-user).
- **Lineage + audit** native in UC (replaced manual Lake Formation access reviews).
- All grants as **Terraform** (databricks provider) → reproducible, reviewed (Dmitry's IaC lane).
- **Bridged during transition:** UC can govern external tables still in S3, so consumers moved gradually.
**R:** Least-privilege preserved + auditable + as-code. Modeling to UC's hierarchy (not a flat Glue port) made it maintainable.

> 💡 **Remember:** Trap — a flat 1:1 port of Glue databases plus per-user IAM grants into UC. Say — "Modeled into UC's three-level hierarchy (catalog per domain, schema per layer), Lake Formation row/col into UC row filters and column masks, all on SCIM groups as Terraform."

---

## 8. Cutover, dual-run, rollback

### Q. Cutover for an AWS-native source — anything different from the EDW case?

**Context:** Core pattern is identical (dual-run + strangler-fig + rollback). The AWS-native flavor has a few smoother bits because both stacks share S3.

**S:** Each wave flipped Redshift/Glue/EMR consumers (Athena, Tableau, downstream jobs) to Databricks.
**T:** Cut over with no incident + always-available rollback.
**A:**
- **Dual-run 6 weeks**, nightly reconciliation gating cutover on N green nights (L1–L4, cent-level finance).
- **Shared S3 helps:** during transition, Databricks read Glue Catalog external tables in place (federation/external metastore) so some consumers moved without data copy — smoother than a cross-system EDW federation.
- **Strangler-fig repoint** via views/semantic layer table-by-table; each independently rollback-able.
- **Rollback** = repoint to Redshift/Athena (kept live + current via incremental); rehearsed in lower env.
- **Decommission EMR/Glue/Redshift only after a stability soak.**
**R:** Zero unplanned rollback. The shared-S3 + Glue-Catalog-bridge made the AWS-native cutover marginally smoother than the EDW one (no heavy federation needed for read-in-place).

> 💡 **Remember:** Trap — describing a generic cutover and missing the AWS-native advantage. Say — "Same dual-run, strangler-fig, N-green-nights pattern, but shared S3 plus the Glue Catalog bridge let consumers read in place with no data copy, so it was smoother than an EDW federation."

---

## 9. Cost — the AWS-native savings story

### Q. Where did the ~58% come from, given you were already on AWS?

**Context:** Different from Teradata (where you killed a license + hardware). Here you're optimizing *within* AWS.

**S:** $3.1M/yr across Redshift (provisioned, sized for peak) + Glue DPU + EMR (idle + babysat).
**T:** Cut cost without losing capability.
**A:**
- **Redshift provisioned-for-peak → elastic Databricks** (autoscale, scale-to-zero off-peak). Redshift paid for month-end peak 24/7; Databricks pays for the window.
- **EMR idle/babysat clusters → job clusters (ephemeral) + auto-terminate.** Killed idle spend.
- **Glue DPU sprawl → consolidated jobs** on shared, policied compute with tag-based chargeback.
- **Photon** = more work per DBU on CPU-heavy SQL.
- **Governance that makes it stick:** cluster policies (max workers, mandatory auto-terminate, instance allowlist) + mandatory tags + `system.billing.usage` chargeback dashboards.
**R:** $3.1M → $1.3M/yr. The elasticity (don't pay for peak 24/7) + killing EMR idle were the big levers; policies/tags kept self-service from eroding it (Dmitry's exact playbook).

> 💡 **Remember:** Trap — implying the savings came from leaving AWS (you stayed; you optimized within it). Say — "Redshift paid for month-end peak 24/7 and EMR sat idle; elasticity plus ephemeral job clusters were the big levers, and cluster policies plus tags kept self-service from eroding it."

---

## 10. Scenario / war-story questions

### Q. A Glue job used job bookmarks for incremental. Post-migration it double-processed. What happened?

**S:** After porting a Glue job, a downstream table showed duplicate rows for one run.
**T:** Find why the incremental broke.
**A:** **How I found it:** reconciliation L2 (count-distinct) flagged inflated rows; traced to the ported job. **Root cause:** the Glue **job bookmark** (which tracked processed S3 partitions) had no equivalent wired in the new job — it reprocessed already-loaded data and the load was a plain append. **Fix:** replaced the bookmark with an **Auto Loader checkpoint** (file-level) + made the write an **idempotent MERGE on natural keys** (data-level) so reprocessing converges instead of duplicating. **R:** dedup'd, and the class fixed everywhere a bookmark had been used. Lesson: "Glue bookmark" must become "checkpoint + idempotent MERGE," not a plain append — that gap is a classic Glue-migration bug.

> 💡 **Remember:** Trap — a ported Glue job left as a plain append with no bookmark equivalent reprocesses and duplicates. Say — "Recon L2 caught the inflated count; the bookmark had no equivalent, so I wired an Auto Loader checkpoint plus idempotent MERGE on natural keys and fixed the whole class."

### Q. EMR job relied on EMRFS consistency. On Databricks it behaved differently. Why?

**Answer:** EMRFS had a consistency layer (historically EMRFS consistent view) to paper over S3 eventual consistency for read-after-write. On Databricks, **Delta provides transactional consistency natively** — but if the ported job read raw S3 paths (not Delta tables) it could still hit listing quirks. **Fix:** write/read **Delta tables**, not raw S3 paths, so the transaction log guarantees consistency. (S3 is strongly consistent now anyway, but Delta is the right abstraction regardless.)

> 💡 **Remember:** Trap — trying to rebuild EMRFS's consistent-view layer instead of letting Delta handle it. Say — "EMRFS papered over S3 eventual consistency; the right fix is to read and write Delta tables, not raw S3 paths, and let the transaction log guarantee consistency."

### Q. Athena consumers query the Glue Catalog. How do you not break them at cutover?

**Answer:** During transition, keep the Glue Catalog tables pointing at the same S3 data so Athena keeps working; migrate the *table definitions* to UC and repoint Databricks/BI consumers via the view layer wave-by-wave. Athena users either stay on Glue Catalog (read-in-place) until their wave, or move to Databricks SQL. Strangler fig at the catalog layer — nobody breaks, everyone moves on their wave.

> 💡 **Remember:** Trap — cutting the Glue Catalog over in one shot and breaking every Athena query at once. Say — "Keep Glue Catalog tables pointed at the same S3 so Athena keeps working, migrate definitions to UC, and repoint consumers via views wave-by-wave; strangler fig at the catalog layer."

### Q. Mid-migration, finance number wrong in prod. (Same drill, AWS flavor.)

**A:** Check the ingest manifest (did all sources land?) → check reconciliation audit for that table/date (green at cutover?) → if newly diverged, look for a source change (a Glue job still running on the old path, double-writing) → row-checksum to isolate → fix the class → re-reconcile. Redshift kept live + soaking means I can always prove the right number. (Identical discipline to the Teradata doc.)

> 💡 **Remember:** Trap — debugging the math instead of checking whether an old Glue job is still double-writing on the legacy path. Say — "Manifest, then recon audit for that date, then hunt a source change like a stale Glue job still writing the old path; Redshift soaking live means I can always prove the right number."

---

## 11. Hard rapid-fire + flashcards

| Prompt | Crisp answer |
|---|---|
| DISTKEY maps to | Z-ORDER / liquid clustering (co-location). NOT partitioning. |
| SORTKEY maps to | Partition (date) + multi-col Z-ORDER for compound sortkeys. |
| DISTSTYLE ALL maps to | Small Delta table → Spark broadcasts it automatically. |
| Redshift VACUUM vs Delta VACUUM | Redshift VACUUM = re-sort + reclaim → Delta `OPTIMIZE ZORDER` (re-sort) + Delta `VACUUM` (reclaim only). They are NOT the same VACUUM. |
| Redshift ANALYZE maps to | Auto stats on Delta write; `ANALYZE COMPUTE STATISTICS` rarely needed. |
| Redshift bulk export | `UNLOAD ('SELECT...') TO 's3://' FORMAT PARQUET PARTITION BY (dt)`. |
| SUPER type | Spark STRUCT/MAP/VARIANT + JSON functions (PARTIQL → Spark JSON). |
| Glue DynamicFrame maps to | Native Spark DataFrame (explicit schema / Auto Loader evolution for the messy-schema cases). |
| Glue job bookmark maps to | Auto Loader checkpoint (file-level) + idempotent MERGE (data-level). Missing this = double-processing bug. |
| Glue Data Catalog maps to | Unity Catalog (or bridge: Databricks reads Glue Catalog during transition). |
| Glue crawlers maps to | Auto Loader schema inference/evolution + explicit DDL. |
| EMR cluster ops maps to | Cluster policies + pools + autoscale + auto-terminate (kills babysitting). |
| EMRFS consistency maps to | Delta transactional consistency (write/read Delta tables, not raw S3). |
| EMR Steps/Oozie maps to | Databricks Workflows. |
| Lake Formation row/col maps to | UC row filters + column masks. |
| Glue Catalog + IAM maps to | UC grants on SCIM groups, all Terraform. |
| Redshift WLM/concurrency maps to | SQL warehouses + multi-cluster load balancing + serverless. Isolate+autoscale, don't ration. |
| "Already AWS, why move" | Unify 3 systems (Redshift+Glue+EMR) → 1 lakehouse; kill EMR babysitting + Redshift queuing + Glue cold starts; open format; ~58% cost. |
| EMR-on-spot is cheaper rebuttal | Per-hour ≠ TCO (idle + babysitting + spot reruns + version toil). Databricks runs spot too. Win is unification+ops+governance; say it honestly. |
| Slower-than-Redshift fix | Lost DISTKEY co-location → ZORDER/cluster join key + date partition + Photon + broadcast dims. |

### Pre-interview checklist
- [ ] Memorize: **900 tables · 25 TB · 120 Glue + 40 EMR · $3.1M→$1.3M · 99.98% parity · 5h→1.4h · zero rollback**
- [ ] DISTKEY/SORTKEY → cluster/partition (the Redshift PI-equivalent) cold
- [ ] Glue job bookmark → checkpoint + idempotent MERGE (the classic Glue bug)
- [ ] EMR story = code ports easy, **ops toil** is the win; EMR-on-spot rebuttal honest
- [ ] Two VACUUMs are different (Redshift re-sort vs Delta file-reclaim)
- [ ] For Dmitry: cost (elasticity + kill idle EMR), IaC (cluster policies replace EMR babysitting = self-service), honesty on raw-compute cost

---

*Last updated: 2026-05-28*
