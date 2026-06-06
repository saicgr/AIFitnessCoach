# Juul — 1-Page Cram Sheet (read 10 min before the call)

## The pitch (memorize)
Own the data platform for sales/finance/ops. **SnapLogic** integrates sources → **Databricks** (Delta Lake, bronze/silver/gold) cleans & models → **Power BI** dashboards. Result: **45% less manual movement · 99% SLA · hours→minutes reporting.**

## Numbers (say these, keep consistent)
45% less manual · 99% SLA · 60% faster · 35% cheaper compute · 40% better data quality

## Tool boundary (the line that wins interviews)
**SnapLogic = integration/landing. Databricks = heavy transform/ML. Snowflake = SQL serving.**
*Light transform in SnapLogic, heavy set-based work in Spark.*

## Flow
Sources (Salesforce · SAP HANA · SFTP · Box · Email · REST) → **SnapLogic** lands raw Parquet to **ADLS bronze** → **Databricks** bronze→silver→gold (Unity Catalog) → publish gold to **Snowflake** → **Power BI**. CI/CD: **Azure DevOps** Dev→Test→Prod.

## SnapLogic must-say terms
- **Designer** (build) / **Manager** (assets, tasks, creds) / **Monitor** (health, alerts)
- **Snaplex** = execution grid — **Groundplex** (on-prem/VNet e.g. SAP HANA) vs **Cloudplex** (managed)
- **Snap** = one step; **Snap Pack** = connector bundle (REST, Snowflake, JDBC, Azure Blob)
- **Core Snaps:** Mapper (shape) · Router (branch) · Filter (drop) · Join (enrich) · File Reader/Writer
- **Tasks:** Scheduled (batch poll) · Triggered (REST endpoint) · Ultra (low-latency)
- **Pipeline Execute Snap** → calls parameterized **child pipeline** = reusable template
- **Error pipeline** → quarantine bad row + retry + alert

## What triggers the Blob landing?
A **Task** runs the pipeline. **Scheduled** = cron (most batch). **Triggered** = REST endpoint. **Ultra** = streaming. Source file pickup = **scheduled poll** + Directory Browser Snap (no native folder-watch).

## SnapLogic transforms (basic, per-record)
Map/rename · cast type · derived fields · filter · route · parse CSV/JSON/XML · format convert · light join. **NOT** big joins/aggregations/CDC — those go to Spark.

## 10GB file? (key answer)
SnapLogic **streams** documents → handles big files *unless* a **blocking Snap (Sort/Aggregate/Join/Group By)** buffers it all → **OOM on Snaplex**. Fix: **binary pass-through** lands raw to bronze, **Spark** does the heavy compute. Avoid blocking Snaps; scale/split nodes.

## Why both Databricks AND Snowflake?
Different jobs: **Databricks** = transform/ML engine (Spark, medallion, CDC/SCD, DQ). **Snowflake** = serving layer (simple SQL, high concurrency, low ops). Land → transform in Databricks → publish gold to Snowflake for BI.

## Databricks must-say
Medallion **bronze→silver→gold** on **Delta Lake** · **DLT expectations** (DQ rules) · **Unity Catalog** (RBAC/RLS/lineage) · CDC + **SCD 1/2** · perf: **Z-ORDER, partition pruning, Auto Loader, Photon**

## Power BI must-say
Star-schema **semantic model** · **DAX** · **drill-through** · **RLS** · **KPI scorecards** · Import (default) vs DirectQuery (big/real-time)

## CI/CD (Azure DevOps)
SnapLogic → Metadata API export + Git + env-specific **Project params/accounts** per stage · Databricks → **Repos + REST API + Terraform** · Power BI → **Deployment Pipelines**

## STAR stories (pick 2-3, lead with result)
1. **SLA/cost** → Z-ORDER + Auto Loader + Photon → 60% faster, 35% cheaper
2. **Data quality** → un-deduped CDC double-count; DLT expectations + SCD2 → 40% fewer defects
3. **10GB OOM** → blocking Snaps; binary pass-through + defer to Spark
4. **Maintainability** → copy-paste pipelines; parameterized templates → 35% faster builds
5. **Observability** → slow incidents; error pipelines + alerting → 40% faster resolution
6. **Ambiguity** → vague "visibility"; pin down decisions → star schema + drill-through

## Two phrases that signal seniority
- **Blocking Snaps cause the OOM** (Sort/Aggregate/Join buffer the whole dataset)
- **Idempotent keyed MERGE/upsert** → safe reprocessing, no double-count, handles late data

## Questions to ask them
Is SnapLogic the standard or am I consolidating onto it? · Where's the Databricks/Snowflake boundary? · How mature is governance (Unity Catalog/lineage)? · Heaviest consumer — sales, post-sales, or CS? · What's success at 6 months?
