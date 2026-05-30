# Senior Data Engineer — Databricks Lakehouse
## Round 1: Projects + Technical Interview (STAR Format)

> **Round 1 scope:** projects and technical depth. The interviewer will drill into ONE recent project — architecture, pipeline internals, orchestration, deployment, incidents — and ask adjacent technical questions off the same project.
>
> **Format:** Every answer below uses STAR — **S**ituation, **T**ask, **A**ction, **R**esult. The interview follows a natural arc: warm-up → recent work → deep-dive on ONE project → technical drill-downs on that same project → adjacent technical scenarios → behavioral → closing.
>
> **Anchor project:** "Retail Sales Intelligence Platform" at Juul Labs — Master Retailer + Product Mapping + Promo Analysis. Q1 2025 → Q1 2026 (~12 months, just wrapped). Address normalization, entity resolution, product master data, promo lift analytics. Hits Databricks + Terraform + orchestration + AWS + Unity Catalog + data quality + multi-source joins, no SAS thread required.
>
> **Persona:** Senior Data Engineer at Juul Labs Inc., remote-CST, 3 years at Juul.

---

## The anchor project in one paragraph (memorize this)

> *"Led the Retail Sales Intelligence Platform at Juul — a unified sales / retailer / product / promo mart that replaced a fragmented set of distributor-by-distributor reports. Q1 2025 through Q1 2026. The core problem: Juul sells through 12 wholesale distributors into ~120k retailer locations, but every distributor used different retailer identifiers, different SKU codes, and different address formats. The same Stop-N-Shop in Boston appeared as three different "retailers" across three feeds. Promo lift analytics were 15-20% off because we couldn't reliably identify the same retailer or product across feeds. Built the address normalization pipeline, the master retailer entity-resolution pipeline, the product master mapping pipeline, and the promo analysis mart on top — all on Databricks Lakehouse + Unity Catalog + Terraform-managed infrastructure. Net result: canonical retailer count reduced from 247k duplicates to 124k true unique locations, promo lift measurement accurate within 2%, $1.2M in mis-applied retailer-funded promo recoveries identified in the first six months."*

Drop this in answer to "tell me about a recent project" and every interviewer pulls on a thread.

---

## Phase 1 — Warm-up (5-10 min)

### Q1. Tell me about your current role.

**Situation:** I joined Juul Labs in 2023 as Senior Data Engineer when the company was rebuilding its data platform after years of outsourced engineering. Juul has unusually heavy data needs for a CPG — 12 distributor feeds covering ~120k retailers, complex product taxonomy (devices, pod flavors, multi-pack SKUs), heavy promotional and trade-spend activity, and multi-region operations.

**Task:** My role splits across three things — lead architect for the analytics platform (Databricks-on-AWS Lakehouse), platform owner for governance (Unity Catalog, Alation, lineage), and tech lead on the highest-priority active initiative each quarter.

**Action:** Day-to-day I split time between architecture decisions, code review for a team of 8 engineers, on-call rotation, and direct contribution. I report to the Director of Data Engineering and partner closely with Sales Ops, Trade Marketing, Finance, and Data Science.

**Result:** Over the last 18 months I led the Unity Catalog rollout to ~3,400 tables, built the Retail Sales Intelligence Platform that I'll walk through later, and shipped a cost-attribution platform that took quarterly cost reviews from 90-minute spreadsheet battles to 20-minute data-driven decisions.

### Q2. Walk me through a typical day.

**Situation:** Juul's data team is async-first because we span CST, PST, and a few EU contractors. My calendar has fewer meetings, more deep work.

**Task:** Balance three jobs — keep the platform running, move major projects forward, support the team.

**Action:** Representative Tuesday last week:
- **7:30-9:00 CST** — coffee, scan #data-platform Slack, triage overnight pages, review nightly Terraform drift report. 2-3 PRs from EU contractors in the queue.
- **9:00-10:30** — deep work. This week it's design for a fourth-quarter promo-analysis enhancement (geographic halo effects).
- **10:30-11:00** — tech sync with Sales Ops (their analytics lead joins). Blockers + upcoming requests.
- **11:00-12:00** — office hours. Anyone in the data org can drop in.
- **12-1** — lunch.
- **1-3** — deep work, often coding. I aim to ship one PR per day.
- **3-3:30** — 1:1 with my manager.
- **3:30-5** — code review queue, async Slack, plan tomorrow.

**Result:** Roughly 50% code review, 25% coding/architecture, 15% incidents/platform health, 10% stakeholder. I write code 2-3 days a week.

### Q3. How is the team structured, and how do you interact with the business?

**Situation:** Juul's data org sits under the CTO. ~25 people across Data Engineering, Data Science, ML Engineering, Analytics Engineering. My direct group is 8 engineers.

**Task:** Serve four primary customers — Sales Ops, Trade Marketing (promo planning + analysis), Finance, and Compliance.

**Action:** Hub-and-spoke. My team owns the platform — bronze ingest, silver canonical entities, governance. Analytics engineers embed in business domains and own gold-layer marts. Monthly platform-steering committee with one rep from each domain.

**Result:** Ticket queue dropped 60% in two quarters after moving to hub-spoke in 2024. Analytics engineers ship their own marts daily.

---

## Phase 2 — Recent work landscape (5-10 min)

### Q4. What have you been working on the past few months?

**Situation:** Last six months have been the closing stretch of the Retail Sales Intelligence Platform plus two adjacent initiatives.

**Task:** Land three things on overlapping timelines — (1) the promo analysis mart for the Q4 2025 trade-spend review, (2) the master retailer ER pipeline going from quarterly batch to daily, (3) ongoing platform health.

**Action:**
- **Promo Analysis Mart (Sept–Dec 2025):** the gold-layer cube on top of canonical sales + canonical retailer + canonical product + promo calendar. Replaced the spreadsheet-based trade-spend review that Sales Ops had been running for years.
- **Master Retailer pipeline cadence change (Nov 2025 – Jan 2026):** moved entity resolution from quarterly batch to daily incremental. New retailers from distributor feeds now resolve within 24h instead of up to 3 months.
- **EU expansion prep (Jan–Feb 2026):** address normalization patterns extended for EU postal codes (different USPS API, different normalization rules).

**Result:** Promo Analysis Mart live for Q4 2025 trade-spend review — first time Trade Marketing could measure promo lift accurately. Daily ER pipeline live January. EU patterns landed Feb.

### Q5. Of those, which would you want to dig into?

**Situation:** The Retail Sales Intelligence Platform is the one I'd dig into. It's the most complete project, technically the most interesting (entity resolution, master data, real promo analytics), and has business outcomes you can measure.

**Task:** Replace fragmented per-distributor reporting with a unified canonical sales / retailer / product / promo platform.

**Action:** [Tee up the deep-dive.]

**Result:** Canonical retailers 247k → 124k true unique. Promo lift accuracy within 2% vs 15-20% off before. $1.2M in promo recoveries identified.

---

## Phase 3 — Deep dive: anchor project (20-30 min)

### Q6. Walk me through the Retail Sales Intelligence project in detail.

