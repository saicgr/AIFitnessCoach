// /free-tools/supplement-stack-analyzer
//
// Parses a user-pasted supplement list and produces a research-backed
// breakdown: evidence tier, optimal timing, optimal dose, citations.
// Identifies redundancies, missing high-value supplements, and poor
// timing patterns. All static data — no LLM.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type EvidenceTier = 'strong' | 'moderate' | 'weak' | 'unsupported';

interface SupplementProfile {
  key: string;
  name: string;
  // Matched against lowercased input lines.
  keywords: string[];
  evidence: EvidenceTier;
  timing: string;
  dose: string;
  notes: string;
  citation: { text: string; url: string };
}

const PROFILES: SupplementProfile[] = [
  {
    key: 'creatine',
    name: 'Creatine Monohydrate',
    keywords: ['creatine'],
    evidence: 'strong',
    timing: 'Anytime daily, consistency matters more than clock time.',
    dose: '3 to 5 g/day. Loading optional.',
    notes: 'The most-studied performance supplement. Improves strength, power, and lean mass.',
    citation: {
      text: 'Kreider RR et al. (2017). ISSN position stand: safety and efficacy of creatine. JISSN 14:18.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/28615996/',
    },
  },
  {
    key: 'whey',
    name: 'Whey Protein',
    keywords: ['whey', 'protein powder', 'whey protein'],
    evidence: 'strong',
    timing: 'Post-workout or any time you need to hit your daily protein target.',
    dose: '20 to 40 g per serving. Total daily protein 1.6 to 2.2 g/kg.',
    notes: 'A convenient protein source, not magic. Whole-food protein is equally effective per gram.',
    citation: {
      text: 'Morton RW et al. (2018). Systematic review and meta-analysis: protein supplementation on resistance training. Br J Sports Med 52:376-384.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/28698222/',
    },
  },
  {
    key: 'multivitamin',
    name: 'Multivitamin',
    keywords: ['multivitamin', 'multi-vitamin', 'multi vit'],
    evidence: 'weak',
    timing: 'With breakfast or lunch (fat-soluble vitamins absorb better with food).',
    dose: '1 serving/day per label.',
    notes: 'Insurance policy for nutrient gaps. Cannot replace a varied diet. Not shown to extend life or improve performance in healthy adults.',
    citation: {
      text: 'Kim J et al. (2018). Multivitamin/mineral supplements and cardiovascular disease prevention. Circulation 11:e004224.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/29991644/',
    },
  },
  {
    key: 'fish_oil',
    name: 'Fish Oil (Omega-3 EPA/DHA)',
    keywords: ['fish oil', 'omega', 'omega-3', 'omega 3', 'epa', 'dha'],
    evidence: 'moderate',
    timing: 'With a fat-containing meal for absorption.',
    dose: '1 to 2 g combined EPA+DHA per day.',
    notes: 'Cardiovascular and anti-inflammatory benefits. Look for products certified low in oxidation (IFOS, USP).',
    citation: {
      text: 'Hu Y et al. (2019). Marine omega-3 supplementation and cardiovascular disease: meta-analysis. J Am Heart Assoc 8:e013543.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/31567003/',
    },
  },
  {
    key: 'vitamin_d',
    name: 'Vitamin D3',
    keywords: ['vitamin d', 'vit d', 'd3', 'vitamin d3'],
    evidence: 'moderate',
    timing: 'With a fat-containing meal. Morning preferred (may interfere with sleep at night).',
    dose: '1,000 to 4,000 IU/day depending on sun exposure and blood levels.',
    notes: 'Most-deficient nutrient in indoor populations. Test 25(OH)D once if possible, target 30 to 50 ng/mL.',
    citation: {
      text: 'Holick MF et al. (2011). Endocrine Society Clinical Practice Guideline: vitamin D deficiency. JCEM 96(7):1911-30.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/21646368/',
    },
  },
  {
    key: 'magnesium',
    name: 'Magnesium',
    keywords: ['magnesium', 'mag glycinate', 'magnesium glycinate', 'magnesium citrate'],
    evidence: 'moderate',
    timing: 'Evening (may support sleep). Avoid magnesium oxide (poor absorption).',
    dose: '200 to 400 mg elemental magnesium. Glycinate or citrate form.',
    notes: 'Many adults are undersupplied. Supports muscle function and sleep quality. Threonate for cognition is overhyped.',
    citation: {
      text: 'Abbasi B et al. (2012). The effect of magnesium supplementation on primary insomnia in elderly. J Res Med Sci 17(12):1161-9.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/23853635/',
    },
  },
  {
    key: 'zinc',
    name: 'Zinc',
    keywords: ['zinc'],
    evidence: 'weak',
    timing: 'On an empty stomach for absorption, OR with food if it upsets stomach.',
    dose: '15 to 30 mg/day. Pair with 1 to 2 mg copper to prevent depletion at sustained doses.',
    notes: 'Useful only if deficient (vegetarians, heavy sweaters). Long-term high doses can suppress copper status.',
    citation: {
      text: 'Maares M, Haase H (2020). A guide to human zinc absorption: general overview and recent advances. Nutrients 12(3):762.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/32183116/',
    },
  },
  {
    key: 'caffeine',
    name: 'Caffeine',
    keywords: ['caffeine', 'coffee', 'pre-workout', 'pre workout', 'preworkout'],
    evidence: 'strong',
    timing: '30 to 45 min pre-workout. STOP at least 8 hours before bedtime.',
    dose: '3 to 6 mg/kg bodyweight pre-training. Cap daily intake at 400 mg.',
    notes: 'Improves strength, endurance, and power output. Tolerance builds; cycle off periodically.',
    citation: {
      text: 'Guest NS et al. (2021). ISSN position stand: caffeine and exercise performance. JISSN 18:1.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/33388079/',
    },
  },
  {
    key: 'citrulline',
    name: 'L-Citrulline (Malate)',
    keywords: ['citrulline', 'l-citrulline', 'citrulline malate'],
    evidence: 'moderate',
    timing: '30 to 60 min pre-workout.',
    dose: '6 to 8 g of citrulline malate (or 3 to 5 g pure L-citrulline).',
    notes: 'Improves blood flow and reduces perceived exertion. Better evidence than L-arginine.',
    citation: {
      text: 'Trexler ET et al. (2019). Acute effects of citrulline supplementation on high-intensity strength and power performance. Sports Med 49(5):707-718.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/30895562/',
    },
  },
  {
    key: 'beta_alanine',
    name: 'Beta-Alanine',
    keywords: ['beta-alanine', 'beta alanine'],
    evidence: 'moderate',
    timing: 'Anytime daily — chronic loading matters, not acute timing.',
    dose: '3.2 to 6.4 g/day split across multiple doses to limit paresthesia.',
    notes: 'Best for 1 to 4 minute high-intensity efforts. Negligible for pure strength or long endurance.',
    citation: {
      text: 'Trexler ET et al. (2015). ISSN position stand: beta-alanine. JISSN 12:30.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/26175657/',
    },
  },
  {
    key: 'ashwagandha',
    name: 'Ashwagandha',
    keywords: ['ashwagandha', 'ksm-66', 'ksm66'],
    evidence: 'weak',
    timing: 'Evening. May modestly support sleep and reduce cortisol.',
    dose: '300 to 600 mg of standardized extract (KSM-66 or Sensoril).',
    notes: 'Adaptogen with small but consistent effects on stress and perceived recovery. Not a substitute for sleep.',
    citation: {
      text: 'Lopresti AL et al. (2019). An investigation into the stress-relieving and pharmacological actions of an ashwagandha extract. Medicine 98(37):e17186.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/31517876/',
    },
  },
  {
    key: 'melatonin',
    name: 'Melatonin',
    keywords: ['melatonin'],
    evidence: 'moderate',
    timing: '30 to 60 min before target bedtime. Lower doses are typically more effective.',
    dose: '0.3 to 1 mg. Most OTC products are massively overdosed (3 to 10 mg).',
    notes: 'Best for circadian shift (jet lag, shift work). Not a sedative — does not "knock you out."',
    citation: {
      text: 'Auld F et al. (2017). Evidence for the efficacy of melatonin in the treatment of primary adult sleep disorders. Sleep Med Rev 34:10-22.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/28648359/',
    },
  },
  {
    key: 'electrolytes',
    name: 'Electrolytes (Na, K, Mg)',
    keywords: ['electrolytes', 'electrolyte', 'lmnt', 'liquid iv'],
    evidence: 'moderate',
    timing: 'Around training, especially long or hot sessions. Morning if low-carb / fasting.',
    dose: '500 to 1,500 mg sodium per session for sweat replacement.',
    notes: 'Sodium is the one most lifters underdo. Powders matter only if you sweat heavily or train >60 min.',
    citation: {
      text: 'McDermott BP et al. (2017). NATA position statement: fluid replacement for the physically active. J Athl Train 52(9):877-895.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/28985128/',
    },
  },
  {
    key: 'bcaa',
    name: 'BCAAs',
    keywords: ['bcaa', 'bcaas', 'branched chain'],
    evidence: 'unsupported',
    timing: 'Not recommended if total daily protein is adequate.',
    dose: 'N/A — redundant with any complete protein source.',
    notes: 'Marketing hype. Whole-protein sources contain all 9 essential amino acids in better ratios. BCAAs without the other EAAs do NOT meaningfully drive MPS.',
    citation: {
      text: 'Wolfe RR (2017). Branched-chain amino acids and muscle protein synthesis in humans: myth or reality? JISSN 14:30.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/28852372/',
    },
  },
  {
    key: 'glutamine',
    name: 'Glutamine',
    keywords: ['glutamine', 'l-glutamine'],
    evidence: 'unsupported',
    timing: 'N/A — no demonstrated benefit in healthy lifters.',
    dose: 'N/A',
    notes: 'Useful in burn/ICU patients. Negligible effect on hypertrophy, strength, or recovery in healthy training adults.',
    citation: {
      text: 'Gleeson M (2008). Dosing and efficacy of glutamine supplementation in human exercise and sport training. J Nutr 138:2045S-2049S.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/18806122/',
    },
  },
  {
    key: 'l_carnitine',
    name: 'L-Carnitine',
    keywords: ['carnitine', 'l-carnitine'],
    evidence: 'weak',
    timing: 'With a carb meal (insulin enhances muscle uptake).',
    dose: '2 to 3 g/day for 12+ weeks.',
    notes: 'Marginal effect on fat oxidation. Not a fat burner. Requires long loading period to elevate muscle levels.',
    citation: {
      text: 'Wall BT et al. (2011). Chronic oral ingestion of L-carnitine and carbohydrate increases muscle carnitine content. J Physiol 589(4):963-973.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/21224234/',
    },
  },
];

