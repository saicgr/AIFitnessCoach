import { useState, useEffect, useRef, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { motion, useInView, AnimatePresence } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

// Apple-style animations - very subtle, purposeful
const fade = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { duration: 1, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const fadeUp = {
  hidden: { opacity: 0, y: 8 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.15 } },
};

// Carousel slides data - app features showcase (updated with green theme)
const carouselSlides = [
  {
    id: 1,
    title: 'AI-Powered Workouts',
    description: 'Get personalized workout plans tailored to your goals, equipment, and schedule.',
    gradient: 'from-emerald-600 via-green-500 to-teal-400',
    icon: (
      <svg className="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
      </svg>
    ),
  },
  {
    id: 2,
    title: 'Smart Coaching',
    description: 'Chat with your AI coach anytime. Get form tips, nutrition advice, and motivation.',
    gradient: 'from-lime-500 via-green-500 to-emerald-500',
    icon: (
      <svg className="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>
    ),
  },
  {
    id: 3,
    title: 'Real-time Tracking',
    description: 'Log your sets, reps, and weights as you train. Rest timers keep you on track.',
    gradient: 'from-teal-500 via-cyan-500 to-emerald-400',
    icon: (
      <svg className="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
  {
    id: 4,
    title: 'Progress Analytics',
    description: 'Visualize your gains. Track personal records, streaks, and strength trends.',
    gradient: 'from-green-600 via-emerald-500 to-lime-400',
    icon: (
      <svg className="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
      </svg>
    ),
  },
];

// Phone showcase features - expandable buttons like Apple
const phoneFeatures = [
  {
    id: 'personalized',
    label: 'Personalized Plans',
    color: '#10B981', // emerald
    description: 'AI creates custom workouts based on your goals, equipment, and available time.',
    hasIcon: true,
  },
  {
    id: 'ai-coach',
    label: 'AI Coach',
    color: '',
    description: 'Chat with your coach 24/7 for form tips, exercise swaps, and motivation.',
    hasIcon: false,
  },
  {
    id: 'tracking',
    label: 'Real-time Tracking',
    color: '',
    description: 'Log sets, reps, and weights as you train with automatic rest timers.',
    hasIcon: false,
  },
  {
    id: 'videos',
    label: 'Exercise Videos',
    color: '',
    description: 'Watch proper form demonstrations for every exercise in your workout.',
    hasIcon: false,
  },
  {
    id: 'analytics',
    label: 'Progress Analytics',
    color: '',
    description: 'Track personal records, streaks, and visualize your strength gains over time.',
    hasIcon: false,
  },
  {
    id: 'nutrition',
    label: 'Nutrition Tracking',
    color: '',
    description: 'Log meals with photos and get instant macro breakdowns from your AI coach.',
    hasIcon: false,
  },
  {
    id: 'scheduling',
    label: 'Smart Scheduling',
    color: '',
    description: 'Weekly workout plans that automatically adapt to your schedule.',
    hasIcon: false,
  },
];

// Feature gallery data (updated gradients - no purple/blue)
const galleryFeatures = [
  {
    id: 1,
    title: 'Exercise Library',
    subtitle: '1700+ exercises with video demos',
    gradient: 'from-emerald-500 to-teal-400',
    icon: (
      <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M15.91 11.672a.375.375 0 010 .656l-5.603 3.113a.375.375 0 01-.557-.328V8.887c0-.286.307-.466.557-.327l5.603 3.112z" />
      </svg>
    ),
  },
  {
    id: 2,
    title: 'Nutrition Tracking',
    subtitle: 'Photo-based meal logging',
    gradient: 'from-orange-500 to-amber-400',
    icon: (
      <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0zM18.75 10.5h.008v.008h-.008V10.5z" />
      </svg>
    ),
  },
  {
    id: 3,
    title: 'Smart Scheduling',
    subtitle: 'Weekly plans that adapt to you',
    gradient: 'from-lime-500 to-green-400',
    icon: (
      <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" />
      </svg>
    ),
  },
  {
    id: 4,
    title: 'Warmup & Cooldown',
    subtitle: 'Auto-generated mobility work',
    gradient: 'from-teal-500 to-cyan-400',
    icon: (
      <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M15.362 5.214A8.252 8.252 0 0112 21 8.25 8.25 0 016.038 7.048 8.287 8.287 0 009 9.6a8.983 8.983 0 013.361-6.867 8.21 8.21 0 003 2.48z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 18a3.75 3.75 0 00.495-7.467 5.99 5.99 0 00-1.925 3.546 5.974 5.974 0 01-2.133-1A3.75 3.75 0 0012 18z" />
      </svg>
    ),
  },
  {
    id: 5,
    title: 'Rest Timers',
    subtitle: 'Optimized recovery between sets',
    gradient: 'from-emerald-500 to-green-400',
    icon: (
      <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
  {
    id: 6,
    title: 'Skill Progressions',
    subtitle: '52+ exercises from beginner to advanced',
    gradient: 'from-green-600 to-emerald-400',
    icon: (
      <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" />
      </svg>
    ),
  },
];

// Stats data
const stats = [
  { value: 1700, suffix: '+', label: 'Exercises' },
  { value: 24, suffix: '/7', label: 'AI Coach' },
  { value: 1000, suffix: '+', label: 'Features' },
];

// Typing animation messages
const chatMessages = [
  { role: 'user', text: 'My shoulder feels tight today' },
  { role: 'ai', text: "I've adjusted your workout to focus on lower body and core. Added shoulder mobility stretches to your cooldown. Ready when you are!" },
];

// Animated Counter Hook
function useCounter(target: number, duration: number = 2000, shouldStart: boolean = false) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!shouldStart) return;

    let startTime: number | null = null;
    let animationFrame: number;

    const animate = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      const easeOut = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(easeOut * target));

      if (progress < 1) {
        animationFrame = requestAnimationFrame(animate);
      }
    };

    animationFrame = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(animationFrame);
  }, [target, duration, shouldStart]);

  return count;
}

