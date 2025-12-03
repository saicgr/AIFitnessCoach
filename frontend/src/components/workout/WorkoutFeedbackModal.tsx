import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import {
  submitWorkoutFeedback,
  type WorkoutFeedbackCreate,
  type ExerciseFeedbackCreate,
  type DifficultyFelt,
  type EnergyLevel,
} from '../../api/client';

interface Exercise {
  name: string;
}

interface WorkoutFeedbackModalProps {
  isOpen: boolean;
  onClose: () => void;
  workoutId: string;
  userId: string;
  exercises: Exercise[];
  onFeedbackSubmitted?: () => void;
}

const StarRating = ({
  rating,
  onRatingChange,
  size = 'md',
}: {
  rating: number;
  onRatingChange: (rating: number) => void;
  size?: 'sm' | 'md' | 'lg';
}) => {
  const [hoverRating, setHoverRating] = useState(0);
  const sizeClasses = {
    sm: 'w-6 h-6',
    md: 'w-8 h-8',
    lg: 'w-10 h-10',
  };

  return (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map((star) => (
        <button
          key={star}
          type="button"
          onClick={() => onRatingChange(star)}
          onMouseEnter={() => setHoverRating(star)}
          onMouseLeave={() => setHoverRating(0)}
          className={`${sizeClasses[size]} transition-transform hover:scale-110`}
        >
          <svg
            viewBox="0 0 24 24"
            fill={star <= (hoverRating || rating) ? '#facc15' : 'none'}
            stroke={star <= (hoverRating || rating) ? '#facc15' : '#6b7280'}
            strokeWidth={2}
          >
            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
          </svg>
        </button>
      ))}
    </div>
  );
};

const DifficultySelector = ({
  value,
  onChange,
}: {
  value?: DifficultyFelt;
  onChange: (value: DifficultyFelt) => void;
}) => {
  const options: { value: DifficultyFelt; label: string; emoji: string }[] = [
    { value: 'too_easy', label: 'Too Easy', emoji: '😎' },
    { value: 'just_right', label: 'Just Right', emoji: '💪' },
    { value: 'too_hard', label: 'Too Hard', emoji: '😰' },
  ];

  return (
    <div className="flex gap-2">
      {options.map((opt) => (
        <button
          key={opt.value}
          type="button"
          onClick={() => onChange(opt.value)}
          className={`flex-1 py-2 px-3 rounded-xl text-sm font-medium transition-all ${
            value === opt.value
              ? 'bg-primary/20 border-2 border-primary text-primary'
              : 'bg-white/5 border-2 border-transparent hover:bg-white/10 text-text-muted'
          }`}
        >
          <span className="text-lg mr-1">{opt.emoji}</span>
          {opt.label}
        </button>
      ))}
    </div>
  );
};

const EnergySelector = ({
  value,
  onChange,
}: {
  value?: EnergyLevel;
  onChange: (value: EnergyLevel) => void;
}) => {
  const options: { value: EnergyLevel; label: string; emoji: string }[] = [
    { value: 'exhausted', label: 'Exhausted', emoji: '😵' },
    { value: 'tired', label: 'Tired', emoji: '😪' },
    { value: 'good', label: 'Good', emoji: '😊' },
    { value: 'energized', label: 'Energized', emoji: '⚡' },
    { value: 'great', label: 'Great!', emoji: '🔥' },
  ];

  return (
    <div className="flex gap-1">
      {options.map((opt) => (
        <button
          key={opt.value}
          type="button"
          onClick={() => onChange(opt.value)}
          className={`flex-1 py-2 px-1 rounded-lg text-xs font-medium transition-all flex flex-col items-center gap-1 ${
            value === opt.value
              ? 'bg-primary/20 border-2 border-primary'
              : 'bg-white/5 border-2 border-transparent hover:bg-white/10'
          }`}
        >
          <span className="text-xl">{opt.emoji}</span>
          <span className={value === opt.value ? 'text-primary' : 'text-text-muted'}>
            {opt.label}
          </span>
        </button>
      ))}
    </div>
  );
};

