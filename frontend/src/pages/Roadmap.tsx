import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

type Status = 'shipping' | 'next' | 'later';

interface RoadmapItem {
  title: string;
  description: string;
  status: Status;
}

interface RoadmapSection {
  title: string;
  subtitle: string;
  status: Status;
  items: RoadmapItem[];
}

const sections: RoadmapSection[] = [
  {
    title: 'Now — Shipping in the next few weeks',
    subtitle: 'These are queued up and going out as soon as builds are signed.',
    status: 'shipping',
    items: [
      {
        title: 'Public Android launch',
        description:
          'Zealova is now approved for Google Play production. Public release is rolling out shortly.',
        status: 'shipping',
      },
      {
        title: 'iOS launch',
        description: 'App Store submission immediately following Android.',
        status: 'shipping',
      },
      {
        title: 'Recipe Import',
        description:
          'Paste any recipe link or screenshot — Zealova extracts the ingredients, scales portions, and auto-logs it to your meals with calories and macros.',
        status: 'shipping',
      },
      {
        title: 'Sharper food recognition',
        description:
          'Better calorie and macro estimates on mixed plates, with an expanding international food database.',
        status: 'shipping',
      },
    ],
  },
  {
    title: 'Next — In active development',
    subtitle: 'Started or planned for the following sprint.',
    status: 'next',
    items: [
      {
        title: 'Form-check from video',
        description:
          'Upload a squat, bench, or deadlift clip. Get rep-by-rep coaching feedback grounded in NSCA / NASM cues.',
        status: 'next',
      },
      {
        title: 'Food Preferences',
        description:
          'Meal pattern, allergens, cooking skill, budget, and dietary restrictions — used to personalize AI meal suggestions and recipe generation.',
        status: 'next',
      },
      {
        title: '"What Should I Eat?" widget',
        description:
          'One tap on your home or lock screen for an AI meal idea with calories and macros, plus a one-tap "Log it" button.',
        status: 'next',
      },
      {
        title: 'Bluetooth heart-rate hardware',
        description:
          'Pair BLE chest straps and HR monitors for live in-workout BPM, zones, and post-workout recovery insights.',
        status: 'next',
      },
      {
        title: 'Recipe Discovery Feed',
        description:
          'Browse, like, and remix recipes shared by the community. Ships alongside the Social tab.',
        status: 'next',
      },
    ],
  },
  {
    title: 'Later — On the horizon',
    subtitle:
      'Bigger pieces being designed and validated. Order may shift based on user feedback.',
    status: 'later',
    items: [
      {
        title: 'Home-screen widget suite',
        description:
          'Toggleable home-screen widgets: Fitness Score, Daily Stats, Weight Tracker, Calories Summary, Macro Rings, Quick Start, Mini Calendar.',
        status: 'later',
      },
      {
        title: 'Progress analytics',
        description:
          'Strength + volume charts over time, muscle heatmap of recently trained groups, week-over-week exercise variation.',
        status: 'later',
      },
      {
        title: 'Body & measurement tracking',
        description:
          'Quick body measurements, before/after photo compare, and daily activity summary from your wearable.',
        status: 'later',
      },
      {
        title: 'Holistic Weekly Plan',
        description:
          'A single weekly view that blends workouts, nutrition, hydration, and fasting — plus rest-day recovery tips.',
        status: 'later',
      },
      {
        title: 'Mood-aware workouts',
        description:
          'Quick mood check-in that adapts the day\'s session — lighter on low-energy days, harder when you\'re ready.',
        status: 'later',
      },
      {
        title: 'Journey + ROI',
        description:
          'Visualize your fitness journey over months and years: total workouts, time invested, milestones, and momentum.',
        status: 'later',
      },
      {
        title: 'Social & challenges',
        description:
          'Active challenges, leaderboards, and friend activity — opt-in, never the default.',
        status: 'later',
      },
      {
        title: 'Coach companion app',
        description:
          'A separate trainer-side product (same backend) where coaches can build and assign programs to clients.',
        status: 'later',
      },
    ],
  },
];

const statusStyles: Record<Status, { label: string; bg: string; text: string; ring: string }> = {
  shipping: {
    label: 'Now',
    bg: 'rgba(34, 197, 94, 0.12)',
    text: 'rgb(34, 197, 94)',
    ring: 'rgba(34, 197, 94, 0.35)',
  },
  next: {
    label: 'Next',
    bg: 'rgba(56, 189, 248, 0.12)',
    text: 'rgb(56, 189, 248)',
    ring: 'rgba(56, 189, 248, 0.35)',
  },
  later: {
    label: 'Later',
    bg: 'rgba(168, 85, 247, 0.12)',
    text: 'rgb(168, 85, 247)',
    ring: 'rgba(168, 85, 247, 0.35)',
  },
};

function StatusBadge({ status }: { status: Status }) {
  const style = statusStyles[status];
  return (
    <span
      className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-medium uppercase tracking-wider"
      style={{
        backgroundColor: style.bg,
        color: style.text,
        border: `1px solid ${style.ring}`,
      }}
    >
      {style.label}
    </span>
  );
}

export default function Roadmap() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[820px] mx-auto">
          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Roadmap
          </h1>
          <p className="text-[15px] text-[var(--color-text-secondary)] leading-relaxed mb-4">
            What's coming next to {BRANDING.appName}. This page is the source of truth — if it isn't here, it isn't being worked on yet.
          </p>
          <p className="text-[13px] text-[var(--color-text-muted)] leading-relaxed mb-12">
            Last updated April 2026 · Order is intentional but flexible based on user feedback.
          </p>

          <div className="space-y-14">
            {sections.map((section) => (
              <div key={section.title}>
                <div className="flex items-center gap-3 mb-2">
                  <h2
                    className="text-[22px] sm:text-[26px] font-semibold text-[var(--color-text)]"
                    style={{ fontFamily: 'var(--font-heading)' }}
                  >
                    {section.title}
                  </h2>
                  <StatusBadge status={section.status} />
                </div>
                <p className="text-[14px] text-[var(--color-text-muted)] leading-relaxed mb-6">
                  {section.subtitle}
                </p>

                <div className="space-y-3">
                  {section.items.map((item) => (
                    <div
                      key={item.title}
                      className="border border-[var(--color-border)] rounded-xl p-5 hover:border-[var(--color-text-muted)] transition-colors"
                    >
                      <div className="flex items-start justify-between gap-4 mb-2">
                        <h3 className="text-[16px] font-semibold text-[var(--color-text)]">
                          {item.title}
                        </h3>
                        <StatusBadge status={item.status} />
                      </div>
                      <p className="text-[14px] text-[var(--color-text-secondary)] leading-relaxed">
                        {item.description}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>

          <div className="mt-16 p-6 border border-[var(--color-border)] rounded-xl">
            <h3
              className="text-[18px] font-semibold mb-2"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Have a request?
            </h3>
            <p className="text-[14px] text-[var(--color-text-secondary)] leading-relaxed">
              Email <a href="mailto:hello@fitwiz.us" className="underline">hello@fitwiz.us</a> or open the in-app chat with the AI coach and tag it as feedback. Every request is read.
            </p>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
