/**
 * DayCard - Premium day container for the schedule
 *
 * Features:
 * - Clean rounded design with subtle shadows
 * - Today/Past/Future state styling
 * - Rest day variant with soft badge
 * - Consistent spacing and typography
 * - Framer Motion animations for fade-in and hover
 */
import type { ReactNode } from 'react';
import { motion } from 'framer-motion';
import {
  dayCardVariants,
  todayDotVariants,
  restDayBadgeVariants,
  buttonVariants,
} from '../../utils/animations';

interface DayCardProps {
  date: Date;
  isToday: boolean;
  isPast: boolean;
  children: ReactNode;
  index?: number; // For stagger animation
}

export default function DayCard({ date, isToday, isPast, children, index = 0 }: DayCardProps) {
  const dayName = date.toLocaleDateString('en-US', { weekday: 'short' });
  const dayNumber = date.getDate();
  const monthName = date.toLocaleDateString('en-US', { month: 'short' });

  return (
    <motion.div
      className={`
        group flex gap-4 lg:gap-6 items-start
        ${isToday ? 'relative' : ''}
      `}
      variants={dayCardVariants}
      initial="hidden"
      animate="visible"
      transition={{ delay: index * 0.05 }}
      whileHover={{ x: 4 }}
    >
      {/* Day Column */}
      <motion.div
        className={`
          flex flex-col items-center w-16 lg:w-20 flex-shrink-0 pt-1
          ${isToday ? 'text-primary' : isPast ? 'text-text-muted' : 'text-text-secondary'}
        `}
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: index * 0.05 + 0.1, duration: 0.2 }}
      >
        <span className={`
          text-xs font-medium uppercase tracking-wider
          ${isToday ? 'text-primary' : ''}
        `}>
          {dayName}
        </span>
        <motion.span
          className={`
            text-2xl lg:text-3xl font-bold mt-0.5
            ${isToday ? 'text-primary' : 'text-text'}
          `}
          whileHover={{ scale: 1.1 }}
          transition={{ type: 'spring', stiffness: 400, damping: 20 }}
        >
          {dayNumber}
        </motion.span>
        <span className={`
          text-xs
          ${isToday ? 'text-primary/70' : 'text-text-muted'}
        `}>
          {monthName}
        </span>

        {/* Today indicator dot with pulse animation */}
        {isToday && (
          <motion.div
            className="w-2 h-2 rounded-full bg-primary mt-2"
            variants={todayDotVariants}
            initial="initial"
            animate="pulse"
          />
        )}
      </motion.div>

      {/* Content Area */}
      <motion.div
        className="flex-1 min-w-0"
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ delay: index * 0.05 + 0.15, duration: 0.25 }}
      >
        {children}
      </motion.div>
    </motion.div>
  );
}

// Rest Day component that goes inside DayCard
interface RestDayBadgeProps {
  isToday: boolean;
  isPast: boolean;
  onAddWorkout: () => void;
  isGenerating?: boolean;
  compact?: boolean;
}

export function RestDayBadge({ isToday, isPast, onAddWorkout, isGenerating = false, compact = false }: RestDayBadgeProps) {
  // Show generating placeholder
  if (isGenerating && !isPast) {
    return (
      <motion.div
        className="p-4 lg:p-5 rounded-2xl border-2 border-dashed border-primary/30 bg-primary/5"
        variants={restDayBadgeVariants}
        initial="hidden"
        animate="visible"
      >
        <div className="flex items-center gap-3">
          <motion.div
            className="w-10 h-10 rounded-xl bg-primary/20 flex items-center justify-center"
            animate={{ rotate: 360 }}
            transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
          >
            <svg className="w-5 h-5 text-primary" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
          </motion.div>
          <motion.span
            className="text-primary font-medium"
            animate={{ opacity: [1, 0.6, 1] }}
            transition={{ duration: 1.5, repeat: Infinity }}
          >
            Generating workout...
          </motion.span>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      className={`
        group/rest rounded-2xl border-2 border-dashed transition-colors duration-200
        ${compact ? 'p-3' : 'p-4 lg:p-5'}
        ${isToday
          ? 'border-primary/30 bg-primary/5 hover:border-primary/50'
          : isPast
          ? 'border-white/5 bg-white/[0.02]'
          : 'border-white/10 bg-white/[0.02] hover:border-white/20'
        }
      `}
      variants={restDayBadgeVariants}
      initial="hidden"
      animate="visible"
      whileHover={!isPast ? { scale: 1.01, y: -2 } : {}}
      transition={{ type: 'spring', stiffness: 400, damping: 25 }}
    >
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0">
          <motion.div
            className={`
              flex-shrink-0 rounded-xl flex items-center justify-center
              ${compact ? 'w-8 h-8' : 'w-10 h-10'}
              ${isToday ? 'bg-primary/20' : 'bg-white/5'}
            `}
            whileHover={{ scale: 1.1, rotate: 5 }}
            transition={{ type: 'spring', stiffness: 400, damping: 20 }}
          >
            <svg
              className={`${compact ? 'w-4 h-4' : 'w-5 h-5'} ${isToday ? 'text-primary' : 'text-text-muted'}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
          </motion.div>
          <span className={`
            font-medium whitespace-nowrap
            ${compact ? 'text-sm' : ''}
            ${isToday ? 'text-primary' : isPast ? 'text-text-muted' : 'text-text-secondary'}
          `}>
            Rest Day
          </span>
        </div>

        {/* Add workout button with animation - icon only in compact mode */}
        {!isPast && (
          <motion.button
            onClick={onAddWorkout}
            className={`
              flex-shrink-0 flex items-center justify-center rounded-xl text-sm font-medium
              transition-colors duration-200
              ${compact ? 'w-8 h-8' : 'gap-2 px-4 py-2'}
              ${isToday
                ? 'bg-primary/20 text-primary hover:bg-primary/30'
                : 'bg-white/5 text-text-secondary hover:bg-white/10 hover:text-text'
              }
            `}
            variants={buttonVariants}
            initial="initial"
            whileHover="hover"
            whileTap="tap"
          >
            <motion.svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              whileHover={{ rotate: 90 }}
              transition={{ duration: 0.2 }}
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </motion.svg>
            {!compact && <span className="hidden sm:inline">Add</span>}
          </motion.button>
        )}
      </div>
    </motion.div>
  );
}
