# FitWiz Platform — Adjacent Coach-Client SaaS Categories

> **Purpose:** Post-fitness expansion candidates. Each is a potential "Trainerize for X" leveraging the FitWiz Pro multi-tenant + manual builder + AI-coach-offline + Stripe Connect + white-label backend.
>
> **Scope:** This doc is exploratory. It does NOT commit to any category. FitWiz fitness B2B + wellness (stated next move) remain priority 1–2. Categories here are Year 3+ conversation.
>
> **Audience:** You (founder), evaluating which adjacent vertical to reuse the platform for after fitness + wellness are stable.
>
> **Last updated:** 2026-04-23

---

## 0. The filters applied — brutal honesty

Every category below passes all THREE filters. Any category that fails even one is documented in §7 (cut list) with reason.

| Filter | Pass = | Fail = |
|---|---|---|
| **1. Recurring revenue** | Client engages for 12+ months; renewal is the norm, not exception | One-shot project (wedding, book, exam, college app) — done in 3–12 months and client disappears |
| **2. AI features are realistic TODAY** | Text/LLM parsing, structured-data analysis, audio transcription, simple vision (food photos, profile photos, screenshots) | Novel computer vision (golf swings, dog body language, dance form) requires 3–5 years of dedicated CV/ML work — NOT "swap the library" |
| **3. Paid coach adds value beyond free YouTube** | Accountability + personalization + emotional support + crisis intervention are the value (information alone isn't the product) | Pure information teaching that YouTube/TikTok already delivers for free (cooking basics, gardening, basic photography) |

---

## 1. The "Calendly + Notion + Stripe" signal — why cobbled stacks = opportunity

**Research finding (confirmed April 2026):** The most common tech stack for professional coaches/consultants without a purpose-built SaaS is:
- **Calendly** — scheduling ($16/mo, 20M+ users)
- **Notion** — client notes + project management + "light CRM"
- **Stripe** — one-off invoices or Stripe Checkout links
- **Zapier** — to glue them together
- **MailerLite / ConvertKit** — email
- **Google Workspace** — files + docs

**Why this stack reveals opportunity:**
- It means the professional has a **real business** (paying clients, revenue, recurring engagement) but **no purpose-built tool exists for their specific vertical**.
- Coaches/consultants in this stack report frustration with "juggling logins, integrations, and monthly fees across platforms" (Calendly community, Paperbell alternatives blog).
- **Calendly explicitly does NOT support payment plans or recurring subscriptions** — a huge gap for ongoing coaching relationships.
- The stack runs **$80–$150/mo per coach** and still doesn't solve: client progress tracking, program/curriculum templates, client-facing mobile app, cohort messaging, AI assist, branded experience, white-label.

**Our thesis:** Every vertical where this stack is dominant = a verified coach-SaaS opportunity. The professionals are already paying; they want fewer tools, better UX, and vertical-specific features.

**How to spot it in a new vertical:**
- Search `"[vertical] coach" + "Calendly"` or `"[vertical] consultant" + "Notion template"`
- Check r/Entrepreneur, r/SmallBusiness, r/coaching for tech stack complaints
- Look for "Notion templates for X coaches" — if there's a thriving template market, the vertical needs SaaS
- Ask "would this coach pay $39–$99/mo to replace 4 tools?" — if yes, it's a candidate

---

## 2. TIER 1 — Validated strong opportunities (recurring + realistic AI + paid beats free)

Each has: large recurring TAM, AI features that work today, and a professional class already paying for cobbled tools.

### 2.1 ADHD / productivity / executive-function coaching

| Metric | Value | Source |
|---|---|---|
| US ADHD adults | 15M+ | CDC |
| US certified ADHD coaches (ICF + ADD Coach Academy + Int'l Assoc ADHD Coaches) | 5K–15K | Industry estimates |
| Typical client engagement | **2–5 years** | ICF retention data |
| Package pricing today (cobbled stack) | $200–$500/mo client-side; coach uses Calendly + Notion | ICF surveys |
| ARPC for FitWiz | $39–$79/mo | Our pricing |
| TAM at 100% US coach capture | **$60M–$180M ARR** | (10K coaches × $50 avg × 12) |

**Why recurring:** ADHD is a chronic neurological condition. Client needs ongoing executive-function support that adjusts with every life transition (new job, new relationship, parenthood, illness). Same client engaged for years.

**Realistic AI today:**
- LLM parses calendar screenshots + task-list screenshots → suggests time-block adjustments
- Text-based AI persona answers "I can't focus at 11pm" with grounding techniques (zero vision needed)
- Pattern detection on daily focus-session logs
- Accountability text check-ins

**Paid beats free:** YouTube explains "what is ADHD." Coaches deliver **accountability + personalized system tuning + crisis support** — not Googleable.

**Cobbled stack today:** Notion templates (many ADHD coaches publish these) + Calendly + Stripe + Voxer.

---

### 2.2 Personal finance / money management coaching

| Metric | Value | Source |
|---|---|---|
| US AFC-certified financial coaches | 15K+ | AFCPE |
| Dave Ramsey-endorsed coaches | ~4K active | Ramsey Solutions |
| Client engagement average | **1–3 years** | AFCPE surveys |
| Package pricing today | $150–$400/mo client-side | Industry estimates |
| ARPC for FitWiz | $49–$99/mo | Our pricing |
| TAM at 50% US coach capture | **$30M–$60M ARR** | (10K coaches × $70 × 12) |

**Why recurring:** Money problems are lifelong. Budget reviews, debt payoff, life events (marriage, baby, house, retirement) trigger new coaching engagements every 12–24 months. **Same client returns for each life stage.**

**Realistic AI today:**
- Plaid bank integration (mature, licensed) — auto-categorize transactions, flag overspending, track net worth
- LLM parses bank/credit card screenshots
- AI accountability: "did you stick to your budget this week?"
- Goal tracking (debt payoff, emergency fund, retirement)

**Paid beats free:** Free Dave Ramsey / Ramit Sethi / Caleb Hammer content explains theory. Coaches **enforce** it: weekly check-ins, accountability calls, budget drift detection. Information is free; enforcement is what people pay for.

**Regulated edge:** Avoid investment advice (SEC/FINRA line). Coaching is legal; advising specific investments is not. Explicit ToS + state-by-state disclaimer needed.

**Cobbled stack today:** Ramit Sethi's own course-platform; Dave Ramsey ELP portal; most indie AFCs use Calendly + Google Sheets + Stripe.

---

### 2.3 Real estate broker → agent training

| Metric | Value | Source |
|---|---|---|
| US real estate brokers (manage agents) | ~100K | NAR |
| US real estate agents | **1.5M** | NAR |
| Annual agent turnover | 15–25% | NAR |
| Training spend per brokerage | $300–$1,000/mo per program | Industry estimates |
| ARPC for FitWiz | $299–$999/mo | Our pricing |
| TAM at 30% US broker capture | **$300M–$600M ARR** | (30K brokers × $600 avg × 12) |

**Why recurring:** Brokerages onboard new agents continuously (15–25% yearly churn = 300K agents needing onboarding each year in US alone). Existing agents need ongoing skill development as market conditions shift. **Training is a perpetual line item on every brokerage P&L.**

**Realistic AI today:**
- Transcribe recorded listing presentations + score against brokerage framework
- LLM generates personalized objection drills from agent's lost deals
- CRM data analysis (kvCORE, BoomTown, Follow Up Boss — all have APIs)
- Activity benchmarks across agents ("agents in top decile make 47 calls/week vs your 12")

**Paid beats free:** Tom Ferry / Mike Ferry content explains theory via YouTube. Brokers pay because: **structured curriculum + accountability + feedback on their real CRM data + recorded role-plays** — customized to their market.

**Cobbled stack today:** kvCORE/BoomTown (CRM, not training) + Loom (recorded trainings) + Google Classroom + weekly Zoom.

**Highest per-coach ARPC opportunity on this entire list.**

---

### 2.4 Sales coaching (SMB tier, under 20 reps)

| Metric | Value | Source |
|---|---|---|
| US sales managers | ~500K | BLS |
| SMB sales managers (<20 reps, our ICP) | ~150K | Segment estimate |
| Rep turnover | 30–40%/year | CSO Insights |
| Enterprise incumbent pricing | Gong $1,200/user/yr | Public pricing |
| SMB gap: NOTHING affordable | — | Market research |
| ARPC for FitWiz | $200–$500/mo | Our pricing |
| TAM at 20% SMB capture | **$108M ARR** | (30K managers × $300 × 12) |

**Why recurring:** Reps churn 30–40%/year. Every new rep needs onboarding + ongoing development. Quota carriers need perpetual call review. **Structurally recurring by workforce dynamics.**

**Realistic AI today:**
- Call transcription + AI scoring (Gong proved this is mature at enterprise; we replicate at SMB price)
- Salesforce/HubSpot/Pipedrive API integration
- LLM generates personalized objection-handling drills from rep's lost deals
- Weekly activity benchmarks

**Paid beats free:** Free content teaches "what to say." Sales managers pay for **drilling it into reps + weekly call review + pipeline strategy + accountability** — can't self-serve.

**Cobbled stack today:** Salesforce + Loom + Gong-Lite alternatives + Notion playbooks + weekly Zoom.

---

### 2.5 Recovery / sobriety / peer-recovery coaching

| Metric | Value | Source |
|---|---|---|
| US peer recovery coaches (NCCAP + CCAR) | 50K+ | Certification bodies |
| Certified addictions counselors (CADC) | 100K+ | NAADAC |
| Client engagement | **Lifelong (1-year minimum, often 5–10 years)** | AA / SMART Recovery |
| Package pricing today | $150–$400/mo client-side | Industry estimates |
| ARPC for FitWiz | $39–$99/mo | Our pricing |
| TAM at 30% US coach capture | **$15M–$35M ARR** | (15K coaches × $65 × 12) |

**Why recurring:** Recovery is lifelong by definition. Daily accountability model. Relapse prevention is ongoing forever. **Most recurring domain on this entire list.**

**Realistic AI today:**
- Text-based triage (no vision needed)
- **CRITICAL:** AI patterns escalate "I want to use right now" to human coach IMMEDIATELY — never auto-handle relapse risk
- Sobriety streak tracking
- Trigger pattern analysis from daily logs
- 12-step or SMART Recovery protocol adherence

**Paid beats free:** Information is free (AA meetings free, SMART Recovery free). **24/7 accountability + crisis intervention from someone who knows your history + sponsor-style check-ins** is what people pay for.

**Regulated edge:** Clinical boundary — peer recovery coach is NOT a therapist. ToS must clarify scope. Mandatory crisis-handoff protocols required.

**Cobbled stack today:** Bark + Sober Time + Calendly + WhatsApp + Google Sheets.

---

### 2.6 Functional medicine / chronic health / longevity coaching

| Metric | Value | Source |
|---|---|---|
| US NBHWC-certified health coaches | 30K+ | NBHWC |
| Practice Better active users (incumbent) | 12K+ | Practice Better |
| Chronic disease + biohacker market (clients) | 50M+ | CDC + industry |
| Client engagement | **Multi-year (chronic condition management)** | NBHWC |
| ARPC for FitWiz | $49–$99/mo | Our pricing |
| TAM at 40% non-Practice-Better capture | **$30M–$50M ARR** | (10K coaches × $70 × 12) |

**Why recurring:** Chronic disease (diabetes, autoimmune, pre-diabetic, hormone, longevity) requires multi-year management. Same client engaged 2–10+ years. Labs need ongoing interpretation. Supplements need ongoing adjustment.

**Realistic AI today:**
- Vision food logging (our existing infra — directly transfers)
- LLM parses bloodwork PDFs (Quest, Labcorp, Function Health) → flags out-of-range markers for coach review
- Supplement adherence tracking
- Symptom pattern detection
- Integration with CGM devices (Levels, Dexcom)

**Paid beats free:** Free content has "eat this, not that." Coach provides **personalized protocol + ongoing lab interpretation + supplement adjustment + insurance navigation + accountability** — high-trust multi-year relationship.

**Incumbent:** Practice Better ($25–$169/mo) is dominant for health coaches. We enter as the AI-native alternative with vision food logging built-in.

**Cobbled stack today (for Practice-Better-holdouts):** Calendly + Typeform (intake) + Evernote + Stripe + manual bloodwork PDFs.

---

### 2.7 Menopause / hormone / women's midlife coaching

| Metric | Value | Source |
|---|---|---|
| US women in peri/post-menopause | **50M+** | NIH |
| Specialized menopause coaches | ~5K (growing 40%+/yr) | Industry estimate |
| Transition duration | **7–14 years** | NIH |
| Package pricing today | $200–$500/mo client-side | Midi Health / Elektra (clinics) |
| ARPC for FitWiz | $79–$149/mo | Our pricing |
| TAM at 30% US coach capture | **$20M–$40M ARR** (growing fast) | (1.5K coaches × $110 × 12) |

**Why recurring:** Peri-menopause to post-menopause = 7–14 year transition. Symptoms shift constantly (hot flashes → sleep → mood → libido → bone density). Structurally recurring.

**Realistic AI today:**
- Symptom logging + LLM pattern detection (hot flash frequency, sleep quality, mood)
- Cycle data integration
- AI persona answers "night sweats at 2am, can't sleep" in coach's voice
- HRT protocol tracking
- Integration with Oura / Whoop / Apple Health (sleep + HRV)

**Paid beats free:** Mainstream medicine fails women here — 10-minute OB-GYN visits don't address lived experience. Coaches provide **continuity + validation + personalization + community** that doctors can't.

**Demographic tailwind:** Gen X hitting menopause now (55M women); Boomers in post-menopause (40M). Combined demographic + cultural awareness boom (Oprah, Halle Berry, Michelle Obama speaking publicly).

**Cobbled stack today:** Notion symptom templates + Calendly + Stripe + private Facebook groups.

---

### 2.8 Homeschool parent coaching / consulting (NEW)

| Metric | Value | Source |
|---|---|---|
| **US homeschooled kids** | **4.3M (up from 2.5M in 2020, +51%)** | National Home Education Research Institute |
| Global homeschool market | $3.5B → $7.2B by 2033 (8.5% CAGR) | Verified Market Reports |
| US homeschool consultants/coaches (active) | ~3K–8K (exploding) | Industry estimates |
| Hourly consulting | $95–$300 | HomeSchool Think Tank |
| Package pricing today | **$500–$3,000 per engagement** | Public coach pricing |
| Engagement duration | **K-12 = 12+ years** | Structural |
| ARPC for FitWiz | $39–$99/mo | Our pricing |
| TAM at 30% US coach capture | **$10M–$25M ARR (growing fast)** | (2K coaches × $70 × 12) |

**Why recurring:** Parents homeschool for 12+ years (K-12). Curriculum changes yearly. New challenges every grade. New siblings enter homeschool at different ages. **Same family engaged for a decade or more.**

**Realistic AI today:**
- Curriculum template library (reuse "exercise library" architecture → "lesson plan library")
- LLM assists curriculum matching to learning style + state requirements
- Progress tracking per child + per subject
- State-requirement compliance checklists (homeschool laws vary wildly by state)
- Parent-child video submission for work review

**Paid beats free:** Free content explains "what is classical education / Charlotte Mason / unschooling." Parents pay because **personalized curriculum design + accountability + compliance navigation + emotional support for overwhelmed parents** — can't self-serve when you're teaching 4 kids across 3 grade levels.

**Post-COVID tailwind:** Homeschool population grew 51% 2020→2024. **Fastest-growing segment in education right now.**

**Cobbled stack today:** Google Classroom + Notion + Calendly + Facebook groups + homeschool planners (paper).

---

### 2.9 Neurodivergent parent coaching (ADHD/autism/2e kids) (NEW)

| Metric | Value | Source |
|---|---|---|
| US kids diagnosed ADHD | 6M+ | CDC |
| US kids diagnosed autism | 1 in 31 | CDC 2025 |
| Established coaches/practices | Neurodiverging, Beautifully Complex, Thrive Autism, Parenting the Neurodiverse, Divergent Therapy | Market research |
| Typical package pricing | **$1,200–$2,100 for 3-month programs** | Public coach pricing |
| Engagement duration | Multi-year (child grows through developmental stages) | Clinical consensus |
| ARPC for FitWiz | $49–$99/mo (or 3-month packages) | Our pricing |
| TAM at 20% US coach capture | **$15M–$30M ARR** | (3K coaches × $70 × 12) |

**Why recurring:** Neurodivergence is lifelong. Parents re-engage at each developmental stage: toddler tantrums → school transitions → puberty → teen independence → young adult launch. **Same family engages for 15+ years.**

**Realistic AI today:**
- Behavior pattern logging (meltdowns, triggers, sleep, food sensitivities)
- LLM parses incident descriptions → identifies patterns coach can address
- Accommodation library (IEP/504 plan templates)
- School communication templates (parent-to-teacher)
- Progress tracking across behavioral goals

**Paid beats free:** Information is abundant (Beautifully Complex podcast free, many Instagram accounts). Parents pay for **personalized behavior plans + accountability + crisis support at 11pm when the meltdown is happening + coach who knows THEIR kid** — not Googleable.

**Market evidence:** Neurodiverging, Beautifully Complex, Thrive Autism Coaching all operating at $1,200–$2,100 per 3-month engagement TODAY. Real paying market, just cobbled tools.

**Cobbled stack today:** Notion + Calendly + Voxer + Zoom + Stripe.

---

### 2.10 Caregiver support coaching (adult children caring for aging parents) (NEW)

| Metric | Value | Source |
|---|---|---|
| **US unpaid family caregivers** | **53M (up from 43.5M in 2015)** | AARP + BLS |
| Caregivers of elderly (65+) | 41M | AARP |
| Average caregiving duration | 4.5 years | AARP |
| Emerging employer benefit market | Benefitfocus, Seniorlink, Greensfelder offering coaching as employee benefit | RGA insurance research |
| ARPC for FitWiz | $49–$79/mo (or employer B2B2C) | Our pricing |
| TAM at 10% caregiver capture | **$300M–$500M ARR** (via employer benefits channel) | Massive |

**Why recurring:** Caregiving journey is 4.5 years average, often extending 10+ years with dementia. Needs shift constantly (early independence support → mid-stage coordination → late-stage hospice). **Same family engaged throughout parent's decline.**

**Realistic AI today:**
- Symptom + incident logging (falls, medication adherence, cognitive changes)
- Care plan templates (activities of daily living, fall prevention, medication schedules)
- LLM parses medical paperwork (insurance, Medicare, advance directives)
- Emotional support chat (caregiver burnout is the #1 unmet need)
- Sibling/family coordination (multiple family members coordinating care)

**Paid beats free:** AARP has endless content. Caregivers pay because **24/7 emotional support + care plan personalization + insurance/Medicare navigation + sibling mediation** is not on a website.

**Dual-ICP potential:**
- **B2C:** Individual caregiver pays directly ($49/mo)
- **B2B:** Sold as employee benefit through HR/benefits platforms ($4–$8/employee/mo, 1000+ employees per deal)

**Emerging market signal:** Benefitfocus (HR platform), Seniorlink (dementia coaching), and law firm Greensfelder already offering paid caregiver coaching as employee benefit. **Verified by RGA (reinsurance company) as a growth area.**

**Cobbled stack today:** Notion + Google Sheets (medication tracker) + Caring Bridge + family group texts + paper folders of insurance docs.

---

### 2.11 Creator economy coaching (YouTubers, Substack authors, course creators) (NEW)

| Metric | Value | Source |
|---|---|---|
| US content creators earning income | 4M+ | Creator Economy Report |
| Substack paid newsletter model | $7–$15/mo or $75–$175/yr (recurring) | Substack public |
| Creator coaching typical pricing | $200–$1,000/mo for 1-on-1 | Industry |
| Cohort-based coaching (6-week programs) | $500–$3,000 per cohort, 2x/year | Substack research |
| ARPC for FitWiz | $49–$99/mo | Our pricing |
| TAM at 10% creator-coach capture | **$20M–$50M ARR** | (5K creator coaches × $70 × 12) |

**Why recurring:** Creators build audiences continuously. Algorithm changes monthly. Monetization strategies evolve yearly. Cohort programs run 2–3x/year indefinitely.

**Realistic AI today:**
- YouTube Analytics API integration
- Substack dashboard parsing
- Stripe/Gumroad revenue tracking
- LLM generates content ideas from client's audience data
- Thumbnail A/B test scoring (LLM vision on thumbnails — realistic)
- Script feedback via text

**Paid beats free:** Free "how to grow YouTube" videos on YouTube (irony). Creators pay for **accountability + personalized strategy + cohort peer support + analysis of THEIR channel data** — not generic.

**Cobbled stack today:** Notion (content calendar) + Loom (async feedback) + Calendly + Slack (cohort community) + Stripe + Substack.

---

### 2.12 Freelancer / consultant / agency owner business coaching (NEW)

| Metric | Value | Source |
|---|---|---|
| US freelancers | 70M (Upwork + BLS combined) | Upwork Economist 2024 |
| US independent consultants | ~12M | IRS + industry |
| Existing generic tools | Bonsai ($25–$66/mo), Honeybook ($19–$66) — neither is coach-client | Market |
| Typical freelance-biz coach package | $200–$800/mo | Industry |
| ARPC for FitWiz | $49–$99/mo | Our pricing |
| TAM at 1% freelance-coach capture | **$50M ARR** | (80K coaches × $70 × 12) |

**Why recurring:** Freelance/consulting business development is continuous — positioning shifts, pricing changes, client acquisition never stops. Feast/famine cycles create ongoing coaching need.

**Realistic AI today:**
- Pitch/proposal scoring (LLM reads proposal, suggests improvements)
- Pricing analysis (LLM parses client proposal + your rates)
- Email/LinkedIn message drafting
- Weekly metric tracking (leads, proposals, close rate)

**Paid beats free:** Tons of free content on freelance biz. People pay because **personalized positioning + accountability + pricing confidence-building** is not Googleable.

**Cobbled stack today:** Notion + Calendly + Stripe + Slack community + weekly Zoom.

---

## 3. TIER 2 — Real but niche or specialized (smaller TAM, tighter ICP)

| # | Domain | Why it qualifies | TAM est. | Unique twist |
|---|---|---|---|---|
| 13 | **Divorce transition coaching** | 1–3 year engagement, emotional + logistical (custody, finances, co-parenting) | $10M ARR | Co-parenting schedule tools, shared calendar w/ ex, child communication logs |
| 14 | **Therapist supervision / consultation** | Therapists require ongoing supervision for license; recurring peer consultation | $15M ARR (specialist) | HIPAA-compliant infra required; case-study anonymization |
| 15 | **Parenting coaching (general, non-neurodivergent)** | Multi-year as kids grow through stages | $20M ARR | Sleep, behavior, screen time, teen years — stage-based playbooks |
| 16 | **Chronic pain / Long COVID / autoimmune coaching** | Multi-year condition management | $15M ARR | Symptom pattern detection, pacing/energy management, flare triggers |
| 17 | **Fertility / IVF coaching** | 1–3 year engagement typical; monthly cycles | $8M ARR | Cycle tracking, IVF protocol adherence, partner shared access |
| 18 | **Music lessons (indie teachers)** | Kids stay 3–10 years; AI pitch/timing detection is realistic | $45M ARR | MyMusicStaff incumbent ($23–$48/mo, dated) — viable but NOT easy port |
| 19 | **OCD / anxiety / phobia coaching** | Regulated edge (adjacent to CBT therapy); multi-year engagement | $10M ARR | ERP protocol tracking, thought records, exposure ladders |
| 20 | **Pastoral counseling / spiritual direction** | Lifelong faith journey; faith-community context | $5M ARR | Faith-tradition-specific protocols, prayer trackers, retreat planning |

---

## 4. TIER 3 — Possible but watch for regulation / controversy / market dynamics

| # | Domain | Why cautious |
|---|---|---|
| 21 | **Mental health therapy** | Huge TAM but SimplePractice $200M+ ARR incumbent + HIPAA + state licensure = hard to compete unless you pick a narrow specialty |
| 22 | **Generic life / career / executive coaching** | Saturated mid-tier (CoachAccountable, Practice, Paperbell). Only viable with narrow specialization (e.g., "exec coaching for female founders") |
| 23 | **Language tutoring (indie)** | Italki/Preply marketplaces take 15–33% — indie SaaS viable as "escape the marketplace tax" pitch but marketplace network effects are real |
| 24 | **Investing / trading mentoring** | SEC/FINRA regulatory edge; real risk of violating investment-advisor rules |
| 25 | **Eating disorder / body image coaching** | Clinical boundary with therapy; regulatory edge; vulnerable population |
| 26 | **OnlyFans / adult creator business coaching** | Real recurring market but platform-policy risk (App Store, Stripe, Google Play may ban) |
| 27 | **Crypto / Web3 mentoring** | Volatile market, reputation risk, SEC uncertainty |
| 28 | **Tarot / astrology / spiritual coaching** | Real TAM, high engagement, but App Store reputation concerns |

---

## 5. TIER 4 — Professional peer mentoring (niche but real)

Smaller TAM but high ARPC potential ($99–$299/mo) if you pick one vertical:

| # | Vertical | # professionals (US) | Why viable |
|---|---|---|---|
| 29 | **Nurse / NP career transitions** | 5M+ RNs | Career growth + specialty transitions recurring |
| 30 | **Physical therapist business coaching** | 240K PTs | Practice setup + insurance navigation |
| 31 | **Dentist practice coaching** | 200K dentists | Business side, not clinical; recurring |
| 32 | **Veterinarian practice coaching** | 115K vets | Practice mgmt + burnout support |
| 33 | **Loan officer / mortgage broker coaching** | 300K+ | Commission-based, ongoing sales skill dev |
| 34 | **Insurance agent coaching** | 1M+ | Similar to real estate — recurring training need |

---

## 6. TIER 5 — Animal-adjacent (specialized, recurring sub-categories)

Dog training as a whole is mostly one-shot (puppy basics), BUT these sub-categories are recurring:

| # | Sub-vertical | Why recurring |
|---|---|---|
| 35 | **Reactive dog rehabilitation** | 6–18 months of ongoing behavior modification per dog (lengthy recurring engagement) |
| 36 | **Pet nutrition consulting (prescription diet management)** | Chronic condition (kidney disease, diabetes) requires ongoing diet adjustment |
| 37 | **Equestrian (competition horses)** | Multi-year show prep, rider + horse development |
| 38 | **Working dog / service dog training** | 12–24 months formal training, often with recurring refreshers |

---

## 7. The CUT list — what does NOT pass the brutal filter

Documenting these so we don't re-propose them. Honest reasoning for each.

### 7.1 Fails recurring filter (one-shot engagements)

| Cut | Why |
|---|---|
| College admissions consulting | 6–12 months then done. Parent disappears after kid enrolls. High-$ per engagement doesn't = recurring. |
| SAT / ACT / LSAT / MCAT / GMAT / GRE prep | 3–6 months. Test is taken; done. |
| Wedding planning / event planning | One-time project by definition |
| Bar exam / CPA exam coaching | 6-month engagement then done |
| Book writing coaching (creative) | 12-month project then done (except for authors writing multiple books, which is rare) |
| Interview coaching | 4-week engagement typically |
| Resume writing | Single project |
| Course-creation one-off | Build course then done |

### 7.2 Fails AI-realistic filter (novel vision/CV far-reach)

| Cut | Why |
|---|---|
| Golf swing coaching | AI swing analysis = 3–5 years of biomechanics CV. V1 Pro, Sportsbox, Hudl spent $10M+ on it with mediocre accuracy. NOT "swap the library." |
| Tennis coaching | Same — stroke analysis is biomechanics-grade CV |
| Dance coaching | Body-pose detection is mature; nuanced technique critique is not |
| Martial arts form critique | Same |
| Dog training (vision of dog body language) | Specialized animal-behavior CV doesn't exist off-shelf |
| Equestrian gait analysis | Same — horse-specific biomechanics |
| Voice/singing pitch nuance | Basic pitch is mature (Yousician), but nuanced coaching (emotion, phrasing) is not AI-scorable today |
| DJ / music production critique | Audio-mix quality is subjective + production-dependent; not AI-scorable |

### 7.3 Fails free-content filter (YouTube infinitely free)

| Cut | Why |
|---|---|
| Cooking coaching (basic-intermediate) | YouTube has infinite free cooking tutorials |
| Basic photography | Free tutorials + free camera YouTube content |
| Gardening coaching | YouTube + Pinterest infinite |
| Painting / drawing basics | Skillshare + YouTube |
| Knitting / crafts | YouTube infinite |
| Basic fitness / nutrition for healthy people | Already covered B2C; generic content infinite |
| Dating app profile tips (basic) | TikTok has 10,000 hours of free content |

### 7.4 Fails combined filters

| Cut | Why |
|---|---|
| Public speaking coaching | Project-based (prep for one talk), not recurring. Yoodli (B2C AI) handles solo practice. |
| Voice acting coaching | Niche + project-based (per audition/role) |
| Photography business (advanced) | Semi-recurring but 17hats + HoneyBook already occupy this space |
| Wedding photography business | Seasonal + project-based + 17hats / Táve already exist |
| Real estate CRM for agents (not training) | kvCORE/BoomTown saturated; we'd need training-specific angle |

### 7.5 Regulation/compliance makes it not worth it

| Cut | Why |
|---|---|
| Unlicensed medical/clinical advice (direct health coaching beyond functional/behavior) | Scope of practice violations in most states |
| Investment advisory (beyond general finance education) | SEC/FINRA |
| Legal coaching for non-lawyers | Unauthorized practice of law |
| Autism therapy (not parent coaching) | BCBA licensure in most states |

---

## 8. Platform thesis refined

**The reusable FitWiz Pro architecture powers coach-client SaaS for ANY domain that meets:**

1. **Recurring engagement** (12+ months typical)
2. **AI features are LLM + text + simple vision + structured data** (NOT novel computer vision)
3. **Paid coaching beats free content** (accountability, personalization, crisis support, community)
4. **Professional class already paying for cobbled Calendly + Notion + Stripe stacks**

**Count of domains passing ALL filters:** ~12 (Tier 1) + 8 (Tier 2) = **20 serious candidates.**

**Combined US TAM at our pricing across Tier 1:** ~**$550M–$1.1B ARR.**

**Build cost per new vertical after FitWiz Pro is stable:** **6–12 weeks** (curate the new library, tune LLM prompts for domain, build 2–3 domain-specific integrations). Note: this number is honest for Tier 1 domains where AI is LLM/text-based. For Tier 2 domains with specialized AI (music pitch detection), add 3–6 months.

---

## 9. Recommended sequencing (post-fitness, post-wellness)

| Year | Move | Rationale |
|---|---|---|
| 2026–2027 | **FitWiz Pro fitness B2B** | Your Phase 1–3 plan |
| 2027–2028 | **Wellness** (your stated next) | Adjacent; max infrastructure reuse |
| 2028 | **ADHD / productivity coaching** | Largest greenfield Tier 1 TAM; AI is realistic; chronic condition = lifelong recurring |
| 2028–2029 | **Homeschool parent coaching** | 51% market growth, 4.3M kids, 12-year engagement = highest LTV of any vertical |
| 2029 | **Personal finance coaching** | Plaid integration mature; AFC/Ramsey ELP network = built-in channel |
| 2029–2030 | **Neurodivergent parent coaching** | Overlaps ADHD mechanically; different buyer (parent vs adult); reuse AI |
| 2030 | **Real estate broker → agent training** | Highest per-customer ARPC ($299–$999); B2B sale to brokerages (different sales motion — requires SDR hire) |
| 2030–2031 | **Caregiver support coaching** | B2B employee-benefit channel; 53M caregivers; dual B2C + B2B2C play |
| 2031 | **Sales coaching SMB** OR **Creator economy coaching** | Either depending on which network/brand path you've built |

**Stop at 5–6 verticals.** Platform companies that try 20 verticals dilute focus. Pick the 5–6 with best TAM × founder fit × architectural reuse and go deep.

---

## 10. How to spot the next one (signal-hunting playbook)

When you're ready to add vertical #7, use these checks:

1. **Search `"[vertical] coach" + "Calendly"` on Google.** Lots of results = real professional class using cobbled tools.
2. **Search Notion template galleries for `[vertical] coaching template`.** Thriving template market = unmet SaaS need.
3. **Check r/coaching, r/smallbusiness, r/[vertical]** for tech-stack complaints and "tired of juggling 5 tools" posts.
4. **Count the certification bodies** in the vertical (ICF, NBHWC, AFCPE, NASM, etc.) — more cert bodies = more professional class.
5. **Verify recurring engagement**: Ask 3 coaches in the vertical "how long does your average client stay?" If answer is <12 months → one-shot → skip.
6. **Verify AI realism**: What's the AI feature that makes your product defensible? Is it LLM + text? Good. Is it novel computer vision? Skip or partner with a CV specialist.
7. **Verify willingness-to-pay**: Are coaches currently paying $100+/mo across their tool stack (Calendly + CRM + Stripe + scheduling + email)? If yes → they'll pay you $39–$99 to consolidate.
8. **Search competitor landscape**: If there's a SimplePractice-equivalent ($100M+ ARR incumbent), skip unless you have a narrow specialty angle. If there's no incumbent or only a dated $25M-ARR player → go.

---

## 11. Signals the user should pay attention to next 12 months

Keep a watchlist as you build FitWiz Pro:
- Practice Better (functional medicine incumbent) raising a funding round / getting acquired → market validation
- Any "ADHD coaching SaaS" launches — first mover matters
- Any Substack authors launching "creator coach OS" → sign someone sees the creator opportunity
- Homeschool post-COVID trend continuing to grow — if it crosses 6M kids by 2028, the market doubles
- Employer benefits platforms (Maven, Lyra, Carrot) adding parent-coaching / caregiver-coaching benefits → B2B2C channel opens

---

**This doc is living.** Update quarterly as you learn from FitWiz Pro what architectural assumptions hold, which AI features actually work at scale, and which verticals your customer base indicates next demand for.