export default function WorkoutFeedbackModal({
  isOpen,
  onClose,
  workoutId,
  userId,
  exercises,
  onFeedbackSubmitted,
}: WorkoutFeedbackModalProps) {
  const [isDone, setIsDone] = useState(false);
  const [overallRating, setOverallRating] = useState(0);
  const [energyLevel, setEnergyLevel] = useState<EnergyLevel | undefined>();
  const [overallDifficulty, setOverallDifficulty] = useState<DifficultyFelt | undefined>();
  const [comment, setComment] = useState('');
  const [showExerciseFeedback, setShowExerciseFeedback] = useState(false);
  const [exerciseRatings, setExerciseRatings] = useState<Map<number, number>>(new Map());
  const [exerciseComments, setExerciseComments] = useState<Map<number, string>>(new Map());

  const submitMutation = useMutation({
    mutationFn: (feedback: WorkoutFeedbackCreate) => submitWorkoutFeedback(workoutId, feedback),
    onSuccess: () => {
      setIsDone(true);
      setTimeout(() => {
        onFeedbackSubmitted?.();
        onClose();
      }, 2000);
    },
  });

  const handleSubmit = () => {
    const exerciseFeedback: ExerciseFeedbackCreate[] = [];

    if (showExerciseFeedback) {
      exercises.forEach((ex, index) => {
        const rating = exerciseRatings.get(index);
        if (rating) {
          exerciseFeedback.push({
            user_id: userId,
            workout_id: workoutId,
            exercise_name: ex.name,
            exercise_index: index,
            rating,
            comment: exerciseComments.get(index),
          });
        }
      });
    }

    submitMutation.mutate({
      user_id: userId,
      workout_id: workoutId,
      overall_rating: overallRating,
      energy_level: energyLevel,
      overall_difficulty: overallDifficulty,
      comment: comment || undefined,
      exercise_feedback: exerciseFeedback.length > 0 ? exerciseFeedback : undefined,
    });
  };

  const handleSkip = () => {
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in">
      <div className="bg-surface rounded-2xl w-full max-w-lg shadow-2xl border border-white/10 overflow-hidden max-h-[90vh] flex flex-col">
        {isDone ? (
          // Success state
          <div className="p-8 text-center">
            <div className="text-6xl mb-4 animate-bounce-in">🎉</div>
            <h2 className="text-xl font-semibold text-text mb-2">Thanks for your feedback!</h2>
            <p className="text-text-muted">Your input helps us improve your workouts.</p>
          </div>
        ) : (
          <>
            {/* Header */}
            <div className="p-4 border-b border-white/10 flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold text-text">How was your workout?</h2>
                <p className="text-sm text-text-muted">Your feedback helps us improve</p>
              </div>
              <button
                onClick={handleSkip}
                className="text-text-muted hover:text-text text-sm"
              >
                Skip
              </button>
            </div>

            {/* Content */}
            <div className="p-4 overflow-y-auto flex-1">
              <div className="space-y-5">
                {/* Overall Rating */}
                <div className="text-center">
                  <p className="text-text-muted text-sm mb-3">Overall Rating</p>
                  <div className="flex justify-center">
                    <StarRating
                      rating={overallRating}
                      onRatingChange={setOverallRating}
                      size="lg"
                    />
                  </div>
                  <p className="text-xs text-text-muted mt-2">
                    {overallRating === 0 && 'Tap to rate'}
                    {overallRating === 1 && 'Poor'}
                    {overallRating === 2 && 'Fair'}
                    {overallRating === 3 && 'Good'}
                    {overallRating === 4 && 'Great'}
                    {overallRating === 5 && 'Excellent!'}
                  </p>
                </div>

                {/* Energy Level */}
                <div>
                  <p className="text-text-muted text-sm mb-3">How do you feel?</p>
                  <EnergySelector value={energyLevel} onChange={setEnergyLevel} />
                </div>

                {/* Difficulty */}
                <div>
                  <p className="text-text-muted text-sm mb-3">Workout difficulty</p>
                  <DifficultySelector value={overallDifficulty} onChange={setOverallDifficulty} />
                </div>

                {/* Comment */}
                <div>
                  <p className="text-text-muted text-sm mb-2">Any comments? (optional)</p>
                  <textarea
                    value={comment}
                    onChange={(e) => setComment(e.target.value)}
                    placeholder="What went well? What could be improved?"
                    className="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-text text-sm placeholder:text-text-muted resize-none focus:outline-none focus:border-primary/50"
                    rows={2}
                  />
                </div>

                {/* Exercise feedback toggle */}
                <div className="flex items-center justify-between py-2 border-t border-white/10 pt-4">
                  <div>
                    <p className="text-sm font-medium text-text">Rate individual exercises</p>
                    <p className="text-xs text-text-muted">Help us optimize your workouts</p>
                  </div>
                  <button
                    onClick={() => setShowExerciseFeedback(!showExerciseFeedback)}
                    className={`relative w-12 h-7 rounded-full transition-all ${
                      showExerciseFeedback
                        ? 'bg-primary shadow-[0_0_15px_rgba(var(--color-primary-rgb),0.4)]'
                        : 'bg-white/20 border border-white/30'
                    }`}
                  >
                    <div
                      className={`absolute top-0.5 w-6 h-6 rounded-full transition-all bg-white ${
                        showExerciseFeedback ? 'left-5' : 'left-0.5'
                      }`}
                    />
                  </button>
                </div>

                {/* Inline exercise ratings (shown when toggle is on) */}
                {showExerciseFeedback && (
                  <div className="space-y-2 animate-fade-in">
                    <p className="text-xs text-text-muted">Tap stars to rate each exercise</p>
                    {exercises.map((exercise, index) => (
                      <div
                        key={index}
                        className="bg-white/5 rounded-xl p-3 border border-white/10"
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="text-sm font-medium text-text truncate flex-1">
                            {exercise.name}
                          </span>
                          <StarRating
                            rating={exerciseRatings.get(index) || 0}
                            onRatingChange={(r) => {
                              const newRatings = new Map(exerciseRatings);
                              newRatings.set(index, r);
                              setExerciseRatings(newRatings);
                            }}
                            size="sm"
                          />
                        </div>
                        {exerciseRatings.get(index) && (
                          <input
                            type="text"
                            value={exerciseComments.get(index) || ''}
                            onChange={(e) => {
                              const newComments = new Map(exerciseComments);
                              newComments.set(index, e.target.value);
                              setExerciseComments(newComments);
                            }}
                            placeholder="Add a note (optional)"
                            className="w-full mt-2 px-2 py-1.5 bg-white/5 border border-white/10 rounded text-text text-xs placeholder:text-text-muted focus:outline-none focus:border-primary/50"
                          />
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-white/10 flex gap-3">
              <button
                onClick={handleSkip}
                className="flex-1 py-3 px-4 bg-white/10 hover:bg-white/15 rounded-xl font-medium text-text transition-colors"
              >
                Skip
              </button>
              <button
                onClick={handleSubmit}
                disabled={overallRating === 0 || submitMutation.isPending}
                className="flex-1 py-3 px-4 bg-primary hover:bg-primary/80 rounded-xl font-medium text-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {submitMutation.isPending ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    Saving...
                  </>
                ) : (
                  'Submit'
                )}
              </button>
            </div>
          </>
        )}
      </div>

      <style>{`
        @keyframes bounce-in {
          0% { transform: scale(0); }
          50% { transform: scale(1.2); }
          100% { transform: scale(1); }
        }
        .animate-bounce-in {
          animation: bounce-in 0.5s ease-out;
        }
      `}</style>
    </div>
  );
}
