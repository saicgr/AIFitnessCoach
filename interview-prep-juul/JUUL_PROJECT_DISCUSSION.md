# Juul Project — Quick Talk Track (SnapLogic · Databricks · Power BI)

## 1. What is the project?
> "At Juul I own the data platform behind sales, finance, and ops reporting. Data lived in disconnected systems — Salesforce, SAP HANA, SFTP file drops, REST APIs — and analysts stitched it in Excel. I built the pipeline end to end: **SnapLogic** integrates all the sources, **Databricks** (Delta Lake, bronze/silver/gold) cleans and models the data, and **Power BI** is the dashboard layer. Result: ~45% less manual data movement, 99% pipeline SLA, reporting went from hours to minutes."

## 2. What do you do day to day?
> "Build and maintain SnapLogic pipelines for new sources, write the Databricks PySpark / SQL transforms, and build Power BI models and dashboards. Morning I check SnapLogic Monitor and Databricks overnight runs and triage any failures. Then it's a mix of build work, a stakeholder sync with sales ops or finance to turn a request into a model, and pushing changes through Dev→Test→Prod."

## 3. Walk me through a SnapLogic pipeline.
> "A **Scheduled Task** polls the source on a cadence (or a **Triggered Task** exposed as a REST endpoint for on-demand). I read with the **REST / SFTP / Snowflake Snap Pack**, use a **Mapper Snap** to shape fields, a **Filter Snap** to drop bad records, a **Router Snap** to branch by type, then **land raw to ADLS Gen2 as Parquet** (the bronze layer) and to Snowflake where a source needs it. Anything that fails routes to an **error pipeline** that quarantines the bad record and alerts. SnapLogic stops there — it's the **integration/landing layer**. Databricks picks up bronze and does the heavy transformation."

**Why SnapLogic lands, Databricks transforms:** SnapLogic is a document-flow integration tool — great at connecting systems and light shaping, weak at big set-based joins/aggregations and stateful history (CDC/SCD). Those run cheaper and faster in Spark. So: *light transform in SnapLogic, heavy transform in Databricks.*

## 4. How do you make pipelines reusable?
> "Parameterized **child pipelines** called with the **Pipeline Execute Snap** — one ingestion pattern serves 12+ sources, so onboarding a new feed is config, not new code. Cut build time ~35%."

## 5. How do you handle errors?
> "Every pipeline has an **error pipeline** attached, plus **retry logic** on transient failures, a **quarantine table** for bad rows, and centralized logging + alerting. Cut incident resolution time ~40%."

---

## SnapLogic terms to actually say
- **Designer / Manager / Monitor** — build canvas / assets & tasks & credentials / runtime health & alerting.
- **Snaplex** — the execution grid that runs pipelines (Groundplex = self-managed for on-prem/VNet like SAP HANA; Cloudplex = managed).
- **Snap** — a single step; **Snap Pack** = a connector bundle (REST, Snowflake, JDBC, Azure Blob).
- **Core Snaps:** Mapper, Router, Filter, Join, Aggregate, File Reader/Writer.
- **Tasks:** Scheduled (batch), Triggered (API endpoint), Ultra (low-latency streaming).
- **Pipeline Execute Snap** — calls a child pipeline → reusable templates.
- **Error pipeline** — attached failure path for retry / quarantine / alerting.

## Databricks one-liners
- **Medallion:** Bronze (raw) → Silver (cleaned, deduped, CDC/SCD) → Gold (business models), on **Delta Lake**.
- **Delta Live Tables** with **expectations** = data-quality rules enforced in the pipeline.
- **Unity Catalog** = governance (RBAC, row-level security, lineage).
- **Perf/cost:** OPTIMIZE, Z-ORDER, partition pruning, Auto Loader, Photon → ~60% faster, ~35% cheaper.

## Power BI one-liners
- Star-schema **semantic model** on the gold layer, **DAX** measures, **drill-through** pages, **row-level security**, **KPI scorecards**.
- Import mode off gold tables for speed; DirectQuery to Databricks/Snowflake when data's large or near-real-time.

---

## End-to-end pipeline (say this when they ask "walk me through the whole flow")
> "Source systems → **SnapLogic** ingests and lands raw to bronze → **Databricks** promotes bronze→silver→gold → **Power BI** serves the dashboards. Every layer ships through **Azure DevOps** CI/CD across Dev→Test→Prod."

