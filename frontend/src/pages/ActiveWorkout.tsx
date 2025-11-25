import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation } from '@tanstack/react-query';
import { getWorkout, completeWorkout } from '../api/client';
import { useAppStore } from '../store';
import type { Workout } from '../types';

export default function ActiveWorkout() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const {
    exerciseProgress,
    setExerciseComplete,
    resetExerciseProgress,
    setCurrentWorkout,
  } = useAppStore();

  const [currentExerciseIndex, setCurrentExerciseIndex] = useState(0);
  const [restTimer, setRestTimer] = useState<number | null>(null);
  const [isResting, setIsResting] = useState(false);

  const { data: workout } = useQuery<Workout>({
    queryKey: ['workout', id],
    queryFn: () => getWorkout(Number(id)),
    enabled: !!id,
  });

  useEffect(() => {
    if (workout) {
      setCurrentWorkout(workout);
    }
  }, [workout, setCurrentWorkout]);

  const completeMutation = useMutation({
    mutationFn: () => completeWorkout(Number(id)),
    onSuccess: () => {
      resetExerciseProgress();
      navigate('/');
    },
  });

  // Rest timer
  useEffect(() => {
    let interval: number;
    if (isResting && restTimer !== null && restTimer > 0) {
      interval = window.setInterval(() => {
        setRestTimer((prev) => (prev !== null ? prev - 1 : null));
      }, 1000);
    } else if (restTimer === 0) {
      setIsResting(false);
      setRestTimer(null);
    }
    return () => clearInterval(interval);
  }, [isResting, restTimer]);

  if (!workout) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-gray-500">Loading workout...</div>
      </div>
    );
  }

  const currentExercise = workout.exercises[currentExerciseIndex];
  const completedCount = Object.values(exerciseProgress).filter(Boolean).length;
  const progress = (completedCount / workout.exercises.length) * 100;

  const handleCompleteSet = () => {
    if (!currentExercise) return;
    setExerciseComplete(currentExercise.exercise_id, true);

    if (currentExerciseIndex < workout.exercises.length - 1) {
      setRestTimer(currentExercise.rest_seconds);
      setIsResting(true);
    }
  };

  const handleNextExercise = () => {
    setIsResting(false);
    setRestTimer(null);
    if (currentExerciseIndex < workout.exercises.length - 1) {
      setCurrentExerciseIndex(currentExerciseIndex + 1);
    }
  };

  const handlePrevExercise = () => {
    if (currentExerciseIndex > 0) {
      setCurrentExerciseIndex(currentExerciseIndex - 1);
    }
  };

  const handleFinishWorkout = () => {
    completeMutation.mutate();
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <header className="bg-primary text-white p-4">
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <button
            onClick={() => navigate(`/workout/${id}`)}
            className="text-white/70 hover:text-white"
          >
            ← Exit
          </button>
          <span className="font-semibold">{workout.name}</span>
          <span className="text-white/70">
            {currentExerciseIndex + 1}/{workout.exercises.length}
          </span>
        </div>
        {/* Progress bar */}
        <div className="max-w-2xl mx-auto mt-3">
          <div className="h-2 bg-white/20 rounded-full overflow-hidden">
            <div
              className="h-full bg-secondary transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-2xl mx-auto w-full p-4 flex flex-col">
        {isResting ? (
          /* Rest Timer View */
          <div className="flex-1 flex flex-col items-center justify-center text-center">
            <div className="text-6xl font-bold text-primary mb-4">
              {formatTime(restTimer || 0)}
            </div>
            <p className="text-xl text-gray-600 mb-8">Rest Time</p>
            <button
              onClick={handleNextExercise}
              className="px-8 py-3 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark"
            >
              Skip Rest
            </button>
          </div>
        ) : (
          /* Exercise View */
          <>
            <div className="flex-1 flex flex-col items-center justify-center text-center">
              <div className="w-20 h-20 bg-primary/10 text-primary rounded-full flex items-center justify-center text-3xl font-bold mb-6">
                {currentExerciseIndex + 1}
              </div>
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                {currentExercise.name}
              </h1>
              <div className="text-lg text-gray-600 mb-6">
                {currentExercise.sets} sets × {currentExercise.reps} reps
                {currentExercise.weight && ` @ ${currentExercise.weight} lbs`}
              </div>
              {currentExercise.notes && (
                <p className="text-gray-500 italic max-w-md">
                  {currentExercise.notes}
                </p>
              )}
            </div>

            {/* Exercise Navigation */}
            <div className="flex gap-3">
              <button
                onClick={handlePrevExercise}
                disabled={currentExerciseIndex === 0}
                className="py-4 px-6 border border-gray-300 rounded-xl text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              {currentExerciseIndex === workout.exercises.length - 1 ? (
                <button
                  onClick={handleFinishWorkout}
                  disabled={completeMutation.isPending}
                  className="flex-1 py-4 px-6 bg-secondary text-white rounded-xl font-semibold hover:bg-secondary/90 disabled:opacity-50"
                >
                  {completeMutation.isPending ? 'Completing...' : 'Finish Workout'}
                </button>
              ) : (
                <button
                  onClick={handleCompleteSet}
                  className="flex-1 py-4 px-6 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark"
                >
                  Complete & Rest
                </button>
              )}
            </div>
          </>
        )}
      </main>

      {/* Exercise List (collapsed) */}
      <div className="bg-white border-t border-gray-200 p-4">
        <div className="max-w-2xl mx-auto">
          <div className="flex gap-2 overflow-x-auto pb-2">
            {workout.exercises.map((ex, index) => (
              <button
                key={index}
                onClick={() => {
                  setIsResting(false);
                  setRestTimer(null);
                  setCurrentExerciseIndex(index);
                }}
                className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center text-sm font-semibold transition-colors ${
                  index === currentExerciseIndex
                    ? 'bg-primary text-white'
                    : exerciseProgress[ex.exercise_id]
                    ? 'bg-secondary text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {index + 1}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
