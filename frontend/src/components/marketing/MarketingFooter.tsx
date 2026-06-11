import { Link } from 'react-router-dom';
import { BRANDING } from '../../lib/branding';
import { FREE_TOOL_COUNT } from '../../lib/toolStats';

// Sitewide internal-link columns. These render on every prerendered page
// (~110 of them), so they're the highest-leverage internal links on the
// site — keep them pointed at the hardest-hitting tools + learn pages.
const popularTools = [
  { label: 'TDEE Calculator', to: '/free-tools/tdee-calculator' },
  { label: '1RM Calculator', to: '/free-tools/1rm-calculator' },
  { label: 'Macro Calculator', to: '/free-tools/macro-calculator' },
  { label: 'Body Fat Calculator', to: '/free-tools/body-fat-calculator' },
  { label: 'BMI Calculator', to: '/free-tools/bmi-calculator' },
  { label: 'Calories Burned', to: '/free-tools/calories-burned-calculator' },
  { label: 'Protein Per Meal', to: '/free-tools/protein-per-meal-calculator' },
  { label: 'Strength Level', to: '/free-tools/strength-level' },
  { label: 'VO2 Max Calculator', to: '/free-tools/vo2-max-calculator' },
  { label: 'AI Workout Generator', to: '/free-tools/ai-workout-generator' },
];

const learnLinks = [
  { label: 'What is TDEE?', to: '/glossary/tdee' },
  { label: 'What is 1RM?', to: '/glossary/1rm' },
  { label: 'Progressive Overload', to: '/glossary/progressive-overload' },
  { label: 'RIR and RPE', to: '/glossary/rir-rpe' },
  { label: 'Zone 2 Cardio', to: '/glossary/zone-2-cardio' },
  { label: 'Full Glossary', to: '/glossary' },
  { label: 'Blog', to: '/blog' },
  { label: 'Best AI Fitness Apps', to: '/best-ai-fitness-apps-2026' },
];

const linkClass = 'text-sm text-zinc-400 hover:text-volt-300 transition-colors';

