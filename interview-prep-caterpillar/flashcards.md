# 🃏 FLASHCARDS — cover the A line, answer from memory, uncover to check
### AEM / Commerce / Elastic · TL/Architect · Nagarro → Caterpillar
*Terse answers (memorize the keywords, not a script). Longer spoken versions are in `qa-study.md`.*

---

## AEM CORE

**Q:** The 4 layers of the AEM stack?
**A:** JCR (content repo) → Sling (URL→resource→script) → OSGi (Java module runtime) → Sites/Components/Templates.

**Q:** What is a Sling Model?
**A:** Java POJO behind a component; annotation injection (`@ValueMapValue`, `@OSGiService`); separates logic from HTL; unit-testable.

**Q:** What is HTL?
**A:** HTML Template Language (Sightly) — AEM's logic-less view templating. No Java in views.

**Q:** How does Sling resolve a request?
**A:** URL → resource (JCR node) → resource type → script/servlet by selectors + extension + method.

**Q:** Editable vs static templates?
**A:** Editable = `/conf`, author-governed + policies, no deploy to change. Static = `/apps`, dev-owned, rigid.

**Q:** Do you build components from scratch?
**A:** No — start from Core Components; extend via proxy (`sling:resourceSuperType`) + delegation pattern.

**Q:** What is MSM?
**A:** Multi Site Manager — language master + Live Copies + rollout configs = multi-country sites.

**Q:** Secure AEM — 4 things?
**A:** Dispatcher allow-list, no CRXDE on prod, least-priv service users (no admin resolver), CSRF framework + secrets in Cloud Manager.

---

## AEMaaCS & DISPATCHER

**Q:** What changed in AEM as a Cloud Service vs 6.5?
**A:** Adobe-managed, auto-scale, immutable `/apps`, Cloud Manager-only deploy, repoinit, Asset Compute, RDE, SCD replication.

**Q:** Dispatcher's 3 jobs?
**A:** Cache + load-balance + **security** (path/selector allow-list filters).

**Q:** On AEMaaCS, what is the PRIMARY cache — Dispatcher or CDN?
**A:** The CDN (Fastly), in front of Dispatcher. Dispatcher still caches, but the CDN is first and handles most traffic.

**Q:** Does Dispatcher stop caching on Cloud Service?
**A:** No. Layers stack: User → CDN → Dispatcher → AEM. Both cache; request hits AEM only if both miss.

**Q:** What controls CDN caching on AEMaaCS?
**A:** Origin response headers: `Cache-Control`, `Surrogate-Control`, `Expires`.

**Q:** How do you invalidate cache on AEMaaCS?
**A:** Mostly don't — refresh on republish; explicit = SCD invalidate; targeted = surrogate-key purge.

---

## COMMERCE / CIF

**Q:** What is CIF?
**A:** Commerce Integration Framework — links AEM to commerce (Adobe Commerce/Magento) over GraphQL.

**Q:** What is the system of record for catalog/price?
**A:** The commerce engine. AEM references by SKU; never copies catalog into the JCR.

**Q:** What does SKU mean?
**A:** Stock-Keeping Unit — the unique product ID AEM uses to reference a product.

**Q:** How do you cache a PDP with live price/inventory?
**A:** TTL-based cache of the SEO shell (content + SKU); hydrate price/inventory client-side via GraphQL.

**Q:** PLP vs PDP?
**A:** Product Listing Page (category, many products) vs Product Detail Page (one product).

**Q:** Headful vs headless commerce?
**A:** Headful = CIF server-rendered for SEO PLP/PDP. Headless = Content Fragments + GraphQL → SPA/mobile.

**Q:** B2B commerce — 4 features?
**A:** Contract/account pricing, entitlements, approval workflows, punchout (cXML/OCI) into procurement.

---

## APP BUILDER / API MESH / PIM

**Q:** What is Adobe App Builder?
**A:** Serverless Node.js actions Adobe hosts — out-of-process customization so Commerce/AEM core stays clean for upgrades.

**Q:** What is API Mesh?
**A:** Combines many sources (Commerce + PIM + ERP + REST) into ONE unified GraphQL endpoint.

**Q:** What is PIM?
**A:** Product Information Management — system of record for rich product attributes/fitment/media.

