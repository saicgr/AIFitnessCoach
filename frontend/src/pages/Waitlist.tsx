import { Camera, Dumbbell, MessageSquareText, MailCheck, ShieldCheck, Sparkles } from 'lucide-react';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import WaitlistHero from '../components/ui/waitlist-hero';

// /waitlist is SSG-prerendered — everything below renders statically (no
// hidden entrance states), so the crawler snapshot carries the full copy.
const PILLARS = [
  { Icon: Camera, title: 'Snap a meal', sub: '2-second macros, no searching a database' },
  { Icon: Dumbbell, title: 'Smart workouts', sub: 'Built around your gym, your injuries, your week' },
  { Icon: MessageSquareText, title: 'AI coach', sub: '24/7 chat that remembers your last session' },
];

const TRUST = [
  { Icon: Sparkles, label: 'Built solo. Honest about what works.' },
  { Icon: MailCheck, label: 'One email at launch — that’s it.' },
  { Icon: ShieldCheck, label: 'No spam, no newsletters, unsubscribe anytime.' },
];

export default function Waitlist() {
  return (
    <div className="min-h-screen bg-[#050505] text-white selection:bg-volt-500/30 overflow-x-hidden">
      <MarketingNav />

      <WaitlistHero source="waitlist_page" />

      {/* Proof band under the fold */}
      <section className="relative px-6 py-16 sm:py-20 border-t border-white/5">
        <div className="max-w-[860px] mx-auto">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
            {PILLARS.map(({ Icon, title, sub }) => (
              <div
                key={title}
                className="rounded-2xl border border-white/10 bg-ink-900 p-5 text-center hover:border-volt-500/40 transition-colors"
              >
                <Icon className="w-6 h-6 mx-auto mb-3 text-volt-400" strokeWidth={1.75} aria-hidden />
                <div className="text-sm font-semibold text-white">{title}</div>
                <div className="text-xs text-white/45 mt-1 leading-relaxed">{sub}</div>
              </div>
            ))}
          </div>

          <div className="mt-12 flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-xs text-white/45">
            {TRUST.map(({ Icon, label }) => (
              <span key={label} className="flex items-center gap-2">
                <Icon className="w-3.5 h-3.5 text-volt-400" strokeWidth={2} aria-hidden />
                {label}
              </span>
            ))}
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
