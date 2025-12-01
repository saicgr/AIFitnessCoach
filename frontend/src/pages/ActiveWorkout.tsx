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
  getExerciseVideoUrl,
} from '../api/client';
import { useAppStore } from '../store';
import SetRow from '../components/workout/SetRow';
import BottomSheet from '../components/workout/BottomSheet';
import ExerciseListModal from '../components/workout/ExerciseListModal';
import type { Workout, ActiveSet, PerformanceLogDetailed, StrengthRecord } from '../types';

// Epley formula for 1RM estimation
const calculate1RM = (weight: number, reps: number): number => {
  if (reps === 1) return weight;
  return weight * (1 + reps / 30);
};

// Convert lbs to kg
const lbsToKg = (lbs: number): number => lbs * 0.453592;

// Format time as MM:SS or H:MM:SS
const formatTime = (seconds: number) => {
  const hours = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  if (hours > 0) {
    return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

// Get icon for muscle group
const getMuscleGroupIcon = (muscleGroup?: string) => {
  const group = muscleGroup?.toLowerCase() || '';
  if (group.includes('chest')) return '💪';
  if (group.includes('back')) return '🔙';
  if (group.includes('shoulder')) return '🤷';
  if (group.includes('leg') || group.includes('quad') || group.includes('hamstring')) return '🦵';
  if (group.includes('arm') || group.includes('bicep') || group.includes('tricep')) return '💪';
  if (group.includes('core') || group.includes('ab')) return '🎯';
  if (group.includes('glute')) return '🍑';
  return '🏋️';
};

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
  const [totalElapsedTime, setTotalElapsedTime] = useState(0);
  const [showPRCelebration, setShowPRCelebration] = useState(false);
  const [prExerciseName, setPRExerciseName] = useState('');
  const [workoutLogId, setWorkoutLogId] = useState<string | null>(null);
  const [sheetExpanded, setSheetExpanded] = useState(false);
  const [showExerciseList, setShowExerciseList] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [videoLoading, setVideoLoading] = useState(false);

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

  // Total elapsed time counter
  useEffect(() => {
    if (isPaused) return;
    const interval = setInterval(() => {
      setTotalElapsedTime(Math.floor((Date.now() - workoutStartTime) / 1000));
    }, 1000);
    return () => clearInterval(interval);
  }, [workoutStartTime, isPaused]);

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

  // Fetch video URL when exercise changes
  useEffect(() => {
    const currentExercise = workout?.exercises[currentExerciseIndex];
    if (!currentExercise?.name) return;

    setVideoLoading(true);
    setVideoUrl(null);

    getExerciseVideoUrl(currentExercise.name)
      .then((url) => setVideoUrl(url))
      .finally(() => setVideoLoading(false));
  }, [workout?.exercises, currentExerciseIndex]);

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
      console.log('Workout completed in', totalTimeSeconds, 'seconds');
    }

    completeMutation.mutate();
  };

  const goToNextExercise = () => {
    if (workout && currentExerciseIndex < workout.exercises.length - 1) {
      setCurrentExerciseIndex(currentExerciseIndex + 1);
      setSheetExpanded(false);
    }
  };

  const goToPreviousExercise = () => {
    if (currentExerciseIndex > 0) {
      setCurrentExerciseIndex(currentExerciseIndex - 1);
      setSheetExpanded(false);
    }
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
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-text-secondary">Loading workout...</p>
        </div>
      </div>
    );
  }

  const currentExercise = workout.exercises[currentExerciseIndex];
  const currentSets = exerciseSets.get(currentExerciseIndex) || [];
  const currentSetIndex = currentSets.findIndex((s) => !s.isCompleted);
  const exerciseCompleted = currentSets.length > 0 && currentSets.every((s) => s.isCompleted);
  const progress = getTotalSetsCount() > 0 ? (getCompletedSetsCount() / getTotalSetsCount()) * 100 : 0;
  const isLastExercise = currentExerciseIndex === workout.exercises.length - 1;

  // Collapsed content for bottom sheet (set-by-set details of current exercise)
  const collapsedContent = (
    <div className="space-y-3">
      {/* Exercise tags and name */}
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <span className="text-xs px-2 py-0.5 bg-white/10 rounded-full text-text-secondary uppercase tracking-wider">
            {currentExercise.equipment || 'Bodyweight'}
          </span>
          {currentExercise.muscle_group && (
            <span className="text-xs px-2 py-0.5 bg-primary/20 rounded-full text-primary uppercase tracking-wider">
              {currentExercise.muscle_group}
            </span>
          )}
        </div>
        <h2 className="text-xl font-bold text-text">{currentExercise.name}</h2>
        <p className="text-text-secondary">{currentExercise.sets} sets × {currentExercise.reps} reps</p>
      </div>

      {/* Current set-by-set table */}
      <div className="bg-white/5 rounded-xl border border-white/10 overflow-hidden">
        <div className="flex items-center gap-2 px-3 py-2 bg-white/5 text-text-muted text-xs font-medium uppercase tracking-wider">
          <div className="w-8 text-center">Set</div>
          <div className="w-16 text-center">Prev</div>
          <div className="flex-1 max-w-16 text-center">Wt</div>
          <div className="flex-1 max-w-16 text-center">Reps</div>
          <div className="w-8 text-center"></div>
        </div>
        <div className="p-2 space-y-1.5">
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
        <div className="p-2 pt-0">
          <button
            onClick={() => handleAddSet(currentExerciseIndex)}
            className="w-full py-2 border-2 border-dashed border-white/20 rounded-xl text-text-secondary hover:border-primary hover:text-primary transition-colors flex items-center justify-center gap-2 text-sm"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add Set
          </button>
        </div>
      </div>

      {/* Navigation buttons */}
      <div className="flex gap-3 pt-2">
        <button
          onClick={() => setShowExerciseList(true)}
          className="flex-shrink-0 w-12 h-12 rounded-xl bg-white/10 border border-white/10 flex items-center justify-center text-text-secondary hover:bg-white/20 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
          </svg>
        </button>
        {isLastExercise ? (
          <button
            onClick={handleFinishWorkout}
            disabled={completeMutation.isPending}
            className="flex-1 h-12 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white rounded-xl font-semibold flex items-center justify-center gap-2 hover:shadow-lg hover:shadow-emerald-500/30 disabled:opacity-50 transition-all"
          >
            {completeMutation.isPending ? (
              <>
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Completing...
              </>
            ) : (
              <>
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                Finish Workout
              </>
            )}
          </button>
        ) : (
          <button
            onClick={goToNextExercise}
            className="flex-1 h-12 bg-gradient-to-r from-primary to-cyan-500 text-white rounded-xl font-semibold flex items-center justify-center gap-2 hover:shadow-lg hover:shadow-primary/30 transition-all"
          >
            Next Exercise
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        )}
      </div>
    </div>
  );

  // Expanded content - shows all exercises with their set details
  const expandedContent = (
    <div className="space-y-4">
      {/* Exercise info header */}
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <span className="text-xs px-2 py-0.5 bg-white/10 rounded-full text-text-secondary uppercase tracking-wider">
            {currentExercise.equipment || 'Bodyweight'}
          </span>
          {currentExercise.muscle_group && (
            <span className="text-xs px-2 py-0.5 bg-primary/20 rounded-full text-primary uppercase tracking-wider">
              {currentExercise.muscle_group}
            </span>
          )}
        </div>
        <h2 className="text-xl font-bold text-text">{currentExercise.name}</h2>
        <p className="text-text-secondary">{currentExercise.sets} sets × {currentExercise.reps} reps</p>
      </div>

      {/* Set-by-set table */}
      <div className="bg-white/5 rounded-xl border border-white/10 overflow-hidden">
        <div className="flex items-center gap-2 px-3 py-2 bg-white/5 text-text-muted text-xs font-medium uppercase tracking-wider">
          <div className="w-8 text-center">Set</div>
          <div className="w-20 text-center">Previous</div>
          <div className="flex-1 max-w-20 text-center">Weight</div>
          <div className="flex-1 max-w-20 text-center">Reps</div>
          <div className="w-8 text-center"></div>
        </div>
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

      {/* AI Coaching Tip */}
      {currentExercise.notes && (
        <div className="bg-gradient-to-r from-primary/10 to-cyan-500/10 rounded-xl p-3 border border-primary/20">
          <div className="flex items-start gap-2">
            <span className="text-lg">💡</span>
            <p className="text-sm text-text-secondary">{currentExercise.notes}</p>
          </div>
        </div>
      )}

      {/* All Exercises List */}
      <div className="space-y-2">
        <h3 className="text-sm font-semibold text-text-secondary uppercase tracking-wider">All Exercises</h3>
        <div className="space-y-2">
          {workout.exercises.map((exercise, index) => {
            const sets = exerciseSets.get(index) || [];
            const isComplete = sets.length > 0 && sets.every((s) => s.isCompleted);
            const isActive = index === currentExerciseIndex;
            const completedSetsCount = sets.filter(s => s.isCompleted).length;

            return (
              <button
                key={index}
                onClick={() => {
                  setCurrentExerciseIndex(index);
                  setSheetExpanded(false);
                }}
                className={`
                  w-full flex items-center gap-3 p-3 rounded-xl
                  border transition-all duration-200
                  ${isActive
                    ? 'bg-primary/20 border-primary/50'
                    : isComplete
                    ? 'bg-emerald-500/10 border-emerald-500/30'
                    : 'bg-white/5 border-white/10'
                  }
                `}
              >
                <div
                  className={`
                    w-8 h-8 rounded-lg flex items-center justify-center text-sm font-bold
                    ${isComplete
                      ? 'bg-emerald-500 text-white'
                      : isActive
                      ? 'bg-primary text-white'
                      : 'bg-white/10 text-text-secondary'
                    }
                  `}
                >
                  {isComplete ? (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  ) : (
                    index + 1
                  )}
                </div>
                <div className="flex-1 text-left">
                  <p className={`font-medium text-sm ${isActive ? 'text-primary' : 'text-text'}`}>
                    {exercise.name}
                  </p>
                </div>
                <span className="text-xs text-text-muted">
                  {completedSetsCount}/{sets.length}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Navigation */}
      <div className="flex gap-3 pt-2 sticky bottom-0 bg-surface/95 -mx-4 px-4 py-3 border-t border-white/10">
        <button
          onClick={goToPreviousExercise}
          disabled={currentExerciseIndex === 0}
          className="flex-shrink-0 w-12 h-12 rounded-xl bg-white/10 border border-white/10 flex items-center justify-center text-text-secondary hover:bg-white/20 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        {isLastExercise ? (
          <button
            onClick={handleFinishWorkout}
            disabled={completeMutation.isPending}
            className="flex-1 h-12 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white rounded-xl font-semibold flex items-center justify-center gap-2 hover:shadow-lg hover:shadow-emerald-500/30 disabled:opacity-50 transition-all"
          >
            {completeMutation.isPending ? 'Completing...' : 'Finish Workout'}
          </button>
        ) : (
          <button
            onClick={goToNextExercise}
            className="flex-1 h-12 bg-gradient-to-r from-primary to-cyan-500 text-white rounded-xl font-semibold flex items-center justify-center gap-2 hover:shadow-lg hover:shadow-primary/30 transition-all"
          >
            Next Exercise
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        )}
      </div>
    </div>
  );

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

      {/* Exercise List Modal */}
      {showExerciseList && (
        <ExerciseListModal
          exercises={workout.exercises}
          currentExerciseIndex={currentExerciseIndex}
          exerciseSets={exerciseSets}
          onSelectExercise={(index) => {
            setCurrentExerciseIndex(index);
            setSheetExpanded(false);
          }}
          onClose={() => setShowExerciseList(false)}
        />
      )}

      {/* Floating Header with Timer */}
      <header className="fixed top-0 left-0 right-0 z-30 px-4 py-3 safe-area-top">
        <div className="flex items-center justify-between">
          {/* Back button */}
          <button
            onClick={() => navigate(`/workout/${id}`)}
            className="w-10 h-10 bg-black/40 backdrop-blur-lg rounded-full flex items-center justify-center text-white hover:bg-black/60 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>

          {/* Total workout time */}
          <div className="bg-black/40 backdrop-blur-lg rounded-full px-4 py-2 flex items-center gap-2">
            <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="text-white font-mono font-semibold">{formatTime(totalElapsedTime)}</span>
          </div>

          {/* Pause button */}
          <button
            onClick={() => setIsPaused(!isPaused)}
            className={`w-10 h-10 backdrop-blur-lg rounded-full flex items-center justify-center transition-colors ${
              isPaused ? 'bg-primary text-white' : 'bg-black/40 text-white hover:bg-black/60'
            }`}
          >
            {isPaused ? (
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 5v14l11-7z" />
              </svg>
            ) : (
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" />
              </svg>
            )}
          </button>
        </div>

        {/* Progress bar */}
        <div className="mt-3 h-1 bg-white/20 rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-primary to-emerald-400 transition-all duration-500"
            style={{ width: `${progress}%` }}
          />
        </div>
      </header>

      {/* Full-screen Exercise Visual */}
      <div
        className="flex-1 relative"
        style={{ paddingBottom: sheetExpanded ? '85vh' : '220px' }}
      >
        {/* Exercise video or Placeholder */}
        {videoUrl ? (
          <video
            key={videoUrl}
            src={videoUrl}
            autoPlay
            loop
            muted
            playsInline
            className="absolute inset-0 w-full h-full object-cover"
          />
        ) : (
          <div className="absolute inset-0 bg-gradient-to-br from-primary/30 via-surface to-cyan-900/30 flex flex-col items-center justify-center">
            {videoLoading ? (
              <>
                <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mb-4" />
                <p className="text-white/60 text-lg">Loading video...</p>
              </>
            ) : (
              <>
                {/* Large muscle group icon */}
                <div className="text-8xl mb-6 opacity-80">{getMuscleGroupIcon(currentExercise.muscle_group)}</div>
                {/* Exercise name */}
                <h1 className="text-3xl font-bold text-white text-center px-8 mb-2">{currentExercise.name}</h1>
                {/* Muscle group */}
                <p className="text-white/60 text-lg">{currentExercise.muscle_group || 'Full Body'}</p>
                {/* Exercise counter */}
                <p className="text-white/40 text-sm mt-4">
                  Exercise {currentExerciseIndex + 1} of {workout.exercises.length}
                </p>
              </>
            )}
          </div>
        )}

        {/* Rest Timer Overlay */}
        {isResting && restTimer !== null && (
          <div className="absolute inset-0 bg-black/70 flex flex-col items-center justify-center z-20">
            <p className="text-white/60 text-lg mb-2">Rest Time</p>
            <div className="text-7xl font-bold text-white font-mono mb-6">
              {formatTime(restTimer)}
            </div>
            <button
              onClick={() => {
                setIsResting(false);
                setRestTimer(null);
              }}
              className="px-8 py-3 bg-white/10 hover:bg-white/20 text-white rounded-full transition-colors text-lg"
            >
              Skip Rest
            </button>
          </div>
        )}

        {/* Exercise completed badge */}
        {exerciseCompleted && !isResting && (
          <div className="absolute top-24 left-1/2 -translate-x-1/2 z-10">
            <div className="bg-emerald-500 text-white px-4 py-2 rounded-full font-semibold flex items-center gap-2 shadow-lg shadow-emerald-500/30">
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
              </svg>
              Exercise Complete
            </div>
          </div>
        )}
      </div>

      {/* Bottom Sheet */}
      <BottomSheet
        isExpanded={sheetExpanded}
        onExpandedChange={setSheetExpanded}
        collapsedHeight={280}
        collapsedContent={collapsedContent}
      >
        {expandedContent}
      </BottomSheet>

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
        .safe-area-top {
          padding-top: max(12px, env(safe-area-inset-top));
        }
      `}</style>
    </div>
  );
}