**Situation:** Juul sells through a tiered distribution network: ~12 wholesale distributors (Convenience Distribution, McLane, Core-Mark, Eby-Brown, GSC, etc.), each selling into thousands of retailer locations. The final retailers are mostly convenience stores, gas stations, tobacco shops, vape shops — ~120k locations across all 50 states.

Every Monday morning, each distributor sends a weekly sales feed via SFTP. Each feed has its own schema, its own retailer identifier scheme, its own SKU codes, its own address format. There is no shared identifier between feeds. The same Stop-N-Shop in Boston might appear as `STP12345` in McLane's feed, `STPNSHP-MA-001` in Core-Mark's feed, and `Stop_n_Shop_Boston_3` in Juul's own direct-to-retailer feed.

This created three compounding problems:
1. **Sales totals didn't add up.** Total units sold to retailers ≠ total units bought by retailers from distributors, because we were counting the same retailer multiple times under different identifiers.
2. **Promo analysis was broken.** When Trade Marketing ran a promotion at "all Stop-N-Shop locations in Massachusetts," they needed to identify those retailers across all distributor feeds. They couldn't. The Q3 2024 promo retrospective came back ±15% off baseline — useless.
3. **Trade-spend recovery was lossy.** Retailer-funded promos (where the retailer covers some of the discount) require proving the retailer's identity to claim the funds back from the retailer's chain accounting. The fragmented identifier set meant ~10% of trade-spend recoveries were left on the table.

In early 2025 the CFO flagged this as a top priority — the trade-spend reconciliation budget was material ($30M+ annually).

**Task:** I was asked in January 2025 to lead the build. Mandate:
1. Single canonical "retailer" identifier across all 12 distributor feeds + internal CRM + 3rd-party retail data (Nielsen TDLinx).
2. Single canonical "product" identifier across distributor SKU codes + manufacturer codes + UPC/GTIN.
3. Promo analysis dashboard that Trade Marketing could trust for monthly review cycles.
4. Daily refresh of the canonical IDs as new retailer locations come in.

Budget: 4 engineers + 1 analytics engineer for ~12 months. ~$1.5M total.

**Action:** Made five architectural calls upfront.

**1. Build address normalization first.** Address quality was the foundation. If we couldn't get "5 Main Street, Boston MA 02110" and "5 Main St, Boston, Massachusetts 02110-1234" to resolve to the same canonical address, nothing downstream would work. Built the normalization layer in months 1-2 before touching entity resolution.

**2. Entity resolution as a deterministic-first, ML-second pipeline.** Started with rules — exact match on USPS-normalized address + standardized phone + business-name fuzzy match. Resolved ~85% of retailers cleanly. For the remaining 15%, layered in a learned matcher (Splink with the Fellegi-Sunter model). Avoided going ML-first because deterministic rules are auditable, debuggable, and don't require labeled training data.

**3. Product master as a hierarchical taxonomy, not a flat SKU table.** Juul products have device families (e.g., JUUL device, JUUL2 device), pod families (e.g., Virginia Tobacco, Mint), pack sizes (4-pack, 2-pack), and SKUs (the actual UPC). A flat mapping wasn't enough — Trade Marketing wanted to roll up "all Virginia Tobacco SKUs across all pack sizes." Built the taxonomy explicitly.

**4. Bitemporal master data tables.** Both retailer and product canonical tables are bitemporal: valid_from / valid_to for "when was this canonical mapping believed to be true" and effective_from / effective_to for "when in real-world time did this fact hold." Critical for promo analysis where you're joining sales from June 2024 to the retailer's identity *as it was* in June 2024, not its identity today.

**5. Promo analysis as a precomputed mart, not on-the-fly queries.** Trade Marketing wanted dashboards that load in seconds. Built a `gold.promo_performance_daily` table refreshed nightly, joining canonical sales × canonical retailer × canonical product × promo calendar × control group.

**Execution timeline:**
- **Jan–Feb 2025:** address normalization pipeline. libpostal for parsing, USPS API for validation, custom Spark UDFs for the merge.
- **Mar–May 2025:** master retailer entity resolution. Blocking → pairwise scoring → clustering → master record selection.
- **Jun–Aug 2025:** product master + SKU resolution. GTIN-first match, manufacturer-code second, fuzzy attribute match last.
- **Sept–Nov 2025:** promo analysis mart. Joins, lift calculation, control-group matching, difference-in-differences for trade-spend recovery validation.
- **Dec 2025:** parallel run vs the legacy per-distributor reports. Difference reconciled with Sales Ops.
- **Jan 2026:** production cutover. Legacy reports decommissioned over February.

**Result:**
- Canonical retailer count: 247k duplicates → **124k true unique locations**.
- Promo lift accuracy: ±15-20% off baseline → **within 2%**.
- Trade-spend recoveries identified in H2 2025: **$1.2M** that would have been missed under the old fragmented setup.
- Sales attribution to specific products: "Unknown SKU" sales rate **8% → 0.4%**.
- Q4 2025 trade-spend review (first one using the new platform) was the smoothest Sales Ops had run in years — they pulled monthly dashboards instead of building bespoke reports.

---

## Phase 4 — Technical drill-downs on the anchor project (30+ min)

### Q7. Why Databricks for this? What did you consider instead?

**Situation:** Jan 2025. Picking the platform for a year-long entity-resolution + analytics build.

**Task:** Choose a platform that handles fuzzy matching, MERGE-heavy upserts, BI queries, and surfaces lineage for audit.

**Action:** Three-way evaluation.

| Option | Strengths | Why I ruled out / picked |
|---|---|---|
| **Snowflake + dbt + external ER service (e.g., Senzing managed)** | Best SQL ergonomics for analytics. dbt was already used by analytics engineers. | ER as a managed service was expensive and opaque — couldn't tune the matching rules. Snowpark not mature enough in early 2025 for the libpostal + ML matcher we wanted. |
| **Databricks Lakehouse** | Native Python + Spark for ER libraries (Splink, RecordLinkage). Unity Catalog for lineage. dbt-on-Databricks for SQL transformations. Existing team expertise. | Slightly more complex than Snowflake for pure-SQL workflows. |
| **AWS-native (Glue + EMR + Athena + Redshift)** | Cheapest option in theory. | Five-platform stack to operate. No equivalent of Unity Catalog's row filters + column masks. Lineage would have been DIY. |

Picked Databricks. Three deciding factors:
1. **Spark + Python ER libraries.** Splink is the gold standard for probabilistic entity resolution. Native PySpark API. Snowflake would have required an external service or a clumsy port.
2. **Bitemporal master tables in Delta.** Delta's MERGE + time travel are nearly perfect for bitemporal master data. SCD2-style updates are 5 lines of SQL.
3. **Unity Catalog lineage** for the auditable chain: distributor feed → bronze → normalized address → canonical retailer → promo analysis result. Lineage is automatic, captured at column level.

**Result:** Got platform sign-off in week 2 of January 2025. Built proof-of-concept ER on 1 month of one distributor's feed in two weeks. Validated the design.

### Q8. Walk me through the full architecture end-to-end.

**Situation:** Need to take 12 weekly distributor feeds + Juul CRM + Nielsen TDLinx + promo calendar through to a Trade Marketing dashboard.

**Task:** Design layers that are independently testable, lineage-traceable, and rebuilable from bronze.

