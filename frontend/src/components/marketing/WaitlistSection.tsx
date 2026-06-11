import WaitlistForm from './WaitlistForm';

interface WaitlistSectionProps {
  source: string;
}

// Static section (no entrance animations): /waitlist is SSG-prerendered and
// hidden initial states get baked into the SEO snapshot. CSS hover
// transitions only.
export default function WaitlistSection({ source }: WaitlistSectionProps) {
  return (
    <section className="relative overflow-hidden py-16 sm:py-20 px-6">
      {/* Static layered volt-tinted radial gradients (no animation, SSG safe) */}
      <div
        aria-hidden
        className="absolute inset-0 overflow-hidden pointer-events-none"
        style={{
          background:
            'radial-gradient(40% 30% at 20% 20%, rgba(255,122,0,0.07), transparent), radial-gradient(36% 28% at 82% 72%, rgba(255,122,0,0.05), transparent), radial-gradient(28% 22% at 55% 38%, rgba(255,122,0,0.04), transparent)',
        }}
      />

      <div className="relative max-w-[860px] mx-auto">
        {/* Eyebrow */}
        <div className="text-center mb-6">
          <span className="condensed-kicker inline-flex items-center gap-2 rounded-full border border-volt-500/30 bg-volt-500/5 px-4 py-2 text-xs text-volt-400">
            <span className="relative inline-flex w-2 h-2 rounded-full bg-volt-400" />
            Launching Soon
          </span>
        </div>

        {/* Big headline */}
        <h2 className="display-heading text-center text-4xl sm:text-6xl md:text-7xl text-white">
          Be first when{' '}
          <span className="text-volt-500">
            iOS drops.
          </span>
        </h2>

        {/* Subhead */}
        <p className="mt-4 text-center text-base sm:text-lg text-white/55 max-w-[560px] mx-auto leading-relaxed">
          Android link goes out the moment Google approves. iOS launches right
          after, and the waitlist gets it first.
        </p>

        {/* The waitlist form, centerpiece */}
        <div className="mt-8">
          <WaitlistForm source={source} />
        </div>

        {/* Visual pillars (3 promise tiles) */}
        <div className="mt-12 grid grid-cols-3 gap-3 sm:gap-4 max-w-[720px] mx-auto">
          {[
            { emoji: '📸', title: 'Snap a meal', sub: '2-second macros' },
            { emoji: '💪', title: 'Smart workouts', sub: 'Built around your gym' },
            { emoji: '🤖', title: 'AI coach', sub: '24/7 chat, no DMs' },
          ].map((tile) => (
            <div
              key={tile.title}
              className="rounded-2xl border border-white/10 bg-[#0D0D0D] p-4 sm:p-5 text-center hover:border-volt-500/40 transition-colors"
            >
              <div className="text-2xl sm:text-3xl mb-2">{tile.emoji}</div>
              <div className="text-xs sm:text-sm font-semibold text-white">{tile.title}</div>
              <div className="text-[10px] sm:text-xs text-white/45 mt-1">{tile.sub}</div>
            </div>
          ))}
        </div>

        {/* Trust strip */}
        <div className="mt-12 flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-xs text-white/45">
          <span className="flex items-center gap-2">
            <span className="text-volt-400">●</span>
            Built solo. Honest about what works.
          </span>
          <span className="flex items-center gap-2">
            <span className="text-volt-400">●</span>
            One email at launch.
          </span>
          <span className="flex items-center gap-2">
            <span className="text-volt-400">●</span>
            Unsubscribe anytime.
          </span>
        </div>
      </div>
    </section>
  );
}
