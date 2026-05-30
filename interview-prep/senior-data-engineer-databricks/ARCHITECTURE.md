# Retail Sales Intelligence Platform — Full Architecture
## Juul Labs · CPG/beverage distributor analytics · ASCII only (no Mermaid)

> Standalone reference for the "draw the architecture / walk me through your platform" interview question. Sketch the boxes top-to-bottom in ~60-90s. Pairs with `INTERVIEW_QA_TECH_REFERENCE.md` (term deep-dives) and the migration docs.

> **Data volume (memorize):** ~10 GB/day raw landing (12 distributor feeds @ ~50-300 MB each + CRM + Nielsen TDLinx, which is the biggest single feed) · largest fact `canonical_sales` ~5-6 TB cumulative · single-digit TB over the 7-year bronze retention. **Senior framing: this is mid-size data, NOT petabyte-scale — the difficulty is entity resolution + bitemporal modeling + cent-level reconciliation, not raw volume; right-size for that, don't over-engineer.** (Caveat: point-of-sale *scan* data would be TB/day; depletion data — cases sold *out* of the distributor — is aggregated and far smaller.)

---

## The full diagram

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  IaC LAYER (everything below is code in git, deployed by CI/CD — no clicks)    ║
║                                                                                ║
║  TERRAFORM CLOUD (platform foundation — platform team, changes rarely)         ║
║    AWS:        VPC · Transfer Family SFTP · S3 (bronze/silver/gold,             ║
║                KMS + 7y object lock) · Step Functions · Lambda · CloudWatch     ║
║                · SNS/SQS · IAM roles · Secrets Manager                          ║
║    Databricks: workspace · Unity Catalog (catalogs/schemas/grants/row-filters)  ║
║                · cluster policies · instance pools · secret scopes · service     ║
║                principals                                                       ║
║                            │ provisions the platform ▼                          ║
║  DATABRICKS ASSET BUNDLES (workloads — data team, changes every PR)            ║
║    databricks.yml → the 4 AM Job DAG · DLT/Lakeflow pipelines · notebooks/      ║
║    wheels · job clusters (reference TF-made policies+pools) · dev/prod targets  ║
╚══════════════════════════════════════════════════════════════════════════════╝

  12 distributor SFTP feeds  +  CRM  +  Nielsen TDLinx        ( + OLTP via CDC )
         │  distributors PUSH files (key-auth)
         ▼
