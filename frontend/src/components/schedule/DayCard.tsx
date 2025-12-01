/**
 * DayCard - Premium day container for the schedule
 *
 * Features:
 * - Clean rounded design with subtle shadows
 * - Today/Past/Future state styling
 * - Rest day variant with soft badge
 * - Consistent spacing and typography
 */
import { ReactNode } from 'react';

interface DayCardProps {
  date: Date;
  isToday: boolean;
  isPast: boolean;
  children: ReactNode;
}

export default function DayCard({ date, isToday, isPast, children }: DayCardProps) {
  const dayName = date.toLocaleDateString('en-US', { weekday: 'short' });
  const dayNumber = date.getDate();
  const monthName = date.toLocaleDateString('en-US', { month: 'short' });

  return (
    <div className={`
      group flex gap-4 lg:gap-6 items-start
      ${isToday ? 'relative' : ''}
    `}>
      {/* Day Column */}
      <div className={`
        flex flex-col items-center w-16 lg:w-20 flex-shrink-0 pt-1
        ${isToday ? 'text-primary' : isPast ? 'text-text-muted' : 'text-text-secondary'}
      `}>
        <span className={`
          text-xs font-medium uppercase tracking-wider
          ${isToday ? 'text-primary' : ''}
        `}>
          {dayName}
        </span>
        <span className={`
          text-2xl lg:text-3xl font-bold mt-0.5
          ${isToday ? 'text-primary' : 'text-text'}
        `}>
          {dayNumber}
        </span>
        <span className={`
          text-xs
          ${isToday ? 'text-primary/70' : 'text-text-muted'}
        `}>
          {monthName}
        </span>

        {/* Today indicator dot */}
        {isToday && (
          <div className="w-2 h-2 rounded-full bg-primary mt-2 shadow-[0_0_8px_rgba(6,182,212,0.5)]" />
        )}
      </div>

      {/* Content Area */}
      <div className="flex-1 min-w-0">
        {children}
      </div>
    </div>
  );
}

// Rest Day component that goes inside DayCard
interface RestDayBadgeProps {
  isToday: boolean;
  isPast: boolean;
  onAddWorkout: () => void;
  isGenerating?: boolean;
}

export function RestDayBadge({ isToday, isPast, onAddWorkout, isGenerating = false }: RestDayBadgeProps) {
  // Show generating placeholder
  if (isGenerating && !isPast) {
    return (
      <div className="p-4 lg:p-5 rounded-2xl border-2 border-dashed border-primary/30 bg-primary/5">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary/20 flex items-center justify-center">
            <svg className="w-5 h-5 text-primary animate-spin" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
          </div>
          <span className="text-primary font-medium">Generating workout...</span>
        </div>
      </div>
    );
  }

  return (
    <div className={`
      group/rest p-4 lg:p-5 rounded-2xl border-2 border-dashed transition-all duration-200
      ${isToday
        ? 'border-primary/30 bg-primary/5 hover:border-primary/50'
        : isPast
        ? 'border-white/5 bg-white/[0.02]'
        : 'border-white/10 bg-white/[0.02] hover:border-white/20'
      }
    `}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className={`
            w-10 h-10 rounded-xl flex items-center justify-center
            ${isToday ? 'bg-primary/20' : 'bg-white/5'}
          `}>
            <svg
              className={`w-5 h-5 ${isToday ? 'text-primary' : 'text-text-muted'}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
          </div>
          <div>
            <span className={`
              font-medium
              ${isToday ? 'text-primary' : isPast ? 'text-text-muted' : 'text-text-secondary'}
            `}>
              Rest Day
            </span>
            {!isPast && (
              <p className="text-xs text-text-muted mt-0.5">Recovery time</p>
            )}
          </div>
        </div>

        {/* Add workout button */}
        {!isPast && (
          <button
            onClick={onAddWorkout}
            className={`
              flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium
              transition-all duration-200
              ${isToday
                ? 'bg-primary/20 text-primary hover:bg-primary/30'
                : 'bg-white/5 text-text-secondary hover:bg-white/10 hover:text-text opacity-0 group-hover/rest:opacity-100'
              }
            `}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            <span className="hidden sm:inline">Add</span>
          </button>
        )}
      </div>
    </div>
  );
}