**Action:** Full path:

```
SFTP landing zones (one per distributor + CRM export + Nielsen feed)
    │
    ▼
S3 raw zone (juul-bronze-prd/retail/<source>/<date>/*.csv|*.parquet)
    │  Lambda triggered on SFTP upload, copies into S3
    │
    ▼  Databricks Auto Loader, one stream per source
juul_us_prd.bronze.distributor_sales_<source>
    │  Delta, append-only, schema-on-read with schema hints
    │  retained 7 years on object lock for FDA + finance audit
    │
    ▼  Daily batch jobs
juul_us_prd.silver.distributor_sales              (typed, deduped, all 12 sources unioned)
juul_us_prd.silver.normalized_address             (USPS-normalized addresses, hashed for join keys)
juul_us_prd.silver.candidate_retailer             (one row per (source, source_retailer_id) with attributes)
juul_us_prd.silver.canonical_retailer             (master retailer table, bitemporal, one row per unique location)
juul_us_prd.silver.retailer_id_resolution         (mapping table: source_retailer_id → canonical_retailer_id)
juul_us_prd.silver.canonical_product              (master product table, hierarchical taxonomy)
juul_us_prd.silver.product_id_resolution          (mapping table: source_sku → canonical_product_id)
juul_us_prd.silver.canonical_sales                (sales facts joined to canonical retailer + canonical product)
    │
    ▼  Daily aggregation jobs (dbt-on-Databricks)
juul_us_prd.gold.sales_by_retailer_daily
juul_us_prd.gold.sales_by_product_daily
juul_us_prd.gold.sales_by_state_daily
juul_us_prd.gold.promo_performance_daily          (promo cohort vs control, lift, cannibalization)
juul_us_prd.gold.trade_spend_reconciliation       (retailer-funded promo recovery analysis)
    │
    ▼
Looker dashboards (Trade Marketing, Sales Ops, Finance)
```

**Key components:**

- **Bronze** = exact copy of distributor inputs. Schema-on-read because distributors silently add columns. Object-lock 7y.
- **Silver canonical entities** = the master data layer. The whole project's value lives here.
- **Silver canonical sales** = sales fact with the master IDs joined in. This is the table everyone queries.
- **Gold marts** = precomputed aggregations for fast BI. dbt-on-Databricks.

**Storage:** S3-backed Delta Lake. Bronze + silver use separate S3 buckets with separate KMS keys; gold is its own bucket.

**Compute:**
- **Auto Loader streams** for bronze ingest (light, near-real-time).
- **Daily batch job cluster** (8-32 workers, Photon) for the silver canonical pipelines — they're MERGE-heavy and benefit from Photon.
- **dbt jobs** in Databricks Workflows for gold.
- **SQL warehouses** (serverless) for Looker queries.

**Networking:** Customer-managed VPC, PrivateLink for Databricks control plane + workspace REST. S3 via VPC endpoint. No public internet for Databricks traffic.

**Orchestration:** Databricks Workflows — daily DAG that runs bronze → silver (in dependency order) → gold (parallelized) → dashboard refresh trigger.

**CI/CD:** GitHub Actions for triggering, Terraform Cloud for infrastructure, Databricks Asset Bundles for notebooks + workflows.

**Result:** End-to-end runs in ~3.5 hours nightly. P95 freshness for Trade Marketing dashboards: 9 AM CST after the 4 AM CST job run. Zero data-loss incidents in production.

### Q9. Walk me through your Terraform setup.

**Situation:** New infrastructure needed — distributor SFTP credentials, S3 buckets, USPS API integration via Lambda, Splink dependencies, Databricks workspace resources.

**Task:** Make every piece deterministic, reviewable, and reusable for the EU expansion later.

**Action:**

**Module layout:**

```
terraform/
  modules/
    aws-sftp-distributor-ingress/  # SFTP user + IAM + S3 landing zone + Lambda trigger
    aws-usps-api-lambda/           # Lambda calling USPS Web Tools API
    aws-s3-medallion/              # bronze/silver/gold buckets with KMS + object lock
    databricks-workspace/          # workspace + cross-account IAM + PrivateLink
    databricks-uc-catalog/         # catalog + schemas + tags
    databricks-job/                # job + cluster policy + alerts
    databricks-cluster-policy/     # approved cluster sizes
  environments/
    us-dev/
    us-stg/
    us-prd/
    eu-prd/                        # added 2026
  policies/
    *.rego                         # OPA gates for CI
```

**Example — SFTP module interface:**

```hcl
module "convenience_distribution_sftp" {
  source = "../../modules/aws-sftp-distributor-ingress"

  distributor_name = "convenience-distribution"
  sftp_user        = "cd-juul-prd"
  ssh_public_key   = data.aws_secretsmanager_secret_version.cd_pubkey.secret_string
  landing_bucket   = module.juul_bronze.bucket_name
  landing_prefix   = "retail/convenience-distribution/"

  schedule_lambda  = {
    enabled = true
    cron    = "cron(0 6 ? * MON *)"  # weekly Monday 6 AM UTC
  }

  tags = local.compliance_tags
}
```

**State:** S3 + DynamoDB lock, KMS-encrypted, separate state per environment. Terraform Cloud for runs, GitHub Actions for triggering.

**Policy-as-code (OPA via conftest):** added rules specific to this project:
- All SFTP users must have key-pair auth, never password.
- All S3 landing zones must encrypt with KMS and version objects.
- All Databricks jobs in `_prd` workspace must reference an approved cluster policy.
- All UC catalogs must have `data_classification` and `cost_center` tags.

These ran on every PR. Caught two PRs that would have shipped password-auth SFTP users.

**Provider versioning:** pinned to patch. Lockfile checked in. Renovate weekly PRs.

**Drift detection:** nightly `terraform plan` from read-only CI principal. Slack alert on non-empty diffs.

**Result:** Initial provisioning end-to-end took 2 days. EU expansion later (Q1 2026) took 5 days because we'd reused 80% of the modules. Drift detection caught 5 manual changes in 2025 that I followed up with reconciliation PRs.

### Q10. Address normalization — walk me through how you actually built it.

**Situation:** 12 distributor feeds, each with their own address formatting conventions. Some are clean ("5 Main Street, Boston, MA 02110-1234"), some are garbage ("5 main st boston ma"), some have data-entry typos ("5 Mainnn Strret, Bostton MA"). About 8% of incoming addresses were unmatchable to USPS without normalization.

**Task:** Take any distributor's address text and produce a canonical normalized representation that's joinable across feeds.

**Action:** Four-stage pipeline:

**Stage 1 — Parse with libpostal.** libpostal is a CRF-based parser that splits raw address text into structured fields (house_number, road, city, state, postal_code). Wrapped libpostal in a PySpark Pandas UDF for batch processing:

```python
from pypostal import parse_address

@F.pandas_udf("struct<house_number:string,road:string,city:string,state:string,postcode:string>")
def parse_address_udf(addresses: pd.Series) -> pd.DataFrame:
    parsed = [dict(parse_address(addr)) for addr in addresses]
    df = pd.DataFrame(parsed)
    return df[["house_number", "road", "city", "state", "postcode"]]
```

libpostal handled ~92% of inputs cleanly. The other 8% had typos or formatting that broke parsing.