**Q:** How does PIM sync without duplicating into AEM?
**A:** Event-driven over Kafka (+ scheduled reconcile); joins to SKU at render; never into JCR.

---

## ELASTIC / SEARCH

**Q:** Why Elastic if AEM has Oak/Lucene?
**A:** Oak/Lucene = repository search. Elastic = application search at scale (facets, autocomplete, relevance, high QPS).

**Q:** Is Elastic your source of truth?
**A:** No — derived read store. Rebuilt from Commerce/PIM. If they disagree, Elastic is wrong.

**Q:** Mapping for part numbers (`1R-0750`)?
**A:** `keyword` (exact) + `edge_ngram` (autocomplete) + custom analyzer (no hyphen split) + per-locale analyzers.

**Q:** How do you tune relevance?
**A:** BM25 default → `function_score` boost (exact# > in-stock > popular); synonyms; track zero-result-rate.

**Q:** Zero-downtime reindex?
**A:** Alias swap — front end queries an alias; build new index, bulk-load, verify, repoint alias, drop old.

**Q:** Keep search fast at scale?
**A:** Right-size shards (10–50GB), replicas for QPS, filter-context (cached), `search_after` not deep paging, force-merge, ILM tiers.

**Q:** What is ILM?
**A:** Index Lifecycle Management — auto-ages data across hot/warm/cold tiers in Elastic.

**Q:** Solr vs Elastic — one line?
**A:** Both Lucene. Solr = config-schema/SolrCloud/Adobe-classic. Elastic = JSON/REST + aggregations + Stack (Kibana/ILM) + Cloud tiers.

---

## INTEGRATION / PERF / LEADERSHIP

**Q:** Why front APIs with Azure APIM?
**A:** One governed door: auth (OAuth2/JWT), rate-limit, transform, versioning, observability across microservices.

**Q:** Where does Kafka fit?
**A:** Event backbone: price/catalog/PIM change → reindex Elastic, purge CDN, sync CRM. Near-real-time, replayable.

**Q:** Integrating a slow 3rd-party system?
**A:** Timeout + retry + circuit breaker + cache; put an integration microservice between AEM and the backend.

**Q:** Search latency spikes at peak — first move?
**A:** Scope it (cluster/node stats + slow-log); short-term query guard + replicas; long-term shard sizing + filter context + circuit breaker.

**Q:** HLD vs LLD?
**A:** HLD = context/boundaries/NFRs/topology (client-facing). LLD = classes/contracts/mappings/sequences (dev-facing).

**Q:** Enforce code standards as lead?
**A:** Review checklist + pattern library + pairing + SonarQube gate; my own PRs set the bar.

---

## BUSINESS / AGILE

**Q:** How do you gather requirements?
**A:** Start from KPIs not features; journey/persona map; acceptance criteria; MoSCoW; "what does success look like as a number?"

**Q:** What is MoSCoW?
**A:** Prioritization: Must / Should / Could / Won't-have.

**Q:** Architect's role in Scrum?
**A:** Runway 1–2 sprints ahead; refinement/planning/demos; own NFR stories; capture ADRs.

**Q:** What is an ADR?
**A:** Architecture Decision Record — short written note of what was decided and why.

**Q:** Client pressures a fixed date you're unsure of?
**A:** 3-point estimate + assumptions + risk flags; discovery spike for unknowns; make scope/time/quality trade-off explicit.

**Q:** B2C vs B2B vs omnichannel?
**A:** B2C = SEO/conversion. B2B = entitlements/approvals/punchout. Omnichannel = unified catalog+inventory across channels.

**Q:** PO wants a feature you think is wrong?
**A:** Separate problem from solution; bring data + cheaper option; disagree-and-commit; document as ADR.

**Q:** Tie architecture to business value?
**A:** Relevance→conversion; cache/CWV→bounce/SEO; locale-launch→speed-to-market; reuse→lower change-cost.

---

## DEPLOYMENT PIPELINE & COMPONENTS

**Q:** What is an AEM component (in plain terms)?
**A:** A reusable, author-configurable building block (like a LEGO brick / a UI widget with a settings panel). Authors drag it onto pages.

**Q:** What does a component consist of?
**A:** HTL (markup) + dialog (author fields) + optional Sling Model (logic) + optional clientlib (JS/CSS) + policy.

**Q:** What does "developing a component" mean?
**A:** Writing the HTL, the dialog, and the Sling Model for one reusable page block — e.g. a "Product Detail" or "Hero Banner".

**Q:** What is the dialog (cq:dialog)?
**A:** The author-facing settings form for a component (e.g. pick a SKU, type a heading). Built with Granite/Coral UI.

**Q:** Code vs content in the JCR — how does each get there?
**A:** Code (components/HTL/templates) is DEPLOYED via the pipeline → /apps (immutable) + /conf. Content (pages) is AUTHORED in the running app → /content. Never deployed.

**Q:** What deploys AEM code?
**A:** Cloud Manager — the only path: Git → Maven build → Sonar gate → Dev → Stage → Prod (blue-green).

**Q:** Maven modules in an AEM project?
**A:** core (Java→OSGi bundle), ui.apps (components/HTL→/apps), ui.config (OSGi configs), ui.content (templates→/conf), dispatcher, all (wraps everything).

**Q:** How does your Java code run in AEM?
**A:** Compiled to an OSGi bundle, installed in Felix; it then provides the Sling Models / services / servlets.

**Q:** AEM environments?
**A:** Dev, Stage (= QA/UAT), Prod, + RDE for fast dev. Each is a full Author + Publish + Dispatcher + CDN.

**Q:** Does ONE pipeline deploy the whole platform?
**A:** NO. AEM, Commerce, Elastic, App Builder, microservices each have their OWN pipeline. They integrate at RUNTIME, not at deploy.

**Q:** How is Elasticsearch "deployed" vs AEM code?
**A:** Cluster provisioned (infra-as-code); index MAPPING via alias-swap reindex; DATA fed continuously by Kafka events — not a code deploy.

**Q:** At runtime, where is Elasticsearch hit on the site?
**A:** Search box, autocomplete, search-results page, product listings — the AEM page queries Elastic (via search service / API Mesh).

**Q:** At runtime, where is Commerce hit?
**A:** Price, stock, add-to-cart, checkout — via CIF GraphQL by SKU.

**Q:** Where does the CDN sit at runtime?
**A:** First hop — in front of Dispatcher, which is in front of AEM Publish. User → CDN → Dispatcher → Publish.

**Q:** Do the external systems also have dev/stage/prod?
**A:** Yes — Commerce, Elastic, APIM each have their own envs; run-mode config wires Stage AEM → Stage Commerce → Stage Elastic.

**Q:** Multi-country — separate pipeline per country?
**A:** No. One codebase, one pipeline, one Prod. Countries = MSM Live Copies + translation + context-aware config in the content tree.

---

## HOW AEM READS EXTERNAL APIS (price example)

**Q:** Where does the price actually live?
**A:** In Commerce (system of record). AEM reads it live via CIF GraphQL; never stores it.

**Q:** How does AEM read an external/microservice API?
**A:** A Sling Model makes an HTTP/GraphQL call to a URL stored in a per-environment OSGi config, routed through the APIM gateway.

**Q:** How does AEM know the right endpoint URL per environment?
**A:** OSGi run-mode config (Stage URL on Stage, Prod URL on Prod); secrets via Cloud Manager env vars.

**Q:** Standard price vs complex dealer price — path?
**A:** Standard → AEM reads Commerce directly via CIF GraphQL (no microservice). Complex B2B → optional pricing microservice behind APIM.

**Q:** Is the pricing microservice inside Commerce?
**A:** No — separate service on its own Kubernetes pipeline, behind APIM. Optional; many platforms just use Commerce.

**Q:** Price READ path vs price CHANGE/propagation path?
**A:** READ: AEM → CIF GraphQL → Commerce (live). CHANGE: Commerce → Kafka event → indexer svc → Elasticsearch + CDN purge.

**Q:** Can microservices be written in any language?
**A:** Yes — polyglot (Python/Java/Node/Go). AEM just calls an HTTP endpoint. Exception: App Builder actions are Node-only.

**Q:** What language are AEM-shop microservices usually?
**A:** Often Spring Boot (Java) for consistency, but the pattern is language-agnostic — pick the right tool per service.

---

## RAPID DEFINITIONS (one-word triggers)
**CDN** Content Delivery Network · **JCR** Java Content Repository · **OSGi** modular Java runtime ·
**CIF** Commerce Integration Framework · **SKU** Stock-Keeping Unit · **PIM** Product Information Mgmt ·
**ERP** Enterprise Resource Planning · **CRM** Customer Relationship Mgmt · **APIM** API Management gateway ·
**SCD** Sling Content Distribution · **TTL** Time To Live · **QPS** Queries Per Second · **BM25** Elastic's
default ranking algo · **DLQ** Dead-Letter Queue · **ILM** Index Lifecycle Mgmt · **KPI** Key Performance
Indicator · **ADR** Architecture Decision Record · **PO** Product Owner · **p95** 95th-percentile latency ·
**SoT** Source of Truth · **SPA** Single-Page App · **CWV** Core Web Vitals · **HLD/LLD** High/Low-Level Design.

---

## 📥 ANKI / QUIZLET IMPORT (tab-separated — paste into Quizlet "Import", or Anki with Tab field separator)
```
The 4 layers of the AEM stack?	JCR → Sling → OSGi → Sites/Components/Templates
What is a Sling Model?	POJO behind a component; annotation injection; logic out of HTL; testable
How does Sling resolve a request?	URL → resource → resource type → script/servlet by selectors+extension+method
Editable vs static templates?	Editable=/conf author-governed+policies; static=/apps dev-owned
What is MSM?	Multi Site Manager — language master + Live Copies + rollout = multi-country
AEMaaCS vs 6.5?	Adobe-managed, auto-scale, immutable /apps, Cloud Manager deploy, repoinit, Asset Compute, RDE, SCD
Dispatcher's 3 jobs?	Cache + load-balance + security (allow-list filters)
Primary cache on AEMaaCS?	The CDN (Fastly) in front of Dispatcher; Dispatcher still caches but is secondary
What controls CDN caching on AEMaaCS?	Response headers: Cache-Control, Surrogate-Control, Expires
How to invalidate cache on AEMaaCS?	Mostly don't; SCD invalidate; surrogate-key purge
What is CIF?	Commerce Integration Framework — AEM↔commerce over GraphQL
Catalog source of truth?	Commerce engine; AEM references by SKU; not in JCR
Cache a PDP with live price?	TTL cache the SEO shell; hydrate price/inventory client-side via GraphQL
Headful vs headless commerce?	Headful=CIF server-rendered SEO; headless=Content Fragments+GraphQL→SPA
B2B commerce features?	Contract pricing, entitlements, approvals, punchout (cXML/OCI)
What is App Builder?	Serverless Node actions Adobe hosts; out-of-process; keeps core clean
What is API Mesh?	One unified GraphQL endpoint over Commerce+PIM+ERP+REST
What is PIM?	Product Information Management — system of record for product attributes
Why Elastic over Oak/Lucene?	Oak=repository search; Elastic=application search at scale (facets/autocomplete/relevance/QPS)
Is Elastic source of truth?	No — derived read store, rebuilt from Commerce/PIM
Part-number mapping?	keyword (exact) + edge_ngram (autocomplete) + custom analyzer + per-locale analyzers
Tune relevance?	BM25 → function_score boost (exact#>in-stock>popular); synonyms; track zero-result-rate
Zero-downtime reindex?	Alias swap — build new index, bulk-load, verify, repoint alias, drop old
Keep search fast?	Right-size shards, replicas, filter-context, search_after, force-merge, ILM
Why Azure APIM?	One governed door: auth, rate-limit, transform, versioning, observability
Where does Kafka fit?	Event backbone: change → reindex/purge-CDN/sync-CRM; near-real-time
HLD vs LLD?	HLD=context/boundaries/NFRs (client); LLD=classes/contracts/mappings (dev)
How to gather requirements?	Start from KPIs; journey/persona map; acceptance criteria; MoSCoW
Architect's role in Scrum?	Runway 1-2 sprints ahead; refinement/planning/demos; own NFR stories; ADRs
Fixed-date pressure?	3-point estimate + assumptions + discovery spike; scope/time/quality explicit
B2C vs B2B vs omnichannel?	B2C=SEO/conversion; B2B=entitlements/approvals/punchout; omni=unified catalog+inventory
PO wants a wrong feature?	Separate problem from solution; data + cheaper option; disagree-and-commit
```