interface ParsedSupplement {
  raw: string;
  profile: SupplementProfile | null;
}

function parseStack(input: string): ParsedSupplement[] {
  const lines = input
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.length > 0);
  return lines.map((line) => {
    const lower = line.toLowerCase();
    // Prefer longer keyword matches first to avoid creatine matching "creatinine" etc.
    const ordered = [...PROFILES].sort(
      (a, b) =>
        Math.max(...b.keywords.map((k) => k.length)) -
        Math.max(...a.keywords.map((k) => k.length)),
    );
    for (const p of ordered) {
      if (p.keywords.some((kw) => lower.includes(kw))) {
        return { raw: line, profile: p };
      }
    }
    return { raw: line, profile: null };
  });
}

const EVIDENCE_COLOR: Record<EvidenceTier, { bg: string; text: string; label: string }> = {
  strong: { bg: 'bg-emerald-500/20 border-emerald-500/40', text: 'text-emerald-400', label: 'Strong evidence' },
  moderate: { bg: 'bg-amber-500/20 border-amber-500/40', text: 'text-amber-400', label: 'Moderate evidence' },
  weak: { bg: 'bg-zinc-700/40 border-zinc-600/40', text: 'text-zinc-300', label: 'Weak evidence' },
  unsupported: { bg: 'bg-rose-500/15 border-rose-500/30', text: 'text-rose-400', label: 'Not supported' },
};

