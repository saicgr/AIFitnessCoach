# ⭐ Q&A STUDY SHEET — read question, answer out loud, check yourself
### TL / Architect · AEM / Commerce / Elastic · Nagarro → Caterpillar
*Abbreviations are spelled out the first time. Swap `[...]` for your real numbers. Practice the full conversation in `mock-interview.md`.*

---

## SECTION 1 — About you & your project

**Q1. Tell me about yourself / your current role.**
A: I'm a technical lead and architect with **[10+]** years across Java and Adobe Experience Manager
(AEM). For the last **[few]** years I've led the architecture of a global parts-and-commerce platform —
content on AEM, commerce on Adobe Commerce, search on Elastic. I'm a **hands-on architect**: I own the
design but I still personally write the hard parts, mentor the team, and run the client-facing technical
discussions.

**Q2. Walk me through the ARCHITECTURE of your platform.** *(the SYSTEM — what you built)*
A: A global aftermarket parts + equipment platform. **Content on AEM as a Cloud Service**; **commerce
on Adobe Commerce through CIF** (Commerce Integration Framework, which connects AEM to commerce over
GraphQL); **parts search on Elastic Cloud**; a **PIM** (Product Information Management system) as the
source of truth for product attributes; **App Builder + API Mesh** unifying Commerce, PIM and ERP
(Enterprise Resource Planning) behind one GraphQL endpoint; **Kafka** as the event backbone; **Azure
APIM** (API Management gateway) in front of Spring Boot microservices. Fastly CDN → Dispatcher → AEM.
**[30+]** countries, **[18]** languages, **~[2M]** products, both B2B dealers and B2C buyers.

**Q3. Walk me through your DAY-TO-DAY.** *(this is a DIFFERENT question — what YOU personally do)*
A: Morning stand-up and unblocking the **[12]**-person onshore/offshore team. Then 1–2 hours hands-on
coding the parts I own — the core Sling Models, the Elastic indexing service, the API Mesh resolvers.
Backlog refinement and sizing with the product owner. Design reviews and writing decision records. Pull-
request reviews against a checklist. A client walkthrough a couple times a week. And production triage
when a search, performance or cache alert fires.

**Q4. Are you hands-on or just architecture?**
A: Hands-on. I don't design anything I can't build myself — I prototype the risky parts first to
de-risk the design, then write the core of it and set the pattern the team follows.

---

## SECTION 2 — AEM core

**Q5. Explain the AEM technology stack.**
A: Four layers. **JCR** (Java Content Repository) is the content tree where everything lives, built on
Jackrabbit Oak. **Apache Sling** maps a request URL to a content resource to a script — "everything is
a resource." **OSGi** (the modular Java runtime, Apache Felix) is how code ships as bundles and
services. On top sit Sites, Templates, Components and Sling Models.

**Q6. What is a Sling Model and why use it?**
A: A plain Java object behind a component that pulls in content via annotations — `@ValueMapValue` reads
a property, `@OSGiService` injects a service, `@PostConstruct` runs init logic. It separates business
logic from the view, and it's unit-testable. It's the standard, paired with HTL (the logic-less HTML
Template Language) for the markup.

**Q7. How does Sling resolve a request?**
A: URL → resource (the JCR node) → resource type → then it picks a script or servlet by selectors,
extension and method. So `product.specs.html` uses the `specs` selector to render a variant.

**Q8. Editable vs static templates?**
A: Editable templates live in `/conf` and are author-governed — authors define structure and policies
without a code deploy. Static templates live in `/apps` and are dev-owned and rigid. For a big org with
many marketers, editable templates plus policies are the answer: governance without a release for every
layout change.

**Q9. Do you build components from scratch?**
A: No. I start from Adobe's **Core Components** — versioned and accessible — using the proxy pattern
(my component inherits the core one via `sling:resourceSuperType`) and extend with the delegation
pattern. I only build bespoke when there's no core equivalent.

**Q10. How do you handle multi-language, multi-country?** *(very relevant to Caterpillar)*
A: **MSM** — Multi Site Manager. A language master, then Live Copies per country with rollout configs,
so country sites inherit but can break inheritance locally where needed. Translation runs through the
translation workflow. That's how a new market becomes a content-and-translation effort instead of a
code release.

**Q11. How do you secure an AEM platform?**
A: Dispatcher allow-list filters, disable the CRXDE dev console on production, least-privilege service
users — never the admin resolver — the CSRF (Cross-Site Request Forgery) framework, and secrets via the
Cloud Manager environment, never committed to the repo.

---

## SECTION 3 — AEM as a Cloud Service & Dispatcher