**Stage 2 — Standardize.** Even after parsing, "St" vs "Street" vs "STREET" vs "STR" are the same thing. Built a deterministic standardization function:
- Road type: `St`, `St.`, `STREET`, `Str` → `Street`. Lookup table from USPS Publication 28.
- State: `MA`, `Mass`, `Massachusetts` → `MA`.
- City: title case, strip whitespace, remove punctuation.
- Postcode: ZIP-5 (strip ZIP+4 for joining; retain ZIP-9 separately).

**Stage 3 — USPS Address Validation API.** Call USPS Web Tools API to validate and get the canonical form. Wrapped in a Lambda we owned (USPS API has rate limits + needs auth). Batch UDF calling the Lambda:

```python
@F.pandas_udf("struct<canonical_address:string,is_valid:boolean,delivery_point:string>")
def usps_validate_udf(parsed_addresses: pd.DataFrame) -> pd.DataFrame:
    # Lambda accepts batch of up to 5 addresses per call
    return call_lambda_in_batches(parsed_addresses, batch_size=5)
```

USPS validation handled another ~5% (caught the typo cases). Cached results in `silver.address_validation_cache` so we didn't re-call the API for known-good addresses — saved ~80% on Lambda invocations.

**Stage 4 — Hash for join key.** The final normalized address gets SHA-256 hashed into an `address_hash` column. Any two records with the same `address_hash` are at the same physical address. Cheap join key for downstream entity resolution.

**Fallback for unresolvable addresses (~0.3%):** logged to `silver.address_normalization_unresolved` for manual review. An ops analyst reviewed weekly and either fixed at source (escalation to distributor) or applied a manual canonical mapping.

**Result:**
- 99.7% of distributor addresses normalized successfully.
- Address hash collisions confirmed at < 0.001% (validated by sampling and manual review).
- USPS API cache hit rate: ~85% after the first 3 months. Cut the Lambda cost from $3.4k/mo projected to $510/mo actual.

### Q11. Master retailer entity resolution — how does it actually work?

**Situation:** ~250k candidate retailers across 12 feeds. Same physical location can appear in up to 12 different feeds with different IDs. Need one canonical record per location with a stable canonical ID that persists across re-runs.

**Task:** Cluster candidates that represent the same physical location into one canonical retailer.

**Action:** Five-stage pipeline.

**Stage 1 — Build candidate retailer table.** One row per `(source, source_retailer_id)`. Columns: normalized address (and address_hash), phone (E.164 standardized), business name, banner (the brand — "Stop-N-Shop", "7-Eleven"), DUNS number if available.

**Stage 2 — Blocking.** Pairwise comparison of 250k candidates is 31 billion pairs — too many. Block by `(zip5, first_token_of_business_name)`. Cuts candidates within a block to typically <100. Total pairs to compare drops to ~50M.

**Stage 3 — Pairwise scoring.** For each candidate pair within a block, compute a similarity score using Splink (probabilistic Fellegi-Sunter):
- Address match (Jaro-Winkler on full normalized address): 0.0 to 1.0
- Phone match (exact on E.164): 0.0 or 1.0
- Business name match (Jaro-Winkler + token-based): 0.0 to 1.0
- Banner match (exact after standardization): 0.0 or 1.0
- DUNS match (exact): 0.0 or 1.0

Splink learns the weights via expectation-maximization on a labeled training set of ~2,000 manually-verified pairs.

**Stage 4 — Cluster via connected components.** Build a graph of pairs with score above threshold (0.85). Use Spark GraphFrames `connectedComponents()` to cluster candidates into entities. Each connected component = one canonical retailer.

**Stage 5 — Master record selection.** For each cluster, pick the "best" candidate as the canonical record using a priority: (1) Nielsen TDLinx record if available (highest data quality), (2) Juul direct CRM record, (3) distributor with highest historical data quality score, (4) earliest-seen record.

Generate a stable canonical_retailer_id using a deterministic hash of (master record's address_hash + master record's banner). Stability is critical — re-running the pipeline must produce the same canonical ID for the same physical location, otherwise downstream joins break.

**Update strategy — bitemporal:**

```sql
MERGE INTO silver.canonical_retailer tgt
USING staged_canonical_retailer src
  ON tgt.canonical_retailer_id = src.canonical_retailer_id
WHEN MATCHED AND tgt.attributes_hash != src.attributes_hash THEN
  UPDATE SET
    tgt.valid_to = current_timestamp(),  -- close old record
    tgt.is_current = false
WHEN NOT MATCHED THEN
  INSERT (canonical_retailer_id, ..., valid_from, valid_to, is_current)
  VALUES (src.canonical_retailer_id, ..., current_timestamp(), '9999-12-31', true);

-- separately, insert new versions for updated records
INSERT INTO silver.canonical_retailer
SELECT
  canonical_retailer_id, ..., current_timestamp() AS valid_from,
  '9999-12-31' AS valid_to, true AS is_current
FROM staged_canonical_retailer
WHERE attributes_hash != tgt.attributes_hash;
```

**Result:**
- 247k candidates collapsed to 124k canonical retailers.
- ER precision (sampled & manually validated): 98.4%.
- ER recall (sampled & manually validated): 96.1%.
- Stability across re-runs: 100% — the deterministic ID generation works.
- Pipeline runtime daily: ~45 minutes on 16 Photon workers.

### Q12. Product master mapping — walk me through that.

**Situation:** Juul's product taxonomy is hierarchical: device family (JUUL device, JUUL2) → pod family (Virginia Tobacco, Mint, Menthol) → pack size (1-pack, 4-pack). SKUs from distributors come as flat codes; some are GTIN/UPC-based, some are manufacturer-internal codes, some are distributor-specific catalog IDs. Same physical product can have 4-5 different SKU codes across feeds.

**Task:** Build a single canonical product table with hierarchical taxonomy + a mapping table from any source SKU to the canonical ID.

**Action:** Three-tier matching:

**Tier 1 — GTIN/UPC exact match.** When a distributor sends GTIN, it's authoritative. Look up against Juul's internal GTIN registry → canonical_product_id. Handles ~75% of SKUs.

**Tier 2 — Manufacturer code + flavor + size match.** When GTIN missing, distributor codes often include parseable manufacturer-product-flavor-size info. Pattern matched against a regex per distributor. Handles another ~22%.

**Tier 3 — Fuzzy attribute match.** When neither works, fuzzy match on the distributor's product description text vs canonical product name (Jaro-Winkler with attribute weighting). Lowest-confidence tier; manual review at < 0.7 confidence.

**Hierarchical taxonomy:**

```sql
CREATE TABLE silver.canonical_product (
    canonical_product_id STRING,
    gtin                 STRING,
    device_family        STRING,
    pod_family           STRING,
    nicotine_strength    DECIMAL(3,1),
    pack_size            INT,
    product_name         STRING,
    -- bitemporal columns
    valid_from           TIMESTAMP,
    valid_to             TIMESTAMP,
    is_current           BOOLEAN
)
PARTITIONED BY (device_family);
```

