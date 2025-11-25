import { Link } from 'react-router-dom';
import type { Workout } from '../types';
import { formatDuration } from '../utils/dateUtils';

interface TodayWorkoutCardProps {
  workout: Workout;
}

// Gradient backgrounds based on workout type
const gradients: Record<string, string> = {
  strength: 'from-indigo-600 to-purple-700',
  cardio: 'from-orange-500 to-red-600',
  flexibility: 'from-teal-500 to-cyan-600',
  hiit: 'from-pink-500 to-rose-600',
  mixed: 'from-blue-600 to-indigo-700',
};

export default function TodayWorkoutCard({ workout }: TodayWorkoutCardProps) {
  const gradient = gradients[workout.type] || gradients.mixed;
  const isCompleted = !!workout.completed_at;

  return (
    <div
      className={`relative overflow-hidden rounded-2xl bg-gradient-to-br ${gradient} text-white shadow-lg`}
    >
      {/* Background pattern */}
      <div className="absolute inset-0 opacity-10">
        <svg className="w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
          <defs>
            <pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse">
              <path d="M 10 0 L 0 0 0 10" fill="none" stroke="white" strokeWidth="0.5" />
            </pattern>
          </defs>
          <rect width="100" height="100" fill="url(#grid)" />
        </svg>
      </div>

      {/* Completed overlay */}
      {isCompleted && (
        <div className="absolute inset-0 bg-black/30 flex items-center justify-center z-10">
          <div className="text-center">
            <div className="w-16 h-16 rounded-full bg-secondary mx-auto flex items-center justify-center mb-2">
              <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <p className="text-lg font-semibold">Completed!</p>
          </div>
        </div>
      )}

      {/* Content */}
      <div className="relative p-6 min-h-[280px] flex flex-col">
        {/* Header label */}
        <div className="mb-4">
          <span className="text-xs font-bold uppercase tracking-wider opacity-80">
            Today's Workout
          </span>
        </div>

        {/* Workout info */}
        <div className="flex-1">
          <h2 className="text-3xl font-bold mb-1 leading-tight">{workout.name}</h2>
          <p className="text-lg opacity-90 capitalize mb-4">
            {workout.type} • {workout.difficulty}
          </p>

          {/* Duration */}
          <div className="flex items-center gap-2 text-lg">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="font-semibold">{formatDuration(workout.duration_minutes)}</span>
          </div>

          {/* Exercise count */}
          <div className="mt-2 flex items-center gap-2 text-sm opacity-80">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
            <span>{workout.exercises.length} exercises</span>
          </div>
        </div>

        {/* Action button */}
        <div className="mt-6">
          <Link
            to={`/workout/${workout.id}`}
            className="block w-full py-4 bg-white text-gray-900 rounded-xl font-bold text-center hover:bg-gray-100 transition-colors shadow-md"
          >
            {isCompleted ? 'View Workout' : 'Start Workout'}
          </Link>
        </div>
      </div>
    </div>
  );
}
