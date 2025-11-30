import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getWorkout,
  completeWorkout,
  createWorkoutLog,
  createPerformanceLog,
  getPerformanceLogs,
  createStrengthRecord,
  getStrengthRecords,
} from '../api/client';
import { useAppStore } from '../store';
import SetRow from '../components/workout/SetRow';
import type { Workout, ActiveSet, WorkoutExercise, PerformanceLogDetailed, StrengthRecord } from '../types';

// Epley formula for 1RM estimation
const calculate1RM = (weight: number, reps: number): number => {
  if (reps === 1) return weight;
  return weight * (1 + reps / 30);
};

// Convert lbs to kg
const lbsToKg = (lbs: number): number => lbs * 0.453592;

export default function ActiveWorkout() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user, setCurrentWorkout } = useAppStore();

  const [currentExerciseIndex, setCurrentExerciseIndex] = useState(0);
  const [exerciseSets, setExerciseSets] = useState<Map<number, ActiveSet[]>>(new Map());
  const [restTimer, setRestTimer] = useState<number | null>(null);
  const [isResting, setIsResting] = useState(false);
  const [workoutStartTime] = useState(Date.now());
  const [showPRCelebration, setShowPRCelebration] = useState(false);
  const [prExerciseName, setPRExerciseName] = useState('');
  const [workoutLogId, setWorkoutLogId] = useState<string | null>(null);

  const { data: workout, isLoading: workoutLoading } = useQuery<Workout>({
    queryKey: ['workout', id],
    queryFn: () => getWorkout(id!),
    enabled: !!id,
  });

  // Fetch previous performance data
  const { data: previousPerformance } = useQuery<PerformanceLogDetailed[]>({
    queryKey: ['performance-logs', user?.id],
    queryFn: () => getPerformanceLogs(user!.id.toString()),
    enabled: !!user?.id,
  });

  // Fetch strength records for PR comparison
  const { data: strengthRecords } = useQuery<StrengthRecord[]>({
    queryKey: ['strength-records', user?.id],
    queryFn: () => getStrengthRecords(user!.id.toString(), undefined, true),
    enabled: !!user?.id,
  });

  // Initialize sets for each exercise
  useEffect(() => {
    if (workout && exerciseSets.size === 0) {
      setCurrentWorkout(workout);
      const newSetsMap = new Map<number, ActiveSet[]>();

      workout.exercises.forEach((exercise, exerciseIndex) => {
        const sets: ActiveSet[] = [];

        // Find previous performance for this exercise
        const prevPerf = previousPerformance?.filter(
          (p) => p.exercise_name.toLowerCase() === exercise.name.toLowerCase()
        );

        // Add warmup set if weight is present
        if (exercise.weight && exercise.weight > 50) {
          const warmupWeight = Math.round((exercise.weight || 0) * 0.5);
          sets.push({
            setNumber: 0,
            setType: 'warmup',
            targetWeight: warmupWeight,
            targetReps: 8,
            actualWeight: warmupWeight,
            actualReps: 8,
            isCompleted: false,
            previousWeight: prevPerf?.[0]?.weight_kg,
            previousReps: prevPerf?.[0]?.reps_completed,
          });
        }

        // Add working sets
        for (let i = 1; i <= exercise.sets; i++) {
          const prevSet = prevPerf?.find((p) => p.set_number === i);
          sets.push({
            setNumber: i,
            setType: 'working',
            targetWeight: exercise.weight || 0,
            targetReps: exercise.reps,
            actualWeight: exercise.weight || 0,
            actualReps: exercise.reps,
            isCompleted: false,
            previousWeight: prevSet?.weight_kg,
            previousReps: prevSet?.reps_completed,
          });
        }

        newSetsMap.set(exerciseIndex, sets);
      });

      setExerciseSets(newSetsMap);
    }
  }, [workout, previousPerformance, setCurrentWorkout, exerciseSets.size]);

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

  // Create workout log mutation
  const createWorkoutLogMutation = useMutation({
    mutationFn: createWorkoutLog,
    onSuccess: (data) => {
      setWorkoutLogId(data.id);
    },
  });

  // Create performance log mutation
  const createPerformanceLogMutation = useMutation({
    mutationFn: createPerformanceLog,
  });

  // Create strength record mutation
  const createStrengthRecordMutation = useMutation({
    mutationFn: createStrengthRecord,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['strength-records'] });
    },
  });

  // Complete workout mutation
  const completeMutation = useMutation({
    mutationFn: () => completeWorkout(id!),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workouts'] });
      navigate('/');
    },
  });

  const checkForPR = useCallback(async (
    exerciseId: string,
    exerciseName: string,
    weight: number,
    reps: number
  ) => {
    if (!user || weight <= 0 || reps <= 0) return;

    const estimated1RM = calculate1RM(weight, reps);
    const currentBest = strengthRecords?.find(
      (r) => r.exercise_name.toLowerCase() === exerciseName.toLowerCase()
    )?.estimated_1rm || 0;

    if (estimated1RM > currentBest) {
      // New PR!
      setPRExerciseName(exerciseName);
      setShowPRCelebration(true);
      setTimeout(() => setShowPRCelebration(false), 3000);

      await createStrengthRecordMutation.mutateAsync({
        user_id: user.id.toString(),
        exercise_id: exerciseId,
        exercise_name: exerciseName,
        weight_kg: weight,
        reps: reps,
        estimated_1rm: estimated1RM,
        is_pr: true,
      });
    }
  }, [user, strengthRecords, createStrengthRecordMutation]);

  const handleSetComplete = useCallback(async (exerciseIndex: number, setIndex: number) => {
    const currentSets = exerciseSets.get(exerciseIndex);
    if (!currentSets || !workout || !user) return;

    const set = currentSets[setIndex];
    if (set.isCompleted) return;

    const exercise = workout.exercises[exerciseIndex];
    const weightKg = lbsToKg(set.actualWeight || 0);

    // Mark set as completed
    const updatedSets = [...currentSets];
    updatedSets[setIndex] = { ...set, isCompleted: true };
    setExerciseSets(new Map(exerciseSets.set(exerciseIndex, updatedSets)));

    // Start rest timer
    setRestTimer(exercise.rest_seconds || 90);
    setIsResting(true);

    // Create workout log if not exists
    let logId = workoutLogId;
    if (!logId) {
      try {
        const workoutLog = await createWorkoutLogMutation.mutateAsync({
          workout_id: workout.id,
          user_id: user.id.toString(),
          sets_json: JSON.stringify([]),
          total_time_seconds: 0,
        });
        logId = workoutLog.id;
        setWorkoutLogId(logId);
      } catch (error) {
        console.error('Failed to create workout log:', error);
      }
    }

    // Log performance
    if (logId && set.actualWeight && set.actualReps) {
      try {
        await createPerformanceLogMutation.mutateAsync({
          workout_log_id: logId,
          user_id: user.id.toString(),
          exercise_id: exercise.exercise_id,
          exercise_name: exercise.name,
          set_number: set.setNumber,
          reps_completed: set.actualReps,
          weight_kg: weightKg,
          is_completed: true,
        });

        // Check for PR (only on working sets)
        if (set.setType === 'working') {
          await checkForPR(exercise.exercise_id, exercise.name, weightKg, set.actualReps);
        }
      } catch (error) {
        console.error('Failed to log performance:', error);
      }
    }
  }, [exerciseSets, workout, user, workoutLogId, createWorkoutLogMutation, createPerformanceLogMutation, checkForPR]);

  const handleWeightChange = (exerciseIndex: number, setIndex: number, weight: number) => {
    const currentSets = exerciseSets.get(exerciseIndex);
    if (!currentSets) return;

    const updatedSets = [...currentSets];
    updatedSets[setIndex] = { ...updatedSets[setIndex], actualWeight: weight };
    setExerciseSets(new Map(exerciseSets.set(exerciseIndex, updatedSets)));
  };

  const handleRepsChange = (exerciseIndex: number, setIndex: number, reps: number) => {
    const currentSets = exerciseSets.get(exerciseIndex);
    if (!currentSets) return;

    const updatedSets = [...currentSets];
    updatedSets[setIndex] = { ...updatedSets[setIndex], actualReps: reps };
    setExerciseSets(new Map(exerciseSets.set(exerciseIndex, updatedSets)));
  };

  const handleSetTypeChange = (exerciseIndex: number, setIndex: number, type: 'warmup' | 'working' | 'failure') => {
    const currentSets = exerciseSets.get(exerciseIndex);
    if (!currentSets) return;

    const updatedSets = [...currentSets];
    updatedSets[setIndex] = { ...updatedSets[setIndex], setType: type };
    setExerciseSets(new Map(exerciseSets.set(exerciseIndex, updatedSets)));
  };

  const handleAddSet = (exerciseIndex: number) => {
    const currentSets = exerciseSets.get(exerciseIndex);
    if (!currentSets || !workout) return;

    const exercise = workout.exercises[exerciseIndex];
    const lastWorkingSet = [...currentSets].reverse().find((s) => s.setType === 'working');
    const newSetNumber = currentSets.filter((s) => s.setType === 'working').length + 1;

    const newSet: ActiveSet = {
      setNumber: newSetNumber,
      setType: 'working',
      targetWeight: lastWorkingSet?.actualWeight || exercise.weight || 0,
      targetReps: lastWorkingSet?.actualReps || exercise.reps,
      actualWeight: lastWorkingSet?.actualWeight || exercise.weight || 0,
      actualReps: lastWorkingSet?.actualReps || exercise.reps,
      isCompleted: false,
    };

    setExerciseSets(new Map(exerciseSets.set(exerciseIndex, [...currentSets, newSet])));
  };

  const handleFinishWorkout = async () => {
    if (!workout || !user) return;

    // Update workout log with final data
    if (workoutLogId) {
      const totalTimeSeconds = Math.floor((Date.now() - workoutStartTime) / 1000);
      try {
        // We'd update the workout log here with final time if the API supports it
        console.log('Workout completed in', totalTimeSeconds, 'seconds');
      } catch (error) {
        console.error('Failed to update workout log:', error);
      }
    }

    completeMutation.mutate();
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getCompletedSetsCount = () => {
    let count = 0;
    exerciseSets.forEach((sets) => {
      count += sets.filter((s) => s.isCompleted).length;
    });
    return count;
  };

  const getTotalSetsCount = () => {
    let count = 0;
    exerciseSets.forEach((sets) => {
      count += sets.length;
    });
    return count;
  };

  if (workoutLoading || !workout) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-text-secondary">Loading workout...</div>
      </div>
    );
  }

  const currentExercise = workout.exercises[currentExerciseIndex];
  const currentSets = exerciseSets.get(currentExerciseIndex) || [];
  const currentSetIndex = currentSets.findIndex((s) => !s.isCompleted);
  const exerciseCompleted = currentSets.length > 0 && currentSets.every((s) => s.isCompleted);
  const progress = getTotalSetsCount() > 0 ? (getCompletedSetsCount() / getTotalSetsCount()) * 100 : 0;

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* PR Celebration Overlay */}
      {showPRCelebration && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 animate-fade-in">
          <div className="bg-gradient-to-br from-amber-500 to-orange-600 p-8 rounded-3xl text-center animate-bounce-in shadow-2xl">
            <div className="text-6xl mb-4">🏆</div>
            <h2 className="text-2xl font-bold text-white mb-2">NEW PR!</h2>
            <p className="text-white/90">{prExerciseName}</p>
          </div>
        </div>
      )}

      {/* Header */}
      <header className="bg-surface/80 backdrop-blur-lg border-b border-white/10 px-4 py-3 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto">
          <div className="flex items-center justify-between mb-3">
            <button
              onClick={() => navigate(`/workout/${id}`)}
              className="text-text-secondary hover:text-text transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <span className="font-semibold text-text">{workout.name}</span>
            <span className="text-text-secondary text-sm">
              {currentExerciseIndex + 1}/{workout.exercises.length}
            </span>
          </div>
          {/* Progress bar */}
          <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-primary to-emerald-400 transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-2xl mx-auto w-full p-4 flex flex-col gap-4">
        {/* Exercise Header */}
        <div className="bg-surface/50 backdrop-blur rounded-2xl p-4 border border-white/10">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 bg-primary/20 text-primary rounded-2xl flex items-center justify-center">
              <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
              </svg>
            </div>
            <div className="flex-1">
              <h1 className="text-xl font-bold text-text">{currentExercise.name}</h1>
              <p className="text-text-secondary text-sm">
                {currentExercise.muscle_group || 'Full Body'}
              </p>
            </div>
            {exerciseCompleted && (
              <div className="bg-emerald-500/20 text-emerald-400 px-3 py-1 rounded-full text-sm font-medium">
                Done
              </div>
            )}
          </div>
        </div>

        {/* AI Coaching Tip */}
        <div className="bg-gradient-to-r from-primary/10 to-cyan-500/10 rounded-xl p-3 border border-primary/20">
          <div className="flex items-start gap-2">
            <span className="text-lg">💡</span>
            <p className="text-sm text-text-secondary">
              {currentExercise.notes || `Focus on controlled movements. Keep your core engaged throughout the exercise.`}
            </p>
          </div>
        </div>

        {/* Rest Timer */}
        {isResting && restTimer !== null && (
          <div className="bg-surface/80 backdrop-blur rounded-2xl p-6 border border-white/10 text-center">
            <p className="text-text-secondary text-sm mb-2">Rest Time</p>
            <div className="text-5xl font-bold text-primary mb-4">
              {formatTime(restTimer)}
            </div>
            <button
              onClick={() => {
                setIsResting(false);
                setRestTimer(null);
              }}
              className="px-6 py-2 bg-white/10 hover:bg-white/20 text-text rounded-xl transition-colors"
            >
              Skip Rest
            </button>
          </div>
        )}

        {/* Sets Table */}
        <div className="bg-surface/50 backdrop-blur rounded-2xl border border-white/10 overflow-hidden">
          {/* Table Header */}
          <div className="flex items-center gap-2 px-3 py-2 bg-white/5 text-text-muted text-xs font-medium uppercase tracking-wider">
            <div className="w-8 text-center">Set</div>
            <div className="w-20 text-center">Previous</div>
            <div className="flex-1 max-w-20 text-center">Weight</div>
            <div className="flex-1 max-w-20 text-center">Reps</div>
            <div className="w-8 text-center">✓</div>
          </div>

          {/* Sets */}
          <div className="p-2 space-y-2">
            {currentSets.map((set, index) => (
              <SetRow
                key={index}
                set={set}
                isActive={index === currentSetIndex}
                onWeightChange={(weight) => handleWeightChange(currentExerciseIndex, index, weight)}
                onRepsChange={(reps) => handleRepsChange(currentExerciseIndex, index, reps)}
                onComplete={() => handleSetComplete(currentExerciseIndex, index)}
                onSetTypeChange={(type) => handleSetTypeChange(currentExerciseIndex, index, type)}
              />
            ))}
          </div>

          {/* Add Set Button */}
          <div className="p-2 pt-0">
            <button
              onClick={() => handleAddSet(currentExerciseIndex)}
              className="w-full py-2 border-2 border-dashed border-white/20 rounded-xl text-text-secondary hover:border-primary hover:text-primary transition-colors flex items-center justify-center gap-2"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Add Set
            </button>
          </div>
        </div>

        {/* Exercise Navigation */}
        <div className="flex gap-3 mt-auto pt-4">
          <button
            onClick={() => setCurrentExerciseIndex(Math.max(0, currentExerciseIndex - 1))}
            disabled={currentExerciseIndex === 0}
            className="py-3 px-5 bg-surface/50 border border-white/10 rounded-xl text-text-secondary hover:bg-white/10 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            Previous
          </button>
          {currentExerciseIndex === workout.exercises.length - 1 ? (
            <button
              onClick={handleFinishWorkout}
              disabled={completeMutation.isPending}
              className="flex-1 py-3 px-5 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white rounded-xl font-semibold hover:shadow-lg hover:shadow-emerald-500/30 disabled:opacity-50 transition-all"
            >
              {completeMutation.isPending ? 'Completing...' : 'Finish Workout'}
            </button>
          ) : (
            <button
              onClick={() => setCurrentExerciseIndex(currentExerciseIndex + 1)}
              className="flex-1 py-3 px-5 bg-gradient-to-r from-primary to-cyan-500 text-white rounded-xl font-semibold hover:shadow-lg hover:shadow-primary/30 transition-all"
            >
              Next Exercise
            </button>
          )}
        </div>
      </main>

      {/* Exercise List (bottom tabs) */}
      <div className="bg-surface/80 backdrop-blur-lg border-t border-white/10 px-4 py-3 sticky bottom-0">
        <div className="max-w-2xl mx-auto">
          <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
            {workout.exercises.map((ex, index) => {
              const sets = exerciseSets.get(index) || [];
              const isComplete = sets.length > 0 && sets.every((s) => s.isCompleted);
              const isActive = index === currentExerciseIndex;

              return (
                <button
                  key={index}
                  onClick={() => setCurrentExerciseIndex(index)}
                  className={`flex-shrink-0 w-10 h-10 rounded-xl flex items-center justify-center text-sm font-semibold transition-all duration-200 ${
                    isActive
                      ? 'bg-primary text-white shadow-lg shadow-primary/30'
                      : isComplete
                      ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                      : 'bg-white/5 text-text-secondary border border-white/10 hover:bg-white/10'
                  }`}
                >
                  {isComplete ? (
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
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* CSS for animations */}
      <style>{`
        @keyframes fade-in {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes bounce-in {
          0% { transform: scale(0.5); opacity: 0; }
          60% { transform: scale(1.1); }
          100% { transform: scale(1); opacity: 1; }
        }
        .animate-fade-in {
          animation: fade-in 0.3s ease-out;
        }
        .animate-bounce-in {
          animation: bounce-in 0.5s ease-out;
        }
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </div>
  );
}