┌─ INGEST (AWS — event-driven, per file) ─────────────────────────────────────┐
│  Transfer Family SFTP ──► S3 raw  (s3://juul-ingest-bronze/raw/<src>/yyyy/..) │
│         │ S3 PutObject event                                                  │
│         ▼                                                                     │
│  Step Functions (per-file state machine)                                      │
│    └─► Lambda HOP: peek header · validate schema vs contract · write manifest │
│         ├─ valid    → leave in raw/<src>/...   (Auto Loader watches this)      │
│         └─ invalid  → quarantine/<src>/...  + PagerDuty alarm                  │
│  CloudWatch alarms: FileArrivalGap (>4h late) · size anomaly ─► SNS ─► PagerDuty │
│  ops.ingest_manifest (Delta) ← one row/file: arrival, rows, schema_ok, status │
└───────────────────────────────────────────────────────────────────────────────┘
         │  Auto Loader (cloudFiles, incremental, checkpointed, SNS/SQS notif mode)
         ▼
┌─ LAKEHOUSE (Databricks — Delta on the same S3, daily 4 AM DAG) ──────────────┐
│                                                                               │
│  BRONZE  raw, all-string + provenance (_source_file, _ingest_ts)              │
│          7-year object lock · never altered · replayable                      │
│            │  dbt-on-Databricks + Spark                                        │
│            ▼                                                                   │
│  SILVER  typed · canonical · SCD2 + bitemporal                                │
│            • normalized_address  (libpostal + USPS via Lambda)                 │
│            • candidate_retailer → canonical_retailer  (deterministic ER, SCD2) │
│            • canonical_product   (hierarchical taxonomy, SCD2)                 │
│            • canonical_sales     (joined to canonical IDs; idempotent MERGE)   │
│            │  dbt models                                                       │
│            ▼                                                                   │
│  GOLD    precomputed marts                                                    │
│            • sales_by_retailer_daily / sales_by_product_daily                 │
│            • promo_performance_daily   (DiD lift)                              │
│            • trade_spend_reconciliation                                        │
│                                                                               │
│  Layout: partition by date · cluster (liquid/Z-ORDER) on retailer_id/product_id │
│  Maintenance: OPTIMIZE + VACUUM (Predictive Optimization)                      │
│  Governance: Unity Catalog (grants, lineage, row-filters/column-masks)         │
│  Compute: job clusters + SQL warehouses · autoscale→0 · cluster policies       │
└───────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
  Looker  ·  Databricks SQL  ·  Alation (lineage)    (consumers via views/semantic layer)

────────────────────────────────────────────────────────────────────────────────
ORCHESTRATION   Step Functions + Lambda (per-file ingest, event-driven, seconds)
                Databricks Workflows     (daily bronze→silver→gold DAG, 4 AM UTC)
                ── two orchestrators: AWS reacts per-file; Databricks transforms ──

CI/CD           Engineer edits transform/job → PR
                ├─ PR:   terraform plan (if .tf changed) · bundle validate -t dev
                │        · pytest · dbt test · Great Expectations · schema-diff
                │        · bundle deploy -t dev (smoke run)
                └─ main: terraform apply (gated) → bundle deploy -t prod
                   (infra first, workloads second — bundle refs TF pools/policies/UC)

TESTING         pytest (Lambda) · dbt test (not-null/unique/relationships on canonical IDs)
                · Great Expectations (cases≥0, revenue within 3σ) · schema diff

RECONCILIATION  dual-run + L1 structural → L2 count/count-distinct → L3 aggregate sums
                → L4 row-checksum (cent grain) → gates cutover / catches drift

MONITORING      CloudWatch (AWS) · Databricks SQL dashboards (freshness/state)
                · system.billing.usage (DBU cost + tags) · PagerDuty (SLA breach)
────────────────────────────────────────────────────────────────────────────────
```

---

## The layered ownership model (what owns what)

| Layer | Owns | Tool | Change rate |
|---|---|---|---|
| **Foundation** | VPC, S3, IAM, SFTP, Step Functions, workspace, Unity Catalog, cluster policies, pools | **Terraform** | Rarely (platform team) |
| **Workloads** | Jobs, DLT pipelines, notebooks, job clusters, schedules | **Asset Bundles** | Every PR (data team) |
| **Event ingest** | Per-file validate + land + alarm | Step Functions + Lambda | Per file (runtime) |
| **Transform** | bronze→silver→gold DAG | Databricks Workflows + dbt | Daily 4 AM |
| **Serving** | Dashboards, lineage | Looker / Databricks SQL / Alation | Continuous |

**Handoff line:** Terraform creates the cluster *policy* + *pool*; the DAB job *references* them — so dev workloads are governed by the platform team's guardrails without devs touching Terraform.

---

## Terraform vs Asset Bundles — do you need both?

Technically no (DAB generates Terraform under the hood; Terraform's databricks provider can also create jobs), but for a real org **yes — split by ownership, change-rate, and blast radius:**

- **Terraform** = slow-changing, security-sensitive **foundation**; reviewed hard; platform team.
- **Asset Bundles** = fast-changing **workloads** that ship in the same repo as the transform code; normal PR; data team.

You don't want a dev editing a job schedule to need access to the Terraform state that controls IAM and S3.

| Tool | Manages | Examples |
|---|---|---|
| Terraform | Cloud infra + workspace + governance | S3, IAM, SFTP, the Databricks workspace, Unity Catalog, cluster policies, pools |
| Asset Bundles | What runs *inside* the workspace | Jobs, DLT pipelines, notebooks, job clusters, schedules |

---

## Why two orchestrators (the most-probed design choice)

| | Step Functions + Lambda | Databricks Workflows |
|---|---|---|
| Trigger | Event-driven (file lands) | Schedule (4 AM UTC) |
| Granularity | Per-file | Whole bronze→silver→gold DAG |
| Job | Ingest, validate, fail-fast | Transform, model, aggregate (Spark) |
| Latency | Seconds | Minutes–hours |
| Lives in | AWS | Databricks |

You can't cleanly do per-file event reaction in a daily DAG (you'd poll S3), and you can't do heavy Spark transforms in Step Functions (it's an orchestrator, not a compute engine). AWS-native layer handles "a file arrived, is it valid, land it"; Databricks handles "now transform everything that landed." **Handoff = the bronze table.**

---

## The five sentences that explain the whole thing

1. **IaC:** Terraform provisions the platform (cloud + workspace + Unity Catalog + cluster policies/pools); Asset Bundles deploy the workloads (jobs/pipelines/notebooks) that reference those policies — both in git, deployed by CI/CD, infra first.
2. **Ingest:** distributors push files via managed SFTP → S3; an S3 event fires Step Functions → a Lambda validates + routes (raw vs quarantine) + writes a manifest; CloudWatch alarms on lateness/size.
3. **Lakehouse:** Auto Loader incrementally lands BRONZE (locked 7y); a daily Databricks DAG runs dbt to resolve the same store/product across 12 inconsistent sources into canonical, time-versioned SILVER facts; GOLD precomputes the business marts.
4. **Two orchestrators on purpose:** AWS (Step Functions/Lambda) does per-file, event-driven reaction; Databricks Workflows does the scheduled heavy transform — right tool per timing problem, handoff at the bronze table.
5. **Trust:** dual-run reconciliation (L1–L4, cent grain) gates every cutover and catches drift; Unity Catalog governs access + lineage; `system.billing.usage` + cluster policies keep elastic compute from blowing the budget.

---

## One-liner openers (pick by what they ask)

- **"Walk me through the architecture":** "Distributor files land event-by-event in AWS (bronze, locked 7y); a daily Databricks DAG resolves the same store/product across 12 inconsistent sources into canonical time-versioned facts (silver); GOLD precomputes the business marts. Terraform owns the platform, Asset Bundles own the workloads, reconciliation gates every change."
- **"Why Databricks here":** heavy Spark entity resolution + bitemporal SILVER + streaming hot path + ML roadmap = lakehouse fits the whole workload on one platform (vs a warehouse + a separate Spark/ML stack).
- **"How do you know it's correct":** dual-run reconciliation ladder L1–L4 at the cent grain, gating cutover — not faith.

---

*Last updated: 2026-05-29 · Numbers/names are the anchor-project template — swap in your real ones.*