**Q12. What's different about AEM as a Cloud Service vs older AEM 6.5?**
A: It's Adobe-managed and auto-scaling. `/apps` is **immutable** — no runtime writes. Deploys only go
through **Cloud Manager** (Git → Maven build → SonarQube quality gate → blue-green). Service users and
base content come from **repoinit**. Assets process through Asset Compute microservices. There's a
Rapid Development Environment for fast iteration, and Sling Content Distribution replaces classic
replication.

**Q13. What does the Dispatcher do?** *(Interviewer 1 coaches this — be precise)*
A: Three jobs: it's a **cache**, a **load-balancer**, and a **security layer** — it filters which paths
and selectors are even allowed through. It is NOT just a cache; the security filtering is the part
people forget.

**Q14. How does caching work on AEM as a Cloud Service, and how do you invalidate?**
A: On Cloud Service the **primary cache is the Adobe-managed CDN, Fastly**, not Dispatcher. It's driven
by origin response headers — `Cache-Control`, `Surrogate-Control`, `Expires`. Dispatcher config ships
as code. I usually don't invalidate manually — Dispatcher refreshes on republish and the CDN respects
TTLs (time-to-live expiries). For an explicit flush I use the Sling Content Distribution invalidate
action, and for targeted purges I tag responses with surrogate keys and purge by tag.

---

## SECTION 4 — Commerce / CIF

**Q15. What is CIF?**
A: Commerce Integration Framework — Adobe's connector that links AEM to a commerce backend (Adobe
Commerce / Magento) over **GraphQL**. Commerce stays the system of record for catalog, price, inventory
and checkout; AEM references products by **SKU** (Stock-Keeping Unit, the product ID) and owns the
content around them. It ships CIF Core Components — product, category, search, cart.

**Q16. How do you keep catalog and content in sync?**
A: I don't duplicate the catalog into AEM. Commerce is the source of truth; AEM references by SKU and
pulls live data through GraphQL. Putting the catalog in the JCR would be a maintenance trap.

**Q17. How do you cache a product page when price and inventory change constantly?**
A: The classic tension. Dispatcher only caches GET requests, so I design cacheable, stable GET URLs.
For CIF pages Adobe recommends TTL-based caching, not event invalidation, because the catalog changes
too often. So I cache the SEO shell — content plus the SKU — and hydrate the volatile price and
inventory client-side. The cached page stays cached and the dynamic bits load async.

**Q18. Headless vs headful commerce — when each?**
A: Headful — CIF components server-rendered in AEM — for SEO-heavy listing and detail pages. Headless —
AEM Content Fragments exposed via GraphQL feeding a single-page app or mobile — when the experience is
a separate front end and AEM is just the content source. Most real platforms mix both.

**Q19. What changes for B2B commerce?** *(Caterpillar dealers / Cat IP procurement)*
A: Account-based pricing and contract catalogs, entitlements, requisition and approval workflows, bulk
reorder, **punchout** — connecting the store into the buyer's procurement software over the cXML or OCI
protocols — and quote-to-order. The commerce engine enforces entitlements; AEM personalizes content per
dealer segment.

---

## SECTION 5 — App Builder, API Mesh, PIM

**Q20. What is Adobe App Builder and when do you use it?**
A: A serverless extensibility platform — you write custom logic as Node.js actions that Adobe hosts and
scales. The point is **out-of-process** customization: you keep your code outside the Commerce or AEM
core, so upgrades stay clean and the custom logic scales independently.

**Q21. What is API Mesh?**
A: It combines multiple sources — Commerce GraphQL, PIM, ERP, third-party REST — into one unified
GraphQL endpoint. So the storefront makes a single query instead of fanning out to four systems. For a
parts platform, Mesh aggregates the catalog from Commerce, enriched attributes from PIM, and inventory
from ERP behind one graph.

**Q22. Where does PIM sit and how do you sync it?**
A: PIM is the system of record for rich product attributes — specs, fitment, media. It syncs to Commerce
and to the Elastic index, never into the JCR. Sync is event-driven over Kafka for near-real-time, plus a
scheduled reconcile to catch drift. AEM joins PIM attributes to the SKU at render time.

---

## SECTION 6 — Elastic / Search (your differentiator)

**Q23. AEM already has Oak/Lucene search — why add Elasticsearch?**
A: Oak's Lucene is for repository queries — authoring and content lookups inside the JCR. It's not built
to be an application search engine over millions of products at high QPS (queries per second). Elastic
is the application-search tier: faceting, typo tolerance, autocomplete, per-locale relevance, analytics.
I index content and catalog out of AEM and Commerce into Elastic and query Elastic from the front end.

