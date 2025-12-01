import type { WorkoutExercise, ActiveSet } from '../../types';

interface ExerciseListModalProps {
  exercises: WorkoutExercise[];
  currentExerciseIndex: number;
  exerciseSets: Map<number, ActiveSet[]>;
  onSelectExercise: (index: number) => void;
  onClose: () => void;
}

export default function ExerciseListModal({
  exercises,
  currentExerciseIndex,
  exerciseSets,
  onSelectExercise,
  onClose,
}: ExerciseListModalProps) {
  const getExerciseStatus = (index: number) => {
    const sets = exerciseSets.get(index) || [];
    if (sets.length === 0) return 'pending';
    if (sets.every((s) => s.isCompleted)) return 'completed';
    if (sets.some((s) => s.isCompleted)) return 'in_progress';
    return 'pending';
  };

  const getCompletedSetsCount = (index: number) => {
    const sets = exerciseSets.get(index) || [];
    return sets.filter((s) => s.isCompleted).length;
  };

  const getTotalSetsCount = (index: number) => {
    const sets = exerciseSets.get(index) || [];
    return sets.length;
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 animate-fade-in"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md bg-surface rounded-t-3xl overflow-hidden animate-slide-up max-h-[80vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-4 border-b border-white/10">
          <h2 className="text-lg font-bold text-text">All Exercises</h2>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-text-secondary hover:bg-white/20 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Exercise List */}
        <div className="overflow-y-auto p-4 space-y-2" style={{ maxHeight: 'calc(80vh - 60px)' }}>
          {exercises.map((exercise, index) => {
            const status = getExerciseStatus(index);
            const isActive = index === currentExerciseIndex;
            const completedSets = getCompletedSetsCount(index);
            const totalSets = getTotalSetsCount(index);

            return (
              <button
                key={index}
                onClick={() => {
                  onSelectExercise(index);
                  onClose();
                }}
                className={`
                  w-full flex items-center gap-3 p-3 rounded-xl
                  border transition-all duration-200
                  ${isActive
                    ? 'bg-primary/20 border-primary/50'
                    : status === 'completed'
                    ? 'bg-emerald-500/10 border-emerald-500/30'
                    : 'bg-white/5 border-white/10 hover:bg-white/10'
                  }
                `}
              >
                {/* Status indicator */}
                <div
                  className={`
                    w-10 h-10 rounded-xl flex items-center justify-center text-sm font-bold
                    ${status === 'completed'
                      ? 'bg-emerald-500 text-white'
                      : isActive
                      ? 'bg-primary text-white'
                      : 'bg-white/10 text-text-secondary'
                    }
                  `}
                >
                  {status === 'completed' ? (
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    index + 1
                  )}
                </div>

                {/* Exercise info */}
                <div className="flex-1 text-left">
                  <p className={`font-medium ${isActive ? 'text-primary' : 'text-text'}`}>
                    {exercise.name}
                  </p>
                  <p className="text-xs text-text-secondary">
                    {exercise.muscle_group || 'Full Body'} • {exercise.sets} sets × {exercise.reps} reps
                  </p>
                </div>

                {/* Progress */}
                <div className="text-right">
                  <p className="text-sm text-text-secondary">
                    {completedSets}/{totalSets}
                  </p>
                  <div className="w-16 h-1.5 bg-white/10 rounded-full overflow-hidden mt-1">
                    <div
                      className={`h-full ${status === 'completed' ? 'bg-emerald-500' : 'bg-primary'}`}
                      style={{ width: totalSets > 0 ? `${(completedSets / totalSets) * 100}%` : '0%' }}
                    />
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      <style>{`
        @keyframes fade-in {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes slide-up {
          from { transform: translateY(100%); }
          to { transform: translateY(0); }
        }
        .animate-fade-in {
          animation: fade-in 0.2s ease-out;
        }
        .animate-slide-up {
          animation: slide-up 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
