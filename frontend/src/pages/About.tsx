import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

const stats = [
  { value: '500+', label: 'Exercises' },
  { value: '50K+', label: 'Workouts Generated' },
  { value: 'Multi-Agent', label: 'AI Coach' },
];

const differentiators = [
  {
    title: 'AI-First Approach',
    description:
      'Every feature is built around AI from the ground up — not bolted on as an afterthought. Your workouts, nutrition plans, and coaching are all powered by Google Gemini.',
  },
  {
    title: 'Learns Your Preferences',
    description:
      `Star your favorite exercises, avoid ones you dislike, and the AI remembers. Over time, ${BRANDING.appName} builds a deep understanding of what works for you.`,
  },
  {
    title: 'Adapts to How You Feel',
    description:
      "Tell the AI coach you're tired, sore, or feeling great — and your workout adjusts in real time. No rigid programs that ignore how your body feels today.",
  },
  {
    title: 'Tracks Everything',
    description:
      'Workouts, nutrition, hydration, body measurements, and progress photos — all in one place. Snap a photo of your meal and the AI logs it instantly.',
  },
];

export default function About() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          {/* Hero */}
          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Your AI-Powered Fitness Coach
          </h1>
          <p className="text-[17px] text-[var(--color-text-secondary)] leading-relaxed mb-16">
            Personalized training, nutrition tracking, and real-time coaching — all driven by AI that learns and adapts to you.
          </p>

          {/* Mission */}
          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Our Mission
              </h2>
              <p>
                We believe everyone deserves a personal trainer. {BRANDING.appName} uses AI to make expert fitness coaching accessible to all — regardless of budget, location, or experience level.
              </p>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-6 py-8 border-y border-[var(--color-border)]">
              {stats.map((stat) => (
                <div key={stat.label} className="text-center">
                  <p
                    className="text-[28px] sm:text-[36px] font-semibold text-emerald-400 mb-1"
                    style={{ fontFamily: 'var(--font-heading)' }}
                  >
                    {stat.value}
                  </p>
                  <p className="text-[13px] text-[var(--color-text-muted)]">{stat.label}</p>
                </div>
              ))}
            </div>

            {/* What Makes {BRANDING.appName} Different */}
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-6"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                What Makes {BRANDING.appName} Different
              </h2>
              <div className="space-y-6">
                {differentiators.map((item) => (
                  <div key={item.title}>
                    <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">
                      {item.title}
                    </h3>
                    <p>{item.description}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Closing */}
            <div className="pt-4">
              <p className="text-[17px] text-[var(--color-text)] font-medium">
                Built by fitness enthusiasts who got tired of generic workout apps.
              </p>
            </div>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