export default function SupplementStackAnalyzer() {
  const [input, setInput] = useState<string>(
    'Creatine 5g\nWhey protein 30g\nFish oil 2g\nMultivitamin\nCaffeine 200mg',
  );
  const [submitted, setSubmitted] = useState<boolean>(false);

  const parsed = useMemo(() => (submitted ? parseStack(input) : []), [input, submitted]);

  // ─── Analysis: keep / drop / consider adding ───
  const analysis = useMemo(() => {
    const identified = parsed.filter((p) => p.profile !== null).map((p) => p.profile!);
    const keys = new Set(identified.map((p) => p.key));
    const keep = identified.filter((p) => p.evidence === 'strong' || p.evidence === 'moderate');
    const drop = identified.filter((p) => p.evidence === 'unsupported');
    const considerAdd: SupplementProfile[] = [];

    // Always recommend creatine if missing
    if (!keys.has('creatine')) considerAdd.push(PROFILES.find((p) => p.key === 'creatine')!);
    // Vitamin D if no D
    if (!keys.has('vitamin_d')) considerAdd.push(PROFILES.find((p) => p.key === 'vitamin_d')!);
    // Fish oil if no omega
    if (!keys.has('fish_oil')) considerAdd.push(PROFILES.find((p) => p.key === 'fish_oil')!);

    // Redundancy: BCAAs with whey
    const redundancies: string[] = [];
    if (keys.has('bcaa') && keys.has('whey')) {
      redundancies.push(
        'BCAAs are redundant when you already take whey protein — whey contains all 9 EAAs in better ratios.',
      );
    }
    if (keys.has('glutamine')) {
      redundancies.push(
        'Glutamine shows no meaningful benefit for healthy training adults. Save the cost.',
      );
    }

    // Timing issues
    const timingFlags: string[] = [];
    if (keys.has('caffeine')) {
      timingFlags.push(
        'Caffeine after 2 PM can measurably reduce deep sleep. Cut off 8 hours before bedtime.',
      );
    }
    if (keys.has('vitamin_d') && !keys.has('fish_oil')) {
      timingFlags.push(
        'Vitamin D is fat-soluble. Take with a fat-containing meal for best absorption.',
      );
    }

    return { keep, drop, considerAdd, redundancies, timingFlags, identified };
  }, [parsed]);

  return (
    <CalculatorShell
      slug="supplement-stack-analyzer"
      title="Supplement Stack Analyzer"
      metaDescription="Paste your supplement list and get an evidence-tier breakdown per item: optimal timing, optimal dose, and citations to peer-reviewed research. Flags redundancies, poor timing, and missing high-value supplements. Free, no sign-up."
      intro="Drop your current stack. We map each supplement to research-grade tiers (strong, moderate, weak, unsupported), flag the timing and dose research actually supports, and surface what you might be missing."
      emailCaptureResult={
        submitted
          ? {
              count: analysis.identified.length,
              keep: analysis.keep.length,
              drop: analysis.drop.length,
              redundancies: analysis.redundancies.length,
            }
          : undefined
      }
      installPrimary="Track your supplement timing in Zealova."
      installSecondary="Zealova reminds you to take each supplement at the optimal time relative to your training, and flags interactions with your meds. Free."
      faqs={[
        {
          q: 'How do you decide the evidence tier?',
          a: 'Strong = multiple meta-analyses or position stands from ISSN/NSCA/ACSM (creatine, caffeine, protein). Moderate = consistent RCT support but smaller effect sizes (citrulline, fish oil, vitamin D, beta-alanine). Weak = mixed or limited evidence (zinc unless deficient, ashwagandha). Not supported = strong evidence of no benefit in healthy lifters (BCAAs when protein is adequate, glutamine).',
        },
        {
          q: 'Why is creatine your default recommendation?',
          a: 'It is the single most-studied performance supplement, with >500 peer-reviewed studies showing consistent strength, power, and lean mass benefits at 3 to 5 g/day. Cheap, safe at recommended doses, and benefits virtually every lifter regardless of goal.',
        },
        {
          q: 'Why is BCAAs "unsupported" if every gym sells it?',
          a: 'Marketing momentum exceeds the research. BCAAs alone are not enough to maximally stimulate muscle protein synthesis — you need the full essential amino acid spectrum (Wolfe 2017). If you already drink whey or eat protein, BCAAs add nothing measurable.',
        },
        {
          q: 'Are dosages personalized?',
          a: 'Recommendations are population-average optimal ranges from published research. They are not medical advice. If you take medications, are pregnant, or have a clinical condition, talk to your doctor — particularly about magnesium, melatonin, vitamin D, and zinc.',
        },
        {
          q: 'Why is timing flagged for caffeine?',
          a: 'Caffeine half-life is 5 to 6 hours. A 200 mg dose at 2 PM still leaves ~100 mg active at 8 PM and ~50 mg at 2 AM. Multiple sleep studies show measurable reductions in deep sleep with caffeine within 6 hours of bedtime, even when subjects don\'t notice it subjectively.',
        },
        {
          q: 'Will this catch every supplement?',
          a: 'It identifies the ~15 most common research-backed supplements lifters and general-pop users take. Niche items (collagen, tongkat ali, methylene blue) will show as unidentified. The output focuses on the supplements where research evidence is unambiguous.',
        },
        {
          q: 'Should I trust this over my doctor?',
          a: 'No. This is research-summarization, not medical advice. The citations link to PubMed so you can read the source studies directly. Always tell your physician what you take — particularly with prescription medications, since some supplements affect anticoagulants, lithium, statins, and thyroid meds.',
        },
      ]}
    >
      {/* Input */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7 space-y-4">
        <label className="block">
          <span className="block text-sm font-medium text-zinc-300 mb-2">
            Paste your current supplements (one per line)
          </span>
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            rows={6}
            placeholder={'Creatine 5g\nWhey protein 30g\nFish oil 2g\nMultivitamin\nCaffeine 200mg'}
            className="w-full px-3 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-sm font-mono leading-relaxed focus:outline-none focus:ring-2 focus:ring-emerald-500"
          />
        </label>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs text-zinc-500">
            Examples: Creatine, Whey, Multivitamin, Fish oil, Vitamin D, Magnesium, Caffeine, L-Citrulline, Beta-Alanine, Ashwagandha, Melatonin, Electrolytes, BCAAs.
          </p>
          <button
            type="button"
            onClick={() => setSubmitted(true)}
            disabled={input.trim().length === 0}
            className="px-5 py-2.5 rounded-lg bg-emerald-500 text-zinc-900 text-sm font-semibold hover:bg-emerald-400 transition disabled:opacity-40 disabled:cursor-not-allowed"
          >
            Analyze stack
          </button>
        </div>
      </section>

      {/* Results */}
      {submitted && (
        <>
          {/* Summary */}
          <section className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <SummaryCard
              label="Keep"
              count={analysis.keep.length}
              names={analysis.keep.map((p) => p.name)}
              tone="emerald"
            />
            <SummaryCard
              label="Drop"
              count={analysis.drop.length}
              names={analysis.drop.map((p) => p.name)}
              tone="rose"
            />
            <SummaryCard
              label="Consider adding"
              count={analysis.considerAdd.length}
              names={analysis.considerAdd.map((p) => p.name)}
              tone="amber"
            />
          </section>

          {/* Flags */}
          {(analysis.redundancies.length > 0 || analysis.timingFlags.length > 0) && (
            <section className="space-y-2">
              {analysis.redundancies.map((r, i) => (
                <div
                  key={`r${i}`}
                  className="rounded-xl border border-rose-500/30 bg-rose-500/5 px-4 py-3"
                >
                  <p className="text-xs font-semibold text-rose-400 uppercase tracking-wider mb-1">
                    Redundancy
                  </p>
                  <p className="text-sm text-zinc-200">{r}</p>
                </div>
              ))}
              {analysis.timingFlags.map((t, i) => (
                <div
                  key={`t${i}`}
                  className="rounded-xl border border-amber-500/30 bg-amber-500/5 px-4 py-3"
                >
                  <p className="text-xs font-semibold text-amber-400 uppercase tracking-wider mb-1">
                    Timing note
                  </p>
                  <p className="text-sm text-zinc-200">{t}</p>
                </div>
              ))}
            </section>
          )}

          {/* Per-supplement breakdown */}
          <section>
            <h2 className="text-lg font-bold text-white mb-3">Your stack, line by line</h2>
            <div className="space-y-3">
              {parsed.map((p, i) => (
                <SupplementCard key={i} parsed={p} />
              ))}
            </div>
          </section>
        </>
      )}

      <MethodologyFooter
        citations={[
          {
            text: 'Kreider RR et al. (2017). ISSN position stand: safety and efficacy of creatine. JISSN 14:18.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/28615996/',
          },
          {
            text: 'Wolfe RR (2017). Branched-chain amino acids and muscle protein synthesis in humans: myth or reality? JISSN 14:30.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/28852372/',
          },
          {
            text: 'Guest NS et al. (2021). ISSN position stand: caffeine and exercise performance. JISSN 18:1.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/33388079/',
          },
          {
            text: 'Examine.com — independent supplement research summaries.',
            url: 'https://examine.com/',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}

function SummaryCard({
  label,
  count,
  names,
  tone,
}: {
  label: string;
  count: number;
  names: string[];
  tone: 'emerald' | 'rose' | 'amber';
}) {
  const map = {
    emerald: 'border-emerald-500/30 bg-emerald-500/5 text-emerald-400',
    rose: 'border-rose-500/30 bg-rose-500/5 text-rose-400',
    amber: 'border-amber-500/30 bg-amber-500/5 text-amber-400',
  };
  return (
    <div className={`rounded-xl border ${map[tone]} px-4 py-4`}>
      <p className="text-[10px] font-semibold uppercase tracking-wider opacity-80">
        {label}
      </p>
      <p className="text-3xl font-bold mt-1 tabular-nums">{count}</p>
      {names.length > 0 && (
        <p className="text-xs text-zinc-300 mt-2 leading-relaxed">{names.join(', ')}</p>
      )}
    </div>
  );
}

function SupplementCard({ parsed }: { parsed: ParsedSupplement }) {
  if (!parsed.profile) {
    return (
      <div className="rounded-xl border border-zinc-800 bg-zinc-900 px-4 py-3">
        <p className="text-sm text-zinc-300 font-mono">{parsed.raw}</p>
        <p className="text-xs text-zinc-500 mt-1">
          Not recognized. If this is a real supplement, the research evidence may be too thin for us to summarize confidently.
        </p>
      </div>
    );
  }
  const p = parsed.profile;
  const tier = EVIDENCE_COLOR[p.evidence];
  return (
    <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-4 sm:p-5">
      <div className="flex items-start justify-between gap-3 flex-wrap mb-2">
        <div>
          <p className="text-xs text-zinc-500 font-mono mb-0.5">{parsed.raw}</p>
          <h3 className="text-base font-bold text-white">{p.name}</h3>
        </div>
        <span
          className={`inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold border ${tier.bg} ${tier.text}`}
        >
          {tier.label}
        </span>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2 mt-3 text-sm">
        <div>
          <p className="text-[10px] uppercase tracking-wider text-zinc-500 font-semibold">
            Timing
          </p>
          <p className="text-zinc-200">{p.timing}</p>
        </div>
        <div>
          <p className="text-[10px] uppercase tracking-wider text-zinc-500 font-semibold">
            Dose
          </p>
          <p className="text-zinc-200">{p.dose}</p>
        </div>
      </div>
      <p className="text-sm text-zinc-400 mt-3 leading-relaxed">{p.notes}</p>
      <p className="text-xs text-zinc-500 mt-3 pt-3 border-t border-zinc-800">
        Source:{' '}
        <a
          href={p.citation.url}
          target="_blank"
          rel="noopener noreferrer"
          className="text-emerald-400 hover:text-emerald-300 underline"
        >
          {p.citation.text}
        </a>
      </p>
    </div>
  );
}
