import type { Workout } from '../types';

export interface TimelineDay {
  date: Date;
  dateString: string; // ISO date string YYYY-MM-DD
  dayName: string; // "Thu", "Fri", "Sat"
  dayNumber: number; // 9, 10, 11
  isToday: boolean;
  isPast: boolean;
  workout: Workout | null;
}

/**
 * Format date to short day name (Mon, Tue, etc.)
 */
export const formatDayName = (date: Date): string => {
  return date.toLocaleDateString('en-US', { weekday: 'short' });
};

/**
 * Get day of month number
 */
export const getDayNumber = (date: Date): number => {
  return date.getDate();
};

/**
 * Check if a date is today
 */
export const isToday = (date: Date): boolean => {
  const today = new Date();
  return isSameDay(date, today);
};

/**
 * Check if a date is in the past
 */
export const isPastDate = (date: Date): boolean => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const compareDate = new Date(date);
  compareDate.setHours(0, 0, 0, 0);
  return compareDate < today;
};

/**
 * Check if two dates are the same day
 */
export const isSameDay = (date1: Date, date2: Date): boolean => {
  return (
    date1.getFullYear() === date2.getFullYear() &&
    date1.getMonth() === date2.getMonth() &&
    date1.getDate() === date2.getDate()
  );
};

/**
 * Get ISO date string (YYYY-MM-DD) from Date
 */
export const toDateString = (date: Date): string => {
  return date.toISOString().split('T')[0];
};

/**
 * Parse ISO date string to Date object
 */
export const parseDate = (dateString: string): Date => {
  // Handle both ISO datetime and date-only strings
  const date = new Date(dateString);
  return date;
};

/**
 * Group workouts by their scheduled date
 */
export const groupWorkoutsByDate = (workouts: Workout[]): Map<string, Workout[]> => {
  const map = new Map<string, Workout[]>();

  workouts.forEach((workout) => {
    if (workout.scheduled_date) {
      const dateKey = workout.scheduled_date.split('T')[0];
      const existing = map.get(dateKey) || [];
      map.set(dateKey, [...existing, workout]);
    }
  });

  return map;
};

/**
 * Generate timeline days with workouts
 * Shows past N days + today + next M days
 */
export const generateTimelineDays = (
  workouts: Workout[],
  pastDays: number = 7,
  futureDays: number = 7
): TimelineDay[] => {
  const workoutsByDate = groupWorkoutsByDate(workouts);
  const days: TimelineDay[] = [];
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Generate dates from past to future
  for (let i = -pastDays; i <= futureDays; i++) {
    const date = new Date(today);
    date.setDate(today.getDate() + i);
    const dateString = toDateString(date);

    // Get first workout for this day (if any)
    const dayWorkouts = workoutsByDate.get(dateString) || [];
    const workout = dayWorkouts[0] || null;

    days.push({
      date,
      dateString,
      dayName: formatDayName(date),
      dayNumber: getDayNumber(date),
      isToday: i === 0,
      isPast: i < 0,
      workout,
    });
  }

  return days;
};

/**
 * Format duration in minutes to display string
 */
export const formatDuration = (minutes: number): string => {
  // Handle invalid input (undefined, null, NaN, negative)
  if (!Number.isFinite(minutes) || minutes < 0) {
    return '-- min';
  }
  if (minutes < 60) {
    return `${minutes} min`;
  }
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
};

/**
 * Get a friendly date label
 */
export const getDateLabel = (date: Date): string => {
  if (isToday(date)) return 'Today';

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  if (isSameDay(date, tomorrow)) return 'Tomorrow';

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  if (isSameDay(date, yesterday)) return 'Yesterday';

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

/**
 * Check if a date is within this week (Sunday to Saturday)
 */
export const isThisWeek = (date: Date): boolean => {
  const now = new Date();
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay()); // Start of week (Sunday)
  startOfWeek.setHours(0, 0, 0, 0);

  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 6); // End of week (Saturday)
  endOfWeek.setHours(23, 59, 59, 999);

  return date >= startOfWeek && date <= endOfWeek;
};

/**
 * Get yesterday's date
 */
export const getYesterday = (): Date => {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);
  return yesterday;
};

/**
 * Get tomorrow's date
 */
export const getTomorrow = (): Date => {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);
  return tomorrow;
};

/**
 * Get today's date at midnight
 */
export const getTodayStart = (): Date => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return today;
};

/**
 * Get the start of the week (Sunday) for a given date
 */
export const getStartOfWeek = (date: Date): Date => {
  const d = new Date(date);
  const day = d.getDay(); // 0 = Sunday, 1 = Monday, etc.
  const diff = d.getDate() - day; // Go back to Sunday
  d.setDate(diff);
  d.setHours(0, 0, 0, 0);
  return d;
};

/**
 * Get the end of the week (Saturday) for a given date
 */
export const getEndOfWeek = (date: Date): Date => {
  const start = getStartOfWeek(date);
  const end = new Date(start);
  end.setDate(start.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return end;
};

/**
 * Generate an array of 7 dates for a week (Sunday to Saturday)
 * @param weekOffset 0 = current week, -1 = last week, 1 = next week
 */
export const getWeekDates = (weekOffset: number = 0): Date[] => {
  const today = new Date();
  const startOfWeek = getStartOfWeek(today);
  startOfWeek.setDate(startOfWeek.getDate() + (weekOffset * 7));

  return Array.from({ length: 7 }, (_, i) => {
    const date = new Date(startOfWeek);
    date.setDate(startOfWeek.getDate() + i);
    return date;
  });
};

/**
 * Format week range for display
 * @param weekDates Array of dates for the week
 * @returns Formatted string like "Nov 18 - Nov 24, 2024"
 */
export const formatWeekRange = (weekDates: Date[]): string => {
  if (weekDates.length === 0) return '';

  const start = weekDates[0];
  const end = weekDates[weekDates.length - 1];

  const startMonth = start.toLocaleDateString('en-US', { month: 'short' });
  const startDay = start.getDate();
  const endMonth = end.toLocaleDateString('en-US', { month: 'short' });
  const endDay = end.getDate();
  const year = end.getFullYear();

  if (startMonth === endMonth) {
    return `${startMonth} ${startDay} - ${endDay}, ${year}`;
  }

  return `${startMonth} ${startDay} - ${endMonth} ${endDay}, ${year}`;
};

/**
 * Format date as "Monday, Nov 25"
 */
export const formatDateWithDay = (date: Date): string => {
  const dayName = date.toLocaleDateString('en-US', { weekday: 'long' });
  const month = date.toLocaleDateString('en-US', { month: 'short' });
  const day = date.getDate();
  return `${dayName}, ${month} ${day}`;
};