```
SOURCES        Salesforce · SAP HANA · SFTP · Box · Email attachments · REST/SOAP APIs · CSV/JSON/Parquet
                 │
INTEGRATION    SnapLogic  ──(Scheduled Task polls / Triggered Task = REST endpoint)
                 │  Mapper → Filter → Router → light Join;  error pipeline → quarantine + alert
                 ▼
LANDING        ADLS Gen2  (Bronze, Parquet)   +  Snowflake (where a source needs it)
                 │
TRANSFORM      Databricks  (Delta Lake / DLT / PySpark / Spark SQL)
               Bronze ─► Silver (clean, dedupe, DQ expectations, CDC, SCD1/2) ─► Gold (star schema)
               governed by Unity Catalog (RBAC, RLS, lineage);  tuned w/ Z-ORDER, partition pruning, Photon
                 ▼
BI             Power BI  (semantic model · DAX · drill-through · RLS · KPI scorecards)
                 ▼
CONSUMERS      Sales · Finance · Customer Success
```

### CI/CD with Azure DevOps (how each layer deploys)
- **SnapLogic:** pipelines/tasks are assets in **Projects**. Export them (via the **SnapLogic Metadata/Public API** as `.slp`), version in **Git**, and an **Azure DevOps release pipeline** promotes them across orgs (Dev → Test → Prod) by calling the SnapLogic API and swapping environment-specific **Project parameters / account credentials** per stage.
- **Databricks:** code lives in **Databricks Repos** (Git-backed). Azure DevOps deploys notebooks/jobs/DLT via the **Databricks REST API** (or Asset Bundles), with **Terraform** provisioning clusters/jobs and env config.
- **Power BI:** **Power BI Deployment Pipelines** (or the Power BI REST API from Azure DevOps) promote datasets/reports Dev→Test→Prod, repointing data source connections per stage.
- One sentence to say: *"Everything is Git-backed and promoted through Azure DevOps release pipelines across Dev/Test/Prod — SnapLogic via its Metadata API, Databricks via Repos + REST API + Terraform, Power BI via deployment pipelines."*

---