Analysts query at any level of the hierarchy:
- "All Virginia Tobacco sales" → filter `pod_family = 'Virginia Tobacco'`
- "All JUUL2 device sales" → filter `device_family = 'JUUL2'`
- Specific SKU → filter `canonical_product_id = 'P-VA-TOB-4PK-5'`

**Handling SKU renames / discontinuations:** when a manufacturer renames a SKU (e.g., regulatory packaging change), the old GTIN gets `valid_to = <rename date>` and a new canonical record gets `valid_from = <rename date>`. Both records share a `product_family_id` so analysts can roll up across the rename:

```sql
SELECT pf.product_family_name, SUM(s.units_sold)
FROM silver.canonical_sales s
JOIN silver.canonical_product p ON s.canonical_product_id = p.canonical_product_id
JOIN silver.product_family pf ON p.product_family_id = pf.product_family_id
WHERE s.sale_date BETWEEN '2025-01-01' AND '2025-12-31';
```

**Result:**
- 100% of distributor SKUs mapped to canonical products (the < 1% fuzzy-match tier flagged for review but still mapped pending confirmation).
- "Unknown SKU" sales rate: 8% → 0.4%.
- Manual review queue: ~30 new SKUs/month after the initial backfill, processed by an analyst in ~2 hours/month.

### Q13. Promo analysis pipeline — walk me through that.

**Situation:** Trade Marketing runs ~60-80 promotional campaigns per quarter. Each has a cohort of retailers (e.g., "all 7-Eleven locations in CA + TX") and a cohort of products (e.g., "all Virginia Tobacco SKUs") and a duration (e.g., "Sept 15 – Oct 31"). They needed to know lift (incremental sales vs baseline) and cannibalization (did other Juul SKUs sales go down because of the promo).

**Task:** Build a promo analysis mart that joins canonical sales × canonical retailer × canonical product × promo calendar and computes lift + cannibalization + halo effects.

**Action:** Three-table model + a precomputed mart.

**1. Promo calendar** — one row per (promo_id, retailer cohort entry, product cohort entry, start_date, end_date, discount_pct). Sourced from Trade Marketing's promo planning tool. Loaded into bronze nightly.

**2. Control group selection** — for every promo, identify "control" retailers similar to the promo cohort but not receiving the promo. Matched on banner, state, average weekly sales. Stored in `silver.promo_control_group`.

**3. Lift calculation** — for each promo + product combo, compute:

```sql
WITH promo_period_sales AS (
  SELECT
    p.promo_id,
    sum(CASE WHEN cs.canonical_retailer_id IN (SELECT retailer_id FROM silver.promo_retailer_cohort WHERE promo_id = p.promo_id) THEN cs.units_sold ELSE 0 END) AS promo_cohort_units,
    sum(CASE WHEN cs.canonical_retailer_id IN (SELECT retailer_id FROM silver.promo_control_group WHERE promo_id = p.promo_id) THEN cs.units_sold ELSE 0 END) AS control_cohort_units
  FROM silver.canonical_sales cs
  JOIN silver.promo_calendar p ON cs.canonical_product_id IN (SELECT product_id FROM silver.promo_product_cohort WHERE promo_id = p.promo_id)
   AND cs.sale_date BETWEEN p.start_date AND p.end_date
  GROUP BY p.promo_id
),
baseline_sales AS (
  -- similar SELECT for the 4 weeks before the promo started, same retailer + product cohorts
),
lift AS (
  SELECT
    pps.promo_id,
    (pps.promo_cohort_units - bs.promo_cohort_baseline_units) / bs.promo_cohort_baseline_units AS raw_lift_pct,
    -- Difference-in-differences: subtract the control group's change to isolate the promo effect
    ((pps.promo_cohort_units - bs.promo_cohort_baseline_units) / bs.promo_cohort_baseline_units)
      - ((pps.control_cohort_units - bs.control_cohort_baseline_units) / bs.control_cohort_baseline_units)
      AS did_lift_pct
  FROM promo_period_sales pps
  JOIN baseline_sales bs ON pps.promo_id = bs.promo_id
)
SELECT * FROM lift;
```

The difference-in-differences (DiD) is critical — raw lift can be misleading because of seasonal effects, broader market trends, etc. DiD isolates the promo's actual effect by subtracting what the control group did over the same period.

**4. Cannibalization** — for each promo, also computed sales of NON-promo products in the same retailer cohort. If JUUL2 promo cannibalized JUUL device sales, lift looks good in isolation but is partially fake.

**5. Trade-spend reconciliation** — for retailer-funded promos, joined the promo records with the retailer's invoice claims. Identified discrepancies (claim says we sold X units; our data says Y units). This was the $1.2M recovery line.

**Materialized as `gold.promo_performance_daily`** — refreshed nightly via dbt. Looker dashboards point at this table; query latency is sub-second.

**Result:**
- Q4 2025 trade-spend review used the new mart. Trade Marketing director said it was "the first time in 3 years our promo data wasn't a fight."
- Identified $1.2M in retailer-funded promo discrepancies in H2 2025.
- Promo lift accuracy: previously ±15-20% off vs actuals; now within 2%.

### Q14. How did you orchestrate this whole pipeline?

**Situation:** Daily pipeline with ~25 jobs across bronze, silver, gold, plus the dbt layer. Dependencies between everything.

**Task:** Pick an orchestration model that handles a complex DAG, retries on failure, alerts on SLA miss, doesn't introduce a separate team into the dependency chain.

**Action:** **Databricks Workflows.** Considered Airflow (Juul had one for non-data work) — would have meant a separate team owning the runtime, awkward Databricks integration (DatabricksRunNowOperator polls), Airflow scheduling latency adding 30s per task. Workflows is native, sub-second transitions, lineage capture for free.

**The DAG:**

```
                                ┌── auto-loader bronze stream (per source × 14 sources)
                                │
       schedule trigger 4 AM ──►├── address_normalization (depends on all bronze)
                                │
                                ├── candidate_retailer_build (depends on address_normalization)
                                │
                                ├── master_retailer_ER (depends on candidate_retailer_build) ──┐
                                │                                                              │
                                ├── product_master_build (independent of retailer) ─────────────┤
                                │                                                              │
                                │                                                              ▼
                                ├── canonical_sales (depends on master_retailer + product_master)
                                │
                                ├── gold/dbt models (depends on canonical_sales)
                                │
                                └── dashboard refresh + alerts
```

Implemented as one master workflow with task dependencies. Each task = one notebook or one dbt run.

**Retry policy:** linear backoff, max 3 retries, escalate to PagerDuty after 4th failure.

**Alerting:** any failure in the daily DAG pages the on-call data engineer. SLA: full DAG complete by 8 AM CST for Trade Marketing's morning dashboards.

**Backfill capability:** the pipeline takes a `--backfill-date` parameter. Each layer is idempotent (silver MERGE, gold idempotent INSERT OVERWRITE). To rebuild the last 30 days: loop the parameter, ~3.5h × 30 = manageable.

**Result:** Daily DAG completes in ~3.5h (P95). Mean time to detect failure: <8 min. Backfilled 6 months of historical data during initial cutover in ~8 days.

### Q15. Walk me through a production incident on this project.

**Situation:** November 14, 2025. PagerDuty fired at 5:47 AM CST — the master_retailer_ER task failed. SLA breach risk: Trade Marketing's Monday morning dashboards.

