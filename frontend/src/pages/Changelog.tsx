import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

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
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Changelog
          </h1>
          <p className="text-[15px] text-[var(--color-text-secondary)] leading-relaxed mb-12">
            What's new in FitWiz. We ship updates regularly to make your fitness journey better.
          </p>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            {changelog.map((entry) => (
              <div key={entry.version} className="border-b border-[var(--color-border)] pb-8 last:border-b-0">
                <div className="flex items-baseline gap-3 mb-4">
                  <h2
                    className="text-[24px] font-semibold text-[var(--color-text)]"
                    style={{ fontFamily: 'var(--font-heading)' }}
                  >
                    {entry.version}
                  </h2>
                  <span className="text-[13px] text-[var(--color-text-muted)]">{entry.date}</span>
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