## "What triggers the file landing in Azure Blob?" (they may ask this specifically)
- **Scheduled Task** — cron-like, time-based. Most batch landing to ADLS runs this way (e.g. nightly).
- **Triggered Task** — pipeline exposed as a **REST/HTTP endpoint**; an external system or another pipeline calls the URL to kick it. On-demand / event-driven.
- **Ultra Task** — always-on, low-latency, streaming-style.
- Picking up *source* files (SFTP/Box): SnapLogic **polls on a schedule** — a Scheduled Task runs, a **Directory Browser Snap** lists new files, then processes them. (No native "watch a folder" event; it's poll-based.)

## "Does SnapLogic support Box / email attachments / more?"
> "Yes — 700+ pre-built Snaps. **Box Snap Pack** for Box files, **Email Snap Pack** (Email Reader pulls messages *and attachments*; Email Sender for alerts), **SFTP/FTP**, **S3 / Azure Blob / GCS**, plus SaaS like Salesforce, SAP, Workday, ServiceNow, SharePoint, and generic REST/SOAP/Kafka. Most source onboarding is configuration, not custom code."

---

## What "basic transformations" SnapLogic does (vs what Databricks does)
SnapLogic does **per-record, streamable shaping** — not big compute:
- **Field mapping / rename** (Mapper) — `cust_id` → `customer_id`
- **Type casting** — string → int / date / decimal
- **Derived fields** — concatenation, IF expressions, formatting, normalizing
- **Filtering** (Filter) — drop nulls / test / invalid rows
- **Routing** (Router) — branch by record type
- **Parsing & structuring** — CSV/JSON/XML parse, flatten nested arrays
- **Format conversion** — CSV → JSON → Parquet on write
- **Light lookups** (Join) — enrich against a *small* reference set

> Rule: **light per-record transform in SnapLogic, heavy set-based work (big joins, aggregations, CDC/SCD) in Databricks/Spark.**

## "What if the file is 10GB?" (high-value answer)
> "SnapLogic **streams documents**, so it handles large files *as long as I avoid blocking Snaps* — **Sort, Aggregate, Join, Group By** buffer the whole dataset in memory and OOM the Snaplex node. For a 10GB file my default is to use SnapLogic as a **mover**: a **binary pass-through** (File Reader → File Writer, no parsing) lands the raw file in ADLS bronze, then **Databricks/Spark** does the heavy transform in parallel. If I must do light per-record work, I keep the path streaming (read → map → filter → write), push any aggregation/join downstream, and scale/split across Snaplex nodes."

Three points to hit: (1) SnapLogic streams; (2) blocking Snaps (Sort/Aggregate/Join) cause the OOM; (3) right move is land-raw + defer heavy compute to Spark.

---

## Challenges faced & how I resolved them — STAR format

### STAR 1 — Pipelines blowing the SLA + compute bill
- **S:** Overnight Databricks loads kept missing the SLA and the compute bill was climbing; analysts had stale data each morning.
- **T:** Get the loads back inside the SLA window and cut cost without re-architecting everything.
- **A:** Profiled the jobs and found full table scans on date filters and full reloads each run. Added **Z-ORDER** on high-cardinality filter columns + **partition pruning** on date, switched ingestion to **Auto Loader** incremental instead of full reloads, enabled **Photon**, and moved aggregations out of SnapLogic into Spark where they parallelize.
- **R:** Runtime dropped **~60%**, Databricks/Snowflake compute **~35%**, and we stopped missing the SLA.

### STAR 2 — Finance numbers didn't reconcile (data quality)
- **S:** Finance flagged that dashboard revenue didn't tie out to their books.
- **T:** Find the root cause and stop bad data reaching the gold layer.
- **A:** Traced it to un-deduped CDC records double-counting in silver, plus dimension changes overwriting history. Added **DLT expectations** to enforce keys with a **quarantine table** for violators, and reworked the dimension as **SCD Type 2** so history was tracked instead of overwritten.
- **R:** Downstream defects dropped **~40%**, the numbers reconciled, and finance trusted the dashboard again.

### STAR 3 — Large-file ingest OOM'ing the Snaplex
- **S:** A new partner feed shipped multi-GB files; the ingestion pipeline kept failing with out-of-memory errors.
- **T:** Ingest the large files reliably without exploding the Snaplex or the runtime.
- **A:** Found a **Sort + Aggregate** in the pipeline path forcing the whole file into memory. Removed the blocking Snaps, switched to a **streaming binary pass-through** that lands raw to ADLS bronze, and moved the sort/aggregation into **Databricks** where Spark parallelizes it. Right-sized the Snaplex node for headroom.
- **R:** Ingestion went green and stayed inside SLA; large files no longer OOM, and the heavy compute runs cheaply in Spark.

### STAR 4 — Inconsistent, copy-pasted pipelines (maintainability)
- **S:** Every new source was a hand-built pipeline; failure behavior and logging differed each time, and onboarding was slow.
- **T:** Standardize ingestion so new sources are fast and behave consistently.
- **A:** Built **parameterized child-pipeline templates** called via the **Pipeline Execute Snap** (read → standardize → validate → land), with shared **error/logging** child pipelines so a fix lands in one place. New sources became configuration, not new development.
- **R:** New pipeline build time dropped **~35%**, onboarding 12+ sources onto one pattern, and every pipeline failed the same predictable way.

### STAR 5 — Production failures were slow to diagnose (observability)
- **S:** When a pipeline failed at night, on-call spent hours figuring out *what* failed and *why*.
- **T:** Cut incident resolution time and give the team one place to see failures.
- **A:** Attached **error pipelines** at the Snap level routing bad records (with reason + timestamp) to a central log/quarantine table, added **retry logic** on transient API/JDBC failures, and wired **alerting** off SnapLogic Monitor on task failures and SLA breaches.
- **R:** Incident resolution time dropped **~40%** and the team got real operational visibility instead of guessing.

### STAR 6 — Vague stakeholder ask (ambiguity / business translation)
- **S:** Sales ops asked for "better visibility" with no defined metrics — a recipe for building the wrong thing.
- **T:** Turn an ambiguous request into something they'd actually use.
- **A:** Ran a couple of working sessions to pin down the *decisions* they were making, turned that into KPI definitions + a **star-schema** model + a **drill-through** Power BI dashboard, and agreed **acceptance criteria** with QA before building.
- **R:** Reporting turnaround went from hours to minutes and the dashboard got adopted instead of ignored.

> Tip: pick **2-3** of these to tell, matched to whatever the interviewer drills into (perf → STAR 1, data quality → STAR 2, SnapLogic depth → STAR 3/4, soft skills → STAR 6). Lead with the result, then the action.

---

---

## Resume bullet decoded — the reusable-templates story
> *"Built reusable SnapLogic pipeline templates using Designer, Manager, Snap Packs, Mapper/Router/Filter/Join/Aggregate/File Reader/File Writer Snaps, JDBC/REST/Snowflake/Azure Blob Snap Packs, standardizing ingestion across 12+ source systems and cutting new pipeline build time 35%."*

Be ready to explain **every term** in it:

| Term | What it is / why I used it |
|---|---|
| **Designer** | Visual canvas where I built the pipelines (drag Snaps, wire, configure). |
| **Manager** | Where assets/projects/tasks/credentials live; how I organized reusable child pipelines and deployed across orgs. |
| **Snap Pack** | A connector bundle (a group of Snaps for one system). |
| **Mapper Snap** | Shape/rename/cast fields to our canonical schema — the workhorse transform. |
| **Router Snap** | Branch records down different paths by type/condition. |
| **Filter Snap** | Drop bad/test/invalid rows (keep only what passes). |
| **Join Snap** | Enrich a stream against a reference dataset (small side). |
| **Aggregate Snap** | Pre-rollups (sum/count/group) where needed — used sparingly (blocking Snap). |
| **File Reader Snap** | Read files from SFTP/Blob/local (streaming). |
| **File Writer Snap** | Write output files (Parquet to ADLS bronze). |
| **JDBC Snap Pack** | Read/write relational DBs (SQL Server, Oracle, SAP via JDBC). |
| **REST Snap Pack** | Consume/expose REST APIs (pagination, auth, rate limits). |
| **Snowflake Snap Pack** | Bulk read/write to Snowflake (uses staging for speed). |
| **Azure Blob Storage Snap Pack** | Read/write ADLS Gen2 / Blob — where I land bronze Parquet. |

**The reuse mechanism (say this):** *"The 'template' is a parameterized **child pipeline** — read → standardize → validate → land — called via the **Pipeline Execute Snap**. Source-specific values (connection, path, schema) are **pipeline parameters**, so one template serves 12+ sources. Common error/logging logic is its own shared child pipeline, so a fix lands in one place. New source onboarding became configuration, not new development — ~35% less build time."*

---

## Curveball follow-ups (be ready, one or two lines each)

### Q: How do you size a Snaplex?
> "By workload and data locality. **Groundplex** when I need to reach on-prem/VNet sources like SAP HANA behind the firewall; **Cloudplex** for cloud-only flows. I size node **memory** for the heaviest pipeline (blocking Snaps like Sort/Aggregate need headroom), and add **nodes** for parallelism/throughput and HA. If a pipeline OOMs, first question is 'is a blocking Snap forcing the whole dataset into memory' before I just throw bigger nodes at it."

### Q: Import vs DirectQuery in Power BI — how do you choose?
> "**Import** by default — data's cached in the model, fastest interaction, full DAX. I use it off the gold layer with scheduled refresh. **DirectQuery** when the data's too big to import, needs near-real-time freshness, or governance requires it stay in the source. Trade-off: DirectQuery is fresher but slower and pushes load onto Databricks/Snowflake. Because I model heavily in the gold layer, Import usually wins."

### Q: How do you handle a late-arriving file / late-arriving data?
> "Two angles. **Late file:** the Scheduled Task polls on a cadence, so a file that lands after the run gets picked up next cycle; I make ingestion **idempotent** (keyed upserts / `MERGE`) so reprocessing doesn't double-count. **Late-arriving *data*** (out-of-order events, a dimension row that shows up after the fact): I handle it in Databricks with **CDC ordering by a sequence column** and **SCD Type 2** so history stays correct, plus a quarantine table for records that can't resolve yet."

### Q: Why not just Snowflake (or just Databricks)?
> "Different jobs. **Databricks** is my transformation/ML engine — heavy Spark joins, medallion modeling, CDC/SCD, data quality. **Snowflake** is the serving layer — simple SQL, high concurrency, low ops for the business and BI. I land with SnapLogic, transform/model in Databricks, publish curated gold to Snowflake for Power BI. Each does what it's best at; that split also kept cost down (heavy batch on Databricks job clusters, interactive querying on Snowflake). There's overlap and consolidating is a fair conversation — but with existing Snowflake adoption it was the lower-risk, better-performing serving layer."

### Q: How do you guarantee you don't lose or double-process records?
> "Idempotent loads — natural/business keys with `MERGE`/upsert into Delta, so re-running a file is safe. Bronze is append-only with the source filename + load timestamp for lineage, and the error pipeline quarantines rejects rather than dropping them silently, so nothing disappears without a trace."

### Q: Batch vs streaming — when each?
> "Most feeds are **batch** (Scheduled Tasks, nightly/hourly) — sales/finance reporting doesn't need sub-minute freshness. For genuinely event-driven sources I expose a **Triggered Task** (REST endpoint) or use an **Ultra Task** for low-latency, and on the Databricks side **Auto Loader / Structured Streaming** for incremental. I don't stream where batch is enough — it's cheaper and simpler."

### Q: How do you test a pipeline / what's your validation strategy?
> "**DLT expectations** for in-pipeline data-quality rules (row counts, null/key checks, ranges), reconciliation checks against source totals, and acceptance criteria agreed with QA before build. In CI I promote Dev→Test→Prod via Azure DevOps and validate against a test dataset in the Test org before prod."

---

## Headline numbers (keep consistent)
45% less manual movement · 99% SLA · 60% faster runtimes · 35% compute saved · 40% better data quality.