**Task:** Diagnose, fix, recover the day's pipeline.

**Action:**

**5:50 — investigated.** Spark UI showed the connected-components stage OOM'd. Splink had produced ~12M candidate pairs for the day's batch, up from ~50M cumulative previously. Something exploded the pair count.

**6:00 — root cause.** A new Juul SKU launch in TX brought in ~40k retailer records from a distributor I hadn't seen before (a one-off direct-to-retailer push from Trade Marketing). All 40k records had the SAME placeholder address ("1 PROMO DR, TX") because Trade Marketing's planning sheet hadn't populated real addresses yet — they intended to fill them later. The blocking on (zip5 + first_token_of_name) put all 40k into the same block → 40k² / 2 = 800M pairs in one block.

**6:15 — quick fix.** Added a sanity filter at the candidate-build step: any source where address quality < 0.5 (more than 50% placeholder addresses) gets quarantined, not fed into ER. Ran the pipeline with the quarantine in place. Completed by 7:40 — Trade Marketing dashboards delayed by ~40 min vs the 8 AM SLA.

**6:30 — escalation.** Notified Trade Marketing leadership of the delay and the placeholder-address issue. Their PM acknowledged the cause and committed to fixing source data going forward.

**8:30 — post-incident actions:**
1. Permanent quarantine filter in candidate_retailer_build, configurable threshold.
2. Added a DQ alert for any source with > 10% placeholder addresses — fires before the ER stage so we don't wait until 6 AM to discover it.
3. New ingest contract with Trade Marketing's planning tool: addresses required at SKU launch time.

**Post-mortem published Nov 17:** root cause, timeline, fix, action items. Distributed in the engineering org as a learning artifact.

**Result:**
- Trade Marketing dashboards delayed 40 minutes that Monday; no further breaches since.
- Placeholder-address pattern caught proactively three times since (different sources).
- Trade Marketing's data-hygiene practices improved — they now require addresses at SKU planning.

### Q16. Data quality — what's your overall approach?

**Situation:** Data quality is the single biggest risk in a project where 12 sources merge into canonical entities. A bad row anywhere can poison promo lift calculations.

**Task:** Catch DQ issues at every layer, fast enough that bad data doesn't reach Trade Marketing.

**Action:** Four layers:

**Layer 1 — Schema enforcement at bronze.** Strict schema, non-conformant rows quarantined.

**Layer 2 — Great Expectations suites at silver:**
- `canonical_sales.units_sold > 0`
- `canonical_sales.canonical_retailer_id IS NOT NULL`
- `canonical_sales.canonical_product_id IS NOT NULL`
- Distinct count of canonical_retailer_id stable within 5% week-over-week (catches ER explosions like the Nov 2025 incident)
- Distinct count of canonical_product_id stable within 1%

**Layer 3 — Cross-table reconciliation** (Great Expectations checkpoints):
- Total units sold (sum across all distributors) reconciles within 0.5% of NetSuite ERP unit shipments
- Sum of promo-cohort sales + non-promo-cohort sales = total sales (no cohort gap)

**Layer 4 — Alation DQ badges** — every gold table has a DQ status visible to analysts. Failed-DQ tables get a red badge; analysts know to wait before using them.

**Alerting:** DLT-style hard failures page the on-call engineer. Reconciliation > 0.5% pages immediately. Trends (drift in canonical entity counts week-over-week) Slack-alert without paging.

**Result:** ~95% of bad-data incidents caught at one of the four layers before downstream consumers noticed. The Nov 2025 placeholder-address incident was caught by the Layer 2 entity-count check (after the fact, but it now fires before the ER stage).

### Q17. How did Unity Catalog fit in?

**Situation:** ~100 tables across bronze/silver/gold for this project. Need lineage for audit, masking for any PII (less PII-heavy than verification flows but retailer contact info still counts), grant management.

**Task:** Use UC as the governance backbone.

**Action:**

**1. Catalog layout.** `juul_us_prd.bronze`, `juul_us_prd.silver`, `juul_us_prd.gold` schemas. Plus `juul_us_prd.dim` for shared dimensions (state, product taxonomy reference tables) and `juul_us_prd.audit` for the log streams.

**2. Tags driving behavior.** Every table tagged with:
- `data_classification` — `internal` or `confidential` for retailer financial data
- `cost_center` — `trade_marketing` or `sales_ops`
- `dri` — engineer email
- `business_steward` — for Alation

**3. Column masking** for retailer contact info (phone, owner name):

```sql
CREATE OR REPLACE FUNCTION juul_us_prd.security.mask_retailer_contact(value STRING)
RETURNS STRING
RETURN CASE
  WHEN is_account_group_member('sales_ops_with_contact_access') THEN value
  ELSE NULL
END;

ALTER TABLE silver.canonical_retailer
  ALTER COLUMN owner_name SET MASK juul_us_prd.security.mask_retailer_contact;
ALTER TABLE silver.canonical_retailer
  ALTER COLUMN owner_phone SET MASK juul_us_prd.security.mask_retailer_contact;
```

Most analysts don't need owner contact info; the ones who do have an explicit clearance group.

**4. Column-level lineage** automatic. Trade Marketing can trace `gold.promo_performance_daily.did_lift_pct` back through `silver.canonical_sales` → `silver.canonical_retailer` → bronze distributor feeds. This was specifically useful when Q4 results looked surprising — Trade Marketing's analyst walked the lineage to verify her numbers were derived correctly.

**5. Audit via `system.access.audit`** streamed to permanent log. Reviewed by compliance quarterly.

**Result:** Zero grant-management incidents over the project. Lineage queries cut Trade Marketing's "where does this number come from" investigations from ~2 days to ~10 minutes.

### Q18. What's the CI/CD setup specific to this project?

**Situation:** ~50 notebooks, 25 workflow definitions, 80+ dbt models, plus Terraform-managed infra.

**Task:** Deploy reliably with validation gates.

**Action:**

**Repo structure:**
```
retail-sales-intelligence/
  databricks.yml
  resources/
    workflow_daily_dag.yml
    workflow_backfill.yml
  src/
    bronze/...
    silver/address_normalization/
    silver/master_retailer/
    silver/product_master/
    silver/canonical_sales/
    gold/dbt/                  # dbt project
  tests/
    unit/...
    integration/...
  terraform/
    ...
```

**PR pipeline:**
1. Linter (pylint, ruff, black, custom lints).
2. Unit tests via pytest.
3. dbt compile + test (catches SQL errors).
4. Schema diff for silver/gold tables.
5. Integration test: full DAG on a 1-day sample of all distributor feeds.
6. OPA gate on Terraform changes.
7. `databricks bundle validate` + deploy to `dev` workspace.

**Merge to main:**
- Auto-deploy to `stg`.
- `stg` runs the full DAG on a 7-day sample.
- DQ checks must pass before promotion.

**Tagged release (prd):**
- Manual approval via GitHub environment protection.
- Compliance review for any change touching tagged PII columns.
- `databricks bundle deploy --target prd`.

**Rollback:** redeploy previous tag. Delta time-travel for table-level rollback:

```sql
RESTORE TABLE juul_us_prd.silver.canonical_retailer TO VERSION AS OF 2034;
```

