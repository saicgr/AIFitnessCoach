# Senior Data Engineer — Migration Interview Prep (Teradata → Databricks)
## STAR Format · Discovery → Diagnosis → Fix → Result · Easy to Scan

> **Companion to `INTERVIEW_QA.md`.** Same house style. Every "how did you" answer is **STAR** — Situation, Task, Action (how I *found* it + how I *approached* it + how I *fixed* it), Result with numbers. Pure-definition items use **Context → Answer**.
>
> **Cross-ref:** for "why Databricks vs Teradata / a relational DB / Redshift / Snowflake," see `INTERVIEW_QA.md` §12 (Platform positioning); acronyms (BTEQ, PI/PPI, TASM, TPT…) in `INTERVIEW_QA_GLOSSARY.md`.
>
> **Anchor project (migration):** **Juul Labs' legacy Teradata EDW → Databricks Lakehouse** — 14-month phased program. The Juul **Retail Sales Intelligence Platform** warehouse: 12 distributor depletion feeds + CRM + Nielsen TDLinx, feeding finance, supply-chain, and category-management reporting. Same company + domain as the main `INTERVIEW_QA.md`; the angle here is the **EDW re-platform**.
>
> **Coherence note (read this):** the anchor company is **Juul** across *every* prep doc. The **source system** is the variable — Teradata here, Redshift/Glue/EMR in the companion doc. In any one interview tell **one** source-system story (whichever matches the JD's stack). Don't claim you migrated off both Teradata *and* Redshift in the same conversation — that's the only way these docs contradict each other.
>
> **Numbers to memorize (customize to your real ones):**
> - **~3,200 tables**, **~1,800 BTEQ scripts**, **~40 TB** compressed source
> - **$4.2M/yr → $1.6M/yr** run cost (~62% reduction), payback ~11 months
> - **99.98% reconciliation parity** at the cent grain; **zero** finance restatements post-cutover
> - **14 months**, **5 waves**, dual-run window **6 weeks** per wave, **zero unplanned rollback**
> - Batch window **6.5 h → 1.8 h**; ad-hoc P90 query **45 s → 8 s**
>
> **No ML.** Entity resolution / dedup = deterministic. Migration correctness = checksums + reconciliation, not models.
>
> **Why this matters for Dmitry:** he led **Terraform standardization across 50+ teams**, **$5M/yr AWS savings**, **self-service infra (−75% manual provisioning)**. A migration story that leads with *pragmatism, cost, reproducible IaC, dual-run safety, and mentorship* is exactly his wavelength. Lead with trade-offs made explicit.

---

## Contents

0. [How to use + the migration one-liner](#0-how-to-use--the-migration-one-liner)
1. [Strategy & planning](#1-strategy--planning)
2. [Discovery & assessment](#2-discovery--assessment)
3. [Schema & DDL conversion](#3-schema--ddl-conversion)
4. [SQL / BTEQ / stored-proc conversion](#4-sql--bteq--stored-proc-conversion)
5. [Data migration mechanics (history + incremental)](#5-data-migration-mechanics-history--incremental)
6. [Reconciliation & parity — the hardest area](#6-reconciliation--parity--the-hardest-area)
7. [ETL & orchestration migration](#7-etl--orchestration-migration)
8. [Performance parity & post-migration tuning](#8-performance-parity--post-migration-tuning)
9. [Cutover, dual-run, rollback](#9-cutover-dual-run-rollback)
10. [Workload management & cost (TASM → policies/serverless, DBU)](#10-workload-management--cost)
11. [Governance & security (roles → Unity Catalog)](#11-governance--security-roles--unity-catalog)
12. [BI / consumer repointing](#12-bi--consumer-repointing)
13. [People: stakeholders, training, mentorship, resistance](#13-people-stakeholders-training-mentorship-resistance)
14. [Scenario / war-story questions](#14-scenario--war-story-questions)
15. [Hard rapid-fire + flashcards](#15-hard-rapid-fire--flashcards)
16. [Source-specific cheat sheet (Teradata / Redshift / Oracle)](#16-source-specific-cheat-sheet)

---

## 0. How to use + the migration one-liner

**30-second framing for "tell me about the migration":**

> "We had a Teradata EDW that was expensive, capacity-capped, and blocking the analytics roadmap. I helped lead a 14-month, 5-wave migration to a Databricks Lakehouse — not a lift-and-shift, a *re-platform with selective re-architecture*. We automated DDL + SQL conversion, ran every wave in **dual-run** with cent-level reconciliation before cutover, and used a **strangler-fig** pattern so consumers moved table-by-table with rollback always available. Result: ~62% run-cost reduction, batch window 6.5h→1.8h, 99.98% reconciliation parity, zero finance restatements, zero unplanned rollback."

**The 4 pillars I repeat:** (1) **assess before you move** (inventory + dependency graph), (2) **automate conversion** (don't hand-port 1,800 scripts), (3) **prove parity** (dual-run + reconciliation is non-negotiable in finance), (4) **migrate consumers incrementally** (strangler fig, never big-bang).

### The architecture — before and after (sketch this on the whiteboard in 60s)

**BEFORE — Juul Teradata EDW:**
```
12 distributor SFTP feeds + CRM + Nielsen TDLinx
        |  (BTEQ / Informatica load scripts)
        v
  ┌──────────────────────────────────────────┐
  │  TERADATA EDW (single MPP appliance)       │
  │   - staging tables (BTEQ FastLoad/TPump)   │
  │   - core EDW (3NF, SET tables, PI/PPI)     │
  │   - semantic / mart layer (views + macros) │
  │   - 1,800 BTEQ scripts (stored procs,      │
  │     macros) orchestrated by Control-M      │
  │   - TASM workload management (rationing)   │
  └──────────────────────────────────────────┘
        |
        v
  Tableau · Looker · Informatica · BI/SQL  (ODBC/JDBC -> Teradata)
```
Pain: fixed appliance at >85% capacity month-end (TASM throttles ad-hoc), $4.2M/yr + hardware refresh due, capacity fights block the roadmap.

**AFTER — Databricks Lakehouse on AWS:**
```
12 distributor SFTP feeds + CRM + Nielsen TDLinx
        |  Transfer Family SFTP -> S3 (event-driven)
        v
  ┌─ INGEST (AWS) ────────────────────────────┐
  │  S3 raw -> Step Functions -> Lambda hop    │
  │  (validate) -> land. CloudWatch alarms.    │
  └────────────────────────────────────────────┘
        |  Auto Loader (incremental, checkpointed)
        v
  ┌─ LAKEHOUSE (Databricks, Delta) ───────────┐
  │  BRONZE raw (7y object lock)               │
  │     |  dbt-on-Databricks + Spark           │
  │  SILVER typed/canonical (SCD2, bitemporal) │
  │     |                                       │
  │  GOLD marts (sales/promo/trade-spend)      │
  │  Governance: Unity Catalog (grants/lineage)│
  │  Orchestration: Databricks Workflows (DAG) │
  │  Compute: job clusters + SQL warehouses,   │
  │           cluster policies, autoscale->0   │
  └────────────────────────────────────────────┘
        |
        v
  Tableau · Looker · Databricks SQL · Alation  (via views / semantic layer)

  IaC: Terraform Cloud (AWS + Databricks providers) + Asset Bundles
  CI/CD: GitHub Actions -> terraform plan/apply + bundle deploy
  Parity: dual-run reconciliation (L1-L4) gates every cutover
```

**The mapping, one line each (the "how does X become Y" table interviewers love):**

| Teradata | Databricks | Why |
|---|---|---|
| MPP appliance (fixed) | S3 + elastic compute | Decouple storage/compute; pay for the window, scale to zero |
| Primary Index / PPI | Partition (date) + Z-ORDER/liquid clustering | Co-location becomes file layout |
| SET table (silent dedup) | Explicit MERGE dedup on natural key | Delta has no SET concept |
| BTEQ + stored procs | dbt models (set-based) + Spark notebooks | Versioned, testable, set-based |
| Control-M | Step Functions (per-file ingest) + Databricks Workflows (DAG) | Right tool per timing problem |
| TASM | Cluster policies + separate SQL warehouses + serverless | Isolate+autoscale, don't ration |
| DBC role grants | Unity Catalog grants + row filters/masks | Centralized, auditable, as-code |
| ODBC->Teradata | Views/semantic layer over Delta | Lets you swap backend under consumers |

---

## 1. Strategy & planning

### Q. Why migrate off Teradata at all? How did you build the business case?

**Context:** A migration with no crisp "why" dies in committee. Lead with business drivers, quantified, not "Databricks is cool."

**S:** Teradata was ~$4.2M/yr (license + hardware refresh looming), running at >85% capacity by month-end so analysts' ad-hoc queries got throttled by TASM, and every new data source needed a capacity-planning fight.
**T:** Build a defensible case the CFO and the analytics VP would both sign.
**A:**
- **Quantified the pain:** cost/yr, the month-end throttling (P90 ad-hoc 45s, spiking to minutes under TASM contention), and 3 roadmap items blocked on capacity (ML feature store, semi-structured ingestion, intra-day refresh).
- **Modeled target economics:** decoupled storage (S3 cheap) + elastic compute (pay for the batch window, autoscale to zero off-peak) + no hardware refresh. Projected ~$1.6M/yr.
- **Named the strategic unlocks**, not just cost: open formats (no re-lock-in), Python/ML on the same data, Unity Catalog governance, semi-structured support.
- **Made the risk explicit up front:** correctness risk in finance numbers → mitigated by dual-run + reconciliation (so the scary part had an answer before they asked).
**R:** Approved with an 11-month payback. Framing cost *and* roadmap unlock (not cost alone) is what got the analytics VP on board, not just finance.

**Dmitry hook:** this is his lane — he did $5M AWS savings. Emphasize you led with numbers and made the trade-off explicit.

> 💡 **Remember:** Trap — leading with "Databricks is cooler/newer" instead of quantified business pain. Say — "It wasn't a tech-fashion move: $4.2M/yr, throttled at month-end, and three roadmap items blocked on capacity — I modeled it to $1.6M with an 11-month payback."

### Q. Lift-and-shift vs re-architect — how did you decide?

**Context:** Pure lift-and-shift = fast but you carry forward Teradata anti-patterns (and pay to run them). Full re-architect = clean but slow and risky. The senior answer is *selective*.

**S:** 3,200 tables, but a usage audit showed the classic long tail.
**T:** Decide per-workload, not one blanket policy.
**A:**
- **Pulled usage telemetry** from Teradata DBQL (query logs) — found ~30% of tables hadn't been queried in 12 months, and ~80% of query volume hit ~400 tables.
- **Tiered the estate:** (1) **Decommission** the dead 30% — don't migrate garbage. (2) **Lift-and-shift** low-value-but-used tables (1:1 DDL + SQL transpile) to move fast. (3) **Re-architect** the ~400 hot tables into proper bronze/silver/gold + Delta + clustering — that's where the perf/cost win lives.
- Got data-owner sign-off on the decommission list (CYA + correctness).
**R:** Cut scope ~30% on day one. The re-architected hot path delivered the batch-window and query-latency wins; the lift-and-shift tail moved fast and cheap. **Pragmatism over perfection** — exactly the trade-off Dmitry rewards.

> 💡 **Remember:** Trap — picking one blanket policy (all lift-and-shift *or* all re-architect) for the whole estate. Say — "I tiered it on DBQL usage: decommission the dead 30%, lift-and-shift the used tail, re-architect only the hot ~400 where the perf and cost win actually lives."

### Q. Phased waves vs big-bang — and how did you wave-plan?

**Context:** Big-bang migrations are how you end up on the news. Phasing limits blast radius, but you must phase along *dependency* lines or you create cross-system joins mid-flight.

**S:** Finance, supply-chain, and category-management marts all sat on shared conformed dimensions.
**T:** Sequence waves so each is independently cutover-able with rollback.
**A:**
- **Built a dependency graph** (see §2) and cut waves along it: **Wave 0** = shared conformed dimensions + the heaviest fact (foundation everyone needs), then **Waves 1–4** = one consumer domain each.
- **Sequenced by risk × value:** earliest wave = a *medium-value, well-understood* domain (supply-chain) to prove the playbook with real-but-survivable stakes — not finance first (too risky), not a trivial domain (proves nothing).
- Each wave: convert → backfill history → dual-run 6 weeks → reconcile → cutover → decommission source tables.
- **Reused the playbook**: wave 1 took ~10 weeks; wave 4 took ~5 — the automation + runbook compounded.
**R:** 5 waves, 14 months, zero unplanned rollback. Phasing along the dependency graph (not org chart) is what prevented mid-migration cross-platform joins.

> 💡 **Remember:** Trap — phasing along the org chart, which strands shared conformed dims and forces Teradata↔Delta joins mid-flight. Say — "I waved along the dependency graph: Wave 0 was the shared dims plus heaviest fact, then one consumer domain per wave — and I led with medium-risk supply-chain, not finance, to prove the playbook survivably."

### Q. How did you handle the "moving train" problem — source keeps changing during a 14-month migration?

**Context:** The source EDW isn't frozen; new columns, new tables, hotfixes land while you migrate. Ignore it and your target drifts out of parity.

**S:** Teradata had ~5–10 change requests/month landing during the program.
**T:** Keep target in sync without freezing the business.
**A:**
- **Change freeze only per-wave, only during its dual-run window** — narrow, negotiated, not a global freeze (which the business would never accept).
- **CDC on the source** (see §5) kept migrated-but-not-cutover tables current via incremental loads, so the target tracked the source until cutover.
- **A schema-diff guard in CI** compared source DDL to a snapshot nightly; any new column on an in-flight table raised a ticket so we updated the converted DDL before it broke reconciliation.
**R:** No wave got "stale" before cutover. The narrow per-wave freeze (not a global one) is what kept business + program both moving.

> 💡 **Remember:** Trap — proposing a global source freeze the business will never accept (or ignoring drift entirely). Say — "Freeze was narrow: only the wave in its dual-run window. CDC kept in-flight tables current and a CI schema-diff guard caught new source columns before they broke reconciliation."

---

## 2. Discovery & assessment

### Q. Walk me through the assessment phase. What did you actually inventory?

**Context:** You cannot plan a migration you haven't measured. The assessment artifact is the spine of the whole program.

**S:** Inherited "migrate the EDW" with no inventory of what the EDW even was.
**T:** Produce a complete, queryable inventory + dependency graph before committing dates.
**A:**
- **Objects:** parsed `DBC.Tables/Columns/Indices` (Teradata's data dictionary) → every table, view, macro, stored proc, data type, PI/PPI, size.
- **Usage:** mined **DBQL** (DBC query logs) for 12 months → query frequency per object, who runs what, peak windows, the slow queries.
- **Lineage:** parsed BTEQ + the scheduler (the job DAG) to build a **source→target dependency graph** (what feeds what).
- **Code surface:** counted 1,800 BTEQ scripts, the macros, the stored procs, the proprietary-function usage (QUALIFY, `SAMPLE`, `TOP`, period types).
- **Consumers:** which Tableau/Looker/Informatica jobs point at which tables (the repoint list).
- Loaded all of it into a Delta table so the program could *query* its own scope ("show me every object in wave 3 with a stored proc").
**R:** A single source of truth that drove wave planning, the decommission list, and effort estimates. The DBQL usage mining is what justified dropping 30% of tables — data, not opinion.

> 💡 **Remember:** Trap — inventorying only objects (tables/views) and skipping usage, lineage, and consumer mapping. Say — "I inventoried five things — objects from DBC, 12-month usage from DBQL, lineage from BTEQ+scheduler, the code surface, and consumers — then loaded it all into Delta so the program could query its own scope."

### Q. How did you estimate effort / timeline credibly?

**Context:** "It'll take a year" is not an estimate. Senior = bottom-up from the inventory + a calibrated unit rate.

**S:** Leadership wanted a date; I had an inventory but no velocity data.
**T:** Estimate without sandbagging or over-promising.
**A:**
- **Ran a pilot wave first** (one medium domain) to get a real **velocity**: tables/week converted, % auto-transpiled vs manual, reconciliation effort per table.
- **Bucketed complexity:** simple (auto-transpile, 1:1) vs medium (some rewrite) vs hard (stored procs, recursive SQL, weird types) — each with a measured hour rate from the pilot.
- **Estimated bottom-up** from the inventory × bucket rates, + a 30% contingency I named explicitly.
- Re-forecast after each wave with actuals (the estimate got *better*, not just older).
**R:** Came in within ~8% of the re-forecast. Naming the contingency and re-forecasting from actuals is what kept leadership trust when wave 1 ran long.

> 💡 **Remember:** Trap — pulling a "one year" number from thin air with no velocity data behind it. Say — "I ran a pilot wave to get real velocity, bucketed the inventory by complexity × measured hour-rate, added a named 30% contingency, and re-forecast from actuals after each wave — landed within 8%."

### Q. (Architecture) Why medallion (bronze/silver/gold) instead of porting Teradata's staging/3NF/mart layers 1:1?

**Context:** Teradata's layering (staging → 3NF core → semantic views) maps *conceptually* to medallion but isn't identical. Justify the target architecture.

**S:** The EDW had staging tables, a 3NF normalized core, and a view/macro semantic layer.
**T:** Land on an architecture that's cloud-native, not a literal port of a 3NF appliance design.
**A:**
- **Staging → BRONZE:** raw, immutable, all-string + provenance, 7y object lock. But unlike Teradata staging (transient, truncated each load), bronze is *retained* — replayability + audit (you can rebuild silver/gold from bronze).
- **3NF core → SILVER:** typed, canonical, deduped, SCD2 + bitemporal. I kept it *less* normalized than the Teradata 3NF core where heavy normalization only existed to save appliance storage — storage is cheap on S3, so I denormalized where it simplified downstream and cut joins.
- **Semantic views/macros → GOLD:** precomputed marts (Teradata recomputed via views every query; gold materializes them — cheaper at read, the elastic-compute trade-off).
- **Why not 1:1:** a literal port carries forward storage-driven normalization and query-time view recomputation that only made sense on a fixed appliance. Medallion + materialized gold fits decoupled storage/compute.
**R:** Cleaner lineage (raw is replayable), fewer runtime joins (denormalized silver), faster reads (materialized gold). The senior point: **map the *intent* of each Teradata layer to medallion; don't transcribe a 3NF appliance schema onto a lakehouse.**

> 💡 **Remember:** Trap — transcribing the 3NF appliance schema 1:1, carrying forward storage-driven normalization that only made sense on a fixed box. Say — "I mapped each layer's *intent*: staging→retained bronze for replay, 3NF core→less-normalized silver (storage is cheap on S3), and view/macro semantics→materialized gold marts."

### Q. (Architecture) How did you decide table layout — partition vs cluster vs nothing — across 3,200 tables systematically?

**Context:** You can't hand-tune 3,200 tables. There's a decision rule.

**S:** Every table needed a layout decision; doing it ad hoc would be inconsistent + slow.
**T:** A repeatable rule driven by the assessment data, not per-table intuition.
**A — the rule I codified:**
- **Partition** by a **low-cardinality, time-based** column (usually `sales_date`/month) — *only* if the table is large + queries filter on it (from DBQL). Small tables: no partition (avoids tiny-files).
- **Z-ORDER / liquid clustering** on the **high-cardinality join/filter keys** (the old PI/PPI join columns), pulled from DBQL's most-common predicates + the Teradata PI definition.
- **Nothing** for small dims — let them broadcast.
- **Default to liquid clustering** on new/hot tables so I stopped hand-picking Z-ORDER keys.
- Encoded this as a layout-decision column in the migration inventory, so layout was data-driven + reviewable, not vibes.
**R:** Consistent layout across the estate, hot tables verified with `EXPLAIN FORMATTED`. Rule of thumb to recite: **date → partition, join key → cluster, small dim → broadcast, never partition a high-card key.**

> 💡 **Remember:** Trap — hand-tuning layout per-table by intuition (or partitioning on the high-cardinality join key → tiny-files disaster). Say — "I codified one data-driven rule from DBQL predicates: date→partition, hot join key→Z-ORDER/liquid clustering, small dim→broadcast, never partition a high-card key — and recorded the decision per table."

---

## 3. Schema & DDL conversion

### Q. How did you convert Teradata DDL to Databricks? What broke?

**Context:** Teradata and Spark/Delta differ in types, table semantics, indexing, and constraints. A naive 1:1 port silently changes data or performance.

**S:** 3,200 tables of Teradata DDL, full of Teradata-isms.
**T:** Convert to Delta DDL that preserves *semantics*, not just syntax.
**A — the specific traps I hit and fixed:**
- **`SET` tables (dedup) vs `MULTISET`:** Teradata `SET` tables silently reject duplicate rows. Delta has no equivalent — a 1:1 port loses that dedup and you get extra rows → reconciliation fails. **Fix:** for every `SET` source table, added an explicit dedup step (`MERGE`/`dropDuplicates` on the natural key) in the load, and documented it.
- **`NUMBER`/`DECIMAL` precision:** mapped to Delta `DECIMAL(p,s)` exactly — never to `DOUBLE` (float drift breaks cent-level finance reconciliation). This single rule prevented a class of parity failures.
- **`VARCHAR` semantics + trailing spaces:** Teradata `CHAR` pads; comparisons and `CHARACTER SET LATIN/UNICODE` collation differ from Spark's. **Fix:** trim/normalize on load and verified string-equality joins still matched.
- **Empty string vs NULL:** Teradata treats `''` distinctly; some downstream logic relied on it. Caught it in reconciliation, made the load preserve the distinction explicitly.
- **Primary Index / PPI:** Teradata's PI drives data distribution across AMPs; there is *no* direct Delta equivalent. **Fix:** translated PPI (partitioned PI) → Delta partitioning on the same low-cardinality column where it made sense, and the PI's join-key role → **Z-ORDER / liquid clustering** (see §8). Did NOT blindly partition on the PI column.
- **Identity columns / `GENERATED`:** mapped to Delta `GENERATED ALWAYS AS IDENTITY`, but verified no downstream logic depended on the *specific* Teradata-assigned surrogate values (it did in two cases → preserved old keys via a mapping table).
**R:** DDL conversion was ~90% automated (template + type-map); the 10% manual was exactly these semantic traps. Catching `SET`-table dedup and DECIMAL-vs-DOUBLE *before* dual-run saved weeks of reconciliation debugging.

> 💡 **Remember:** Trap — a syntax-clean 1:1 port that silently changes data (SET dedup lost, DECIMAL→DOUBLE drift, CHAR padding, empty-string-vs-NULL). Say — "DDL conversion preserves *semantics*, not syntax: every SET table got an explicit dedup MERGE, DECIMAL stayed DECIMAL (never DOUBLE), and I caught these before dual-run, not during it."

### Q. SET vs MULTISET — why does it matter so much? (favorite gotcha)

**Context:** This is *the* Teradata schema trap and a classic interview probe.

**Answer:**
- **`SET` table** = no duplicate rows allowed; Teradata enforces it on insert (silently drops dups). **`MULTISET`** = duplicates allowed.
- Delta tables are always "multiset" — they don't dedup on write.
- **Risk:** port a `SET` table 1:1 → the dedup that Teradata was silently doing for years stops happening → row counts inflate → reconciliation fails and, worse, downstream sums double-count.
- **Fix:** identify every `SET` source (from `DBC.Tables`), add explicit dedup in the load keyed on the natural/primary index, and add a reconciliation check on distinct-row count.
- **Whiteboard line:** "Delta has no SET-table concept, so SET-table dedup becomes *my* responsibility in the load — an explicit MERGE on the natural key, verified by a count-distinct reconciliation."

> 💡 **Remember:** Trap — assuming dedup "just happens" on Delta like it did on a SET table, so row counts inflate and downstream sums double-count. Say — "Delta is always multiset, so SET-table dedup becomes my responsibility — an explicit MERGE on the natural key, verified by a count-distinct check in reconciliation."

### Q. How did you decide partitioning + clustering on the target (replacing the Primary Index)?

**Context:** Teradata distributes by PI hash across AMPs; Spark/Delta distributes by files + partitions + clustering. The mapping is conceptual, not mechanical.

**S:** Every hot fact had a PI (often the join key) and sometimes a PPI (date).
**T:** Reproduce Teradata's good join/scan performance without a PI.
**A:**
- **PPI date column → Delta partition** (low cardinality, time-based, drives partition pruning).
- **PI join key (high cardinality) → Z-ORDER / liquid clustering**, NOT a partition (partitioning on a high-card key = tiny-files disaster).
- **Verified with `EXPLAIN FORMATTED`** that the hot queries got partition pruning + data skipping, comparing logical plan to the Teradata explain.
- Moved newer tables to **liquid clustering** so I stopped hand-tuning Z-ORDER keys.
**R:** Hot-path queries matched or beat Teradata (P90 45s→8s) without a PI. The discipline — date→partition, join-key→cluster, never the reverse — is the reusable rule.

> 💡 **Remember:** Trap — treating PI→layout as a mechanical 1:1 (e.g. partitioning on the high-card PI join key). Say — "There's no persistent PI on Delta — co-location is a file-layout property: PPI date→partition, PI join key→Z-ORDER/liquid clustering, verified with EXPLAIN FORMATTED against the Teradata plan."

---

## 4. SQL / BTEQ / stored-proc conversion

### Q. How did you convert 1,800 BTEQ scripts? You didn't hand-port them, right?

**Context:** Hand-porting 1,800 scripts is a multi-year death march and error-prone. Automate the bulk, hand-fix the residue.

**S:** 1,800 BTEQ scripts + macros + stored procs, heavy on Teradata-proprietary SQL.
**T:** Convert at scale with high fidelity and a way to catch what the tool got wrong.
**A:**
- **Automated transpilation** for the bulk — a SQL transpiler (SQLGlot-based tooling / Databricks LakeBridge / a vendor like BladeBridge) to convert Teradata SQL → Spark SQL, then ran every converted query through a **parse + dry-run** gate.
- **Categorized what *didn't* auto-convert** and built a fix-pattern library: `QUALIFY` → window + filter (Spark now supports QUALIFY directly), `SAMPLE`/`TOP` → `LIMIT`/`TABLESAMPLE`, Teradata date arithmetic + `ADD_MONTHS`/period types → Spark equivalents, recursive `WITH RECURSIVE`, proprietary `TD_*` functions.
- **Stored procedures + macros:** these don't transpile cleanly — rewrote procedural BTEQ logic as **dbt models** (set-based) where possible, and as **Python/notebook** orchestration where genuinely procedural. Killed a lot of cursor-loop logic by making it set-based.
- **Every converted query validated by reconciliation** (§6), not by "it ran."
**R:** ~75% auto-transpiled clean; the fix-pattern library made the residual 25% fast + consistent. The senior move was *the validation gate* — "it parsed" is not "it's correct."

> 💡 **Remember:** Trap — hand-porting 1,800 scripts (multi-year death march) *or* trusting the transpiler because output "ran." Say — "I auto-transpiled the bulk (~75%) through a parse-and-dry-run gate, built a fix-pattern library for the residue, and validated every query by reconciliation — 'it parsed' is not 'it's correct.'"

### Q. What Teradata SQL features bit you specifically?

**Context:** Quick-fire knowledge of the dialect gaps signals real migration experience.

**Answer — the ones I hit:**
- **`QUALIFY`** — Teradata's filter-on-window-function. Spark supports it now, but older transpiles expanded it to subqueries; verified semantics.
- **Default rounding mode** — Teradata `ROUND` is half-up; Spark `round()` is half-up too but `bround` is half-even, and CAST behavior differs. Pinned the rounding explicitly (caused a cent-level parity diff — see §6).
- **`NULL` ordering** — Teradata sorts NULLs differently by default than Spark (`NULLS FIRST/LAST`); broke `ROW_NUMBER` "latest record" logic until I made ordering explicit.
- **Integer division / implicit casts** — Teradata's implicit type coercion differs; `int/int` and string-to-number coercions produced different results until casts were made explicit.
- **`SAMPLE`, `TOP`, `MINUS`** → `TABLESAMPLE`, `LIMIT`, `EXCEPT`.
- **Period / interval types** — no direct Spark type; modeled as start/end columns.
- **Case sensitivity / collation** — Teradata default is case-insensitive comparison (LATIN); Spark is case-sensitive → join keys silently stopped matching. **Fix:** normalize case on load.

> 💡 **Remember:** Trap — naming only the obvious syntax swaps (SAMPLE/TOP/MINUS) and missing the *silent* semantic ones that corrupt data. Say — "The syntax swaps are easy; the killers are silent — half-up vs half-even rounding, NULL sort order in 'latest-record' logic, case-insensitive joins, and implicit casts — all of which pass parsing and fail reconciliation."

### Q. How did you handle stored procedures and procedural (cursor) logic?

**Context:** Spark/dbt are set-based; Teradata stored procs are often row-by-row procedural. A literal port performs terribly.

**S:** ~120 stored procs, several with cursor loops doing row-at-a-time updates.
**T:** Re-express procedural intent as set-based where possible.
**A:**
- **Read each proc for *intent*, not syntax** — most cursor loops were really a join + aggregate + update expressed badly.
- **Rewrote as set-based dbt models / `MERGE`** — e.g. a loop that updated balances row-by-row became one windowed `MERGE`.
- **The genuinely procedural few** (multi-step with external calls) became Python notebooks orchestrated by Workflows.
- Validated each by reconciling output to the Teradata proc's output on the same input.
**R:** One balance-update proc went from a 40-min cursor loop to a 90-sec set-based MERGE. The lesson: don't translate procedural code literally — translate the *intent* to set-based.

> 💡 **Remember:** Trap — literally porting cursor loops to PySpark loops, which performs terribly. Say — "I read each proc for *intent*, not syntax — most cursor loops were really a join+aggregate+update expressed badly, so they became a single windowed MERGE; one went from a 40-min loop to a 90-sec set-based MERGE."

---

## 5. Data migration mechanics (history + incremental)

### Q. How did you actually move 40 TB of history out of Teradata?

**Context:** Bulk export + transfer + land + validate. The mechanics matter; "we copied it" doesn't.

**S:** 40 TB compressed, the largest fact ~6 TB, on a system that throttled exports under load.
**T:** Move it all without starving production, and prove it landed intact.
**A:**
- **Bulk export via TPT** (Teradata Parallel Transporter) — the parallel, AMP-aware export path, not row-by-row JDBC (which would take weeks + hammer the box).
- **Exported to a neutral format (Parquet/compressed delimited) → S3**, partitioned by date so loads were resumable per partition.
- **Throttled to off-peak** + capped parallelism so production TASM wasn't starved (negotiated the window with the DBAs).
- **Big tables split by partition/date range** and loaded independently → a failure reprocessed one range, not 6 TB.
- **Auto Loader / COPY INTO** to land into bronze, then transform to silver/gold.
- **Row-count + checksum per partition** on landing (see §6) before declaring a partition "migrated."
**R:** Full history in the negotiated windows, zero production SLA breach, every partition checksum-verified. Splitting big tables by date range is what made failures cheap (reprocess a day, not a table).

> 💡 **Remember:** Trap — row-by-row JDBC extract that takes weeks and starves production, or one monolithic unverified copy. Say — "Bulk export via TPT (parallel, AMP-aware) to Parquet/S3 partitioned by date, throttled off-peak, split big tables by range so a failure reprocesses a day — and checksummed every partition before calling it migrated."

### Q. History is a snapshot — how did you catch up the delta until cutover?

**Context:** Between "bulk export Tuesday" and "cutover six weeks later," the source kept changing. You need incremental sync.

**S:** Tables stayed live in Teradata during their dual-run window.
**T:** Keep the Databricks copy current until the moment of cutover.
**A:**
- **CDC / incremental pulls:** for tables with a reliable `updated_ts` or load-batch id, incremental MERGE on a schedule; for the rest, daily full-refresh of the affected partitions.
- **Idempotent MERGE** keyed on natural keys so re-running a catch-up never duplicated.
- **Tracked a high-water mark** per table so each incremental knew where to resume.
- At cutover: one final incremental, freeze source, final reconcile, flip consumers.
**R:** Target tracked source within a day throughout dual-run; the final pre-cutover delta was tiny and fast to reconcile. Idempotent MERGE meant catch-up reruns were safe.

> 💡 **Remember:** Trap — treating the bulk snapshot as "done" and ignoring the six weeks of source changes before cutover. Say — "The snapshot is just the baseline — incremental MERGE on a high-water mark (idempotent, keyed on natural keys) tracked the source within a day, then one final tiny delta at cutover."

### Q. Biggest single table was 6 TB and the load kept failing — what did you do?

**Context:** A monolithic load of a huge table is fragile. (Mirrors the "large file fails at 50%" idempotency story in the main doc.)

**S:** The 6 TB fact load failed ~70% in on a transient cluster issue, and a naive restart meant redoing 70%.
**T:** Make the load resumable + idempotent.
**A:**
- **Partitioned the load by date range** → each range an independent, atomic Delta write.
- **Driver tracked completed ranges** in a control table; restart skipped done ranges (same idempotency principle as Auto Loader checkpoints — atomic commit + a record of what's done = no partial, no dupes).
- Re-ran only the failed ranges.
**R:** Restart cost dropped from "redo 4 TB" to "redo one day." Atomic per-partition commit + a completion ledger = the table-scale version of exactly-once.

> 💡 **Remember:** Trap — a monolithic load where a 70%-in failure forces redoing all 4 TB (and a naive restart risks dupes). Say — "I made it resumable and idempotent: partition the load by date range into atomic Delta writes, track completed ranges in a control table, restart skips the done ranges — atomic commit plus a completion ledger is exactly-once at table scale."

---

## 6. Reconciliation & parity — the hardest area

> **This is the #1 thing migration interviewers push on, especially in finance.** "How did you *know* the migration was correct?" Have the layered answer + a real near-miss.

### Q. How did you prove the migrated data matched Teradata?

**Context:** "It ran" ≠ "it's correct." Reconciliation must be layered: structural → volumetric → aggregate → row-level, with finance numbers at the cent.

**S:** Finance would not cut over without proof to the cent; a single wrong number = lost trust + a restatement.
**T:** Build automated, repeatable parity I could run every night of dual-run.
**A — the reconciliation ladder:**
- **L1 structural:** column count, names, types, nullability match the converted DDL.
- **L2 volumetric:** `COUNT(*)` and `COUNT(DISTINCT pk)` per table per partition (catches the SET-table dedup trap).
- **L3 aggregate:** `SUM`/`MIN`/`MAX`/`AVG` on every numeric column + per-partition control totals — the high-signal, cheap check that catches most issues.
- **L4 row-level checksum:** hash each row (`sha2(concat_ws(...))`) on both sides, compare the set of hashes → finds the exact rows that differ, not just "something's off." Sampled for the giant tables, full for finance-critical.
- **All of it automated** as a reconciliation job writing pass/fail + the diff to an audit table; dual-run wasn't "done" until L1–L4 were green for N consecutive days.
**R:** 99.98% parity; the 0.02% were *explainable* (documented rounding/semantic differences, signed off by finance), not unknowns. Cent-level row checksums are what let finance sign the cutover.

> 💡 **Remember:** Trap — proving correctness with only a `COUNT(*)` match (counts can tie while values are wrong). Say — "I ran a four-rung ladder — structural, volumetric, aggregate sums, then row-level checksum at the cent grain — automated to an audit table, and dual-run wasn't done until L1-L4 were green for N consecutive nights."

### Q. Tell me about a parity difference you had to chase down.

**Context:** This is where you show diagnostic depth. The classic culprits: rounding, NULL handling, collation, type coercion.

**S:** Wave-2 dual-run, a revenue mart was off by **a few cents** on ~0.3% of rows — small, but in finance "a few cents wrong" = "all of it is suspect."
**T:** Find the exact root cause, not paper over it.
**A — how I found it:**
- **L4 row-checksum** isolated the *exact* differing rows → all had fractional cents in a `unit_price * qty` calc.
- **Diffed the calc step by step** on a sample → Teradata and Spark rounded the half-cent differently at one intermediate `CAST`.
- **Root cause:** Teradata's implicit rounding at an intermediate DECIMAL cast was half-up; the transpiled Spark used a different intermediate precision → rounding diverged.
- **Fix:** pinned explicit `DECIMAL(p,s)` at every intermediate step + explicit `round()` half-up to match Teradata exactly; never let an implicit cast decide precision.
- **Then swept** for the same pattern across all converted financial calcs (fix the class, not the instance — like the main-doc "no caveats, just fix" habit).
**R:** Parity to the cent after the fix. The lesson I tell: in finance migrations, **rounding + intermediate DECIMAL precision is the #1 silent parity killer** — pin it explicitly everywhere, don't trust implicit casts.

> 💡 **Remember:** Trap — patching the one differing row instead of the *class*, or hand-waving "rounding, probably." Say — "L4 row-checksum isolated the exact rows, I diffed the calc step-by-step to a half-cent rounding diff at an intermediate CAST, pinned DECIMAL precision and round() half-up everywhere — then swept all financial calcs for the same pattern."

### Q. What else commonly breaks parity? (rapid)

- **DECIMAL → DOUBLE** anywhere = float drift = guaranteed cent diffs. Never do it.
- **NULL vs empty string** treated differently → counts + joins diverge.
- **NULL sort order** in `ROW_NUMBER`/`QUALIFY` "latest" logic → wrong record picked.
- **Case-insensitive (Teradata) vs case-sensitive (Spark) joins** → silent non-matches → row loss.
- **Timezone / timestamp semantics** (Teradata `TIMESTAMP(0)` vs Spark TIMESTAMP, session TZ) → off-by-hours.
- **Trailing-space `CHAR` padding** → string joins miss.
- **Date arithmetic** (`ADD_MONTHS` month-end behavior) differs.

> 💡 **Remember:** Trap — thinking parity breaks are random when they're a known short list. Say — "It's always one of a handful: DECIMAL→DOUBLE drift, NULL-vs-empty-string, NULL sort order, case-insensitive-vs-sensitive joins, timezone semantics, CHAR padding, or date arithmetic — I keep a checklist and sweep for each."

### Q. Build me the reconciliation framework. How did you actually engineer it — not just "we compared"?

**Context:** Interviewers push past "we reconciled" into "show me the system." This is the architecture of the parity engine itself.

**S:** 3,200 tables across 5 waves — manual SQL comparison was never going to scale or be trustworthy enough for finance sign-off.
**T:** Build a reusable, config-driven reconciliation framework that ran every night of every dual-run and produced auditable pass/fail + the exact diff.
**A — how I designed it:**
- **Config-driven, not per-table code:** one YAML/Delta config per table — `{source_table, target_table, pk_cols, numeric_cols, partition_col, recon_level, sample_pct, tolerance}`. The engine read the config and generated the comparison queries. Onboarding a new table = a config row, not new code.
- **Both-sides extraction at the same grain:** queried Teradata (via JDBC/federation) and Delta with identical aggregation SQL per partition, so I compared apples to apples (same `GROUP BY date`).
- **The ladder ran cheap→expensive with short-circuit:** L1 structural → L2 counts → L3 aggregate sums → L4 row-checksum. If L3 failed I didn't bother with the expensive L4 full-checksum until L1-L3 were green (saved compute).
- **Results to an audit Delta table:** `recon_run(table, partition, level, source_val, target_val, diff, status, run_ts)` — queryable history, the artifact finance signed off on, and the thing I checked first when a prod number was questioned later.
- **Tolerance handling:** exact-match for counts/keys; a documented, finance-approved epsilon for known rounding (never silent) — anything outside tolerance = fail + alert.
- **Gating:** a wave's "ready to cut over" flag was computed from N consecutive green nights in that audit table, not a human eyeballing.
**A — how I scaled it to 3,200 tables:** parallelized the recon jobs (the cheap L1-L3 across all tables nightly; full L4 row-checksum only on finance-critical + a rotating sample of the rest), so the nightly recon finished inside the dual-run window.
**R:** Every table had a nightly, auditable parity verdict; finance signed cutover off the audit table, not faith. The config-driven design is why wave 4's recon setup took hours, not weeks. **Whiteboard line:** "Reconciliation was a config-driven framework writing pass/fail to an audit table, ladder L1-L4 cheap-to-expensive, gating cutover on N green nights — not a pile of one-off compare scripts."

> 💡 **Remember:** Trap — describing reconciliation as one-off compare scripts that won't scale to 3,200 tables or earn finance sign-off. Say — "It was a config-driven engine — one row per table generates the comparison queries, runs the ladder cheap-to-expensive with short-circuit, writes pass/fail to an audit Delta table, and gates cutover on N green nights computed from that table, not a human eyeballing."

### Q. How did you compute the row-level checksum across two different engines without the hash itself diverging?

**Context:** The subtle trap — `MD5`/`SHA` of a row will differ across Teradata and Spark if the *string representation* of values differs (trailing spaces, decimal formatting, NULL rendering, date format) even when the data is "equal." So the checksum must normalize first.

**S:** First cut of L4 checksum showed ~everything mismatching — but the data was actually fine.
**T:** Make a cross-engine row hash that only differs when the *data* differs.
**A — how I found it:** sampled "mismatched" rows, compared field-by-field → values were equal but their canonical string forms differed (`100.50` vs `100.5`, `'AUSTIN '` vs `'AUSTIN'`, `1957-03-01` vs `1957-03-01 00:00:00`).
**A — how I fixed it:** built a **normalization contract** applied identically on both sides *before* hashing — `CAST` decimals to fixed `(p,s)` then format, `TRIM` strings, render NULL as a fixed sentinel, format dates/timestamps to a fixed pattern, fixed column order, fixed delimiter → then `SHA2(concat_ws('|', normalized_cols), 256)`. Compared the *set* of hashes (e.g. `EXCEPT` both ways) to find rows present-only-on-one-side or differing.
**R:** Mismatches dropped to the genuine handful (the rounding bug below). Lesson I tell: **a cross-engine checksum is only valid if you normalize representation first** — otherwise you're comparing formatting, not data. This one detail separates people who've actually done a finance migration from people who've read about it.

> 💡 **Remember:** Trap — hashing raw values across engines, so `100.50` vs `100.5` and `'AUSTIN '` vs `'AUSTIN'` mismatch even when the data is equal — you compare formatting, not data. Say — "I applied an identical normalization contract on both sides before hashing — fixed DECIMAL precision, TRIM, NULL sentinel, fixed date/column order — then SHA2 the concat; only then does a mismatch mean the data actually differs."

### Q. Walk the full lifecycle of migrating ONE hard table end-to-end.

**Context:** Sometimes they want the whole arc on a single concrete object, not the abstract process. Pick a gnarly one.

**S:** `canonical_sales` — the central fact, ~6 TB, a Teradata `SET` table (silent dedup), DECIMAL money columns, PI on `(retailer_id, product_id)`, PPI on `sales_date`, fed by 12 distributor BTEQ loads, joined by every finance mart.
**T:** Migrate it with zero parity loss and parity-or-better performance.
**A — the lifecycle:**
1. **Assess:** from DBQL it was the #1 most-queried table → a re-architect target, not lift-and-shift. Mapped its 12 upstream loads + all downstream consumers.
2. **DDL convert:** `DECIMAL(18,2)` preserved exactly (not DOUBLE); PPI `sales_date` → Delta **partition**; PI `(retailer_id, product_id)` → **Z-ORDER/liquid clustering**; flagged the **SET-table dedup** as my responsibility.
3. **Load logic:** the 12 BTEQ loads → dbt models; added the **explicit dedup MERGE** on natural key the SET table used to do silently; pinned DECIMAL at every intermediate step.
4. **History move:** TPT export by `sales_date` range → Parquet/S3 → Auto Loader → bronze → silver; checksum per date partition.
5. **Incremental catch-up:** CDC on the source kept it current through dual-run (idempotent MERGE, high-water mark).
6. **Reconcile:** L1-L4; **caught the cent-level rounding diff here** (next question) and fixed the class.
7. **Tune:** `EXPLAIN FORMATTED` confirmed partition pruning on `sales_date` + skipping on the cluster keys; matched Teradata's PI-join performance.
8. **Cutover:** repoint the finance marts' views from Teradata to Delta after N green nights; rollback = flip views back (source still live).
9. **Soak + decommission** weeks later.
**R:** Cent-level parity, P90 query past Teradata, zero restatement. **This single-table arc is the whole playbook in miniature** — assess → convert (semantics!) → move → catch-up → reconcile → tune → cut over → soak.

> 💡 **Remember:** Trap — jumping straight to "load the data" and skipping the assess/convert-semantics/reconcile/soak bookends. Say — "Take `canonical_sales`: assess (DBQL says re-architect), convert preserving DECIMAL + SET-dedup + PI→cluster, TPT history by date, CDC catch-up, L1-L4 reconcile, EXPLAIN-verify, repoint views after N green nights, soak then decommission — the whole playbook on one table."

---

## 7. ETL & orchestration migration

### Q. How did you migrate the ETL + scheduling?

**Context:** The EDW had a scheduler (e.g. Control-M / TWS) firing BTEQ + Informatica. You're moving both the *transforms* and the *orchestration*.

**S:** ~1,800 BTEQ jobs wired in a legacy scheduler with complex dependencies + SLAs.
**T:** Re-home transforms to dbt/Spark and orchestration to Databricks Workflows without losing the dependency graph or SLAs.
**A:**
- **Transforms → dbt-on-Databricks** (set-based SQL, version-controlled, testable) + Spark notebooks for the procedural residue.
- **Orchestration → Databricks Workflows** (the DAG), with the dependency graph lifted from the assessment lineage (§2) — not hand-rebuilt.
- **Kept the enterprise scheduler as the top-level trigger** initially (it owned cross-system SLAs) and let it kick the Databricks job via API — *pragmatic*, avoided a big-bang scheduler swap, decoupled the two migrations.
- **Encoded SLAs as Workflow alerts** + `system.workflow.job_runs` monitoring so a regression pages, same as the old scheduler's SLA alerts.
- **Asset Bundles + Terraform** so jobs/clusters were IaC, reproducible across dev/stage/prod (Dmitry's self-service/IaC lane).
**R:** Batch window 6.5h→1.8h (elastic compute + set-based rewrites). Keeping the legacy scheduler as the trigger during transition is the trade-off that de-risked it — two migrations, sequenced, not simultaneous.

> 💡 **Remember:** Trap — swapping the enterprise scheduler big-bang at the same time as the transforms, doubling the risk. Say — "I sequenced two migrations, not one: transforms to dbt/Workflows with the dependency graph lifted from assessment lineage, but kept the legacy scheduler as the top-level trigger initially since it owned cross-system SLAs."

### Q. Why dbt for the transform layer specifically?

**Context:** Justify the tool, don't just name it.

**Answer:** Version control + code review on transforms (BTEQ had none), built-in **tests** (not-null/unique/relationships) that double as reconciliation, **lineage/docs** auto-generated (replacing tribal knowledge), set-based SQL that forces you off cursor loops, and **incremental + microbatch** strategies for big facts. It made the transform layer reviewable and testable — which is exactly what a finance estate needs and Teradata BTEQ lacked.

> 💡 **Remember:** Trap — naming dbt without justifying it over plain notebooks ("it's popular"). Say — "dbt gave the transform layer what BTEQ never had: version control, code review, built-in tests that double as reconciliation, auto-generated lineage, and set-based SQL that forces you off cursor loops — exactly what a finance estate needs."

---

## 8. Performance parity & post-migration tuning

### Q. After migrating, some queries were *slower* than Teradata. How did you fix that?

**Context:** Teradata's MPP + PI is genuinely fast for its workloads; a naive Delta layout can lose to it at first. You must tune to parity.

**S:** Post-wave-1, a few heavy analyst queries ran slower on Databricks than on Teradata — credibility risk ("the new thing is worse").
**T:** Get them to parity-or-better fast, before the doubt spread.
**A — how I diagnosed:**
- **Spark UI** on the slow queries → big shuffles + full scans where Teradata had used the PI to co-locate the join.
- **Root cause:** the lift-and-shift tables had no clustering — Teradata's PI co-location was lost and not yet replaced.
- **Fix:** `OPTIMIZE ... ZORDER BY (join_key)` (later liquid clustering) to co-locate on the hot join keys; partition pruning on the date column; verified with `EXPLAIN FORMATTED`.
- **Enabled Photon** on the SQL warehouse for the analyst BI workload.
- For one repeated star-join, made sure the small dims **broadcast** so the big fact didn't shuffle.
**R:** P90 ad-hoc 45s→8s — past Teradata. The fix was reproducing the PI's *co-location* role via clustering + pruning, which a 1:1 port had dropped. Made "cluster the hot join keys" a standard post-migration step.

> 💡 **Remember:** Trap — concluding "Databricks is just slower" instead of diagnosing the dropped PI co-location. Say — "Spark UI showed big shuffles where Teradata's PI co-located the join — the lift-and-shift had no clustering. ZORDER/cluster the hot join keys, partition-prune the date, Photon, broadcast the small dims — 45s to 8s, past Teradata."

### Q. How is the Databricks performance model different from Teradata's, conceptually?

**Context:** Showing you understand *why* the tuning differs signals depth.

**Answer:**
- **Teradata:** shared-nothing MPP; rows hash-distributed across **AMPs** by the **Primary Index**; a join on the PI is local (no redistribution). Tuning = pick the right PI/PPI + collect stats.
- **Databricks/Spark:** storage (files in S3) decoupled from compute; performance comes from **file layout** (partition pruning + data skipping via Z-ORDER/liquid clustering), **shuffle** management (AQE), and **broadcast** for small dims. There's no persistent PI — co-location is a *file-layout* property you maintain with `OPTIMIZE`/clustering.
- **The mental swap:** "what's my Primary Index" becomes "what's my partition column (date) + cluster keys (hot join keys), and are my files compacted." Same goal (minimize data movement on the hot join), different mechanism.

> 💡 **Remember:** Trap — still thinking in "what's my Primary Index" terms on a decoupled storage/compute engine. Say — "Teradata co-locates by PI hash across AMPs; Spark has no persistent PI — co-location is a file-layout property you maintain with partition+clustering+OPTIMIZE, plus AQE and broadcast. Same goal, different mechanism."

---

## 9. Cutover, dual-run, rollback

### Q. Walk me through a cutover. How did you de-risk it?

**Context:** Cutover is the moment of maximum risk. The senior answer is "it was boring because of dual-run + rollback," not heroics.

**S:** Each wave ended in flipping live consumers from Teradata to Databricks.
**T:** Cut over with no data incident and an always-available escape hatch.
**A:**
- **Dual-run (parallel run)** 6 weeks: both systems ran the same loads daily; nightly reconciliation (§6) compared them. Cutover was gated on N consecutive green nights.
- **Strangler-fig consumer migration:** repointed consumers *table-by-table* (via views/synonyms — see below), not all at once. Each could be rolled back independently.
- **Rollback plan written + rehearsed:** because dual-run kept Teradata current, rollback = repoint consumers back; the source was still live and correct. Rehearsed it in a lower env.
- **Cutover runbook** with go/no-go criteria, owners, comms, and a freeze window — boring on purpose.
- **Decommission only after a stability soak** (the source stayed read-only available weeks post-cutover before we dropped it).
**R:** Zero unplanned rollback across 5 waves; the one time a consumer hit an issue post-cutover, we repointed it back in minutes (Teradata still current) and fixed forward. Dual-run + keeping the source alive is what made rollback a non-event.

> 💡 **Remember:** Trap — describing cutover as a heroic big-bang weekend with no escape hatch. Say — "Cutover was boring on purpose: 6 weeks of dual-run gated on N green recon nights, strangler-fig repoint table-by-table via views, a rehearsed rollback (source stayed live), and a go/no-go runbook — decommission only after a soak."

### Q. How did consumers point at the data so you could swap underneath them?

**Context:** The strangler-fig mechanic. An **abstraction layer** lets you swap the backend without the consumer knowing.

**Answer:**
- Consumers queried **views / a semantic layer**, not physical tables directly, so I could repoint a view from Teradata (via federation) to the Delta table without changing consumer SQL.
- During dual-run the view pointed at Teradata; at cutover, flip the view to Delta; rollback = flip back.
- **Lakehouse Federation / query federation** let some consumers query Teradata *through* Databricks during transition, smoothing the move.
- This is the strangler fig: new system grows behind a stable interface until the old one is fully strangled, then removed.

> 💡 **Remember:** Trap — having consumers hit physical tables directly, so swapping the backend means rewriting every consumer's SQL. Say — "Consumers queried a view/semantic layer, never physical tables — so cutover was flipping a view from Teradata-federated to Delta, and rollback was flipping it back. That indirection *is* the strangler fig."

### Q. What were your go/no-go criteria for cutover?

**Answer (memorize):** (1) **N consecutive nights of green reconciliation** (L1–L4) including cent-level finance parity; (2) **performance parity-or-better** on the wave's top queries; (3) **all consumers repointed + smoke-tested** in stage; (4) **rollback rehearsed**; (5) **owners + comms + freeze window** scheduled; (6) **sign-off from the data owner + finance** for that domain. Any red = no-go, slip the date. Pragmatic but not reckless.

> 💡 **Remember:** Trap — vague "it looked good" criteria instead of objective, pre-agreed gates. Say — "Six hard gates: N green recon nights at cent parity, perf parity-or-better, consumers repointed and smoke-tested, rollback rehearsed, comms/freeze scheduled, and data-owner + finance sign-off — any red is a no-go and we slip."

---

## 10. Workload management & cost

### Q. Teradata had TASM for workload management. What's the Databricks equivalent?

**Context:** TASM (Teradata Active System Management) prioritizes/throttles queries on a fixed box. Databricks decouples compute, so the model is different — and usually cheaper.

**Answer:**
- **The core shift:** Teradata = one fixed box, so you *ration* it (TASM priorities, throttles, the month-end contention). Databricks = elastic compute, so instead of rationing you **isolate + autoscale** — give workloads their own compute.
- **Mapping:** TASM workload classes → **separate clusters / SQL warehouses per workload** + **cluster policies** (caps, instance types, autoscaling bounds) + **pools** for fast start. Heavy batch ≠ analyst ad-hoc ≠ data science, each on its own compute, so they don't contend.
- **Serverless SQL** for BI = no more month-end throttling (it scales out), the pain that drove the migration.
- **Cost control** via cluster policies (max workers, auto-terminate), mandatory **tags**, and `system.billing.usage` dashboards.
**R:** Month-end throttling disappeared (analysts got their own elastic warehouse), and cluster policies kept the elasticity from becoming a cost free-for-all.

> 💡 **Remember:** Trap — looking for a 1:1 "TASM equivalent" instead of recognizing the model flips from rationing to isolation. Say — "On a fixed box you ration with TASM; on elastic compute you isolate and autoscale — separate clusters/SQL warehouses per workload, cluster policies as guardrails, serverless for BI so month-end throttling just disappears."

### Q. How did you actually hit the ~62% cost reduction — and keep elastic compute from blowing the budget?

**Context:** Elastic compute cuts cost *or* explodes it depending on governance. This is Dmitry's exact wheelhouse ($5M savings, cost dashboards).

**S:** Lift-and-shift workloads naively run on always-on clusters would have erased the savings.
**T:** Realize the storage/compute-decoupling savings without a runaway DBU bill.
**A:**
- **Autoscale + auto-terminate** everywhere; batch clusters scale to zero off-peak (vs Teradata's 24/7 hardware).
- **Right-sized via the sample-then-measure method** (10% sample → shuffle math → workers), not guesswork.
- **Cluster policies** as guardrails: max workers, allowed instance types, mandatory auto-terminate, mandatory cost tags — self-service within rails (his −75%-manual-provisioning pattern).
- **Photon** for CPU-heavy SQL (more work per DBU); measured the win in `system.billing.usage`.
- **Job clusters (ephemeral) for batch**, not all-purpose clusters left running.
- **Chargeback dashboard** by tag so each team saw its spend → behavioral savings.
**R:** $4.2M/yr → $1.6M/yr. The governance (policies + tags + dashboards) is what made the savings *stick* instead of eroding as teams self-served.

> 💡 **Remember:** Trap — claiming the cloud is "automatically cheaper" while always-on clusters quietly erase the savings. Say — "Decoupling cuts cost *only* with governance: autoscale + auto-terminate + ephemeral job clusters for the savings, then cluster policies, mandatory tags, and chargeback dashboards to make them stick — $4.2M to $1.6M."

---

## 11. Governance & security (roles → Unity Catalog)

### Q. How did you migrate Teradata's security model?

**Context:** Teradata has database-level roles/grants; Databricks governance is **Unity Catalog** (catalog→schema→table grants, lineage, audit). Don't just re-create grants — modernize.

**S:** Hundreds of Teradata roles/grants, plus row/column access patterns done ad hoc.
**T:** Reproduce least-privilege access in Unity Catalog, auditable.
**A:**
- **Extracted existing grants** from `DBC.AllRights`/`DBC.RoleMembers` → mapped to UC catalogs/schemas/grants.
- **Modeled to UC's hierarchy** (catalog per domain, schema per layer) rather than a flat 1:1 port — cleaner least-privilege.
- **Row/column security → UC row filters + column masks** (centralized, not scattered view logic).
- **Identity via SCIM** from the IdP (groups, not individual users) so access is group-managed.
- **Lineage + audit** came free from UC (replacing Teradata's manual access reviews).
- All grants as **Terraform** (databricks provider) → reproducible, reviewed.
**R:** Least-privilege preserved + auditable, access as code. Mapping to UC's hierarchy (not a flat port) is what made it maintainable.

> 💡 **Remember:** Trap — flatly recreating every Teradata grant 1:1 and managing access per individual user. Say — "I extracted grants from DBC.AllRights but modeled them to UC's hierarchy (catalog per domain, schema per layer), row filters/column masks instead of scattered view logic, SCIM groups not users, all as Terraform — modernize, don't transcribe."

---

## 12. BI / consumer repointing

### Q. How did you move Tableau/Looker/Informatica consumers without breaking them?

**Context:** Consumers are where a migration becomes visible to the business. Break a CFO dashboard and the whole program loses trust.

**S:** Dozens of Tableau workbooks + Looker models + Informatica jobs pointed at Teradata.
**T:** Repoint them with zero visible breakage.
**A:**
- **Inventoried every consumer → table** dependency in assessment (§2) so nothing was a surprise at cutover.
- **Repointed via the view/semantic layer** (strangler fig) so most consumers just changed a connection, not their SQL.
- **Validated dashboards number-for-number** against Teradata during dual-run (a dashboard showing a different total = instant credibility loss).
- **Looker/dbt semantic layer** centralized metric definitions so "revenue" meant one thing post-migration.
- **Repointed in waves with the owning team**, smoke-tested, kept rollback.
**R:** No dashboard showed a wrong number at cutover (validated during dual-run). The view-layer indirection is what made repointing a connection-string change, not a rebuild.

> 💡 **Remember:** Trap — repointing dashboards without validating the numbers, so a CFO sees a different total and the program loses trust. Say — "I inventoried every consumer→table dependency, repointed via the view layer so it was a connection change not a rebuild, and validated dashboards number-for-number against Teradata during dual-run before any flip."

---

## 13. People: stakeholders, training, mentorship, resistance

> Dmitry weights culture + mentorship heavily ("culture is infrastructure", grew a team 1→15). Have real people answers.

### Q. There was resistance — DBAs and analysts comfortable with Teradata. How did you handle it?

**S:** Senior Teradata DBAs saw the migration as eliminating their expertise; analysts feared their SQL/dashboards breaking.
**T:** Convert skeptics into owners, not casualties.
**A:**
- **Brought DBAs in as the reconciliation + parity authority** — their deep Teradata knowledge was exactly what caught the SET-table and rounding traps. Reframed their expertise as essential, not obsolete.
- **Analysts:** ran hands-on Databricks SQL sessions, showed their exact dashboards working faster, and kept their SQL working via the view layer.
- **Over-communicated the why + the safety net** (dual-run, rollback) so it felt safe, not imposed.
- **Honesty:** named what *would* be harder (some Teradata-specific tricks don't translate) instead of overselling.
**R:** The lead DBA became the parity gatekeeper and our most effective advocate. Reframing expertise as essential (not threatened) is what flipped the resistance.

> 💡 **Remember:** Trap — treating skeptical DBAs/analysts as obstacles to route around. Say — "I made their Teradata expertise essential, not obsolete — the DBAs became the parity authority (they caught the SET-table and rounding traps), and the lead skeptic became our best advocate."

### Q. How did you mentor the team through tech they didn't know?

**S:** Team was strong in Teradata/SQL, new to Spark/Delta/dbt.
**T:** Level them up without becoming the bottleneck.
**A:**
- **Pairing on the first conversions**, then a **fix-pattern library + runbook** so they were self-sufficient (self-service, Dmitry's value).
- **Code review as teaching** — explained the *why* (why cluster not partition the join key), not just the fix.
- **Was wrong publicly** when I was (a partitioning choice I had to reverse) so the team felt safe being wrong → faster learning.
- Rotated who owned each wave so knowledge spread, not siloed.
**R:** Wave 4 ran in half the time of wave 1, led mostly by the team with me advising. The runbook + "be wrong publicly" culture is what made it scale beyond me.

> 💡 **Remember:** Trap — becoming the hero/bottleneck who personally does every conversion. Say — "I leveled them up to replace me: pair on the first conversions, then a fix-pattern library + runbook, code review as teaching (the *why*, not just the fix), and being wrong publicly so they felt safe — wave 4 ran team-led in half wave 1's time."

---

## 14. Scenario / war-story questions

### Q. Mid-migration, finance says a migrated number is wrong in production. Go.

**S:** Post-cutover, finance flags a revenue total off vs their records.
**A:**
- **First: is it a migration bug or a source change?** Check the reconciliation audit table for that table/date — was it green at cutover?
- **If green at cutover:** the divergence is *new* → check what changed since (a source CR, a late-arriving restatement) — likely not the migration.
- **If it was never truly green** (a sampled check missed it): row-checksum the exact rows, isolate the calc, find the semantic diff (rounding/NULL/cast), fix the class, re-reconcile.
- **Communicate continuously**; if it's material, the source is still available (we soak before decommission) → I can prove the correct number either way.
- **Postmortem + add the missed check** to the reconciliation suite.
**R (framing):** "Because we kept dual-run reconciliation history and the source alive during soak, I can always answer 'was it us or a real change' with evidence — not opinion."

> 💡 **Remember:** Trap — panicking and assuming "the migration broke it" before checking whether it was ever green. Say — "First I check the recon audit table — was that table/date green at cutover? If yes, the divergence is new (a source CR or restatement); if it was never truly green, row-checksum the exact rows and fix the class — evidence, not opinion."

### Q. You're 8 months in and behind schedule. What do you cut?

**A:** Re-scope, don't crash quality. **Protect** reconciliation + dual-run (non-negotiable in finance). **Cut/defer** the low-value lift-and-shift long tail (or leave it on the source longer / federate it). **Re-tier** with fresh DBQL usage data — maybe more tables are dead now. Re-forecast transparently with options + trade-offs for leadership to choose. **Pragmatic over perfect.**

> 💡 **Remember:** Trap — "crashing" the schedule by cutting reconciliation/dual-run to save time (catastrophic in finance). Say — "I re-scope, never crash quality: protect reconciliation and dual-run, defer or federate the low-value lift-and-shift tail, re-tier with fresh DBQL usage, and re-forecast transparently with options for leadership to choose."

### Q. A stored proc's logic is undocumented and the author left. How do you migrate it?

**A:** Treat the proc as the spec but verify by behavior: capture its **inputs→outputs** on production data, rewrite as set-based dbt/Spark, and **reconcile the new output to the old proc's output** on the same inputs until they match. The reconciliation *is* the validation that I captured the intent — I don't need the docs if I can prove output parity.

> 💡 **Remember:** Trap — refusing to migrate (or guessing) because the proc is undocumented and the author is gone. Say — "The proc *is* the spec — I capture its inputs→outputs on production data, rewrite set-based, and reconcile new output to old on identical inputs until they match; output parity proves I captured the intent, docs or not."

### Q. Cutover weekend: reconciliation goes red at 2 AM. What do you do?

**A:** **No-go, don't force it** — slip is cheaper than a wrong finance number. Triage with the recon diff (which table, which rows, structural vs aggregate vs row-level), decide if it's a quick known-pattern fix (rounding/NULL) or unknown. If unknown → abort cutover, stay on Teradata (still live), root-cause Monday. Rollback is a non-event because we never decommissioned the source. Comms to stakeholders immediately with the new plan.

> 💡 **Remember:** Trap — forcing the cutover at 2 AM to "hit the date" with a red reconciliation. Say — "No-go, don't force it — a slipped date is cheaper than a wrong finance number. Triage the diff; if it's not a known-pattern quick fix, abort, stay on Teradata (still live), comms immediately, root-cause Monday — rollback is a non-event."

---

## 15. Hard rapid-fire + flashcards

| Prompt | Crisp answer |
|---|---|
| SET vs MULTISET | SET dedups silently; Delta doesn't → add explicit MERGE dedup on natural key + count-distinct recon. |
| #1 parity killer | Intermediate DECIMAL precision + rounding mode. Pin `DECIMAL(p,s)` + explicit `round()` everywhere; never DECIMAL→DOUBLE. |
| Primary Index maps to | Nothing 1:1. Date→partition, hot join key→Z-ORDER/liquid clustering. Co-location becomes file layout. |
| TASM maps to | Separate clusters/SQL warehouses + cluster policies + pools + serverless. Isolate+autoscale, don't ration. |
| BTEQ converts to | dbt models (set-based) + Spark notebooks (procedural residue), orchestrated by Workflows. |
| Reconciliation ladder | L1 structural → L2 count/count-distinct → L3 aggregate sums → L4 row checksum (cent grain for finance). |
| Cutover pattern | Dual-run (parallel) gated on N green recon nights + strangler-fig repoint via views + rehearsed rollback. |
| Rollback works because | Dual-run keeps source current + we soak before decommission → repoint back = minutes. |
| Move 40TB | TPT parallel export → Parquet/S3 partitioned by date → Auto Loader/COPY INTO → checksum per partition. |
| Keep current till cutover | CDC/incremental MERGE (idempotent, high-water mark); full final delta at cutover. |
| QUALIFY | Teradata filter-on-window; Spark supports it; verify older transpiles didn't change semantics. |
| Case sensitivity | Teradata LATIN = case-insensitive joins; Spark = case-sensitive → normalize case on load or lose rows. |
| NULL ordering | Differs by default → make `NULLS FIRST/LAST` explicit in ROW_NUMBER "latest" logic. |
| Why not big-bang | Blast radius. Strangler-fig per-domain waves along the dependency graph, each independently rollback-able. |
| Lift-shift vs re-arch | Decommission dead (DBQL usage), lift-shift the used tail, re-architect the hot ~400 for the perf/cost win. |
| Slower-than-Teradata fix | Lost PI co-location → ZORDER/cluster the hot join key + partition prune + Photon + broadcast dims. |
| Cost win | Autoscale+auto-terminate+job clusters + cluster policies + tags + `system.billing.usage` chargeback. |
| Security | `DBC.AllRights` → Unity Catalog grants/row-filters/column-masks, SCIM groups, all as Terraform. |
| Moving-train problem | Narrow per-wave freeze + CDC keeps in-flight tables current + CI schema-diff guard on source DDL. |
| Estimate credibly | Pilot wave → measured velocity × complexity buckets, bottom-up + named contingency, re-forecast per wave. |

### Pre-interview checklist (migration)
- [ ] Memorize: **3,200 tables · 1,800 BTEQ · 40 TB · $4.2M→$1.6M · 99.98% parity · 6.5h→1.8h · zero rollback**
- [ ] One-liner (top of doc) in 30 seconds
- [ ] The reconciliation ladder L1–L4 cold (the most-probed area)
- [ ] One real parity war-story (the rounding/DECIMAL one) with how you *found* it
- [ ] SET-table + Primary-Index answers (the two Teradata gotchas)
- [ ] For Dmitry: cost ($4.2M→$1.6M, how it stuck), IaC (Terraform/Asset Bundles), self-service (cluster policies), mentorship (1 wave → team-led by wave 4), trade-off framing (pragmatic re-scope)

---

## 16. Source-specific cheat sheet

> If your real migration was Redshift or Oracle, swap the gotchas. The strategy/reconciliation/cutover chapters are identical.

### Teradata → Databricks (this doc's anchor)
- **Gotchas:** SET vs MULTISET dedup · Primary Index/PPI → partition+cluster · BTEQ/macros/stored procs · QUALIFY · DECIMAL rounding · case-insensitive collation · NULL ordering · period/interval types · TASM → cluster policies.
- **Tools:** TPT (export), BladeBridge/LakeBridge/SQLGlot (transpile), DBQL (usage mining).

### Redshift → Databricks
- **Gotchas:** **DISTKEY/SORTKEY** (Redshift's co-location) → partition + Z-ORDER/liquid clustering (direct analog to the PI story) · `VACUUM`/`ANALYZE` rhythm → `OPTIMIZE`/stats · Redshift Spectrum external tables → UC external tables · `IDENTITY` columns · `SUPER`/JSON handling · stricter `VARCHAR` byte-length limits · serializable isolation differences · UNLOAD to S3 (the export path, analog to TPT).
- **Tools:** `UNLOAD` to Parquet/S3, then COPY INTO/Auto Loader; SQLGlot/LakeBridge transpile; STL/SVL system tables for usage mining.

### Oracle → Databricks
- **Gotchas:** **PL/SQL packages + procedures** (heaviest rewrite — procedural → set-based dbt/Spark) · `NUMBER` precision → `DECIMAL` (don't lose to DOUBLE) · **`''` = NULL in Oracle** (Oracle treats empty string AS null — opposite-ish of Teradata; big parity trap) · `ROWNUM`/`CONNECT BY` hierarchical → window/`WITH RECURSIVE` · `MERGE` semantics · sequences → IDENTITY · `DATE` carries time · materialized views · partitioning syntax · case-sensitive by default (unlike Teradata).
- **Tools:** GoldenGate / DataPump / Spark JDBC bulk extract; SQLGlot/vendor transpile for PL/SQL; `V$SQL`/AWR for usage mining.

---

*Last updated: 2026-05-28*
