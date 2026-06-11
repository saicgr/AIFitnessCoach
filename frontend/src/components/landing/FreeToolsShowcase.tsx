import { Link } from 'react-router-dom';
import { FREE_TOOL_COUNT } from '../../lib/toolStats';

// Curated, hardcoded marquee tools (deliberately NOT importing
// calcRegistry.ts — that 26KB data module stays out of the homepage chunk).
const TOOLS = [
  { slug: 'tdee-calculator', name: 'TDEE Calculator', desc: 'Your real daily calorie burn' },
  { slug: '1rm-calculator', name: '1RM Calculator', desc: 'Estimate your one-rep max' },
  { slug: 'macro-calculator', name: 'Macro Calculator', desc: 'Protein, carbs, fat targets' },
  { slug: 'strength-level', name: 'Strength Level', desc: 'How strong are you, really?' },
  { slug: 'body-fat-calculator', name: 'Body Fat %', desc: 'Jackson-Pollock estimate' },
  { slug: 'ai-workout-generator', name: 'AI Workout Generator', desc: 'A free plan in 30 seconds' },
  { slug: 'ai-roast-my-routine', name: 'Roast My Routine', desc: 'AI critiques your split' },
  { slug: 'plate-loader', name: 'Plate Loader', desc: 'What to put on the bar' },
  { slug: 'should-i-train-today', name: 'Should I Train Today?', desc: 'Recovery readiness check' },
  { slug: 'year-in-fitness-wrapped', name: 'Fitness Wrapped', desc: 'Your year, Spotify-style' },
];

/**
 * The GEO asset: 60+ free tools, surfaced with real internal links so
 * crawlers (and LLMs) see the breadth from the homepage itself.
 */
export default function FreeToolsShowcase() {
  return (
    <section className="relative py-24 sm:py-32" aria-labelledby="free-tools-heading">
      <div className="mx-auto max-w-[1100px] px-6">
        <div className="mb-12 flex flex-wrap items-end justify-between gap-6">
          <div>
            <p className="condensed-kicker mb-4 text-xs text-volt-500">No signup. No paywall.</p>
            <h2 id="free-tools-heading" className="display-heading text-4xl text-white sm:text-5xl md:text-6xl">
              {FREE_TOOL_COUNT} free tools.<br />Zero excuses.
            </h2>
          </div>
          <p className="max-w-sm text-sm leading-relaxed text-zinc-400">
            Calculators, timers, AI analyzers, and share cards that other apps
            charge for. Free in your browser, forever.
          </p>
        </div>

        <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-5">
          {TOOLS.map((tool) => (
            <li key={tool.slug}>
              <Link
                to={`/free-tools/${tool.slug}`}
                className="group flex h-full flex-col rounded-2xl border border-white/10 bg-[#0e0c0a] p-5 transition-all hover:-translate-y-0.5 hover:border-volt-500/40"
              >
                <span className="text-sm font-semibold text-white group-hover:text-volt-300 transition-colors">
                  {tool.name}
                </span>
                <span className="mt-1.5 text-xs leading-relaxed text-zinc-500">{tool.desc}</span>
                <span className="mt-auto pt-3 text-volt-500 opacity-0 transition-opacity group-hover:opacity-100" aria-hidden="true">
                  →
                </span>
              </Link>
            </li>
          ))}
        </ul>

        <div className="mt-8 text-center">
          <Link
            to="/free-tools"
            className="inline-flex items-center gap-2 rounded-full border border-volt-500/40 px-7 py-3.5 text-sm font-medium text-volt-400 transition-colors hover:bg-volt-500/10 hover:text-volt-300"
          >
            Browse all {FREE_TOOL_COUNT} free tools
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12l-7.5 7.5M21 12H3" />
            </svg>
          </Link>
        </div>
      </div>
    </section>
  );
}