**Result:** Median PR-to-prd time: 4 days. Zero rollback incidents over the project. Deploy frequency: ~daily during active build, ~weekly in maintenance mode.

### Q19. Cost optimization on this pipeline?

**Situation:** Steady-state Databricks spend ~$14k/mo for this project (compute) plus ~$2k/mo for storage. Plus USPS Lambda + Splink (open-source, no license) + dbt Cloud ($800/mo).

**Task:** Run efficiently while meeting the 8 AM SLA.

**Action:**

1. **Cluster right-sizing.** Originally provisioned at 32 workers; usage analysis showed 16 was sufficient for the daily DAG. Saved ~$3.5k/mo.
2. **Photon on for SQL/aggregation jobs, off for Python-UDF-heavy stages.** ER stage uses lots of Python (Splink) → Photon premium not worth it. Saved another ~$1.2k/mo.
3. **USPS API cache.** 85% cache hit rate, cut Lambda from projected $3.4k/mo to $510/mo.
4. **dbt incremental models** for gold marts. Rebuild only the partitions affected by the latest sales window. Cut dbt runtime from 45 min to 12 min.
5. **Auto-stop SQL warehouses** at 30 min idle. Looker uses a single Pro warehouse that auto-stops when Trade Marketing isn't querying.

**Cost attribution:** every job tagged `cost_center=trade_marketing` or `sales_ops`. Monthly Looker dashboard reviewed with both teams' leadership.

**Result:** Steady-state cost $16k/mo all-in (down from initial estimate $22k). Cost-per-canonical-sale: ~$0.00008. Business approves on the trade-spend recovery alone — $1.2M ÷ $16k/mo = ~6 months payback.

### Q20. Why dbt for the gold layer?

**Situation:** Gold layer is ~80 SQL models. Analytics engineers (not data engineers) own most of them. They needed to ship marts without learning Spark API.

**Task:** Pick a transformation layer that's SQL-native, version-controlled, testable.

**Action:** **dbt-on-Databricks.** Considered:
- **Pure Databricks SQL notebooks** — works but no testing framework, no dependency management.
- **Apache Airflow DAGs of SQL queries** — Airflow we ruled out for the broader orchestration; not bringing it in for SQL alone.
- **dbt** — purpose-built for SQL transformation. Native Databricks integration. Testing via dbt tests. Lineage via dbt's DAG.

dbt won. Specific patterns:
- `models/marts/sales/` — sales-by-X marts
- `models/marts/promo/` — promo analysis marts
- `models/dim/` — dimension tables
- dbt tests for not-null, unique, accepted-values, custom SQL tests
- Incremental models for the big fact tables

**dbt + Databricks Workflows integration:** the daily DAG calls `dbt run --models marts.promo+` as one task. Workflow handles retries; dbt handles SQL.

**Result:** Analytics engineers ship gold models without DE involvement. 80+ models, dependency graph clean. Documentation auto-generated and surfaces in Alation.

---

## Phase 5 — Adjacent technical scenarios (10 min)

### Q21. If you started fresh today, what would you do differently?

**Situation:** Reflecting one month into production.

**Task:** Identify what didn't pay off as expected.

**Action:**

1. **Splink configuration tuning earlier.** I shipped Splink with default-ish parameters and let it run for a quarter before tuning. The first quarter's ER was ~3 percentage points lower precision than it could have been. If I'd invested 2 weeks in tuning up front (more labeled pairs, better blocking strategy) I'd have caught more match candidates faster.
2. **Bitemporal columns from day 1, not retrofit.** I added bitemporal columns to canonical_retailer in month 4 when Trade Marketing wanted to ask "what was this retailer's identity as of June?" Retrofitting was painful. Should have built bitemporal from the start.
3. **Sales reconciliation against ERP earlier.** I added the NetSuite reconciliation check in month 8. Should have been month 1. Would have caught two upstream data issues months earlier.

**Result:** No strategic regrets. Tactical lessons that I'd apply to the next greenfield project.

### Q22. Scenario: how would you handle Slowly Changing Dimensions for canonical_retailer?

**Situation:** Retailers change ownership, banners, addresses (rare but happens). Need to know what was true at any point in time.

**Task:** Pick an SCD pattern.

**Action:** **SCD Type 2 with bitemporal columns** — already implemented. Each row has `valid_from`, `valid_to`, `is_current`. When a retailer's attributes change, the old row gets `valid_to = <change date>`, a new row inserts with `valid_from = <change date>` and the same `canonical_retailer_id`. Two columns: `canonical_retailer_id` (stable across versions) + `retailer_version_id` (unique per version).

Joins from historical sales use:
```sql
SELECT s.units_sold, r.banner, r.address_hash
FROM silver.canonical_sales s
JOIN silver.canonical_retailer r
  ON s.canonical_retailer_id = r.canonical_retailer_id
 AND s.sale_date BETWEEN r.valid_from AND r.valid_to;
```

Cost: storage roughly 1.5× a single-version table. Worth it for analytical correctness.

**Result:** Trade Marketing can ask "show me Stop-N-Shop sales in June 2024, using the retailer attributes as they were in June 2024" and get correct answers.

### Q23. Scenario: how would you scale this pipeline 10×?

**Situation:** 10× volume — 1.2M canonical retailers, 100k SKUs, 50 distributor feeds.

**Task:** Identify bottlenecks.

**Action:**

1. **ER blocking strategy.** Current blocking (zip5 + first_token_of_name) won't scale. Would move to LSH (locality-sensitive hashing) on address embeddings.
2. **MERGE on canonical_retailer.** At 1.2M rows the MERGE INTO is still tractable, but I'd partition by state_code and only MERGE affected partitions.
3. **Splink memory.** ER state-store can balloon. Would switch to RocksDB state store or break the ER into per-state shards.
4. **USPS API throughput.** At 10× we'd hit API limits. Would negotiate enterprise tier or move to a commercial address-validation provider (Smarty Streets).
5. **Cost.** Probably 6-8× current cost (per-job overhead amortizes). Would model + re-justify.

**Result:** Architecture scales. The fundamental design is well-trodden at 10× our scale. Real risk: ER false-positive rate climbs at scale; would invest more in labeled training data.

---

## Phase 6 — Behavioral (5-10 min)

### Q24. Tell me about a disagreement with a stakeholder during this project.

**Situation:** April 2025, during the ER design phase. The Trade Marketing director wanted to commit to a 99% ER precision target. He'd seen a vendor pitch claiming 99%+ on retail entity resolution.

**Task:** Push back honestly without breaking the relationship or the project.

**Action:** I walked him through the math: 99% precision means 1 in 100 canonical retailers is incorrectly merged. With 124k canonical retailers, that's ~1,240 wrong merges. Each wrong merge means sales at retailer A are attributed to retailer B — that's bigger error than the system we were replacing.

Then I gave him real numbers: industry-published benchmarks for retail ER hover at 95-97% precision. Our PoC at month 1 hit 96%. With tuning we could get to 98%, possibly 98.5% with a year of refinement. 99% was a marketing number, not a real one.

I committed to 98% precision with measurement methodology spelled out. Came back with a written plan covering training data labeling, evaluation methodology, ongoing precision/recall monitoring.

