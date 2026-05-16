import { useState, useEffect, useRef } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useAppStore } from '../../store';
import { BRANDING } from '../../lib/branding';

function useClickOutside(ref: React.RefObject<HTMLElement | null>, handler: () => void) {
  useEffect(() => {
    const listener = (e: MouseEvent | TouchEvent) => {
      if (!ref.current || ref.current.contains(e.target as Node)) return;
      handler();
    };
    document.addEventListener('mousedown', listener);
    document.addEventListener('touchstart', listener);
    return () => {
      document.removeEventListener('mousedown', listener);
      document.removeEventListener('touchstart', listener);
    };
  }, [ref, handler]);
}

const socialLinks = [
  {
    label: 'Instagram',
    href: BRANDING.instagram,
    icon: (
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
      </svg>
    ),
  },
  {
    label: 'TikTok',
    href: 'https://tiktok.com/@getzealova',
    icon: (
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
      </svg>
    ),
  },
  {
    label: 'YouTube',
    href: 'https://youtube.com/@getzealova',
    icon: (
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
        <path d="M23.498 6.186a3.016 3.016 0 00-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 00.502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 002.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 002.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
      </svg>
    ),
  },
  {
    label: 'X (Twitter)',
    href: 'https://x.com/getzealova',
    icon: (
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
        <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
      </svg>
    ),
  },
  {
    label: 'Discord',
    href: 'https://discord.gg/WAYNZpVgsK',
    icon: (
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
        <path d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189z"/>
      </svg>
    ),
  },
  {
    label: 'Reddit',
    href: 'https://reddit.com/r/zealova',
    icon: (
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 0A12 12 0 000 12a12 12 0 0012 12 12 12 0 0012-12A12 12 0 0012 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 01-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 01.042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 014.028 12c0-.968.786-1.754 1.754-1.754.463 0 .898.196 1.207.49 1.207-.883 2.878-1.43 4.744-1.487l.885-4.182a.342.342 0 01.14-.197.35.35 0 01.238-.042l2.906.617a1.214 1.214 0 011.108-.701zM9.25 12C8.561 12 8 12.562 8 13.25c0 .687.561 1.248 1.25 1.248.687 0 1.248-.561 1.248-1.249 0-.688-.561-1.249-1.249-1.249zm5.5 0c-.687 0-1.248.561-1.248 1.25 0 .687.561 1.248 1.249 1.248.688 0 1.249-.561 1.249-1.249 0-.687-.562-1.249-1.25-1.249zm-5.466 3.99a.327.327 0 00-.231.094.33.33 0 000 .463c.842.842 2.484.913 2.961.913.477 0 2.105-.056 2.961-.913a.361.361 0 000-.462.342.342 0 00-.462 0c-.545.533-1.684.73-2.512.73-.828 0-1.953-.21-2.498-.73a.327.327 0 00-.22-.095z"/>
      </svg>
    ),
  },
];

