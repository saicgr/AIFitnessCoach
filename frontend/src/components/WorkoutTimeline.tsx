import { useState } from 'react';
import { Link } from 'react-router-dom';
import type { Workout } from '../types';
import {
  getWeekDates,
  formatWeekRange,
  toDateString,
  isToday as checkIsToday,
  isPastDate,
  formatDuration
} from '../utils/dateUtils';

interface WorkoutTimelineProps {
  workouts: Workout[];
  isLoading: boolean;
  onGenerateWorkout: () => void;
}

interface WorkoutCardProps {
  workout: Workout;
  isToday: boolean;
  isPast: boolean;
}

function WorkoutCard({ workout, isToday, isPast }: WorkoutCardProps) {
  const isCompleted = !!workout.completed_at;

  return (
    <Link
      to={`/workout/${workout.id}`}
      className={`block p-4 rounded-xl border-2 transition-all hover:shadow-md ${
        isToday
          ? 'border-primary/50 bg-primary/5'
          : isCompleted
          ? 'border-secondary/30 bg-secondary/5'
          : isPast
          ? 'border-gray-200 bg-gray-50'
          : 'border-gray-200 bg-white'
      }`}
    >
      <div className="flex items-center justify-between">
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-gray-900 truncate">{workout.name}</h3>
          <p className="text-sm text-gray-600 mt-1 capitalize">{workout.type}</p>

          <div className="mt-2 flex items-center gap-3 text-xs text-gray-500">
            <span className="flex items-center gap-1">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {formatDuration(workout.duration_minutes)}
            </span>
            <span>{workout.exercises.length} exercises</span>
            <span className="capitalize">{workout.difficulty}</span>
          </div>
        </div>

        {/* Status badge */}
        {isCompleted ? (
          <div className="flex-shrink-0 ml-3">
            <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center">
              <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
        ) : isPast && !isCompleted ? (
          <div className="flex-shrink-0 ml-3">
            <div className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center">
              <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
          </div>
        ) : null}
      </div>
    </Link>
  );
}

interface RestDayCardProps {
  isToday: boolean;
  isPast: boolean;
  onAddWorkout: () => void;
}

function RestDayCard({ isToday, isPast, onAddWorkout }: RestDayCardProps) {
  if (isToday) {
    return (
      <div className="p-4 rounded-xl border-2 border-dashed border-primary/30 bg-primary/5">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <svg className="w-5 h-5 text-primary/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <span className="text-gray-600 font-medium">Rest Day</span>
          </div>
          <button
            onClick={onAddWorkout}
            className="text-primary text-sm font-medium hover:underline"
          >
            + Add Workout
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className={`p-4 rounded-xl border-2 border-dashed ${
      isPast ? 'border-gray-200 bg-gray-50' : 'border-gray-200 bg-white'
    }`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
          </svg>
          <span className="text-gray-400 text-sm italic">
            {isPast ? 'Rest Day' : 'Rest Day'}
          </span>
        </div>
        {!isPast && (
          <button
            onClick={onAddWorkout}
            className="text-gray-500 text-sm hover:text-primary transition-colors"
          >
            + Add
          </button>
        )}
      </div>
    </div>
  );
}

export default function WorkoutTimeline({ workouts, isLoading, onGenerateWorkout }: WorkoutTimelineProps) {
  const [weekOffset, setWeekOffset] = useState(0);

  // Generate week dates (Monday to Sunday)
  const weekDates = getWeekDates(weekOffset);

  // Group workouts by date for quick lookup
  const workoutsByDate = new Map<string, Workout>();
  workouts.forEach((workout) => {
    if (workout.scheduled_date) {
      const dateKey = workout.scheduled_date.split('T')[0];
      // Keep first workout if multiple on same day
      if (!workoutsByDate.has(dateKey)) {
        workoutsByDate.set(dateKey, workout);
      }
    }
  });

  // Get workout for a specific date
  const getWorkoutForDate = (date: Date): Workout | null => {
    const dateStr = toDateString(date);
    return workoutsByDate.get(dateStr) || null;
  };

  if (isLoading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3, 4, 5, 6, 7].map((i) => (
          <div key={i} className="animate-pulse">
            <div className="flex gap-3">
              <div className="w-24 flex-shrink-0">
                <div className="h-4 w-16 bg-gray-200 rounded mb-1" />
                <div className="h-3 w-12 bg-gray-200 rounded" />
              </div>
              <div className="flex-1 h-20 bg-gray-100 rounded-xl" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="flex flex-col">
      {/* Week Navigation */}
      <div className="flex items-center justify-between p-4 mb-4 bg-white rounded-xl border border-gray-200">
        <button
          onClick={() => setWeekOffset(w => w - 1)}
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          aria-label="Previous week"
        >
          <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>

        <div className="text-center">
          <div className="font-semibold text-gray-900">
            {formatWeekRange(weekDates)}
          </div>
          {weekOffset === 0 && (
            <div className="text-xs text-primary mt-0.5">Current Week</div>
          )}
        </div>

        <button
          onClick={() => setWeekOffset(w => w + 1)}
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          aria-label="Next week"
        >
          <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>

      {/* Days List */}
      <div className="space-y-3">
        {weekDates.map(date => {
          const workout = getWorkoutForDate(date);
          const isToday = checkIsToday(date);
          const isPast = isPastDate(date);

          return (
            <div
              key={toDateString(date)}
              className={`flex gap-3 ${isToday ? 'relative' : ''}`}
            >
              {/* Day Label */}
              <div className={`w-24 flex-shrink-0 ${isToday ? 'text-primary' : 'text-gray-700'}`}>
                <div className={`text-sm font-semibold ${isToday ? 'text-primary' : 'text-gray-900'}`}>
                  {date.toLocaleDateString('en-US', { weekday: 'short' })}
                </div>
                <div className={`text-xs ${isToday ? 'text-primary' : 'text-gray-500'}`}>
                  {date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                </div>
                {isToday && (
                  <div className="w-2 h-2 rounded-full bg-primary mt-1" />
                )}
              </div>

              {/* Workout or Rest Day Card */}
              <div className="flex-1">
                {workout ? (
                  <WorkoutCard workout={workout} isToday={isToday} isPast={isPast} />
                ) : (
                  <RestDayCard isToday={isToday} isPast={isPast} onAddWorkout={onGenerateWorkout} />
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Quick navigation buttons */}
      {weekOffset !== 0 && (
        <div className="mt-6 text-center">
          <button
            onClick={() => setWeekOffset(0)}
            className="text-sm text-primary font-medium hover:underline"
          >
            Back to Current Week
          </button>
        </div>
      )}
    </div>
  );
}
