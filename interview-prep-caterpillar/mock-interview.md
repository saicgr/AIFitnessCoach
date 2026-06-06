# 🎤 MOCK INTERVIEW — full transcripts (read it out loud)
### TL / Architect · AEM / Commerce / Elastic · Nagarro → Caterpillar

> Two realistic ~25–30 min transcripts, one per interviewer, written as actual back-and-forth with
> **follow-up probes** (that's how real interviews go — they dig). Everything is anchored on **YOUR
> platform** (see `STUDY-THIS.md`) so your story stays consistent. **You** = your lines;
> *(coaching notes in italics)*. Swap `[...]` for your real numbers.
>
> **Abbreviations are spelled out in (brackets) the first time they appear** — e.g. PLP/PDP = product
> listing page / product detail page. Glossary of the rest is at the bottom.

---

# 🟦 MOCK A — Technical round (Interviewer 1, the Adobe Champion)

**Interviewer:** Hey, thanks for joining. Let's keep it practical. Tell me about the platform you're
working on day to day and where you sit in it.

**You:** Sure. I'm the technical lead and architect on a **global aftermarket parts and equipment
platform** — same shape as a dealer-driven commerce site. **Content runs on AEM as a Cloud Service**,
**commerce on Adobe Commerce through CIF** (Commerce Integration Framework), **parts search on Elastic
Cloud**, with a **PIM** (Product Information Management system) as the system of record for product
attributes. It serves **[30+]** countries, **[18]** languages, around **[2M]** SKUs (stock-keeping
units — the unique product IDs), and both **B2B dealers and B2C** buyers.
The way it's wired: Fastly CDN (Content Delivery Network) in front of Dispatcher in front of AEM
publish. AEM owns brand and product *content* and renders **PLP/PDP** (product listing pages and
product detail pages) through **CIF**, referencing products by **SKU** — the catalog itself lives in
Commerce, never in the JCR (Java Content Repository, AEM's content store). Product attributes flow from
**PIM**. Search is indexed **out** into Elastic. And the integration layer is **App Builder plus API
Mesh** unifying Commerce, PIM and ERP (Enterprise Resource Planning system) behind one GraphQL
endpoint, with **Kafka** as the event backbone and **Azure APIM** (API Management gateway) fronting our
Spring Boot microservices.
I'm a hands-on architect — I own the HLD/LLD (high-level and low-level design) but I personally write
the hard parts: the core Sling Models, the Elastic indexing service, and the Mesh resolvers.

**Interviewer:** Good. You said CDN in front of Dispatcher — on AEMaaCS, what actually does the caching,
and how do you invalidate?

**You:** On Cloud Service the **primary cache is the Adobe-managed CDN, Fastly**, not Dispatcher.
Caching is driven by origin response headers — `Cache-Control`, `Surrogate-Control`, `Expires`.
Dispatcher is still there for caching, load-balancing and **security filtering**, and its config now
ships **as code** in the dispatcher module, validated by the SDK. For invalidation I mostly *don't* do
it manually — Dispatcher refreshes on republish and the CDN respects TTLs (time-to-live cache
expiries). When I need an explicit flush I use the **SCD** (Sling Content Distribution) **invalidate**
action, and for targeted purges I tag responses with **surrogate keys** so I can purge by tag at the CDN.

**Interviewer:** *(probing)* Right — so how do you cache a product page when price and inventory change
every few minutes? Doesn't that blow up your cache?

**You:** That's the classic tension. Dispatcher only caches **GET**, so first I design the commerce
GraphQL for cacheable, stable GET URLs tied to content paths. For CIF pages specifically Adobe
recommends **TTL-based caching** rather than event invalidation, because the catalog changes too often.
So I cache the **SEO shell** — content plus the SKU — at the CDN with a short TTL, and **hydrate the
volatile price and inventory client-side** through the Commerce GraphQL API. The cached page stays
cached, the dynamic bits come in async, and caching is configurable per CIF component and on the
GraphQL client OSGi service. Net result we held anonymous cache-hit ratio around **[90%+]** without
ever serving a stale price.

**Interviewer:** Nice. Let's talk search. AEM already has Oak and Lucene — why did you stand up Elastic
at all?

**You:** Oak/Lucene is for **repository** queries — authoring, content lookups inside the JCR. It's not
built to be an application search engine over **[2M]** parts at high QPS (queries per second). Elastic
is the **application search** tier: faceted navigation, typo tolerance, autocomplete, per-locale
relevance, analytics. I
index content and catalog *out of* AEM and Commerce into Elastic and query Elastic from the front end.
Important framing: Elastic is a **derived read store, never the source of truth**.

**Interviewer:** Part numbers are nasty — `1R-0750`, hyphens, alphanumerics, partial matches. How's
your mapping?

**You:** Multi-field. A `keyword` sub-field for **exact** part-number match, plus an **`edge_ngram`**
(or `search_as_you_type`) field for **autocomplete**, and a **custom analyzer** that doesn't split on
hyphens and handles the alphanumeric pattern. Descriptions are `text` with **per-locale language
analyzers**; facets like model and category are `keyword`; specs are numeric. On relevance I start with
BM25 (Elasticsearch's default relevance-ranking algorithm) then `function_score` boosting — exact part
number first, then in-stock, then popular SKUs — plus
synonyms for industry terms. And I watch **zero-result-rate** as the health metric, not just latency.

**Interviewer:** *(probing)* And when you re-map or re-index — how do you do that without downtime?

**You:** **Alias swap.** The front end always queries an **alias**, never a concrete index. To reindex
I build a brand-new index with the new mapping, bulk-load it — idempotent, keyed by SKU — verify it,
then **atomically repoint the alias** and drop the old index. The indexing itself is event-driven off
**Kafka**: a price or PIM change publishes an event, a consumer transforms it to an Elastic document and
pushes via the **Bulk API**; failures go to a **DLQ** (dead-letter queue — a holding queue for failed
messages) with retry, and a periodic full reconcile catches drift.

**Interviewer:** You've used SolrCloud too, I saw. Solr vs Elastic — how do you decide?

**You:** *(this is his world — be genuine, then turn it into a question)* Both are Lucene under the hood.
**Solr** is great when you want config-driven schema, strong built-in faceting, and you're already in a
SolrCloud/Zookeeper ops world — it's classic in the Adobe ecosystem. **Elastic** wins for the
JSON/REST developer ergonomics, richer aggregations, and the **Elastic Stack** — Kibana, ILM (Index
Lifecycle Management — auto-ages data across hot/warm/cold tiers), **Elastic Cloud's** hot-warm-cold
tiers — plus it's strong for autocomplete and relevance
experimentation at high QPS. For a parts catalog with heavy autocomplete and per-locale relevance I
lean Elastic Cloud; if a shop already has working relevance on SolrCloud, the migration cost may not
justify it. I'm curious — I think you've migrated Solr to Elastic; what drove your call?

**Interviewer:** *(answers — you've just turned an exam into a conversation)* … Okay, integration. You
mentioned App Builder and API Mesh. Why not just do it in OSGi services inside AEM?

**You:** Two reasons: **clean upgrades** and **independent scaling**. **App Builder** runs custom logic
as **serverless Node actions on Adobe I/O Runtime** (Adobe's serverless hosting — "out of process"
means the code runs outside the Commerce/AEM core), so I'm not forking the Commerce or
AEM core, which keeps upgrades clean. **API Mesh** lets me combine Commerce GraphQL, PIM, ERP and
third-party REST into **one unified GraphQL endpoint**, so the storefront makes a single query instead
of fanning out to four systems. So Mesh aggregates parts catalog plus enriched PIM attributes plus ERP
inventory behind one graph, and App Builder runs the sync and transform actions — for example, an I/O
Event on a price update kicks the reindex. Heavy OSGi integration logic inside AEM would couple
everything and make upgrades painful.

**Interviewer:** Where does PIM sit, and how do you keep it in sync without it duplicating into AEM?

**You:** PIM is the **system of record for rich attributes** — specs, fitment, media references. It
syncs to Commerce and to the Elastic index, never into the JCR. AEM joins PIM attributes to the **SKU**
at render time through GraphQL/Mesh. Sync is event-driven over **Kafka** for near-real-time plus a
scheduled reconcile for drift. AEM stays authoring-only for the *content around* the product, not the
product data itself.

**Interviewer:** Quick one — APIM. Why front everything with Azure APIM?

**You:** One governed front door instead of point-to-point coupling: central auth — OAuth2/JWT (token-
based authentication standards) — **rate-limiting and throttling**, request/response transformation,
caching, versioning, and observability across the microservice estate. With this many integrations —
AEM, Commerce, PIM, CRM (Customer Relationship Management system), dealer systems — APIM is where I
enforce and monitor it all consistently. Logic Apps handle the lower-code orchestration flows.

**Interviewer:** Last technical one. You get paged: parts search latency spikes at peak. Walk me
through it.

**You:** First, scope it — is it Elastic or upstream? I check **cluster and node stats and the
slow-log** in Kibana. Common culprits: poorly sized shards, a query doing a **leading wildcard**, or a
hot shard. Short term I'd add a query guard and scale **replicas** to spread read load. Then the real
fix: right-size shards to data — roughly 10–50GB each, don't over-shard — move scored clauses that don't
need scoring into **filter context** so they're cached, switch deep pagination to **`search_after`**,
force-merge read-only indices, and make sure the service layer has a **timeout plus circuit breaker**
with a cached fallback so a slow cluster never wedges the whole page. That pattern took us from
**[~1.8s]** p95 (95th-percentile response time — the slowest 5% of requests) to **[~180ms]**.

**Interviewer:** Solid. What questions do you have for me?

**You:** Three. Is the engagement already on AEMaaCS or mid-migration? Is search SolrCloud or Elastic
Cloud today, and who owns the indexing pipeline? And what's the top production pain point right now —
relevance, cache-hit ratio, or sync latency?

---

# 🟩 MOCK B — Business / Functional round (Interviewer 2, the Agile consultant)

**Interviewer:** Hi! I'm less on the code side — I care how you work with the business. Give me the
quick version of your current program and your role in it.

**You:** Happy to. It's a **global parts commerce and content platform** — **[30+]** countries, both
**B2B dealers and B2C** buyers. The business drivers are **speed-to-market for new countries**, **search
conversion**, and **consolidating brands** onto one platform. My role is technical lead/architect, but
a big part of it is **client-facing** — I gather requirements, run solution walkthroughs, and I sit in
the Scrum team. I lead with the *outcome* the business wants and work back to the architecture.

**Interviewer:** You said multi-country. Tell me about a multi-brand or multi-country rollout you've
done — what made it hard?

**You:** The business pain was that **every new country needed an engineering release** — marketing was
blocked on us. We re-architected so they self-serve: **MSM** (Multi Site Manager — AEM's multi-country
content feature) language masters with **Live Copies** per country, and **editable templates plus
policies** so local marketers compose pages from a governed
component set with **no code deploy**. Translation runs through a workflow; dealers and regions get
their own access. The hard part wasn't technical — it was **governance versus local autonomy**: how much
can a local market change before it breaks brand consistency. We solved that with break-inheritance
rules agreed with the business. Outcome: a new locale went from a **[multi-week release]** to a
**content-and-translation effort in days**.

**Interviewer:** How do you gather requirements from people who can't talk OSGi?

**You:** I start from **business goals and KPIs** (Key Performance Indicators — the success metrics),
not features. Workshops, journey and persona mapping — a dealer doing a bulk reorder behaves nothing
like a DIY buyer searching one part — and I turn each ask into **acceptance criteria** with the product
owner. I prioritize with **MoSCoW** (Must / Should / Could / Won't-have prioritization), surface
assumptions early, and validate with a clickable flow or a thin spike before I commit architecture. My favorite
question in those rooms is "**what does success look like as a number?**"

**Interviewer:** *(probing)* And when they keep changing that ask mid-sprint?

**You:** I protect the sprint commitment. New asks go to the backlog and the PO re-prioritizes for next
sprint — unless it's a genuine emergency, and then we **swap something out transparently**, never
silent scope creep. The reason I can absorb change at all is that the architecture is modular —
components, headless content, composable services — so change is **cheap by design**.

**Interviewer:** You're an architect in a Scrum team — what do you actually do in the ceremonies?

**You:** I keep an **architecture runway one or two sprints ahead** so the team is never blocked. In
**refinement** I check feasibility and help split epics into sprint-able stories and size them; in
**planning** I commit *with* the team, not over them; in **reviews** I demo and gather feedback. I
deliberately own the **non-functional stories** — performance, security, search relevance — so they
don't get crowded out by features. And I capture decisions as lightweight **ADRs** (Architecture
Decision Records — a short written note of what we decided and why) so nobody re-litigates them later.

**Interviewer:** Estimates. A client pushes you to commit to a date you're not sure about. What do you
do?

**You:** I never give a single number on an unknown. I give a **three-point estimate** — optimistic,
likely, pessimistic — with the assumptions and the risky long-poles called out: PIM sync, search
relevance, multi-locale, performance. If there's real uncertainty I propose a short **discovery spike**
to convert unknowns into knowns, then commit. Under date pressure I make the **scope-time-quality
trade-off explicit**: "we can hit that date with this scope, and fast-follow the rest." Honest early
beats a missed date.

**Interviewer:** Our world is B2B and B2C and omnichannel. What changes between them, functionally?

**You:** **B2C** is anonymous-friendly, SEO and conversion-led, simple cart to checkout. **B2B** — the
dealer side — is **account-based**: contract pricing, entitlements, requisition and **approval
workflows**, bulk reorder, **punchout** (connecting the store directly into the buyer's procurement
software) over cXML or OCI (the two standard punchout protocols), and quote-to-order. **Omnichannel**
means one consistent catalog and content across web, mobile, the dealer
portal, and the call center, with unified inventory and things like buy-online-pickup-at-dealer.
Architecturally the commerce engine owns entitlements, AEM personalizes the content per segment, and
headless feeds the non-web channels.

**Interviewer:** A product owner insists on a feature you think is wrong. Real example.

**You:** On my current platform the PO (product owner) wanted **[a heavy custom search UI]**. I thought it added cost
without serving the real goal. So I separated the **problem from their proposed solution** — restated
the outcome they actually wanted, which was fewer dead-end searches — and brought **data**: the real
issue was **zero-result-rate**, not the UI. I offered a lighter option that hit the same KPI and laid
out the cost and risk of their version. We went with the lighter one, the KPI moved, and I documented it
as an ADR. I push back on the *how*; I rarely fight their *why*. Disagree, then commit.

**Interviewer:** How do you keep all this architecture tied to what the business actually cares about?

**You:** Every non-functional decision maps to a business metric. Search relevance and autocomplete →
**conversion** and lower zero-result-rate. Cache-hit ratio and Core Web Vitals → **bounce and SEO**.
Time to launch a locale → **speed-to-market**. Component reuse → **lower change cost**. I report
architecture health in business terms, not server terms — that's how I keep the room aligned.

**Interviewer:** Great. Anything you want to ask me?

**You:** Yes — is this engagement primarily B2B dealer/procurement or B2C? How mature is the Agile setup —
dedicated PO, fixed-scope or capacity model? And what's the top business pain driving the program —
speed-to-market, conversion, or consolidation?

---

## 🎯 Reusable rapid-fire (if either interviewer free-fires extra questions)
*Short, say-out-loud answers. Same platform underneath.*

- **Sling Models vs JSP?** POJOs, annotation injection, separates logic from HTL, unit-testable. Standard.
- **Editable vs static templates?** Editable = `/conf`, author-governed + policies; static = `/apps`, dev. Big org → editable.
- **Core Components — build from scratch?** No. Proxy (`sling:resourceSuperType`) + delegation. Build bespoke only when no core equivalent.
- **How does Sling resolve a request?** URL → resource (node) → resource type → script/servlet by selectors/extension/method.
- **AEMaaCS vs 6.5?** Adobe-managed, auto-scale, **immutable `/apps`**, Cloud Manager CI/CD, repoinit, Asset Compute, RDE, SCD.
- **Secure AEM?** Dispatcher allow-list, no CRXDE on prod, least-priv service users (no admin resolver), CSRF, secrets in Cloud Manager env.
- **Headless vs headful commerce?** Headful CIF for SEO PLP/PDP; headless Content Fragments + GraphQL for SPA/mobile/dealer portal.
- **Keep catalog and content in sync?** Don't duplicate — Commerce is SoT, AEM references by SKU, pull live via GraphQL.
- **HLD vs LLD?** HLD = context, boundaries, NFRs, topology (client-facing). LLD = class designs, endpoint contracts, mappings, sequences (dev-facing).
- **Caching tiers?** Browser → CDN → Dispatcher → AEM, plus app-cache for commerce/search. TTL by volatility; personalize at edge/client.
- **CI/CD for AEMaaCS?** Cloud Manager: git → Maven build → Sonar quality gate → security/perf → blue-green.
- **Mentoring as lead?** Review checklist, pattern library, pairing on hard tickets, Sonar gates, my PRs set the bar.

---

## 📖 GLOSSARY — every abbreviation in this file
**AEM** — Adobe Experience Manager (the CMS). **AEMaaCS** — AEM as a Cloud Service (Adobe-hosted AEM).
**ADR** — Architecture Decision Record. **APIM** — (Azure) API Management gateway. **BM25** —
Elasticsearch's default relevance-ranking algorithm. **CDN** — Content Delivery Network (edge cache,
here Fastly). **CIF** — Commerce Integration Framework (AEM↔commerce over GraphQL). **CRM** — Customer
Relationship Management system. **CSRF** — Cross-Site Request Forgery (an attack AEM has a framework to
prevent). **CWV** — Core Web Vitals (Google's page-speed/UX metrics). **DLQ** — Dead-Letter Queue
(holds failed messages for retry). **ERP** — Enterprise Resource Planning system (orders/inventory).
**GraphQL** — a query language/API style; client asks for exactly the fields it needs. **HLD/LLD** —
High-Level / Low-Level Design. **HTL** — HTML Template Language (Sightly; AEM's view templating,
logic-less). **ILM** — Index Lifecycle Management (Elastic; ages data hot→warm→cold). **JCR** — Java
Content Repository (AEM's content tree). **KPI** — Key Performance Indicator. **MSM** — Multi Site
Manager (AEM multi-country). **MoSCoW** — Must/Should/Could/Won't prioritization. **OAuth2 / JWT** —
token-based auth standards. **OSGi** — the modular Java runtime AEM is built on. **PIM** — Product
Information Management (system of record for product attributes). **PLP / PDP** — Product Listing Page /
Product Detail Page. **PO** — Product Owner. **p95** — 95th-percentile latency (slowest 5% of requests).
**QPS** — Queries Per Second. **RDE** — Rapid Development Environment (fast AEMaaCS dev sandbox).
**SCD** — Sling Content Distribution (AEMaaCS replication/invalidation). **SKU** — Stock-Keeping Unit
(the product ID). **Sling** — Apache Sling, AEM's request→resource→script framework. **SoT** — Source of
Truth. **SPA** — Single-Page Application (React/Angular front end). **TTL** — Time To Live (cache expiry).
**cXML / OCI** — the two standard B2B punchout protocols.

---

### Sources
- [Caching in AEM as a Cloud Service (Adobe)](https://experienceleague.adobe.com/en/docs/experience-manager-cloud-service/content/implementing/content-delivery/caching)
- [CIF storefront caching (Adobe)](https://experienceleague.adobe.com/docs/experience-manager-cloud-service/content/content-and-commerce/storefront/administering/caching.html?lang=en)
- [App Builder + API Mesh for ecommerce (Adobe)](https://business.adobe.com/blog/perspectives/using-app-builder-and-api-mesh-to-expand-your-ecommerce-functionalities)
- [AEM Technical Foundations (Adobe)](https://experienceleague.adobe.com/en/docs/experience-manager-cloud-service/content/implementing/developing/aem-technologies)
- [Caterpillar — Personalized eCommerce Experience](https://www.caterpillar.com/en/news/caterpillarNews/2025/personalized-ecommerce-experience.html)