export default function MarketingFooter() {
  return (
    <footer className="vl-dark-chrome relative bg-[#050505] text-white overflow-hidden">
      {/* Volt hairline */}
      <div className="kinetic-rule" />

      <div className="max-w-[1200px] mx-auto px-6 py-16 relative z-10">
        {/* 6-column grid */}
        <div className="grid grid-cols-2 md:grid-cols-6 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-2">
            <Link
              to="/"
              className="text-[26px] tracking-wide uppercase text-white hover:text-volt-400 transition-colors"
              style={{ fontFamily: 'var(--font-display)' }}
            >
              {BRANDING.appName}
            </Link>
            <p className="mt-3 text-sm text-zinc-400 leading-relaxed max-w-xs">
              Your AI-powered fitness coach. Personalized workouts, nutrition tracking, and real-time guidance.
            </p>
            <div className="mt-5 flex flex-col gap-2 items-start">
              <a
                href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Get it on Google Play"
              >
                <img
                  src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                  alt="Get it on Google Play"
                  className="h-10 w-auto"
                  width={646}
                  height={250}
                  loading="lazy"
                  decoding="async"
                />
              </a>
              <span className="condensed-kicker text-[11px] text-zinc-500">iOS coming soon</span>
            </div>
          </div>

          {/* Product */}
          <div>
            <h4 className="condensed-kicker text-xs text-volt-500 mb-4">Product</h4>
            <ul className="space-y-3">
              <li><Link to="/features" className={linkClass}>Features</Link></li>
              <li><Link to="/pricing" className={linkClass}>Pricing</Link></li>
              <li><Link to="/roadmap" className={linkClass}>Roadmap</Link></li>
              <li><Link to="/changelog" className={linkClass}>Changelog</Link></li>
              <li><Link to="/waitlist" className={linkClass}>Join Waitlist</Link></li>
            </ul>
          </div>

          {/* Popular tools — sitewide internal links */}
          <div>
            <h4 className="condensed-kicker text-xs text-volt-500 mb-4">Popular Tools</h4>
            <ul className="space-y-3">
              {popularTools.map((t) => (
                <li key={t.to}><Link to={t.to} className={linkClass}>{t.label}</Link></li>
              ))}
              <li><Link to="/free-tools" className="text-sm text-volt-400 hover:text-volt-300 transition-colors font-medium">All {FREE_TOOL_COUNT} free tools</Link></li>
            </ul>
          </div>

          {/* Learn */}
          <div>
            <h4 className="condensed-kicker text-xs text-volt-500 mb-4">Learn</h4>
            <ul className="space-y-3">
              {learnLinks.map((l) => (
                <li key={l.to}><Link to={l.to} className={linkClass}>{l.label}</Link></li>
              ))}
            </ul>
          </div>

          {/* Company + Legal */}
          <div>
            <h4 className="condensed-kicker text-xs text-volt-500 mb-4">Company</h4>
            <ul className="space-y-3">
              <li><Link to="/about" className={linkClass}>About</Link></li>
              <li><Link to="/architecture" className={linkClass}>Architecture</Link></li>
              <li><Link to="/faq" className={linkClass}>FAQ</Link></li>
              <li><Link to="/contact" className={linkClass}>Contact</Link></li>
              <li><a href="https://discord.gg/WAYNZpVgsK" target="_blank" rel="noopener noreferrer" className={linkClass}>Discord</a></li>
              <li><a href={BRANDING.instagram} target="_blank" rel="noopener noreferrer" className={linkClass}>Instagram</a></li>
              <li><a href="https://reddit.com/r/zealova" target="_blank" rel="noopener noreferrer" className={linkClass}>Reddit</a></li>
            </ul>
            <h4 className="condensed-kicker text-xs text-volt-500 mb-4 mt-8">Legal</h4>
            <ul className="space-y-3">
              <li><Link to="/terms" className={linkClass}>Terms of Service</Link></li>
              <li><Link to="/privacy" className={linkClass}>Privacy Policy</Link></li>
              <li><Link to="/health-disclaimer" className={linkClass}>Health Disclaimer</Link></li>
              <li><Link to="/refunds" className={linkClass}>Refund Policy</Link></li>
              <li><Link to="/delete-account" className={linkClass}>Delete Account</Link></li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-8 border-t border-white/10">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-sm text-zinc-500">
              Copyright {new Date().getFullYear()} {BRANDING.appName}. All rights reserved.
            </p>
            <div className="flex items-center gap-6">
              {/* Discord */}
              <a href="https://discord.gg/WAYNZpVgsK" target="_blank" rel="noopener noreferrer" className="text-zinc-500 hover:text-volt-400 transition-colors" aria-label="Discord">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189z"/>
                </svg>
              </a>
              {/* Instagram */}
              <a href={BRANDING.instagram} target="_blank" rel="noopener noreferrer" className="text-zinc-500 hover:text-volt-400 transition-colors" aria-label="Instagram">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
                </svg>
              </a>
              {/* Reddit */}
              <a href="https://reddit.com/r/zealova" target="_blank" rel="noopener noreferrer" className="text-zinc-500 hover:text-volt-400 transition-colors" aria-label="Reddit">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 0A12 12 0 000 12a12 12 0 0012 12 12 12 0 0012-12A12 12 0 0012 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 01-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 01.042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 014.028 12c0-.968.786-1.754 1.754-1.754.463 0 .898.196 1.207.49 1.207-.883 2.878-1.43 4.744-1.487l.885-4.182a.342.342 0 01.14-.197.35.35 0 01.238-.042l2.906.617a1.214 1.214 0 011.108-.701zM9.25 12C8.561 12 8 12.562 8 13.25c0 .687.561 1.248 1.25 1.248.687 0 1.248-.561 1.248-1.249 0-.688-.561-1.249-1.249-1.249zm5.5 0c-.687 0-1.248.561-1.248 1.25 0 .687.561 1.248 1.249 1.248.688 0 1.249-.561 1.249-1.249 0-.687-.562-1.249-1.25-1.249zm-5.466 3.99a.327.327 0 00-.231.094.33.33 0 000 .463c.842.842 2.484.913 2.961.913.477 0 2.105-.056 2.961-.913a.361.361 0 000-.462.342.342 0 00-.462 0c-.545.533-1.684.73-2.512.73-.828 0-1.953-.21-2.498-.73a.327.327 0 00-.22-.095z"/>
                </svg>
              </a>
              <Link to="/terms" className="text-sm text-zinc-500 hover:text-zinc-300 transition-colors">Terms</Link>
              <Link to="/privacy" className="text-sm text-zinc-500 hover:text-zinc-300 transition-colors">Privacy</Link>
            </div>
          </div>
        </div>
      </div>

      {/* Oversized watermark */}
      <div
        aria-hidden="true"
        className="pointer-events-none select-none absolute -bottom-[2vw] left-1/2 -translate-x-1/2 whitespace-nowrap uppercase text-white/[0.04] leading-none"
        style={{ fontFamily: 'var(--font-display)', fontSize: 'clamp(80px, 14vw, 220px)' }}
      >
        {BRANDING.appName}
      </div>
    </footer>
  );
}