**Q24. Is Elastic your source of truth?**
A: No — never. Elastic is a **derived read store**. Commerce and PIM are the systems of record; Elastic
is rebuilt from them. If they disagree, Elastic is wrong and gets reindexed.

**Q25. How do you model part-number search?** *(`1R-0750`-style)*
A: Multi-field. A `keyword` field for exact part-number match, plus an `edge_ngram` (or
`search_as_you_type`) field for autocomplete, and a custom analyzer that doesn't split on the hyphen and
handles the alphanumeric pattern. Descriptions are `text` with per-locale language analyzers; facets
like model and category are `keyword`; specs are numeric.

**Q26. How do you tune relevance?**
A: Start with BM25 — Elastic's default ranking algorithm — then `function_score` boosting: exact part
number first, then in-stock, then popular items. Synonyms for industry terms. And I measure
zero-result-rate and click-through, not just latency, so I'm tuning to the business outcome.

**Q27. How do you reindex without downtime?**
A: **Alias swap.** The front end always queries an alias, never a concrete index. To reindex I build a
new index with the new mapping, bulk-load it (idempotent, keyed by SKU), verify it, then atomically
repoint the alias and drop the old one. Indexing is event-driven off Kafka; failures go to a dead-letter
queue with retry.

**Q28. How do you keep search fast at scale?**
A: Right-size shards to the data — roughly 10–50GB each, don't over-shard. Replicas for read throughput.
Put clauses that don't need scoring into filter context, which is cached. Use `search_after` instead of
deep pagination. Force-merge read-only indices. And ILM — Index Lifecycle Management — to age data
across hot, warm and cold tiers.

**Q29. You've used Solr too — Solr vs Elastic?** *(rapport with Interviewer 1)*
A: Both are Lucene under the hood. Solr is great with config-driven schema, strong built-in faceting,
and an existing SolrCloud/Zookeeper ops setup — classic in the Adobe world. Elastic wins on JSON/REST
ergonomics, richer aggregations, and the Elastic Stack — Kibana, ILM, Elastic Cloud's hot-warm-cold
tiers — plus autocomplete and relevance experimentation at high QPS. For heavy autocomplete and
per-locale relevance I lean Elastic Cloud. *(Then ask him what drove his Solr→Elastic migration.)*

---

## SECTION 7 — Integration, performance, leadership

**Q30. Why front your APIs with Azure APIM?**
A: One governed front door instead of point-to-point coupling: central authentication (OAuth2/JWT
tokens), rate-limiting and throttling, request/response transformation, caching, versioning, and
observability across all the microservices. With this many integrations it's where I enforce and monitor
everything consistently.

**Q31. Where does Kafka fit?**
A: It's the event backbone. A price, catalog or PIM change publishes an event; consumers reindex
Elastic, purge CDN cache, and sync the CRM. That gives near-real-time sync with replay and backpressure
instead of brittle synchronous chains.

**Q32. How do you integrate AEM with a slow third-party system?**
A: Wrap every external call in a service with a timeout, retry, and circuit breaker, plus caching. For
heavy backends I put an integration microservice between AEM and the system so AEM stays a thin
content-and-presentation tier. Contract-first — OpenAPI or a GraphQL schema.

**Q33. Production search latency spikes at peak — walk me through it.**
A: Scope it first — Elastic or upstream? I check cluster and node stats and the slow-log in Kibana.
Usual culprits: bad shard sizing, a leading-wildcard query, or a hot shard. Short term: a query guard
plus more replicas. Long term: right-size shards, move non-scoring clauses to filter context,
`search_after` for paging, force-merge, and a circuit breaker with cached fallback so a slow cluster
never wedges the page. That pattern took us from **[~1.8s]** to **[~180ms]** at p95.

**Q34. HLD vs LLD — what goes in each?**
A: High-Level Design is client-facing: context, integration boundaries, non-functional requirements,
deployment topology. Low-Level Design is dev-facing: class designs, endpoint contracts, index mappings,
sequence diagrams, error handling.

**Q35. How do you mentor and enforce standards as a lead?**
A: A written review checklist — HTL not Java in views, no admin resolver, null-safety, Sling Model
tests — an internal pattern library, pairing on hard tickets, SonarQube quality gates in the pipeline,
and my own pull requests setting the bar.

---

## SECTION 8 — Business / Agile (Interviewer 2) — lead with OUTCOME, then how

