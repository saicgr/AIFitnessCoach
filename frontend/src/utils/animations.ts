/**
 * Shared Framer Motion animation variants
 *
 * Premium, production-grade animations matching Apple Fitness / Fitbod style
 */
import type { Variants } from 'framer-motion';

// Timing constants for consistent feel
export const TIMING = {
  fast: 0.15,
  normal: 0.2,
  slow: 0.3,
  stagger: 0.05,
};

// Spring configurations
export const SPRING = {
  snappy: { type: 'spring', stiffness: 400, damping: 30 },
  gentle: { type: 'spring', stiffness: 300, damping: 25 },
  bouncy: { type: 'spring', stiffness: 500, damping: 20 },
} as const;

// ===== SIDEBAR ANIMATIONS =====

export const sidebarVariants: Variants = {
  hidden: { x: -80, opacity: 0 },
  visible: {
    x: 0,
    opacity: 1,
    transition: {
      duration: TIMING.slow,
      ease: [0.22, 1, 0.36, 1],
      staggerChildren: TIMING.stagger,
      delayChildren: 0.1,
    },
  },
};

export const sidebarItemVariants: Variants = {
  hidden: { x: -20, opacity: 0 },
  visible: {
    x: 0,
    opacity: 1,
    transition: { duration: TIMING.normal, ease: 'easeOut' },
  },
};

export const sidebarHover = {
  scale: 1.08,
  transition: SPRING.snappy,
};

export const sidebarTap = {
  scale: 0.95,
};

// ===== CARD ANIMATIONS =====

export const cardVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: TIMING.normal,
      ease: [0.22, 1, 0.36, 1],
    },
  },
};

export const cardHover = {
  y: -4,
  transition: { duration: TIMING.fast, ease: 'easeOut' },
};

export const workoutCardVariants: Variants = {
  hidden: { opacity: 0, scale: 0.95, y: 15 },
  visible: {
    opacity: 1,
    scale: 1,
    y: 0,
    transition: {
      duration: TIMING.normal,
      ease: [0.22, 1, 0.36, 1],
    },
  },
};

export const workoutCardHover = {
  scale: 1.02,
  boxShadow: '0 8px 30px rgba(6, 182, 212, 0.15)',
  transition: { duration: TIMING.fast, ease: 'easeOut' },
};

// ===== BUTTON ANIMATIONS =====

export const buttonVariants: Variants = {
  initial: { scale: 1 },
  hover: {
    scale: 1.05,
    transition: SPRING.snappy,
  },
  tap: {
    scale: 0.95,
    transition: { duration: 0.1 },
  },
};

export const iconButtonVariants: Variants = {
  initial: { scale: 1, rotate: 0 },
  hover: {
    scale: 1.1,
    transition: SPRING.snappy,
  },
  tap: {
    scale: 0.9,
    transition: { duration: 0.1 },
  },
};

export const addButtonVariants: Variants = {
  initial: { scale: 1, rotate: 0 },
  hover: {
    scale: 1.05,
    rotate: 90,
    transition: { ...SPRING.gentle, rotate: { duration: TIMING.normal } },
  },
  tap: {
    scale: 0.95,
    transition: { duration: 0.1 },
  },
};

// ===== LIST / STAGGER ANIMATIONS =====

export const staggerContainerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: TIMING.stagger,
      delayChildren: 0.1,
    },
  },
};

export const fadeInUpVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: TIMING.normal,
      ease: [0.22, 1, 0.36, 1],
    },
  },
};

// ===== HEADER TOOLBAR ANIMATIONS =====

export const toolbarVariants: Variants = {
  hidden: { opacity: 0, y: -15 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: TIMING.normal,
      ease: [0.22, 1, 0.36, 1],
      staggerChildren: TIMING.stagger,
    },
  },
};

export const toolbarItemVariants: Variants = {
  hidden: { opacity: 0, y: -10, scale: 0.9 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { duration: TIMING.fast, ease: 'easeOut' },
  },
};

// ===== DRAG & DROP ANIMATIONS =====

export const dragItemVariants: Variants = {
  idle: {
    scale: 1,
    boxShadow: '0 0 0 rgba(0, 0, 0, 0)',
    zIndex: 0,
  },
  dragging: {
    scale: 1.03,
    boxShadow: '0 15px 30px rgba(0, 0, 0, 0.3)',
    zIndex: 50,
    transition: SPRING.snappy,
  },
};

export const dropPlaceholderVariants: Variants = {
  hidden: { opacity: 0, height: 0 },
  visible: {
    opacity: 1,
    height: 'auto',
    transition: { duration: TIMING.fast, ease: 'easeOut' },
  },
};

// ===== BADGE / INDICATOR ANIMATIONS =====

export const badgePulseVariants: Variants = {
  initial: { scale: 1, opacity: 1 },
  pulse: {
    scale: [1, 1.15, 1],
    opacity: [1, 0.8, 1],
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

export const glowPulseVariants: Variants = {
  initial: { boxShadow: '0 0 0 rgba(6, 182, 212, 0)' },
  glow: {
    boxShadow: [
      '0 0 0 rgba(6, 182, 212, 0)',
      '0 0 20px rgba(6, 182, 212, 0.4)',
      '0 0 0 rgba(6, 182, 212, 0)',
    ],
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

// ===== DAY CARD ANIMATIONS =====

export const dayCardVariants: Variants = {
  hidden: { opacity: 0, x: -20 },
  visible: {
    opacity: 1,
    x: 0,
    transition: {
      duration: TIMING.normal,
      ease: [0.22, 1, 0.36, 1],
    },
  },
};

export const restDayBadgeVariants: Variants = {
  hidden: { opacity: 0, scale: 0.9 },
  visible: {
    opacity: 1,
    scale: 1,
    transition: { duration: TIMING.normal, ease: 'easeOut' },
  },
};

// ===== TODAY INDICATOR ANIMATIONS =====

export const todayDotVariants: Variants = {
  initial: { scale: 1 },
  pulse: {
    scale: [1, 1.3, 1],
    boxShadow: [
      '0 0 8px rgba(6, 182, 212, 0.5)',
      '0 0 16px rgba(6, 182, 212, 0.8)',
      '0 0 8px rgba(6, 182, 212, 0.5)',
    ],
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

// ===== ACTIVE INDICATOR ANIMATIONS =====

export const activeIndicatorVariants: Variants = {
  hidden: { opacity: 0, x: -4, height: 0 },
  visible: {
    opacity: 1,
    x: 0,
    height: 32,
    transition: { duration: TIMING.fast, ease: 'easeOut' },
  },
};

// ===== TOOLTIP ANIMATIONS =====

export const tooltipVariants: Variants = {
  hidden: { opacity: 0, x: 8, scale: 0.95 },
  visible: {
    opacity: 1,
    x: 0,
    scale: 1,
    transition: { duration: TIMING.fast, ease: 'easeOut' },
  },
};
