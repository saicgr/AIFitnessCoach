/**
 * Sidebar - Premium fixed left navigation sidebar (Desktop only)
 *
 * Features:
 * - Fixed vertical sidebar with icons + labels
 * - Premium spacing and hover states with Framer Motion animations
 * - Active state indication with glow pulse
 * - Glassmorphism styling
 * - Slide-in entrance animation
 */
import { Link, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
  sidebarVariants,
  sidebarItemVariants,
  sidebarHover,
  sidebarTap,
  activeIndicatorVariants,
} from '../../utils/animations';
import { useAppStore } from '../../store';

interface NavItem {
  path: string;
  label: string;
  icon: React.ReactNode;
  activeColor: string;
  glowColor: string;
  isWidget?: boolean;  // If true, clicking opens widget instead of navigating
}

const navItems: NavItem[] = [
  {
    path: '/home',
    label: 'Schedule',
    activeColor: 'text-primary',
    glowColor: 'rgba(6, 182, 212, 0.4)',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
      </svg>
    ),
  },
  {
    path: '/metrics',
    label: 'Metrics',
    activeColor: 'text-accent',
    glowColor: 'rgba(16, 185, 129, 0.4)',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
      </svg>
    ),
  },
  {
    path: '/nutrition',
    label: 'Nutrition',
    activeColor: 'text-orange',
    glowColor: 'rgba(249, 115, 22, 0.4)',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.879 16.121A3 3 0 1012.015 11L11 14H9c0 .768.293 1.536.879 2.121z" />
      </svg>
    ),
  },
  {
    path: '/library',
    label: 'Library',
    activeColor: 'text-blue-400',
    glowColor: 'rgba(96, 165, 250, 0.4)',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
      </svg>
    ),
  },
  {
    path: '/achievements',
    label: 'Achievements',
    activeColor: 'text-yellow-400',
    glowColor: 'rgba(250, 204, 21, 0.4)',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
      </svg>
    ),
  },
  {
    path: '/chat',
    label: 'AI Coach',
    activeColor: 'text-secondary',
    glowColor: 'rgba(168, 85, 247, 0.4)',
    isWidget: true,  // Opens chat widget instead of navigating
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>
    ),
  },
  {
    path: '/profile',
    label: 'Profile',
    activeColor: 'text-pink-400',
    glowColor: 'rgba(236, 72, 153, 0.4)',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
      </svg>
    ),
  },
];

export default function Sidebar() {
  const location = useLocation();
  const { chatWidgetState, setChatWidgetOpen } = useAppStore();

  const handleItemClick = (item: NavItem) => {
    if (item.isWidget) {
      // Toggle the chat widget open
      setChatWidgetOpen(true);
    }
    // For non-widget items, the Link handles navigation
  };

  return (
    <motion.aside
      className="hidden lg:flex fixed left-0 top-0 h-screen w-20 flex-col items-center py-8 bg-surface/80 backdrop-blur-xl border-r border-white/5 z-40"
      variants={sidebarVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Logo */}
      <motion.div
        className="mb-10"
        variants={sidebarItemVariants}
      >
        <motion.div
          className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-lg shadow-primary/20"
          whileHover={{ scale: 1.1, rotate: 5 }}
          whileTap={{ scale: 0.95 }}
          transition={{ type: 'spring', stiffness: 400, damping: 20 }}
        >
          <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        </motion.div>
      </motion.div>

      {/* Navigation Items */}
      <nav className="flex-1 flex flex-col items-center gap-2">
        {navItems.map((item) => {
          const isActive = item.isWidget ? chatWidgetState.isOpen : location.pathname === item.path;

          // Common content for the nav item
          const navContent = (
            <motion.div
              className={`
                group relative flex flex-col items-center justify-center
                w-14 h-14 rounded-2xl transition-colors
                ${isActive
                  ? `bg-white/10 ${item.activeColor}`
                  : 'text-text-muted hover:text-text-secondary'
                }
              `}
              whileHover={!isActive ? sidebarHover : { scale: 1.02 }}
              whileTap={sidebarTap}
              animate={isActive ? {
                boxShadow: [
                  `0 0 0 ${item.glowColor}`,
                  `0 0 20px ${item.glowColor}`,
                  `0 0 0 ${item.glowColor}`,
                ],
              } : {}}
              transition={isActive ? {
                boxShadow: { duration: 2, repeat: Infinity, ease: 'easeInOut' }
              } : undefined}
            >
              {/* Active indicator */}
              <AnimatePresence>
                {isActive && (
                  <motion.div
                    className="absolute left-0 top-1/2 -translate-y-1/2 w-1 bg-primary rounded-r-full"
                    variants={activeIndicatorVariants}
                    initial="hidden"
                    animate="visible"
                    exit="hidden"
                  />
                )}
              </AnimatePresence>

              {item.icon}

              {/* Label - shows on hover with animation */}
              <AnimatePresence>
                <motion.span
                  className={`
                    absolute left-full ml-4 px-3 py-1.5 rounded-lg
                    bg-surface border border-white/10 shadow-xl
                    text-sm font-medium text-text whitespace-nowrap
                    pointer-events-none
                    opacity-0 invisible group-hover:opacity-100 group-hover:visible
                  `}
                  initial={{ opacity: 0, x: 8, scale: 0.95 }}
                  whileHover={{ opacity: 1, x: 0, scale: 1 }}
                >
                  {item.label}
                </motion.span>
              </AnimatePresence>
            </motion.div>
          );

          return (
            <motion.div
              key={item.path}
              variants={sidebarItemVariants}
              className="relative"
            >
              {item.isWidget ? (
                // Widget items use a button that opens the widget
                <button
                  onClick={() => handleItemClick(item)}
                  className="block"
                  title={item.label}
                >
                  {navContent}
                </button>
              ) : (
                // Regular nav items use Link for navigation
                <Link
                  to={item.path}
                  className="block"
                  title={item.label}
                >
                  {navContent}
                </Link>
              )}
            </motion.div>
          );
        })}
      </nav>

      {/* Bottom section - settings shortcut */}
      <motion.div
        className="mt-auto pt-4 border-t border-white/5"
        variants={sidebarItemVariants}
      >
        <Link to="/settings" title="Settings">
          <motion.div
            className="w-10 h-10 rounded-full bg-gradient-to-br from-white/10 to-white/5 flex items-center justify-center cursor-pointer"
            whileHover={{ scale: 1.15, rotate: 90 }}
            whileTap={{ scale: 0.9 }}
            transition={{ type: 'spring', stiffness: 400, damping: 20 }}
          >
            <svg className="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </motion.div>
        </Link>
      </motion.div>
    </motion.aside>
  );
}
