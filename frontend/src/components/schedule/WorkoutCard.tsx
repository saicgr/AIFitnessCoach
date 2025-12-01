/**
 * WorkoutCard - Premium workout card for the schedule
 *
 * Features:
 * - Compact top-line summary (name, type, duration, difficulty)
 * - Tags for target muscles and equipment
 * - Right-aligned consistent icon buttons
 * - Premium hover states and transitions
 */
import type { Workout } from '../../types';
import { formatDuration } from '../../utils/dateUtils';
import IconButton from '../ui/IconButton';

// Difficulty badge component
function DifficultyBadge({ difficulty }: { difficulty: string }) {
  const colors: Record<string, string> = {
    easy: 'bg-emerald-500/20 text-emerald-400',
    medium: 'bg-amber-500/20 text-amber-400',
    hard: 'bg-coral/20 text-coral',
  };

  return (
    <span className={`
      px-2 py-0.5 rounded-full text-xs font-medium capitalize
      ${colors[difficulty] || 'bg-white/10 text-text-secondary'}
    `}>
      {difficulty}
    </span>
  );
}

interface WorkoutCardProps {
  workout: Workout;
  isToday: boolean;
  isPast: boolean;
  isDragging?: boolean;
  onClick?: () => void;
  onDelete?: (workoutId: string) => void;
  onStart?: (workoutId: string) => void;
  onRegenerate?: (workoutId: string) => void;
  onSettings?: (workoutId: string) => void;
  isRegenerating?: boolean;
}

export default function WorkoutCard({
  workout,
  isToday,
  isPast,
  isDragging = false,
  onClick,
  onDelete,
  onStart,
  onRegenerate,
  onSettings,
  isRegenerating = false,
}: WorkoutCardProps) {
  const isCompleted = !!workout.completed_at;

  const handleAction = (e: React.MouseEvent, action: () => void) => {
    e.stopPropagation();
    action();
  };

  // Card state styles
  const cardStyles = isToday
    ? 'border-primary/40 bg-gradient-to-br from-primary/10 to-primary/5 shadow-[0_0_20px_rgba(6,182,212,0.1)]'
    : isCompleted
    ? 'border-accent/30 bg-accent/5'
    : isPast
    ? 'border-white/5 bg-white/[0.02] opacity-70'
    : 'border-white/10 bg-white/[0.03] hover:border-white/20 hover:bg-white/[0.05]';

  return (
    <div
      onClick={onClick}
      className={`
        group relative p-4 lg:p-5 rounded-2xl border-2 cursor-pointer
        transition-all duration-200
        ${isDragging ? 'opacity-50 scale-[0.98]' : ''}
        ${cardStyles}
      `}
    >
      {/* Top Row: Name, Type, Duration, Difficulty */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          {/* Workout Name */}
          <h3 className="font-semibold text-text text-base lg:text-lg truncate pr-2">
            {workout.name}
          </h3>

          {/* Metadata Row */}
          <div className="flex items-center gap-3 mt-2 flex-wrap">
            <span className="text-text-secondary text-sm capitalize">{workout.type}</span>
            <span className="w-1 h-1 rounded-full bg-text-muted" />
            <span className="text-text-secondary text-sm flex items-center gap-1.5">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {formatDuration(workout.duration_minutes)}
            </span>
            <span className="w-1 h-1 rounded-full bg-text-muted" />
            <span className="text-text-secondary text-sm">{workout.exercises.length} exercises</span>
            <DifficultyBadge difficulty={workout.difficulty} />
          </div>
        </div>

        {/* Status/Start Button */}
        <div className="flex-shrink-0">
          {isCompleted ? (
            <div className="w-10 h-10 rounded-xl bg-accent flex items-center justify-center">
              <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
              </svg>
            </div>
          ) : isPast && !isCompleted ? (
            <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center">
              <svg className="w-4 h-4 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
          ) : onStart && !isDragging ? (
            <button
              onClick={(e) => handleAction(e, () => onStart(workout.id))}
              className="
                w-12 h-12 rounded-xl bg-primary flex items-center justify-center
                hover:bg-primary/90 hover:scale-105 active:scale-95
                transition-all duration-200
                shadow-lg shadow-primary/25
              "
              title="Start workout"
            >
              <svg className="w-5 h-5 text-white ml-0.5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 5v14l11-7z" />
              </svg>
            </button>
          ) : null}
        </div>
      </div>

      {/* Tags Section */}
      <div className="mt-4 space-y-2">
        {/* Target Muscles */}
        {workout.target_muscles && workout.target_muscles.length > 0 && (
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-text-muted text-xs font-medium">Targets</span>
            {workout.target_muscles.slice(0, 4).map((muscle, idx) => (
              <span
                key={idx}
                className="px-2.5 py-1 bg-primary/15 text-primary text-xs rounded-lg capitalize font-medium"
              >
                {muscle}
              </span>
            ))}
            {workout.target_muscles.length > 4 && (
              <span className="text-xs text-text-muted font-medium">+{workout.target_muscles.length - 4}</span>
            )}
          </div>
        )}

        {/* Equipment */}
        {workout.equipment && workout.equipment.length > 0 && (
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-text-muted text-xs font-medium">Equipment</span>
            {workout.equipment.slice(0, 4).map((item, idx) => (
              <span
                key={idx}
                className="px-2.5 py-1 bg-accent/15 text-accent text-xs rounded-lg capitalize font-medium"
              >
                {item}
              </span>
            ))}
            {workout.equipment.length > 4 && (
              <span className="text-xs text-text-muted font-medium">+{workout.equipment.length - 4}</span>
            )}
          </div>
        )}
      </div>

      {/* Action Buttons - Visible on hover */}
      {!isDragging && !isPast && (
        <div className={`
          absolute bottom-4 right-4 flex items-center gap-2
          opacity-0 group-hover:opacity-100 transition-all duration-200
          translate-y-1 group-hover:translate-y-0
        `}>
          {/* Settings */}
          {onSettings && !isCompleted && (
            <IconButton
              variant="ghost"
              size="sm"
              icon={
                <svg className="w-full h-full" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              }
              label="Settings"
              onClick={(e) => handleAction(e, () => onSettings(workout.id))}
            />
          )}

          {/* Regenerate */}
          {onRegenerate && !isCompleted && (
            <IconButton
              variant="primary"
              size="sm"
              loading={isRegenerating}
              icon={
                <svg className="w-full h-full" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              }
              label="Regenerate"
              onClick={(e) => handleAction(e, () => onRegenerate(workout.id))}
            />
          )}

          {/* Delete */}
          {onDelete && (
            <IconButton
              variant="danger"
              size="sm"
              icon={
                <svg className="w-full h-full" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              }
              label="Delete"
              onClick={(e) => handleAction(e, () => onDelete(workout.id))}
            />
          )}
        </div>
      )}

      {/* Delete button for completed/past workouts */}
      {!isDragging && (isCompleted || isPast) && onDelete && (
        <div className="absolute bottom-4 right-4 opacity-0 group-hover:opacity-100 transition-all">
          <IconButton
            variant="danger"
            size="sm"
            icon={
              <svg className="w-full h-full" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            }
            label="Delete"
            onClick={(e) => handleAction(e, () => onDelete(workout.id))}
          />
        </div>
      )}
    </div>
  );
}
