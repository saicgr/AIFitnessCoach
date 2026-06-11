import { Link } from 'react-router-dom';

const ARTICLES = [
  {
    to: '/vs/google-health',
    kicker: 'Comparison',
    title: 'Zealova vs Google Health Coach',
    desc: 'Why a dedicated training engine beats a general wellness assistant.',
  },
  {
    to: '/vs/bevel',
    kicker: 'Comparison',
    title: 'Zealova vs Bevel',
    desc: 'Coaching that programs your workouts, not just reads your wearable.',
  },
  {
    to: '/best-ai-fitness-apps-2026',
    kicker: 'Roundup',
    title: 'Best AI Fitness Apps of 2026',
    desc: 'Every serious AI trainer, ranked honestly. Including where we lose.',
  },
  {
    to: '/blog',
    kicker: 'Blog',
    title: 'Research and deep dives',
    desc: 'Original data, technical explainers, and the occasional hot take.',
  },
];

export default function ComparisonTeaser() {
  return (
    <section className="border-t border-white/5 py-24 sm:py-28" aria-labelledby="compare-heading">
      <div className="mx-auto max-w-[1100px] px-6">
        <p className="condensed-kicker mb-4 text-xs text-volt-500">Do your homework</p>
        <h2 id="compare-heading" className="display-heading mb-12 text-4xl text-white sm:text-5xl">
          Compare us. We insist.
        </h2>

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {ARTICLES.map((a) => (
            <Link
              key={a.to}
              to={a.to}
              className="group flex flex-col rounded-2xl border border-white/10 bg-[#0e0c0a] p-6 transition-all hover:-translate-y-0.5 hover:border-volt-500/40"
            >
              <span className="condensed-kicker text-[10px] text-zinc-500">{a.kicker}</span>
              <span className="mt-2 text-base font-semibold leading-snug text-white transition-colors group-hover:text-volt-300">
                {a.title}
              </span>
              <span className="mt-2 text-sm leading-relaxed text-zinc-400">{a.desc}</span>
              <span className="mt-4 text-volt-500" aria-hidden="true">→</span>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