**Q36. Tell me about a multi-country or multi-brand rollout.**
A: The business pain was every new country needed an engineering release — marketing was blocked on us.
We re-architected for self-serve: MSM language master plus Live Copies per country, and editable
templates plus policies so marketers compose pages with no code deploy. The hard part wasn't technical,
it was governance vs local autonomy — solved with agreed break-inheritance rules. Outcome: a new locale
went from a multi-week release to a content-and-translation effort in days.

**Q37. How do you gather requirements from non-technical stakeholders?**
A: I start from business goals and KPIs (Key Performance Indicators), not features. Workshops, journey
and persona mapping, then I turn each ask into acceptance criteria with the product owner. I prioritize
with MoSCoW — Must, Should, Could, Won't — surface assumptions early, and validate with a clickable flow
before committing architecture. My favorite question is "what does success look like as a number?"

**Q38. How do you operate as an architect in Scrum?**
A: I keep an architecture runway one or two sprints ahead so the team is never blocked. I'm in
refinement checking feasibility and splitting epics, in planning committing with the team, and in
reviews demoing. I deliberately own the non-functional stories — performance, security, search relevance
— so they don't get crowded out, and I capture decisions as short ADRs (Architecture Decision Records).

**Q39. A client pressures you for a fixed date you're unsure about.**
A: I never give a single number on an unknown. I give a three-point estimate — optimistic, likely,
pessimistic — with assumptions and the risky long-poles called out. If there's real uncertainty I
propose a short discovery spike to convert unknowns to knowns, then commit. Under pressure I make the
scope-time-quality trade-off explicit: hit the date with this scope, fast-follow the rest.

**Q40. B2B vs B2C vs omnichannel — what changes?**
A: B2C is anonymous-friendly, SEO and conversion-led, simple cart to checkout. B2B is account-based:
contract pricing, entitlements, approval workflows, bulk reorder, punchout into procurement systems.
Omnichannel is one consistent catalog and content across web, mobile, dealer portal and call center
with unified inventory. The commerce engine owns entitlements; AEM personalizes content per segment.

**Q41. A product owner wants a feature you think is wrong.**
A: I separate the problem from their proposed solution — restate the outcome they actually want, bring
data, and offer a cheaper option that hits the same KPI, with the cost and risk of their version laid
out. If they still want it and it's their call, I document it and deliver it well. Disagree, then commit.
I push back on the how, rarely on their why.

**Q42. How do you tie architecture to business value?**
A: Every non-functional decision maps to a metric. Search relevance and autocomplete drive conversion
and lower zero-result-rate. Cache-hit ratio and Core Web Vitals drive bounce and SEO. Faster locale
launch is speed-to-market. Component reuse is lower change-cost. I report architecture health in
business terms, not server terms.

---

## SECTION 9 — Behavioral (have a real story for each)

**Q43. Biggest production issue you owned?** → The parts-search-returns-nothing story (analyzer fix +
alias swap; zero-result-rate to ~0%, p95 1.8s → 180ms).

**Q44. A key architecture decision and its trade-offs?** → Keeping the catalog out of the JCR — Commerce
as source of truth, SKU references, App Builder + Mesh for clean upgrades vs the easy-but-wrong path of
copying catalog into AEM.

**Q45. A time you led/mentored a team?** → The review checklist + pattern library + Sonar gates that
raised quality across an onshore/offshore team without making you the bottleneck.

**Q46. "Tell me about yourself" (the opener)?** → Chain three: built a multi-country platform → fixed a
revenue-critical search fire → led the team through it. About 90 seconds.

---

## SECTION 10 — Questions YOU ask them

**Interviewer 1 (technical):** Already on AEM as a Cloud Service or mid-migration? · Search on SolrCloud
or Elastic Cloud, and who owns the indexing pipeline? · Composable via App Builder + API Mesh, or OSGi +
APIM? · Where does PIM sit? · Top production pain point right now?

**Interviewer 2 (business):** Primarily B2B dealer/procurement or B2C? · How mature is the Agile setup —
dedicated product owner, fixed-scope or capacity model? · Onshore/offshore split? · Top business pain
driving the program — speed-to-market, conversion, or consolidation?

---

## 30-MINUTE TIMING
0–3 min: intro (30-sec architecture + "day to day I…"). · 3–22 min: their questions — 30–60 sec each,
headline first, then stop. · 22–27 min: your questions. · 27–30 min: wrap.

**Top traps:** Dispatcher = cache + load-balance + SECURITY · Elastic ≠ source of truth · catalog ∉ JCR
· don't customize Commerce core (that's why App Builder exists) · never bluff App Builder/Mesh to an
Adobe Champion — give the correct concept + "haven't run it in prod."
