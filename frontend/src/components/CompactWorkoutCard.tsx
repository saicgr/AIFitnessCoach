import { Link } from 'react-router-dom';
import type { Workout } from '../types';
import { formatDuration } from '../utils/dateUtils';

interface CompactWorkoutCardProps {
  workout: Workout;
  isPast?: boolean;
}

export default function CompactWorkoutCard({ workout, isPast = false }: CompactWorkoutCardProps) {
  const isCompleted = !!workout.completed_at;

  return (
    <Link
      to={`/workout/${workout.id}`}
      className={`block p-4 rounded-xl border-2 transition-all hover:shadow-md ${
        isCompleted
          ? 'border-secondary/30 bg-secondary/5'
          : isPast
          ? 'border-gray-200 bg-gray-50'
          : 'border-gray-200 bg-white'
      }`}
    >
      <div className="flex justify-between items-start">
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-gray-900 truncate">{workout.name}</h3>
          <p className="text-sm text-gray-600 truncate capitalize">
            {workout.type} workout
          </p>
          <div className="mt-2 flex items-center gap-3 text-sm text-gray-500">
            <span className="flex items-center gap-1">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {formatDuration(workout.duration_minutes)}
            </span>
            <span className="capitalize">{workout.difficulty}</span>
          </div>
        </div>

        {/* Completion badge */}
        {isCompleted && (
          <div className="flex-shrink-0 ml-3">
            <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center">
              <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
        )}

        {/* Missed badge for past uncompleted */}
        {isPast && !isCompleted && (
          <div className="flex-shrink-0 ml-3">
            <div className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center">
              <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
          </div>
        )}
      </div>

      {/* Exercise preview */}
      <div className="mt-3 flex gap-2 flex-wrap">
        {workout.exercises.slice(0, 2).map((ex, i) => (
          <span key={i} className="text-xs px-2 py-1 bg-gray-100 rounded-full text-gray-600">
            {ex.name}
          </span>
        ))}
        {workout.exercises.length > 2 && (
          <span className="text-xs px-2 py-1 bg-gray-100 rounded-full text-gray-600">
            +{workout.exercises.length - 2} more
          </span>
        )}
      </div>
    </Link>
  );
}