// Typing Animation Component
function TypingText({ text, onComplete }: { text: string; onComplete?: () => void }) {
  const [displayText, setDisplayText] = useState('');
  const [isComplete, setIsComplete] = useState(false);

  useEffect(() => {
    let index = 0;
    const interval = setInterval(() => {
      if (index < text.length) {
        setDisplayText(text.slice(0, index + 1));
        index++;
      } else {
        setIsComplete(true);
        clearInterval(interval);
        onComplete?.();
      }
    }, 30);

    return () => clearInterval(interval);
  }, [text, onComplete]);

  return (
    <span>
      {displayText}
      {!isComplete && <span className="animate-pulse">|</span>}
    </span>
  );
}

export default function MarketingLanding() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const [isHovering, setIsHovering] = useState(false);
  const [progress, setProgress] = useState(0);
  const progressRef = useRef<number | null>(null);
  const lastTimeRef = useRef<number>(0);
  const [chatStep, setChatStep] = useState(0);
  const [chatStarted, setChatStarted] = useState(false);
  const [activePhoneFeature, setActivePhoneFeature] = useState<string | null>('personalized');

  const galleryRef = useRef<HTMLDivElement>(null);
  const statsRef = useRef<HTMLDivElement>(null);
  const chatRef = useRef<HTMLDivElement>(null);
  const phoneRef = useRef<HTMLDivElement>(null);

  const statsInView = useInView(statsRef, { once: true, margin: '-100px' });
  const chatInView = useInView(chatRef, { once: true, margin: '-100px' });
  const phoneInView = useInView(phoneRef, { once: true, margin: '-100px' });

  // Auto-advance carousel with progress animation
  useEffect(() => {
    setProgress(0);
    lastTimeRef.current = 0;

    if (isPaused || isHovering) {
      if (progressRef.current) {
        cancelAnimationFrame(progressRef.current);
        progressRef.current = null;
      }
      return;
    }

    const DURATION = 5000;

    const animate = (timestamp: number) => {
      if (!lastTimeRef.current) {
        lastTimeRef.current = timestamp;
      }

      const elapsed = timestamp - lastTimeRef.current;
      const newProgress = Math.min((elapsed / DURATION) * 100, 100);

      setProgress(newProgress);

      if (newProgress >= 100) {
        setCurrentSlide((prev) => (prev + 1) % carouselSlides.length);
      } else {
        progressRef.current = requestAnimationFrame(animate);
      }
    };

    progressRef.current = requestAnimationFrame(animate);

    return () => {
      if (progressRef.current) {
        cancelAnimationFrame(progressRef.current);
      }
    };
  }, [isPaused, isHovering, currentSlide]);

  // Start chat animation when in view
  useEffect(() => {
    if (chatInView && !chatStarted) {
      setChatStarted(true);
      setChatStep(1);
    }
  }, [chatInView, chatStarted]);

  const scrollTo = (id: string) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
  };

  const scrollGallery = useCallback((direction: 'left' | 'right') => {
    if (!galleryRef.current) return;
    const scrollAmount = 320;
    galleryRef.current.scrollBy({
      left: direction === 'left' ? -scrollAmount : scrollAmount,
      behavior: 'smooth',
    });
  }, []);

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)] selection:bg-emerald-500/20 overflow-x-hidden">
      {/* Navigation */}
      <MarketingNav />

      {/* Hero Section */}
      <section className="relative min-h-screen flex flex-col items-center justify-center px-6 pt-12">
        <motion.div
          className="max-w-[680px] mx-auto text-center"
          initial="hidden"
          animate="visible"
          variants={stagger}
        >
          <motion.p variants={fade} className="text-[17px] text-[var(--color-text-muted)] mb-3">
            Introducing
          </motion.p>

          <motion.h1
            variants={fadeUp}
            className="text-[56px] sm:text-[80px] md:text-[96px] font-semibold tracking-[-0.03em] leading-[1.05] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            <span className="bg-gradient-to-r from-emerald-400 via-green-400 to-lime-400 bg-clip-text text-transparent">
              FitWiz
            </span>
          </motion.h1>

          <motion.p
            variants={fadeUp}
            className="text-[28px] sm:text-[32px] md:text-[40px] font-semibold tracking-[-0.02em] leading-[1.1] text-[var(--color-text-secondary)] mb-6"
          >
            Your AI fitness coach.
          </motion.p>

          <motion.p
            variants={fadeUp}
            className="text-[17px] sm:text-[19px] text-[var(--color-text-secondary)] max-w-[500px] mx-auto leading-[1.47] mb-10"
          >
            Personalized workouts. Real-time guidance. Intelligent progress tracking.
          </motion.p>

          <motion.div variants={fadeUp} className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              to="/login"
              className="min-w-[160px] px-7 py-3 bg-emerald-500 text-white text-[17px] rounded-full hover:bg-emerald-400 transition-colors"
            >
              Get started
            </Link>
            <button
              onClick={() => scrollTo('highlights')}
              className="min-w-[160px] px-7 py-3 text-emerald-400 text-[17px] hover:underline transition-all"
            >
              Learn more
            </button>
          </motion.div>
        </motion.div>

        {/* Scroll indicator */}
        <motion.div
          className="absolute bottom-8 left-1/2 -translate-x-1/2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.3 }}
          transition={{ delay: 1.5, duration: 1 }}
        >
          <motion.svg
            className="w-6 h-6 text-[var(--color-text-muted)]"
            fill="none"
            viewBox="0 0 24 24"
            animate={{ y: [0, 8, 0] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            <path stroke="currentColor" strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
          </motion.svg>
        </motion.div>
      </section>

      {/* Highlights Carousel Section */}
      <section id="highlights" className="py-20 sm:py-28 px-6">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="text-center mb-12"
          >
            <motion.p variants={fade} className="text-[17px] text-[var(--color-text-muted)] mb-2">
              Get the highlights.
            </motion.p>
            <motion.h2
              variants={fadeUp}
              className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em]"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              See what's new.
            </motion.h2>
          </motion.div>

          {/* Carousel */}
          <div
            className="relative"
            onMouseEnter={() => setIsHovering(true)}
            onMouseLeave={() => setIsHovering(false)}
          >
            <div className="overflow-hidden rounded-3xl">
              <AnimatePresence mode="wait">
                <motion.div
                  key={currentSlide}
                  initial={{ opacity: 0, x: 100 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -100 }}
                  transition={{ duration: 0.5, ease: [0.25, 0.1, 0.25, 1] as const }}
                  className={`relative h-[400px] sm:h-[480px] bg-gradient-to-br ${carouselSlides[currentSlide].gradient} flex flex-col items-center justify-center p-8 sm:p-12`}
                >
                  <motion.div
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ delay: 0.2, duration: 0.5 }}
                    className="mb-6"
                  >
                    {carouselSlides[currentSlide].icon}
                  </motion.div>
                  <motion.h3
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.3, duration: 0.5 }}
                    className="text-[28px] sm:text-[40px] font-semibold text-white text-center mb-4"
                  >
                    {carouselSlides[currentSlide].title}
                  </motion.h3>
                  <motion.p
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.4, duration: 0.5 }}
                    className="text-[17px] sm:text-[19px] text-white/90 text-center max-w-[500px]"
                  >
                    {carouselSlides[currentSlide].description}
                  </motion.p>
                </motion.div>
              </AnimatePresence>
            </div>

            {/* Carousel Controls */}
            <div className="flex items-center justify-center gap-4 mt-6">
              <div className="flex items-center gap-2">
                {carouselSlides.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setCurrentSlide(index)}
                    className="relative h-1 rounded-full overflow-hidden transition-all duration-300"
                    style={{ width: index === currentSlide ? '48px' : '24px' }}
                    aria-label={`Go to slide ${index + 1}`}
                  >
                    <div className="absolute inset-0 bg-[var(--color-surface-muted)]" />
                    <div
                      className="absolute inset-y-0 left-0 bg-emerald-500 rounded-full transition-none"
                      style={{
                        width: index === currentSlide
                          ? `${progress}%`
                          : index < currentSlide
                            ? '100%'
                            : '0%',
                      }}
                    />
                  </button>
                ))}
              </div>

              <button
                onClick={() => setIsPaused(!isPaused)}
                className="p-2 rounded-full bg-[var(--color-surface-muted)] hover:bg-[var(--color-surface-elevated)] transition-colors"
                aria-label={isPaused ? 'Play' : 'Pause'}
              >
                {isPaused ? (
                  <svg className="w-4 h-4 text-[var(--color-text)]" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M8 5v14l11-7z" />
                  </svg>
                ) : (
                  <svg className="w-4 h-4 text-[var(--color-text)]" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
                  </svg>
                )}
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Phone Showcase Section */}
      <section className="py-20 sm:py-28 px-6">
        <div className="max-w-[1200px] mx-auto">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-16"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Take a closer look.
          </motion.h2>

          <motion.div
            ref={phoneRef}
            initial={{ opacity: 0, y: 40 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="card-spur rounded-3xl p-8 sm:p-12 lg:p-16"
          >
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center">
              {/* Left side - Feature buttons */}
              <div className="space-y-3">
                {phoneFeatures.map((feature, index) => (
                  <motion.button
                    key={feature.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={phoneInView ? { opacity: 1, x: 0 } : {}}
                    transition={{ delay: index * 0.1, duration: 0.5 }}
                    onClick={() => setActivePhoneFeature(activePhoneFeature === feature.id ? null : feature.id)}
                    className={`w-full text-left px-5 py-3.5 rounded-full transition-all duration-300 flex items-center gap-3 ${
                      activePhoneFeature === feature.id
                        ? 'bg-[var(--color-surface-elevated)]'
                        : 'bg-[var(--color-surface-muted)] hover:bg-[var(--color-surface-elevated)]'
                    }`}
                  >
                    <span className={`flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center ${
                      feature.hasIcon && feature.color ? '' : 'border border-[var(--color-border)]'
                    }`}
                    style={feature.hasIcon && feature.color ? { backgroundColor: feature.color } : {}}>
                      {feature.hasIcon && feature.color ? (
                        <span className="w-2 h-2 rounded-full bg-white" />
                      ) : (
                        <svg className="w-3 h-3 text-[var(--color-text-muted)]" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                      )}
                    </span>
                    <span className="text-[15px] sm:text-[17px] text-[var(--color-text)] font-medium">{feature.label}</span>
                  </motion.button>
                ))}

                {/* Expanded description */}
                <AnimatePresence mode="wait">
                  {activePhoneFeature && (
                    <motion.div
                      key={activePhoneFeature}
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ duration: 0.3 }}
                      className="overflow-hidden"
                    >
                      <p className="text-[15px] text-[var(--color-text-secondary)] leading-relaxed pt-4 pl-14">
                        {phoneFeatures.find(f => f.id === activePhoneFeature)?.description}
                      </p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>

              {/* Right side - Phone mockup */}
              <div className="relative flex justify-center lg:justify-end">
                <motion.div
                  className="relative"
                  animate={{
                    rotateY: activePhoneFeature ? [0, -5, 0] : 0,
                  }}
                  transition={{ duration: 0.6, ease: 'easeOut' }}
                  style={{ perspective: 1000 }}
                >
                  {/* Phone device frame - stays dark always */}
                  <div
                    className="relative w-[280px] sm:w-[320px] rounded-[3rem] p-3 shadow-2xl"
                    style={{
                      background: 'linear-gradient(145deg, #3a3a3c 0%, #1c1c1e 50%, #0a0a0a 100%)',
                      boxShadow: `
                        0 50px 100px -20px rgba(0, 0, 0, 0.8),
                        0 30px 60px -10px rgba(0, 0, 0, 0.6),
                        inset 0 1px 0 rgba(255, 255, 255, 0.1),
                        inset 0 -1px 0 rgba(0, 0, 0, 0.3)
                      `,
                      transform: 'rotateY(-8deg) rotateX(2deg)',
                      transformStyle: 'preserve-3d',
                    }}
                  >
                    {/* Phone notch */}
                    <div className="absolute top-5 left-1/2 -translate-x-1/2 w-28 h-8 bg-black rounded-full z-20" />

                    {/* Phone screen - stays dark (it's a phone UI) */}
                    <div
                      className="relative rounded-[2.5rem] overflow-hidden bg-black"
                      style={{ aspectRatio: '9/19.5' }}
                    >
                      <div className="absolute inset-0 bg-gradient-to-b from-[#0a0a0a] to-[#1a1a1a]">
                        <div className="flex items-center justify-between px-6 pt-14 pb-2">
                          <span className="text-[11px] text-white/60 font-medium">9:41</span>
                          <div className="flex items-center gap-1">
                            <svg className="w-4 h-4 text-white/60" fill="currentColor" viewBox="0 0 24 24">
                              <path d="M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9-4.03-9-9-9zm0 16c-3.86 0-7-3.14-7-7s3.14-7 7-7 7 3.14 7 7-3.14 7-7 7z" opacity={0.3}/>
                              <path d="M12 5c-3.86 0-7 3.14-7 7h2c0-2.76 2.24-5 5-5V5z"/>
                            </svg>
                            <svg className="w-4 h-4 text-white/60" fill="currentColor" viewBox="0 0 24 24">
                              <path d="M15.67 4H14V2h-4v2H8.33C7.6 4 7 4.6 7 5.33v15.33C7 21.4 7.6 22 8.33 22h7.33c.74 0 1.34-.6 1.34-1.33V5.33C17 4.6 16.4 4 15.67 4z"/>
                            </svg>
                          </div>
                        </div>

                        <AnimatePresence mode="wait">
                          <motion.div
                            key={activePhoneFeature || 'default'}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            transition={{ duration: 0.3 }}
                            className="px-4 pt-2"
                          >
                            {activePhoneFeature === 'personalized' && (
                              <div className="space-y-3">
                                <div className="text-[10px] text-white/40 uppercase tracking-wider">Today's Workout</div>
                                <div className="bg-gradient-to-br from-emerald-500/20 to-green-500/10 rounded-2xl p-4 border border-emerald-500/20">
                                  <div className="text-white font-semibold mb-1">Upper Body Strength</div>
                                  <div className="text-[11px] text-white/60">45 min - 6 exercises</div>
                                  <div className="flex gap-2 mt-3">
                                    <span className="px-2 py-1 rounded-full bg-white/10 text-[9px] text-white/80">Push</span>
                                    <span className="px-2 py-1 rounded-full bg-white/10 text-[9px] text-white/80">Dumbbells</span>
                                  </div>
                                </div>
                                <div className="bg-[#1d1d1f] rounded-xl p-3">
                                  <div className="flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-lg bg-emerald-500/20 flex items-center justify-center">
                                      <span className="text-[10px]">1</span>
                                    </div>
                                    <div>
                                      <div className="text-[12px] text-white">Bench Press</div>
                                      <div className="text-[10px] text-white/50">4 sets x 8 reps</div>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            )}

                            {activePhoneFeature === 'ai-coach' && (
                              <div className="space-y-3">
                                <div className="flex items-center gap-2 mb-4">
                                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-emerald-500 to-green-500" />
                                  <div>
                                    <div className="text-[12px] text-white font-medium">AI Coach</div>
                                    <div className="text-[9px] text-emerald-400">Online</div>
                                  </div>
                                </div>
                                <div className="bg-[#2d2d2f] rounded-2xl rounded-bl-sm p-3 max-w-[85%]">
                                  <p className="text-[11px] text-white/90 leading-relaxed">
                                    Great work on yesterday's session! Ready for today's upper body workout?
                                  </p>
                                </div>
                                <div className="bg-emerald-500 rounded-2xl rounded-br-sm p-3 max-w-[85%] ml-auto">
                                  <p className="text-[11px] text-white leading-relaxed">
                                    Yes! But my shoulder is a bit sore.
                                  </p>
                                </div>
                              </div>
                            )}

                            {activePhoneFeature === 'tracking' && (
                              <div className="space-y-3">
                                <div className="text-center py-4">
                                  <div className="text-[40px] font-bold text-white">1:32</div>
                                  <div className="text-[11px] text-white/50 uppercase tracking-wider">Rest Timer</div>
                                </div>
                                <div className="bg-[#1d1d1f] rounded-xl p-4">
                                  <div className="flex justify-between items-center mb-3">
                                    <span className="text-[12px] text-white">Set 3 of 4</span>
                                    <span className="text-[12px] text-emerald-400">Completed</span>
                                  </div>
                                  <div className="flex gap-2">
                                    {[1,2,3,4].map(i => (
                                      <div key={i} className={`flex-1 h-1.5 rounded-full ${i <= 3 ? 'bg-emerald-500' : 'bg-white/20'}`} />
                                    ))}
                                  </div>
                                </div>
                              </div>
                            )}

                            {activePhoneFeature === 'videos' && (
                              <div className="space-y-3">
                                <div className="bg-[#1d1d1f] rounded-xl overflow-hidden">
                                  <div className="h-32 bg-gradient-to-br from-gray-700 to-gray-900 flex items-center justify-center">
                                    <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center">
                                      <svg className="w-5 h-5 text-white ml-1" fill="currentColor" viewBox="0 0 24 24">
                                        <path d="M8 5v14l11-7z" />
                                      </svg>
                                    </div>
                                  </div>
                                  <div className="p-3">
                                    <div className="text-[12px] text-white font-medium">Dumbbell Row</div>
                                    <div className="text-[10px] text-white/50">Proper form demonstration</div>
                                  </div>
                                </div>
                              </div>
                            )}

                            {activePhoneFeature === 'analytics' && (
                              <div className="space-y-3">
                                <div className="text-[10px] text-white/40 uppercase tracking-wider">This Week</div>
                                <div className="grid grid-cols-2 gap-2">
                                  <div className="bg-[#1d1d1f] rounded-xl p-3">
                                    <div className="text-[20px] font-bold text-white">4</div>
                                    <div className="text-[10px] text-white/50">Workouts</div>
                                  </div>
                                  <div className="bg-[#1d1d1f] rounded-xl p-3">
                                    <div className="text-[20px] font-bold text-orange-400">12</div>
                                    <div className="text-[10px] text-white/50">Day Streak</div>
                                  </div>
                                </div>
                                <div className="bg-[#1d1d1f] rounded-xl p-3">
                                  <div className="text-[10px] text-white/50 mb-2">Bench Press PR</div>
                                  <div className="text-[16px] font-bold text-emerald-400">185 lbs</div>
                                </div>
                              </div>
                            )}

                            {activePhoneFeature === 'nutrition' && (
                              <div className="space-y-3">
                                <div className="text-[10px] text-white/40 uppercase tracking-wider">Today's Nutrition</div>
                                <div className="flex justify-between">
                                  {[
                                    { label: 'Protein', value: '142g', color: 'bg-emerald-500' },
                                    { label: 'Carbs', value: '185g', color: 'bg-green-500' },
                                    { label: 'Fat', value: '65g', color: 'bg-orange-500' },
                                  ].map(macro => (
                                    <div key={macro.label} className="text-center">
                                      <div className={`w-10 h-10 mx-auto rounded-full ${macro.color}/20 flex items-center justify-center mb-1`}>
                                        <div className={`w-6 h-6 rounded-full ${macro.color}`} />
                                      </div>
                                      <div className="text-[11px] text-white font-medium">{macro.value}</div>
                                      <div className="text-[9px] text-white/50">{macro.label}</div>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}

                            {activePhoneFeature === 'scheduling' && (
                              <div className="space-y-3">
                                <div className="text-[10px] text-white/40 uppercase tracking-wider">This Week</div>
                                <div className="space-y-2">
                                  {['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((day, i) => (
                                    <div key={day} className={`flex items-center gap-3 p-2 rounded-lg ${i === 1 ? 'bg-emerald-500/20 border border-emerald-500/30' : ''}`}>
                                      <span className="text-[11px] text-white/60 w-8">{day}</span>
                                      <span className="text-[11px] text-white">
                                        {['Upper Body', 'Lower Body', 'Rest', 'Push', 'Pull'][i]}
                                      </span>
                                      {i < 2 && <span className="ml-auto text-[9px] text-emerald-400">Done</span>}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}

                            {!activePhoneFeature && (
                              <div className="flex items-center justify-center h-48">
                                <p className="text-[13px] text-white/40">Select a feature</p>
                              </div>
                            )}
                          </motion.div>
                        </AnimatePresence>
                      </div>

                      <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-white/30 rounded-full" />
                    </div>
                  </div>

                  <div
                    className="absolute -bottom-20 left-1/2 -translate-x-1/2 w-48 h-48 rounded-full opacity-20 blur-3xl"
                    style={{
                      background: '#10B981',
                    }}
                  />
                </motion.div>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Feature Gallery Section */}
      <section id="features" className="py-20 sm:py-28 px-6 bg-[var(--color-surface-muted)]">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="flex items-end justify-between mb-8"
          >
            <div>
              <motion.p variants={fade} className="text-[17px] text-[var(--color-text-muted)] mb-2">
                Take a closer look.
              </motion.p>
              <motion.h2
                variants={fadeUp}
                className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em]"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Features that work.
              </motion.h2>
            </div>

            <div className="hidden sm:flex items-center gap-2">
              <button
                onClick={() => scrollGallery('left')}
                className="p-3 rounded-full bg-[var(--color-surface)] hover:bg-[var(--color-surface-elevated)] transition-colors border border-[var(--color-border)]"
                aria-label="Scroll left"
              >
                <svg className="w-5 h-5 text-[var(--color-text)]" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <button
                onClick={() => scrollGallery('right')}
                className="p-3 rounded-full bg-[var(--color-surface)] hover:bg-[var(--color-surface-elevated)] transition-colors border border-[var(--color-border)]"
                aria-label="Scroll right"
              >
                <svg className="w-5 h-5 text-[var(--color-text)]" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          </motion.div>

          <div
            ref={galleryRef}
            className="flex gap-5 overflow-x-auto pb-4 scrollbar-hide snap-x snap-mandatory"
            style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
          >
            {galleryFeatures.map((feature) => (
              <motion.div
                key={feature.id}
                initial={{ opacity: 0, scale: 0.95 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                whileHover={{ scale: 1.02 }}
                transition={{ duration: 0.3 }}
                className="flex-shrink-0 w-[280px] sm:w-[320px] snap-start"
              >
                <div className="h-[360px] p-6 rounded-3xl card-spur flex flex-col">
                  <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${feature.gradient} flex items-center justify-center mb-auto`}>
                    {feature.icon}
                  </div>
                  <div>
                    <h3 className="text-[21px] font-semibold text-[var(--color-text)] mb-1">{feature.title}</h3>
                    <p className="text-[15px] text-[var(--color-text-secondary)]">{feature.subtitle}</p>
                  </div>
                </div>
              </motion.div>
            ))}

            {/* See All Features Card */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              whileHover={{ scale: 1.02 }}
              transition={{ duration: 0.3 }}
              className="flex-shrink-0 w-[280px] sm:w-[320px] snap-start"
            >
              <Link
                to="/features"
                className="h-[360px] p-6 rounded-3xl bg-gradient-to-br from-emerald-900/50 to-green-900/30 border border-emerald-500/20 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center text-center"
              >
                <div className="w-16 h-16 rounded-2xl bg-emerald-500/20 flex items-center justify-center mb-6">
                  <svg className="w-8 h-8 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                  </svg>
                </div>
                <h3 className="text-[21px] font-semibold text-[var(--color-text)] mb-2">See All Features</h3>
                <p className="text-[15px] text-[var(--color-text-secondary)]">Explore 1000+ features</p>
              </Link>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-20 sm:py-28 px-6">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            ref={statsRef}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="grid grid-cols-1 sm:grid-cols-3 gap-8 sm:gap-12"
          >
            {stats.map((stat, index) => {
              const count = useCounter(stat.value, 2000, statsInView);
              return (
                <motion.div key={index} variants={fadeUp} className="text-center">
                  <div className="text-[56px] sm:text-[72px] font-semibold tracking-[-0.02em] leading-none mb-2">
                    <span className="bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent">
                      {count}{stat.suffix}
                    </span>
                  </div>
                  <p className="text-[17px] text-[var(--color-text-secondary)]">{stat.label}</p>
                </motion.div>
              );
            })}
          </motion.div>
        </div>
      </section>

      {/* AI Coach Demo */}
      <section className="py-20 sm:py-28 px-6 bg-[var(--color-surface-muted)]">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center"
          >
            <motion.div variants={fadeUp}>
              <h2
                className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-6"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Your coach,<br />always available.
              </h2>
              <p className="text-[17px] sm:text-[19px] text-[var(--color-text-secondary)] leading-[1.47] mb-8">
                Get instant answers about your training, nutrition, and recovery. Your AI coach knows your goals, schedule, and limitations.
              </p>
              <div className="space-y-4">
                {[
                  'Understands your fitness context',
                  'Analyzes meals from photos',
                  'Suggests exercise alternatives',
                  'Available around the clock',
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <svg className="w-5 h-5 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                    <span className="text-[15px] sm:text-[17px] text-[var(--color-text)]">{item}</span>
                  </div>
                ))}
              </div>
            </motion.div>

            <motion.div variants={fadeUp} ref={chatRef}>
              <div className="p-6 rounded-3xl card-spur">
                <div className="flex items-center gap-3 pb-4 border-b border-[var(--color-border)]">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-500 to-green-500 flex items-center justify-center">
                    <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
                    </svg>
                  </div>
                  <div>
                    <div className="text-[15px] font-medium text-[var(--color-text)]">AI Coach</div>
                    <div className="text-[13px] text-emerald-400 flex items-center gap-1">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                      Online
                    </div>
                  </div>
                </div>

                <div className="py-5 space-y-4 min-h-[180px]">
                  <AnimatePresence>
                    {chatStep >= 1 && (
                      <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="flex justify-end"
                      >
                        <div className="max-w-[80%] px-4 py-2.5 rounded-2xl rounded-br-md bg-emerald-500 text-[15px] text-white">
                          <TypingText
                            text={chatMessages[0].text}
                            onComplete={() => setTimeout(() => setChatStep(2), 500)}
                          />
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>

                  <AnimatePresence>
                    {chatStep >= 2 && (
                      <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="flex justify-start"
                      >
                        <div className="max-w-[85%] px-4 py-2.5 rounded-2xl rounded-bl-md bg-[var(--color-surface-elevated)] text-[15px] text-[var(--color-text)]">
                          <TypingText text={chatMessages[1].text} />
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>

                <div className="pt-4 border-t border-[var(--color-border)]">
                  <Link
                    to="/login"
                    className="block w-full px-4 py-3 rounded-xl bg-[var(--color-surface-elevated)] hover:bg-[var(--color-surface-muted)] text-[15px] text-center text-[var(--color-text-secondary)] hover:text-[var(--color-text)] transition-colors"
                  >
                    Try it yourself
                  </Link>
                </div>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="py-20 sm:py-28 px-6">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="text-center mb-16"
          >
            <motion.h2
              variants={fadeUp}
              className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Start in minutes.
            </motion.h2>
            <motion.p variants={fadeUp} className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)]">
              Three simple steps to your first workout.
            </motion.p>
          </motion.div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-50px' }}
            variants={stagger}
            className="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-12"
          >
            {[
              { num: '1', title: 'Sign up', desc: 'Create your account with Google. Takes seconds.', color: 'from-emerald-500 to-green-400' },
              { num: '2', title: 'Tell us about you', desc: 'Quick conversation to understand your goals.', color: 'from-lime-500 to-green-400' },
              { num: '3', title: 'Start training', desc: 'Get your first AI workout instantly.', color: 'from-teal-500 to-emerald-400' },
            ].map((step, i) => (
              <motion.div
                key={i}
                variants={fadeUp}
                whileHover={{ y: -4 }}
                className="text-center p-8 rounded-3xl card-spur"
              >
                <div className={`inline-flex w-16 h-16 rounded-2xl bg-gradient-to-br ${step.color} items-center justify-center mb-6`}>
                  <span className="text-[28px] font-bold text-white">{step.num}</span>
                </div>
                <h3 className="text-[21px] sm:text-[24px] font-semibold tracking-[-0.01em] mb-2">{step.title}</h3>
                <p className="text-[15px] sm:text-[17px] text-[var(--color-text-secondary)]">{step.desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Why FitWiz Section */}
      <section className="py-20 sm:py-28 px-6 bg-[var(--color-surface-muted)]">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="text-center mb-16"
          >
            <motion.h2
              variants={fadeUp}
              className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              <span className="bg-gradient-to-r from-emerald-400 via-green-400 to-lime-400 bg-clip-text text-transparent">
                Why FitWiz?
              </span>
            </motion.h2>
            <motion.p variants={fadeUp} className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)] max-w-[560px] mx-auto">
              The only fitness app you'll ever need.
            </motion.p>
          </motion.div>

          {/* Comparison Rows */}
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="space-y-4 mb-12"
          >
            {[
              { category: 'AI Workout Generation', apps: { FitWiz: true, Hevy: false, MFP: false, Gravl: true } },
              { category: 'Nutrition + Food Scanning', apps: { FitWiz: true, Hevy: false, MFP: true, Gravl: false } },
              { category: 'Intermittent Fasting', apps: { FitWiz: true, Hevy: false, MFP: false, Gravl: false } },
              { category: 'AI Coach (5 agents)', apps: { FitWiz: true, Hevy: false, MFP: false, Gravl: false } },
              { category: 'All-in-One Platform', apps: { FitWiz: true, Hevy: false, MFP: false, Gravl: false } },
            ].map((row, i) => (
              <motion.div
                key={i}
                variants={fadeUp}
                className="flex items-center gap-4 p-4 rounded-2xl card-spur"
              >
                <span className="text-[15px] text-[var(--color-text)] font-medium w-[200px] flex-shrink-0">{row.category}</span>
                <div className="flex-1 flex items-center justify-around">
                  {Object.entries(row.apps).map(([app, has]) => (
                    <div key={app} className="flex flex-col items-center gap-1 min-w-[60px]">
                      {has ? (
                        <svg className="w-5 h-5 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                      ) : (
                        <svg className="w-5 h-5 text-[var(--color-text-muted)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      )}
                      <span className={`text-[11px] ${app === 'FitWiz' ? 'text-emerald-400 font-medium' : 'text-[var(--color-text-secondary)]'}`}>
                        {app}
                      </span>
                    </div>
                  ))}
                </div>
              </motion.div>
            ))}
          </motion.div>

          {/* Price Comparison Bar */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="p-6 rounded-3xl bg-gradient-to-r from-emerald-900/40 to-green-900/20 border border-emerald-500/20 mb-8"
          >
            <h3 className="text-[17px] font-semibold text-center mb-4 text-[var(--color-text)]">Monthly premium pricing</h3>
            <div className="flex items-end justify-center gap-4 sm:gap-8">
              {[
                { name: 'FitWiz', price: '$5.99', height: 'h-16', highlight: true },
                { name: 'Gravl', price: '$10.99', height: 'h-28', highlight: false },
                { name: 'MacroFactor', price: '$11.99', height: 'h-32', highlight: false },
                { name: 'MFP', price: '$19.99', height: 'h-48', highlight: false },
              ].map((app) => (
                <div key={app.name} className="flex flex-col items-center gap-2">
                  <span className={`text-[13px] font-bold ${app.highlight ? 'text-emerald-400' : 'text-[var(--color-text-muted)]'}`}>
                    {app.price}
                  </span>
                  <div
                    className={`w-12 sm:w-16 ${app.height} rounded-t-xl ${
                      app.highlight
                        ? 'bg-gradient-to-t from-emerald-600 to-emerald-400'
                        : 'bg-[var(--color-surface-muted)]'
                    }`}
                  />
                  <span className={`text-[11px] ${app.highlight ? 'text-emerald-400 font-medium' : 'text-[var(--color-text-secondary)]'}`}>
                    {app.name}
                  </span>
                </div>
              ))}
            </div>
          </motion.div>

          <motion.p
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center text-[15px] text-[var(--color-text-secondary)]"
          >
            <span className="text-emerald-400 font-medium">FitWiz</span> gives you workouts + nutrition + fasting + AI coaching for less than others charge for just one.
          </motion.p>
        </div>
      </section>

      {/* Pricing Preview */}
      <section className="py-20 sm:py-28 px-6">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="text-center mb-12"
          >
            <motion.h2
              variants={fadeUp}
              className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Simple, transparent pricing.
            </motion.h2>
            <motion.p variants={fadeUp} className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)]">
              Start free. Upgrade when you're ready.
            </motion.p>
          </motion.div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-[700px] mx-auto"
          >
            {[
              { name: 'Free', price: '$0', period: 'forever', features: ['1,722 exercises with videos', 'Unlimited workout logging', 'Barcode scanner & food logging', '5 AI chat messages/day', 'No ads, ever'], highlight: false },
              { name: 'Premium', price: '$5.99', period: '/month', features: ['Unlimited AI chat (5 agents)', 'AI workout generation', 'AI photo food scanning', 'Advanced analytics & heatmaps', 'All 10 fasting protocols'], highlight: true },
            ].map((plan, i) => (
              <motion.div
                key={i}
                variants={fadeUp}
                className={`p-6 rounded-3xl transition-all ${
                  plan.highlight
                    ? 'bg-gradient-to-br from-emerald-900/50 to-green-900/30 border-2 border-emerald-500/50'
                    : 'card-spur'
                }`}
              >
                <h3 className="text-[21px] font-semibold text-[var(--color-text)] mb-2">{plan.name}</h3>
                <div className="flex items-baseline gap-1 mb-6">
                  <span className="text-[40px] font-bold text-[var(--color-text)]">{plan.price}</span>
                  <span className="text-[15px] text-[var(--color-text-secondary)]">{plan.period}</span>
                </div>
                <ul className="space-y-3 mb-6">
                  {plan.features.map((feature, j) => (
                    <li key={j} className="flex items-center gap-2 text-[15px] text-[var(--color-text-secondary)]">
                      <svg className="w-4 h-4 text-emerald-400 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                      </svg>
                      {feature}
                    </li>
                  ))}
                </ul>
                <Link
                  to="/pricing"
                  className={`block w-full py-3 rounded-xl text-center text-[15px] font-medium transition-colors ${
                    plan.highlight
                      ? 'bg-emerald-500 text-white hover:bg-emerald-400'
                      : 'bg-[var(--color-surface-elevated)] text-[var(--color-text)] hover:bg-[var(--color-surface-muted)]'
                  }`}
                >
                  {plan.name === 'Free' ? 'Get Started' : 'Start Free Trial'}
                </Link>
              </motion.div>
            ))}
          </motion.div>

          <motion.div
            variants={fadeUp}
            className="text-center mt-8"
          >
            <Link to="/pricing" className="text-emerald-400 hover:underline text-[15px]">
              See full pricing details
            </Link>
          </motion.div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-20 sm:py-32 px-6">
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="max-w-[680px] mx-auto text-center"
        >
          <motion.h2
            variants={fadeUp}
            className="text-[40px] sm:text-[56px] md:text-[64px] font-semibold tracking-[-0.02em] leading-[1.05] mb-6"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Start training<br />smarter today.
          </motion.h2>
          <motion.div variants={fadeUp}>
            <Link
              to="/login"
              className="inline-flex px-8 py-3.5 bg-emerald-500 text-white text-[17px] rounded-full hover:bg-emerald-400 transition-colors"
            >
              Get started free
            </Link>
            <p className="mt-5 text-[13px] text-[var(--color-text-secondary)]">No credit card required.</p>
          </motion.div>
        </motion.div>
      </section>

      {/* Footer */}
      <MarketingFooter />
    </div>
  );
}
