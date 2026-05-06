import { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import WaitlistForm from './WaitlistForm';

interface WaitlistSectionProps {
  source: string;
}

const fadeUp = {
  hidden: { opacity: 0, y: 28 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.16, 1, 0.3, 1] as const } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.08 } },
};

export default function WaitlistSection({ source }: WaitlistSectionProps) {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: '-80px' });

  return (
    <section
      ref={ref}
      className="relative overflow-hidden py-16 sm:py-20 px-6"
    >
      {/* Animated background gradient orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <motion.div
          className="absolute -top-40 -left-40 w-[600px] h-[600px] rounded-full bg-emerald-500/15 blur-3xl"
          animate={{
            x: [0, 60, 0],
            y: [0, 40, 0],
            scale: [1, 1.1, 1],
          }}
          transition={{ duration: 14, repeat: Infinity, ease: 'easeInOut' }}
        />
        <motion.div
          className="absolute -bottom-40 -right-40 w-[700px] h-[700px] rounded-full bg-emerald-400/10 blur-3xl"
          animate={{
            x: [0, -50, 0],
            y: [0, -30, 0],
            scale: [1, 1.15, 1],
          }}
          transition={{ duration: 16, repeat: Infinity, ease: 'easeInOut', delay: 2 }}
        />
        <motion.div
          className="absolute top-1/2 left-1/2 w-[400px] h-[400px] rounded-full bg-cyan-500/8 blur-3xl"
          animate={{
            x: ['-50%', '-40%', '-50%'],
            y: ['-50%', '-60%', '-50%'],
          }}
          transition={{ duration: 12, repeat: Infinity, ease: 'easeInOut', delay: 4 }}
        />
      </div>

      <motion.div
        initial="hidden"
        animate={inView ? 'visible' : 'hidden'}
        variants={stagger}
        className="relative max-w-[860px] mx-auto"
      >
        {/* Eyebrow */}
        <motion.div variants={fadeUp} className="text-center mb-6">
          <span className="inline-flex items-center gap-2 rounded-full border border-emerald-500/30 bg-emerald-500/5 px-4 py-2 text-xs font-semibold tracking-[0.2em] uppercase text-emerald-400">
            <span className="relative flex w-2 h-2">
              <span className="absolute inline-flex w-full h-full rounded-full bg-emerald-400 opacity-75 animate-ping" />
              <span className="relative inline-flex w-2 h-2 rounded-full bg-emerald-400" />
            </span>
            Launching Soon
          </span>
        </motion.div>

        {/* Big headline */}
        <motion.h2
          variants={fadeUp}
          className="text-center text-3xl sm:text-5xl md:text-6xl font-bold tracking-tight text-[var(--color-text)] leading-[1.05]"
        >
          Be first when{' '}
          <span className="bg-gradient-to-r from-emerald-400 via-emerald-300 to-cyan-300 bg-clip-text text-transparent">
            iOS drops.
          </span>
        </motion.h2>

        {/* Subhead */}
        <motion.p
          variants={fadeUp}
          className="mt-4 text-center text-base sm:text-lg text-[var(--color-text-muted)] max-w-[560px] mx-auto leading-relaxed"
        >
          Android link goes out the moment Google approves. iOS launches right after — waitlist gets it first.
        </motion.p>

        {/* The waitlist form, centerpiece — placed above the fold */}
        <motion.div variants={fadeUp} className="mt-8">
          <WaitlistForm source={source} />
        </motion.div>

        {/* Visual pillars (3 promise tiles) */}
        <motion.div
          variants={fadeUp}
          className="mt-12 grid grid-cols-3 gap-3 sm:gap-4 max-w-[720px] mx-auto"
        >
          {[
            { emoji: '📸', title: 'Snap a meal', sub: '2-second macros' },
            { emoji: '💪', title: 'Smart workouts', sub: 'Built around your gym' },
            { emoji: '🤖', title: 'AI coach', sub: '24/7 chat, no DMs' },
          ].map((tile, i) => (
            <motion.div
              key={tile.title}
              initial={{ opacity: 0, y: 20 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: 0.4 + i * 0.08, duration: 0.5 }}
              className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)]/40 backdrop-blur-sm p-4 sm:p-5 text-center hover:border-emerald-500/40 transition-colors"
            >
              <div className="text-2xl sm:text-3xl mb-2">{tile.emoji}</div>
              <div className="text-xs sm:text-sm font-semibold text-[var(--color-text)]">{tile.title}</div>
              <div className="text-[10px] sm:text-xs text-[var(--color-text-muted)] mt-1">{tile.sub}</div>
            </motion.div>
          ))}
        </motion.div>

        {/* Trust strip */}
        <motion.div
          variants={fadeUp}
          className="mt-12 flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-xs text-[var(--color-text-muted)]"
        >
          <span className="flex items-center gap-2">
            <span className="text-emerald-400">●</span>
            Built solo. Honest about what works.
          </span>
          <span className="flex items-center gap-2">
            <span className="text-emerald-400">●</span>
            One email at launch.
          </span>
          <span className="flex items-center gap-2">
            <span className="text-emerald-400">●</span>
            Unsubscribe anytime.
          </span>
        </motion.div>
      </motion.div>
    </section>
  );
}
