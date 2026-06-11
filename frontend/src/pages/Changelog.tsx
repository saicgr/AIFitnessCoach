import { useEffect } from 'react';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

interface ChangelogEntry {
  version: string;
  date: string;
  changes: string[];
}

const changelog: ChangelogEntry[] = [
  {
    version: 'v0.74',
    date: 'March 2026',
    changes: [
      'Fitness Wrapped: Monthly recap with AI personality card',
      'Exercise preferences: Star favorites, avoid exercises, queue for next workout',
      'Improved nutrition dashboard with macro tracking',
      'AI form check via video in chat',
    ],
  },
  {
    version: 'v0.73',
    date: 'February 2026',
    changes: [
      'Multi-agent AI coach (nutrition, workout, injury, hydration specialists)',
      'Barcode scanner for food nutrition',
      'GitHub-style workout heatmap in stats',
      'Mood-based workout adaptation',
    ],
  },
  {
    version: 'v0.72',
    date: 'January 2026',
    changes: [
      'Complete app redesign with dark mode',
      'AI food photo analysis',
      'Workout superset detection',
      'Progressive overload tracking',
    ],
  },
];

export default function Changelog() {
  useEffect(() => {
    document.title = 'Changelog | Zealova';
    const setMeta = (key: string, value: string, isProperty = false) => {
      const attr = isProperty ? 'property' : 'name';
      let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
      if (!el) {
        el = document.createElement('meta');
        el.setAttribute(attr, key);
        document.head.appendChild(el);
      }
      el.content = value;
    };
    setMeta(
      'description',
      'See what is new in Zealova. Release notes and feature updates for the AI fitness coach.'
    );
  }, []);

  return (
    <div className="min-h-screen bg-[#050505] text-zinc-100">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <p className="condensed-kicker text-volt-500 text-[13px] mb-3">Release Notes</p>
          <h1 className="display-heading text-4xl sm:text-5xl text-white mb-4">
            Changelog
          </h1>
          <p className="text-[15px] text-zinc-300 leading-relaxed mb-12">
            What's new in {BRANDING.appName}. We ship updates regularly to make your fitness journey better.
          </p>

          <div className="space-y-8 text-[15px] text-zinc-300 leading-relaxed">
            {changelog.map((entry) => (
              <div key={entry.version} className="border-b border-white/10 pb-8 last:border-b-0">
                <div className="flex items-baseline gap-3 mb-4 flex-wrap">
                  <h2 className="inline-flex items-center rounded-full border border-volt-500/30 bg-volt-500/10 px-3 py-1 text-[15px] font-semibold text-volt-400">
                    {entry.version}
                  </h2>
                  <span className="text-[13px] text-zinc-500">{entry.date}</span>
                </div>
                <ul className="list-disc pl-6 space-y-2">
                  {entry.changes.map((change, i) => (
                    <li key={i}>{change}</li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