**Result:** He accepted 98%. We shipped at 98.4%. He used the "98.4% verified precision" number in his Q1 2026 board readout. The honesty up front bought trust later.

### Q25. How did you develop people during this project?

**Situation:** Four-engineer team (me + three) plus one analytics engineer embedded.

**Task:** Real growth opportunities without sacrificing project timeline.

**Action:**
- **L4 engineer** owned the address-normalization pipeline. First time leading a sub-module end-to-end including stakeholder updates. I sat in the first three stakeholder reviews; he ran them solo after.
- **L3 engineer** owned the entity resolution evaluation harness (labeled-pair management, precision/recall reporting). Self-contained, technically interesting. She presented the methodology at our engineering all-hands.
- **Embedded analytics engineer** owned the dbt gold-layer models. Pair-programmed initially, then independent.

All three got positive reviews. The L3 got promoted at the next cycle.

**Result:** Knowledge distributed across the team. Bus factor on the pipeline is 4, not 1.

### Q26. When the project hit a blocker, how did you handle it?

**Situation:** June 2025. Splink's expectation-maximization training was producing unstable weights — successive training runs on the same labeled data produced significantly different weights. ER quality was bouncing 95% to 92% precision week-over-week.

**Task:** Identify and fix without losing the timeline.

**Action:**
1. Reproduced the instability locally on a sample dataset.
2. Diagnosed: small labeled-pair set (~500) wasn't enough for EM to converge consistently. Needed more labeled pairs.
3. Two-week sprint: built a labeling tool (simple web app) for ops analysts to label retailer pairs. Generated 2,500 new labeled pairs over two weeks via the ops team.
4. With 3,000 labeled pairs total, EM converged consistently. Precision stabilized at 98%.
5. Documented the labeling-pair lifecycle as part of ongoing maintenance — review labels quarterly, add new ones as distributors change.

**Result:** ER quality stable from July 2025 onwards. The labeling tool was a one-time investment that paid for itself in the precision improvement.

---

## Phase 7 — Closing (5-10 min)

### Q27. What would your first 30/60/90 days look like in this role?

**Situation:** Joining as Senior DE leading the new Lakehouse build.

**Task:** Land impact early without overstepping.

**Action:**
- **Days 0-30 — understand:** read design docs, Terraform modules, source-system overviews. Spend time with the existing data team and end users. Map dependencies. Identify the three highest-risk areas. Don't propose major changes yet.
- **Days 30-60 — propose:** write the architecture doc for the new Lakehouse — workspace topology, UC catalog layout, Terraform module structure, orchestration approach, governance rollout. Circulate for review.
- **Days 60-90 — execute on foundation:** ship Terraform-managed infrastructure for dev. Stand up one end-to-end reference pipeline. Begin the SAS migration inventory.

**Result:** By day 90: infrastructure exists, one reference pipeline runs, migration plan committed. Quick wins (one or two pipelines migrated) by day 90 if scope allows.

### Q28. What questions do you have for us?

**Situation:** End of the interview, my turn.

**Task:** Surface info I need to evaluate fit and show senior thinking.

**Action:**
1. **"What's the biggest blocker the existing team has hit that you're hoping a new senior engineer will unblock?"** — surfaces what they actually need.
2. **"How does data engineering interact with security and compliance? Is PII governance owned by data engineering or a separate function?"** — gauges org maturity.
3. **"What does success look like at 6 months and 12 months in this role?"** — gauges leadership clarity.
4. **"Why is this role open now — backfill or new?"** — gauges team trajectory.
5. **"Can you walk me through the first project? What's most pressing?"** — gauges role concreteness.
6. **"On-call expectations — pure platform or also application?"**
7. **"What's the team structure I'd be joining and the existing seniority distribution?"**

**Result:** I get the info I need. They see senior questions — about how the org works, what success means, what's broken.

---

## Quick-recall flashcards (review the morning of)

| Question type | Answer in one breath |
|---|---|
| Tell me about a recent project | "Retail Sales Intelligence Platform at Juul — Q1 2025 to Q1 2026. Built canonical retailer + canonical product + promo analysis on top of 12 distributor feeds. Address normalization → entity resolution → master data → promo lift mart. 247k retailers collapsed to 124k true unique. Promo lift accuracy within 2% vs 15-20% off before. $1.2M trade-spend recovery in H2." |
| Architecture in 30 seconds | "12 SFTP feeds → S3 bronze → silver canonical entities (address norm, ER, product master) → silver canonical sales → gold dbt marts → Looker. Daily DAG via Databricks Workflows, ~3.5h runtime, 8 AM SLA." |
| Why Databricks | "Spark + Python for Splink ER. Delta MERGE for bitemporal master data. Unity Catalog lineage for audit. Snowflake's external-service ER was opaque + expensive. AWS-native too many platforms." |
| Address normalization in 30 sec | "libpostal parse → standardize via USPS Publication 28 → USPS API validate (via Lambda) → SHA-256 hash for join. 99.7% normalized, 85% USPS cache hit rate, cost $510/mo." |
| Entity resolution in 30 sec | "Block by zip5 + first name token. Splink probabilistic Fellegi-Sunter scoring on (address, phone, name, banner, DUNS). Connected-components clustering. Master record selection by data-quality priority. Stable canonical_retailer_id via deterministic hash. 98.4% precision, 96.1% recall." |
| Promo analysis in 30 sec | "Difference-in-differences on (promo cohort sales) vs (control cohort sales), pre vs post. Control group = retailers similar to promo cohort but not promo'd. Cannibalization checked separately. Materialized as gold.promo_performance_daily, dbt incremental." |
| Biggest incident | "Nov 14: master_retailer_ER OOM'd. Root cause: 40k retailers with placeholder addresses from a Trade Marketing direct-push, all in same blocking key → 800M pairs in one block. Hot fix: address-quality filter at candidate-build. Permanent: DQ alert before ER stage." |
| Mentorship | "L4 owned address normalization end-to-end. L3 owned ER eval harness, presented at all-hands, promoted. Analytics engineer owned dbt gold layer." |
| Cost | "$16k/mo all-in. Right-sized clusters, Photon off for Python-UDF stages, USPS API cache, dbt incremental. Cost-per-sale ~$0.00008." |

---

## Pre-interview checklist

- [ ] Sketch the architecture in 30 seconds — practice (bronze → silver canonical entities → silver canonical sales → gold dbt marts → Looker)
- [ ] Memorize four numbers: **247k → 124k**, **±15-20% off → within 2%**, **$1.2M recovery**, **98.4% ER precision**
- [ ] Be ready to draw the ER 5-stage pipeline if asked: candidates → blocking → pairwise scoring → connected-components → master record selection
- [ ] Open Databricks docs tabs: Delta MERGE semantics, Auto Loader schema evolution, UC system tables, Asset Bundles
- [ ] Camera / lighting check 15 min before
- [ ] Water, tissues, phone silent

## Post-interview

- [ ] Thank-you email within 4 hours referencing one specific topic discussed
- [ ] Log every question they asked — useful for next round (which is probably the SAS round)
- [ ] If they referenced a tool you weren't deep on, look it up tonight

---

*Last updated: 2026-05-27*