export default function MarketingNav() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);
  const location = useLocation();
  const { theme, toggleTheme } = useAppStore();

  const toolsRef = useRef<HTMLDivElement>(null);
  const compareRef = useRef<HTMLDivElement>(null);
  const resourcesRef = useRef<HTMLDivElement>(null);

  useClickOutside(toolsRef, () => { if (openDropdown === 'tools') setOpenDropdown(null); });
  useClickOutside(compareRef, () => { if (openDropdown === 'compare') setOpenDropdown(null); });
  useClickOutside(resourcesRef, () => { if (openDropdown === 'resources') setOpenDropdown(null); });

  // The landing page has a cinematic hero the nav floats transparently over
  // until the user scrolls past it. Every other page has content starting
  // right under the nav, so the nav must be frosted-glass from the start —
  // otherwise page content scrolls *under* a transparent bar and overlaps it.
  useEffect(() => {
    const isLanding = location.pathname === '/';

    if (!isLanding) {
      // Non-landing: always frosted, no scroll listener needed.
      setIsScrolled(true);
      return;
    }

    const computeThreshold = () => Math.max(2400, window.innerHeight * 4);
    let threshold = computeThreshold();
    const handleScroll = () => setIsScrolled(window.scrollY > threshold);
    const handleResize = () => {
      threshold = computeThreshold();
      handleScroll();
    };

    handleScroll();
    window.addEventListener('scroll', handleScroll, { passive: true });
    window.addEventListener('resize', handleResize);
    return () => {
      window.removeEventListener('scroll', handleScroll);
      window.removeEventListener('resize', handleResize);
    };
  }, [location.pathname]);

  const isActive = (path: string) => location.pathname === path;
  const toggle = (key: string) => setOpenDropdown(openDropdown === key ? null : key);

  const dropdownBtnClass = (key: string) =>
    `text-sm font-medium transition-colors flex items-center gap-1 ${
      openDropdown === key
        ? 'text-emerald-500'
        : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text)]'
    }`;

  const dropdownItemClass = "flex items-center gap-3 px-4 py-2.5 text-sm text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] rounded-lg transition-colors";

  const chevron = (key: string) => (
    <svg className={`w-3.5 h-3.5 transition-transform ${openDropdown === key ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
    </svg>
  );

  const dropdownPanel = (children: React.ReactNode, width = "w-52") => (
    <motion.div
      className={`absolute top-full mt-2 right-0 ${width} bg-[var(--color-surface)] border border-[var(--color-border)] rounded-xl shadow-lg overflow-hidden p-1.5`}
      initial={{ opacity: 0, y: -8, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -8, scale: 0.96 }}
      transition={{ duration: 0.15 }}
    >
      {children}
    </motion.div>
  );

  // Single top-level link kept simple. Everything else lives in 3
  // organized dropdowns: Tools, Compare, Resources.
  const navLinks = [
    { label: 'Features', to: '/features' },
  ];

  const toolsLinks = [
    { label: 'All Free Tools', to: '/free-tools', desc: '52 calculators and AI tools' },
    { label: 'Glossary', to: '/glossary', desc: '15 fitness concepts explained' },
  ];

  const compareLinks = [
    { label: 'All comparisons & guides', to: '/blog' },
    { label: 'vs Google Health', to: '/vs/google-health' },
    { label: 'Best AI Fitness Apps 2026', to: '/best-ai-fitness-apps-2026' },
    { label: 'Best Calorie Trackers 2026', to: '/best-calorie-tracker-apps-2026' },
    { label: 'Best Workout Generators 2026', to: '/best-workout-generator-apps-2026' },
    { label: 'Best Fitbit Alternatives', to: '/best-fitbit-alternatives-2026' },
    { label: 'Best MyFitnessPal Alternatives', to: '/best-myfitnesspal-alternatives-2026' },
  ];

  const resourceLinks = [
    { label: 'FAQ', to: '/faq' },
    { label: 'Roadmap', to: '/roadmap' },
    { label: 'Contact', to: '/contact' },
    { label: 'Privacy Policy', to: '/privacy' },
    { label: 'Terms of Service', to: '/terms' },
    { label: 'Refund Policy', to: '/refunds' },
  ];

  return (
    <motion.nav
      className={`fixed top-0 left-0 right-0 z-50 nav-glass transition-all duration-300 ${
        isScrolled ? 'is-scrolled' : ''
      }`}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.5 }}
    >
      <div className="max-w-[1200px] mx-auto px-6 lg:px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link
            to="/"
            className="flex items-center gap-2 text-[22px] font-bold tracking-[-0.02em] text-[var(--color-text)] hover:text-emerald-500 transition-colors"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            <img src="/zealova-logo.png" alt={BRANDING.appName} className="w-8 h-8 object-contain" />
            {BRANDING.appName}
          </Link>

          {/* Desktop Nav — 4 top-level items: Tools · Compare · Features · Resources */}
          <div className="hidden md:flex items-center gap-6">
            {/* Tools Dropdown */}
            <div ref={toolsRef} className="relative">
              <button onClick={() => toggle('tools')} className={dropdownBtnClass('tools')}>
                Tools {chevron('tools')}
              </button>
              <AnimatePresence>
                {openDropdown === 'tools' && dropdownPanel(
                  toolsLinks.map((link) => (
                    <Link
                      key={link.to}
                      to={link.to}
                      onClick={() => setOpenDropdown(null)}
                      className="flex flex-col gap-0.5 px-4 py-2.5 text-sm hover:bg-[var(--color-surface-muted)] rounded-lg transition-colors"
                    >
                      <span className="text-[var(--color-text)] font-medium">{link.label}</span>
                      <span className="text-[11px] text-[var(--color-text-muted)]">{link.desc}</span>
                    </Link>
                  )),
                  "w-64"
                )}
              </AnimatePresence>
            </div>

            {/* Compare Dropdown */}
            <div ref={compareRef} className="relative">
              <button onClick={() => toggle('compare')} className={dropdownBtnClass('compare')}>
                Compare {chevron('compare')}
              </button>
              <AnimatePresence>
                {openDropdown === 'compare' && dropdownPanel(
                  compareLinks.map((link) => (
                    <Link
                      key={link.to}
                      to={link.to}
                      onClick={() => setOpenDropdown(null)}
                      className={dropdownItemClass}
                    >
                      {link.label}
                    </Link>
                  )),
                  "w-72"
                )}
              </AnimatePresence>
            </div>

            {/* Features (top-level) */}
            {navLinks.map((link) => (
              <Link
                key={link.to}
                to={link.to}
                className={`text-sm font-medium transition-colors ${
                  isActive(link.to)
                    ? 'text-emerald-500'
                    : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text)]'
                }`}
              >
                {link.label}
              </Link>
            ))}

            {/* Resources Dropdown — FAQ, Roadmap, Contact, Legal, Community */}
            <div ref={resourcesRef} className="relative">
              <button onClick={() => toggle('resources')} className={dropdownBtnClass('resources')}>
                Resources {chevron('resources')}
              </button>
              <AnimatePresence>
                {openDropdown === 'resources' && dropdownPanel(
                  <>
                    {resourceLinks.map((link) => (
                      <Link
                        key={link.to}
                        to={link.to}
                        onClick={() => setOpenDropdown(null)}
                        className={dropdownItemClass}
                      >
                        {link.label}
                      </Link>
                    ))}
                    <div className="h-px bg-[var(--color-border)] my-1.5 mx-2" />
                    <p className="px-4 py-1 text-[10px] uppercase tracking-wider text-[var(--color-text-muted)] font-semibold">Community</p>
                    <div className="grid grid-cols-3 gap-1 px-2 pb-2 pt-1">
                      {socialLinks.map((social) => (
                        <a
                          key={social.label}
                          href={social.href}
                          target="_blank"
                          rel="noopener noreferrer"
                          aria-label={social.label}
                          onClick={() => setOpenDropdown(null)}
                          className="flex items-center justify-center py-2 text-[var(--color-text-secondary)] hover:text-emerald-500 hover:bg-[var(--color-surface-muted)] rounded-lg transition-colors"
                        >
                          {social.icon}
                        </a>
                      ))}
                    </div>
                  </>,
                  "w-60"
                )}
              </AnimatePresence>
            </div>

          </div>

          {/* Right side: Theme toggle + Pricing CTA */}
          <div className="hidden md:flex items-center gap-4">
            <button
              onClick={toggleTheme}
              className="p-2 rounded-lg text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] transition-all"
              aria-label={`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`}
            >
              {theme === 'light' ? (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
                </svg>
              ) : (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
                </svg>
              )}
            </button>

            <Link
              to="/waitlist"
              className="flex items-center gap-2 px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-[#ffffff] rounded-full transition-all text-sm font-medium shadow-lg shadow-emerald-500/20 hover:shadow-emerald-500/40"
            >
              <span className="relative flex w-2 h-2">
                <span className="absolute inline-flex w-full h-full rounded-full bg-[#ffffff] opacity-75 animate-ping" />
                <span className="relative inline-flex w-2 h-2 rounded-full bg-[#ffffff]" />
              </span>
              Join Waitlist
            </Link>
          </div>

          {/* Mobile: theme toggle + hamburger */}
          <div className="md:hidden flex items-center gap-2">
            <button
              onClick={toggleTheme}
              className="p-2 rounded-lg text-[var(--color-text-secondary)] hover:text-[var(--color-text)] transition-all"
              aria-label={`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`}
            >
              {theme === 'light' ? (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
                </svg>
              ) : (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
                </svg>
              )}
            </button>
            <button
              className="text-[var(--color-text-secondary)] hover:text-[var(--color-text)] p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Menu"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                {mobileMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                )}
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            className="md:hidden absolute top-16 left-0 right-0 bg-[var(--color-surface-glass)] backdrop-blur-xl border-b border-[var(--color-border)]"
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }}
          >
            <div className="max-w-[1200px] mx-auto px-6 py-4 flex flex-col gap-1">
              {/* Tools group */}
              <p className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wider px-4 pt-1 pb-1">Tools</p>
              {toolsLinks.map((link) => (
                <Link
                  key={link.to}
                  to={link.to}
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex flex-col py-2.5 px-4 rounded-lg text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] transition-colors"
                >
                  <span className="text-sm font-medium">{link.label}</span>
                  <span className="text-[11px] text-[var(--color-text-muted)]">{link.desc}</span>
                </Link>
              ))}

              {/* Compare group */}
              <p className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wider px-4 pt-3 pb-1">Compare</p>
              {compareLinks.map((link) => (
                <Link
                  key={link.to}
                  to={link.to}
                  onClick={() => setMobileMenuOpen(false)}
                  className="text-sm font-medium py-2.5 px-4 rounded-lg text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] transition-colors"
                >
                  {link.label}
                </Link>
              ))}

              {/* Product group */}
              <p className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wider px-4 pt-3 pb-1">Product</p>
              {navLinks.map((link) => (
                <Link
                  key={link.to}
                  to={link.to}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`text-sm font-medium py-2.5 px-4 rounded-lg transition-colors ${
                    isActive(link.to)
                      ? 'text-emerald-500 bg-emerald-50/50'
                      : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)]'
                  }`}
                >
                  {link.label}
                </Link>
              ))}

              {/* Resources group */}
              <p className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wider px-4 pt-3 pb-1">Resources</p>
              {resourceLinks.map((link) => (
                <Link
                  key={link.to}
                  to={link.to}
                  onClick={() => setMobileMenuOpen(false)}
                  className="text-sm font-medium py-2.5 px-4 rounded-lg text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] transition-colors"
                >
                  {link.label}
                </Link>
              ))}

              <hr className="border-[var(--color-border)] my-2" />

              {/* Community */}
              <p className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wider px-4 pt-1 pb-2">Community</p>
              <div className="grid grid-cols-3 gap-2 px-2">
                {socialLinks.map((social) => (
                  <a
                    key={social.label}
                    href={social.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() => setMobileMenuOpen(false)}
                    className="flex flex-col items-center gap-1.5 py-3 px-2 text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] rounded-lg transition-colors"
                  >
                    {social.icon}
                    <span className="text-[11px] font-medium">{social.label}</span>
                  </a>
                ))}
              </div>

              <hr className="border-[var(--color-border)] my-2" />

              {/* Contact */}
              <a
                href={`mailto:${BRANDING.supportEmail}`}
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 text-sm font-medium py-3 px-4 text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] rounded-lg transition-colors"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                </svg>
                {BRANDING.supportEmail}
              </a>

              <hr className="border-[var(--color-border)] my-2" />

              {/* CTA */}
              <Link
                to="/waitlist"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center justify-center gap-2 text-sm font-medium py-3 px-4 bg-emerald-500 text-[#ffffff] rounded-full mt-1 shadow-lg shadow-emerald-500/20"
              >
                <span className="relative flex w-2 h-2">
                  <span className="absolute inline-flex w-full h-full rounded-full bg-[#ffffff] opacity-75 animate-ping" />
                  <span className="relative inline-flex w-2 h-2 rounded-full bg-[#ffffff]" />
                </span>
                Join Waitlist — iOS + Android
              </Link>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.nav>
  );
}
