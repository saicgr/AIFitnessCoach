import { useEffect } from 'react';
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
  useEffect(() => {
    document.title = 'About | Zealova';
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
      'Learn about Zealova, the AI-powered fitness coach that personalizes workouts, nutrition, and coaching to you.'
    );
  }, []);

  return (
    <div className="min-h-screen bg-[#050505] text-zinc-100">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          {/* Hero */}
          <p className="condensed-kicker text-volt-500 text-[13px] mb-3">About {BRANDING.appName}</p>
          <h1 className="display-heading text-4xl sm:text-5xl text-white mb-4">
            Your AI-Powered Fitness Coach
          </h1>
          <p className="text-[17px] text-zinc-300 leading-relaxed mb-16">
            Personalized training, nutrition tracking, and real-time coaching — all driven by AI that learns and adapts to you.
          </p>

          {/* Mission */}
          <div className="space-y-8 text-[15px] text-zinc-300 leading-relaxed">
            <div>
              <h2 className="text-[24px] font-semibold text-white mb-4">
                Our Mission
              </h2>
              <p>
                We believe everyone deserves a personal trainer. {BRANDING.appName} uses AI to make expert fitness coaching accessible to all — regardless of budget, location, or experience level.
              </p>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-6 py-8 border-y border-white/10">
              {stats.map((stat) => (
                <div key={stat.label} className="text-center">
                  <p className="display-heading text-[28px] sm:text-[36px] text-volt-400 mb-1">
                    {stat.value}
                  </p>
                  <p className="text-[13px] text-zinc-500">{stat.label}</p>
                </div>
              ))}
            </div>

            {/* What Makes {BRANDING.appName} Different */}
            <div>
              <h2 className="text-[24px] font-semibold text-white mb-6">
                What Makes {BRANDING.appName} Different
              </h2>
              <div className="space-y-6">
                {differentiators.map((item) => (
                  <div key={item.title}>
                    <h3 className="text-[17px] font-semibold text-white mb-2">
                      {item.title}
                    </h3>
                    <p>{item.description}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Closing */}
            <div className="pt-4">
              <p className="text-[17px] text-white font-medium">
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
